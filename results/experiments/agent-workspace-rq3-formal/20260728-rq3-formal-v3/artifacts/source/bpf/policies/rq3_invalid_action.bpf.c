// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	return BPF_NAMEI_EXT_SELECT_TARGET + 1;
}

char _license[] SEC("license") = "GPL";
