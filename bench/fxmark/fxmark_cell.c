// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "namei_ext_harness.h"

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <linux/magic.h>
#include <limits.h>
#include <math.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/statfs.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define FXMARK_READDIR_FILES_PER_WORKER 8192
#define FXMARK_MAX_WORKERS 4

struct cell_config {
	const char *condition;
	const char *fxmark_binary;
	const char *fuse_binary;
	const char *policy_object;
	const char *result_jsonl;
	const char *raw_prefix;
	const char *work_root;
	const char *cgroup_root;
	const char *type;
	int ncore;
	int duration;
	int timeout;
	int repetition;
};

struct tree_count {
	unsigned long long files;
	unsigned long long directories;
};

struct fxmark_result {
	int ncpu;
	double seconds;
	double works;
	double works_per_second;
};

struct policy_stats {
	uint32_t program_id;
	uint64_t run_time_ns;
	uint64_t run_count;
};

struct readdir_validation {
	unsigned long long entries;
	unsigned long long expected_entries;
	unsigned long long lookup_runs;
	unsigned long long readdir_runs;
	bool names_complete;
	bool selected_identity;
};

struct readdir_child_result {
	unsigned long long entries;
	int error;
	bool names_complete;
	bool selected_identity;
};

static struct tree_count observed_tree;

static unsigned long long monotonic_ms(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now))
		return 0;
	return (unsigned long long)now.tv_sec * 1000ull +
	       (unsigned long long)now.tv_nsec / 1000000ull;
}

static int path_format(char *out, size_t size, const char *format, ...)
{
	va_list args;
	int ret;

	va_start(args, format);
	ret = vsnprintf(out, size, format, args);
	va_end(args);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int mkdir_p(const char *path)
{
	char copy[PATH_MAX];
	char *cursor;

	if (snprintf(copy, sizeof(copy), "%s", path) >= (int)sizeof(copy))
		return -ENAMETOOLONG;
	for (cursor = copy + 1; *cursor; ++cursor) {
		if (*cursor != '/')
			continue;
		*cursor = '\0';
		if (mkdir(copy, 0755) && errno != EEXIST)
			return -errno;
		*cursor = '/';
	}
	if (mkdir(copy, 0755) && errno != EEXIST)
		return -errno;
	return 0;
}

static int count_tree_entry(const char *path, const struct stat *st, int type,
			    struct FTW *ftw)
{
	(void)path;
	(void)st;
	(void)ftw;
	if (type == FTW_F)
		observed_tree.files++;
	else if (type == FTW_D)
		observed_tree.directories++;
	return 0;
}

static int count_tree(const char *root, struct tree_count *count)
{
	memset(&observed_tree, 0, sizeof(observed_tree));
	if (nftw(root, count_tree_entry, 32, FTW_PHYS))
		return -errno;
	*count = observed_tree;
	return 0;
}

static int expected_tree(const struct cell_config *config,
			 struct tree_count *count)
{
	if (!strcmp(config->type, "MRPL")) {
		count->files = config->ncore;
		count->directories = 1 + 4 * config->ncore;
		return 0;
	}
	if (!strcmp(config->type, "MRPM") || !strcmp(config->type, "MRPH")) {
		count->files = 32768;
		count->directories = 4681;
		return 0;
	}
	if (!strcmp(config->type, "MRDL")) {
		count->files =
			FXMARK_READDIR_FILES_PER_WORKER * config->ncore;
		count->directories = 1 + config->ncore;
		return 0;
	}
	if (!strcmp(config->type, "MRDM")) {
		count->files =
			FXMARK_READDIR_FILES_PER_WORKER * config->ncore;
		count->directories = 1;
		return 0;
	}
	return -EINVAL;
}

static bool is_readdir_test(const struct cell_config *config)
{
	return !strcmp(config->type, "MRDL") ||
	       !strcmp(config->type, "MRDM");
}

static int precreate_readdir_directories(const struct cell_config *config,
					 const char *physical_root)
{
	char path[PATH_MAX];
	int ret;

	if (strcmp(config->type, "MRDL"))
		return 0;
	for (int worker = 0; worker < config->ncore; worker++) {
		ret = path_format(path, sizeof(path), "%s/%d", physical_root,
				  worker);
		if (!ret)
			ret = mkdir_p(path);
		if (ret)
			return ret;
	}
	return 0;
}

static int write_all(int fd, const void *buffer, size_t size)
{
	const char *cursor = buffer;

	while (size) {
		ssize_t written = write(fd, cursor, size);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!written)
			return -EIO;
		cursor += written;
		size -= (size_t)written;
	}
	return 0;
}

static int read_all(int fd, void *buffer, size_t size)
{
	char *cursor = buffer;

	while (size) {
		ssize_t received = read(fd, cursor, size);

		if (received < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!received)
			return -EPIPE;
		cursor += received;
		size -= (size_t)received;
	}
	return 0;
}

static int read_all_timeout(int fd, void *buffer, size_t size,
			    int timeout_seconds)
{
	unsigned long long deadline =
		monotonic_ms() + (unsigned long long)timeout_seconds * 1000ull;
	char *cursor = buffer;

	while (size) {
		unsigned long long now = monotonic_ms();
		struct pollfd descriptor = {
			.fd = fd,
			.events = POLLIN,
		};
		int remaining;
		int ret;

		if (!now || now >= deadline)
			return -ETIMEDOUT;
		remaining = (int)(deadline - now);
		ret = poll(&descriptor, 1, remaining);
		if (ret < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!ret)
			return -ETIMEDOUT;
		if (descriptor.revents & (POLLERR | POLLNVAL))
			return -EIO;
		if (descriptor.revents & POLLHUP && !(descriptor.revents & POLLIN))
			return -EPIPE;
		for (;;) {
			ssize_t received = read(fd, cursor, size);

			if (received < 0 && errno == EINTR)
				continue;
			if (received < 0)
				return -errno;
			if (!received)
				return -EPIPE;
			cursor += received;
			size -= (size_t)received;
			break;
		}
	}
	return 0;
}

