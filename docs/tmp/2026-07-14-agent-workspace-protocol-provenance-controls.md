# Agent Workspace Protocol Provenance And Control Repair

Date: 2026-07-14

## Motivation

The BUILD_AND_EVALUATE Agent workspace matrix run
`results/experiments/agent-workspace-matrix/20260714T225035Z-deaf17c0/` passed
its synthetic KVM/FUSE fixture, but independent result review classified it as
incomplete/supporting rather than final Experiment A evidence. Before adding
more source-derived lifecycle behavior, the protocol-level blockers needed to
be removed so future runs preserve enough raw evidence for OSDI/SOSP-style
result review.

The repaired protocol addresses the review findings that were independent of
the source-oracle gap:

- matrix summaries should not be labeled as preflight summaries;
- result roots should preserve command/provenance files, input hashes, kernel
  config, stdout, and stderr;
- no-hook controls should include latency metrics, not only correctness rows;
- the FUSE row should explicitly record its cache/foreground/single-threaded
  options.

This repair does not claim final Experiment A evidence. The workload still
needs AgentFS-derived lifecycle rows such as rename, unlink, cached-negative
creation, and a source-tied RQ3 boundary table.

## Files Inspected

- `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`
- `docs/tmp/2026-07-02-agentfs-official-workload-reproduction.md`
- `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/01-experiment-gate/experiment-001-agent-workspace/003-result-review-20260714T155300-0700.md`
- `tests/agent_workspace/namei_ext_agent_workspace.c`
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`
- `mk/kvm.mk`

## Implementation Details

Runner changes:

- `tests/agent_workspace/namei_ext_agent_workspace.c`
  - records `agent_workspace_matrix_summary` when invoked with `--matrix`;
  - keeps `agent_workspace_preflight_summary` for the preflight path;
  - adds `nohook_stat_base_main_ns` and `nohook_readdir_base_ns` metrics.
- `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`
  - records `fuse_agent_workspace_matrix_summary` when invoked with
    `--matrix`;
  - keeps `fuse_agent_workspace_preflight_summary` for the preflight path;
  - adds `fuse_nohook_stat_base_main_ns` and
    `fuse_nohook_readdir_base_ns` metrics;
  - records `fuse_options_recorded` with
    `foreground=true,single_threaded=true,attr_timeout=0,entry_timeout=0,negative_timeout=0`.

Make target changes:

- `mk/kvm.mk`
  - records `agent-workspace-matrix-command.txt`;
  - records `agent-workspace-matrix-inputs.sha256` over kernel image, kernel
    config, policy object/source, runner binaries/sources, Makefile, `mk/kvm.mk`,
    and the complete-experiment plan;
  - copies `kernel.config`;
  - records `uname.txt`, `proc-version.txt`, and `kernel-cmdline.txt`;
  - preserves `stdout-agent-workspace-matrix.log` and
    `stderr-agent-workspace-matrix.log`;
  - emits an `agent-workspace-provenance` JSONL row;
  - hard-gates the new summary names, no-hook metrics, FUSE options record, and
    provenance files.

## Validation

Commands:

```text
make -n __experiment_agent_workspace_matrix RUN_ID=dryrun-agent-workspace-protocol
make agent-workspace
make experiment-agent-workspace
```

Results:

- `make -n __experiment_agent_workspace_matrix` expanded the expected
  provenance commands, hash file generation, runner stdout/stderr capture, and
  hard gates.
- `make agent-workspace` rebuilt both C runners successfully.
- `make experiment-agent-workspace` passed through KVM.

New raw result root:

```text
results/experiments/agent-workspace-matrix/20260714T231148Z-7e0cc0e8/
```

Observed files:

- `agent-workspace-matrix.jsonl` with 702 rows;
- `dmesg-agent-workspace-matrix.log` with 433 lines;
- `agent-workspace-matrix-inputs.sha256` with 11 inputs;
- `agent-workspace-matrix-command.txt`;
- `kernel.config`;
- `uname.txt`;
- `proc-version.txt`;
- `kernel-cmdline.txt`;
- `stdout-agent-workspace-matrix.log`;
- `stderr-agent-workspace-matrix.log`.

Key raw checks:

- `pass == false` rows: 0.
- Event counts include one `agent-workspace-provenance` row, eight
  `agent-workspace-metric` rows, and 600 sample rows.
- New metrics:
  - `nohook_stat_base_main_ns`: 611 ns/op;
  - `nohook_readdir_base_ns`: 2026 ns/op;
  - `namei_ext_stat_main_ns`: 1065 ns/op;
  - `namei_ext_readdir_ws_ns`: 2966 ns/op;
  - `fuse_nohook_stat_base_main_ns`: 570 ns/op;
  - `fuse_nohook_readdir_base_ns`: 1866 ns/op;
  - `fuse_stat_main_ns`: 22824 ns/op;
  - `fuse_readdir_ws_ns`: 39807 ns/op.
- Summary/options rows passed:
  - `agent_workspace_matrix_summary`;
  - `fuse_options_recorded`;
  - `fuse_agent_workspace_matrix_summary`.
- Operation counters remained nonzero for both the `namei_ext` and FUSE paths.
- The Make-owned dmesg failure-pattern gate passed.

## Remaining Risks And Follow-up

This repair removes protocol blockers but does not close the final Experiment A
source-oracle gap. The next implementation work should add source-derived
AgentFS lifecycle rows under both `namei_ext` and the feature-equivalent FUSE
policy:

- rename;
- unlink;
- cached-negative creation;
- a bash/git-derived command sequence or source trace;
- source-tied RQ3 boundary rows for owned methods, daemon/runtime state,
  COW/checkpoint/audit metadata, data/write/persistence responsibility, and
  invalid-policy containment.

Until those rows exist and pass result review, the latest run is supporting
protocol evidence, not final paper evidence.
