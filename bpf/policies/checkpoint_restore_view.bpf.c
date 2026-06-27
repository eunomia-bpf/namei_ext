// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

enum checkpoint_path_class {
	CHECKPOINT_CLASS_STATE = 1,
	CHECKPOINT_CLASS_CONFIG = 2,
	CHECKPOINT_CLASS_CACHE = 3,
	CHECKPOINT_CLASS_RUNTIME = 4,
	CHECKPOINT_CLASS_MIXED_EPOCH = 5,
};

struct checkpoint_session {
	__u32 restore_id;
	__u32 checkpoint_epoch;
	__u32 active;
	__u32 reserved;
};

struct checkpoint_rule_key {
	struct namei_ext_component_key component;
	__u32 path_class;
	__u32 checkpoint_epoch;
};

struct checkpoint_rule {
	struct namei_ext_redirect_rule redirect;
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, __u64);
	__type(value, struct checkpoint_session);
} checkpoint_sessions SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct checkpoint_rule_key);
	__type(value, struct checkpoint_rule);
} checkpoint_rules SEC(".maps");

static __inline __u32 checkpoint_epoch(struct bpf_namei_ext_ctx *ctx)
{
	struct checkpoint_session *session;
	__u64 key = ctx->cgroup_id;

	session = bpf_map_lookup_elem(&checkpoint_sessions, &key);
	if (!session || !session->active)
		return 1;
	return session->checkpoint_epoch;
}

static __inline int apply_checkpoint_rule(struct bpf_namei_ext_ctx *ctx,
					  __u32 path_class)
{
	struct checkpoint_rule_key key = {};
	struct checkpoint_rule *rule;

	namei_ext_build_component_key(ctx, &key.component);
	key.path_class = path_class;
	key.checkpoint_epoch = checkpoint_epoch(ctx);
	rule = bpf_map_lookup_elem(&checkpoint_rules, &key);
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	return namei_ext_apply_rule(ctx, &rule->redirect);
}

static __inline int checkpoint_lookup(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "dump.rdb")) {
		namei_ext_redirect_literal(ctx, "dump.ckpt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "appendonly.aof")) {
		namei_ext_redirect_literal(ctx, "aof.ckpt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "nginx.conf")) {
		namei_ext_redirect_literal(ctx, "nginx.ckpt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "cache.db")) {
		namei_ext_redirect_literal(ctx, "cache.ckpt");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "redis.sock")) {
		namei_ext_redirect_literal(ctx, "redis.sock.new");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "nginx.pid")) {
		namei_ext_redirect_literal(ctx, "nginx.pid.new");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "epoch.bad")) {
		namei_ext_redirect_literal(ctx, "poison.epoch");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_STATE) ==
	    BPF_NAMEI_EXT_REDIRECT)
		return BPF_NAMEI_EXT_REDIRECT;
	if (apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_CONFIG) ==
	    BPF_NAMEI_EXT_REDIRECT)
		return BPF_NAMEI_EXT_REDIRECT;
	if (apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_CACHE) ==
	    BPF_NAMEI_EXT_REDIRECT)
		return BPF_NAMEI_EXT_REDIRECT;
	if (apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_RUNTIME) ==
	    BPF_NAMEI_EXT_REDIRECT)
		return BPF_NAMEI_EXT_REDIRECT;
	return apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_MIXED_EPOCH);
}

static __inline int checkpoint_readdir(struct bpf_namei_ext_ctx *ctx)
{
	if (namei_ext_is(ctx, "dump.ckpt")) {
		namei_ext_redirect_literal(ctx, "dump.rdb");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "aof.ckpt")) {
		namei_ext_redirect_literal(ctx, "appendonly.aof");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "nginx.ckpt")) {
		namei_ext_redirect_literal(ctx, "nginx.conf");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "cache.ckpt")) {
		namei_ext_redirect_literal(ctx, "cache.db");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "redis.sock.new")) {
		namei_ext_redirect_literal(ctx, "redis.sock");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "nginx.pid.new")) {
		namei_ext_redirect_literal(ctx, "nginx.pid");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "poison.epoch")) {
		namei_ext_redirect_literal(ctx, "epoch.bad");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return apply_checkpoint_rule(ctx, CHECKPOINT_CLASS_STATE);
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		return checkpoint_lookup(ctx);
	if (ctx->event == BPF_NAMEI_EXT_READDIR)
		return checkpoint_readdir(ctx);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
