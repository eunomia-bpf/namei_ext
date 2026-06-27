# W4 Cache Content Oracle 对抗 review 和修订记录

## 背景

本记录对应 `make kvm-w4-cache-content` 的第一版实现 review。该 gate 的目标是证明
W4 cache-locality policy family 不只是 lookup/readdir path oracle，而能在修改内核
KVM guest 中让 cache-state 分支影响普通 VFS open/read/readdir。

## Review 结论

Subagent 对第一版实现给出两个 blocker：

- `kvm-w4-cache-content` 哈希了 ccache/BuildKit manifest，但 runner 没有读取
  `w4-cache-oracle-entries.tsv`，而是在 guest 中构造固定文件名。因此 provenance 链条
  断开，不能称为 manifest-bound cache content oracle。
- `cache_locality_view.bpf.c` 虽然定义了 `cache_rules` map，但第一版 gate 主要走
  literal fallback；`populate_policy_map()` 对 `POLICY_CACHE_LOCALITY` 直接返回。
  因此该 gate 没有证明 map-backed cache-state dispatch。

Review 还指出：文档可以把第一版称为 KVM attach-path literal content fixture，但不能把它
写成 W4 manifest-bound cache semantics、release-level W4 evidence 或 C1/C8 支持证据。

## 修订设计

本次修订选择补强实现，而不是只降级文档：

- `cache_locality_view.bpf.c` 的 lookup/readdir 改为 map-first：先查 `cache_rules`，
  map miss 才进入 literal fallback。
- `tests/w1_oracle/namei_ext_w1_oracle.c` 新增与 BPF policy 对齐的 `struct cache_rule`，
  并把 W4 branch 映射到 bounded cache state。
- `populate_policy_map()` 对 `POLICY_CACHE_LOCALITY` 不再跳过；它为每条 W4 TSV entry
  写入 lookup 和 readdir 两个 `cache_rules` map key。
- `run_cache_content_oracle()` 改为读取 `w4-cache-oracle-entries.tsv`，按
  `parent_relative` materialize workdir，并用 `original_backing_path` 生成
  `shadow_backing_component`。
- `mk/kvm.mk` 的 `kvm-w4-cache-content` 依赖改为 `workload-w4-oracle-entries`，guest 内
  逐行校验 TSV backing SHA256，并把 TSV 纳入 input hash manifest。
- `mk/report.mk` 现在要求 `w4-cache-content-inputs.sha256` 有 7 个精确输入，并硬检查
  `w4-cache-content-start`、`map_update` 和 `w4-cache-content-done`。

## 验证

已运行 targeted KVM gate：

```text
make kvm-w4-cache-content RUN_ID=20260614T-w4-cache-content-map
```

关键 raw result：

```text
results/phase1/20260614T-w4-cache-content-map/w4-cache-content.jsonl
results/phase1/20260614T-w4-cache-content-map/w4-cache-content-inputs.sha256
```

JSONL 计数：

```text
failing_cases=0
map_update=1
attached_expected_match=4
attached_forbidden_mismatch=3
readdir_alias=4
summary.failures=0
summary.qualified_for_c8=false
```

## 证据边界

修订后，该 gate 可以准确表述为：

```text
manifest-derived W4 entries 沿 cache_rules map-backed state dispatch，在修改内核 KVM
guest 中影响 ordinary VFS open/read/readdir。
```

它仍不能表述为：

```text
真实 ccache/BuildKit cache correctness、真实 compiler/go output hash、真实 cache
transition coverage、stale window、update writes 或 table/update budget 反事实已经通过。
```

因此 W4 仍然是 `functional_only`，不能计入 C1/C8。

## 第二轮复审

修订后再次请求 subagent 对抗 review。结论：

- Blocker：无。
- Major：无。
- Scoped verdict：可以接受为 Phase 1 W4 manifest-derived map-backed content oracle。

Subagent 核查点：

- `cache_locality_view.bpf.c` lookup/readdir 已经先调用 `apply_cache_rule()`，literal
  fallback 只在 map miss 或 map PASS 后运行，不再是 W4 content gate 的主要证据。
- `--cache-content` 已读取 W4 TSV、按 manifest materialize backing、解析 current
  cgroup id、填充 `cache_rules`，并 attach 当前 cgroup。
- `mk/kvm.mk` 和 `mk/report.mk` 已纳入 W4 TSV、7 个 input hash、`map_update=1`、
  start/done 和 case counts。
- 文档已把 claim 限定为 manifest-derived TSV + `cache_rules` map-backed KVM functional
  oracle，并明确不计入 C1/C8。

复审留下两个非阻塞 minor：

- hash witness 仍由用户态把 TSV SHA256 prefix 同时写入 `expected_hash[0]` 和
  `observed_hash[0]`，足够支撑 Phase 1 state-dispatch functional oracle，但不能声称真实
  content-hash mismatch checker。
- report 已经 hard-gate 关键事件。复审后又补充 gate `read_entries=1`、`materialize=1`
  和 `current_cgroup_id=1`，并用现有
  `RUN_ID=20260614T-w4-cache-content-map-phase1` raw results 重新运行 `make report`
  验证通过。
