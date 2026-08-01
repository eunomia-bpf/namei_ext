/* SPDX-License-Identifier: GPL-2.0 */
#ifndef NAMEI_EXT_RETIREMENT_LITMUS_H
#define NAMEI_EXT_RETIREMENT_LITMUS_H

#ifdef NAMEI_EXT_LITMUS_BPF
typedef unsigned int litmus_u32;
typedef unsigned long long litmus_u64;
#else
#include <stdint.h>
typedef uint32_t litmus_u32;
typedef uint64_t litmus_u64;
#endif

#define NAMEI_EXT_LITMUS_VERSION 2U

#define NAMEI_EXT_LITMUS_IDLE 0ULL
#define NAMEI_EXT_LITMUS_ARMED 1ULL
#define NAMEI_EXT_LITMUS_HELD 2ULL
#define NAMEI_EXT_LITMUS_RELEASED 3ULL
#define NAMEI_EXT_LITMUS_DONE 4ULL
#define NAMEI_EXT_LITMUS_TIMEOUT 5ULL

#define NAMEI_EXT_LITMUS_REPLACE 1ULL
#define NAMEI_EXT_LITMUS_CLEAR 2ULL

#define NAMEI_EXT_LITMUS_TIMEOUT_DEADLINE 1U
#define NAMEI_EXT_LITMUS_TIMEOUT_LOOP_LIMIT 2U

#define NAMEI_EXT_LITMUS_ERROR_RESOLVE_RESULT (1U << 0)
#define NAMEI_EXT_LITMUS_ERROR_NOT_RCU (1U << 1)
#define NAMEI_EXT_LITMUS_ERROR_REDIRECT_STATE (1U << 2)
#define NAMEI_EXT_LITMUS_ERROR_TARGET_IDENTITY (1U << 3)
#define NAMEI_EXT_LITMUS_ERROR_DUPLICATE_EVENT (1U << 4)
#define NAMEI_EXT_LITMUS_ERROR_UPDATE_CLASS (1U << 5)

struct retirement_litmus_state {
	litmus_u64 cookie;
	litmus_u64 state;
	litmus_u64 mode;
	litmus_u64 expected_cgroup_id;
	litmus_u64 observed_cgroup_id;
	litmus_u64 observed_mount;
	litmus_u64 observed_dentry;
	litmus_u64 deadline_ns;
	litmus_u64 event_seq;
	litmus_u64 hold_seq;
	litmus_u64 update_entry_seq;
	litmus_u64 clear_entry_seq;
	litmus_u64 grace_entry_seq;
	litmus_u64 reader_release_seq;
	litmus_u64 clear_exit_seq;
	litmus_u64 update_exit_seq;
	litmus_u64 hold_ns;
	litmus_u64 update_entry_ns;
	litmus_u64 clear_entry_ns;
	litmus_u64 grace_entry_ns;
	litmus_u64 reader_release_ns;
	litmus_u64 clear_exit_ns;
	litmus_u64 update_exit_ns;
	litmus_u64 hold_cookie;
	litmus_u64 update_cookie;
	litmus_u64 grace_cookie;
	litmus_u64 release_cookie;
	litmus_u64 exit_cookie;
	litmus_u64 resolve_attempts;
	litmus_u64 resolve_matches;
	litmus_u64 update_entries;
	litmus_u64 clear_entries;
	litmus_u64 grace_entries;
	litmus_u64 clear_exits;
	litmus_u64 update_exits;
	litmus_u64 error_flags;
	litmus_u32 version;
	litmus_u32 reader_tid;
	litmus_u32 writer_tid;
	litmus_u32 expected_target_id;
	litmus_u32 observed_target_id;
	litmus_u32 observed_reader_tid;
	litmus_u32 observed_writer_tid;
	litmus_u32 observed_reader_cpu;
	litmus_u32 observed_writer_cpu;
	litmus_u32 timeout_reason;
	litmus_u32 reserved;
	litmus_u64 resolve_redirect;
	litmus_u32 resolve_rcu_walk;
	litmus_u32 reserved2;
};

_Static_assert(__builtin_offsetof(struct retirement_litmus_state, cookie) == 0,
	       "retirement litmus cookie offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, deadline_ns) == 56,
	       "retirement litmus deadline offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, event_seq) == 64,
	       "retirement litmus event sequence offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, update_exit_seq) ==
		       120,
	       "retirement litmus update exit offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, hold_ns) == 128,
	       "retirement litmus timestamp offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, hold_cookie) == 184,
	       "retirement litmus event cookie offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, error_flags) == 280,
	       "retirement litmus error offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, version) == 288,
	       "retirement litmus version offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state,
				  expected_target_id) == 300,
	       "retirement litmus target ID offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state,
				  observed_reader_cpu) == 316,
	       "retirement litmus CPU offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state, reserved) == 328,
	       "retirement litmus tail offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state,
				  resolve_redirect) == 336,
	       "retirement litmus resolve pointer offset changed");
_Static_assert(__builtin_offsetof(struct retirement_litmus_state,
				  resolve_rcu_walk) == 344,
	       "retirement litmus resolve mode offset changed");
_Static_assert(sizeof(struct retirement_litmus_state) == 352,
	       "retirement litmus state size changed");

#endif /* NAMEI_EXT_RETIREMENT_LITMUS_H */
