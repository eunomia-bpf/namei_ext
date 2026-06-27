# W4 cache-content hardgate provenance 实现记录

日期：2026-06-17

## 背景

W4 cache-content oracle 和 cache-content table-only comparator 是 C8 负证据链中的
关键节点。它们分别证明 `cache_locality_view.bpf.c` 能用 `cache_rules` map-backed
state dispatch 影响普通 VFS open/read/readdir，也证明当前同一 manifest-derived
content oracle 仍可被 `table_redirect.bpf.c` exact redirects 表达。因此这些结果必须
保持清晰的执行完整性。

此前两个 guest target 都会写 input sha256 manifest 和 dmesg log，但没有在 guest 内
立即 `sha256sum -c`，也没有把 dmesg BUG/WARNING/Oops/panic/hung-task/blocked-task
pattern 作为 hard failure。这样会让 reviewer 质疑 cache-content comparator 的 provenance 低于
后续 W4 transition counterfactual 和 W2/W3 macrobench hardgate。

## 实现

本次只修改 Makefile-owned KVM control plane：

- `mk/kvm.mk`
  - `__phase1_guest_w4_cache_content` 在写入
    `w4-cache-content-inputs.sha256` 后运行 `sha256sum -c`。
  - `__phase1_guest_w4_cache_content` 在保存
    `dmesg-w4-cache-content.log` 后扫描 `BUG`、`WARNING`、`Oops`、
    `Kernel panic`、`panic:`、`hung task`、`INFO: task ... blocked for more than`
    和 `kernel BUG at`，非零即失败。
  - `__phase1_guest_w4_cache_table_content` 对
    `w4-cache-table-content-inputs.sha256` 增加同样的 `sha256sum -c`。
  - `__phase1_guest_w4_cache_table_content` 对
    `dmesg-w4-cache-table-content.log` 增加同样的 dmesg hard gate。

没有新增 shell 脚本，没有改变 JSON schema，也没有改变 C8 verdict。两个 target 仍然
只提供 Phase 1 cache-content correctness 和 table-only negative evidence。

## 设计选择

这些检查属于执行完整性，必须放在 guest target 内。ledger 和论文只能解释已经通过的
raw evidence，不能把 input hash 不可回读或 dmesg 有 kernel warning/oops/panic 的 run
解释成可用证据。

## 结论范围

该改动只提高 W4 cache-content 证据链的 fail-fast/provenance 质量。它不支持 C8。
当前 table-only content comparator 仍通过，所以 W4 cache-content oracle 仍是负证据：
需要真实 stale/corrupt transition、operation-weighted policy hit rate、BuildKit trace
或 table/update budget failure 才能改变 C8 verdict。

## 验证

静态检查：

```text
git diff --check -- mk/kvm.mk docs/tmp/2026-06-17-w4-cache-content-hardgate-provenance.md docs/paper/sections/05-evaluation.tex
make -C docs/paper check
```

均通过。

KVM smoke：

```text
make kvm-w4-cache-content \
  RUN_ID=20260617T-w4-cache-content-hardgate-smoke-v1

make kvm-w4-cache-table-content \
  RUN_ID=20260617T-w4-cache-table-content-hardgate-smoke-v1
```

两个 target 均通过。guest output 显示新加的 `sha256sum -c` 和 dmesg hard gate 均执行。
结果路径：

```text
results/phase1/20260617T-w4-cache-content-hardgate-smoke-v1/
results/phase1/20260617T-w4-cache-table-content-hardgate-smoke-v1/
```

读回 summary：

- cache-content oracle：`branches=4`、`pass=true`、`failures=0`、
  `qualified_for_c8=false`。
- table-content comparator：`branches=4`、`pass=true`、`failures=0`、
  `table_baseline_current_oracle_pass=true`、
  `content_equivalent_table_oracle=true`、`qualified_for_c8=false`。

两个 input manifests 均通过回读校验：

```text
results/phase1/20260617T-w4-cache-content-hardgate-smoke-v1/w4-cache-content-inputs.sha256
results/phase1/20260617T-w4-cache-table-content-hardgate-smoke-v1/w4-cache-table-content-inputs.sha256
```

两个 dmesg issue scan 均为 0。
