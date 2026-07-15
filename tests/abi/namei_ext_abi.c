// SPDX-License-Identifier: GPL-2.0

#include <stddef.h>
#include <stdio.h>

#if defined(NAMEI_EXT_ABI_UAPI)
#include <linux/bpf.h>
#define ABI_HEADER "uapi"
#elif defined(NAMEI_EXT_ABI_BPF)
#include "namei_ext_policy.h"
#define ABI_HEADER "bpf"
#else
#error "define NAMEI_EXT_ABI_UAPI or NAMEI_EXT_ABI_BPF"
#endif

#if defined(NAMEI_EXT_ABI_UAPI)
_Static_assert(BPF_PROG_TYPE_NAMEI_EXT == 33,
	       "BPF_PROG_TYPE_NAMEI_EXT enum value changed");
_Static_assert(BPF_CGROUP_NAMEI_EXT == 59,
	       "BPF_CGROUP_NAMEI_EXT enum value changed");
#endif

_Static_assert(BPF_NAMEI_EXT_NAME_MAX == 64,
	       "BPF_NAMEI_EXT_NAME_MAX changed");
_Static_assert(BPF_NAMEI_EXT_LOOKUP == 0,
	       "BPF_NAMEI_EXT_LOOKUP enum value changed");
_Static_assert(BPF_NAMEI_EXT_READDIR == 1,
	       "BPF_NAMEI_EXT_READDIR enum value changed");
_Static_assert(BPF_NAMEI_EXT_PASS == 0,
	       "BPF_NAMEI_EXT_PASS enum value changed");
_Static_assert(BPF_NAMEI_EXT_REDIRECT == 1,
	       "BPF_NAMEI_EXT_REDIRECT enum value changed");
_Static_assert(BPF_NAMEI_EXT_HIDE == 2,
	       "BPF_NAMEI_EXT_HIDE enum value changed");
_Static_assert(BPF_NAMEI_EXT_SELECT_TARGET == 3,
	       "BPF_NAMEI_EXT_SELECT_TARGET enum value changed");

_Static_assert(offsetof(struct bpf_namei_ext_ctx, event) == 0,
	       "event offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, flags) == 4,
	       "flags offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, name_len) == 8,
	       "name_len offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, name_hash) == 12,
	       "name_hash offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, cgroup_id) == 16,
	       "cgroup_id offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, name) == 24,
	       "name offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, redirect_name_len) == 88,
	       "redirect_name_len offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, target_id) == 92,
	       "target_id offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, redirect_name) == 96,
	       "redirect_name offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, parent_dev) == 160,
	       "parent_dev offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, parent_ino) == 168,
	       "parent_ino offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, parent_generation) == 176,
	       "parent_generation offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, parent_flags) == 180,
	       "parent_flags offset changed");
_Static_assert(sizeof(struct bpf_namei_ext_ctx) == 184,
	       "bpf_namei_ext_ctx size changed");

#if defined(NAMEI_EXT_ABI_BPF)
_Static_assert(offsetof(struct namei_ext_component_key, event) == 0,
	       "component key event offset changed");
_Static_assert(offsetof(struct namei_ext_component_key, name_len) == 4,
	       "component key name_len offset changed");
_Static_assert(offsetof(struct namei_ext_component_key, cgroup_id) == 8,
	       "component key cgroup_id offset changed");
_Static_assert(offsetof(struct namei_ext_component_key, parent_dev) == 16,
	       "component key parent_dev offset changed");
_Static_assert(offsetof(struct namei_ext_component_key, parent_ino) == 24,
	       "component key parent_ino offset changed");
_Static_assert(offsetof(struct namei_ext_component_key, name) == 32,
	       "component key name offset changed");
_Static_assert(sizeof(struct namei_ext_component_key) == 96,
	       "component key size changed");

_Static_assert(offsetof(struct namei_ext_redirect_rule, action) == 0,
	       "redirect rule action offset changed");
_Static_assert(offsetof(struct namei_ext_redirect_rule, target_len) == 4,
	       "redirect rule target_len offset changed");
_Static_assert(offsetof(struct namei_ext_redirect_rule, branch) == 8,
	       "redirect rule branch offset changed");
_Static_assert(offsetof(struct namei_ext_redirect_rule, flags) == 12,
	       "redirect rule flags offset changed");
_Static_assert(offsetof(struct namei_ext_redirect_rule, target) == 16,
	       "redirect rule target offset changed");
_Static_assert(sizeof(struct namei_ext_redirect_rule) == 80,
	       "redirect rule size changed");
#endif

int main(void)
{
	printf("{\"event\":\"abi\",\"name\":\"%s_layout\","
	       "\"pass\":true,\"ctx_size\":%zu,\"name_offset\":%zu,"
	       "\"redirect_name_offset\":%zu,\"name_max\":%u,"
	       "\"parent_dev_offset\":%zu,\"parent_ino_offset\":%zu,"
	       "\"detail\":\"PASS/REDIRECT/HIDE/SELECT_TARGET enum values and ctx layout match Phase 1 ABI\"}\n",
	       ABI_HEADER, sizeof(struct bpf_namei_ext_ctx),
	       offsetof(struct bpf_namei_ext_ctx, name),
	       offsetof(struct bpf_namei_ext_ctx, redirect_name),
	       (unsigned int)BPF_NAMEI_EXT_NAME_MAX,
	       offsetof(struct bpf_namei_ext_ctx, parent_dev),
	       offsetof(struct bpf_namei_ext_ctx, parent_ino));
	return 0;
}
