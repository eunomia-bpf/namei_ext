// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include "rq2_measurement.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <linux/magic.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/vfs.h>
#include <time.h>
#include <unistd.h>

_Static_assert(sizeof(AFS_RQ2_DOCUMENT_ID) - 1 == 22,
	       "RQ2 document ID must be exactly 22 bytes");
_Static_assert(sizeof(AFS_RQ2_DOCUMENT_PAYLOAD) - 1 == 27,
	       "RQ2 payload must be exactly 27 bytes");

struct linux_dirent64 {
	uint64_t d_ino;
	int64_t d_off;
	unsigned short d_reclen;
	unsigned char d_type;
	char d_name[];
};

#define LINUX_DIRENT64_NAME_OFFSET \
	offsetof(struct linux_dirent64, d_name)

uint64_t afs_rq2_monotonic_raw_ns(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC_RAW, &now))
		return 0;
	return (uint64_t)now.tv_sec * 1000000000ULL +
	       (uint64_t)now.tv_nsec;
}

int afs_rq2_parse_count(const char *text, uint32_t *value)
{
	char *end = NULL;
	unsigned long parsed;

	errno = 0;
	parsed = strtoul(text, &end, 10);
	if (errno || !end || *end || !parsed || parsed > UINT32_MAX)
		return -EINVAL;
	*value = (uint32_t)parsed;
	return 0;
}

int afs_rq2_join_path(char *destination, size_t size,
		      const char *parent, const char *child)
{
	int written = snprintf(destination, size, "%s/%s", parent, child);

	if (written < 0 || (size_t)written >= size)
		return -ENAMETOOLONG;
	return 0;
}

int afs_rq2_write_payload(const char *path)
{
	const char *cursor = AFS_RQ2_DOCUMENT_PAYLOAD;
	size_t remaining = sizeof(AFS_RQ2_DOCUMENT_PAYLOAD) - 1;
	int fd;

	fd = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
	if (fd < 0)
		return -errno;
	while (remaining) {
		ssize_t written = write(fd, cursor, remaining);

		if (written < 0) {
			int saved_errno = errno;

			if (saved_errno == EINTR)
				continue;
			close(fd);
			return -saved_errno;
		}
		cursor += written;
		remaining -= (size_t)written;
	}
	if (close(fd))
		return -errno;
	return 0;
}

int afs_rq2_emit_filesystem(FILE *out, const char *mechanism,
			    const char *path)
{
	struct statfs status;
	int ret = 0;

	if (statfs(path, &status))
		ret = -errno;
	else if ((unsigned long)status.f_type != EXT4_SUPER_MAGIC)
		ret = -ENODEV;
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-filesystem\","
		"\"mechanism\":\"%s\",\"filesystem\":\"ext4\","
		"\"f_type\":%lu,\"errno\":%d,\"pass\":%s}\n",
		mechanism, ret ? 0UL : (unsigned long)status.f_type,
		ret ? -ret : 0, ret ? "false" : "true");
	fflush(out);
	return ret;
}

static int timed_read_payload(int parent_fd, const char *path,
			      struct afs_rq2_transaction *observation)
{
	char buffer[64];
	size_t expected_length = sizeof(AFS_RQ2_DOCUMENT_PAYLOAD) - 1;
	size_t offset = 0;
	bool matches = true;
	int fd;

	fd = openat(parent_fd, path, O_RDONLY | O_CLOEXEC);
	if (fd < 0) {
		observation->open_errno = errno;
		return -errno;
	}
	for (;;) {
		ssize_t bytes = read(fd, buffer, sizeof(buffer));

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			observation->read_errno = errno;
			close(fd);
			return -errno;
		}
		if (!bytes) {
			observation->payload_eof = true;
			break;
		}
		if (offset > expected_length ||
		    (size_t)bytes > expected_length - offset ||
		    memcmp(buffer, AFS_RQ2_DOCUMENT_PAYLOAD + offset,
			   (size_t)bytes))
			matches = false;
		if (SIZE_MAX - offset < (size_t)bytes) {
			observation->read_errno = EOVERFLOW;
			close(fd);
			return -EOVERFLOW;
		}
		offset += (size_t)bytes;
	}
	observation->payload_bytes = offset;
	observation->payload_matches = matches && offset == expected_length;
	if (close(fd)) {
		observation->close_errno = errno;
		return -errno;
	}
	return observation->payload_matches ? 0 : -EBADMSG;
}

