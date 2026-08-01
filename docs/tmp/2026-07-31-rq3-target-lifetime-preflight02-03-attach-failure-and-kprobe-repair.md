# RQ3 Target-Lifetime Preflight02/03 Attach Failure And Kprobe Repair

## Question

The deterministic target-retirement litmus must stop an exact reader after it
has borrowed the registered old `struct path` in RCU-walk, start replacement or
clear on another CPU, and release the reader only when the writer reaches
`synchronize_rcu()`. This record preserves two failed attempts after commit
`2f2e6a1fefd74a3422acbaf3bc156bb059d0c7d8` and explains the tracing attachment
repair. Neither failed result root is positive mechanism evidence.

## Immutable Preflight02 Launcher Failure

`results/experiments/namei-ext-target-lifetime-preflight/20260801T045528Z-target-lifetime-preflight02/`
was launched through a PTY. During live supervision, the operator observed the
QEMU/virtme-ng process in job-control stop; that process-state observation was
not captured in the result root. The immutable root itself records a failure
after exactly the 180-second launcher timeout, empty launcher logs, and no usable
guest artifact. It therefore supports no mechanism result regardless of the
operator diagnosis. The result root remains immutable and must not be reused.

## Immutable Preflight03 Runtime Failure

`results/experiments/namei-ext-target-lifetime-preflight/20260801T045916Z-target-lifetime-preflight03/`
used the non-PTY Make path and booted the modified normal kernel successfully.
The captured kernel commit is `621aff8d1bb52fad718f11fd882c956d6a5686ae`, and
the project commit is `2f2e6a1fefd74a3422acbaf3bc156bb059d0c7d8`.

The guest runner failed before the deterministic litmus with:

```text
libbpf: prog 'hold_borrowed_target': failed to attach: -EBUSY
```

The boot directory records `runner.status=1`; the top-level run is failed with
`failure=kvm-launch-or-guest-command`. Normal-kernel workload observations after
the failed litmus attachment are not admissible target-retirement evidence, and
KASAN/KCSAN did not run. The result root remains immutable.

## Root Cause

The first litmus implementation used
`fexit/namei_ext_resolve_target`. All three target-lifetime kernels provide BTF,
BPF events, kprobes, and kprobe events, but the normal configuration records:

```text
CONFIG_FTRACE=y
# CONFIG_FUNCTION_TRACER is not set
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
```

The built `namei_ext_resolve_target()` begins with `endbr64` and the function
body rather than a function-tracer patch site. The BPF object can load, but
libbpf cannot install the fexit trampoline and returns `-EBUSY`. Enabling the
function tracer only for this experiment would change all three test-kernel
configurations and is unnecessary because the required observation is available
through the already enabled kprobe path.

## Paired Kprobe/Kretprobe Repair

The repaired test-only BPF object uses seven tracing links:

1. `kprobe/namei_ext_resolve_target` accepts only the exact armed reader TID and
   captures the `redirect` pointer and `rcu_walk` argument from x86-64
   `pt_regs`.
2. `kretprobe/namei_ext_resolve_target` accepts the same reader, requires one
   entry capture and a zero return value, reads the resulting redirect state,
   and requires a borrowed non-null mount/dentry for the expected cgroup and
   target ID.
3. The return probe then records the hold event and waits exactly as the fexit
   version did. A kretprobe runs before the caller resumes, so the reader is
   still inside the surrounding namei RCU read-side critical section.
4. The existing update-entry, clear-entry, grace-period-entry, clear-return,
   and update-return probes retain the exact event-order contract.

The shared BPF/userspace schema is version 2 and 352 bytes. It adds the captured
redirect address and RCU-walk argument to each raw litmus row, and changes the
source identity to `tracing-bpf-kprobe-kretprobe`. The analyzer rejects missing
entry-probe evidence and rejects the old fexit/version-1 schema, so failed or
stale records cannot satisfy the repaired contract.

This changes only experiment instrumentation. It does not change the namei_ext
ABI, target registry, namei implementation, kernel configuration, workload
oracle, or event-order claim.

## Host Validation

- the userspace runner and BPF object build with `-Wall -Wextra -Werror`;
- GCC `-fanalyzer` reports no runner finding;
- all 38 analyzer tests pass, including entry-evidence and stale-schema
  negatives plus the existing 12,100-history exhaustive linearizability check;
- BPF BTF and kernel BTF both report a 168-byte x86-64 register context with
  matching `ax`, `si`, and `di` offsets;
- userspace and BPF builds agree on the 352-byte shared-state layout;
- the BPF object contains exactly seven non-relocation kprobe/kretprobe program
  sections; and
- `git diff --check` passes.

## Next Gate

Commit the clean instrumentation repair, then run a new non-PTY preflight root
through `make kvm-namei-ext-target-lifetime-preflight`. A valid preflight must
complete normal, KASAN, and KCSAN boots and produce four version-2 litmus rows
per boot, exact event sequences, old/fresh object identity checks, concurrent
engagement, sanitizer evidence, cleanup, and controlling success statuses.
