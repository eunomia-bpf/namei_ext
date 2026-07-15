# Agent Workspace Matrix RQ2 Metric And Hard-Gate Repair

Date: 2026-07-14

## Motivation

BUILD_AND_EVALUATE step 0003 restarted Experiment A, the Agent workspace
lifecycle matrix, under the renewed frozen contract. The existing Make-owned
KVM matrix was the correct execution path, but inspecting the first new raw run
showed one measurement defect and one gate-coverage gap:

- aggregate latency metrics included JSONL sample emission overhead;
- the Make hard gate did not require the newer source-like `.git`/`src` rows
  or parent `ws` readdir coherence rows.

These were implementation and protocol defects in the existing admitted
experiment, not reasons to change the paper hypothesis or add a new baseline.

## Code Paths Inspected

- `tests/agent_workspace/namei_ext_agent_workspace.c`
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`
- `mk/kvm.mk`
- `results/experiments/agent-workspace-matrix/20260714T224916Z-9b4f6dec/`

## Design Choice

For latency measurement, raw per-operation samples are the primary observations.
The aggregate metric should be a mean over those measured samples, not a timer
covering sample serialization. Both `namei_ext` and FUSE runners now accumulate
the measured sample durations and emit aggregate ns/op from that sum.

For completeness, `kvm-agent-workspace-matrix` now fails if the current
source-like and parent-alias rows are absent. This keeps the Make target aligned
with the complete experiment contract and avoids accepting a preflight-sized
matrix as a full result.

## Implementation Details

Changed `measure_stat_latency()` and `measure_readdir_latency()` in both
runner files:

- removed the outer elapsed timer;
- accumulated each operation's measured `sample_elapsed`;
- emitted aggregate ns/op as `total_elapsed / reps`;
- preserved all raw sample rows.

Changed `mk/kvm.mk` required-case list for `kvm-agent-workspace-matrix` to
include:

- `setup_source_dirs`
- `nohook_parent_lists_ws`
- `policy_parent_lists_ws`
- `base_epoch_src_app`
- `base_epoch_git_head`
- `upper_epoch_src_app`
- `upper_epoch_git_head`
- matching FUSE source/parent rows
- final manifests and invalid-target containment rows

## Validation

Commands:

```text
make agent-workspace
make experiment-agent-workspace
```

Final raw root:

`results/experiments/agent-workspace-matrix/20260714T225035Z-deaf17c0/`

Observed results:

- `make agent-workspace` passed.
- `make experiment-agent-workspace` passed through KVM and the real
  `cgroup/namei_ext` attach path.
- Raw JSONL contains 396 rows and no `pass == false` rows.
- Raw JSONL contains 300 sample rows:
  - 100 `namei_ext_stat_main_ns`
  - 50 `namei_ext_readdir_ws_ns`
  - 100 `fuse_stat_main_ns`
  - 50 `fuse_readdir_ws_ns`
- Aggregate metrics after the fix:
  - `namei_ext_stat_main_ns`: 1088 ns/op
  - `namei_ext_readdir_ws_ns`: 3031 ns/op
  - `fuse_stat_main_ns`: 23314 ns/op
  - `fuse_readdir_ws_ns`: 40807 ns/op
- Required source-like, parent-alias, FUSE parity, manifest, metric, boundary,
  and invalid-target containment rows passed the Make hard gate.
- Dmesg had no matched kernel failure pattern.

## Remaining Risks

This repair improves the admitted Agent workspace matrix but does not by itself
make the run final paper evidence. Independent result review still needs to
judge:

- whether the workload is source-derived enough for headline Experiment A;
- whether FUSE fairness and cache-policy choices are sufficient for RQ2;
- whether the RQ3 boundary rows are enough or need a source-backed Markdown
  ownership account;
- whether macro command runtime and broader operation coverage are still needed.
