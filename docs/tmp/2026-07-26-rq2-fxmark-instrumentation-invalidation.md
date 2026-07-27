# RQ2 FxMark Instrumentation Invalidation

## Motivation

The first full RQ2 run began after the five-condition KVM preflight. Its purpose
was to execute the fixed 450-cell FxMark matrix. During the run, the attached
`PASS` and `SELECT` results showed a large cost that required checking whether
the benchmark measured the proposed policy or benchmark-only instrumentation.

## Affected Run

- Run ID: `20260726T-rq2-fxmark-full-v1`
- Result root:
  `results/experiments/fxmark-rq2/20260726T-rq2-fxmark-full-v1/`
- Start: `2026-07-27T00:30:55Z`
- Invalidation: `2026-07-27T02:25:41Z`
- Preserved progress: 12 completed boots and 113 raw observations

`run.json` records status `invalidated` and the reason. The run was stopped as
soon as the defect was isolated. Its artifacts remain preserved and must not be
fed to the paper analysis.

## Defect

The initial BPF policies performed map lookups and atomic updates for total and
measured-phase counters on every pathname component. FxMark invokes `stat()` on
multi-component paths, so this benchmark-only work was repeated many times per
reported operation. It is not part of the narrow `PASS` or `SELECT` decision
function whose cost RQ2 intends to measure.

The preflight's low attached throughput and the early full-run observations
therefore conflate `namei_ext` cost with instrumentation cost. This is a
measurement defect, not a negative result about the minimal mechanism.

## Corrective Design

The correction removes the phase helper, BPF maps, map lookups, and atomic
updates from both policies. `PASS` now immediately returns. `SELECT` performs
only the component comparison and bounded selection action.

Mechanism engagement is checked outside the measured lookup path:

1. query the exact attached BPF program ID before measurement;
2. move the FxMark leader to the experiment cgroup and stop it before `exec`;
3. preserve `/proc/<pid>/cgroup` as a raw artifact and verify exact membership;
4. resume the process only after the membership gate passes;
5. query the program ID again after measurement and require stability;
6. require the `SELECT` workload to succeed through a logical `view` component
   that has no physical upper entry, then verify the exact lower tree.

FUSE setup/measured request accounting remains. It runs in the FUSE daemon and
does not add work to cache-hit client-side pathname lookup.

## Validation And Follow-Up

The corrected FxMark driver and both counter-free BPF policies pass the local
build without new warnings. An independent experiment reviewer approved the
correction subject to exact benchmark-leader cgroup verification; the launch
barrier implements that condition.

A fresh KVM full run under a new run ID is mandatory. No observation from
`full-v1`, and no attached-policy performance value from the old preflight,
may support an RQ2 claim.
