// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE
#define FUSE_USE_VERSION 26

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <ftw.h>
#include <limits.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define TREE_FILES 64
#define MAX_MOUNTS (TREE_FILES + 2)

struct baseline_stats {
	unsigned long long created_dirs;
	unsigned long long created_files;
	unsigned long long created_symlinks;
	unsigned long long bind_mounts;
	unsigned long long overlay_mounts;
	unsigned long long fuse_mounts;
	unsigned long long bytes_copied;
	unsigned long long source_update_writes;
	unsigned long long baseline_update_writes;
	unsigned long long update_bytes_copied;
};

struct baseline_env {
	char top[PATH_MAX];
	char root[PATH_MAX];
	char backing_root[PATH_MAX];
	char lower[PATH_MAX];
	char upper[PATH_MAX];
	char work[PATH_MAX];
	char merged[PATH_MAX];
	char native[PATH_MAX];
	char native_backing[PATH_MAX];
	char alias[PATH_MAX];
	char backing[PATH_MAX];
	char upper_alias[PATH_MAX];
	char tree_alias[TREE_FILES][PATH_MAX];
	char tree_backing[TREE_FILES][PATH_MAX];
	char upper_tree_alias[TREE_FILES][PATH_MAX];
	char mount_points[MAX_MOUNTS][PATH_MAX];
	int mount_count;
	pid_t fuse_pid;
	struct baseline_stats stats;
};

struct path_ctx {
	const char *path;
	int want_errno;
};

struct content_ctx {
	const char *path;
	const char *expected;
};

struct access_ctx {
	const char *path;
	int mode;
	int want_errno;
};

struct readdir_ctx {
	const char *path;
};

struct tree_ctx {
	struct baseline_env *env;
};

typedef void (*bench_op_fn)(void *ctx, unsigned long long *ops,
			    unsigned long long *ok,
			    unsigned long long *fail);

static int latency_samples;
static int latency_batch;

static int set_path(char *dst, size_t size, const char *fmt, ...)
{
	va_list ap;
	int ret;

	va_start(ap, fmt);
	ret = vsnprintf(dst, size, fmt, ap);
	va_end(ap);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static unsigned long long now_ns(void)
{
	struct timespec ts;

	clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
	return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

static int parse_int_arg(const char *arg, int min, int *out)
{
	char *end = NULL;
	long value;

	errno = 0;
	value = strtol(arg, &end, 10);
	if (errno || !end || *end || value < min || value > INT_MAX)
		return -EINVAL;
	*out = (int)value;
	return 0;
}

static const char *scratch_root(void)
{
	const char *root = getenv("NAMEI_EXT_BASELINE_TMPDIR");

	if (root && root[0])
		return root;
	return "/tmp";
}

static int make_temp_top(struct baseline_env *env)
{
	int ret;

	ret = snprintf(env->top, sizeof(env->top),
		       "%s/namei-ext-baseline-XXXXXX", scratch_root());
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= sizeof(env->top))
		return -ENAMETOOLONG;
	if (!mkdtemp(env->top))
		return -errno;
	env->stats.created_dirs++;
	return 0;
}

static void emit_measure(FILE *out, const char *event, const char *run_id,
			 const char *baseline, const char *bench, int sample,
			 int latency_sample, unsigned long long ops,
			 unsigned long long elapsed_ns,
			 unsigned long long ok, unsigned long long fail)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"%s\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"baseline\":\"%s\","
		"\"bench\":\"%s\",\"sample\":%d",
		event, run_id, baseline, bench, sample);
	if (latency_sample >= 0)
		fprintf(out, ",\"latency_sample\":%d", latency_sample);
	fprintf(out,
		",\"ops\":%llu,\"elapsed_ns\":%llu,"
		"\"ok\":%llu,\"fail\":%llu}\n",
		ops, elapsed_ns, ok, fail);
	fflush(out);
}

static void emit_setup(FILE *out, const char *run_id, const char *baseline,
		       bool pass, int err, unsigned long long setup_ns,
		       const struct baseline_stats *stats)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"baseline-setup\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"baseline\":\"%s\","
		"\"pass\":%s,\"errno\":%d,\"setup_ns\":%llu,"
		"\"created_dirs\":%llu,\"created_files\":%llu,"
		"\"created_symlinks\":%llu,\"bind_mounts\":%llu,"
		"\"overlay_mounts\":%llu,\"fuse_mounts\":%llu,"
		"\"bytes_copied\":%llu}\n",
		run_id, baseline, pass ? "true" : "false", err, setup_ns,
		stats->created_dirs, stats->created_files,
		stats->created_symlinks, stats->bind_mounts,
		stats->overlay_mounts, stats->fuse_mounts, stats->bytes_copied);
	fflush(out);
}

