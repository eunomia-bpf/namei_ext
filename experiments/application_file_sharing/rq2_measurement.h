/* SPDX-License-Identifier: GPL-2.0 */
#ifndef APPLICATION_FILE_SHARING_RQ2_MEASUREMENT_H
#define APPLICATION_FILE_SHARING_RQ2_MEASUREMENT_H

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/types.h>

#define AFS_RQ2_DOCUMENT_ID "namei-fixed-doc-id-001"
#define AFS_RQ2_DOCUMENT_BASENAME "payload.txt"
#define AFS_RQ2_DOCUMENT_PAYLOAD "xdg-portal-existing-object\n"

struct afs_rq2_transaction {
	uint64_t total_ns;
	uint64_t document_stat_ns;
	uint64_t payload_stat_ns;
	uint64_t open_read_close_ns;
	uint64_t readdir_ns;
	int document_stat_errno;
	int payload_stat_errno;
	int open_errno;
	int read_errno;
	int close_errno;
	int directory_open_errno;
	int getdents_errno;
	int directory_close_errno;
	uint64_t payload_bytes;
	uint32_t directory_entries;
	bool payload_matches;
	bool payload_eof;
	bool dot_seen;
	bool dotdot_seen;
	bool document_seen;
	bool unexpected_entry;
	bool pass;
};

struct afs_rq2_batch {
	struct afs_rq2_transaction *observations;
	uint32_t capacity;
	uint32_t count;
};

struct afs_rq2_thread_snapshot {
	pid_t tid;
	uint64_t runtime_ns;
	uint64_t runqueue_wait_ns;
	uint64_t timeslices;
	uint64_t voluntary_context_switches;
	uint64_t involuntary_context_switches;
};

struct afs_rq2_process_snapshot {
	pid_t pid;
	struct afs_rq2_thread_snapshot *threads;
	uint32_t thread_count;
};

uint64_t afs_rq2_monotonic_raw_ns(void);
int afs_rq2_parse_count(const char *text, uint32_t *value);
int afs_rq2_join_path(char *destination, size_t size,
		      const char *parent, const char *child);
int afs_rq2_write_payload(const char *path);
int afs_rq2_emit_filesystem(FILE *out, const char *mechanism,
			    const char *path);
int afs_rq2_run_transaction(int parent_fd, const char *document_id,
			    struct afs_rq2_transaction *observation);
int afs_rq2_run_warmup(int parent_fd, const char *document_id,
		       uint32_t warmup_count);
int afs_rq2_collect_measured(struct afs_rq2_batch *batch, int parent_fd,
			     const char *document_id, uint32_t sample_count);
int afs_rq2_emit_batch(FILE *out, const char *mechanism,
		       const char *stream, const struct afs_rq2_batch *batch);
void afs_rq2_free_batch(struct afs_rq2_batch *batch);
int afs_rq2_run_measured(FILE *out, const char *mechanism,
			 const char *stream, int parent_fd,
			 const char *document_id, uint32_t sample_count);
int afs_rq2_emit_single_oracle(FILE *out, const char *mechanism,
			      const char *stream, const char *phase, int parent_fd,
			      const char *document_id);
int afs_rq2_emit_hidden_oracle(FILE *out, const char *mechanism,
			      const char *phase, int parent_fd,
			      const char *document_id);
int afs_rq2_capture_process_snapshot(struct afs_rq2_process_snapshot *snapshot,
				     pid_t pid);
int afs_rq2_emit_captured_process_snapshot(
	FILE *out, const char *mechanism, const char *role, const char *phase,
	const struct afs_rq2_process_snapshot *snapshot);
void afs_rq2_free_process_snapshot(struct afs_rq2_process_snapshot *snapshot);
int afs_rq2_emit_process_snapshot(FILE *out, const char *mechanism,
				  const char *role, const char *phase,
				  pid_t pid);
void afs_rq2_emit_ack(FILE *out, const char *mechanism,
		      const char *operation, uint64_t latency_ns,
		      int operation_ret);

#endif
