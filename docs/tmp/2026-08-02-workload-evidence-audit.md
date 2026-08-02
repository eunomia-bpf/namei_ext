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

Current-source validation rebuilt the seven completed workload runners through
their Make targets: Agent source task, Application File Sharing, Build Action
Sandboxing, Kubernetes ConfigMap Publication, Checkpoint/Restore, and Toolchain
Environments, followed by the complete Spindle formal path. The
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

The evaluation contains all seven mandatory industrial RQ1 case studies.
Evidence depth can differ, but no workflow is merged, removed, or replaced:

1. **Agent Workspaces** is the completed headline case. It covers source-task
   correctness, a same-oracle FUSE cost comparison, and a matched
   custom/stackable-filesystem ownership comparison.
2. **Build Action Sandboxing** is the traditional, non-agent second main case.
   Its Bazel correctness result is complete. Its official sandboxfs cost
   comparison remains missing.
3. **Sandboxed Application File Sharing**, **Service Configuration and Secret
   Rotation**, **Checkpoint/Restore and Migration**, **HPC File Staging**, and
   **Toolchain and Dependency Environments** provide complete RQ1 breadth.
   They should not each grow a separate weak performance story.

FxMark and ccache answer performance questions; they are not additional
workload case studies and do not alter the seven-case portfolio.

## Completed Workload Data

| Workload | Source and oracle | Formal data | What it supports |
| --- | --- | --- | --- |
| Agent Workspaces | AgentFS-derived lifecycle and released SWE-Factory-Gym `pallets__click-2622` | Three source-task KVM boots; 18 pytest runs; 12 policy-backed visibility states; 6 physical controls; concurrent 40/40 and 39/40 Click outcomes, switch, rollback, withdrawal | Headline RQ1 source-task evidence |
| Agent Workspaces, FUSE comparison | Same 48-oracle lifecycle in both mechanisms | 20 fresh KVM boots; 20,000 lifecycle samples; 960/960 oracles; p50 5.51 us versus 62.64 us; paired FUSE/`namei_ext` ratio 11.32x [11.24, 11.64] | Headline RQ2 controlled lifecycle cost, not end-to-end agent speedup |
| Agent Workspaces, Wrapfs-derived comparison | Same 37-row existing-object workspace oracle | Three KVM boots; both mechanisms passed 37/37 rows per boot; 13 stackable-filesystem method classes observed | RQ3 method and runtime-responsibility boundary for one matched workload |
| Build Action Sandboxing | Bazel 6.5.0, two concurrent genrules, declared and undeclared inputs | Three KVM boots; 6/6 Bazel actions; 6 logical/lower object matches; 12 preserved lower objects; all allow/hide/select branches | Traditional-workload RQ1 evidence |
| Sandboxed Application File Sharing | Official `xdg-document-portal` 1.18.4 grant/isolation/revoke lifecycle | Three KVM boots; 15/15 official-source states and 15/15 `namei_ext` states; exact operation agreement | Supporting RQ1 source-fidelity evidence |
| Service Configuration and Secret Rotation | Official Kubernetes v1.30.0 `AtomicWriter` V0/V1/no-op/rollback | Three KVM boots; 12/12 source states; 12/12 `namei_ext` states; 6 direct controls; 24 stable-root dirfd checks; 12 old-fd checks; 36 lower-object checks | Supporting RQ1 for already-materialized payload selection |
| Checkpoint/Restore and Migration | DMTCP PathTranslator and source-derived same-path A-to-B checkpoint/restart | Three KVM boots; nine real restart conditions; six positive A-to-B transitions; three withdrawn `ENOENT` controls; restart-time `SELECT` 12-to-24 versus withdrawn 12-to-12; 108 lower-object rows unchanged | Supporting RQ1 moved-root reopen evidence |
| HPC File Staging | Pinned LLNL Spindle serial-pull loader slice and 47 first-party source-to-cache mappings | Three KVM boots; 3/3 source, 3/3 `namei_ext`, and 3/3 withdrawn conditions; 141 mapping/selection/identity/preservation rows per category; 204 `SELECT` hits; three permission and withdrawal controls | Supporting RQ1 for final selection of Spindle-populated node-local objects, not distribution, scaling, or performance |
| Toolchain and Dependency Environments | Ubuntu CPython 3.10/3.12 venv workflow | Three KVM boots; 18 physical/logical states; 24 Python probes; concurrent views, switch, rollback; 3,270 lower-object records unchanged per boot | Supporting RQ1 environment-selection evidence |

