# Agent Runtime And Environment Workload Reproduction

Date: 2026-07-01

## Motivation

This record extends the filesystem/workspace reproduction survey with
agent-runtime, terminal-task, and environment-construction sources. The purpose
is to identify reusable workload traces, state transitions, and correctness
oracles for `namei_ext`; it is not an argument that those workloads require
`namei_ext`, eBPF, or any specific implementation mechanism.

Raw logs are under:

- `results/reproduction/2026-07-01-official-workloads/`

Source commits:

- SWE-ReX: `5c995c365dfb`
- Terminal-Bench: `1a6ffa9674b5`
- SWE-MiniSandbox: `381ada53ab35`
- AgentCgroup: `5af9e7b8f37a`
- OpenHands SDK: `feca62017e2d`
- MEnvAgent: `d9e63881f7c4`
- Multi-Docker-Eval: `3160f50a6d18`
- SWE-rebench V2: `c71902a8cf8`
- SWE-Factory: `760b1758c04b`

## Summary

| Source | Workload or artifact attempted | Result | Reuse decision |
| --- | --- | --- | --- |
| SWE-ReX | Local runtime, dummy/local deployments, server/runtime/execution tests | Reproduced local subset: 68 passed, 1 xfailed, excluding one auth-status API drift test. | Use as a runtime harness source for local shell sessions, command execution, upload/download/read/write, and multi-session behavior. Do not claim Docker/Modal/Fargate reproduction yet. |
| Terminal-Bench | Unit tests, installed-agent runtime tests, run/resume/status Docker-backed tests, and selected official oracle tasks | Reproduced: 93 unit tests passed, 2 installed-agent tests passed, 5 run/resume/status tests passed, and 63 official tasks resolved through the upstream oracle agent, plus seven setup/content/artifact/workload-boundary tasks and two attempted tasks without upstream result summaries. A permission-adapted replay of `shell-deobfuscation` passed. | Strong task-oracle source: terminal tasks, Docker-backed setup, oracle agent, run interruption/resume/status, protected paths, packaging, services/logs, Git/object cleanup, data/log/database transforms, security repair, forensics/document tasks, build/environment/debug/compile tasks, service/API state, and test-script correctness. |
| SWE-MiniSandbox | Per-sandbox `/tmp` isolation tests for chroot/namespace startup | Reproduced: 4 tests passed, including concurrent tmpfs isolation. | Use as many-agent sandbox setup source: private tmpfs, chroot setup, namespace isolation, and no host-`/tmp` sharing oracle. |
| AgentCgroup | Local daemon tests, bash wrapper tests, characterization analysis, BPF build | Mostly reproduced. Python unit tests 43/43 passed, bash wrapper tests 14/14 passed, characterization fast-mode regenerated analysis from traces, scheduler/process monitor build passed after submodules. `memcg` build failed because running kernel BTF lacks `struct memcg_bpf_ops`. | Use traces and per-tool-call boundaries for operation-weighted agent workload shaping. Do not use AgentCgroup as a filesystem baseline, and do not claim full memory-controller reproduction on this host. |
| OpenHands SDK | Remote workspace unit tests, file-editor workspace-root tests, terminal session tests | Reproduced targeted local/tool subset: 195 passed. First run failed before tests due user-level `uv` cache permission; rerun with repo-local `UV_CACHE_DIR` passed. | Strong source for workspace API, file upload/download, command event polling, terminal sessions, file editor path validation, output deduplication, and workspace/tool lifecycle. |
| SWE-rebench V2 | Prompt rendering and README sample Docker eval | Reproduced. Annotation rendering produced one prompt/meta-prompt record. Sample eval for `unidata__netcdf-c-1925` passed with `all_ok=true`, exit code 0, and all expected fail-to-pass tests matched. | Strong environment/cache workload source: real repo, image, install config, test commands, patch/test-patch, Docker evaluation oracle. |
| MEnvAgent | Code/source audit, full HF dataset downloads, trajectory summary, Docker Hub registry probes, official MEnvData image/eval rows | Partially reproduced as data plus image/eval rows. Repo's core code is still marked as being organized for public release. Full `MEnvData-SWE` has 3,005 environment rows across 10 languages; trajectory data has 3,918 rows over 3,000 unique image names and exposes `execute_bash`, `str_replace_editor`, and `submit`. Passing rows: `python-attrs__attrs-586` and `go-task__task-1814`. Negative row: `eyre-rs__color-eyre-114` failed before tests because `tests/install.rs` already existed when applying the official new-file test patch. | Use as an executable W4 seed plus dataset/schema and trajectory source for environment reuse and agent tool-call workloads. Do not claim reproduced MEnvAgent system/runtime or assume every row replays without per-row evidence. |
| Multi-Docker-Eval | Code/source audit, full HF parquet download, evaluator `make_test_spec` smoke | Harness-level smoke passed, and full HF parquet has 334 task rows. Rows provide task metadata, language, labels, patches, and test patches, but no Dockerfile/eval-script fields. | Use benchmark criteria and task corpus as W4 environment-construction source. Full workload reproduction needs released or generated `docker_res`. |
| SWE-Factory | Correct repository identified, HF dataset downloads, SWE-Factory-Gym single-task eval | Reproduced one executable SWE-Factory-Gym workload: `pallets__click-2622` built an image, applied the gold patch, ran 40 pytest tests, and resolved with `OMNIGRIL_EXIT_CODE=0`. Also downloaded SetupBench-lite 671 rows, SWE-Factory-Gym 430 rows with Dockerfile/eval script, and 2,809 DeepSWE trajectory rows. | Strong W4 executable workload source. Do not claim full LLM-driven SWE-Builder generation without API-backed generation. |
| DockSmith | HF model/dataset file inspection, all index shards, one full training shard structure | Dataset/model artifacts are accessible. All nine training index shards were downloaded, totaling 39,719 conversation metadata rows. Shard 1 contains 4,033 aligned conversation lists covering context retrieval, test analysis, Dockerfile writing, and eval-script writing agents. No primary public GitHub implementation or official evaluator was identified. | Use as environment-construction trajectory source. Do not present it as a reproduced DockSmith system workload. |

