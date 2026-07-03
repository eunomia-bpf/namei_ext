// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

#ifndef __always_inline
#define __always_inline inline __attribute__((always_inline))
#endif

enum cache_state {
	CACHE_STATE_VERIFIED_HIT = 1,
	CACHE_STATE_MISS = 2,
	CACHE_STATE_STALE = 3,
	CACHE_STATE_CORRUPT = 4,
	CACHE_STATE_PASSTHROUGH = 5,
};

#define CACHE_LOCAL_SUFFIX_LEN 6
#define CACHE_CCACHE_OBJECT_LEN 32
#define CACHE_PARENT_NAME_WITNESSES 4
#define CACHE_NAME_HASH_OFFSET 1469598103934665603ULL
#define CACHE_NAME_HASH_PRIME 1099511628211ULL

struct cache_rule {
	struct namei_ext_redirect_rule verified_hit;
	struct namei_ext_redirect_rule canonical;
	struct namei_ext_redirect_rule reject;
	__u64 expected_hash[4];
	__u64 observed_hash[4];
	__u32 state;
	__u32 witness_count;
};

struct cache_epoch_session {
	__u32 cache_epoch;
	__u32 active;
	__u32 reserved[2];
};

struct cache_epoch_rule_key {
	struct namei_ext_component_key component;
	__u32 cache_epoch;
};

struct cache_epoch_rule {
	struct namei_ext_redirect_rule redirect;
	__u32 state;
	__u32 reserved;
};

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct namei_ext_component_key);
	__type(value, struct cache_rule);
} cache_rules SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_STATE);
	__type(key, __u64);
	__type(value, struct cache_epoch_session);
} cache_epoch_sessions SEC(".maps");

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct cache_epoch_rule_key);
	__type(value, struct cache_epoch_rule);
} cache_epoch_rules SEC(".maps");

static __always_inline void cache_build_parent_component_key(
	const struct bpf_namei_ext_ctx *ctx,
	struct namei_ext_component_key *key)
{
	key->event = ctx->event;
	key->name_len = 0;
	key->cgroup_id = ctx->cgroup_id;
	key->parent_dev = ctx->parent_dev;
	key->parent_ino = ctx->parent_ino;
}

static __always_inline int cache_hash_witness_ok(const struct cache_rule *rule)
{
	if (rule->witness_count > 0 &&
	    rule->expected_hash[0] != rule->observed_hash[0])
		return 0;
	if (rule->witness_count > 1 &&
	    rule->expected_hash[1] != rule->observed_hash[1])
		return 0;
	if (rule->witness_count > 2 &&
	    rule->expected_hash[2] != rule->observed_hash[2])
		return 0;
	if (rule->witness_count > 3 &&
	    rule->expected_hash[3] != rule->observed_hash[3])
		return 0;
	return 1;
}

static __always_inline __u64
cache_component_name_hash(const struct bpf_namei_ext_ctx *ctx)
{
	__u64 hash = CACHE_NAME_HASH_OFFSET;
	__u32 i;

#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX; i++) {
		if (i < ctx->name_len) {
			hash ^= ctx->name[i];
			hash *= CACHE_NAME_HASH_PRIME;
		}
	}
	return hash;
}

static __always_inline int
cache_parent_name_witness_ok(const struct bpf_namei_ext_ctx *ctx,
			     const struct cache_rule *rule)
{
	__u64 hash;

	if (!rule->witness_count ||
	    rule->witness_count > CACHE_PARENT_NAME_WITNESSES)
		return 0;
	hash = cache_component_name_hash(ctx);
	if (rule->witness_count > 0 && rule->expected_hash[0] == hash)
		return 1;
	if (rule->witness_count > 1 && rule->expected_hash[1] == hash)
		return 1;
	if (rule->witness_count > 2 && rule->expected_hash[2] == hash)
		return 1;
	if (rule->witness_count > 3 && rule->expected_hash[3] == hash)
		return 1;
	return 0;
}

static __always_inline int cache_name_is_stats(const struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->name_len != 5)
		return 0;
	return ctx->name[0] == 's' && ctx->name[1] == 't' &&
	       ctx->name[2] == 'a' && ctx->name[3] == 't' &&
	       ctx->name[4] == 's';
}

static __always_inline int cache_char_is_lower_alnum(__u8 c)
{
	return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z');
}

static __always_inline int
cache_name_is_ccache_object(const struct bpf_namei_ext_ctx *ctx)
{
	__u32 i;

	if (ctx->name_len != CACHE_CCACHE_OBJECT_LEN)
		return 0;
#pragma clang loop unroll(full)
	for (i = 0; i < CACHE_CCACHE_OBJECT_LEN - 1; i++) {
		if (!cache_char_is_lower_alnum(ctx->name[i]))
			return 0;
	}
	if (ctx->name[CACHE_CCACHE_OBJECT_LEN - 1] != 'M' &&
	    ctx->name[CACHE_CCACHE_OBJECT_LEN - 1] != 'R')
		return 0;
	return 1;
}

static __always_inline int
cache_name_has_local_suffix(const struct bpf_namei_ext_ctx *ctx)
{
	__u32 i;

	if (ctx->name_len <= CACHE_LOCAL_SUFFIX_LEN)
		return 0;
#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX - CACHE_LOCAL_SUFFIX_LEN; i++) {
		if (ctx->name_len == i + CACHE_LOCAL_SUFFIX_LEN &&
		    ctx->name[i] == '.' && ctx->name[i + 1] == 'l' &&
		    ctx->name[i + 2] == 'o' && ctx->name[i + 3] == 'c' &&
		    ctx->name[i + 4] == 'a' && ctx->name[i + 5] == 'l')
			return 1;
	}
	return 0;
}

