## results/workloads: workload companion builds and traces, W5 DMTCP host checks, source provenance

Slice: the 134 `results/workloads/*` units (129 `runs/<RUN_ID>`, 3 `checkpoint-restore-source/<RUN_ID>`, `preflight/checkpoint-restore-pathvirt`, `provenance`). That is 14.85 GB (13.83 GiB) in 11,035 files per `units.tsv`, written 2026-06-13 to 2026-08-08. The per-unit rows are in `p4-workloads.csv`.

### What this tree is

`mk/workload.mk` defines `WORKLOAD_RUN_ROOT = $(RESULT_ROOT)/workloads/runs/$(RUN_ID)`. Each consuming experiment target pulled in host-side `workload-*` prerequisites under the same `RUN_ID`. The KVM experiment wrote to `results/phase1/<RUN_ID>` (and, for some July runs, also to `results/experiments/<suite>/<RUN_ID>`), and the workload layer wrote its host-side inputs here. The consumers were the phase1 KVM targets in `mk/kvm.mk` and, later, `mk/experiments/*.mk`. Of the 129 `runs/` directories, 121 have a KVM-side twin with the same name. Those twin roots belong to other parts of this archive:

| Twin location | Runs |
|---|---:|
| `results/phase1` only | 110 |
| `results/phase1` and `results/experiments/build-cache` | 5 |
| `results/experiments/service-config-rotation-preflight` only | 6 |
| no twin: the 5 group-B runs, the W3 capability audit, the 2 Spindle checks | 8 |

Source trees and built binaries were never stored here. They live in `.build/workloads/runs/<RUN_ID>/`. What is stored here is the following:

- build and configure logs, `build.json`
- the strace `%file` raw trace, `trace.json`, and the source-build manifest `manifest.json`
- the trace-witness manifest `alias-manifest.json`
- W2/W3/W4 witness manifests with tiny fixture files
- oracle-entry TSVs
- `w1-build-output-oracle.jsonl`

Every manifest records `run_environment=host`, `policy_executed=false`, `kvm_validated=false`, `output_hash_oracle=false`, and a `c1_c8_gate` string beginning `not_validated_until_...`. None of the files here is namei_ext policy evidence. They are the inputs that the KVM runs consumed.

Producer history:

- Commit `5c0b1f9` (2026-06-27) is the first tracked appearance of `mk/workload.mk`, `configs/eval-osdi/workload-sources.mk`, and `workloads/legacy/*/evidence.md`. That is a history import: the June runs predate it.
- Commit `0f6b731` (2026-07-25) removed the manifest, fixture, checkpoint, cache, oracle-entry, output-oracle, and podman-capability `workload-*` targets, together with the `mk/kvm.mk` phase1 targets. The last full definitions are at `0f6b731^`.
- Still present in the current `mk/workload.mk`: `workload-redis-build`, `workload-nginx-build`, the source/provenance targets, and the DMTCP, sandboxfs, and Spindle targets. The ccache/build-cache KVM targets now live in `mk/experiments/legacy_build_cache.mk`.