## Reproduced Sources

### SWE-ReX

Logs:

- `swe-rex-install.log`
- `swe-rex-local-pytest.log`
- `swe-rex-test-deps-install.log`
- `swe-rex-local-pytest-after-aiohttp.log`
- `swe-rex-local-pytest-no-auth-drift.log`

What ran:

- Installed the repository in a local venv.
- The first selected pytest failed because `aiohttp` was missing.
- After installing `aiohttp`, selected local/runtime/server tests had one
  failure: `test_unauthenticated_request` expected HTTP 403 but got 401.
- Re-running the same local set while excluding that API-status drift produced
  68 passed, 1 xfailed, and 1 deselected.

Reusable workload shape:

- local sandboxed command execution;
- runtime/session lifecycle;
- file upload/download/read/write API shape;
- server polling and command-result behavior.

Do not claim remote Docker, Modal, AWS, or Fargate reproduction from this run.

### Terminal-Bench

Logs:

- `terminal-bench-install.log`
- `terminal-bench-unit-pytest.log`
- `terminal-bench-installed-agent-pytest.log`
- `terminal-bench-run-resume-status-pytest.log`
- `terminal-bench-acl-permissions-oracle/summary.json`
- `terminal-bench-acl-permissions-oracle/2026-07-01__terminal-bench-acl-permissions-oracle/results.json`
- `terminal-bench-filesystem-oracle-suite/summary.json`
- `terminal-bench-filesystem-oracle-suite/2026-07-01__terminal-bench-filesystem-oracle-suite/results.json`
- `terminal-bench-file-security-oracle-suite/summary.json`
- `terminal-bench-file-security-oracle-suite/2026-07-01__terminal-bench-file-security-oracle-suite/results.json`
- `terminal-bench-git-service-oracle-suite/summary.json`
- `terminal-bench-git-service-oracle-suite/2026-07-01__terminal-bench-git-service-oracle-suite/results.json`
- `terminal-bench-package-data-oracle-suite/summary.json`
- `terminal-bench-package-data-oracle-suite/2026-07-01__terminal-bench-package-data-oracle-suite/results.json`
- `terminal-bench-package-data-oracle-suite/postgres-csv-clean-compose-diagnostic.log`
- `terminal-bench-data-log-service-oracle-suite/summary.json`
- `terminal-bench-data-log-service-oracle-suite/2026-07-01__terminal-bench-data-log-service-oracle-suite/results.json`
- `terminal-bench-data-sql-log-oracle-suite/summary.json`
- `terminal-bench-data-sql-log-oracle-suite/2026-07-01__terminal-bench-data-sql-log-oracle-suite/results.json`
- `terminal-bench-security-network-oracle-suite/summary.json`
- `terminal-bench-security-network-oracle-suite/2026-07-01__terminal-bench-security-network-oracle-suite/results.json`
- `terminal-bench-file-service-pipeline-oracle-suite/summary.json`
- `terminal-bench-file-service-pipeline-oracle-suite/2026-07-01__terminal-bench-file-service-pipeline-oracle-suite/results.json`
- `terminal-bench-shell-deobfuscation-permission-adapted-oracle/summary.json`
- `terminal-bench-shell-deobfuscation-permission-adapted-oracle/2026-07-01__terminal-bench-shell-deobfuscation-permission-adapted-oracle/results.json`
- `terminal-bench-forensics-document-oracle-suite/summary.json`
- `terminal-bench-forensics-document-oracle-suite/2026-07-01__terminal-bench-forensics-document-oracle-suite/results.json`
- `terminal-bench-build-env-oracle-suite/summary.json`
- `terminal-bench-build-env-oracle-suite/2026-07-01__terminal-bench-build-env-oracle-suite/results.json`
- `terminal-bench-compile-system-oracle-suite/summary.json`
- `terminal-bench-compile-system-oracle-suite/2026-07-01__terminal-bench-compile-system-oracle-suite/results.json`
- `terminal-bench-env-debug-oracle-suite/summary.json`
- `terminal-bench-env-debug-oracle-suite/2026-07-01__terminal-bench-env-debug-oracle-suite/results.json`
- `terminal-bench-data-file-debug-oracle-suite/summary.json`
- `terminal-bench-data-file-debug-oracle-suite/2026-07-01__terminal-bench-data-file-debug-oracle-suite/results.json`
- `terminal-bench-service-api-oracle-suite/summary.json`
- `terminal-bench-service-api-oracle-suite/2026-07-01__terminal-bench-service-api-oracle-suite/results.json`

