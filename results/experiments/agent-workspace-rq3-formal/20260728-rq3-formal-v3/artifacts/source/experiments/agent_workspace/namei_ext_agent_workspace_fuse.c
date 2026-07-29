// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE
#define FUSE_USE_VERSION 314

#ifndef AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES
#define AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES 20
#define AGENT_WORKSPACE_RQ2_STAT_SAMPLES 100
#define AGENT_WORKSPACE_RQ2_OPEN_SAMPLES 100
#define AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES 100
#define AGENT_WORKSPACE_RQ2_READDIR_SAMPLES 50
#define AGENT_WORKSPACE_RQ2_EXEC_SAMPLES 20
#endif

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <limits.h>
#include <pthread.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

enum fuse_workspace_counter {
	FUSE_COUNTER_GETATTR = 0,
	FUSE_COUNTER_READDIR = 1,
	FUSE_COUNTER_OPEN = 2,
	FUSE_COUNTER_CREATE = 3,
	FUSE_COUNTER_READ = 4,
	FUSE_COUNTER_WRITE = 5,
	FUSE_COUNTER_READLINK = 6,
	FUSE_COUNTER_HIDDEN_LOOKUP = 7,
	FUSE_COUNTER_HIDDEN_READDIR = 8,
	FUSE_COUNTER_UNLINK = 9,
	FUSE_COUNTER_RENAME = 10,
	FUSE_COUNTER_MKNOD = 11,
	FUSE_COUNTER_INVALIDATE_ATTEMPT = 12,
	FUSE_COUNTER_INVALIDATE_ERROR = 13,
	FUSE_COUNTER_TRUNCATE = 14,
	FUSE_COUNTER_RELEASE = 15,
	FUSE_COUNTER_REQUEST_TOTAL = 16,
	FUSE_COUNTER_HANDLE_OPENED = 17,
	FUSE_COUNTER_RELEASE_COMPLETED = 18,
	FUSE_COUNTER_MAX = 19,
};

struct fuse_workspace_state {
	char base[PATH_MAX];
	char upper[PATH_MAX];
	volatile int active_epoch;
	volatile unsigned long long counters[FUSE_COUNTER_MAX];
};

enum fuse_control_command {
	FUSE_CONTROL_SET_EPOCH = 1,
	FUSE_CONTROL_STOP = 2,
};

struct fuse_control_request {
	int command;
	int epoch;
};

struct fuse_control_response {
	int status;
	unsigned int invalidations;
};

struct fuse_control_thread {
	struct fuse *fuse;
	struct fuse_workspace_state *state;
	int request_fd;
	int response_fd;
};

struct fuse_resource_sample {
	unsigned long long user_ticks;
	unsigned long long system_ticks;
	unsigned long long cpu_runtime_ns;
	unsigned long long runqueue_wait_ns;
	unsigned long long timeslices;
	unsigned long long voluntary_switches;
	unsigned long long involuntary_switches;
	unsigned long long requests;
	unsigned long long threads;
};

static const char *result_event = "agent-workspace-preflight";
static const char *result_level = "kvm_agent_workspace_dependency_preflight";

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"%s\",\"result_level\":\"%s\",\"case\":\"%s\","
		"\"pass\":%s,\"errno\":%d,\"detail\":\"%s\"}\n",
		result_event, result_level, name, pass ? "true" : "false",
		err, detail);
	fflush(out);
}

static void emit_counter(FILE *out, const char *name,
			 unsigned long long value, bool pass,
			 const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-fuse-counter\","
		"\"result_level\":\"%s\",\"counter\":\"%s\",\"value\":%llu,\"pass\":%s,"
		"\"detail\":\"%s\"}\n",
		result_level, name, value, pass ? "true" : "false", detail);
	fflush(out);
}

static void emit_metric(FILE *out, const char *name,
			unsigned long long value, bool pass,
			const char *unit, const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-metric\","
		"\"result_level\":\"%s\",\"metric\":\"%s\",\"value\":%llu,"
		"\"unit\":\"%s\",\"pass\":%s,\"detail\":\"%s\"}\n",
		result_level, name, value, unit, pass ? "true" : "false",
		detail);
	fflush(out);
}

static void emit_sample(FILE *out, const char *name, unsigned int iteration,
			unsigned long long value, bool pass, const char *unit)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-sample\","
		"\"result_level\":\"%s\",\"metric\":\"%s\",\"iteration\":%u,"
		"\"value\":%llu,\"unit\":\"%s\",\"pass\":%s}\n",
		result_level, name, iteration, value, unit,
		pass ? "true" : "false");
	fflush(out);
}

static void emit_lifecycle_sample(FILE *out, const char *name,
				  unsigned int iteration,
				  unsigned long long value, int err,
				  const char *error_stage)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-lifecycle-sample\","
		"\"result_level\":\"%s\",\"metric\":\"%s\",\"iteration\":%u,"
		"\"value\":%llu,\"unit\":\"ns\",\"pass\":%s,\"errno\":%d,"
		"\"error_stage\":\"%s\"}\n",
		result_level, name, iteration, value,
		err ? "false" : "true", err, error_stage);
	fflush(out);
}

static void emit_manifest(FILE *out, const char *name, bool pass,
			  const char *detail)
{
	fprintf(out,
		"{\"event\":\"agent-workspace-manifest\","
		"\"result_level\":\"%s\",\"manifest\":\"%s\",\"pass\":%s,"
		"\"detail\":\"%s\"}\n",
		result_level, name, pass ? "true" : "false", detail);
	fflush(out);
}

static void emit_fuse_resource(FILE *out,
			       const struct fuse_resource_sample *before,
			       const struct fuse_resource_sample *after,
			       bool pass)
{
#define RESOURCE_DELTA(field) \
	(after->field >= before->field ? after->field - before->field : 0)
	fprintf(out,
		"{\"event\":\"agent-workspace-fuse-resource\","
		"\"result_level\":\"%s\",\"window\":\"rq2-measurement\","
		"\"user_ticks\":%llu,\"system_ticks\":%llu,"
		"\"cpu_runtime_ns\":%llu,\"runqueue_wait_ns\":%llu,"
		"\"timeslices\":%llu,"
		"\"voluntary_context_switches\":%llu,"
		"\"involuntary_context_switches\":%llu,"
		"\"callback_requests\":%llu,"
		"\"threads_before\":%llu,\"threads_after\":%llu,"
		"\"clock_ticks_per_second\":%ld,"
		"\"pass\":%s}\n",
		result_level,
		RESOURCE_DELTA(user_ticks),
		RESOURCE_DELTA(system_ticks),
		RESOURCE_DELTA(cpu_runtime_ns),
		RESOURCE_DELTA(runqueue_wait_ns),
		RESOURCE_DELTA(timeslices),
		RESOURCE_DELTA(voluntary_switches),
		RESOURCE_DELTA(involuntary_switches),
		RESOURCE_DELTA(requests),
		before->threads, after->threads,
		sysconf(_SC_CLK_TCK), pass ? "true" : "false");
	fflush(out);
#undef RESOURCE_DELTA
}

static unsigned long long nsec_now(void)
{
	struct timespec ts;

	if (clock_gettime(CLOCK_MONOTONIC, &ts))
		return 0;
	return (unsigned long long)ts.tv_sec * 1000000000ull + ts.tv_nsec;
}

static int set_path(char *dst, size_t size, const char *dir, const char *name)
{
	int ret = snprintf(dst, size, "%s/%s", dir, name);

	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int write_file(const char *path, const char *value)
{
	int fd;
	ssize_t len;
	int saved_errno = 0;

	fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0644);
	if (fd < 0)
		return -errno;
	len = write(fd, value, strlen(value));
	if (len < 0)
		saved_errno = errno;
	if (close(fd) && !saved_errno)
		saved_errno = errno;
	if (saved_errno)
		return -saved_errno;
	return 0;
}

static bool file_contains_token(const char *path, const char *token)
{
	char buf[4096] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread > 0 && strstr(buf, token);
}