static int timed_read_directory(int parent_fd, const char *document_id,
				struct afs_rq2_transaction *observation)
{
	char buffer[4096];
	int fd;

	fd = openat(parent_fd, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (fd < 0) {
		observation->directory_open_errno = errno;
		return -errno;
	}
	for (;;) {
		ssize_t bytes = syscall(SYS_getdents64, fd, buffer, 4096U);
		size_t offset = 0;

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			observation->getdents_errno = errno;
			close(fd);
			return -errno;
		}
		if (!bytes)
			break;
		while (offset < (size_t)bytes) {
			struct linux_dirent64 *entry =
				(struct linux_dirent64 *)(buffer + offset);
			size_t name_capacity;

			if (entry->d_reclen < LINUX_DIRENT64_NAME_OFFSET + 1 ||
			    entry->d_reclen > (size_t)bytes - offset) {
				observation->getdents_errno = EIO;
				close(fd);
				return -EIO;
			}
			name_capacity = entry->d_reclen -
					LINUX_DIRENT64_NAME_OFFSET;
			if (!memchr(entry->d_name, '\0', name_capacity)) {
				observation->getdents_errno = EIO;
				close(fd);
				return -EIO;
			}
			observation->directory_entries++;
			if (!strcmp(entry->d_name, ".")) {
				if (observation->dot_seen)
					observation->unexpected_entry = true;
				observation->dot_seen = true;
			} else if (!strcmp(entry->d_name, "..")) {
				if (observation->dotdot_seen)
					observation->unexpected_entry = true;
				observation->dotdot_seen = true;
			} else if (!strcmp(entry->d_name, document_id)) {
				if (observation->document_seen)
					observation->unexpected_entry = true;
				observation->document_seen = true;
			} else {
				observation->unexpected_entry = true;
			}
			offset += entry->d_reclen;
		}
	}
	if (close(fd)) {
		observation->directory_close_errno = errno;
		return -errno;
	}
	if (!observation->dot_seen || !observation->dotdot_seen ||
	    !observation->document_seen || observation->unexpected_entry ||
	    observation->directory_entries != 3)
		return -ENOMSG;
	return 0;
}

int afs_rq2_run_transaction(int parent_fd, const char *document_id,
			    struct afs_rq2_transaction *observation)
{
	char payload_path[128];
	struct stat status;
	uint64_t t0;
	uint64_t t1;
	uint64_t t2;
	uint64_t t3;
	uint64_t t4;
	int ret = 0;

	memset(observation, 0, sizeof(*observation));
	if (strlen(document_id) != 22 ||
	    snprintf(payload_path, sizeof(payload_path), "%s/%s", document_id,
		     AFS_RQ2_DOCUMENT_BASENAME) >= (int)sizeof(payload_path))
		return -EINVAL;
	t0 = afs_rq2_monotonic_raw_ns();
	if (!t0)
		return -errno;
	if (fstatat(parent_fd, document_id, &status, AT_SYMLINK_NOFOLLOW)) {
		observation->document_stat_errno = errno;
		ret = -errno;
	}
	t1 = afs_rq2_monotonic_raw_ns();
	if (!ret && fstatat(parent_fd, payload_path, &status, 0)) {
		observation->payload_stat_errno = errno;
		ret = -errno;
	}
	t2 = afs_rq2_monotonic_raw_ns();
	if (!ret)
		ret = timed_read_payload(parent_fd, payload_path, observation);
	t3 = afs_rq2_monotonic_raw_ns();
	if (!ret)
		ret = timed_read_directory(parent_fd, document_id, observation);
	t4 = afs_rq2_monotonic_raw_ns();
	if (!t1 || !t2 || !t3 || !t4)
		return -EIO;
	observation->document_stat_ns = t1 - t0;
	observation->payload_stat_ns = t2 - t1;
	observation->open_read_close_ns = t3 - t2;
	observation->readdir_ns = t4 - t3;
	observation->total_ns = t4 - t0;
	observation->pass = !ret && !observation->document_stat_errno &&
		!observation->payload_stat_errno && !observation->open_errno &&
		!observation->read_errno && !observation->close_errno &&
		!observation->directory_open_errno &&
		!observation->getdents_errno &&
		!observation->directory_close_errno &&
		observation->payload_bytes ==
			(sizeof(AFS_RQ2_DOCUMENT_PAYLOAD) - 1) &&
		observation->payload_matches && observation->payload_eof &&
		observation->dot_seen && observation->dotdot_seen &&
		observation->document_seen &&
		!observation->unexpected_entry &&
		observation->directory_entries == 3;
	return observation->pass ? 0 : (ret ? ret : -EINVAL);
}