Results:

- Unit tests: 93 passed.
- Installed-agent runtime tests: 2 passed.
- Docker-backed run/resume/status runtime tests: 5 passed.
- Official task `acl-permissions-inheritance`: `n_resolved=1`,
  `n_unresolved=0`, `accuracy=1.0`, per-trial `is_resolved=true`, and
  9/9 parser checks passed.
- Official filesystem/service suite: `n_resolved=3`, `n_unresolved=0`,
  `accuracy=1.0`; `nginx-request-logging` passed 8/8 parser checks,
  `deterministic-tarball` passed 12/12 parser checks, and
  `tree-directory-parser` passed 8/8 parser checks.
- Official file/security suite: `n_resolved=4`, `n_unresolved=0`,
  `accuracy=1.0`; `decommissioning-service-with-sensitive-data` passed 6/6
  parser checks, `fix-permissions` passed 1/1, `recover-obfuscated-files`
  passed 3/3, and `git-leak-recovery` passed 5/5.
- Official Git/service suite: `n_resolved=5`, `n_unresolved=0`,
  `accuracy=1.0`; `configure-git-webserver` passed 1/1 parser check,
  `extract-safely` passed 3/3, `openssl-selfsigned-cert` passed 6/6,
  `git-multibranch` passed 1/1, and `sanitize-git-repo` passed 3/3.
- Official package/service/data suite: `n_resolved=3`, `n_unresolved=1`,
  `accuracy=0.75`; `multi-source-data-merger` passed 3/3 parser checks,
  `home-server-https` passed 10/10, and `pypi-server` passed 1/1.
  `postgres-csv-clean` failed before agent/test execution during
  `docker compose up`; diagnostic logs show `postgres_db` exited with code 2
  after `ls: cannot open directory '/docker-entrypoint-initdb.d/': Permission
  denied`.
- Official data/log/service/database suite: `n_resolved=5`,
  `n_unresolved=0`, `accuracy=1.0`; `fibonacci-server` passed 6/6 parser
  checks, `csv-to-parquet` passed 2/2, `db-wal-recovery` passed 7/7,
  `analyze-access-logs` passed 3/3, and `jsonl-aggregator` passed 1/1.
- Official data/SQL/log suite: `n_resolved=6`, `n_unresolved=0`,
  `accuracy=1.0`; `pandas-etl` passed 3/3 parser checks,
  `jq-data-processing` passed 14/14, `log-summary-date-ranges` passed 2/2,
  `sqlite-db-truncate` passed 1/1, `log-summary` passed 3/3, and
  `pandas-sql-query` passed 2/2.