static int expect_source_trace(FILE *out, const char *name, const char *path)
{
	bool pass;

	pass = file_contains_token(path, "TRACE_ID=agentfs-bash-git-workspace-v1") &&
	       file_contains_token(path,
				   "UPSTREAM_COMMIT=0a014ebd4918615baff589ed17486e557e7c6a23") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-run-bash.sh:6-25") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-run-git.sh:9-30") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-overlay-whiteout.sh:60-123") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-symlinks.sh:19-68") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-fuse-cache-invalidation.sh:134-158") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-fuse-cache-invalidation.sh:109-132") &&
	       file_contains_token(path,
				   "SOURCE=cli/tests/test-fuse-cache-invalidation.sh:60-90") &&
	       file_contains_token(path,
				   "ORACLE=base-object-unchanged");
	emit_case(out, name, pass, pass ? 0 : EINVAL,
		  pass ? "fixed-commit AgentFS source bindings matched" :
			 "AgentFS trace is missing fixed upstream bindings");
	return pass ? 0 : -1;
}

static bool read_file_matches_quiet(const char *path, const char *want)
{
	char buf[128] = {};
	ssize_t nread;
	int fd;

	fd = open(path, O_RDONLY);
	if (fd < 0)
		return false;
	nread = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	return nread >= 0 && !strcmp(buf, want);
}

static bool stat_errno_quiet(const char *path, int want_errno)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st))
		return want_errno == 0;
	return want_errno && errno == want_errno;
}

static int expect_stat_errno(FILE *out, const char *name, const char *path,
			     int want_errno)
{
	struct stat st;

	errno = 0;
	if (!stat(path, &st)) {
		if (!want_errno) {
			emit_case(out, name, true, 0, "stat matched");
			return 0;
		}
		emit_case(out, name, false, 0, "stat unexpectedly succeeded");
		return -1;
	}
	if (want_errno && errno == want_errno) {
		emit_case(out, name, true, errno, "stat errno matched");
		return 0;
	}
	emit_case(out, name, false, errno, "stat mismatch");
	return -1;
}

static int expect_mode(FILE *out, const char *name, const char *path,
		       mode_t want_mode)
{
	struct stat st;
	bool pass;

	if (stat(path, &st)) {
		emit_case(out, name, false, errno, "stat for mode oracle failed");
		return -1;
	}
	pass = (st.st_mode & 0777) == want_mode;
	emit_case(out, name, pass, pass ? 0 : EINVAL,
		  pass ? "logical path mode matched selected object" :
			 "logical path mode did not match selected object");
	return pass ? 0 : -1;
}

static int expect_unprivileged_access_denied(FILE *out, const char *name,
					     const char *path)
{
	pid_t pid;
	int status;

	pid = fork();
	if (pid < 0) {
		emit_case(out, name, false, errno, "fork for access oracle failed");
		return -1;
	}
	if (!pid) {
		if (setgid(65534) || setuid(65534))
			_exit(2);
		errno = 0;
		_exit(access(path, R_OK) && errno == EACCES ? 0 : 1);
	}
	while (waitpid(pid, &status, 0) < 0) {
		if (errno == EINTR)
			continue;
		emit_case(out, name, false, errno,
			  "wait for access oracle failed");
		return -1;
	}
	if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
		emit_case(out, name, true, EACCES,
			  "unprivileged read access was denied");
		return 0;
	}
	emit_case(out, name, false, EACCES,
		  "unprivileged read access was not denied as expected");
	return -1;
}

static int expect_read_file(FILE *out, const char *name, const char *path,
			    const char *want)
{
	char buf[128] = {};
	ssize_t nread;
	int fd;
	int err;

	errno = 0;
	fd = open(path, O_RDONLY);
	if (fd < 0) {
		emit_case(out, name, false, errno, "open for read failed");
		return -1;
	}
	nread = read(fd, buf, sizeof(buf) - 1);
	err = errno;
	close(fd);
	if (nread < 0) {
		emit_case(out, name, false, err, "read failed");
		return -1;
	}
	if (!strcmp(buf, want)) {
		emit_case(out, name, true, 0, "read content matched");
		return 0;
	}
	emit_case(out, name, false, 0, "read content mismatch");
	return -1;
}

static int expect_symlink_read(FILE *out, const char *name, const char *path,
			       const char *want)
{
	char buf[128] = {};
	ssize_t nread;

	errno = 0;
	nread = readlink(path, buf, sizeof(buf) - 1);
	if (nread < 0) {
		emit_case(out, name, false, errno, "readlink failed");
		return -1;
	}
	if (!strcmp(buf, want)) {
		emit_case(out, name, true, 0, "symlink target matched");
		return 0;
	}
	emit_case(out, name, false, 0, "symlink target mismatch");
	return -1;
}

static int expect_workspace_readdir(FILE *out, const char *name, const char *path,
				    bool want_generated)
{
	bool saw_main = false;
	bool saw_deleted = false;
	bool saw_link = false;
	bool saw_generated = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "main.txt"))
			saw_main = true;
		if (!strcmp(de->d_name, "deleted.txt"))
			saw_deleted = true;
		if (!strcmp(de->d_name, "link.txt"))
			saw_link = true;
		if (!strcmp(de->d_name, "generated.txt"))
			saw_generated = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);

	if (saw_main && saw_link && !saw_deleted &&
	    saw_generated == want_generated) {
		emit_case(out, name, true, 0,
			  "workspace directory view matched");
		return 0;
	}
	emit_case(out, name, false, 0, "workspace directory view mismatch");
	return -1;
}

static int expect_native_workspace_readdir(FILE *out, const char *name,
					   const char *path, bool want_generated)
{
	bool saw_main = false;
	bool saw_deleted = false;
	bool saw_link = false;
	bool saw_generated = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "main.txt"))
			saw_main = true;
		if (!strcmp(de->d_name, "deleted.txt"))
			saw_deleted = true;
		if (!strcmp(de->d_name, "link.txt"))
			saw_link = true;
		if (!strcmp(de->d_name, "generated.txt"))
			saw_generated = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);

	if (saw_main && saw_deleted && saw_link &&
	    saw_generated == want_generated) {
		emit_case(out, name, true, 0,
			  "native lower directory view matched");
		return 0;
	}
	emit_case(out, name, false, 0, "native lower directory view mismatch");
	return -1;
}

static int expect_parent_readdir_ws(FILE *out, const char *name,
				    const char *path)
{
	bool saw_ws = false;
	struct dirent *de;
	DIR *dir;

	errno = 0;
	dir = opendir(path);
	if (!dir) {
		emit_case(out, name, false, errno, "opendir failed");
		return -1;
	}
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, "ws"))
			saw_ws = true;
	}
	if (errno) {
		emit_case(out, name, false, errno, "readdir failed");
		closedir(dir);
		return -1;
	}
	closedir(dir);
	emit_case(out, name, saw_ws, saw_ws ? 0 : ENOENT,
		  saw_ws ? "parent listed logical workspace alias" :
			   "parent did not list logical workspace alias");
	return saw_ws ? 0 : -1;
}

static int measure_stat_latency(FILE *out, const char *name, const char *path,
				int want_errno, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;

		if (!stat_errno_quiet(path, want_errno)) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "stat latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "stat latency measured");
	return 0;
}

static int measure_access_latency(FILE *out, const char *name, const char *path,
				  int mode, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;

		if (access(path, mode)) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "access latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "access latency measured");
	return 0;
}

static int measure_open_latency(FILE *out, const char *name, const char *path,
				unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		int fd;

		fd = open(path, O_RDONLY | O_CLOEXEC);
		if (fd < 0) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "open latency check failed");
			return -1;
		}
		close(fd);
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "open latency measured");
	return 0;
}

static int run_exec_once(const char *path)
{
	pid_t pid;
	int status;

	pid = fork();
	if (pid < 0)
		return -errno;
	if (!pid) {
		char *const argv[] = { (char *)path, NULL };

		execv(path, argv);
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

static int measure_exec_latency(FILE *out, const char *name, const char *path,
				unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		int err;

		err = run_exec_once(path);
		if (err) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "exec latency check failed");
			return -1;
		}
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "exec latency measured");
	return 0;
}

static int measure_readdir_latency(FILE *out, const char *name,
				   const char *path, unsigned int reps)
{
	unsigned long long total_elapsed = 0;
	unsigned int i;

	for (i = 0; i < reps; i++) {
		unsigned long long sample_start = nsec_now();
		unsigned long long sample_elapsed;
		DIR *dir;
		struct dirent *de;

		errno = 0;
		dir = opendir(path);
		if (!dir) {
			emit_metric(out, name, 0, false, "ns_per_op",
				    "opendir latency check failed");
			return -1;
		}
		while ((de = readdir(dir)))
			;
		if (errno) {
			closedir(dir);
			emit_metric(out, name, 0, false, "ns_per_op",
				    "readdir latency check failed");
			return -1;
		}
		closedir(dir);
		sample_elapsed = nsec_now() - sample_start;
		total_elapsed += sample_elapsed;
		emit_sample(out, name, i, sample_elapsed, true, "ns");
	}
	emit_metric(out, name, total_elapsed / reps, true, "ns_per_op",
		    "readdir latency measured");
	return 0;
}

