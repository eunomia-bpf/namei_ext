# Research State

Last updated: 2026-07-02
Status: handoff pointer only.

This file is intentionally short. It does not own related-work, novelty,
baseline, workload-source, or result verdicts.

## Canonical Layout

| Need | Read/update |
| --- | --- |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, closest work, source-use verdicts, mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone Phase 1 research/implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `results/` |
| Historical plans and paper drafts | `docs/research_plan.md`, `docs/case_studies.md`, `docs/experiment-plans/*.md`, `docs/phase1_design.md`, `docs/paper/README.md`, `docs/paper/*` routing stubs |

## Current Project State

- Stage: runnable `namei_ext` prototype plus source-backed workload selection.
- Current paper idea: a narrow VFS name-resolution extension point where an
  eBPF policy selects path-view actions while the kernel and lower filesystem
  keep ownership of VFS objects, data path, permissions, writes, and ordinary
  filesystem semantics.
- Current claim boundary: do not claim workloads require eBPF, `namei_ext`, or
  dynamic policy logic; do not frame the paper around table-only impossibility.
- Paper-facing workload direction: AI agent workspace lifecycle first, W4
  environment/cache transition second, W2 service reload/update upgrade third.
- `table_redirect.bpf.c`: archived boundary ablation only, not the next
  research mainline.
- The paper draft tree under `docs/paper/` is routing-only after the
  2026-07-02 skill-layout compression; it should not be used as a current
  claim, workload, or result source.

## Latest Source-Reproduction State

- BranchFS now has an independent 2026-07-02 rerun: release build passed,
  upstream `run_all_tests.sh` passed, Rust ioctl/integration tests passed
  8/8 and 22/22, and quick Python/shell benchmarks were captured under
  `results/reproduction/2026-07-02-official-workloads/branchfs/`.
- Sandlock now has a machine-readable summary over preserved raw logs: CLI
  tests and manual COW/protected-path smoke pass; named-UNIX,
  resource-control, and default Go pkg-config sub-oracles remain caveats.
- Redis AFS now has a fresh-checkout lifecycle reproduction: `afs` builds and
  create/import/mount/query/checkpoint/bookmark/fork/unmount paths pass against
  isolated Redis; live mounted edit synchronization is not claimed because
  v1/v2 hit host inotify watcher exhaustion and v4 still did not reflect
  mounted edits in `afs fs get/find`, fork grep, or checkpoint diff after the
  inotify limit was raised.
- AgentFS official SDK/CLI/integration/examples reproduced positively; earlier
  `pjdfstest` and adapted `xfstests` remain full-filesystem conformance caveats.
- YoloFS public compat-branch mounted VM e2e now reproduces: after guest build
  dependency installation and cleanup of local generated kmod artifacts,
  upstream `make test-e2e-vm` built/installed `yolofs.ko`, loaded the module,
  ran 593/593 mounted e2e tests, unloaded the module, and stopped the VM.
  Private `agent-eval` and `perf-eval` submodules remain unreproduced.
- Mirage official workload/test evidence now includes both the earlier Python
  subset and a TypeScript/FUSE follow-up: TypeScript build/test passed, 5522
  package tests passed, 15/15 TypeScript examples matched truth files, explicit
  FUSE integration matched 9/9 truth lines, and the Python FS shim example
  matched 4/4 truth lines. Live SaaS/API provider backends and deployed
  long-running service behavior remain unreproduced.
- SWE-agent official tests reproduced through partitioned pytest runs.
- OpenHands SDK now has an independent targeted reproduction record covering
  195/195 remote-workspace, file-editor workspace-root, and terminal-session
  tests. A follow-up DockerWorkspace backend record now reproduces the official
  prebuilt agent-server image with real container startup/health, mounted
  `/workspace`, command execution, API file upload/download, pause/resume, and
  cleanup. OpenHands Cloud, Kubernetes, browser, and live LLM paths remain
  unreproduced.
- AgentCgroup now has an independent reproduction record covering controller
  tests, wrapper tests, trace-driven integration, fast characterization,
  scheduler/process builds, and the `memcg_bpf_ops` host-kernel boundary.
- SWE-MiniSandbox now has an independent core-sandbox reproduction record
  covering private `/tmp` tmpfs, mount namespace/chroot startup command
  generation, and concurrent sandbox isolation.
- SWE-ReX now has an independent local/remote-runtime reproduction record
  covering file transfer, command execution, shell sessions, timeout/interrupt
  behavior, pager handling, interactive commands, multi-session isolation, and
  a single preserved auth status-code drift. A follow-up Docker backend record
  built `swe-rex-test:latest` and passed 6/6 Docker deployment tests; Modal,
  Fargate, and Daytona remain unreproduced.