- Official security/network suite: `n_resolved=4`, `n_unresolved=2`,
  `accuracy=0.6666666666666666`; `sql-injection-attack` passed 2/2 parser
  checks, `vul-flask` passed 3/3, `vulnerable-secret` passed 3/3, and
  `fix-code-vulnerability` passed 373/373. `cron-broken-network` reached
  pytest and passed curl binary checks but failed the live `example.com`
  content oracle. `broken-networking` failed before parser summary generation
  because task setup could not connect to `archive.ubuntu.com` to install
  curl, uv, and pytest.
- Official file/service/pipeline suite: `n_resolved=7`, `n_unresolved=1`,
  `accuracy=0.875`; `large-scale-text-editing` passed 5/5 parser checks,
  `processing-pipeline` passed 9/9, `jupyter-notebook-server` passed 4/4,
  `fix-git` passed 2/2, `new-encrypt-command` passed 1/1,
  `kv-store-grpc` passed 7/7, and `pcap-to-netflow` passed 4/4.
  Unmodified `shell-deobfuscation` failed before workload output because
  `/oracle/solution.sh` was unreadable to the container's `agent` user; an
  isolated permission-adapted replay passed 3/3 parser checks.
- Official forensics/document suite: `n_resolved=7`, `n_unresolved=1`,
  `accuracy=0.875`; `reverse-engineering` passed 2/2 parser checks,
  `financial-document-processor` passed 7/7, `crack-7z-hash` passed 2/2,
  `filter-js-from-html` passed 2/2, `heterogeneous-dates` passed 3/3,
  `extract-elf` passed 2/2, and `html-finance-verify` passed 1/1.
  `password-recovery` reached pytest but failed both recovery-file and
  password-match checks.
- Official build/environment suite: `n_resolved=3`, `n_unresolved=1`,
  `accuracy=0.75`; `broken-python` passed 2/2 parser checks,
  `npm-conflict-resolution` passed 5/5, and `setup-custom-dev-env` passed 7/7.
  `build-cython-ext` passed 10/11 checks but failed
  `test_pyknotid_repository_tests`.
- Official compile/system suite: `n_resolved=4`, `n_unresolved=0`,
  `accuracy=1.0`; `modernize-fortran-build` passed 3/3 parser checks,
  `polyglot-c-py` passed 1/1, `sqlite-with-gcov` passed 3/3, and
  `build-tcc-qemu` passed 1/1.
- Official environment/debug suite: `n_resolved=2`, `n_unresolved=1`,
  `accuracy=0.6666666666666666`; `conda-env-conflict-resolution` passed
  3/3 parser checks, and `fix-pandas-version` passed 3/3.
  `incompatible-python-fasttext` failed before parser execution during Docker
  build of `fasttext==0.9.3`. `amuse-install` was requested and produced
  partial logs, but no upstream result summary was produced, so it is tracked
  as attempted without result rather than counted in accuracy.
- Official data/file/debug suite: `n_resolved=6`, `n_unresolved=0`,
  `accuracy=1.0`; `bank-trans-filter` passed 1/1 parser check,
  `cpp-compatibility` passed 2/2, `recover-accuracy-log` passed 3/3,
  `regex-log` passed 1/1, `organization-json-generator` passed 4/4, and
  `modernize-scientific-stack` passed 2/2.
- Official service/API suite: `n_resolved=3`, `n_unresolved=0`,
  `accuracy=1.0` for tasks with upstream result summaries;
  `simple-web-scraper` passed 5/5 parser checks, `create-bucket` passed 2/2,
  and `simple-sheets-put` passed 3/3. `mlflow-register` was requested and its
  agent log shows MLflow server startup plus model `gpt-5` registration, but
  the upstream harness did not write a per-task result summary and the client
  container exited 255, so it is tracked as attempted without result.

Reusable workload shape:

- terminal task directory with instructions, Dockerfile, compose file,
  solution script, and `run-tests.sh`;
- installed agent success/failure oracle;
- run interruption, resume, status, and completion lifecycle;
- test-script oracle suitable for agent workspace correctness.
- POSIX ACL protected-path workload: `/srv/shared`, `research` group,
  `alice`/`bob` full access, outside-user denial, default ACL inheritance,
  and file/subdirectory creation checks.
