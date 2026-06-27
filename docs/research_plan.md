# namei_ext 研究计划

## 摘要

`namei_ext` 探索一个类似 `sched_ext` 的 VFS path-resolution 扩展点。目标不是实现
新的文件系统，而是让内核继续拥有 path walk、dentry、inode、permission check、
mount traversal 和 lower-filesystem operations，同时让 eBPF 程序在 lookup 和
directory enumeration 时决定一个窄语义的 path-resolution policy。

## 当前状态

截至 2026-06-18，长期 research state 需要按 scoped paper verdict 读取：当前论文可站住的正结果是 W2 nginx sandbox fixture 的 setup/materialization slice、tool-redirect lookup/access/open/exec metadata latency slice，以及 W1-W4 Phase 1 lookup/readdir oracle matrix。全局 C2、full metadata C3、C8 table-only insufficiency 和 full C7 reproducibility 都没有通过。

Sandbox/fixture 当前最强：W2 nginx fixture 已通过 real trace/no-production-open gate，且在 copy/symlink/bind/projected-volume/FUSE baselines 下通过 storage、setup、update 和 materialization thresholds。它可以作为局部主结果，但还不能代表 W1/W3/W4，也不能证明 C8。

Checkpoint/restore 当前最弱：W3 Redis 有 Redis RDB load/replay witness、materialized checkpoint-view baseline 和 FUSE checkpoint-view baseline，但这不是 Podman/CRIU restore。W3 setup/update threshold ledger 为负；真实 restore 还需要先通过 Podman/CRIU capability gate，再补 post-restore VFS trace、restore health、0 mixed epoch 和 table/update budget counterfactual。

若下一轮改成更强 OSDI 叙事，顶层 use case 不应继续按 W1/W2/W3/W4 四条线并列，而应收敛为三个：agent sandbox lifecycle、service fixture sandbox 和 content-verified cache view。agent sandbox lifecycle 可以包含 fork/fanout、checkpoint rollback/restore、workspace materialization/update 和 deterministic trace replay；不包含 eval isolation。W1 build graph 更适合折叠为 agent sandbox trace replay 来源；当前 W3 Redis replay 不是主线 restore，除非重做成真实 sandbox checkpoint/rollback 或 Podman/CRIU restore workflow。

新的解释记录见 `docs/tmp/2026-06-18-fuse-baseline-and-native-overhead-interpretation.md`；本次 sandbox/checkpoint benchmark 计划同步见 `docs/tmp/2026-06-18-sandbox-checkpoint-benchmark-plan.md`。

截至 2026-06-16，Phase 1 已经完成以下工程里程碑：

- 四个主线 policy family 已落到真实 eBPF 程序：
  `build_graph_view.bpf.c`、`sandbox_fixture_view.bpf.c`、
  `checkpoint_restore_view.bpf.c` 和 `cache_locality_view.bpf.c`。
- 辅助基线 `pass_only.bpf.c`、`redirect_alias.bpf.c` 和
  `table_redirect.bpf.c` 已进入同一个 BPF build。
- `make kvm-policy-load` 已在修改后的内核 KVM guest 内逐个 load/attach/detach
  所有 policy object，raw evidence 位于
  `results/phase1/20260614T044641Z-4b962c22/policy-load.jsonl`。
- `make kvm-policy-semantic` 已在修改后的内核 KVM guest 内验证四个主线 family 的
  POC lookup/readdir 语义、negative pass-through 和 detach 行为，raw evidence 位于
  `results/phase1/20260614T045249Z-156c3470/policy-semantic.jsonl`。
- `make kvm-w1-oracle RUN_ID=20260615T-parent-key-poc` 已在修改后的内核
  KVM guest 内把 W1 Redis/nginx trace-derived entries 分别 materialize 到独立
  synthetic 临时目录，并用
  `build_graph_view.bpf.c` 和 `table_redirect.bpf.c` 跑同一组 lookup/readdir
  path oracle。9 个 entries、2 个 policy、0 failure，raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w1-oracle.jsonl`。该 gate 是
  `kvm_policy_path_oracle`，仍显式标记 `qualified_for_c8=false`，因为它还不是完整
  build output hash oracle，也没有 table/update budget counterfactual。
- `make phase1-smoke`、`make kvm-functional` 和 `make kvm-bench` 已通过现有
  Phase 1 smoke/functional/microbenchmark 回归。
- `make phase1 RUN_ID=20260614T-w2-nginx-probes-phase1 SAMPLES=1 BENCH_ITERS=2000`
  已通过，并生成包含 policy-load、policy-semantic、table-conformance、W1/W2
  path oracle、W2 nginx real endpoint health + fixture content probes oracle、W3 checkpoint path oracle、W4 cache path
  oracle、W4 cache content oracle、functional、bench 和 Docker gates 的 summary：
  `results/phase1/20260614T-w2-nginx-probes-phase1/summary.md`。其中
  `make kvm-w2-nginx-real` 在同一修改内核 KVM guest 中把真实 nginx `1.26.3` binary 的
  `nginx -t` config parser、worker 启动、redirected endpoint HTTP health check 和 worker
  quit 接到 `sandbox_fixture_view.bpf.c` 的 `nginx.conf -> nginx.test.conf` 与
  `upstream.sock -> upstream.local` aliases 上；同一 attach window 内还用普通 VFS
  `open/read` 执行 `nginx.conf`、`upstream.sock`、`server.crt`、`db.password` 和
  `prod.token` 的 fixture content probes，raw evidence 位于
  `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl`。
- `make phase1 RUN_ID=20260615T-full-phase1-bench-variants` 已通过，并生成历史
  完整 Phase 1 result root：
  `results/phase1/20260615T-full-phase1-bench-variants/summary.md`。该 root 把
  W1 release replay/branch probes、W2 nginx real、W3 Redis checkpoint replay、
  W4 real ccache trace/policy bridge/policy-attached compile、W4 parent-scoped compile、
  W4 table-only compile comparator、W4 release counterfactual accounting、functional、
  Docker、dmesg 和新 microbenchmark variant hard gates 纳入同一份 `summary.md`。
  该 run 中 `bench.jsonl` 含 35 个 bench row、0 failing ops、5 个 variant：
  `baseline`、`pass_only`、`table_redirect_empty`、`table_redirect_hit` 和 `policy`；
  `table_redirect_hit` 在 KVM guest 内成功写入 66 条 `exact_redirects` map rule，
  4 个真实 policy attach 均成功。`qualified_for_c8=true` 的 row 仍为 0，不能支撑
  C1/C8 或 OSDI 发布级性能结论。
- `make kvm-w3-redis-counterfactual
  RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1` 已补上 W3 Redis checkpoint
  replay 的 same-workload table-only comparator，并在修改后的 kernel KVM 中通过。
  该 target 依次运行 `checkpoint_restore_view.bpf.c` Redis replay、
  `table_redirect.bpf.c` Redis replay 和 counterfactual accounting。raw evidence 位于
  `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/`。结果显示
  checkpoint policy replay 和 table-only replay 均为 0 failure；
  table-only 只写入两条 exact redirect rule，`table_baseline_current_oracle_pass=true`、
  `table_rule_writes=2`、`table_budget_failure=false`、
  `zero_mixed_epoch_checker=false`、`restore_trace_checker=false`、
  `qualified_for_c8=false`。这是 W3/C8 的负证据：当前 Redis RDB replay 仍可被
  table-only exact redirect 解释，不能证明 checkpoint/restore family 需要 eBPF
  可编程逻辑。实现记录：
  `docs/tmp/2026-06-15-w3-table-replay-counterfactual-implementation.md`。
- `make workload-w3-podman-criu-capability
  RUN_ID=20260615T-w3-podman-criu-capability-audit-v1` 新增 W3 real restore 的
  host capability audit。该 target 是 Make-owned，写出 Podman/CRIU stdout/stderr
  和 `capability.jsonl` 后 fail-fast。当前 host audit 结果为
  `podman_present=true`、`podman_version_ok=true`、
  `podman_checkpoint_help_ok=true`，但 `podman_checkpoint_listed=false`、
  `criu_present=false`、`criu_version_ok=false`、`pass=false`。raw evidence 位于
  `results/workloads/runs/20260615T-w3-podman-criu-capability-audit-v1/w3-podman-criu-capability/`。
  这不是 Phase 1 C8 支持；它把 W3 real Podman/CRIU restore 的环境 blocker
  机械化记录下来。实现记录：
  `docs/tmp/2026-06-15-w3-podman-criu-capability-audit-implementation.md`。
- `make eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-contract-bench-variants
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants` 已通过，生成
  `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b12-policy-family/policy-family.jsonl`、
  `policy-family-inputs.sha256`、`summary.md` 和
  `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/manifest.json`。
  该 ledger 把 C1/C8 的 B12 policy-family release contract 机械化：四类 family 当前都有
  `semantic_witness_pass=true`，但 `release_metric_pass=false`、
  `table_counterfactual_support=false`、`qualifying_workload_rows=0`，
  summary 为 `qualified_families=0`、`release_gate_pass=false`。随后
  `make eval-osdi-policy-family RUN_ID=20260615T-eval-contract-bench-variants-hardgate
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants` 按预期失败，防止当前
  Phase 1 功能证据被误写成 C1/C8 发布级证据。
- `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-contract-bench-variants
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants` 已通过，生成
  `results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b2-performance/performance.jsonl`、
  `performance-inputs.sha256`、`manifest.json` 和 `summary.md`。该 ledger 把当前
  KVM `bench.jsonl` 标记为 `phase1_kvm_microbench_smoke`：`samples=1`、
  `variants_observed=["baseline","pass_only","policy","table_redirect_empty","table_redirect_hit"]`、
  `failing_ops=0`，并确认 `has_pass_only_baseline=true`、
  `has_table_redirect_empty_baseline=true`、`has_table_redirect_hit_baseline=true`。
  但它仍记录 `has_latency_raw_rows=false`、`has_tail_latency_artifact=false`、
  `has_confidence_interval=false`、`has_randomized_order=false`、
  `has_system_metrics=false`，并列出缺失的
  FUSE、copy-tree、symlink-forest、bind mount 和 OverlayFS release baselines。随后
  `make eval-osdi-performance RUN_ID=20260615T-eval-contract-bench-variants-hardgate
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants` 按预期失败，防止
  Phase 1 aggregate timing 被误写成 C2/C3/C5 的 OSDI 性能证据。
- 已新增默认关闭的 KVM microbenchmark latency sampling plumbing：
  `BENCH_LATENCY_SAMPLES` 和 `BENCH_LATENCY_BATCH` 进入
  `configs/benchmarks/phase1.mk`，`kvm-bench` 会显式把 `SAMPLES`、`BENCH_ITERS`
  和 latency knobs 传入 guest make，runner 在真实 KVM attach 路径下追加
  `event=bench_latency` raw rows。pilot run
  `make kvm-bench RUN_ID=20260615T-kvm-bench-latency-pilot SAMPLES=1 BENCH_ITERS=200
  BENCH_LATENCY_SAMPLES=2 BENCH_LATENCY_BATCH=4` 已通过，产生 35 个 aggregate row、
  70 个 latency row、0 failing ops、4 个 attach success 和 66 条
  `table_redirect_hit` map update。实现记录：
  `docs/tmp/2026-06-15-kvm-bench-latency-sampling.md`。该 pilot 只是
  `kvm-bench` 子集，没有完整 `metadata.json`，因此不能作为 B2/B8 ledger root；
  该旧 full root 仍是 `20260615T-full-phase1-bench-variants`，其
  `has_latency_raw_rows=false`、`has_tail_latency_artifact=false` 结论保持不变。
- 已新增 `make eval-osdi-performance-tail`，从 KVM `bench_latency` raw rows 生成
  per `(bench,variant)` 的 p50/p95/p99、mean、stdev 和 95% CI JSONL artifact。
  pilot target
  `make eval-osdi-performance-tail RUN_ID=20260615T-tail-artifact-pilot
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-kvm-bench-latency-pilot` 已通过，生成
  `results/eval-osdi/paper/20260615T-tail-artifact-pilot/b2-performance/bench-latency-tail.jsonl`，
  summary 为 rows=70、groups=35、`has_tail_latency_artifact=true`、
  pilot-scale `has_confidence_interval=true`、`has_release_sample_budget=false`。新的 canonical
  ledger
  `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-tail-artifact
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants` 仍记录
  `has_tail_latency_artifact=false`、`release_gate_pass=false`，因为完整 Phase 1 root
  没有采集 `bench_latency` rows。实现记录：
  `docs/tmp/2026-06-15-eval-osdi-tail-latency-artifact.md`。
- 已新增 `make eval-osdi-baselines`，在修改内核 KVM guest 中运行外部 filesystem
  baseline smoke：copy tree、symlink forest、bind mount 和 OverlayFS。runner 位于
  `bench/workloads/namei_ext_baselines.c`，只写 raw JSONL；Make target 负责 KVM 启动、
  tmpfs scratch root、dmesg、input sha256、ledger、manifest 和 summary。validated run
  `20260615T-kvm-external-baselines-content-v1` 生成
  `results/eval-osdi/baselines/20260615T-kvm-external-baselines-content-v1/baseline-ledger.jsonl`，
  summary 为 4 个 baseline selected/pass、raw rows=78、bench rows=32、latency rows=32、
  每个 baseline 都有 `read_tool_content` update oracle、0 failure；FUSE redirect 仍缺。
  新的 performance ledger
  `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-content-baselines
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-content-v1`
  已把 copy/symlink/bind/OverlayFS 标记为存在，并把 `missing_release_baselines`
  缩小为 `["fuse_redirect"]`。该证据仍是 smoke-level；由于 canonical full root 没有
  `bench_latency` rows、release repetitions、随机化顺序和系统指标，B2/B8 release gate
  继续为 false。实现记录：
  `docs/tmp/2026-06-15-eval-osdi-external-baselines-implementation.md`。
- 已补齐 FUSE redirect external baseline。runner 现在包含项目内最小 libfuse
  path-remapping filesystem：`/tool` 和 `tree/include/pkgXX/tool` 由 FUSE daemon
  映射到 backing files，`readdir` 只暴露 visible alias，不暴露 `tool.real`；update
  后 `read_tool_content` 必须读到 `tool-updated\n`。Phase 1 kernel config 新增
  `CONFIG_FUSE_FS=y`，避免 KVM guest 在 `--skip-modules` 下依赖 `modprobe`。validated
  run：
  `make eval-osdi-baselines RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2
  BASELINE_SAMPLES=1 BASELINE_ITERS=50 BASELINE_LATENCY_SAMPLES=1
  BASELINE_LATENCY_BATCH=2`，生成
  `results/eval-osdi/baselines/20260615T-kvm-external-baselines-fuse-smoke-v2/baseline-ledger.jsonl`。
  summary 为 5 个 baseline selected/pass、raw rows=97、bench rows=40、latency rows=40、
  `has_fuse_redirect_baseline=true`、`missing_release_baselines=[]`、FUSE row
  `fuse_mounts=1`、0 failure、dmesg issue count 0。新的 performance ledger
  `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-ledger-fuse-baselines-smoke
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-bench-variants
  EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID=20260615T-kvm-external-baselines-fuse-smoke-v2`
  已清空 external baseline 缺口，但由于 canonical full root 仍没有 `bench_latency`
  rows、release repetitions、随机化顺序和系统指标，B2/B8 release gate 继续为 false。
  hard gate run `20260615T-eval-ledger-fuse-baselines-hardgate` 按预期失败，防止 smoke
  被误计入 C2/C3/C5。
- 已按 research lifecycle contract 新增 `research/` durable artifacts：
  `research/STATE.md`、`research/CLAIM_LEDGER.md`、`research/EXPERIMENT_PLAN.md`、
  `research/EXPERIMENT_TRACKER.md`、`research/RESULTS_SUMMARY.md`、
  `research/CLAIM_VERDICT.md` 和 `research/FOLLOWUP_PLAN.md`。这些文件把当前阶段明确为
  execute/gate loop，而不是 paper polish；`CLAIM_VERDICT.md` 明确 C1/C8 blocked、
  C2/C3/C5 unsupported、C4/C6/C7 partial。实现记录：
  `docs/tmp/2026-06-15-research-lifecycle-artifacts.md`。
- `mk/report.mk` 已把 microbenchmark variant set、每个 variant 的 row 数、
  `bench-start.policy_variants`、policy attach/detach 和 `table_redirect_hit`
  map update 写入完整 Phase 1 report hard gate。旧 full root
  `20260615T-full-phase1-gatefix` 因缺少新 variants 不能再作为当前 canonical
  Phase 1 closure。实现记录：
  `docs/tmp/2026-06-15-phase1-bench-variant-report-gate.md` 和
  `docs/tmp/2026-06-15-full-phase1-bench-variants-run.md`。
- `make workload-provenance` 已获取固定真实 source inputs 并写入 provenance：
  Redis `7.2.14`、nginx `1.26.3`、PostgreSQL `16.6` 和 Prometheus `v2.55.1`。
  对应结果位于 `results/workloads/provenance/`。archive SHA256 已进入
  `configs/eval-osdi/workload-sources.mk` 并在每次解压前 fail-fast 校验。
- `make workload-build-graph RUN_ID=20260615T-parent-key-poc` 已从干净
  源码树构建并 strace 两个真实 W1 build-graph workload：Redis `7.2.14` 和
  nginx `1.26.3`。raw logs、trace、source-build manifests 和 trace-witness
  manifests 位于
  `results/workloads/runs/20260615T-parent-key-poc/`。这些 manifests
  明确标记 `run_environment=host`、`policy_executed=false`、`kvm_validated=false`
  和 `output_hash_oracle=false`。Redis 构建 recipe 还设置
  `GIT_CEILING_DIRECTORIES`，避免 Redis release-header 生成过程向上扫描父项目
  git repository 并污染文件访问 trace。
- `make workload-w1-build-output-oracle RUN_ID=20260615T-parent-key-poc`
  已把 W1 Redis/nginx 真实 host 构建输出变成独立 raw oracle：
  `results/workloads/runs/20260615T-parent-key-poc/w1-build-output-oracle.jsonl`。
  该 artifact 校验 build 和 trace 两次真实构建产出的 binary 路径与 SHA256，记录
  duration、trace file-op lines 和 source manifest hash，并写入 2 条 workload row
  加 1 条 summary；字段为 `result_level=host_real_build_output_oracle`、
  `output_hash_oracle=false`、`host_output_hash_oracle=true`、
  `release_output_hash_oracle=false`、`output_hash_oracle_scope=host`、
  `policy_executed=false`、`kvm_validated=false` 和 `qualified_for_c8=false`。随后
  `make kvm-w1-oracle RUN_ID=20260615T-parent-key-poc` 已把该 JSONL 纳入
  `w1-oracle-inputs.sha256`，使 KVM W1 path oracle 的输入完整性链包含真实构建输出证据。
- `make kvm-w1-build-replay RUN_ID=20260615T-parent-key-poc`
  已在修改后的内核 KVM guest 内运行 W1 policy build replay witness。该 target
  复制真实 Redis/nginx source tree 到 guest 临时目录，先在未 attach policy 时生成
  baseline preprocessed output，再 materialize trace-derived shadow aliases，load/attach
  `build_graph_view.bpf.c`，随后通过同一路径运行 Redis `src/server.c` 和 nginx
  `src/core/nginx.c` 的 policy preprocessing，并与 baseline byte-for-byte 比较。
  raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w1-build-replay.jsonl`；
  output hash 位于 `w1-build-replay-outputs.sha256`，Redis baseline/policy
  都是 `c4fc64fce52917575d2e4c7d0735a45685f54be29f68303a730f69bfeb588422`，
  nginx baseline/policy 都是
  `dbb253e0d661fce0dabbd9b0ad2c42e349ed99277dc6f9168974a589e3048c5e`。该结果的
  `result_level=kvm_policy_build_replay_witness`、
  `output_hash_oracle_scope=kvm_policy_preprocess`、
  `policy_replay_output_hash_oracle=true`，但
  `release_output_hash_oracle=false`、`output_hash_oracle=false` 和
  `qualified_for_c8=false`。它证明 policy attach path 能影响真实源码 preprocessing，
  但不是完整 `make redis-server` 或 nginx release binary replay。