static int set_bpf_stats_enabled(bool enabled)
{
	return namei_ext_write_text("/proc/sys/kernel/bpf_stats_enabled",
				    enabled ? "1\n" : "0\n");
}

static int configure_policy_scopes(const struct cell_config *config,
				   const char *cgroup,
				   const char *physical_root)
{
	char path[PATH_MAX];
	int ret;

	ret = namei_ext_policy_parent_exact(cgroup, config->work_root);
	if (ret || !is_readdir_test(config))
		return ret;
	if (!strcmp(config->type, "MRDM"))
		return namei_ext_policy_parent_add(cgroup, physical_root);
	for (int worker = 0; worker < config->ncore; worker++) {
		ret = path_format(path, sizeof(path), "%s/%d", physical_root,
				  worker);
		if (!ret)
			ret = namei_ext_policy_parent_add(cgroup, path);
		if (ret)
			return ret;
	}
	return 0;
}

static int redirect_fd(int target_fd, const char *path)
{
	int fd = open(path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);

	if (fd < 0)
		return -errno;
	if (dup2(fd, target_fd) < 0) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	if (close(fd))
		return -errno;
	return 0;
}

static int wait_with_timeout(pid_t pid, int timeout_seconds,
			     struct rusage *usage, int *exit_status)
{
	unsigned long long deadline =
		monotonic_ms() + (unsigned long long)timeout_seconds * 1000ull;
	int status;

	for (;;) {
		pid_t result = wait4(pid, &status, WNOHANG, usage);

		if (result == pid)
			break;
		if (result < 0)
			return -errno;
		if (monotonic_ms() >= deadline) {
			kill(-pid, SIGKILL);
			if (wait4(pid, &status, 0, usage) != pid)
				return -errno;
			*exit_status = -ETIMEDOUT;
			return 0;
		}
		usleep(100000);
	}
	if (!WIFEXITED(status)) {
		*exit_status = WIFSIGNALED(status) ?
			-(128 + WTERMSIG(status)) : -ECHILD;
		return 0;
	}
	*exit_status = WEXITSTATUS(status);
	return 0;
}

static int parse_fxmark_output(const char *path, struct fxmark_result *result)
{
	char header[256];
	char row[512];
	FILE *input = fopen(path, "r");

	if (!input)
		return -errno;
	if (!fgets(header, sizeof(header), input) ||
	    strcmp(header, "# ncpu secs works works/sec \n") ||
	    !fgets(row, sizeof(row), input) ||
	    sscanf(row, "%d %lf %lf %lf", &result->ncpu, &result->seconds,
		   &result->works, &result->works_per_second) != 4) {
		fclose(input);
		return -EINVAL;
	}
	if (fclose(input))
		return -errno;
	if (!isfinite(result->seconds) || !isfinite(result->works) ||
	    !isfinite(result->works_per_second) || result->seconds <= 0 ||
	    result->works <= 0 || result->works_per_second <= 0)
		return -ERANGE;
	return 0;
}

static int run_fxmark(const struct cell_config *config, const char *root,
		      const char *cgroup, const char *begin_command,
		      const char *end_command, const char *stdout_path,
		      const char *stderr_path, const char *cgroup_path,
		      bool *cgroup_verified, struct rusage *usage, int *exit_status)
{
	char ncore[16];
	char duration[16];
	char proc_path[64];
	char membership[4096];
	char expected[PATH_MAX];
	const char *relative;
	size_t written = 0;
	ssize_t nread;
	int membership_fd;
	int output_fd;
	int status;
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		setpgid(0, 0);
		if (redirect_fd(STDOUT_FILENO, stdout_path) ||
		    redirect_fd(STDERR_FILENO, stderr_path) ||
		    namei_ext_move_self_to_cgroup(cgroup))
			_exit(125);
		raise(SIGSTOP);
		snprintf(ncore, sizeof(ncore), "%d", config->ncore);
		snprintf(duration, sizeof(duration), "%d", config->duration);
		execl(config->fxmark_binary, config->fxmark_binary,
		      "--type", config->type,
		      "--ncore", ncore,
		      "--nbg", "0",
		      "--duration", duration,
		      "--directio", "0",
		      "--root", root,
		      "--profbegin", begin_command,
		      "--profend", end_command,
		      (char *)NULL);
		_exit(126);
	}
	setpgid(pid, pid);
	if (waitpid(pid, &status, WUNTRACED) != pid || !WIFSTOPPED(status)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -ECHILD;
	}
	if (snprintf(proc_path, sizeof(proc_path), "/proc/%ld/cgroup",
		     (long)pid) >= (int)sizeof(proc_path)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -ENAMETOOLONG;
	}
	membership_fd = open(proc_path, O_RDONLY | O_CLOEXEC);
	if (membership_fd < 0) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -errno;
	}
	nread = read(membership_fd, membership, sizeof(membership) - 1);
	if (nread < 0) {
		int saved_errno = errno;

		close(membership_fd);
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -saved_errno;
	}
	membership[nread] = '\0';
	if (close(membership_fd)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -errno;
	}
	output_fd = open(cgroup_path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC,
			 0644);
	if (output_fd < 0) {
		int saved_errno = errno;

		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -saved_errno;
	}
	while (written < (size_t)nread) {
		ssize_t result = write(output_fd, membership + written,
				       (size_t)nread - written);

		if (result < 0) {
			int saved_errno = errno;

			close(output_fd);
			kill(-pid, SIGKILL);
			waitpid(pid, NULL, 0);
			return -saved_errno;
		}
		if (!result) {
			close(output_fd);
			kill(-pid, SIGKILL);
			waitpid(pid, NULL, 0);
			return -EIO;
		}
		written += (size_t)result;
	}
	if (close(output_fd)) {
		int saved_errno = errno;

		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -saved_errno;
	}
	if (strncmp(cgroup, config->cgroup_root, strlen(config->cgroup_root)) ||
	    cgroup[strlen(config->cgroup_root)] != '/') {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -EINVAL;
	}
	relative = cgroup + strlen(config->cgroup_root);
	if (path_format(expected, sizeof(expected), "0::%s\n", relative) ||
	    strcmp(membership, expected)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -EINVAL;
	}
	*cgroup_verified = true;
	if (kill(pid, SIGCONT)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -errno;
	}
	return wait_with_timeout(pid, config->timeout, usage, exit_status);
}

