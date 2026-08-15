// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: operation (1=unbind), device pointer, driver pointer. */
SEC("raw_tp/ebpfos_driver_lifecycle")
int driver_lifecycle_component(struct ebpfos_bpf_ctx *ctx)
{
	if (argument(ctx, 0) == 1 && (!argument(ctx, 1) || !argument(ctx, 2)))
		return EBPFOS_DENY(19); /* ENODEV */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
