// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "namei_ext_harness.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
#define CASE_COUNT 16

enum semantic_counter {
	SC_COUNTER_TOTAL = 0,
	SC_COUNTER_LOOKUP = 1,
	SC_COUNTER_SELECT = 2,
	SC_COUNTER_PASS = 3,
	SC_COUNTER_READDIR = 4,
};

enum semantic_target {
	TARGET_A = 1,
	TARGET_B = 2,
	TARGET_X = 3,
	TARGET_MAX = 4,
};

struct arm_paths {
	char a[PATH_MAX];
	char b[PATH_MAX];
	char x[PATH_MAX];
	char unmanaged[PATH_MAX];
};

struct fixture {
	struct arm_paths direct;
	struct arm_paths selected;
	char logical[PATH_MAX];
	char selected_a_lower[PATH_MAX];
	char selected_b_lower[PATH_MAX];
	char selected_x_lower[PATH_MAX];
	char cgroup[PATH_MAX];
};

struct case_context {
	FILE *out;
	const char *arm;
	const char *id;
	unsigned int operations;
	unsigned int failures;
};

struct counter_snapshot {
	uint64_t pass;
	uint64_t target[TARGET_MAX];
};

struct policy_state {
	struct namei_ext_harness_policy policy;
	bool attached;
	bool targets_registered;
	bool parent_registered;
	bool cgroup_created;
	uint64_t cgroup_id;
};

static void json_string(FILE *out, const char *value)
{
	fputc('"', out);
	for (const unsigned char *p = (const unsigned char *)value; *p; p++) {
		switch (*p) {
		case '"':
			fputs("\\\"", out);
			break;
		case '\\':
			fputs("\\\\", out);
			break;
		case '\n':
			fputs("\\n", out);
			break;
		case '\r':
			fputs("\\r", out);
			break;
		case '\t':
			fputs("\\t", out);
			break;
		default:
			if (*p < 0x20)
				fprintf(out, "\\u%04x", *p);
			else
				fputc(*p, out);
		}
	}
	fputc('"', out);
}

static void emit_setup(FILE *out, const char *step, int error, bool pass)
{
	fputs("{\"event\":\"semantic-continuation-setup\",\"step\":", out);
	json_string(out, step);
	fprintf(out, ",\"errno\":%d,\"pass\":%s}\n", error,
		pass ? "true" : "false");
	fflush(out);
}

static int emit_operation(struct case_context *ctx, const char *operation,
			  long result, int error, const char *detail,
			  bool pass)
{
	fputs("{\"event\":\"semantic-continuation-operation\",\"arm\":",
	      ctx->out);
	json_string(ctx->out, ctx->arm);
	fputs(",\"case\":", ctx->out);
	json_string(ctx->out, ctx->id);
	fputs(",\"operation\":", ctx->out);
	json_string(ctx->out, operation);
	fprintf(ctx->out, ",\"return\":%ld,\"errno\":%d,\"detail\":",
		result, error);
	json_string(ctx->out, detail);
	fprintf(ctx->out, ",\"pass\":%s}\n", pass ? "true" : "false");
	fflush(ctx->out);
	ctx->operations++;
	if (!pass)
		ctx->failures++;
	return pass ? 0 : -EINVAL;
}

static void emit_case_summary(struct case_context *ctx)
{
	fputs("{\"event\":\"semantic-continuation-case\",\"arm\":", ctx->out);
	json_string(ctx->out, ctx->arm);
	fputs(",\"case\":", ctx->out);
	json_string(ctx->out, ctx->id);
	fprintf(ctx->out,
		",\"operations\":%u,\"failures\":%u,\"pass\":%s}\n",
		ctx->operations, ctx->failures,
		ctx->failures ? "false" : "true");
	fflush(ctx->out);
}

static int join_path(char *dst, size_t size, const char *parent,
		     const char *name)
{
	return namei_ext_path_join(dst, size, parent, name);
}

static int case_path(char *dst, size_t size, const char *root,
		     const char *id, const char *name)
{
	char base[PATH_MAX];
	int ret = join_path(base, sizeof(base), root, id);

	if (ret)
		return ret;
	if (!name || !name[0]) {
		if (strlen(base) >= size)
			return -ENAMETOOLONG;
		strcpy(dst, base);
		return 0;
	}
	return join_path(dst, size, base, name);
}

static int write_all_fd(int fd, const char *value)
{
	size_t left = strlen(value);
	const char *cursor = value;

	while (left) {
		ssize_t written = write(fd, cursor, left);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!written)
			return -EIO;
		cursor += written;
		left -= (size_t)written;
	}
	return 0;
}

static int read_file_value(const char *path, char *buffer, size_t size,
			   ssize_t *bytes_out)
{
	ssize_t total = 0;
	int fd = open(path, O_RDONLY | O_CLOEXEC);

	if (fd < 0)
		return -errno;
	while ((size_t)total + 1 < size) {
		ssize_t bytes = read(fd, buffer + total,
				     size - 1 - (size_t)total);

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			int saved = errno;
			close(fd);
			return -saved;
		}
		if (!bytes)
			break;
		total += bytes;
	}
	buffer[total] = '\0';
	if (close(fd))
		return -errno;
	*bytes_out = total;
	return 0;
}

static int directory_entries(const char *path, const char *expected,
			     unsigned int *entries_out)
{
	DIR *dir = opendir(path);
	struct dirent *entry;
	unsigned int entries = 0;
	bool seen = false;
	bool unexpected = false;

	if (!dir)
		return -errno;
	errno = 0;
	while ((entry = readdir(dir))) {
		if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
			continue;
		entries++;
		if (!strcmp(entry->d_name, expected))
			seen = true;
		else
			unexpected = true;
	}
	int saved = errno;
	if (closedir(dir) && !saved)
		saved = errno;
	*entries_out = entries;
	if (saved)
		return -saved;
	return seen && !unexpected && entries == 1 ? 0 : -EINVAL;
}

static int path_is_empty(const char *path)
{
	DIR *dir = opendir(path);
	struct dirent *entry;
	int ret = 0;

	if (!dir)
		return -errno;
	errno = 0;
	while ((entry = readdir(dir))) {
		if (strcmp(entry->d_name, ".") && strcmp(entry->d_name, "..")) {
			ret = -ENOTEMPTY;
			break;
		}
	}
	if (!ret && errno)
		ret = -errno;
	if (closedir(dir) && !ret)
		ret = -errno;
	return ret;
}

struct child_read_result {
	int error;
	ssize_t bytes;
	bool matches;
};

