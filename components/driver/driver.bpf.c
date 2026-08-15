// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: device pointer, driver pointer, bus pointer, owner module pointer. */
SEC("raw_tp/ebpfos_driver")
int driver_component(struct ebpfos_bpf_ctx *ctx)
{
	if (!argument(ctx, 0) || !argument(ctx, 1))
		return EBPFOS_DENY(19); /* ENODEV */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