- SWE-rebench V2 now has an independent README sample reproduction record and
  selected public HF sample follow-ups. `unidata__netcdf-c-1925` passed the
  Docker evaluator with all 12 fail-to-pass tests passed, no pass-to-pass
  failures, and `all_ok=true`. Four public HF Clojure rows now reproduce
  through the official evaluator: `pilosus__pip-license-checker-119`,
  `chrovis__cljam-268`, `yogthos__migratus-223`, and
  `pilosus__pip-license-checker-49`; all report `all_ok=true` and
  `passed_match=true`. Preserve the `yogthos__migratus-223` caveat: the raw
  row `exit_code` is 1 due a nested testcontainers Docker-socket error, so
  cleaner W4 candidates are `pilosus` and `chrovis` rows. A public HF
  JavaScript row, `pbiswas101__mathball-153`, now also passes with raw exit
  code 0, 406/406 fail-to-pass tests, no pass-to-pass failures, and
  `all_ok=true`. A public HF Dart row, `nyxx-discord__nyxx-547`, also passes
  with raw exit code 0, 15/15 fail-to-pass tests, 0/520 pass-to-pass failures,
  and `all_ok=true`. A public HF Go row, `mgechev__revive-1408`, also passes
  with raw exit code 0, 2/2 fail-to-pass tests, 0/492 pass-to-pass failures,
  and `all_ok=true`. A second public HF Go row,
  `hashicorp__consul-10576`, also passes cleanly with raw exit code 0, 39/39
  fail-to-pass tests, 0 pass-to-pass failures, and `all_ok=true`. A public HF
  Java row, `spoonlabs__gumtree-spoon-ast-diff-171`, also passes with raw exit
  code 0, 2/2 fail-to-pass tests, 0/2 pass-to-pass failures, and
  `all_ok=true`. C# `btcpayserver__btcpayserver-6251` and Elixir
  `mhanberg__temple-135` are evaluator-positive but have raw row exit-code
  caveats. A follow-up completed attempted coverage of the remaining public HF
  sample rows: Elixir/Go remaining rows (`elixir-ecto__ecto-2338`,
  `rrrene__credo-711`, `ceph__go-ceph-502`, and
  `fsouza__fake-gcs-server-1035`) are all evaluator-positive, with `fsouza`
  clean raw exit 0; Java remaining rows have clean `jchambers__pushy-850`,
  evaluator-positive raw-exit caveats for `gchq__gaffer-2904` and
  `apache__streampipes-2889`, and one mismatch:
  `alibaba__fescar-382` passed 24/25 expected F2P and missed
  `---NO TEST NAME FOUND YET---`. Public HF sample accounting is now 20/20
  attempted, 19/20 evaluator-positive, 11/20 clean raw-exit-0 positives, 8/20
  evaluator-positive raw-exit caveats, and 1/20 mismatch. This is still not
  full corpus, image-builder, or environment-generation reproduction.
- SWE-Factory-Gym now has a single-row replay plus a multirepo follow-up:
  `pallets__click-2622` resolved first, then `python-attrs__attrs-556`,
  `mochajs__mocha-1965`, and `iamkun__dayjs-337` all completed and resolved
  with `OMNIGRIL_EXIT_CODE=0`. The `iamkun/dayjs` row keeps a post-oracle
  cleanup warning as an artifact caveat.
- MEnvData-SWE now has an independent selected-row replay record: Python
  `python-attrs__attrs-586` and Go `go-task__task-1814` pass with
  `OMNIGRIL_EXIT_CODE=0`; Rust `eyre-rs__color-eyre-114` remains a preserved
  negative test-patch artifact caveat.
- The first follow-up MEnvData-SWE language extension attempted the remaining
  language families with released image/eval rows: JavaScript, Ruby, PHP,
  Java, and C pass with `OMNIGRIL_EXIT_CODE=0`; TypeScript, C++, and Rust are
  preserved negative artifact rows. That extension brought attempted coverage
  to all 10 dataset languages, with positive rows for seven at that point.
- A MEnvData-SWE positive retry closed the remaining language-positive gap:
  TypeScript `sindresorhus__type-fest-818`, C++ `CLIUtils__CLI11-926`, and
  Rust `cobalt-org__liquid-rust-403` pass with `OMNIGRIL_EXIT_CODE=0`;
  combined MEnvData evidence now has positive selected rows for all 10 dataset
  languages. Earlier negative rows remain artifact caveats.
- DockSmith now has a trajectory-inspection and smoke-replay record. Local
  shard 1 of `8sj7df9k8m5x8/docker_building_training` contains 298 instances
  with tagged Dockerfile/eval-script text, but tagged eval scripts use
  placeholder test patches rather than concrete official fail-to-pass patches.
  A trajectory-derived smoke replay for `00imvj00__mqttrs-7` built the
  extracted Dockerfile, ran target Rust tests at commit
  `77d51fb5449394e450b3565205d989433511082b`, passed 15 decoder and 14 encoder
  tests, and reported `OMNIGRIL_EXIT_CODE=0`. Treat DockSmith as trajectory and
  smoke workload evidence, not full official benchmark reproduction.
- Multi-Docker-Eval now has a second-language public-task replay beyond the
  earlier Go synthetic/manual probe. Public Python task
  `pallets-eco__flask-wtf-512` was run through the upstream evaluator with a
  manual `docker_res`: v1 exposed missing `pytest`, v2 exposed current
  Flask/Werkzeug dependency drift, and v3 pinned `Flask==2.1.3`,
  `Werkzeug==2.1.0`, and `WTForms==3.0.1`, producing a positive F2P result
  with before-patch failure, after-patch 13/13 target tests passed,
  `resolved=1`, and `stable=1`. This remains manual-environment evidence; the
  public dataset still lacks official generated `docker_res`.
- Terminal-Bench selected official-task evidence, OpenHands SDK, SWE-ReX,
  SWE-rebench V2, SWE-Factory-Gym, MEnvData-SWE, Multi-Docker-Eval, Redis AFS,
  BranchFS, Sandlock, YoloFS, DeltaFS, TableFS, and IndexFS statuses are
  indexed in `docs/background-related-work.md` and
  `docs/reference/CODE_SOURCES.md`.

## Next Action

Implement a Make-owned, KVM-validated AI agent workspace lifecycle workload in
`namei_ext`. The workload should include a real source-backed oracle, a
state-transition path view, operation-weighted lookup/readdir signal, and
natural baselines such as source-system/FUSE/materialized/native behavior.

Second priority is a W4 environment/cache run with real stale/corrupt/update or
environment-reuse behavior. Third priority is a W2 real reload/update or
secret/config rotation trace.

Do not add new source-role or novelty verdicts to `research/*.md`; update the
canonical docs above instead.