static int wait_for_fuse_mount(const char *mountpoint, pid_t pid)
{
	unsigned long long deadline = monotonic_ms() + 10000;

	while (monotonic_ms() < deadline) {
		struct statfs fs;
		int status;

		if (!statfs(mountpoint, &fs) &&
		    (unsigned long)fs.f_type == FUSE_SUPER_MAGIC)
			return 0;
		if (waitpid(pid, &status, WNOHANG) == pid)
			return -ECHILD;
		usleep(50000);
	}
	return -ETIMEDOUT;
}

static int start_fuse(const struct cell_config *config, const char *lower,
		      const char *view, const char *stats, const char *control,
		      pid_t *pid_out)
{
	char stderr_path[PATH_MAX];
	pid_t pid;

	if (path_format(stderr_path, sizeof(stderr_path), "%s.fuse.stderr",
			config->raw_prefix))
		return -ENAMETOOLONG;
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		setpgid(0, 0);
		if (redirect_fd(STDOUT_FILENO, "/dev/null") ||
		    redirect_fd(STDERR_FILENO, stderr_path))
			_exit(125);
		execl(config->fuse_binary, config->fuse_binary, lower, view,
		      stats, control, (char *)NULL);
		_exit(126);
	}
	setpgid(pid, pid);
	if (wait_for_fuse_mount(view, pid)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -EIO;
	}
	*pid_out = pid;
	return 0;
}

static int stop_fuse(pid_t pid, const char *mountpoint, struct rusage *usage,
		     int *exit_status)
{
	if (umount2(mountpoint, 0) && umount2(mountpoint, MNT_DETACH)) {
		int unmount_error = -errno;
		int wait_error;

		kill(-pid, SIGKILL);
		wait_error = wait_with_timeout(pid, 10, usage, exit_status);
		return wait_error ? wait_error : unmount_error;
	}
	return wait_with_timeout(pid, 10, usage, exit_status);
}

static int read_file(const char *path, char *buffer, size_t size)
{
	ssize_t nread;
	int fd = open(path, O_RDONLY | O_CLOEXEC);

	if (fd < 0)
		return -errno;
	nread = read(fd, buffer, size - 1);
	if (nread < 0) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	buffer[nread] = '\0';
	if (close(fd))
		return -errno;
	return 0;
}

static int extract_u64(const char *json, const char *field,
		       unsigned long long *value)
{
	const char *position = strstr(json, field);
	char *end;

	if (!position)
		return -ENOENT;
	position += strlen(field);
	errno = 0;
	*value = strtoull(position, &end, 10);
	if (errno || end == position)
		return -EINVAL;
	return 0;
}

static int attached_program_stats(struct namei_ext_harness_policy *policy,
				  struct policy_stats *stats)
{
	struct bpf_prog_info info = {};
	uint32_t info_len = sizeof(info);
	uint32_t attached_ids[4] = {};
	uint32_t attached_count = 4;
	uint32_t attach_flags = 0;

	if (bpf_prog_get_info_by_fd(policy->prog_fd, &info, &info_len))
		return -errno;
	if (bpf_prog_query(policy->cgroup_fd, BPF_CGROUP_NAMEI_EXT, 0,
			   &attach_flags, attached_ids, &attached_count))
		return -errno;
	if (attached_count != 1 || attached_ids[0] != info.id)
		return -EINVAL;
	stats->program_id = info.id;
	stats->run_time_ns = info.run_time_ns;
	stats->run_count = info.run_cnt;
	return 0;
}

static int validation_directory_path(const struct cell_config *config,
				     const char *root, int index,
				     char *path, size_t size)
{
	if (!strcmp(config->type, "MRDL"))
		return path_format(path, size, "%s/%d", root, index);
	if (!strcmp(config->type, "MRDM") && !index)
		return path_format(path, size, "%s", root);
	return -EINVAL;
}

static int parse_readdir_name(const struct cell_config *config, int directory,
			      const char *name, size_t *slot)
{
	unsigned long long file;
	int consumed = 0;
	int worker;

	if (!strcmp(config->type, "MRDL")) {
		if (sscanf(name, "n_dir_rd-%d-%llu.dat%n", &worker, &file,
			   &consumed) != 2 ||
		    name[consumed] || worker != directory)
			return -EINVAL;
	} else if (!strcmp(config->type, "MRDM")) {
		if (sscanf(name, "n_shdir_rd-%d-%llu.dat%n", &worker, &file,
			   &consumed) != 2 ||
		    name[consumed] || worker < 0 || worker >= config->ncore)
			return -EINVAL;
	} else {
		return -EINVAL;
	}
	if (file >= FXMARK_READDIR_FILES_PER_WORKER)
		return -ERANGE;
	*slot = (size_t)worker * FXMARK_READDIR_FILES_PER_WORKER +
		(size_t)file;
	return 0;
}

