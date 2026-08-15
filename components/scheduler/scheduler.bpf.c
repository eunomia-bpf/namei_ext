// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

/* Generic component ABI example. Production builds use sched_ext struct_ops. */
SEC("raw_tp/ebpfos_sched")
int scheduler_component(struct ebpfos_bpf_ctx *ctx)
{
	__u64 pid = argument(ctx, 0);
	__u64 nr_cpus = argument(ctx, 2);
	if (!nr_cpus)
		return EBPFOS_FALLBACK();
	return EBPFOS_REDIRECT(pid % nr_cpus);
}

char LICENSE[] SEC("license") = "GPL";