- `make kvm-w1-build-macrobench
  RUN_ID=20260616T-w1-build-macrobench-smoke-v3 W1_BUILD_MACROBENCH_SAMPLES=1`
  已在修改后的内核 KVM guest 内运行 W1 build graph proposed-system setup/update
  macrobench PoC。该 target 复用真实 Redis/nginx trace source、9 个 trace-derived
  W1 entries 和 `build_graph_view.bpf.c` attach path，写出
  `results/phase1/20260616T-w1-build-macrobench-smoke-v3/w1-build-macrobench.jsonl`
  与 `w1-build-macrobench-inputs.sha256`。summary 为 `samples=1`、
  `setup_rows=1`、`update_rows=1`、`correctness_rows=1`、`pass=true`、
  `failures=0`、`policy_executed=true`、`kvm_validated=true`、
  `c2_supported=false`、`release_gate_pass=false`。setup row 记录
  `setup_ns=57973895`、`entries=9`、`created_files=10`、`created_symlinks=2`；
  update row 记录 `update_ns=66338828` 和 `update_bytes_copied=412795`。
  第一次 smoke
  `20260616T-w1-build-macrobench-smoke-v1` 保留失败证据：Redis preprocessing
  output compare 失败是因为 runner 把 baseline/policy 放在两个临时 source tree 中，
  Redis 预处理输出包含不同的绝对源文件路径；v3 已改为同一 source tree 上先 baseline、
  再 materialize aliases、再 attach policy replay。实现记录为
  `docs/tmp/2026-06-16-w1-build-macrobench-implementation.md`。该 PoC 只证明
  W1 macrobench plumbing，不是 W1 release comparison。
- `make kvm-w1-build-macrobench
  RUN_ID=20260616T-w1-build-macrobench-release-sample-v1
  W1_BUILD_MACROBENCH_SAMPLES=20` 随后把 W1 proposed-system 侧推进到
  20-sample KVM release input。raw evidence 位于
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench.jsonl`，
  input hash manifest 位于
  `results/phase1/20260616T-w1-build-macrobench-release-sample-v1/w1-build-macrobench-inputs.sha256`。
  summary 为 `samples=20`、`setup_rows=20`、`update_rows=20`、
  `correctness_rows=20`、`pass=true`、`failures=0`、`policy_executed=true`、
  `kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`；
  host 侧 `sha256sum -c` 通过。该 run 的 setup 平均约 `66.09 ms`，source copy
  平均约 `20.84 s`，update 平均约 `52.42 ms`。运行记录为
  `docs/tmp/2026-06-16-w1-build-release-repetition-run.md`。该 evidence 只证明
  W1 proposed-system release repetition input；后续已补 W1 copy/symlink/bind
  baseline release input 和 W1 release ledger，但该 ledger 为负，W1 仍缺
  projected/FUSE、storage/threshold 支持和 W3/W4 对等宏基准。
- 当前 W1 trace-witness manifests 证明一组手工选择的候选 entries 能被真实
  trace 命中，并覆盖 build-graph family 的 generated/source/toolchain/external-dep
  分支。Redis 有 4 个候选 entries、5,692 个候选 trace hits、
  `candidate_witness_hit_rate=0.004647141379397619`；nginx 有 5 个候选 entries、
  5,638 个候选 trace hits、`candidate_witness_hit_rate=0.00313836644630933`。
  alias manifests 还包含 `release_gate_eligible=false` 和
  `policy_execution_basis=host_trace_only`。这些 host manifests 本身不能计入 C1/C8；
  后续 KVM W1 path oracle、KVM policy preprocessing replay witness 和 KVM policy
  release-binary replay witness 已证明这些 entries 可沿真实 attach path 执行、影响真实
  源码 preprocessing，并在规范化 debug/build-id 元数据后保持 Redis/nginx release
  binary hash 一致；后续 W1 KVM branch probes 还在真实 Redis/nginx source parent
  directory 副本中验证了 `private.h -> poison.dep` 和 `missing.h -> PASS/ENOENT`
  分支语义。但这些 branch probes 仍不是 release build trace 中自然触发的 workload
  hit；完整 trace-derived alias set、release-level operation-weighted redirected hit
  rate 和 C8 table/update budget 仍未完成。
- `docs/tmp/2026-06-15-w1-release-binary-replay-gap-analysis.md` 已把 W1
  release binary replay 缺口单独记录为 Phase 1 调研 artifact。该分析识别出的
  主要 blocker 是：当时 `struct namei_ext_component_key` 仍只按
  `(event, cgroup_id, component name)` 建 key，不能区分同名 component 的
  parent/path context；alias manifests 也是 `release_gate_eligible=false` 的候选
  witness，不是完整 trace-derived alias set。后续 parent-aware ABI PoC 已解决
  component-only key 的第一层 blocker。后续
  `docs/tmp/2026-06-15-w1-release-binary-replay-implementation.md` 已补上
  KVM release-binary witness；`docs/tmp/2026-06-15-w1-branch-probes-implementation.md`
  又补上 KVM poison/negative branch probes。release-level 自然 workload hit、完整
  trace-derived alias set、operation-weighted hit rate 和 table/update budget
  counterfactual 仍未补齐，因此 W1 仍不能计入 C1/C8 主结论。
- `docs/tmp/2026-06-15-parent-aware-namei-abi-survey.md` 和
  `docs/tmp/2026-06-15-parent-aware-namei-abi-implementation.md` 已把 parent-aware
  ABI 的调研、实现和验证独立记录。当前 kernel ctx 以 append-only 方式暴露
  `parent_dev`、`parent_ino`、`parent_generation` 和 `parent_flags`；verifier 只允许
  BPF 读取这些字段；map-backed policy key 使用 `(event, cgroup_id, parent_dev,
  parent_ino, component name)`。`parent_generation` 暂不进入 map key，因为用户态
  `stat()` 无法可移植地填充 inode generation。`make phase1
  RUN_ID=20260615T-full-phase1-bench-variants` 已在修改后的 kernel/KVM 路径下通过当前
  canonical 完整 Phase 1 gate，summary 位于
  `results/phase1/20260615T-full-phase1-bench-variants/summary.md`：policy load/semantic、
  table conformance、W1/W2/W3/W4 oracle、W1 preprocessing replay、W1 release
  binary replay、W1 branch probes、W2 nginx real、W3 Redis checkpoint replay、
  W4 cache content、W4 real
  ccache transition、W4 real ccache cache-path trace、W4 trace-derived ccache
  policy bridge、W4 real ccache policy-attached compile、W4 parent-scoped ccache
  compile、W4 table-only ccache compile comparator、W4 release counterfactual accounting、
  functional、bench variants、Docker
  和 dmesg gate 均为 0 failure；
  `table-budget C8-qualified rows` 仍为 0。该 PoC 解除 component-only key 的
  parent collision blocker。
- `make kvm-w1-release-build-replay RUN_ID=20260615T-parent-key-poc` 已在修改后的
  kernel KVM guest 内完成 W1 release-binary replay witness，并已纳入同一
  `make report` 硬校验。该 target 复制 Redis/nginx trace source 为 baseline/policy
  两套源码树，baseline 在未 attach policy 时 rebuild，policy 树在 attach
  `build_graph_view.bpf.c` 后 rebuild；保存的可执行 ELF 先移除 debug section 和
  `.note.gnu.build-id`，避免临时源码路径和链接器 build-id 污染 output hash。最终
  Redis baseline/policy hash 都是
  `65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b`，nginx
  baseline/policy hash 都是
  `f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544`；
  `w1-release-build-replay-summary` 为 0 failure，`policy_executed=true`、
  `kvm_validated=true`、`release_binary_hash_match=true`，但
  `qualified_for_c8=false`。该 witness 证明 W1 policy attach path 可支撑真实
  Redis/nginx release rebuild 的 output equivalence；它仍不是 C8，因为完整
  trace-derived alias set、release-level poison/negative natural workload hits、
  operation-weighted hit rate 和 table/update budget counterfactual 仍未完成。
- `make kvm-w1-branch-probes RUN_ID=20260615T-parent-key-poc` 已在修改后的 kernel
  KVM guest 内补上 W1 build-graph poison/negative branch probes。该 target 复制
  Redis/nginx trace source 到 guest 临时目录，在 Redis `src/` 和 nginx `src/core/`
  parent directories 中写入 `poison.dep`，并验证 attach 前 `private.h`/`missing.h`
  不可达、attach 后 `private.h` lookup 解析到 poison sentinel、readdir 显示
  `private.h` 且隐藏 `poison.dep`、`missing.h` 仍为 `ENOENT` 且不出现在 readdir，
  detach 后 aliases 再次不可达。`w1-branch-probe-summary` 为 0 failure，
  `policy_executed=true`、`kvm_validated=true`、`qualified_for_c8=false`。该 gate
  还记录 host trace candidate hit rate
  `11330/3021315=0.0037500227549924453`，并显式标记
  `operation_weighted_hit_rate_is_release=false`。它证明 branch semantics 可沿真实
  KVM attach path 执行，但仍不是 release-level natural workload hit 或 C8 evidence。
- 当前 W2 fixture-witness manifests 证明 nginx workload fixture config、PostgreSQL
  upstream sample config、Makefile-owned fake cert、local endpoint、poison sentinel 和 fake password fixture
  可以生成 6 个 sandbox-fixture entries。`make kvm-w2-oracle` 已在 KVM guest 中用
  `sandbox_fixture_view.bpf.c` 和 `table_redirect.bpf.c` 通过同一组 lookup/readdir path
  oracle。`make kvm-w2-nginx-real` 进一步用真实 nginx binary 和 workload fixture
  config 验证：attach 前 `conf/nginx.conf` 缺失导致 `nginx -t` 失败；attach 后
  同一路径经 `sandbox_fixture_view.bpf.c` 重定向到 `nginx.test.conf` 并被 nginx
  config parser 接受；fixture config 中的 `include upstream.sock` 又经同一 policy
  重定向到 `upstream.local`，使 nginx 把 HTTP GET 代理到 runner 启动的
  `127.0.0.1:18080` local upstream。raw result 中 `attached_endpoint_upstream=true`，
  证明 endpoint alias 被真实服务请求路径消费；随后 worker 在 policy 仍 attached 时通过
  `nginx -s quit` 退出；detach 后同一配置测试再次失败。该 target 还在 policy
  attached 时执行五个 fixture content probes，证明 `nginx.conf`、`upstream.sock`、
  `server.crt`、`db.password` 和 `prod.token` 分别解析到 fixture/fake/poison backing，
  且不等于同目录 production-like decoy。该结果是
  `kvm_real_app_health_oracle` + `functional_only` content probes，仍不做
  trace-level no-real-secret/cert/poison open checker、release-level endpoint matrix、
  startup trace、operation-weighted hit rate 或 table/update budget failure。
- 当前 W3 checkpoint-witness manifests 证明 Redis/nginx provenance 绑定的
  checkpoint/restore witness entries 可以生成 7 个 entries。`make kvm-w3-oracle`
  已在 KVM guest 中用 `checkpoint_restore_view.bpf.c` 和 `table_redirect.bpf.c`
  通过同一组 lookup/readdir path oracle；它仍不运行真实 Podman/CRIU restore，
  不验证 restore health、post-restore VFS trace、state/config/cache hash 或
  0 mixed epoch oracle，也不证明 table/update budget failure。
- `make kvm-w3-redis-replay RUN_ID=20260615T-parent-key-poc` 已在修改后的 kernel
  KVM guest 内补上 Redis checkpoint replay witness。该 target 先用真实
  `redis-server` 生成包含 key `namei_ext:w3:checkpoint` 的 `dump.ckpt`，再证明
  attach 前可见名 `dump.rdb` 不会加载该 hidden checkpoint；随后 attach
  `checkpoint_restore_view.bpf.c`，让 Redis 通过可见 `dump.rdb` 读取到 backing
  `dump.ckpt`，`GET` 返回 `checkpoint_restore_policy_loaded`，且 readdir 只显示
  `dump.rdb`、隐藏 `dump.ckpt`；detach 后同一路径再次不加载 hidden checkpoint。
  raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w3-redis-replay.jsonl`，summary 为 0 failure，
  `redis_checkpoint_loaded_via_policy=true`、`post_restore_vfs_replay=true`、
  `podman_criu_restore_executed=false` 和 `qualified_for_c8=false`。它证明真实 Redis
  RDB load path 可观察到 checkpoint policy 决策，但仍不是 Podman/CRIU restore、
  restore health 或 0 mixed epoch C8 证据。
