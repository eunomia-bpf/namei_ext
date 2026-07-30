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
#include <signal.h>
#include <stdbool.h>
#include <stddef.h>
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

#define MDTEST_PHASES 3
#define MDTEST_TARGET_ID 1

struct cell_config {
	const char *condition;
	const char *mdtest_binary;
	const char *fuse_binary;
	const char *policy_object;
	const char *observations;
	const char *raw_prefix;
	const char *work_root;
	const char *cgroup_root;
	const char *tmpfs_size;
	const char *image_size;
	int ranks;
	int items_per_rank;
	int repetition;
	int phase_timeout;
	int fuse_timeout;
	int ext4_inodes;
};

struct policy_stats {
	uint32_t program_id;
	uint64_t run_time_ns;
	uint64_t run_count;
};

struct tree_count {
	unsigned long long files;
	unsigned long long directories;
	unsigned long long other;
};

struct summary_values {
	double maximum;
	double minimum;
	double mean;
	double stddev;
};

struct mdtest_summary {
	struct summary_values creation;
	struct summary_values stat;
	struct summary_values read;
	struct summary_values removal;
};

struct phase_result {
	const char *operation;
	int status;
	double ops_per_second;
	struct summary_values summary;
	struct rusage client_usage;
	struct rusage fuse_usage;
	struct tree_count observed_tree;
	struct tree_count expected_tree;
	uint32_t program_id_before;
	uint32_t program_id_after;
	uint64_t untimed_policy_runs;
	unsigned long fuse_f_type;
	bool attempted;
	bool pass;
	bool warning_as_errors;
	bool warnings_or_errors_absent;
	bool tree_correct;
	bool leader_cgroup_verified;
	bool mpi_ranks_cgroup_verified;
	bool mpi_bindings_reported;
	bool attachment_stable;
	bool selected_identity;
	bool fuse_daemon_live;
	bool fuse_dev_fd_verified;
	bool cleanup_complete;
	int cache_drop_value;
	ssize_t cache_drop_bytes_written;
	int cache_drop_errno;
};

static struct tree_count walked_tree;

static unsigned long long monotonic_ms(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now))
		return 0;
	return (unsigned long long)now.tv_sec * 1000ull +
	       (unsigned long long)now.tv_nsec / 1000000ull;
}

static unsigned long long timeval_ns(struct timeval value)
{
	return (unsigned long long)value.tv_sec * 1000000000ull +
	       (unsigned long long)value.tv_usec * 1000ull;
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

static int parse_positive_int(const char *value, int *result)
{
	char *end = NULL;
	long parsed;

	errno = 0;
	parsed = strtol(value, &end, 10);
	if (errno || !end || *end || parsed <= 0 || parsed > INT_MAX)
		return -EINVAL;
	*result = (int)parsed;
	return 0;
}

static int parse_size(const char *value, off_t *result)
{
	char *end = NULL;
	unsigned long long multiplier = 1;
	unsigned long long parsed;

	errno = 0;
	parsed = strtoull(value, &end, 10);
	if (errno || !end || end == value || !parsed)
		return -EINVAL;
	if (*end) {
		if (end[1])
			return -EINVAL;
		switch (*end) {
		case 'K':
		case 'k':
			multiplier = 1024ull;
			break;
		case 'M':
		case 'm':
			multiplier = 1024ull * 1024ull;
			break;
		case 'G':
		case 'g':
			multiplier = 1024ull * 1024ull * 1024ull;
			break;
		default:
			return -EINVAL;
		}
	}
	if (parsed > (unsigned long long)LLONG_MAX / multiplier)
		return -ERANGE;
	*result = (off_t)(parsed * multiplier);
	return 0;
}

static int parse_config(int argc, char **argv, struct cell_config *config)
{
	if (argc != 17)
		return -EINVAL;
	config->condition = argv[1];
	config->mdtest_binary = argv[2];
	config->fuse_binary = argv[3];
	config->policy_object = argv[4];
	config->observations = argv[5];
	config->raw_prefix = argv[6];
	config->work_root = argv[7];
	config->cgroup_root = argv[8];
	config->tmpfs_size = argv[14];
	config->image_size = argv[15];
	if (parse_positive_int(argv[9], &config->ranks) ||
	    parse_positive_int(argv[10], &config->items_per_rank) ||
	    parse_positive_int(argv[11], &config->repetition) ||
	    parse_positive_int(argv[12], &config->phase_timeout) ||
	    parse_positive_int(argv[13], &config->fuse_timeout) ||
	    parse_positive_int(argv[16], &config->ext4_inodes))
		return -EINVAL;
	if (config->ranks != 1 && config->ranks != 4)
		return -EINVAL;
	if (strcmp(config->condition, "stock") &&
	    strcmp(config->condition, "unattached") &&
	    strcmp(config->condition, "pass") &&
	    strcmp(config->condition, "select") &&
	    strcmp(config->condition, "fuse"))
		return -EINVAL;
	if ((!strcmp(config->condition, "pass") ||
	     !strcmp(config->condition, "select")) &&
	    !strcmp(config->policy_object, "-"))
		return -EINVAL;
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
			kill(-pid, SIGTERM);
			usleep(500000);
			kill(-pid, SIGKILL);
			if (wait4(pid, &status, 0, usage) != pid)
				return -errno;
			*exit_status = -ETIMEDOUT;
			return 0;
		}
		usleep(10000);
	}
	if (!WIFEXITED(status)) {
		*exit_status = WIFSIGNALED(status) ?
			-(128 + WTERMSIG(status)) : -ECHILD;
		return 0;
	}
	*exit_status = WEXITSTATUS(status);
	return 0;
}

static int run_command(char *const argv[], const char *stdout_path,
		       const char *stderr_path, int timeout_seconds,
		       struct rusage *usage, int *exit_status)
{
	pid_t pid = fork();

	if (pid < 0)
		return -errno;
	if (!pid) {
		if (setpgid(0, 0) ||
		    redirect_fd(STDOUT_FILENO, stdout_path) ||
		    redirect_fd(STDERR_FILENO, stderr_path))
			_exit(126);
		execvp(argv[0], argv);
		_exit(errno == ENOENT ? 127 : 126);
	}
	if (setpgid(pid, pid) && errno != EACCES && errno != ESRCH)
		return -errno;
	return wait_with_timeout(pid, timeout_seconds, usage, exit_status);
}

