// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum build_graph_branch {
	BUILD_BRANCH_GENERATED = 1,
	BUILD_BRANCH_SOURCE_FALLBACK = 2,
	BUILD_BRANCH_TOOLCHAIN = 3,
	BUILD_BRANCH_EXTERNAL_DEP = 4,
	BUILD_BRANCH_UNDECLARED_POISON = 5,
	BUILD_BRANCH_NEGATIVE = 6,
};

struct build_graph_rule {
	struct namei_ext_redirect_rule redirect;
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct namei_ext_component_key);
	__type(value, struct build_graph_rule);
} build_graph_rules SEC(".maps");

static __inline int apply_build_rule(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct build_graph_rule *rule;

	namei_ext_build_component_key(ctx, &key);
	rule = bpf_map_lookup_elem(&build_graph_rules, &key);
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	return namei_ext_apply_rule(ctx, &rule->redirect);
}

static __inline int build_lookup(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "config.h")) {
		namei_ext_redirect_literal(ctx, "config.gen.h");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "version.h")) {
		namei_ext_redirect_literal(ctx, "version.src.h");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "cc")) {
		namei_ext_redirect_literal(ctx, "cc.real");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "libssl.so")) {
		namei_ext_redirect_literal(ctx, "libssl.dep");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "private.h")) {
		namei_ext_redirect_literal(ctx, "poison.dep");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "missing.h"))
		return BPF_NAMEI_EXT_PASS;
	return apply_build_rule(ctx);
}

static __inline int build_readdir(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "config.gen.h")) {
		namei_ext_redirect_literal(ctx, "config.h");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "version.src.h")) {
		namei_ext_redirect_literal(ctx, "version.h");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "cc.real")) {
		namei_ext_redirect_literal(ctx, "cc");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "libssl.dep")) {
		namei_ext_redirect_literal(ctx, "libssl.so");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "poison.dep")) {
		namei_ext_redirect_literal(ctx, "private.h");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return apply_build_rule(ctx);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		return build_lookup(ctx);
	if (ctx->event == BPF_NAMEI_EXT_READDIR)
		return build_readdir(ctx);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
