/* SPDX-License-Identifier: GPL-2.0 */
#ifndef NAMEI_EXT_POLICY_H
#define NAMEI_EXT_POLICY_H

#include "namei_ext.h"

#ifndef BPF_MAP_TYPE_HASH
#define BPF_MAP_TYPE_HASH 1
#endif

#ifndef BPF_MAP_TYPE_ARRAY
#define BPF_MAP_TYPE_ARRAY 2
#endif

#ifndef BPF_ANY
#define BPF_ANY 0
#endif

#ifndef __uint
#define __uint(name, val) int (*name)[val]
#endif

#ifndef __type
#define __type(name, val) typeof(val) *name
#endif

#define NAMEI_EXT_POLICY_MAX_RULES 4096
#define NAMEI_EXT_POLICY_MAX_STATE 256

struct namei_ext_component_key {
	__u32 event;
	__u32 name_len;
	__u64 cgroup_id;
	__u64 parent_dev;
	__u64 parent_ino;
	__u8 name[BPF_NAMEI_EXT_NAME_MAX];
};

struct namei_ext_redirect_rule {
	__u32 action;
	__u32 target_len;
	__u32 branch;
	__u32 flags;
	__u8 target[BPF_NAMEI_EXT_NAME_MAX];
};

#ifndef NAMEI_EXT_POLICY_LAYOUT_ONLY
static void *(*bpf_map_lookup_elem)(const void *map, const void *key) =
	(void *)1;

static __inline void namei_ext_build_component_key(
	const struct bpf_namei_ext_ctx *ctx, struct namei_ext_component_key *key)
{
	__u32 i;

	key->event = ctx->event;
	key->name_len = ctx->name_len;
	key->cgroup_id = ctx->cgroup_id;
	key->parent_dev = ctx->parent_dev;
	key->parent_ino = ctx->parent_ino;
#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX; i++) {
		if (i < ctx->name_len)
			key->name[i] = ctx->name[i];
		else
			key->name[i] = 0;
	}
}

static __inline int namei_ext_name_is(const struct bpf_namei_ext_ctx *ctx,
				      const __u8 *name, __u32 len)
{
	__u32 i;

	if (ctx->name_len != len)
		return 0;
#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX; i++) {
		if (i >= len)
			break;
		if (ctx->name[i] != name[i])
			return 0;
	}
	return 1;
}

static __inline void namei_ext_set_redirect(struct bpf_namei_ext_ctx *ctx,
					    const __u8 *target, __u32 len)
{
	__u32 i;

	ctx->redirect_name_len = len;
#pragma clang loop unroll(full)
	for (i = 0; i < BPF_NAMEI_EXT_NAME_MAX; i++) {
		if (i < len)
			ctx->redirect_name[i] = target[i];
	}
}

static __inline int namei_ext_apply_rule(struct bpf_namei_ext_ctx *ctx,
					 const struct namei_ext_redirect_rule *rule)
{
	if (!rule)
		return BPF_NAMEI_EXT_PASS;
	if (rule->action != BPF_NAMEI_EXT_REDIRECT)
		return BPF_NAMEI_EXT_PASS;
	namei_ext_set_redirect(ctx, rule->target, rule->target_len);
	return BPF_NAMEI_EXT_REDIRECT;
}

#define namei_ext_is(ctx, literal) \
	namei_ext_name_is((ctx), (const __u8 *)(literal), sizeof(literal) - 1)

#define namei_ext_redirect_literal(ctx, literal) \
	do { \
		static const __u8 __target[] = literal; \
		namei_ext_set_redirect((ctx), __target, sizeof(literal) - 1); \
	} while (0)
#endif /* NAMEI_EXT_POLICY_LAYOUT_ONLY */

#endif /* NAMEI_EXT_POLICY_H */
