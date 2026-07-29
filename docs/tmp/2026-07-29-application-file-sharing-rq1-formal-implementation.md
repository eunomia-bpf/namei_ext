# Implementation: RQ1 Sandboxed Application File Sharing

## Motivation

The existing XDG-derived preflight recorded one aggregate pass per lifecycle
state. That was enough to debug the policy, but not enough to inspect each
lookup, read, directory enumeration, application-isolation decision, and
selected lower object independently. The formal workload replaces that
historical result path with current-kernel, per-state evidence.

## Files

- `bpf/policies/application_file_sharing.bpf.c` remains the policy under test.
- `experiments/application_file_sharing/namei_ext_application_file_sharing.c`
  now emits the raw state and lower-object observations.
- `configs/benchmarks/application_file_sharing.mk` fixes the one-boot
  preflight, three-boot formal repetitions, result roots, and timeout.
- `mk/experiments/application_file_sharing.mk` owns artifact capture, fresh
  KVM boots, finalization, and count-only analysis.
- `Makefile` and `mk/suites.mk` expose the formal entrypoints without promoting
  the workload into the passing aggregate suite before result review.

## State Observation

Each probe child enters application A or B's cgroup and reports:

- `stat` errno for the logical document;
- separate `stat` and open/read results for its payload;
- separate `opendir`, complete `readdir`, and `closedir` results for the
  logical parent;
- whether enumeration listed `document`;
- direct access to the registered host document and payload;
- an unrelated same-named path's read result and bytes;
- logical and lower device/inode values.

The parent emits one `application-file-sharing-state` JSONL record per state.
A hidden state requires successful directory enumeration with no logical entry,
not merely a failed `opendir`. The visible state additionally requires both the
document and payload to be the registered lower objects.

## Lifecycle And Cleanup

The controller executes pre-grant isolation, application-A grant,
cross-application isolation, and application-A revoke. It then records the
lower payload's device, inode, mode, size, and bytes before and after the
lifecycle. The guest copies the lower and unrelated payloads into the boot
result directory for direct host-side `cmp`.

Policy detach, target clearing, and removal of both application cgroups are
explicit pass/fail observations. A missing observation or failed operation
fails the boot and the host finalizer.

## Make And Result Path

`make kvm-application-file-sharing-preflight RUN_ID=<id>` runs one fresh boot.
`make experiment-application-file-sharing-rq1 RUN_ID=<id>` runs three fresh
boots with the same workload and oracle.

Each boot captures kernel evidence, external BPF and FUSE inventory before and
after the workload, controller output, dmesg, state records, lower-object
records, and teardown. The analyzer only counts passing raw observations and
does not make a scientific verdict.

No checksum, custom result schema checker, table comparison, or materialized
view baseline is part of this workload.

## Local Validation

The controller and all BPF policies compile with:

```text
make application-file-sharing bpf
```

The analysis target parses through Make, the active workload paths contain no
checksum command, and `git diff --check` passes. Real functional validation
still requires the planned modified-kernel KVM preflight.
