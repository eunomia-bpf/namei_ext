# Terminal-Bench Build/Environment Suite Reproduction

Date: 2026-07-01

## Motivation

The active workload-reproduction goal is to identify and reproduce upstream
workloads before deciding which ones to turn into `namei_ext` experiments. This
run extends the selected official Terminal-Bench coverage with build and
environment repair tasks. These tasks are useful W4 environment/cache seeds
because they exercise package installation, dependency conflict repair, source
checkout/build, shell setup, and executable parser-test oracles.

This is upstream workload reproduction only. It is not a `namei_ext` KVM
validation run and not evidence that any workload requires eBPF.

## Command

Run from `.cache/source-inspection/terminal-bench`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id broken-python \
  --task-id build-cython-ext \
  --task-id npm-conflict-resolution \
  --task-id setup-custom-dev-env \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-build-env-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite/2026-07-01__terminal-bench-build-env-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite/2026-07-01__terminal-bench-build-env-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite/2026-07-01__terminal-bench-build-env-oracle-suite/run.log`
- Top-level harness log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-build-env-oracle-suite/tb-run.log`

## Result

The upstream harness completed four official tasks with the oracle agent:

- `n_resolved=3`
- `n_unresolved=1`
- `accuracy=0.75`
- parser checks: 24 passed, 1 failed

| Task | Result | Parser checks | Workload shape |
| --- | --- | --- | --- |
| `broken-python` | resolved | 2/2 passed | Repair system Python/pip and verify package install. |
| `npm-conflict-resolution` | resolved | 5/5 passed | Resolve Node.js/npm dependency conflicts while preserving package constraints. |
| `setup-custom-dev-env` | resolved | 7/7 passed | Install/configure zsh, oh-my-zsh, plugins, Miniconda, and a login conda environment across zsh/bash. |
| `build-cython-ext` | unresolved | 10/11 passed | Clone `pyknotid`, fix NumPy 2.3 compatibility, build Cython extensions, and run imports/example/repository tests. |

`build-cython-ext` is a useful preserved negative. The oracle-agent run passed
the NumPy version check, repository clone check, core import check, all three
Cython extension import checks, extension behavior checks, Python-vs-Cython
comparison, and README example usage. It failed only
`test_pyknotid_repository_tests`, so the workload is not cleanly resolved by
the unmodified official run.

## Reuse Decision

Reusable workload shapes:

- Python package-management repair and system package-install oracle.
- Node.js dependency conflict repair and installed package-tree oracle.
- Shell and conda development-environment materialization oracle.
- Source checkout plus compiled-extension build and import/example oracle.

These tasks are good W4 environment/cache candidates because they combine
repository state, generated dependency trees, installed artifacts, and parser
tests. They are still command-heavy upstream tasks; before using them as
`namei_ext` release workloads, the project needs a Make-owned KVM workload that
extracts the relevant path-view/cache/environment state transitions and compares
against source/native, FUSE/source-system, and materialized baselines.

## Boundary

This run should be described as selected official Terminal-Bench task
reproduction, not full Terminal-Bench-Core reproduction. The unresolved
`build-cython-ext` row must remain visible as a workload-level oracle failure,
not silently filtered out.
