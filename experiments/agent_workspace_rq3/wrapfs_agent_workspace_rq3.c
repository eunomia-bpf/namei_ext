// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "semantic_oracles.h"

struct runner {
	FILE *out;
	unsigned long long method_sequence;
	bool module_loaded;
	bool mounted;
	bool result_failed;
	char visible[PATH_MAX];
	char fixture_root[PATH_MAX];
};

struct workspace_paths {
	char base[PATH_MAX];
	char upper[PATH_MAX];
	char base_src[PATH_MAX];
	char upper_src[PATH_MAX];
	char base_git[PATH_MAX];
	char upper_git[PATH_MAX];
	char base_main[PATH_MAX];
	char upper_main[PATH_MAX];
	char base_deleted[PATH_MAX];
	char upper_deleted[PATH_MAX];
	char base_link[PATH_MAX];
	char upper_link[PATH_MAX];
	char base_src_app[PATH_MAX];
	char upper_src_app[PATH_MAX];
	char base_git_head[PATH_MAX];
	char upper_git_head[PATH_MAX];
	char base_generated[PATH_MAX];
	char upper_generated[PATH_MAX];
	char base_tool[PATH_MAX];
	char upper_tool[PATH_MAX];
	char base_denied[PATH_MAX];
	char upper_denied[PATH_MAX];
	char upper_renamed[PATH_MAX];
	char base_cached_negative[PATH_MAX];
	char upper_cached_negative[PATH_MAX];
	char visible_main[PATH_MAX];
	char visible_deleted[PATH_MAX];
	char visible_link[PATH_MAX];
	char visible_src_app[PATH_MAX];
	char visible_git_head[PATH_MAX];
	char visible_generated[PATH_MAX];
	char visible_tool[PATH_MAX];
	char visible_denied[PATH_MAX];
	char visible_renamed[PATH_MAX];
	char visible_cached_negative[PATH_MAX];
};

struct directory_view {
	bool main;
	bool deleted;
	bool link;
	bool generated;
	bool renamed;
	bool cached_negative;
	bool src;
	bool git;
};

struct lower_manifest {
	bool base_main_preserved;
	bool base_deleted_preserved;
	bool base_src_preserved;
	bool base_git_preserved;
	bool base_symlink_preserved;
	bool base_generated_absent;
	bool base_cached_negative_absent;
	bool upper_main_preserved;
	bool upper_deleted_preserved;
	bool upper_src_preserved;
	bool upper_git_preserved;
	bool upper_symlink_preserved;
	bool upper_generated_present;
	bool upper_renamed_absent;
	bool upper_cached_negative_absent;
	bool visible_main;
	bool visible_deleted;
	bool visible_generated;
	bool visible_cached_negative;
};

static int json_flush(struct runner *run)
{
	if (fflush(run->out)) {
		run->result_failed = true;
		return -1;
	}
	return 0;
}

static int emit_semantic_oracle(struct runner *run, const char *name,
				 bool pass, int err)
{
	const struct rq3_semantic_contract *contract;
	int written;

	contract = rq3_semantic_contract_for_case(name, false);
	if (!contract)
		return 0;
	written = fprintf(run->out,
			  "{\"event\":\"rq3-semantic-oracle\","
			  "\"result_level\":\"kvm_agent_workspace_rq3\","
			  "\"condition\":\"wrapfs\",\"oracle_id\":\"%s\","
			  "\"case\":\"%s\",\"operation\":\"%s\","
			  "\"expected\":\"%s\",\"pass\":%s,\"errno\":%d}\n",
			  contract->oracle_id, name, contract->operation,
			  contract->expected, pass ? "true" : "false", err);
	if (written < 0) {
		run->result_failed = true;
		return -1;
	}
	return 0;
}

static int emit_case(struct runner *run, const char *name, bool pass, int err,
		     const char *detail)
{
	int written;

	written = fprintf(run->out,
			  "{\"event\":\"rq3-wrapfs-case\","
			  "\"result_level\":\"kvm_agent_workspace_rq3\","
			  "\"case\":\"%s\",\"pass\":%s,\"errno\":%d,"
			  "\"detail\":\"%s\"}\n",
			  name, pass ? "true" : "false", err, detail);
	if (written < 0) {
		run->result_failed = true;
		return -1;
	}
	if (emit_semantic_oracle(run, name, pass, err))
		return -1;
	return json_flush(run);
}

static int emit_method(struct runner *run, const char *operation,
		       const char *method, const char *path_role, bool pass,
		       int err)
{
	int written;

	run->method_sequence++;
	written = fprintf(run->out,
			  "{\"event\":\"rq3-method-ownership\","
			  "\"result_level\":\"kvm_agent_workspace_rq3\","
			  "\"condition\":\"wrapfs\","
			  "\"sequence\":%llu,\"operation\":\"%s\","
			  "\"method_owner\":\"wrapfs\","
			  "\"method\":\"%s\",\"path_role\":\"%s\","
			  "\"pass\":%s,\"errno\":%d}\n",
			  run->method_sequence, operation, method, path_role,
			  pass ? "true" : "false", err);
	if (written < 0) {
		run->result_failed = true;
		return -1;
	}
	return json_flush(run);
}