int afs_rq2_run_warmup(int parent_fd, const char *document_id,
		       uint32_t warmup_count)
{
	for (uint32_t sample = 0; sample < warmup_count; sample++) {
		struct afs_rq2_transaction observation;
		int ret = afs_rq2_run_transaction(parent_fd, document_id,
						  &observation);

		if (ret)
			return ret;
	}
	return 0;
}

static void emit_transaction(FILE *out, const char *event,
			     const char *mechanism, const char *stream,
			     const char *phase, uint32_t sample,
			     const struct afs_rq2_transaction *observation)
{
	fprintf(out,
		"{\"event\":\"%s\",\"mechanism\":\"%s\","
		"\"stream\":\"%s\",\"phase\":\"%s\","
		"\"sample\":%" PRIu32 ",\"total_ns\":%" PRIu64 ","
		"\"document_stat_ns\":%" PRIu64 ","
		"\"payload_stat_ns\":%" PRIu64 ","
		"\"open_read_close_ns\":%" PRIu64 ","
		"\"readdir_ns\":%" PRIu64 ","
		"\"document_stat_errno\":%d,\"payload_stat_errno\":%d,"
		"\"open_errno\":%d,\"read_errno\":%d,\"close_errno\":%d,"
		"\"directory_open_errno\":%d,\"getdents_errno\":%d,"
		"\"directory_close_errno\":%d,"
		"\"payload_bytes\":%" PRIu64 ","
		"\"directory_entries\":%" PRIu32 ","
		"\"payload_matches\":%s,\"payload_eof\":%s,"
		"\"dot_seen\":%s,\"dotdot_seen\":%s,"
		"\"document_seen\":%s,\"unexpected_entry\":%s,"
		"\"pass\":%s}\n",
		event, mechanism, stream, phase, sample,
		observation->total_ns, observation->document_stat_ns,
		observation->payload_stat_ns,
		observation->open_read_close_ns, observation->readdir_ns,
		observation->document_stat_errno,
		observation->payload_stat_errno, observation->open_errno,
		observation->read_errno, observation->close_errno,
		observation->directory_open_errno,
		observation->getdents_errno,
		observation->directory_close_errno,
		observation->payload_bytes, observation->directory_entries,
		observation->payload_matches ? "true" : "false",
		observation->payload_eof ? "true" : "false",
		observation->dot_seen ? "true" : "false",
		observation->dotdot_seen ? "true" : "false",
		observation->document_seen ? "true" : "false",
		observation->unexpected_entry ? "true" : "false",
		observation->pass ? "true" : "false");
	fflush(out);
}

int afs_rq2_collect_measured(struct afs_rq2_batch *batch, int parent_fd,
			     const char *document_id, uint32_t sample_count)
{
	memset(batch, 0, sizeof(*batch));
	batch->observations = calloc(sample_count, sizeof(*batch->observations));
	if (!batch->observations)
		return -ENOMEM;
	batch->capacity = sample_count;
	for (uint32_t sample = 0; sample < sample_count; sample++) {
		int ret = afs_rq2_run_transaction(parent_fd, document_id,
						  &batch->observations[sample]);

		batch->count++;
		if (ret)
			return ret;
	}
	return 0;
}

