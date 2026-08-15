// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: requested pages, reclaim priority, gfp mask, NUMA node. */
SEC("raw_tp/ebpfos_mm")
int memory_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 priority = argument(ctx, 1);
	/* Override the current reclaim target; Linux still performs the reclaim. */
	return EBPFOS_OVERRIDE(priority < 4 ? 64 : 16);
}

char LICENSE[] SEC("license") = "GPL";
