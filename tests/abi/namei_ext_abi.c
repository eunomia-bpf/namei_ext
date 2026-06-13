// SPDX-License-Identifier: GPL-2.0

#include <stddef.h>
#include <stdio.h>

#if defined(NAMEI_EXT_ABI_UAPI)
#include <linux/bpf.h>
#define ABI_HEADER "uapi"
#elif defined(NAMEI_EXT_ABI_BPF)
#include "namei_ext.h"
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
_Static_assert(offsetof(struct bpf_namei_ext_ctx, reserved) == 92,
	       "reserved offset changed");
_Static_assert(offsetof(struct bpf_namei_ext_ctx, redirect_name) == 96,
	       "redirect_name offset changed");
_Static_assert(sizeof(struct bpf_namei_ext_ctx) == 160,
	       "bpf_namei_ext_ctx size changed");

int main(void)
{
	printf("{\"event\":\"abi\",\"name\":\"%s_layout\","
	       "\"pass\":true,\"ctx_size\":%zu,\"name_offset\":%zu,"
	       "\"redirect_name_offset\":%zu,\"name_max\":%u,"
	       "\"detail\":\"PASS/REDIRECT enum values and ctx layout match Phase 1 ABI\"}\n",
	       ABI_HEADER, sizeof(struct bpf_namei_ext_ctx),
	       offsetof(struct bpf_namei_ext_ctx, name),
	       offsetof(struct bpf_namei_ext_ctx, redirect_name),
	       (unsigned int)BPF_NAMEI_EXT_NAME_MAX);
	return 0;
}