static int remove_if_present(const char *path)
{
	if (!unlink(path) || errno == ENOENT)
		return 0;
	return -errno;
}

static int measure_workspace_lifecycle(FILE *out, const char *name,
				       const char *created_path,
				       const char *renamed_path,
				       unsigned int reps)
{
	unsigned int i;
	int failures = 0;

	for (i = 0; i < reps; i++) {
		unsigned long long start;
		unsigned long long elapsed;
		const char *stage = "none";
		struct stat st;
		int err = 0;

		if (remove_if_present(created_path) ||
		    remove_if_present(renamed_path) ||
		    !stat_errno_quiet(created_path, ENOENT) ||
		    !stat_errno_quiet(renamed_path, ENOENT))
			return -1;

		start = nsec_now();
		errno = 0;
		if (!stat(created_path, &st) || errno != ENOENT) {
			err = errno ? errno : EEXIST;
			stage = "negative_lookup";
		} else if (mknod(created_path, S_IFREG | 0644, 0)) {
			err = errno;
			stage = "create";
		}
		if (!err && rename(created_path, renamed_path)) {
			err = errno;
			stage = "rename";
		}
		if (!err && unlink(renamed_path)) {
			err = errno;
			stage = "unlink";
		}
		elapsed = nsec_now() - start;

		if (!stat_errno_quiet(created_path, ENOENT) ||
		    !stat_errno_quiet(renamed_path, ENOENT)) {
			if (!err) {
				err = EIO;
				stage = "postcondition";
			}
			remove_if_present(created_path);
			remove_if_present(renamed_path);
		}
		emit_lifecycle_sample(out, name, i, elapsed, err, stage);
		if (err)
			failures++;
	}
	return failures ? -1 : 0;
}

static int expect_final_manifest(FILE *out, const char *logical_main,
				 const char *logical_deleted,
				 const char *logical_generated,
				 const char *base_generated)
{
	bool pass;

	pass = read_file_matches_quiet(logical_main, "upper-main\n") &&
	       read_file_matches_quiet(logical_generated,
				       "generated-in-upper\n") &&
	       stat_errno_quiet(logical_deleted, ENOENT) &&
	       stat_errno_quiet(base_generated, ENOENT);
	emit_manifest(out, "fuse_final_tree_manifest", pass,
		      pass ? "logical tree matched expected upper epoch manifest" :
			     "logical tree manifest mismatch");
	return pass ? 0 : -1;
}

static struct fuse_workspace_state *fuse_state(void)
{
	return fuse_get_context()->private_data;
}

static void fuse_count_state(struct fuse_workspace_state *state, unsigned int key)
{
	if (key < FUSE_COUNTER_MAX)
		__sync_fetch_and_add(&state->counters[key], 1);
}

static void fuse_count(unsigned int key)
{
	fuse_count_state(fuse_state(), key);
}

static void fuse_count_request(unsigned int key)
{
	struct fuse_workspace_state *state = fuse_state();

	fuse_count_state(state, FUSE_COUNTER_REQUEST_TOTAL);
	fuse_count_state(state, key);
}

static unsigned long long fuse_request_count(
	const struct fuse_workspace_state *state)
{
	return state->counters[FUSE_COUNTER_REQUEST_TOTAL];
}

static int read_task_resource(pid_t pid, const char *task,
			      struct fuse_resource_sample *sample)
{
	unsigned long long cpu_runtime_ns;
	unsigned long long runqueue_wait_ns;
	unsigned long long timeslices;
	char path[PATH_MAX];
	char line[4096];
	FILE *file;

	snprintf(path, sizeof(path), "/proc/%d/task/%s/schedstat", pid, task);
	file = fopen(path, "r");
	if (!file)
		return -errno;
	if (fscanf(file, "%llu %llu %llu", &cpu_runtime_ns,
		   &runqueue_wait_ns, &timeslices) != 3) {
		fclose(file);
		return -EINVAL;
	}
	fclose(file);
	sample->cpu_runtime_ns += cpu_runtime_ns;
	sample->runqueue_wait_ns += runqueue_wait_ns;
	sample->timeslices += timeslices;

	snprintf(path, sizeof(path), "/proc/%d/task/%s/status", pid, task);
	file = fopen(path, "r");
	if (!file)
		return -errno;
	while (fgets(line, sizeof(line), file)) {
		unsigned long long value;

		if (sscanf(line, "voluntary_ctxt_switches: %llu", &value) == 1)
			sample->voluntary_switches += value;
		if (sscanf(line, "nonvoluntary_ctxt_switches: %llu", &value) == 1)
			sample->involuntary_switches += value;
	}
	if (ferror(file)) {
		int err = errno ? errno : EIO;

		fclose(file);
		return -err;
	}
	fclose(file);
	sample->threads++;
	return 0;
}

static int read_fuse_resource(pid_t pid,
			      const struct fuse_workspace_state *state,
			      struct fuse_resource_sample *sample)
{
	struct dirent *entry;
	char path[PATH_MAX];
	char line[4096];
	char *after_comm;
	char process_state;
	long long ignored[10];
	DIR *tasks;
	FILE *file;
	int matched;

	memset(sample, 0, sizeof(*sample));
	snprintf(path, sizeof(path), "/proc/%d/stat", pid);
	file = fopen(path, "r");
	if (!file)
		return -errno;
	if (!fgets(line, sizeof(line), file)) {
		int err = errno ? errno : EIO;

		fclose(file);
		return -err;
	}
	fclose(file);
	after_comm = strrchr(line, ')');
	if (!after_comm || after_comm[1] != ' ')
		return -EINVAL;
	matched = sscanf(after_comm + 2,
			 "%c %lld %lld %lld %lld %lld %lld %lld %lld %lld %lld %llu %llu",
			 &process_state,
			 &ignored[0], &ignored[1], &ignored[2], &ignored[3],
			 &ignored[4], &ignored[5], &ignored[6], &ignored[7],
			 &ignored[8], &ignored[9], &sample->user_ticks,
			 &sample->system_ticks);
	if (matched != 13)
		return -EINVAL;
	(void)process_state;

	snprintf(path, sizeof(path), "/proc/%d/task", pid);
	tasks = opendir(path);
	if (!tasks)
		return -errno;
	for (;;) {
		const char *cursor;
		int ret;

		errno = 0;
		entry = readdir(tasks);
		if (!entry) {
			if (errno) {
				ret = -errno;
				closedir(tasks);
				return ret;
			}
			break;
		}
		cursor = entry->d_name;
		if (!*cursor)
			continue;
		while (*cursor >= '0' && *cursor <= '9')
			cursor++;
		if (*cursor)
			continue;
		ret = read_task_resource(pid, entry->d_name, sample);
		if (ret) {
			closedir(tasks);
			return ret;
		}
	}
	if (closedir(tasks))
		return -errno;
	if (!sample->threads)
		return -ESRCH;
	sample->requests = fuse_request_count(state);
	return 0;
}

static bool fuse_resource_monotonic(
	const struct fuse_resource_sample *before,
	const struct fuse_resource_sample *after)
{
	return after->user_ticks >= before->user_ticks &&
	       after->system_ticks >= before->system_ticks &&
	       after->cpu_runtime_ns >= before->cpu_runtime_ns &&
	       after->runqueue_wait_ns >= before->runqueue_wait_ns &&
	       after->timeslices >= before->timeslices &&
	       after->voluntary_switches >= before->voluntary_switches &&
	       after->involuntary_switches >= before->involuntary_switches &&
	       after->requests >= before->requests &&
	       before->threads == after->threads;
}

