// SPDX-License-Identifier: GPL-2.0

#define NAMEI_EXT_LITMUS_BPF
#include "retirement_litmus.h"

#define SEC(name) __attribute__((section(name), used))
#define __always_inline inline __attribute__((always_inline))
#define LITMUS_MAX_LOOPS (8U * 1024U * 1024U)

static litmus_u64 (*const bpf_ktime_get_ns)(void) = (void *)5;
static litmus_u32 (*const bpf_get_smp_processor_id)(void) = (void *)8;
static litmus_u64 (*const bpf_get_current_pid_tgid)(void) = (void *)14;
static long (*const bpf_probe_read_kernel)(void *dst, litmus_u32 size,
					   const void *unsafe_ptr) = (void *)113;
static long (*const bpf_loop)(litmus_u32 count, void *callback_fn,
			      void *callback_ctx, litmus_u64 flags) = (void *)181;

struct litmus_path {
	void *mnt;
	void *dentry;
};

struct litmus_redirect {
	unsigned char active;
	unsigned char target_pending;
	unsigned char target_active;
	unsigned char target_borrowed;
	litmus_u32 len;
	litmus_u32 hash;
	litmus_u32 target_id;
	litmus_u64 target_cgroup_id;
	char name[64];
	struct litmus_path target;
};

volatile struct retirement_litmus_state retirement_litmus;

static __always_inline litmus_u32 current_tid(void)
{
	return (litmus_u32)bpf_get_current_pid_tgid();
}

static __always_inline litmus_u64 next_event(void)
{
	return __sync_fetch_and_add(&retirement_litmus.event_seq, 1) + 1;
}

static __always_inline void set_error(litmus_u32 error)
{
	__sync_fetch_and_or(&retirement_litmus.error_flags, error);
}

static long wait_for_writer(litmus_u32 index, void *opaque)
{
	litmus_u64 state;

	(void)index;
	(void)opaque;
	state = retirement_litmus.state;
	if (state == NAMEI_EXT_LITMUS_RELEASED)
		return 1;
	if (bpf_ktime_get_ns() < retirement_litmus.deadline_ns)
		return 0;
	retirement_litmus.timeout_reason = NAMEI_EXT_LITMUS_TIMEOUT_DEADLINE;
	__sync_val_compare_and_swap(&retirement_litmus.state,
				    NAMEI_EXT_LITMUS_HELD,
				    NAMEI_EXT_LITMUS_TIMEOUT);
	return 1;
}

SEC("fexit/namei_ext_resolve_target")
int hold_borrowed_target(litmus_u64 *ctx)
{
	struct litmus_redirect redirect = {};
	void *redirect_ptr = (void *)(unsigned long)ctx[0];
	litmus_u32 rcu_walk = (litmus_u32)ctx[1];
	int result = (int)ctx[2];
	litmus_u64 state;

	if (current_tid() != retirement_litmus.reader_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_ARMED)
		return 0;
	__sync_fetch_and_add(&retirement_litmus.resolve_attempts, 1);
	if (result) {
		set_error(NAMEI_EXT_LITMUS_ERROR_RESOLVE_RESULT);
		return 0;
	}
	if (!rcu_walk) {
		set_error(NAMEI_EXT_LITMUS_ERROR_NOT_RCU);
		return 0;
	}
	if (bpf_probe_read_kernel(&redirect, sizeof(redirect), redirect_ptr)) {
		set_error(NAMEI_EXT_LITMUS_ERROR_REDIRECT_STATE);
		return 0;
	}
	if (!redirect.target_active || redirect.target_pending ||
	    !redirect.target_borrowed || !redirect.target.mnt ||
	    !redirect.target.dentry) {
		set_error(NAMEI_EXT_LITMUS_ERROR_REDIRECT_STATE);
		return 0;
	}
	if (redirect.target_cgroup_id != retirement_litmus.expected_cgroup_id ||
	    redirect.target_id != retirement_litmus.expected_target_id) {
		set_error(NAMEI_EXT_LITMUS_ERROR_TARGET_IDENTITY);
		return 0;
	}

	retirement_litmus.observed_cgroup_id = redirect.target_cgroup_id;
	retirement_litmus.observed_target_id = redirect.target_id;
	retirement_litmus.observed_reader_tid = current_tid();
	retirement_litmus.observed_reader_cpu = bpf_get_smp_processor_id();
	retirement_litmus.observed_mount =
		(litmus_u64)(unsigned long)redirect.target.mnt;
	retirement_litmus.observed_dentry =
		(litmus_u64)(unsigned long)redirect.target.dentry;
	retirement_litmus.hold_cookie = retirement_litmus.cookie;
	retirement_litmus.hold_ns = bpf_ktime_get_ns();
	retirement_litmus.hold_seq = next_event();
	state = __sync_val_compare_and_swap(&retirement_litmus.state,
					     NAMEI_EXT_LITMUS_ARMED,
					     NAMEI_EXT_LITMUS_HELD);
	if (state != NAMEI_EXT_LITMUS_ARMED) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	__sync_fetch_and_add(&retirement_litmus.resolve_matches, 1);

	bpf_loop(LITMUS_MAX_LOOPS, wait_for_writer, 0, 0);
	state = retirement_litmus.state;
	if (state == NAMEI_EXT_LITMUS_RELEASED) {
		retirement_litmus.release_cookie = retirement_litmus.cookie;
		retirement_litmus.reader_release_ns = bpf_ktime_get_ns();
		retirement_litmus.reader_release_seq = next_event();
		retirement_litmus.state = NAMEI_EXT_LITMUS_DONE;
	} else if (state == NAMEI_EXT_LITMUS_HELD) {
		retirement_litmus.timeout_reason =
			NAMEI_EXT_LITMUS_TIMEOUT_LOOP_LIMIT;
		retirement_litmus.state = NAMEI_EXT_LITMUS_TIMEOUT;
	}
	return 0;
}

