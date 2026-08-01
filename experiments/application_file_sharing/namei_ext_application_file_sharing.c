// SPDX-License-Identifier: GPL-2.0

#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <namei_ext_harness.h>
#include "rq2_measurement.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define DOCUMENT_TARGET_ID 1
#define DOCUMENT_PAYLOAD "xdg-portal-existing-object\n"
#define UNRELATED_PAYLOAD "unrelated-document-object\n"
#define RESULT_LEVEL "kvm_application_file_sharing_rq1"

enum application_file_sharing_counter {
	AFS_COUNTER_TOTAL = 0,
	AFS_COUNTER_LOOKUP = 1,
	AFS_COUNTER_READDIR = 2,
	AFS_COUNTER_SELECT = 3,
	AFS_COUNTER_HIDE_LOOKUP = 4,
	AFS_COUNTER_HIDE_READDIR = 5,
	AFS_COUNTER_PASS = 6,
	AFS_COUNTER_VISIBLE_READDIR = 7,
};

struct probe_paths {
	const char *view;
	const char *document;
	const char *payload;
	const char *host_document;
	const char *host_payload;
	const char *unrelated_payload;
	const char *listed_name;
};

struct state_observation {
	struct stat logical_document;
	struct stat lower_document;
	struct stat logical_payload;
	struct stat lower_payload;
	int move_errno;
	int document_errno;
	int lower_document_errno;
	int payload_stat_errno;
	int payload_read_errno;
	int lower_payload_errno;
	int opendir_errno;
	int readdir_errno;
	int closedir_errno;
	int unrelated_errno;
	bool payload_bytes_expected;
	bool unrelated_bytes_expected;
	bool document_listed;
};

static void emit_case(FILE *out, const char *name, bool pass, int err,
		      const char *detail)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-case\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"case\":\"%s\",\"pass\":%s,\"errno\":%d,"
		"\"detail\":\"%s\"}\n",
		name, pass ? "true" : "false", err, detail);
	fflush(out);
}

static void emit_counter(FILE *out, const char *name,
			 unsigned long long value, bool pass)
{
	fprintf(out,
		"{\"event\":\"application-file-sharing-policy-counter\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"counter\":\"%s\",\"value\":%llu,\"pass\":%s}\n",
		name, value, pass ? "true" : "false");
	fflush(out);
}

