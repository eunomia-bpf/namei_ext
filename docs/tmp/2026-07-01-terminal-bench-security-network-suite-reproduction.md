# Terminal-Bench Security/Network Suite Reproduction

Date: 2026-07-01

## Motivation

This record extends selected Terminal-Bench official-task reproduction with
security, code-vulnerability, exploit, and network-repair tasks. The purpose is
to identify reusable workload shapes and correctness oracles for `namei_ext`,
not to argue that these tasks require `namei_ext`, eBPF, or any specific policy
mechanism.

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

- `results/reproduction/2026-07-01-official-workloads/terminal-bench-security-network-oracle-suite/`

Command shape:

```text
uv run tb run
  --dataset-path original-tasks
  --task-id vulnerable-secret
  --task-id fix-code-vulnerability
  --task-id sql-injection-attack
  --task-id vul-flask
  --task-id broken-networking
  --task-id cron-broken-network
  --agent oracle
  --n-concurrent 1
  --n-attempts 1
  --run-id 2026-07-01__terminal-bench-security-network-oracle-suite
  --no-upload-results
  --cleanup
```

## Workload Shapes

| Task | Workload shape | Oracle |
| --- | --- | --- |
| `sql-injection-attack` | Multi-container vulnerable/master API services, exploit SQL injection, and delete targeted users through the service interface. | Target users are deleted and the API usage/deletion log is verified. |
| `vul-flask` | Modify a vendored Flask 1.1.1 tree to reject server-side template injection while preserving Flask identity. | HTTP requests render injected expressions as text and server/version checks pass. |
| `vulnerable-secret` | Exploit a vulnerable binary and materialize the recovered flag into `/app/results.txt`. | Result file exists, contains the exact expected flag, and has the expected format. |
| `fix-code-vulnerability` | Patch Bottle header handling to reject CRLF/control-character injection while preserving upstream behavior. | Upstream Bottle regression tests pass, and the task report identifies `/app/bottle.py` plus CWE-93. |
| `cron-broken-network` | Repair `/usr/bin/curl` while recurring cron/at/init paths attempt to re-break it, then fetch live `example.com`. | Curl binary existence/integrity checks pass, but the live content comparison failed in this environment. |
| `broken-networking` | Repair system networking enough for `apt`, `curl`, `uv`, and pytest setup, then fetch live `example.com`. | Test setup did not complete because Ubuntu mirror access failed before curl/uv/pytest installation. |

## Results

Suite-level result:

| Metric | Value |
| --- | --- |
| Dataset size | 6 |
| Resolved | 4 |
| Unresolved | 2 |
| Accuracy | 0.6666666666666666 |
| Clean reproduction | No |

Per-task result:

| Task | Result | Parser checks | Boundary |
| --- | --- | --- | --- |
| `sql-injection-attack` | Resolved | 2/2 passed | None. |
| `vul-flask` | Resolved | 3/3 passed | None. |
| `vulnerable-secret` | Resolved | 3/3 passed | None. |
| `fix-code-vulnerability` | Resolved | 373/373 passed | None. |
| `cron-broken-network` | Unresolved | 2/3 passed | Pytest ran, but the live `example.com` content check matched only 10/46 expected lines. |
| `broken-networking` | Parse error | 0/0 parsed | `apt` could not connect to `archive.ubuntu.com`, so curl, uv, and pytest setup did not complete. |

## Raw Artifacts

Key artifacts under the result root:

- `summary.json`
- `tb-run.log`
- `2026-07-01__terminal-bench-security-network-oracle-suite/results.json`
- `2026-07-01__terminal-bench-security-network-oracle-suite/run.log`
- `2026-07-01__terminal-bench-security-network-oracle-suite/run_metadata.json`
- Per-task `commands.txt`, `panes/`, `sessions/`, and `results.json`

## Interpretation

This run adds four clean official Terminal-Bench workload seeds. The strongest
reusable tasks are `sql-injection-attack`, `vul-flask`,
`vulnerable-secret`, and `fix-code-vulnerability`, because their oracles are
self-contained inside the task container or service graph.

The two network-repair tasks should not be main workload seeds in their current
form. `broken-networking` failed before the task oracle because the test setup
could not reach Ubuntu mirrors. `cron-broken-network` reached the oracle and
verified curl binary integrity, but the final assertion depends on live
`example.com` HTML content. They are useful as evidence that Terminal-Bench
contains live-network/system-repair tasks, but not as stable release workloads
unless we vendor or mock the external network dependency in a future
Make-owned harness.

Together with earlier Terminal-Bench runs, selected official-task reproduction
now covers 31 resolved tasks plus three unresolved or setup/content-boundary
tasks. This is still selected official-task reproduction, not full
Terminal-Bench-Core reproduction.

## Reuse Decision

Use the passing tasks as workload-source evidence for:

- service-state mutation through an exploit/API path;
- vendored dependency repair with HTTP-level correctness;
- binary exploit output materialization;
- code-vulnerability repair with large regression-suite preservation and CWE
  reporting.

Keep the two live-network tasks as boundaries. Do not present them as clean
reproduced workload seeds until their external mirror/content dependencies are
controlled.