- deterministic source-tree packaging workload: exclusion rules, sensitive
  `0600` file filtering, symlink preservation, metadata normalization, and
  reproducible archive hash oracle.
- directory reconstruction workload: exact `tree -F` output equivalence,
  zero-byte file creation, mode `700` directories, and idempotent rebuild.
- service fixture workload: Nginx config, document root, custom 404 page,
  access/error log paths, rate limiting, localhost health, and log-format
  oracle.
- file/security workload: protected-data archive/encrypt/delete lifecycle,
  no-plaintext intermediate oracle, Git secret recovery and cleanup, exact
  obfuscated-file recovery, and execute-bit repair.
- Git/service workload: Git-to-web deployment, branch-aware HTTPS deployment,
  repository sanitization, safe targeted archive extraction, TLS
  key/certificate materialization, and service/webroot content oracles.
- Package/service/data workload: local PyPI build/upload/install, DNS and
  HTTPS service setup, self-signed certificate materialization, multi-source
  JSON/CSV/Parquet merge, conflict-report oracle, and a preserved PostgreSQL
  setup negative for future database configuration/rotation work.
- Data/log/service/database workload: CSV-to-Parquet file conversion,
  multi-file JSONL aggregation, access-log report materialization, long-running
  HTTP service setup with input validation, and SQLite WAL recovery with
  base-plus-WAL correctness checks.
- Data/SQL/log workload: jq-only JSON transformation with command replay,
  CSV ETL, DuckDB/pandas SQL query, truncated SQLite recovery, simple log
  severity summaries, and date-windowed log summaries.
- Security/network workload: SQL-injection service mutation, vendored Flask
  template-injection repair, binary secret extraction, Bottle header-security
  repair with upstream regression tests, and preserved live-network boundaries
  for future controlled-network harnessing.
- File/service/pipeline workload: million-row Vim-macro CSV transformation,
  multi-script pipeline repair, secure Jupyter HTTPS/auth setup, Git lost-work
  recovery, batch file encryption, generated gRPC key-value service, PCAP to
  NetFlow-v5 conversion, and permission-adapted shell deobfuscation.
- Forensics/document workload: mixed JPG/PDF document classification and invoice
  summary materialization, browser-backed XSS filter validation, encrypted
  archive recovery, ELF memory extraction, HTML/MHTML financial report
  verification, compiled-binary reverse engineering, CSV numeric output, and a
  preserved deleted-file password-recovery oracle failure.
- Build/environment workload: system Python/pip repair, Node.js dependency
  conflict repair, shell and conda development-environment setup, and Cython
  extension source build with a preserved repository-test oracle failure.
- Compile/system workload: Fortran Makefile migration, Python/C polyglot source
  generation, SQLite build with gcov instrumentation, and QEMU-attached TCC ISO
  materialization with in-guest execution.
- Environment/debug workload: conda environment conflict repair, pandas/pyarrow
  dependency pinning, fastText native-extension build boundary, and AMUSE
  scientific-computing virtualenv setup attempt.
- Data/file/debug workload: transaction CSV filtering, generator/judge JSONL
  recovery, regex/log extraction, multi-CSV organization JSON materialization,
  header-only C++11 compatibility repair, and Python 2 to Python 3 scientific
  script migration.
- Service/API workload: local web scraping with CSV/report outputs,
  LocalStack S3 bucket and ACL state, spreadsheet service state, and an MLflow
  model-registry setup attempt that needs a clean upstream result summary
  before release use.

Dedicated follow-up record:

- `docs/tmp/2026-07-01-terminal-bench-acl-workload-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-filesystem-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-file-security-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-git-service-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-package-data-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-data-log-service-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-data-sql-log-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-security-network-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-file-service-pipeline-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-forensics-document-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-build-env-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-compile-system-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-env-debug-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-data-file-debug-suite-reproduction.md`
- `docs/tmp/2026-07-01-terminal-bench-service-api-suite-reproduction.md`

### SWE-MiniSandbox

Logs:

- `swe-minisandbox-install.log`
- `swe-minisandbox-tmpfs-pytest.log`

Result:

- `tests/test_tmpfs_tmp_isolation.py`: 4 passed.

The tests verify that generated chroot/namespace startup does not bind-mount
host `/tmp`, mounts a private tmpfs before chroot, and gives concurrent
sandboxes isolated `/tmp` contents. This is directly reusable as a many-agent
workspace setup/isolation oracle.

