// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "namei_ext_harness.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/openat2.h>
#include <limits.h>
#include <pthread.h>
#include <sched.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define TARGET_POOL_SIZE 16
#define EVENT_BUFFER_SIZE 2048
#define TRACE_BUFFER_SIZE (16 * 1024 * 1024)
#define TARGET_ID 1

struct shared_run_state {
	atomic_uint_fast64_t event_seq;
	atomic_uint_fast64_t op_seq;
	atomic_uint failures;
};

struct run_log {
	int fd;
	pthread_mutex_t lock;
	struct shared_run_state *shared;
	char output_dir[PATH_MAX];
};

struct target_object {
	char state[48];
	char path[PATH_MAX];
	char payload[96];
	dev_t dev;
	ino_t ino;
	mode_t mode;
	uid_t uid;
	gid_t gid;
	off_t size;
	bool directory;
	dev_t child_dev;
	ino_t child_ino;
	mode_t child_mode;
	uid_t child_uid;
	gid_t child_gid;
	off_t child_size;
};

enum open_kind {
	OPEN_FINAL_FILE,
	OPEN_DIRECTORY,
	OPEN_DIRECTORY_CHILD,
};

struct publication_cell {
	struct run_log *log;
	const char *name;
	const char *logical_path;
	const char *logical_child;
	struct target_object *targets;
	size_t target_count;
	unsigned int duration_seconds;
	unsigned int reader_count;
	unsigned int min_updates;
	unsigned int min_opens;
	int control_fd;
	int trace_marker_fd;
	pthread_mutex_t trace_lock;
	atomic_bool start;
	atomic_bool abort;
	bool trace_markers_enabled;
	atomic_uint_fast64_t deadline_ns;
	atomic_uint_fast64_t updates;
	atomic_uint failures;
};

struct rcu_trace_event {
	char enable_path[PATH_MAX];
	char event_dir[PATH_MAX];
	char filter_path[PATH_MAX];
	bool created;
	bool enabled;
};

struct rcu_trace_session {
	char buffer_size_path[PATH_MAX];
	char kprobe_events[PATH_MAX];
	char trace_clock_path[PATH_MAX];
	char trace_marker_path[PATH_MAX];
	char trace_path[PATH_MAX];
	char tracing_on_path[PATH_MAX];
	struct rcu_trace_event update_enter;
	struct rcu_trace_event update_return;
	struct rcu_trace_event resolve_return;
	bool tracing_enabled;
};

struct reader_arg {
	struct publication_cell *cell;
	unsigned int reader_id;
	uint64_t opens;
	uint64_t successful_opens;
	uint64_t absent_opens;
};

struct writer_arg {
	struct publication_cell *cell;
	uint64_t writer_seq;
};

typedef int (*cell_fn)(struct run_log *log, const char *cell_name,
		       const char *cgroup_path, const char *managed_dir,
		       const char *physical_dir, const char *logical_path,
		       const char *logical_child, struct target_object *targets,
		       size_t target_count, unsigned int duration_seconds,
		       unsigned int reader_count, unsigned int min_updates,
			       unsigned int min_opens, unsigned int lifecycle_cycles);

static int read_fd_matches(int fd, const char *expected);

static uint64_t monotonic_raw_ns(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC_RAW, &now))
		return 0;
	return (uint64_t)now.tv_sec * 1000000000ULL + now.tv_nsec;
}

static int write_all(int fd, const char *buffer, size_t length)
{
	size_t offset = 0;

	while (offset < length) {
		ssize_t written = write(fd, buffer + offset, length - offset);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!written)
			return -EIO;
		offset += (size_t)written;
	}
	return 0;
}

static int emit_line(struct run_log *log, const char *format, ...)
{
	char buffer[EVENT_BUFFER_SIZE];
	va_list args;
	int length;
	int ret;

	va_start(args, format);
	length = vsnprintf(buffer, sizeof(buffer), format, args);
	va_end(args);
	if (length < 0 || (size_t)length >= sizeof(buffer))
		return -EOVERFLOW;
	pthread_mutex_lock(&log->lock);
	ret = write_all(log->fd, buffer, (size_t)length);
	pthread_mutex_unlock(&log->lock);
	return ret;
}

static int emit_history(struct run_log *log, const char *cell,
			const char *phase, const char *operation,
			const char *subtype, const char *actor,
			uint64_t actor_id, uint64_t op_id,
			uint64_t writer_seq, const char *state, dev_t dev,
			ino_t ino, int result)
{
	char buffer[EVENT_BUFFER_SIZE];
	uint64_t event_seq;
	int length;
	int ret;

	pthread_mutex_lock(&log->lock);
	event_seq = atomic_fetch_add_explicit(&log->shared->event_seq, 1,
					      memory_order_relaxed) +
		    1;
	length = snprintf(
		buffer, sizeof(buffer),
		"{\"event\":\"target-lifetime-history\","
		"\"cell\":\"%s\",\"phase\":\"%s\","
		"\"operation\":\"%s\",\"subtype\":\"%s\","
		"\"actor\":\"%s\",\"actor_id\":%" PRIu64 ","
		"\"op_id\":%" PRIu64 ",\"writer_seq\":%" PRIu64 ","
		"\"event_seq\":%" PRIu64 ",\"time_ns\":%" PRIu64 ","
		"\"state\":\"%s\",\"device\":%" PRIu64 ","
		"\"inode\":%" PRIu64 ",\"result\":%d}\n",
		cell, phase, operation, subtype ? subtype : "",
		actor ? actor : "", actor_id, op_id,
		writer_seq, event_seq, monotonic_raw_ns(), state ? state : "",
		(uint64_t)dev, (uint64_t)ino, result);
	if (length < 0 || (size_t)length >= sizeof(buffer)) {
		pthread_mutex_unlock(&log->lock);
		return -EOVERFLOW;
	}
	ret = write_all(log->fd, buffer, (size_t)length);
	pthread_mutex_unlock(&log->lock);
	return ret;
}

static int emit_open_return(struct run_log *log, const char *cell,
			    const char *actor, uint64_t actor_id,
			    uint64_t op_id, int result)
{
	char buffer[EVENT_BUFFER_SIZE];
	uint64_t event_seq;
	int length;
	int ret;

	pthread_mutex_lock(&log->lock);
	event_seq = atomic_fetch_add_explicit(&log->shared->event_seq, 1,
					      memory_order_relaxed) + 1;
	length = snprintf(
		buffer, sizeof(buffer),
		"{\"event\":\"target-lifetime-open-return\","
		"\"cell\":\"%s\",\"actor\":\"%s\","
		"\"actor_id\":%" PRIu64 ",\"op_id\":%" PRIu64 ","
		"\"event_seq\":%" PRIu64 ",\"time_ns\":%" PRIu64 ","
		"\"result\":%d}\n",
		cell, actor ? actor : "", actor_id, op_id, event_seq,
		monotonic_raw_ns(), result);
	if (length < 0 || (size_t)length >= sizeof(buffer)) {
		pthread_mutex_unlock(&log->lock);
		return -EOVERFLOW;
	}
	ret = write_all(log->fd, buffer, (size_t)length);
	pthread_mutex_unlock(&log->lock);
	return ret;
}

static void record_failure(struct run_log *log)
{
	atomic_fetch_add_explicit(&log->shared->failures, 1,
				  memory_order_relaxed);
}

static int make_dir(const char *path, mode_t mode)
{
	if (!mkdir(path, mode))
		return 0;
	return errno == EEXIST ? 0 : -errno;
}

static int copy_text(char *destination, size_t size, const char *source)
{
	size_t length = strlen(source);

	if (length >= size)
		return -ENAMETOOLONG;
	memcpy(destination, source, length + 1);
	return 0;
}

static int stat_target(struct target_object *target)
{
	struct stat st;

	if (stat(target->path, &st))
		return -errno;
	target->dev = st.st_dev;
	target->ino = st.st_ino;
	target->mode = st.st_mode;
	target->uid = st.st_uid;
	target->gid = st.st_gid;
	target->size = st.st_size;
	if (target->directory) {
		char child[PATH_MAX];

		if (namei_ext_path_join(child, sizeof(child), target->path,
					"child.txt"))
			return -ENAMETOOLONG;
		if (stat(child, &st))
			return -errno;
		target->child_dev = st.st_dev;
		target->child_ino = st.st_ino;
		target->child_mode = st.st_mode;
		target->child_uid = st.st_uid;
		target->child_gid = st.st_gid;
		target->child_size = st.st_size;
	}
	return 0;
}

static int emit_target_definition(struct run_log *log, const char *cell,
				  const struct target_object *target)
{
	return emit_line(
		log,
		"{\"event\":\"target-lifetime-target\","
		"\"cell\":\"%s\",\"state\":\"%s\","
		"\"directory\":%s,\"device\":%" PRIu64 ","
		"\"inode\":%" PRIu64 ",\"mode\":%u,\"uid\":%u,"
		"\"gid\":%u,\"size\":%" PRId64 ","
		"\"child_device\":%" PRIu64 ","
		"\"child_inode\":%" PRIu64 ",\"child_mode\":%u,"
		"\"child_uid\":%u,\"child_gid\":%u,"
		"\"child_size\":%" PRId64 ","
		"\"payload_class\":\"%s\"}\n",
		cell, target->state, target->directory ? "true" : "false",
		(uint64_t)target->dev, (uint64_t)target->ino,
		(unsigned int)target->mode, (unsigned int)target->uid,
		(unsigned int)target->gid, (int64_t)target->size,
		(uint64_t)target->child_dev, (uint64_t)target->child_ino,
		(unsigned int)target->child_mode, (unsigned int)target->child_uid,
		(unsigned int)target->child_gid, (int64_t)target->child_size,
		target->state);
}

