// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__uint(max_entries, NAMEI_EXT_POLICY_MAX_RULES);
	__type(key, struct namei_ext_component_key);
	__type(value, struct namei_ext_redirect_rule);
} exact_redirects SEC(".maps");

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	struct namei_ext_component_key key = {};
	struct namei_ext_redirect_rule *rule;

	namei_ext_build_component_key(ctx, &key);
	rule = bpf_map_lookup_elem(&exact_redirects, &key);
	return namei_ext_apply_rule(ctx, rule);
}

char _license[] SEC("license") = "GPL";
