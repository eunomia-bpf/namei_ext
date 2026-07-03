# Terminal-Bench Service/API Suite Reproduction

Date: 2026-07-01

## Motivation

This run extends selected official Terminal-Bench workload reproduction to
local services and API-backed state. These tasks are useful workload seeds
because they exercise working-directory outputs, service startup, local
emulators, API-visible state, and exact test-script oracles.

This is upstream workload reproduction only. It is not a `namei_ext` KVM
validation run and not evidence that any workload requires eBPF.

## Command

Run from `.cache/source-inspection/terminal-bench`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id simple-web-scraper \
  --task-id create-bucket \
  --task-id mlflow-register \
  --task-id simple-sheets-put \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-service-api-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/2026-07-01__terminal-bench-service-api-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/2026-07-01__terminal-bench-service-api-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/2026-07-01__terminal-bench-service-api-oracle-suite/run.log`
- Top-level harness log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/tb-run.log`
- MLflow agent log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-service-api-oracle-suite/2026-07-01__terminal-bench-service-api-oracle-suite/mlflow-register/mlflow-register.1-of-1.2026-07-01__terminal-bench-service-api-oracle-suite/sessions/agent.log`

## Result

The upstream harness produced three official task results:

- `n_resolved=3`
- `n_unresolved=0`
- `accuracy=1.0`
- parser checks: 10 passed, 0 failed

| Task | Result | Parser checks | Workload shape |
| --- | --- | --- | --- |
| `simple-web-scraper` | resolved | 5/5 passed | Scrape a local web service and materialize CSV plus report outputs with structure, completeness, and accuracy checks. |
| `create-bucket` | resolved | 2/2 passed | Create an S3-compatible bucket in LocalStack and set API-visible public-read ACL state. |
| `simple-sheets-put` | resolved | 3/3 passed | Create spreadsheet API state backed by a local service and verify spreadsheet, sheet, and cell creation. |
| `mlflow-register` | attempted without result | no upstream result summary | Start MLflow, register model `gpt-5`, and exercise model-registry state; agent log shows registration, but the harness did not write a per-task result and the client container exited 255. |

## Reuse Decision

Reusable workload shapes:

- service-backed file materialization with a parser oracle;
- LocalStack/S3-compatible object-store namespace creation and ACL state;
- spreadsheet-like service state with table/cell creation oracles;
- MLflow model-registry setup as a candidate service-state workload, pending a
  clean upstream result summary.

These are good selected Terminal-Bench seeds for service/API state and W4
environment/cache work. The MLflow task should not be counted as reproduced
until the upstream harness emits a per-task result summary.

## Boundary

This run should be described as selected official Terminal-Bench task
reproduction, not full Terminal-Bench-Core reproduction. After this run, the
cumulative selected unmodified official-task count is 63 resolved and seven
unresolved or setup/content/artifact/workload-boundary tasks, plus two
attempted tasks without upstream result summaries.