static int emit_lower_check(struct run_log *log, const char *cell,
			    const struct target_object *target, const char *object,
			    const struct stat *observed, bool bytes_match, int result)
{
	dev_t expected_dev = !strcmp(object, "child") ? target->child_dev : target->dev;
	ino_t expected_ino = !strcmp(object, "child") ? target->child_ino : target->ino;
	mode_t expected_mode = !strcmp(object, "child") ? target->child_mode : target->mode;
	uid_t expected_uid = !strcmp(object, "child") ? target->child_uid : target->uid;
	gid_t expected_gid = !strcmp(object, "child") ? target->child_gid : target->gid;
	off_t expected_size = !strcmp(object, "child") ? target->child_size : target->size;

	return emit_line(
		log,
		"{\"event\":\"target-lifetime-lower-object\","
		"\"cell\":\"%s\",\"state\":\"%s\",\"object\":\"%s\","
		"\"expected_device\":%" PRIu64 ",\"observed_device\":%" PRIu64 ","
		"\"expected_inode\":%" PRIu64 ",\"observed_inode\":%" PRIu64 ","
		"\"expected_mode\":%u,\"observed_mode\":%u,"
		"\"expected_uid\":%u,\"observed_uid\":%u,"
		"\"expected_gid\":%u,\"observed_gid\":%u,"
		"\"expected_size\":%" PRId64 ",\"observed_size\":%" PRId64 ","
		"\"bytes_match\":%s,\"result\":%d,\"pass\":%s}\n",
		cell, target->state, object, (uint64_t)expected_dev,
		(uint64_t)(observed ? observed->st_dev : 0),
		(uint64_t)expected_ino,
		(uint64_t)(observed ? observed->st_ino : 0),
		(unsigned int)expected_mode,
		(unsigned int)(observed ? observed->st_mode : 0),
		(unsigned int)expected_uid,
		(unsigned int)(observed ? observed->st_uid : 0),
		(unsigned int)expected_gid,
		(unsigned int)(observed ? observed->st_gid : 0),
		(int64_t)expected_size, (int64_t)(observed ? observed->st_size : 0),
		bytes_match ? "true" : "false", result,
		result ? "false" : "true");
}

static int verify_lower_object(struct run_log *log, const char *cell,
			       const struct target_object *target, const char *path,
			       const char *object)
{
	bool child = !strcmp(object, "child");
	dev_t expected_dev = child ? target->child_dev : target->dev;
	ino_t expected_ino = child ? target->child_ino : target->ino;
	mode_t expected_mode = child ? target->child_mode : target->mode;
	uid_t expected_uid = child ? target->child_uid : target->uid;
	gid_t expected_gid = child ? target->child_gid : target->gid;
	off_t expected_size = child ? target->child_size : target->size;
	struct stat observed = {};
	bool bytes_match = false;
	int fd = -1;
	int ret = 0;

	if (stat(path, &observed)) {
		ret = -errno;
	} else if (observed.st_dev != expected_dev ||
		   observed.st_ino != expected_ino ||
		   observed.st_mode != expected_mode ||
		   observed.st_uid != expected_uid ||
		   observed.st_gid != expected_gid ||
		   observed.st_size != expected_size) {
		ret = -ESTALE;
	}
	if (!ret && (!target->directory || child)) {
		fd = open(path, O_RDONLY | O_CLOEXEC);
		if (fd < 0)
			ret = -errno;
		else {
			ret = read_fd_matches(fd, target->payload);
			bytes_match = !ret;
		}
	} else if (!ret) {
		bytes_match = true;
	}
	if (fd >= 0 && close(fd) && !ret)
		ret = -errno;
	if (emit_lower_check(log, cell, target, object, &observed, bytes_match,
			     ret))
		return -EIO;
	return ret;
}

static int verify_publication_targets(struct run_log *log, const char *cell,
				      struct target_object *targets,
				      size_t target_count)
{
	unsigned int failures = 0;
	size_t i;

	for (i = 0; i < target_count; i++) {
		char child[PATH_MAX];

		if (verify_lower_object(log, cell, &targets[i], targets[i].path,
					"target"))
			failures++;
		if (!targets[i].directory)
			continue;
		if (namei_ext_path_join(child, sizeof(child), targets[i].path,
					"child.txt") ||
		    verify_lower_object(log, cell, &targets[i], child, "child"))
			failures++;
	}
	return failures ? -EIO : 0;
}

static const struct target_object *
classify_fd(const struct target_object *targets, size_t target_count,
	    enum open_kind kind, const struct stat *st)
{
	size_t i;

	for (i = 0; i < target_count; i++) {
		dev_t dev = kind == OPEN_DIRECTORY_CHILD ?
				    targets[i].child_dev :
				    targets[i].dev;
		ino_t ino = kind == OPEN_DIRECTORY_CHILD ?
				    targets[i].child_ino :
				    targets[i].ino;

		if (st->st_dev == dev && st->st_ino == ino)
			return &targets[i];
	}
	return NULL;
}

static int read_fd_matches(int fd, const char *expected)
{
	char buffer[256] = {};
	size_t length = strlen(expected);
	ssize_t count;

	if (length >= sizeof(buffer))
		return -EOVERFLOW;
	if (lseek(fd, 0, SEEK_SET) < 0)
		return -errno;
	count = read(fd, buffer, sizeof(buffer) - 1);
	if (count < 0)
		return -errno;
	return count == (ssize_t)length && !memcmp(buffer, expected, length) ?
		       0 :
		       -EIO;
}

static int directory_fd_matches(int fd, const struct target_object *target)
{
	char payload[96];
	bool found_child = false;
	DIR *directory;
	struct dirent *entry;
	int child_fd;
	int scan_fd;
	int ret = 0;

	scan_fd = openat(fd, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (scan_fd < 0)
		return -errno;
	directory = fdopendir(scan_fd);
	if (!directory) {
		close(scan_fd);
		return -errno;
	}
	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, "child.txt"))
			found_child = true;
	}
	if (errno)
		ret = -errno;
	if (closedir(directory) && !ret)
		ret = -errno;
	if (ret)
		return ret;
	if (!found_child)
		return -ENOENT;
	child_fd = openat(fd, "child.txt", O_RDONLY | O_CLOEXEC);
	if (child_fd < 0)
		return -errno;
	if (snprintf(payload, sizeof(payload), "%s\n", target->state) < 0) {
		close(child_fd);
		return -EINVAL;
	}
	ret = read_fd_matches(child_fd, payload);
	if (close(child_fd) && !ret)
		ret = -errno;
	return ret;
}

static int emit_descriptor_check(struct run_log *log, const char *cell,
				 const char *subtype, uint64_t op_id,
				 const char *state, int result)
{
	return emit_line(
		log,
		"{\"event\":\"target-lifetime-descriptor\","
		"\"cell\":\"%s\",\"subtype\":\"%s\","
		"\"op_id\":%" PRIu64 ",\"state\":\"%s\","
		"\"result\":%d,\"pass\":%s}\n",
		cell, subtype, op_id, state, result,
		result ? "false" : "true");
}

static int emit_update_marker(int trace_marker_fd, const char *phase,
			      uint64_t writer_seq)
{
	char marker[96];
	int length;

	if (trace_marker_fd < 0)
		return 0;
	length = snprintf(marker, sizeof(marker),
			  "namei_ext-update-%s-%" PRIu64 "\n", phase,
			  writer_seq);
	if (length < 0 || (size_t)length >= sizeof(marker))
		return -EINVAL;
	return write_all(trace_marker_fd, marker, (size_t)length);
}

static int direct_control_write(int control_fd, const char *command,
				size_t length, int trace_marker_fd,
				uint64_t writer_seq)
{
	ssize_t written;
	int write_errno;
	int marker_ret;

	marker_ret = emit_update_marker(trace_marker_fd, "begin", writer_seq);
	if (marker_ret)
		return marker_ret;
	written = write(control_fd, command, length);
	write_errno = written < 0 ? errno : 0;
	marker_ret = emit_update_marker(trace_marker_fd, "end", writer_seq);
	if (marker_ret)
		return marker_ret;
	if (written < 0)
		return -write_errno;
	return written == (ssize_t)length ? 0 : -EIO;
}

static int direct_register_write_traced(int control_fd,
					const struct target_object *target,
					int trace_marker_fd,
					uint64_t writer_seq)
{
	char command[64];
	int target_fd;
	int length;
	int ret;

	target_fd = open(target->path, O_PATH | O_CLOEXEC);
	if (target_fd < 0)
		return -errno;
	length = snprintf(command, sizeof(command), "%u %d\n", TARGET_ID,
			  target_fd);
	if (length < 0 || (size_t)length >= sizeof(command)) {
		close(target_fd);
		return -EINVAL;
	}
	ret = direct_control_write(control_fd, command, (size_t)length,
				   trace_marker_fd, writer_seq);
	if (close(target_fd) && !ret)
		ret = -errno;
	return ret;
}

static int direct_register_write(int control_fd,
				 const struct target_object *target)
{
	return direct_register_write_traced(control_fd, target, -1, 0);
}

static int direct_clear_write_traced(int control_fd, int trace_marker_fd,
				     uint64_t writer_seq)
{
	static const char command[] = "clear\n";

	return direct_control_write(control_fd, command, sizeof(command) - 1,
				    trace_marker_fd, writer_seq);
}

static int direct_clear_write(int control_fd)
{
	return direct_clear_write_traced(control_fd, -1, 0);
}