static int read_file(const char *path, char **contents_out, size_t *size_out)
{
	struct stat st;
	char *contents;
	ssize_t done = 0;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	if (fstat(fd, &st)) {
		int saved_errno = errno;

		close(fd);
		return -saved_errno;
	}
	if (st.st_size < 0 || st.st_size > 32 * 1024 * 1024) {
		close(fd);
		return -EFBIG;
	}
	contents = calloc(1, (size_t)st.st_size + 1);
	if (!contents) {
		close(fd);
		return -ENOMEM;
	}
	while (done < st.st_size) {
		ssize_t received = read(fd, contents + done, (size_t)(st.st_size - done));

		if (received < 0 && errno == EINTR)
			continue;
		if (received <= 0) {
			int saved_errno = received < 0 ? errno : EIO;

			free(contents);
			close(fd);
			return -saved_errno;
		}
		done += received;
	}
	if (close(fd)) {
		int saved_errno = errno;

		free(contents);
		return -saved_errno;
	}
	*contents_out = contents;
	*size_out = (size_t)st.st_size;
	return 0;
}

static bool output_has_warning_or_error(const char *contents)
{
	const char *cursor = contents;

	while (*cursor) {
		const char *end = strchr(cursor, '\n');
		size_t length = end ? (size_t)(end - cursor) : strlen(cursor);

		if ((length >= 8 && !memcmp(cursor, "WARNING:", 8)) ||
		    (length >= 6 && !memcmp(cursor, "ERROR:", 6)) ||
		    (length >= 6 && !memcmp(cursor, "Error:", 6)) ||
		    (length >= 6 && !memcmp(cursor, "Error ", 6)) ||
		    (length >= 11 && !memcmp(cursor, "** error **", 11)))
			return true;
		if (!end)
			break;
		cursor = end + 1;
	}
	return false;
}

static int parse_summary_row(const char *line, const char *operation,
			     struct summary_values *result)
{
	char name[64];
	char extra;
	size_t length;
	struct summary_values parsed;
	int consumed = 0;

	if (sscanf(line, " %63[A-Za-z ] %lf %lf %lf %lf %n%c", name,
		   &parsed.maximum, &parsed.minimum, &parsed.mean,
		   &parsed.stddev, &consumed, &extra) != 5)
		return 0;
	length = strlen(name);
	while (length && (name[length - 1] == ' ' || name[length - 1] == '\t'))
		name[--length] = '\0';
	if (strcmp(name, operation))
		return 0;
	if (!isfinite(parsed.maximum) || !isfinite(parsed.minimum) ||
	    !isfinite(parsed.mean) || !isfinite(parsed.stddev))
		return -ERANGE;
	*result = parsed;
	return 1;
}

static int parse_mdtest_summary(const char *path, struct mdtest_summary *summary,
				bool *warning_free)
{
	char *contents = NULL;
	char *copy = NULL;
	char *line;
	char *save = NULL;
	size_t size = 0;
	int header_count = 0;
	int creation_count = 0;
	int stat_count = 0;
	int read_count = 0;
	int removal_count = 0;
	bool in_summary = false;
	int ret;

	ret = read_file(path, &contents, &size);
	if (ret)
		return ret;
	(void)size;
	*warning_free = !output_has_warning_or_error(contents);
	copy = strdup(contents);
	free(contents);
	if (!copy)
		return -ENOMEM;
	for (line = strtok_r(copy, "\n", &save); line;
	     line = strtok_r(NULL, "\n", &save)) {
		if (!strcmp(line, "SUMMARY rate: (of 1 iterations)")) {
			header_count++;
			in_summary = true;
			continue;
		}
		if (!in_summary)
			continue;
		ret = parse_summary_row(line, "File creation", &summary->creation);
		if (ret < 0)
			goto out;
		if (ret) {
			creation_count++;
			continue;
		}
		ret = parse_summary_row(line, "File stat", &summary->stat);
		if (ret < 0)
			goto out;
		if (ret) {
			stat_count++;
			continue;
		}
		ret = parse_summary_row(line, "File read", &summary->read);
		if (ret < 0)
			goto out;
		if (ret) {
			read_count++;
			continue;
		}
		ret = parse_summary_row(line, "File removal", &summary->removal);
		if (ret < 0)
			goto out;
		if (ret)
			removal_count++;
	}
	ret = header_count == 1 && creation_count == 1 && stat_count == 1 &&
	      read_count == 1 && removal_count == 1 ? 0 : -EINVAL;
out:
	free(copy);
	return ret;
}

static bool summary_value_valid(const struct summary_values *value, bool nonzero)
{
	if (fabs(value->maximum - value->minimum) > 0.0005 ||
	    fabs(value->maximum - value->mean) > 0.0005 ||
	    fabs(value->stddev) > 0.0005)
		return false;
	return nonzero ? value->mean > 0 : fabs(value->mean) <= 0.0005;
}

static int validate_phase_summary(const char *phase,
				  const struct mdtest_summary *summary,
				  struct summary_values *selected)
{
	if (!strcmp(phase, "create")) {
		*selected = summary->creation;
		return summary_value_valid(&summary->creation, true) &&
		       summary_value_valid(&summary->stat, false) &&
		       summary_value_valid(&summary->read, false) &&
		       summary_value_valid(&summary->removal, false) ? 0 : -EINVAL;
	}
	if (!strcmp(phase, "stat")) {
		*selected = summary->stat;
		return summary_value_valid(&summary->creation, false) &&
		       summary_value_valid(&summary->stat, true) &&
		       summary_value_valid(&summary->read, false) &&
		       summary_value_valid(&summary->removal, false) ? 0 : -EINVAL;
	}
	if (!strcmp(phase, "remove")) {
		*selected = summary->removal;
		return summary_value_valid(&summary->creation, false) &&
		       summary_value_valid(&summary->stat, false) &&
		       summary_value_valid(&summary->read, false) &&
		       summary_value_valid(&summary->removal, true) ? 0 : -EINVAL;
	}
	return -EINVAL;
}

static int parse_only(const char *phase, const char *stdout_path,
		      const char *stderr_path)
{
	struct mdtest_summary summary = {};
	struct summary_values selected = {};
	char *stderr_contents = NULL;
	size_t stderr_size = 0;
	bool stdout_warning_free = false;
	int ret;

	ret = parse_mdtest_summary(stdout_path, &summary, &stdout_warning_free);
	if (ret)
		return ret;
	ret = read_file(stderr_path, &stderr_contents, &stderr_size);
	if (ret)
		return ret;
	(void)stderr_size;
	if (!stdout_warning_free || output_has_warning_or_error(stderr_contents)) {
		free(stderr_contents);
		return -EINVAL;
	}
	free(stderr_contents);
	ret = validate_phase_summary(phase, &summary, &selected);
	if (ret)
		return ret;
	printf("{\"phase\":\"%s\",\"max\":%.6f,\"min\":%.6f,"
	       "\"mean\":%.6f,\"stddev\":%.6f}\n",
	       phase, selected.maximum, selected.minimum, selected.mean,
	       selected.stddev);
	return 0;
}

static int count_tree_entry(const char *path, const struct stat *st, int type,
			    struct FTW *ftw)
{
	(void)path;
	(void)st;
	(void)ftw;
	if (type == FTW_F)
		walked_tree.files++;
	else if (type == FTW_D)
		walked_tree.directories++;
	else
		walked_tree.other++;
	return 0;
}

