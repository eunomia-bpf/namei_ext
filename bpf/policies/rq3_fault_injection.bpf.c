// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum rq3_fault_mode {
	RQ3_FAULT_PASS = 0,
	RQ3_FAULT_REDIRECT_LEN_ZERO = 1,
	RQ3_FAULT_REDIRECT_LEN_65 = 2,
	RQ3_FAULT_REDIRECT_DOT = 3,
	RQ3_FAULT_REDIRECT_DOT_DOT = 4,
	RQ3_FAULT_REDIRECT_SLASH = 5,
	RQ3_FAULT_REDIRECT_EMBEDDED_NUL = 6,
	RQ3_FAULT_TARGET_ZERO = 7,
	RQ3_FAULT_TARGET_UNREGISTERED = 8,
	RQ3_FAULT_SELECT_READDIR = 9,
	RQ3_FAULT_SELECT_CREATE = 10,
	RQ3_FAULT_SELECT_FINAL_OPEN = 11,
	RQ3_FAULT_REDIRECT_CREATE = 12,
};

#define RQ3_UNREGISTERED_TARGET_ID 0xffffffffU

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__type(value, __u32);
} rq3_fault_mode SEC(".maps");

static __inline int emit_redirect_fault(struct bpf_namei_ext_ctx *ctx,
					__u32 mode)
{
	switch (mode) {
	case RQ3_FAULT_REDIRECT_LEN_ZERO:
		ctx->redirect_name_len = 0;
		break;
	case RQ3_FAULT_REDIRECT_LEN_65:
		ctx->redirect_name_len = BPF_NAMEI_EXT_NAME_MAX + 1;
		ctx->redirect_name[0] = 'x';
		break;
	case RQ3_FAULT_REDIRECT_DOT:
		ctx->redirect_name_len = 1;
		ctx->redirect_name[0] = '.';
		break;
	case RQ3_FAULT_REDIRECT_DOT_DOT:
		ctx->redirect_name_len = 2;
		ctx->redirect_name[0] = '.';
		ctx->redirect_name[1] = '.';
		break;
	case RQ3_FAULT_REDIRECT_SLASH:
		ctx->redirect_name_len = 3;
		ctx->redirect_name[0] = 'a';
		ctx->redirect_name[1] = '/';
		ctx->redirect_name[2] = 'b';
		break;
	case RQ3_FAULT_REDIRECT_EMBEDDED_NUL:
		ctx->redirect_name_len = 3;
		ctx->redirect_name[0] = 'a';
		ctx->redirect_name[1] = '\0';
		ctx->redirect_name[2] = 'b';
		break;
	default:
		return BPF_NAMEI_EXT_PASS;
	}
	return BPF_NAMEI_EXT_REDIRECT;
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	__u32 key = 0;
	__u32 *mode;

	mode = bpf_map_lookup_elem(&rq3_fault_mode, &key);
	if (!mode || *mode == RQ3_FAULT_PASS)
		return BPF_NAMEI_EXT_PASS;

	if (*mode == RQ3_FAULT_SELECT_READDIR) {
		if (ctx->event == BPF_NAMEI_EXT_READDIR)
			return BPF_NAMEI_EXT_SELECT_TARGET;
		return BPF_NAMEI_EXT_PASS;
	}

	if (*mode >= RQ3_FAULT_REDIRECT_LEN_ZERO &&
	    *mode <= RQ3_FAULT_REDIRECT_EMBEDDED_NUL) {
		if (!namei_ext_is(ctx, "rq3_redirect"))
			return BPF_NAMEI_EXT_PASS;
		return emit_redirect_fault(ctx, *mode);
	}

	if (ctx->event != BPF_NAMEI_EXT_LOOKUP)
		return BPF_NAMEI_EXT_PASS;

	if (*mode == RQ3_FAULT_TARGET_ZERO &&
	    namei_ext_is(ctx, "rq3_target")) {
		ctx->target_id = 0;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	if (*mode == RQ3_FAULT_TARGET_UNREGISTERED &&
	    namei_ext_is(ctx, "rq3_target")) {
		ctx->target_id = RQ3_UNREGISTERED_TARGET_ID;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	if (*mode == RQ3_FAULT_SELECT_CREATE &&
	    namei_ext_is(ctx, "rq3_select_create")) {
		ctx->target_id = 1;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	if (*mode == RQ3_FAULT_SELECT_FINAL_OPEN &&
	    namei_ext_is(ctx, "rq3_select_open")) {
		ctx->target_id = 1;
		return BPF_NAMEI_EXT_SELECT_TARGET;
	}

	if (*mode == RQ3_FAULT_REDIRECT_CREATE &&
	    namei_ext_is(ctx, "rq3_redirect_create")) {
		namei_ext_redirect_literal(ctx, "redirected_create");
		return BPF_NAMEI_EXT_REDIRECT;
	}

	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
