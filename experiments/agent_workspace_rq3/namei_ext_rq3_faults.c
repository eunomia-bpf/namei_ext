// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#define VERIFIER_LOG_SIZE (1024 * 1024)
#define UNREGISTERED_TARGET_ID 0xffffffffU
#define MANIFEST_ITEM_COUNT 8
#define EXPECTED_RUNTIME_CELLS 18

static unsigned int fault_cells_started;
static unsigned int fault_cells_torn_down;

enum rq3_fault_mode {
	RQ3_FAULT_PASS = 0,
	RQ3_FAULT_REDIRECT_LEN_ZERO = 1,
	RQ3_FAULT_REDIRECT_LEN_65 = 2,
	RQ3_FAULT_REDIRECT_DOT = 3,
	RQ3_FAULT_REDIRECT_DOT_DOT = 4,
	RQ3_FAULT_REDIRECT_SLASH = 5,
	RQ3_FAULT_REDIRECT_EMBEDDED_NUL = 6,
	RQ3_FAULT_TARGET_ZERO = 7,
	RQ3_FAULT_TARGET_UNREGISTERED = 8,
	RQ3_FAULT_SELECT_READDIR = 9,
	RQ3_FAULT_SELECT_CREATE = 10,
	RQ3_FAULT_SELECT_FINAL_OPEN = 11,
	RQ3_FAULT_REDIRECT_CREATE = 12,
};

struct attached_policy {
	struct bpf_object *obj;
	int cgroup_fd;
	int prog_fd;
	int mode_map_fd;
	bool attached;
};

struct manifest_item {
	bool exists;
	unsigned int dev_major;
	unsigned int dev_minor;
	unsigned long long ino;
	unsigned int mode;
	unsigned int uid;
	unsigned int gid;
	unsigned long long size;
	long long mtime_sec;
	unsigned int mtime_nsec;
	char sha256[65];
	char symlink_target[256];
};

struct lower_manifest {
	struct manifest_item items[MANIFEST_ITEM_COUNT];
	char root_entries[2048];
	char readdir_entries[2048];
};

