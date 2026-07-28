// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <bpf/bpf.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <limits.h>
#include <linux/bpf.h>
#include <namei_ext_harness.h>
#include <signal.h>
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

#define TARGET_ID 1
#define SHA256_HEX_LENGTH 64
#define MAX_SNAPSHOTS 6

enum checkpoint_restore_counter {
	CR_COUNTER_TOTAL = 0,
	CR_COUNTER_LOOKUP = 1,
	CR_COUNTER_SELECT = 2,
	CR_COUNTER_PASS = 3,
};

enum condition_kind {
	CONDITION_PATHVIRT,
	CONDITION_NAMEI_EXT,
	CONDITION_WITHDRAWN,
};

struct controller_paths {
	char fixture[PATH_MAX];
	char logical[PATH_MAX];
	char logical_workspace[PATH_MAX];
	char generation_a[PATH_MAX];
	char generation_b[PATH_MAX];
	char workspace_a[PATH_MAX];
	char workspace_b[PATH_MAX];
	char checkpoint_dir[PATH_MAX];
	char tmp_dir[PATH_MAX];
	char cgroup[PATH_MAX];
	char port_file[PATH_MAX];
	char app_observations[PATH_MAX];
	char pre_ready[PATH_MAX];
	char post_ready[PATH_MAX];
	char complete[PATH_MAX];
	char success[PATH_MAX];
	char failure[PATH_MAX];
	char lower_before[PATH_MAX];
	char lower_after[PATH_MAX];
	char coordinator_stdout[PATH_MAX];
	char coordinator_stderr[PATH_MAX];
	char launch_stdout[PATH_MAX];
	char launch_stderr[PATH_MAX];
	char command_stdout[PATH_MAX];
	char command_stderr[PATH_MAX];
	char restart_stdout[PATH_MAX];
	char restart_stderr[PATH_MAX];
	char quit_stdout[PATH_MAX];
	char quit_stderr[PATH_MAX];
	char process_cgroups[PATH_MAX];
	char checkpoint_images[PATH_MAX];
	char checkpoint_hashes[PATH_MAX];
};

struct controller_config {
	enum condition_kind condition;
	const char *condition_name;
	const char *result_dir;
	const char *dmtcp_root;
	const char *policy_path;
	const char *app_path;
	const char *cgroup_root;
	unsigned int timeout_seconds;
	uid_t runtime_uid;
	gid_t runtime_gid;
	char coordinator[PATH_MAX];
	char launch[PATH_MAX];
	char command[PATH_MAX];
	char restart[PATH_MAX];
	char dmtcp_library[PATH_MAX];
	struct controller_paths paths;
};

struct file_snapshot {
	char path[PATH_MAX];
	struct stat metadata;
	char sha256[SHA256_HEX_LENGTH + 1];
};

static uint64_t monotonic_ns(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now)) {
		perror("clock_gettime");
		exit(120);
	}
	return (uint64_t)now.tv_sec * 1000000000ULL + now.tv_nsec;
}

static void sleep_milliseconds(unsigned int milliseconds)
{
	struct timespec delay = {
		.tv_sec = milliseconds / 1000,
		.tv_nsec = (long)(milliseconds % 1000) * 1000000L,
	};

	while (nanosleep(&delay, &delay) && errno == EINTR)
		;
}

static void emit_case(FILE *output, const char *condition, const char *name,
		      bool pass, int error, const char *detail)
{
	fprintf(output,
		"{\"event\":\"checkpoint-restore-case\","
		"\"condition\":\"%s\",\"case\":\"%s\",\"errno\":%d,"
		"\"detail\":\"%s\",\"pass\":%s}\n",
		condition, name, error < 0 ? -error : error, detail,
		pass ? "true" : "false");
	fflush(output);
}

static void emit_counter(FILE *output, const char *condition,
			 const char *phase, const char *name, uint64_t value,
			 bool pass)
{
	fprintf(output,
		"{\"event\":\"checkpoint-restore-policy-counter\","
		"\"condition\":\"%s\",\"phase\":\"%s\","
		"\"counter\":\"%s\",\"value\":%llu,\"pass\":%s}\n",
		condition, phase, name, (unsigned long long)value,
		pass ? "true" : "false");
	fflush(output);
}

static void emit_lifecycle(FILE *output, const char *condition,
			   uint64_t checkpoint_ns, uint64_t update_ns,
			   uint64_t restart_ns, uint64_t total_ns, bool pass)
{
	fprintf(output,
		"{\"event\":\"checkpoint-restore-lifecycle\","
		"\"condition\":\"%s\",\"checkpoint_ns\":%llu,"
		"\"update_ns\":%llu,\"restart_ns\":%llu,"
		"\"total_ns\":%llu,\"pass\":%s}\n",
		condition, (unsigned long long)checkpoint_ns,
		(unsigned long long)update_ns,
		(unsigned long long)restart_ns, (unsigned long long)total_ns,
		pass ? "true" : "false");
	fflush(output);
}

static int make_directory(const char *path, mode_t mode)
{
	if (!mkdir(path, mode))
		return 0;
	return errno == EEXIST ? 0 : -errno;
}

