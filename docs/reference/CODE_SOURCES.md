# Reproducible Code Source Catalog

This catalog tracks papers and systems by the evidence role they can play for
`namei_ext`. PDFs remain indexed in `INDEX.md`; this file records code and
artifact entry points.

Canonical related-work, novelty, and baseline conclusions live in
`docs/background-related-work.md`. Canonical idea/claim framing lives in
`docs/idea-story.md`. This file is only the source/code catalog.

This catalog is not an exclusion checklist. A source is useful when it provides
one or more of: real code, task inputs, state transitions, executable oracles,
failure taxonomies, or mechanism baselines. Do not select or describe sources
as an argument that another mechanism cannot work.

## Catalog Ownership

Record only stable source facts here: repository URLs, artifact locations,
workload roles, and how a source may be reused. Put novelty judgments, baseline
requirements, same-claim risk, and final workload-selection verdicts in
`docs/background-related-work.md`. Put dated reproduction details in
`docs/tmp/YYYY-MM-DD-*.md`, with raw logs and generated summaries under
`results/`.

## Direct Workload Seeds

| Source | Paper or system | Code / artifact | Workload role | Use in `namei_ext` |
| --- | --- | --- | --- | --- |
| BranchFS / branch contexts | Fork, Explore, Commit: OS Primitives for Agentic Exploration | https://github.com/multikernel/branchfs | AI agent workspace lifecycle | Reproduce branch create, nested branch, commit, abort, and `@branch` access patterns; use as a source of dynamic branch/session path-view semantics. The independent 2026-07-02 rerun is indexed below. |
| Sandlock | Sandlock: Confining AI Agent Code with Unprivileged Linux Primitives | https://github.com/multikernel/sandlock | AI agent sandbox lifecycle | Reproduce process sandbox runs with COW workspace, readable/writable path classes, network rules, and dry-run/commit semantics; use as an agent safety workload source. The 2026-07-02 evidence summary indexes positive and negative raw sub-oracles. |
| SWE-MiniSandbox | SWE-MiniSandbox: Container-Free Reinforcement Learning for Building Software Engineering Agents | https://github.com/lblankl/SWE-MiniSandbox | Batched SWE agent sandbox setup | Reproduce namespace/chroot/bind-mount based per-instance SWE environments; use to drive many-agent lifecycle and workspace-state traces. |
| SWE-agent | Agent-Computer Interfaces Enable Automated Software Engineering | https://github.com/SWE-agent/SWE-agent | Real software-engineering agent actions | Run issue-fixing tasks over real repositories and collect build/test/file-access traces for agent workspace and build/action views. |
| SWE-ReX | SWE-agent Remote Execution Framework | https://github.com/SWE-agent/SWE-ReX | Sandboxed code execution runtime | Use as a runtime harness for SWE-agent-style command execution; compare runtime workspace setup paths rather than reimplementing its sandbox. |
| OpenHands SDK | The OpenHands Software Agent SDK / OpenHands platform | https://github.com/OpenHands/software-agent-sdk | Agent workspaces and multi-agent workflows | Use local or ephemeral Docker/Kubernetes workspaces as real agent workspace traces; good source for workspace mount and tool-call lifecycle events. |
| Terminal-Bench | Terminal-Bench: Benchmarking Agents on Hard, Realistic Tasks in Command Line Interfaces | https://github.com/laude-institute/terminal-bench | Terminal agent tasks | Select official tasks with real build/test/server setup, file-state transitions, and task tests as correctness oracles. Exact selected task IDs, pass/fail status, and raw-result roots are recorded in the evidence index below and summarized in `docs/background-related-work.md`; do not describe the selected subset as full Terminal-Bench-Core reproduction. |
| AgentCgroup | AgentCgroup: Understanding and Controlling OS Resources of AI Agents | https://github.com/eunomia-bpf/agentcgroup | Agent tool-call tracing and SWE-rebench task set | Use the task set and per-tool-call boundaries to build operation-weighted traces; not a filesystem baseline. |
| MEnvAgent / MEnvData-SWE | MEnvAgent: Scalable Polyglot Environment Construction for Verifiable Software Engineering | https://github.com/ernie-research/MEnvAgent and https://huggingface.co/datasets/ernie-research/MEnvData-SWE | Environment construction and reuse | Use released MEnvData image/eval rows and trajectories for W4 cache/environment reuse; per-row reproduction status is recorded in dated evidence records and summarized in `docs/background-related-work.md`. |
| Multi-Docker-Eval | Multi-Docker-Eval benchmark | https://github.com/Z2sJ4t/Multi-Docker-Eval and https://huggingface.co/datasets/litble/Multi-Docker-Eval | Docker environment construction benchmark | Use public task rows and evaluator shape as W4 environment-construction workload input; dataset/evaluator artifact boundaries are recorded in dated evidence records and summarized in `docs/background-related-work.md`. |
| SWE-rebench V2 | SWE-rebench V2: Language-Agnostic SWE Task Collection at Scale | https://github.com/SWE-rebench/SWE-rebench-V2 and https://huggingface.co/datasets/ibragim-bad/SWE-rebench-V2-sample | Large language-agnostic SWE task corpus | Source real repositories, base commits, tests, per-instance Docker images, and environment metadata for agent/build/cache traces. README and selected HF sample evidence is indexed below. |
| AgentFS | Turso AgentFS | https://github.com/tursodatabase/agentfs | Open-source agent filesystem implementation | Use as a concrete agent-filesystem codebase for session, copy-on-write, audit, snapshot/restore, mount behavior, and FUSE/NFS baseline study; conformance reproduction status belongs in dated evidence records and `docs/background-related-work.md`. |
| Redis Agent Filesystem | Redis AFS | https://github.com/redis/agent-filesystem | Open-source agent workspace system | Use create/import/mount/unmount/fork/checkpoint/bookmark/query operations plus markdown grep/search/file-operation benchmarks as real agent workspace lifecycle inputs and possible baseline behavior; indexed-search and mounted-edit sync status belong in dated evidence records and `docs/background-related-work.md`. |
| Mirage | Unified virtual filesystem for AI agents | https://github.com/strukto-ai/mirage | Open-source agent VFS over tools and services | Use as an agent-filesystem implementation source for multi-backend path namespaces, cross-mount operations, portable workspace snapshots, cache warm/cold semantics, CLI/server lifecycle, Python FS shim behavior, and explicit FUSE mount behavior. |

