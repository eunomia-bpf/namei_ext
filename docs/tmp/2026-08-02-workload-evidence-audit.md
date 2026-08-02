# Workload Evidence Audit

## Purpose

This record answers three questions: which workloads have formal evidence,
what each result actually supports, and which missing experiment has the
highest paper value. It separates industrial case studies from performance
benchmarks and incomplete source-integration attempts.

The audit inspected `docs/evaluation.md`, the paper evaluation section, each
completed result summary and report, the Build Action sandboxfs plan and its
three preflight records, and the raw roots listed below. The repository and
kernel worktrees were clean at the end of the audit.

Current-source validation rebuilt the five completed workload runners through
their Make targets: Agent source task, Application File Sharing, Build Action
Sandboxing, Kubernetes ConfigMap Publication, and Toolchain Environments. The
Agent RQ2, Agent RQ3, Build Action RQ2, and Application File Sharing RQ2
analyzer suites also passed 30/30 host-side tests. These checks establish that
the current entrypoints still build and analyze; they are not new KVM or paper
results.

An independent evidence review found that the initial draft still labeled
Bazel as supporting in the paper and called repeated FxMark condition runs
"cells." The paper now names Bazel as the traditional second main case. FxMark
counts below distinguish 9/6/3 operation-and-worker cells from 450/300/180
repeated condition-run observations. Detailed Agent and toolchain claims now
point to their analysis reports, while historical ccache claims point directly
to the legacy raw JSONL because those roots have no current `summary.json`.
The review also returned NO-GO for a fourth run under the closed sandboxfs
protocol.

## Paper-Facing Workload Structure

The evaluation must complete all seven industrial RQ1 case studies. Evidence
depth can differ, but the five completed workflows are not a stopping point:

1. **Agent Workspaces** is the completed headline case. It covers source-task
   correctness, a same-oracle FUSE cost comparison, and a matched
   custom/stackable-filesystem ownership comparison.
2. **Build Action Sandboxing** is the traditional, non-agent second main case.
   Its Bazel correctness result is complete. Its official sandboxfs cost
   comparison remains missing.
3. **Sandboxed Application File Sharing**, **Service Configuration and Secret
   Rotation**, and **Toolchain and Dependency Environments** provide RQ1
   breadth. They should not each grow a separate weak performance story.
4. **Checkpoint/Restore and Migration** and **HPC File Staging** are required
   W5/W6 RQ1 case studies. They are not completed experiments and do not yet
   contribute paper numbers; both must receive a complete source-oracle KVM
   result.

FxMark and ccache answer performance questions; they are not additional
workload case studies and cannot substitute for W5 or W6.

## Completed Workload Data

| Workload | Source and oracle | Formal data | What it supports |
| --- | --- | --- | --- |
| Agent Workspaces | AgentFS-derived lifecycle and released SWE-Factory-Gym `pallets__click-2622` | Three source-task KVM boots; 18 pytest runs; 12 policy-backed visibility states; 6 physical controls; concurrent 40/40 and 39/40 Click outcomes, switch, rollback, withdrawal | Headline RQ1 source-task evidence |
| Agent Workspaces, FUSE comparison | Same 48-oracle lifecycle in both mechanisms | 20 fresh KVM boots; 20,000 lifecycle samples; 960/960 oracles; p50 5.51 us versus 62.64 us; paired FUSE/`namei_ext` ratio 11.32x [11.24, 11.64] | Headline RQ2 controlled lifecycle cost, not end-to-end agent speedup |
| Agent Workspaces, Wrapfs-derived comparison | Same 37-row existing-object workspace oracle | Three KVM boots; both mechanisms passed 37/37 rows per boot; 13 stackable-filesystem method classes observed | RQ3 method and runtime-responsibility boundary for one matched workload |
| Build Action Sandboxing | Bazel 6.5.0, two concurrent genrules, declared and undeclared inputs | Three KVM boots; 6/6 Bazel actions; 6 logical/lower object matches; 12 preserved lower objects; all allow/hide/select branches | Traditional-workload RQ1 evidence |
| Sandboxed Application File Sharing | Official `xdg-document-portal` 1.18.4 grant/isolation/revoke lifecycle | Three KVM boots; 15/15 official-source states and 15/15 `namei_ext` states; exact operation agreement | Supporting RQ1 source-fidelity evidence |
| Service Configuration and Secret Rotation | Official Kubernetes v1.30.0 `AtomicWriter` V0/V1/no-op/rollback | Three KVM boots; 12/12 source states; 12/12 `namei_ext` states; 6 direct controls; 24 stable-root dirfd checks; 12 old-fd checks; 36 lower-object checks | Supporting RQ1 for already-materialized payload selection |
| Toolchain and Dependency Environments | Ubuntu CPython 3.10/3.12 venv workflow | Three KVM boots; 18 physical/logical states; 24 Python probes; concurrent views, switch, rollback; 3,270 lower-object records unchanged per boot | Supporting RQ1 environment-selection evidence |