static int write_control_file(const char *path, const char *text)
{
	size_t length = strlen(text);
	int fd;
	int ret;

	fd = open(path, O_WRONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	ret = write_all(fd, text, length);
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int read_trace_file(const char *path, char **output)
{
	char *buffer;
	size_t offset = 0;
	int fd;
	int ret = 0;

	buffer = calloc(1, TRACE_BUFFER_SIZE);
	if (!buffer)
		return -ENOMEM;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0) {
		ret = -errno;
		goto out;
	}
	while (offset < TRACE_BUFFER_SIZE - 1) {
		ssize_t count = read(fd, buffer + offset,
				     TRACE_BUFFER_SIZE - 1 - offset);

		if (count < 0) {
			if (errno == EINTR)
				continue;
			ret = -errno;
			break;
		}
		if (!count)
			break;
		offset += (size_t)count;
	}
	if (!ret && offset == TRACE_BUFFER_SIZE - 1)
		ret = -EOVERFLOW;
	if (close(fd) && !ret)
		ret = -errno;
out:
	if (ret) {
		free(buffer);
		return ret;
	}
	*output = buffer;
	return 0;
}

static int preserve_raw_trace(const struct run_log *log, const char *cell,
			      const char *phase, const char *trace)
{
	char name[96];
	char path[PATH_MAX];
	int length;
	int fd;
	int ret;

	length = snprintf(name, sizeof(name), "%s-%s-rcu-trace.txt", cell,
			  phase);
	if (length < 0 || (size_t)length >= sizeof(name) ||
	    namei_ext_path_join(path, sizeof(path), log->output_dir, name))
		return -ENAMETOOLONG;
	fd = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	ret = write_all(fd, trace, strlen(trace));
	if (close(fd) && !ret)
		ret = -errno;
	return ret;
}

static int verify_rcu_target_path(struct run_log *log, const char *cell,
				  int control_fd, const char *logical_path,
				  const struct target_object *target,
				  bool directory)
{
	static const char probe_definition[] =
		"r:namei_ext_lifetime/resolve_target_return "
		"namei_ext_resolve_target rcu_walk=$arg2:u8 result=$retval:s32\n";
	static const char probe_removal[] =
		"-:namei_ext_lifetime/resolve_target_return\n";
	const char *trace_root = "/sys/kernel/debug/tracing";
	char event_dir[PATH_MAX];
	char enable_path[PATH_MAX];
	char filter_path[PATH_MAX];
	char kprobe_events[PATH_MAX];
	char trace_path[PATH_MAX];
	char tracing_on[PATH_MAX];
	char filter[64];
	char *trace = NULL;
	char *line;
	char *saveptr = NULL;
	struct open_how how = {
		.flags = directory ? O_RDONLY | O_DIRECTORY | O_CLOEXEC :
					O_RDONLY | O_CLOEXEC,
		.resolve = RESOLVE_CACHED,
	};
	struct stat st = {};
	unsigned int rcu_hits = 0;
	unsigned int ref_hits = 0;
	unsigned int resolve_failures = 0;
	bool event_created = false;
	bool event_enabled = false;
	bool tracing_enabled = false;
	int clear_ret;
	int fd = -1;
	int ret = 0;
	int trace_ret = 0;

	if (access("/sys/kernel/tracing/kprobe_events", F_OK) == 0)
		trace_root = "/sys/kernel/tracing";
	if (namei_ext_path_join(kprobe_events, sizeof(kprobe_events), trace_root,
				"kprobe_events") ||
	    namei_ext_path_join(trace_path, sizeof(trace_path), trace_root,
				"trace") ||
	    namei_ext_path_join(tracing_on, sizeof(tracing_on), trace_root,
				"tracing_on") ||
	    namei_ext_path_join(event_dir, sizeof(event_dir), trace_root,
				"events/namei_ext_lifetime/resolve_target_return") ||
	    namei_ext_path_join(enable_path, sizeof(enable_path), event_dir,
				"enable") ||
	    namei_ext_path_join(filter_path, sizeof(filter_path), event_dir,
				"filter"))
		return -ENAMETOOLONG;
	if (!access(event_dir, F_OK))
		return -EEXIST;

	ret = direct_register_write(control_fd, target);
	if (ret)
		goto out_clear_target;
	fd = open(logical_path,
		  directory ? O_RDONLY | O_DIRECTORY | O_CLOEXEC :
			      O_RDONLY | O_CLOEXEC);
	if (fd < 0) {
		ret = -errno;
		goto out_clear_target;
	}
	ret = directory ? directory_fd_matches(fd, target) :
			  read_fd_matches(fd, target->payload);
	if (close(fd) && !ret)
		ret = -errno;
	fd = -1;
	if (ret)
		goto out_clear_target;

	ret = write_control_file(kprobe_events, probe_definition);
	if (ret)
		goto out_clear_target;
	event_created = true;
	if (snprintf(filter, sizeof(filter), "common_pid == %ld\n",
		     (long)getpid()) < 0) {
		ret = -EINVAL;
		goto out_trace;
	}
	if ((ret = write_control_file(filter_path, filter)) ||
	    (ret = write_control_file(trace_path, "\n")) ||
	    (ret = write_control_file(enable_path, "1\n")))
		goto out_trace;
	event_enabled = true;
	ret = write_control_file(tracing_on, "1\n");
	if (ret)
		goto out_trace;
	tracing_enabled = true;

	fd = (int)syscall(SYS_openat2, AT_FDCWD, logical_path, &how,
			  sizeof(how));
	if (fd < 0) {
		ret = -errno;
	} else if (fstat(fd, &st)) {
		ret = -errno;
	} else if (st.st_dev != target->dev || st.st_ino != target->ino) {
		ret = -ESTALE;
	} else if (directory) {
		ret = directory_fd_matches(fd, target);
	} else {
			ret = read_fd_matches(fd, target->payload);
	}
	if (fd >= 0 && close(fd) && !ret)
		ret = -errno;
	fd = -1;

out_trace:
	if (tracing_enabled && write_control_file(tracing_on, "0\n") && !trace_ret)
		trace_ret = -EIO;
	if (event_enabled && write_control_file(enable_path, "0\n") && !trace_ret)
		trace_ret = -EIO;
	if (event_created && read_trace_file(trace_path, &trace) && !trace_ret)
		trace_ret = -EIO;
	if (event_created && write_control_file(kprobe_events, probe_removal) &&
	    !trace_ret)
		trace_ret = -EIO;
	if (trace && preserve_raw_trace(log, cell, "controlled", trace) &&
	    !trace_ret)
		trace_ret = -EIO;
	if (trace) {
		for (line = strtok_r(trace, "\n", &saveptr); line;
		     line = strtok_r(NULL, "\n", &saveptr)) {
			char *fields;
			unsigned int rcu_walk;
			int result;

			if (!strstr(line, "resolve_target_return:"))
				continue;
			fields = strstr(line, "rcu_walk=");
			if (!fields || sscanf(fields, "rcu_walk=%u result=%d",
					      &rcu_walk, &result) != 2 ||
			    rcu_walk > 1) {
				trace_ret = trace_ret ? trace_ret : -EINVAL;
				continue;
			}
			if (result)
				resolve_failures++;
			else if (rcu_walk)
				rcu_hits++;
			else
				ref_hits++;
			if (emit_line(
				    log,
				    "{\"event\":\"target-lifetime-rcu-branch\","
				    "\"cell\":\"%s\",\"source\":\"kretprobe:namei_ext_resolve_target:arg2+retval\","
				    "\"phase\":\"controlled\",\"rcu_walk\":%s,\"result\":%d,"
				    "\"under_update\":false,\"writer_seq\":0}\n",
				    cell, rcu_walk ? "true" : "false", result))
				record_failure(log);
		}
	}
	free(trace);
	if (!ret && trace_ret)
		ret = trace_ret;
	if (!ret && (!rcu_hits || resolve_failures))
		ret = -ENODATA;

out_clear_target:
	clear_ret = direct_clear_write(control_fd);
	if (!ret && clear_ret)
		ret = clear_ret;
	if (emit_line(
		    log,
			    "{\"event\":\"target-lifetime-rcu-proof\","
			    "\"cell\":\"%s\",\"state\":\"%s\","
			    "\"raw_trace\":\"%s-controlled-rcu-trace.txt\","
		    "\"expected_device\":%" PRIu64 ","
		    "\"observed_device\":%" PRIu64 ","
		    "\"expected_inode\":%" PRIu64 ","
		    "\"observed_inode\":%" PRIu64 ","
		    "\"resolve_cached_result\":%d,\"rcu_walk_hits\":%u,"
		    "\"ref_walk_hits\":%u,\"resolve_failures\":%u,"
		    "\"pass\":%s}\n",
			    cell, target->state, cell, (uint64_t)target->dev,
		    (uint64_t)st.st_dev, (uint64_t)target->ino,
		    (uint64_t)st.st_ino, ret, rcu_hits, ref_hits, resolve_failures,
		    ret ? "false" : "true"))
		record_failure(log);
	return ret;
}

static int init_rcu_trace_event(struct rcu_trace_event *event,
				const char *trace_root, const char *event_name)
{
	char relative[PATH_MAX];
	int length;

	length = snprintf(relative, sizeof(relative),
			  "events/namei_ext_lifetime_stress/%s", event_name);
	if (length < 0 || (size_t)length >= sizeof(relative) ||
	    namei_ext_path_join(event->event_dir, sizeof(event->event_dir),
				trace_root, relative) ||
	    namei_ext_path_join(event->enable_path, sizeof(event->enable_path),
				event->event_dir, "enable") ||
	    namei_ext_path_join(event->filter_path, sizeof(event->filter_path),
				event->event_dir, "filter"))
		return -ENAMETOOLONG;
	return access(event->event_dir, F_OK) == 0 ? -EEXIST : 0;
}

static int disable_rcu_trace_event(struct rcu_trace_event *event)
{
	int ret = 0;

	if (event->enabled)
		ret = write_control_file(event->enable_path, "0\n");
	event->enabled = false;
	return ret;
}

static int remove_rcu_trace_event(struct rcu_trace_session *session,
				  struct rcu_trace_event *event,
				  const char *event_name)
{
	char command[128];
	int length;
	int ret = 0;

	if (!event->created)
		return 0;
	length = snprintf(command, sizeof(command),
			  "-:namei_ext_lifetime_stress/%s\n", event_name);
	if (length < 0 || (size_t)length >= sizeof(command))
		ret = -EINVAL;
	else
		ret = write_control_file(session->kprobe_events, command);
	event->created = false;
	return ret;
}

static int start_concurrent_rcu_trace(struct publication_cell *cell,
				      struct rcu_trace_session *session)
{
	static const char update_enter_definition[] =
		"p:namei_ext_lifetime_stress/update_enter "
		"namei_ext_register_target_write\n";
	static const char update_return_definition[] =
		"r:namei_ext_lifetime_stress/update_return "
		"namei_ext_register_target_write result=$retval:s64\n";
	static const char resolve_return_definition[] =
		"r:namei_ext_lifetime_stress/resolve_return "
		"namei_ext_resolve_target rcu_walk=$arg2:u8 result=$retval:s32\n";
	const char *trace_root = "/sys/kernel/debug/tracing";
	char *trace_clock = NULL;
	int ret;

	if (access("/sys/kernel/tracing/kprobe_events", F_OK) == 0)
		trace_root = "/sys/kernel/tracing";
	if (namei_ext_path_join(session->kprobe_events,
				sizeof(session->kprobe_events), trace_root,
				"kprobe_events") ||
	    namei_ext_path_join(session->trace_path, sizeof(session->trace_path),
				trace_root, "trace") ||
	    namei_ext_path_join(session->tracing_on_path,
				sizeof(session->tracing_on_path), trace_root,
				"tracing_on") ||
	    namei_ext_path_join(session->trace_clock_path,
				sizeof(session->trace_clock_path), trace_root,
				"trace_clock") ||
	    namei_ext_path_join(session->trace_marker_path,
				sizeof(session->trace_marker_path), trace_root,
				"trace_marker") ||
	    namei_ext_path_join(session->buffer_size_path,
				sizeof(session->buffer_size_path), trace_root,
				"buffer_size_kb"))
		return -ENAMETOOLONG;
	if ((ret = init_rcu_trace_event(&session->update_enter, trace_root,
					"update_enter")) ||
	    (ret = init_rcu_trace_event(&session->update_return, trace_root,
					"update_return")) ||
	    (ret = init_rcu_trace_event(&session->resolve_return, trace_root,
					"resolve_return")))
		return ret;
	if ((ret = write_control_file(session->tracing_on_path, "0\n")) ||
	    (ret = write_control_file(session->trace_clock_path, "counter\n")) ||
	    (ret = read_trace_file(session->trace_clock_path, &trace_clock)))
		return ret;
	if (!strstr(trace_clock, "[counter]"))
		ret = -EINVAL;
	free(trace_clock);
	if (ret || (ret = write_control_file(session->buffer_size_path, "1024\n")))
		return ret;
	ret = write_control_file(session->kprobe_events, update_enter_definition);
	if (ret)
		return ret;
	session->update_enter.created = true;
	ret = write_control_file(session->kprobe_events, update_return_definition);
	if (ret)
		goto out_remove;
	session->update_return.created = true;
	ret = write_control_file(session->kprobe_events, resolve_return_definition);
	if (ret)
		goto out_remove;
	session->resolve_return.created = true;
	if ((ret = write_control_file(session->resolve_return.filter_path,
				      "rcu_walk == 1\n")) ||
	    (ret = write_control_file(session->trace_path, "\n")))
		goto out_remove;
	cell->trace_marker_fd = open(session->trace_marker_path,
				     O_WRONLY | O_CLOEXEC);
	if (cell->trace_marker_fd < 0) {
		ret = -errno;
		goto out_remove;
	}
	if ((ret = write_control_file(session->update_enter.enable_path, "1\n")))
		goto out_close_marker;
	session->update_enter.enabled = true;
	if ((ret = write_control_file(session->update_return.enable_path, "1\n")))
		goto out_disable;
	session->update_return.enabled = true;
	if ((ret = write_control_file(session->resolve_return.enable_path, "1\n")))
		goto out_disable;
	session->resolve_return.enabled = true;
	ret = write_control_file(session->tracing_on_path, "1\n");
	if (ret)
		goto out_disable;
	session->tracing_enabled = true;
	cell->trace_markers_enabled = true;
	return 0;

out_disable:
	disable_rcu_trace_event(&session->resolve_return);
	disable_rcu_trace_event(&session->update_return);
	disable_rcu_trace_event(&session->update_enter);
out_close_marker:
	close(cell->trace_marker_fd);
	cell->trace_marker_fd = -1;
out_remove:
	remove_rcu_trace_event(session, &session->resolve_return,
			       "resolve_return");
	remove_rcu_trace_event(session, &session->update_return,
			       "update_return");
	remove_rcu_trace_event(session, &session->update_enter,
			       "update_enter");
	return ret;
}

static int parse_concurrent_rcu_trace(struct publication_cell *cell,
				      char *trace, int trace_result)
{
	char *line;
	char *saveptr = NULL;
	uint64_t armed_writer_seq = 0;
	uint64_t active_writer_seq = 0;
	bool update_returned = false;
	unsigned long entries_buffered = 0;
	unsigned long entries_written = 0;
	unsigned int begin_markers = 0;
	unsigned int end_markers = 0;
	unsigned int update_windows = 0;
	unsigned int update_enters = 0;
	unsigned int update_returns = 0;
	unsigned int rcu_successes = 0;
	unsigned int rcu_failures = 0;
	unsigned int rcu_under_update = 0;
	int ret = trace_result;

	for (line = strtok_r(trace, "\n", &saveptr); line;
	     line = strtok_r(NULL, "\n", &saveptr)) {
		char *marker;
		uint64_t writer_seq;

		if (sscanf(line, "# entries-in-buffer/entries-written: %lu/%lu",
			   &entries_buffered, &entries_written) == 2)
			continue;
		marker = strstr(line, "namei_ext-update-begin-");
		if (marker) {
			if (sscanf(marker, "namei_ext-update-begin-%" SCNu64,
				   &writer_seq) != 1 || !writer_seq ||
			    armed_writer_seq || active_writer_seq) {
				ret = -EINVAL;
				continue;
			}
			armed_writer_seq = writer_seq;
			update_returned = false;
			begin_markers++;
			if (emit_line(
				    cell->log,
				    "{\"event\":\"target-lifetime-rcu-marker\","
				    "\"cell\":\"%s\",\"phase\":\"begin\","
				    "\"writer_seq\":%" PRIu64 "}\n",
				    cell->name, writer_seq))
				record_failure(cell->log);
			continue;
		}
		if (strstr(line, "update_enter:")) {
			if (!armed_writer_seq || active_writer_seq ||
			    update_returned) {
				ret = -EINVAL;
				continue;
			}
			active_writer_seq = armed_writer_seq;
			update_enters++;
			if (emit_line(
				    cell->log,
				    "{\"event\":\"target-lifetime-rcu-update\","
				    "\"cell\":\"%s\",\"phase\":\"enter\","
				    "\"writer_seq\":%" PRIu64 "}\n",
				    cell->name, active_writer_seq))
				record_failure(cell->log);
			continue;
		}
		if (strstr(line, "resolve_return:")) {
			char *fields = strstr(line, "rcu_walk=");
			unsigned int rcu_walk;
			int result;

			if (!fields || sscanf(fields, "rcu_walk=%u result=%d",
					      &rcu_walk, &result) != 2 ||
			    rcu_walk != 1) {
				ret = -EINVAL;
				continue;
			}
			if (result)
				rcu_failures++;
			else {
				rcu_successes++;
				if (active_writer_seq)
					rcu_under_update++;
			}
			if (emit_line(
				    cell->log,
				    "{\"event\":\"target-lifetime-rcu-branch\","
				    "\"cell\":\"%s\",\"source\":\"kretprobe:namei_ext_resolve_target:arg2+retval\","
				    "\"phase\":\"concurrent\",\"rcu_walk\":true,"
				    "\"result\":%d,\"under_update\":%s,"
				    "\"writer_seq\":%" PRIu64 "}\n",
				    cell->name, result,
				    active_writer_seq ? "true" : "false",
				    active_writer_seq))
				record_failure(cell->log);
			continue;
		}
		if (strstr(line, "update_return:")) {
			char *fields = strstr(line, "result=");
			long long result;

			if (!fields || sscanf(fields, "result=%lld", &result) != 1 ||
			    !armed_writer_seq ||
			    active_writer_seq != armed_writer_seq ||
			    update_returned) {
				ret = -EINVAL;
				continue;
			}
			update_returns++;
			if (result < 0)
				ret = -EIO;
			if (emit_line(
				    cell->log,
				    "{\"event\":\"target-lifetime-rcu-update\","
				    "\"cell\":\"%s\",\"phase\":\"return\","
				    "\"writer_seq\":%" PRIu64 ",\"result\":%lld}\n",
				    cell->name, active_writer_seq, result))
				record_failure(cell->log);
			active_writer_seq = 0;
			update_returned = true;
			continue;
		}
		marker = strstr(line, "namei_ext-update-end-");
		if (marker) {
			if (sscanf(marker, "namei_ext-update-end-%" SCNu64,
				   &writer_seq) != 1 ||
			    writer_seq != armed_writer_seq || active_writer_seq ||
			    !update_returned) {
				ret = -EINVAL;
				continue;
			}
			end_markers++;
			update_windows++;
			if (emit_line(
				    cell->log,
				    "{\"event\":\"target-lifetime-rcu-marker\","
				    "\"cell\":\"%s\",\"phase\":\"end\","
				    "\"writer_seq\":%" PRIu64 "}\n",
				    cell->name, writer_seq))
				record_failure(cell->log);
			armed_writer_seq = 0;
			update_returned = false;
			continue;
		}
	}
	if (!entries_written || entries_buffered != entries_written ||
	    armed_writer_seq || active_writer_seq ||
	    update_windows != update_enters || update_windows != update_returns ||
	    !update_windows || !rcu_under_update)
		ret = ret ? ret : -ENODATA;
	if (emit_line(
		    cell->log,
		    "{\"event\":\"target-lifetime-rcu-stress\","
		    "\"cell\":\"%s\",\"trace_entries\":%lu,"
		    "\"raw_trace\":\"%s-concurrent-rcu-trace.txt\","
		    "\"trace_clock\":\"counter\","
		    "\"trace_entries_written\":%lu,\"begin_markers\":%u,"
		    "\"end_markers\":%u,\"update_windows\":%u,"
		    "\"kernel_update_enters\":%u,\"kernel_update_returns\":%u,"
		    "\"rcu_walk_hits\":%u,\"rcu_resolve_failures\":%u,"
		    "\"rcu_under_update\":%u,"
		    "\"result\":%d,\"pass\":%s}\n",
		    cell->name, entries_buffered, cell->name, entries_written,
		    begin_markers, end_markers, update_windows, update_enters,
		    update_returns, rcu_successes, rcu_failures, rcu_under_update, ret,
		    ret ? "false" : "true"))
		record_failure(cell->log);
	return ret;
}

static int stop_concurrent_rcu_trace(struct publication_cell *cell,
				     struct rcu_trace_session *session)
{
	char *trace = NULL;
	int ret = 0;
	int cleanup_ret = 0;
	int lock_ret;

	lock_ret = pthread_mutex_lock(&cell->trace_lock);
	if (lock_ret)
		return -lock_ret;
	if (session->tracing_enabled &&
	    write_control_file(session->tracing_on_path, "0\n")) {
		cleanup_ret = -EIO;
		atomic_store_explicit(&cell->abort, true, memory_order_release);
	}
	session->tracing_enabled = false;
	cell->trace_markers_enabled = false;
	if (disable_rcu_trace_event(&session->resolve_return) && !cleanup_ret)
		cleanup_ret = -EIO;
	if (disable_rcu_trace_event(&session->update_return) && !cleanup_ret)
		cleanup_ret = -EIO;
	if (disable_rcu_trace_event(&session->update_enter) && !cleanup_ret)
		cleanup_ret = -EIO;
	if (cell->trace_marker_fd >= 0 && close(cell->trace_marker_fd) &&
	    !cleanup_ret)
		cleanup_ret = -errno;
	cell->trace_marker_fd = -1;
	if (read_trace_file(session->trace_path, &trace))
		ret = -EIO;
	if (remove_rcu_trace_event(session, &session->resolve_return,
				   "resolve_return") && !cleanup_ret)
		cleanup_ret = -EIO;
	if (remove_rcu_trace_event(session, &session->update_return,
				   "update_return") && !cleanup_ret)
		cleanup_ret = -EIO;
	if (remove_rcu_trace_event(session, &session->update_enter,
				   "update_enter") && !cleanup_ret)
		cleanup_ret = -EIO;
	lock_ret = pthread_mutex_unlock(&cell->trace_lock);
	if (lock_ret && !cleanup_ret)
		cleanup_ret = -lock_ret;
	if (!ret && cleanup_ret)
		ret = cleanup_ret;
	if (trace) {
		if (preserve_raw_trace(cell->log, cell->name, "concurrent", trace) &&
		    !ret)
			ret = -EIO;
		ret = parse_concurrent_rcu_trace(cell, trace, ret);
		free(trace);
	} else {
		if (!ret)
			ret = -EIO;
		if (emit_line(
			   cell->log,
			   "{\"event\":\"target-lifetime-rcu-stress\","
			   "\"cell\":\"%s\",\"trace_entries\":0,"
			   "\"raw_trace\":\"%s-concurrent-rcu-trace.txt\","
			   "\"trace_clock\":\"counter\","
			   "\"trace_entries_written\":0,\"begin_markers\":0,"
			   "\"end_markers\":0,\"update_windows\":0,"
			   "\"kernel_update_enters\":0,"
			   "\"kernel_update_returns\":0,\"rcu_walk_hits\":0,"
			   "\"rcu_resolve_failures\":0,\"rcu_under_update\":0,"
			   "\"result\":%d,\"pass\":false}\n",
			   cell->name, cell->name, ret))
			record_failure(cell->log);
	}
	return ret;
}

static int history_update(struct run_log *log, const char *cell,
			  int control_fd, const char *operation,
			  const struct target_object *target,
			  uint64_t writer_seq, int trace_marker_fd)
{
	const char *state = target ? target->state : "absent";
	dev_t dev = target ? target->dev : 0;
	ino_t ino = target ? target->ino : 0;
	uint64_t op_id =
		atomic_fetch_add_explicit(&log->shared->op_seq, 1,
					  memory_order_relaxed) +
		1;
	int ret;

	if (emit_history(log, cell, "invoke", operation, "", "writer", 0, op_id,
			 writer_seq, state, dev, ino, 0))
		record_failure(log);
	ret = target ? direct_register_write_traced(control_fd, target,
						     trace_marker_fd, writer_seq) :
		       direct_clear_write_traced(control_fd, trace_marker_fd,
					 writer_seq);
	if (emit_history(log, cell, "response", operation, "", "writer", 0, op_id,
			 writer_seq, state, dev, ino, ret))
		record_failure(log);
	if (ret)
		record_failure(log);
	return ret;
}

static const char *open_kind_name(enum open_kind kind)
{
	switch (kind) {
	case OPEN_FINAL_FILE:
		return "file";
	case OPEN_DIRECTORY:
		return "directory";
	case OPEN_DIRECTORY_CHILD:
		return "directory-child";
	}
	return "unknown";
}

static int history_open(struct run_log *log, const char *cell,
			const char *path, enum open_kind kind,
			const struct target_object *targets, size_t target_count,
			const char *actor, uint64_t actor_id, int *held_fd)
{
	const struct target_object *target = NULL;
	const char *subtype = open_kind_name(kind);
	const char *state = "error";
	char expected[96];
	struct stat first;
	struct stat second;
	uint64_t op_id =
		atomic_fetch_add_explicit(&log->shared->op_seq, 1,
					  memory_order_relaxed) +
		1;
	int flags = O_CLOEXEC;
	int descriptor_ret = 0;
	int result = 0;
	int fd;

	flags |= kind == OPEN_DIRECTORY ? O_RDONLY | O_DIRECTORY : O_RDONLY;
	if (emit_history(log, cell, "invoke", "OPEN", subtype, actor, actor_id,
			 op_id, 0, "",
			 0, 0, 0))
		record_failure(log);
	fd = openat(AT_FDCWD, path, flags);
	if (fd < 0) {
		result = -errno;
		if (emit_open_return(log, cell, actor, actor_id, op_id, result))
			record_failure(log);
		state = result == -ENOENT ? "absent" : "error";
		if (emit_history(log, cell, "response", "OPEN", subtype, actor,
				 actor_id, op_id,
				 0, state, 0, 0, result))
			record_failure(log);
		if (result != -ENOENT)
			record_failure(log);
		if (held_fd)
			*held_fd = -1;
		return result;
	}
	if (emit_open_return(log, cell, actor, actor_id, op_id, 0))
		record_failure(log);
	if (fstat(fd, &first)) {
		result = -errno;
	} else {
		target = classify_fd(targets, target_count, kind, &first);
		if (!target)
			result = -ESTALE;
		else
			state = target->state;
	}
	if (result) {
		if (emit_history(log, cell, "response", "OPEN", subtype, actor,
				 actor_id, op_id, 0, state, 0, 0, result))
			record_failure(log);
		record_failure(log);
		close(fd);
		if (held_fd)
			*held_fd = -1;
		return result;
	}
	if (emit_history(log, cell, "response", "OPEN", subtype, actor, actor_id,
			 op_id, 0, state, first.st_dev, first.st_ino, 0))
		record_failure(log);

	sched_yield();
	if (kind == OPEN_DIRECTORY) {
		descriptor_ret = directory_fd_matches(fd, target);
	} else {
		if (snprintf(expected, sizeof(expected), "%s\n", target->state) <
		    0)
			descriptor_ret = -EINVAL;
		if (!descriptor_ret)
			descriptor_ret = read_fd_matches(fd, expected);
	}
	if (!descriptor_ret && fstat(fd, &second))
		descriptor_ret = -errno;
	if (!descriptor_ret &&
	    (first.st_dev != second.st_dev || first.st_ino != second.st_ino))
		descriptor_ret = -ESTALE;
	if (emit_descriptor_check(log, cell, subtype, op_id, state,
				  descriptor_ret))
		record_failure(log);
	if (descriptor_ret)
		record_failure(log);
	if (held_fd) {
		*held_fd = fd;
	} else if (close(fd)) {
		record_failure(log);
		return -errno;
	}
	return descriptor_ret;
}

static void *publication_writer(void *opaque)
{
	struct writer_arg *arg = opaque;
	struct publication_cell *cell = arg->cell;
	size_t target_index = 0;
	unsigned int phase = 0;

	while (!atomic_load_explicit(&cell->start, memory_order_acquire))
		sched_yield();
	if (atomic_load_explicit(&cell->abort, memory_order_relaxed))
		return NULL;
	while (monotonic_raw_ns() <
	       atomic_load_explicit(&cell->deadline_ns,
				    memory_order_acquire)) {
		const struct target_object *target =
			phase < 2 ? &cell->targets[target_index] : NULL;
		const char *operation = phase < 2 ? "SET" : "CLEAR";
		int update_ret;
		int lock_ret;
		bool trace_update;

		lock_ret = pthread_mutex_lock(&cell->trace_lock);
		if (lock_ret) {
			atomic_fetch_add_explicit(&cell->failures, 1,
						  memory_order_relaxed);
			break;
		}
		if (atomic_load_explicit(&cell->abort, memory_order_acquire)) {
			pthread_mutex_unlock(&cell->trace_lock);
			break;
		}
		arg->writer_seq++;
		trace_update = cell->trace_markers_enabled;
		update_ret = history_update(cell->log, cell->name, cell->control_fd,
					    operation, target, arg->writer_seq,
					    trace_update ?
						    cell->trace_marker_fd : -1);
		lock_ret = pthread_mutex_unlock(&cell->trace_lock);
		if (update_ret || lock_ret) {
			atomic_fetch_add_explicit(&cell->failures, 1,
						  memory_order_relaxed);
			break;
		}
		atomic_fetch_add_explicit(&cell->updates, 1,
					  memory_order_relaxed);
		if (phase == 0) {
			target_index = (target_index + 1) % cell->target_count;
			phase = 1;
		} else if (phase == 1) {
			phase = 2;
		} else {
			target_index = (target_index + 1) % cell->target_count;
			phase = 0;
		}
	}
	arg->writer_seq++;
	if (history_update(cell->log, cell->name, cell->control_fd, "CLEAR",
			   NULL, arg->writer_seq, -1))
		atomic_fetch_add_explicit(&cell->failures, 1,
					  memory_order_relaxed);
	else
		atomic_fetch_add_explicit(&cell->updates, 1,
					  memory_order_relaxed);
	return NULL;
}

static void *publication_reader(void *opaque)
{
	struct reader_arg *arg = opaque;
	struct publication_cell *cell = arg->cell;
	bool directory_cell = cell->logical_child != NULL;

	while (!atomic_load_explicit(&cell->start, memory_order_acquire))
		sched_yield();
	if (atomic_load_explicit(&cell->abort, memory_order_relaxed))
		return NULL;
	while (monotonic_raw_ns() <
	       atomic_load_explicit(&cell->deadline_ns,
				    memory_order_acquire)) {
		const char *path;
		enum open_kind kind;
		int ret;

		if (directory_cell && (arg->opens & 1)) {
			path = cell->logical_path;
			kind = OPEN_DIRECTORY;
		} else if (directory_cell) {
			path = cell->logical_child;
			kind = OPEN_DIRECTORY_CHILD;
		} else {
			path = cell->logical_path;
			kind = OPEN_FINAL_FILE;
		}
		ret = history_open(cell->log, cell->name, path, kind,
				   cell->targets, cell->target_count, "reader",
				   arg->reader_id, NULL);
		if (!ret)
			arg->successful_opens++;
		else if (ret == -ENOENT)
			arg->absent_opens++;
		else
			atomic_fetch_add_explicit(&cell->failures, 1,
						  memory_order_relaxed);
		arg->opens++;
	}
	return NULL;
}

static int run_publication_cell(struct run_log *log, const char *cell_name,
				const char *cgroup_path,
				const char *managed_dir,
				const char *physical_dir,
				const char *logical_path,
				const char *logical_child,
				struct target_object *targets,
				size_t target_count,
				unsigned int duration_seconds,
				unsigned int reader_count,
				unsigned int min_updates,
				unsigned int min_opens,
				unsigned int lifecycle_cycles)
{
	struct publication_cell cell = {
		.log = log,
		.name = cell_name,
		.logical_path = logical_path,
		.logical_child = logical_child,
		.targets = targets,
		.target_count = target_count,
		.duration_seconds = duration_seconds,
		.reader_count = reader_count,
		.min_updates = min_updates,
		.min_opens = min_opens,
		.control_fd = -1,
		.trace_marker_fd = -1,
	};
	struct rcu_trace_session trace_session = {};
	struct writer_arg writer_arg = { .cell = &cell };
	struct reader_arg *reader_args = NULL;
	pthread_t *reader_threads = NULL;
	pthread_t writer_thread;
	unsigned int created_readers = 0;
	bool writer_created = false;
	bool trace_started = false;
	unsigned int failures = 0;
	unsigned int i;
	int ret = 0;
	int trace_ret;

	(void)cgroup_path;
	(void)managed_dir;
	(void)physical_dir;
	(void)lifecycle_cycles;
	for (i = 0; i < target_count; i++) {
		if (emit_target_definition(log, cell_name, &targets[i]))
			record_failure(log);
	}
	cell.control_fd = open("/sys/kernel/debug/namei_ext/register_target",
			       O_WRONLY | O_CLOEXEC);
	if (cell.control_fd < 0)
		return -errno;
	ret = pthread_mutex_init(&cell.trace_lock, NULL);
	if (ret) {
		close(cell.control_fd);
		return -ret;
	}
	ret = verify_rcu_target_path(log, cell_name, cell.control_fd,
				     logical_path, &targets[0],
				     logical_child != NULL);
	if (ret)
		goto out;
	reader_args = calloc(reader_count, sizeof(*reader_args));
	reader_threads = calloc(reader_count, sizeof(*reader_threads));
	if (!reader_args || !reader_threads) {
		ret = -ENOMEM;
		goto out;
	}
	ret = pthread_create(&writer_thread, NULL, publication_writer,
			     &writer_arg);
	if (ret) {
		ret = -ret;
		goto out;
	}
	writer_created = true;
	for (i = 0; i < reader_count; i++) {
		reader_args[i].cell = &cell;
		reader_args[i].reader_id = i;
		ret = pthread_create(&reader_threads[i], NULL,
				     publication_reader, &reader_args[i]);
		if (ret) {
			ret = -ret;
			break;
		}
		created_readers++;
	}
	if (ret) {
		atomic_store_explicit(&cell.abort, true, memory_order_relaxed);
		atomic_store_explicit(&cell.start, true, memory_order_release);
		for (i = 0; i < created_readers; i++)
			pthread_join(reader_threads[i], NULL);
		if (writer_created)
			pthread_join(writer_thread, NULL);
		goto out;
	}
	ret = start_concurrent_rcu_trace(&cell, &trace_session);
	if (ret) {
		atomic_store_explicit(&cell.abort, true, memory_order_relaxed);
		atomic_store_explicit(&cell.start, true, memory_order_release);
		for (i = 0; i < created_readers; i++)
			pthread_join(reader_threads[i], NULL);
		if (writer_created)
			pthread_join(writer_thread, NULL);
		goto out;
	}
	trace_started = true;
	atomic_store_explicit(
		&cell.deadline_ns,
		monotonic_raw_ns() +
			(uint64_t)duration_seconds * 1000000000ULL,
		memory_order_release);
	atomic_store_explicit(&cell.start, true, memory_order_release);
	{
		const uint64_t trace_start = monotonic_raw_ns();
		const uint64_t trace_minimum = trace_start + 250000000ULL;
		const uint64_t trace_limit = trace_start + 2000000000ULL;
		struct timespec interval = {
			.tv_sec = 0,
			.tv_nsec = 1000000,
		};
		bool sleep_failed = false;
		uint64_t now;

		do {
			struct timespec remaining = interval;

			while (nanosleep(&remaining, &remaining)) {
				if (errno == EINTR)
					continue;
				atomic_fetch_add_explicit(&cell.failures, 1,
							  memory_order_relaxed);
				sleep_failed = true;
				break;
			}
			now = monotonic_raw_ns();
		} while (!sleep_failed && now < trace_limit &&
			 (now < trace_minimum ||
			  atomic_load_explicit(&cell.updates,
					       memory_order_relaxed) < 3));
		if (atomic_load_explicit(&cell.updates, memory_order_relaxed) < 3)
			atomic_fetch_add_explicit(&cell.failures, 1,
						  memory_order_relaxed);
	}
	trace_ret = stop_concurrent_rcu_trace(&cell, &trace_session);
	trace_started = false;
	if (trace_ret)
		atomic_fetch_add_explicit(&cell.failures, 1,
					  memory_order_relaxed);
	pthread_join(writer_thread, NULL);
	for (i = 0; i < reader_count; i++)
		pthread_join(reader_threads[i], NULL);
	if (atomic_load_explicit(&cell.updates, memory_order_relaxed) <
	    min_updates)
		failures++;
	for (i = 0; i < reader_count; i++) {
		int reader_pass = reader_args[i].opens >= min_opens &&
				  reader_args[i].successful_opens > 0 &&
				  reader_args[i].absent_opens > 0;

		if (!reader_pass)
			failures++;
		if (emit_line(
			    log,
			    "{\"event\":\"target-lifetime-reader-summary\","
			    "\"cell\":\"%s\",\"reader\":%u,"
			    "\"opens\":%" PRIu64 ","
			    "\"successful_opens\":%" PRIu64 ","
			    "\"absent_opens\":%" PRIu64 ","
			    "\"pass\":%s}\n",
			    cell_name, i, reader_args[i].opens,
			    reader_args[i].successful_opens,
			    reader_args[i].absent_opens,
			    reader_pass ? "true" : "false"))
			record_failure(log);
	}
	failures +=
		atomic_load_explicit(&cell.failures, memory_order_relaxed);
	ret = emit_line(
		log,
		"{\"event\":\"target-lifetime-cell-summary\","
		"\"cell\":\"%s\",\"duration_seconds\":%u,"
		"\"readers\":%u,\"updates\":%" PRIu64 ","
		"\"minimum_updates\":%u,\"minimum_opens_per_reader\":%u,"
		"\"failures\":%u,\"pass\":%s}\n",
		cell_name, duration_seconds, reader_count,
		(uint64_t)atomic_load_explicit(&cell.updates,
					      memory_order_relaxed),
		min_updates, min_opens, failures,
		failures ? "false" : "true");
	if (ret)
		record_failure(log);
	if (failures)
		ret = -EIO;
out:
	if (trace_started && stop_concurrent_rcu_trace(&cell, &trace_session) &&
	    !ret)
		ret = -EIO;
	free(reader_threads);
	free(reader_args);
	if (cell.control_fd >= 0 && close(cell.control_fd) && !ret)
		ret = -errno;
	trace_ret = pthread_mutex_destroy(&cell.trace_lock);
	if (trace_ret && !ret)
		ret = -trace_ret;
	return ret;
}

static int emit_lifecycle_case(struct run_log *log, const char *name,
			       unsigned int cycle, int result)
{
	return emit_line(
		log,
		"{\"event\":\"target-lifetime-lifecycle\","
		"\"case\":\"%s\",\"cycle\":%u,\"result\":%d,"
		"\"pass\":%s}\n",
			name, cycle, result, result ? "false" : "true");
}

static int emit_lifecycle_step(struct run_log *log, const char *case_name,
			       unsigned int cycle, const char *step,
			       int expected_result, int observed_result,
			       const struct target_object *target,
			       const struct stat *observed)
{
	dev_t expected_dev = target ? target->dev : 0;
	ino_t expected_ino = target ? target->ino : 0;
	dev_t observed_dev = observed ? observed->st_dev : 0;
	ino_t observed_ino = observed ? observed->st_ino : 0;
	bool pass = observed_result == expected_result &&
		    (!target || (observed && observed_dev == expected_dev &&
			 observed_ino == expected_ino));

	if (emit_line(
		    log,
		    "{\"event\":\"target-lifetime-lifecycle-step\","
		    "\"cell\":\"pinned-object\",\"case\":\"%s\","
		    "\"cycle\":%u,\"step\":\"%s\","
		    "\"expected_result\":%d,\"observed_result\":%d,"
		    "\"expected_device\":%" PRIu64 ","
		    "\"observed_device\":%" PRIu64 ","
		    "\"expected_inode\":%" PRIu64 ","
		    "\"observed_inode\":%" PRIu64 ",\"pass\":%s}\n",
		    case_name, cycle, step, expected_result, observed_result,
		    (uint64_t)expected_dev, (uint64_t)observed_dev,
		    (uint64_t)expected_ino, (uint64_t)observed_ino,
		    pass ? "true" : "false")) {
		record_failure(log);
		return -EIO;
	}
	return pass ? 0 : -EIO;
}

static int emit_cleanup(struct run_log *log, const char *cell,
			int target_clear, int scope_clear, int detach,
			int cgroup_remove, int tree_remove)
{
	bool pass = !target_clear && !scope_clear && !detach &&
		    !cgroup_remove && !tree_remove;

	return emit_line(
		log,
		"{\"event\":\"target-lifetime-cleanup\","
		"\"cell\":\"%s\",\"target_clear\":%d,"
		"\"scope_clear\":%d,\"detach\":%d,"
		"\"cgroup_remove\":%d,\"tree_remove\":%d,\"pass\":%s}\n",
		cell, target_clear, scope_clear, detach, cgroup_remove,
		tree_remove, pass ? "true" : "false");
}

static int check_held_file(int fd, const char *expected, dev_t dev, ino_t ino,
			   struct stat *observed)
{
	int ret;

	ret = read_fd_matches(fd, expected);
	if (ret)
		return ret;
	if (fstat(fd, observed))
		return -errno;
	return observed->st_dev == dev && observed->st_ino == ino ? 0 : -ESTALE;
}

static int check_held_directory(int fd, const struct target_object *target,
				struct stat *observed)
{
	int ret;

	if (fstat(fd, observed))
		return -errno;
	if (observed->st_dev != target->dev || observed->st_ino != target->ino)
		return -ESTALE;
	ret = directory_fd_matches(fd, target);
	return ret;
}

static int run_pinned_lifecycle_cell(
	struct run_log *log, const char *cell_name, const char *cgroup_path,
	const char *managed_dir, const char *physical_dir,
	const char *logical_path, const char *logical_child,
	struct target_object *targets, size_t target_count,
	unsigned int duration_seconds, unsigned int reader_count,
	unsigned int min_updates, unsigned int min_opens,
	unsigned int lifecycle_cycles)
{
	char original[PATH_MAX];
	char renamed[PATH_MAX];
	char child[PATH_MAX];
	char expected[96];
	int control_fd = -1;
	uint64_t writer_seq = 0;
	unsigned int failures = 0;
	unsigned int cycle;
	int ret = 0;

	(void)cgroup_path;
	(void)managed_dir;
	(void)duration_seconds;
	(void)reader_count;
	(void)min_updates;
	(void)min_opens;
	(void)targets;
	(void)target_count;
	control_fd = open("/sys/kernel/debug/namei_ext/register_target",
			  O_WRONLY | O_CLOEXEC);
	if (control_fd < 0)
		return -errno;

	for (cycle = 0; cycle < lifecycle_cycles; cycle++) {
		struct target_object file_target = { .directory = false };
		struct target_object dir_target = { .directory = true };
		struct stat held_logical_stat = {};
		struct stat held_physical_stat = {};
		struct stat held_dir_stat = {};
		int held_logical = -1;
		int held_physical = -1;
		int held_dir = -1;
		int case_ret = 0;
		int step_ret;

		snprintf(file_target.state, sizeof(file_target.state),
			 "pinned-file-%u", cycle);
		snprintf(file_target.payload, sizeof(file_target.payload), "%s\n",
			 file_target.state);
		snprintf(original, sizeof(original), "%s/file-%u", physical_dir,
			 cycle);
		snprintf(renamed, sizeof(renamed), "%s/file-%u-renamed",
			 physical_dir, cycle);
		if (copy_text(file_target.path, sizeof(file_target.path),
			      original))
			case_ret = -ENAMETOOLONG;
		if (namei_ext_write_text(original, file_target.payload) ||
		    stat_target(&file_target) ||
		    emit_target_definition(log, cell_name, &file_target))
			case_ret = -EIO;
		held_physical = open(original, O_RDONLY | O_CLOEXEC);
		if (held_physical < 0)
			case_ret = -errno;
		if (!case_ret) {
			step_ret = history_update(log, cell_name, control_fd, "SET",
						  &file_target, ++writer_seq, -1);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "register", 0, step_ret,
						NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_FINAL_FILE, &file_target, 1,
						"lifecycle", cycle, &held_logical);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "open-held-logical", 0,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = rename(original, renamed) ? -errno : 0;
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "rename-target", 0, step_ret,
						NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_FINAL_FILE, &file_target, 1,
						"lifecycle", cycle, NULL);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "open-after-rename", 0,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = unlink(renamed) ? -errno : 0;
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "unlink-target", 0, step_ret,
						NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_FINAL_FILE, &file_target, 1,
						"lifecycle", cycle, NULL);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "open-after-unlink", 0,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_update(log, cell_name, control_fd, "CLEAR",
						  NULL, ++writer_seq, -1);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "clear-registration", 0,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_FINAL_FILE, &file_target, 1,
						"lifecycle", cycle, NULL);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "open-after-clear", -ENOENT,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = check_held_file(held_logical, file_target.payload,
						   file_target.dev, file_target.ino,
						   &held_logical_stat);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "held-logical-after-clear", 0,
						step_ret, &file_target,
						&held_logical_stat))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = check_held_file(held_physical, file_target.payload,
						   file_target.dev, file_target.ino,
						   &held_physical_stat);
			if (emit_lifecycle_step(log, "file-rename-unlink-clear",
						cycle, "held-physical-after-clear", 0,
						step_ret, &file_target,
						&held_physical_stat))
				case_ret = -EIO;
		}
		if (held_logical >= 0)
			close(held_logical);
		if (held_physical >= 0)
			close(held_physical);
		if (emit_lifecycle_case(log, "file-rename-unlink-clear", cycle,
				       case_ret))
			record_failure(log);
		if (case_ret)
			failures++;

		case_ret = 0;
		snprintf(dir_target.state, sizeof(dir_target.state),
			 "pinned-dir-%u", cycle);
		snprintf(original, sizeof(original), "%s/dir-%u", physical_dir,
			 cycle);
		snprintf(renamed, sizeof(renamed), "%s/dir-%u-renamed",
			 physical_dir, cycle);
		if (copy_text(dir_target.path, sizeof(dir_target.path),
			      original))
			case_ret = -ENAMETOOLONG;
		if (namei_ext_path_join(child, sizeof(child), original,
					"child.txt"))
			case_ret = -ENAMETOOLONG;
		snprintf(expected, sizeof(expected), "%s\n", dir_target.state);
		if (!case_ret)
			case_ret = make_dir(original, 0755);
		if (!case_ret)
			case_ret = namei_ext_write_text(child, expected);
		if (!case_ret)
			case_ret = stat_target(&dir_target);
		if (!case_ret)
			case_ret =
				emit_target_definition(log, cell_name, &dir_target);
		if (!case_ret) {
			step_ret = history_update(log, cell_name, control_fd, "SET",
						  &dir_target, ++writer_seq, -1);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"register", 0, step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_DIRECTORY, &dir_target, 1,
						"lifecycle", cycle, &held_dir);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"open-held-logical", 0, step_ret,
						NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = rename(original, renamed) ? -errno : 0;
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"rename-target", 0, step_ret, NULL,
						NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_child,
						OPEN_DIRECTORY_CHILD, &dir_target, 1,
						"lifecycle", cycle, NULL);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"open-child-after-rename", 0,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_update(log, cell_name, control_fd, "CLEAR",
						  NULL, ++writer_seq, -1);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"clear-registration", 0, step_ret,
						NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = history_open(log, cell_name, logical_path,
						OPEN_DIRECTORY, &dir_target, 1,
						"lifecycle", cycle, NULL);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"open-after-clear", -ENOENT,
						step_ret, NULL, NULL))
				case_ret = -EIO;
		}
		if (!case_ret) {
			step_ret = check_held_directory(held_dir, &dir_target,
							&held_dir_stat);
			if (emit_lifecycle_step(log, "directory-rename-clear", cycle,
						"held-directory-after-clear", 0,
						step_ret, &dir_target, &held_dir_stat))
				case_ret = -EIO;
		}
		if (held_dir >= 0)
			close(held_dir);
		namei_ext_remove_tree(renamed);
		if (emit_lifecycle_case(log, "directory-rename-clear", cycle,
				       case_ret))
			record_failure(log);
		if (case_ret)
			failures++;
	}
	ret = emit_line(
		log,
		"{\"event\":\"target-lifetime-cell-summary\","
		"\"cell\":\"%s\",\"lifecycle_cycles\":%u,"
		"\"failures\":%u,\"pass\":%s}\n",
		cell_name, lifecycle_cycles, failures,
		failures ? "false" : "true");
	if (ret)
		record_failure(log);
	if (failures)
		ret = -EIO;
	if (control_fd >= 0 && close(control_fd) && !ret)
		ret = -errno;
	return ret;
}