- `make kvm-w3-redis-counterfactual RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
  随后把同一个 Redis RDB replay 换成 `table_redirect.bpf.c` 运行，并生成
  `w3-redis-counterfactual.jsonl`。table replay 通过相同 Redis GET/readdir/detach
  oracle，且只需要 `dump.rdb -> dump.ckpt` lookup rule 和
  `dump.ckpt -> dump.rdb` readdir rule 两条 table update。counterfactual row 记录
  `policy_replay_pass=true`、`table_replay_pass=true`、
  `table_baseline_current_oracle_pass=true`、`table_rule_writes=2` 和
  `qualified_for_c8=false`。因此 W3 当前从“缺 same-workload table comparator”变为
  “same-workload table comparator 通过”的负证据；后续要支持 C8，必须引入真实
  Podman/CRIU restore、restore trace、zero mixed epoch/update/stale-window checker，
  或其它能让 table-only 在同等 budget 下失败的 release workload。
- 当前 W4 cache-witness manifests 证明 Redis/nginx/Prometheus provenance 绑定的
  cache-locality witness entries 可以生成 4 个 entries。`make kvm-w4-oracle`
  已在 KVM guest 中用 `cache_locality_view.bpf.c` 和 `table_redirect.bpf.c`
  通过同一组 lookup/readdir path oracle。`make kvm-w4-cache-content
  RUN_ID=20260614T-w4-cache-content-map` 进一步在同一修改内核 KVM guest 中读取
  `w4-cache-oracle-entries.tsv`，按 entry 的 `parent_relative` 构造 workdir，把
  manifest backing materialize 成 shadow component，填充 `cache_rules` map，并用
  `cache_locality_view.bpf.c` 验证 verified hit、stale fallback、corrupt reject 和
  miss canonical 四个分支：`object.o` 解析到 `object.local` 且不等于 `object.bad`，
  `stale.o` 解析到 `stale.canon` 且不等于 `stale.local`，`corrupt.o` 解析到
  `corrupt.reject` 且不等于 `corrupt.local`，`pkg.mod` 解析到 `pkg.canon`。raw result 位于
  `results/phase1/20260614T-w4-cache-content-map/w4-cache-content.jsonl`，其中
  `map_update=1`、summary 为 0 failure 并显式记录 `qualified_for_c8=false`。完整
  Phase 1 run 的对应结果位于
  `results/phase1/20260614T-w2-nginx-probes-phase1/w4-cache-content.jsonl`，
  summary 同样为 0 failure。该 cache-content gate 本身不包含真实 ccache 编译或
  BuildKit build，不验证 compiler/go output hash、cache transition trace、
  update writes 或 stale window，也不证明 table/update budget failure。
- `make kvm-w4-cache-table-content RUN_ID=20260615T-w4-cache-table-content-smoke-v1`
  已补上 W4 cache-content oracle 的 same-workload table-only comparator。该 target
  使用同一 `w4-cache-oracle-entries.tsv`、同一修改内核 KVM attach path 和同一内容
  oracle，只把 policy 换成 `table_redirect.bpf.c`。raw evidence 位于
  `results/phase1/20260615T-w4-cache-table-content-smoke-v1/w4-cache-table-content.jsonl`；
  summary 为 0 failure，并记录 `branches=4`、
  `table_baseline_current_oracle_pass=true`、
  `content_equivalent_table_oracle=true` 和 `qualified_for_c8=false`。逐 case 覆盖
  4 个 expected match、3 个 forbidden mismatch 和 4 个 readdir alias。因此 W4
  cache-content oracle 当前也是 C8 负证据：verified hit、stale fallback、corrupt
  reject 和 miss canonical 的 manifest-derived witness 仍可被 exact table 表达；后续
  仍需要真实 stale/corrupt transition、operation-weighted hit rate、BuildKit cache
  trace、update/stale window 或 table/update budget failure。
- `make kvm-w4-ccache-real RUN_ID=20260615T-parent-key-poc` 已在修改后的 kernel
  KVM guest 内补上 W4 真实 ccache cold/hot transition witness。该 target 对 Redis
  `src/crc64.c` 和 nginx `src/core/ngx_string.c` 分别执行 cold/hot 两次
  `ccache gcc -c`，记录 `cache_miss=2`、`direct_cache_hit=2`、
  `local_storage_hit=2`、`local_storage_write=4` 和 `files_in_cache=4`。Redis
  cold/hot object hash 均为
  `d242984f49cd453b93273ec4a67567dc1c71109ca283d3e13f2c39250291793b`，nginx
  cold/hot object hash 均为
  `bd61b93452ad3a9af9a6b7f6357d8f15a88a4b98150b40958908ca7c6a569e73`。随后 target
  把两个 hot object 写入
  `results/phase1/20260615T-parent-key-poc/w4-ccache-real-entries.tsv`，并用
  `cache_locality_view.bpf.c` 跑 map-backed cache content oracle；summary 中
  `real_ccache_run=true`、`policy_executed=true`、`kvm_validated=true`、
  `output_hash_match=true`、`policy_content_oracle_failures=0`。raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w4-ccache-real.jsonl`。该 gate 仍显式
  `qualified_for_c8=false`，因为它只证明真实 ccache transition 和 ccache-derived
  object 上的 policy content oracle，不证明 ccache 自身 cache path 通过
  `namei_ext`、operation-weighted policy cache hit rate、真实 stale/corrupt
  transition、update/stale-window measurement 或 table/update budget failure。
- `make kvm-w4-ccache-trace RUN_ID=20260615T-parent-key-poc` 进一步在修改后的 kernel
  KVM guest 中用 `strace -f -e trace=%file` 跟踪真实 `ccache` hot compile。该 target
  先用同一独立 `CCACHE_DIR` 对 Redis `src/crc64.c` 和 nginx
  `src/core/ngx_string.c` 做 cold compile 暖 cache，再分别 trace hot compile。
  raw result 位于
  `results/phase1/20260615T-parent-key-poc/w4-ccache-trace.jsonl`，trace logs 位于
  `w4-ccache-trace-redis.strace.log` 和 `w4-ccache-trace-nginx.strace.log`。当前结果
  记录 Redis hot compile 134 条 file-op trace、其中 20 条触碰 `CCACHE_DIR`；nginx
  hot compile 602 条 file-op trace、其中 20 条触碰 `CCACHE_DIR`；`cache_miss=2`、
  `direct_cache_hit=2`、`local_storage_hit=2`、`local_storage_write=4`，并保存
  `w4-ccache-trace-inputs.sha256` 和 `w4-ccache-trace-artifacts.sha256`。该 gate
  只证明真实 ccache hot path 在 KVM 中实际访问 cache directory；`policy_executed=false`
  且 `qualified_for_c8=false`，因为它没有 attach `namei_ext` policy，也不提供
  operation-weighted policy cache hit rate、真实 stale/corrupt transition、
  update/stale-window measurement 或 table/update budget failure。
- `make kvm-w4-ccache-policy-bridge RUN_ID=20260615T-parent-key-poc` 已补上 W4
  trace-derived ccache policy bridge。该 target 从上述 Redis/nginx raw strace logs 中
  抽取成功 `openat(..., O_RDONLY) = fd` 的真实 cache object paths，生成
  `w4-ccache-policy-bridge-trace-objects.txt` 和
  `w4-ccache-policy-bridge-entries.tsv`，再在修改后的 kernel KVM guest 中 attach
  `cache_locality_view.bpf.c` 跑 content oracle。当前 bridge 有 4 个 trace-derived
  entries：Redis 2 个、nginx 2 个；`attached_expected_match=4`、
  `attached_forbidden_mismatch=4`、`readdir_alias=4`、`policy_content_oracle_failures=0`。
  `w4-ccache-policy-bridge-policy-scope` 明确记录
  `ccache_compile_policy_executed=false`、
  `trace_derived_policy_oracle_executed=true`、`operation_weighted_policy_cache_hit_rate=false`
  和 `qualified_for_c8=false`。该 gate 证明真实 trace object component 能被 W4 policy
  oracle 消费，但仍不证明真实 ccache compile 自身由 `namei_ext` policy 决策。
- `make kvm-w4-ccache-bulk-policy-bridge
  RUN_ID=20260616T-w4-ccache-bulk-smoke-v1` 已把 W4 ccache trace shape 从
  two-file sampled trace 扩展为 Redis/nginx 各 10 个真实 source 的 bulk hot compile
  trace。该 target 先在修改内核 KVM guest 中对 20 个 source 做 ccache cold/hot
  compile，`w4-ccache-bulk-cache-path-trace` row 记录 `source_count=20`、
  `cache_path_file_ops=400`、`cache_miss=20`、`direct_cache_hit=20` 和
  `output_hash_match=true`；随后从 strace logs 抽取 40 个成功读取的真实 ccache cache
  object paths，生成 `w4-ccache-bulk-policy-bridge-trace-objects.txt` 和
  `w4-ccache-bulk-policy-bridge-entries.tsv`，再 attach
  `cache_locality_view.bpf.c` 跑 content/readdir oracle。summary 记录
  `redis_trace_objects=20`、`nginx_trace_objects=20`、
  `policy_content_oracle_failures=0`、`policy_executed=true`、`kvm_validated=true`
  和 `pass=true`。该 run 是更真实 cache workload shape 的 smoke evidence，仍显式
  `qualified_for_c8=false`，因为它还没有 operation-weighted policy-attached compile
  hit-rate、同 bulk shape 的 FUSE/cache-remap/native ccache baseline、
  真实 stale/corrupt transition、update/stale-window measurement 或 table/update
  budget failure。后续已补同 bulk shape 的 materialized baseline release input，但
  仍缺 proposed-system policy-attached compile 和其他强 baseline。实现记录见
  `docs/tmp/2026-06-16-w4-bulk-ccache-workload-implementation.md`。
