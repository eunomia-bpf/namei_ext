// SPDX-License-Identifier: GPL-2.0-only
#include "ebpfos_bpf.h"

struct xdp_md {
	__u32 data;
	__u32 data_end;
	__u32 data_meta;
	__u32 ingress_ifindex;
	__u32 rx_queue_index;
	__u32 egress_ifindex;
};

#define XDP_DROP 1
#define XDP_PASS 2

/* Native XDP component used for dataplane replacement experiments. */
SEC("xdp")
int network_component(struct xdp_md *ctx)
{
	return ctx->data <= ctx->data_end ? XDP_PASS : XDP_DROP;
}

/* eBPFOS graph-facing network policy components. */
SEC("raw_tp/ebpfos_net_rx")
int network_rx_component(struct ebpfos_bpf_ctx *ctx)
{
	return argument(ctx, 0) ? EBPFOS_CONTINUE(0) : EBPFOS_FALLBACK();
}

SEC("raw_tp/ebpfos_net_tx")
int network_tx_component(struct ebpfos_bpf_ctx *ctx)
{
	return argument(ctx, 0) ? EBPFOS_CONTINUE(0) : EBPFOS_FALLBACK();
}

char LICENSE[] SEC("license") = "GPL";