SEC("kprobe/namei_ext_register_target_write")
int mark_update_entry(void *ctx)
{
	(void)ctx;
	if (current_tid() != retirement_litmus.writer_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_HELD)
		return 0;
	if (retirement_litmus.update_entries) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	retirement_litmus.update_cookie = retirement_litmus.cookie;
	retirement_litmus.observed_writer_tid = current_tid();
	retirement_litmus.observed_writer_cpu = bpf_get_smp_processor_id();
	retirement_litmus.update_entry_ns = bpf_ktime_get_ns();
	retirement_litmus.update_entry_seq = next_event();
	retirement_litmus.update_entries = 1;
	return 0;
}

SEC("kprobe/namei_ext_clear_targets")
int mark_clear_entry(void *ctx)
{
	(void)ctx;
	if (current_tid() != retirement_litmus.writer_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_HELD)
		return 0;
	if (retirement_litmus.mode != NAMEI_EXT_LITMUS_CLEAR ||
	    !retirement_litmus.update_entry_seq) {
		set_error(NAMEI_EXT_LITMUS_ERROR_UPDATE_CLASS);
		return 0;
	}
	if (retirement_litmus.clear_entries) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	retirement_litmus.clear_entry_ns = bpf_ktime_get_ns();
	retirement_litmus.clear_entry_seq = next_event();
	retirement_litmus.clear_entries = 1;
	return 0;
}

SEC("kprobe/synchronize_rcu")
int release_reader_at_grace_entry(void *ctx)
{
	litmus_u64 state;

	(void)ctx;
	if (current_tid() != retirement_litmus.writer_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_HELD ||
	    !retirement_litmus.update_entry_seq)
		return 0;
	if ((retirement_litmus.mode == NAMEI_EXT_LITMUS_CLEAR &&
	     !retirement_litmus.clear_entry_seq) ||
	    (retirement_litmus.mode == NAMEI_EXT_LITMUS_REPLACE &&
	     retirement_litmus.clear_entry_seq) ||
	    (retirement_litmus.mode != NAMEI_EXT_LITMUS_CLEAR &&
	     retirement_litmus.mode != NAMEI_EXT_LITMUS_REPLACE)) {
		set_error(NAMEI_EXT_LITMUS_ERROR_UPDATE_CLASS);
		return 0;
	}
	if (retirement_litmus.grace_entries) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	retirement_litmus.grace_cookie = retirement_litmus.cookie;
	retirement_litmus.grace_entry_ns = bpf_ktime_get_ns();
	retirement_litmus.grace_entry_seq = next_event();
	retirement_litmus.grace_entries = 1;
	state = __sync_val_compare_and_swap(&retirement_litmus.state,
					     NAMEI_EXT_LITMUS_HELD,
					     NAMEI_EXT_LITMUS_RELEASED);
	if (state != NAMEI_EXT_LITMUS_HELD)
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
	return 0;
}

SEC("kretprobe/namei_ext_clear_targets")
int mark_clear_exit(void *ctx)
{
	(void)ctx;
	if (current_tid() != retirement_litmus.writer_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_DONE ||
	    retirement_litmus.mode != NAMEI_EXT_LITMUS_CLEAR ||
	    !retirement_litmus.clear_entry_seq)
		return 0;
	if (retirement_litmus.clear_exits) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	retirement_litmus.clear_exit_ns = bpf_ktime_get_ns();
	retirement_litmus.clear_exit_seq = next_event();
	retirement_litmus.clear_exits = 1;
	return 0;
}

SEC("kretprobe/namei_ext_register_target_write")
int mark_update_exit(void *ctx)
{
	(void)ctx;
	if (current_tid() != retirement_litmus.writer_tid ||
	    retirement_litmus.state != NAMEI_EXT_LITMUS_DONE ||
	    !retirement_litmus.update_entry_seq)
		return 0;
	if (retirement_litmus.update_exits) {
		set_error(NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT);
		return 0;
	}
	retirement_litmus.exit_cookie = retirement_litmus.cookie;
	retirement_litmus.update_exit_ns = bpf_ktime_get_ns();
	retirement_litmus.update_exit_seq = next_event();
	retirement_litmus.update_exits = 1;
	return 0;
}

char _license[] SEC("license") = "GPL";