static int open_validation_directories(const struct cell_config *config,
				       const char *root,
				       const char *physical_root,
				       DIR **directories,
				       bool *selected_identity)
{
	int count = !strcmp(config->type, "MRDL") ? config->ncore : 1;

	*selected_identity = strcmp(config->condition, "fuse") != 0;
	for (int index = 0; index < count; index++) {
		struct stat logical_stat;
		struct stat physical_stat;
		char logical[PATH_MAX];
		char physical[PATH_MAX];
		int ret;

		ret = validation_directory_path(config, root, index, logical,
						sizeof(logical));
		if (!ret)
			ret = validation_directory_path(config, physical_root, index,
							physical,
							sizeof(physical));
		if (ret)
			return ret;
		directories[index] = opendir(logical);
		if (!directories[index])
			return -errno;
		if (fstat(dirfd(directories[index]), &logical_stat) ||
		    stat(physical, &physical_stat))
			return -errno;
		if (strcmp(config->condition, "fuse") &&
		    (logical_stat.st_dev != physical_stat.st_dev ||
		     logical_stat.st_ino != physical_stat.st_ino))
			*selected_identity = false;
	}
	return 0;
}

static int enumerate_validation_directories(const struct cell_config *config,
					    DIR **directories,
					    struct readdir_child_result *result)
{
	size_t file_count =
		(size_t)FXMARK_READDIR_FILES_PER_WORKER * config->ncore;
	int directory_count =
		!strcmp(config->type, "MRDL") ? config->ncore : 1;
	unsigned char *seen = calloc(file_count, sizeof(*seen));
	int ret = 0;

	if (!seen)
		return -ENOMEM;
	for (int directory = 0; directory < directory_count; directory++) {
		bool dot = false;
		bool dotdot = false;
		struct dirent *entry;

		errno = 0;
		while ((entry = readdir(directories[directory]))) {
			size_t slot;

			result->entries++;
			if (!strcmp(entry->d_name, ".")) {
				if (dot) {
					ret = -EEXIST;
					break;
				}
				dot = true;
				continue;
			}
			if (!strcmp(entry->d_name, "..")) {
				if (dotdot) {
					ret = -EEXIST;
					break;
				}
				dotdot = true;
				continue;
			}
			ret = parse_readdir_name(config, directory, entry->d_name,
						 &slot);
			if (ret || seen[slot]) {
				if (!ret)
					ret = -EEXIST;
				break;
			}
			seen[slot] = 1;
		}
		if (!ret && errno)
			ret = -errno;
		if (!ret && (!dot || !dotdot))
			ret = -ENOENT;
		if (ret)
			break;
	}
	for (size_t slot = 0; !ret && slot < file_count; slot++) {
		if (!seen[slot])
			ret = -ENOENT;
	}
	free(seen);
	result->names_complete = !ret;
	return ret;
}

static int close_validation_directories(const struct cell_config *config,
					DIR **directories)
{
	int count = !strcmp(config->type, "MRDL") ? config->ncore : 1;
	int ret = 0;

	for (int index = 0; index < count; index++) {
		if (directories[index] && closedir(directories[index]) && !ret)
			ret = -errno;
	}
	return ret;
}

static void readdir_validation_child(const struct cell_config *config,
				     const char *root,
				     const char *physical_root,
				     const char *cgroup,
				     int ready_fd, int go_fd, int result_fd)
{
	struct readdir_child_result result = {};
	DIR *directories[FXMARK_MAX_WORKERS] = {};
	char go;
	int open_status;

	setpgid(0, 0);
	open_status = namei_ext_move_self_to_cgroup(cgroup);
	if (!open_status)
		open_status = open_validation_directories(config, root,
							  physical_root,
							  directories,
							  &result.selected_identity);
	if (write_all(ready_fd, &open_status, sizeof(open_status)))
		_exit(125);
	if (!open_status) {
		int ret = read_all(go_fd, &go, sizeof(go));

		if (!ret)
			ret = enumerate_validation_directories(config, directories,
							       &result);
		result.error = ret;
	} else {
		result.error = open_status;
	}
	open_status = close_validation_directories(config, directories);
	if (!result.error && open_status)
		result.error = open_status;
	if (write_all(result_fd, &result, sizeof(result)))
		_exit(125);
	_exit(result.error ? 1 : 0);
}

static int validate_readdir_view(
	const struct cell_config *config, const char *root,
	const char *physical_root, const char *cgroup,
	struct namei_ext_harness_policy *policy,
	struct readdir_validation *validation)
{
	struct policy_stats stats_before = {};
	struct policy_stats stats_opened = {};
	struct policy_stats stats_after = {};
	struct readdir_child_result child_result = {};
	struct rusage usage = {};
	int ready_pipe[2] = {-1, -1};
	int result_pipe[2] = {-1, -1};
	int go_pipe[2] = {-1, -1};
	bool stats_enabled = false;
	int child_status = -1;
	int open_status;
	char go = 1;
	pid_t pid = -1;
	int ret = 0;

