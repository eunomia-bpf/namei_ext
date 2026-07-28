// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum service_config_rotation_counter {
	SCR_COUNTER_TOTAL = 0,
	SCR_COUNTER_LOOKUP = 1,
	SCR_COUNTER_READDIR = 2,
	SCR_COUNTER_SELECT = 3,
	SCR_COUNTER_PASS = 4,
	SCR_COUNTER_MAX = 5,
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, struct namei_ext_component_key);
	__type(value, __u32);
} service_config_views SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, SCR_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} service_config_rotation_counters SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, 64);
	__type(key, __u64);
	__type(value, __u8);
} service_config_rotation_cgroups SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&service_config_rotation_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	__u8 *managed;
	__u32 *target_id;

	managed = bpf_map_lookup_elem(&service_config_rotation_cgroups,
				      &ctx->cgroup_id);
	if (!managed || !*managed)
		return BPF_NAMEI_EXT_PASS;

	count_event(SCR_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_event(SCR_COUNTER_LOOKUP);
	else if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_event(SCR_COUNTER_READDIR);

	namei_ext_build_component_key(ctx, &key);
	key.event = 0;
	target_id = bpf_map_lookup_elem(&service_config_views, &key);
	if (target_id && *target_id &&
	    ctx->event == BPF_NAMEI_EXT_LOOKUP) {
		ctx->target_id = *target_id;
		count_event(SCR_COUNTER_SELECT);
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	count_event(SCR_COUNTER_PASS);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
