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

enum test_counter {
	TEST_FS_LOOKUP,
	TEST_FS_READDIR,
	TEST_MM_RECLAIM,
	TEST_BLOCK_SUBMIT,
	TEST_NET_RX,
	TEST_NET_TX,
	TEST_DRIVER_PROBE,
	TEST_DRIVER_UNBIND,
	TEST_COUNTER_MAX,
};

struct {
	__uint(type, BPF_MAP_TYPE_ARRAY);
	__uint(max_entries, TEST_COUNTER_MAX);
	__type(key, __u32);
	__type(value, __u64);
} test_hits SEC(".maps");

static __always_inline void hit(__u32 key)
{
	__u64 *value = bpf_map_lookup_elem(&test_hits, &key);

	if (value)
		__sync_fetch_and_add(value, 1);
}

SEC("struct_ops")
__u32 BPF_PROG(test_fs_lookup, __u64 name_hash, __u32 name_len,
	       __u32 walk_flags, __u32 nd_flags)
{
	hit(TEST_FS_LOOKUP);
	if (name_len == 6)
		return EBPFOS_DENY(13);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(test_fs_readdir, __u64 file, __u64 inode,
	       __u64 pos, __u32 f_mode)
{
	hit(TEST_FS_READDIR);
	return EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(test_mm_reclaim, __u64 nr_to_reclaim, __s32 priority,
	       __u64 gfp_mask, __s32 nid)
{
	hit(TEST_MM_RECLAIM);
	return EBPFOS_OVERRIDE(32);
}

SEC("struct_ops")
__u32 BPF_PROG(test_block_submit, __u64 sector, __u32 bytes,
	       __u32 opf, __u64 bdev)
{
	hit(TEST_BLOCK_SUBMIT);
	return bytes ? EBPFOS_DENY(5) : EBPFOS_CONTINUE(0);
}

SEC("struct_ops")
__u32 BPF_PROG(test_net_rx, __u64 skb, __u32 len,
	       __u32 protocol, __u32 ifindex)
{
	hit(TEST_NET_RX);
	return EBPFOS_DENY(1);
}

SEC("struct_ops")
__u32 BPF_PROG(test_net_tx, __u64 skb, __u32 len,
	       __u32 protocol, __u32 ifindex)
{
	hit(TEST_NET_TX);
	return EBPFOS_DENY(1);
}

SEC("struct_ops")
__u32 BPF_PROG(test_driver_probe, __u64 dev, __u64 drv,
	       __u64 bus, __u64 owner)
{
	hit(TEST_DRIVER_PROBE);
	return EBPFOS_DENY(19);
}

SEC("struct_ops")
__u32 BPF_PROG(test_driver_unbind, __u64 dev, __u64 drv,
	       __u64 reserved0, __u64 reserved1)
{
	hit(TEST_DRIVER_UNBIND);
	return EBPFOS_DENY(16);
}

SEC(".struct_ops.link")
struct ebpfos_fs_ops ebpfos_test_fs = {
	.lookup = (void *)test_fs_lookup,
	.readdir = (void *)test_fs_readdir,
};

SEC(".struct_ops.link")
struct ebpfos_mm_ops ebpfos_test_mm = {
	.reclaim = (void *)test_mm_reclaim,
};

SEC(".struct_ops.link")
struct ebpfos_block_ops ebpfos_test_block = {
	.submit = (void *)test_block_submit,
};

SEC(".struct_ops.link")
struct ebpfos_net_ops ebpfos_test_net = {
	.rx = (void *)test_net_rx,
	.tx = (void *)test_net_tx,
};

SEC(".struct_ops.link")
struct ebpfos_driver_ops ebpfos_test_driver = {
	.probe = (void *)test_driver_probe,
	.unbind = (void *)test_driver_unbind,
};