	memset(validation, 0, sizeof(*validation));
	validation->expected_entries =
		!strcmp(config->type, "MRDL") ?
			(unsigned long long)config->ncore *
				(FXMARK_READDIR_FILES_PER_WORKER + 2) :
			(unsigned long long)config->ncore *
				FXMARK_READDIR_FILES_PER_WORKER + 2;
	if (policy) {
		ret = set_bpf_stats_enabled(true);
		if (ret)
			goto out;
		stats_enabled = true;
		ret = attached_program_stats(policy, &stats_before);
		if (ret)
			goto out;
	}
	if (pipe2(ready_pipe, O_CLOEXEC) ||
	    pipe2(go_pipe, O_CLOEXEC) ||
	    pipe2(result_pipe, O_CLOEXEC)) {
		ret = -errno;
		goto out;
	}
	pid = fork();
	if (pid < 0) {
		ret = -errno;
		goto out;
	}
	if (!pid) {
		close(ready_pipe[0]);
		close(go_pipe[1]);
		close(result_pipe[0]);
		readdir_validation_child(config, root, physical_root, cgroup,
					 ready_pipe[1], go_pipe[0],
					 result_pipe[1]);
	}
	setpgid(pid, pid);
	close(ready_pipe[1]);
	ready_pipe[1] = -1;
	close(go_pipe[0]);
	go_pipe[0] = -1;
	close(result_pipe[1]);
	result_pipe[1] = -1;
	ret = read_all_timeout(ready_pipe[0], &open_status, sizeof(open_status),
			       config->timeout);
	if (ret)
		goto out;
	if (policy) {
		ret = attached_program_stats(policy, &stats_opened);
		if (ret)
			goto out;
	}
	if (!open_status) {
		ret = write_all(go_pipe[1], &go, sizeof(go));
		if (ret)
			goto out;
	}
	ret = read_all_timeout(result_pipe[0], &child_result,
			       sizeof(child_result), config->timeout);
	if (ret)
		goto out;
	ret = wait_with_timeout(pid, config->timeout, &usage, &child_status);
	pid = -1;
	if (ret)
		goto out;
	if (policy) {
		ret = attached_program_stats(policy, &stats_after);
		if (ret)
			goto out;
	}
	validation->entries = child_result.entries;
	validation->names_complete = child_result.names_complete;
	validation->selected_identity = child_result.selected_identity;
	if (policy) {
		if (stats_opened.run_count < stats_before.run_count ||
		    stats_after.run_count < stats_opened.run_count) {
			ret = -ERANGE;
			goto out;
		}
		validation->lookup_runs =
			stats_opened.run_count - stats_before.run_count;
		validation->readdir_runs =
			stats_after.run_count - stats_opened.run_count;
	}
	if (open_status || child_result.error || child_status ||
	    !validation->names_complete ||
	    validation->entries != validation->expected_entries ||
	    (!strcmp(config->condition, "select") &&
	     !validation->selected_identity) ||
	    (policy && (!validation->lookup_runs ||
			validation->readdir_runs != validation->entries)))
		ret = -EINVAL;

out:
	if (stats_enabled) {
		int disable_ret = set_bpf_stats_enabled(false);

		if (disable_ret && !ret)
			ret = disable_ret;
	}
	if (pid > 0) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
	}
	for (int index = 0; index < 2; index++) {
		if (ready_pipe[index] >= 0)
			close(ready_pipe[index]);
		if (go_pipe[index] >= 0)
			close(go_pipe[index]);
		if (result_pipe[index] >= 0)
			close(result_pipe[index]);
	}
	return ret;
}

static unsigned long long timeval_ns(struct timeval value)
{
	return (unsigned long long)value.tv_sec * 1000000000ull +
	       (unsigned long long)value.tv_usec * 1000ull;
}

static int stream_error(void)
{
	return errno ? -errno : -EIO;
}

static int write_json_string(FILE *out, const char *value)
{
	const unsigned char *cursor = (const unsigned char *)value;

	if (fputc('"', out) == EOF)
		return stream_error();
	for (; *cursor; cursor++) {
		switch (*cursor) {
		case '"':
			if (fputs("\\\"", out) == EOF)
				return stream_error();
			break;
		case '\\':
			if (fputs("\\\\", out) == EOF)
				return stream_error();
			break;
		case '\b':
			if (fputs("\\b", out) == EOF)
				return stream_error();
			break;
		case '\f':
			if (fputs("\\f", out) == EOF)
				return stream_error();
			break;
		case '\n':
			if (fputs("\\n", out) == EOF)
				return stream_error();
			break;
		case '\r':
			if (fputs("\\r", out) == EOF)
				return stream_error();
			break;
		case '\t':
			if (fputs("\\t", out) == EOF)
				return stream_error();
			break;
		default:
			if (*cursor < 0x20) {
				if (fprintf(out, "\\u%04x", *cursor) < 0)
					return stream_error();
			} else if (fputc(*cursor, out) == EOF) {
				return stream_error();
			}
		}
	}
	if (fputc('"', out) == EOF)
		return stream_error();
	return 0;
}