static int count_tree(const char *root, struct tree_count *count)
{
	memset(&walked_tree, 0, sizeof(walked_tree));
	if (nftw(root, count_tree_entry, 64, FTW_PHYS))
		return -errno;
	*count = walked_tree;
	return 0;
}

static int copy_file_to_path(const char *source, const char *destination)
{
	char *contents = NULL;
	size_t size = 0;
	ssize_t written = 0;
	int fd;
	int ret;

	ret = read_file(source, &contents, &size);
	if (ret)
		return ret;
	fd = open(destination, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, 0644);
	if (fd < 0) {
		ret = -errno;
		goto out;
	}
	while ((size_t)written < size) {
		ssize_t count = write(fd, contents + written, size - (size_t)written);

		if (count < 0 && errno == EINTR)
			continue;
		if (count <= 0) {
			ret = count < 0 ? -errno : -EIO;
			close(fd);
			goto out;
		}
		written += count;
	}
	ret = close(fd) ? -errno : 0;
out:
	free(contents);
	return ret;
}

static int set_bpf_stats_enabled(bool enabled)
{
	return namei_ext_write_text("/proc/sys/kernel/bpf_stats_enabled",
				    enabled ? "1\n" : "0\n");
}

static int attached_program_stats(struct namei_ext_harness_policy *policy,
				  struct policy_stats *stats)
{
	struct bpf_prog_info info = {};
	__u32 info_len = sizeof(info);
	__u32 attach_flags = 0;
	__u32 program_count = 1;
	__u32 program_id = 0;

	if (bpf_prog_get_info_by_fd(policy->prog_fd, &info, &info_len))
		return -errno;
	if (bpf_prog_query(policy->cgroup_fd, BPF_CGROUP_NAMEI_EXT, 0,
			   &attach_flags, &program_id, &program_count))
		return -errno;
	if (program_count != 1 || program_id != info.id)
		return -EINVAL;
	stats->program_id = info.id;
	stats->run_time_ns = info.run_time_ns;
	stats->run_count = info.run_cnt;
	return 0;
}

static int write_text_line(int fd, const char *format, ...)
{
	char buffer[4096];
	va_list args;
	int length;
	ssize_t done = 0;

	va_start(args, format);
	length = vsnprintf(buffer, sizeof(buffer), format, args);
	va_end(args);
	if (length < 0 || (size_t)length >= sizeof(buffer))
		return -EOVERFLOW;
	while (done < length) {
		ssize_t count = write(fd, buffer + done, (size_t)(length - done));

		if (count < 0 && errno == EINTR)
			continue;
		if (count <= 0)
			return count < 0 ? -errno : -EIO;
		done += count;
	}
	return 0;
}

static int process_mpi_rank(pid_t pid, int expected_ranks, int *rank_out)
{
	static const char prefix[] = "OMPI_COMM_WORLD_RANK=";
	char path[PATH_MAX];
	char environment[65536];
	size_t used = 0;
	int fd;

	if (path_format(path, sizeof(path), "/proc/%ld/environ", (long)pid))
		return -ENAMETOOLONG;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return errno == ENOENT || errno == ESRCH ? 0 : -errno;
	while (used < sizeof(environment)) {
		ssize_t received = read(fd, environment + used,
				       sizeof(environment) - used);

		if (received < 0 && errno == EINTR)
			continue;
		if (received < 0) {
			int saved_errno = errno;

			close(fd);
			return saved_errno == ENOENT || saved_errno == ESRCH ?
				0 : -saved_errno;
		}
		if (!received)
			break;
		used += (size_t)received;
	}
	if (close(fd))
		return -errno;
	for (size_t offset = 0; offset < used;) {
		size_t remaining = used - offset;
		size_t length = strnlen(environment + offset, remaining);
		char *end = NULL;
		long rank;

		if (length == remaining)
			return -EOVERFLOW;
		if (length > sizeof(prefix) - 1 &&
		    !memcmp(environment + offset, prefix, sizeof(prefix) - 1)) {
			errno = 0;
			rank = strtol(environment + offset + sizeof(prefix) - 1,
				     &end, 10);
			if (errno || !end || *end || rank < 0 ||
			    rank >= expected_ranks)
				return -EINVAL;
			*rank_out = (int)rank;
			return 1;
		}
		offset += length + 1;
	}
	return 0;
}

static int read_cgroup_procs(const char *cgroup, pid_t leader, int audit_fd,
			     int expected_ranks, unsigned int *mpi_rank_mask,
			     bool *leader_seen)
{
	char path[PATH_MAX];
	char line[64];
	FILE *input;

	if (path_format(path, sizeof(path), "%s/cgroup.procs", cgroup))
		return -ENAMETOOLONG;
	input = fopen(path, "r");
	if (!input)
		return -errno;
	while (fgets(line, sizeof(line), input)) {
		char cmdline_path[PATH_MAX];
		char cmdline[512] = {};
		char *end = NULL;
		long parsed;
		int mpi_rank = -1;
		int mpi_result;
		int fd;
		ssize_t received;

		errno = 0;
		parsed = strtol(line, &end, 10);
		if (errno || !end || (*end && *end != '\n') || parsed <= 0)
			continue;
		if ((pid_t)parsed == leader)
			*leader_seen = true;
		mpi_result = process_mpi_rank(
			(pid_t)parsed, expected_ranks, &mpi_rank);
		if (mpi_result < 0) {
			fclose(input);
			return mpi_result;
		}
		if (mpi_result > 0)
			*mpi_rank_mask |= 1u << mpi_rank;
		if (path_format(cmdline_path, sizeof(cmdline_path),
				"/proc/%ld/cmdline", parsed))
			continue;
		fd = open(cmdline_path, O_RDONLY | O_CLOEXEC);
		if (fd < 0)
			continue;
		received = read(fd, cmdline, sizeof(cmdline) - 1);
		close(fd);
		if (received < 0)
			continue;
		for (ssize_t index = 0; index < received; index++) {
			if (!cmdline[index])
				cmdline[index] = ' ';
		}
		if (write_text_line(audit_fd, "pid=%ld mpi_rank=%d cmd=%s\n",
				    parsed, mpi_rank, cmdline))
			return -EIO;
	}
	if (ferror(input)) {
		int saved_errno = errno ? errno : EIO;

		fclose(input);
		return -saved_errno;
	}
	if (fclose(input))
		return -errno;
	return 0;
}

static int child_cgroup_handshake(int fd)
{
	char ready = '1';

	if (write(fd, &ready, 1) != 1)
		return -errno;
	return close(fd) ? -errno : 0;
}

static int parent_cgroup_handshake(int fd)
{
	char ready = 0;
	ssize_t received;

	do {
		received = read(fd, &ready, 1);
	} while (received < 0 && errno == EINTR);
	if (close(fd))
		return -errno;
	return received == 1 && ready == '1' ? 0 : -EPIPE;
}

