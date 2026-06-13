// SPDX-License-Identifier: GPL-2.0

#include "namei_ext.h"

static __inline int name_is_tool(const struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->name_len != 4)
		return 0;
	return ctx->name[0] == 't' &&
	       ctx->name[1] == 'o' &&
	       ctx->name[2] == 'o' &&
	       ctx->name[3] == 'l';
}

static __inline int name_is_tool_real(const struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->name_len != 9)
		return 0;
	return ctx->name[0] == 't' &&
	       ctx->name[1] == 'o' &&
	       ctx->name[2] == 'o' &&
	       ctx->name[3] == 'l' &&
	       ctx->name[4] == '.' &&
	       ctx->name[5] == 'r' &&
	       ctx->name[6] == 'e' &&
	       ctx->name[7] == 'a' &&
	       ctx->name[8] == 'l';
}

static __inline void redirect_to_tool(struct bpf_namei_ext_ctx *ctx)
{
	ctx->redirect_name_len = 4;
	ctx->redirect_name[0] = 't';
	ctx->redirect_name[1] = 'o';
	ctx->redirect_name[2] = 'o';
	ctx->redirect_name[3] = 'l';
}

static __inline void redirect_to_tool_real(struct bpf_namei_ext_ctx *ctx)
{
	ctx->redirect_name_len = 9;
	ctx->redirect_name[0] = 't';
	ctx->redirect_name[1] = 'o';
	ctx->redirect_name[2] = 'o';
	ctx->redirect_name[3] = 'l';
	ctx->redirect_name[4] = '.';
	ctx->redirect_name[5] = 'r';
	ctx->redirect_name[6] = 'e';
	ctx->redirect_name[7] = 'a';
	ctx->redirect_name[8] = 'l';
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP && name_is_tool(ctx)) {
		redirect_to_tool_real(ctx);
		return BPF_NAMEI_EXT_REDIRECT;
	}

	if (ctx->event == BPF_NAMEI_EXT_READDIR && name_is_tool_real(ctx)) {
		redirect_to_tool(ctx);
		return BPF_NAMEI_EXT_REDIRECT;
	}

	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