- `make kvm-w4-ccache-policy-compile RUN_ID=20260615T-parent-key-poc` 已补上 W4
  真实 ccache policy-attached compile witness。该 target 复制上一阶段真实
  `CCACHE_DIR`，把 4 个 trace-derived cache objects 从 visible name rename 成 hidden
  `.local` backing，在 attach `cache_locality_view.bpf.c` 后填充 `cache_rules` map，
  再运行真实 Redis `src/crc64.c` 和 nginx `src/core/ngx_string.c` 的
  `ccache gcc -c` hot compile。raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w4-ccache-policy-compile.jsonl`；
  summary 记录 `real_ccache_run=true`、`policy_executed=true`、
  `ccache_compile_policy_executed=true`、`policy_redirected_cache_objects=4`、
  `redis_trace_objects=2`、`nginx_trace_objects=2`、`output_hash_match=true`、
  `pass=true` 和 `failures=0`。ccache stats 记录 `cache_miss=0`、
  `direct_cache_hit=2`、`local_storage_hit=2` 和 `local_storage_write=0`。该 gate
  证明真实 ccache hot compile 能在 policy attach window 内通过 `namei_ext`
  解析 trace-derived cache objects，并保持 Redis/nginx output object hash 与 baseline
  hot object 一致；它仍显式 `qualified_for_c8=false`，因为还没有 release-level
  operation-weighted policy cache hit rate、真实 stale/corrupt transition、update/stale
  window 或 table/update budget counterfactual。
- `make kvm-w4-ccache-table-compile RUN_ID=20260615T-parent-key-poc` 已补上 W4
  table-only policy-attached ccache compile comparator。该 target 复用同一份真实
  trace-derived `CCACHE_DIR`、同一组 Redis/nginx source file 和同一组 4 个 cache
  object，把 policy 从 `cache_locality_view.bpf.c` 换成 `table_redirect.bpf.c` 的
  exact redirect table。raw evidence 位于
  `results/phase1/20260615T-parent-key-poc/w4-ccache-table-compile.jsonl`；summary
  记录 `real_ccache_run=true`、`policy_executed=true`、
  `ccache_compile_policy_executed=true`、`policy_redirected_cache_objects=4`、
  `redis_trace_objects=2`、`nginx_trace_objects=2`、`output_hash_match=true`、
  `table_baseline_current_oracle_pass=true`、`content_equivalent_table_oracle=true`、
  `pass=true` 和 `failures=0`。ccache stats 同样记录 `cache_miss=0`、
  `direct_cache_hit=2`、`local_storage_hit=2` 和 `local_storage_write=0`。这个结果是
  C8 的负面证据：当前 sampled Redis/nginx ccache hot compile witness 能被
  table-only exact redirect 解释，因此 W4 仍不能声称需要 eBPF 可编程逻辑；后续必须用
  release-level operation-weighted hit rate、stale/corrupt transition、update/stale
  window 或 table/update budget failure 证明 table-only 不足。
- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-valid-sibling-structured-oracle` 已补上
  W4 parent-scoped cache policy PoC。最终实现没有新增第二张 parent map，而是复用
  `cache_rules`，用 `name_len=0` 的 parent wildcard key 表示“该 cache leaf parent
  下 verified-hit object lookup 解析为 `component.local`”；lookup path 又进一步收窄为
  ccache object-shape guard（32 字节 component，前 31 字节 lower-alnum，末尾 `M` 或
  `R`）加 trace-derived bounded name witness，并在同 parent 下加入 `metadata.txt`
  sibling PASS 负例和合法 ccache object 形状但不在 witness 集合中的 sibling PASS 负例。
  普通 exact entries 仍用于
  readdir alias。raw evidence 位于
  `results/phase1/20260615T-w4-valid-sibling-structured-oracle/w4-ccache-parent-compile.jsonl`；
  summary 记录 `real_ccache_run=true`、`policy_executed=true`、
  `ccache_compile_policy_executed=true`、`output_hash_match=true`、
  `parent_rule_policy=true`、`cache_leaf_parents=4`、`parent_rule_updates=4`、
  `exact_readdir_updates=4`、`table_equivalent_rule_updates=8`、`direct_cache_hit=2`、
  `local_storage_hit=2`、`pass=true`、`failures=0`，且 raw event
  `attached_parent_sibling_pass` 与 `attached_parent_valid_sibling_pass` 均为
  `pass=true`，其中 valid-shape sibling oracle 额外记录
  `content_oracle=true`、`content_oracle_kind=exact-text`、
  `expected_content_len=observed_content_len` 和相等的
  `expected_content_fnv1a64`/`observed_content_fnv1a64`，且
  `parent_valid_sibling_backing_absent` 也为 `pass=true`；Makefile target 已显式 hard-check 这些事件，并在 stats event 中记录
  `parent_sibling_pass=true`、`parent_sibling_pass_count=1`、
  `valid_shape_sibling_prepare_count=1`、
  `valid_shape_sibling_backing_absent_count=1`、
  `valid_shape_sibling_content_oracle=true` 和
  `valid_shape_sibling_content_pass_count=1`。该 witness 也已纳入默认 `make phase1` 和
  `make report` hard gate。实现记录见
  `docs/tmp/2026-06-15-w4-parent-scoped-cache-policy-implementation.md` 和
  `docs/tmp/2026-06-15-w4-valid-shape-sibling-gate-implementation.md`。这个 PoC
  显示 parent-scoped suffix policy 可以在 KVM 内驱动真实 Redis/nginx ccache hot
  compile，并且 `metadata.txt` 这个明显不满足 ccache object-shape 的同 parent sibling
  会 PASS，`0000000000000000000000000000000M` 这个合法形状但非 witness sibling 在
  `.local` backing 不存在时也会 PASS；但它不是 per-object content-verified
  decision，当前样本只有 4 个对象、readdir 仍是 exact alias，总 update 数仍等于 4 条
  parent lookup rule 加 4 条 exact readdir rule，且没有 release-scale hit-rate 或
  table budget failure，因此仍标记 `qualified_for_c8=false`。
- `make kvm-w4-ccache-release-counterfactual RUN_ID=20260615T-full-phase1-bench-variants`
  已把 W4 真实 ccache trace、trace-derived policy bridge、parent-scoped compile witness
  和 table-only compile comparator 连接成一个 KVM release counterfactual accounting
  gate。raw evidence 位于
  `results/phase1/20260615T-full-phase1-bench-variants/w4-ccache-release-counterfactual.jsonl`；
  输入哈希位于 `w4-ccache-release-counterfactual-inputs.sha256`，覆盖 11 个输入文件。
  当前 row 记录 `trace_cache_path_file_ops=40`、`trace_cache_objects=4`、
  `parent_rule_writes=4`、`exact_readdir_rule_writes=4`、`table_rule_writes=8`、
  `eligible_object_policy_hit_rate=1`、`cache_path_policy_coverage=0.1`、
  `attached_cache_path_file_ops=40`、`attached_policy_cache_object_ops=16`、
  `attached_sampled_operation_hit_rate=0.4`、
  `attached_sampled_operation_hit_rate_is_release=false`、
  `table_baseline_current_oracle_pass=true`、
  `operation_weighted_policy_cache_hit_rate=false` 和 `qualified_for_c8=false`。该 gate
  只把当前负证据机械化：sampled object set 和 sampled attach-window file-op stream 可被
  parent policy 覆盖，但 table-only 同样通过，且 release-level operation-weighted hit rate
  没有建立。实现记录见
  `docs/tmp/2026-06-15-w4-release-counterfactual-accounting-implementation.md` 和
  `docs/tmp/2026-06-15-w4-attach-window-optrace-implementation.md`；report gate 修复与
  raw strace replay 复算记录见
  `docs/tmp/2026-06-15-w4-attach-window-report-gate-fix.md`。当前完整 run 记录见
  `docs/tmp/2026-06-15-full-phase1-bench-variants-run.md`。
- `docs/tmp/2026-06-14-real-workload-source-signal-ledger.md` 已把四类 policy family
  的真实来源、性能信号、当前 raw evidence 和 release blocker 绑定成 source-to-signal
  ledger；`docs/experiment-plans/osdi-evaluation.md` 和论文 evaluation section 也同步了
  同一套 ledger。后续任何 C1/C8 表述必须先消除对应 release blocker。
- `docs/tmp/2026-06-15-eval-osdi-policy-family-gate-implementation.md` 已记录
  B12 release contract 的 Makefile 实现、输入哈希、验证命令、hard gate 预期失败
  和剩余 blocker。该文档是当前 OSDI eval gate 的实现记录；后续每个新增 release
  workload、baseline、metric 或 report gate 仍必须各自写独立 `docs/tmp/` 记录。
- `docs/tmp/2026-06-15-eval-osdi-performance-gate-implementation.md` 已记录
  B2/B8 performance contract 的 Makefile 实现、当前 smoke bench 的降级原因、
  验证命令和发布级性能评估缺口。
- `make table-budget RUN_ID=20260614T-w2-nginx-probes-phase1` 已新增 table-only
  budget accounting artifact：
  `results/phase1/20260614T-w2-nginx-probes-phase1/table-budget.jsonl`。该 target
  读取 W1/W2/W3/W4 KVM path oracle 的 table baseline 结果和对应 TSV，记录 4 个
  family 的 entries、table entries、static-load accounted update writes、committed
  budget、input sha256 和 `qualified_for_c8=false`。`make report` 会重新运行
  `make table-budget`，并把该 artifact、`table-budget-inputs.sha256`、exact family
  mapping 和 budget schema 作为 hard gate 纳入 summary。它仍只说明当前 path oracle
  下 table baseline 通过，不能支撑 C8。
- `make clean` 只清理 workload build/cache outputs，不删除 `results/workloads/`；
  workload raw results 只能通过显式 `make workload-clean-results` 清理。

这些结果证明 policy objects 可以构建、通过真实 KVM attach path，并执行四类不同
POC path-resolution 语义；也证明 primary workloads 的上游 source inputs 已经固定
并可复现获取，且 W1 的 Redis/nginx source-build-trace、host build-output oracle、
W1 per-entry synthetic-directory path oracle、W1 KVM policy preprocessing replay witness、
W2 fixture path oracle、W2 nginx real endpoint health + fixture content probes oracle、
W3 checkpoint path oracle、W4 cache path oracle、W4 cache content oracle、W4 真实
ccache transition witness、W4 真实 ccache cache-path trace witness 和 W4 trace-derived
ccache policy bridge witness、W4 真实 ccache policy-attached compile witness、W4
parent-scoped ccache compile witness、W3 Redis table-only replay counterfactual、W4
cache-content table-only comparator、W4 table-only ccache compile comparator 和 W4
release counterfactual accounting
可以 Makefile-only 复现。它们还不能支撑 C1/C8 论文主张。C1/C8 仍要求每个 policy
family 至少两个真实 workload row 从 `planned`、`source-build-trace` 或
`functional_only` 变为 `qualified_for_c8`，并由 workload provenance、semantic
witness、family-specific full oracle、table-only counterfactual 和 raw KVM results
共同证明。

目标抽象是：

```text
parent path + component name + operation context -> path-resolution decision
```

初始动作只有：

- `PASS`：继续正常 VFS resolution。
- `REDIRECT`：把当前 component 替换成 policy 选择的 component；实际 lookup、
  permission check 和 file operations 仍由内核执行。

这个位置介于 bind mount、OverlayFS 等固定内核机制和 FUSE 这类完整用户态文件系统
之间。

## OSDI 风格定位

现代系统越来越频繁地需要让同一个路径在不同 workload、依赖图、checkpoint/restore
session、cache 状态和执行上下文下解析到不同 backing object。构建系统需要
per-action declared input 和 generated output view；测试和 staging 环境需要把真实
config、secret、certificate、socket 或 endpoint path 替换成 fixture 或 fake
service；checkpoint/restore 需要把 checkpointed state/config/cache 和新运行环境的
runtime-local path 组合成一致的 restored view；构建和包系统需要把 content-verified
local cache、remote cache 或 canonical store 按 hash/state 选择出来。这些场景的
共同点不是需要一个新文件系统，而是需要在已有文件之上提供动态、可验证、每工作负载
可编程的路径解析机制。

现有机制落在两个极端。Bind mount、OverlayFS 等内核机制性能好，并保留
原生 VFS 行为，但策略固定、粒度粗、动态重配置成本高。FUSE 提供了足够灵活
的路径解析语义，但把大量路径决策移到用户态，引入额外上下文切换，并经常
重复实现 VFS 和 lower filesystem 已经提供的功能。LSM、Landlock、fanotify
和 BPF LSM 可以限制或观察访问，却不能自然表达“这个 workload 看到的路径树
应该长什么样”。

`namei_ext` 的核心观察是：许多真实 workload 需要的是可编程路径解析，而不是
可编程 filesystem implementation。因此，`namei_ext` 在 VFS name resolution
路径中加入一个窄 eBPF 决策点。每次路径解析或目录枚举时，
内核向 BPF 提供 parent path、component name 和事件上下文；BPF 返回受限
动作：`PASS` 或 `REDIRECT`。在 Phase 1 中，`REDIRECT` 把当前 component
重定向到同一父目录下的 backing component，并让 readdir 把 backing entry
以 alias 名字返回。BPF 不创建 dentry，不分配 inode，不实现 file operations，
也不执行递归路径解析。

这种设计保留了内核对文件系统语义的所有权，同时让路径解析变成 per-workload
可编程策略。目标是在 build graph view、controlled test fixture substitution、
checkpoint/restore path view 和 content-verified cache locality 等真实场景中，
获得接近内核机制的 data-path 行为，同时避免 FUSE 式全文件系统实现的复杂性和开销。

一句话论文 claim：

```text
Phase 1 只证明：可以在 VFS name resolution 上实现一个窄 eBPF path-resolution
PoC，让内核继续拥有 VFS object 和 lower-filesystem 语义。
```

生产级路径解析定制能否由该 abstraction 支撑，仍是后续 OSDI 级别 evaluation gate，
不能由当前 Phase 1 PoC 直接声明。

论文不能把一个 generic redirect table 当成主证据。更强的 abstraction claim 必须由
多个语义不同的 eBPF policy family 支撑：`build_graph_view.bpf.c`、
`sandbox_fixture_view.bpf.c`、`checkpoint_restore_view.bpf.c` 和
`cache_locality_view.bpf.c` 都必须在同一个 kernel ABI 上运行。只有当
`table_redirect.bpf.c` 在同等 table/update budget 下无法同时满足这些 family 的
semantic oracle 和 cost gate 时，C8 的“需要 eBPF programmable path-resolution
logic”才成立。

## 动机

许多生产系统并不需要完整自定义文件系统。它们需要的是对已有目录树的不同路径解析
视图：

- 构建系统从真实源码、generated outputs、toolchain 和 external deps 构造 per-action
  view，并用 undeclared input poison 暴露依赖泄漏。
- 测试和 staging 系统把 production config、secret、cert、socket 和 endpoint path
  替换成 fixture、fake secret 或 local fake service；这不是安全隔离或 deny/hide。
- Checkpoint/restore 系统需要让 state/config/cache 与 checkpoint manifest 一致，
  同时把 socket、pid、temp 等 runtime-local path 绑定到新的 restore 环境。
- 构建和包系统使用 local/remote cache、CAS、compiler cache、binary cache 或
  content-addressed store；path-resolution 必须基于 hash/state 拒绝 stale/corrupt
  cache。

现有选择都不完全合适：