### AgentCgroup

Logs:

- `agentcgroup-python-unittest.log`
- `agentcgroup-bash-wrapper-test.log`
- `agentcgroup-characterization-fast.log`
- `agentcgroup-agentcg-make.log`
- `agentcgroup-submodule-update.log`
- `agentcgroup-agentcg-make-after-submodules.log`
- `agentcgroup-agentcg-make-memcg.log`

Results:

- Python daemon unit tests: 43 passed.
- Bash wrapper tests: 14 passed.
- Characterization fast-mode succeeded over pre-collected traces. It loaded 33
  Haiku tasks and 111 local-model tasks, and regenerated tool/resource analysis
  figures and reports.
- Initial `make -C agentcg` failed because submodules were not initialized.
- After `git submodule update --init --recursive`, the default `agentcg` build
  passed for the scheduler and process monitor.
- `make -C agentcg memcg` failed because `struct memcg_bpf_ops` is only a
  forward declaration in the running kernel BTF.

Reusable workload shape:

- per-tool-call cgroup boundaries;
- `Bash`, `Read`, `Grep`, `Edit`, `Write`, and other agent tool-call sequences;
- resource traces aligned with tool-call timing;
- file-open/process monitor concepts for operation-weighted trace selection.

For `namei_ext`, AgentCgroup is useful as trace evidence and task selection
input, not as a filesystem mechanism baseline.

### OpenHands SDK

Logs:

- `openhands-sdk-targeted-pytest.log`
- `openhands-sdk-targeted-pytest-local-uv-cache.log`

Results:

- The first `uv run` failed before testing because the user-level `uv` wheel
  cache was not writable.
- Re-running with `UV_CACHE_DIR=.cache/uv` and
  `UV_PROJECT_ENVIRONMENT=.cache/venvs/openhands-sdk` passed 195 tests.

Tested subsets:

- `tests/sdk/workspace/remote`
- `tests/tools/file_editor/test_workspace_root.py`
- `tests/tools/terminal/test_terminal_session.py`

Reusable workload shape:

- remote workspace command execution API;
- command event polling with output deduplication and per-command isolation;
- file upload/download paths;
- file-editor workspace-root path validation;
- real terminal sessions over tmux/subprocess;
- terminal cwd, output truncation, timeout, and session cleanup behavior.

### SWE-rebench V2

Logs and artifacts:

- `swe-rebench-v2-install-render-deps.log`
- `swe-rebench-v2-annotation-render.log`
- `swe-rebench-v2-rendered-prompts.json`
- `swe-rebench-v2-sample-eval.log`
- `swe-rebench-v2-eval-report.json`

Results:

- Prompt rendering over `sample.json` passed and produced one enriched record
  with `prompt` and `meta_prompt`.
- The README sample Docker evaluation passed:
  - `total=1`;
  - `all_ok=true`;
  - `instance_id=unidata__netcdf-c-1925`;
  - `exit_code=0`;
  - all expected fail-to-pass tests matched.

Reusable workload shape:

- real repository and base commit;
- prebuilt instance image;
- install configuration and test commands;
- patch/test-patch oracle;
- Docker-backed evaluation result with parsed fail-to-pass/pass-to-pass tests.

This is one of the strongest W4 environment/cache workload sources because it
already closed an executable sample eval on this machine.

## Partially Reusable Sources

### MEnvAgent

Logs:

- `hf-menvbench-splits.json`
- `hf-menvbench-first-row.json`
- `hf-menvdata-swe-splits.json`
- `hf-menvdata-swe-first-row.json`
- `hf-menvdata-swe-trajectory-splits.json`
- `hf-menvdata-swe-trajectory-first-row.json`
- `menvdata-first-image-pull-smoke.log`
- `hf-full-file-downloads.log`
- `hf-full-dataset-summaries.log`
- `hf-dataset-derived-counts.json`
- `menvdata-image-registry-probe.log`
- `menvdata-mcatwj-registry-probe.log`
- `menvdata-python-attrs-586/extract-summary.json`
- `menvdata-python-attrs-586/docker-pull.log`
- `menvdata-python-attrs-586/eval.log`
- `menvdata-python-attrs-586/run-summary.json`
- `menvdata-go-task-1814/run-summary.json`
- `menvdata-rust-color-eyre-114/run-summary.json`