static __always_inline __u8 cache_local_suffix(__u32 idx)
{
	if (idx == 0)
		return '.';
	if (idx == 1)
		return 'l';
	if (idx == 2)
		return 'o';
	if (idx == 3)
		return 'c';
	if (idx == 4)
		return 'a';
	if (idx == 5)
		return 'l';
	return 0;
}

static __always_inline int
cache_lookup_parent_rule(struct bpf_namei_ext_ctx *ctx,
			 const struct cache_rule *rule)
{
	__u32 i;

	if (rule->state != CACHE_STATE_VERIFIED_HIT)
		return BPF_NAMEI_EXT_PASS;
	if (ctx->name_len > BPF_NAMEI_EXT_NAME_MAX - CACHE_LOCAL_SUFFIX_LEN)
		return BPF_NAMEI_EXT_PASS;
	if (cache_name_is_stats(ctx))
		return BPF_NAMEI_EXT_PASS;
	if (!cache_name_is_ccache_object(ctx))
		return BPF_NAMEI_EXT_PASS;
	if (cache_name_has_local_suffix(ctx))
		return BPF_NAMEI_EXT_PASS;
	if (!cache_parent_name_witness_ok(ctx, rule))
		return BPF_NAMEI_EXT_PASS;

	ctx->redirect_name_len = ctx->name_len + CACHE_LOCAL_SUFFIX_LEN;
#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX; i++) {
		if (i < ctx->name_len) {
			ctx->redirect_name[i] = ctx->name[i];
		} else if (i < ctx->name_len + CACHE_LOCAL_SUFFIX_LEN) {
			__u32 suffix_idx = i - ctx->name_len;

			ctx->redirect_name[i] = cache_local_suffix(suffix_idx);
		}
	}
	return BPF_NAMEI_EXT_REDIRECT;
}

static __always_inline int apply_cache_parent_rule(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct cache_rule *rule;

	cache_build_parent_component_key(ctx, &key);
	rule = bpf_map_lookup_elem(&cache_rules, &key);
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		return cache_lookup_parent_rule(ctx, rule);
	return BPF_NAMEI_EXT_PASS;
}

static __always_inline int apply_cache_epoch_rule(struct bpf_namei_ext_ctx *ctx)
{
	struct cache_epoch_rule_key key = {};
	struct cache_epoch_session *session;
	struct cache_epoch_rule *rule;
	__u64 cgroup_id = ctx->cgroup_id;

	session = bpf_map_lookup_elem(&cache_epoch_sessions, &cgroup_id);
	if (!session || !session->active)
		return BPF_NAMEI_EXT_PASS;
	namei_ext_build_component_key(ctx, &key.component);
	key.cache_epoch = session->cache_epoch;
	rule = bpf_map_lookup_elem(&cache_epoch_rules, &key);
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	return namei_ext_apply_rule(ctx, &rule->redirect);
}

static __inline int apply_cache_rule(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct cache_rule *rule;
	int ret;

	ret = apply_cache_epoch_rule(ctx);
	if (ret != BPF_NAMEI_EXT_PASS)
		return ret;

	namei_ext_build_component_key(ctx, &key);
	rule = bpf_map_lookup_elem(&cache_rules, &key);
	if (!rule)
		return apply_cache_parent_rule(ctx);

	if (rule->state == CACHE_STATE_VERIFIED_HIT &&
	    cache_hash_witness_ok(rule))
		return namei_ext_apply_rule(ctx, &rule->verified_hit);
	if (rule->state == CACHE_STATE_STALE ||
	    rule->state == CACHE_STATE_MISS)
		return namei_ext_apply_rule(ctx, &rule->canonical);
	if (rule->state == CACHE_STATE_CORRUPT || !cache_hash_witness_ok(rule))
		return namei_ext_apply_rule(ctx, &rule->reject);
	ret = apply_cache_parent_rule(ctx);
	if (ret != BPF_NAMEI_EXT_PASS)
		return ret;
	return BPF_NAMEI_EXT_PASS;
}

static __inline int cache_lookup(struct bpf_namei_ext_ctx *ctx)
{
	int ret = apply_cache_rule(ctx);

	if (ret != BPF_NAMEI_EXT_PASS)
		return ret;
	if (namei_ext_is(ctx, "object.o")) {
		namei_ext_redirect_literal(ctx, "object.local");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "pkg.mod")) {
		namei_ext_redirect_literal(ctx, "pkg.canon");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "stale.o")) {
		namei_ext_redirect_literal(ctx, "stale.canon");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "corrupt.o")) {
		namei_ext_redirect_literal(ctx, "corrupt.reject");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return BPF_NAMEI_EXT_PASS;
}

static __inline int cache_readdir(struct bpf_namei_ext_ctx *ctx)
{
	int ret = apply_cache_rule(ctx);

	if (ret != BPF_NAMEI_EXT_PASS)
		return ret;
	if (namei_ext_is(ctx, "object.local")) {
		namei_ext_redirect_literal(ctx, "object.o");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "pkg.canon")) {
		namei_ext_redirect_literal(ctx, "pkg.mod");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "stale.canon")) {
		namei_ext_redirect_literal(ctx, "stale.o");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	if (namei_ext_is(ctx, "corrupt.reject")) {
		namei_ext_redirect_literal(ctx, "corrupt.o");
		return BPF_NAMEI_EXT_REDIRECT;
	}
	return BPF_NAMEI_EXT_PASS;
}

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	if (ctx->event == BPF_NAMEI_EXT_LOOKUP)
		return cache_lookup(ctx);
	if (ctx->event == BPF_NAMEI_EXT_READDIR)
		return cache_readdir(ctx);
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
