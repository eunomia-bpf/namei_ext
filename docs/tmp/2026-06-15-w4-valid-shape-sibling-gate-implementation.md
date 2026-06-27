# W4 合法形状 sibling PASS gate 实现记录

Last updated: 2026-06-15
Stage at update: execute / claim-gate
Source/command: `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-valid-sibling-structured-oracle`
Completeness: partial

## 动机

W4 parent-scoped ccache PoC 原本只证明了同一 cache leaf parent 下的
`metadata.txt` 不会被 parent wildcard rule 抢走。这个负例太弱，因为
`metadata.txt` 明显不满足 ccache object 文件名语法；如果 policy 只是“对 parent
下所有看起来像 ccache object 的名字都追加 `.local`”，那么一个真实存在、名字合法但
不是 cache witness 的 sibling 会被错误 redirect。这个错误会破坏 VFS pass-through
语义，也会削弱论文中关于可验证 policy 边界的说法。

本步骤的目标是加入一个更强的 KVM hard gate：在 parent rule 生效的同一个目录中创建
一个名字满足 ccache object 形状、但不属于 trace-derived witness 集合的真实 sibling，
并在 policy attach 后确认它仍由原 VFS 路径打开。

## 检查过的代码路径

- `bpf/policies/cache_locality_view.bpf.c`
  - `cache_lookup_parent_rule()` 原先只检查 parent rule state、ccache object 形状和
    `.local` suffix，未检查 component 是否属于 trace-derived witness。
  - `struct cache_rule` 已有 `expected_hash[4]` 和 `witness_count`，可以复用为
    bounded name witness，不需要新增 BPF map 或 ABI 字段。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `update_cache_parent_rule()` 原先只写 parent wildcard key 和 state。
  - `ccache_prepare_parent_sibling()` / `ccache_policy_expect_parent_sibling_pass()`
    已经覆盖 `metadata.txt` sibling PASS。
  - `run_ccache_policy_compile()` 的 `--ccache-parent-compile` 分支负责在 KVM guest 中
    加载 policy、更新 map、attach cgroup/namei_ext，并运行真实 Redis/nginx ccache hot
    compile。
- `mk/kvm.mk`
  - `__phase1_guest_w4_ccache_parent_compile` 是本 gate 的 owning Make target。
- `mk/report.mk`
  - `report` hard gate 和 Markdown report 需要识别新增 raw event，避免 report 只检查旧
    `metadata.txt` sibling。

## 设计选择

实现保持一个 eBPF policy 程序，不引入 YAML/JSON/DSL，也不新增 kernel ABI。

Parent wildcard rule 现在仍使用 `name_len=0` 的 `cache_rules` key 表示一个 ccache leaf
parent，但 redirect 条件收窄为：

1. rule state 必须是 `CACHE_STATE_VERIFIED_HIT`；
2. component 长度必须是 32 字节；
3. 前 31 字节必须是 lower alnum，最后一个字节必须是 `M` 或 `R`；
4. component 不能已经带 `.local` suffix；
5. component 名称 hash 必须匹配 parent rule 中最多 4 个 trace-derived bounded name
   witnesses 之一。

名称 witness 使用 64-bit FNV-1a 风格 hash。BPF 侧在 verifier 可见的固定上界循环内计算
component hash；用户态 oracle 用同一算法从 `entries.tsv` 的 visible component 填入
`expected_hash[0..3]`，并把 `witness_count` 设为实际数量。Phase 1 上限是 4 个同 parent
witness；超过上限时 fail-fast，而不是静默降级为宽 wildcard。

## 被拒绝的替代方案

- 只保留 object-shape guard：会误 redirect 合法形状但非 witness 的 sibling。
- 新增 parent-specific map：能表达 witness，但会扩大代码和 ABI 面；当前 `cache_rule`
  已有可复用 bounded witness 字段。
- 在 BPF 中检查 `.local` backing 是否存在：当前 namei_ext BPF ABI 不提供安全的文件系统
  lookup helper，不能在 policy 中做二次 VFS lookup。
- 给 parent rule 增加 exact lookup entries：会退化成普通 table redirect，无法继续测试
  parent-scoped policy 语义。

## 实现细节

- `cache_locality_view.bpf.c`
  - 新增 `cache_component_name_hash()` 和 `cache_parent_name_witness_ok()`。
  - `cache_lookup_parent_rule()` 在 object-shape guard 后调用 name witness guard；不匹配时
    返回 `BPF_NAMEI_EXT_PASS`。
