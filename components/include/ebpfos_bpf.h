/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef EBPFOS_BPF_H
#define EBPFOS_BPF_H

#ifndef __u8
typedef unsigned char __u8;
typedef unsigned short __u16;
typedef unsigned int __u32;
typedef unsigned long long __u64;
typedef signed int __s32;
typedef signed long long __s64;
#endif

#define SEC(_name) __attribute__((section(_name), used))
#define EBPFOS_MAX_ARGS 6
#define EBPFOS_ACTION_SHIFT 28U
#define EBPFOS_ACTION_PAYLOAD_MASK 0x0fffffffU

#define EBPFOS_CONTINUE(_payload) \
	((0U << EBPFOS_ACTION_SHIFT) | ((__u32)(_payload) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_DENY(_errno) \
	((1U << EBPFOS_ACTION_SHIFT) | ((__u32)(_errno) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_REDIRECT(_target) \
	((2U << EBPFOS_ACTION_SHIFT) | ((__u32)(_target) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_OVERRIDE(_value) \
	((3U << EBPFOS_ACTION_SHIFT) | ((__u32)(_value) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_FALLBACK() (4U << EBPFOS_ACTION_SHIFT)

/* Layout passed directly to raw-tracepoint-compatible programs. */
struct ebpfos_bpf_ctx {
	__u64 hook_id;
	__u64 generation;
	__u64 nr_args;
	__u64 args[EBPFOS_MAX_ARGS];
};

static __inline __attribute__((always_inline)) __u64
argument(const struct ebpfos_bpf_ctx *ctx, __u32 index)
{
	return index < ctx->nr_args && index < EBPFOS_MAX_ARGS ? ctx->args[index] : 0;
}

#endif