static int setup_publication_targets(const char *cell_name,
				     const char *physical_dir, bool directory,
				     struct target_object *targets,
				     size_t target_count)
{
	size_t i;

	for (i = 0; i < target_count; i++) {
		char child[PATH_MAX];
		char component[32];
		int length;
		int ret;

		targets[i].directory = directory;
		length = snprintf(targets[i].state, sizeof(targets[i].state),
				  "%s-%zu", cell_name, i);
		if (length < 0 ||
		    (size_t)length >= sizeof(targets[i].state))
			return -ENAMETOOLONG;
		length = snprintf(targets[i].payload,
				  sizeof(targets[i].payload), "%s-%zu\n",
				  cell_name, i);
		if (length < 0 ||
		    (size_t)length >= sizeof(targets[i].payload))
			return -ENAMETOOLONG;
		length = snprintf(component, sizeof(component), "%zu", i);
		if (length < 0 || (size_t)length >= sizeof(component))
			return -ENAMETOOLONG;
		if (namei_ext_path_join(targets[i].path,
					sizeof(targets[i].path), physical_dir,
					component))
			return -ENAMETOOLONG;
		if (directory) {
			ret = make_dir(targets[i].path, 0755);
			if (ret)
				return ret;
			if (namei_ext_path_join(child, sizeof(child),
						targets[i].path, "child.txt"))
				return -ENAMETOOLONG;
			ret = namei_ext_write_text(child, targets[i].payload);
		} else {
			ret = namei_ext_write_text(targets[i].path,
						   targets[i].payload);
		}
		if (ret)
			return ret;
		ret = stat_target(&targets[i]);
		if (ret)
			return ret;
	}
	return 0;
}