- `namei_ext_w1_oracle.c`
  - `update_cache_parent_rule()` 现在要求 caller 提供 1 到 4 个 name witnesses。
  - parent-rule population 为每个 unique cache leaf parent 收集同 parent visible object 的
    component hash，超过 4 个直接失败。
  - 新增 `parent_valid_sibling_prepare` raw event：选择一个 32 字节合法 ccache object 名称，
    当前 run 为 `0000000000000000000000000000000M`，确保它不和同 parent entries 冲突，
    删除对应 `.local` backing，再创建真实 sibling 文件。
  - 新增 `parent_valid_sibling_backing_absent` raw event：在创建 sibling 前确认
    `0000000000000000000000000000000M.local` 不存在，避免 `attached_parent_valid_sibling_pass`
    只证明存在一个 backing。
  - 新增 `attached_parent_valid_sibling_pass` raw event：attach 后打开这个合法形状 sibling。
    Oracle 会读取文件并比较预写内容 `W4_CCACHE_PARENT_SIBLING_TEXT`；如果 policy 误
    redirect 到缺失的 `.local` backing，open 会失败，如果 redirect 到错误 backing，
    content 比较会失败。
- `mk/kvm.mk`
  - `__phase1_guest_w4_ccache_parent_compile` 现在 hard-check
    `parent_valid_sibling_prepare`、`parent_valid_sibling_backing_absent` 和
    `attached_parent_valid_sibling_pass` 的 pass count 大于 0。
- `mk/report.mk`
  - `report` hard gate 增加对 `parent_valid_sibling_prepare`、
    `parent_valid_sibling_backing_absent` 和 `attached_parent_valid_sibling_pass` 的 raw
    event 检查。
  - W4 parent-scoped report 表格区分 `Metadata PASS`、`Backing Absent` 和
    `Valid-Shape PASS`。

## 验证

已运行：

```text
make bpf w1-oracle
make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-valid-sibling-structured-oracle
```

结果：

- `results/phase1/20260615T-w4-valid-sibling-structured-oracle/w4-ccache-parent-compile.jsonl`
  中 `parent_valid_sibling_prepare` 为 `pass=true`。
- `parent_valid_sibling_backing_absent` 为 `pass=true`，证明对应 `.local` backing
  在 attach 前不存在。
- `attached_parent_sibling_pass` 为 `pass=true`。
- `attached_parent_valid_sibling_pass` 为 `pass=true`，并记录
  `content_oracle=true`、`content_oracle_kind=exact-text`、
  `expected_content_len=observed_content_len=37` 以及相同的
  `expected_content_fnv1a64`/`observed_content_fnv1a64`；path 为一个以
  `0000000000000000000000000000000M` 结尾的 ccache leaf path。这证明 attach
  后读到的是预写 sibling 内容，而不是错误 redirect 到其它 backing 后碰巧 open 成功。
- `w4-ccache-parent-compile-stats` 记录
  `valid_shape_sibling_prepare_count=1`、
  `valid_shape_sibling_backing_absent_count=1`、
  `valid_shape_sibling_content_oracle=true` 和
  `valid_shape_sibling_content_pass_count=1`。
- `w4-ccache-parent-compile-summary` 记录 `pass=true`、`failures=0`、
  `policy_redirected_cache_objects=4`、`cache_leaf_parents=4`、
  `parent_rule_updates=4`、`exact_readdir_updates=4`、
  `table_equivalent_rule_updates=8` 和 `qualified_for_c8=false`。
- `w4-ccache-parent-compile-stats` 记录 `direct_cache_hit=2`、
  `parent_sibling_pass=true` 和 `parent_sibling_pass_count=1`。
- `w4-ccache-parent-compile-inputs.sha256` 与
  `w4-ccache-parent-compile-outputs.sha256` 均通过 `sha256sum -c`。

## 剩余风险和后续工作

这个 gate 仍不能升级为 C8。原因是：

- 当前样本只有 4 个 cache objects 和 4 个 cache leaf parents；
- readdir alias 仍由 exact entries 表达；
- 只覆盖一个合法形状 non-witness sibling，不覆盖同 parent 多 sibling、锁文件、临时文件、
  metadata sidecar 或缺 backing 的 release 级分布；
- 没有真实 stale/corrupt transition、update window 或 stale window；
- table-only comparator 在当前 sampled witness 上仍通过 output oracle，因此当前证据是
  C8 的负面证据，而不是支持证据。

下一步如果要支撑 C8，需要在真实 BuildKit/Go/ccache release workload 中引入
operation-weighted hit rate、same-run table/update budget comparator、stale/corrupt
transition 和完整 sibling safety oracle。
