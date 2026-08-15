// SPDX-License-Identifier: GPL-2.0-only
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

#define EBPFOS_ACTION_SHIFT 28U
#define EBPFOS_ACTION_PAYLOAD_MASK 0x0fffffffU
#define EBPFOS_CONTINUE(_payload) \
	((0U << EBPFOS_ACTION_SHIFT) | ((__u32)(_payload) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_DENY(_errno) \
	((1U << EBPFOS_ACTION_SHIFT) | ((__u32)(_errno) & EBPFOS_ACTION_PAYLOAD_MASK))
#define EBPFOS_OVERRIDE(_value) \
	((3U << EBPFOS_ACTION_SHIFT) | ((__u32)(_value) & EBPFOS_ACTION_PAYLOAD_MASK))

char LICENSE[] SEC("license") = "GPL";

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_fs_lookup_impl, __u64 name_hash, __u32 name_len,
	       __u32 walk_flags, __u32 nd_flags)
{
	if (name_len > 4096)
		return EBPFOS_DENY(36);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_fs_readdir_impl, __u64 file, __u64 inode,
	       __u64 pos, __u32 f_mode)
{
	if (!file || !inode)
		return EBPFOS_DENY(9);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_mm_reclaim_impl, __u64 nr_to_reclaim, __s32 priority,
	       __u64 gfp_mask, __s32 nid)
{
	if (priority < 4 && nr_to_reclaim < 64)
		return EBPFOS_OVERRIDE(64);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_block_submit_impl, __u64 sector, __u32 bytes,
	       __u32 opf, __u64 bdev)
{
	if (bytes > (128U << 20))
		return EBPFOS_DENY(7);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_net_rx_impl, __u64 skb, __u32 len,
	       __u32 protocol, __u32 ifindex)
{
	return skb ? EBPFOS_CONTINUE(0) : EBPFOS_DENY(22);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_net_tx_impl, __u64 skb, __u32 len,
	       __u32 protocol, __u32 ifindex)
{
	return skb ? EBPFOS_CONTINUE(0) : EBPFOS_DENY(22);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_driver_probe_impl, __u64 dev, __u64 drv,
	       __u64 bus, __u64 owner)
{
	return dev && drv ? EBPFOS_CONTINUE(0) : EBPFOS_DENY(19);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_driver_unbind_impl, __u64 dev, __u64 drv,
	       __u64 reserved0, __u64 reserved1)
{
	return dev && drv ? EBPFOS_CONTINUE(0) : EBPFOS_DENY(19);
}

SEC(".struct_ops.link")
struct ebpfos_fs_ops ebpfos_fs_component = {
	.lookup = (void *)ebpfos_fs_lookup_impl,
	.readdir = (void *)ebpfos_fs_readdir_impl,
};

SEC(".struct_ops.link")
struct ebpfos_mm_ops ebpfos_mm_component = {
	.reclaim = (void *)ebpfos_mm_reclaim_impl,
};

SEC(".struct_ops.link")
struct ebpfos_block_ops ebpfos_block_component = {
	.submit = (void *)ebpfos_block_submit_impl,
};

SEC(".struct_ops.link")
struct ebpfos_net_ops ebpfos_net_component = {
	.rx = (void *)ebpfos_net_rx_impl,
	.tx = (void *)ebpfos_net_tx_impl,
};

SEC(".struct_ops.link")
struct ebpfos_driver_ops ebpfos_driver_component = {
	.probe = (void *)ebpfos_driver_probe_impl,
	.unbind = (void *)ebpfos_driver_unbind_impl,
};
