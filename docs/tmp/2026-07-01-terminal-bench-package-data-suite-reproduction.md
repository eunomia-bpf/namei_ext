# Terminal-Bench Package/Data Suite Reproduction

Date: 2026-07-01

## Motivation

This record extends the selected Terminal-Bench official-task reproduction with
package, service, database, and data-integration tasks. The goal is to identify
reusable workload shapes and correctness oracles for `namei_ext`, not to prove
that those tasks require `namei_ext`, eBPF, or any specific mechanism.

This record is intentionally a dated evidence note. Durable related-work and
workload-source verdicts belong in `docs/background-related-work.md`; stable
source facts belong in `docs/reference/CODE_SOURCES.md`; raw outputs stay under
`results/`.

## Source And Command

Source:

- Repository: `https://github.com/laude-institute/terminal-bench`
- Commit: `1a6ffa9674b571da0ed040c470cb40c4d85f9b9b`
- Dataset path: `original-tasks`
- Agent: upstream `oracle`

Result root:

- `results/reproduction/2026-07-01-official-workloads/terminal-bench-package-data-oracle-suite/`

Command shape:

```text
uv run tb run
  --dataset-path original-tasks
  --task-id pypi-server
  --task-id home-server-https
  --task-id postgres-csv-clean
  --task-id multi-source-data-merger
  --agent oracle
  --n-concurrent 1
  --n-attempts 1
  --run-id 2026-07-01__terminal-bench-package-data-oracle-suite
  --no-upload-results
  --cleanup
```

## Workload Shapes

| Task | Workload shape | Oracle |
| --- | --- | --- |
| `multi-source-data-merger` | Multi-source JSON/CSV/Parquet ingestion, schema mapping, priority merge, conflict reporting, and Parquet output materialization. | Output files exist; merged data exact values match; conflict report exact values match. |
| `home-server-https` | DNS entry setup, self-signed certificate materialization, Nginx HTTPS configuration, HTTPS content serving, and mock API access. | HTML exists; certificate files exist; Nginx SSL config, process, port, DNS, HTTPS, certificate validity, content, and mock API checks pass. |
| `postgres-csv-clean` | Intended PostgreSQL CSV import, in-database cleaning, `pg_stat_statements` evidence, and CSV export. | Not reached; setup failed before agent/test execution. |
| `pypi-server` | Local PyPI server setup, Python package build/upload, pip install via local index, and package API check. | Package API check passes. |

## Results

Suite-level result:

| Metric | Value |
| --- | --- |
| Dataset size | 4 |
| Resolved | 3 |
| Unresolved | 1 |
| Accuracy | 0.75 |
| Clean reproduction | No; one setup-level negative task was preserved. |

Per-task result:

| Task | Result | Parser checks |
| --- | --- | --- |
| `multi-source-data-merger` | Resolved | 3/3 passed |
| `home-server-https` | Resolved | 10/10 passed |
| `postgres-csv-clean` | Setup-level negative | No parser checks; failed before agent/test execution |
| `pypi-server` | Resolved | 1/1 passed |

## Negative Result

`postgres-csv-clean` failed before the oracle agent or task tests ran. The
Terminal-Bench harness reported `failure_mode=unknown_agent_error` after
`docker compose up -d` failed. A separate diagnostic replay reproduced the
failure and preserved the raw compose output.

The Postgres sidecar reached container creation/startup, then exited with code
2 before becoming healthy. The diagnostic log records:

```text
dependency failed to start: container postgres_db exited (2)
ls: cannot open directory '/docker-entrypoint-initdb.d/': Permission denied
```

This is a setup-level artifact boundary, not an oracle correctness failure for
the database-cleaning workload itself.

## Raw Artifacts

Key artifacts under the result root:

- `summary.json`
- `tb-run.log`
- `postgres-csv-clean-compose-diagnostic.log`
- `2026-07-01__terminal-bench-package-data-oracle-suite/results.json`
- `2026-07-01__terminal-bench-package-data-oracle-suite/run.log`
- `2026-07-01__terminal-bench-package-data-oracle-suite/run_metadata.json`

## Interpretation

This run adds three resolved official Terminal-Bench package/service/data
workload seeds: local PyPI/package serving, HTTPS/DNS/service setup, and
multi-source data integration. It also preserves one setup-level negative
PostgreSQL task whose intended shape is useful but whose current upstream
container setup did not reach the oracle on this host.

Together with earlier Terminal-Bench runs, selected official-task reproduction
now covers 16 resolved tasks plus one preserved setup-level negative task. This
is still selected official-task reproduction, not full Terminal-Bench-Core
reproduction.

## Reuse Decision

Use the resolved tasks as workload-source evidence for:

- package-server and dependency-install path setup;
- service/DNS/TLS artifact materialization;
- multi-source data merge materialization and exact output checks.

Keep `postgres-csv-clean` as a candidate shape for future database
configuration/secret/rotation work, but do not cite it as a reproduced
Terminal-Bench workload until its setup-level failure is resolved.