The five currently completed RQ1 workflows account for 15 fresh formal KVM
boots. This is progress toward the seven-workload target, not the target
itself. Their oracles differ by workflow; their individual counts should not
be summed into one synthetic score.

## Performance Evidence Outside The Case-Study Count

| Evidence | Formal data | Interpretation |
| --- | --- | --- |
| FxMark cache-hot path walks | 50 KVM boots, 450/450 condition-run observations across nine operation/worker cells; `SELECT`/cached-FUSE throughput 1.052--1.088 with all paired intervals above one | Active lookup-path cost and FUSE comparison |
| FxMark directory enumeration | 50 KVM boots, 300/300 condition-run observations across six operation/worker cells; `SELECT`/FUSE 2.20--3.66 in five cells; four-worker shared-directory cell 1.018 [0.907, 1.135] | Readdir cost and shared-directory contention boundary |
| Patched-unattached fast path | 60 KVM boots, 180/180 condition-run observations across three worker-count cells; patched/stock ratios near 1 with intervals covering 1 | Unused cache-hot MRPL cost on the tested host |
| Historical ccache hot-cache compile | 20 samples per mechanism, 400/400 output checks; FUSE/`namei_ext` 2.18x; native/`namei_ext` 0.945x | Traditional macro support only; ccache already owns cache validation |
| Historical ccache epoch switch | 20 samples over two epochs, 800/800 outputs; FUSE/`namei_ext` 2.10x | Supporting update-path evidence without independent-run uncertainty |

## Incomplete Workloads

| Required workload | Work completed | Why it is not current evidence |
| --- | --- | --- |
| Checkpoint/Restore and Migration | Pinned DMTCP build, official `pathvirt`, and the source-derived A-to-B checkpoint/restart oracle pass on the host. Attempt 6b also completed PathTranslator's same-application A-to-B lifecycle, checkpoint image, lower-object preservation, and cleanup in modified-kernel KVM | Attempt 6b stopped because the runner configured the policy parent before attaching BPF. The runner now follows attach-then-scope setup, scope/target-then-detach cleanup, records each setup operation, and independently cleans partial state. There is still no valid `namei_ext` KVM result |
| HPC File Staging | Spindle built; source loader slice and 47-object inventory fixed; generic final-file/cross-filesystem selection passed 117/117 | Three Spindle preflights failed before BPF attachment; no Spindle RQ1 result |

These failures do not weaken the five completed workload rows, but they leave
the seven-workload evaluation incomplete. The paper must not count DMTCP or
Spindle as reproduced until their new end-to-end RQ1 runs pass.

## Open Experiment Order

The reconsidered mdtest experiment closed after its third permitted preflight.
Four conditions completed 24/24 cells, but the official FUSE condition failed
before mounting because the guest hard open-file limit remained 4,096. The
matrix is incomplete, there is no formal run or paper result, and the protocol
will not receive a fourth attempt.