**Bulk payload versus measurement** (bytes from a read-only walk; this walk's file counts include symlinked files, so they total about 25 more than `units.tsv`):

| Content | Size | Files | Kind |
|---|---:|---:|---|
| strace `%file` raw traces (`strace.log*`, plus per-PID `strace.<proj>.<pid>` in 2 early runs) | 12,966 MiB | 6,655 | raw trace payload. Summarized by `trace.json:file_op_lines` and alias-manifest hits, recorded below. |
| DMTCP source build trees copied into the 3 `checkpoint-restore-source` runs | 806.8 MiB | 2,673 | payload (build tree, binaries, objects) |
| DMTCP install copies (2 source runs + preflight v4) | 214.6 MiB | 87 | payload |
| DMTCP checkpoint images (`.dmtcp`, about 24.4 MB each, 7 images) plus restart scripts | 162.9 MiB | 21 | payload |
| preflight DMTCP `dmtcp-source.tar.gz` + 4 source files, 2 runtime binaries | 3.5 MiB | 7 | payload |
| build/configure logs | 7.6 MiB | 410 | measurement logs |
| JSON manifests, TSVs, fixture stubs | 2.2 MiB | 894 | measurement/metadata |
| Spindle debug log (1 file) | 2.7 MiB | 1 | log |
| W5 observations, lower-object JSONL, controller logs | 0.2 MiB | 295 | measurement |
| `provenance/` | 0.2 MiB | 17 | metadata (fully recorded below) |

Per-group size from `units.tsv`:

| Group | Units | Size |
|---|---:|---:|
| A | 11 | 4,185 MiB |
| B | 5 | 1,942 MiB |
| C | 18 | 6,845 MiB |
| D–J together | 95 | 7.3 MiB |
| K | 3 | 1,020 MiB |
| L | 1 | 168 MiB |
| M | 1 | 0.2 MiB |

**Status across the slice:** 132 completed and 2 failed. The two failures are the W3 Podman/CRIU capability audit, which failed as the tracked doc expected, and the first Spindle source check. No run is empty or incomplete.

### Facts constant across runs (recorded once)

**Build configuration** (identical in 195 of the 197 `build.json` files):

- Redis 7.2.14: `make redis-server BUILD_TLS=no MALLOC=libc JOBS=24`, with `GIT_CEILING_DIRECTORIES` set to the per-run source root from `20260614T-workloads-git-ceiling` onward.
- nginx 1.26.3: `./configure --without-http_rewrite_module --without-http_gzip_module`, then `make` with `JOBS=24`.
- Toolchain: `cc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`. Traced rebuilds used `strace -- version 6.8` with `-f -e trace=%file`.
- The other 2 files belong to the first run, `20260614T-workload-w1`, which records no toolchain or JOBS fields.

**Binary hashes are not reproducible.** The build binary sha256 differs in every run, and differs again between the build and the traced rebuild of the same run. Absolute per-run source paths are embedded in the binary. The hashes therefore identify a run's binary; they are not reproducibility evidence.

**W1 trace-witness candidates** (`alias-manifest.json`). These are identical in all 29 runs that have one (groups A and C). Only the sha of the generated header changes per run. The table shows trace hits per candidate:

| Workload | Candidate (branch) | Backing sha256 prefix | Hits |
|---|---|---|---:|
| redis | `src/release.h` (generated_output) | regenerated each run | 18 |
| redis | `src/server.c` (declared_source_fallback) | 33c30ca97306 | 2 |
| redis | `cc` → `/usr/bin/gcc` (toolchain_selection) | 1b99826121ae | 1,534 |
| redis | `/usr/include/stdio.h` (external_dependency) | b4f6709d12c8 | 4,138 |
| redis | **total** | | **5,692** |
| nginx | `objs/ngx_auto_config.h` (generated_output) | regenerated each run | 225 |
| nginx | `objs/ngx_auto_headers.h` (generated_output) | 268bec1c0f60 | 129 |
| nginx | `src/core/nginx.c` (declared_source_fallback) | c1a2139c1a39 | 7 |
| nginx | `cc` → `/usr/bin/gcc` (toolchain_selection) | 1b99826121ae | 2,113 |
| nginx | `/usr/include/stdio.h` (external_dependency) | b4f6709d12c8 | 3,164 |
| nginx | **total** | | **5,638** |

Branch coverage is 4 of 6 in every run. `undeclared_dependency_poison` and `negative_fallback` are false, with the recorded reason "clean host configure/build trace does not exercise poison or negative probes".

`candidate_witness_hit_rate` is the number of hits divided by all strace `%file` lines, with `release_gate_eligible=false`. Its ranges:

- nginx: 0.0031378–0.0031386
- redis: 0.0046024–0.0046471

**W2/W3/W4 witness manifests.** The candidate sets are byte-identical in every run that contains them. Each entry gives visible name → shadow backing name, with the backing sha prefix:

| Manifest | Candidates | Branch coverage |
|---|---|---|
| `w2-nginx-fixture`, 26 runs | `nginx.conf`→`nginx.test.conf` (2d37a18dbf88); `server.crt`→`server.fake.crt` (679440add19e); `upstream.sock`→`upstream.local` (d3b36896c2c2); `prod.token`→`poison.secret` (842352db5251) | 4/6: config, certificate, endpoint, poison |
| `w2-postgres-secret-fixture`, 11 runs | `postgresql.conf`→upstream `postgresql.conf.sample` (263421e9f1d3); `db.password`→`db.fake.pass` (4a1ffb26769f) | 2/7 |
| `w3-redis-podman-criu`, 15 runs | `dump.rdb`→`dump.ckpt` (00e25c63e669); `appendonly.aof`→`aof.ckpt` (70153de522ba); `redis.sock`→`redis.sock.new` (f56d6b0052df); `epoch.bad`→`poison.epoch` (b33c5e06d634) | 3/5: state, runtime, mixed_epoch |
| `w3-nginx-podman-criu`, 15 runs | `nginx.conf`→upstream sample conf (95363d79620c); `cache.db`→`cache.ckpt` (70db79736300); `nginx.pid`→`nginx.pid.new` (48bfd6263593) | 3/5 |
| `w4-ccache-redis-nginx`, 26 runs | verified_hit `object.o`→`object.local` (b60cdc322bfa); stale `stale.o`→`stale.canon` (ba83367f47c2); corrupt `corrupt.o`→`corrupt.reject` (e32145600fc7) | 3/5: miss and pass_through false |
| `w4-buildkit-prometheus-go-cache`, 26 runs | miss_canonical `pkg.mod`→`pkg.canon` (9f4ce6feb314, which is the Prometheus `go.mod` sha) | 1/5 |

The recorded reason the W3/W4 coverage is partial: "current W3 path oracle does not run CRIU/Podman restore" and "current W4 path oracle does not run ccache".

**Oracle-entry TSV row counts:** W1 has 9 rows (4 redis + 5 nginx), W2 has 6, W3 has 7, W4 has 4.

### A. Full workload set for multi-suite phase1 runs (11 runs, 4.19 GB)

**Producer.** These are the prerequisites of `make phase1` and the `kvm-w{1..4}-oracle` targets: `workload-build-graph`, `workload-sandbox-fixture`, `workload-checkpoint-restore`, `workload-cache-locality`, and the `workload-w1..w4-oracle-entries` targets. From 2026-06-14 on, `workload-w1-build-output-oracle` was added as well. All of these are in `mk/workload.mk` at `0f6b731^`.

**Design record.** `docs/tmp/2026-06-14-real-build-graph-workload-trace.md` describes the design: clean per-run source trees, a single strace log instead of per-PID files, and `GIT_CEILING_DIRECTORIES` so that Redis release-header generation does not scan the parent repo.

**Outcome.** All 11 runs passed on the workload side. Each run has:

- builds, traces, and both witness manifests
- all six W2/W3/W4 manifests
- the four TSVs
- `w1-build-output-oracle.jsonl` with 3 of 3 rows passing (2 workload rows plus the summary) in the 8 runs that have it

`git-ceiling`, `w4-cache-content-phase1`, and `w4-cache-content-map-phase1` predate the output-oracle target.

| RUN_ID | nginx build/trace s | redis build/trace s | nginx `%file` lines | redis `%file` lines | output oracle |
|---|---|---|---:|---:|---|
| 20260614T-workloads-git-ceiling | 2.96 / 12.07 | 4.25 / 10.19 | 1,796,791 | 1,234,834 | – |
| 20260614T-w2-nginx-probes-phase1 | 2.91 / 10.55 | 3.74 / 10.49 | 1,796,480 | 1,235,623 | 3/3 |
| 20260614T-w4-cache-content-phase1 | 2.96 / 10.40 | 3.82 / 10.18 | 1,796,629 | 1,235,055 | – |
| 20260614T-w4-cache-content-map-phase1 | 3.08 / 10.62 | 3.82 / 10.84 | 1,796,349 | 1,235,513 | – |
| 20260615T-parent-key-poc | 4.45 / 14.92 | 8.17 / 25.06 | 1,796,476 | 1,224,839 | 3/3 |
| 20260615T-full-phase1-gatefix | 3.02 / 10.66 | 3.81 / 10.13 | 1,796,404 | 1,235,512 | 3/3 |
| 20260615T-full-phase1-bench-variants | 2.95 / 10.46 | 3.97 / 10.85 | 1,796,400 | 1,235,976 | 3/3 |
| 20260615T-full-phase1-b12-refresh-v1 | 2.98 / 10.62 | 3.67 / 10.27 | 1,796,564 | 1,235,289 | 3/3 |
| 20260615T-full-phase1-c2-release-sample-v1 | 2.96 / 10.30 | 3.79 / 10.21 | 1,796,526 | 1,236,752 | 3/3 |
| 20260615T-full-phase1-c2-setup-update-v1 | 2.97 / 10.40 | 3.80 / 10.17 | 1,796,488 | 1,235,552 | 3/3 |
| 20260617T-c4-lookup-readdir-kvm-v1 | 2.98 / 11.77 | 3.76 / 10.19 | 1,796,723 | 1,235,567 | 3/3 |

**Comparison with tracked docs.** Every number the tracked docs state agrees with the raw data:

- **`20260614T-workloads-git-ceiling`** (canonical in `docs/tmp/2026-06-14-real-build-graph-workload-trace.md` and in the W2/W3/W4-buildkit `workloads/legacy/*/evidence.md`):
  - raw `%file` lines 1,234,834 / 1,796,791 match the doc
  - hit rates 0.004609526462666237 / 0.0031378162513058003 match
  - binary sha 6abd37c6998c… / 9c587881ce73… match
- **`20260615T-parent-key-poc`** (canonical in `workloads/legacy/w1-{redis,nginx}-build/evidence.md`):
  - 1,224,839 / 1,796,476 lines, 4/5 candidates, and 5,692/5,638 hits match
  - rates 0.004647141379397619 / 0.00313836644630933 match
  - `docs/tmp/2026-06-15-w1-branch-probe-review-fix.md` records that the paper's `05-evaluation.tex` then bound W1 evidence to this workload root with these line counts. The current paper text cites no `results/workloads` path; the reference was removed in `762741e`.
  - This run's builds and traces are about 1.5–2.5x slower than the other runs (8.17 s and 25.06 s for Redis). The cause is not recorded.
- **`20260614T-w2-nginx-probes-phase1`** (`docs/tmp/2026-06-14-w1-host-build-output-oracle.md`): binary sha c6676758f2b9… / d62549c506b5… and the summary pass match.
- **Path citations.** `full-phase1-gatefix` (`workloads/legacy/w4-ccache-redis-nginx/evidence.md`), `c2-release-sample-v1` (`docs/tmp/2026-06-15-c2-workload-macrobench-design.md`), and `b12-refresh-v1` cite manifest paths only. All of those paths exist.

### B. Early W1 build/trace iterations, 2026-06-13 (5 runs, 1.94 GB, uncited)

These are earlier forms of `workload-{redis,nginx}-build[-trace,-manifest]` and have no trace-witness manifest. No tracked doc names these runs. The design doc above describes the changes they led to.

| RUN_ID | Layout | nginx build/trace s | redis build/trace s | nginx lines | redis lines |
|---|---|---|---|---:|---:|
| 20260614T-workload-w1 | shared source dir; strace `-ff` (2,599 + 1,101 per-PID files) | 3.16 / 10.93 | 3.88 / 11.50 | 1,013,531 | 1,004,192 |
| 20260614T-workload-w1b | shared source dir; per-PID (2,598 + 225 files) | 3.14 / 10.55 | 1.20 / 5.89 | 1,013,753 | 547,782 |
| 20260614T-workload-w1c | per-run source dir; single logs; no git ceiling | 3.02 / 10.53 | 3.77 / 11.20 | 1,796,657 | 1,636,048 |
| 20260614T-workloads-fixes | same as w1c | 3.22 / 10.66 | 3.92 / 11.20 | 1,796,577 | 1,635,350 |
| 20260614T-workloads-top | same as w1c | 3.36 / 11.04 | 3.82 / 11.73 | 1,796,563 | 1,635,996 |

**Notes:**

- In w1b, the Redis build took 1.20 s and produced only 225 per-PID files and 547,782 lines. That is consistent with an incremental build in the shared source tree, the problem the per-run trees were introduced to avoid.
- In w1 and w1b, `file_op_lines` (about 1.01M) counts only `strace.log`. In w1, separate per-PID files hold a further 787,180 make lines and 226,351 configure lines, so these counts are not comparable with the single-log count of about 1.797M used from w1c onward.
- Redis without `GIT_CEILING_DIRECTORIES` produced about 1.636M lines. With it, from git-ceiling onward, the count is about 1.235M: a drop of roughly 400k file operations attributed to git probing of the parent repo.

### C. W1 build-graph for W1 macrobench and baseline runs (18 runs, 6.84 GB)

**Producer.** These are prerequisites of `kvm-w1-build-macrobench`, `kvm-w1-build-baseline-macrobench`, and the FUSE/projected/test baselines, via `workload-w1-oracle-entries`, which needs both alias manifests. Contents: builds, traces, and the W1 witness for both projects, plus the 9-row TSV. All 18 passed. The candidate hits are exactly 5,638 (nginx) and 5,692 (redis) in every run.

| Metric | Median | Range |
|---|---:|---:|
| nginx build | 2.99 s | 2.91–3.25 s |
| redis build | 3.74 s | 3.69–3.95 s |
| nginx traced rebuild | 11.57 s | 10.36–12.28 s |
| redis traced rebuild | 10.15 s | 10.01–10.47 s |
| nginx `%file` lines | | 1,796,367–1,796,828 |
| redis `%file` lines | | 1,234,771–1,236,490 |

Runs, as nginx/redis build seconds:

- 2026-06-16:
  - baseline-all-smoke-v1: 2.97/3.71
  - baseline-release-sample-v1: 3.01/3.71
  - baseline-release-sample-v2: 3.20/3.87
  - baseline-smoke-v1: 2.91/3.74
  - baseline-smoke-v2: 2.96/3.73
  - fuse-baseline-smoke-v1: 3.12/3.77
  - macrobench-release-sample-v1: 2.97/3.69
  - macrobench-smoke-v1: 3.08/3.72
  - macrobench-smoke-v2: 3.25/3.93
  - macrobench-smoke-v3: 3.02/3.80
- 2026-06-17:
  - baseline-release-sample-v3: 2.99/3.74
  - fuse-baseline-test-hardgate-release-v1: 2.97/3.74
  - fuse-baseline-test-hardgate-release-v2: 3.02/3.78
  - fuse-baseline-test-hardgate-release-v3: 2.99/3.73
  - fuse-baseline-test-hardgate-release-v4: 2.92/3.74
  - fuse-baseline-test-release-v1: 2.93/3.70
  - fuse-baseline-test-smoke-v1: 2.93/3.79
  - macrobench-release-sample-v2: 3.22/3.95

**Tracked.** `docs/tmp/2026-06-16-w1-build-release-repetition-run.md` gives the workload root of `20260616T-w1-build-macrobench-release-sample-v1` as about 381M; the raw size is 380.3 MiB. Several docs cite the other run names, but only for their KVM results (W1 baseline, FUSE-baseline, and ledger docs). No tracked file summarizes their workload-side numbers, so the figures above are the only record.

### D. W2 nginx build + fixture (15 runs, 0.7 MiB)

**Producer.** These are prerequisites of `kvm-w2-nginx-{real,real-trace,macrobench,baseline-macrobench}`: `workload-nginx-build` plus `workload-nginx-fixture-manifest`. Contents: the nginx build (no trace) and the constant 4-candidate W2 nginx fixture. All 15 passed. nginx build median 2.95 s (range 2.92–3.05 s).

Runs:

- `20260614T-w2-nginx-probes`
- `20260615T-w2-nginx-c2-macrobench-{smoke,release-sample}-v1`
- `20260616T-w2-nginx-baseline-macrobench-{smoke-v1,release-sample-v1..v4}`
- `20260616T-w2-nginx-{bind,fuse,projected}-baseline-smoke-v1`
- `20260617T-w2-nginx-{baseline-hardgate,macrobench-hardgate,real-hardgate}-smoke-v1`
- `20260617T-w2-nginx-real-trace-release-v1`

**Tracked.** The W2 docs (`docs/tmp/2026-06-15/16/17-w2-nginx-*`) cite these run names only for their KVM results. There is no workload-side summary.

### E. W3 Redis build + checkpoint manifests (4 runs)

**Producer.** These are prerequisites of `kvm-w3-redis-{replay,table-replay,policy-macrobench,baseline-macrobench}`: `workload-redis-build` plus `workload-w3-oracle-entries`. Contents: the Redis build, both W3 manifests (4+3 candidates), and the 7-row TSV. All 4 passed. Redis build times:

| RUN_ID | Redis build |
|---|---:|
| 20260615T-w3-redis-counterfactual-smoke-v1 | 4.78 s |
| 20260616T-w3-redis-baseline-macrobench-smoke-v1 | 3.83 s |
| 20260616T-w3-redis-macrobench-release-v1 | 3.72 s |
| 20260616T-w3-redis-policy-macrobench-smoke-v1 | 3.79 s |

The KVM-side docs are `docs/tmp/2026-06-15-w3-table-replay-counterfactual-implementation.md` and `docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md`.

### F. W3 Podman/CRIU host capability audit (1 run, failed as designed)

`20260615T-w3-podman-criu-capability-audit-v1` came from `workload-w3-podman-criu-capability` (removed in `0f6b731`). It recorded:

- `podman_present=true`, `podman version 4.9.3`, `podman_checkpoint_help_ok=true`
- `podman_checkpoint_listed=false`: the help output is the generic command list, with no checkpoint command
- `criu_present=false`, empty `criu --version` output
- `pass=false`; the summary has `failures=1`

This matches `docs/tmp/2026-06-15-w3-podman-criu-capability-audit-implementation.md`, which states that the failure was expected and that W3 real Podman/CRIU restore stays blocked.

### G. W4 cache witness manifests (15 runs, 0.3 MiB)

**Producer.** These are prerequisites of `kvm-w4-cache-{content,table-content,transition-counterfactual}` via `workload-w4-oracle-entries`. Contents: both W4 manifests (3+1 candidates) plus a 4-row TSV. All 15 passed. The exception is `20260614T-w4-cache-content`, which has the manifests but no TSV.

Runs:

- `20260614T-w4-cache-content{,-map}`
- `20260615T-w4-cache-table-content-smoke-v1`
- `20260617T-w4-cache-content-hardgate-smoke-v1/v2`
- `20260617T-w4-cache-table-content-hardgate-smoke-v1..v3`
- `20260617T-w4-cache-transition-{hardgate-release-v1/v2,hardgate-smoke-v1,release-v1,smoke-v2}`
- `20260629T-w4-cache-transition-c8-{smoke,release}-v1`

Tracked docs (for example `docs/tmp/2026-06-14-w4-cache-content-oracle.md`, `docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md`, and `docs/tmp/2026-06-29-c8-killer-experiment-update.md`) describe only the KVM side.

### H. Redis + nginx plain builds for the W4 ccache and build-cache KVM runs (52 runs, 3.1 MiB)

**Producer.** These come from `workload-redis-build` and `workload-nginx-build`, still in `mk/workload.mk`. The consumers were `kvm-w4-ccache-{real,trace,bulk-trace,...}` and `kvm-build-cache-matrix`, then in `mk/kvm.mk` and now in `mk/experiments/legacy_build_cache.mk`. Those consumers compile Redis/nginx sources with ccache from `.build/workloads/runs/<RUN_ID>/`. Contents: `build.json` and logs only. All 52 completed.

| Date / cohort | Runs | nginx build, median (range) | redis build, median (range) |
|---|---:|---|---|
| 2026-06-15: w4-attach-window ×2, w4-parent-* ×7, w4-release-counterfactual, w4-valid-sibling-* ×4 | 14 | 3.05 s (2.98–7.93) | 3.86 s (3.73–40.77) |
| 2026-06-16: w4-ccache-bulk-*, materialized-, rule- (smoke and release) | 17 | 3.00 s (2.92–3.42) | 3.76 s (3.66–5.66) |
| 2026-06-29: w4-ccache-bulk-cache-epoch-c8 ×4, diagnose, fuse/native/policy-compile releases and shakeouts | 11 | 4.14 s (4.07–4.47) | 5.36 s (5.22–6.78) |
| 2026-07-23/24: build-cache{,-state}-{smoke,release}-v1, bad-local-{stale,corrupt-hidden}-smoke-v1, build-cache-bfs-integrated-smoke-v1, epoch-switch-{smoke-v1,smoke-v2,release-v2} | 10 | 4.34 s (4.04–15.78) | 5.63 s (5.34–14.90) |

**Outliers:**

- `20260615T-w4-parent-suffixguard-poc` took 7.93 s (nginx) and 40.77 s (redis).
- `20260723T-build-cache-state-smoke-v1` took 15.78 s and 14.90 s.
- From 2026-06-29 on, builds are about 35–45% slower, with identical toolchain and configuration. The host conditions are not recorded.

**Paper/eval citations.** `docs/evaluation.md` cites the KVM-side roots of five of these runs:

- `20260723T-build-cache-release-v1`: hot-cache compile, 400/400 oracle checks, FUSE/namei_ext 2.18x
- `20260723T-build-cache-state-release-v1`
- `20260724T-epoch-switch-release-v2`: 800/800 output matches, FUSE/namei_ext 2.10x
- `20260724T-bad-local-{stale,corrupt-hidden}-smoke-v1`

The workload companions here hold only the Redis/nginx `build.json` and logs for those runs. The build binaries (Redis 1e30a30ea307/45fa608fa683/e630cc986c7a, nginx 7639eca24ed4/4c7be2423f01/9c12a172a12a for the three release runs) are in the CSV. No tracked doc summarizes the workload side.

### I. nginx build for service-config-rotation preflights (6 runs)

**Producer.** `workload-nginx-build` as a prerequisite of `mk/experiments/service_config_rotation.mk`, for `20260728T-service-config-rotation-preflight-v1..v3` and `-v2-preflight-v1..v3`.

| Item | Value |
|---|---|
| nginx build time | 4.00–4.62 s |
| `build.json` copy | each `build.json` is byte-identical to the copy installed in `results/experiments/service-config-rotation-preflight/<RUN_ID>/artifacts/source/nginx-build.json`, so this unit is redundant with that root |
| consuming experiments | all 6 have `run.json` `status=failed`, `failure=kvm-launch-or-guest-command`, consistent with `docs/tmp/2026-07-28-service-config-rotation*-preflight-attempt-*.md` and the v2 result review ("terminally failed and incomplete") |

### J. Spindle source check (2 runs, uncited by id)

**Producer.** `make workload-spindle-source-check` (`mk/workload.mk`, added in `88f8b25`). It runs Spindle 8853636d2d77 with these arguments under `SPINDLE_DEBUG=3`:

```
--level=high --launcher=serial --pull --noclean=yes --strip=no test_driver --dlopen --pull --nompi
```

**`20260729T230000Z-5a1ce001` failed.** stderr is empty and the cache tree has 29 directories and 95 files. But no `spindle_output.*` debug log was captured, and `mapping-logs.txt` is 0 bytes, so the recipe's final `test -s mapping-logs.txt` gate fails.

**`20260729T231000Z-5a1ce002` passed:**

- stderr empty; same 29/95 cache tree
- debug log of 2,790,009 B and 16,390 lines
- 66 `Adding … spindlens-file` mapping records
- server statistics: libread 94 (33.35 MB), libstore 92, metadata 174, libdist 136, procdir 32

`docs/tmp/2026-07-29-spindle-hpc-staging-implementation.md` reports "66 total first-party file mappings, exactly 47 focal mappings". The 66 matches; the 47-focal subset was not re-derived here. Note that the run IDs say 23:00Z/23:10Z, but the file mtimes are 2026-07-29 05:57–05:58 local time.

### K. W5 DMTCP checkpoint-restore source-positive control (3 runs, 1.02 GB)

**Producer.** `make checkpoint-restore-source-feasibility` (`mk/experiments/checkpoint_restore.mk`; the result root is `$(RESULT_ROOT)/workloads/checkpoint-restore-source/$(RUN_ID)`).

**What each run does:**

- copies the built DMTCP 068559d9b14c source tree (`dmtcp-source/`, 806.8 MiB across the three runs, pure payload)
- in the later two runs, also copies the relocated install
- runs the upstream `make check-autotest AUTOTEST='--verbose pathvirt'`
- runs the namei_ext controller's PathTranslator `pathvirt` lifecycle on an A/B generation fixture

Every run passed:

- upstream autotest 1/1 (`test groups: pass=1 fail=0 skipped=0 total=1`)
- 8/8 controller cases
- generation A before the checkpoint (`restarts=0`, `saw_stale`), then generation B after restart (`restarts=1`, `restart_env_status=0`, `saw_new`)
- all 6 lower objects unchanged in inode, mode, size, mtime, and content
- one checkpoint image of about 24.4 MB

| RUN_ID | Install | Checkpoint ms | Update ns | Restart ms | Total ms | Launch stderr |
|---|---|---:|---:|---:|---:|---|
| 20260802T093352Z-fd5e7659 | build-tree | 30.6 | 49 | 204.0 | 642.9 | `libdmtcp_pathvirt.so` preload warning (123 B) |
| 20260802T094525Z-df8ae7d4 | relocated copy | 40.5 | 78 | 204.4 | 734.3 | same warning |
| 20260802T111500Z-w5-attempt5-source | relocated copy, `DMTCP_PATHVIRT_PLUGIN=1`, no `--pathvirt` | 30.3 | 24 | 203.3 | 680.2 | empty |

**Comparison with tracked docs.** All three agree with the raw data:

- `docs/tmp/2026-08-02-w5-checkpoint-restore-attempt-4-implementation.md` gives df8ae7d4 as "40.5 ms checkpoint, 204.4 ms restart, and 734.3 ms total", which matches. It says fd5e7659 used the build-tree install, which matches: that run has no `dmtcp-install` copy.
- `docs/tmp/2026-08-02-w5-attempt-4-result-and-attempt-5-plan.md` says attempt5 passed with an empty `dmtcp-launch.stderr.log`, which matches. The obsolete preload warning appears in the other two runs.
- `docs/tmp/2026-08-02-workload-evidence-audit.md` lists df8ae7d4 as the W5 DMTCP source-positive control. All docs state that these timings are diagnostic and are not W5 KVM or performance results.

### L. W5 DMTCP pathvirt host preflight (1 unit, 4 subruns, 168 MiB)

**Producer.** `make checkpoint-restore-pathvirt-host-preflight`, added in `6974030` and removed in `cd8aa2d`. All four subruns ran on 2026-07-28 with DMTCP 068559d9b14c plus `restart-env-scan-count.patch` (sha 7c945ba6f4bf). From v2 on, `run.json` records:

- `result_level=host_dependency_preflight`, `status=completed`
- source 5f5cba9218eb (dirty), kernel bdc9a83e3dfb (clean)

The checkpoint images (93 MiB) and v4's install copy (71.5 MiB), source tarball, and runtime binaries are payload.

| Subrun | Cases | Checkpoint ms | Update ns | Restart ms | Total ms | Upstream autotest |
|---|---:|---:|---:|---:|---:|---|
| dmtcp-restart-env-fix-v1 | 8/8 | 40.7 | 34 | 203.3 | 808.6 | not run (no `run.json`) |
| dmtcp-pathvirt-contract-v2 | 8/8 | 30.5 | 42 | 203.3 | 667.2 | 1/1 |
| dmtcp-pathvirt-contract-v3 | 8/8 | 40.6 | 54 | 203.1 | 667.2 | 1/1 |
| dmtcp-pathvirt-contract-v4 | 8/8 | 40.3 | 35 | 202.7 | 676.8 | 1/1 |

Every subrun shows the A→B transition (`restart_env_status=0` after restart) with the 6 lower objects unchanged.

**Tracked.** `docs/tmp/2026-07-28-dmtcp-restart-env-root-cause.md` and `docs/tmp/2026-07-28-checkpoint-restore-implementation-status.md` cite v4 with 40,293,948 ns checkpoint, 35 ns update, 202,661,059 ns restart, and 676,812,385 ns total. These match exactly. `docs/tmp/2026-07-28-dmtcp-source-feasibility.md` and `docs/tmp/2026-07-28-checkpoint-restore-plan-review.md` cite the v4 autotest pass, which matches. No doc cites v2, v3, or restart-env-fix-v1, so the table above is their only record.

### M. Source and build provenance (`results/workloads/provenance`, cited by `workloads/legacy/*/evidence.md`)

**Producer.** The `mk/workload.mk` provenance targets: `workload-provenance`/`*-fetch` (the postgres/prometheus targets were removed in `0f6b731`; redis/nginx are still produced, which is why those files have 2026-07-23 mtimes), `workload-dmtcp-provenance`, `workload-sandboxfs-build`, and `workload-spindle-provenance`. Every `archive_sha256` equals `expected_archive_sha256`. All archive hashes and commits equal the pins in `configs/benchmarks/workload-sources.mk`. The license, configure, sample-config, and go.sum hashes below appear only in these JSON files and nowhere else in the tracked tree, so this list preserves them.

**Source provenance** (schema `namei_ext.workload_source.v1`):

| Project | Version / commit | URL | Archive sha256 | Other recorded hashes |
|---|---|---|---|---|
| redis (w1-redis-build, w3-redis-podman-criu, w4-ccache-redis-nginx) | 7.2.14 / f2262eccb855eadd1afb0c457ea583ef9d5400b5 | https://github.com/redis/redis/archive/refs/tags/7.2.14.tar.gz | 704bfac84ab1c0771ddc08c8bea72e2203e3ce64c1fc6750e76b8ce2c00f3145 | COPYING 97f0a15b7bbae580d2609dad2e11f1956ae167be296ab60f4691ab9c30ee9828; Makefile 9349fc753e82733517e6839ac84df07e0f28bf68256119538ba18e1e0781f2ca; src/Makefile 64cba1862b07d90d439f111ac18bfb001e8949612e938bdefc23cd57382cc167 |
| nginx (w1-nginx-build, w2-nginx-fixture, w3-nginx-podman-criu, w4-ccache-redis-nginx) | 1.26.3 | https://nginx.org/download/nginx-1.26.3.tar.gz | 69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa | LICENSE f19c4caea60247490199c5a6d0134281e3fb20b3d7577e6873c628597f5381d9; configure df485655b589ead56ed03f38792445c060bdf3cb4026486b434a2a912cbb65e5; conf/nginx.conf 95363d79620c1b3eb6951711b6630a411f147bc9197bc91442c0605cf6688e46 |
| postgresql (w2-postgres-secret-fixture) | 16.6 | https://ftp.postgresql.org/pub/source/v16.6/postgresql-16.6.tar.gz | 520d173632e93507f26eb66713d953b687cfba5e72c467d3adbc8ec4dbb8148f | COPYRIGHT 9bf20ee493926a7e17a74bc7f05089fbc014269667b1540bc35a6b194a40c9de; configure 71962376d95a1f3f3f70d0f53e25c8c78a107c298670c3af30cd58c65bf80dca; postgresql.conf.sample 263421e9f1d37ce2be6cc86efd404764c23d85d85c3312e86e660b26d83a0ea6 |
| prometheus (w4-buildkit-prometheus-go-cache) | v2.55.1 / 6d7569113f1ca814f1e149f74176656540043b8d | https://github.com/prometheus/prometheus/archive/refs/tags/v2.55.1.tar.gz | f48251f5c89eea6d3b43814499d558bacc4829265419ee69be49c5af98f79573 | LICENSE c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4; go.mod 9f4ce6feb314691b5570d0ce21dbbf91e40c47f82dd5e965c091e184ab0ad3d4; go.sum 0686d2e7b0db939fb52c606ba56c87e2918ec229883e580a4bd866529f6ef4d3; cache mounts `/go/pkg/mod`, `/root/.cache/go-build` |

**Build provenance** (`provenance/build/`):

- **dmtcp-068559d9b14c** (schema v1, written 2026-07-28):
  - source: https://github.com/dmtcp/dmtcp/archive/068559d9b14c5f96a57869753bba7c066cbf9653.tar.gz, archive sha256 e2f15525073fc631efd994640ef645461f2c910843da60f9e8929d593ed49c7e, LGPL-3.0-or-later (COPYING f9de575a82f84070ce62a0bc558d590c14dbdb65d196c81e3a9b683a1794af1d)
  - patch `thirdparty/patches/dmtcp/restart-env-scan-count.patch` 7c945ba6f4bfc375b3c83f5714ed9546660a164a4c9e235999f1e9e55ca3c127, "fix dmtcp_get_restart_env flattened-environment scan bound"
  - pinned files: `src/dmtcpplugin.cpp` 86ddff5d38fe…, `src/plugin_pathtranslator.cpp` d03a89f00a12…, `test/pathvirt1.c` ffce8c1c7686…, `test/autotest.py` be303d3d34c1…
  - build: `./configure --prefix=…/install`, make -j4, gcc/g++ 13.3.0, GNU Make 4.3
  - install: 23 files (`install-tree.sha256` manifest sha 73ef79905db3…). Artifact hashes: `dmtcp_launch` fe777949e9e2…, `dmtcp_coordinator` 90fa2e5e31d4…, `dmtcp_command` f89a57846317…, `dmtcp_restart` 143f626e7a55…, `libdmtcp.so` f0e4c97ada18…
- **sandboxfs-2305d34fe764** (schema v2, written 2026-08-08):
  - version 0.2.0, commit 2305d34fe764a64cf4783b43315e6eb5322310d6, from codeload.github.com/bazelbuild/sandboxfs
  - Cargo.lock: `thirdparty/locks/sandboxfs-0.2.0.Cargo.lock`
  - build: `cargo build --release --locked` with cargo/rustc 1.90.0 and libfuse 2.9.9 (`ldd`: libfuse.so.2, libgcc_s, libc)
  - No archive sha256 is recorded here, and none is pinned in `workload-sources.mk`.
  - The stored `build.log` contains 0 `Compiling` lines and ends `Finished … in 0.04s`, so it records a no-op rebuild, not the original compile.
- **spindle-8853636d2d77** (schema v1, written 2026-07-29 to 2026-08-02):
  - commit 8853636d2d774729a5a728f5cf6c296b65a1099c, from codeload.github.com/LLNL/Spindle, LGPL-2.1-or-later
  - build options: security none, serial resource manager, cachepath `/tmp/namei-ext-spindle-cache`, commpath `/tmp/namei-ext-spindle-comm`
  - install: 27 files (`install-tree.sha256`, 27 lines). No archive sha256 is recorded.

### Doc vs raw mismatches

1. **sandboxfs build provenance.** `docs/tmp/2026-07-28-build-action-rq2-infrastructure-implementation.md:69-74` says the target validates the archive SHA-256 and records "the archive, lock, build log, runtime linkage, binary hash, and toolchain" in `results/workloads/provenance/build/`. The raw `provenance/build/sandboxfs-2305d34fe764/build.json` does not match that description:
   - it has schema v2 and was rewritten on 2026-08-08, after commit `6700791` removed `SANDBOXFS_ARCHIVE_SHA256`
   - it records neither an archive sha256 nor a binary sha256
   - its `build.log` is a no-op rebuild (0 `Compiling` lines)
   - the binary sha `aeeb0a295b2a…` and the Cargo.lock sha `ac39cf081c6e…` quoted in `docs/tmp/2026-07-28-sandboxfs-0.2.0-protocol-audit.md` appear nowhere in this slice

   The toolchain facts that the docs state (rustc and cargo 1.90.0, libfuse 2.9.9, links `libfuse.so.2`) do match.
2. **Unlabeled rates, not a mismatch.** `docs/tmp/2026-06-15-w1-release-binary-replay-gap-analysis.md:71-72` quotes hit rates 0.004609526462666237 and 0.0031378162513058003 without naming a run. Those are the `20260614T-workloads-git-ceiling` values. The canonical run in the evidence docs, `parent-key-poc`, has 0.004647141379397619 and 0.00313836644630933.
3. **Not re-verified.** The Spindle implementation doc's "exactly 47 focal mappings" was not re-derived. The 66 total matches.

No other disagreements were found. Every other workload-side number stated in a tracked doc matches the raw data.

### Keep-list (`p4-workloads-keep.tsv`)

The keep-list has 47 files, 136,080 bytes in total. Each is at most 10 KB and each is the raw source of a number or provenance fact stated in `workloads/legacy/*/evidence.md` or `docs/tmp`:

- the 4 source-provenance JSONs
- the sandboxfs `build.json` and `ldd.txt`
- the DMTCP `build.json` and install manifest. The pathvirt-contract-v4 copies are byte-identical, so only one copy is listed.
- git-ceiling: the W1 `manifest.json` and `alias-manifest.json`, the W2/W3/W4 manifests, and the 4 TSVs
- parent-key-poc: the W1 `manifest.json` and `alias-manifest.json`
- gatefix: the W4 ccache manifest and its TSV
- the w2-nginx-probes-phase1 output-oracle JSONL
- the W3 capability JSONL and `podman-version.stdout`
- W5 preflight v4: observations, application observations, lower-before/after, `run.json`, and 4 checksum manifests
- W5 source runs df8ae7d4 and attempt5: observations, application observations, lower-before/after

Three doc-stated facts live only in log files and were excluded under the no-logs rule. Each is quoted in this section above instead:

- the upstream autotest line `test groups: pass=1 fail=0 skipped=0 total=1`, in `upstream-autotest.stdout.log`
- Spindle's 66 `spindlens-file` mappings, in the 2.79 MB `spindle_output.lab.654791` debug log
- the empty attempt-5 `dmtcp-launch.stderr.log`

### Notable findings

1. **Tracked numbers agree with the raw data.** Every workload-side number that a tracked doc states was checked and matches: W1 trace lines, hits, and hit rates for git-ceiling and parent-key-poc; output-oracle binary hashes; the W3 capability fields; Spindle's 66 mappings; and W5 lifecycle timings for preflight v4 and source runs df8ae7d4 and attempt5. No disagreement was found.
2. **No paper citations.** The current paper cites no `results/workloads` path. The paper's earlier binding to `20260615T-parent-key-poc` was removed in `762741e`. `docs/evaluation.md` cites only the KVM-side twins of five group-H runs.
3. **Raw strace logs are 92% of the slice** (12.66 GiB). Their content is summarized by the line counts and per-candidate hit counts above. The DMTCP source trees, install copies, and checkpoint images (about 1.2 GB) are payload.
4. **Failures.** The two failures are the expected W3 Podman/CRIU audit (CRIU absent) and Spindle run `5a1ce001` (no debug log captured). The six service-config-rotation workload builds succeeded, but their consuming KVM preflights all failed (`kvm-launch-or-guest-command`). Those `build.json` files are duplicated byte-for-byte in the experiment roots.
5. **Workload-side effects visible only in this data:**
   - the `GIT_CEILING_DIRECTORIES` change cut the Redis trace from about 1.636M to about 1.235M `%file` lines
   - the early shared-tree run w1b was incremental (Redis build 1.2 s, 548k lines)
   - build binaries are not reproducible across runs (the path is embedded)
   - builds from 2026-06-29 on are about 35–45% slower with identical toolchain and configuration