static int wait_fuse_quiescent(const struct fuse_workspace_state *state)
{
	const unsigned long long stable_ns = 20000000ull;
	const unsigned long long deadline = nsec_now() + 5000000000ull;
	struct timespec delay = {
		.tv_sec = 0,
		.tv_nsec = 1000000,
	};
	unsigned long long stable_since = 0;
	unsigned long long previous_total = ULLONG_MAX;

	while (nsec_now() < deadline) {
		unsigned long long handle_count;
		unsigned long long release_count;
		unsigned long long total;
		unsigned long long now;

		__sync_synchronize();
		handle_count = state->counters[FUSE_COUNTER_HANDLE_OPENED];
		release_count = state->counters[FUSE_COUNTER_RELEASE_COMPLETED];
		total = state->counters[FUSE_COUNTER_REQUEST_TOTAL];
		now = nsec_now();
		if (release_count > handle_count)
			return -EOVERFLOW;
		if (release_count == handle_count &&
		    total == previous_total) {
			if (!stable_since)
				stable_since = now;
			else if (now - stable_since >= stable_ns)
				return 0;
		} else {
			stable_since = 0;
		}
		previous_total = total;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static const char *active_target(const struct fuse_workspace_state *state)
{
	return state->active_epoch ? state->upper : state->base;
}

static bool is_hidden_path(const char *path)
{
	return !strcmp(path, "/ws/deleted.txt");
}

static int backing_path(const char *path, char *dst, size_t size)
{
	struct fuse_workspace_state *state = fuse_state();
	const char *target;
	const char *suffix;
	int ret;

	if (is_hidden_path(path)) {
		fuse_count_state(state, FUSE_COUNTER_HIDDEN_LOOKUP);
		return -ENOENT;
	}
	if (!strcmp(path, "/ws")) {
		ret = snprintf(dst, size, "%s", active_target(state));
		if (ret < 0)
			return -errno;
		if ((size_t)ret >= size)
			return -ENAMETOOLONG;
		return 0;
	}
	if (strncmp(path, "/ws/", 4))
		return -ENOENT;

	target = active_target(state);
	suffix = path + 4;
	if (!suffix[0])
		return -ENOENT;
	ret = snprintf(dst, size, "%s/%s", target, suffix);
	if (ret < 0)
		return -errno;
	if ((size_t)ret >= size)
		return -ENAMETOOLONG;
	return 0;
}

static int agent_fuse_getattr(const char *path, struct stat *st,
			      struct fuse_file_info *fi)
{
	char backing[PATH_MAX];
	int ret;

	(void)fi;
	fuse_count_request(FUSE_COUNTER_GETATTR);
	memset(st, 0, sizeof(*st));
	if (!strcmp(path, "/")) {
		st->st_mode = S_IFDIR | 0755;
		st->st_nlink = 2;
		return 0;
	}

	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	if (lstat(backing, st))
		return -errno;
	return 0;
}

static int agent_fuse_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
			      off_t off, struct fuse_file_info *fi,
			      enum fuse_readdir_flags flags)
{
	char backing[PATH_MAX];
	struct dirent *de;
	DIR *dir;
	int ret;

	(void)off;
	(void)fi;
	(void)flags;

	fuse_count_request(FUSE_COUNTER_READDIR);
	filler(buf, ".", NULL, 0, 0);
	filler(buf, "..", NULL, 0, 0);
	if (!strcmp(path, "/")) {
		filler(buf, "ws", NULL, 0, 0);
		return 0;
	}

	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	dir = opendir(backing);
	if (!dir)
		return -errno;
	while ((de = readdir(dir))) {
		if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
			continue;
		if (!strcmp(de->d_name, "deleted.txt")) {
			fuse_count(FUSE_COUNTER_HIDDEN_READDIR);
			continue;
		}
		filler(buf, de->d_name, NULL, 0, 0);
	}
	closedir(dir);
	return 0;
}

static int agent_fuse_open(const char *path, struct fuse_file_info *fi)
{
	char backing[PATH_MAX];
	int fd;
	int ret;

	fuse_count_request(FUSE_COUNTER_OPEN);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	fd = open(backing, fi->flags);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fuse_count(FUSE_COUNTER_HANDLE_OPENED);
	return 0;
}

static int agent_fuse_create(const char *path, mode_t mode,
			     struct fuse_file_info *fi)
{
	char backing[PATH_MAX];
	int fd;
	int ret;

	fuse_count_request(FUSE_COUNTER_CREATE);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	fd = open(backing, fi->flags | O_CREAT, mode);
	if (fd < 0)
		return -errno;
	fi->fh = (uint64_t)fd;
	fuse_count(FUSE_COUNTER_HANDLE_OPENED);
	return 0;
}

static int agent_fuse_mknod(const char *path, mode_t mode, dev_t rdev)
{
	char backing[PATH_MAX];
	int ret;

	fuse_count_request(FUSE_COUNTER_MKNOD);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	if (mknod(backing, mode, rdev))
		return -errno;
	return 0;
}

static int agent_fuse_read(const char *path, char *buf, size_t size, off_t off,
			   struct fuse_file_info *fi)
{
	ssize_t nread;
	int fd = (int)fi->fh;

	fuse_count_request(FUSE_COUNTER_READ);
	(void)path;
	nread = pread(fd, buf, size, off);
	if (nread < 0)
		return -errno;
	return (int)nread;
}

static int agent_fuse_write(const char *path, const char *buf, size_t size,
			    off_t off, struct fuse_file_info *fi)
{
	ssize_t nwritten;
	int fd = (int)fi->fh;

	fuse_count_request(FUSE_COUNTER_WRITE);
	(void)path;
	nwritten = pwrite(fd, buf, size, off);
	if (nwritten < 0)
		return -errno;
	return (int)nwritten;
}

static int agent_fuse_truncate(const char *path, off_t size,
			       struct fuse_file_info *fi)
{
	char backing[PATH_MAX];
	int ret;

	(void)fi;
	fuse_count_request(FUSE_COUNTER_TRUNCATE);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	if (truncate(backing, size))
		return -errno;
	return 0;
}

static int agent_fuse_readlink(const char *path, char *buf, size_t size)
{
	char backing[PATH_MAX];
	ssize_t nread;
	int ret;

	fuse_count_request(FUSE_COUNTER_READLINK);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	nread = readlink(backing, buf, size - 1);
	if (nread < 0)
		return -errno;
	buf[nread] = '\0';
	return 0;
}

static int agent_fuse_unlink(const char *path)
{
	char backing[PATH_MAX];
	int ret;

	fuse_count_request(FUSE_COUNTER_UNLINK);
	ret = backing_path(path, backing, sizeof(backing));
	if (ret)
		return ret;
	if (unlink(backing))
		return -errno;
	return 0;
}

static int agent_fuse_rename(const char *from, const char *to,
			     unsigned int flags)
{
	char backing_from[PATH_MAX];
	char backing_to[PATH_MAX];
	int ret;

	fuse_count_request(FUSE_COUNTER_RENAME);
	if (flags)
		return -EINVAL;
	ret = backing_path(from, backing_from, sizeof(backing_from));
	if (ret)
		return ret;
	ret = backing_path(to, backing_to, sizeof(backing_to));
	if (ret)
		return ret;
	if (rename(backing_from, backing_to))
		return -errno;
	return 0;
}

static int agent_fuse_release(const char *path, struct fuse_file_info *fi)
{
	int saved_errno;
	int ret;

	fuse_count_request(FUSE_COUNTER_RELEASE);
	(void)path;
	ret = close((int)fi->fh);
	saved_errno = ret ? errno : 0;
	fuse_count(FUSE_COUNTER_RELEASE_COMPLETED);
	return ret ? -saved_errno : 0;
}

static struct fuse_operations agent_fuse_ops = {
	.getattr = agent_fuse_getattr,
	.readdir = agent_fuse_readdir,
	.open = agent_fuse_open,
	.create = agent_fuse_create,
	.mknod = agent_fuse_mknod,
	.read = agent_fuse_read,
	.write = agent_fuse_write,
	.truncate = agent_fuse_truncate,
	.readlink = agent_fuse_readlink,
	.unlink = agent_fuse_unlink,
	.rename = agent_fuse_rename,
	.release = agent_fuse_release,
};

static int read_full(int fd, void *buf, size_t size)
{
	size_t offset = 0;

	while (offset < size) {
		ssize_t nread = read(fd, (char *)buf + offset, size - offset);

		if (!nread)
			return -EPIPE;
		if (nread < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		offset += (size_t)nread;
	}
	return 0;
}

static int write_full(int fd, const void *buf, size_t size)
{
	size_t offset = 0;

	while (offset < size) {
		ssize_t nwritten = write(fd, (const char *)buf + offset,
					 size - offset);

		if (nwritten < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		offset += (size_t)nwritten;
	}
	return 0;
}

static void *fuse_control_loop(void *arg)
{
	static const char *const epoch_paths[] = {
		"/ws",
		"/ws/main.txt",
		"/ws/src/app.txt",
		"/ws/.git/HEAD",
		"/ws/link.txt",
		"/ws/denied.txt",
	};
	struct fuse_control_thread *control = arg;

	for (;;) {
		struct fuse_control_request request;
		struct fuse_control_response response = {};
		size_t i;
		int ret;

		ret = read_full(control->request_fd, &request, sizeof(request));
		if (ret)
			return (void *)(intptr_t)ret;
		if (request.command == FUSE_CONTROL_STOP) {
			ret = write_full(control->response_fd, &response,
					 sizeof(response));
			return (void *)(intptr_t)ret;
		}
		if (request.command != FUSE_CONTROL_SET_EPOCH ||
		    (request.epoch != 0 && request.epoch != 1)) {
			response.status = -EINVAL;
		} else {
			control->state->active_epoch = request.epoch;
			__sync_synchronize();
			for (i = 0; i < sizeof(epoch_paths) /
					     sizeof(epoch_paths[0]); i++) {
				ret = fuse_invalidate_path(control->fuse,
							   epoch_paths[i]);
				fuse_count_state(
					control->state,
					FUSE_COUNTER_INVALIDATE_ATTEMPT);
				response.invalidations++;
				if (ret) {
					fuse_count_state(
						control->state,
						FUSE_COUNTER_INVALIDATE_ERROR);
					if (!response.status)
						response.status = ret;
				}
			}
		}
		ret = write_full(control->response_fd, &response, sizeof(response));
		if (ret)
			return (void *)(intptr_t)ret;
	}
}

static int run_fuse_daemon(struct fuse_workspace_state *state,
			   const char *mountpoint, int request_fd,
			   int response_fd)
{
	char *fuse_argv[] = {
		"namei_ext_agent_workspace_fuse",
		"-o",
		"attr_timeout=3600,entry_timeout=3600,negative_timeout=3600,default_permissions",
		NULL,
	};
	struct fuse_args args = FUSE_ARGS_INIT(3, fuse_argv);
	struct fuse_control_thread control;
	struct fuse *fuse;
	pthread_t control_thread;
	void *thread_status = NULL;
	int loop_status;
	int ret;

	fuse = fuse_new(&args, &agent_fuse_ops, sizeof(agent_fuse_ops), state);
	if (!fuse) {
		fuse_opt_free_args(&args);
		return 2;
	}
	if (fuse_mount(fuse, mountpoint)) {
		fuse_destroy(fuse);
		fuse_opt_free_args(&args);
		return 2;
	}
	control = (struct fuse_control_thread) {
		.fuse = fuse,
		.state = state,
		.request_fd = request_fd,
		.response_fd = response_fd,
	};
	ret = pthread_create(&control_thread, NULL, fuse_control_loop, &control);
	if (ret) {
		fuse_unmount(fuse);
		fuse_destroy(fuse);
		fuse_opt_free_args(&args);
		return 2;
	}
	loop_status = fuse_loop(fuse);
	ret = pthread_join(control_thread, &thread_status);
	fuse_unmount(fuse);
	fuse_destroy(fuse);
	fuse_opt_free_args(&args);
	if (loop_status || ret || (intptr_t)thread_status)
		return 1;
	return 0;
}

static int request_fuse_control(int request_fd, int response_fd,
				int command, int epoch,
				unsigned int *invalidations)
{
	struct fuse_control_request request = {
		.command = command,
		.epoch = epoch,
	};
	struct fuse_control_response response;
	int ret;

	ret = write_full(request_fd, &request, sizeof(request));
	if (ret)
		return ret;
	ret = read_full(response_fd, &response, sizeof(response));
	if (ret)
		return ret;
	if (invalidations)
		*invalidations = response.invalidations;
	return response.status;
}

static int wait_for_fuse_ready(const char *ready_path, pid_t fuse_pid)
{
	struct timespec delay = {
		.tv_sec = 0,
		.tv_nsec = 50000000,
	};
	int i;

	for (i = 0; i < 100; i++) {
		struct stat st;
		int status;
		pid_t wait_ret;

		if (!stat(ready_path, &st))
			return 0;
		wait_ret = waitpid(fuse_pid, &status, WNOHANG);
		if (wait_ret == fuse_pid)
			return -EIO;
		if (wait_ret < 0 && errno != EINTR)
			return -errno;
		nanosleep(&delay, NULL);
	}
	return -ETIMEDOUT;
}

static int stop_fuse(const char *mountpoint, pid_t fuse_pid, int request_fd,
		     int response_fd)
{
	struct timespec delay = {
		.tv_sec = 0,
		.tv_nsec = 10000000,
	};
	int first_error = 0;
	int status;
	int ret;
	int i;

	if (request_fd >= 0 && response_fd >= 0) {
		ret = request_fuse_control(request_fd, response_fd,
					   FUSE_CONTROL_STOP, 0, NULL);
		if (ret)
			first_error = ret;
	}
	if (umount(mountpoint) && errno != EINVAL)
		if (!first_error)
			first_error = -errno;

	if (fuse_pid > 0) {
		for (i = 0; i < 100; i++) {
			ret = waitpid(fuse_pid, &status, WNOHANG);
			if (ret == fuse_pid)
				break;
			if (ret < 0) {
				if (errno == EINTR)
					continue;
				if (errno != ECHILD && !first_error)
					first_error = -errno;
				break;
			}
			nanosleep(&delay, NULL);
		}
		if (ret == 0) {
			kill(fuse_pid, SIGTERM);
			while (waitpid(fuse_pid, &status, 0) < 0 &&
			       errno == EINTR)
				;
			if (!first_error)
				first_error = -ETIMEDOUT;
		} else if (ret == fuse_pid &&
			   (!WIFEXITED(status) || WEXITSTATUS(status)) &&
			   !first_error) {
			first_error = -EIO;
		}
	}
	return first_error;
}

static int expect_fuse_counter(FILE *out, struct fuse_workspace_state *state,
			       const char *name, unsigned int key,
			       bool require_nonzero)
{
	unsigned long long value;

	if (key >= FUSE_COUNTER_MAX) {
		emit_counter(out, name, 0, false, "counter key out of range");
		return -1;
	}
	value = state->counters[key];
	if (require_nonzero && !value) {
		emit_counter(out, name, value, false, "counter stayed zero");
		return -1;
	}
	emit_counter(out, name, value, true, "counter observed");
	return 0;
}

int main(int argc, char **argv)
{
	const char *result_path;
	const char *source_trace_path = NULL;
	char root[] = "/tmp/namei-ext-agent-workspace-fuse-XXXXXX";
	char mountpoint[PATH_MAX];
	char base[PATH_MAX];
	char upper[PATH_MAX];
	char logical_root[PATH_MAX];
	char logical_main[PATH_MAX];
	char logical_deleted[PATH_MAX];
	char logical_link[PATH_MAX];
	char logical_generated[PATH_MAX];
	char logical_renamed[PATH_MAX];
	char logical_cached_negative[PATH_MAX];
	char logical_lifecycle_created[PATH_MAX];
	char logical_lifecycle_renamed[PATH_MAX];
	char logical_denied[PATH_MAX];
	char logical_tool[PATH_MAX];
	char base_main[PATH_MAX];
	char base_deleted[PATH_MAX];
	char base_link[PATH_MAX];
	char base_generated[PATH_MAX];
	char base_renamed[PATH_MAX];
	char base_cached_negative[PATH_MAX];
	char base_denied[PATH_MAX];
	char base_tool[PATH_MAX];
	char upper_main[PATH_MAX];
	char upper_deleted[PATH_MAX];
	char upper_link[PATH_MAX];
	char upper_generated[PATH_MAX];
	char upper_renamed[PATH_MAX];
	char upper_cached_negative[PATH_MAX];
	char upper_denied[PATH_MAX];
	char upper_tool[PATH_MAX];
	char logical_src_app[PATH_MAX];
	char logical_git_head[PATH_MAX];
	char base_src[PATH_MAX];
	char upper_src[PATH_MAX];
	char base_git[PATH_MAX];
	char upper_git[PATH_MAX];
	char base_src_app[PATH_MAX];
	char upper_src_app[PATH_MAX];
	char base_git_head[PATH_MAX];
	char upper_git_head[PATH_MAX];
	struct fuse_workspace_state *state = MAP_FAILED;
	struct fuse_resource_sample resource_before = {};
	struct fuse_resource_sample resource_after = {};
	bool resource_window_started = false;
	FILE *out;
	pid_t fuse_pid = -1;
	int control_request_fd = -1;
	int control_response_fd = -1;
	int request_pipe[2] = { -1, -1 };
	int response_pipe[2] = { -1, -1 };
	bool matrix_mode = false;
	bool rq2_mode = false;
	int fails = 0;
	int err;
	int argi = 1;

	if (argi < argc && !strcmp(argv[argi], "--matrix")) {
		matrix_mode = true;
		result_event = "agent-workspace-matrix";
		result_level = "kvm_agent_workspace_lifecycle_matrix";
		argi++;
	} else if (argi < argc && !strcmp(argv[argi], "--rq2")) {
		rq2_mode = true;
		result_event = "agent-workspace-rq2";
		result_level = "kvm_agent_workspace_rq2_boot";
		argi++;
	}

	if (argc - argi < 1 || argc - argi > 2) {
		fprintf(stderr,
			"usage: %s [--matrix|--rq2] RESULT_JSONL [SOURCE_TRACE]\n",
			argv[0]);
		return 2;
	}
	result_path = argv[argi];
	if (argc - argi == 2)
		source_trace_path = argv[argi + 1];
	if ((matrix_mode || rq2_mode) && !source_trace_path) {
		fprintf(stderr, "matrix and RQ2 modes require SOURCE_TRACE\n");
		return 2;
	}

	out = fopen(result_path, "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}

	if (!mkdtemp(root)) {
		emit_case(out, "fuse_mkdtemp", false, errno, "mkdtemp failed");
		fclose(out);
		return 1;
	}
	if (chmod(root, 0755)) {
		emit_case(out, "fuse_setup_root_mode", false, errno,
			  "workspace root chmod failed");
		fclose(out);
		return 1;
	}

	if (set_path(mountpoint, sizeof(mountpoint), root, "fuse-view") ||
	    set_path(base, sizeof(base), root, "base") ||
	    set_path(upper, sizeof(upper), root, "upper") ||
	    set_path(logical_root, sizeof(logical_root), mountpoint, "ws") ||
	    set_path(logical_main, sizeof(logical_main), mountpoint,
		     "ws/main.txt") ||
	    set_path(logical_deleted, sizeof(logical_deleted), mountpoint,
		     "ws/deleted.txt") ||
	    set_path(logical_link, sizeof(logical_link), mountpoint,
		     "ws/link.txt") ||
	    set_path(logical_generated, sizeof(logical_generated), mountpoint,
		     "ws/generated.txt") ||
	    set_path(logical_renamed, sizeof(logical_renamed), mountpoint,
		     "ws/renamed.txt") ||
	    set_path(logical_cached_negative, sizeof(logical_cached_negative),
		     mountpoint, "ws/cached-negative.txt") ||
	    set_path(logical_lifecycle_created,
		     sizeof(logical_lifecycle_created), mountpoint,
		     "ws/lifecycle-created.txt") ||
	    set_path(logical_lifecycle_renamed,
		     sizeof(logical_lifecycle_renamed), mountpoint,
		     "ws/lifecycle-renamed.txt") ||
	    set_path(logical_denied, sizeof(logical_denied), mountpoint,
		     "ws/denied.txt") ||
	    set_path(logical_tool, sizeof(logical_tool), mountpoint,
		     "ws/tool.sh") ||
	    set_path(base_main, sizeof(base_main), base, "main.txt") ||
	    set_path(base_deleted, sizeof(base_deleted), base, "deleted.txt") ||
	    set_path(base_link, sizeof(base_link), base, "link.txt") ||
	    set_path(base_generated, sizeof(base_generated), base,
		     "generated.txt") ||
	    set_path(base_renamed, sizeof(base_renamed), base, "renamed.txt") ||
	    set_path(base_cached_negative, sizeof(base_cached_negative), base,
		     "cached-negative.txt") ||
	    set_path(base_denied, sizeof(base_denied), base, "denied.txt") ||
	    set_path(base_tool, sizeof(base_tool), base, "tool.sh") ||
	    set_path(upper_main, sizeof(upper_main), upper, "main.txt") ||
	    set_path(upper_deleted, sizeof(upper_deleted), upper,
		     "deleted.txt") ||
	    set_path(upper_link, sizeof(upper_link), upper, "link.txt") ||
	    set_path(upper_generated, sizeof(upper_generated), upper,
		     "generated.txt") ||
	    set_path(upper_renamed, sizeof(upper_renamed), upper,
		     "renamed.txt") ||
	    set_path(upper_cached_negative, sizeof(upper_cached_negative),
		     upper, "cached-negative.txt") ||
	    set_path(upper_denied, sizeof(upper_denied), upper, "denied.txt") ||
	    set_path(upper_tool, sizeof(upper_tool), upper, "tool.sh") ||
	    set_path(logical_src_app, sizeof(logical_src_app), mountpoint,
		     "ws/src/app.txt") ||
	    set_path(logical_git_head, sizeof(logical_git_head), mountpoint,
		     "ws/.git/HEAD") ||
	    set_path(base_src, sizeof(base_src), base, "src") ||
	    set_path(upper_src, sizeof(upper_src), upper, "src") ||
	    set_path(base_git, sizeof(base_git), base, ".git") ||
	    set_path(upper_git, sizeof(upper_git), upper, ".git") ||
	    set_path(base_src_app, sizeof(base_src_app), base_src, "app.txt") ||
	    set_path(upper_src_app, sizeof(upper_src_app), upper_src,
		     "app.txt") ||
	    set_path(base_git_head, sizeof(base_git_head), base_git, "HEAD") ||
	    set_path(upper_git_head, sizeof(upper_git_head), upper_git,
		     "HEAD")) {
		emit_case(out, "fuse_set_paths", false, ENAMETOOLONG,
			  "path construction failed");
		fails++;
		goto cleanup;
	}

	if (mkdir(mountpoint, 0755) || mkdir(base, 0755) || mkdir(upper, 0755)) {
		emit_case(out, "fuse_setup_dirs", false, errno, "mkdir failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "fuse_setup_dirs", true, 0,
		  "mount, base, and upper directories created");

	if (mkdir(base_src, 0755) || mkdir(upper_src, 0755) ||
	    mkdir(base_git, 0755) || mkdir(upper_git, 0755)) {
		emit_case(out, "fuse_setup_source_dirs", false, errno,
			  "source-like directory setup failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "fuse_setup_source_dirs", true, 0,
		  "source-like src and .git directories created");
	if (matrix_mode || rq2_mode) {
		fails += !!expect_source_trace(out,
					       "fuse_agentfs_source_trace_artifact",
					       source_trace_path);
		emit_case(out, "fuse_agentfs_source_trace_replayed",
			  fails == 0, fails,
			  "AgentFS-derived trace replayed as .git/src, whiteout, symlink, create, rename, unlink, and cached-negative oracle rows");
	}

	if (write_file(base_main, "base-main\n") ||
	    write_file(base_deleted, "base-deleted\n") ||
	    write_file(upper_main, "upper-main\n") ||
	    write_file(upper_deleted, "upper-deleted\n") ||
	    write_file(base_denied, "base-denied\n") ||
	    write_file(upper_denied, "upper-denied\n") ||
	    write_file(base_tool, "#!/bin/sh\nexit 0\n") ||
	    write_file(upper_tool, "#!/bin/sh\nexit 0\n") ||
	    write_file(base_src_app, "base-app\n") ||
	    write_file(upper_src_app, "agent-edited-app\n") ||
	    write_file(base_git_head, "ref: refs/heads/main\n") ||
	    write_file(upper_git_head, "ref: refs/heads/agent\n") ||
	    symlink("main.txt", base_link) ||
	    symlink("main.txt", upper_link)) {
		emit_case(out, "fuse_setup_files", false, errno,
			  "workspace file setup failed");
		fails++;
		goto cleanup;
	}
	if (chmod(base_tool, 0755) || chmod(upper_tool, 0755) ||
	    chmod(upper_main, 0600) || chmod(base_denied, 0000) ||
	    chmod(upper_denied, 0100)) {
		emit_case(out, "fuse_setup_executable_tools", false, errno,
			  "chmod executable tool failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "fuse_setup_executable_tools", true, 0,
		  "base and upper executable tool files created");
	emit_case(out, "fuse_setup_files", true, 0,
		  "base and upper workspace files created");

	fails += !!expect_read_file(out, "fuse_nohook_base_main", base_main,
				    "base-main\n");
	fails += !!expect_read_file(out, "fuse_nohook_upper_main", upper_main,
				    "upper-main\n");
	fails += !!expect_stat_errno(out, "fuse_nohook_base_deleted_visible",
				     base_deleted, 0);
	fails += !!expect_native_workspace_readdir(out, "fuse_nohook_base_readdir",
						   base, false);
	fails += !!measure_stat_latency(out, "fuse_nohook_stat_base_main_ns",
					base_main, 0,
					rq2_mode ?
					AGENT_WORKSPACE_RQ2_STAT_SAMPLES : 100);
	fails += !!measure_readdir_latency(out, "fuse_nohook_readdir_base_ns",
					   base, rq2_mode ?
					   AGENT_WORKSPACE_RQ2_READDIR_SAMPLES :
					   50);

	state = mmap(NULL, sizeof(*state), PROT_READ | PROT_WRITE,
		     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
	if (state == MAP_FAILED) {
		emit_case(out, "fuse_state_mmap", false, errno, "mmap failed");
		fails++;
		goto cleanup;
	}
	snprintf(state->base, sizeof(state->base), "%s", base);
	snprintf(state->upper, sizeof(state->upper), "%s", upper);
	state->active_epoch = 0;

	if (pipe(request_pipe) || pipe(response_pipe)) {
		emit_case(out, "fuse_control_pipe", false, errno,
			  "FUSE control pipe creation failed");
		fails++;
		goto cleanup;
	}
	fuse_pid = fork();
	if (fuse_pid < 0) {
		emit_case(out, "fuse_fork", false, errno, "fork failed");
		fails++;
		goto cleanup;
	}
	if (fuse_pid == 0) {
		close(request_pipe[1]);
		close(response_pipe[0]);
		_exit(run_fuse_daemon(state, mountpoint, request_pipe[0],
				      response_pipe[1]));
	}
	close(request_pipe[0]);
	request_pipe[0] = -1;
	close(response_pipe[1]);
	response_pipe[1] = -1;
	control_request_fd = request_pipe[1];
	control_response_fd = response_pipe[0];
	request_pipe[1] = -1;
	response_pipe[0] = -1;
	emit_case(out, "fuse_options_recorded", true, 0,
		  "single_threaded=true,attr_timeout=3600,entry_timeout=3600,negative_timeout=3600,default_permissions=true,kernel_cache=false");

	err = wait_for_fuse_ready(logical_root, fuse_pid);
	if (err) {
		emit_case(out, "fuse_mount_ready", false, -err,
			  "FUSE mount did not become ready");
		fails++;
		goto cleanup;
	}
	emit_case(out, "fuse_mount_ready", true, 0,
		  "FUSE policy filesystem mounted");

	fails += !!expect_parent_readdir_ws(out, "fuse_parent_lists_ws",
					    mountpoint);
	fails += !!expect_stat_errno(out, "fuse_selected_root_visible",
				     logical_root, 0);
	fails += !!expect_workspace_readdir(out, "fuse_base_epoch_readdir",
					    logical_root, false);
	fails += !!expect_read_file(out, "fuse_base_epoch_main", logical_main,
				    "base-main\n");
	fails += !!expect_mode(out, "fuse_base_epoch_main_mode",
			       logical_main, 0644);
	fails += !!expect_unprivileged_access_denied(
		out, "fuse_base_epoch_denied_access", logical_denied);
	fails += !!expect_mode(out, "fuse_base_epoch_denied_mode",
			       logical_denied, 0000);
	fails += !!expect_read_file(out, "fuse_base_epoch_src_app",
				    logical_src_app, "base-app\n");
	fails += !!expect_read_file(out, "fuse_base_epoch_git_head",
				    logical_git_head,
				    "ref: refs/heads/main\n");
	fails += !!expect_stat_errno(out, "fuse_base_epoch_whiteout",
				     logical_deleted, ENOENT);
	fails += !!expect_symlink_read(out, "fuse_base_epoch_symlink",
				       logical_link, "main.txt");

	{
		unsigned int invalidations = 0;

		err = request_fuse_control(control_request_fd,
					   control_response_fd,
					   FUSE_CONTROL_SET_EPOCH, 1,
					   &invalidations);
		emit_case(out, "fuse_epoch_switch_invalidated",
			  !err && invalidations == 6, err ? -err : 0,
			  "epoch switched after six targeted inode invalidations");
		if (err || invalidations != 6) {
			fails++;
			goto cleanup;
		}
	}
	fails += !!expect_workspace_readdir(out,
					    "fuse_upper_epoch_readdir_before_write",
					    logical_root, false);
	fails += !!expect_read_file(out, "fuse_upper_epoch_main", logical_main,
				    "upper-main\n");
	fails += !!expect_mode(out, "fuse_upper_epoch_main_mode",
			       logical_main, 0600);
	fails += !!expect_unprivileged_access_denied(
		out, "fuse_upper_epoch_denied_access", logical_denied);
	fails += !!expect_mode(out, "fuse_upper_epoch_denied_mode",
			       logical_denied, 0100);
	fails += !!expect_read_file(out, "fuse_upper_epoch_src_app",
				    logical_src_app, "agent-edited-app\n");
	fails += !!expect_read_file(out, "fuse_upper_epoch_git_head",
				    logical_git_head,
				    "ref: refs/heads/agent\n");
	fails += !!expect_stat_errno(out, "fuse_upper_epoch_whiteout",
				     logical_deleted, ENOENT);
	fails += !!expect_symlink_read(out, "fuse_upper_epoch_symlink",
				       logical_link, "main.txt");
	fails += !!expect_stat_errno(out,
				     "fuse_upper_generated_negative_before_write",
				     logical_generated, ENOENT);

	{
		unsigned long long macro_start = nsec_now();
		unsigned long long macro_elapsed;

	err = write_file(logical_generated, "generated-in-upper\n");
	if (err) {
		emit_case(out, "fuse_upper_epoch_write", false, -err,
			  "logical write failed");
		fails++;
	} else {
		emit_case(out, "fuse_upper_epoch_write", true, 0,
			  "logical write completed through FUSE policy FS");
		fails += !!expect_read_file(out, "fuse_upper_generated_visible",
					    upper_generated,
					    "generated-in-upper\n");
		fails += !!expect_workspace_readdir(
			out, "fuse_upper_epoch_readdir_after_write",
			logical_root, true);
		fails += !!expect_stat_errno(out, "fuse_base_not_materialized",
					     base_generated, ENOENT);
	}
	fails += !!expect_stat_errno(out,
				     "fuse_agentfs_cached_negative_before_create",
				     logical_cached_negative, ENOENT);
	err = write_file(logical_cached_negative, "cached-negative-created\n");
	if (err) {
		emit_case(out, "fuse_agentfs_cached_negative_create", false,
			  -err,
			  "cached-negative create through FUSE path failed");
		fails++;
	} else {
			emit_case(out, "fuse_agentfs_cached_negative_create", true, 0,
				  "cached-negative create became visible");
			fails += !!expect_stat_errno(
				out, "fuse_agentfs_cached_negative_logical_stat",
				logical_cached_negative, 0);
			fails += !!expect_read_file(
				out, "fuse_agentfs_cached_negative_visible",
				logical_cached_negative,
				"cached-negative-created\n");
	}
	if (rename(logical_generated, logical_renamed)) {
		emit_case(out, "fuse_agentfs_rename_generated_to_renamed",
			  false, errno, "logical rename failed");
		fails++;
	} else {
		emit_case(out, "fuse_agentfs_rename_generated_to_renamed",
			  true, 0, "logical rename completed through FUSE");
		fails += !!expect_stat_errno(
			out, "fuse_agentfs_rename_generated_old_absent",
			logical_generated, ENOENT);
			fails += !!expect_read_file(
				out, "fuse_agentfs_rename_generated_new_visible",
				logical_renamed, "generated-in-upper\n");
		if (rename(logical_renamed, logical_generated)) {
			emit_case(out, "fuse_agentfs_rename_restored_generated",
				  false, errno, "logical rename restore failed");
			fails++;
		} else {
			emit_case(out, "fuse_agentfs_rename_restored_generated",
				  true, 0, "logical rename restore completed");
		}
	}
	if (unlink(logical_cached_negative)) {
		emit_case(out, "fuse_agentfs_unlink_cached_created", false,
			  errno, "logical unlink failed");
		fails++;
	} else {
		emit_case(out, "fuse_agentfs_unlink_cached_created", true, 0,
			  "logical unlink removed created file");
		fails += !!expect_stat_errno(out,
					     "fuse_agentfs_unlink_cached_absent",
					     logical_cached_negative, ENOENT);
	}
		macro_elapsed = nsec_now() - macro_start;
		emit_metric(out, "fuse_macro_lifecycle_ns", macro_elapsed,
			    fails == 0, "ns",
			    "source lifecycle create/rename/unlink macro measured");
	}
	fails += !!expect_final_manifest(out, logical_main, logical_deleted,
					 logical_generated, base_generated);
	fails += !!expect_read_file(out, "fuse_base_main_preserved", base_main,
				    "base-main\n");
	fails += !!expect_read_file(out, "fuse_base_deleted_preserved",
				    base_deleted, "base-deleted\n");
	fails += !!expect_stat_errno(out, "fuse_base_cached_negative_unmodified",
				     base_cached_negative, ENOENT);
	if (rq2_mode) {
		err = wait_fuse_quiescent(state);
		emit_case(out, "fuse_resource_pre_drain", !err,
			  err ? -err : 0,
			  "prior successful file handles reached matching release callbacks and the callback count stayed stable");
		if (!err)
			err = read_fuse_resource(fuse_pid, state,
						 &resource_before);
		emit_case(out, "fuse_resource_window_start", !err,
			  err ? -err : 0,
			  "FUSE daemon resource window started");
		if (err)
			fails++;
		else
			resource_window_started = true;
	}
	if (rq2_mode)
		fails += !!measure_workspace_lifecycle(
			out, "fuse_lifecycle_ns",
			logical_lifecycle_created, logical_lifecycle_renamed,
			AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES);
	fails += !!measure_stat_latency(out, "fuse_stat_main_ns",
					logical_main, 0, rq2_mode ?
					AGENT_WORKSPACE_RQ2_STAT_SAMPLES : 100);
	fails += !!measure_open_latency(out, "fuse_open_main_ns",
					logical_main, rq2_mode ?
					AGENT_WORKSPACE_RQ2_OPEN_SAMPLES : 100);
	fails += !!measure_access_latency(out, "fuse_access_main_ns",
					  logical_main, R_OK, rq2_mode ?
					  AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES :
					  100);
	fails += !!measure_exec_latency(out, "fuse_exec_tool_ns",
					logical_tool, rq2_mode ?
					AGENT_WORKSPACE_RQ2_EXEC_SAMPLES : 20);
	fails += !!measure_readdir_latency(out, "fuse_readdir_ws_ns",
					   logical_root, rq2_mode ?
					   AGENT_WORKSPACE_RQ2_READDIR_SAMPLES :
					   50);
	if (rq2_mode) {
		err = wait_fuse_quiescent(state);
		emit_case(out, "fuse_resource_post_drain", !err,
			  err ? -err : 0,
			  "timed successful file handles reached matching release callbacks and the callback count stayed stable");
		if (!err)
			err = read_fuse_resource(fuse_pid, state,
						 &resource_after);
		emit_case(out, "fuse_resource_window_end",
			  resource_window_started && !err, err ? -err : 0,
			  "FUSE daemon resource window ended");
		if (!resource_window_started || err) {
			fails++;
		} else {
			bool resource_pass = fuse_resource_monotonic(
				&resource_before, &resource_after);

			emit_fuse_resource(out, &resource_before, &resource_after,
					   resource_pass);
			if (!resource_pass)
				fails++;
		}
	}

	err = stop_fuse(mountpoint, fuse_pid, control_request_fd,
			control_response_fd);
	fuse_pid = -1;
	close(control_request_fd);
	close(control_response_fd);
	control_request_fd = -1;
	control_response_fd = -1;
	if (err) {
		emit_case(out, "fuse_unmount", false, -err,
			  "FUSE unmount failed");
		fails++;
	} else {
		emit_case(out, "fuse_unmount", true, 0, "FUSE unmounted");
	}

	if (state != MAP_FAILED) {
		fails += !!expect_fuse_counter(out, state, "getattr",
					       FUSE_COUNTER_GETATTR, true);
		fails += !!expect_fuse_counter(out, state, "readdir",
					       FUSE_COUNTER_READDIR, true);
		fails += !!expect_fuse_counter(out, state, "open",
					       FUSE_COUNTER_OPEN, true);
		fails += !!expect_fuse_counter(out, state, "create",
					       FUSE_COUNTER_CREATE, rq2_mode);
		fails += !!expect_fuse_counter(out, state, "read",
					       FUSE_COUNTER_READ, true);
		fails += !!expect_fuse_counter(out, state, "write",
					       FUSE_COUNTER_WRITE, true);
		fails += !!expect_fuse_counter(out, state, "readlink",
					       FUSE_COUNTER_READLINK, true);
		fails += !!expect_fuse_counter(out, state, "unlink",
					       FUSE_COUNTER_UNLINK, true);
		fails += !!expect_fuse_counter(out, state, "rename",
					       FUSE_COUNTER_RENAME, true);
		fails += !!expect_fuse_counter(out, state, "mknod",
					       FUSE_COUNTER_MKNOD, false);
		fails += !!expect_fuse_counter(out, state, "truncate",
					       FUSE_COUNTER_TRUNCATE, false);
		fails += !!expect_fuse_counter(out, state, "release",
					       FUSE_COUNTER_RELEASE, true);
		fails += !!expect_fuse_counter(out, state, "request_total",
					       FUSE_COUNTER_REQUEST_TOTAL, true);
		fails += !!expect_fuse_counter(out, state, "handle_opened",
					       FUSE_COUNTER_HANDLE_OPENED, true);
		fails += !!expect_fuse_counter(out, state, "release_completed",
					       FUSE_COUNTER_RELEASE_COMPLETED, true);
		fails += !!expect_fuse_counter(out, state, "hidden_lookup",
					       FUSE_COUNTER_HIDDEN_LOOKUP, true);
		fails += !!expect_fuse_counter(out, state, "hidden_readdir",
					       FUSE_COUNTER_HIDDEN_READDIR, true);
		fails += !!expect_fuse_counter(out, state, "invalidate_attempt",
					       FUSE_COUNTER_INVALIDATE_ATTEMPT, true);
		fails += !!expect_fuse_counter(out, state, "invalidate_error",
					       FUSE_COUNTER_INVALIDATE_ERROR, false);
		if (state->counters[FUSE_COUNTER_INVALIDATE_ATTEMPT] != 6 ||
		    state->counters[FUSE_COUNTER_INVALIDATE_ERROR] != 0)
			fails++;
	}

cleanup:
	if (fuse_pid > 0)
		stop_fuse(mountpoint, fuse_pid, control_request_fd,
			  control_response_fd);
	if (control_request_fd >= 0)
		close(control_request_fd);
	if (control_response_fd >= 0)
		close(control_response_fd);
	if (request_pipe[0] >= 0)
		close(request_pipe[0]);
	if (request_pipe[1] >= 0 &&
	    request_pipe[1] != control_request_fd)
		close(request_pipe[1]);
	if (response_pipe[0] >= 0 &&
	    response_pipe[0] != control_response_fd)
		close(response_pipe[0]);
	if (response_pipe[1] >= 0)
		close(response_pipe[1]);
	unlink(base_main);
	unlink(base_deleted);
	unlink(base_link);
	unlink(base_generated);
	unlink(base_renamed);
	unlink(base_cached_negative);
	unlink(base_denied);
	unlink(base_tool);
	unlink(base_src_app);
	unlink(base_git_head);
	unlink(upper_main);
	unlink(upper_deleted);
	unlink(upper_link);
	unlink(upper_generated);
	unlink(upper_renamed);
	unlink(upper_cached_negative);
	unlink(upper_denied);
	unlink(upper_tool);
	unlink(upper_src_app);
	unlink(upper_git_head);
	rmdir(base_src);
	rmdir(base_git);
	rmdir(upper_src);
	rmdir(upper_git);
	rmdir(mountpoint);
	rmdir(base);
	rmdir(upper);
	rmdir(root);
	if (state != MAP_FAILED)
		munmap(state, sizeof(*state));
	emit_case(out,
		  rq2_mode ? "fuse_agent_workspace_rq2_summary" :
		  matrix_mode ? "fuse_agent_workspace_matrix_summary" :
				"fuse_agent_workspace_preflight_summary",
		  fails == 0, fails,
		  fails ? (rq2_mode ? "FUSE agent workspace RQ2 failures" :
			   matrix_mode ?
				   "FUSE agent workspace matrix failures" :
				   "FUSE agent workspace preflight failures") :
			  (rq2_mode ? "FUSE agent workspace RQ2 passed" :
			   matrix_mode ? "FUSE agent workspace matrix passed" :
					 "FUSE agent workspace preflight passed"));
	fclose(out);
	return fails ? 1 : 0;
}
