// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* args: name hash, length, lookup flags, lookup state. */
SEC("raw_tp/ebpfos_vfs_lookup")
int filesystem_lookup_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 length = argument(ctx, 1);
	if (length > 4096)
		return EBPFOS_DENY(36); /* ENAMETOOLONG */
	return EBPFOS_CONTINUE(0);
}

/* args: file pointer, inode pointer, position, f_mode. */
SEC("raw_tp/ebpfos_vfs_readdir")
int filesystem_readdir_component(struct ebpfos_bpf_ctx *ctx)
{
	if (!argument(ctx, 0) || !argument(ctx, 1))
		return EBPFOS_DENY(9); /* EBADF */
	return EBPFOS_CONTINUE(0);
}

char LICENSE[] SEC("license") = "GPL";