static int write_observation(const struct cell_config *config, bool pass,
			     const struct fxmark_result *result,
			     const struct tree_count *actual,
			     const struct tree_count *expected,
			     int fxmark_status, int fuse_status,
			     const struct rusage *client_usage,
			     const struct rusage *fuse_usage,
			     const struct policy_stats *policy_before,
			     const struct policy_stats *policy_after,
			     const struct readdir_validation *readdir,
			     unsigned long long fuse_setup,
			     unsigned long long fuse_measured,
			     unsigned long long fuse_measured_opendir,
			     unsigned long long fuse_measured_readdir,
			     unsigned long long fuse_measured_releasedir,
			     unsigned long long fuse_phase_measured_acks,
			     unsigned long long fuse_phase_after_acks,
			     unsigned long long fuse_phase_invalid_commands,
			     unsigned long fuse_f_type_before,
			     unsigned long fuse_f_type_after,
			     bool cgroup_verified,
			     const char *stdout_path, const char *stderr_path,
			     const char *cgroup_path,
			     const char *fuse_stats_path)
{
	FILE *out = fopen(config->result_jsonl, "a");

	if (!out)
		return -errno;
	if (fprintf(out,
		"{\"event\":\"fxmark-cell\",\"repetition\":%d,"
		"\"condition\":\"%s\",\"type\":\"%s\",\"workers\":%d,"
		"\"duration_seconds\":%d,\"fxmark_status\":%d,"
		"\"fuse_status\":%d,\"seconds\":%.9f,\"works\":%.0f,"
		"\"works_per_second\":%.9f,"
		"\"actual_files\":%llu,\"expected_files\":%llu,"
		"\"actual_directories\":%llu,\"expected_directories\":%llu,"
		"\"attached_program_id_before\":%u,"
		"\"attached_program_id_after\":%u,"
		"\"policy_run_time_ns_before\":%llu,"
		"\"policy_run_time_ns_after\":%llu,"
			"\"policy_run_count_before\":%llu,"
			"\"policy_run_count_after\":%llu,"
			"\"attachment_stable\":%s,"
			"\"select_required_for_logical_path\":%s,"
			"\"leader_cgroup_verified\":%s,"
			"\"readdir_validation_required\":%s,"
			"\"logical_directory_entries\":%llu,"
			"\"expected_directory_entries\":%llu,"
			"\"logical_names_complete\":%s,"
			"\"selected_directory_identity\":%s,"
			"\"validation_lookup_runs\":%llu,"
			"\"validation_readdir_runs\":%llu,"
			"\"bpf_stats_post_timing_only\":%s,"
			"\"fuse_setup_requests\":%llu,"
			"\"fuse_measured_requests\":%llu,"
			"\"fuse_measured_opendir\":%llu,"
			"\"fuse_measured_readdir\":%llu,"
			"\"fuse_measured_releasedir\":%llu,"
			"\"fuse_phase_measured_acks\":%llu,"
			"\"fuse_phase_after_acks\":%llu,"
			"\"fuse_phase_invalid_commands\":%llu,"
			"\"fuse_f_type_before\":%lu,"
			"\"fuse_f_type_after\":%lu,"
			"\"client_user_ns\":%llu,\"client_system_ns\":%llu,"
			"\"client_voluntary_context_switches\":%ld,"
			"\"client_involuntary_context_switches\":%ld,"
			"\"fuse_user_ns\":%llu,\"fuse_system_ns\":%llu,"
			"\"fuse_voluntary_context_switches\":%ld,"
			"\"fuse_involuntary_context_switches\":%ld,"
			"\"stdout\":",
		config->repetition, config->condition, config->type,
		config->ncore, config->duration, fxmark_status, fuse_status,
		result->seconds, result->works, result->works_per_second,
		actual->files, expected->files, actual->directories,
		expected->directories, policy_before->program_id,
		policy_after->program_id,
		(unsigned long long)policy_before->run_time_ns,
		(unsigned long long)policy_after->run_time_ns,
			(unsigned long long)policy_before->run_count,
			(unsigned long long)policy_after->run_count,
			policy_before->program_id &&
			policy_before->program_id == policy_after->program_id ?
				"true" : "false",
			!strcmp(config->condition, "select") ? "true" : "false",
			cgroup_verified ? "true" : "false",
			is_readdir_test(config) ? "true" : "false",
			readdir->entries, readdir->expected_entries,
			readdir->names_complete ? "true" : "false",
			readdir->selected_identity ? "true" : "false",
			readdir->lookup_runs, readdir->readdir_runs,
			is_readdir_test(config) ? "true" : "false",
			fuse_setup, fuse_measured, fuse_measured_opendir,
			fuse_measured_readdir, fuse_measured_releasedir,
			fuse_phase_measured_acks, fuse_phase_after_acks,
			fuse_phase_invalid_commands,
			fuse_f_type_before, fuse_f_type_after,
			timeval_ns(client_usage->ru_utime),
			timeval_ns(client_usage->ru_stime), client_usage->ru_nvcsw,
			client_usage->ru_nivcsw, timeval_ns(fuse_usage->ru_utime),
			timeval_ns(fuse_usage->ru_stime), fuse_usage->ru_nvcsw,
			fuse_usage->ru_nivcsw) < 0 ||
	    write_json_string(out, stdout_path) ||
	    fprintf(out, ",\"stderr\":") < 0 ||
	    write_json_string(out, stderr_path) ||
	    fprintf(out, ",\"leader_cgroup\":") < 0 ||
	    write_json_string(out, cgroup_path) ||
	    fprintf(out, ",\"fuse_stats\":") < 0 ||
	    write_json_string(out, fuse_stats_path) ||
	    fprintf(out, ",\"pass\":%s}\n", pass ? "true" : "false") < 0) {
		int saved_errno = errno ? errno : EIO;

		fclose(out);
		return -saved_errno;
	}
	if (fclose(out))
		return -errno;
	return 0;
}

static int parse_positive_int(const char *value, int *result)
{
	char *end;
	long parsed;

	errno = 0;
	parsed = strtol(value, &end, 10);
	if (errno || *end || parsed < 1 || parsed > INT_MAX)
		return -EINVAL;
	*result = parsed;
	return 0;
}

