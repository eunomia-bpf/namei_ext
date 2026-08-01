// SPDX-License-Identifier: GPL-2.0

#include "rq2_fuse_counter.h"

#include <bpf/bpf.h>
#include <bpf/libbpf.h>
#include <errno.h>
#include <linux/bpf.h>
#include <string.h>

#define AFS_RQ2_FUSE_OPCODE_COUNT 64

int afs_rq2_fuse_counter_open(struct afs_rq2_fuse_counter *counter,
			      const char *object_path,
			      uint32_t connection)
{
	struct bpf_program *program;
	struct bpf_map *filter_map;
	struct bpf_map *counts_map;
	uint32_t key = 0;
	int ret;

	memset(counter, 0, sizeof(*counter));
	counter->counts_fd = -1;
	counter->object = bpf_object__open_file(object_path, NULL);
	ret = libbpf_get_error(counter->object);
	if (ret) {
		counter->object = NULL;
		return ret;
	}
	filter_map = bpf_object__find_map_by_name(counter->object,
						  "fuse_connection");
	counts_map = bpf_object__find_map_by_name(counter->object,
						  "fuse_opcode_counts");
	if (!filter_map || !counts_map) {
		ret = -ENOENT;
		goto out;
	}
	program = bpf_object__find_program_by_name(counter->object,
						   "count_fuse_request");
	if (!program) {
		ret = -ENOENT;
		goto out;
	}
	ret = bpf_object__load(counter->object);
	if (ret)
		goto out;
	if (bpf_map_update_elem(bpf_map__fd(filter_map), &key, &connection,
				BPF_ANY)) {
		ret = -errno;
		goto out;
	}
	counter->counts_fd = bpf_map__fd(counts_map);
	counter->link = bpf_program__attach_tracepoint(
		program, "fuse", "fuse_request_send");
	ret = libbpf_get_error(counter->link);
	if (ret) {
		counter->link = NULL;
		goto out;
	}
	counter->connection = connection;
	return 0;

out:
	afs_rq2_fuse_counter_close(counter);
	return ret;
}

int afs_rq2_fuse_counter_emit(FILE *out,
			      const struct afs_rq2_fuse_counter *counter,
			      const char *phase)
{
	for (uint32_t opcode = 0; opcode < AFS_RQ2_FUSE_OPCODE_COUNT;
	     opcode++) {
		uint64_t value = 0;

		if (bpf_map_lookup_elem(counter->counts_fd, &opcode, &value))
			return -errno;
		fprintf(out,
			"{\"event\":\"application-file-sharing-rq2-fuse-counter\","
			"\"mechanism\":\"xdg-document-portal\","
			"\"phase\":\"%s\",\"connection\":%u,"
			"\"opcode\":%u,\"value\":%llu}\n",
			phase, counter->connection, opcode,
			(unsigned long long)value);
	}
	fflush(out);
	return 0;
}

int afs_rq2_fuse_counter_total(
	const struct afs_rq2_fuse_counter *counter, uint64_t *total)
{
	uint64_t sum = 0;

	for (uint32_t opcode = 0; opcode < AFS_RQ2_FUSE_OPCODE_COUNT;
	     opcode++) {
		uint64_t value = 0;

		if (bpf_map_lookup_elem(counter->counts_fd, &opcode, &value))
			return -errno;
		if (UINT64_MAX - sum < value)
			return -EOVERFLOW;
		sum += value;
	}
	*total = sum;
	return 0;
}

int afs_rq2_fuse_counter_close(struct afs_rq2_fuse_counter *counter)
{
	int ret = 0;

	if (counter->link) {
		ret = bpf_link__destroy(counter->link);
		counter->link = NULL;
	}
	if (counter->object) {
		bpf_object__close(counter->object);
		counter->object = NULL;
	}
	counter->counts_fd = -1;
	return ret;
}
