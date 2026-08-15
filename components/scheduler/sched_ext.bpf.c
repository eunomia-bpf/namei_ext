// SPDX-License-Identifier: GPL-2.0-only
#ifdef __EBPFOS_HOST_CHECK__
#include "ebpfos_bpf.h"
SEC("host_check") int ebpfos_sched_ext_host_check(void *ctx) { return ctx != 0; }
#else
#include <scx/common.bpf.h>

char _license[] SEC("license") = "GPL";

s32 BPF_STRUCT_OPS(ebpfos_select_cpu, struct task_struct *p, s32 prev_cpu,
		   u64 wake_flags)
{
	bool is_idle = false;
	return scx_bpf_select_cpu_dfl(p, prev_cpu, wake_flags, &is_idle);
}

void BPF_STRUCT_OPS(ebpfos_enqueue, struct task_struct *p, u64 enq_flags)
{
	scx_bpf_dsq_insert(p, SCX_DSQ_GLOBAL, SCX_SLICE_DFL, enq_flags);
}

void BPF_STRUCT_OPS(ebpfos_dispatch, s32 cpu, struct task_struct *prev)
{
	scx_bpf_dsq_move_to_local(SCX_DSQ_GLOBAL, 0);
}

void BPF_STRUCT_OPS(ebpfos_sched_exit, struct scx_exit_info *info)
{
}

SCX_OPS_DEFINE(ebpfos_sched_ops,
	       .select_cpu = (void *)ebpfos_select_cpu,
	       .enqueue = (void *)ebpfos_enqueue,
	       .dispatch = (void *)ebpfos_dispatch,
	       .exit = (void *)ebpfos_sched_exit,
	       .name = "ebpfos");
#endif