static int build_paths(struct controller_config *config)
{
	struct controller_paths *paths = &config->paths;
	const char *result = config->result_dir;

	return namei_ext_path_join(paths->fixture, sizeof(paths->fixture),
				   result, "fixture") ||
		       namei_ext_path_join(paths->logical,
				   sizeof(paths->logical), paths->fixture,
				   "logical") ||
		       namei_ext_path_join(paths->logical_workspace,
				   sizeof(paths->logical_workspace),
				   paths->logical, "workspace") ||
		       namei_ext_path_join(paths->generation_a,
				   sizeof(paths->generation_a), paths->fixture,
				   "generation-a") ||
		       namei_ext_path_join(paths->generation_b,
				   sizeof(paths->generation_b), paths->fixture,
				   "generation-b") ||
		       namei_ext_path_join(paths->workspace_a,
				   sizeof(paths->workspace_a),
				   paths->generation_a, "workspace") ||
		       namei_ext_path_join(paths->workspace_b,
				   sizeof(paths->workspace_b),
				   paths->generation_b, "workspace") ||
		       namei_ext_path_join(paths->checkpoint_dir,
				   sizeof(paths->checkpoint_dir), result,
				   "checkpoint") ||
		       namei_ext_path_join(paths->tmp_dir,
				   sizeof(paths->tmp_dir), result, "tmp") ||
		       namei_ext_path_join(paths->cgroup,
				   sizeof(paths->cgroup), config->cgroup_root,
				   config->condition_name) ||
		       namei_ext_path_join(paths->port_file,
				   sizeof(paths->port_file), result,
				   "coordinator.port") ||
		       namei_ext_path_join(paths->app_observations,
				   sizeof(paths->app_observations), result,
				   "application-observations.jsonl") ||
		       namei_ext_path_join(paths->pre_ready,
				   sizeof(paths->pre_ready), result,
				   "pre-ready") ||
		       namei_ext_path_join(paths->post_ready,
				   sizeof(paths->post_ready), result,
				   "post-ready") ||
		       namei_ext_path_join(paths->complete,
				   sizeof(paths->complete), result, "complete") ||
		       namei_ext_path_join(paths->success,
				   sizeof(paths->success), result, "success") ||
		       namei_ext_path_join(paths->failure,
				   sizeof(paths->failure), result, "failure") ||
		       namei_ext_path_join(paths->lower_before,
				   sizeof(paths->lower_before), result,
				   "lower-before.jsonl") ||
		       namei_ext_path_join(paths->lower_after,
				   sizeof(paths->lower_after), result,
				   "lower-after.jsonl") ||
		       namei_ext_path_join(paths->coordinator_stdout,
				   sizeof(paths->coordinator_stdout), result,
				   "dmtcp-coordinator.stdout.log") ||
		       namei_ext_path_join(paths->coordinator_stderr,
				   sizeof(paths->coordinator_stderr), result,
				   "dmtcp-coordinator.stderr.log") ||
		       namei_ext_path_join(paths->launch_stdout,
				   sizeof(paths->launch_stdout), result,
				   "dmtcp-launch.stdout.log") ||
		       namei_ext_path_join(paths->launch_stderr,
				   sizeof(paths->launch_stderr), result,
				   "dmtcp-launch.stderr.log") ||
		       namei_ext_path_join(paths->command_stdout,
				   sizeof(paths->command_stdout), result,
				   "dmtcp-command.stdout.log") ||
		       namei_ext_path_join(paths->command_stderr,
				   sizeof(paths->command_stderr), result,
				   "dmtcp-command.stderr.log") ||
		       namei_ext_path_join(paths->restart_stdout,
				   sizeof(paths->restart_stdout), result,
				   "dmtcp-restart.stdout.log") ||
		       namei_ext_path_join(paths->restart_stderr,
				   sizeof(paths->restart_stderr), result,
				   "dmtcp-restart.stderr.log") ||
		       namei_ext_path_join(paths->quit_stdout,
				   sizeof(paths->quit_stdout), result,
				   "dmtcp-quit.stdout.log") ||
		       namei_ext_path_join(paths->quit_stderr,
				   sizeof(paths->quit_stderr), result,
				   "dmtcp-quit.stderr.log") ||
		       namei_ext_path_join(paths->process_cgroups,
				   sizeof(paths->process_cgroups), result,
				   "process-cgroups.txt") ||
		       namei_ext_path_join(paths->checkpoint_images,
				   sizeof(paths->checkpoint_images), result,
				   "checkpoint-images.txt") ||
		       namei_ext_path_join(paths->checkpoint_hashes,
				   sizeof(paths->checkpoint_hashes), result,
				   "checkpoint-images.sha256");
}

static int write_fixture_file(const char *directory, const char *name,
			      const char *content)
{
	char path[PATH_MAX];
	int ret;

	ret = namei_ext_path_join(path, sizeof(path), directory, name);
	return ret ? ret : namei_ext_write_text(path, content);
}