static int emit_manifest(struct runner *run, bool pass,
			 const struct lower_manifest *manifest)
{
	int written;

	written = fprintf(run->out,
			  "{\"event\":\"rq3-lower-tree-manifest\","
			  "\"result_level\":\"kvm_agent_workspace_rq3\","
			  "\"condition\":\"wrapfs\",\"pass\":%s,"
			  "\"base_main_preserved\":%s,"
			  "\"base_deleted_preserved\":%s,"
			  "\"base_src_preserved\":%s,"
			  "\"base_git_preserved\":%s,"
			  "\"base_symlink_preserved\":%s,"
			  "\"base_generated_absent\":%s,"
			  "\"base_cached_negative_absent\":%s,"
			  "\"upper_main_preserved\":%s,"
			  "\"upper_deleted_preserved\":%s,"
			  "\"upper_src_preserved\":%s,"
			  "\"upper_git_preserved\":%s,"
			  "\"upper_symlink_preserved\":%s,"
			  "\"upper_generated_present\":%s,"
			  "\"upper_renamed_absent\":%s,"
			  "\"upper_cached_negative_absent\":%s,"
			  "\"visible_main\":%s,"
			  "\"visible_deleted\":%s,"
			  "\"visible_generated\":%s,"
			  "\"visible_cached_negative\":%s}\n",
			  pass ? "true" : "false",
			  manifest->base_main_preserved ? "true" : "false",
			  manifest->base_deleted_preserved ? "true" : "false",
			  manifest->base_src_preserved ? "true" : "false",
			  manifest->base_git_preserved ? "true" : "false",
			  manifest->base_symlink_preserved ? "true" : "false",
			  manifest->base_generated_absent ? "true" : "false",
			  manifest->base_cached_negative_absent ? "true" : "false",
			  manifest->upper_main_preserved ? "true" : "false",
			  manifest->upper_deleted_preserved ? "true" : "false",
			  manifest->upper_src_preserved ? "true" : "false",
			  manifest->upper_git_preserved ? "true" : "false",
			  manifest->upper_symlink_preserved ? "true" : "false",
			  manifest->upper_generated_present ? "true" : "false",
			  manifest->upper_renamed_absent ? "true" : "false",
			  manifest->upper_cached_negative_absent ? "true" : "false",
			  manifest->visible_main ? "true" : "false",
			  manifest->visible_deleted ? "true" : "false",
			  manifest->visible_generated ? "true" : "false",
			  manifest->visible_cached_negative ? "true" : "false");
	if (written < 0) {
		run->result_failed = true;
		return -1;
	}
	return json_flush(run);
}

static int set_path(char *dst, size_t size, const char *dir, const char *name)
{
	int ret = snprintf(dst, size, "%s/%s", dir, name);

	if (ret < 0)
		return -EIO;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int make_dir(const char *path)
{
	if (!mkdir(path, 0755))
		return 0;
	return -errno;
}

static int write_plain_file(const char *path, const char *value, mode_t mode)
{
	size_t length = strlen(value);
	size_t offset = 0;
	int saved_errno;
	int fd;

	fd = open(path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, mode);
	if (fd < 0)
		return -errno;
	while (offset < length) {
		ssize_t written = write(fd, value + offset, length - offset);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			saved_errno = errno;
			close(fd);
			return -saved_errno;
		}
		if (!written) {
			close(fd);
			return -EIO;
		}
		offset += (size_t)written;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int read_file_quiet(const char *path, const char *expected)
{
	char buffer[256] = { 0 };
	size_t expected_length = strlen(expected);
	ssize_t got;
	int saved_errno;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	do {
		got = read(fd, buffer, sizeof(buffer) - 1U);
	} while (got < 0 && errno == EINTR);
	saved_errno = errno;
	if (close(fd) && got >= 0)
		return -errno;
	if (got < 0)
		return -saved_errno;
	if ((size_t)got != expected_length)
		return -EINVAL;
	if (memcmp(buffer, expected, expected_length))
		return -EINVAL;
	return 0;
}

static int stat_absent_quiet(const char *path)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st))
		return -EEXIST;
	if (errno != ENOENT)
		return -errno;
	return 0;
}

static int symlink_target_quiet(const char *path, const char *expected)
{
	char buffer[PATH_MAX] = { 0 };
	ssize_t length;

	length = readlink(path, buffer, sizeof(buffer) - 1U);
	if (length < 0)
		return -errno;
	buffer[(size_t)length] = '\0';
	if (strcmp(buffer, expected))
		return -EINVAL;
	return 0;
}

static int mode_matches_quiet(const char *path, mode_t expected)
{
	struct stat st;

	if (stat(path, &st))
		return -errno;
	if ((st.st_mode & 0777U) != expected)
		return -EINVAL;
	return 0;
}

static int execute_quiet(const char *path)
{
	pid_t pid;
	int status;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		execl(path, path, NULL);
		_exit(127);
	}
	while (waitpid(pid, &status, 0) < 0) {
		if (errno != EINTR)
			return -errno;
	}
	if (!WIFEXITED(status) || WEXITSTATUS(status))
		return -EIO;
	return 0;
}

static int unprivileged_read_denied_quiet(const char *path)
{
	pid_t pid;
	int status;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		if (setgid(65534) || setuid(65534))
			_exit(2);
		errno = 0;
		_exit(access(path, R_OK) && errno == EACCES ? 0 : 1);
	}
	while (waitpid(pid, &status, 0) < 0) {
		if (errno != EINTR)
			return -errno;
	}
	if (!WIFEXITED(status) || WEXITSTATUS(status))
		return -EACCES;
	return 0;
}