- Symlink forest 和 copied tree 物化成本高，更新和清理也贵。
- Bind mount 和 OverlayFS 性能好，但策略固定、粒度粗、动态重配置成本高。
- FUSE 灵活，但把路径决策推到用户态，带来额外 user/kernel crossing，并容易重复实现
  lower filesystem 已有的语义。
- LSM、Landlock、fanotify 和 BPF LSM 可以限制或观察访问，却不能自然表达“这个
  workload 应该把此路径解析到哪个 backing object”。

`namei_ext` 聚焦中间地带：用可编程 path-resolution policy 表达这些扩展，同时保留
native lower-filesystem data I/O。

## 设计目标

1. 做路径解析策略，而不是文件系统实现。BPF 只决定一个路径 component 如何被解析；
   VFS 和 lower filesystem 继续拥有文件系统语义。
2. 只暴露一个窄 BPF 决策函数。lookup 和目录枚举调用同一个 eBPF policy 函数，
   用 `ctx->event` 区分事件类型。
3. 保留 VFS 安全属性。BPF 不能创建或持有 VFS object，不能执行递归 path walk，
   不能绕过 permission check，也不能实现 file operations。
4. 重定向 component，而不是重定义权限。Phase 1 使用同父目录 component redirect：
   BPF 把一个有界 redirect component 写入 ctx，内核通过正常 VFS 机制执行后续 lookup。
5. 保持 lookup 和目录视图一致。`open("/view/foo")` 和 `getdents64("/view")`
   必须由同一套 policy 语义解释。
6. 按 workload 绑定 policy。Phase 1 使用 cgroup-scoped attach，因为它直接对应
   build action、service worker 和 serverless worker。第一版 ABI 在一个 cgroup
   决策点只接收一个 `namei_ext` policy；multi-policy composition 是后续工作，不作为
   cgroup-BPF 的隐式副作用。
7. 最小化未启用时的开销。未 attach policy 时，VFS fast path 由 static branch 保护，
   剩余开销必须被测量。
8. 保持上游友好。内核改动应小、局部、可 review：尽量把新逻辑放在 `namei_ext`
   代码中，对既有 VFS 文件只做最小 guarded call-site 改动。
9. 达到 artifact-grade。Phase 1 必须构建内核、打包 runtime、启动 KVM、加载 policy
   programs、运行功能测试和微基准，并通过 Makefile-only infrastructure 产出可复现结果。

## 设计位置

最接近的类比是 `sched_ext`：

```text
sched_ext:
    内核拥有调度器机制
    BPF 选择调度策略

namei_ext:
    内核拥有 VFS 机制
    BPF 选择路径解析策略
```

这和 BPF 文件系统有意不同：

- BPF 不实现 `inode_operations`。
- BPF 不实现 `file_operations`。
- BPF 不直接创建 dentry 或 inode。
- BPF 不执行递归 path walk。
- BPF 不处理文件数据 read、write 或 mmap。

数据操作仍由 lower filesystem 执行，从而保留 page cache 行为，并避免 FUSE
data path 的主要开销。

## 内核放置点

为了作用于所有文件系统，这个扩展点必须放在具体 filesystem implementation 之上、
syscall-level policy 之下。

主 hook 应放在 VFS name resolution path 中：

```text
openat/statx/execve/rename/unlink/mkdir/...
        |
        v
VFS namei path walk
        |
        +-- namei_ext BPF policy
        |
        v
dcache / mount traversal / lower filesystem
```

policy object 应面向 `struct path`，而不是面向 inode：

- 一个 path 同时包含 `vfsmount` 和 `dentry`。
- 同一个 inode 可以通过多个路径和 hardlink 到达。
- Mount namespace、bind mount 和 chroot 都是路径语义。
- Dcache fast path 可能绕过 lower filesystem 的 `lookup()` callback。

目录枚举也必须被同一抽象处理。只处理 path lookup 会让 `cat /view/foo` 成功，
但 `ls /view` 仍不显示 `foo`。因此设计上同一个 policy abstraction 会在两个 VFS
边界被调用：

- namei path walking 中的 component lookup。
- `getdents64` / `iterate_dir` 中的目录枚举。

## 拟议接口

第一版原型暴露一个 cgroup-attached BPF program type 和一个 policy function。
lookup 和目录枚举是不同的 VFS call site，但它们用不同 event type 调用同一个
BPF 决策函数：

```c
SEC("cgroup/namei_ext")
int policy(struct bpf_namei_ext_ctx *ctx);
```

Phase 1 context 是固定大小。输入字段只读；redirect output 字段可由 BPF 写入：

```c
#define BPF_NAMEI_EXT_NAME_MAX 64

enum bpf_namei_ext_event {
    BPF_NAMEI_EXT_LOOKUP,
    BPF_NAMEI_EXT_READDIR,
};

struct bpf_namei_ext_ctx {
    u32 event;
    u32 flags;
    u32 name_len;
    u32 name_hash;
    u64 cgroup_id;
    u8 name[BPF_NAMEI_EXT_NAME_MAX];
    u32 redirect_name_len;
    u32 reserved;
    u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
    u64 parent_dev;
    u64 parent_ino;
    u32 parent_generation;
    u32 parent_flags;
};
```

返回值受约束：

```c
enum bpf_namei_ext_action {
    BPF_NAMEI_EXT_PASS,
    BPF_NAMEI_EXT_REDIRECT,
};
```

对 `LOOKUP` 来说，`REDIRECT` 表示在同一父目录中 lookup `redirect_name`，
而不是请求的 component。对 `READDIR` 来说，`REDIRECT` 表示把当前 lower entry
以 `redirect_name` 作为用户可见 alias 发出。

这样 Phase 1 可以避免完整 path-string rewrite、递归 path walk 和图环，同时演示核心
programmable path-resolution 机制的最小可运行 PoC。它还不能证明生产级机制或 C8
claim；这些结论必须等待 release-scale workload、operation-weighted coverage 和
table/update-budget counterfactual 通过。

## 安全契约

核心论文主张依赖一个窄且可执行的契约：

- BPF 可以选择 path-resolution policy，但不能拥有 VFS object。
- Redirect output name 由内核校验为单个 component。
- Phase 1 redirect 非递归，并且只允许同父目录。
- Policy 不能绕过 lower filesystem 不允许的权限。
- Permission check 保持在正常 VFS/lower-filesystem 路径中。
- 遇到 BPF failure、verifier rejection、runtime error 或 policy timeout 时，内核必须
  返回有文档说明的失败，或进入明确命名的非 Phase-1 诊断模式。Phase 1 validation
  不能静默降级到更弱行为。

原型应从读多写少的 path-resolution 场景开始；create、unlink、rename 等 writable
operation 后续再评估。

## 初始范围

当前 Phase 1 语义切片支持：

- cgroup-scoped policy attachment。
- `PASS` 和同父目录 component `REDIRECT`。
- `openat`、`statx`、`access` 和 `execve` 的路径解析。
- 把 backing entry 重写成 alias entry 的目录枚举。
- read/write data path 继续委派给 lower filesystem。

Phase 1 避免：

- 任意 BPF path-string 构造。
- BPF 创建 dentry 或 inode。
- 在 target registry 完成设计前支持 cross-directory 或 registered-path redirect。
- 网络或远程文件系统语义。
- 完整 POSIX writable union 语义。
- 超出正常 VFS 行为的 cross-filesystem rename 语义。

详细 Phase 1 工程设计历史记录见 [phase1_design.md](phase1_design.md)，但该文档已经
标为历史文档；当前规范以本研究计划和 OSDI evaluation plan 为准。简言之，Phase 1
只有在干净 checkout 能通过一个顶层 Make target 构建修改后的内核、打包
BPF/userspace runtime、在 KVM 中启动修改后的内核、加载 policy、运行正确性测试、
运行现实的微基准并产出可复现结果时，才算完成。

## 使用场景

### 构建依赖图 / Hermetic Build Action

构建系统经常构造 per-action filesystem view。`namei_ext` 的目标不是替代构建系统，
而是把 generated output 优先、declared source fallback、toolchain selection、
external dependency 和 undeclared dependency poison 这些路径解析语义放进一个
cgroup-scoped eBPF policy。

关键指标：

- sandbox/view setup latency；
- metadata operation throughput 和 p99；
- build action wall time；
- 创建的 inodes、symlinks、mounts 或 table entries 数量；
- output hash、undeclared dependency poison 和 dependency leak checker。

### 受控测试沙箱 / Fixture Substitution

测试、staging 和 CI workload 常需要把 production config、secret、certificate、
socket 或 endpoint path 替换成 fixture、fake secret 或 local fake service。这个
use case 不做安全隔离、不做 hide/deny claim，也不声称替代完整 container rootfs。
它只证明可编程 path-resolution 可以表达真实应用启动时的 fixture substitution。

关键指标：

- fixture setup latency；
- startup 到 health check 成功的 p99；
- no-real-secret/config hash oracle；
- endpoint checker 和 poison sentinel；
- 与 projected volume、copy/symlink/bind/FUSE 的功能等价比较。

### Checkpoint/Restore Path View

Checkpoint/restore 不只是复制目录。恢复后的 workload 需要看到与 checkpoint manifest
一致的 state/config/cache，同时 socket、pid、temp 和部分 runtime-local path 必须指向
新环境。`checkpoint_restore_view.bpf.c` 用 restore_id、checkpoint_epoch、path class
和 manifest hash 做 bounded decision，证明这是独立于 build/test/cache 的 policy
family。

关键指标：

- restore view setup latency；
- restored service health-check latency；
- state/config/cache hash 与 checkpoint manifest 一致；
- runtime-local path remap 正确；
- 0 mixed checkpoint/current epoch。

### Content-Verified Cache Locality

真实构建和包系统大量依赖 local/remote cache、CAS、compiler cache、binary cache 和
content-addressed store。`cache_locality_view.bpf.c` 按 content hash、cache state、
node/profile 和 canonical manifest 决定 verified hit、stale/corrupt reject、miss
fallback 或 pass-through。

关键指标：

- cache view setup latency；
- hit/miss/stale/corrupt path 的 p99；
- content hash correctness；
- stale/corrupt cache 0 unexpected hit；
- update writes、stale window 和 table-only counterfactual。

## 评估计划

基线：

发布级 baseline 身份、配置和功能等价规则以
[experiment-plans/osdi-evaluation.md](experiment-plans/osdi-evaluation.md) 的
baseline identity table 为准；这里仅列高层类别。

- 原生 lower filesystem。
- Bind mounts。
- OverlayFS。
- Symlink forest。
- 适用场景下的 FUSE passthrough。
- 简单 FUSE path-remapping filesystem。

微基准：

- `openat` 和 `statx` 延迟。
- Dcache hit/miss 路径。
- `getdents64` 吞吐。
- Path depth sensitivity。
- Policy map lookup 开销。
- Redirect-chain 开销。

宏基准：

- Bazel-style 或 Ninja-style build sandbox workload。
- 真实服务 fixture-substitution workload。
- CRIU/Podman-style checkpoint/restore path-view workload。
- 使用 Bazel remote cache trace、ccache、BuildKit cache mount 或 Nix store path 的
  content-verified cache-locality workload。

正确性测试：

- Symlink handling。
- Hardlink visibility。
- Mount crossing。
- Chroot 和 mount namespace interaction。
- Permission preservation。
- 如果启用 rename、unlink、create，则测试对应行为。
- 如果原型暴露目录视图，则测试 inotify/fanotify 行为。

Phase 1 必须把 evaluation plan 变成可运行 artifact。第一套 benchmark 应包含现实的
metadata-path 微基准：

1. 针对 native lower file 的 cache-hot visible lookup。
2. alias path 到达 backing component 的 redirected alias lookup。
3. redirected alias `access` path walk。
4. 针对真实 backing file 的 redirected alias `open` 和预期失败的 `execve` path walk。
5. `getdents64` 列出 alias name 而不是 backing component name 的目录视图一致性。
6. 在确定性目录中执行 build/fixture/checkpoint/cache-style metadata walk，请求的
   component 会被重定向到 backing component。

所有 Phase 1 measurement 都应在修改后内核的 KVM guest 中运行。当前 artifact 输出
raw JSONL、Markdown summary、kernel config evidence、dmesg logs、ABI layout evidence、
kernel image hash、Docker image tar hash、主仓库和 kernel submodule provenance、
config hashes，以及 Docker runtime smoke result。论文级加固还需要更多重复、
随机化顺序、tail distribution、系统指标和更强 baseline systems。

面向论文的多使用场景评估设计见
[experiment-plans/osdi-evaluation.md](experiment-plans/osdi-evaluation.md)。
该计划是 Phase 1 之后 OSDI/SOSP 级主张、基线、真实工作负载、消融、压力测试和
主张门禁的依据。
中文论文形态 evaluation section 草稿维护在
[paper/evaluation.md](paper/evaluation.md)，只能从发布级 raw results 和上述计划中
填入数字和结论。

## 相关工作边界

相关工作边界必须明确：

- FUSE 提供完整 user-space filesystem semantics。`namei_ext` 面向更窄的
  path-resolution policy class，并保持 lower-filesystem data I/O 走原生路径。
- FUSE passthrough 降低 backing file 的 data-path overhead。`namei_ext` 的目标是在
  path-resolution-only transformation 中避免引入完整 FUSE semantics。
- EXTFUSE 用 eBPF 加速 FUSE。`namei_ext` 不是更快的 FUSE request path，而是
  VFS-level path-resolution extension point。
- OverlayFS 和 bind mounts 提供固定的内核 filesystem-tree composition。
  `namei_ext` 让 policy 可编程，并能按 workload 动态绑定。
- Landlock、BPF LSM 和 fanotify 提供访问控制或观测。`namei_ext` 还会改变路径解析
  结果的可见对象。
- Bento 等安全 filesystem framework 帮助实现文件系统。`namei_ext` 刻意避免暴露完整
  filesystem implementation interface。

## 研究问题

1. VFS extension interface 可以多窄，同时仍覆盖真实 build-graph、
   fixture-substitution、checkpoint/restore 和 cache-locality workloads？
2. BPF-defined path-resolution policy 能否在不把 inode/dentry ownership 暴露给 BPF 的
   前提下保留 VFS safety properties？
3. 与 native VFS、OverlayFS 和 FUSE passthrough 相比，metadata-path overhead 还剩多少？
4. 目录枚举需要哪些语义才能和 redirected lookup 保持一致？
5. 哪些 writable operations 可以安全支持，而不把系统变成完整 programmable filesystem？

## 里程碑

