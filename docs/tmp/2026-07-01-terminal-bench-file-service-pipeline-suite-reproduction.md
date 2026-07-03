# Terminal-Bench File/Service/Pipeline Suite Reproduction

Date: 2026-07-01

## Motivation

This record extends selected Terminal-Bench official-task reproduction with
file editing, script-pipeline repair, secure service setup, Git recovery,
batch encryption, RPC service construction, network-flow conversion, and shell
deobfuscation tasks. The purpose is to identify reusable workload shapes and
correctness oracles for `namei_ext`, not to argue that these tasks require
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

Result roots:

- `results/reproduction/2026-07-01-official-workloads/terminal-bench-file-service-pipeline-oracle-suite/`
- `results/reproduction/2026-07-01-official-workloads/terminal-bench-shell-deobfuscation-permission-adapted-oracle/`

Unmodified official command shape:

```text
uv run tb run
  --dataset-path original-tasks
  --task-id fix-git
  --task-id large-scale-text-editing
  --task-id new-encrypt-command
  --task-id processing-pipeline
  --task-id jupyter-notebook-server
  --task-id kv-store-grpc
  --task-id pcap-to-netflow
  --task-id shell-deobfuscation
  --agent oracle
  --n-concurrent 1
  --n-attempts 1
  --run-id 2026-07-01__terminal-bench-file-service-pipeline-oracle-suite
  --no-upload-results
  --cleanup
```

Permission-adapted replay command shape:

```text
cp -a original-tasks/shell-deobfuscation .cache/.../terminal-bench-adapted-shell/original-tasks/
chmod -R a+rX .cache/.../terminal-bench-adapted-shell/original-tasks/shell-deobfuscation
uv run tb run
  --dataset-path .cache/source-inspection/terminal-bench-adapted-shell/original-tasks
  --task-id shell-deobfuscation
  --agent oracle
  --n-concurrent 1
  --n-attempts 1
  --run-id 2026-07-01__terminal-bench-shell-deobfuscation-permission-adapted-oracle
  --no-upload-results
  --cleanup
```

The adapted replay changed only task-file permissions in an isolated copied
dataset. It is useful to diagnose the boundary, but it is not an unmodified
official-task reproduction.

## Workload Shapes

| Task | Workload shape | Oracle |
| --- | --- | --- |
| `large-scale-text-editing` | Transform a 1-million-row CSV using constrained Vim macros. | Macro script exists, is well-formed, runs headlessly, transforms input byte-for-byte to expected output, and stays within macro efficiency constraints. |
| `processing-pipeline` | Repair a multi-script shell data pipeline and its dependencies. | Scripts exist, are executable, readable, have correct shebangs and line endings; output directory permissions are correct; pipeline runs; expected output files and processed data exist. |
| `jupyter-notebook-server` | Configure and start a secure HTTPS Jupyter server with password auth and a sample notebook. | Server is running, config exists, password authentication works, and notebook content exists. |
| `fix-git` | Recover lost personal-site changes and merge them back into master. | Expected content appears in the `about` and layout files. |
| `new-encrypt-command` | Encrypt all files under `/app/data/` into `/app/encrypted_data/` using the installed command. | Encryption success oracle passes for outputs. |
| `kv-store-grpc` | Create a Python gRPC key-value server from a proto definition. | Proto exists; grpc tools are installed; protobuf files are generated; server file exists; real server runs; protocol handshake and get/set RPCs work. |
| `pcap-to-netflow` | Convert a PCAP into binary NetFlow v5 export files. | Generated file count and sampled flow fields match expected values. |
| `shell-deobfuscation` | Deobfuscate a suspicious shell script without executing it, create exact clean output, and remove executable bits. | Clean script exists and is non-executable, content matches exactly, no execution side effects exist, and suspicious script is non-executable. |

## Results

Unmodified official suite-level result:

| Metric | Value |
| --- | --- |
| Dataset size | 8 |
| Resolved | 7 |
| Unresolved | 1 |
| Accuracy | 0.875 |
| Clean reproduction | No |

Unmodified official per-task result:

| Task | Result | Parser checks | Boundary |
| --- | --- | --- | --- |
| `large-scale-text-editing` | Resolved | 5/5 passed | None. |
| `processing-pipeline` | Resolved | 9/9 passed | None. |
| `jupyter-notebook-server` | Resolved | 4/4 passed | None. |
| `fix-git` | Resolved | 2/2 passed | None. |
| `new-encrypt-command` | Resolved | 1/1 passed | None. |
| `kv-store-grpc` | Resolved | 7/7 passed | None. |
| `pcap-to-netflow` | Resolved | 4/4 passed | None. |
| `shell-deobfuscation` | Unresolved | 0/3 passed | Official `solution.sh` was mode `0700`; inside the task container, `bash /oracle/solution.sh` failed with `Permission denied` before workload output was produced. |

Permission-adapted replay result:

| Task | Result | Parser checks | Interpretation |
| --- | --- | --- | --- |
| `shell-deobfuscation` | Resolved | 3/3 passed | The workload oracle passes after correcting copied task-file permissions; this is not counted as unmodified official clean reproduction. |

## Raw Artifacts

Key artifacts under the official result root:

- `summary.json`
- `tb-run.log`
- `2026-07-01__terminal-bench-file-service-pipeline-oracle-suite/results.json`
- `2026-07-01__terminal-bench-file-service-pipeline-oracle-suite/run.log`
- `2026-07-01__terminal-bench-file-service-pipeline-oracle-suite/run_metadata.json`
- Per-task `commands.txt`, `panes/`, `sessions/`, and `results.json`

Key artifacts under the adapted replay root:

- `summary.json`
- `tb-run.log`
- `2026-07-01__terminal-bench-shell-deobfuscation-permission-adapted-oracle/results.json`
- `2026-07-01__terminal-bench-shell-deobfuscation-permission-adapted-oracle/run.log`
- `2026-07-01__terminal-bench-shell-deobfuscation-permission-adapted-oracle/run_metadata.json`
- Per-task `commands.txt`, `panes/`, `sessions/`, and `results.json`

## Interpretation

This run adds seven clean unmodified official Terminal-Bench workload seeds.
The strongest reusable shapes are bulk file transformation, multi-script
pipeline repair, secure service setup, Git recovery, batch encryption, gRPC
server construction, and network capture conversion.

The `shell-deobfuscation` boundary is an upstream artifact-packaging issue:
the official task files in this checkout have restrictive permissions, and the
container's `agent` user could not read `/oracle/solution.sh`. The
permission-adapted replay shows that the task's workload oracle is otherwise
reproducible. Treat it as a usable workload shape with an explicit artifact
permission caveat, not as an unmodified official clean reproduction.

Together with earlier Terminal-Bench runs, selected unmodified official-task
reproduction now covers 38 resolved tasks plus four unresolved or
setup/content/artifact-boundary tasks. This is still selected official-task
reproduction, not full Terminal-Bench-Core reproduction.

## Reuse Decision

Use the passing tasks as workload-source evidence for:

- large file transforms and exact output materialization;
- shell pipeline repair and executable-bit/line-ending/shebang oracles;
- service fixture setup with background server and auth/TLS configuration;
- Git state recovery;
- batch file encryption and output-directory materialization;
- generated RPC interfaces and service liveness;
- binary network-flow export with sampled field oracles.

Use `shell-deobfuscation` only with the permission-adapted caveat. It is useful
for a security/file-operation workload shape, but the unmodified official task
does not currently reproduce cleanly on this host because of oracle-file
permissions.
