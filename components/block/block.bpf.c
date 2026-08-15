// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: sector, bytes, op flags, block-device pointer. */
SEC("raw_tp/ebpfos_block")
int block_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 bytes = argument(ctx, 1);
	/* Example admission limit; normal I/O falls through to Linux. */
	if (bytes > (128ULL << 20))
		return EBPFOS_DENY(7); /* E2BIG */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
