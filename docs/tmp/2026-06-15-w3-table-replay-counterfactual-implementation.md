# W3 Redis table-only replay counterfactual 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: user requested continued Phase 1 OSDI-grade evaluation work
Completeness: complete

## 动机

B12/C8 的核心问题不是“有没有四个 eBPF policy 文件”，而是每个 policy family 是否在真实
workload 上体现了 table-only exact redirect 难以替代的语义。当前 W3
`checkpoint_restore_view.bpf.c` 已经有 KVM Redis checkpoint replay witness，但同一个
Redis replay 没有 table-only comparator。因此它只能证明 checkpoint policy 能跑通，不能回答
“table_redirect 在同等 workload 下能不能也跑通”。

本次实现的目标是补一个最小、机器可审计的 same-workload counterfactual：

- 同一个 Redis checkpoint replay；
- 同一个修改内核 KVM 环境；
- 同一个 `tests/w1_oracle/namei_ext_w1_oracle` runner；
- 只把 policy 从 `checkpoint_restore_view.bpf.c` 换成 `table_redirect.bpf.c`；
- 输出独立 raw JSONL 和输入 sha256；
- 汇总到一个 W3 release counterfactual accounting JSONL；
- 若 table-only 通过，必须作为 C8 负证据保留；若失败，也只在其它 release 条件满足后才能支持 C8。

## 设计约束

- 不改内核 ABI，不新增 BPF helper。
- 不新增项目自有 `.sh` 控制面。
- 入口必须是 Make target。
- policy 仍是 eBPF 程序，不引入 YAML/JSON/DSL policy。
- raw JSONL 只记录事实和 gate 字段，不在 collector 里写论文解释。
- Phase 1 validation 必须在 KVM 里跑真实 modified-kernel attach path。

## 计划改动

1. 扩展 `run_w3_redis_replay()`，让它接受 policy kind/name/source label。
2. 保留现有 `--checkpoint-redis-replay` 行为，新增 `--checkpoint-redis-table-replay`。
3. 新增 Make 变量：
   - `W3_REDIS_TABLE_REPLAY_JSON`
   - `W3_REDIS_TABLE_REPLAY_WORK_DIR`
   - `W3_REDIS_COUNTERFACTUAL_JSON`
   - `W3_REDIS_COUNTERFACTUAL_INPUTS`
4. 新增 KVM targets：
   - `kvm-w3-redis-table-replay`
   - `kvm-w3-redis-counterfactual`
5. 将 `phase1` 顺序接入新 targets，使默认 Phase 1 生成 W3 table-only comparator。
6. 更新 report hard gate 和 B12 ledger 输入，使新 evidence 被引用。

## 预期判读

如果 table-only replay 通过：

- 这是 W3/C8 的负证据；
- W3 不得声称 checkpoint/restore family 已证明 programmable path-resolution 必要性；
- B12 ledger 应继续保持 `checkpoint_restore` blocked。

如果 table-only replay 失败：

- 仍不能单独升级 C8；
- 还需要确认失败来自 table-only expressiveness，而不是 runner、policy load、map setup 或其它执行错误；
- 需要有 post-restore trace、zero mixed epoch 或 update/stale window 等 release-level oracle 才可计入 C8。

## 待验证

- `make w1-oracle`
- `make kvm-w3-redis-counterfactual RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
- `make -n eval-osdi-policy-family-ledger RUN_ID=20260615T-eval-w3-counterfactual-parse-v1 EVAL_OSDI_PHASE1_RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
- `make -n report RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
- `git diff --check`

## 实现结果

本次实现修改了：

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `run_w3_redis_replay()` 参数化 policy kind/name/result level；
  - 保留 `--checkpoint-redis-replay`；
  - 新增 `--checkpoint-redis-table-replay`；
  - table replay 在 attach 前写入两条 exact redirect 规则：
    `dump.rdb -> dump.ckpt` 和 readdir 反向 `dump.ckpt -> dump.rdb`。
- `mk/kvm.mk`
  - 新增 `kvm-w3-redis-table-replay`；
  - 新增 `kvm-w3-redis-counterfactual`；
  - 新增 `w3-redis-table-replay.jsonl`、`w3-redis-counterfactual.jsonl` 和对应 input sha256。
- `Makefile`
  - 默认 `phase1` 顺序加入 W3 table replay 和 W3 counterfactual；
  - `make help` 暴露新 targets。
- `mk/report.mk`
  - 增加 W3 table replay/counterfactual 的存在性、input sha256 和 raw JSONL gate；
  - 报告中新增 W3 table-only replay counterfactual 表；
  - 强制 counterfactual 仍为 `qualified_for_c8=false`。
- `mk/eval_osdi.mk`
  - B12 ledger 输入要求包含 `w3-redis-counterfactual.jsonl`；
  - `checkpoint_restore` 的 `table_counterfactual_support` 只在 counterfactual C8-qualified 且 table baseline 失败时才可能为 true。

## 验证结果

`make w1-oracle` 通过，说明 runner 编译成功。

`make kvm-w3-redis-counterfactual RUN_ID=20260615T-w3-redis-counterfactual-smoke-v1`
通过。该 target 实际启动三次 KVM guest：

1. checkpoint policy Redis replay；
2. table_redirect Redis replay；
3. counterfactual accounting。

关键 raw result：

- `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/w3-redis-replay.jsonl`
  - `pass=true`
  - `failures=0`
  - `policy_family="checkpoint_restore_view.bpf.c"`
  - `redis_checkpoint_loaded_via_policy=true`
  - `qualified_for_c8=false`
- `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/w3-redis-table-replay.jsonl`
  - `pass=true`
  - `failures=0`
  - `policy_family="table_redirect.bpf.c"`
  - `table_baseline_current_oracle=true`
  - `redis_checkpoint_loaded_via_policy=true`
  - `populate_table_rules.actual="2"`
  - `qualified_for_c8=false`
- `results/phase1/20260615T-w3-redis-counterfactual-smoke-v1/w3-redis-counterfactual.jsonl`
  - `policy_replay_pass=true`
  - `table_replay_pass=true`
  - `table_baseline_current_oracle_pass=true`
  - `table_rule_writes=2`
  - `table_budget_failure=false`
  - `zero_mixed_epoch_checker=false`
  - `restore_trace_checker=false`
  - `qualified_for_c8=false`

`sha256sum -c` 对 `w3-redis-counterfactual-inputs.sha256` 通过。

`make -n eval-osdi-policy-family-ledger ...` 和 `make -n report ...` 都能解析。
`git diff --check` 通过。

dmesg 关键词检查只命中 kernel command line 中的 `panic=30`，没有真实 BUG/Oops/Call
Trace/verifier failure。

## 判读

这个增量没有支持 C8。它把 W3 从“缺 table-only same-workload comparator”推进到
“table-only 在当前 Redis checkpoint replay 上也通过”。因此它是更强的负证据：

- W3 当前不能证明 checkpoint/restore policy family 需要 programmable path-resolution；
- B12 ledger 必须继续 blocked；
- 后续若要支持 W3/C8，需要真实 Podman/CRIU restore、restore trace、zero mixed epoch、
  update/stale window，或者能让 table-only 在同等 budget 下失败的 release workload。
