# Terminal-Bench Environment/Debug Suite Reproduction

Date: 2026-07-01

## Motivation

This run extends selected official Terminal-Bench workload reproduction to
environment-debugging and dependency-repair tasks. These tasks are useful W4
environment/cache seeds because they exercise Python package compatibility,
conda environment repair, data-analysis dependency pinning, and
scientific-computing setup.

This is upstream workload reproduction only. It is not a `namei_ext` KVM
validation run and not evidence that any workload requires eBPF.

## Command

Run from `.cache/source-inspection/terminal-bench`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id fix-pandas-version \
  --task-id incompatible-python-fasttext \
  --task-id conda-env-conflict-resolution \
  --task-id amuse-install \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-env-debug-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/2026-07-01__terminal-bench-env-debug-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/2026-07-01__terminal-bench-env-debug-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/2026-07-01__terminal-bench-env-debug-oracle-suite/run.log`
- Top-level harness log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/tb-run.log`
- `amuse-install` partial agent log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-env-debug-oracle-suite/2026-07-01__terminal-bench-env-debug-oracle-suite/amuse-install/amuse-install.1-of-1.2026-07-01__terminal-bench-env-debug-oracle-suite/sessions/agent.log`

## Result

The upstream harness requested four official tasks. Its `results.json` contains
three reported task results:

- `n_resolved=2`
- `n_unresolved=1`
- `accuracy=0.6666666666666666`
- parser checks among reported tasks: 6 passed, 0 failed
- attempted without result summary: `amuse-install`

| Task | Result | Parser checks | Workload shape |
| --- | --- | --- | --- |
| `conda-env-conflict-resolution` | resolved | 3/3 passed | Repair a conda environment conflict, update `environment.yml`, and verify import-script execution. |
| `fix-pandas-version` | resolved | 3/3 passed | Pin pandas/pyarrow versions and verify data-loading and customer-segmentation analysis. |
| `incompatible-python-fasttext` | unresolved before parser | no parser summary | Build/debug Python package compatibility for `fasttext`; Docker compose build failed while compiling `fasttext==0.9.3` under Python 3.13. |
| `amuse-install` | attempted without result summary | no parser summary | Create an AMUSE virtualenv and run a scientific-computing example; the run reached the oracle solution but no per-task `results.json` was produced. |

`incompatible-python-fasttext` failed before the agent or parser tests ran. The
Docker build tried `pip install fasttext==0.9.3`; g++ then hit an internal
compiler error while compiling `src/args.cc`. This is a setup/build-level
boundary, not a failed application oracle.

`amuse-install` is not counted in `accuracy`. The metadata lists it as a
requested task and log artifacts exist, but the task produced no upstream
parser summary. The harness log reached `bash /oracle/solution.sh`, and the
task container later exited 255. Keep this as an incomplete attempt unless a
separate run produces a normal Terminal-Bench result.

## Reuse Decision

Reusable workload shapes:

- conda dependency conflict repair with executable import oracles;
- pandas/pyarrow data-analysis dependency pinning with data-processing tests;
- native Python extension build/debug setup boundaries;
- scientific-computing virtualenv installation and example execution shape.

The first two are clean W4 environment/cache seeds. The fastText task is useful
as a native-extension build boundary but needs a controlled base image or
upstream-compatible Python version before it can be a clean release workload.
The AMUSE task is a useful task shape but is not yet a reproduced oracle result
from this run.

## Boundary

This run should be described as selected official Terminal-Bench task
reproduction, not full Terminal-Bench-Core reproduction. Report the cumulative
selected unmodified official-task count as 54 resolved and seven unresolved or
setup/content/artifact/workload-boundary tasks, plus one attempted task without
an upstream result summary.
