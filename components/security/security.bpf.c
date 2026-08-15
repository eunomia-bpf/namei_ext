// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* Generic decision program; production builds bind equivalent logic via BPF LSM. */
SEC("raw_tp/ebpfos_security")
int security_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 operation = argument(ctx, 0);
	__u64 subject = argument(ctx, 1);
	if (operation == 1 && subject == 0)
		return EBPFOS_DENY(13); /* EACCES */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
