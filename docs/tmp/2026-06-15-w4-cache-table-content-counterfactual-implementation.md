# W4 cache-content table-only counterfactual 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: continue B12/C8 counterfactual work after W3 table replay
Completeness: complete

## 动机

W4 已经有 `cache_locality_view.bpf.c` 的 cache-content oracle，覆盖 verified hit、
stale fallback、corrupt reject 和 miss canonical 四类分支；也有真实 ccache sampled
compile 的 table-only comparator。缺口是：cache-content oracle 本身还没有同一
workload、同一 TSV、同一 KVM attach path 下的 table-only content comparator。

这个增量的目标不是支持 C8，而是补齐一个 reviewer 会要求的负证据：如果
`table_redirect.bpf.c` 在当前 W4 content oracle 上也能通过，就必须明确记录当前
stale/corrupt/miss witness 仍然太窄，不能证明需要 eBPF programmable cache policy。

## 设计约束

- 不改内核 ABI，不新增 BPF helper。
- 不新增项目自有 shell 脚本。
- 所有入口通过 Make target。
- policy 仍是 eBPF 程序，不引入 YAML/JSON/DSL。
- table comparator 输出独立 JSONL，不改变既有 `w4-cache-content.jsonl` 的事件计数。
- raw collector 只写事实和 gate 字段，不写论文解释性统计。

## 计划改动

1. 参数化 `run_cache_content_oracle()` 的 policy kind、policy name、event name 和
   result level。
2. 保留现有 `--cache-content` 行为。
3. 新增 `--cache-table-content`，使用 `table_redirect.bpf.c` 的 `exact_redirects`
   map 运行同一 content oracle。
4. 新增 KVM targets：
   - `kvm-w4-cache-table-content`
   - `__phase1_guest_w4_cache_table_content`
5. 将新 target 接入默认 `phase1` 和 `make report` hard gate。
6. 报告中把该结果标为 `qualified_for_c8=false` 的 C8 负证据。

## 预期判读

如果 table-only content comparator 通过：

- W4 的 cache-content oracle 仍不能支持 C8；
- 当前 stale/corrupt/miss witness 只能说明 `cache_locality_view.bpf.c` 功能正确；
- 后续必须依赖真实 cache transition、release-level operation-weighted hit rate、
  update/stale window 或 table/update budget failure 才能支持 C8。

如果 table-only content comparator 失败：

- 仍不能立即升级 C8；
- 需要确认失败来自 table-only expressiveness，而不是 runner、map update、materialization
  或 policy load 问题；
- 还需要 release workload 和 budget gate 才能计入 C8。

## 实现结果

本次实现修改了：

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 参数化 W4 cache-content oracle 的 event、result level、policy name 和 policy
    family；
  - 保留 `--cache-content`；
  - 新增 `--cache-table-content`，通过 `table_redirect.bpf.c` 的 `exact_redirects`
    map 运行同一 content oracle；
  - summary row 记录 `table_baseline_current_oracle_pass` 和
    `content_equivalent_table_oracle`。
- `mk/kvm.mk`
  - 新增 `W4_CACHE_TABLE_CONTENT_JSON` 和 `W4_CACHE_TABLE_CONTENT_WORK_DIR`；
  - 新增 `kvm-w4-cache-table-content` 和 guest target；
  - 保存独立 `w4-cache-table-content.jsonl`、`w4-cache-table-content-inputs.sha256`
    和 `dmesg-w4-cache-table-content.log`。
- `Makefile`
  - 默认 `phase1` 加入 `kvm-w4-cache-table-content`；
  - `make help` 暴露新 target。
- `mk/report.mk`
  - 增加 W4 table-only content comparator 的存在性、input sha256、raw JSONL 和
    report hard gate；
  - 报告中新增 W4 cache table-only content counterfactual 表；
  - artifact/dmesg 列表包含新文件。

## 验证结果

- `make w1-oracle`
- `make kvm-w4-cache-table-content RUN_ID=20260615T-w4-cache-table-content-smoke-v1`
- `make -n report RUN_ID=20260615T-w4-cache-table-content-smoke-v1`
- `sha256sum -c results/phase1/20260615T-w4-cache-table-content-smoke-v1/w4-cache-table-content-inputs.sha256`

上述命令均通过。raw result 位于：

`results/phase1/20260615T-w4-cache-table-content-smoke-v1/w4-cache-table-content.jsonl`

关键字段：

- `event=w4-cache-table-content-summary`
- `result_level=kvm_cache_table_content_oracle`
- `policy=table_redirect`
- `policy_family=table_redirect.bpf.c`
- `branches=4`
- `pass=true`
- `failures=0`
- `table_baseline_current_oracle_pass=true`
- `content_equivalent_table_oracle=true`
- `qualified_for_c8=false`

逐 case 检查通过：

- 4 个 `attached_expected_match`；
- 3 个 `attached_forbidden_mismatch`；
- 4 个 `readdir_alias`；
- branch set 为 `verified_hit`、`stale_fallback`、`corrupt_reject` 和
  `miss_canonical`。

dmesg 关键词检查只命中 kernel command line 中的 `panic=30`，没有真实 BUG/Oops/Call
Trace/verifier failure。

## 判读

这个增量不支持 C8。它把 W4 cache-content oracle 从“只有 programmable policy content
oracle”推进到“同一 content oracle 下 table-only 也通过”。因此它是负证据：

- 当前 W4 stale/corrupt/miss content witness 仍可被 exact table 表达；
- W4 不能仅凭 cache-content oracle 声称需要 eBPF programmable path-resolution；
- 后续要支持 C8，仍需要 release-level operation-weighted cache hit rate、真实
  stale/corrupt transition、BuildKit cache-path trace、update/stale window，或同等
  table/update budget 下的明确失败。