static int run_mdtest(const struct cell_config *config, const char *cgroup,
		      const char *logical_view, const char *phase_flag,
		      const char *stdout_path, const char *stderr_path,
		      const char *audit_path, struct rusage *usage,
			      int *exit_status, bool *leader_verified,
			      bool *mpi_ranks_verified)
{
	char ranks[32];
	char items[32];
	char timeout_seconds[32];
	char *argv[] = {
		"timeout", "--signal=TERM", "--kill-after=10s", timeout_seconds,
		"taskset", "-c", "0-3", "mpirun", "--allow-run-as-root",
		"--bind-to", "core", "--map-by", "core",
		"--report-bindings", "-np", ranks, (char *)config->mdtest_binary,
		"-a", "POSIX", "-F", "-u", "-i", "1", "-n", items,
		"--warningAsErrors", "-d", (char *)logical_view,
		(char *)phase_flag, NULL
	};
	unsigned long long deadline =
		monotonic_ms() + (unsigned long long)(config->phase_timeout + 20) *
				       1000ull;
	int pipefd[2] = {-1, -1};
	int audit_fd = -1;
	int status = 0;
	unsigned int mpi_rank_mask = 0;
	unsigned int all_ranks_mask = (1u << config->ranks) - 1;
	bool leader_seen = false;
	pid_t pid;

	snprintf(ranks, sizeof(ranks), "%d", config->ranks);
	snprintf(items, sizeof(items), "%d", config->items_per_rank);
	snprintf(timeout_seconds, sizeof(timeout_seconds), "%ds",
		 config->phase_timeout);
	if (pipe2(pipefd, O_CLOEXEC))
		return -errno;
	audit_fd = open(audit_path, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC,
			0644);
	if (audit_fd < 0) {
		close(pipefd[0]);
		close(pipefd[1]);
		return -errno;
	}
	pid = fork();
	if (pid < 0) {
		close(audit_fd);
		close(pipefd[0]);
		close(pipefd[1]);
		return -errno;
	}
	if (!pid) {
		close(pipefd[0]);
		if (setpgid(0, 0) ||
		    namei_ext_move_self_to_cgroup(cgroup) ||
		    child_cgroup_handshake(pipefd[1]) ||
		    redirect_fd(STDOUT_FILENO, stdout_path) ||
		    redirect_fd(STDERR_FILENO, stderr_path))
			_exit(126);
		execvp(argv[0], argv);
		_exit(errno == ENOENT ? 127 : 126);
	}
	close(pipefd[1]);
	if (setpgid(pid, pid) && errno != EACCES && errno != ESRCH) {
		close(pipefd[0]);
		close(audit_fd);
		return -errno;
	}
	if (parent_cgroup_handshake(pipefd[0])) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		close(audit_fd);
		return -EPIPE;
	}
	for (;;) {
		pid_t waited;

		if (!leader_seen || mpi_rank_mask != all_ranks_mask) {
			if (read_cgroup_procs(cgroup, pid, audit_fd, config->ranks,
					      &mpi_rank_mask, &leader_seen)) {
				kill(-pid, SIGKILL);
				waitpid(pid, NULL, 0);
				close(audit_fd);
				return -EIO;
			}
		}
		waited = wait4(pid, &status, WNOHANG, usage);
		if (waited == pid)
			break;
		if (waited < 0) {
			close(audit_fd);
			return -errno;
		}
		if (monotonic_ms() >= deadline) {
			kill(-pid, SIGTERM);
			usleep(500000);
			kill(-pid, SIGKILL);
			if (wait4(pid, &status, 0, usage) != pid) {
				close(audit_fd);
				return -errno;
			}
			*exit_status = -ETIMEDOUT;
			goto done;
		}
		usleep(1000);
	}
	if (!WIFEXITED(status))
		*exit_status = WIFSIGNALED(status) ?
			-(128 + WTERMSIG(status)) : -ECHILD;
	else
		*exit_status = WEXITSTATUS(status);
done:
	if (close(audit_fd))
		return -errno;
	*leader_verified = leader_seen;
	*mpi_ranks_verified = mpi_rank_mask == all_ranks_mask;
	return 0;
}

static int count_binding_lines(const char *path, int expected)
{
	char *contents = NULL;
	char *cursor;
	size_t size = 0;
	int count = 0;
	int ret;

	ret = read_file(path, &contents, &size);
	if (ret)
		return ret;
	(void)size;
	cursor = contents;
	while ((cursor = strstr(cursor, " rank ")) != NULL) {
		const char *line_end = strchr(cursor, '\n');
		const char *bound = strstr(cursor, " bound ");

		if (bound && (!line_end || bound < line_end))
			count++;
		cursor += 6;
	}
	free(contents);
	return count == expected ? 0 : -EINVAL;
}

static int wait_for_fuse_mount(const char *mountpoint, pid_t pid,
			       int timeout_seconds, unsigned long *f_type)
{
	unsigned long long deadline =
		monotonic_ms() + (unsigned long long)timeout_seconds * 1000ull;

	for (;;) {
		struct statfs fs;

		if (!statfs(mountpoint, &fs) &&
		    (unsigned long)fs.f_type == FUSE_SUPER_MAGIC) {
			*f_type = (unsigned long)fs.f_type;
			return 0;
		}
		if (kill(pid, 0) && errno == ESRCH)
			return -ECHILD;
		if (monotonic_ms() >= deadline)
			return -ETIMEDOUT;
		usleep(10000);
	}
}

static bool process_has_fuse_fd(pid_t pid)
{
	char directory_path[PATH_MAX];
	struct stat fuse_stat;
	DIR *directory;
	struct dirent *entry;
	bool found = false;

	if (stat("/dev/fuse", &fuse_stat))
		return false;
	if (path_format(directory_path, sizeof(directory_path), "/proc/%ld/fd",
			(long)pid))
		return false;
	directory = opendir(directory_path);
	if (!directory)
		return false;
	while ((entry = readdir(directory)) != NULL) {
		char fd_path[PATH_MAX];
		struct stat st;

		if (entry->d_name[0] == '.')
			continue;
		if (path_format(fd_path, sizeof(fd_path), "%s/%s", directory_path,
				entry->d_name))
			continue;
		if (!stat(fd_path, &st) && S_ISCHR(st.st_mode) &&
		    st.st_rdev == fuse_stat.st_rdev) {
			found = true;
			break;
		}
	}
	closedir(directory);
	return found;
}

