// SPDX-License-Identifier: GPL-2.0

#include "namei_ext_policy.h"

SEC("cgroup/namei_ext")
int namei_ext_policy(struct bpf_namei_ext_ctx *ctx)
{
	return BPF_NAMEI_EXT_PASS;
}

char _license[] SEC("license") = "GPL";
