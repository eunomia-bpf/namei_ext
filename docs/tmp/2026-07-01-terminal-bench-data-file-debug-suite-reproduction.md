# Terminal-Bench Data/File/Debug Suite Reproduction

Date: 2026-07-01

## Motivation

This run extends selected official Terminal-Bench workload reproduction to
file-output, log-recovery, structured-data, and lightweight debugging tasks.
These are useful agent-workspace and W4 environment/cache seeds because they
exercise real working-directory inputs, generated files, exact output oracles,
dependency files, and compile/test checks without relying on large model
downloads or QEMU-heavy setup.

This is upstream workload reproduction only. It is not a `namei_ext` KVM
validation run and not evidence that any workload requires eBPF.

## Command

Run from `.cache/source-inspection/terminal-bench`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id recover-accuracy-log \
  --task-id regex-log \
  --task-id bank-trans-filter \
  --task-id organization-json-generator \
  --task-id modernize-scientific-stack \
  --task-id cpp-compatibility \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-data-file-debug-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite/2026-07-01__terminal-bench-data-file-debug-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite/2026-07-01__terminal-bench-data-file-debug-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite/2026-07-01__terminal-bench-data-file-debug-oracle-suite/run.log`
- Top-level harness log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-file-debug-oracle-suite/tb-run.log`

## Result

The upstream harness completed six official tasks with the oracle agent:

- `n_resolved=6`
- `n_unresolved=0`
- `accuracy=1.0`
- parser checks: 13 passed, 0 failed

| Task | Result | Parser checks | Workload shape |
| --- | --- | --- | --- |
| `bank-trans-filter` | resolved | 1/1 passed | Filter a transaction CSV with typo-tolerant company/account matching and write sorted JSON. |
| `cpp-compatibility` | resolved | 2/2 passed | Edit a header-only C++ template implementation to compile under C++11 while preserving its interface. |
| `recover-accuracy-log` | resolved | 3/3 passed | Recover generator/judge JSONL logs across three async runs and compute exact per-run accuracy. |
| `regex-log` | resolved | 1/1 passed | Write a regex that extracts the last valid date from log lines containing valid IPv4 addresses. |
| `organization-json-generator` | resolved | 4/4 passed | Materialize multi-CSV organization data into schema-valid JSON with relationship and statistics checks. |
| `modernize-scientific-stack` | resolved | 2/2 passed | Port a Python 2 climate-analysis script to Python 3 and provide a dependency file. |

## Reuse Decision

Reusable workload shapes:

- log recovery and per-run accuracy materialization with golden file oracles;
- regex/log analysis over working-directory inputs;
- CSV-to-JSON transformation with exact schema and relationship checks;
- source-file compatibility repair with compile oracles;
- legacy scientific script migration with dependency-file and execution oracles.

These are good selected Terminal-Bench workload seeds for agent workspaces and
environment/debug tasks. They remain command-heavy upstream terminal tasks; a
paper-facing `namei_ext` run should extract path-view state transitions and
correctness oracles, then run them through Make-owned KVM validation.

## Boundary

This run should be described as selected official Terminal-Bench task
reproduction, not full Terminal-Bench-Core reproduction. After this run, the
cumulative selected unmodified official-task count is 60 resolved and seven
unresolved or setup/content/artifact/workload-boundary tasks, plus one attempted
task without an upstream result summary.