static int parse_config(int argc, char **argv, struct cell_config *config)
{
	if (argc != 14)
		return -EINVAL;
	config->condition = argv[1];
	config->fxmark_binary = argv[2];
	config->fuse_binary = argv[3];
	config->policy_object = argv[4];
	config->result_jsonl = argv[5];
	config->raw_prefix = argv[6];
	config->work_root = argv[7];
	config->cgroup_root = argv[8];
	config->type = argv[9];
	if (parse_positive_int(argv[10], &config->ncore) ||
	    parse_positive_int(argv[11], &config->duration) ||
	    parse_positive_int(argv[12], &config->timeout) ||
	    parse_positive_int(argv[13], &config->repetition))
		return -EINVAL;
	if (config->ncore > FXMARK_MAX_WORKERS ||
	    (strcmp(config->type, "MRPL") &&
	     strcmp(config->type, "MRPM") &&
	     strcmp(config->type, "MRPH") &&
	     strcmp(config->type, "MRDL") &&
	     strcmp(config->type, "MRDM")) ||
	    (strcmp(config->condition, "stock") &&
	     strcmp(config->condition, "unattached") &&
	     strcmp(config->condition, "empty") &&
	     strcmp(config->condition, "pass") &&
	     strcmp(config->condition, "select") &&
	     strcmp(config->condition, "fuse")))
		return -EINVAL;
	return 0;
}