Findings:

- The repo states that core code is still being organized for public release.
- `MEnvBench` exposes task metadata: repo, pull number, instance id, base
  commit, patch, test patch, problem statement, created time, and language.
- `MEnvData-SWE` exposes environment fields:
  `env_setup_script`, `original_env_setup_script`, `eval_script`, and
  `image_name`.
- The full `MEnvData-SWE` file has 3,005 rows across C, C++, Go, Java,
  JavaScript, PHP, Python, Ruby, Rust, and TypeScript.
- The first `MEnvData-SWE` row is `systemd__systemd-24645` with image
  `swe-images-c:systemd-systemd-pr-24645`.
- Pulling that image by the literal name failed with access denied / repository
  not found.
- The HF README's Docker Hub convention is `mcatwj/<image_name>`. With that
  prefix, public manifests exist for the first C/systemd image and for the
  selected Python attrs image.
- The first selected executable row was `python-attrs__attrs-586`, image
  `mcatwj/swe-images-python:python-attrs-attrs-pr-586`. Running the official
  eval script inside that image passed: Docker run exit 0, `21 passed, 1
  warning in 0.08s`, `OMNIGRIL_EXIT_CODE=0`, and
  `COMMAND_EXECUTION_COMPLETE`.
- The second passing row was `go-task__task-1814`, image
  `mcatwj/swe-images-go:go-task-task-pr-1814`. Running the official eval
  script passed `TestExitCodeZero` and `TestExitCodeOne` with
  `OMNIGRIL_EXIT_CODE=0`.
- The Rust row `eyre-rs__color-eyre-114` pulled
  `mcatwj/swe-images-rust:eyre-rs-color-eyre-pr-114` but failed before tests:
  the official script attempted to apply a new `tests/install.rs` test file
  that already existed in the image working tree.
- `MEnvData-SWE-Trajectory` exposes `tools`, `messages`, and `docker_image`
  fields.
- The full trajectory file has 3,918 rows over 3,000 unique image names.
  Parsed tool names are `str_replace_editor`, `execute_bash`, and `submit`.
- Earlier manifest probes for the first image using the bare tag plus
  plausible Docker Hub, GHCR, and HF registry prefixes failed; those are kept
  as provenance for the incorrect registry assumption.

Reuse:

- use task and environment script fields for W4 environment-reuse workload
  design;
- use `python-attrs__attrs-586` and `go-task__task-1814` as verified
  executable seeds;
- keep `eyre-rs__color-eyre-114` as an artifact caveat showing that not every
  public image/eval row is cleanly replayable;
- use trajectory fields for agent action/tool-call shapes;
- do not claim full MEnvAgent reproduction until the core runtime code is
  available as a complete runnable system.

### Multi-Docker-Eval

Logs:

- `hf-multi-docker-eval-splits.json`
- `hf-multi-docker-eval-first-row.json`
- `hf-multi-docker-eval-size.json`
- `multi-docker-eval-install.log`
- `multi-docker-eval-test-spec-smoke.log`
- `hf-full-file-downloads.log`
- `hf-full-dataset-summaries.log`
- `hf-dataset-derived-counts.json`

Findings:

- The full HF parquet has 334 rows in the test split.
- The dataset row exposes task metadata such as repo, pull number, instance id,
  base commit, patch, test patch, language, and label.
- Language counts are 40 each for C, Go, JavaScript, Ruby, and Rust; 39 for
  Python; 35 for Java; 30 each for C++ and PHP. Labels are 267 hard and 67
  easy.
- The public repo does not ship a sample `dataset` plus `docker_res` pair.
- The evaluator requires `docker_res` entries containing `dockerfile`,
  `eval_script`, and optional `setup_scripts`.
- A harness-level `make_test_spec` smoke passed and confirmed that evaluator
  normalization removes `-n auto` style parallel test flags.

Reuse:

- use its repository selection and build/runtime-success benchmark criteria for
  W4 workload selection;
- use the evaluator once a concrete `docker_res` artifact is produced or
  released;
- do not claim an official Multi-Docker-Eval workload run from this audit.

### SWE-Factory

Logs:

