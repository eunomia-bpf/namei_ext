/* SPDX-License-Identifier: GPL-2.0 */
#ifndef APPLICATION_FILE_SHARING_RQ2_FUSE_COUNTER_H
#define APPLICATION_FILE_SHARING_RQ2_FUSE_COUNTER_H

#include <stdint.h>
#include <stdio.h>

struct bpf_link;
struct bpf_object;

struct afs_rq2_fuse_counter {
	struct bpf_object *object;
	struct bpf_link *link;
	int counts_fd;
	uint32_t connection;
};

int afs_rq2_fuse_counter_open(struct afs_rq2_fuse_counter *counter,
			      const char *object_path,
			      uint32_t connection);
int afs_rq2_fuse_counter_emit(FILE *out,
			      const struct afs_rq2_fuse_counter *counter,
			      const char *phase);
int afs_rq2_fuse_counter_total(
	const struct afs_rq2_fuse_counter *counter, uint64_t *total);
int afs_rq2_fuse_counter_close(struct afs_rq2_fuse_counter *counter);

#endif
