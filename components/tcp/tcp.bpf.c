// SPDX-License-Identifier: GPL-2.0-only
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "GPL";

extern __u32 tcp_slow_start(struct tcp_sock *tp, __u32 acked) __ksym;
extern void tcp_cong_avoid_ai(struct tcp_sock *tp, __u32 w, __u32 acked) __ksym;

static __always_inline struct tcp_sock *tcp_sk_from_sock(struct sock *sk)
{
	return (struct tcp_sock *)sk;
}

SEC("struct_ops")
void BPF_PROG(ebpfos_tcp_init, struct sock *sk)
{
	struct tcp_sock *tp = tcp_sk_from_sock(sk);

	if (tp->snd_cwnd < 2)
		tp->snd_cwnd = 2;
}

SEC("struct_ops")
void BPF_PROG(ebpfos_tcp_cong_avoid, struct sock *sk, __u32 ack, __u32 acked)
{
	struct tcp_sock *tp = tcp_sk_from_sock(sk);

	if (tp->snd_cwnd < tp->snd_ssthresh)
		acked = tcp_slow_start(tp, acked);
	if (acked)
		tcp_cong_avoid_ai(tp, tp->snd_cwnd, acked);
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_tcp_ssthresh, struct sock *sk)
{
	struct tcp_sock *tp = tcp_sk_from_sock(sk);
	__u32 half = tp->snd_cwnd >> 1;

	return half > 2 ? half : 2;
}

SEC("struct_ops")
__u32 BPF_PROG(ebpfos_tcp_undo_cwnd, struct sock *sk)
{
	return tcp_sk_from_sock(sk)->snd_cwnd;
}

SEC(".struct_ops.link")
struct tcp_congestion_ops ebpfos_tcp_component = {
	.init = (void *)ebpfos_tcp_init,
	.ssthresh = (void *)ebpfos_tcp_ssthresh,
	.cong_avoid = (void *)ebpfos_tcp_cong_avoid,
	.undo_cwnd = (void *)ebpfos_tcp_undo_cwnd,
	.name = "ebpfreno",
};