static int run_attached_cell(struct run_log *log, const char *policy_path,
			     const char *cgroup_root, const char *work_root,
			     const char *cell_name, bool directory,
			     cell_fn run_cell,
			     unsigned int duration_seconds,
			     unsigned int reader_count,
			     unsigned int min_updates,
			     unsigned int min_opens,
			     unsigned int lifecycle_cycles)
{
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	struct target_object targets[TARGET_POOL_SIZE] = {};
	char cgroup_path[PATH_MAX];
	char cell_root[PATH_MAX];
	char managed_dir[PATH_MAX];
	char physical_dir[PATH_MAX];
	char logical_path[PATH_MAX];
	char logical_child[PATH_MAX];
	pid_t child;
	int cgroup_remove_ret = 0;
	int detach_ret = 0;
	int scope_clear_ret = 0;
	int status;
	int target_clear_ret = 0;
	int tree_remove_ret = 0;
	int ret = 0;

	snprintf(cgroup_path, sizeof(cgroup_path), "%s/namei-ext-life-%ld-%s",
		 cgroup_root, (long)getpid(), cell_name);
	if (namei_ext_path_join(cell_root, sizeof(cell_root), work_root,
				cell_name) ||
	    namei_ext_path_join(managed_dir, sizeof(managed_dir), cell_root,
				"managed") ||
	    namei_ext_path_join(physical_dir, sizeof(physical_dir), cell_root,
				"physical") ||
	    namei_ext_path_join(logical_path, sizeof(logical_path),
				managed_dir, "view") ||
	    namei_ext_path_join(logical_child, sizeof(logical_child),
				logical_path, "child.txt"))
		return -ENAMETOOLONG;
	if ((ret = make_dir(cell_root, 0755)) ||
	    (ret = make_dir(managed_dir, 0755)) ||
	    (ret = make_dir(physical_dir, 0755)) ||
	    (ret = make_dir(cgroup_path, 0755)))
		goto out;
	if (run_cell == run_publication_cell &&
	    (ret = setup_publication_targets(cell_name, physical_dir,
					     directory, targets,
					     TARGET_POOL_SIZE)))
		goto out;
	if (namei_ext_policy_load_attach(policy_path, cgroup_path, &policy)) {
		ret = -errno;
		goto out;
	}
	ret = namei_ext_policy_parent_exact(cgroup_path, managed_dir);
	if (ret)
		goto out;
	child = fork();
	if (child < 0) {
		ret = -errno;
		goto out;
	}
	if (!child) {
		int child_ret;

		if (namei_ext_move_self_to_cgroup(cgroup_path))
			_exit(2);
		child_ret = run_cell(
			log, cell_name, cgroup_path, managed_dir, physical_dir,
			logical_path, directory ? logical_child : NULL, targets,
			run_cell == run_publication_cell ? TARGET_POOL_SIZE : 0,
			duration_seconds, reader_count, min_updates, min_opens,
			lifecycle_cycles);
		_exit(child_ret ? 1 : 0);
	}
	if (waitpid(child, &status, 0) != child)
		ret = -errno;
	else if (!WIFEXITED(status) || WEXITSTATUS(status))
		ret = -EIO;
	if (run_cell == run_publication_cell &&
	    verify_publication_targets(log, cell_name, targets, TARGET_POOL_SIZE) &&
	    !ret)
		ret = -EIO;
out:
	if (policy.attached) {
		target_clear_ret = namei_ext_clear_targets(cgroup_path);
		scope_clear_ret = namei_ext_policy_parent_clear(cgroup_path);
		detach_ret = namei_ext_policy_destroy(&policy);
	}
	if (rmdir(cgroup_path) && errno != ENOENT)
		cgroup_remove_ret = -errno;
	namei_ext_remove_tree(cell_root);
	if (!access(cell_root, F_OK))
		tree_remove_ret = -EEXIST;
	else if (errno != ENOENT)
		tree_remove_ret = -errno;
	if (emit_cleanup(log, cell_name, target_clear_ret, scope_clear_ret,
			 detach_ret, cgroup_remove_ret, tree_remove_ret))
		record_failure(log);
	if (!ret && (target_clear_ret || scope_clear_ret || detach_ret ||
		     cgroup_remove_ret || tree_remove_ret))
		ret = -EIO;
	if (ret)
		record_failure(log);
	return ret;
}