static const struct {
	const char *role;
	const char *relative_path;
} manifest_paths[MANIFEST_ITEM_COUNT] = {
	{ "redirect_source", "rq3_redirect" },
	{ "target_source", "rq3_target" },
	{ "final_open_source", "rq3_select_open" },
	{ "readdir_entry", "readdir/entry" },
	{ "select_create_path", "rq3_select_create" },
	{ "redirect_create_path", "rq3_redirect_create" },
	{ "redirected_create_path", "redirected_create" },
	{ "symlink_fixture", "fixture-link" },
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      int expected_errno, const char *detail)
{
	fprintf(out,
		"{\"event\":\"rq3-fault-oracle\",\"case\":\"%s\","
		"\"pass\":%s,\"errno\":%d,\"expected_errno\":%d,"
		"\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, expected_errno, detail);
	fflush(out);
}

static int sha256_file(const char *path, char output[65])
{
	char buffer[128] = {};
	ssize_t got;
	size_t used = 0;
	pid_t pid;
	int pipe_fds[2];
	int status;
	size_t i;

	if (pipe2(pipe_fds, O_CLOEXEC))
		return -1;
	pid = fork();
	if (pid < 0) {
		close(pipe_fds[0]);
		close(pipe_fds[1]);
		return -1;
	}
	if (!pid) {
		if (dup2(pipe_fds[1], STDOUT_FILENO) < 0)
			_exit(126);
		close(pipe_fds[0]);
		close(pipe_fds[1]);
		execlp("sha256sum", "sha256sum", "--", path, NULL);
		_exit(127);
	}
	close(pipe_fds[1]);
	while (used < sizeof(buffer) - 1) {
		got = read(pipe_fds[0], buffer + used,
			   sizeof(buffer) - 1 - used);
		if (got < 0 && errno == EINTR)
			continue;
		if (got <= 0)
			break;
		used += (size_t)got;
	}
	close(pipe_fds[0]);
	while (waitpid(pid, &status, 0) < 0) {
		if (errno == EINTR)
			continue;
		return -1;
	}
	if (!WIFEXITED(status) || WEXITSTATUS(status) ||
	    used < 65 || buffer[64] != ' ') {
		errno = EIO;
		return -1;
	}
	for (i = 0; i < 64; i++) {
		if (!((buffer[i] >= '0' && buffer[i] <= '9') ||
		      (buffer[i] >= 'a' && buffer[i] <= 'f'))) {
			errno = EINVAL;
			return -1;
		}
	}
	memcpy(output, buffer, 64);
	output[64] = '\0';
	return 0;
}

static int capture_manifest_item(const char *path, struct manifest_item *item)
{
	struct statx stx;
	ssize_t length;

	memset(item, 0, sizeof(*item));
	if (statx(AT_FDCWD, path, AT_SYMLINK_NOFOLLOW | AT_STATX_SYNC_AS_STAT,
		  STATX_BASIC_STATS, &stx)) {
		if (errno == ENOENT)
			return 0;
		return -1;
	}
	item->exists = true;
	item->dev_major = stx.stx_dev_major;
	item->dev_minor = stx.stx_dev_minor;
	item->ino = stx.stx_ino;
	item->mode = stx.stx_mode;
	item->uid = stx.stx_uid;
	item->gid = stx.stx_gid;
	item->size = stx.stx_size;
	item->mtime_sec = stx.stx_mtime.tv_sec;
	item->mtime_nsec = stx.stx_mtime.tv_nsec;
	if (S_ISREG(stx.stx_mode) && sha256_file(path, item->sha256))
		return -1;
	if (S_ISLNK(stx.stx_mode)) {
		length = readlink(path, item->symlink_target,
				  sizeof(item->symlink_target) - 1);
		if (length < 0)
			return -1;
		item->symlink_target[length] = '\0';
	}
	return 0;
}

static int compare_names(const void *left, const void *right)
{
	return strcmp(left, right);
}

static int capture_directory_entries(const char *path, char *output,
				     size_t output_size)
{
	char names[64][256];
	struct dirent *entry;
	size_t count = 0;
	size_t used = 0;
	DIR *dir;
	size_t i;

	dir = opendir(path);
	if (!dir)
		return -1;
	errno = 0;
	while ((entry = readdir(dir))) {
		size_t length;

		if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
			continue;
		if (count >= sizeof(names) / sizeof(names[0])) {
			closedir(dir);
			errno = EOVERFLOW;
			return -1;
		}
		length = strlen(entry->d_name);
		if (length >= sizeof(names[count])) {
			closedir(dir);
			errno = ENAMETOOLONG;
			return -1;
		}
		memcpy(names[count], entry->d_name, length + 1);
		count++;
	}
	if (errno) {
		int saved_errno = errno;

		closedir(dir);
		errno = saved_errno;
		return -1;
	}
	if (closedir(dir))
		return -1;
	qsort(names, count, sizeof(names[0]), compare_names);
	output[0] = '\0';
	for (i = 0; i < count; i++) {
		int length = snprintf(output + used, output_size - used, "%s%s",
				      i ? "," : "", names[i]);

		if (length < 0 || (size_t)length >= output_size - used) {
			errno = EOVERFLOW;
			return -1;
		}
		used += (size_t)length;
	}
	return 0;
}

static int capture_lower_manifest(const char *root,
				  struct lower_manifest *manifest)
{
	char path[4096];
	size_t i;

	memset(manifest, 0, sizeof(*manifest));
	for (i = 0; i < MANIFEST_ITEM_COUNT; i++) {
		if (snprintf(path, sizeof(path), "%s/%s", root,
			     manifest_paths[i].relative_path) >= (int)sizeof(path)) {
			errno = ENAMETOOLONG;
			return -1;
		}
		if (capture_manifest_item(path, &manifest->items[i]))
			return -1;
	}
	if (capture_directory_entries(root, manifest->root_entries,
				      sizeof(manifest->root_entries)))
		return -1;
	if (snprintf(path, sizeof(path), "%s/readdir", root) >=
	    (int)sizeof(path)) {
		errno = ENAMETOOLONG;
		return -1;
	}
	if (capture_directory_entries(path, manifest->readdir_entries,
				      sizeof(manifest->readdir_entries)))
		return -1;
	return 0;
}

static bool manifest_items_equal(const struct manifest_item *a,
				 const struct manifest_item *b)
{
	return a->exists == b->exists &&
	       a->dev_major == b->dev_major &&
	       a->dev_minor == b->dev_minor &&
	       a->ino == b->ino &&
	       a->mode == b->mode &&
	       a->uid == b->uid &&
	       a->gid == b->gid &&
	       a->size == b->size &&
	       a->mtime_sec == b->mtime_sec &&
	       a->mtime_nsec == b->mtime_nsec &&
	       !strcmp(a->sha256, b->sha256) &&
	       !strcmp(a->symlink_target, b->symlink_target);
}

static bool lower_manifests_equal(const struct lower_manifest *a,
				  const struct lower_manifest *b)
{
	size_t i;

	for (i = 0; i < MANIFEST_ITEM_COUNT; i++) {
		if (!manifest_items_equal(&a->items[i], &b->items[i]))
			return false;
	}
	return !strcmp(a->root_entries, b->root_entries) &&
	       !strcmp(a->readdir_entries, b->readdir_entries);
}

static void emit_manifest(FILE *out, const char *case_name, const char *phase,
			  const struct lower_manifest *manifest)
{
	size_t i;

	for (i = 0; i < MANIFEST_ITEM_COUNT; i++) {
		const struct manifest_item *item = &manifest->items[i];

		fprintf(out,
			"{\"event\":\"rq3-fault-lower-object\","
			"\"fault_case\":\"%s\",\"phase\":\"%s\",\"role\":\"%s\","
			"\"exists\":%s,\"dev_major\":%u,\"dev_minor\":%u,"
			"\"ino\":%llu,\"mode\":%u,\"uid\":%u,\"gid\":%u,"
			"\"size\":%llu,\"mtime_sec\":%lld,\"mtime_nsec\":%u,"
			"\"sha256\":\"%s\",\"symlink_target\":\"%s\","
			"\"pass\":true}\n",
			case_name, phase, manifest_paths[i].role,
			item->exists ? "true" : "false", item->dev_major,
			item->dev_minor, item->ino, item->mode, item->uid,
			item->gid, item->size, item->mtime_sec,
			item->mtime_nsec, item->sha256, item->symlink_target);
	}
	fprintf(out,
		"{\"event\":\"rq3-fault-directory-manifest\","
		"\"fault_case\":\"%s\",\"phase\":\"%s\","
		"\"directory\":\"root\",\"entries\":\"%s\",\"pass\":true}\n",
		case_name, phase, manifest->root_entries);
	fprintf(out,
		"{\"event\":\"rq3-fault-directory-manifest\","
		"\"fault_case\":\"%s\",\"phase\":\"%s\","
		"\"directory\":\"readdir\",\"entries\":\"%s\",\"pass\":true}\n",
		case_name, phase, manifest->readdir_entries);
	fflush(out);
}

static bool emit_containment(FILE *out, const char *case_name,
			     const struct lower_manifest *before,
			     const struct lower_manifest *after)
{
	bool pass = lower_manifests_equal(before, after);

	fprintf(out,
		"{\"event\":\"rq3-fault-containment\",\"fault_case\":\"%s\","
		"\"pass\":%s,\"object_count\":%u,"
		"\"detail\":\"lower manifest unchanged across fault\"}\n",
		case_name, pass ? "true" : "false", MANIFEST_ITEM_COUNT);
	fflush(out);
	return pass;
}

static int write_text_file(const char *path, const char *contents)
{
	size_t len = strlen(contents);
	ssize_t written;
	int fd;

	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (fd < 0)
		return -1;
	written = write(fd, contents, len);
	if (written != (ssize_t)len) {
		int saved = written < 0 ? errno : EIO;

		close(fd);
		errno = saved;
		return -1;
	}
	if (close(fd))
		return -1;
	return 0;
}

static int write_raw_file(const char *path, const char *contents)
{
	FILE *file;
	size_t len = strlen(contents);

	file = fopen(path, "w");
	if (!file)
		return -1;
	if (fwrite(contents, 1, len, file) != len) {
		int saved = errno ? errno : EIO;

		fclose(file);
		errno = saved;
		return -1;
	}
	if (fclose(file))
		return -1;
	return 0;
}

static int expect_rejected_load(FILE *out, const char *case_name,
				const char *obj_path, int expected_errno,
				const char *required_log_a,
				const char *required_log_b,
				const char *log_path)
{
	char *log;
	struct bpf_object_open_opts opts;
	struct bpf_object *obj;
	int load_err;
	int actual_errno;
	bool log_matches;
	bool pass;

	log = calloc(1, VERIFIER_LOG_SIZE);
	if (!log) {
		emit_case(out, case_name, false, errno, expected_errno,
			  "verifier log allocation failed");
		return -1;
	}
	memset(&opts, 0, sizeof(opts));
	opts.sz = sizeof(opts);
	opts.kernel_log_buf = log;
	opts.kernel_log_size = VERIFIER_LOG_SIZE;
	opts.kernel_log_level = 1;

	obj = bpf_object__open_file(obj_path, &opts);
	load_err = libbpf_get_error(obj);
	if (load_err) {
		actual_errno = -load_err;
		obj = NULL;
	} else {
		load_err = bpf_object__load(obj);
		actual_errno = load_err < 0 ? -load_err : 0;
	}

	if (write_raw_file(log_path, log)) {
		int saved = errno;

		bpf_object__close(obj);
		free(log);
		emit_case(out, case_name, false, saved, expected_errno,
			  "failed to preserve verifier log");
		return -1;
	}

	log_matches = strstr(log, required_log_a) != NULL;
	if (required_log_b)
		log_matches = log_matches &&
			      strstr(log, required_log_b) != NULL;
	pass = load_err < 0 && actual_errno == expected_errno && log_matches;
	emit_case(out, case_name, pass, actual_errno, expected_errno,
		  pass ? "load rejected with expected verifier evidence" :
			 "load rejection errno or verifier evidence mismatch");
	bpf_object__close(obj);
	free(log);
	return pass ? 0 : -1;
}

static int load_and_attach(const char *obj_path, const char *cgroup_path,
			   struct attached_policy *policy)
{
	struct bpf_program *prog;
	struct bpf_map *map;
	int err;

	memset(policy, 0, sizeof(*policy));
	policy->cgroup_fd = -1;
	policy->prog_fd = -1;
	policy->mode_map_fd = -1;

	policy->obj = bpf_object__open_file(obj_path, NULL);
	err = libbpf_get_error(policy->obj);
	if (err) {
		policy->obj = NULL;
		errno = -err;
		return -1;
	}
	err = bpf_object__load(policy->obj);
	if (err) {
		errno = -err;
		goto error;
	}
	prog = bpf_object__next_program(policy->obj, NULL);
	if (!prog) {
		errno = EINVAL;
		goto error;
	}
	policy->prog_fd = bpf_program__fd(prog);
	if (policy->prog_fd < 0) {
		errno = EINVAL;
		goto error;
	}
	map = bpf_object__find_map_by_name(policy->obj, "rq3_fault_mode");
	if (!map) {
		errno = ENOENT;
		goto error;
	}
	policy->mode_map_fd = bpf_map__fd(map);
	if (policy->mode_map_fd < 0) {
		errno = EINVAL;
		goto error;
	}
	policy->cgroup_fd = open(cgroup_path,
				 O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (policy->cgroup_fd < 0)
		goto error;
	err = bpf_prog_attach(policy->prog_fd, policy->cgroup_fd,
			      BPF_CGROUP_NAMEI_EXT, 0);
	if (err) {
		errno = -err;
		goto error;
	}
	policy->attached = true;
	return 0;

error:
	if (policy->cgroup_fd >= 0)
		close(policy->cgroup_fd);
	bpf_object__close(policy->obj);
	policy->obj = NULL;
	policy->cgroup_fd = -1;
	return -1;
}

static int destroy_policy(struct attached_policy *policy)
{
	int err = 0;

	if (policy->attached) {
		err = bpf_prog_detach2(policy->prog_fd, policy->cgroup_fd,
				       BPF_CGROUP_NAMEI_EXT);
		policy->attached = false;
	}
	if (policy->cgroup_fd >= 0)
		close(policy->cgroup_fd);
	bpf_object__close(policy->obj);
	policy->obj = NULL;
	policy->cgroup_fd = -1;
	return err;
}

static int set_fault_mode(struct attached_policy *policy, __u32 mode)
{
	__u32 key = 0;

	return bpf_map_update_elem(policy->mode_map_fd, &key, &mode, BPF_ANY);
}

static int register_target(unsigned int target_id, const char *target_dir)
{
	char command[64];
	int control_fd;
	int target_fd;
	int len;
	ssize_t written;

	target_fd = open(target_dir, O_PATH | O_DIRECTORY | O_CLOEXEC);
	if (target_fd < 0)
		return -1;
	control_fd = open("/sys/kernel/debug/namei_ext/register_target",
			  O_WRONLY | O_CLOEXEC);
	if (control_fd < 0) {
		close(target_fd);
		return -1;
	}
	len = snprintf(command, sizeof(command), "%u %d\n", target_id,
		       target_fd);
	if (len <= 0 || len >= (int)sizeof(command)) {
		close(control_fd);
		close(target_fd);
		errno = EOVERFLOW;
		return -1;
	}
	written = write(control_fd, command, len);
	if (written != len) {
		int saved = written < 0 ? errno : EIO;

		close(control_fd);
		close(target_fd);
		errno = saved;
		return -1;
	}
	close(control_fd);
	close(target_fd);
	return 0;
}

static int clear_targets(void)
{
	static const char command[] = "clear\n";
	int fd;
	ssize_t written;

	fd = open("/sys/kernel/debug/namei_ext/register_target",
		  O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -1;
	written = write(fd, command, sizeof(command) - 1);
	if (written != (ssize_t)sizeof(command) - 1) {
		int saved = written < 0 ? errno : EIO;

		close(fd);
		errno = saved;
		return -1;
	}
	return close(fd);
}

static int begin_fault_cell(FILE *out, const char *fault_obj,
			    const char *cgroup_path, const char *target_dir,
			    const char *root, const char *case_name,
			    struct attached_policy *policy,
			    struct lower_manifest *baseline)
{
	if (capture_lower_manifest(root, baseline))
		goto fail;
	emit_manifest(out, case_name, "before_attach", baseline);
	if (load_and_attach(fault_obj, cgroup_path, policy))
		goto fail;
	if (register_target(1, target_dir))
		goto fail_detach;
	fault_cells_started++;
	return 0;

fail_detach:
	destroy_policy(policy);
	clear_targets();
fail:
	fprintf(out,
		"{\"event\":\"rq3-fault-cell-lifecycle\","
		"\"fault_case\":\"%s\",\"pass\":false,\"errno\":%d,"
		"\"detail\":\"fault cell setup failed\"}\n",
		case_name, errno);
	fflush(out);
	return -1;
}

static int end_fault_cell(FILE *out, const char *root, const char *case_name,
			  struct attached_policy *policy,
			  const struct lower_manifest *baseline)
{
	struct lower_manifest after;
	int saved_errno = 0;
	int err;
	bool pass;

	err = destroy_policy(policy);
	if (err)
		saved_errno = err < 0 ? -err : err;
	if (clear_targets() && !saved_errno)
		saved_errno = errno;
	if (capture_lower_manifest(root, &after) && !saved_errno)
		saved_errno = errno;
	if (saved_errno) {
		fprintf(out,
			"{\"event\":\"rq3-fault-cell-lifecycle\","
			"\"fault_case\":\"%s\",\"pass\":false,\"errno\":%d,"
			"\"detail\":\"fault cell teardown failed\"}\n",
			case_name, saved_errno);
		fflush(out);
		return -1;
	}
	emit_manifest(out, case_name, "after_teardown", &after);
	pass = lower_manifests_equal(baseline, &after);
	if (pass)
		fault_cells_torn_down++;
	fprintf(out,
		"{\"event\":\"rq3-fault-cell-lifecycle\","
		"\"fault_case\":\"%s\",\"pass\":%s,\"errno\":0,"
		"\"detail\":\"policy detached, targets cleared, lower manifest preserved\"}\n",
		case_name, pass ? "true" : "false");
	fflush(out);
	return pass ? 0 : -1;
}

static int leave_and_remove_child_cgroup(FILE *out, const char *cgroup_path)
{
	char parent_path[4096];
	char procs_path[4096];
	char pid_buffer[32];
	char *slash;
	ssize_t written;
	int length;
	int fd;

	if (snprintf(parent_path, sizeof(parent_path), "%s", cgroup_path) >=
	    (int)sizeof(parent_path))
		goto invalid;
	slash = strrchr(parent_path, '/');
	if (!slash || slash == parent_path)
		goto invalid;
	*slash = '\0';
	if (snprintf(procs_path, sizeof(procs_path), "%s/cgroup.procs",
		     parent_path) >= (int)sizeof(procs_path))
		goto invalid;
	fd = open(procs_path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		goto fail;
	length = snprintf(pid_buffer, sizeof(pid_buffer), "%ld\n",
			  (long)getpid());
	if (length <= 0 || length >= (int)sizeof(pid_buffer)) {
		close(fd);
		errno = EOVERFLOW;
		goto fail;
	}
	written = write(fd, pid_buffer, length);
	if (written != length) {
		int saved_errno = written < 0 ? errno : EIO;

		close(fd);
		errno = saved_errno;
		goto fail;
	}
	if (close(fd) || rmdir(cgroup_path))
		goto fail;
	emit_case(out, "fault_child_cgroup_removed", true, 0, 0,
		  "runner left and removed detached child cgroup");
	return 0;

invalid:
	errno = EINVAL;
fail:
	emit_case(out, "fault_child_cgroup_removed", false, errno, 0,
		  "runner could not leave and remove child cgroup");
	return -1;
}

static int enter_child_cgroup(FILE *out, const char *cgroup_path)
{
	char procs_path[4096];
	char pid_buffer[32];
	ssize_t written;
	int length;
	int fd;

	if (snprintf(procs_path, sizeof(procs_path), "%s/cgroup.procs",
		     cgroup_path) >= (int)sizeof(procs_path)) {
		errno = ENAMETOOLONG;
		goto fail;
	}
	fd = open(procs_path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		goto fail;
	length = snprintf(pid_buffer, sizeof(pid_buffer), "%ld\n",
			  (long)getpid());
	if (length <= 0 || length >= (int)sizeof(pid_buffer)) {
		close(fd);
		errno = EOVERFLOW;
		goto fail;
	}
	written = write(fd, pid_buffer, length);
	if (written != length) {
		int saved_errno = written < 0 ? errno : EIO;

		close(fd);
		errno = saved_errno;
		goto fail;
	}
	if (close(fd))
		goto fail;
	emit_case(out, "fault_child_cgroup_entered", true, 0, 0,
		  "runner entered dedicated fault child cgroup");
	return 0;

fail:
	emit_case(out, "fault_child_cgroup_entered", false, errno, 0,
		  "runner could not enter dedicated fault child cgroup");
	return -1;
}

static int drop_lookup_caches(FILE *out)
{
	static const char command[] = "2\n";
	ssize_t written;
	int fd;

	sync();
	fd = open("/proc/sys/vm/drop_caches", O_WRONLY | O_CLOEXEC);
	if (fd < 0) {
		emit_case(out, "target_cache_drop", false, errno, 0,
			  "open drop_caches failed");
		return -1;
	}
	written = write(fd, command, sizeof(command) - 1);
	if (written != (ssize_t)sizeof(command) - 1) {
		int saved = written < 0 ? errno : EIO;

		close(fd);
		emit_case(out, "target_cache_drop", false, saved, 0,
			  "drop_caches write failed");
		return -1;
	}
	if (close(fd)) {
		emit_case(out, "target_cache_drop", false, errno, 0,
			  "drop_caches close failed");
		return -1;
	}
	emit_case(out, "target_cache_drop", true, 0, 0,
		  "dentry and inode caches dropped before cold lookup");
	return 0;
}

static int prepare_fault_manifest(FILE *out, struct attached_policy *policy,
				  const char *case_name, const char *root,
				  struct lower_manifest *before)
{
	if (set_fault_mode(policy, RQ3_FAULT_PASS) ||
	    capture_lower_manifest(root, before)) {
		emit_case(out, case_name, false, errno, 0,
			  "pre-fault lower manifest capture failed");
		return -1;
	}
	emit_manifest(out, case_name, "before", before);
	return 0;
}

static bool finish_fault_manifest(FILE *out, struct attached_policy *policy,
				  const char *case_name, const char *root,
				  const struct lower_manifest *before)
{
	struct lower_manifest after;

	if (set_fault_mode(policy, RQ3_FAULT_PASS) ||
	    capture_lower_manifest(root, &after)) {
		fprintf(out,
			"{\"event\":\"rq3-fault-containment\","
			"\"fault_case\":\"%s\",\"pass\":false,\"object_count\":%u,"
			"\"detail\":\"post-fault manifest capture failed\"}\n",
			case_name, MANIFEST_ITEM_COUNT);
		fflush(out);
		return false;
	}
	emit_manifest(out, case_name, "after", &after);
	return emit_containment(out, case_name, before, &after);
}

static int expect_stat_errno(FILE *out, struct attached_policy *policy,
			     const char *case_name, __u32 mode,
			     const char *path, int expected_errno,
			     const char *root)
{
	struct lower_manifest before;
	struct stat st;
	int actual_errno;
	bool contained;
	bool pass;

	if (prepare_fault_manifest(out, policy, case_name, root, &before))
		return -1;
	if (set_fault_mode(policy, mode)) {
		emit_case(out, case_name, false, errno, expected_errno,
			  "failed to update fault mode");
		return -1;
	}
	errno = 0;
	if (!stat(path, &st))
		actual_errno = 0;
	else
		actual_errno = errno;
	contained = finish_fault_manifest(out, policy, case_name, root, &before);
	pass = actual_errno == expected_errno && contained;
	emit_case(out, case_name, pass, actual_errno, expected_errno,
		  pass ? "stat failed closed and preserved lower objects" :
			 "stat errno or lower-object containment mismatched");
	return pass ? 0 : -1;
}

static int expect_open_errno(FILE *out, struct attached_policy *policy,
			     const char *case_name, __u32 mode,
			     const char *path, int flags, int expected_errno,
			     const char *root)
{
	struct lower_manifest before;
	int actual_errno;
	int fd;
	bool contained;
	bool pass;

	if (prepare_fault_manifest(out, policy, case_name, root, &before))
		return -1;
	if (set_fault_mode(policy, mode)) {
		emit_case(out, case_name, false, errno, expected_errno,
			  "failed to update fault mode");
		return -1;
	}
	errno = 0;
	fd = open(path, flags, 0644);
	if (fd >= 0) {
		actual_errno = 0;
		close(fd);
	} else {
		actual_errno = errno;
	}
	contained = finish_fault_manifest(out, policy, case_name, root, &before);
	pass = actual_errno == expected_errno && contained;
	emit_case(out, case_name, pass, actual_errno, expected_errno,
		  pass ? "open failed closed and created no lower object" :
			 "open errno or lower-object containment mismatched");
	return pass ? 0 : -1;
}

static int expect_readdir_errno(FILE *out, struct attached_policy *policy,
				const char *case_name, __u32 mode,
				const char *path, int expected_errno,
				const char *root)
{
	struct lower_manifest before;
	struct dirent *entry;
	DIR *dir;
	int actual_errno;
	bool contained;
	bool pass;

	if (prepare_fault_manifest(out, policy, case_name, root, &before))
		return -1;
	if (set_fault_mode(policy, mode)) {
		emit_case(out, case_name, false, errno, expected_errno,
			  "failed to update fault mode");
		return -1;
	}
	dir = opendir(path);
	if (!dir) {
		emit_case(out, case_name, false, errno, expected_errno,
			  "opendir failed before directory iteration");
		return -1;
	}
	errno = 0;
	do {
		entry = readdir(dir);
	} while (entry);
	actual_errno = errno;
	if (closedir(dir) && !actual_errno)
		actual_errno = errno;
	contained = finish_fault_manifest(out, policy, case_name, root, &before);
	pass = actual_errno == expected_errno && contained;
	emit_case(out, case_name, pass, actual_errno, expected_errno,
		  pass ? "directory iteration failed closed and preserved lower objects" :
			 "readdir errno or lower-object containment mismatched");
	return pass ? 0 : -1;
}

static int run_stat_fault_cell(FILE *out, const char *fault_obj,
			       const char *cgroup_path, const char *target_dir,
			       const char *root, const char *case_name,
			       __u32 mode, const char *path,
			       int expected_errno)
{
	struct lower_manifest baseline;
	struct attached_policy policy;
	int failures = 0;

	if (begin_fault_cell(out, fault_obj, cgroup_path, target_dir, root,
			     case_name, &policy, &baseline))
		return -1;
	failures += expect_stat_errno(out, &policy, case_name, mode, path,
				      expected_errno, root) != 0;
	failures += end_fault_cell(out, root, case_name, &policy, &baseline) != 0;
	return failures ? -1 : 0;
}

static int run_readdir_fault_cell(FILE *out, const char *fault_obj,
				  const char *cgroup_path,
				  const char *target_dir, const char *root,
				  const char *case_name, __u32 mode,
				  const char *path, int expected_errno)
{
	struct lower_manifest baseline;
	struct attached_policy policy;
	int failures = 0;

	if (begin_fault_cell(out, fault_obj, cgroup_path, target_dir, root,
			     case_name, &policy, &baseline))
		return -1;
	failures += expect_readdir_errno(out, &policy, case_name, mode, path,
					 expected_errno, root) != 0;
	failures += end_fault_cell(out, root, case_name, &policy, &baseline) != 0;
	return failures ? -1 : 0;
}

static int run_open_fault_cell(FILE *out, const char *fault_obj,
			       const char *cgroup_path, const char *target_dir,
			       const char *root, const char *case_name,
			       __u32 mode, const char *path, int flags,
			       int expected_errno)
{
	struct lower_manifest baseline;
	struct attached_policy policy;
	int failures = 0;

	if (begin_fault_cell(out, fault_obj, cgroup_path, target_dir, root,
			     case_name, &policy, &baseline))
		return -1;
	failures += expect_open_errno(out, &policy, case_name, mode, path, flags,
				      expected_errno, root) != 0;
	failures += end_fault_cell(out, root, case_name, &policy, &baseline) != 0;
	return failures ? -1 : 0;
}

static int run_target_zero_cell(FILE *out, const char *fault_obj,
				const char *cgroup_path,
				const char *target_dir, const char *root,
				const char *target_path)
{
	struct lower_manifest baseline;
	struct attached_policy policy;
	int failures = 0;

	if (begin_fault_cell(out, fault_obj, cgroup_path, target_dir, root,
			     "target_zero", &policy, &baseline))
		return -1;
	failures += drop_lookup_caches(out) != 0;
	failures += expect_stat_errno(out, &policy, "target_zero",
				      RQ3_FAULT_TARGET_ZERO, target_path, EINVAL,
				      root) != 0;
	failures += expect_stat_errno(out, &policy, "target_zero_warm",
				      RQ3_FAULT_TARGET_ZERO, target_path, EINVAL,
				      root) != 0;
	failures += end_fault_cell(out, root, "target_zero", &policy,
				  &baseline) != 0;
	return failures ? -1 : 0;
}

static int make_fixture(FILE *out, const char *root)
{
	char path[4096];

	if (mkdir(root, 0755) && errno != EEXIST)
		goto error;
	snprintf(path, sizeof(path), "%s/target", root);
	if (mkdir(path, 0755) && errno != EEXIST)
		goto error;
	snprintf(path, sizeof(path), "%s/readdir", root);
	if (mkdir(path, 0755) && errno != EEXIST)
		goto error;
	snprintf(path, sizeof(path), "%s/rq3_redirect", root);
	if (write_text_file(path, "redirect-source\n"))
		goto error;
	snprintf(path, sizeof(path), "%s/rq3_target", root);
	if (write_text_file(path, "target-source\n"))
		goto error;
	snprintf(path, sizeof(path), "%s/rq3_select_open", root);
	if (write_text_file(path, "open-source\n"))
		goto error;
	snprintf(path, sizeof(path), "%s/readdir/entry", root);
	if (write_text_file(path, "entry\n"))
		goto error;
	snprintf(path, sizeof(path), "%s/fixture-link", root);
	if (symlink("rq3_target", path))
		goto error;
	emit_case(out, "fixture_setup", true, 0, 0,
		  "fault fixture created");
	return 0;

error:
	emit_case(out, "fixture_setup", false, errno, 0,
		  "fault fixture creation failed");
	return -1;
}

int main(int argc, char **argv)
{
	static const struct {
		const char *name;
		__u32 mode;
	} redirect_cases[] = {
		{ "redirect_len_zero", RQ3_FAULT_REDIRECT_LEN_ZERO },
		{ "redirect_len_65", RQ3_FAULT_REDIRECT_LEN_65 },
		{ "redirect_dot", RQ3_FAULT_REDIRECT_DOT },
		{ "redirect_dot_dot", RQ3_FAULT_REDIRECT_DOT_DOT },
		{ "redirect_slash", RQ3_FAULT_REDIRECT_SLASH },
		{ "redirect_embedded_nul", RQ3_FAULT_REDIRECT_EMBEDDED_NUL },
	};
	char redirect_path[4096];
	char target_path[4096];
	char readdir_path[4096];
	char select_create_path[4096];
	char redirect_create_path[4096];
	char select_open_path[4096];
	char target_dir[4096];
	char ctx_log[4096];
	char action_log[4096];
	char readdir_case[128];
	FILE *out;
	int failures = 0;
	size_t i;

	if (argc != 8) {
		fprintf(stderr,
			"usage: %s <invalid-ctx.o> <invalid-action.o> "
			"<fault.o> <jsonl> <log-dir> <cgroup> <work-root>\n",
			argv[0]);
		return 2;
	}
	out = fopen(argv[4], "a");
	if (!out) {
		perror("fopen jsonl");
		return 1;
	}
	if (enter_child_cgroup(out, argv[6])) {
		fclose(out);
		return 1;
	}
	snprintf(ctx_log, sizeof(ctx_log), "%s/invalid-ctx-verifier.log",
		 argv[5]);
	snprintf(action_log, sizeof(action_log),
		 "%s/invalid-action-verifier.log", argv[5]);
	failures += expect_rejected_load(
		out, "verifier_reject_ctx_write", argv[1], EACCES,
		"invalid bpf_context access", NULL, ctx_log) != 0;
	failures += expect_rejected_load(
		out, "verifier_reject_action_4", argv[2], EINVAL,
		"At program exit", "[0, 3]", action_log) != 0;
	if (failures)
		goto done;

	if (make_fixture(out, argv[7])) {
		failures++;
		goto done;
	}
	snprintf(redirect_path, sizeof(redirect_path), "%s/rq3_redirect",
		 argv[7]);
	snprintf(target_path, sizeof(target_path), "%s/rq3_target", argv[7]);
	snprintf(readdir_path, sizeof(readdir_path), "%s/readdir", argv[7]);
	snprintf(select_create_path, sizeof(select_create_path),
		 "%s/rq3_select_create", argv[7]);
	snprintf(redirect_create_path, sizeof(redirect_create_path),
		 "%s/rq3_redirect_create", argv[7]);
	snprintf(select_open_path, sizeof(select_open_path),
		 "%s/rq3_select_open", argv[7]);
	snprintf(target_dir, sizeof(target_dir), "%s/target", argv[7]);

	for (i = 0; i < sizeof(redirect_cases) / sizeof(redirect_cases[0]);
	     i++) {
		failures += run_stat_fault_cell(
			out, argv[3], argv[6], target_dir, argv[7],
			redirect_cases[i].name, redirect_cases[i].mode,
			redirect_path, EINVAL) != 0;
		snprintf(readdir_case, sizeof(readdir_case), "%s_readdir",
			 redirect_cases[i].name);
		failures += run_readdir_fault_cell(
			out, argv[3], argv[6], target_dir, argv[7],
			readdir_case, redirect_cases[i].mode, argv[7],
			EINVAL) != 0;
	}
	failures += run_target_zero_cell(out, argv[3], argv[6], target_dir,
					 argv[7], target_path) != 0;
	failures += run_stat_fault_cell(
		out, argv[3], argv[6], target_dir, argv[7],
		"target_unregistered", RQ3_FAULT_TARGET_UNREGISTERED,
		target_path, ENOENT) != 0;
	failures += run_readdir_fault_cell(
		out, argv[3], argv[6], target_dir, argv[7], "select_readdir",
		RQ3_FAULT_SELECT_READDIR, readdir_path, EOPNOTSUPP) != 0;
	failures += run_open_fault_cell(
		out, argv[3], argv[6], target_dir, argv[7], "select_create",
		RQ3_FAULT_SELECT_CREATE, select_create_path,
		O_WRONLY | O_CREAT | O_EXCL, EOPNOTSUPP) != 0;
	failures += run_open_fault_cell(
		out, argv[3], argv[6], target_dir, argv[7], "redirect_create",
		RQ3_FAULT_REDIRECT_CREATE, redirect_create_path,
		O_WRONLY | O_CREAT | O_EXCL, EOPNOTSUPP) != 0;
	failures += run_open_fault_cell(
		out, argv[3], argv[6], target_dir, argv[7], "select_final_open",
		RQ3_FAULT_SELECT_FINAL_OPEN, select_open_path, O_RDONLY,
		EOPNOTSUPP) != 0;

	emit_case(out, "fault_policy_attach",
		  fault_cells_started == EXPECTED_RUNTIME_CELLS, 0, 0,
		  "each runtime fault loaded and attached an independent policy");
	emit_case(out, "register_target",
		  fault_cells_started == EXPECTED_RUNTIME_CELLS, 0, 0,
		  "target 1 registered independently for every runtime cell");
	emit_case(out, "policy_teardown",
		  fault_cells_torn_down == EXPECTED_RUNTIME_CELLS, 0, 0,
		  "every runtime fault detached and closed its BPF object");
	emit_case(out, "target_teardown",
		  fault_cells_torn_down == EXPECTED_RUNTIME_CELLS, 0, 0,
		  "every runtime fault cleared its target registry");
	if (fault_cells_started != EXPECTED_RUNTIME_CELLS ||
	    fault_cells_torn_down != EXPECTED_RUNTIME_CELLS)
		failures++;
	failures += leave_and_remove_child_cgroup(out, argv[6]) != 0;
	if (write_text_file(select_open_path, "after-detach\n")) {
		emit_case(out, "post_teardown_lower_access", false, errno, 0,
			  "ordinary lower file access failed after detach");
		failures++;
	} else {
		emit_case(out, "post_teardown_lower_access", true, 0, 0,
			  "ordinary lower file access succeeded after detach");
	}

done:
	fprintf(out,
		"{\"event\":\"rq3-fault-summary\",\"pass\":%s,"
		"\"failures\":%d,\"unregistered_target_id\":%u}\n",
		failures ? "false" : "true", failures,
		UNREGISTERED_TARGET_ID);
	if (fclose(out))
		return 1;
	return failures ? 1 : 0;
}