int afs_rq2_emit_batch(FILE *out, const char *mechanism,
		       const char *stream, const struct afs_rq2_batch *batch)
{
	if (!batch->observations || !batch->count ||
	    batch->count > batch->capacity)
		return -EINVAL;
	for (uint32_t sample = 0; sample < batch->count; sample++)
		emit_transaction(out, "application-file-sharing-rq2-sample",
				 mechanism, stream, "measured", sample,
				 &batch->observations[sample]);
	return ferror(out) ? -EIO : 0;
}

void afs_rq2_free_batch(struct afs_rq2_batch *batch)
{
	free(batch->observations);
	memset(batch, 0, sizeof(*batch));
}

int afs_rq2_run_measured(FILE *out, const char *mechanism,
			 const char *stream, int parent_fd,
			 const char *document_id, uint32_t sample_count)
{
	struct afs_rq2_batch batch;
	int ret;
	int emit_ret;

	ret = afs_rq2_collect_measured(&batch, parent_fd, document_id,
				       sample_count);
	emit_ret = afs_rq2_emit_batch(out, mechanism, stream, &batch);
	afs_rq2_free_batch(&batch);
	return ret ? ret : emit_ret;
}

int afs_rq2_emit_single_oracle(FILE *out, const char *mechanism,
			      const char *stream, const char *phase, int parent_fd,
			      const char *document_id)
{
	struct afs_rq2_transaction observation;
	int ret = afs_rq2_run_transaction(parent_fd, document_id,
					  &observation);

	emit_transaction(out, "application-file-sharing-rq2-oracle",
			 mechanism, stream, phase, 0, &observation);
	return ret;
}

int afs_rq2_emit_hidden_oracle(FILE *out, const char *mechanism,
			      const char *phase, int parent_fd,
			      const char *document_id)
{
	struct stat status;
	int stat_errno = 0;
	int directory_errno = 0;
	bool listed = false;
	bool unexpected = false;
	uint32_t entries = 0;
	char buffer[4096];
	int directory_fd;
	bool pass;

	if (fstatat(parent_fd, document_id, &status, AT_SYMLINK_NOFOLLOW))
		stat_errno = errno;
	directory_fd = openat(parent_fd, ".",
			      O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (directory_fd < 0) {
		directory_errno = errno;
	} else {
		for (;;) {
			ssize_t bytes = syscall(SYS_getdents64, directory_fd,
						buffer, sizeof(buffer));
			size_t offset = 0;

			if (bytes < 0) {
				if (errno == EINTR)
					continue;
				directory_errno = errno;
				break;
			}
			if (!bytes)
				break;
			while (offset < (size_t)bytes) {
				struct linux_dirent64 *entry =
					(struct linux_dirent64 *)(buffer + offset);

				if (entry->d_reclen <
						LINUX_DIRENT64_NAME_OFFSET + 1 ||
				    entry->d_reclen > (size_t)bytes - offset) {
					directory_errno = EIO;
					break;
				}
				entries++;
				if (!strcmp(entry->d_name, document_id))
					listed = true;
				else if (strcmp(entry->d_name, ".") &&
					 strcmp(entry->d_name, ".."))
					unexpected = true;
				offset += entry->d_reclen;
			}
			if (directory_errno)
				break;
		}
		if (close(directory_fd) && !directory_errno)
			directory_errno = errno;
	}
	pass = stat_errno == ENOENT && !directory_errno && !listed &&
	       !unexpected && entries == 2;
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-hidden-oracle\","
		"\"mechanism\":\"%s\",\"phase\":\"%s\","
		"\"document_stat_errno\":%d,\"directory_errno\":%d,"
		"\"directory_entries\":%" PRIu32 ","
		"\"document_listed\":%s,\"unexpected_entry\":%s,"
		"\"pass\":%s}\n",
		mechanism, phase, stat_errno, directory_errno, entries,
		listed ? "true" : "false",
		unexpected ? "true" : "false", pass ? "true" : "false");
	fflush(out);
	return pass ? 0 : -EINVAL;
}

