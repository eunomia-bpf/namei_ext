// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "namei_ext_harness.h"

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <linux/magic.h>
#include <limits.h>
#include <math.h>
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
	return -EINVAL;
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
		      const char *view, const char *stats, pid_t *pid_out)
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
		      stats, (char *)NULL);
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
	if (umount2(mountpoint, 0) && umount2(mountpoint, MNT_DETACH))
		return -errno;
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

static int attached_program_id(struct namei_ext_harness_policy *policy,
			       uint32_t *program_id)
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
	*program_id = info.id;
	return 0;
}

static unsigned long long timeval_ns(struct timeval value)
{
	return (unsigned long long)value.tv_sec * 1000000000ull +
	       (unsigned long long)value.tv_usec * 1000ull;
}

static int write_observation(const struct cell_config *config, bool pass,
			     const struct fxmark_result *result,
			     const struct tree_count *actual,
			     const struct tree_count *expected,
			     int fxmark_status, int fuse_status,
			     const struct rusage *fuse_usage,
			     uint32_t attached_before,
			     uint32_t attached_after,
			     unsigned long long fuse_setup,
			     unsigned long long fuse_measured,
			     bool cgroup_verified,
			     const char *stdout_path, const char *stderr_path,
			     const char *cgroup_path,
			     const char *fuse_stats_path)
{
	FILE *out = fopen(config->result_jsonl, "a");

	if (!out)
		return -errno;
	fprintf(out,
		"{\"event\":\"fxmark-cell\",\"repetition\":%d,"
		"\"condition\":\"%s\",\"type\":\"%s\",\"workers\":%d,"
		"\"duration_seconds\":%d,\"fxmark_status\":%d,"
		"\"fuse_status\":%d,\"seconds\":%.9f,\"works\":%.0f,"
		"\"works_per_second\":%.9f,"
		"\"actual_files\":%llu,\"expected_files\":%llu,"
		"\"actual_directories\":%llu,\"expected_directories\":%llu,"
		"\"attached_program_id_before\":%u,"
		"\"attached_program_id_after\":%u,"
			"\"attachment_stable\":%s,"
			"\"select_required_for_logical_path\":%s,"
			"\"leader_cgroup_verified\":%s,"
			"\"fuse_setup_requests\":%llu,"
		"\"fuse_measured_requests\":%llu,"
		"\"fuse_user_ns\":%llu,\"fuse_system_ns\":%llu,"
		"\"fuse_voluntary_context_switches\":%ld,"
			"\"fuse_involuntary_context_switches\":%ld,"
			"\"stdout\":\"%s\",\"stderr\":\"%s\","
			"\"leader_cgroup\":\"%s\","
			"\"fuse_stats\":\"%s\",\"pass\":%s}\n",
		config->repetition, config->condition, config->type,
		config->ncore, config->duration, fxmark_status, fuse_status,
		result->seconds, result->works, result->works_per_second,
		actual->files, expected->files, actual->directories,
		expected->directories, attached_before, attached_after,
			attached_before && attached_before == attached_after ?
				"true" : "false",
			!strcmp(config->condition, "select") ? "true" : "false",
			cgroup_verified ? "true" : "false",
			fuse_setup, fuse_measured, timeval_ns(fuse_usage->ru_utime),
			timeval_ns(fuse_usage->ru_stime), fuse_usage->ru_nvcsw,
			fuse_usage->ru_nivcsw, stdout_path, stderr_path,
			cgroup_path, fuse_stats_path, pass ? "true" : "false");
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
	if (config->ncore > 4 ||
	    (strcmp(config->condition, "stock") &&
	     strcmp(config->condition, "unattached") &&
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
	char cgroup[PATH_MAX];
	char lower[PATH_MAX];
	char view[PATH_MAX];
	char root[PATH_MAX];
	char begin_command[PATH_MAX * 2];
	char end_command[PATH_MAX * 2];
	char fuse_stats[8192] = {};
	uint32_t attached_before = 0;
	uint32_t attached_after = 0;
	unsigned long long fuse_setup = 0;
	unsigned long long fuse_measured = 0;
	pid_t fuse_pid = -1;
	bool policy_loaded = false;
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
			config.raw_prefix)) {
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

	if (!strcmp(config.condition, "pass") ||
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
		if (attached_program_id(&policy, &attached_before)) {
			pass = false;
			goto cleanup;
		}
		snprintf(begin_command, sizeof(begin_command), "/bin/true");
		snprintf(end_command, sizeof(end_command), "/bin/true");
	} else if (!strcmp(config.condition, "fuse")) {
		if (mkdir_p(view) ||
		    start_fuse(&config, lower, view, fuse_stats_path, &fuse_pid)) {
			pass = false;
			goto cleanup;
		}
		fuse_mounted = true;
		if (path_format(begin_command, sizeof(begin_command),
				"/bin/kill -USR1 %ld", (long)fuse_pid) ||
		    path_format(end_command, sizeof(end_command),
				"/bin/kill -USR2 %ld", (long)fuse_pid)) {
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

	if (policy_loaded &&
	    (attached_program_id(&policy, &attached_after) ||
	     attached_after != attached_before))
		pass = false;

cleanup:
	if (fuse_mounted) {
		struct statfs fs;

		if (statfs(view, &fs) ||
		    (unsigned long)fs.f_type != FUSE_SUPER_MAGIC)
			pass = false;
		if (stop_fuse(fuse_pid, view, &fuse_usage, &fuse_status) ||
		    fuse_status || read_file(fuse_stats_path, fuse_stats,
					    sizeof(fuse_stats)) ||
		    extract_u64(fuse_stats, "\"setup_total\":", &fuse_setup) ||
		    extract_u64(fuse_stats, "\"measured_total\":",
				&fuse_measured) ||
		    !fuse_setup)
			pass = false;
	}
	if (policy_loaded) {
		if (namei_ext_policy_destroy(&policy))
			pass = false;
	}
	if (!strcmp(config.condition, "select") &&
	    namei_ext_clear_targets(cgroup))
		pass = false;
	if (rmdir(cgroup))
		pass = false;

	if (write_observation(&config, pass, &result, &actual, &expected,
			      fxmark_status, fuse_status, &fuse_usage,
			      attached_before, attached_after, fuse_setup,
			      fuse_measured, cgroup_verified, stdout_path, stderr_path,
			      cgroup_path,
			      fuse_stats_path))
		return 1;
	namei_ext_remove_tree(config.work_root);
	return pass ? 0 : 1;
}