static int read_as_user(const char *path, uid_t uid, gid_t gid,
			const char *expected, struct child_read_result *result)
{
	int pipefd[2];
	pid_t pid;
	int status;

	if (pipe(pipefd))
		return -errno;
	pid = fork();
	if (pid < 0) {
		int saved = errno;
		close(pipefd[0]);
		close(pipefd[1]);
		return -saved;
	}
	if (!pid) {
		struct child_read_result child = {};
		char buffer[64];
		ssize_t bytes;
		int ret;

		close(pipefd[0]);
		if (setgroups(0, NULL) || setgid(gid) || setuid(uid)) {
			child.error = errno;
		} else {
			ret = read_file_value(path, buffer, sizeof(buffer), &bytes);
			child.error = ret ? -ret : 0;
			child.bytes = ret ? -1 : bytes;
			child.matches = !ret && !strcmp(buffer, expected);
		}
		ssize_t ignored = write(pipefd[1], &child, sizeof(child));
		(void)ignored;
		close(pipefd[1]);
		_exit(0);
	}
	close(pipefd[1]);
	ssize_t bytes = read(pipefd[0], result, sizeof(*result));
	int saved = errno;
	close(pipefd[0]);
	if (waitpid(pid, &status, 0) != pid)
		return -errno;
	if (bytes != sizeof(*result))
		return -(bytes < 0 ? saved : EIO);
	if (!WIFEXITED(status) || WEXITSTATUS(status))
		return -ECHILD;
	return 0;
}

static int case_s01(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	struct stat st;
	int ret = case_path(path, sizeof(path), paths->a, ctx->id, "missing");

	if (ret)
		return ret;
	errno = 0;
	ret = stat(path, &st);
	return emit_operation(ctx, "stat-missing", ret, ret ? errno : 0,
			      "ENOENT", ret == -1 && errno == ENOENT);
}

static int case_s02(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	char buffer[64];
	struct stat st;
	ssize_t bytes = -1;
	int fd = -1;
	int ret;

	if (case_path(path, sizeof(path), paths->a, ctx->id, "file"))
		return -ENAMETOOLONG;
	fd = open(path, O_CREAT | O_EXCL | O_RDWR | O_CLOEXEC, 0644);
	ret = emit_operation(ctx, "create-exclusive", fd, fd < 0 ? errno : 0,
			     "created", fd >= 0);
	if (ret)
		goto out;
	ret = write_all_fd(fd, "alpha");
	if (emit_operation(ctx, "write", ret ? -1 : 5, ret ? -ret : 0,
			   "five-bytes", !ret))
		goto out;
	if (close(fd)) {
		fd = -1;
		emit_operation(ctx, "close-after-write", -1, errno, "closed",
			       false);
		goto out;
	}
	fd = -1;
	if (stat(path, &st)) {
		emit_operation(ctx, "stat", -1, errno, "regular-0644-size-5",
			       false);
		goto out;
	}
	if (emit_operation(ctx, "stat", 0, 0, "regular-0644-size-5",
			   S_ISREG(st.st_mode) && (st.st_mode & 0777) == 0644 &&
			   st.st_size == 5))
		goto out;
	errno = 0;
	ret = access(path, R_OK | W_OK);
	if (emit_operation(ctx, "access-read-write", ret, ret ? errno : 0,
			   "allowed", ret == 0))
		goto out;
	ret = read_file_value(path, buffer, sizeof(buffer), &bytes);
	if (emit_operation(ctx, "open-read", ret ? -1 : bytes,
			   ret ? -ret : 0, "alpha",
			   !ret && bytes == 5 && !strcmp(buffer, "alpha")))
		goto out;
	errno = 0;
	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	ret = emit_operation(ctx, "create-exclusive-existing", fd,
			     fd < 0 ? errno : 0, "EEXIST",
			     fd < 0 && errno == EEXIST);
	if (fd >= 0) {
		close(fd);
		fd = -1;
	}
	if (ret)
		goto out;
	errno = 0;
	ret = unlink(path);
	if (emit_operation(ctx, "unlink", ret, ret ? errno : 0, "removed",
			   ret == 0))
		goto out;
	errno = 0;
	ret = stat(path, &st);
	emit_operation(ctx, "stat-after-unlink", ret, ret ? errno : 0,
		       "ENOENT", ret == -1 && errno == ENOENT);
out:
	if (fd >= 0)
		close(fd);
	if (ctx->failures)
		unlink(path);
	return ctx->failures ? -EINVAL : 0;
}

static int case_s03(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	struct stat st;
	int fd;
	int ret;

	if (case_path(path, sizeof(path), paths->a, ctx->id, "owned"))
		return -ENAMETOOLONG;
	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (emit_operation(ctx, "create", fd, fd < 0 ? errno : 0, "created",
			   fd >= 0))
		goto out;
	close(fd);
	errno = 0;
	ret = chmod(path, 0600);
	if (emit_operation(ctx, "chmod", ret, ret ? errno : 0, "mode-0600",
			   ret == 0))
		goto out;
	errno = 0;
	ret = chown(path, 65534, 65534);
	if (emit_operation(ctx, "chown", ret, ret ? errno : 0,
			   "uid-gid-65534", ret == 0))
		goto out;
	errno = 0;
	ret = stat(path, &st);
	if (emit_operation(ctx, "stat-owner-mode", ret, ret ? errno : 0,
			   "regular-0600-65534-65534",
			   ret == 0 && S_ISREG(st.st_mode) &&
			   (st.st_mode & 0777) == 0600 && st.st_uid == 65534 &&
			   st.st_gid == 65534))
		goto out;
	errno = 0;
	ret = unlink(path);
	emit_operation(ctx, "unlink", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures)
		unlink(path);
	return ctx->failures ? -EINVAL : 0;
}

static int case_s04(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	struct child_read_result child = {};
	int fd;
	int ret;

	if (case_path(path, sizeof(path), paths->a, ctx->id, "secret"))
		return -ENAMETOOLONG;
	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0600);
	if (emit_operation(ctx, "create-root-0600", fd, fd < 0 ? errno : 0,
			   "created", fd >= 0))
		goto out;
	ret = write_all_fd(fd, "secret");
	close(fd);
	if (emit_operation(ctx, "write-secret", ret ? -1 : 6,
			   ret ? -ret : 0, "six-bytes", !ret))
		goto out;
	ret = read_as_user(path, 65534, 65534, "secret", &child);
	if (emit_operation(ctx, "unprivileged-read-denied", ret ? -1 : -1,
			   ret ? -ret : child.error, "EACCES",
			   !ret && child.error == EACCES))
		goto out;
	errno = 0;
	ret = chmod(path, 0644);
	if (emit_operation(ctx, "chmod-0644", ret, ret ? errno : 0,
			   "mode-0644", ret == 0))
		goto out;
	memset(&child, 0, sizeof(child));
	ret = read_as_user(path, 65534, 65534, "secret", &child);
	if (emit_operation(ctx, "unprivileged-read-allowed",
			   ret ? -1 : child.bytes, ret ? -ret : child.error,
			   "secret", !ret && !child.error && child.bytes == 6 &&
			   child.matches))
		goto out;
	errno = 0;
	ret = unlink(path);
	emit_operation(ctx, "unlink", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures)
		unlink(path);
	return ctx->failures ? -EINVAL : 0;
}