static int parse_thread_snapshot(pid_t pid, pid_t tid,
				 uint64_t *runtime_ns,
				 uint64_t *runqueue_wait_ns,
				 uint64_t *timeslices,
				 uint64_t *voluntary_switches,
				 uint64_t *involuntary_switches)
{
	char path[PATH_MAX];
	char *line = NULL;
	size_t capacity = 0;
	bool voluntary_seen = false;
	bool involuntary_seen = false;
	FILE *file;
	int ret = 0;

	if (snprintf(path, sizeof(path), "/proc/%jd/task/%jd/schedstat",
		     (intmax_t)pid, (intmax_t)tid) >= (int)sizeof(path))
		return -ENAMETOOLONG;
	file = fopen(path, "re");
	if (!file)
		return -errno;
	if (fscanf(file, "%" SCNu64 " %" SCNu64 " %" SCNu64,
		   runtime_ns, runqueue_wait_ns, timeslices) != 3)
		ret = -EINVAL;
	if (fclose(file) && !ret)
		ret = -errno;
	if (ret)
		return ret;
	if (snprintf(path, sizeof(path), "/proc/%jd/task/%jd/status",
		     (intmax_t)pid, (intmax_t)tid) >= (int)sizeof(path))
		return -ENAMETOOLONG;
	file = fopen(path, "re");
	if (!file)
		return -errno;
	while (getline(&line, &capacity, file) >= 0) {
		if (sscanf(line, "voluntary_ctxt_switches: %" SCNu64,
			   voluntary_switches) == 1) {
			voluntary_seen = true;
			continue;
		}
		if (sscanf(line, "nonvoluntary_ctxt_switches: %" SCNu64,
			   involuntary_switches) == 1)
			involuntary_seen = true;
	}
	if (ferror(file))
		ret = -EIO;
	if ((!voluntary_seen || !involuntary_seen) && !ret)
		ret = -ENODATA;
	free(line);
	if (fclose(file) && !ret)
		ret = -errno;
	return ret;
}

int afs_rq2_capture_process_snapshot(struct afs_rq2_process_snapshot *snapshot,
				     pid_t pid)
{
	char path[PATH_MAX];
	struct dirent *entry;
	DIR *directory;
	int ret = 0;

	memset(snapshot, 0, sizeof(*snapshot));
	snapshot->pid = pid;
	if (snprintf(path, sizeof(path), "/proc/%jd/task", (intmax_t)pid) >=
	    (int)sizeof(path))
		return -ENAMETOOLONG;
	directory = opendir(path);
	if (!directory)
		return -errno;
	for (;;) {
		char *end = NULL;
		long parsed_tid;
		uint64_t runtime_ns = 0;
		uint64_t runqueue_wait_ns = 0;
		uint64_t timeslices = 0;
		uint64_t voluntary_switches = 0;
		uint64_t involuntary_switches = 0;
		struct afs_rq2_thread_snapshot *resized;
		struct afs_rq2_thread_snapshot *thread;
		int snapshot_ret;

		errno = 0;
		entry = readdir(directory);
		if (!entry) {
			if (errno)
				ret = -errno;
			break;
		}
		if (entry->d_name[0] == '.')
			continue;
		errno = 0;
		parsed_tid = strtol(entry->d_name, &end, 10);
		if (errno || !end || *end || parsed_tid <= 0 ||
		    parsed_tid > INT_MAX) {
			ret = -EINVAL;
			break;
		}
		snapshot_ret = parse_thread_snapshot(
			pid, (pid_t)parsed_tid, &runtime_ns, &runqueue_wait_ns,
			&timeslices, &voluntary_switches,
			&involuntary_switches);
		if (snapshot_ret) {
			ret = snapshot_ret;
			break;
		}
		if (snapshot->thread_count == UINT32_MAX) {
			ret = -EOVERFLOW;
			break;
		}
		resized = realloc(
			snapshot->threads,
			((size_t)snapshot->thread_count + 1) * sizeof(*resized));
		if (!resized) {
			ret = -ENOMEM;
			break;
		}
		snapshot->threads = resized;
		thread = &snapshot->threads[snapshot->thread_count++];
		*thread = (struct afs_rq2_thread_snapshot) {
			.tid = (pid_t)parsed_tid,
			.runtime_ns = runtime_ns,
			.runqueue_wait_ns = runqueue_wait_ns,
			.timeslices = timeslices,
			.voluntary_context_switches = voluntary_switches,
			.involuntary_context_switches = involuntary_switches,
		};
	}
	if (closedir(directory) && !ret)
		ret = -errno;
	if (ret || !snapshot->thread_count) {
		afs_rq2_free_process_snapshot(snapshot);
		return ret ? ret : -ESRCH;
	}
	return 0;
}