1. 为 kernel、KVM、BPF policy programs 和 benchmark matrices 增加
   infrastructure-as-code configs。
2. 记录 VFS lookup、readdir、locking/RCU、dcache 和 permission-ordering constraints
   的 kernel code survey。
3. 记录 one-function BPF ABI rationale、same-parent redirect design、functional
   test plan 和 benchmark plan。
4. 增加 top-level Makefile 和 Docker runtime image，使 `make phase1` 可以构建、
   启动 KVM、运行测试、运行 benchmark 并写出结果。
5. 实现最小 kernel patch，在 namei lookup 中调用 BPF policy。
6. 实现 cgroup-scoped attachment，作为 Phase 1 isolation 机制。
7. 增加和 lookup 一致的目录枚举支持。
8. 在 KVM 中运行 Phase 1 functional suite。
9. 针对 native-before-attach 和 attached-policy variants 运行 Phase 1 microbenchmark suite。
10. 把 ABI layout/header-sync gates 和 Docker runtime smoke 纳入默认 Phase 1 artifact path。
11. 如果 same-parent redirect 不足以支撑论文 workload set，则增加 referenced
    backing-path registry 和 cross-directory redirect support。
12. 为论文 evaluation 增加 OverlayFS、bind mount、symlink forest 和 FUSE baselines。
13. 推送 kernel submodule commit 和主仓库 commit，形成可复现 Phase 1 artifact。
14. 在 read-mostly PoC 测量完成后，决定第一篇论文是否包含 writable path operations。

## 2026-06-15 evaluation infrastructure 进展

已补齐 OSDI B2/B8 performance path 的两个基础设施缺口：

- `kvm-bench` 可以在 host 侧写出 `metadata.json`、repo status、kernel image/config hash 和
  benchmark/KVM config hash，然后在修改内核 KVM guest 中运行真实 `cgroup/namei_ext`
  attach path。
- `namei_ext_bench` 可以用 `RUN_ID` 派生的确定性 seed 写出 randomized variant order 和
  per-benchmark order rows。
- KVM guest 会在 benchmark 前后保存 `/proc/stat`、`/proc/meminfo`、`/proc/vmstat` 和
  `/proc/diskstats`，并在 `bench-system-metrics.jsonl` 中记录 before/after artifact 名称。
- `eval-osdi-performance-ledger` 会把 tail/CI artifact、run-order rows、system-metrics rows
  和五个 external baseline smoke rows 一起纳入 B2/B8 ledger。

当前 pilot 结果是：

- `results/phase1/20260615T-kvm-bench-order-metrics-pilot-v3/`
- `results/eval-osdi/paper/20260615T-eval-ledger-order-metrics-pilot-v2/b2-performance/`

该 pilot 中 `has_tail_latency_artifact=true`、`has_confidence_interval=true`、
`has_randomized_order=true`、`has_system_metrics=true`、`missing_release_baselines=[]`，
但 `has_release_tail_sample_budget=false` 且 `release_gate_pass=false`。因此它只证明
infrastructure 跑通，不能写成 C2/C3/C5 的 release 性能证据。下一步必须把相同路径扩展到
release repetitions，并把 copy/symlink/bind/OverlayFS/FUSE baselines 也扩展到 release
repetitions。

随后已跑通 20-sample microbench release-sample pilot：

- `results/phase1/20260615T-kvm-bench-release-sample-pilot/`
- `results/eval-osdi/paper/20260615T-eval-ledger-release-sample-pilot/b2-performance/`

该 run 中 `samples=20`、`bench_latency_rows=700`、`has_repetition_budget=true`、
`has_release_tail_sample_budget=true`、`has_randomized_order=true`、`has_system_metrics=true`。
`eval-osdi-performance` hard gate 当时仍然按预期失败，因为 external baseline release gate
尚未形成机器可读输入，B12 policy-family gate 也仍未通过。

之后 baseline release gate 已补齐：

- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-release-pilot/`
- `results/eval-osdi/paper/20260615T-eval-ledger-release-baselines-pilot/b2-performance/`

五个 external baselines 都有 20-sample KVM rows，`baseline_release_gate_pass=true`，
performance ledger 中 `missing_release_baselines=[]`。`eval-osdi-performance` hard gate 仍然
按预期失败，因为该 target 不能只凭输入证据支持 C2/C3/C5。

随后已增加 B2/B8 performance comparison/verdict ledger：

- `results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-expected-set-smoke-v1/`

comparison ledger 对 7 个 internal/external 共享 case 计算 `policy/native` p99 ratio、
`policy/FUSE` p99 speedup 和 `pass_only/native` residual。该历史 run 在当时输入规则下
得到负 verdict：`input_gate_pass=true`，但 `kernel_p99_threshold_pass=false`、
`fuse_speedup_threshold_pass=false`、`pass_only_threshold_pass=false`，因此
`c2_supported=false`、`c3_supported=false`、`c5_supported=false`、`release_gate_pass=false`。
关键数值是 max policy/native p99 ratio 8.18x、min policy/FUSE p99 speedup 1.45x、
max pass-only/native p99 ratio 4.36x。`eval-osdi-performance` hard gate 已改为读取
comparison verdict；`20260615T-eval-comparison-hardgate-v1` 按预期失败。后续
latency-batch gate 把该历史 run 降级为 diagnostic negative evidence，而不是
paper-grade p99 release evidence。

同时 baseline release gate 已 harden 到固定 8 个 expected benchmark cases：
`lookup_native_hot`、`lookup_tool_redirect`、`access_tool_redirect`、`open_tool_redirect`、
`read_tool_content`、`exec_tool_redirect`、`readdir_alias_view` 和
`build_tree_stat_walk`。1-sample smoke run 中五个 baseline 都覆盖该集合，
但 `baseline_release_gate_pass=false`，说明 smoke sample budget 不会误过 release gate。

随后根据 Arendt review 和 raw latency 调研，又增加了 release latency batch gate：

- `results/eval-osdi/paper/20260615T-eval-comparison-latency-batch-gate-v1/b2-performance/`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-unique-sample-smoke-v1/`

旧 release pilots 的 internal/external tail 都有 `has_release_sample_budget=true`，但
`min_ops_per_latency_row=4`，低于 `EVAL_OSDI_REQUIRED_LATENCY_BATCH=64`。因此最新
comparison summary 为 `input_gate_pass=false`、`has_internal_latency_batch=false`、
`has_external_latency_batch=false`、`verdict=blocked_by_missing_inputs`。旧 threshold
数字保留为 diagnostic negative evidence，但不能写成 paper-grade release p99 verdict。
baseline release gate 也新增 unique sample id budget，1-sample smoke 下
`baseline_unique_sample_budget_pass=false`。这一段是当时的 input-blocked 结论；下面的
batch=64 rerun 已消除该方法学阻塞。

上述 batch=64 release input 已经重跑完成：

- `results/phase1/20260615T-kvm-bench-release-batch64-v1/`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-batch64-v1/`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/`
- `results/eval-osdi/paper/20260615T-eval-comparison-batch64-hardgate-v1/b2-performance/`

新的 comparison summary 中 `input_gate_pass=true`、`has_internal_latency_batch=true`、
`has_external_latency_batch=true`、`baseline_release_gate_pass=true`，说明 B2/B8 已经不再被
latency-batch 方法学阻塞。但 release gate 仍然为 false：
`kernel_p99_threshold_pass=false`、`fuse_speedup_threshold_pass=false`、
`pass_only_threshold_pass=false`、`c2_supported=false`、`c3_supported=false`、
`c5_supported=false`。关键负数是 max policy/native p99 ratio 1.77x、min
policy/FUSE p99 speedup 1.33x、max pass-only/native p99 ratio 1.71x。
因此下一步不再是重复 batch=64 输入，而是定位内核热路径剩余开销、补 C2
setup/storage/update macrobench，或收窄 C2/C3/C5。

随后尝试了两轮 RCU-pass fastpath PoC，并把结果记录为负结果：

- `docs/tmp/2026-06-15-rcu-pass-fastpath-negative-result.md`
- `results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/`
- `results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/`
- `results/phase1/20260615T-kvm-bench-post-rcu-experiment-stable-smoke-v1/`

第一版让 PASS 在 RCU-walk 中继续，REDIRECT 返回 `-ECHILD`；第二版对 REDIRECT 尝试
`try_to_unlazy(nd)` 并复用 decision。两版都能在修改内核 KVM 中跑通 release input，
且 pass-only/native residual 分别降到 1.48x 和 1.38x；但最差 policy/native p99
分别恶化到 2.49x 和 2.43x，三项 C3/C5 阈值仍失败。因此这条优化路径已拒绝，当前
内核没有保留 RCU fastpath 改动。后续 B2/B8 工作应转向 cgroup BPF dispatch/context
成本、ctx construction、policy/map hot path，或者明确收窄性能主张。

随后完成 dispatch/context 热路径调研：

- `docs/tmp/2026-06-15-namei-ext-dispatch-context-cost-survey.md`

调研结论是：`pass_only` residual 由全局 static key、RCU 降级、184 字节 ctx 清零、
name copy、parent identity 填充、`task_dfl_cgroup(current)`、`cgroup_id(cgrp)`、
effective array lookup、`bpf_cg_run_ctx` setup/reset 和 BPF dispatch 共同组成。
不能贸然删除 `bpf_cg_run_ctx`，因为 `namei_ext_func_proto()` 复用 cgroup common helpers，
local storage 和 retval helpers 依赖 `current->bpf_ctx`；也不能无设计地懒填
`cgroup_id`，因为 table policy、cache policy 和 workload loaders 已把它作为 map key
隔离字段。下一轮最低风险 PoC 是不改 UAPI 的 ctx 初始化拆分：减少无用整块清零和字段
填充，同时保持 output buffer 清零、现有 offset 和 parent-aware semantics。

ctx 初始化拆分 PoC 随后完成并记录为混合结果：

- `docs/tmp/2026-06-15-ctx-init-split-poc-implementation.md`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-smoke-v1/`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-batch64-v1/`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-batch64-v1/`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-hardgate-v1/b2-performance/`

该 PoC 的 KVM release input 和 external baseline 都通过，comparison summary 中
`input_gate_pass=true`、`pass_only_threshold_pass=true`，max pass-only/native p99
ratio 降到 1.095x。但 C3 仍失败：`kernel_p99_threshold_pass=false`、
`fuse_speedup_threshold_pass=false`，max policy/native p99 ratio 为 1.81x，
min policy/FUSE p99 speedup 为 1.64x。`make eval-osdi-performance` hard gate
按预期退出 2。因此 ctx 初始化拆分只能作为 pass-only residual attribution evidence，
不能作为 C3/C5 supported evidence。下一步应转向 redirect policy/map hot path，
或在 helper-set/no-run-ctx ABI 设计和 claim narrowing 之间做明确选择。

随后完成 tail sample-density 诊断：