static void emit_update(FILE *out, const char *run_id, const char *baseline,
			bool pass, int err, unsigned long long update_ns,
			const struct baseline_stats *stats)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"baseline-update\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"baseline\":\"%s\","
		"\"pass\":%s,\"errno\":%d,\"update_ns\":%llu,"
		"\"source_update_writes\":%llu,"
		"\"baseline_update_writes\":%llu,"
		"\"update_bytes_copied\":%llu}\n",
		run_id, baseline, pass ? "true" : "false", err, update_ns,
		stats->source_update_writes, stats->baseline_update_writes,
		stats->update_bytes_copied);
	fflush(out);
}

static void emit_cleanup(FILE *out, const char *run_id, const char *baseline,
			 bool pass, int err)
{
	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"baseline-cleanup\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"baseline\":\"%s\","
		"\"pass\":%s,\"errno\":%d}\n",
		run_id, baseline, pass ? "true" : "false", err);
	fflush(out);
}

static int mkdir_one(const char *path, struct baseline_stats *stats)
{
	if (!mkdir(path, 0755)) {
		stats->created_dirs++;
		return 0;
	}
	if (errno == EEXIST)
		return 0;
	return -errno;
}

static int write_payload(const char *path, const char *payload, mode_t mode,
			 struct baseline_stats *stats)
{
	size_t len = strlen(payload);
	int fd;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
	if (fd < 0)
		return -errno;
	if (write(fd, payload, len) != (ssize_t)len) {
		int err = errno;

		close(fd);
		return -err;
	}
	if (fchmod(fd, mode)) {
		int err = errno;

		close(fd);
		return -err;
	}
	if (close(fd))
		return -errno;
	stats->created_files++;
	return 0;
}

static int copy_file(const char *src, const char *dst,
		     unsigned long long *bytes_out)
{
	char buf[8192];
	struct stat st;
	int in;
	int out;
	int ret = 0;
	unsigned long long bytes = 0;

	in = open(src, O_RDONLY);
	if (in < 0)
		return -errno;
	if (fstat(in, &st)) {
		ret = -errno;
		goto out_close_in;
	}
	out = open(dst, O_CREAT | O_TRUNC | O_WRONLY, st.st_mode & 0777);
	if (out < 0) {
		ret = -errno;
		goto out_close_in;
	}
	for (;;) {
		ssize_t nr = read(in, buf, sizeof(buf));

		if (nr < 0) {
			ret = -errno;
			break;
		}
		if (!nr)
			break;
		if (write(out, buf, nr) != nr) {
			ret = -errno;
			break;
		}
		bytes += (unsigned long long)nr;
	}
	if (!ret && fchmod(out, st.st_mode & 0777))
		ret = -errno;
	if (close(out) && !ret)
		ret = -errno;
out_close_in:
	if (close(in) && !ret)
		ret = -errno;
	if (!ret && bytes_out)
		*bytes_out += bytes;
	return ret;
}

static int add_mount_point(struct baseline_env *env, const char *path)
{
	if (env->mount_count >= MAX_MOUNTS)
		return -ENOSPC;
	snprintf(env->mount_points[env->mount_count],
		 sizeof(env->mount_points[env->mount_count]), "%s", path);
	env->mount_count++;
	return 0;
}

static int remove_cb(const char *fpath, const struct stat *sb, int typeflag,
		     struct FTW *ftwbuf)
{
	(void)sb;
	(void)ftwbuf;

	if (typeflag == FTW_DP || typeflag == FTW_D)
		return rmdir(fpath);
	return unlink(fpath);
}

static int rm_rf(const char *path)
{
	if (!path[0])
		return 0;
	if (!access(path, F_OK) && nftw(path, remove_cb, 64,
					FTW_DEPTH | FTW_PHYS))
		return -errno;
	return 0;
}

static int run_unmount_helper(const char *helper, const char *path)
{
	int status;
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (pid == 0) {
		execlp(helper, helper, "-u", "-z", path, NULL);
		_exit(127);
	}
	while (waitpid(pid, &status, 0) < 0) {
		if (errno == EINTR)
			continue;
		return -errno;
	}
	if (WIFEXITED(status) && WEXITSTATUS(status) == 0)
		return 0;
	return -EIO;
}

static int unmount_one(struct baseline_env *env, const char *path)
{
	int err;

	if (!umount2(path, MNT_DETACH))
		return 0;
	err = errno;
	if (err == EINVAL || err == ENOENT)
		return 0;
	if (env->fuse_pid > 0 && (err == EPERM || err == EACCES)) {
		if (!run_unmount_helper("fusermount3", path) ||
		    !run_unmount_helper("fusermount", path))
			return 0;
	}
	return -err;
}

static int cleanup_env(struct baseline_env *env)
{
	int ret = 0;
	int err;
	int i;

	for (i = env->mount_count - 1; i >= 0; i--) {
		err = unmount_one(env, env->mount_points[i]);
		if (err && !ret)
			ret = err;
	}
	if (env->fuse_pid > 0) {
		int status;

		kill(env->fuse_pid, SIGTERM);
		while (waitpid(env->fuse_pid, &status, 0) < 0) {
			if (errno == EINTR)
				continue;
			if (!ret)
				ret = -errno;
			break;
		}
	}
	err = rm_rf(env->top);
	if (err && !ret)
		ret = err;
	memset(env, 0, sizeof(*env));
	return ret;
}

