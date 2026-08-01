// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

#define AFS_RQ2_FUSE_OPCODE_COUNT 64

typedef int __s32;
typedef unsigned short __u16;

struct trace_event_raw_fuse_request_send {
	__u16 common_type;
	__u8 common_flags;
	__u8 common_preempt_count;
	__s32 common_pid;
	__u32 connection;
	__u32 padding;
	__u64 unique;
	__u32 opcode;
	__u32 len;
};

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__type(value, __u32);
} fuse_connection SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, AFS_RQ2_FUSE_OPCODE_COUNT);
	__type(key, __u32);
	__type(value, __u64);
} fuse_opcode_counts SEC(".maps");

SEC("tracepoint/fuse/fuse_request_send")
int count_fuse_request(struct trace_event_raw_fuse_request_send *ctx)
{
	__u32 key = 0;
	__u32 *connection;
	__u64 *count;

	connection = bpf_map_lookup_elem(&fuse_connection, &key);
	if (!connection || ctx->connection != *connection ||
	    ctx->opcode >= AFS_RQ2_FUSE_OPCODE_COUNT)
		return 0;
	key = ctx->opcode;
	count = bpf_map_lookup_elem(&fuse_opcode_counts, &key);
	if (count)
		__sync_fetch_and_add(count, 1);
	return 0;
}

char _license[] SEC("license") = "GPL";