- `swe-factory-setupbench-lite-summary.log`
- `hf-swe-factory-dataset-search.log`
- `swe-factory-hf-download-summary.log`
- `swe-factory-eval-venv-install.log`
- `swe-factory-gym-click2622-prepare.log`
- `swe-factory-gym-click2622-eval-after-venv.log`
- `swe-factory-gym-click2622/reports/gold.namei_ext_click2622.json`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/report.json`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/test_output_after_apply.txt`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/build_image.log`

Findings:

- The correct public repository is `DeepSoftwareAnalytics/swe-factory`.
- The correct public HF SetupBench-lite dataset is
  `Deep-Software-Analytics/SweSetupBench-lite`; it has 671 rows.
- The first row is `assertj__assertj-3820` from `assertj/assertj`.
- Rows contain repo, pull number, instance id, issue numbers, base commit,
  patch, test patch, problem statement, hints, created time, and version.
- `SWE-Factory/SWE-Factory-Gym` has 430 rows with Dockerfile and eval script.
- `SWE-Factory/DeepSWE-Agent-Kimi-K2-Trajectories-2.8K` has 2,809 trajectory
  rows.
- A one-task SWE-Factory-Gym run for `pallets__click-2622` succeeded through
  the upstream evaluator. The Docker image built, the gold patch applied, 40
  pytest tests passed, and the report recorded `resolved=true`.
- Running SWE-Builder itself requires LLM API configuration and generates
  Docker/eval outputs in a later stage.

Reuse:

- use SetupBench-lite and SWE-Factory-Gym as real issue/task sources;
- use SWE-Factory-Gym as an executable Docker/eval workload seed;
- use SWE-Builder's staged environment-generation model as W4 related method;
- do not claim full SWE-Builder generation without an API-backed run.

### DockSmith

Logs:

- `hf-docksmith-training-splits.json`
- `hf-docksmith-training-first-row.json`
- `hf-docksmith-training-size.json`
- `hf-docksmith-model-metadata.log`
- `hf-full-file-downloads.log`
- `docksmith-shard-structure-probe.log`
- `docksmith-index-download-and-summary.log`
- `docksmith-index-summary.json`

Findings:

- The Hugging Face model `8sj7df9k8m5x8/DockSmith` is public and not gated.
- The training dataset `8sj7df9k8m5x8/docker_building_training` is visible and
  has nine JSON shards plus matching index files.
- All nine index shards were downloaded, totaling 39,719 conversation metadata
  rows.
- Shard 1 contains 4,033 conversation lists aligned with 4,033 index rows.
  Agent types include context retrieval, test analysis, Dockerfile writing,
  and eval-script writing stages.
- No primary public DockSmith GitHub implementation was identified.

Reuse:

- use DockSmith as environment-construction motivation and trajectory
  provenance;
- use its conversations as Docker/eval-generation trajectory workload input;
- do not claim DockSmith system reproduction without a primary implementation
  or official evaluator entry point.

## What This Means For `namei_ext`

The strongest reusable sources now split into two paper-facing workload
families:

1. **AI agent workspace lifecycle.**
   BranchFS, Sandlock, AgentFS, Redis AFS, Mirage, OpenHands SDK, SWE-ReX,
   Terminal-Bench, SWE-MiniSandbox, and AgentCgroup together provide branch,
   workspace, sandbox, terminal, and tool-call lifecycle oracles. The
   `namei_ext` workload should reuse their state transitions and correctness
   checks, not their complete FUSE/custom runtime implementations.

2. **Environment construction and cache reuse.**
   SWE-rebench V2, SWE-Factory-Gym, and MEnvData-SWE are immediately
   executable seeds on this machine. MEnvAgent's full runtime is not reproduced,
   but its dataset has verified public Docker image/eval rows for Python and
   Go plus a preserved Rust negative row. DockSmith provides
   stronger-than-metadata environment scripts and trajectory artifacts, but
   evaluator access is not closed.
   Multi-Docker-Eval provides task corpus and evaluator structure, but still
   needs released or generated `docker_res` artifacts for a full run.

The next `namei_ext` implementation step should be a Make-owned KVM workload
that selects one concrete trace from these sources and reports:

- workload provenance and exact input task;
- correctness oracle first;
- transition-time lookup/readdir operations;
- operation-weighted path signal;
- natural baselines: native runtime, FUSE/workspace system, materialized
  copy/symlink/bind/Overlay/projection where applicable;
- a verdict that can narrow the paper claim.

Do not turn these sources into a new table-only proof exercise. The evidence
they provide is real workload shape, not mechanism exclusivity.