static int create_common_non_overlay(struct baseline_env *env)
{
	char dir[PATH_MAX];
	int ret;
	int i;

	memset(env, 0, sizeof(*env));
	ret = make_temp_top(env);
	if (ret)
		return ret;

	ret = set_path(env->root, sizeof(env->root), "%s/view", env->top);
	if (ret)
		return ret;
	ret = set_path(env->backing_root, sizeof(env->backing_root),
		       "%s/backing", env->top);
	if (ret)
		return ret;
	ret = mkdir_one(env->root, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->backing_root, &env->stats);
	if (ret)
		return ret;

	ret = set_path(env->native, sizeof(env->native), "%s/native",
		       env->root);
	if (ret)
		return ret;
	ret = set_path(env->alias, sizeof(env->alias), "%s/tool", env->root);
	if (ret)
		return ret;
	ret = set_path(env->backing, sizeof(env->backing), "%s/tool.real",
		       env->backing_root);
	if (ret)
		return ret;
	ret = write_payload(env->native, "native\n", 0755, &env->stats);
	if (ret)
		return ret;
	ret = write_payload(env->backing, "tool\n", 0755, &env->stats);
	if (ret)
		return ret;

	ret = set_path(dir, sizeof(dir), "%s/tree", env->root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree/include", env->root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree", env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree/include",
		       env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;

	for (i = 0; i < TREE_FILES; i++) {
		ret = set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			       env->root, i);
		if (ret)
			return ret;
		ret = mkdir_one(dir, &env->stats);
		if (ret)
			return ret;
		ret = set_path(env->tree_alias[i],
			       sizeof(env->tree_alias[i]), "%s/tool", dir);
		if (ret)
			return ret;
		ret = set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			       env->backing_root, i);
		if (ret)
			return ret;
		ret = mkdir_one(dir, &env->stats);
		if (ret)
			return ret;
		ret = set_path(env->tree_backing[i],
			       sizeof(env->tree_backing[i]), "%s/tool.real",
			       dir);
		if (ret)
			return ret;
		ret = write_payload(env->tree_backing[i], "tree\n", 0755,
				    &env->stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int setup_copy_tree(struct baseline_env *env)
{
	unsigned long long bytes = 0;
	int ret;
	int i;

	ret = create_common_non_overlay(env);
	if (ret)
		return ret;
	ret = copy_file(env->backing, env->alias, &bytes);
	if (ret)
		return ret;
	env->stats.created_files++;
	env->stats.bytes_copied += bytes;
	for (i = 0; i < TREE_FILES; i++) {
		bytes = 0;
		ret = copy_file(env->tree_backing[i], env->tree_alias[i],
				&bytes);
		if (ret)
			return ret;
		env->stats.created_files++;
		env->stats.bytes_copied += bytes;
	}
	return 0;
}

static int setup_symlink_forest(struct baseline_env *env)
{
	int ret;
	int i;

	ret = create_common_non_overlay(env);
	if (ret)
		return ret;
	if (symlink(env->backing, env->alias))
		return -errno;
	env->stats.created_symlinks++;
	for (i = 0; i < TREE_FILES; i++) {
		if (symlink(env->tree_backing[i], env->tree_alias[i]))
			return -errno;
		env->stats.created_symlinks++;
	}
	return 0;
}

static int setup_bind_mount(struct baseline_env *env)
{
	int ret;
	int i;

	ret = create_common_non_overlay(env);
	if (ret)
		return ret;
	ret = write_payload(env->alias, "", 0755, &env->stats);
	if (ret)
		return ret;
	if (mount(env->backing, env->alias, NULL, MS_BIND, NULL))
		return -errno;
	ret = add_mount_point(env, env->alias);
	if (ret)
		return ret;
	env->stats.bind_mounts++;

	for (i = 0; i < TREE_FILES; i++) {
		ret = write_payload(env->tree_alias[i], "", 0755,
				    &env->stats);
		if (ret)
			return ret;
		if (mount(env->tree_backing[i], env->tree_alias[i], NULL,
			  MS_BIND, NULL))
			return -errno;
		ret = add_mount_point(env, env->tree_alias[i]);
		if (ret)
			return ret;
		env->stats.bind_mounts++;
	}
	return 0;
}

static int setup_overlayfs(struct baseline_env *env)
{
	char opts[PATH_MAX * 3 + 64];
	char dir[PATH_MAX];
	unsigned long long bytes = 0;
	int ret;
	int i;

	memset(env, 0, sizeof(*env));
	ret = make_temp_top(env);
	if (ret)
		return ret;

	ret = set_path(env->lower, sizeof(env->lower), "%s/lower", env->top);
	if (ret)
		return ret;
	ret = set_path(env->upper, sizeof(env->upper), "%s/upper", env->top);
	if (ret)
		return ret;
	ret = set_path(env->work, sizeof(env->work), "%s/work", env->top);
	if (ret)
		return ret;
	ret = set_path(env->merged, sizeof(env->merged), "%s/merged",
		       env->top);
	if (ret)
		return ret;
	ret = set_path(env->backing_root, sizeof(env->backing_root),
		       "%s/backing", env->top);
	if (ret)
		return ret;
	ret = mkdir_one(env->lower, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->upper, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->work, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->merged, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->backing_root, &env->stats);
	if (ret)
		return ret;

	ret = set_path(env->native, sizeof(env->native), "%s/native",
		       env->lower);
	if (ret)
		return ret;
	ret = set_path(env->backing, sizeof(env->backing), "%s/tool.real",
		       env->backing_root);
	if (ret)
		return ret;
	ret = set_path(env->upper_alias, sizeof(env->upper_alias), "%s/tool",
		       env->upper);
	if (ret)
		return ret;
	ret = write_payload(env->native, "native\n", 0755, &env->stats);
	if (ret)
		return ret;
	ret = write_payload(env->backing, "tool\n", 0755, &env->stats);
	if (ret)
		return ret;
	ret = copy_file(env->backing, env->upper_alias, &bytes);
	if (ret)
		return ret;
	env->stats.created_files++;
	env->stats.bytes_copied += bytes;

	ret = set_path(dir, sizeof(dir), "%s/tree", env->upper);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree/include", env->upper);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree", env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree/include",
		       env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;

	for (i = 0; i < TREE_FILES; i++) {
		ret = set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			       env->upper, i);
		if (ret)
			return ret;
		ret = mkdir_one(dir, &env->stats);
		if (ret)
			return ret;
		ret = set_path(env->upper_tree_alias[i],
			       sizeof(env->upper_tree_alias[i]), "%s/tool",
			       dir);
		if (ret)
			return ret;
		ret = set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			       env->backing_root, i);
		if (ret)
			return ret;
		ret = mkdir_one(dir, &env->stats);
		if (ret)
			return ret;
		ret = set_path(env->tree_backing[i],
			       sizeof(env->tree_backing[i]), "%s/tool.real",
			       dir);
		if (ret)
			return ret;
		ret = write_payload(env->tree_backing[i], "tree\n", 0755,
				    &env->stats);
		if (ret)
			return ret;
		bytes = 0;
		ret = copy_file(env->tree_backing[i],
				env->upper_tree_alias[i], &bytes);
		if (ret)
			return ret;
		env->stats.created_files++;
		env->stats.bytes_copied += bytes;
	}

	if (snprintf(opts, sizeof(opts), "lowerdir=%s,upperdir=%s,workdir=%s",
		     env->lower, env->upper, env->work) >= (int)sizeof(opts))
		return -ENAMETOOLONG;
	if (mount("overlay", env->merged, "overlay", 0, opts))
		return -errno;
	ret = add_mount_point(env, env->merged);
	if (ret)
		return ret;
	env->stats.overlay_mounts++;

	ret = set_path(env->root, sizeof(env->root), "%s", env->merged);
	if (ret)
		return ret;
	ret = set_path(env->native, sizeof(env->native), "%s/native",
		       env->merged);
	if (ret)
		return ret;
	ret = set_path(env->alias, sizeof(env->alias), "%s/tool",
		       env->merged);
	if (ret)
		return ret;
	for (i = 0; i < TREE_FILES; i++) {
		ret = set_path(env->tree_alias[i],
			       sizeof(env->tree_alias[i]),
			       "%s/tree/include/pkg%02d/tool",
			       env->merged, i);
		if (ret)
			return ret;
	}
	return 0;
}

