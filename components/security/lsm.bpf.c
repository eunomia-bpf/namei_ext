// SPDX-License-Identifier: GPL-2.0-only
#ifdef __EBPFOS_HOST_CHECK__
#include "ebpfos_bpf.h"
SEC("host_check") int ebpfos_lsm_host_check(void *ctx) { return ctx != 0; }
#else
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "GPL";

/* Preserve an earlier LSM denial and otherwise admit the exec. */
SEC("lsm/bprm_check_security")
int BPF_PROG(ebpfos_bprm_check_security, struct linux_binprm *bprm, int ret)
{
	return ret;
}
#endif
