# Terminal-Bench Data/Log/Service Suite Reproduction

Date: 2026-07-01

## Motivation

This record extends selected Terminal-Bench official-task reproduction with
data conversion, multi-file aggregation, log analysis, service execution, and
database recovery tasks. The purpose is to identify reusable workload shapes
and correctness oracles for `namei_ext`, not to argue that these tasks require
`namei_ext`, eBPF, or any specific policy mechanism.

This is a dated evidence note. Durable related-work and workload-source
verdicts belong in `docs/background-related-work.md`; stable source facts
belong in `docs/reference/CODE_SOURCES.md`; raw results stay under `results/`.

## Source And Command

Source:

- Repository: `https://github.com/laude-institute/terminal-bench`
- Commit: `1a6ffa9674b571da0ed040c470cb40c4d85f9b9b`
- Dataset path: `original-tasks`
- Agent: upstream `oracle`

Result root:

- `results/reproduction/2026-07-01-official-workloads/terminal-bench-data-log-service-oracle-suite/`

Command shape:

```text
uv run tb run
  --dataset-path original-tasks
  --task-id csv-to-parquet
  --task-id jsonl-aggregator
  --task-id analyze-access-logs
  --task-id fibonacci-server
  --task-id db-wal-recovery
  --agent oracle
  --n-concurrent 1
  --n-attempts 1
  --run-id 2026-07-01__terminal-bench-data-log-service-oracle-suite
  --no-upload-results
  --cleanup
```

## Workload Shapes

| Task | Workload shape | Oracle |
| --- | --- | --- |
| `csv-to-parquet` | Convert `/app/data.csv` into `/app/data.parquet`. | Parquet file exists; dataframe exactly matches the CSV input. |
| `jsonl-aggregator` | Aggregate multiple `/app/records_*.jsonl` files into `/app/aggregates.json`. | Exact top-5 users and top-5 tags JSON structure and values. |
| `analyze-access-logs` | Scan `/app/access_log` and materialize `/app/report.txt`. | Total requests, unique IPs, 404 count, top URLs, and report format checks. |
| `fibonacci-server` | Start a long-running HTTP server on port 3000 with `/fib?n=` endpoint. | Service responds; small/large Fibonacci results match; invalid inputs return 400. |
| `db-wal-recovery` | Recover an SQLite database from an encrypted/corrupted WAL file and write `/app/recovered.json`. | JSON exists, is valid, sorted, complete, has no duplicate IDs, and contains WAL updates. |

## Results

Suite-level result:

| Metric | Value |
| --- | --- |
| Dataset size | 5 |
| Resolved | 5 |
| Unresolved | 0 |
| Accuracy | 1.0 |
| Clean reproduction | Yes |

Per-task result:

| Task | Result | Parser checks |
| --- | --- | --- |
| `fibonacci-server` | Resolved | 6/6 passed |
| `csv-to-parquet` | Resolved | 2/2 passed |
| `db-wal-recovery` | Resolved | 7/7 passed |
| `analyze-access-logs` | Resolved | 3/3 passed |
| `jsonl-aggregator` | Resolved | 1/1 passed |

## Raw Artifacts

Key artifacts under the result root:

- `summary.json`
- `tb-run.log`
- `2026-07-01__terminal-bench-data-log-service-oracle-suite/results.json`
- `2026-07-01__terminal-bench-data-log-service-oracle-suite/run.log`
- `2026-07-01__terminal-bench-data-log-service-oracle-suite/run_metadata.json`
- Per-task `commands.txt` and `results.json`

## Interpretation

This run adds five clean official Terminal-Bench workload seeds. The data tasks
exercise file materialization and exact output equivalence. The log task
exercises scan-and-report behavior over existing application logs. The service
task exercises long-running server setup and query validation. The WAL recovery
task exercises a state-recovery path where base database state and WAL changes
must be combined into a materialized JSON oracle.

Together with earlier Terminal-Bench runs, selected official-task reproduction
now covers 21 resolved tasks plus one preserved setup-level negative task. This
is still selected official-task reproduction, not full Terminal-Bench-Core
reproduction.

## Reuse Decision

Use these tasks as workload-source evidence for:

- file conversion and materialized output equivalence;
- multi-file aggregation and exact JSON oracle checks;
- log scanning and report materialization;
- long-running service setup with endpoint-state oracle;
- database state recovery and stale/base-versus-WAL correctness checks.

Do not present this as full Terminal-Bench-Core reproduction. It is a selected
official-task expansion that strengthens the workload-source pool for future
Make-owned, KVM-validated `namei_ext` experiments.
