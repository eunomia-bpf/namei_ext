// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum configmap_publication_counter {
	CONFIGMAP_COUNTER_TOTAL = 0,
	CONFIGMAP_COUNTER_LOOKUP = 1,
	CONFIGMAP_COUNTER_READDIR = 2,
	CONFIGMAP_COUNTER_SELECT = 3,
	CONFIGMAP_COUNTER_PASS = 4,
	CONFIGMAP_COUNTER_HIDE = 5,
	CONFIGMAP_COUNTER_MAX = 6,
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} configmap_publication_v0_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} configmap_publication_v1_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, 64);
	__type(key, __u64);
	__type(value, __u32);
} configmap_publication_generations SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, CONFIGMAP_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} configmap_publication_counters SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&configmap_publication_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	__u64 cgroup_id = ctx->cgroup_id;
	__u32 *generation;
	__u32 *target_id;

	generation = bpf_map_lookup_elem(&configmap_publication_generations,
					 &cgroup_id);
	if (!generation)
		return BPF_NAMEI_EXT_PASS;

	count_event(CONFIGMAP_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_event(CONFIGMAP_COUNTER_LOOKUP);
	else if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_event(CONFIGMAP_COUNTER_READDIR);

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	if (*generation)
		target_id = bpf_map_lookup_elem(&configmap_publication_v1_views,
					       &key);
	else
		target_id = bpf_map_lookup_elem(&configmap_publication_v0_views,
					       &key);
	if (!target_id) {
		count_event(CONFIGMAP_COUNTER_PASS);
		return BPF_NAMEI_EXT_PASS;
	}
	if (!*target_id) {
		count_event(CONFIGMAP_COUNTER_HIDE);
		return BPF_NAMEI_EXT_HIDE;
	}
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP) {
		ctx->target_id = *target_id;
		count_event(CONFIGMAP_COUNTER_SELECT);
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	count_event(CONFIGMAP_COUNTER_PASS);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