static int write_exact(int fd, const void *buffer, size_t length)
{
	const char *cursor = buffer;

	while (length) {
		ssize_t written = write(fd, cursor, length);

		if (written < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		cursor += written;
		length -= (size_t)written;
	}
	return 0;
}

static int read_exact(int fd, void *buffer, size_t length)
{
	char *cursor = buffer;

	while (length) {
		ssize_t bytes = read(fd, cursor, length);

		if (bytes < 0) {
			if (errno == EINTR)
				continue;
			return -errno;
		}
		if (!bytes)
			return -EIO;
		cursor += bytes;
		length -= (size_t)bytes;
	}
	return 0;
}

static int observe_text(const char *path, const char *expected,
			bool *bytes_expected)
{
	char buffer[4096];
	size_t expected_length = strlen(expected);
	size_t offset = 0;
	bool matches = true;
	int fd;

	*bytes_expected = false;
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return errno;
	for (;;) {
		ssize_t bytes = read(fd, buffer, sizeof(buffer));

		if (bytes < 0) {
			int saved_errno = errno;

			if (saved_errno == EINTR)
				continue;
			close(fd);
			return saved_errno;
		}
		if (!bytes)
			break;
		if (offset > expected_length ||
		    (size_t)bytes > expected_length - offset ||
		    memcmp(buffer, expected + offset, (size_t)bytes))
			matches = false;
		if (SIZE_MAX - offset < (size_t)bytes) {
			close(fd);
			return EOVERFLOW;
		}
		offset += (size_t)bytes;
	}
	if (close(fd))
		return errno;
	*bytes_expected = matches && offset == expected_length;
	return 0;
}

static void observe_directory(const char *path, const char *name,
			      struct state_observation *observation)
{
	struct dirent *entry;
	DIR *directory;

	observation->document_listed = false;
	directory = opendir(path);
	if (!directory) {
		observation->opendir_errno = errno;
		return;
	}
	errno = 0;
	while ((entry = readdir(directory))) {
		if (!strcmp(entry->d_name, name))
			observation->document_listed = true;
	}
	observation->readdir_errno = errno;
	if (closedir(directory))
		observation->closedir_errno = errno;
}

static int observe_state(const char *cgroup_path,
			 const struct probe_paths *paths,
			 struct state_observation *observation)
{
	int pipefd[2];
	pid_t pid;
	int ret;

	memset(observation, 0, sizeof(*observation));
	if (pipe2(pipefd, O_CLOEXEC))
		return -errno;
	pid = fork();
	if (pid < 0) {
		ret = -errno;
		close(pipefd[0]);
		close(pipefd[1]);
		return ret;
	}
	if (!pid) {
		struct state_observation child = {};
		int move_ret;

		close(pipefd[0]);
		move_ret = namei_ext_move_self_to_cgroup(cgroup_path);
		if (move_ret)
			child.move_errno = -move_ret;
		if (!child.move_errno) {
			if (stat(paths->document, &child.logical_document))
				child.document_errno = errno;
			if (stat(paths->host_document, &child.lower_document))
				child.lower_document_errno = errno;
			if (stat(paths->payload, &child.logical_payload))
				child.payload_stat_errno = errno;
			child.payload_read_errno = observe_text(
				paths->payload, DOCUMENT_PAYLOAD,
				&child.payload_bytes_expected);
			if (stat(paths->host_payload, &child.lower_payload))
				child.lower_payload_errno = errno;
			observe_directory(paths->view, paths->listed_name, &child);
			child.unrelated_errno = observe_text(
				paths->unrelated_payload, UNRELATED_PAYLOAD,
				&child.unrelated_bytes_expected);
		}
		ret = write_exact(pipefd[1], &child, sizeof(child));
		close(pipefd[1]);
		_exit(ret ? 126 : 0);
	}
	close(pipefd[1]);
	ret = read_exact(pipefd[0], observation, sizeof(*observation));
	close(pipefd[0]);
	if (namei_ext_wait_child(pid) && !ret)
		ret = -ECHILD;
	return ret;
}

static bool same_object(const struct stat *logical,
			const struct stat *lower)
{
	return logical->st_dev == lower->st_dev &&
	       logical->st_ino == lower->st_ino;
}

static bool emit_state(FILE *out, const char *state, bool expected_visible,
		       const struct state_observation *observation,
		       int observation_ret)
{
	bool lower_visible = !observation->lower_document_errno &&
			     !observation->lower_payload_errno;
	bool pass;

	if (expected_visible) {
		pass = !observation_ret && !observation->move_errno &&
		       !observation->document_errno &&
		       !observation->payload_stat_errno &&
		       !observation->payload_read_errno &&
		       !observation->opendir_errno &&
		       !observation->readdir_errno &&
		       !observation->closedir_errno &&
		       !observation->unrelated_errno &&
		       observation->payload_bytes_expected &&
		       observation->unrelated_bytes_expected &&
		       observation->document_listed && lower_visible &&
		       same_object(&observation->logical_document,
				   &observation->lower_document) &&
		       same_object(&observation->logical_payload,
				   &observation->lower_payload);
	} else {
		pass = !observation_ret && !observation->move_errno &&
		       observation->document_errno == ENOENT &&
		       observation->payload_stat_errno == ENOENT &&
		       observation->payload_read_errno == ENOENT &&
		       !observation->opendir_errno &&
		       !observation->readdir_errno &&
		       !observation->closedir_errno &&
		       !observation->unrelated_errno &&
		       !observation->document_listed &&
		       observation->unrelated_bytes_expected && lower_visible;
	}

	fprintf(out,
		"{\"event\":\"application-file-sharing-state\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"state\":\"%s\",\"expected_visible\":%s,"
		"\"observation_errno\":%d,\"move_errno\":%d,"
		"\"document_errno\":%d,"
		"\"payload_stat_errno\":%d,\"payload_read_errno\":%d,"
		"\"opendir_errno\":%d,\"readdir_errno\":%d,"
		"\"closedir_errno\":%d,\"document_listed\":%s,"
		"\"payload_bytes_expected\":%s,"
		"\"unrelated_errno\":%d,"
		"\"unrelated_bytes_expected\":%s,"
		"\"lower_document_errno\":%d,"
		"\"lower_payload_errno\":%d,"
		"\"logical_document_dev\":\"%" PRIuMAX "\","
		"\"logical_document_ino\":\"%" PRIuMAX "\","
		"\"lower_document_dev\":\"%" PRIuMAX "\","
		"\"lower_document_ino\":\"%" PRIuMAX "\","
		"\"logical_payload_dev\":\"%" PRIuMAX "\","
		"\"logical_payload_ino\":\"%" PRIuMAX "\","
		"\"lower_payload_dev\":\"%" PRIuMAX "\","
		"\"lower_payload_ino\":\"%" PRIuMAX "\","
		"\"pass\":%s}\n",
		state, expected_visible ? "true" : "false",
		observation_ret ? -observation_ret : 0,
		observation->move_errno, observation->document_errno,
		observation->payload_stat_errno,
		observation->payload_read_errno,
		observation->opendir_errno, observation->readdir_errno,
		observation->closedir_errno,
		observation->document_listed ? "true" : "false",
		observation->payload_bytes_expected ? "true" : "false",
		observation->unrelated_errno,
		observation->unrelated_bytes_expected ? "true" : "false",
		observation->lower_document_errno,
		observation->lower_payload_errno,
		(uintmax_t)observation->logical_document.st_dev,
		(uintmax_t)observation->logical_document.st_ino,
		(uintmax_t)observation->lower_document.st_dev,
		(uintmax_t)observation->lower_document.st_ino,
		(uintmax_t)observation->logical_payload.st_dev,
		(uintmax_t)observation->logical_payload.st_ino,
		(uintmax_t)observation->lower_payload.st_dev,
		(uintmax_t)observation->lower_payload.st_ino,
		pass ? "true" : "false");
	fflush(out);
	return pass;
}

static bool same_timespec(const struct timespec *left,
			  const struct timespec *right)
{
	return left->tv_sec == right->tv_sec &&
	       left->tv_nsec == right->tv_nsec;
}

static bool same_metadata(const struct stat *before,
			  const struct stat *after)
{
	return before->st_dev == after->st_dev &&
	       before->st_ino == after->st_ino &&
	       before->st_mode == after->st_mode &&
	       before->st_uid == after->st_uid &&
	       before->st_gid == after->st_gid &&
	       before->st_size == after->st_size &&
	       same_timespec(&before->st_mtim, &after->st_mtim) &&
	       same_timespec(&before->st_ctim, &after->st_ctim);
}

static bool emit_lower_object(FILE *out, const struct stat *before,
			      const struct stat *after, int after_errno,
			      bool bytes_expected)
{
	bool metadata_unchanged = !after_errno &&
				  same_metadata(before, after);
	bool pass = metadata_unchanged && bytes_expected;

	fprintf(out,
		"{\"event\":\"application-file-sharing-lower-object\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"object\":\"host-document-payload\","
		"\"after_errno\":%d,"
		"\"before_dev\":\"%" PRIuMAX "\","
		"\"before_ino\":\"%" PRIuMAX "\","
		"\"before_mode\":\"%" PRIoMAX "\","
		"\"before_uid\":%" PRIuMAX ",\"before_gid\":%" PRIuMAX ","
		"\"before_size\":\"%" PRIdMAX "\","
		"\"before_mtime_sec\":\"%" PRIdMAX "\","
		"\"before_mtime_nsec\":%ld,"
		"\"before_ctime_sec\":\"%" PRIdMAX "\","
		"\"before_ctime_nsec\":%ld,"
		"\"after_dev\":\"%" PRIuMAX "\","
		"\"after_ino\":\"%" PRIuMAX "\","
		"\"after_mode\":\"%" PRIoMAX "\","
		"\"after_uid\":%" PRIuMAX ",\"after_gid\":%" PRIuMAX ","
		"\"after_size\":\"%" PRIdMAX "\","
		"\"after_mtime_sec\":\"%" PRIdMAX "\","
		"\"after_mtime_nsec\":%ld,"
		"\"after_ctime_sec\":\"%" PRIdMAX "\","
		"\"after_ctime_nsec\":%ld,"
		"\"metadata_unchanged\":%s,\"bytes_expected\":%s,"
		"\"pass\":%s}\n",
		after_errno,
		(uintmax_t)before->st_dev, (uintmax_t)before->st_ino,
		(uintmax_t)before->st_mode, (uintmax_t)before->st_uid,
		(uintmax_t)before->st_gid, (intmax_t)before->st_size,
		(intmax_t)before->st_mtim.tv_sec, before->st_mtim.tv_nsec,
		(intmax_t)before->st_ctim.tv_sec, before->st_ctim.tv_nsec,
		(uintmax_t)after->st_dev, (uintmax_t)after->st_ino,
		(uintmax_t)after->st_mode, (uintmax_t)after->st_uid,
		(uintmax_t)after->st_gid, (intmax_t)after->st_size,
		(intmax_t)after->st_mtim.tv_sec, after->st_mtim.tv_nsec,
		(intmax_t)after->st_ctim.tv_sec, after->st_ctim.tv_nsec,
		metadata_unchanged ? "true" : "false",
		bytes_expected ? "true" : "false",
		pass ? "true" : "false");
	fflush(out);
	return pass;
}

static int update_grant(struct namei_ext_harness_policy *policy,
			uint64_t cgroup_id,
			const char *parent, const char *name, bool grant)
{
	if (grant)
		return namei_ext_component_map_update(
			policy, "sharing_grants", cgroup_id, parent, name,
			DOCUMENT_TARGET_ID);
	return namei_ext_component_map_delete(
		policy, "sharing_grants", cgroup_id, parent, name);
}

static int register_scope(struct namei_ext_harness_policy *policy,
			  const char *parent, const char *name)
{
	return namei_ext_component_map_update(
		policy, "sharing_scopes", 0, parent, name, 1);
}

static int check_counter(FILE *out,
			 struct namei_ext_harness_policy *policy,
			 const char *name, uint32_t key)
{
	uint64_t value = 0;
	bool pass;
	int ret;

	ret = namei_ext_policy_counter(
		policy, "application_file_sharing_counters", key, &value);
	if (ret)
		return ret;
	pass = value > 0;
	emit_counter(out, name, value, pass);
	return pass ? 0 : -EINVAL;
}

static int record_state(FILE *out, const char *state, bool expected_visible,
			const char *cgroup_path,
			const struct probe_paths *paths)
{
	struct state_observation observation;
	int ret;

	ret = observe_state(cgroup_path, paths, &observation);
	return emit_state(out, state, expected_visible, &observation, ret) ?
	       0 : -EINVAL;
}

static int emit_rq2_policy_snapshot(
	FILE *out, struct namei_ext_harness_policy *policy, const char *phase)
{
	static const char * const names[] = {
		"total", "lookup", "readdir", "select", "hide_lookup",
		"hide_readdir", "pass", "visible_readdir",
	};

	for (uint32_t key = 0; key < sizeof(names) / sizeof(names[0]); key++) {
		uint64_t value = 0;
		int ret = namei_ext_policy_counter(
			policy, "application_file_sharing_counters", key,
			&value);

		if (ret)
			return ret;
		fprintf(out,
			"{\"event\":\"application-file-sharing-rq2-bpf-counter\","
			"\"mechanism\":\"namei_ext\",\"phase\":\"%s\","
			"\"counter\":\"%s\",\"key\":%" PRIu32 ","
			"\"value\":%" PRIu64 "}\n",
			phase, names[key], key, value);
	}
	fflush(out);
	return 0;
}

static int run_rq2_direct_control(FILE *out, const char *root,
				  uint32_t warmup_count,
				  uint32_t sample_count)
{
	char parent[PATH_MAX];
	char document[PATH_MAX];
	char payload[PATH_MAX];
	int parent_fd = -1;
	int ret;

	ret = afs_rq2_join_path(parent, sizeof(parent), root, "direct-ext4");
	if (!ret)
		ret = afs_rq2_join_path(document, sizeof(document), parent,
					AFS_RQ2_DOCUMENT_ID);
	if (!ret)
		ret = afs_rq2_join_path(payload, sizeof(payload), document,
					AFS_RQ2_DOCUMENT_BASENAME);
	if (!ret && mkdir(parent, 0755))
		ret = -errno;
	if (!ret && mkdir(document, 0755))
		ret = -errno;
	if (!ret)
		ret = afs_rq2_write_payload(payload);
	if (!ret) {
		parent_fd = open(parent, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
		if (parent_fd < 0)
			ret = -errno;
	}
	if (!ret)
		ret = afs_rq2_emit_single_oracle(
			out, "namei_ext", "direct-before-warmup", parent_fd,
			AFS_RQ2_DOCUMENT_ID);
	if (!ret)
		ret = afs_rq2_run_warmup(parent_fd, AFS_RQ2_DOCUMENT_ID,
					 warmup_count);
	if (!ret)
		ret = afs_rq2_run_measured(out, "namei_ext", "direct-ext4",
					    parent_fd, AFS_RQ2_DOCUMENT_ID,
					    sample_count);
	if (parent_fd >= 0 && close(parent_fd) && !ret)
		ret = -errno;
	return ret;
}

static int run_rq2_namei_measurement(
	FILE *out, struct namei_ext_harness_policy *policy,
	const char *cgroup_path, const char *cgroup_root, const char *view,
	const char *document_id, uint32_t warmup_count, uint32_t sample_count)
{
	struct afs_rq2_batch batch = {};
	struct afs_rq2_process_snapshot client_before = {};
	struct afs_rq2_process_snapshot client_after = {};
	int parent_fd = -1;
	bool moved = false;
	int ret;
	int cleanup_ret;

	ret = namei_ext_move_self_to_cgroup(cgroup_path);
	if (ret)
		return ret;
	moved = true;
	parent_fd = open(view, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (parent_fd < 0) {
		ret = -errno;
		goto out;
	}
	ret = afs_rq2_emit_single_oracle(
		out, "namei_ext", "first-after-grant", parent_fd, document_id);
	if (!ret)
		ret = afs_rq2_run_warmup(parent_fd, document_id, warmup_count);
	if (!ret)
		ret = emit_rq2_policy_snapshot(out, policy, "before");
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&client_before,
					       getpid());
	if (!ret)
		ret = afs_rq2_collect_measured(
			&batch, parent_fd, document_id, sample_count);
	if (!ret)
		ret = afs_rq2_capture_process_snapshot(&client_after,
					       getpid());
	if (!ret)
		ret = emit_rq2_policy_snapshot(out, policy, "after");
	if (client_before.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "namei_ext", "client", "before", &client_before);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (client_after.thread_count) {
		int emit_ret = afs_rq2_emit_captured_process_snapshot(
			out, "namei_ext", "client", "after", &client_after);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
	if (batch.count) {
		int emit_ret = afs_rq2_emit_batch(
			out, "namei_ext", "policy-view", &batch);

		if (emit_ret && !ret)
			ret = emit_ret;
	}
out:
	afs_rq2_free_batch(&batch);
	afs_rq2_free_process_snapshot(&client_before);
	afs_rq2_free_process_snapshot(&client_after);
	if (parent_fd >= 0 && close(parent_fd) && !ret)
		ret = -errno;
	if (moved) {
		cleanup_ret = namei_ext_move_self_to_cgroup(cgroup_root);
		if (cleanup_ret && !ret)
			ret = cleanup_ret;
	}
	return ret;
}

static int run_rq2_namei_hidden(FILE *out, const char *cgroup_path,
				const char *cgroup_root, const char *view,
				const char *document_id)
{
	int parent_fd = -1;
	bool moved = false;
	int ret;
	int cleanup_ret;

	ret = namei_ext_move_self_to_cgroup(cgroup_path);
	if (ret)
		return ret;
	moved = true;
	parent_fd = open(view, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
	if (parent_fd < 0)
		ret = -errno;
	else
		ret = afs_rq2_emit_hidden_oracle(
			out, "namei_ext", "first-after-revoke", parent_fd,
			document_id);
	if (parent_fd >= 0 && close(parent_fd) && !ret)
		ret = -errno;
	if (moved) {
		cleanup_ret = namei_ext_move_self_to_cgroup(cgroup_root);
		if (cleanup_ret && !ret)
			ret = cleanup_ret;
	}
	return ret;
}

int main(int argc, char **argv)
{
	const char *cgroup_root = "/sys/fs/cgroup";
	const char *document_name = "document";
	struct namei_ext_harness_policy policy = {
		.cgroup_fd = -1,
		.prog_fd = -1,
	};
	char root[PATH_MAX] = {};
	char cgroup_a[PATH_MAX] = {};
	char cgroup_b[PATH_MAX] = {};
	char view[PATH_MAX] = {};
	char document[PATH_MAX] = {};
	char host_document[PATH_MAX] = {};
	char payload[PATH_MAX] = {};
	char host_payload[PATH_MAX] = {};
	char unrelated[PATH_MAX] = {};
	char unrelated_document[PATH_MAX] = {};
	char unrelated_payload[PATH_MAX] = {};
	char saved_host_payload[PATH_MAX] = {};
	char saved_unrelated_payload[PATH_MAX] = {};
	struct probe_paths paths;
	struct stat host_before = {};
	struct stat host_after = {};
	uint64_t app_a_cgroup_id = 0;
	uint32_t rq2_warmup_count = 0;
	uint32_t rq2_sample_count = 0;
	const char *rq2_fixture_root = NULL;
	FILE *out;
	bool rq2_mode = false;
	bool cgroup_a_created = false;
	bool cgroup_b_created = false;
	bool target_registered = false;
	int host_after_errno = 0;
	int fails = 0;
	int ret;

	if (argc != 4 && argc != 5 && argc != 8) {
		fprintf(stderr,
			"usage: %s POLICY_BPF_O RESULT_JSONL RESULT_DIR "
			"[CGROUP_ROOT [RQ2_WARMUP RQ2_SAMPLES "
			"RQ2_EXT4_ROOT]]\n",
			argv[0]);
		return 2;
	}
	if (argc >= 5)
		cgroup_root = argv[4];
	if (argc == 8) {
		rq2_mode = true;
		document_name = AFS_RQ2_DOCUMENT_ID;
		rq2_fixture_root = argv[7];
		if (afs_rq2_parse_count(argv[5], &rq2_warmup_count) ||
		    afs_rq2_parse_count(argv[6], &rq2_sample_count)) {
			fprintf(stderr, "invalid RQ2 warmup or sample count\n");
			return 2;
		}
	}
	if (snprintf(root, sizeof(root), "%s/%s",
		     rq2_mode ? rq2_fixture_root : "/tmp",
		     "namei-ext-app-file-sharing-XXXXXX") >=
	    (int)sizeof(root)) {
		fprintf(stderr, "fixture root path is too long\n");
		return 2;
	}
	out = fopen(argv[2], "a");
	if (!out) {
		perror("fopen result");
		return 2;
	}
	if (!mkdtemp(root)) {
		emit_case(out, "fixture_paths", false, errno,
			  "workspace setup failed");
		fclose(out);
		return 1;
	}
	if (rq2_mode) {
		ret = afs_rq2_emit_filesystem(out, "namei_ext", root);
		if (ret) {
			namei_ext_remove_tree(root);
			fclose(out);
			return 1;
		}
	}
	if (snprintf(cgroup_a, sizeof(cgroup_a),
		     "%s/namei-ext-app-share-a-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_a) ||
	    snprintf(cgroup_b, sizeof(cgroup_b),
		     "%s/namei-ext-app-share-b-%ld", cgroup_root,
		     (long)getpid()) >= (int)sizeof(cgroup_b) ||
	    namei_ext_path_join(view, sizeof(view), root, "view") ||
	    namei_ext_path_join(document, sizeof(document), view,
				document_name) ||
	    namei_ext_path_join(host_document, sizeof(host_document), root,
				"host-document") ||
	    namei_ext_path_join(payload, sizeof(payload), document,
				"payload.txt") ||
	    namei_ext_path_join(host_payload, sizeof(host_payload),
				host_document, "payload.txt") ||
	    namei_ext_path_join(unrelated, sizeof(unrelated), root,
				"unrelated") ||
	    namei_ext_path_join(unrelated_document,
				sizeof(unrelated_document), unrelated,
				"document") ||
	    namei_ext_path_join(unrelated_payload, sizeof(unrelated_payload),
				unrelated_document, "payload.txt") ||
	    namei_ext_path_join(saved_host_payload, sizeof(saved_host_payload),
				argv[3], "lower-document-payload.txt") ||
	    namei_ext_path_join(saved_unrelated_payload,
				sizeof(saved_unrelated_payload), argv[3],
				"unrelated-document-payload.txt")) {
		emit_case(out, "fixture_paths", false, ENAMETOOLONG,
			  "path construction failed");
		fails++;
		goto cleanup;
	}
	if (mkdir(view, 0755) || mkdir(document, 0755) ||
	    mkdir(host_document, 0755) || mkdir(unrelated, 0755) ||
	    mkdir(unrelated_document, 0755) ||
	    namei_ext_write_text(host_payload, DOCUMENT_PAYLOAD) ||
	    namei_ext_write_text(unrelated_payload, UNRELATED_PAYLOAD) ||
	    stat(host_payload, &host_before)) {
		emit_case(out, "fixture_paths", false, errno,
			  "existing host document fixture failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "fixture_paths", true, 0,
		  "logical portal path, host document, and unrelated path created");
	if (rq2_mode) {
		ret = run_rq2_direct_control(out, root, rq2_warmup_count,
					     rq2_sample_count);
		emit_case(out, "rq2_direct_ext4", !ret, ret ? -ret : 0,
			  ret ? "direct ext4 transaction failed" :
			  "direct ext4 transaction completed");
		fails += !!ret;
		if (ret)
			goto cleanup;
	}

	if (mkdir(cgroup_a, 0755)) {
		emit_case(out, "application_identities", false, errno,
			  "application A cgroup failed");
		fails++;
		goto cleanup;
	}
	cgroup_a_created = true;
	if (mkdir(cgroup_b, 0755)) {
		emit_case(out, "application_identities", false, errno,
			  "application B cgroup failed");
		fails++;
		goto cleanup;
	}
	cgroup_b_created = true;
	emit_case(out, "application_identities", true, 0,
		  "two independent application identities created");

	ret = namei_ext_cgroup_id(cgroup_a, &app_a_cgroup_id);
	if (ret) {
		emit_case(out, "application_a_identity", false, -ret,
			  "cgroup identity lookup failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "application_a_identity", true, 0,
		  "application A cgroup identity recorded");

	ret = namei_ext_register_target(cgroup_a, host_document,
					 DOCUMENT_TARGET_ID);
	if (ret) {
		emit_case(out, "register_existing_document", false, -ret,
			  "target registration in application cgroup failed");
		fails++;
		goto cleanup;
	}
	target_registered = true;
	emit_case(out, "register_existing_document", true, 0,
		  "existing host document registered for application A");

	ret = namei_ext_policy_load_attach(argv[1], cgroup_root, &policy);
	if (ret) {
		emit_case(out, "attach_policy", false, errno,
			  "load or attach failed");
		fails++;
		goto cleanup;
	}
	emit_case(out, "attach_policy", true, 0,
		  "policy attached to the cgroup/namei_ext path");
	ret = register_scope(&policy, view, document_name);
	emit_case(out, "register_portal_scope", !ret, ret ? -ret : 0,
		  "policy scoped to the portal parent and logical name");
	fails += !!ret;
	if (ret)
		goto cleanup;

	paths.view = view;
	paths.document = document;
	paths.payload = payload;
	paths.host_document = host_document;
	paths.host_payload = host_payload;
	paths.unrelated_payload = unrelated_payload;
	paths.listed_name = document_name;

	ret = record_state(out, "application-a-before-grant", false,
			   cgroup_a, &paths);
	fails += !!ret;
	ret = record_state(out, "application-b-without-grant", false,
			   cgroup_b, &paths);
	fails += !!ret;

	if (rq2_mode) {
		uint64_t started = afs_rq2_monotonic_raw_ns();

		ret = update_grant(&policy, app_a_cgroup_id, view,
				   document_name, true);
		afs_rq2_emit_ack(out, "namei_ext", "grant",
				 afs_rq2_monotonic_raw_ns() - started, ret);
	} else {
		ret = update_grant(&policy, app_a_cgroup_id, view,
				   document_name, true);
	}
	emit_case(out, "grant_application_a", !ret, ret ? -ret : 0,
		  "grant installed for application A");
	fails += !!ret;
	if (!ret) {
		if (rq2_mode) {
			ret = run_rq2_namei_measurement(
				out, &policy, cgroup_a, cgroup_root, view,
				document_name, rq2_warmup_count,
				rq2_sample_count);
			emit_case(out, "rq2_namei_measurement", !ret,
				  ret ? -ret : 0,
				  ret ? "namei_ext measured transaction failed" :
					  "namei_ext measured transaction completed");
			fails += !!ret;
		}
		if (!ret) {
			ret = record_state(out, "application-a-after-grant", true,
					   cgroup_a, &paths);
			fails += !!ret;
		}
	}
	ret = record_state(out, "application-b-during-a-grant", false,
			   cgroup_b, &paths);
	fails += !!ret;

	if (rq2_mode) {
		uint64_t started = afs_rq2_monotonic_raw_ns();

		ret = update_grant(&policy, app_a_cgroup_id, view,
				   document_name, false);
		afs_rq2_emit_ack(out, "namei_ext", "revoke",
				 afs_rq2_monotonic_raw_ns() - started, ret);
	} else {
		ret = update_grant(&policy, app_a_cgroup_id, view,
				   document_name, false);
	}
	emit_case(out, "revoke_application_a", !ret, ret ? -ret : 0,
		  "grant removed for application A");
	fails += !!ret;
	if (!ret) {
		if (rq2_mode) {
			ret = run_rq2_namei_hidden(
				out, cgroup_a, cgroup_root, view,
				document_name);
			emit_case(out, "rq2_namei_post_revoke", !ret,
				  ret ? -ret : 0,
				  ret ? "post-revoke RQ2 oracle failed" :
					  "post-revoke RQ2 oracle passed");
			fails += !!ret;
		}
		if (!ret) {
			ret = record_state(out, "application-a-after-revoke", false,
					   cgroup_a, &paths);
			fails += !!ret;
		}
	}

	if (stat(host_payload, &host_after))
		host_after_errno = errno;
	if (!emit_lower_object(
		    out, &host_before, &host_after, host_after_errno,
		    !host_after_errno &&
		    namei_ext_read_text_equals(host_payload, DOCUMENT_PAYLOAD)))
		fails++;

	ret = namei_ext_copy_file(host_payload, saved_host_payload);
	if (!ret)
		ret = namei_ext_copy_file(unrelated_payload,
					  saved_unrelated_payload);
	emit_case(out, "preserve_raw_objects", !ret, ret ? -ret : 0,
		  "lower and unrelated payloads saved for host comparison");
	fails += !!ret;

	fails += !!check_counter(out, &policy, "lookup", AFS_COUNTER_LOOKUP);
	fails += !!check_counter(out, &policy, "readdir", AFS_COUNTER_READDIR);
	fails += !!check_counter(out, &policy, "select", AFS_COUNTER_SELECT);
	fails += !!check_counter(out, &policy, "hide_lookup",
				 AFS_COUNTER_HIDE_LOOKUP);
	fails += !!check_counter(out, &policy, "hide_readdir",
				 AFS_COUNTER_HIDE_READDIR);

cleanup:
	if (policy.attached) {
		ret = namei_ext_policy_destroy(&policy);
		emit_case(out, "detach_policy", !ret, ret ? -ret : 0,
			  ret ? "policy detach failed" : "policy detached");
		fails += !!ret;
	} else {
		emit_case(out, "detach_policy", false, ENOENT,
			  "policy was not attached");
		fails++;
	}
	if (target_registered) {
		ret = namei_ext_clear_targets(cgroup_a);
		emit_case(out, "clear_registered_document", !ret,
			  ret ? -ret : 0,
			  ret ? "target registry clear failed" :
			  "application A target registry cleared");
		fails += !!ret;
	} else {
		emit_case(out, "clear_registered_document", false, ENOENT,
			  "target was not registered");
		fails++;
	}
	if (cgroup_a_created) {
		ret = rmdir(cgroup_a);
		emit_case(out, "remove_application_a_cgroup", !ret,
			  ret ? errno : 0,
			  ret ? "application A cgroup removal failed" :
			  "application A cgroup removed");
		fails += !!ret;
	} else {
		emit_case(out, "remove_application_a_cgroup", false, ENOENT,
			  "application A cgroup was not created");
		fails++;
	}
	if (cgroup_b_created) {
		ret = rmdir(cgroup_b);
		emit_case(out, "remove_application_b_cgroup", !ret,
			  ret ? errno : 0,
			  ret ? "application B cgroup removal failed" :
			  "application B cgroup removed");
		fails += !!ret;
	} else {
		emit_case(out, "remove_application_b_cgroup", false, ENOENT,
			  "application B cgroup was not created");
		fails++;
	}
	namei_ext_remove_tree(root);
	if (rq2_mode) {
		fprintf(out,
			"{\"event\":\"application-file-sharing-rq2-summary\","
			"\"mechanism\":\"namei_ext\","
			"\"document_id_bytes\":22,\"payload_bytes\":27,"
			"\"warmup_transactions\":%" PRIu32 ","
			"\"measured_transactions\":%" PRIu32 ","
			"\"direct_transactions\":%" PRIu32 ","
			"\"failures\":%d,\"pass\":%s}\n",
			rq2_warmup_count, rq2_sample_count, rq2_sample_count,
			fails, fails ? "false" : "true");
	}
	fprintf(out,
		"{\"event\":\"application-file-sharing-summary\","
		"\"result_level\":\"" RESULT_LEVEL "\","
		"\"workload\":\"sandboxed-application-file-sharing\","
		"\"source_system\":\"xdg-documents-portal\","
		"\"applications\":2,\"states\":5,"
		"\"pass\":%s,\"failures\":%d}\n",
		fails ? "false" : "true", fails);
	fclose(out);
	return fails ? 1 : 0;
}