static int setup_fixture(struct controller_config *config)
{
	struct controller_paths *paths = &config->paths;
	int ret;

	const struct {
		const char *path;
		mode_t mode;
	} directories[] = {
		{ config->result_dir, 0755 },
		{ paths->fixture, 0755 },
		{ paths->logical, 0755 },
		{ paths->generation_a, 0755 },
		{ paths->generation_b, 0755 },
		{ paths->workspace_a, 0755 },
		{ paths->workspace_b, 0755 },
		{ paths->checkpoint_dir, 0755 },
		{ paths->tmp_dir, 0700 },
	};

	for (unsigned int index = 0;
	     index < sizeof(directories) / sizeof(directories[0]); index++) {
		ret = make_directory(directories[index].path,
				     directories[index].mode);
		if (ret)
			return ret;
	}
	if (access(paths->logical_workspace, F_OK) == 0)
		return -EEXIST;
	if (errno != ENOENT)
		return -errno;

	ret = write_fixture_file(paths->workspace_a, "state.txt",
				 "generation-a\n");
	if (!ret)
		ret = write_fixture_file(paths->workspace_a, "shared.txt",
					 "shared-common\n");
	if (!ret)
		ret = write_fixture_file(paths->workspace_a, "stale.txt",
					 "stale-only\n");
	if (!ret)
		ret = write_fixture_file(paths->workspace_b, "state.txt",
					 "generation-b\n");
	if (!ret)
		ret = write_fixture_file(paths->workspace_b, "shared.txt",
					 "shared-common\n");
	if (!ret)
		ret = write_fixture_file(paths->workspace_b, "new.txt",
					 "new-only\n");
	return ret;
}

static int sha256_file(const char *path,
		       char output[SHA256_HEX_LENGTH + 1])
{
	char buffer[PATH_MAX + SHA256_HEX_LENGTH + 8] = {};
	ssize_t total = 0;
	int pipe_fd[2];
	int status;
	pid_t child;

	if (pipe2(pipe_fd, O_CLOEXEC))
		return -errno;
	child = fork();
	if (child < 0) {
		int saved_errno = errno;

		close(pipe_fd[0]);
		close(pipe_fd[1]);
		return -saved_errno;
	}
	if (!child) {
		if (dup2(pipe_fd[1], STDOUT_FILENO) < 0)
			_exit(120);
		close(pipe_fd[0]);
		close(pipe_fd[1]);
		execlp("sha256sum", "sha256sum", path, (char *)NULL);
		_exit(121);
	}
	close(pipe_fd[1]);
	while (total < (ssize_t)sizeof(buffer) - 1) {
		ssize_t count = read(pipe_fd[0], buffer + total,
				     sizeof(buffer) - 1 - total);

		if (count > 0) {
			total += count;
			continue;
		}
		if (!count)
			break;
		if (errno == EINTR)
			continue;
		close(pipe_fd[0]);
		kill(child, SIGKILL);
		waitpid(child, NULL, 0);
		return -errno;
	}
	close(pipe_fd[0]);
	if (waitpid(child, &status, 0) != child || !WIFEXITED(status) ||
	    WEXITSTATUS(status))
		return -ECHILD;
	if (total < SHA256_HEX_LENGTH)
		return -EIO;
	for (unsigned int index = 0; index < SHA256_HEX_LENGTH; index++) {
		char value = buffer[index];

		if (!((value >= '0' && value <= '9') ||
		      (value >= 'a' && value <= 'f')))
			return -EINVAL;
		output[index] = value;
	}
	output[SHA256_HEX_LENGTH] = '\0';
	return 0;
}

static int capture_snapshots(const struct controller_config *config,
			     struct file_snapshot snapshots[MAX_SNAPSHOTS])
{
	static const char *names[] = {
		"state.txt", "shared.txt", "stale.txt",
		"state.txt", "shared.txt", "new.txt",
	};
	int ret;

	for (unsigned int index = 0; index < MAX_SNAPSHOTS; index++) {
		const char *directory =
			index < 3 ? config->paths.workspace_a :
				    config->paths.workspace_b;

		ret = namei_ext_path_join(snapshots[index].path,
					  sizeof(snapshots[index].path),
					  directory, names[index]);
		if (ret)
			return ret;
		if (stat(snapshots[index].path, &snapshots[index].metadata))
			return -errno;
		ret = sha256_file(snapshots[index].path,
				  snapshots[index].sha256);
		if (ret)
			return ret;
	}
	return 0;
}

static int write_snapshot_manifest(const char *path, const char *phase,
				   const struct file_snapshot snapshots[MAX_SNAPSHOTS])
{
	FILE *output = fopen(path, "w");

	if (!output)
		return -errno;
	for (unsigned int index = 0; index < MAX_SNAPSHOTS; index++) {
		const struct stat *metadata = &snapshots[index].metadata;

		fprintf(output,
			"{\"event\":\"checkpoint-restore-lower\","
			"\"phase\":\"%s\",\"path\":\"%s\","
			"\"dev\":%llu,\"ino\":%llu,\"mode\":%u,"
			"\"size\":%lld,\"mtime_sec\":%lld,"
			"\"mtime_nsec\":%ld,\"sha256\":\"%s\"}\n",
			phase, snapshots[index].path,
			(unsigned long long)metadata->st_dev,
			(unsigned long long)metadata->st_ino,
			(unsigned int)metadata->st_mode,
			(long long)metadata->st_size,
			(long long)metadata->st_mtim.tv_sec,
			metadata->st_mtim.tv_nsec, snapshots[index].sha256);
	}
	return fclose(output) ? -errno : 0;
}