static int start_fuse(const struct cell_config *config, const char *physical_root,
		      const char *logical_view, const char *phase,
		      pid_t *pid_out, unsigned long *f_type,
		      bool *daemon_live, bool *fuse_fd_verified)
{
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char source_option[PATH_MAX + 16];
	pid_t pid;

	if (path_format(stdout_path, sizeof(stdout_path), "%s.%s.fuse.stdout",
			config->raw_prefix, phase) ||
	    path_format(stderr_path, sizeof(stderr_path), "%s.%s.fuse.stderr",
			config->raw_prefix, phase) ||
	    path_format(source_option, sizeof(source_option), "source=%s",
			physical_root))
		return -ENAMETOOLONG;
	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		if (setpgid(0, 0) ||
		    redirect_fd(STDOUT_FILENO, stdout_path) ||
		    redirect_fd(STDERR_FILENO, stderr_path))
			_exit(126);
		execlp("taskset", "taskset", "-c", "4-7", config->fuse_binary,
		       "-f", "-o", source_option, "-o",
		       "default_permissions,cache=always,timeout=86400,clone_fd",
		       logical_view, (char *)NULL);
		_exit(errno == ENOENT ? 127 : 126);
	}
	if (setpgid(pid, pid) && errno != EACCES && errno != ESRCH)
		return -errno;
	if (wait_for_fuse_mount(logical_view, pid, config->fuse_timeout, f_type)) {
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -ETIMEDOUT;
	}
	*daemon_live = !kill(pid, 0);
	*fuse_fd_verified = process_has_fuse_fd(pid);
	if (!*daemon_live || !*fuse_fd_verified) {
		umount2(logical_view, MNT_DETACH);
		kill(-pid, SIGKILL);
		waitpid(pid, NULL, 0);
		return -EIO;
	}
	*pid_out = pid;
	return 0;
}

static int stop_fuse(pid_t pid, const char *logical_view, int timeout_seconds,
		     struct rusage *usage, int *status_out)
{
	if (umount2(logical_view, 0))
		return -errno;
	return wait_with_timeout(pid, timeout_seconds, usage, status_out);
}

struct identity_result {
	dev_t logical_dev;
	ino_t logical_ino;
	dev_t physical_dev;
	ino_t physical_ino;
	int error;
};

