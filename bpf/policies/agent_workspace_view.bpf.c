// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum agent_workspace_counter {
	AW_COUNTER_TOTAL = 0,
	AW_COUNTER_LOOKUP = 1,
	AW_COUNTER_READDIR = 2,
	AW_COUNTER_SELECT_WS_LOOKUP = 3,
	AW_COUNTER_HIDE_DELETED_LOOKUP = 4,
	AW_COUNTER_HIDE_DELETED_READDIR = 5,
	AW_COUNTER_PASS = 6,
	AW_COUNTER_MAX = 7,
};

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, AW_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} aw_counters SEC(".maps");

static __inline void count_event(__u32 key)
{
	__u64 *value;

	value = bpf_map_lookup_elem(&aw_counters, &key);
	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	count_event(AW_COUNTER_TOTAL);
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		count_event(AW_COUNTER_LOOKUP);
	if (ctx->event == BPF_NAMEI_EXT_READDIR)
		count_event(AW_COUNTER_READDIR);

	if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
	    namei_ext_is(ctx, "ws")) {
		ctx->target_id = 1;
		count_event(AW_COUNTER_SELECT_WS_LOOKUP);
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	if ((ctx->event == BPF_NAMEI_EXT_LOOKUP ||
	     ctx->event == BPF_NAMEI_EXT_READDIR) &&
	    namei_ext_is(ctx, "deleted.txt")) {
		if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
			count_event(AW_COUNTER_HIDE_DELETED_LOOKUP);
		else
			count_event(AW_COUNTER_HIDE_DELETED_READDIR);
		return BPF_NAMEI_EXT_HIDE;
	}

	count_event(AW_COUNTER_PASS);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