static bool fuse_parse_pkg_path(const char *path, const char *suffix, int *idx)
{
	char fmt[64];
	char extra;
	int parsed;

	snprintf(fmt, sizeof(fmt), "/tree/include/pkg%%02d%s%%c", suffix);
	parsed = sscanf(path, fmt, idx, &extra);
	return parsed == 1 && *idx >= 0 && *idx < TREE_FILES;
}

static const char *fuse_file_source(struct baseline_env *env, const char *path)
{
	int idx;

	if (!strcmp(path, "/native"))
		return env->native_backing;
	if (!strcmp(path, "/tool"))
		return env->backing;
	if (fuse_parse_pkg_path(path, "/tool", &idx))
		return env->tree_backing[idx];
	return NULL;
}

static bool fuse_is_dir_path(const char *path)
{
	int idx;

	return !strcmp(path, "/") || !strcmp(path, "/tree") ||
	       !strcmp(path, "/tree/include") ||
	       fuse_parse_pkg_path(path, "", &idx);
}

static void fuse_fill_dir_stat(struct stat *st)
{
	memset(st, 0, sizeof(*st));
	st->st_mode = S_IFDIR | 0755;
	st->st_nlink = 2;
}

static int fuse_redirect_getattr(const char *path, struct stat *st)
{
	struct baseline_env *env = fuse_get_context()->private_data;
	const char *source;

	if (fuse_is_dir_path(path)) {
		fuse_fill_dir_stat(st);
		return 0;
	}

	source = fuse_file_source(env, path);
	if (!source)
		return -ENOENT;
	if (stat(source, st))
		return -errno;
	return 0;
}