- `docs/tmp/2026-06-15-tail-sample-density-diagnostic.md`
- `results/phase1/20260615T-kvm-bench-ctx-init-split-tail10-v1/`
- `results/eval-osdi/baselines/20260615T-kvm-external-baselines-ctx-init-split-tail10-v1/`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/`
- `results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1/b2-performance/`

该诊断把每组 latency rows 从 20 增到 200，用来检查 20-row p99=max 的方法学风险。
结果显示 `input_gate_pass=true`、`fuse_speedup_threshold_pass=true`，min policy/FUSE
p99 speedup 为 2.26x；但 `kernel_p99_threshold_pass=false`、
`pass_only_threshold_pass=false`，max policy/native p99 ratio 为 4.37x，max
pass-only/native p99 ratio 为 2.62x。结论是 FUSE speedup 已不是主 blocker；
下一步应定位 pass-only/readdir/tree-walk tail residual，而不是继续优化
`exec_tool_redirect` 或单纯追逐 FUSE 2x。

随后完成 rusage/no-hook 诊断：

- `docs/tmp/2026-06-15-bench-rusage-diagnostic-implementation.md`
- `docs/tmp/2026-06-15-kvm-bench-variant-selector-implementation.md`
- `docs/tmp/2026-06-15-rusage-nohook-tail-diagnostic.md`
- `results/phase1/20260615T-kvm-bench-rusage-tail10-v1/`
- `results/eval-osdi/paper/20260615T-eval-rusage-tail10-v1/b2-performance/`
- `results/phase1/20260615T-kvm-bench-nohook-baseline-tail10-v1/`
- `results/eval-osdi/paper/20260615T-eval-nohook-baseline-tail10-v1/b2-performance/`
- `results/phase1/20260615T-kvm-bench-baseline-passonly-tail10-v1/`
- `results/eval-osdi/paper/20260615T-eval-baseline-passonly-tail10-v1/b2-performance/`

该步骤为每条 `bench`/`bench_latency` raw row 增加 `getrusage()` delta，并用
`BENCH_VARIANTS` 支持 Make-owned no-hook baseline-only 和 matched baseline/pass-only
诊断。结果显示非 exec p99 rows 基本没有 page fault 或 context switch，`pass_only`
和 `policy` 的 self CPU/op 几乎同步上升，说明 residual 更像 common
hook/dispatch CPU 成本。no-hook baseline-only 下 max pass-only/nohook p99 ratio 为
1.306x；matched baseline/pass-only 下 max pass-only/native p99 ratio 为 1.323x，
仍高于 1.1x C5 阈值。因此该诊断降低了 C5 失败的严重程度并澄清了归因，但没有改变
C5 unsupported verdict。下一步若继续性能线，需要设计 helper-set/no-run-ctx fastpath
或更细 cgroup dispatch attribution；否则应收窄 C3/C5。

## 2026-06-15 B12 refresh checkpoint

本轮重新运行完整 Phase 1：

- `make phase1 RUN_ID=20260615T-full-phase1-b12-refresh-v1`
- `make eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-b12-refresh-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1`
- `make eval-osdi-policy-family RUN_ID=20260615T-eval-b12-refresh-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-b12-refresh-v1`

结果：

- full Phase 1 run 通过，新的 evidence root 为
  `results/phase1/20260615T-full-phase1-b12-refresh-v1/`。
- B12 ledger 写出
  `results/eval-osdi/paper/20260615T-eval-b12-refresh-v1/b12-policy-family/policy-family.jsonl`。
- ledger summary 仍为 `qualified_families=0`、`release_gate_pass=false`、
  `c1_supported=false`、`c8_supported=false`。
- W4 row 明确记录 `content_table_counterfactual_negative=true`。
- hard gate `make eval-osdi-policy-family` 按预期失败，防止 refreshed evidence 被误写成
  C1/C8 supported claim。

判读：这次 refresh 修复了旧 canonical root 缺 W3/W4 counterfactual artifacts 的问题，但
没有改变 research conclusion。当前仍只能声明 Phase 1 prototype/witness 级别结果，不能声明
static table baseline 已被 release workload 反驳。

## 2026-06-15 C2 setup/update raw-row checkpoint

本轮继续在完整 Phase 1 中加入 `namei_ext` 自身的 setup/update raw rows，并重新刷新
B12 ledger：

- `make phase1 RUN_ID=20260615T-full-phase1-c2-setup-update-v1`
- `make eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-b12-c2-setup-update-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1`
- `make eval-osdi-policy-family RUN_ID=20260615T-eval-b12-c2-setup-update-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1`

结果：

- full Phase 1 run 通过，当前 canonical evidence root 更新为
  `results/phase1/20260615T-full-phase1-c2-setup-update-v1/`。
- 该 root 的 `bench.jsonl` 包含 1 条 `namei_ext-setup` row：
  `variant=backing_tree`、`created_dirs=67`、`created_files=66`、`bytes_written=132`。
- 该 root 的 `bench.jsonl` 包含 2 条 `namei_ext-update` rows：
  source backing update 为 `source_update_writes=65`、`update_bytes_written=845`；
  table map update 为 `policy_update_writes=66`。
- B12 ledger 写出
  `results/eval-osdi/paper/20260615T-eval-b12-c2-setup-update-v1/b12-policy-family/policy-family.jsonl`。
- ledger summary 仍为 `qualified_families=0`、`release_gate_pass=false`、
  `c1_supported=false`、`c8_supported=false`。
- hard gate `make eval-osdi-policy-family` 按预期失败，防止该 C2 raw-row refresh 被误写成
  C1/C8 支持证据。

判读：这一步解决的是 C2 的 raw-input plumbing，不是 C2 release claim。它证明修改内核
KVM 中的 `namei_ext` bench runner 已经保留 setup/update 原始观测；但仍缺 W1--W4
release macrobench、feature-equivalent external baselines、重复实验、tail/CI、资源指标和
正确性 oracle。因此 C2 仍为 unsupported，下一步必须做 setup/storage/update macrobench
comparison。

## 2026-06-15 C2 macrobench ledger checkpoint

在 raw rows 进入 full Phase 1 root 之后，本轮继续增加 C2 fail-fast macrobench ledger：

- `make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-macrobench-ledger-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`
- `make eval-osdi-macrobench RUN_ID=20260615T-eval-c2-macrobench-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`

结果：

- ledger 写出
  `results/eval-osdi/paper/20260615T-eval-c2-macrobench-ledger-v1/b3-macrobench/macrobench.jsonl`。
- summary 记录 `namei_ext_raw_gate_pass=true`，说明 full Phase 1 root 中的
  `namei_ext-setup` 和 `namei_ext-update` rows 能被 C2 contract 读取。
- summary 记录 `baseline_release_gate_pass=true` 和
  `baseline_unique_sample_budget_pass=true`，说明 batch=64 external baseline root 中五个
  baselines 都满足 release row budget。
- summary 同时记录 `namei_ext_release_sample_budget_pass=false`、
  `macrobench_input_gate_pass=false`、`c2_supported=false` 和
  `release_gate_pass=false`。
- hard gate `make eval-osdi-macrobench` 按预期失败，防止 raw input 和 baseline input
  被误写成 C2 支持证据。

判读：C2 现在不是“没有基础设施”，而是“基础设施已经能 fail fast 地指出证据不足”。
该 checkpoint 仍是 single-sample 历史记录；后续 release-sample checkpoint 已把
`namei_ext` 侧样本预算补齐。剩余工作是把 W1--W4 workload-equivalent
setup/storage/update 成本、对象数、写入量和正确性 oracle 纳入同一 schema；同时需要
明确 C2 阈值，否则论文仍只能声明 input gate。

## 2026-06-15 C2 release-sample checkpoint

本轮继续补齐 C2 的 `namei_ext` 侧 release repetition，并保持 hard gate 不误放行：

- `make bench`
- `make kvm-bench RUN_ID=20260615T-kvm-bench-c2-repetition-smoke-v1 SAMPLES=2 BENCH_ITERS=100 BENCH_LATENCY_SAMPLES=0`
- `make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-macrobench-ledger-unique-sample-compat-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-setup-update-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`
- `make phase1 RUN_ID=20260615T-full-phase1-c2-release-sample-v1 SAMPLES=20 BENCH_ITERS=2000 BENCH_LATENCY_SAMPLES=0`
- `make eval-osdi-macrobench-ledger RUN_ID=20260615T-eval-c2-release-sample-ledger-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`
- `make eval-osdi-macrobench RUN_ID=20260615T-eval-c2-release-sample-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1 EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID=20260615T-kvm-external-baselines-batch64-v1`

结果：

- full Phase 1 release-sample root
  `results/phase1/20260615T-full-phase1-c2-release-sample-v1/` 通过。
- 该 root 的 `bench.jsonl` 中 `namei_ext-setup`、`namei_ext-update variant=backing_tree`
  和 `namei_ext-update variant=table_redirect_hit` 各有 20 rows、20 unique samples，
  sample id 覆盖 0--19。
- `bench_map_update` 有 20 rows，benchmark failure rows 为 0。
- C2 macrobench ledger 写出
  `results/eval-osdi/paper/20260615T-eval-c2-release-sample-ledger-v1/b3-macrobench/macrobench.jsonl`。
- summary 记录 `namei_ext_raw_gate_pass=true`、
  `namei_ext_release_sample_budget_pass=true`、`baseline_release_gate_pass=true`、
  `baseline_unique_sample_budget_pass=true` 和 `macrobench_input_gate_pass=true`。
- summary 同时记录 `c2_supported=false`、`release_gate_pass=false` 和
  `verdict=blocked_by_missing_thresholds`，missing evidence 为 W1--W4
  workload-equivalent setup/storage/update macrobench 和 C2 setup/update success thresholds。
- hard gate `make eval-osdi-macrobench` 写出 artifacts 后按预期失败，防止 release
  sample budget 被误写成 C2 支持证据。

判读：C2 input gate 现在已经不再缺 `namei_ext` repetition。C2 仍不能支持论文主张，
因为还没有 W1--W4 同 workload 宏基准、feature-equivalent baseline comparison 和明确阈值。
下一步必须把每个 use case 的 setup/storage/update 成本和 correctness oracle 接入
`b3-macrobench/` schema，然后再判断是否能支持 materialization cost improvement。

## 2026-06-15 C2 workload-equivalent macrobench design checkpoint

本轮继续为下一步 C2 release evidence 写出独立设计记录：

- `docs/tmp/2026-06-15-c2-workload-macrobench-design.md`

设计结论：

- 第一版 target 应命名为 `eval-osdi-workload-macrobench-ledger`，输出仍放在
  `results/eval-osdi/paper/<run-id>/b3-macrobench/`。
- 第一版只做 `result_level=c2_workload_derived_contract`：读取现有 W1--W4 真实
  workload artifacts、KVM correctness oracles、setup/storage/update proxy fields 和
  missing blocker，生成 machine-checkable inventory。
- 第一版必须 expected-fail，不能支持 C2，因为它不是 KVM per-sample workload
  setup/update re-execution。
- 真正 release target 需要后续 `result_level=c2_workload_kvm_macrobench`：在修改内核
  KVM 内重跑 workload-specific setup/update，至少 20 个 samples，并和
  feature-equivalent baselines 比较。
- 优先实现 PoC 的 workload 是 W2 nginx fixture 或 W4 ccache，因为它们已有 app-level
  KVM correctness oracle；W3 Podman/CRIU 仍先受 capability blocker 限制。

判读：该设计把 C2 后续工作拆成 derived contract 和 KVM macrobench 两级，避免把 host
trace/provenance 或 fixture materialization 误写成 OSDI-level setup/materialization
性能证据。

## 2026-06-15 C2 workload-equivalent derived ledger checkpoint

本轮按设计实现并验证第一版 C2 workload macrobench 派生账本：

- `make eval-osdi-workload-macrobench-ledger RUN_ID=20260615T-eval-c2-workload-derived-ledger-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1`
- `make eval-osdi-workload-macrobench RUN_ID=20260615T-eval-c2-workload-derived-hardgate-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-c2-release-sample-v1`

实现记录：

- `docs/tmp/2026-06-15-c2-workload-macrobench-derived-ledger-implementation.md`

结果：

- ledger 写出
  `results/eval-osdi/paper/20260615T-eval-c2-workload-derived-ledger-v1/b3-macrobench/workload-macrobench.jsonl`。
- summary 记录 `workload_rows=8`、`correctness_oracle_passed=5`、
  `policy_kvm_rows=5`、`c2_eligible_rows=0`、`c2_supported=false`、
  `release_gate_pass=false` 和 `verdict=derived_contract_only`。
- 8 个 workload row 覆盖 W1 Redis/nginx build、W2 nginx/PostgreSQL fixture、
  W3 Redis/nginx checkpoint/restore 和 W4 ccache/BuildKit cache。
- 该 ledger 的 `result_level=c2_workload_derived_contract`，
  `run_environment=mixed_host_kvm_derived`，因此只记录 inventory 和 blockers。
- hard gate `make eval-osdi-workload-macrobench` 写出 artifacts 后按预期失败，防止
  derived inventory 被误写成 C2 支持证据。

判读：C2 workload inventory 已经机械化，但 C2 verdict 不变。当前最有价值的下一步不是
再增加派生字段，而是在修改内核 KVM 中选择 W2 nginx fixture 或 W4 ccache 做真正的
per-sample setup/update macrobenchmark，补 feature-equivalent baseline、app-level
correctness oracle 和显式阈值。

## 2026-06-15 W2 nginx KVM setup/update macrobench PoC checkpoint

本轮继续实现第一个真实 workload 的 KVM per-sample setup/update PoC：

- `make w1-oracle`
- `make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-smoke-v1 W2_NGINX_MACROBENCH_SAMPLES=2`

设计和实现记录：

- `docs/tmp/2026-06-15-w2-nginx-c2-kvm-macrobench-design.md`
- `docs/tmp/2026-06-15-w2-nginx-c2-kvm-macrobench-implementation.md`

结果：

- KVM guest 写出
  `results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/w2-nginx-macrobench.jsonl`。
- JSONL 包含 2 条 `w2-nginx-macrobench-setup`、2 条
  `w2-nginx-macrobench-update`、2 条 `w2-nginx-macrobench-correctness` 和 1 条
  `w2-nginx-macrobench-summary`。
- summary 记录 `pass=true`、`failures=0`、`policy_executed=true`、
  `kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。
- 每个 setup sample 创建 5 个目录、12 个文件；每个 update sample 更新
  `upstream.local`、`server.fake.crt` 和 `db.fake.pass` 三个 source backing files。
- correctness oracle 记录 pre-attach `nginx -t` 必须失败，attach 后和 post-update
  `nginx -t` 必须成功，并验证 config、endpoint、cert、secret、poison 以及 post-update
  endpoint/cert/secret probes。

判读：W2 nginx fixture 已经有真实 KVM setup/update raw-row path，但仍然只是
2-sample PoC。C2 verdict 不变。下一步应把 `kvm-w2-nginx-macrobench` 提升为
release target：至少 20 个 samples、同 workload feature-equivalent baseline、显式
setup/storage/update 阈值，并让 `eval-osdi-workload-macrobench-ledger` 读取这些 KVM
raw rows。

## 2026-06-15 W2 nginx KVM setup/update release-sample checkpoint

本轮继续把 W2 nginx KVM setup/update PoC 跑到 20 samples：

- `make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 W2_NGINX_MACROBENCH_SAMPLES=20`

运行记录：

- `docs/tmp/2026-06-15-w2-nginx-c2-kvm-macrobench-release-sample-run.md`

结果：

- KVM guest 写出
  `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`。
- JSONL 包含 20 条 `w2-nginx-macrobench-setup`、20 条
  `w2-nginx-macrobench-update`、20 条 `w2-nginx-macrobench-correctness` 和 1 条
  `w2-nginx-macrobench-summary`。
