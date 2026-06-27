# W4 parent object-shape guard 和 sibling PASS 负例实现记录

日期：2026-06-15

## 动机

`2026-06-15-w4-parent-scoped-cache-policy-implementation.md` 记录的 parent-scoped
ccache PoC 已经能在 KVM 内跑通真实 Redis/nginx ccache hot compile，但它的 parent
wildcard 仍然太粗：只要同一 cache leaf parent 下的 component 通过少量 guard，就会被改写为
`component.local`。这种实现容易被审稿人解释为“一个目录级 suffix redirect table”，不足以说明
policy 有真实 workload 语义。

本步骤把 parent wildcard 收窄为 ccache object-shape policy，并加入同 parent `metadata.txt`
文件的 PASS 负例。目标不是宣称 C8 已成立，而是消除“粗 wildcard 会误伤明显非 ccache
object sibling”的直接漏洞。

## 代码路径

- `bpf/policies/cache_locality_view.bpf.c`
  - 新增 `CACHE_CCACHE_OBJECT_LEN = 32`。
  - 新增 `cache_name_is_ccache_object()`：只接受 31 字节 lower-alnum 前缀加最后一字节
    `M` 或 `R` 的 ccache object 名字。
  - parent lookup rule 在生成 `.local` redirect 前必须通过该 object-shape guard。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `W4_CCACHE_PARENT_SIBLING = "metadata.txt"`。
  - parent mode 在 attach 前把 `metadata.txt` 写入一个真实 cache leaf parent。
  - attach 后执行 `attached_parent_sibling_pass`，用真实 lookup/open 路径确认
    `metadata.txt` 没有被 parent policy 改写。

## 设计选择

- object-shape guard 仍然是 ccache-specific，不是通用 cache policy。它来自当前真实 ccache
  trace 中的 object component 形态：长度为 32，末尾为 `M` 或 `R`，前缀为 lower-alnum。
- sibling 负例选择 `metadata.txt`，因为它明显不满足 ccache object-shape；旧的粗 wildcard 会把它
  改成 `metadata.txt.local` 并导致 lookup 失败。这个负例不能代表所有 sibling 安全性。
- 负例放在 KVM policy attach window 内执行，失败会计入 `failures`，从而让
  `make kvm-w4-ccache-parent-compile` 失败。
- 没有增加 YAML/JSON/DSL policy 配置；policy 仍然是 `cache_locality_view.bpf.c` 中的 eBPF
  程序。

## 验证

本地构建：

- `make bpf`：通过。
- `make w1-oracle`：通过。

KVM verifier/load：

- `make kvm-policy-load RUN_ID=20260615T-w4-parent-shape-load`：通过。

KVM real ccache parent compile：

- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-poc`：通过。
- `make kvm-w4-ccache-parent-compile RUN_ID=20260615T-w4-parent-shape-hardgate`：通过，并在
  Makefile target 中显式 hard-check `attached_parent_sibling_pass`。

关键原始结果：

- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-shape-poc/w4-ccache-parent-compile-outputs.sha256`
- `results/phase1/20260615T-w4-parent-shape-poc/dmesg-w4-ccache-parent-compile.log`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile.jsonl`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-stats.txt`
- `results/phase1/20260615T-w4-parent-shape-hardgate/w4-ccache-parent-compile-outputs.sha256`
- `results/phase1/20260615T-w4-parent-shape-hardgate/dmesg-w4-ccache-parent-compile.log`

关键事件：

- `parent_sibling_prepare`: `pass=true`
- `attached_parent_sibling_pass`: `pass=true`
- `w4-ccache-parent-compile-summary`: `pass=true`, `failures=0`,
  `output_hash_match=true`, `policy_redirected_cache_objects=4`,
  `cache_leaf_parents=4`, `parent_rule_updates=4`, `exact_readdir_updates=4`,
  `table_equivalent_rule_updates=8`, `qualified_for_c8=false`
- `w4-ccache-parent-compile-stats`: `cache_miss=0`, `direct_cache_hit=2`,
  `local_storage_hit=2`, `local_storage_write=0`
- `w4-ccache-parent-compile-stats` 在 hardgate run 中还记录
  `parent_sibling_pass=true` 和 `parent_sibling_pass_count=1`

## 当前结论

这次修订证明 parent-scoped cache policy 不再只是“对 parent 下任意名字追加 `.local`”：它会先执行
ccache object-shape 判断，并且在一个真实 cache leaf parent 下让 `metadata.txt` 这个明显非
ccache object 的 sibling PASS。这个结果加强了 Phase 1 PoC 的真实性。

但它仍然不能计入 C8：样本仍只有 4 个 object，readdir 仍依赖 exact alias，total updates 仍是
4 条 parent lookup rule 加 4 条 exact readdir rule，没有 release-scale object set、same-run
table budget failure、operation-weighted redirect coverage、missing backing、stale/corrupt 或 update-window
证据。

## 后续风险

- 当前 object-shape guard 绑定当前 ccache 版本和 trace 形态。后续 release-scale workload 必须记录
  ccache 版本、object name 分布，并验证该 guard 是否覆盖真实对象。
- `metadata.txt` 只是一个明显非 object-shape 的 sibling 负例。后续还需要 valid-shape decoy、
  `metadata.txt.local` decoy、temp/lock/stats 文件路径、多 parent sibling PASS，以及
  missing/corrupt backing 的负例。
- 如果 readdir 继续依赖 exact alias，table-only baseline 仍可解释当前样本，不能支撑
  programmable path-resolution 的主 claim。