int main(int argc, char **argv)
{
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct rusage client_usage = {};
	struct rusage fuse_usage = {};
	struct cell_config config;
	struct fxmark_result result = {};
	struct tree_count actual = {};
	struct tree_count expected = {};
	char physical_root[PATH_MAX];
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char cgroup_path[PATH_MAX];
	char fuse_stats_path[PATH_MAX];
	char fuse_control_path[PATH_MAX];
	char cgroup[PATH_MAX];
	char lower[PATH_MAX];
	char view[PATH_MAX];
	char root[PATH_MAX];
	char begin_command[PATH_MAX * 2];
	char end_command[PATH_MAX * 2];
	char fuse_stats[8192] = {};
	struct policy_stats policy_before = {};
	struct policy_stats policy_after = {};
	struct readdir_validation readdir = {};
	unsigned long long fuse_setup = 0;
	unsigned long long fuse_measured = 0;
	unsigned long long fuse_measured_opendir = 0;
	unsigned long long fuse_measured_readdir = 0;
	unsigned long long fuse_measured_releasedir = 0;
	unsigned long long fuse_phase_measured_acks = 0;
	unsigned long long fuse_phase_after_acks = 0;
	unsigned long long fuse_phase_invalid_commands = 0;
	unsigned long fuse_f_type_before = 0;
	unsigned long fuse_f_type_after = 0;
	pid_t fuse_pid = -1;
	bool policy_loaded = false;
	bool policy_parent_configured = false;
	bool fuse_mounted = false;
	bool cgroup_verified = false;
	bool pass = true;
	int fxmark_status = -1;
	int fuse_status = -1;
	int ret;

	if (parse_config(argc, argv, &config)) {
		fprintf(stderr,
			"usage: %s CONDITION FXMARK FUSE POLICY JSONL "
			"RAW_PREFIX WORK_ROOT CGROUP_ROOT TYPE NCORE DURATION "
			"TIMEOUT REPETITION\n", argv[0]);
		return 2;
	}
	namei_ext_remove_tree(config.work_root);
	if (mkdir_p(config.work_root) ||
	    path_format(lower, sizeof(lower), "%s/lower", config.work_root) ||
	    path_format(view, sizeof(view), "%s/view", config.work_root) ||
	    path_format(root, sizeof(root), "%s/bench", view) ||
	    path_format(cgroup, sizeof(cgroup), "%s/fxmark-%ld",
			config.cgroup_root, (long)getpid()) ||
	    path_format(stdout_path, sizeof(stdout_path), "%s.stdout",
			config.raw_prefix) ||
	    path_format(stderr_path, sizeof(stderr_path), "%s.stderr",
			config.raw_prefix) ||
	    path_format(cgroup_path, sizeof(cgroup_path), "%s.cgroup",
			config.raw_prefix) ||
	    path_format(fuse_stats_path, sizeof(fuse_stats_path), "%s.fuse.json",
			config.raw_prefix) ||
	    path_format(fuse_control_path, sizeof(fuse_control_path),
			"/tmp/namei-ext-fxmark-phase-%ld.sock",
			(long)getpid())) {
		fprintf(stderr, "setup path failed\n");
		return 1;
	}
	if (mkdir(cgroup, 0755)) {
		perror("mkdir cgroup");
		return 1;
	}

	if (!strcmp(config.condition, "select") ||
	    !strcmp(config.condition, "fuse")) {
		if (mkdir_p(lower) ||
		    path_format(physical_root, sizeof(physical_root),
				"%s/bench", lower) ||
		    mkdir_p(physical_root)) {
			pass = false;
			goto cleanup;
		}
	} else {
		if (mkdir_p(root) ||
		    snprintf(physical_root, sizeof(physical_root), "%s", root) >=
			    (int)sizeof(physical_root)) {
			pass = false;
			goto cleanup;
		}
	}
	if (precreate_readdir_directories(&config, physical_root) ||
	    (is_readdir_test(&config) && set_bpf_stats_enabled(false))) {
		pass = false;
		goto cleanup;
	}

	if (!strcmp(config.condition, "empty") ||
	    !strcmp(config.condition, "pass") ||
	    !strcmp(config.condition, "select")) {
		if (!strcmp(config.policy_object, "-")) {
			pass = false;
			goto cleanup;
		}
		if (!strcmp(config.condition, "select") &&
		    namei_ext_register_target(cgroup, lower, 1)) {
			pass = false;
			goto cleanup;
		}
		if (namei_ext_policy_load_attach(config.policy_object, cgroup,
						 &policy)) {
			pass = false;
			goto cleanup;
			}
			policy_loaded = true;
			if ((!strcmp(config.condition, "empty") &&
			     namei_ext_policy_parent_clear(cgroup)) ||
			    (strcmp(config.condition, "empty") &&
			     configure_policy_scopes(&config, cgroup,
						     physical_root))) {
				pass = false;
				goto cleanup;
		}
		policy_parent_configured = true;
		if (attached_program_stats(&policy, &policy_before)) {
			pass = false;
			goto cleanup;
		}
		snprintf(begin_command, sizeof(begin_command), "/bin/true");
		snprintf(end_command, sizeof(end_command), "/bin/true");
	} else if (!strcmp(config.condition, "fuse")) {
		struct statfs fs;

		if (mkdir_p(view) ||
		    start_fuse(&config, lower, view, fuse_stats_path,
			       fuse_control_path, &fuse_pid)) {
			pass = false;
			goto cleanup;
		}
		fuse_mounted = true;
		if (statfs(view, &fs) ||
		    (unsigned long)fs.f_type != FUSE_SUPER_MAGIC) {
			pass = false;
			goto cleanup;
		}
		fuse_f_type_before = (unsigned long)fs.f_type;
		if (path_format(begin_command, sizeof(begin_command),
				"%s --phase %s measured", config.fuse_binary,
				fuse_control_path) ||
		    path_format(end_command, sizeof(end_command),
				"%s --phase %s after", config.fuse_binary,
				fuse_control_path)) {
			pass = false;
			goto cleanup;
		}
	} else {
		snprintf(begin_command, sizeof(begin_command), "/bin/true");
		snprintf(end_command, sizeof(end_command), "/bin/true");
	}

	ret = run_fxmark(&config, root, cgroup, begin_command, end_command,
			 stdout_path, stderr_path, cgroup_path, &cgroup_verified,
			 &client_usage,
			 &fxmark_status);
	if (ret || fxmark_status || !cgroup_verified ||
	    parse_fxmark_output(stdout_path, &result) ||
	    result.ncpu != config.ncore ||
	    result.seconds < config.duration * 0.9 ||
	    result.seconds > config.duration * 1.2)
		pass = false;

	if (expected_tree(&config, &expected) ||
	    count_tree(physical_root, &actual) ||
	    actual.files != expected.files ||
	    actual.directories != expected.directories)
		pass = false;

	if (pass && is_readdir_test(&config) &&
	    validate_readdir_view(
		    &config, root, physical_root, cgroup,
		    (!strcmp(config.condition, "pass") ||
		     !strcmp(config.condition, "select")) ? &policy : NULL,
		    &readdir))
		pass = false;

	if (policy_loaded &&
	    (attached_program_stats(&policy, &policy_after) ||
	     policy_after.program_id != policy_before.program_id))
		pass = false;
	if (!strcmp(config.condition, "empty") &&
	    policy_after.run_count != policy_before.run_count)
		pass = false;

cleanup:
	if (fuse_mounted) {
		struct statfs fs;

		if (statfs(view, &fs) ||
		    (unsigned long)fs.f_type != FUSE_SUPER_MAGIC) {
			pass = false;
		} else {
			fuse_f_type_after = (unsigned long)fs.f_type;
		}
		if (stop_fuse(fuse_pid, view, &fuse_usage, &fuse_status) ||
		    fuse_status || read_file(fuse_stats_path, fuse_stats,
					    sizeof(fuse_stats)) ||
		    extract_u64(fuse_stats, "\"setup_total\":", &fuse_setup) ||
		    extract_u64(fuse_stats, "\"measured_total\":",
				&fuse_measured) ||
		    extract_u64(fuse_stats, "\"measured_opendir\":",
				&fuse_measured_opendir) ||
		    extract_u64(fuse_stats, "\"measured_readdir\":",
				&fuse_measured_readdir) ||
		    extract_u64(fuse_stats, "\"measured_releasedir\":",
				&fuse_measured_releasedir) ||
		    extract_u64(fuse_stats, "\"phase_measured_acks\":",
				&fuse_phase_measured_acks) ||
		    extract_u64(fuse_stats, "\"phase_after_acks\":",
				&fuse_phase_after_acks) ||
		    extract_u64(fuse_stats, "\"phase_invalid_commands\":",
				&fuse_phase_invalid_commands) ||
		    !fuse_setup)
			pass = false;
		if (is_readdir_test(&config) &&
		    (!fuse_measured_opendir || !fuse_measured_readdir ||
		     !fuse_measured_releasedir ||
		     fuse_phase_measured_acks != 1 ||
		     fuse_phase_after_acks != 1 ||
		     fuse_phase_invalid_commands))
			pass = false;
	}
	if (policy_parent_configured &&
	    namei_ext_policy_parent_global(cgroup))
		pass = false;
	if (policy_loaded) {
		if (namei_ext_policy_destroy(&policy))
			pass = false;
	}
	if (!strcmp(config.condition, "select") &&
	    namei_ext_clear_targets(cgroup))
		pass = false;
	if (unlink(fuse_control_path) && errno != ENOENT)
		pass = false;
	if (rmdir(cgroup))
		pass = false;

	if (write_observation(&config, pass, &result, &actual, &expected,
			      fxmark_status, fuse_status, &client_usage, &fuse_usage,
			      &policy_before, &policy_after, &readdir, fuse_setup,
			      fuse_measured, fuse_measured_opendir,
			      fuse_measured_readdir, fuse_measured_releasedir,
			      fuse_phase_measured_acks,
			      fuse_phase_after_acks,
			      fuse_phase_invalid_commands,
			      fuse_f_type_before,
			      fuse_f_type_after, cgroup_verified, stdout_path,
			      stderr_path, cgroup_path, fuse_stats_path))
		return 1;
	namei_ext_remove_tree(config.work_root);
	return pass ? 0 : 1;
}