## Methodology And Oracle Sources

| Source | Artifact status | Evidence role | Use in `namei_ext` |
| --- | --- | --- | --- |
| YoloFS | Public umbrella, filesystem repository, and website available; filesystem unit tests, compat kmod build, and compat-branch mounted VM e2e reproduced; agent/perf evaluation submodules are not accessible. | Agent-filesystem failure taxonomy, workload design, evaluation methodology, mounted stackable-filesystem behavior, and stackable-kernel-filesystem related-work artifact. | Use its hidden-side-effect tasks, staging/snapshot/permission concepts, final filesystem-state oracle, permission/tool-call accounting, mounted e2e behavior, and user-agent-filesystem interaction methodology to design a YoloFS-like agent workload. Sources: https://github.com/YoloFS/YoloFS, https://github.com/YoloFS/filesystem, https://yolofs.github.io. |
| DockSmith | Paper available; Hugging Face collection lists a model and Docker-building trajectory dataset; shard-1 trajectory inspection and one trajectory-derived Docker smoke replay completed. Sources: https://arxiv.org/abs/2602.00592, https://huggingface.co/collections/8sj7df9k8m5x8/docksmith, https://huggingface.co/datasets/8sj7df9k8m5x8/docker_building_training/viewer. | Environment-construction workload methodology, trajectory source, and smoke workload source. | Use its framing of environment setup as a first-class agentic task and reuse extracted context-retrieval, Dockerfile-writing, eval-script-writing, and test-analysis phases for W4 traces. Do not claim a primary DockSmith codebase or full official fail-to-pass reproduction; shard-1 eval scripts contain placeholder test patches. |
| SWE-Factory | Public code and paper. | Environment-construction pipeline source. | Use SWE-Builder style environment setup, validation, and fail2pass checks as reproducible input for environment/cache workloads. |
| Multi-Docker-Eval | Public benchmark, paper, HF task dataset, and evaluator. The public dataset exposes task rows; Dockerfile/eval-script `docker_res` availability is tracked in dated evidence records. | Environment-construction task/evaluator source. | Use executable-state success, fail-to-pass metrics, efficiency, and repository diversity as W4 workload selection criteria. |
| MEnvAgent / MEnvData-SWE | Public code repository plus released benchmark/data artifacts. | Environment reuse methodology and executable benchmark source. | Use MEnvBench tasks, MEnvData image/eval rows, and environment reuse transitions to drive W4 state changes; per-row replay evidence is tracked in dated records. |