static int trace_contains_all_tokens(const char *path)
{
	static const char *const tokens[] = {
		"TRACE_ID=agentfs-bash-git-workspace-v1",
		"UPSTREAM_COMMIT=0a014ebd4918615baff589ed17486e557e7c6a23",
		"SOURCE=cli/tests/test-run-bash.sh:6-25",
		"SOURCE=cli/tests/test-run-git.sh:9-30",
		"SOURCE=cli/tests/test-overlay-whiteout.sh:60-123",
		"SOURCE=cli/tests/test-symlinks.sh:19-68",
		"SOURCE=cli/tests/test-fuse-cache-invalidation.sh:134-158",
		"SOURCE=cli/tests/test-fuse-cache-invalidation.sh:109-132",
		"SOURCE=cli/tests/test-fuse-cache-invalidation.sh:60-90",
		"ORACLE=base-object-unchanged",
	};
	char buffer[16384];
	ssize_t total = 0;
	int fd;
	size_t i;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	for (;;) {
		ssize_t got = read(fd, buffer + total,
				   sizeof(buffer) - 1U - (size_t)total);

		if (got < 0) {
			int saved_errno = errno;

			if (saved_errno == EINTR)
				continue;
			close(fd);
			return -saved_errno;
		}
		if (!got)
			break;
		total += got;
		if ((size_t)total == sizeof(buffer) - 1U) {
			char extra;

			do {
				got = read(fd, &extra, 1);
			} while (got < 0 && errno == EINTR);
			if (got != 0) {
				int saved_errno = got < 0 ? errno : EFBIG;

				close(fd);
				return -saved_errno;
			}
			break;
		}
	}
	if (close(fd))
		return -errno;
	buffer[(size_t)total] = '\0';
	for (i = 0; i < sizeof(tokens) / sizeof(tokens[0]); i++) {
		if (!strstr(buffer, tokens[i]))
			return -EINVAL;
	}
	return 0;
}

static int insert_module(const char *module_path, bool *inserted)
{
	int saved_errno;
	int fd;
	long ret;

	fd = open(module_path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	ret = syscall(SYS_finit_module, fd, "", 0);
	saved_errno = errno;
	if (ret) {
		close(fd);
		return -saved_errno;
	}
	*inserted = true;
	if (close(fd))
		return -errno;
	return 0;
}

static int remove_module(void)
{
	long ret = syscall(SYS_delete_module, "wrapfs", O_NONBLOCK);

	if (ret)
		return -errno;
	return 0;
}

static int tracked_mount(struct runner *run, const char *lower,
			 const char *epoch)
{
	int err = 0;

	if (mount(lower, run->visible, "wrapfs", 0, NULL))
		err = errno;
	if (!err)
		run->mounted = true;
	if (emit_method(run, "mount", "wrapfs_get_tree+wrapfs_fill_super",
			epoch, !err, err))
		return -EIO;
	if (err)
		return -err;
	return 0;
}

static int tracked_unmount(struct runner *run, const char *epoch)
{
	int err = 0;

	if (umount2(run->visible, 0))
		err = errno;
	if (!err)
		run->mounted = false;
	if (emit_method(run, "unmount", "kill_anon_super+wrapfs_put_super",
			epoch, !err, err))
		return -EIO;
	if (err)
		return -err;
	return 0;
}

static int tracked_open(struct runner *run, const char *path, int flags,
			mode_t mode, const char *path_role, bool creates)
{
	int fd;
	int err;

	fd = open(path, flags, mode);
	err = fd < 0 ? errno : 0;
	if (creates &&
	    emit_method(run, "create", "wrapfs_create", path_role, !err, err)) {
		if (fd >= 0)
			close(fd);
		return -EIO;
	}
	if (emit_method(run, "open", "wrapfs_open", path_role, !err, err)) {
		if (fd >= 0)
			close(fd);
		return -EIO;
	}
	if (fd < 0)
		return -err;
	return fd;
}

static ssize_t tracked_read(struct runner *run, int fd, void *buffer,
			    size_t size, const char *path_role)
{
	ssize_t got;
	int err;

	do {
		got = read(fd, buffer, size);
	} while (got < 0 && errno == EINTR);
	err = got < 0 ? errno : 0;
	if (emit_method(run, "read", "wrapfs_read_iter", path_role,
			got >= 0, err))
		return -EIO;
	if (got < 0)
		return -err;
	return got;
}

static ssize_t tracked_write(struct runner *run, int fd, const void *buffer,
			     size_t size, const char *path_role)
{
	ssize_t written;
	int err;

	do {
		written = write(fd, buffer, size);
	} while (written < 0 && errno == EINTR);
	err = written < 0 ? errno : 0;
	if (emit_method(run, "write", "wrapfs_write_iter", path_role,
			written >= 0, err))
		return -EIO;
	if (written < 0)
		return -err;
	return written;
}

static int tracked_fsync(struct runner *run, int fd, const char *path_role)
{
	int err = 0;

	if (fsync(fd))
		err = errno;
	if (emit_method(run, "fsync", "wrapfs_fsync", path_role, !err, err))
		return -EIO;
	return err ? -err : 0;
}

static int tracked_rename(struct runner *run, const char *old_path,
			  const char *new_path, const char *path_role)
{
	int err = 0;

	if (rename(old_path, new_path))
		err = errno;
	if (emit_method(run, "rename", "wrapfs_rename", path_role, !err, err))
		return -EIO;
	return err ? -err : 0;
}

static int tracked_unlink(struct runner *run, const char *path,
			  const char *path_role)
{
	int err = 0;

	if (unlink(path))
		err = errno;
	if (emit_method(run, "unlink", "wrapfs_unlink", path_role, !err, err))
		return -EIO;
	return err ? -err : 0;
}

static int tracked_read_file(struct runner *run, const char *path,
			     const char *expected, const char *path_role)
{
	char buffer[256] = { 0 };
	size_t expected_length = strlen(expected);
	ssize_t got;
	int close_err;
	int fd;

	fd = tracked_open(run, path, O_RDONLY | O_CLOEXEC, 0, path_role, false);
	if (fd < 0)
		return fd;
	got = tracked_read(run, fd, buffer, sizeof(buffer) - 1U, path_role);
	close_err = close(fd);
	if (got < 0)
		return (int)got;
	if (close_err)
		return -errno;
	if ((size_t)got != expected_length)
		return -EINVAL;
	if (memcmp(buffer, expected, expected_length))
		return -EINVAL;
	return 0;
}

static int tracked_scan_directory(struct runner *run, const char *path,
				  const char *path_role,
				  struct directory_view *view)
{
	struct dirent *entry;
	DIR *directory;
	int err = 0;

	memset(view, 0, sizeof(*view));
	directory = opendir(path);
	if (!directory) {
		err = errno;
		if (emit_method(run, "open", "wrapfs_open", path_role, false,
				err))
			return -EIO;
		return -err;
	}
	if (emit_method(run, "open", "wrapfs_open", path_role, !err, err)) {
		closedir(directory);
		return -EIO;
	}

	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, "main.txt"))
			view->main = true;
		else if (!strcmp(entry->d_name, "deleted.txt"))
			view->deleted = true;
		else if (!strcmp(entry->d_name, "link.txt"))
			view->link = true;
		else if (!strcmp(entry->d_name, "generated.txt"))
			view->generated = true;
		else if (!strcmp(entry->d_name, "renamed.txt"))
			view->renamed = true;
		else if (!strcmp(entry->d_name, "cached-negative.txt"))
			view->cached_negative = true;
		else if (!strcmp(entry->d_name, "src"))
			view->src = true;
		else if (!strcmp(entry->d_name, ".git"))
			view->git = true;
	}
	err = errno;
	if (closedir(directory) && !err)
		err = errno;
	if (emit_method(run, "readdir", "wrapfs_readdir", path_role, !err, err))
		return -EIO;
	return err ? -err : 0;
}