static int case_s05(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	char buffer[64];
	struct stat st;
	struct timespec times[2] = {
		{ .tv_sec = 1700000000, .tv_nsec = 123456789 },
		{ .tv_sec = 1700000000, .tv_nsec = 123456789 },
	};
	ssize_t bytes = -1;
	int fd;
	int ret;

	if (case_path(path, sizeof(path), paths->a, ctx->id, "timed"))
		return -ENAMETOOLONG;
	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (emit_operation(ctx, "create", fd, fd < 0 ? errno : 0, "created",
			   fd >= 0))
		goto out;
	ret = write_all_fd(fd, "abcdefgh");
	close(fd);
	if (emit_operation(ctx, "write-eight", ret ? -1 : 8,
			   ret ? -ret : 0, "eight-bytes", !ret))
		goto out;
	errno = 0;
	ret = truncate(path, 3);
	if (emit_operation(ctx, "truncate", ret, ret ? errno : 0, "size-3",
			   ret == 0))
		goto out;
	errno = 0;
	ret = utimensat(AT_FDCWD, path, times, 0);
	if (emit_operation(ctx, "utimensat", ret, ret ? errno : 0,
			   "fixed-mtime", ret == 0))
		goto out;
	ret = read_file_value(path, buffer, sizeof(buffer), &bytes);
	if (stat(path, &st) && !ret)
		ret = -errno;
	if (emit_operation(ctx, "stat-read-after-truncate", ret ? -1 : bytes,
			   ret ? -ret : 0, "abc-size-3-fixed-mtime",
			   !ret && bytes == 3 && !strcmp(buffer, "abc") &&
			   st.st_size == 3 && st.st_mtim.tv_sec == 1700000000 &&
			   st.st_mtim.tv_nsec == 123456789))
		goto out;
	errno = 0;
	ret = unlink(path);
	emit_operation(ctx, "unlink", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures)
		unlink(path);
	return ctx->failures ? -EINVAL : 0;
}