static int probe_policy(const char *cgroup, const char *logical_view,
			const char *physical_root, bool require_identity,
			bool *selected_identity)
{
	struct identity_result result = {};
	int pipefd[2] = {-1, -1};
	pid_t pid;
	ssize_t received;
	int status;

	if (pipe2(pipefd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		close(pipefd[0]);
		close(pipefd[1]);
		return -errno;
	}
	if (!pid) {
		struct stat logical;
		struct stat physical;
		ssize_t written;

		close(pipefd[0]);
		if (namei_ext_move_self_to_cgroup(cgroup) ||
		    stat(logical_view, &logical) ||
		    stat(physical_root, &physical)) {
			result.error = errno ? errno : EIO;
		} else {
			result.logical_dev = logical.st_dev;
			result.logical_ino = logical.st_ino;
			result.physical_dev = physical.st_dev;
			result.physical_ino = physical.st_ino;
		}
		do {
			written = write(pipefd[1], &result, sizeof(result));
		} while (written < 0 && errno == EINTR);
		if (written != (ssize_t)sizeof(result))
			result.error = errno ? errno : EIO;
		close(pipefd[1]);
		_exit(result.error ? 1 : 0);
	}
	close(pipefd[1]);
	do {
		received = read(pipefd[0], &result, sizeof(result));
	} while (received < 0 && errno == EINTR);
	close(pipefd[0]);
	if (waitpid(pid, &status, 0) != pid)
		return -errno;
	if (received != (ssize_t)sizeof(result) || result.error ||
	    !WIFEXITED(status) || WEXITSTATUS(status))
		return -EIO;
	*selected_identity =
		result.logical_dev == result.physical_dev &&
		result.logical_ino == result.physical_ino;
	return require_identity && !*selected_identity ? -EXDEV : 0;
}

static int run_untimed_policy_probe(struct namei_ext_harness_policy *policy,
				    const char *cgroup,
				    const char *logical_view,
				    const char *physical_root,
				    bool require_identity,
				    struct phase_result *result)
{
	struct policy_stats before = {};
	struct policy_stats after = {};
	bool identity = false;
	int ret;

	ret = attached_program_stats(policy, &before);
	if (ret)
		return ret;
	result->program_id_before = before.program_id;
	if (set_bpf_stats_enabled(true))
		return -errno;
	ret = probe_policy(cgroup, logical_view, physical_root, require_identity,
			   &identity);
	if (set_bpf_stats_enabled(false) && !ret)
		ret = -errno;
	if (ret)
		return ret;
	ret = attached_program_stats(policy, &after);
	if (ret)
		return ret;
	result->program_id_after = after.program_id;
	result->untimed_policy_runs = after.run_count - before.run_count;
	result->attachment_stable = before.program_id &&
		before.program_id == after.program_id;
	result->selected_identity = require_identity && identity;
	return result->attachment_stable && result->untimed_policy_runs ?
		0 : -EINVAL;
}

static int capture_meminfo(const struct cell_config *config, const char *phase,
			   const char *when)
{
	char path[PATH_MAX];

	if (path_format(path, sizeof(path), "%s.%s.meminfo.%s",
			config->raw_prefix, phase, when))
		return -ENAMETOOLONG;
	return copy_file_to_path("/proc/meminfo", path);
}

static int write_drop_caches(const struct cell_config *config, const char *phase,
			     struct phase_result *result)
{
	static const char requested[] = "3\n";
	char event_path[PATH_MAX];
	int event_fd;
	int drop_fd;
	int error = 0;
	ssize_t written = -1;

	result->cache_drop_value = 3;
	if (path_format(event_path, sizeof(event_path),
			"%s.%s.drop-caches.json", config->raw_prefix, phase))
		return -ENAMETOOLONG;
	drop_fd = open("/proc/sys/vm/drop_caches", O_WRONLY | O_CLOEXEC);
	if (drop_fd < 0) {
		error = errno;
	} else {
		do {
			written = write(drop_fd, requested, sizeof(requested) - 1);
		} while (written < 0 && errno == EINTR);
		if (written < 0)
			error = errno;
		if (close(drop_fd) && !error)
			error = errno;
	}
	result->cache_drop_bytes_written = written;
	result->cache_drop_errno = error;
	event_fd = open(event_path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC,
			0644);
	if (event_fd < 0)
		return -errno;
	if (dprintf(event_fd,
		    "{\"schema\":\"namei_ext.mdtest_cold_metadata.drop_caches.v1\","
		    "\"phase\":\"%s\",\"requested_value\":3,"
		    "\"bytes_requested\":2,\"bytes_written\":%zd,\"error\":%d}\n",
		    phase, written, error) < 0) {
		error = errno ? errno : EIO;
		close(event_fd);
		return -error;
	}
	if (close(event_fd))
		return -errno;
	return !error && written == (ssize_t)(sizeof(requested) - 1) ?
		0 : -(error ? error : EIO);
}

static int drop_caches(const struct cell_config *config, const char *phase,
		       struct phase_result *result)
{
	int ret;

	ret = capture_meminfo(config, phase, "before");
	if (ret)
		return ret;
	sync();
	ret = write_drop_caches(config, phase, result);
	if (ret)
		return ret;
	return capture_meminfo(config, phase, "after");
}

static int setup_ext4(const struct cell_config *config, const char *tmpfs_root,
		      const char *image, const char *ext4_root,
		      const char *physical_root)
{
	char mount_options[64];
	char inode_count[32];
	char mkfs_stdout[PATH_MAX];
	char mkfs_stderr[PATH_MAX];
	char mount_stdout[PATH_MAX];
	char mount_stderr[PATH_MAX];
	struct rusage usage = {};
	struct statfs fs;
	off_t image_size;
	int status = -1;
	int ret = 0;
	int fd;
	bool tmpfs_mounted = false;
	bool ext4_mounted = false;
	char *mkfs_argv[] = {
		"mkfs.ext4", "-F", "-N", inode_count, "-E",
		"lazy_itable_init=0,lazy_journal_init=0", (char *)image, NULL
	};
	char *mount_argv[] = {
		"mount", "-t", "ext4", "-o", "loop,noatime", (char *)image,
		(char *)ext4_root, NULL
	};

	ret = mkdir_p(tmpfs_root);
	if (ret)
		return ret;
	if (snprintf(mount_options, sizeof(mount_options), "size=%s,mode=0755",
		     config->tmpfs_size) >= (int)sizeof(mount_options))
		return -ENAMETOOLONG;
	if (mount("tmpfs", tmpfs_root, "tmpfs", MS_NOSUID | MS_NODEV,
		  mount_options))
		return -errno;
	tmpfs_mounted = true;
	ret = parse_size(config->image_size, &image_size);
	if (ret)
		goto fail;
	fd = open(image, O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0600);
	if (fd < 0) {
		ret = -errno;
		goto fail;
	}
	if (ftruncate(fd, image_size)) {
		ret = -errno;
		close(fd);
		goto fail;
	}
	if (close(fd)) {
		ret = -errno;
		goto fail;
	}
	ret = mkdir_p(ext4_root);
	if (ret)
		goto fail;
	snprintf(inode_count, sizeof(inode_count), "%d", config->ext4_inodes);
	if (path_format(mkfs_stdout, sizeof(mkfs_stdout), "%s.mkfs.stdout",
			config->raw_prefix) ||
	    path_format(mkfs_stderr, sizeof(mkfs_stderr), "%s.mkfs.stderr",
			config->raw_prefix) ||
	    path_format(mount_stdout, sizeof(mount_stdout), "%s.mount.stdout",
			config->raw_prefix) ||
	    path_format(mount_stderr, sizeof(mount_stderr), "%s.mount.stderr",
			config->raw_prefix))
		goto path_too_long;
	if (run_command(mkfs_argv, mkfs_stdout, mkfs_stderr, 300, &usage,
			&status) || status) {
		ret = -EIO;
		goto fail;
	}
	memset(&usage, 0, sizeof(usage));
	status = -1;
	if (run_command(mount_argv, mount_stdout, mount_stderr, 60, &usage,
			&status) || status) {
		ret = -EIO;
		goto fail;
	}
	ext4_mounted = true;
	if (statfs(ext4_root, &fs) ||
	    (unsigned long)fs.f_type != EXT4_SUPER_MAGIC) {
		ret = -EINVAL;
		goto fail;
	}
	if (mkdir(physical_root, 0755)) {
		ret = -errno;
		goto fail;
	}
	return 0;

path_too_long:
	ret = -ENAMETOOLONG;
fail:
	if (ext4_mounted)
		(void)umount2(ext4_root, MNT_DETACH);
	if (tmpfs_mounted)
		(void)umount2(tmpfs_root, MNT_DETACH);
	return ret;
}

static int verify_loop_released(const struct cell_config *config,
				const char *image)
{
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	struct rusage usage = {};
	struct stat st;
	int status = -1;
	char *argv[] = {"losetup", "-j", (char *)image, NULL};

	if (path_format(stdout_path, sizeof(stdout_path), "%s.losetup.stdout",
			config->raw_prefix) ||
	    path_format(stderr_path, sizeof(stderr_path), "%s.losetup.stderr",
			config->raw_prefix))
		return -ENAMETOOLONG;
	if (run_command(argv, stdout_path, stderr_path, 30, &usage, &status) ||
	    status || stat(stdout_path, &st))
		return -EIO;
	return st.st_size == 0 ? 0 : -EBUSY;
}

static int run_phase(const struct cell_config *config, const char *phase,
		     const char *phase_flag, const char *logical_view,
		     const char *physical_root, const char *cgroup,
		     struct namei_ext_harness_policy *policy,
		     struct phase_result *result)
{
	char stdout_path[PATH_MAX];
	char stderr_path[PATH_MAX];
	char audit_path[PATH_MAX];
	char *stderr_contents = NULL;
	size_t stderr_size = 0;
	struct mdtest_summary summary = {};
	pid_t fuse_pid = -1;
	int fuse_status = -1;
	bool stdout_warning_free = false;
	bool stderr_warning_free = false;
	bool attached = policy != NULL;
	bool cache_drop_required = strcmp(phase, "create") != 0;
	bool fuse_started = false;
	int ret;

	result->operation = phase;
	result->attempted = true;
	result->warning_as_errors = true;
	if (path_format(stdout_path, sizeof(stdout_path), "%s.%s.mdtest.stdout",
			config->raw_prefix, phase) ||
	    path_format(stderr_path, sizeof(stderr_path), "%s.%s.mdtest.stderr",
			config->raw_prefix, phase) ||
	    path_format(audit_path, sizeof(audit_path), "%s.%s.cgroup.log",
			config->raw_prefix, phase))
		return -ENAMETOOLONG;
	if (cache_drop_required) {
		ret = drop_caches(config, phase, result);
		if (ret)
			return ret;
	}
	if (!strcmp(config->condition, "fuse")) {
		ret = start_fuse(config, physical_root, logical_view, phase,
				 &fuse_pid, &result->fuse_f_type,
				 &result->fuse_daemon_live,
				 &result->fuse_dev_fd_verified);
		if (ret)
			return ret;
		fuse_started = true;
	}
	ret = run_mdtest(config, cgroup, logical_view, phase_flag, stdout_path,
			 stderr_path, audit_path, &result->client_usage,
			 &result->status, &result->leader_cgroup_verified,
			 &result->mpi_ranks_cgroup_verified);
	if (fuse_started) {
		int stop_ret = stop_fuse(fuse_pid, logical_view,
					 config->fuse_timeout, &result->fuse_usage,
					 &fuse_status);

		if (!ret && stop_ret)
			ret = stop_ret;
		if (!ret && fuse_status)
			ret = -EIO;
	}
	if (ret)
		return ret;
	ret = parse_mdtest_summary(stdout_path, &summary, &stdout_warning_free);
	if (ret)
		return ret;
	ret = read_file(stderr_path, &stderr_contents, &stderr_size);
	if (ret)
		return ret;
	(void)stderr_size;
	stderr_warning_free = !output_has_warning_or_error(stderr_contents);
	free(stderr_contents);
	result->warnings_or_errors_absent =
		stdout_warning_free && stderr_warning_free;
	result->mpi_bindings_reported =
		count_binding_lines(stderr_path, config->ranks) == 0;
	if (!strcmp(phase, "create")) {
		ret = validate_phase_summary(phase, &summary, &result->summary);
		if (ret)
			return ret;
		result->ops_per_second = result->summary.mean;
		result->expected_tree.files =
			(unsigned long long)config->ranks * config->items_per_rank;
		result->expected_tree.directories =
			(unsigned long long)config->ranks + 2;
	} else if (!strcmp(phase, "stat")) {
		ret = validate_phase_summary(phase, &summary, &result->summary);
		if (ret)
			return ret;
		result->ops_per_second = result->summary.mean;
		result->expected_tree.files =
			(unsigned long long)config->ranks * config->items_per_rank;
		result->expected_tree.directories =
			(unsigned long long)config->ranks + 2;
	} else if (!strcmp(phase, "remove")) {
		ret = validate_phase_summary(phase, &summary, &result->summary);
		if (ret)
			return ret;
		result->ops_per_second = result->summary.mean;
		result->expected_tree.directories = 1;
	} else {
		return -EINVAL;
	}
	ret = count_tree(physical_root, &result->observed_tree);
	if (ret)
		return ret;
	result->tree_correct =
		result->observed_tree.files == result->expected_tree.files &&
		result->observed_tree.directories ==
			result->expected_tree.directories &&
		result->observed_tree.other == 0;
	if (attached) {
		ret = run_untimed_policy_probe(
			policy, cgroup, logical_view, physical_root,
			!strcmp(config->condition, "select"), result);
		if (ret)
			return ret;
	}
	result->pass = !result->status &&
		result->warnings_or_errors_absent &&
		result->tree_correct &&
		(!cache_drop_required ||
		 (result->cache_drop_value == 3 &&
		  result->cache_drop_bytes_written == 2 &&
		  !result->cache_drop_errno)) &&
		result->leader_cgroup_verified &&
		result->mpi_ranks_cgroup_verified &&
		result->mpi_bindings_reported &&
		(!attached || (result->attachment_stable &&
			       result->untimed_policy_runs > 0)) &&
		(strcmp(config->condition, "select") ||
		 result->selected_identity) &&
		(strcmp(config->condition, "fuse") ||
		 (result->fuse_f_type == FUSE_SUPER_MAGIC &&
		  result->fuse_daemon_live &&
		  result->fuse_dev_fd_verified));
	return result->pass ? 0 : -EINVAL;
}

static int write_observation(FILE *out, const struct cell_config *config,
			     const struct phase_result *result,
			     unsigned long ext4_f_type)
{
	return fprintf(
		out,
		"{\"event\":\"mdtest-cold-metadata-phase\","
		"\"schema\":\"namei_ext.mdtest_cold_metadata.phase.v1\","
		"\"repetition\":%d,\"condition\":\"%s\",\"ranks\":%d,"
		"\"items_per_rank\":%d,\"operation\":\"%s\","
		"\"phase_status\":%d,\"ops_per_second\":%.6f,"
		"\"summary_max\":%.6f,\"summary_min\":%.6f,"
		"\"summary_mean\":%.6f,\"summary_stddev\":%.6f,"
		"\"pass\":%s,\"warning_as_errors\":%s,"
		"\"warnings_or_errors_absent\":%s,\"tree_correct\":%s,"
		"\"cache_drop_value\":%d,\"cache_drop_bytes_written\":%zd,"
		"\"cache_drop_errno\":%d,"
		"\"leader_cgroup_verified\":%s,"
		"\"mpi_ranks_cgroup_verified\":%s,"
		"\"mpi_bindings_reported\":%s,\"attachment_stable\":%s,"
		"\"attached_program_id_before\":%u,"
		"\"attached_program_id_after\":%u,"
		"\"untimed_policy_runs\":%llu,\"selected_identity\":%s,"
		"\"fuse_f_type\":%lu,\"fuse_daemon_live\":%s,"
		"\"fuse_dev_fd_verified\":%s,\"ext4_f_type\":%lu,"
		"\"cleanup_complete\":%s,"
		"\"actual_files\":%llu,\"expected_files\":%llu,"
		"\"actual_directories\":%llu,\"expected_directories\":%llu,"
		"\"actual_other\":%llu,"
		"\"client_user_ns\":%llu,\"client_system_ns\":%llu,"
		"\"client_voluntary_context_switches\":%ld,"
		"\"client_involuntary_context_switches\":%ld,"
		"\"fuse_user_ns\":%llu,\"fuse_system_ns\":%llu,"
		"\"fuse_voluntary_context_switches\":%ld,"
		"\"fuse_involuntary_context_switches\":%ld}\n",
		config->repetition, config->condition, config->ranks,
		config->items_per_rank, result->operation, result->status,
		result->ops_per_second, result->summary.maximum,
		result->summary.minimum, result->summary.mean,
		result->summary.stddev, result->pass ? "true" : "false",
		result->warning_as_errors ? "true" : "false",
		result->warnings_or_errors_absent ? "true" : "false",
		result->tree_correct ? "true" : "false",
		result->cache_drop_value, result->cache_drop_bytes_written,
		result->cache_drop_errno,
		result->leader_cgroup_verified ? "true" : "false",
		result->mpi_ranks_cgroup_verified ? "true" : "false",
		result->mpi_bindings_reported ? "true" : "false",
		result->attachment_stable ? "true" : "false",
		result->program_id_before, result->program_id_after,
		(unsigned long long)result->untimed_policy_runs,
		result->selected_identity ? "true" : "false",
		result->fuse_f_type,
		result->fuse_daemon_live ? "true" : "false",
		result->fuse_dev_fd_verified ? "true" : "false",
		ext4_f_type, result->cleanup_complete ? "true" : "false",
		result->observed_tree.files, result->expected_tree.files,
		result->observed_tree.directories,
		result->expected_tree.directories,
		result->observed_tree.other,
		timeval_ns(result->client_usage.ru_utime),
		timeval_ns(result->client_usage.ru_stime),
		result->client_usage.ru_nvcsw,
		result->client_usage.ru_nivcsw,
		timeval_ns(result->fuse_usage.ru_utime),
		timeval_ns(result->fuse_usage.ru_stime),
		result->fuse_usage.ru_nvcsw,
		result->fuse_usage.ru_nivcsw) < 0 ? -EIO : 0;
}

int main(int argc, char **argv)
{
	struct cell_config config;
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct phase_result phases[MDTEST_PHASES] = {};
	struct statfs ext4_fs;
	char cell_root[PATH_MAX];
	char tmpfs_root[PATH_MAX];
	char image[PATH_MAX];
	char ext4_root[PATH_MAX];
	char physical_root[PATH_MAX];
	char logical_parent[PATH_MAX];
	char logical_view[PATH_MAX];
	char cgroup[PATH_MAX];
	bool ext4_mounted = false;
	bool tmpfs_mounted = false;
	bool view_mounted = false;
	bool cgroup_created = false;
	bool policy_loaded = false;
	bool policy_parent_configured = false;
	bool target_registered = false;
	bool cleanup_complete = false;
	bool attached;
	FILE *observations = NULL;
	int ret = 1;
	int failure = 0;

	if (argc == 5 && !strcmp(argv[1], "--parse-only"))
		return parse_only(argv[2], argv[3], argv[4]) ? 1 : 0;
	if (parse_config(argc, argv, &config)) {
		fprintf(stderr,
			"usage: %s CONDITION MDTEST FUSE POLICY OBSERVATIONS RAW_PREFIX "
			"WORK_ROOT CGROUP_ROOT RANKS ITEMS REPETITION PHASE_TIMEOUT "
			"FUSE_TIMEOUT TMPFS_SIZE IMAGE_SIZE EXT4_INODES\n",
			argv[0]);
		return 2;
	}
	attached = !strcmp(config.condition, "pass") ||
		   !strcmp(config.condition, "select");
	if (path_format(cell_root, sizeof(cell_root), "%s/ranks-%d",
			config.work_root, config.ranks) ||
	    path_format(tmpfs_root, sizeof(tmpfs_root), "%s/tmpfs", cell_root) ||
	    path_format(image, sizeof(image), "%s/ext4.img", tmpfs_root) ||
	    path_format(ext4_root, sizeof(ext4_root), "%s/ext4", cell_root) ||
	    path_format(physical_root, sizeof(physical_root), "%s/bench",
			ext4_root) ||
	    path_format(logical_parent, sizeof(logical_parent), "%s/logical",
			cell_root) ||
	    path_format(logical_view, sizeof(logical_view), "%s/view",
			logical_parent) ||
	    path_format(cgroup, sizeof(cgroup), "%s/mdtest-%ld",
			config.cgroup_root, (long)getpid())) {
		fprintf(stderr, "path construction failed\n");
		return 1;
	}
	namei_ext_remove_tree(cell_root);
	if (mkdir_p(cell_root) || mkdir_p(logical_parent) ||
	    mkdir(logical_view, 0755)) {
		perror("create cell directories");
		goto cleanup;
	}
	if (mkdir(cgroup, 0755)) {
		perror("create cgroup");
		goto cleanup;
	}
	cgroup_created = true;
	if (setup_ext4(&config, tmpfs_root, image, ext4_root, physical_root)) {
		fprintf(stderr, "ext4 setup failed\n");
		goto cleanup;
	}
	tmpfs_mounted = true;
	ext4_mounted = true;
	if (statfs(physical_root, &ext4_fs) ||
	    (unsigned long)ext4_fs.f_type != EXT4_SUPER_MAGIC) {
		fprintf(stderr, "ext4 identity failed\n");
		goto cleanup;
	}
	if (!strcmp(config.condition, "stock") ||
	    !strcmp(config.condition, "unattached") ||
	    !strcmp(config.condition, "pass")) {
		if (mount(physical_root, logical_view, NULL, MS_BIND, NULL)) {
			perror("bind logical view");
			goto cleanup;
		}
		view_mounted = true;
	}
	if (attached) {
		if (set_bpf_stats_enabled(false)) {
			fprintf(stderr, "disable BPF stats failed\n");
			goto cleanup;
		}
		if (!strcmp(config.condition, "select")) {
			if (namei_ext_register_target(cgroup, physical_root,
						     MDTEST_TARGET_ID)) {
				fprintf(stderr, "target registration failed\n");
				goto cleanup;
			}
			target_registered = true;
		}
		if (namei_ext_policy_load_attach(config.policy_object, cgroup,
						 &policy)) {
			fprintf(stderr, "policy attach failed\n");
			goto cleanup;
		}
		policy_loaded = true;
		if (namei_ext_policy_parent_exact(cgroup, logical_parent)) {
			fprintf(stderr, "policy parent setup failed\n");
			goto cleanup;
		}
		policy_parent_configured = true;
	}
	if (run_phase(&config, "create", "-C", logical_view, physical_root,
		      cgroup, attached ? &policy : NULL, &phases[0])) {
		fprintf(stderr, "create phase failed\n");
		goto cleanup;
	}
	if (run_phase(&config, "stat", "-T", logical_view, physical_root,
		      cgroup, attached ? &policy : NULL, &phases[1])) {
		fprintf(stderr, "stat phase failed\n");
		goto cleanup;
	}
	if (run_phase(&config, "remove", "-r", logical_view, physical_root,
		      cgroup, attached ? &policy : NULL, &phases[2])) {
		fprintf(stderr, "remove phase failed\n");
		goto cleanup;
	}
	ret = 0;

cleanup:
	if (policy_parent_configured &&
	    namei_ext_policy_parent_global(cgroup))
		failure = 1;
	if (policy_loaded && namei_ext_policy_destroy(&policy))
		failure = 1;
	if (target_registered && namei_ext_clear_targets(cgroup))
		failure = 1;
	if (attached && set_bpf_stats_enabled(false))
		failure = 1;
	if (view_mounted && umount2(logical_view, 0))
		failure = 1;
	if (ext4_mounted && umount2(ext4_root, 0))
		failure = 1;
	if (ext4_mounted && verify_loop_released(&config, image))
		failure = 1;
	if (tmpfs_mounted && umount2(tmpfs_root, 0))
		failure = 1;
	if (cgroup_created && rmdir(cgroup))
		failure = 1;
	if (!failure) {
		namei_ext_remove_tree(cell_root);
		cleanup_complete = access(cell_root, F_OK) && errno == ENOENT;
	}
	for (int index = 0; index < MDTEST_PHASES; index++) {
		if (phases[index].attempted)
			phases[index].cleanup_complete = cleanup_complete;
	}
	observations = fopen(config.observations, "a");
	if (!observations) {
		perror("open observations");
		return 1;
	}
	for (int index = 0; index < MDTEST_PHASES; index++) {
		if (!phases[index].attempted)
			continue;
		if (!cleanup_complete)
			phases[index].pass = false;
		if (write_observation(observations, &config, &phases[index],
				      (unsigned long)ext4_fs.f_type))
			failure = 1;
	}
	if (fclose(observations))
		failure = 1;
	return ret || failure || !cleanup_complete ? 1 : 0;
}