## Mechanism And Baseline Anchors

These systems are not dismissed. They are useful because they explain which
mechanism family a reviewer will expect us to compare against.

| Source | Code / artifact | Evidence role | Use in `namei_ext` |
| --- | --- | --- | --- |
| ExtFUSE | https://github.com/extfuse/extfuse | eBPF-assisted FUSE mechanism anchor. | Use to sharpen the related-work contrast: ExtFUSE moves specialized FUSE request handling into the kernel, while `namei_ext` exposes only a VFS name-resolution decision and leaves lower FS semantics in the kernel. |
| Bento | https://github.com/smiller123/bento and https://github.com/smiller123/bentofs | Safe in-kernel filesystem framework. | Use as the custom/kernel-FS comparison point: Bento reduces in-kernel FS development risk but still asks the developer to build a filesystem. |
| FUSE studies | FAST 2017 FUSE study and HotStorage 2015 FUSE survey | Measurement-methodology anchor. | Use to justify workload-specific FUSE measurements rather than generic "FUSE is slow" claims. |
| DeltaFS | https://github.com/pdlfs/deltafs, https://github.com/pdlfs/deltafs-umbrella, and https://github.com/pdlfs/deltafs-vpic-preload | Distributed metadata/index service anchor and optional HPC workload-shape source. | Use VPIC file-per-particle writes, trajectory reads, large-directory create/stat/delete, and snapshot workflow shapes as related-work or appendix inputs. Full DeltaFS/VPIC reproduction is heavy and should not displace the agent workload. |
| IndexFS | https://github.com/pdlfs/indexfs and https://github.com/zhengqmark/indexfs-0.4 | Scalable metadata-service anchor and metadata workload-shape source. | Use mdtest-style create/stat/delete, standalone shared-directory tests, tree/replay/cache/RPC/SST-compaction tasks, and N-N checkpoint/bulk-insertion discussion as full metadata-service context. It is not a direct path-view workload. |
| TableFS | https://github.com/pdlfs/tablefs and https://www.cs.cmu.edu/~kair/code/tablefs-0.3.tar.gz | Stacked metadata filesystem anchor and conventional metadata workload source. | Use the original FUSE TableFS and fsbench workloads (`metadatacreate`, `metadataquery`, `smallfilecreate`, `smallfilequery`, `scanquery`, `lsstatquery`, `renamequery`, `deletequery`) plus Linux-kernel/Postmark workload shapes as related-work or appendix baselines. |
| Wrapfs | Reference paper and templates. | Stackable-filesystem anchor. | Use to explain the classic approach of adding filesystem behavior beneath existing applications. |

## Source Admission Criteria

A source may inform the paper-facing workload set when it provides at least one
stable artifact type: public code or benchmark harness, real repository/task
inputs, executable correctness oracle, observable filesystem state transition,
or a mechanism baseline a reviewer will expect.

Final source-use verdicts, same-claim risk, baseline requirements, reproduction
status, and next-workload decisions are intentionally not kept in this catalog;
they live in `docs/background-related-work.md`.

## Evidence Record Index

Detailed reproduction commands, status, negative results, and raw-result roots
are recorded in dated evidence files:

| Record | Scope |
| --- | --- |
| `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md` | Consolidated workload inventory and reuse decision: AgentFS-derived workspace lifecycle selected as the first KVM workload source; SWE-Factory-Gym or MEnvData-SWE selected for first W4; DeltaFS/IndexFS/TableFS kept as appendix/related-work only; 2026-07-03 YoloFS `agent-eval`/`perf-eval`/result submodule access checks still return GitHub `Repository not found`. |
| `docs/tmp/2026-06-30-filesystem-workload-reproduction-report.md` | AgentFS, Redis AFS, Mirage, YoloFS historical state, DeltaFS, TableFS, and IndexFS build/smoke reproduction. |
| `docs/tmp/2026-07-01-yolofs-public-artifact-reproduction-update.md` | YoloFS public filesystem artifact and unavailable agent/perf submodule boundary. |
| `docs/tmp/2026-07-01-yolofs-e2e-vm-retry.md` | YoloFS public mounted VM e2e retry and guest-readiness failure boundary. |
| `docs/tmp/2026-07-02-yolofs-compat-e2e-vm-reproduction.md` | YoloFS public compat-branch mounted VM e2e reproduction: guest kmod build/install, `yolo reload`, 593/593 mounted e2e tests passed, module unload, VM stop, plus dependency/generated-artifact cleanup caveats. |
| `docs/tmp/2026-07-01-branchfs-sandlock-workload-reproduction.md` | BranchFS and Sandlock upstream tests/workload evidence. |
| `docs/tmp/2026-07-02-branchfs-workload-reproduction.md` | BranchFS independent rerun: release build, all upstream shell/Rust tests, Python quick benchmark, shell quick benchmark, and machine-readable summary. |
| `docs/tmp/2026-07-02-sandlock-workload-evidence-summary.md` | Sandlock machine-readable evidence summary over preserved raw logs: CLI/COW/protected-path positives plus named-UNIX, resource-control, and pkg-config caveats. |
| `docs/tmp/2026-07-02-swe-agent-workload-reproduction.md` | Official SWE-agent repository pytest/workload reproduction, including deterministic agent loop, Docker replay, run-single, and run-batch evidence. |
| `docs/tmp/2026-07-02-swe-rex-workload-reproduction.md` | SWE-ReX targeted local/remote-runtime reproduction: local runtime file transfer, in-process remote server, read/write/upload, command execution, shell sessions, timeouts, interrupts, pager handling, interactive commands, multi-session isolation, and a preserved auth status-code drift boundary. |
| `docs/tmp/2026-07-02-swe-rex-docker-backend-reproduction.md` | SWE-ReX Docker backend reproduction: built `swe-rex-test:latest`, collected 6 Docker deployment tests, and passed 6/6 over Docker lifecycle, python-standalone Docker deployment, Docker/Podman config parsing, liveness, and cleanup. |
| `docs/tmp/2026-07-02-openhands-sdk-workload-reproduction.md` | OpenHands SDK targeted workspace/tool reproduction: remote workspace command polling/isolation, file upload/download/read/write, file-editor workspace-root validation, and tmux/subprocess terminal-session behavior. |
| `docs/tmp/2026-07-02-openhands-docker-workspace-reproduction.md` | OpenHands DockerWorkspace backend reproduction: official prebuilt agent-server image, real container startup/health, server info, mounted `/workspace`, command execution, API upload/download, pause/resume, and cleanup. |
| `docs/tmp/2026-07-02-agentcgroup-workload-reproduction.md` | AgentCgroup independent reproduction: controller tests, bash wrapper tests, trace-driven integration, fast characterization over pre-collected traces, scheduler/process builds, and `memcg_bpf_ops` host-kernel boundary. |
| `docs/tmp/2026-07-02-swe-minisandbox-workload-reproduction.md` | SWE-MiniSandbox core sandboxdev reproduction: private `/tmp` tmpfs, mount namespace/chroot startup command, and concurrent sandbox isolation tests. |
| `docs/tmp/2026-07-02-agentfs-official-workload-reproduction.md` | AgentFS official SDK/CLI/integration/example reproduction: Rust/Python/TypeScript SDKs, FUSE mount, COW sandbox run, bash/git overlay actions, whiteout, cache invalidation, symlink handling, and AI framework example builds. |
| `docs/tmp/2026-07-02-swe-rebench-v2-workload-reproduction.md` | SWE-rebench V2 README sample Docker eval reproduction: `unidata__netcdf-c-1925`, prebuilt netcdf-c image identity, gold patch and test patch, `make check`, 12 fail-to-pass tests passed, no pass-to-pass failures, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-sample-reproduction.md` | SWE-rebench V2 public HF sample selected-row reproduction: `pilosus__pip-license-checker-119`, prebuilt Clojure image, `lein test`, 11 fail-to-pass tests passed, no pass-to-pass failures, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-clojure-batch-reproduction.md` | SWE-rebench V2 public HF Clojure batch reproduction: `chrovis__cljam-268`, `yogthos__migratus-223`, and `pilosus__pip-license-checker-49` all report evaluator `all_ok=true`; `yogthos` preserves a raw row `exit_code=1` nested-Docker caveat. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-js-reproduction.md` | SWE-rebench V2 public HF JavaScript row reproduction: `pbiswas101__mathball-153`, prebuilt Mathball image, `npx mocha`, 406 fail-to-pass tests passed, no pass-to-pass failures, raw exit code 0, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-dart-reproduction.md` | SWE-rebench V2 public HF Dart row reproduction: `nyxx-discord__nyxx-547`, prebuilt nyxx image, `dart run test`, 15 fail-to-pass tests passed, 0/520 pass-to-pass failures, raw exit code 0, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-go-reproduction.md` | SWE-rebench V2 public HF Go row reproduction: `mgechev__revive-1408`, prebuilt Revive image, `go test -v ./...`, 2 fail-to-pass tests passed, 0/492 pass-to-pass failures, raw exit code 0, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-java-reproduction.md` | SWE-rebench V2 public HF Java row reproduction: `spoonlabs__gumtree-spoon-ast-diff-171`, prebuilt Gumtree Spoon AST Diff image, `mvn test -B --no-transfer-progress`, 2 fail-to-pass tests passed, 0/2 pass-to-pass failures, raw exit code 0, and `all_ok=true`. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-csharp-elixir-go-extension.md` | SWE-rebench V2 public HF C#/Elixir/Go extension: `btcpayserver__btcpayserver-6251` and `mhanberg__temple-135` are evaluator-positive with raw row exit caveats; `hashicorp__consul-10576` is a clean raw-exit-0 positive with 39 fail-to-pass tests passed and `all_ok=true`; selected HF sample coverage is now 12/20 rows. |
| `docs/tmp/2026-07-02-swe-rebench-v2-hf-full-sample-attempt.md` | SWE-rebench V2 public HF full-sample attempt: the remaining 8 rows were rerun in completed Elixir/Go and Java batches; public HF sample coverage is now 20/20 attempted, 19/20 evaluator-positive, 11/20 clean raw-exit-0 positives, 8/20 evaluator-positive raw-exit caveats, and one mismatch (`alibaba__fescar-382`). |
| `docs/tmp/2026-07-02-swe-factory-gym-workload-reproduction.md` | SWE-Factory-Gym single-row replay: `pallets__click-2622`, generated Dockerfile and eval script, gold patch, 40 pytest tests passed, `OMNIGRIL_EXIT_CODE=0`, and `resolved=true`. |
| `docs/tmp/2026-07-02-swe-factory-gym-multirepo-reproduction.md` | SWE-Factory-Gym multirepo replay: additional `python-attrs__attrs-556`, `mochajs__mocha-1965`, and `iamkun__dayjs-337` released rows all completed and resolved with `OMNIGRIL_EXIT_CODE=0`; preserves the `iamkun/dayjs` post-oracle cleanup warning. |
| `docs/tmp/2026-07-02-swe-factory-gym-diverse-extension.md` | SWE-Factory-Gym diverse extension replay: additional `nodejs__undici-3566`, `tailwindlabs__tailwindcss-12404`, and `python-pillow__Pillow-5425` released rows all completed and resolved with clean patch application and `OMNIGRIL_EXIT_CODE=0`; selected Gym evidence is now seven resolved rows across seven repositories. |
| `docs/tmp/2026-07-02-menvdata-swe-workload-reproduction.md` | MEnvData-SWE selected image/eval row replay: Python `python-attrs__attrs-586` and Go `go-task__task-1814` passed with `OMNIGRIL_EXIT_CODE=0`; Rust `eyre-rs__color-eyre-114` preserved as a negative test-patch artifact caveat. |
| `docs/tmp/2026-07-02-menvdata-swe-language-extension.md` | MEnvData-SWE language coverage extension: attempted one additional official image/eval row for JavaScript, TypeScript, Ruby, PHP, Java, C, C++, and Rust; JavaScript/Ruby/PHP/Java/C passed, TypeScript/C++/Rust remained preserved negative artifact rows; combined MEnvData evidence reached attempted coverage for all 10 dataset languages. |
| `docs/tmp/2026-07-02-menvdata-swe-positive-retry.md` | MEnvData-SWE positive retry: alternate official TypeScript/C++/Rust image/eval rows all pass; combined MEnvData selected-row evidence now has positive rows for all 10 dataset languages while preserving earlier negative artifact rows. |
| `docs/tmp/2026-07-02-menvdata-swe-second-sample.md` | MEnvData-SWE second-sample replay: additional Python `PyCQA__pycodestyle-859`, Go `go-yaml__yaml-353`, JavaScript `AlaSQL__alasql-970`, Rust `pest-parser__pest-702`, and TypeScript `refined-github__refined-github-7041` official image/eval rows all pass with Docker status 0 and `OMNIGRIL_EXIT_CODE=0`; selected evidence is now 15 passing rows across all 10 dataset languages plus four preserved artifact caveats. |
| `docs/tmp/2026-07-02-docksmith-trajectory-smoke-reproduction.md` | DockSmith trajectory inspection and smoke replay: shard 1 has 298 instances with tagged Dockerfile/eval-script text, but tagged eval scripts use placeholder test patches; trajectory-derived `00imvj00__mqttrs-7` Dockerfile builds, target Rust tests pass 15 decoder and 14 encoder tests, and smoke `OMNIGRIL_EXIT_CODE=0`. |
| `docs/tmp/2026-07-02-multi-docker-eval-python-manual-replay.md` | Multi-Docker-Eval Python manual `docker_res` replay: public task `pallets-eco__flask-wtf-512` first exposed missing `pytest` and Flask/Werkzeug dependency drift, then resolved with pinned `Flask==2.1.3`, `Werkzeug==2.1.0`, and `WTForms==3.0.1`; upstream evaluator reports before-patch failure, after-patch 13/13 target tests passed, `resolved=1`, and `stable=1`. |
| `docs/tmp/2026-07-01-agentfs-pjdfstest-workload-reproduction.md` | AgentFS `pjdfstest` reproduction evidence. |
| `docs/tmp/2026-07-01-agentfs-xfstests-workload-reproduction.md` | AgentFS `xfstests` reproduction evidence. |
| `docs/tmp/2026-07-01-redis-afs-md-workload-reproduction.md` | Redis AFS markdown grep/search/file-operation workload evidence. |
| `docs/tmp/2026-07-01-redis-afs-indexed-search-workload-reproduction.md` | Redis AFS Docker `redis:8` Search follow-up, current-CLI markdown run, and indexed-backend caveat. |
| `docs/tmp/2026-07-02-redis-afs-lifecycle-workload-reproduction.md` | Redis AFS fresh-checkout lifecycle reproduction: create/import/mount/query/checkpoint/bookmark/fork/unmount positives, inotify-limit rerun evidence, and mounted-edit sync/create-exclusive caveats. |
| `docs/tmp/2026-07-02-mirage-workload-reproduction.md` | Mirage official Python workload/test reproduction: 468 focused tests, 13 integration truth-diff cases, and 11 Python examples over command conformance, multi-backend namespace, cache, snapshot, cross-mount, and version-branching behavior. |
| `docs/tmp/2026-07-02-mirage-typescript-fuse-workload-reproduction.md` | Mirage TypeScript/FUSE reproduction: TypeScript build, 5522 passed package tests, 15/15 TypeScript examples, explicit FUSE integration, Python FS shim truth check, and cleanup checks. |
| `docs/tmp/2026-07-01-agent-runtime-environment-workload-reproduction.md` | OpenHands SDK, Terminal-Bench, SWE-ReX, SWE-MiniSandbox, AgentCgroup, SWE-rebench V2, SWE-Factory, MEnvAgent, Multi-Docker-Eval, and DockSmith artifact evidence. |
| `docs/tmp/2026-07-01-terminal-bench-acl-workload-reproduction.md` | Terminal-Bench official `acl-permissions-inheritance` task reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-filesystem-suite-reproduction.md` | Terminal-Bench official `deterministic-tarball`, `tree-directory-parser`, and `nginx-request-logging` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-file-security-suite-reproduction.md` | Terminal-Bench official `decommissioning-service-with-sensitive-data`, `git-leak-recovery`, `recover-obfuscated-files`, and `fix-permissions` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-git-service-suite-reproduction.md` | Terminal-Bench official `configure-git-webserver`, `extract-safely`, `openssl-selfsigned-cert`, `git-multibranch`, and `sanitize-git-repo` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-package-data-suite-reproduction.md` | Terminal-Bench official `multi-source-data-merger`, `home-server-https`, and `pypi-server` tasks reproduced through the upstream harness and oracle agent; `postgres-csv-clean` preserved as a setup-level negative. |
| `docs/tmp/2026-07-01-terminal-bench-data-log-service-suite-reproduction.md` | Terminal-Bench official `csv-to-parquet`, `jsonl-aggregator`, `analyze-access-logs`, `fibonacci-server`, and `db-wal-recovery` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-data-sql-log-suite-reproduction.md` | Terminal-Bench official `jq-data-processing`, `pandas-etl`, `pandas-sql-query`, `sqlite-db-truncate`, `log-summary`, and `log-summary-date-ranges` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-security-network-suite-reproduction.md` | Terminal-Bench official `sql-injection-attack`, `vul-flask`, `vulnerable-secret`, and `fix-code-vulnerability` tasks reproduced through the upstream harness and oracle agent; `cron-broken-network` and `broken-networking` preserved as live-network/setup boundaries. |
| `docs/tmp/2026-07-01-terminal-bench-file-service-pipeline-suite-reproduction.md` | Terminal-Bench official `large-scale-text-editing`, `processing-pipeline`, `jupyter-notebook-server`, `fix-git`, `new-encrypt-command`, `kv-store-grpc`, and `pcap-to-netflow` tasks reproduced through the upstream harness and oracle agent; unmodified `shell-deobfuscation` preserved as an artifact-permission boundary with a passing permission-adapted replay. |
| `docs/tmp/2026-07-01-terminal-bench-forensics-document-suite-reproduction.md` | Terminal-Bench official `reverse-engineering`, `financial-document-processor`, `crack-7z-hash`, `filter-js-from-html`, `heterogeneous-dates`, `extract-elf`, and `html-finance-verify` tasks reproduced through the upstream harness and oracle agent; `password-recovery` preserved as a workload-level oracle failure. |
| `docs/tmp/2026-07-01-terminal-bench-build-env-suite-reproduction.md` | Terminal-Bench official `broken-python`, `npm-conflict-resolution`, and `setup-custom-dev-env` tasks reproduced through the upstream harness and oracle agent; `build-cython-ext` preserved as a repository-test oracle failure after 10/11 parser checks passed. |
| `docs/tmp/2026-07-01-terminal-bench-compile-system-suite-reproduction.md` | Terminal-Bench official `modernize-fortran-build`, `polyglot-c-py`, `sqlite-with-gcov`, and `build-tcc-qemu` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-env-debug-suite-reproduction.md` | Terminal-Bench official `conda-env-conflict-resolution` and `fix-pandas-version` tasks reproduced through the upstream harness and oracle agent; `incompatible-python-fasttext` preserved as a Docker-build boundary and `amuse-install` preserved as an attempted task without an upstream result summary. |
| `docs/tmp/2026-07-01-terminal-bench-data-file-debug-suite-reproduction.md` | Terminal-Bench official `bank-trans-filter`, `cpp-compatibility`, `recover-accuracy-log`, `regex-log`, `organization-json-generator`, and `modernize-scientific-stack` tasks reproduced through the upstream harness and oracle agent. |
| `docs/tmp/2026-07-01-terminal-bench-service-api-suite-reproduction.md` | Terminal-Bench official `simple-web-scraper`, `create-bucket`, and `simple-sheets-put` tasks reproduced through the upstream harness and oracle agent; `mlflow-register` preserved as an attempted task without an upstream result summary. |
| `docs/tmp/2026-07-01-environment-dataset-and-partial-fs-reproduction-update.md` | Environment-dataset and partial filesystem reproduction update. |
| `docs/tmp/2026-07-01-menvdata-polyglot-eval-extension.md` | MEnvData-SWE Python/Go/Rust row replay status. |
| `docs/tmp/2026-07-01-multi-docker-eval-evaluator-probe.md` | Multi-Docker-Eval evaluator probe with synthetic `docker_res`. |
| `docs/tmp/2026-07-01-official-workload-reproduction-extension.md` | Consolidated upstream workload/test extension record. |
| `docs/tmp/2026-07-01-deltafs-posix-workload-extension.md` | DeltaFS POSIX VPIC and large-directory generator runs plus multi-rank/server negative evidence. |
| `docs/tmp/2026-07-01-tablefs-fsbench-individual-workload-reproduction.md` | TableFS individual fsbench split-run evidence and remaining segfaulting groups. |
| `docs/tmp/2026-07-01-indexfs-workload-extension.md` | IndexFS official tree-test build blockage plus passing source POSIX mdtest workload-shape runs. |
| `docs/tmp/2026-07-01-deltafs-mpirank-minimal-diagnostic.md` | DeltaFS minimum 2-rank POSIX diagnostic showing multi-rank timeout persists at tiny scale. |