static int expect_directory_view(struct runner *run, const char *case_name,
				 bool generated, bool cached_negative)
{
	struct directory_view view;
	bool pass;
	int err;

	err = tracked_scan_directory(run, run->visible, case_name, &view);
	if (err)
		return err;
	pass = view.main && !view.deleted && view.link &&
	       view.generated == generated && !view.renamed &&
	       view.cached_negative == cached_negative && view.src && view.git;
	return pass ? 0 : -EINVAL;
}

static int create_generated_file(struct runner *run, const char *path)
{
	static const char contents[] = "generated-in-upper\n";
	struct stat st;
	ssize_t written;
	int fsync_result;
	int saved_errno;
	int fd;

	fd = tracked_open(run, path,
			  O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC,
			  0644, "generated", true);
	if (fd < 0)
		return fd;
	written = tracked_write(run, fd, contents, sizeof(contents) - 1U,
				"generated");
	if (written < 0) {
		close(fd);
		return (int)written;
	}
	if ((size_t)written != sizeof(contents) - 1U) {
		close(fd);
		return -EIO;
	}
	fsync_result = tracked_fsync(run, fd, "generated");
	if (fsync_result) {
		close(fd);
		return fsync_result;
	}
	if (fchmod(fd, 0640)) {
		saved_errno = errno;
		close(fd);
		return -saved_errno;
	}
	if (fstat(fd, &st)) {
		saved_errno = errno;
		close(fd);
		return -saved_errno;
	}
	if (!S_ISREG(st.st_mode) || (st.st_mode & 0777U) != 0640U ||
	    st.st_size != (off_t)(sizeof(contents) - 1U)) {
		close(fd);
		return -EINVAL;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int create_cached_negative_file(struct runner *run, const char *path)
{
	static const char contents[] = "cached-negative-created\n";
	ssize_t written;
	int fd;

	fd = tracked_open(run, path,
			  O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC,
			  0644, "cached-negative", true);
	if (fd < 0)
		return fd;
	written = tracked_write(run, fd, contents, sizeof(contents) - 1U,
				"cached-negative");
	if (written < 0) {
		close(fd);
		return (int)written;
	}
	if ((size_t)written != sizeof(contents) - 1U) {
		close(fd);
		return -EIO;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int setup_paths(struct runner *run, struct workspace_paths *paths)
{
#define SET_WORKSPACE_PATH(field, directory, leaf)                           \
	do {                                                                  \
		int path_result = set_path((field), sizeof(field),             \
					   (directory), (leaf));                 \
		if (path_result)                                               \
			return path_result;                                    \
	} while (0)

	SET_WORKSPACE_PATH(paths->base, run->fixture_root, "base");
	SET_WORKSPACE_PATH(paths->upper, run->fixture_root, "upper");
	SET_WORKSPACE_PATH(run->visible, run->fixture_root, "visible");
	SET_WORKSPACE_PATH(paths->base_src, paths->base, "src");
	SET_WORKSPACE_PATH(paths->upper_src, paths->upper, "src");
	SET_WORKSPACE_PATH(paths->base_git, paths->base, ".git");
	SET_WORKSPACE_PATH(paths->upper_git, paths->upper, ".git");
	SET_WORKSPACE_PATH(paths->base_main, paths->base, "main.txt");
	SET_WORKSPACE_PATH(paths->upper_main, paths->upper, "main.txt");
	SET_WORKSPACE_PATH(paths->base_deleted, paths->base, "deleted.txt");
	SET_WORKSPACE_PATH(paths->upper_deleted, paths->upper, "deleted.txt");
	SET_WORKSPACE_PATH(paths->base_link, paths->base, "link.txt");
	SET_WORKSPACE_PATH(paths->upper_link, paths->upper, "link.txt");
	SET_WORKSPACE_PATH(paths->base_src_app, paths->base_src, "app.txt");
	SET_WORKSPACE_PATH(paths->upper_src_app, paths->upper_src, "app.txt");
	SET_WORKSPACE_PATH(paths->base_git_head, paths->base_git, "HEAD");
	SET_WORKSPACE_PATH(paths->upper_git_head, paths->upper_git, "HEAD");
	SET_WORKSPACE_PATH(paths->base_generated, paths->base, "generated.txt");
	SET_WORKSPACE_PATH(paths->upper_generated, paths->upper,
			   "generated.txt");
	SET_WORKSPACE_PATH(paths->base_tool, paths->base, "tool.sh");
	SET_WORKSPACE_PATH(paths->upper_tool, paths->upper, "tool.sh");
	SET_WORKSPACE_PATH(paths->base_denied, paths->base, "denied.txt");
	SET_WORKSPACE_PATH(paths->upper_denied, paths->upper, "denied.txt");
	SET_WORKSPACE_PATH(paths->upper_renamed, paths->upper, "renamed.txt");
	SET_WORKSPACE_PATH(paths->base_cached_negative, paths->base,
			   "cached-negative.txt");
	SET_WORKSPACE_PATH(paths->upper_cached_negative, paths->upper,
			   "cached-negative.txt");
	SET_WORKSPACE_PATH(paths->visible_main, run->visible, "main.txt");
	SET_WORKSPACE_PATH(paths->visible_deleted, run->visible, "deleted.txt");
	SET_WORKSPACE_PATH(paths->visible_link, run->visible, "link.txt");
	SET_WORKSPACE_PATH(paths->visible_src_app, run->visible, "src/app.txt");
	SET_WORKSPACE_PATH(paths->visible_git_head, run->visible, ".git/HEAD");
	SET_WORKSPACE_PATH(paths->visible_generated, run->visible,
			   "generated.txt");
	SET_WORKSPACE_PATH(paths->visible_tool, run->visible, "tool.sh");
	SET_WORKSPACE_PATH(paths->visible_denied, run->visible, "denied.txt");
	SET_WORKSPACE_PATH(paths->visible_renamed, run->visible, "renamed.txt");
	SET_WORKSPACE_PATH(paths->visible_cached_negative, run->visible,
			   "cached-negative.txt");

#undef SET_WORKSPACE_PATH
	return 0;
}

static int setup_fixtures(struct runner *run,
			  const struct workspace_paths *paths)
{
	int err;

	err = make_dir(paths->base);
	if (err)
		return err;
	err = make_dir(paths->upper);
	if (err)
		return err;
	err = make_dir(run->visible);
	if (err)
		return err;
	err = make_dir(paths->base_src);
	if (err)
		return err;
	err = make_dir(paths->upper_src);
	if (err)
		return err;
	err = make_dir(paths->base_git);
	if (err)
		return err;
	err = make_dir(paths->upper_git);
	if (err)
		return err;
	err = write_plain_file(paths->base_main, "base-main\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->upper_main, "upper-main\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->base_deleted, "base-deleted\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->upper_deleted, "upper-deleted\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->base_src_app, "base-app\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->upper_src_app, "agent-edited-app\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->base_git_head,
			       "ref: refs/heads/main\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->upper_git_head,
			       "ref: refs/heads/agent\n", 0644);
	if (err)
		return err;
	err = write_plain_file(paths->base_tool, "#!/bin/sh\nexit 0\n", 0755);
	if (err)
		return err;
	err = write_plain_file(paths->upper_tool, "#!/bin/sh\nexit 0\n", 0755);
	if (err)
		return err;
	err = write_plain_file(paths->base_denied, "base-denied\n", 0000);
	if (err)
		return err;
	err = write_plain_file(paths->upper_denied, "upper-denied\n", 0100);
	if (err)
		return err;
	if (chmod(paths->base_tool, 0755) ||
	    chmod(paths->upper_tool, 0755) ||
	    chmod(paths->base_denied, 0000) ||
	    chmod(paths->upper_denied, 0100) ||
	    chmod(paths->upper_main, 0600))
		return -errno;
	if (symlink("main.txt", paths->base_link))
		return -errno;
	if (symlink("main.txt", paths->upper_link))
		return -errno;
	return 0;
}

static int verify_final_manifest(struct runner *run,
				 const struct workspace_paths *paths,
				 struct lower_manifest *manifest)
{
	struct directory_view visible;
	struct stat st;
	int err;

	if (tracked_scan_directory(run, run->visible, "final-visible",
				   &visible))
		return -EIO;
	manifest->base_main_preserved =
		!read_file_quiet(paths->base_main, "base-main\n");
	manifest->base_deleted_preserved =
		!read_file_quiet(paths->base_deleted, "base-deleted\n");
	manifest->base_src_preserved =
		!read_file_quiet(paths->base_src_app, "base-app\n");
	manifest->base_git_preserved =
		!read_file_quiet(paths->base_git_head,
				 "ref: refs/heads/main\n");
	manifest->base_symlink_preserved =
		!symlink_target_quiet(paths->base_link, "main.txt");
	manifest->base_generated_absent =
		!stat_absent_quiet(paths->base_generated);
	manifest->base_cached_negative_absent =
		!stat_absent_quiet(paths->base_cached_negative);
	manifest->upper_main_preserved =
		!read_file_quiet(paths->upper_main, "upper-main\n");
	manifest->upper_deleted_preserved =
		!read_file_quiet(paths->upper_deleted, "upper-deleted\n");
	manifest->upper_src_preserved =
		!read_file_quiet(paths->upper_src_app, "agent-edited-app\n");
	manifest->upper_git_preserved =
		!read_file_quiet(paths->upper_git_head,
				 "ref: refs/heads/agent\n");
	manifest->upper_symlink_preserved =
		!symlink_target_quiet(paths->upper_link, "main.txt");
	err = read_file_quiet(paths->upper_generated, "generated-in-upper\n");
	if (!err && !stat(paths->upper_generated, &st))
		manifest->upper_generated_present =
			(st.st_mode & 0777U) == 0640U;
	manifest->upper_renamed_absent =
		!stat_absent_quiet(paths->upper_renamed);
	manifest->upper_cached_negative_absent =
		!stat_absent_quiet(paths->upper_cached_negative);
	manifest->visible_main =
		visible.main &&
		!read_file_quiet(paths->visible_main, "upper-main\n");
	manifest->visible_deleted = visible.deleted ||
		stat_absent_quiet(paths->visible_deleted) != 0;
	manifest->visible_generated = visible.generated;
	manifest->visible_cached_negative = visible.cached_negative ||
		stat_absent_quiet(paths->visible_cached_negative) != 0;

	return manifest->base_main_preserved &&
		       manifest->base_deleted_preserved &&
		       manifest->base_src_preserved &&
		       manifest->base_git_preserved &&
		       manifest->base_symlink_preserved &&
		       manifest->base_generated_absent &&
		       manifest->base_cached_negative_absent &&
		       manifest->upper_main_preserved &&
		       manifest->upper_deleted_preserved &&
		       manifest->upper_src_preserved &&
		       manifest->upper_git_preserved &&
		       manifest->upper_symlink_preserved &&
		       manifest->upper_generated_present &&
		       manifest->upper_renamed_absent &&
		       manifest->upper_cached_negative_absent &&
		       manifest->visible_main && !manifest->visible_deleted &&
		       manifest->visible_generated &&
		       !manifest->visible_cached_negative &&
		       visible.link && !visible.renamed && visible.src &&
		       visible.git
	       ? 0
	       : -EINVAL;
}

static int remove_tree_callback(const char *path, const struct stat *st,
				int type, struct FTW *state)
{
	(void)st;
	(void)type;
	(void)state;
	return remove(path);
}

static int remove_fixture_tree(const char *path)
{
	if (!path[0])
		return 0;
	if (!nftw(path, remove_tree_callback, 32, FTW_DEPTH | FTW_PHYS))
		return 0;
	return -errno;
}

#define REQUIRE_CASE(run, name, expression, ok_detail, fail_detail)           \
	do {                                                                   \
		int require_result = (expression);                              \
		if (emit_case((run), (name), require_result == 0,                \
			      require_result < 0 ? -require_result : 0,          \
			      require_result == 0 ? (ok_detail) : (fail_detail))) { \
			status = 2;                                              \
			goto cleanup;                                           \
		}                                                              \
		if (require_result) {                                          \
			status = 1;                                              \
			goto cleanup;                                           \
		}                                                              \
	} while (0)

int main(int argc, char **argv)
{
	const char *module_path;
	const char *result_path;
	const char *work_root;
	const char *source_trace;
	const char *preloaded_env;
	struct workspace_paths paths = { 0 };
	struct lower_manifest final_manifest = { 0 };
	struct runner run = { 0 };
	char resolved_work_root[PATH_MAX];
	char fixture_template[PATH_MAX];
	int cleanup_err;
	int status = 0;
	int err;
	bool module_preloaded;

	if (argc != 5) {
		fprintf(stderr,
			"usage: %s WRAPFS_KO JSONL_OUTPUT WORK_ROOT SOURCE_TRACE\n",
			argv[0]);
		return 2;
	}
	module_path = argv[1];
	result_path = argv[2];
	work_root = argv[3];
	source_trace = argv[4];
	preloaded_env = getenv("NAMEI_EXT_RQ3_WRAPFS_PRELOADED");
	module_preloaded = preloaded_env && !strcmp(preloaded_env, "1");

	run.out = fopen(result_path, "a");
	if (!run.out) {
		perror("fopen JSONL output");
		return 2;
	}
	if (!realpath(work_root, resolved_work_root)) {
		err = -errno;
		if (emit_case(&run, "resolve_work_root", false, -err,
			      "work root does not resolve"))
			status = 2;
		else
			status = 1;
		goto cleanup;
	}
	err = snprintf(fixture_template, sizeof(fixture_template),
		       "%s/rq3-wrapfs-XXXXXX", resolved_work_root);
	if (err < 0 || (size_t)err >= sizeof(fixture_template)) {
		if (emit_case(&run, "fixture_path", false, ENAMETOOLONG,
			      "fixture path is too long"))
			status = 2;
		else
			status = 1;
		goto cleanup;
	}
	if (!mkdtemp(fixture_template)) {
		err = errno;
		if (emit_case(&run, "create_fixture_root", false, err,
			      "mkdtemp under work root failed"))
			status = 2;
		else
			status = 1;
		goto cleanup;
	}
	if (chmod(fixture_template, 0755)) {
		err = errno;
		if (emit_case(&run, "fixture_root_mode", false, err,
			      "fixture root chmod failed"))
			status = 2;
		else
			status = 1;
		goto cleanup;
	}
	if (snprintf(run.fixture_root, sizeof(run.fixture_root), "%s",
		     fixture_template) >= (int)sizeof(run.fixture_root)) {
		if (emit_case(&run, "copy_fixture_path", false, ENAMETOOLONG,
			      "fixture root copy failed"))
			status = 2;
		else
			status = 1;
		goto cleanup;
	}

	REQUIRE_CASE(&run, "agentfs_source_trace",
		     trace_contains_all_tokens(source_trace),
		     "fixed AgentFS source trace bindings matched",
		     "source trace is unreadable or missing required bindings");
	REQUIRE_CASE(&run, "construct_workspace_paths",
		     setup_paths(&run, &paths),
		     "base, upper, and stable visible paths constructed",
		     "workspace path construction failed");
	REQUIRE_CASE(&run, "setup_workspace_fixtures",
		     setup_fixtures(&run, &paths),
		     "base and upper source-derived fixtures created",
		     "workspace fixture setup failed");

	if (module_preloaded) {
		REQUIRE_CASE(&run, "insmod_wrapfs", 0,
			     "Wrapfs module was preloaded by the traced KVM runner",
			     "unreachable preloaded module failure");
	} else {
		err = insert_module(module_path, &run.module_loaded);
		REQUIRE_CASE(&run, "insmod_wrapfs", err,
			     "Wrapfs module loaded with finit_module",
			     "Wrapfs module load failed");
	}

	REQUIRE_CASE(&run, "mount_base_epoch",
		     tracked_mount(&run, paths.base, "base-epoch"),
		     "base mounted at stable visible path",
		     "base Wrapfs mount failed");
	REQUIRE_CASE(&run, "base_lookup_main",
		     tracked_read_file(&run, paths.visible_main, "base-main\n",
				       "base-main"),
		     "base main lookup and read matched",
		     "base main lookup or read mismatched");
	REQUIRE_CASE(&run, "base_main_mode",
		     mode_matches_quiet(paths.visible_main, 0644),
		     "base main mode matched 0644",
		     "base main mode mismatched");
	REQUIRE_CASE(&run, "base_lookup_deleted_hidden",
		     stat_absent_quiet(paths.visible_deleted),
		     "deleted.txt lookup returned ENOENT",
		     "deleted.txt lookup was visible or failed unexpectedly");
	REQUIRE_CASE(&run, "base_readdir_deleted_hidden",
		     expect_directory_view(&run, "base-directory", false, false),
		     "base readdir hid deleted.txt and exposed expected entries",
		     "base directory view mismatched");
	REQUIRE_CASE(&run, "base_nested_src",
		     tracked_read_file(&run, paths.visible_src_app, "base-app\n",
				       "base-src-app"),
		     "base nested src path matched",
		     "base nested src path mismatched");
	REQUIRE_CASE(&run, "base_nested_git",
		     tracked_read_file(&run, paths.visible_git_head,
				       "ref: refs/heads/main\n",
				       "base-git-head"),
		     "base nested .git path matched",
		     "base nested .git path mismatched");
	REQUIRE_CASE(&run, "base_symlink",
		     symlink_target_quiet(paths.visible_link, "main.txt"),
		     "base symlink target matched",
		     "base symlink target mismatched");
	REQUIRE_CASE(&run, "base_symlink_follow",
		     tracked_read_file(&run, paths.visible_link, "base-main\n",
				       "base-link-target"),
		     "base symlink resolved to base main",
		     "base symlink target read mismatched");
	REQUIRE_CASE(&run, "base_exec_tool",
		     execute_quiet(paths.visible_tool),
		     "base executable completed through Wrapfs",
		     "base executable failed through Wrapfs");
	REQUIRE_CASE(&run, "base_unprivileged_access_denied",
		     unprivileged_read_denied_quiet(paths.visible_denied),
		     "base denied file rejected unprivileged read access",
		     "base denied-file permission oracle failed");
	REQUIRE_CASE(&run, "base_denied_mode",
		     mode_matches_quiet(paths.visible_denied, 0000),
		     "base denied-file mode matched 0000",
		     "base denied-file mode mismatched");
	REQUIRE_CASE(&run, "unmount_base_epoch",
		     tracked_unmount(&run, "base-epoch"),
		     "base epoch unmounted",
		     "base epoch unmount failed");

	REQUIRE_CASE(&run, "mount_upper_epoch",
		     tracked_mount(&run, paths.upper, "upper-epoch"),
		     "upper mounted at the same visible path",
		     "upper Wrapfs mount failed");
	REQUIRE_CASE(&run, "upper_lookup_main",
		     tracked_read_file(&run, paths.visible_main, "upper-main\n",
				       "upper-main"),
		     "upper main lookup and read matched",
		     "upper main lookup or read mismatched");
	REQUIRE_CASE(&run, "upper_main_mode",
		     mode_matches_quiet(paths.visible_main, 0600),
		     "upper main mode matched 0600",
		     "upper main mode mismatched");
	REQUIRE_CASE(&run, "upper_lookup_deleted_hidden",
		     stat_absent_quiet(paths.visible_deleted),
		     "deleted.txt lookup returned ENOENT",
		     "deleted.txt lookup was visible or failed unexpectedly");
	REQUIRE_CASE(&run, "upper_readdir_deleted_hidden",
		     expect_directory_view(&run, "upper-directory", false, false),
		     "upper readdir hid deleted.txt and exposed expected entries",
		     "upper directory view mismatched");
	REQUIRE_CASE(&run, "upper_nested_src",
		     tracked_read_file(&run, paths.visible_src_app,
				       "agent-edited-app\n", "upper-src-app"),
		     "upper nested src path matched",
		     "upper nested src path mismatched");
	REQUIRE_CASE(&run, "upper_nested_git",
		     tracked_read_file(&run, paths.visible_git_head,
				       "ref: refs/heads/agent\n",
				       "upper-git-head"),
		     "upper nested .git path matched",
		     "upper nested .git path mismatched");
	REQUIRE_CASE(&run, "upper_symlink",
		     symlink_target_quiet(paths.visible_link, "main.txt"),
		     "upper symlink target matched",
		     "upper symlink target mismatched");
	REQUIRE_CASE(&run, "upper_symlink_follow",
		     tracked_read_file(&run, paths.visible_link, "upper-main\n",
				       "upper-link-target"),
		     "upper symlink resolved to upper main",
		     "upper symlink target read mismatched");
	REQUIRE_CASE(&run, "upper_exec_tool",
		     execute_quiet(paths.visible_tool),
		     "upper executable completed through Wrapfs",
		     "upper executable failed through Wrapfs");
	REQUIRE_CASE(&run, "upper_unprivileged_access_denied",
		     unprivileged_read_denied_quiet(paths.visible_denied),
		     "upper denied file rejected unprivileged read access",
		     "upper denied-file permission oracle failed");
	REQUIRE_CASE(&run, "upper_denied_mode",
		     mode_matches_quiet(paths.visible_denied, 0100),
		     "upper denied-file mode matched 0100",
		     "upper denied-file mode mismatched");
	REQUIRE_CASE(&run, "generated_negative_before_create",
		     stat_absent_quiet(paths.visible_generated),
		     "generated.txt negative lookup returned ENOENT",
		     "generated.txt unexpectedly existed");
	REQUIRE_CASE(&run, "generated_create_write_fsync_fchmod_fstat",
		     create_generated_file(&run, paths.visible_generated),
		     "generated file completed create/write/fsync/fchmod/fstat",
		     "generated file operation sequence failed");
	REQUIRE_CASE(&run, "generated_lower_visible",
		     read_file_quiet(paths.upper_generated,
				     "generated-in-upper\n"),
		     "generated file reached upper lower tree",
		     "generated file missing from upper lower tree");
	REQUIRE_CASE(&run, "generated_readdir_visible",
		     expect_directory_view(&run, "generated-directory", true,
					   false),
		     "generated file became visible in readdir",
		     "generated file missing or directory view mismatched");
	REQUIRE_CASE(&run, "cached_negative_before_create",
		     stat_absent_quiet(paths.visible_cached_negative),
		     "cached-negative lookup returned ENOENT",
		     "cached-negative unexpectedly existed");
	REQUIRE_CASE(&run, "cached_negative_create",
		     create_cached_negative_file(
			     &run, paths.visible_cached_negative),
		     "create replaced the prior negative dentry",
		     "create after negative lookup failed");
	REQUIRE_CASE(&run, "cached_negative_read",
		     tracked_read_file(&run, paths.visible_cached_negative,
				       "cached-negative-created\n",
				       "cached-negative"),
		     "created cached-negative file was readable",
		     "created cached-negative file read mismatched");
	REQUIRE_CASE(&run, "cached_negative_readdir_visible",
		     expect_directory_view(&run, "cached-negative-directory",
					   true, true),
		     "created cached-negative file became visible in readdir",
		     "cached-negative file missing from directory view");
	REQUIRE_CASE(&run, "rename_generated_to_renamed",
		     tracked_rename(&run, paths.visible_generated,
				    paths.visible_renamed, "generated-to-renamed"),
		     "generated file renamed through Wrapfs",
		     "generated rename failed");
	REQUIRE_CASE(&run, "rename_old_absent",
		     stat_absent_quiet(paths.visible_generated),
		     "old generated name became absent",
		     "old generated name remained visible");
	REQUIRE_CASE(&run, "rename_new_visible",
		     tracked_read_file(&run, paths.visible_renamed,
				       "generated-in-upper\n", "renamed"),
		     "renamed file became visible",
		     "renamed file read mismatched");
	REQUIRE_CASE(&run, "rename_restore_generated",
		     tracked_rename(&run, paths.visible_renamed,
				    paths.visible_generated,
				    "renamed-to-generated"),
		     "renamed file restored to generated name",
		     "rename restore failed");
	REQUIRE_CASE(&run, "unlink_cached_negative",
		     tracked_unlink(&run, paths.visible_cached_negative,
				    "cached-negative"),
		     "cached-negative file unlinked through Wrapfs",
		     "cached-negative unlink failed");
	REQUIRE_CASE(&run, "unlink_cached_negative_absent",
		     stat_absent_quiet(paths.visible_cached_negative),
		     "unlinked cached-negative name returned ENOENT",
		     "unlinked cached-negative name remained visible");

	err = verify_final_manifest(&run, &paths, &final_manifest);
	if (emit_manifest(&run, !err, &final_manifest)) {
		status = 2;
		goto cleanup;
	}
	REQUIRE_CASE(&run, "final_lower_tree_manifest", err,
		     "base remained unchanged and upper contained lifecycle writes",
		     "final visible or lower tree manifest mismatched");
	REQUIRE_CASE(&run, "unmount_upper_epoch",
		     tracked_unmount(&run, "upper-epoch"),
		     "upper epoch unmounted",
		     "upper epoch unmount failed");

	if (module_preloaded) {
		REQUIRE_CASE(&run, "rmmod_wrapfs", 0,
			     "module unload deferred to traced KVM runner",
			     "unreachable deferred module unload failure");
	} else {
		err = remove_module();
		if (!err)
			run.module_loaded = false;
		REQUIRE_CASE(&run, "rmmod_wrapfs", err,
			     "Wrapfs module unloaded with delete_module",
			     "Wrapfs module unload failed");
	}

	REQUIRE_CASE(&run, "remove_fixture_tree",
		     remove_fixture_tree(run.fixture_root),
		     "workspace fixture tree removed",
		     "workspace fixture tree cleanup failed");
	run.fixture_root[0] = '\0';
	REQUIRE_CASE(&run, "rq3_wrapfs_complete", 0,
		     "all source-derived Wrapfs workspace oracles passed",
		     "unreachable");

cleanup:
	if (run.mounted) {
		cleanup_err = tracked_unmount(&run, "failure-cleanup");
		if (cleanup_err) {
			if (emit_case(&run, "cleanup_unmount", false,
				      -cleanup_err,
				      "failure cleanup unmount failed"))
				status = 2;
			else if (!status)
				status = 1;
		} else if (emit_case(&run, "cleanup_unmount", true, 0,
				     "mounted Wrapfs instance cleaned up")) {
			status = 2;
		}
	}
	if (run.module_loaded) {
		cleanup_err = remove_module();
		if (cleanup_err) {
			if (emit_case(&run, "cleanup_rmmod", false, -cleanup_err,
				      "failure cleanup module unload failed"))
				status = 2;
			else if (!status)
				status = 1;
		} else {
			run.module_loaded = false;
			if (emit_case(&run, "cleanup_rmmod", true, 0,
				      "loaded Wrapfs module cleaned up"))
				status = 2;
		}
	}
	if (run.fixture_root[0]) {
		cleanup_err = remove_fixture_tree(run.fixture_root);
		if (cleanup_err) {
			if (emit_case(&run, "cleanup_fixture_tree", false,
				      -cleanup_err,
				      "failure cleanup fixture removal failed"))
				status = 2;
			else if (!status)
				status = 1;
		} else if (status &&
			   emit_case(&run, "cleanup_fixture_tree", true, 0,
				     "failure fixture tree cleaned up")) {
			status = 2;
		}
	}
	if (run.result_failed)
		status = 2;
	if (fclose(run.out))
		status = 2;
	return status;
}
