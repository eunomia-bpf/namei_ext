// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
	    namei_ext_is(ctx, "portal")) {
		ctx->target_id = 1;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
	    namei_ext_is(ctx, "selected-file")) {
		ctx->target_id = 2;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
	    namei_ext_is(ctx, "selected-exec")) {
		ctx->target_id = 3;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP &&
	    namei_ext_is(ctx, "pinned-file")) {
		ctx->target_id = 4;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
