# Agent Workspace Source-Lifecycle Repair Run

Timestamp: 2026-07-14T17:32:37-0700
Phase: BUILD_AND_EVALUATE
Step: `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/`
Gate: EXPERIMENT_GATE
Experiment: Agent workspace lifecycle
Status: completed Make-owned KVM run; result review pending

## Question And Entry

The previous result review and protocol repair run left the source-oracle gap
open for final Experiment A. The missing evidence was not another weak
baseline. It was the AgentFS-derived lifecycle content required by the frozen
experiment plan:

- source-derived rename;
- source-derived unlink;
- cached-negative creation and invalidation;
- bash/git command-sequence or source-trace evidence;
- source-tied RQ3 boundary rows;
- broader invalid-policy containment beyond generic smoke checks.

This node repairs the source-lifecycle and boundary-row part without changing
the frozen RQs, comparison families, workload families, or paper story.

## Inputs And Method

Instructions and plans read:

- `docs/user-instruction.md`;
- `docs/evaluation.md`;
- `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`;
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/step-report.md`;
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/003-result-review-20260714T155300-0700.md`;
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/004-protocol-repair-run-20260714T161245-0700.md`.

Files changed:

- `tests/agent_workspace/namei_ext_agent_workspace.c`;
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`;
- `mk/kvm.mk`.

Implementation changes:

- Both the `namei_ext` and FUSE runners now emit a source-trace declaration
  tying the matrix to the AgentFS reproduction record's bash/git workspace
  lifecycle shape: branch `.git` state, edited `src/app`, whiteout, symlink,
  create, rename, unlink, and cached-negative invalidation.
- The existing rename, unlink, and cached-negative operations are now required
  by the Make hard gate for both `namei_ext` and FUSE rows.
- RQ3 boundary rows now include source-oracle scope, owned methods,
  daemon/runtime state, metadata state, data/write-path owner, privileged code
  surface, and containment responsibility for `namei_ext`,
  feature-equivalent FUSE, and custom/stackable filesystem ownership.

Commands:

```text
make agent-workspace
make -n __experiment_agent_workspace_matrix RUN_ID=dryrun-source-lifecycle-gates
make experiment-agent-workspace
```

## Results And Raw Evidence

Raw result root:

```text
results/experiments/agent-workspace-matrix/20260715T003201Z-a12b8555/
```

Preserved artifacts:

- `agent-workspace-matrix.jsonl`;
- `dmesg-agent-workspace-matrix.log`;
- `agent-workspace-matrix-inputs.sha256`;
- `agent-workspace-matrix-command.txt`;
- `kernel.config`;
- `uname.txt`;
- `proc-version.txt`;
- `kernel-cmdline.txt`;
- `stdout-agent-workspace-matrix.log`;
- `stderr-agent-workspace-matrix.log`.

Raw checks:

- rows: 724;
- `pass == false` rows: 0;
- case rows: 90;
- metric rows: 8;
- latency sample rows: 600;
- boundary rows: 3;
- policy/FUSE counter rows: 18;
- dmesg target-error grep: no hits for `BUG:`, `WARNING:`, `Oops:`,
  `Call Trace:`, hung task, general protection, NULL pointer, KASAN, or UBSAN.

Source-lifecycle rows now pass for both mechanisms:

- `agentfs_source_trace_declared`;
- `agentfs_cached_negative_before_create`;
- `agentfs_cached_negative_create`;
- `agentfs_cached_negative_visible`;
- `agentfs_rename_generated_to_renamed`;
- `agentfs_rename_generated_old_absent`;
- `agentfs_rename_generated_new_visible`;
- `agentfs_rename_restored_generated`;
- `agentfs_unlink_cached_created`;
- `agentfs_unlink_cached_absent`;
- the corresponding `fuse_agentfs_*` rows.

Observed aggregate latency metrics:

| Metric | ns/op |
| --- | ---: |
| `nohook_stat_base_main_ns` | 1175 |
| `nohook_readdir_base_ns` | 1875 |
| `namei_ext_stat_main_ns` | 1032 |
| `namei_ext_readdir_ws_ns` | 3044 |
| `fuse_nohook_stat_base_main_ns` | 618 |
| `fuse_nohook_readdir_base_ns` | 1888 |
| `fuse_stat_main_ns` | 28488 |
| `fuse_readdir_ws_ns` | 50920 |

## Scientific Impact And Decision

Research value before result review: candidate Experiment A evidence, not yet
paper evidence.

The run closes several concrete gaps from the previous result review:

- source-like `.git` and `src` rows remain present;
- rename, unlink, and cached-negative lifecycle rows now execute and are hard
  gated for both `namei_ext` and FUSE;
- FUSE remains feature-equivalent for this matrix and exercises rename/unlink
  counters;
- boundary rows are now source-tied rather than generic mechanism labels.

Remaining uncertainty for result review:

- whether the source-trace declaration plus reduced bash/git-shaped matrix is
  strong enough to count as source-derived AgentFS lifecycle evidence;
- whether the limited RQ2 metric set is sufficient for a paper result or still
  only supporting overhead evidence;
- whether unregistered-target containment plus source-tied ownership rows are
  enough for the current RQ3 cell, or whether a separate malformed/unsupported
  policy row is required before final interpretation.

## Next Action

Run an independent result review over this plan, code scope, and raw result
root. Do not route to WRITE_GATE or update paper result slots until that review
classifies run status, tested hypothesis, research value, paper impact, and
next paper decision.
