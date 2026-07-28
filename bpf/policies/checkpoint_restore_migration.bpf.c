// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum checkpoint_restore_counter {
	CR_COUNTER_TOTAL = 0,
	CR_COUNTER_LOOKUP = 1,
	CR_COUNTER_SELECT = 2,
	CR_COUNTER_PASS = 3,
	CR_COUNTER_MAX = 4,
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} checkpoint_restore_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, CR_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} checkpoint_restore_counters SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&checkpoint_restore_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	__u32 *target_id;

	count_event(CR_COUNTER_TOTAL);
	if (ctx->event != BPF_NAMEI_EXT_LOOKUP) {
		count_event(CR_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}
	count_event(CR_COUNTER_LOOKUP);

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	target_id = bpf_map_lookup_elem(&checkpoint_restore_views, &key);
	if (!target_id || !*target_id) {
		count_event(CR_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	ctx->target_id = *target_id;
	count_event(CR_COUNTER_SELECT);
	return BPF_NAMEI_EXT_SELECT_TARGET;
}

char _license[] SEC(".license") = "GPL";
