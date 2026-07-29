// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum build_action_sandboxing_counter {
	BAS_COUNTER_TOTAL = 0,
	BAS_COUNTER_LOOKUP = 1,
	BAS_COUNTER_READDIR = 2,
	BAS_COUNTER_SELECT = 3,
	BAS_COUNTER_ALLOW_LOOKUP = 4,
	BAS_COUNTER_ALLOW_READDIR = 5,
	BAS_COUNTER_HIDE_LOOKUP = 6,
	BAS_COUNTER_HIDE_READDIR = 7,
	BAS_COUNTER_PASS = 8,
	BAS_COUNTER_MAX = 9,
};

#define BUILD_ACTION_ALLOWLIST_MAX_ENTRIES 8192

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} build_action_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} build_action_roots SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, BUILD_ACTION_ALLOWLIST_MAX_ENTRIES);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} build_action_declared_inputs SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, BAS_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} build_action_sandboxing_counters SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&build_action_sandboxing_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct namei_ext_component_key root_key = {};
	__u32 *declared;
	__u32 *root;
	__u32 *target_id;

	count_event(BAS_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_event(BAS_COUNTER_LOOKUP);
	else if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_event(BAS_COUNTER_READDIR);

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;

	root_key.cgroup_id = key.cgroup_id;
	root_key.parent_dev = key.parent_dev;
	root_key.parent_ino = key.parent_ino;
	root = bpf_map_lookup_elem(&build_action_roots, &root_key);
	if (root && *root) {
		declared = bpf_map_lookup_elem(&build_action_declared_inputs,
					       &key);
		if (declared && *declared) {
			if (ctx->event == BPF_NAMEI_EXT_READDIR)
				count_event(BAS_COUNTER_ALLOW_READDIR);
			else
				count_event(BAS_COUNTER_ALLOW_LOOKUP);
			return BPF_NAMEI_EXT_PASS;
		}
		if (ctx->event == BPF_NAMEI_EXT_READDIR)
			count_event(BAS_COUNTER_HIDE_READDIR);
		else
			count_event(BAS_COUNTER_HIDE_LOOKUP);
		return BPF_NAMEI_EXT_HIDE;
	}

	target_id = bpf_map_lookup_elem(&build_action_views, &key);
	if (target_id && *target_id &&
	    ctx->event == BPF_NAMEI_EXT_LOOKUP) {
		ctx->target_id = *target_id;
		count_event(BAS_COUNTER_SELECT);
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	count_event(BAS_COUNTER_PASS);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