- summary 记录 `samples=20`、`setup_rows=20`、`update_rows=20`、
  `correctness_rows=20`、`pass=true`、`failures=0`、`policy_executed=true`、
  `kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。
- setup 分布：`setup_ns` 约 6.94--9.31 ms，每样本 5 dirs、12 files、293 bytes written、
  5638 bytes copied。
- update 分布：`update_ns` 约 10.8--32.4 us，每样本 3 source writes、0 policy writes、
  149 或 152 bytes written。

判读：W2 nginx fixture 已有 20-sample KVM setup/update raw input；C2 verdict 仍不变。
下一步不再是 release repetition，而是同 workload feature-equivalent baseline、显式阈值，
以及把 `eval-osdi-workload-macrobench-ledger` 接到这些 W2 KVM raw rows。

## 2026-06-16 真实 workload 来源和 citation checkpoint

本轮补齐真实 workload/source citation 审计，记录在：

- `docs/tmp/2026-06-16-real-workload-source-citation-audit.md`

同步更新：

- `docs/paper/refs.bib`
- `docs/paper/sections/02-motivation.tex`
- `docs/experiment-plans/osdi-evaluation.md`
- `research/CLAIM_LEDGER.md`
- `workload/w2-nginx-fixture/evidence.md`

结论：

- W1 build graph 的 primary sources 锁定为 Bazel sandboxing/hermeticity/dependencies/
  toolchains，以及 Redis/nginx 真实源码构建。
- W2 sandbox fixture 的 primary sources 锁定为 Kubernetes projected volumes/secrets、
  Docker Compose configs/secrets，以及 nginx/PostgreSQL 真实配置和服务路径。
- W3 checkpoint/restore 的 primary sources 锁定为 Podman checkpoint、CRIU
  checkpoint/restore、CRIU external bind mounts 和 DMTCP path virtualization。
- W4 cache locality 的 primary sources 锁定为 ccache、Docker BuildKit cache mounts、
  Bazel remote cache/remote execution API、Nix binary cache/content-addressed store 和
  Prometheus Go module graph。
- 这些来源只证明 use case 真实存在；它们不支持 C1/C2/C8 结论。C1/C8 仍需要每个
  policy family 的真实 workload oracle、operation-weighted release metric、table-only
  failure 或超预算证据。C2 现在已有 W2 nginx 的 feature-equivalent
  setup/storage/update baseline、storage footprint aggregation 和显式阈值 slice；W1
  build graph 也已有 proposed-system 和 copy/symlink/bind baseline release input，但
  W1 ledger 为负。因此全局 C2 仍需要 W1 projected/FUSE/threshold 或范围收窄，以及
  W3/W4 对等 workload macrobench。

判读：W2 同 workload feature-equivalent baseline 已推进到 copy/symlink/bind/projected/FUSE
五类 input，并已有 storage/threshold-supported W2 slice ledger；W1 build graph 也已有
20-sample proposed-system KVM setup/update release input和 copy/symlink/bind baseline
release input，但 W1 ledger 显示 fastest baseline 优于 proposed-system。当前最有价值的
C2 下一步是补 W1 projected/FUSE/threshold 或明确把 W1 写成负结果并收窄 C2，同时扩展
W3/W4 对等 setup/storage/update macrobench；如果转向 C8，则优先选择
W4 的真实 stale/corrupt transition 或 BuildKit/Prometheus cache trace，因为它比 W2
更可能产生 table-only failure 或 update-budget failure。

## 2026-06-16 W2 nginx feature baseline 与 workload ledger checkpoint

本轮补齐 W2 nginx 的同 workload feature baseline，并新增 W2 专用 workload
macrobench ledger。实现记录：

- `docs/tmp/2026-06-16-w2-nginx-feature-baseline-design.md`
- `docs/tmp/2026-06-16-w2-nginx-feature-baseline-implementation.md`
- `docs/tmp/2026-06-16-w2-nginx-bind-baseline-implementation.md`
- `docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md`
- `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-design.md`
- `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md`
- `docs/tmp/2026-06-16-w2-nginx-workload-ledger-implementation.md`

新增或更新的 Make targets：

- `make kvm-w2-nginx-baseline-macrobench`
- `make eval-osdi-w2-nginx-workload-macrobench-ledger`
- `make eval-osdi-w2-nginx-workload-macrobench`

运行结果：

- `make kvm-w2-nginx-baseline-macrobench RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4 W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20`
  通过，结果位于
  `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl`。
- 该 result 覆盖 `copy_tree`、`symlink_forest`、`bind_mount`、`projected_volume` 和
  `fuse_redirect` 五类 baseline；每类都有
  20 条 setup rows、20 条 update rows 和 20 条 correctness rows，summary 为
  `baseline_count=5`、`setup_rows=100`、`update_rows=100`、`correctness_rows=100`、
  `pass=true`、`failures=0`、`policy_executed=false`、`kvm_validated=true`、
  `feature_equivalent_baseline=true`、`c2_supported=false`、`release_gate_pass=false`。
- `make eval-osdi-w2-nginx-workload-macrobench-ledger RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v4
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4`
  通过，结果位于
  `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v4/b3-macrobench/w2-nginx-workload-macrobench.jsonl`。
- ledger summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
  `copy_symlink_baselines_pass=true`、`bind_baseline_pass=true`、
  `projected_volume_baseline_pass=true`、`fuse_baseline_pass=true`、
  `all_feature_baselines_pass=true`、`full_feature_equivalent_baseline_pass=true`，但
  `storage_footprint_pass=false`、`threshold_pass=false`、`c2_supported=false`、
  `release_gate_pass=false`。
- `make eval-osdi-w2-nginx-workload-macrobench RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v4
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4`
  已写出 artifacts，并按预期非零退出。

判读：W2 现在从“只有 proposed-system raw input”推进到“有 proposed-system、copy/symlink/bind
baseline、projected-volume baseline、FUSE baseline 和 expected-fail claim ledger”。该
checkpoint 当时还缺 storage footprint、显式 setup/storage/update 阈值，以及 W1/W3/W4
对等 macrobench；后续 W2 threshold 和 W1 release input 已继续缩小该缺口。

## 2026-06-16 W2 nginx storage/threshold ledger checkpoint

本轮继续把 W2 nginx workload ledger 从 v4 的五类 baseline input 推进到 storage/threshold
判定。实现记录：

- `docs/tmp/2026-06-16-w2-nginx-storage-threshold-design.md`
- `docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md`

新增或更新的文件：

- `configs/eval-osdi/w2-nginx-workload-macrobench.jq`
- `mk/eval_osdi.mk`

运行结果：

- `make eval-osdi-w2-nginx-workload-macrobench-ledger RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v5
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4`
  通过，结果位于
  `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`。
- ledger summary 为 `storage_footprint_pass=true`、
  `setup_latency_threshold_pass=true`、`update_latency_threshold_pass=true`、
  `update_materialization_threshold_pass=true`、`threshold_pass=true`、
  `w2_c2_slice_supported=true`，但全局 `c2_supported=false`、
  `release_gate_pass=false`。
- 关键均值为 `policy_setup_ns_avg=7500337.5`、
  `best_baseline_setup_ns_avg=9959036.45`、`policy_update_ns_avg=13914.8`、
  `best_baseline_update_ns_avg=14044.7`、`policy_setup_objects_avg=17`、
  `min_baseline_setup_objects_avg=19`、`policy_setup_bytes_avg=5931` 和
  `min_baseline_setup_bytes_avg=5931`。
- `missing_evidence=["W1/W3/W4 workload setup/storage/update macrobench"]`。
- `make eval-osdi-w2-nginx-workload-macrobench RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4`
  已写出 artifacts，并按预期非零退出。

判读：W2 nginx fixture 这一 slice 现在可以写成“同 workload、KVM、五类 feature
baseline、storage/threshold-supported”。但这仍不能把全局 C2 升级为 supported，因为
C2 的原始范围是 W1--W4 多 workload。后续 W1 已补 proposed-system release input；
当前缺口已进一步缩小为 W1 projected/FUSE/threshold 或 W1 负结果范围收窄，以及 W3/W4
对等 setup/storage/update macrobench。

## 2026-06-16 W1 build baseline release 与 workload ledger checkpoint

本轮继续把 W1 build graph 的同 workload baseline 从 1-sample smoke 提升为
20-sample KVM release input，并生成 claim-level ledger。新增记录：

- `docs/tmp/2026-06-16-w1-build-baseline-release-run.md`
- `docs/tmp/2026-06-16-w1-build-workload-ledger-release-run.md`

运行结果：

- `make kvm-w1-build-baseline-macrobench RUN_ID=20260616T-w1-build-baseline-release-sample-v1
  W1_BUILD_BASELINE_MACROBENCH_SAMPLES=20 W1_BUILD_BASELINES='copy_tree symlink_forest bind_mount'`
  通过，结果位于
  `results/phase1/20260616T-w1-build-baseline-release-sample-v1/w1-build-baseline-macrobench.jsonl`。
- summary 为 `baseline_count=3`、`samples=20`、`setup_rows=60`、`update_rows=60`、
  `correctness_rows=60`、`pass=true`、`failures=0`、
  `feature_equivalent_baseline=true`、`c2_supported=false` 和
  `release_gate_pass=false`。input hash 复验通过。
- `make eval-osdi-w1-build-workload-macrobench-ledger
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-ledger-release-v1
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v1`
  通过，结果位于
  `results/eval-osdi/paper/20260616T-eval-w1-build-workload-macrobench-ledger-release-v1/b3-macrobench/w1-build-workload-macrobench.jsonl`。
- ledger summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
  `copy_tree_baseline_pass=true`、`symlink_forest_baseline_pass=true`、
  `bind_mount_baseline_pass=true`，但 `projected_volume_baseline_pass=false`、
  `fuse_baseline_pass=false`、`storage_footprint_pass=false`、`threshold_pass=false`、
  `w1_c2_slice_supported=false`、`c2_supported=false`、`release_gate_pass=false`。
  `missing_inputs` 为 W1 projected-volume、W1 FUSE 和 W3/W4 macrobench；
  `failed_gates` 为 W1 storage footprint、setup latency、update latency 和 update
  materialization gate。
- 关键均值为 `policy_setup_ns_avg=66090011.6`、
  `best_baseline_setup_ns_avg=18326753.1`、`policy_update_ns_avg=52416038.25`、
  `best_baseline_update_ns_avg=40165924.95`、`policy_setup_objects_avg=14`、
  `min_baseline_setup_objects_avg=6`、`policy_setup_bytes_avg=457356` 和
  `min_baseline_setup_bytes_avg=69298`。
- `make eval-osdi-w1-build-workload-macrobench
  RUN_ID=20260616T-eval-w1-build-workload-macrobench-hardgate-release-v1
  EVAL_OSDI_W1_BUILD_POLICY_RUN_ID=20260616T-w1-build-macrobench-release-sample-v1
  EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID=20260616T-w1-build-baseline-release-sample-v1`
  写出 artifacts 后按预期失败；hardgate status artifact 记录 predicate
  `status=4`、`pass=false`，外层 Make wrapper 观察到 `hardgate_status=2`。

判读：W1 release comparison infrastructure 现在可运行，但结果不支持 C2。最快
`copy_tree` setup 和最快 `bind_mount` update 都优于 proposed-system；同时 W1 仍缺
projected-volume/FUSE baseline 和 storage/threshold-supported ledger。因此不能把 W1
写成 materialization/setup/update improvement，只能写成 release-level negative evidence
或继续补完整 baseline/threshold 后重新 gate。

## 2026-06-16 W4 materialized external baseline checkpoint

本轮继续按“baseline 不够强就补 baseline，而不是改弱 paper”的原则推进 W4：

- 新增 `make kvm-w4-ccache-materialized-baseline-macrobench`。该 target 复用
  `kvm-w4-ccache-policy-bridge` 的真实 Redis/nginx ccache trace-derived entries，在
  修改内核 KVM 中运行 `materialized_cache_view` 外部 baseline。baseline 不加载 eBPF、
  不 attach `namei_ext` policy，只把 `original` cache object 直接物化为应用可见
  `visible` 路径。
- 设计/实现记录为
  `docs/tmp/2026-06-16-w4-materialized-cache-baseline-design.md`、
  `docs/tmp/2026-06-16-w4-materialized-cache-baseline-implementation.md` 和
  `docs/tmp/2026-06-16-w4-materialized-baseline-ledger-integration.md`。
- `make kvm-w4-ccache-materialized-baseline-macrobench
  RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1
  W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=20` 通过。结果位于
  `results/phase1/20260616T-w4-ccache-materialized-baseline-release-v1/w4-ccache-materialized-baseline.jsonl`。
  summary 为 `samples=20`、`setup_rows=20`、`update_rows=20`、
  `correctness_rows=20`、`pass=true`、`failures=0`、`policy_executed=false` 和
  `feature_equivalent_baseline=true`。
- materialized baseline setup/update 平均为 57.95 ms/3.82 ms。之前
  `20260616T-w4-ccache-rule-macrobench-release-v1` 中 parent-rule policy setup/update
  平均为 110.55 ms/6.52 ms，table baseline 为 104.06 ms/6.31 ms。
- `make eval-osdi-w4-ccache-workload-macrobench-ledger
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-ledger-v2
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1`
  通过。ledger 位于
  `results/eval-osdi/paper/20260616T-eval-w4-ccache-workload-macrobench-ledger-v2/b3-macrobench/w4-ccache-workload-macrobench.jsonl`。
- ledger summary 为 `policy_release_input_pass=true`、
  `table_release_input_pass=true`、`materialized_baseline_pass=true`、
  `full_feature_equivalent_baseline_pass=true`，但 `storage_footprint_pass=false`、
  `setup_latency_threshold_pass=false`、`update_latency_threshold_pass=false`、
  `rule_materialization_threshold_pass=false`、`w4_c2_slice_supported=false`、
  `c2_supported=false` 和 `release_gate_pass=false`。
- hard gate
  `make eval-osdi-w4-ccache-workload-macrobench
  RUN_ID=20260616T-eval-w4-ccache-workload-macrobench-hardgate-v2
  EVAL_OSDI_W4_CCACHE_RULE_RUN_ID=20260616T-w4-ccache-rule-macrobench-release-v1
  EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID=20260616T-w4-ccache-materialized-baseline-release-v1`
  写出 artifacts 后按预期失败；status artifact 记录 `status=4`、`pass=false`。

判读：W4 当前不是“没有 baseline”，而是在更强的外部 materialized baseline 下明确为
负结果。该负结果不应通过改 paper 规避。下一步如果继续 W4，应补更复杂且真实的
cache workload：更多 cache objects 和同 parent fanout、真实 stale/corrupt/update
window、operation-weighted policy hit rate、BuildKit/Prometheus cache trace、
FUSE/cache-remap baseline 或 native ccache/BuildKit baseline。否则 C2 必须把 W4 作为
负结果或收窄范围。

## 2026-06-16 W4 bulk materialized external baseline checkpoint

本轮继续补 W4 的更强 baseline，而不是把现有负结果写弱。新增记录：

- `docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-design.md`
- `docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md`

运行结果：

- `make kvm-w4-ccache-bulk-materialized-baseline-macrobench
  RUN_ID=20260616T-w4-ccache-bulk-materialized-release-v1
  W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=20` 通过。结果位于
  `results/phase1/20260616T-w4-ccache-bulk-materialized-release-v1/`。
- 该 target 先复用 bulk Redis/nginx ccache trace path，`w4-ccache-bulk-trace.jsonl`
  记录 20 个真实 source、400 条 cache-path file ops、20 次 miss、20 次 direct hit
  和 output hash match。
- `w4-ccache-bulk-policy-bridge.jsonl` 记录 40 个 trace-derived cache objects，其中
  Redis/nginx 各 20 个，`policy_content_oracle_failures=0`。
- `w4-ccache-bulk-materialized-baseline.jsonl` 记录
  `workload=w4-ccache-bulk-redis-nginx`、`samples=20`、`setup_rows=20`、
  `update_rows=20`、`correctness_rows=20`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true` 和
  `feature_equivalent_baseline=true`。
- release setup min/avg/max 为 425.40/484.83/573.99 ms；update min/avg/max 为
  2.83/3.12/3.77 ms；object shape 为 40 cache objects、36 leaf parents、
  201335 bytes copied。

判读：这一步把 W4 bulk trace shape 的外部 materialized baseline 补成 release-style
raw input。它不支持 C2/C8，因为 proposed-system 还没有在同一个 20-source/40-object
bulk shape 下执行 policy-attached compile，也没有 FUSE/cache-remap/native
ccache/BuildKit baseline、stale/corrupt/update-window gate 或 table-only budget failure。
下一步应该先补 bulk proposed-system policy compile；如果它依然慢于 materialized
baseline，就继续补 FUSE/cache-remap/native baseline 和 workload/state transition，而不是
把 paper 写成“baseline 不合适”。
