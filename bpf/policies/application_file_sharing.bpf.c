// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum application_file_sharing_counter {
	AFS_COUNTER_TOTAL = 0,
	AFS_COUNTER_LOOKUP = 1,
	AFS_COUNTER_READDIR = 2,
	AFS_COUNTER_SELECT = 3,
	AFS_COUNTER_HIDE_LOOKUP = 4,
	AFS_COUNTER_HIDE_READDIR = 5,
	AFS_COUNTER_PASS = 6,
	AFS_COUNTER_VISIBLE_READDIR = 7,
	AFS_COUNTER_MAX = 8,
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} sharing_scopes SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} sharing_grants SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, AFS_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} application_file_sharing_counters SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&application_file_sharing_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct namei_ext_component_key scope_key;
	__u32 *managed;
	__u32 *target_id;

	count_event(AFS_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_event(AFS_COUNTER_LOOKUP);
	else if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_event(AFS_COUNTER_READDIR);

	if (!namei_ext_is(ctx, "document") &&
	    !namei_ext_is(ctx, "namei-fixed-doc-id-001")) {
		count_event(AFS_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	scope_key = key;
	scope_key.cgroup_id = 0;
	managed = bpf_map_lookup_elem(&sharing_scopes, &scope_key);
	if (!managed || !*managed) {
		count_event(AFS_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}

	target_id = bpf_map_lookup_elem(&sharing_grants, &key);
	if (!target_id || !*target_id) {
		if (ctx->event == BPF_NAMEI_EXT_READDIR)
			count_event(AFS_COUNTER_HIDE_READDIR);
		else
			count_event(AFS_COUNTER_HIDE_LOOKUP);
		return BPF_NAMEI_EXT_HIDE;
	}

	if (ctx->event == BPF_NAMEI_EXT_LOOKUP) {
		ctx->target_id = *target_id;
		count_event(AFS_COUNTER_SELECT);
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	count_event(AFS_COUNTER_VISIBLE_READDIR);
	count_event(AFS_COUNTER_PASS);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
