// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* x86-64 getppid(2) = 110. Used only by the VM replacement test. */
SEC("raw_tp/ebpfos_syscall_test")
int syscall_test_override(struct ebpfos_bpf_ctx *ctx)
{
	if (argument(ctx, 0) == 110)
		return EBPFOS_OVERRIDE(4242);
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
