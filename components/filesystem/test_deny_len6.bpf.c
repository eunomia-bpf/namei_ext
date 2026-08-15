// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* VM test component: deny a single pathname component length. */
SEC("raw_tp/ebpfos_vfs_test")
int filesystem_test_deny_len6(struct ebpfos_bpf_ctx *ctx)
{
	if (argument(ctx, 1) == 6)
		return EBPFOS_DENY(13); /* EACCES */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
