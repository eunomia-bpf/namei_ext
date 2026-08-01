// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum semantic_continuation_counter {
	SC_COUNTER_TOTAL = 0,
	SC_COUNTER_LOOKUP = 1,
	SC_COUNTER_SELECT = 2,
	SC_COUNTER_PASS = 3,
	SC_COUNTER_READDIR = 4,
	SC_COUNTER_MAX = 5,
};

#define SEMANTIC_CONTINUATION_TARGET_MAX 4

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} semantic_continuation_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, SC_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} semantic_continuation_counters SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, SEMANTIC_CONTINUATION_TARGET_MAX);
	__type(key, __u32);
	__type(value, __u64);
} semantic_continuation_target_hits SEC(".maps");

static __inline void count_array(void *map, __u32 key)
{
	__u64 *value = bpf_map_lookup_elem(map, &key);

	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	__u32 *target_id;

	count_array(&semantic_continuation_counters, SC_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_READDIR) {
		count_array(&semantic_continuation_counters,
			    SC_COUNTER_READDIR);
		count_array(&semantic_continuation_counters, SC_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}
	if (ctx->event != BPF_NAMEI_EXT_LOOKUP) {
		count_array(&semantic_continuation_counters, SC_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	count_array(&semantic_continuation_counters, SC_COUNTER_LOOKUP);
	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	target_id = bpf_map_lookup_elem(&semantic_continuation_views, &key);
	if (!target_id || !*target_id ||
	    *target_id >= SEMANTIC_CONTINUATION_TARGET_MAX) {
		count_array(&semantic_continuation_counters, SC_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	ctx->target_id = *target_id;
	count_array(&semantic_continuation_counters, SC_COUNTER_SELECT);
	count_array(&semantic_continuation_target_hits, *target_id);
	return BPF_NAMEI_EXT_SELECT_TARGET;
}

char _license[] SEC("license") = "GPL";
