# Exact-Parent Dispatch Preflight Review

## Question

The previous attribution run found approximately ten namei_ext BPF program
invocations per one-worker FxMark `MRPL` work unit. The exact-parent dispatch
implementation was intended to invoke the policy only at the managed parent.
This review asks two separate questions:

1. Did exact-parent registration reduce BPF program invocations from about ten
   per work unit to about one?
2. Did that reduction materially close the active-path throughput gap to the
   cache-hot feature-equivalent FUSE condition?

The workload, policies, matched stock/patched kernels, FUSE implementation,
correctness oracle, duration, and five conditions were unchanged.

## Runs

Attribution run with BPF statistics enabled:

`results/experiments/fxmark-rq2-preflight/20260727T-policy-parent-run-count-v1`

Normal performance preflight with BPF statistics disabled:

`results/experiments/fxmark-rq2-preflight/20260727T-policy-parent-preflight-v1`

Both runs used patched kernel commit
`c7af99f6760979e17c5066ebceba342757b78b24` and matched stock commit
`062871f1371b2e02a272ff5279c6479aff0a37ef`. Each result has five isolated KVM
boots, five unique passing observations, exact expected/observed boot and cell
sets, completed run metadata, kernel identity, configuration, raw logs, and
dmesg. No configured kernel failure signature was found.

## Invocation Result

| Condition | Work units | Policy runs | Runs/work | BPF ns/run |
| --- | ---: | ---: | ---: | ---: |
| `PASS` | 2,340,379 | 2,340,381 | 1.0000009 | 25.06 |
| `SELECT` | 2,093,737 | 2,093,739 | 1.0000010 | 25.10 |

These calculations use the preserved before/after raw counters. The two extra
program runs are outside the measured work-unit loop. The earlier diagnostic
reported approximately 10.0001 runs/work and about 24 ns/run. Exact-parent
registration therefore achieved its immediate dispatch-count goal.

Throughput from this statistics-enabled run is not interpreted because
`bpf_stats_enabled` changes runtime behavior.

## Normal Preflight Result

| Condition | Work/s | Relative to patched-unattached | Relative to FUSE |
| --- | ---: | ---: | ---: |
| stock | 2,470,921 | 1.060 | 1.210 |
| patched-unattached | 2,331,891 | 1.000 | 1.142 |
| `PASS` | 1,235,376 | 0.530 | 0.605 |
| `SELECT` | 1,085,385 | 0.465 | 0.532 |
| FUSE | 2,041,385 | 0.875 | 1.000 |

The FUSE row recorded 28 setup requests and one measured-phase request, so this
remains the cache-hot stable-view comparison defined by the RQ2 plan.

This is one two-second directional sample, not final statistical evidence.
Nevertheless, it does not show the mechanism improvement required to justify
the full 450-cell matrix. `SELECT` is about 0.53x the FUSE throughput in this
preflight, and `PASS` is about 0.61x.

## Interpretation

Reducing BPF program executions did not materially improve active throughput.
The current hook still enters namei_ext dispatch for every pathname component.
Each nonmatching component acquires the cgroup RCU read section, finds the
effective attachment owner, and scans the exact-parent set before returning
`PASS`. Only the BPF program execution is suppressed. For this pathname shape,
the repeated dispatch filter remains on approximately ten components per work
unit.

The evidence therefore rejects the narrower diagnosis that repeated BPF
program bodies were the dominant remaining cost. It does not reject the RQ2
hypothesis or change the FUSE baseline. It identifies another mechanism layer
that must be repaired before the unchanged hypothesis is tested at full scale.

## Decision

Do not run or reinterpret the full 450-cell RQ2 matrix from this kernel.
Preserve both preflights as internal mechanism evidence.

The follow-up attached-but-`EXACT(empty)` diagnostic has now completed. It
remained near exact `PASS` despite executing the BPF program zero times, so the
next design must provide a cheaper negative-component fast path rather than
optimize the policy body. The complete design, raw-result review, and mechanism
decision are recorded in
`docs/tmp/2026-07-27-fxmark-exact-empty-dispatch-diagnostic.md`.

Candidate implementation directions for that negative fast path are:

- a global RCU registry that cheaply rejects parents not registered by any
  namei_ext attachment before cgroup dispatch;
- a lookup-lifetime snapshot that resolves the effective cgroup/scope once and
  avoids repeating cgroup discovery for every component; or
- another VFS-owned exact-parent marker with explicit registration, rename,
  mount, detach, and teardown semantics.

These are mechanism candidates, not accepted ABI decisions. Prefix matching,
path strings, decision caching, dcache-miss-only policy, and a new policy
language remain out of scope.
