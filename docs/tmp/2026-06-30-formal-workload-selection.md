# Formal workload selection and evaluation boundary

Canonical framing update: this dated record is historical evidence for the
workload decision. The current skill-owned entry points are
`docs/idea-story.md` for the paper story and claim ledger, and
`docs/background-related-work.md` for related work, novelty, baselines, and
workload-source reuse.

## Decision

We should stop making `table_redirect.bpf.c` the center of the paper story.
The main story is the mechanism-family tradeoff: FUSE/userspace filesystems,
custom kernel filesystems, static/materialized namespace construction, and a
narrow eBPF VFS name-resolution hook.

`table_redirect.bpf.c` is not a research objective for the next phase. Existing
exact-map runs may remain as archived boundary evidence, but new work should not
be framed as proving that static tables are inadequate.

The literature is used to select realistic workload sources and explain why
nearby systems chose FUSE, custom filesystems, namespace services, snapshot
managers, or materialized views. It is not used for exclusivity arguments, and the
`namei_ext` paper should not claim that only this interface can handle the
selected workloads.

## Formal workload set

The release paper should not keep adding ad hoc cases. After the reproducible
source survey, the paper-facing set should be three evaluation workloads. The
old W1-W4 names remain internal implementation families.

| Paper-facing workload | Reproducible source candidates | Why it is useful for evaluation | Current status |
| --- | --- | --- | --- |
| AI agent workspace lifecycle | BranchFS, Sandlock, SWE-MiniSandbox, SWE-agent/SWE-ReX, OpenHands SDK, Terminal-Bench, AgentCgroup traces, AgentFS, Redis Agent Filesystem, Mirage | Stable agent-visible paths, branch/session/workspace/protected-path state, and commit/abort or rollback transitions give a realistic path-view workload. | New main agent workload candidate; W1/W3 fixtures are boundary evidence until a code-backed live trace exists. |
| Service fixture sandbox: nginx reload/update and PostgreSQL secret/config rotation | nginx, PostgreSQL, Kubernetes projected volumes, Docker Compose configs/secrets; optionally Sandlock-style service sandbox tasks | Stable service-visible paths select config, secret, cert, socket, endpoint, and poison fixtures; lower FS still owns file data and permissions. | Positive C2 slice; C8 boundary only until real reload/update trace passes. |
| Content-verified cache and environment reuse | ccache, BuildKit/Go cache, DockSmith trajectories, SWE-Factory, MEnvAgent, Multi-Docker-Eval, SWE-rebench V2, SWE-agent/SWE-ReX task builds | Runtime chooses verified local hit, canonical backing, miss fallback, stale reject, corrupt reject, and environment/cache update epoch. | Strongest current C8 candidate; still missing live stale/corrupt/update-window run. |

YoloFS remains strong methodology and oracle-design evidence. Historical note:
this 2026-06-30 survey did not find public code. The 2026-07-01 correction in
`docs/tmp/2026-07-01-yolofs-public-artifact-reproduction-update.md` found
public YoloFS filesystem code, reproduced main/compat unit tests, and built the
compat kmod, but did not reproduce the unavailable agent/perf benchmark
submodules or mounted VM e2e path. BranchFS, Sandlock, AgentFS, Redis Agent
Filesystem, and Mirage are concrete agent-filesystem or workspace sources with
public implementations.

2026-07-01 reproduction update: BranchFS and Sandlock have now been exercised
through upstream workload/test entry points. BranchFS passed release build, all
upstream test suites, and quick benchmarks. Sandlock passed release build, CLI
tests, Go in-tree SDK tests, COW/protected-path smoke, and most Rust/Python SDK
tests, with named UNIX socket deny and two Python resource-control negatives
preserved. The dedicated record is
`docs/tmp/2026-07-01-branchfs-sandlock-workload-reproduction.md`.

2026-07-01 agent-runtime/environment update: OpenHands SDK, Terminal-Bench,
SWE-MiniSandbox, SWE-ReX, AgentCgroup, SWE-rebench V2, and SWE-Factory-Gym have
executable subset evidence. OpenHands SDK passed 195 targeted
workspace/file/terminal tests; Terminal-Bench passed unit, installed-agent, and
Docker-backed run/resume/status tests; SWE-MiniSandbox passed private `/tmp`
isolation tests; SWE-ReX passed a local runtime subset after excluding one
auth-status API drift; AgentCgroup passed local daemon/wrapper tests and trace
characterization, built scheduler/process components, and failed only the
memcg component because running kernel BTF lacks `memcg_bpf_ops`; SWE-rebench
V2 passed prompt rendering and a one-task Docker sample eval; SWE-Factory-Gym
`pallets__click-2622` passed a one-task upstream evaluator run with 40 pytest
tests and `resolved=true`. MEnvAgent and DockSmith provide full dataset and
trajectory artifacts but not closed executable system reproductions; Multi-
Docker-Eval provides a 334-row task parquet and evaluator shape but still needs
`docker_res`. The dedicated records are
`docs/tmp/2026-07-01-agent-runtime-environment-workload-reproduction.md` and
`docs/tmp/2026-07-01-environment-dataset-and-partial-fs-reproduction-update.md`.

## Archived Boundary Rows

The repository contains older exact-map and materialized-view diagnostic rows.
They are retained as historical boundary evidence and negative/mixed results.
They are not the next research direction, and they should not be used to frame
the novelty argument. The paper-facing rule is simpler: keep main workloads
when they have real code, a real oracle, observable state transitions, and
operation-weighted path signal.

## What Must Be True Before Reporting A Main Workload

A real workload should be reported in the main evaluation only after a
Make-owned KVM result records all of the following:

1. Real workload source and provenance, not only a controlled fixture.
2. A workload oracle: output hash, service health, restore health, secret
   non-exposure, stale/corrupt rejection, or zero mixed epoch.
3. Operations issued during the relevant state transition, not only before and
   after.
4. Operation-weighted branch distribution over the real trace.
5. Same-oracle comparisons against natural mechanisms: FUSE, materialized view,
   projected/bind/copy/symlink/Overlay where applicable, and native workload
   mechanism where applicable.
6. The summary row must say whether the run is main evidence, appendix evidence,
   or a negative result.

## Paper Wording

Safe wording now:

> We select workloads because they have reproducible code, executable oracles,
> observable path-state transitions, and operation-weighted path-resolution
> signal. Existing exact-table counterfactuals are archived boundary rows; they
> are not the novelty argument and should not drive the next experiments.

Current wording guard:

- Do not define any workload as a static-table counterexample.
- Do not claim that workloads require `namei_ext`, eBPF, or dynamic policy
  logic.
- Do not dismiss YoloFS, DockSmith, ExtFUSE, Bento, DeltaFS, IndexFS, or
  TableFS because they are not all direct workload seeds.
- Do state the evidence target: real source, workload oracle, transition-time
  operations, operation-weighted path signal, natural baselines, and a verdict
  that can narrow the claim.

## Recommended paper set

For a conservative paper:

- Main positive workload: W2 service fixture sandbox.
- Main C8 candidate: W4 content-verified cache and environment reuse.
- Main agent workload candidate: AI agent workspace lifecycle from
  BranchFS/Sandlock/SWE-agent/OpenHands/Terminal-Bench style sources.

For a stronger full-release paper, run the AI agent workspace lifecycle and W4
live stale/corrupt/update-window first, then W2 real reload/update. W3 should
not remain a separate paper-facing workload unless it is a real agent rollback
or Podman/CRIU transition trace.