static int parse_uint(const char *value, unsigned int *result)
{
	char *end = NULL;
	unsigned long parsed;

	errno = 0;
	parsed = strtoul(value, &end, 10);
	if (errno || !end || *end || !parsed || parsed > UINT_MAX)
		return -EINVAL;
	*result = (unsigned int)parsed;
	return 0;
}

int main(int argc, char **argv)
{
	struct run_log log = {
		.fd = -1,
		.lock = PTHREAD_MUTEX_INITIALIZER,
	};
	char root_template[PATH_MAX];
	char *work_root;
	unsigned int duration_seconds;
	unsigned int reader_count;
	unsigned int min_updates;
	unsigned int min_opens;
	unsigned int lifecycle_cycles;
	unsigned int failures = 0;
	char *slash;
	int ret;

	if (argc != 10) {
		fprintf(stderr,
			"usage: %s POLICY OUTPUT CGROUP_ROOT WORK_ROOT DURATION READERS MIN_UPDATES MIN_OPENS LIFECYCLE_CYCLES\n",
			argv[0]);
		return 2;
	}
	if (parse_uint(argv[5], &duration_seconds) ||
	    parse_uint(argv[6], &reader_count) ||
	    parse_uint(argv[7], &min_updates) ||
	    parse_uint(argv[8], &min_opens) ||
	    parse_uint(argv[9], &lifecycle_cycles))
		return 2;
	if (copy_text(log.output_dir, sizeof(log.output_dir), argv[2]))
		return 2;
	slash = strrchr(log.output_dir, '/');
	if (!slash) {
		if (copy_text(log.output_dir, sizeof(log.output_dir), "."))
			return 2;
	} else if (slash == log.output_dir) {
		slash[1] = '\0';
	} else {
		*slash = '\0';
	}
	if (snprintf(root_template, sizeof(root_template),
		     "%s/namei-ext-target-lifetime-XXXXXX", argv[4]) < 0 ||
	    strlen(root_template) >= sizeof(root_template) - 1)
		return 2;
	log.shared = mmap(NULL, sizeof(*log.shared), PROT_READ | PROT_WRITE,
			  MAP_SHARED | MAP_ANONYMOUS, -1, 0);
	if (log.shared == MAP_FAILED)
		return 2;
	atomic_init(&log.shared->event_seq, 0);
	atomic_init(&log.shared->op_seq, 0);
	atomic_init(&log.shared->failures, 0);
	work_root = mkdtemp(root_template);
	if (!work_root) {
		munmap(log.shared, sizeof(*log.shared));
		return 2;
	}
	log.fd = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (log.fd < 0) {
		namei_ext_remove_tree(work_root);
		munmap(log.shared, sizeof(*log.shared));
		return 2;
	}
	if (emit_line(&log,
		  "{\"event\":\"target-lifetime-run-start\","
		  "\"duration_seconds\":%u,\"readers\":%u,"
		  "\"minimum_updates\":%u,\"minimum_opens_per_reader\":%u,"
		  "\"lifecycle_cycles\":%u}\n",
		  duration_seconds, reader_count, min_updates, min_opens,
		  lifecycle_cycles))
		failures++;

	ret = run_attached_cell(&log, argv[1], argv[3], work_root,
				"final-file", false, run_publication_cell,
				duration_seconds, reader_count, min_updates,
				min_opens, lifecycle_cycles);
	if (ret)
		failures++;
	ret = run_attached_cell(&log, argv[1], argv[3], work_root,
				"directory", true, run_publication_cell,
				duration_seconds, reader_count, min_updates,
				min_opens, lifecycle_cycles);
	if (ret)
		failures++;
	ret = run_attached_cell(&log, argv[1], argv[3], work_root,
				"pinned-object", true,
				run_pinned_lifecycle_cell, duration_seconds,
				reader_count, min_updates, min_opens,
				lifecycle_cycles);
	if (ret)
		failures++;
	failures += atomic_load_explicit(&log.shared->failures,
					 memory_order_relaxed);
	if (emit_line(&log,
		  "{\"event\":\"target-lifetime-run-summary\","
		  "\"failures\":%u,\"pass\":%s}\n",
		  failures, failures ? "false" : "true"))
		failures++;
	if (close(log.fd))
		failures++;
	namei_ext_remove_tree(work_root);
	if (munmap(log.shared, sizeof(*log.shared)))
		failures++;
	return failures ? 1 : 0;
}