The seven completed RQ1 workflows account for 21 fresh formal KVM boots in
their current source-oracle result rows. Their oracles differ by workflow;
their individual counts should not
be summed into one synthetic score.

## Performance Evidence Outside The Case-Study Count

| Evidence | Formal data | Interpretation |
| --- | --- | --- |
| FxMark cache-hot path walks | 50 KVM boots, 450/450 condition-run observations across nine operation/worker cells; `SELECT`/cached-FUSE throughput 1.052--1.088 with all paired intervals above one | Active lookup-path cost and FUSE comparison |
| FxMark directory enumeration | 50 KVM boots, 300/300 condition-run observations across six operation/worker cells; `SELECT`/FUSE 2.20--3.66 in five cells; four-worker shared-directory cell 1.018 [0.907, 1.135] | Readdir cost and shared-directory contention boundary |
| Patched-unattached fast path | 60 KVM boots, 180/180 condition-run observations across three worker-count cells; patched/stock ratios near 1 with intervals covering 1 | Unused cache-hot MRPL cost on the tested host |
| Historical ccache hot-cache compile | 20 samples per mechanism, 400/400 output checks; FUSE/`namei_ext` 2.18x; native/`namei_ext` 0.945x | Traditional macro support only; ccache already owns cache validation |
| Historical ccache epoch switch | 20 samples over two epochs, 800/800 outputs; FUSE/`namei_ext` 2.10x | Supporting update-path evidence without independent-run uncertainty |

## Seven-Case Completion

W6 formal root
`results/experiments/spindle-staging/20260802T114220Z-w6-formal01/`
closes the only missing RQ1 row. Three fresh modified-kernel KVM boots each
completed the source Spindle, direct `namei_ext`, and withdrawn-target
conditions. The result is admitted only for the frozen 47-object loader slice
and exact Spindle-created cache files. Earlier failed or incomplete Spindle
roots remain diagnostic history and are not combined with the formal result.

## Open Experiment Order

The reconsidered mdtest experiment closed after its third permitted preflight.
Four conditions completed 24/24 cells, but the official FUSE condition failed
before mounting because the guest hard open-file limit remained 4,096. The
matrix is incomplete, there is no formal run or paper result, and the protocol
will not receive a fourth attempt.

There is no remaining RQ1 workload slot. W1--W7 stay fixed as seven separate
case studies. The highest-value next experiment is a traditional
source-derived RQ2 comparison, preferably W6 final-object selection or a new
scientifically independent W3 protocol, against feature-equivalent FUSE.

The old sandboxfs timing protocol cannot simply receive a fourth preflight.
Its three attempts ended before a valid pair, and its final record explicitly
closed that protocol. Any new work must first establish that it tests a
scientifically independent question or replace the old experiment with a
fresh, materially different plan; otherwise it is process repetition rather
than new evidence.

The existing Agent, FxMark, and ccache RQ2 evidence remains valid. Adding
separate weak FUSE variants for every supporting case would fragment the
performance story rather than deepen the representative comparison.

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
- W5 Checkpoint/Restore RQ1 summary and detailed report:
  `results/experiments/checkpoint-restore-rq1/20260802T111000Z-w5-formal01/analysis/summary.json` and
  `results/experiments/checkpoint-restore-rq1/20260802T111000Z-w5-formal01/analysis/report.md`
- W6 HPC File Staging RQ1 summary and detailed report:
  `results/experiments/spindle-staging/20260802T114220Z-w6-formal01/analysis/summary.json` and
  `results/experiments/spindle-staging/20260802T114220Z-w6-formal01/analysis/report.md`

## Remaining Risks

- Only Agent Workspaces currently has complete RQ1/RQ2/RQ3 coverage.
- RQ2 has strong controlled evidence but only one complete source-derived
  application comparison.
- RQ3 has one matched custom/stackable-filesystem workload. It is an ownership
  and runtime-responsibility result, not a security ranking.
- W6 covers one serial-pull loader slice and final-object selection. It does
  not reproduce Spindle's distributed launch scaling or establish a W6
  performance comparison.
- The paper must keep incomplete source-integration attempts and historical
  preflights out of headline evidence.
