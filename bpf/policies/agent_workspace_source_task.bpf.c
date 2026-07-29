// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum agent_source_task_counter {
	AST_COUNTER_TOTAL = 0,
	AST_COUNTER_LOOKUP = 1,
	AST_COUNTER_READDIR = 2,
	AST_COUNTER_SELECT = 3,
	AST_COUNTER_HIDE_LOOKUP = 4,
	AST_COUNTER_HIDE_READDIR = 5,
	AST_COUNTER_PASS = 6,
	AST_COUNTER_MAX = 7,
};

#define AGENT_SOURCE_TASK_TARGET_MAX 5

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} agent_source_task_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, AST_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} agent_source_task_counters SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, AGENT_SOURCE_TASK_TARGET_MAX);
	__type(key, __u32);
	__type(value, __u64);
} agent_source_task_target_hits SEC(".maps");

static __inline void count_array(void *map, __u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(map, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	__u32 *target_id;

	count_array(&agent_source_task_counters, AST_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_array(&agent_source_task_counters, AST_COUNTER_LOOKUP);
	else if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_array(&agent_source_task_counters, AST_COUNTER_READDIR);
	else {
		count_array(&agent_source_task_counters, AST_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	if (!namei_ext_is(ctx, "ws")) {
		count_array(&agent_source_task_counters, AST_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	target_id = bpf_map_lookup_elem(&agent_source_task_views, &key);
	if (!target_id || !*target_id) {
		if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
			count_array(&agent_source_task_counters,
				    AST_COUNTER_HIDE_LOOKUP);
		else
			count_array(&agent_source_task_counters,
				    AST_COUNTER_HIDE_READDIR);
		return BPF_NAMEI_EXT_HIDE;
	}

	if (ctx->event == BPF_NAMEI_EXT_READDIR) {
		count_array(&agent_source_task_counters, AST_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	ctx->target_id = *target_id;
	count_array(&agent_source_task_counters, AST_COUNTER_SELECT);
	if (*target_id < AGENT_SOURCE_TASK_TARGET_MAX)
		count_array(&agent_source_task_target_hits, *target_id);
	return BPF_NAMEI_EXT_SELECT_TARGET;
}

char _license[] SEC("license") = "GPL";