static int fuse_redirect_access(const char *path, int mask)
{
	struct baseline_env *env = fuse_get_context()->private_data;
	const char *source;

	if (fuse_is_dir_path(path))
		return (mask & W_OK) ? -EACCES : 0;

	source = fuse_file_source(env, path);
	if (!source)
		return -ENOENT;
	if (access(source, mask))
		return -errno;
	return 0;
}

static int fuse_redirect_open(const char *path, struct fuse_file_info *fi)
{
	struct baseline_env *env = fuse_get_context()->private_data;
	const char *source = fuse_file_source(env, path);
	int fd;

	if (!source)
		return -ENOENT;
	if ((fi->flags & O_ACCMODE) != O_RDONLY)
		return -EACCES;
	fd = open(source, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fi->direct_io = 1;
	fi->keep_cache = 0;
	return 0;
}

static int fuse_redirect_read(const char *path, char *buf, size_t size,
			      off_t offset, struct fuse_file_info *fi)
{
	ssize_t ret;

	(void)path;
	ret = pread((int)fi->fh, buf, size, offset);
	if (ret < 0)
		return -errno;
	return (int)ret;
}

static int fuse_redirect_release(const char *path, struct fuse_file_info *fi)
{
	int ret;

	(void)path;
	ret = close((int)fi->fh);
	return ret ? -errno : 0;
}

static int fuse_redirect_readdir(const char *path, void *buf,
				 fuse_fill_dir_t filler, off_t offset,
				 struct fuse_file_info *fi)
{
	char name[16];
	int idx;

	(void)offset;
	(void)fi;
	if (!fuse_is_dir_path(path))
		return -ENOENT;

	filler(buf, ".", NULL, 0);
	filler(buf, "..", NULL, 0);
	if (!strcmp(path, "/")) {
		filler(buf, "native", NULL, 0);
		filler(buf, "tool", NULL, 0);
		filler(buf, "tree", NULL, 0);
		return 0;
	}
	if (!strcmp(path, "/tree")) {
		filler(buf, "include", NULL, 0);
		return 0;
	}
	if (!strcmp(path, "/tree/include")) {
		for (idx = 0; idx < TREE_FILES; idx++) {
			snprintf(name, sizeof(name), "pkg%02d", idx);
			filler(buf, name, NULL, 0);
		}
		return 0;
	}
	filler(buf, "tool", NULL, 0);
	return 0;
}

static struct fuse_operations fuse_redirect_ops = {
	.getattr = fuse_redirect_getattr,
	.access = fuse_redirect_access,
	.open = fuse_redirect_open,
	.read = fuse_redirect_read,
	.release = fuse_redirect_release,
	.readdir = fuse_redirect_readdir,
};

static int wait_for_fuse_ready(struct baseline_env *env)
{
	struct timespec delay = { .tv_sec = 0, .tv_nsec = 50000000 };
	int i;

	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t ret;

		if (!stat(env->alias, &st))
			return 0;
		ret = waitpid(env->fuse_pid, &status, WNOHANG);
		if (ret == env->fuse_pid) {
			env->fuse_pid = 0;
			return -EIO;
		}
		if (ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int create_common_fuse(struct baseline_env *env)
{
	char dir[PATH_MAX];
	int ret;
	int i;

	memset(env, 0, sizeof(*env));
	ret = make_temp_top(env);
	if (ret)
		return ret;

	ret = set_path(env->root, sizeof(env->root), "%s/fuse-view", env->top);
	if (ret)
		return ret;
	ret = set_path(env->backing_root, sizeof(env->backing_root),
		       "%s/backing", env->top);
	if (ret)
		return ret;
	ret = mkdir_one(env->root, &env->stats);
	if (ret)
		return ret;
	ret = mkdir_one(env->backing_root, &env->stats);
	if (ret)
		return ret;

	ret = set_path(env->native, sizeof(env->native), "%s/native",
		       env->root);
	if (ret)
		return ret;
	ret = set_path(env->alias, sizeof(env->alias), "%s/tool", env->root);
	if (ret)
		return ret;
	ret = set_path(env->native_backing, sizeof(env->native_backing),
		       "%s/native.real", env->backing_root);
	if (ret)
		return ret;
	ret = set_path(env->backing, sizeof(env->backing), "%s/tool.real",
		       env->backing_root);
	if (ret)
		return ret;
	ret = write_payload(env->native_backing, "native\n", 0755,
			    &env->stats);
	if (ret)
		return ret;
	ret = write_payload(env->backing, "tool\n", 0755, &env->stats);
	if (ret)
		return ret;

	ret = set_path(dir, sizeof(dir), "%s/tree", env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;
	ret = set_path(dir, sizeof(dir), "%s/tree/include",
		       env->backing_root);
	if (ret)
		return ret;
	ret = mkdir_one(dir, &env->stats);
	if (ret)
		return ret;

	for (i = 0; i < TREE_FILES; i++) {
		ret = set_path(dir, sizeof(dir), "%s/tree/include/pkg%02d",
			       env->backing_root, i);
		if (ret)
			return ret;
		ret = mkdir_one(dir, &env->stats);
		if (ret)
			return ret;
		ret = set_path(env->tree_alias[i],
			       sizeof(env->tree_alias[i]),
			       "%s/tree/include/pkg%02d/tool", env->root, i);
		if (ret)
			return ret;
		ret = set_path(env->tree_backing[i],
			       sizeof(env->tree_backing[i]), "%s/tool.real",
			       dir);
		if (ret)
			return ret;
		ret = write_payload(env->tree_backing[i], "tree\n", 0755,
				    &env->stats);
		if (ret)
			return ret;
	}
	return 0;
}

static int setup_fuse_redirect(struct baseline_env *env)
{
	char *argv[] = {
		"namei_ext_fuse_redirect",
		"-f",
		"-s",
		"-o",
		"default_permissions,attr_timeout=0,entry_timeout=0,negative_timeout=0",
		env->root,
		NULL,
	};
	int ret;

	ret = create_common_fuse(env);
	if (ret)
		return ret;
	ret = add_mount_point(env, env->root);
	if (ret)
		return ret;

	env->fuse_pid = fork();
	if (env->fuse_pid < 0)
		return -errno;
	if (env->fuse_pid == 0)
		_exit(fuse_main(6, argv, &fuse_redirect_ops, env));

	ret = wait_for_fuse_ready(env);
	if (ret)
		return ret;
	env->stats.fuse_mounts++;
	return 0;
}

static int update_copy_like(struct baseline_env *env, bool overlay)
{
	unsigned long long bytes = 0;
	int ret;

	ret = write_payload(env->backing, "tool-updated\n", 0755,
			    &env->stats);
	if (ret)
		return ret;
	env->stats.source_update_writes++;
	ret = copy_file(env->backing, overlay ? env->upper_alias : env->alias,
			&bytes);
	if (ret)
		return ret;
	env->stats.baseline_update_writes++;
	env->stats.update_bytes_copied += bytes;
	return 0;
}

static int update_copy_tree(struct baseline_env *env)
{
	return update_copy_like(env, false);
}

static int update_overlayfs(struct baseline_env *env)
{
	return update_copy_like(env, true);
}

static int update_link_like(struct baseline_env *env)
{
	int ret;

	ret = write_payload(env->backing, "tool-updated\n", 0755,
			    &env->stats);
	if (ret)
		return ret;
	env->stats.source_update_writes++;
	return 0;
}

static void op_stat_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;
	struct stat st;

	(*ops)++;
	errno = 0;
	if (!stat(ctx->path, &st)) {
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
}

static void op_open_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;
	int fd;

	(*ops)++;
	errno = 0;
	fd = open(ctx->path, O_RDONLY);
	if (fd >= 0) {
		close(fd);
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
}

static void op_read_content(void *data, unsigned long long *ops,
			    unsigned long long *ok, unsigned long long *fail)
{
	struct content_ctx *ctx = data;
	char buf[64];
	size_t want = strlen(ctx->expected);
	int fd;
	ssize_t got;

	(*ops)++;
	fd = open(ctx->path, O_RDONLY);
	if (fd < 0) {
		(*fail)++;
		return;
	}
	got = read(fd, buf, sizeof(buf));
	if (close(fd))
		(*fail)++;
	else if (got == (ssize_t)want && !memcmp(buf, ctx->expected, want))
		(*ok)++;
	else
		(*fail)++;
}

static void op_access_path(void *data, unsigned long long *ops,
			   unsigned long long *ok, unsigned long long *fail)
{
	struct access_ctx *ctx = data;

	(*ops)++;
	errno = 0;
	if (!access(ctx->path, ctx->mode)) {
		if (!ctx->want_errno)
			(*ok)++;
		else
			(*fail)++;
	} else if (errno == ctx->want_errno) {
		(*ok)++;
	} else {
		(*fail)++;
	}
}

static int exec_errno_once(const char *path, int want_errno)
{
	char *const argv[] = { (char *)path, NULL };
	char *const envp[] = { NULL };
	int status;
	pid_t pid;

	pid = fork();
	if (pid < 0)
		return -1;
	if (pid == 0) {
		execve(path, argv, envp);
		_exit(errno == want_errno ? 0 : 1);
	}
	if (waitpid(pid, &status, 0) < 0)
		return -1;
	return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
}

static void op_exec_path(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct path_ctx *ctx = data;

	(*ops)++;
	if (!exec_errno_once(ctx->path, ctx->want_errno))
		(*ok)++;
	else
		(*fail)++;
}

static void op_readdir_alias_view(void *data, unsigned long long *ops,
				  unsigned long long *ok,
				  unsigned long long *fail)
{
	struct readdir_ctx *ctx = data;
	bool saw_native = false;
	bool saw_alias = false;
	bool saw_backing = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(ctx->path);
	if (!dir) {
		(*fail)++;
		return;
	}
	while ((de = readdir(dir))) {
		(*ops)++;
		if (!strcmp(de->d_name, "native"))
			saw_native = true;
		if (!strcmp(de->d_name, "tool"))
			saw_alias = true;
		if (!strcmp(de->d_name, "tool.real"))
			saw_backing = true;
	}
	if (errno) {
		(*fail)++;
		closedir(dir);
		return;
	}
	closedir(dir);
	if (saw_native && saw_alias && !saw_backing)
		(*ok)++;
	else
		(*fail)++;
}

static void op_tree_walk(void *data, unsigned long long *ops,
			 unsigned long long *ok, unsigned long long *fail)
{
	struct tree_ctx *ctx = data;
	struct stat st;
	int j;

	for (j = 0; j < TREE_FILES; j++) {
		(*ops)++;
		if (!stat(ctx->env->tree_alias[j], &st))
			(*ok)++;
		else
			(*fail)++;
	}
}

static void run_op_batch(FILE *out, const char *run_id, const char *baseline,
			 const char *bench, int sample, int latency_sample,
			 int iterations, bench_op_fn op, void *ctx,
			 unsigned long long *failures)
{
	unsigned long long start, end, ops = 0, ok = 0, fail = 0;
	int i;

	start = now_ns();
	for (i = 0; i < iterations; i++)
		op(ctx, &ops, &ok, &fail);
	end = now_ns();
	emit_measure(out, latency_sample >= 0 ? "baseline_latency" : "baseline",
		     run_id, baseline, bench, sample, latency_sample, ops,
		     end - start, ok, fail);
	*failures += fail;
}

static void run_measured_bench(FILE *out, const char *run_id,
			       const char *baseline, const char *bench,
			       int sample, int iterations, bench_op_fn op,
			       void *ctx, unsigned long long *failures)
{
	int latency_sample;

	run_op_batch(out, run_id, baseline, bench, sample, -1, iterations, op,
		     ctx, failures);
	for (latency_sample = 0; latency_sample < latency_samples;
	     latency_sample++)
		run_op_batch(out, run_id, baseline, bench, sample,
			     latency_sample, latency_batch, op, ctx, failures);
}

static unsigned long long run_suite(FILE *out, const char *run_id,
				    const char *baseline,
				    struct baseline_env *env, int samples,
				    int iterations)
{
	int readdir_iters = iterations / 20;
	int exec_iters = iterations / 100;
	int tree_iters = iterations / TREE_FILES;
	unsigned long long failures = 0;
	int sample;

	if (readdir_iters < 1)
		readdir_iters = 1;
	if (exec_iters < 1)
		exec_iters = 1;
	if (tree_iters < 1)
		tree_iters = 1;

	for (sample = 0; sample < samples; sample++) {
		struct path_ctx native_stat = { env->native, 0 };
		struct path_ctx tool_stat = { env->alias, 0 };
			struct access_ctx tool_access = { env->alias, X_OK, 0 };
			struct path_ctx tool_open = { env->alias, 0 };
			struct content_ctx tool_content = {
				env->alias, "tool-updated\n"
			};
			struct path_ctx tool_exec = { env->alias, ENOEXEC };
			struct readdir_ctx readdir = { env->root };
			struct tree_ctx tree = { env };

		run_measured_bench(out, run_id, baseline, "lookup_native_hot",
				   sample, iterations, op_stat_path,
				   &native_stat, &failures);
		run_measured_bench(out, run_id, baseline,
				   "lookup_tool_redirect", sample,
				   iterations, op_stat_path, &tool_stat,
				   &failures);
		run_measured_bench(out, run_id, baseline,
				   "access_tool_redirect", sample,
				   iterations, op_access_path, &tool_access,
				   &failures);
			run_measured_bench(out, run_id, baseline, "open_tool_redirect",
					   sample, iterations, op_open_path,
					   &tool_open, &failures);
			run_measured_bench(out, run_id, baseline, "read_tool_content",
					   sample, iterations, op_read_content,
					   &tool_content, &failures);
			run_measured_bench(out, run_id, baseline, "exec_tool_redirect",
					   sample, exec_iters, op_exec_path,
					   &tool_exec, &failures);
		run_measured_bench(out, run_id, baseline, "readdir_alias_view",
				   sample, readdir_iters,
				   op_readdir_alias_view, &readdir,
				   &failures);
		run_measured_bench(out, run_id, baseline, "build_tree_stat_walk",
				   sample, tree_iters, op_tree_walk, &tree,
				   &failures);
	}
	return failures;
}

struct baseline_def {
	const char *name;
	int (*setup)(struct baseline_env *env);
	int (*update)(struct baseline_env *env);
};

static const struct baseline_def baseline_defs[] = {
	{ "copy_tree", setup_copy_tree, update_copy_tree },
	{ "symlink_forest", setup_symlink_forest, update_link_like },
	{ "bind_mount", setup_bind_mount, update_link_like },
	{ "overlayfs", setup_overlayfs, update_overlayfs },
	{ "fuse_redirect", setup_fuse_redirect, update_link_like },
};

static bool is_known_baseline(const char *name)
{
	size_t i;

	for (i = 0; i < sizeof(baseline_defs) / sizeof(baseline_defs[0]); i++) {
		if (!strcmp(name, baseline_defs[i].name))
			return true;
	}
	return false;
}

static bool selected(const char *list, const char *name)
{
	char buf[512];
	char *saveptr = NULL;
	char *tok;

	if (!strcmp(list, "all"))
		return true;
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (!strcmp(tok, name))
			return true;
	}
	return false;
}

static unsigned long long emit_unknown_baselines(FILE *out, const char *run_id,
						 const char *list)
{
	char buf[512];
	char *saveptr = NULL;
	char *tok;
	unsigned long long failures = 0;
	struct baseline_stats zero = {};

	if (!strcmp(list, "all"))
		return 0;
	snprintf(buf, sizeof(buf), "%s", list);
	for (tok = strtok_r(buf, " ,", &saveptr); tok;
	     tok = strtok_r(NULL, " ,", &saveptr)) {
		if (is_known_baseline(tok))
			continue;
		emit_setup(out, run_id, tok, false, ENOTSUP, 0, &zero);
		failures++;
	}
	return failures;
}

static int run_baseline(FILE *out, const char *run_id,
			const struct baseline_def *def, int samples,
			int iterations, unsigned long long *failures)
{
	struct baseline_env env;
	unsigned long long start;
	unsigned long long setup_ns;
	unsigned long long update_ns;
	unsigned long long op_failures;
	int ret;

	memset(&env, 0, sizeof(env));
	start = now_ns();
	ret = def->setup(&env);
	setup_ns = now_ns() - start;
	emit_setup(out, run_id, def->name, ret == 0, ret ? -ret : 0,
		   setup_ns, &env.stats);
	if (ret) {
		(*failures)++;
		cleanup_env(&env);
		return ret;
	}

	start = now_ns();
	ret = def->update(&env);
	update_ns = now_ns() - start;
	emit_update(out, run_id, def->name, ret == 0, ret ? -ret : 0,
		    update_ns, &env.stats);
	if (ret)
		(*failures)++;

	op_failures = run_suite(out, run_id, def->name, &env, samples,
				iterations);
	*failures += op_failures;

	ret = cleanup_env(&env);
	emit_cleanup(out, run_id, def->name, ret == 0, ret ? -ret : 0);
	if (ret)
		(*failures)++;
	return ret;
}

int main(int argc, char **argv)
{
	const char *baselines;
	const char *run_id;
	unsigned long long failures = 0;
	unsigned long long baselines_run = 0;
	int samples;
	int iterations;
	FILE *out;
	size_t i;

	if (argc != 8) {
		fprintf(stderr,
			"usage: %s RESULT_JSONL RUN_ID SAMPLES ITERATIONS LATENCY_SAMPLES LATENCY_BATCH BASELINES\n",
			argv[0]);
		return 2;
	}
	run_id = argv[2];
	if (parse_int_arg(argv[3], 1, &samples) ||
	    parse_int_arg(argv[4], 1, &iterations) ||
	    parse_int_arg(argv[5], 0, &latency_samples) ||
	    parse_int_arg(argv[6], 1, &latency_batch))
		return 2;
	baselines = argv[7];

	out = fopen(argv[1], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}

	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"baseline-start\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"samples\":%d,"
		"\"iterations\":%d,\"latency_samples\":%d,"
		"\"latency_batch\":%d,\"selected_baselines\":\"%s\","
		"\"tree_files\":%d}\n",
		run_id, samples, iterations, latency_samples, latency_batch,
		baselines, TREE_FILES);
	fflush(out);

	for (i = 0; i < sizeof(baseline_defs) / sizeof(baseline_defs[0]); i++) {
		if (!selected(baselines, baseline_defs[i].name))
			continue;
		baselines_run++;
		run_baseline(out, run_id, &baseline_defs[i], samples,
			     iterations, &failures);
	}
	failures += emit_unknown_baselines(out, run_id, baselines);

	fprintf(out,
		"{\"schema\":\"namei_ext.eval_osdi.baseline_raw.v1\","
		"\"event\":\"baseline-summary\",\"run_id\":\"%s\","
		"\"run_environment\":\"kvm\",\"baselines_run\":%llu,"
		"\"failures\":%llu,\"pass\":%s}\n",
		run_id, baselines_run, failures,
		failures == 0 && baselines_run > 0 ? "true" : "false");
	fclose(out);
	return failures == 0 && baselines_run > 0 ? 0 : 1;
}
