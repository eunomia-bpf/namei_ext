// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: syscall number, arg0..arg4. Deny reboot/kexec in the example policy. */
SEC("raw_tp/ebpfos_syscall")
int syscall_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 nr = argument(ctx, 0);
	if (nr == 169 || nr == 246 || nr == 320)
		return EBPFOS_DENY(1); /* EPERM */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
