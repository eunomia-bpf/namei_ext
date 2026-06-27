// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum sandbox_fixture_branch {
	FIXTURE_BRANCH_CONFIG = 1,
	FIXTURE_BRANCH_SECRET = 2,
	FIXTURE_BRANCH_CERT = 3,
	FIXTURE_BRANCH_ENDPOINT = 4,
	FIXTURE_BRANCH_POISON = 5,
};

struct sandbox_fixture_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 path_class;
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct namei_ext_component_key);
	__type(value, struct sandbox_fixture_rule);
} fixture_rules SEC(".maps");

static __inline int apply_fixture_rule(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct sandbox_fixture_rule *rule;

	namei_ext_build_component_key(ctx, &key);
	rule = bpf_map_lookup_elem(&fixture_rules, &key);
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	return namei_ext_apply_rule(ctx, &rule->redirect);
}

static __inline int fixture_lookup(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "nginx.conf")) {
		namei_ext_redirect_literal(ctx, "nginx.test.conf");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "postgresql.conf")) {
		namei_ext_redirect_literal(ctx, "postgres.test.conf");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "db.password")) {
		namei_ext_redirect_literal(ctx, "db.fake.pass");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "server.crt")) {
		namei_ext_redirect_literal(ctx, "server.fake.crt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "upstream.sock")) {
		namei_ext_redirect_literal(ctx, "upstream.local");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "prod.token")) {
		namei_ext_redirect_literal(ctx, "poison.secret");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return apply_fixture_rule(ctx);
}

static __inline int fixture_readdir(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "nginx.test.conf")) {
		namei_ext_redirect_literal(ctx, "nginx.conf");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "postgres.test.conf")) {
		namei_ext_redirect_literal(ctx, "postgresql.conf");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "db.fake.pass")) {
		namei_ext_redirect_literal(ctx, "db.password");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "server.fake.crt")) {
		namei_ext_redirect_literal(ctx, "server.crt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "upstream.local")) {
		namei_ext_redirect_literal(ctx, "upstream.sock");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "poison.secret")) {
		namei_ext_redirect_literal(ctx, "prod.token");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return apply_fixture_rule(ctx);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		return fixture_lookup(ctx);
	if (ctx->event == BPF_NAMEI_EXT_READDIR)
		return fixture_readdir(ctx);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