The next workload experiments are W5 DMTCP and W6 Spindle. Each must reach a
complete source workload and oracle through the modified-kernel KVM attach
path. They should not be replaced by another microbenchmark, ccache variant,
or supporting workflow.

The old sandboxfs timing protocol cannot simply receive a fourth preflight.
Its three attempts ended before a valid pair, and its final record explicitly
closed that protocol. Any new work must first establish that it tests a
scientifically independent question or replace the old experiment with a
fresh, materially different plan; otherwise it is process repetition rather
than new evidence.

The existing Agent, FxMark, and ccache RQ2 evidence remains valid. Adding
another custom FUSE implementation for ConfigMap or venv would be a weaker
comparison than completing W5 and W6.

## Raw Evidence

- Agent source-task summary and detailed report:
  `results/experiments/agent-workspace-source-task-rq1/20260729T-agent-source-task-formal01/analysis/summary.json` and
  `results/experiments/agent-workspace-source-task-rq1/20260729T-agent-source-task-formal01/analysis/report.md`
- Agent lifecycle matrix roots:
  `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`,
  `results/experiments/agent-workspace-matrix/20260722T020210Z-rq1run2/`, and
  `results/experiments/agent-workspace-matrix/20260722T020245Z-rq1run3/`
- Agent RQ2:
  `results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v3/`
- Agent RQ3:
  `results/experiments/agent-workspace-rq3-formal/20260728-rq3-formal-v3/`
- Build Action RQ1:
  `results/experiments/build-action-sandboxing-rq1/20260729T180121Z-w3-formal02/`
- Application File Sharing RQ1:
  `results/experiments/application-file-sharing-source-oracle-rq1/20260730T-xdg-source-formal01/`
- Kubernetes ConfigMap RQ1:
  `results/experiments/kubernetes-configmap-publication-rq1/20260729T-kubernetes-configmap-publication-rq1-01/`
- Toolchain Environment RQ1 summary and detailed report:
  `results/experiments/toolchain-environment/20260729T171551Z-toolchain-formal01/analysis/summary.json` and
  `results/experiments/toolchain-environment/20260729T171551Z-toolchain-formal01/analysis/report.md`
- FxMark RQ2:
  `results/experiments/fxmark-rq2/20260728T-rq2-rcu-target-formal-v3/`
- FxMark readdir:
  `results/experiments/fxmark-readdir/20260729T082800Z-fxmark-readdir-formal-v1/`
- FxMark unused fast path:
  `results/experiments/fxmark-fast-path/20260728T-fxmark-fast-path-formal-v1/`
- ccache hot-cache legacy raw rows (no current `summary.json`):
  `results/experiments/build-cache/20260723T-build-cache-release-v1/w4-ccache-bulk-policy-compile.jsonl`,
  `results/experiments/build-cache/20260723T-build-cache-release-v1/w4-ccache-bulk-native-compile.jsonl`, and
  `results/experiments/build-cache/20260723T-build-cache-release-v1/w4-ccache-bulk-fuse-compile.jsonl`
- ccache epoch-switch legacy raw rows (no current `summary.json`):
  `results/phase1/20260724T-epoch-switch-release-v2/w4-ccache-bulk-compile-epoch-switch.jsonl`
- W5 DMTCP source-positive control:
  `results/workloads/checkpoint-restore-source/20260802T094525Z-df8ae7d4/`

## Remaining Risks

- Only Agent Workspaces currently has complete RQ1/RQ2/RQ3 coverage.
- RQ2 has strong controlled evidence but only one complete source-derived
  application comparison.
- RQ3 has one matched custom/stackable-filesystem workload. It is an ownership
  and runtime-responsibility result, not a security ranking.
- The paper must keep incomplete source-integration attempts and historical
  preflights out of headline evidence.