int afs_rq2_emit_captured_process_snapshot(
	FILE *out, const char *mechanism, const char *role, const char *phase,
	const struct afs_rq2_process_snapshot *snapshot)
{
	if (!snapshot->threads || !snapshot->thread_count)
		return -EINVAL;
	for (uint32_t index = 0; index < snapshot->thread_count; index++) {
		const struct afs_rq2_thread_snapshot *thread =
			&snapshot->threads[index];

		fprintf(out,
			"{\"event\":\"application-file-sharing-rq2-thread\","
			"\"mechanism\":\"%s\",\"role\":\"%s\","
			"\"phase\":\"%s\",\"pid\":%jd,\"tid\":%jd,"
			"\"runtime_ns\":%" PRIu64 ","
			"\"runqueue_wait_ns\":%" PRIu64 ","
			"\"timeslices\":%" PRIu64 ","
			"\"voluntary_context_switches\":%" PRIu64 ","
			"\"involuntary_context_switches\":%" PRIu64 "}\n",
			mechanism, role, phase, (intmax_t)snapshot->pid,
			(intmax_t)thread->tid, thread->runtime_ns,
			thread->runqueue_wait_ns, thread->timeslices,
			thread->voluntary_context_switches,
			thread->involuntary_context_switches);
	}
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-process-snapshot\","
		"\"mechanism\":\"%s\",\"role\":\"%s\","
		"\"phase\":\"%s\",\"pid\":%jd,\"threads\":%" PRIu32 ","
		"\"errno\":0,\"pass\":true}\n",
		mechanism, role, phase, (intmax_t)snapshot->pid,
		snapshot->thread_count);
	fflush(out);
	return ferror(out) ? -EIO : 0;
}

void afs_rq2_free_process_snapshot(struct afs_rq2_process_snapshot *snapshot)
{
	free(snapshot->threads);
	memset(snapshot, 0, sizeof(*snapshot));
}

int afs_rq2_emit_process_snapshot(FILE *out, const char *mechanism,
				  const char *role, const char *phase,
				  pid_t pid)
{
	struct afs_rq2_process_snapshot snapshot;
	int ret;

	ret = afs_rq2_capture_process_snapshot(&snapshot, pid);
	if (!ret)
		ret = afs_rq2_emit_captured_process_snapshot(
			out, mechanism, role, phase, &snapshot);
	afs_rq2_free_process_snapshot(&snapshot);
	return ret;
}

void afs_rq2_emit_ack(FILE *out, const char *mechanism,
		      const char *operation, uint64_t latency_ns,
		      int operation_ret)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-rq2-control\","
		"\"mechanism\":\"%s\",\"operation\":\"%s\","
		"\"latency_ns\":%" PRIu64 ",\"errno\":%d,\"pass\":%s}\n",
		mechanism, operation, latency_ns,
		operation_ret ? -operation_ret : 0,
		operation_ret ? "false" : "true");
	fflush(out);
}