static int validate_snapshots(
	const struct file_snapshot before[MAX_SNAPSHOTS],
	struct file_snapshot after[MAX_SNAPSHOTS])
{
	for (unsigned int index = 0; index < MAX_SNAPSHOTS; index++) {
		const struct stat *left = &before[index].metadata;
		const struct stat *right = &after[index].metadata;

		if (strcmp(before[index].path, after[index].path) ||
		    left->st_dev != right->st_dev ||
		    left->st_ino != right->st_ino ||
		    left->st_mode != right->st_mode ||
		    left->st_size != right->st_size ||
		    left->st_mtim.tv_sec != right->st_mtim.tv_sec ||
		    left->st_mtim.tv_nsec != right->st_mtim.tv_nsec ||
		    strcmp(before[index].sha256, after[index].sha256))
			return -EIO;
	}
	return 0;
}

static int open_log(const char *path)
{
	return open(path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
}

static void set_child_environment(const struct controller_config *config,
				  const char *port, bool restart_phase)
{
	char mapping[PATH_MAX * 2 + 2];
	char library_path[PATH_MAX * 2];
	const char *existing_library_path = getenv("LD_LIBRARY_PATH");

	setenv("DMTCP_CHECKPOINT_DIR", config->paths.checkpoint_dir, 1);
	setenv("DMTCP_TMPDIR", config->paths.tmp_dir, 1);
	setenv("DMTCP_GZIP", "0", 1);
	if (port)
		setenv("DMTCP_COORD_PORT", port, 1);
	if (config->condition == CONDITION_PATHVIRT) {
		const char *physical = restart_phase ?
			config->paths.workspace_b : config->paths.workspace_a;

		if (snprintf(mapping, sizeof(mapping), "%s:%s",
			     config->paths.logical_workspace, physical) >=
		    (int)sizeof(mapping))
			_exit(122);
		setenv("DMTCP_PATH_MAPPING", mapping, 1);
	} else {
		unsetenv("DMTCP_PATH_MAPPING");
	}
	if (existing_library_path && existing_library_path[0]) {
		if (snprintf(library_path, sizeof(library_path), "%s:%s",
			     config->dmtcp_library,
			     existing_library_path) >=
		    (int)sizeof(library_path))
			_exit(123);
	} else if (snprintf(library_path, sizeof(library_path), "%s",
			    config->dmtcp_library) >=
		   (int)sizeof(library_path)) {
		_exit(124);
	}
	setenv("LD_LIBRARY_PATH", library_path, 1);

	setenv("NAMEI_EXT_CR_LOGICAL_WORKSPACE",
	       config->paths.logical_workspace, 1);
	setenv("NAMEI_EXT_CR_PHYSICAL_A", config->paths.workspace_a, 1);
	setenv("NAMEI_EXT_CR_PHYSICAL_B", config->paths.workspace_b, 1);
	setenv("NAMEI_EXT_CR_APP_OBSERVATIONS",
	       config->paths.app_observations, 1);
	setenv("NAMEI_EXT_CR_PRE_READY", config->paths.pre_ready, 1);
	setenv("NAMEI_EXT_CR_POST_READY", config->paths.post_ready, 1);
	setenv("NAMEI_EXT_CR_COMPLETE", config->paths.complete, 1);
	setenv("NAMEI_EXT_CR_SUCCESS", config->paths.success, 1);
	setenv("NAMEI_EXT_CR_FAILURE", config->paths.failure, 1);
	setenv("NAMEI_EXT_CR_EXPECT_POST_FAILURE",
	       config->condition == CONDITION_WITHDRAWN ? "1" : "0", 1);
}

static pid_t spawn_process(const struct controller_config *config,
			   char *const argv[], const char *stdout_path,
			   const char *stderr_path, const char *cgroup,
			   const char *port, bool restart_phase)
{
	pid_t child = fork();

	if (child < 0)
		return -errno;
	if (!child) {
		int stdout_fd;
		int stderr_fd;

		setpgid(0, 0);
		if (cgroup && namei_ext_move_self_to_cgroup(cgroup))
			_exit(125);
		stdout_fd = open_log(stdout_path);
		stderr_fd = open_log(stderr_path);
		if (stdout_fd < 0 || stderr_fd < 0 ||
		    dup2(stdout_fd, STDOUT_FILENO) < 0 ||
		    dup2(stderr_fd, STDERR_FILENO) < 0)
			_exit(126);
		close(stdout_fd);
		close(stderr_fd);
		set_child_environment(config, port, restart_phase);
		if (geteuid() == 0) {
			if (setgroups(0, NULL) ||
			    setgid(config->runtime_gid) ||
			    setuid(config->runtime_uid))
				_exit(128);
		} else if (geteuid() != config->runtime_uid ||
			   getegid() != config->runtime_gid) {
			_exit(128);
		}
		execv(argv[0], argv);
		_exit(127);
	}
	return child;
}

static int wait_child(pid_t child, unsigned int timeout_seconds,
		      int *status_out)
{
	uint64_t deadline = monotonic_ns() +
		(uint64_t)timeout_seconds * 1000000000ULL;

	while (monotonic_ns() < deadline) {
		pid_t waited = waitpid(child, status_out, WNOHANG);

		if (waited == child)
			return 0;
		if (waited < 0 && errno != EINTR)
			return -errno;
		sleep_milliseconds(10);
	}
	if (kill(-child, SIGKILL) && errno != ESRCH)
		return -errno;
	if (waitpid(child, status_out, 0) != child && errno != ECHILD)
		return -errno;
	return -ETIMEDOUT;
}

static void terminate_process(pid_t child)
{
	int status;

	if (child <= 0)
		return;
	if (waitpid(child, &status, WNOHANG) == child)
		return;
	if (kill(-child, SIGKILL) && errno != ESRCH)
		return;
	waitpid(child, &status, 0);
}

static int wait_for_file(const char *path, unsigned int timeout_seconds)
{
	uint64_t deadline = monotonic_ns() +
		(uint64_t)timeout_seconds * 1000000000ULL;

	while (monotonic_ns() < deadline) {
		if (!access(path, F_OK))
			return 0;
		if (errno != ENOENT)
			return -errno;
		sleep_milliseconds(10);
	}
	return -ETIMEDOUT;
}

static int read_port(const char *path, unsigned int timeout_seconds,
		     char output[16])
{
	uint64_t deadline = monotonic_ns() +
		(uint64_t)timeout_seconds * 1000000000ULL;

	while (monotonic_ns() < deadline) {
		char buffer[32] = {};
		ssize_t count;
		int fd = open(path, O_RDONLY | O_CLOEXEC);

		if (fd >= 0) {
			count = read(fd, buffer, sizeof(buffer) - 1);
			close(fd);
			if (count > 0) {
				char *end = NULL;
				unsigned long port = strtoul(buffer, &end, 10);

				if (end != buffer && port > 0 && port <= 65535) {
					snprintf(output, 16, "%lu", port);
					return 0;
				}
			}
		} else if (errno != ENOENT) {
			return -errno;
		}
		sleep_milliseconds(10);
	}
	return -ETIMEDOUT;
}

static int record_process_cgroup(const char *output_path, const char *phase,
				 pid_t pid)
{
	char proc_path[64];
	char buffer[1024] = {};
	ssize_t count;
	int input;
	FILE *output;

	if (snprintf(proc_path, sizeof(proc_path), "/proc/%ld/cgroup",
		     (long)pid) >= (int)sizeof(proc_path))
		return -ENAMETOOLONG;
	input = open(proc_path, O_RDONLY | O_CLOEXEC);
	if (input < 0)
		return -errno;
	count = read(input, buffer, sizeof(buffer) - 1);
	close(input);
	if (count <= 0)
		return count < 0 ? -errno : -EIO;
	for (ssize_t index = 0; index < count; index++) {
		if (buffer[index] == '\n' || buffer[index] == '\r')
			buffer[index] = ' ';
	}
	output = fopen(output_path, "a");
	if (!output)
		return -errno;
	fprintf(output, "phase=%s pid=%ld cgroup=%s\n", phase, (long)pid,
		buffer);
	return fclose(output) ? -errno : 0;
}

static int run_process(const struct controller_config *config,
		       char *const argv[], const char *stdout_path,
		       const char *stderr_path, const char *port,
		       bool restart_phase, int *status_out)
{
	pid_t child = spawn_process(config, argv, stdout_path, stderr_path,
				    NULL, port, restart_phase);
	int ret;

	if (child < 0)
		return child;
	ret = wait_child(child, config->timeout_seconds, status_out);
	return ret;
}

static int find_checkpoint_image(const struct controller_config *config,
				 char output[PATH_MAX])
{
	struct dirent *entry;
	DIR *directory;
	unsigned int matches = 0;
	int ret = 0;

	directory = opendir(config->paths.checkpoint_dir);
	if (!directory)
		return -errno;
	errno = 0;
	while ((entry = readdir(directory))) {
		struct stat metadata;
		char candidate[PATH_MAX];
		size_t length = strlen(entry->d_name);

		if (strncmp(entry->d_name, "ckpt_", 5) || length < 12 ||
		    strcmp(entry->d_name + length - 6, ".dmtcp"))
			continue;
		ret = namei_ext_path_join(candidate, sizeof(candidate),
					  config->paths.checkpoint_dir,
					  entry->d_name);
		if (ret)
			break;
		if (stat(candidate, &metadata)) {
			ret = -errno;
			break;
		}
		if (!S_ISREG(metadata.st_mode))
			continue;
		matches++;
		if (matches == 1 &&
		    snprintf(output, PATH_MAX, "%s", candidate) >= PATH_MAX) {
			ret = -ENAMETOOLONG;
			break;
		}
	}
	if (!ret && errno)
		ret = -errno;
	if (closedir(directory) && !ret)
		ret = -errno;
	if (ret)
		return ret;
	return matches == 1 ? 0 : matches ? -E2BIG : -ENOENT;
}

static int record_checkpoint_image(const struct controller_config *config,
				   const char *image)
{
	char hash[SHA256_HEX_LENGTH + 1];
	const char *relative;
	size_t result_length = strlen(config->result_dir);
	FILE *output;
	int ret = sha256_file(image, hash);

	if (ret)
		return ret;
	if (strncmp(image, config->result_dir, result_length) ||
	    image[result_length] != '/' || !image[result_length + 1])
		return -EXDEV;
	relative = image + result_length + 1;
	output = fopen(config->paths.checkpoint_images, "w");
	if (!output)
		return -errno;
	fprintf(output, "%s\n", relative);
	if (fclose(output))
		return -errno;
	output = fopen(config->paths.checkpoint_hashes, "w");
	if (!output)
		return -errno;
	fprintf(output, "%s  %s\n", hash, relative);
	return fclose(output) ? -errno : 0;
}

static int policy_program_id(struct namei_ext_harness_policy *policy,
			     uint32_t *id_out)
{
	struct bpf_prog_info info = {};
	uint32_t length = sizeof(info);

	if (bpf_obj_get_info_by_fd(policy->prog_fd, &info, &length))
		return -errno;
	if (!info.id)
		return -EINVAL;
	*id_out = info.id;
	return 0;
}

static int configure_policy(struct controller_config *config,
			    struct namei_ext_harness_policy *policy,
			    uint64_t *cgroup_id_out, uint32_t *program_id_out)
{
	int ret;

	if (make_directory(config->paths.cgroup, 0755))
		return -errno;
	ret = namei_ext_cgroup_id(config->paths.cgroup, cgroup_id_out);
	if (ret)
		return ret;
	ret = namei_ext_register_target(config->paths.cgroup,
					 config->paths.workspace_a, TARGET_ID);
	if (ret)
		return ret;
	ret = namei_ext_policy_parent_exact(config->paths.cgroup,
					    config->paths.logical);
	if (ret)
		return ret;
	if (namei_ext_policy_load_attach(config->policy_path,
					  config->paths.cgroup, policy))
		return -errno;
	ret = policy_program_id(policy, program_id_out);
	if (ret)
		return ret;
	return namei_ext_component_map_update(
		policy, "checkpoint_restore_views", *cgroup_id_out,
		config->paths.logical, "workspace", TARGET_ID);
}

static int collect_counter(FILE *output,
			   struct namei_ext_harness_policy *policy,
			   const struct controller_config *config,
			   const char *phase, uint32_t key, const char *name,
			   uint64_t *value_out, bool require_positive)
{
	int ret = namei_ext_policy_counter(
		policy, "checkpoint_restore_counters", key, value_out);
	bool pass = !ret && (!require_positive || *value_out > 0);

	emit_counter(output, config->condition_name, phase, name,
		     ret ? 0 : *value_out, pass);
	return pass ? 0 : (ret ? ret : -ERANGE);
}

static int validate_exit_status(int status, int expected)
{
	if (!WIFEXITED(status))
		return -ECHILD;
	return WEXITSTATUS(status) == expected ? 0 : -EPROTO;
}

static int run_lifecycle(struct controller_config *config, FILE *output)
{
	struct file_snapshot before[MAX_SNAPSHOTS] = {};
	struct file_snapshot after[MAX_SNAPSHOTS] = {};
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char checkpoint_image[PATH_MAX] = {};
	char port[16] = {};
	char *coordinator_argv[] = {
		config->coordinator, "--quiet", "--coord-port", "0",
		"--port-file", config->paths.port_file, "--timeout", "120",
		"--ckptdir", config->paths.checkpoint_dir, NULL,
	};
	char *launch_pathvirt_argv[] = {
		config->launch, "--join-coordinator", "--pathvirt",
		(char *)config->app_path, NULL,
	};
	char *launch_plain_argv[] = {
		config->launch, "--join-coordinator",
		(char *)config->app_path, NULL,
	};
	char *command_argv[] = {
		config->command, "--json", "--kcheckpoint", NULL,
	};
	char *quit_argv[] = {
		config->command, "--json", "--quit", NULL,
	};
	char *restart_argv[] = {
		config->restart, "--join-coordinator", "--quiet",
		checkpoint_image, NULL,
	};
	uint64_t lifecycle_start = monotonic_ns();
	uint64_t checkpoint_start = 0;
	uint64_t checkpoint_end = 0;
	uint64_t update_start = 0;
	uint64_t update_end = 0;
	uint64_t restart_start = 0;
	uint64_t restart_end = 0;
	uint64_t pre_select = 0;
	uint64_t post_select = 0;
	uint64_t cgroup_id = 0;
	uint32_t program_id = 0;
	pid_t coordinator_pid = -1;
	pid_t launch_pid = -1;
	pid_t restart_pid = -1;
	int launch_status = 0;
	int command_status = 0;
	int restart_status = 0;
	int quit_status = 0;
	int fails = 0;
	int ret;
	bool policy_configured = false;
	bool cgroup_created = false;

	ret = setup_fixture(config);
	emit_case(output, config->condition_name, "setup_fixture", !ret,
		  ret, "prepared immutable A/B trees and absent logical workspace");
	if (ret)
		return 1;
	ret = capture_snapshots(config, before);
	if (!ret)
		ret = write_snapshot_manifest(config->paths.lower_before,
					      "before", before);
	emit_case(output, config->condition_name, "capture_lower_before", !ret,
		  ret, "captured lower-object identity and SHA-256");
	if (ret)
		return 1;

	if (config->condition != CONDITION_PATHVIRT) {
		cgroup_created = true;
		ret = configure_policy(config, &policy, &cgroup_id, &program_id);
		emit_case(output, config->condition_name, "configure_policy", !ret,
			  ret, "attached exact-parent policy and selected target A");
		if (ret) {
			fails++;
			goto cleanup;
		}
		policy_configured = true;
		fprintf(output,
			"{\"event\":\"checkpoint-restore-policy\","
			"\"condition\":\"%s\",\"program_id\":%u,"
			"\"cgroup_id\":%llu,\"target_id\":%u,"
			"\"pass\":true}\n",
			config->condition_name, program_id,
			(unsigned long long)cgroup_id, TARGET_ID);
		fflush(output);
	}

	coordinator_pid = spawn_process(
		config, coordinator_argv, config->paths.coordinator_stdout,
		config->paths.coordinator_stderr, NULL, NULL, false);
	ret = coordinator_pid < 0 ? (int)coordinator_pid :
		read_port(config->paths.port_file, config->timeout_seconds, port);
	emit_case(output, config->condition_name, "start_coordinator", !ret,
		  ret, "started isolated DMTCP coordinator");
	if (ret) {
		fails++;
		goto cleanup;
	}

	launch_pid = spawn_process(
		config,
		config->condition == CONDITION_PATHVIRT ?
			launch_pathvirt_argv : launch_plain_argv,
		config->paths.launch_stdout, config->paths.launch_stderr,
		config->condition == CONDITION_PATHVIRT ?
			NULL : config->paths.cgroup,
		port, false);
	ret = launch_pid < 0 ? (int)launch_pid :
		wait_for_file(config->paths.pre_ready, config->timeout_seconds);
	if (!ret)
		ret = record_process_cgroup(config->paths.process_cgroups,
					    "pre-checkpoint", launch_pid);
	emit_case(output, config->condition_name, "pre_checkpoint_oracle",
		  !ret, ret, "application resolved generation A and closed path descriptors");
	if (ret) {
		fails++;
		goto cleanup;
	}
	if (policy_configured &&
	    collect_counter(output, &policy, config, "pre-checkpoint",
			    CR_COUNTER_SELECT, "select", &pre_select, true)) {
		fails++;
		goto cleanup;
	}

	checkpoint_start = monotonic_ns();
	ret = run_process(config, command_argv, config->paths.command_stdout,
			  config->paths.command_stderr, port, false,
			  &command_status);
	checkpoint_end = monotonic_ns();
	if (!ret)
		ret = validate_exit_status(command_status, 0);
	if (!ret)
		ret = wait_child(launch_pid, config->timeout_seconds,
				 &launch_status);
	if (!ret)
		ret = find_checkpoint_image(config, checkpoint_image);
	if (!ret)
		ret = record_checkpoint_image(config, checkpoint_image);
	emit_case(output, config->condition_name, "checkpoint", !ret, ret,
		  "DMTCP created a checkpoint image and killed the original worker");
	if (ret) {
		fails++;
		goto cleanup;
	}
	launch_pid = -1;

	update_start = monotonic_ns();
	if (config->condition == CONDITION_NAMEI_EXT) {
		ret = namei_ext_register_target(config->paths.cgroup,
						 config->paths.workspace_b,
						 TARGET_ID);
	} else if (config->condition == CONDITION_WITHDRAWN) {
		ret = namei_ext_component_map_delete(
			&policy, "checkpoint_restore_views", cgroup_id,
			config->paths.logical, "workspace");
	} else {
		ret = 0;
	}
	update_end = monotonic_ns();
	emit_case(output, config->condition_name, "update_mapping", !ret, ret,
		  config->condition == CONDITION_NAMEI_EXT ?
			  "atomically replaced target ID 1 with generation B" :
		  config->condition == CONDITION_WITHDRAWN ?
			  "withdrew the restart-time component mapping" :
			  "restart environment will supply generation B mapping");
	if (ret) {
		fails++;
		goto cleanup;
	}

	restart_start = monotonic_ns();
	restart_pid = spawn_process(
		config, restart_argv, config->paths.restart_stdout,
		config->paths.restart_stderr,
		config->condition == CONDITION_PATHVIRT ?
			NULL : config->paths.cgroup,
		port, true);
	if (restart_pid < 0) {
		ret = restart_pid;
	} else if (config->condition == CONDITION_WITHDRAWN) {
		ret = wait_for_file(config->paths.failure,
				    config->timeout_seconds);
		if (!ret)
			ret = wait_child(restart_pid, config->timeout_seconds,
					 &restart_status);
		if (!ret)
			ret = validate_exit_status(restart_status, 126);
	} else {
		ret = wait_for_file(config->paths.post_ready,
				    config->timeout_seconds);
		if (!ret)
			ret = record_process_cgroup(config->paths.process_cgroups,
						    "post-restart",
						    restart_pid);
		if (!ret)
			ret = namei_ext_write_text(config->paths.complete,
						   "complete\n");
		if (!ret)
			ret = wait_for_file(config->paths.success,
					    config->timeout_seconds);
		if (!ret)
			ret = wait_child(restart_pid, config->timeout_seconds,
					 &restart_status);
		if (!ret)
			ret = validate_exit_status(restart_status, 0);
	}
	restart_end = monotonic_ns();
	emit_case(output, config->condition_name, "restart_oracle", !ret, ret,
		  config->condition == CONDITION_WITHDRAWN ?
			  "withdrawn mapping produced the expected post-restart failure" :
			  "restored application resolved generation B through the same path");
	if (ret) {
		fails++;
		goto cleanup;
	}
	restart_pid = -1;

	if (policy_configured) {
		ret = collect_counter(output, &policy, config, "post-restart",
				      CR_COUNTER_SELECT, "select",
				      &post_select, true);
		if (!ret && config->condition == CONDITION_NAMEI_EXT &&
		    post_select <= pre_select)
			ret = -ERANGE;
		emit_case(output, config->condition_name,
			  "policy_restart_attribution", !ret, ret,
			  config->condition == CONDITION_NAMEI_EXT ?
				  "SELECT count increased after restart" :
				  "pre-checkpoint SELECT attribution preserved");
		if (ret) {
			fails++;
			goto cleanup;
		}
	}

	ret = capture_snapshots(config, after);
	if (!ret)
		ret = write_snapshot_manifest(config->paths.lower_after,
					      "after", after);
	if (!ret)
		ret = validate_snapshots(before, after);
	emit_case(output, config->condition_name, "lower_objects_unchanged",
		  !ret, ret, "lower object identity, metadata, and SHA-256 remained unchanged");
	if (ret)
		fails++;

cleanup:
	if (coordinator_pid > 0) {
		ret = run_process(config, quit_argv, config->paths.quit_stdout,
				  config->paths.quit_stderr, port, false,
				  &quit_status);
		if (!ret)
			ret = validate_exit_status(quit_status, 0);
		if (!ret)
			ret = wait_child(coordinator_pid,
					 config->timeout_seconds,
					 &command_status);
		if (ret) {
			terminate_process(coordinator_pid);
			fails++;
		}
		coordinator_pid = -1;
	}
	terminate_process(launch_pid);
	terminate_process(restart_pid);
	terminate_process(coordinator_pid);
	if (policy_configured) {
		if (namei_ext_policy_destroy(&policy))
			fails++;
		if (namei_ext_clear_targets(config->paths.cgroup))
			fails++;
		if (namei_ext_policy_parent_clear(config->paths.cgroup))
			fails++;
	}
	if (cgroup_created && rmdir(config->paths.cgroup))
		fails++;
	emit_lifecycle(output, config->condition_name,
		       checkpoint_end > checkpoint_start ?
			       checkpoint_end - checkpoint_start : 0,
		       update_end > update_start ? update_end - update_start : 0,
		       restart_end > restart_start ?
			       restart_end - restart_start : 0,
		       monotonic_ns() - lifecycle_start, !fails);
	fprintf(output,
		"{\"event\":\"checkpoint-restore-summary\","
		"\"condition\":\"%s\",\"failures\":%d,\"pass\":%s}\n",
		config->condition_name, fails, fails ? "false" : "true");
	fflush(output);
	return fails ? 1 : 0;
}

static int parse_condition(const char *value, enum condition_kind *condition)
{
	if (!strcmp(value, "pathvirt"))
		*condition = CONDITION_PATHVIRT;
	else if (!strcmp(value, "namei_ext"))
		*condition = CONDITION_NAMEI_EXT;
	else if (!strcmp(value, "withdrawn"))
		*condition = CONDITION_WITHDRAWN;
	else
		return -EINVAL;
	return 0;
}

static int build_runtime_paths(struct controller_config *config)
{
	return namei_ext_path_join(config->coordinator,
				   sizeof(config->coordinator),
				   config->dmtcp_root,
				   "bin/dmtcp_coordinator") ||
		       namei_ext_path_join(config->launch,
				   sizeof(config->launch), config->dmtcp_root,
				   "bin/dmtcp_launch") ||
		       namei_ext_path_join(config->command,
				   sizeof(config->command), config->dmtcp_root,
				   "bin/dmtcp_command") ||
		       namei_ext_path_join(config->restart,
				   sizeof(config->restart), config->dmtcp_root,
				   "bin/dmtcp_restart") ||
		       namei_ext_path_join(config->dmtcp_library,
				   sizeof(config->dmtcp_library),
				   config->dmtcp_root, "lib/dmtcp");
}

int main(int argc, char **argv)
{
	struct controller_config config = {};
	struct stat result_metadata;
	FILE *output;
	char *end = NULL;
	unsigned long timeout;
	int ret;

	if (argc != 9) {
		fprintf(stderr,
			"usage: %s CONDITION OUT_JSONL RESULT_DIR DMTCP_ROOT POLICY APP CGROUP_ROOT TIMEOUT\n",
			argv[0]);
		return 2;
	}
	ret = parse_condition(argv[1], &config.condition);
	if (ret)
		return 2;
	config.condition_name = argv[1];
	config.result_dir = argv[3];
	config.dmtcp_root = argv[4];
	config.policy_path = argv[5];
	config.app_path = argv[6];
	config.cgroup_root = argv[7];
	timeout = strtoul(argv[8], &end, 10);
	if (!end || *end || !timeout || timeout > 300)
		return 2;
	config.timeout_seconds = timeout;
	if (build_runtime_paths(&config) || build_paths(&config))
		return 2;
	if (stat(config.result_dir, &result_metadata)) {
		perror("checkpoint_restore result directory");
		return 2;
	}
	config.runtime_uid = result_metadata.st_uid;
	config.runtime_gid = result_metadata.st_gid;
	if (access(config.coordinator, X_OK) ||
	    access(config.launch, X_OK) ||
	    access(config.command, X_OK) ||
	    access(config.restart, X_OK) ||
	    access(config.app_path, X_OK) ||
	    (config.condition != CONDITION_PATHVIRT &&
	     access(config.policy_path, R_OK))) {
		perror("checkpoint_restore runtime artifact");
		return 2;
	}
	output = fopen(argv[2], "a");
	if (!output) {
		perror("checkpoint_restore observations");
		return 2;
	}
	ret = run_lifecycle(&config, output);
	if (fclose(output))
		return 2;
	return ret;
}