static int case_s06(struct case_context *ctx, const struct arm_paths *paths)
{
	char dir[PATH_MAX];
	char child[PATH_MAX];
	unsigned int entries = 0;
	int fd;
	int ret;

	if (case_path(dir, sizeof(dir), paths->a, ctx->id, "dir") ||
	    join_path(child, sizeof(child), dir, "child"))
		return -ENAMETOOLONG;
	errno = 0;
	ret = mkdir(dir, 0750);
	if (emit_operation(ctx, "mkdir", ret, ret ? errno : 0, "mode-0750",
			   ret == 0))
		goto out;
	fd = open(child, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (emit_operation(ctx, "create-child", fd, fd < 0 ? errno : 0,
			   "created", fd >= 0))
		goto out;
	close(fd);
	ret = directory_entries(dir, "child", &entries);
	if (emit_operation(ctx, "readdir", ret ? -1 : (long)entries,
			   ret ? -ret : 0, "only-child", !ret))
		goto out;
	errno = 0;
	ret = unlink(child);
	if (emit_operation(ctx, "unlink-child", ret, ret ? errno : 0,
			   "removed", ret == 0))
		goto out;
	errno = 0;
	ret = rmdir(dir);
	emit_operation(ctx, "rmdir", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(child);
		rmdir(dir);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_s07(struct case_context *ctx, const struct arm_paths *paths)
{
	char path[PATH_MAX];
	struct stat st;
	int ret;

	if (case_path(path, sizeof(path), paths->a, ctx->id, "fifo"))
		return -ENAMETOOLONG;
	errno = 0;
	ret = mkfifo(path, 0640);
	if (emit_operation(ctx, "mkfifo", ret, ret ? errno : 0, "mode-0640",
			   ret == 0))
		goto out;
	errno = 0;
	ret = lstat(path, &st);
	if (emit_operation(ctx, "lstat-fifo", ret, ret ? errno : 0,
			   "fifo-0640", ret == 0 && S_ISFIFO(st.st_mode) &&
			   (st.st_mode & 0777) == 0640))
		goto out;
	errno = 0;
	ret = unlink(path);
	emit_operation(ctx, "unlink", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures)
		unlink(path);
	return ctx->failures ? -EINVAL : 0;
}

static int case_s08(struct case_context *ctx, const struct arm_paths *paths)
{
	char target[PATH_MAX];
	char linkpath[PATH_MAX];
	char buffer[64];
	struct stat st;
	ssize_t bytes = -1;
	int fd;
	int ret;

	if (case_path(target, sizeof(target), paths->a, ctx->id, "target") ||
	    case_path(linkpath, sizeof(linkpath), paths->a, ctx->id, "link"))
		return -ENAMETOOLONG;
	fd = open(target, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	if (emit_operation(ctx, "create-target", fd, fd < 0 ? errno : 0,
			   "created", fd >= 0))
		goto out;
	ret = write_all_fd(fd, "beta");
	close(fd);
	if (emit_operation(ctx, "write-target", ret ? -1 : 4,
			   ret ? -ret : 0, "beta", !ret))
		goto out;
	errno = 0;
	ret = symlink("target", linkpath);
	if (emit_operation(ctx, "symlink", ret, ret ? errno : 0,
			   "relative-target", ret == 0))
		goto out;
	errno = 0;
	ret = lstat(linkpath, &st);
	if (emit_operation(ctx, "lstat-symlink", ret, ret ? errno : 0,
			   "symlink", ret == 0 && S_ISLNK(st.st_mode)))
		goto out;
	bytes = readlink(linkpath, buffer, sizeof(buffer) - 1);
	if (bytes >= 0)
		buffer[bytes] = '\0';
	if (emit_operation(ctx, "readlink", bytes, bytes < 0 ? errno : 0,
			   "target", bytes == 6 && !strcmp(buffer, "target")))
		goto out;
	ret = read_file_value(linkpath, buffer, sizeof(buffer), &bytes);
	if (emit_operation(ctx, "follow-open-read", ret ? -1 : bytes,
			   ret ? -ret : 0, "beta",
			   !ret && bytes == 4 && !strcmp(buffer, "beta")))
		goto out;
	errno = 0;
	ret = unlink(linkpath);
	if (emit_operation(ctx, "unlink-link", ret, ret ? errno : 0,
			   "removed", ret == 0))
		goto out;
	errno = 0;
	ret = unlink(target);
	emit_operation(ctx, "unlink-target", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(linkpath);
		unlink(target);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int create_payload(const char *path, const char *payload)
{
	int fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0644);
	int ret;

	if (fd < 0)
		return -errno;
	ret = write_all_fd(fd, payload);
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int case_s09(struct case_context *ctx, const struct arm_paths *paths)
{
	char source[PATH_MAX];
	char alias[PATH_MAX];
	struct stat source_st;
	struct stat alias_st;
	int ret;

	if (case_path(source, sizeof(source), paths->a, ctx->id, "original") ||
	    case_path(alias, sizeof(alias), paths->a, ctx->id, "alias"))
		return -ENAMETOOLONG;
	ret = create_payload(source, "link-data");
	if (emit_operation(ctx, "create-source", ret ? -1 : 0,
			   ret ? -ret : 0, "link-data", !ret))
		goto out;
	errno = 0;
	ret = link(source, alias);
	if (emit_operation(ctx, "link", ret, ret ? errno : 0, "linked",
			   ret == 0))
		goto out;
	ret = stat(source, &source_st);
	if (!ret)
		ret = stat(alias, &alias_st);
	if (emit_operation(ctx, "stat-link-relation", ret ? -1 : 0,
			   ret ? errno : 0, "same-inode-nlink-2",
			   !ret && source_st.st_dev == alias_st.st_dev &&
			   source_st.st_ino == alias_st.st_ino &&
			   source_st.st_nlink == 2 && alias_st.st_nlink == 2))
		goto out;
	ret = unlink(alias);
	if (emit_operation(ctx, "unlink-alias", ret, ret ? errno : 0,
			   "removed", ret == 0))
		goto out;
	ret = stat(source, &source_st);
	if (emit_operation(ctx, "stat-link-count-one", ret, ret ? errno : 0,
			   "nlink-1", ret == 0 && source_st.st_nlink == 1))
		goto out;
	ret = unlink(source);
	emit_operation(ctx, "unlink-source", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(alias);
		unlink(source);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int read_expected(struct case_context *ctx, const char *operation,
			 const char *path, const char *expected)
{
	char buffer[64];
	ssize_t bytes = -1;
	int ret = read_file_value(path, buffer, sizeof(buffer), &bytes);

	return emit_operation(ctx, operation, ret ? -1 : bytes,
			      ret ? -ret : 0, expected,
			      !ret && bytes == (ssize_t)strlen(expected) &&
			      !strcmp(buffer, expected));
}

static int case_s10(struct case_context *ctx, const struct arm_paths *paths)
{
	char oldpath[PATH_MAX];
	char newpath[PATH_MAX];
	struct stat st;
	int ret;

	if (case_path(oldpath, sizeof(oldpath), paths->a, ctx->id, "old") ||
	    case_path(newpath, sizeof(newpath), paths->a, ctx->id, "new"))
		return -ENAMETOOLONG;
	ret = create_payload(oldpath, "rename-data");
	if (emit_operation(ctx, "create-source", ret ? -1 : 0,
			   ret ? -ret : 0, "rename-data", !ret))
		goto out;
	errno = 0;
	ret = rename(oldpath, newpath);
	if (emit_operation(ctx, "rename", ret, ret ? errno : 0, "renamed",
			   ret == 0))
		goto out;
	errno = 0;
	ret = stat(oldpath, &st);
	if (emit_operation(ctx, "stat-old", ret, ret ? errno : 0, "ENOENT",
			   ret == -1 && errno == ENOENT))
		goto out;
	if (read_expected(ctx, "read-new", newpath, "rename-data"))
		goto out;
	ret = unlink(newpath);
	emit_operation(ctx, "unlink-new", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(oldpath);
		unlink(newpath);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_s11(struct case_context *ctx, const struct arm_paths *paths)
{
	char source[PATH_MAX];
	char destination[PATH_MAX];
	struct stat st;
	int ret;

	if (case_path(source, sizeof(source), paths->a, ctx->id, "src") ||
	    case_path(destination, sizeof(destination), paths->b, ctx->id,
		      "dst"))
		return -ENAMETOOLONG;
	ret = create_payload(source, "cross-rename");
	if (emit_operation(ctx, "create-source", ret ? -1 : 0,
			   ret ? -ret : 0, "cross-rename", !ret))
		goto out;
	errno = 0;
	ret = rename(source, destination);
	if (emit_operation(ctx, "rename-a-to-b", ret, ret ? errno : 0,
			   "same-ext4-success", ret == 0))
		goto out;
	errno = 0;
	ret = stat(source, &st);
	if (emit_operation(ctx, "stat-source", ret, ret ? errno : 0,
			   "ENOENT", ret == -1 && errno == ENOENT))
		goto out;
	if (read_expected(ctx, "read-destination", destination,
			  "cross-rename"))
		goto out;
	ret = unlink(destination);
	emit_operation(ctx, "unlink-destination", ret, ret ? errno : 0,
		       "removed", ret == 0);
out:
	if (ctx->failures) {
		unlink(source);
		unlink(destination);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_s12(struct case_context *ctx, const struct arm_paths *paths)
{
	char source[PATH_MAX];
	char destination[PATH_MAX];
	struct stat source_st;
	struct stat destination_st;
	int ret;

	if (case_path(source, sizeof(source), paths->a, ctx->id, "src") ||
	    case_path(destination, sizeof(destination), paths->b, ctx->id,
		      "dst"))
		return -ENAMETOOLONG;
	ret = create_payload(source, "cross-link");
	if (emit_operation(ctx, "create-source", ret ? -1 : 0,
			   ret ? -ret : 0, "cross-link", !ret))
		goto out;
	errno = 0;
	ret = link(source, destination);
	if (emit_operation(ctx, "link-a-to-b", ret, ret ? errno : 0,
			   "same-ext4-success", ret == 0))
		goto out;
	ret = stat(source, &source_st);
	if (!ret)
		ret = stat(destination, &destination_st);
	if (emit_operation(ctx, "stat-link-relation", ret ? -1 : 0,
			   ret ? errno : 0, "same-inode-nlink-2",
			   !ret && source_st.st_dev == destination_st.st_dev &&
			   source_st.st_ino == destination_st.st_ino &&
			   source_st.st_nlink == 2 && destination_st.st_nlink == 2))
		goto out;
	ret = unlink(destination);
	if (emit_operation(ctx, "unlink-destination", ret, ret ? errno : 0,
			   "removed", ret == 0))
		goto out;
	ret = unlink(source);
	emit_operation(ctx, "unlink-source", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(destination);
		unlink(source);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_crossfs(struct case_context *ctx,
			const struct arm_paths *paths, bool rename_case)
{
	char source[PATH_MAX];
	char destination[PATH_MAX];
	struct stat st;
	int ret;

	if (case_path(source, sizeof(source), paths->a, ctx->id, "src") ||
	    case_path(destination, sizeof(destination), paths->x, ctx->id,
		      "dst"))
		return -ENAMETOOLONG;
	ret = create_payload(source, "cross-fs");
	if (emit_operation(ctx, "create-source", ret ? -1 : 0,
			   ret ? -ret : 0, "cross-fs", !ret))
		goto out;
	errno = 0;
	ret = rename_case ? rename(source, destination) : link(source, destination);
	if (emit_operation(ctx, rename_case ? "rename-ext4-to-tmpfs" :
					       "link-ext4-to-tmpfs",
			   ret, ret ? errno : 0, "EXDEV",
			   ret == -1 && errno == EXDEV))
		goto out;
	if (read_expected(ctx, "read-source-unchanged", source, "cross-fs"))
		goto out;
	errno = 0;
	ret = stat(destination, &st);
	if (emit_operation(ctx, "stat-destination", ret, ret ? errno : 0,
			   "ENOENT", ret == -1 && errno == ENOENT))
		goto out;
	ret = unlink(source);
	emit_operation(ctx, "unlink-source", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (ctx->failures) {
		unlink(destination);
		unlink(source);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_s15(struct case_context *ctx, const struct arm_paths *paths)
{
	return read_expected(ctx, "read-unmanaged", paths->unmanaged,
			     "ordinary-lower");
}

static int dirfd_operations(struct case_context *ctx, int dirfd)
{
	char buffer[16] = {};
	int fd = openat(dirfd, "fdfile", O_CREAT | O_EXCL | O_RDWR | O_CLOEXEC,
			0644);
	int ret;
	ssize_t bytes;

	if (emit_operation(ctx, "openat-create", fd, fd < 0 ? errno : 0,
			   "created", fd >= 0))
		goto out;
	ret = write_all_fd(fd, "fd-data");
	if (emit_operation(ctx, "write-via-fd", ret ? -1 : 7,
			   ret ? -ret : 0, "fd-data", !ret))
		goto out;
	if (lseek(fd, 0, SEEK_SET) < 0) {
		emit_operation(ctx, "seek-via-fd", -1, errno, "offset-zero",
			       false);
		goto out;
	}
	bytes = read(fd, buffer, sizeof(buffer) - 1);
	if (bytes >= 0)
		buffer[bytes] = '\0';
	if (emit_operation(ctx, "read-via-fd", bytes,
			   bytes < 0 ? errno : 0, "fd-data",
			   bytes == 7 && !strcmp(buffer, "fd-data")))
		goto out;
	close(fd);
	fd = -1;
	errno = 0;
	ret = renameat(dirfd, "fdfile", dirfd, "fdnew");
	if (emit_operation(ctx, "renameat", ret, ret ? errno : 0, "renamed",
			   ret == 0))
		goto out;
	errno = 0;
	ret = unlinkat(dirfd, "fdnew", 0);
	emit_operation(ctx, "unlinkat", ret, ret ? errno : 0, "removed",
		       ret == 0);
out:
	if (fd >= 0)
		close(fd);
	if (ctx->failures) {
		unlinkat(dirfd, "fdfile", 0);
		unlinkat(dirfd, "fdnew", 0);
	}
	return ctx->failures ? -EINVAL : 0;
}

static int case_s16_direct(struct case_context *ctx,
			   const struct arm_paths *paths)
{
	char path[PATH_MAX];
	int dirfd;

	if (case_path(path, sizeof(path), paths->a, ctx->id, NULL))
		return -ENAMETOOLONG;
	dirfd = open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (emit_operation(ctx, "open-directory", dirfd,
			   dirfd < 0 ? errno : 0, "opened", dirfd >= 0))
		return -EINVAL;
	int ret = dirfd_operations(ctx, dirfd);
	close(dirfd);
	return ret;
}

static int run_case(struct case_context *ctx, const struct arm_paths *paths,
		    unsigned int number)
{
	switch (number) {
	case 1:
		return case_s01(ctx, paths);
	case 2:
		return case_s02(ctx, paths);
	case 3:
		return case_s03(ctx, paths);
	case 4:
		return case_s04(ctx, paths);
	case 5:
		return case_s05(ctx, paths);
	case 6:
		return case_s06(ctx, paths);
	case 7:
		return case_s07(ctx, paths);
	case 8:
		return case_s08(ctx, paths);
	case 9:
		return case_s09(ctx, paths);
	case 10:
		return case_s10(ctx, paths);
	case 11:
		return case_s11(ctx, paths);
	case 12:
		return case_s12(ctx, paths);
	case 13:
		return case_crossfs(ctx, paths, true);
	case 14:
		return case_crossfs(ctx, paths, false);
	case 15:
		return case_s15(ctx, paths);
	case 16:
		return case_s16_direct(ctx, paths);
	default:
		return -EINVAL;
	}
}

static void case_id(char *buffer, size_t size, unsigned int number)
{
	snprintf(buffer, size, "S%02u", number);
}

static int create_dir(const char *path, mode_t mode)
{
	if (mkdir(path, mode) && errno != EEXIST)
		return -errno;
	return 0;
}

static int prepare_arm_roots(struct arm_paths *paths, const char *prefix,
			     const char *ext4_root, const char *tmpfs_root)
{
	char ext4_arm[PATH_MAX];
	char tmpfs_arm[PATH_MAX];
	int ret;

	ret = join_path(ext4_arm, sizeof(ext4_arm), ext4_root, prefix);
	if (!ret)
		ret = join_path(tmpfs_arm, sizeof(tmpfs_arm), tmpfs_root, prefix);
	if (!ret)
		ret = create_dir(ext4_arm, 0755);
	if (!ret)
		ret = create_dir(tmpfs_arm, 0755);
	if (!ret)
		ret = join_path(paths->a, sizeof(paths->a), ext4_arm, "a");
	if (!ret)
		ret = join_path(paths->b, sizeof(paths->b), ext4_arm, "b");
	if (!ret)
		ret = join_path(paths->x, sizeof(paths->x), tmpfs_arm, "x");
	if (!ret)
		ret = create_dir(paths->a, 0755);
	if (!ret)
		ret = create_dir(paths->b, 0755);
	if (!ret)
		ret = create_dir(paths->x, 0755);
	return ret;
}

static int prepare_case_dirs(const struct arm_paths *paths)
{
	char id[8];
	char path[PATH_MAX];

	for (unsigned int number = 1; number <= CASE_COUNT; number++) {
		case_id(id, sizeof(id), number);
		const char *roots[] = { paths->a, paths->b, paths->x };

		for (size_t root = 0; root < ARRAY_SIZE(roots); root++) {
			if (case_path(path, sizeof(path), roots[root], id, NULL))
				return -ENAMETOOLONG;
			if (mkdir(path, 0755))
				return -errno;
		}
	}
	return 0;
}

static int prepare_fixture(struct fixture *fixture, const char *ext4_root,
			   const char *tmpfs_root, const char *logical,
			   const char *cgroup_root)
{
	char path[PATH_MAX];
	int ret = prepare_arm_roots(&fixture->direct, "direct", ext4_root,
				    tmpfs_root);

	if (!ret)
		ret = prepare_arm_roots(&fixture->selected, "selected", ext4_root,
					tmpfs_root);
	if (!ret)
		ret = prepare_case_dirs(&fixture->direct);
	if (!ret)
		ret = prepare_case_dirs(&fixture->selected);
	if (!ret && strlen(logical) >= sizeof(fixture->logical))
		ret = -ENAMETOOLONG;
	if (!ret)
		strcpy(fixture->logical, logical);
	if (!ret)
		ret = create_dir(fixture->logical, 0755);
	const char *names[] = { "a", "b", "x" };
	for (size_t i = 0; !ret && i < ARRAY_SIZE(names); i++) {
		ret = join_path(path, sizeof(path), fixture->logical, names[i]);
		if (!ret)
			ret = create_dir(path, 0755);
	}
	if (!ret)
		ret = join_path(fixture->selected.a,
				sizeof(fixture->selected.a), fixture->logical, "a");
	if (!ret)
		ret = join_path(fixture->selected.b,
				sizeof(fixture->selected.b), fixture->logical, "b");
	if (!ret)
		ret = join_path(fixture->selected.x,
				sizeof(fixture->selected.x), fixture->logical, "x");
	if (!ret)
		ret = join_path(fixture->selected.unmanaged,
				sizeof(fixture->selected.unmanaged), fixture->logical,
				"unmanaged");
	if (!ret)
		ret = namei_ext_write_text(fixture->selected.unmanaged,
					"ordinary-lower");
	if (!ret && strlen(fixture->selected.unmanaged) >=
			   sizeof(fixture->direct.unmanaged))
		ret = -ENAMETOOLONG;
	if (!ret)
		strcpy(fixture->direct.unmanaged, fixture->selected.unmanaged);
	if (!ret && strlen(fixture->selected_a_lower) == 0) {
		char selected_ext4[PATH_MAX];
		char selected_tmpfs[PATH_MAX];

		ret = join_path(selected_ext4, sizeof(selected_ext4), ext4_root,
				"selected");
		if (!ret)
			ret = join_path(selected_tmpfs, sizeof(selected_tmpfs),
					tmpfs_root, "selected");
		if (!ret)
			ret = join_path(fixture->selected_a_lower,
					sizeof(fixture->selected_a_lower),
					selected_ext4, "a");
		if (!ret)
			ret = join_path(fixture->selected_b_lower,
					sizeof(fixture->selected_b_lower),
					selected_ext4, "b");
		if (!ret)
			ret = join_path(fixture->selected_x_lower,
					sizeof(fixture->selected_x_lower),
					selected_tmpfs, "x");
	}
	if (!ret)
		ret = join_path(fixture->cgroup, sizeof(fixture->cgroup),
				cgroup_root, "namei-ext-semantic-continuation");
	return ret;
}

static int configure_policy(FILE *out, const char *policy_object,
			    const char *cgroup_root, struct fixture *fixture,
			    struct policy_state *state)
{
	int ret = create_dir(fixture->cgroup, 0755);

	if (!ret)
		state->cgroup_created = true;
	if (!ret)
		ret = namei_ext_cgroup_id(fixture->cgroup, &state->cgroup_id);
	if (!ret)
		ret = namei_ext_register_target(fixture->cgroup,
					       fixture->selected_a_lower, TARGET_A);
	if (!ret)
		state->targets_registered = true;
	if (!ret)
		ret = namei_ext_register_target(fixture->cgroup,
					       fixture->selected_b_lower, TARGET_B);
	if (!ret)
		ret = namei_ext_register_target(fixture->cgroup,
					       fixture->selected_x_lower, TARGET_X);
	if (!ret)
		ret = namei_ext_policy_parent_exact(fixture->cgroup,
						 fixture->logical);
	if (!ret)
		state->parent_registered = true;
	if (!ret && namei_ext_policy_load_attach(policy_object, cgroup_root,
						  &state->policy))
		ret = -errno;
	if (!ret)
		state->attached = true;
	const char *names[] = { "a", "b", "x" };
	const uint32_t targets[] = { TARGET_A, TARGET_B, TARGET_X };
	for (size_t i = 0; !ret && i < ARRAY_SIZE(names); i++)
		ret = namei_ext_component_map_update(
			&state->policy, "semantic_continuation_views",
			state->cgroup_id, fixture->logical, names[i], targets[i]);
	emit_setup(out, "configure-policy", ret ? -ret : 0, !ret);
	return ret;
}

static int read_counters(struct policy_state *state,
			 struct counter_snapshot *snapshot)
{
	int ret = namei_ext_policy_counter(&state->policy,
			"semantic_continuation_counters", SC_COUNTER_PASS,
			&snapshot->pass);

	for (uint32_t target = 1; !ret && target < TARGET_MAX; target++)
		ret = namei_ext_policy_counter(
			&state->policy, "semantic_continuation_target_hits",
			target, &snapshot->target[target]);
	return ret;
}

static unsigned int expected_target_mask(unsigned int number)
{
	switch (number) {
	case 11:
	case 12:
		return (1U << TARGET_A) | (1U << TARGET_B);
	case 13:
	case 14:
		return (1U << TARGET_A) | (1U << TARGET_X);
	case 15:
		return 0;
	default:
		return 1U << TARGET_A;
	}
}

static bool emit_engagement(FILE *out, const char *id,
			    const struct counter_snapshot *before,
			    const struct counter_snapshot *after,
			    unsigned int expected_mask, int counter_error)
{
	bool pass = !counter_error;
	uint64_t delta[TARGET_MAX] = {};

	for (unsigned int target = 1; target < TARGET_MAX; target++) {
		delta[target] = after->target[target] - before->target[target];
		if (expected_mask & (1U << target))
			pass = pass && delta[target] > 0;
		else
			pass = pass && delta[target] == 0;
	}
	uint64_t pass_delta = after->pass - before->pass;
	if (!expected_mask)
		pass = pass && pass_delta > 0;
	fputs("{\"event\":\"semantic-continuation-engagement\",\"arm\":\"selected\",\"case\":",
	      out);
	json_string(out, id);
	fprintf(out,
		",\"expected_target_mask\":%u,\"target_a_delta\":%" PRIu64
		",\"target_b_delta\":%" PRIu64
		",\"target_x_delta\":%" PRIu64
		",\"pass_delta\":%" PRIu64
		",\"counter_errno\":%d,\"pass\":%s}\n",
		expected_mask, delta[TARGET_A], delta[TARGET_B], delta[TARGET_X],
		pass_delta, counter_error, pass ? "true" : "false");
	fflush(out);
	return pass;
}

static int wait_status(pid_t pid)
{
	int status;

	if (waitpid(pid, &status, 0) != pid)
		return -errno;
	if (!WIFEXITED(status))
		return -ECHILD;
	return WEXITSTATUS(status) ? -EINVAL : 0;
}

static int run_case_child(FILE *out, const char *arm,
			  const struct arm_paths *paths, unsigned int number,
			  const char *cgroup)
{
	char id[8];
	pid_t pid;

	case_id(id, sizeof(id), number);
	fflush(out);
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		struct case_context ctx = {
			.out = out,
			.arm = arm,
			.id = id,
		};
		int ret = 0;

		if (cgroup)
			ret = namei_ext_move_self_to_cgroup(cgroup);
		if (!ret)
			ret = run_case(&ctx, paths, number);
		if (ret && !ctx.failures) {
			emit_operation(&ctx, "runner-error", -1, -ret,
				       "case-runner-error", false);
		}
		emit_case_summary(&ctx);
		fflush(out);
		_exit(ctx.failures || ret ? 1 : 0);
	}
	return wait_status(pid);
}

static int emit_residual(FILE *out, const char *arm, const char *id,
			 const struct arm_paths *physical)
{
	const char *roots[] = { physical->a, physical->b, physical->x };
	bool pass = true;
	int error = 0;
	char path[PATH_MAX];

	for (size_t i = 0; i < ARRAY_SIZE(roots); i++) {
		if (case_path(path, sizeof(path), roots[i], id, NULL)) {
			pass = false;
			error = ENAMETOOLONG;
			break;
		}
		int ret = path_is_empty(path);
		if (ret) {
			pass = false;
			error = -ret;
			break;
		}
	}
	fputs("{\"event\":\"semantic-continuation-residual\",\"arm\":", out);
	json_string(out, arm);
	fputs(",\"case\":", out);
	json_string(out, id);
	fprintf(out, ",\"errno\":%d,\"pass\":%s}\n", error,
		pass ? "true" : "false");
	fflush(out);
	return pass ? 0 : -error;
}

static int write_pid_to_cgroup(const char *cgroup, pid_t pid)
{
	char path[PATH_MAX];
	char value[32];
	int length;
	int fd;

	if (join_path(path, sizeof(path), cgroup, "cgroup.procs"))
		return -ENAMETOOLONG;
	length = snprintf(value, sizeof(value), "%ld\n", (long)pid);
	if (length <= 0 || (size_t)length >= sizeof(value))
		return -EINVAL;
	fd = open(path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	ssize_t written = write(fd, value, (size_t)length);
	int saved = errno;
	if (close(fd) && written == length)
		return -errno;
	return written == length ? 0 : -(written < 0 ? saved : EIO);
}

static int teardown_policy(FILE *out, const char *cgroup_root,
			   struct fixture *fixture, struct policy_state *state,
			   pid_t child)
{
	int first = 0;
	int ret;

	if (state->parent_registered) {
		ret = namei_ext_policy_parent_clear(fixture->cgroup);
		if (ret && !first)
			first = ret;
		else if (!ret)
			state->parent_registered = false;
	}
	if (state->targets_registered) {
		ret = namei_ext_clear_targets(fixture->cgroup);
		if (ret && !first)
			first = ret;
		else if (!ret)
			state->targets_registered = false;
	}
	if (state->attached) {
		ret = namei_ext_policy_destroy(&state->policy);
		if (ret && !first)
			first = ret;
		else if (!ret)
			state->attached = false;
	}
	if (child > 0) {
		ret = write_pid_to_cgroup(cgroup_root, child);
		if (ret && !first)
			first = ret;
	}
	if (state->cgroup_created) {
		ret = rmdir(fixture->cgroup) ? -errno : 0;
		if (ret && !first)
			first = ret;
		else if (!ret)
			state->cgroup_created = false;
	}
	emit_setup(out, child > 0 ? "teardown-policy-before-dirfd" :
				      "teardown-policy",
		   first ? -first : 0, !first);
	return first;
}

static int run_selected_s16(FILE *out, const struct arm_paths *logical_paths,
			    const struct arm_paths *physical_paths,
			    const char *cgroup_root, struct fixture *fixture,
			    struct policy_state *state)
{
	struct counter_snapshot before = {};
	struct counter_snapshot after = {};
	char logical[PATH_MAX];
	char lower[PATH_MAX];
	char id[] = "S16";
	int ready[2];
	int go[2];
	pid_t pid;
	int ret;
	int counter_error;

	if (case_path(logical, sizeof(logical), logical_paths->a, id, NULL) ||
	    case_path(lower, sizeof(lower), physical_paths->a, id, NULL))
		return -ENAMETOOLONG;
	counter_error = read_counters(state, &before);
	if (pipe(ready) || pipe(go))
		return -errno;
	fflush(out);
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		struct case_context ctx = {
			.out = out,
			.arm = "selected",
			.id = id,
		};
		struct stat actual = {};
		struct stat expected = {};
		char signal = 'R';
		int dirfd = -1;
		int child_ret = namei_ext_move_self_to_cgroup(fixture->cgroup);

		close(ready[0]);
		close(go[1]);
		if (!child_ret)
			dirfd = open(logical, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
		if (dirfd < 0 && !child_ret)
			child_ret = -errno;
		if (!child_ret && (fstat(dirfd, &actual) || stat(lower, &expected)))
			child_ret = -errno;
		bool identity = !child_ret && actual.st_dev == expected.st_dev &&
			actual.st_ino == expected.st_ino;
		emit_operation(&ctx, "open-directory", dirfd,
			       child_ret ? -child_ret : 0,
			       "selected-lower-identity", identity);
		if (write(ready[1], &signal, 1) != 1)
			child_ret = -EIO;
		close(ready[1]);
		if (read(go[0], &signal, 1) != 1 || signal != 'G')
			child_ret = -EIO;
		close(go[0]);
		if (!child_ret)
			child_ret = dirfd_operations(&ctx, dirfd);
		if (dirfd >= 0)
			close(dirfd);
		emit_case_summary(&ctx);
		fflush(out);
		_exit(child_ret || ctx.failures ? 1 : 0);
	}
	close(ready[1]);
	close(go[0]);
	char signal;
	ret = read(ready[0], &signal, 1) == 1 && signal == 'R' ? 0 : -EIO;
	close(ready[0]);
	if (!ret) {
		int snapshot_ret = read_counters(state, &after);
		if (!counter_error)
			counter_error = snapshot_ret;
		if (!emit_engagement(out, id, &before, &after,
				     1U << TARGET_A,
				     counter_error ? -counter_error : 0))
			ret = -EINVAL;
	}
	int teardown_ret = teardown_policy(out, cgroup_root, fixture, state, pid);
	if (!ret && teardown_ret)
		ret = teardown_ret;
	signal = ret ? 'F' : 'G';
	if (write(go[1], &signal, 1) != 1 && !ret)
		ret = -EIO;
	close(go[1]);
	int wait_ret = wait_status(pid);
	if (!ret && wait_ret)
		ret = wait_ret;
	int residual_ret = emit_residual(out, "selected", id, physical_paths);
	if (!ret && residual_ret)
		ret = residual_ret;
	return ret;
}

static int run_arm(FILE *out, const char *arm,
		   const struct arm_paths *logical_paths,
		   const struct arm_paths *physical_paths,
		   const unsigned int *cases, size_t case_count,
		   const char *cgroup_root, struct fixture *fixture,
		   struct policy_state *state)
{
	int failures = 0;

	for (size_t i = 0; i < case_count; i++) {
		unsigned int number = cases[i];
		char id[8];
		int ret;

		case_id(id, sizeof(id), number);
		if (!strcmp(arm, "selected") && number == 16) {
			ret = run_selected_s16(out, logical_paths, physical_paths,
					       cgroup_root, fixture, state);
		} else if (!strcmp(arm, "selected")) {
			struct counter_snapshot before = {};
			struct counter_snapshot after = {};
			int counter_error = read_counters(state, &before);

			ret = run_case_child(out, arm, logical_paths, number,
					     fixture->cgroup);
			int snapshot_ret = read_counters(state, &after);
			if (!counter_error)
				counter_error = snapshot_ret;
			bool engaged = emit_engagement(
				out, id, &before, &after,
				expected_target_mask(number),
				counter_error ? -counter_error : 0);
			if (!ret && !engaged)
				ret = -EINVAL;
		} else {
			ret = run_case_child(out, arm, physical_paths, number, NULL);
		}
		int residual_ret = 0;
		if (!(!strcmp(arm, "selected") && number == 16))
			residual_ret = emit_residual(out, arm, id, physical_paths);
		if (ret || residual_ret)
			failures++;
	}
	return failures ? -EINVAL : 0;
}

static int remove_case_dirs(const struct arm_paths *paths)
{
	char id[8];
	char path[PATH_MAX];
	const char *roots[] = { paths->a, paths->b, paths->x };

	for (unsigned int number = CASE_COUNT; number > 0; number--) {
		case_id(id, sizeof(id), number);
		for (size_t root = 0; root < ARRAY_SIZE(roots); root++) {
			if (case_path(path, sizeof(path), roots[root], id, NULL))
				return -ENAMETOOLONG;
			if (rmdir(path))
				return -errno;
		}
	}
	return 0;
}

static int cleanup_fixture(struct fixture *fixture, const char *ext4_root,
			   const char *tmpfs_root)
{
	char path[PATH_MAX];
	int ret = remove_case_dirs(&fixture->direct);

	/* selected logical paths point at placeholders; use lower roots directly. */
	struct arm_paths selected_lower = {};
	if (!ret && (strlen(fixture->selected_a_lower) >= sizeof(selected_lower.a) ||
		     strlen(fixture->selected_b_lower) >= sizeof(selected_lower.b) ||
		     strlen(fixture->selected_x_lower) >= sizeof(selected_lower.x)))
		ret = -ENAMETOOLONG;
	if (!ret) {
		strcpy(selected_lower.a, fixture->selected_a_lower);
		strcpy(selected_lower.b, fixture->selected_b_lower);
		strcpy(selected_lower.x, fixture->selected_x_lower);
		ret = remove_case_dirs(&selected_lower);
	}
	if (!ret)
		ret = unlink(fixture->selected.unmanaged) ? -errno : 0;
	const char *logical_names[] = { "a", "b", "x" };
	for (size_t i = 0; !ret && i < ARRAY_SIZE(logical_names); i++) {
		ret = join_path(path, sizeof(path), fixture->logical,
				logical_names[i]);
		if (!ret && rmdir(path))
			ret = -errno;
	}
	if (!ret && rmdir(fixture->logical))
		ret = -errno;
	const char *arms[] = { "direct", "selected" };
	for (size_t i = 0; !ret && i < ARRAY_SIZE(arms); i++) {
		char ext4_arm[PATH_MAX];
		char tmpfs_arm[PATH_MAX];
		ret = join_path(ext4_arm, sizeof(ext4_arm), ext4_root, arms[i]);
		if (!ret)
			ret = join_path(tmpfs_arm, sizeof(tmpfs_arm), tmpfs_root,
					arms[i]);
		const char *ext4_children[] = { "a", "b" };
		for (size_t child = 0; !ret && child < ARRAY_SIZE(ext4_children);
		     child++) {
			ret = join_path(path, sizeof(path), ext4_arm,
					ext4_children[child]);
			if (!ret && rmdir(path))
				ret = -errno;
		}
		if (!ret) {
			ret = join_path(path, sizeof(path), tmpfs_arm, "x");
			if (!ret && rmdir(path))
				ret = -errno;
		}
		if (!ret && rmdir(ext4_arm))
			ret = -errno;
		if (!ret && rmdir(tmpfs_arm))
			ret = -errno;
	}
	return ret;
}

int main(int argc, char **argv)
{
	static const unsigned int preflight_cases[] = { 2, 11 };
	static const unsigned int formal_cases[] = {
		1, 2, 3, 4, 5, 6, 7, 8,
		9, 10, 11, 12, 13, 14, 15, 16,
	};
	struct fixture fixture = {};
	struct arm_paths selected_lower = {};
	struct policy_state state = {
		.policy = { .cgroup_fd = -1, .prog_fd = -1 },
	};
	const unsigned int *cases;
	size_t case_count;
	bool direct_first;
	FILE *out;
	int failures = 0;
	int ret;

	if (argc != 9) {
		fprintf(stderr,
			"usage: %s POLICY OUTPUT CGROUP_ROOT EXT4_ROOT TMPFS_ROOT LOGICAL_ROOT PROFILE ORDER\n",
			argv[0]);
		return 2;
	}
	if (!strcmp(argv[7], "preflight")) {
		cases = preflight_cases;
		case_count = ARRAY_SIZE(preflight_cases);
	} else if (!strcmp(argv[7], "formal")) {
		cases = formal_cases;
		case_count = ARRAY_SIZE(formal_cases);
	} else {
		fprintf(stderr, "invalid profile: %s\n", argv[7]);
		return 2;
	}
	if (!strcmp(argv[8], "direct-selected"))
		direct_first = true;
	else if (!strcmp(argv[8], "selected-direct"))
		direct_first = false;
	else {
		fprintf(stderr, "invalid order: %s\n", argv[8]);
		return 2;
	}
	out = fopen(argv[2], "w");
	if (!out) {
		perror("fopen output");
		return 1;
	}
	setvbuf(out, NULL, _IOLBF, 0);
	ret = prepare_fixture(&fixture, argv[4], argv[5], argv[6], argv[3]);
	emit_setup(out, "prepare-fixture", ret ? -ret : 0, !ret);
	if (ret) {
		fclose(out);
		return 1;
	}
	ret = configure_policy(out, argv[1], argv[3], &fixture, &state);
	if (ret) {
		teardown_policy(out, argv[3], &fixture, &state, 0);
		cleanup_fixture(&fixture, argv[4], argv[5]);
		fclose(out);
		return 1;
	}
	if (strlen(fixture.selected_a_lower) >= sizeof(selected_lower.a) ||
	    strlen(fixture.selected_b_lower) >= sizeof(selected_lower.b) ||
	    strlen(fixture.selected_x_lower) >= sizeof(selected_lower.x)) {
		emit_setup(out, "selected-lower-paths", ENAMETOOLONG, false);
		teardown_policy(out, argv[3], &fixture, &state, 0);
		cleanup_fixture(&fixture, argv[4], argv[5]);
		fclose(out);
		return 1;
	}
	strcpy(selected_lower.a, fixture.selected_a_lower);
	strcpy(selected_lower.b, fixture.selected_b_lower);
	strcpy(selected_lower.x, fixture.selected_x_lower);
	emit_setup(out, "selected-lower-paths", 0, true);

	if (direct_first) {
		failures += !!run_arm(out, "direct", &fixture.direct,
				      &fixture.direct, cases, case_count, argv[3],
				      &fixture, &state);
		failures += !!run_arm(out, "selected", &fixture.selected,
				      &selected_lower, cases, case_count, argv[3],
				      &fixture, &state);
	} else {
		failures += !!run_arm(out, "selected", &fixture.selected,
				      &selected_lower, cases, case_count, argv[3],
				      &fixture, &state);
		failures += !!run_arm(out, "direct", &fixture.direct,
				      &fixture.direct, cases, case_count, argv[3],
				      &fixture, &state);
	}

	if (state.attached || state.targets_registered ||
	    state.parent_registered || state.cgroup_created) {
		ret = teardown_policy(out, argv[3], &fixture, &state, 0);
		failures += !!ret;
	}
	ret = cleanup_fixture(&fixture, argv[4], argv[5]);
	emit_setup(out, "cleanup-fixture", ret ? -ret : 0, !ret);
	failures += !!ret;
	fprintf(out,
		"{\"event\":\"semantic-continuation-summary\",\"profile\":\"%s\",\"order\":\"%s\",\"expected_cases_per_arm\":%zu,\"failures\":%d,\"pass\":%s}\n",
		argv[7], argv[8], case_count, failures,
		failures ? "false" : "true");
	if (fclose(out))
		return 1;
	return failures ? 1 : 0;
}
