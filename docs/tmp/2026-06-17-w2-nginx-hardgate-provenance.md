# W2 nginx hardgate provenance 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-17

## 背景

W2 nginx fixture 是当前唯一通过 C2 storage/threshold slice 的 workload。此前
`kvm-w2-nginx-real`、`kvm-w2-nginx-macrobench` 和
`kvm-w2-nginx-baseline-macrobench` 都会写入 input sha256 manifest 和 dmesg log，
但 guest target 没有在写入后立即 hard-gate 这些证据。这样不会改变 raw row
correctness，但会让唯一正 slice 的 provenance 比 W1/W4 最近补强后的 gate 弱。

## 实现

本次只修改 Makefile-owned KVM control plane：

- `mk/kvm.mk`
  - `__phase1_guest_w2_nginx_real` 在写入
    `w2-nginx-real-inputs.sha256` 后运行 `sha256sum -c`。
  - `__phase1_guest_w2_nginx_real` 在保存
    `dmesg-w2-nginx-real.log` 后扫描 `BUG`、`WARNING`、`Oops`、
    `Kernel panic`、`panic:`、`hung task` 和 `kernel BUG at`，非零即失败。
  - `__phase1_guest_w2_nginx_macrobench` 对
    `w2-nginx-macrobench-inputs.sha256` 增加 `sha256sum -c`，并对
    `dmesg-w2-nginx-macrobench.log` 增加同样的 dmesg hard gate。
  - `__phase1_guest_w2_nginx_baseline_macrobench` 对
    `w2-nginx-baseline-macrobench-inputs.sha256` 增加 `sha256sum -c`，
    并对 `dmesg-w2-nginx-baseline-macrobench.log` 增加同样的 dmesg hard gate。

没有新增 shell 脚本，也没有改变 result root 或 JSON schema。失败仍由 Make target
直接暴露，不写 `skipped` 或 partial-success 字段。

## 设计选择

这些检查放在 guest target 内，而不是放在后处理 ledger 中，因为它们属于执行完整性：
输入哈希必须能在 guest 中回读，修改内核运行期间不能产生 kernel warning/oops/panic。
ledger 只能解释通过的 raw evidence，不能把一个有 dmesg failure 的 run 提升成可用证据。

## 结论范围

该改动只提高 W2 正 slice 的 hardgate 质量。它不把全局 C2 改成 supported，也不支持 C8。
W1、W3 和 W4 仍必须作为负结果处理，除非后续有新的 KVM release evidence 改变各自
storage/setup/update/materialization 或 table-only counterfactual verdict。

## 验证

静态检查：

```text
git diff --check -- mk/kvm.mk docs/tmp/2026-06-17-w2-nginx-hardgate-provenance.md docs/paper/sections/05-evaluation.tex
make -C docs/paper check
make -C docs/paper paper
```

均通过。`make -C docs/paper paper` 仍有既有 overfull/float warnings，但退出状态为 0，
输出 PDF 为 `.build/paper/main.pdf`。

KVM smoke：

```text
make kvm-w2-nginx-real \
  RUN_ID=20260617T-w2-nginx-real-hardgate-smoke-v1

make kvm-w2-nginx-macrobench \
  RUN_ID=20260617T-w2-nginx-macrobench-hardgate-smoke-v1 \
  W2_NGINX_MACROBENCH_SAMPLES=2

make kvm-w2-nginx-baseline-macrobench \
  RUN_ID=20260617T-w2-nginx-baseline-hardgate-smoke-v1 \
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=2
```

三个 target 均通过。guest output 显示新加的 `sha256sum -c` 和 dmesg hard gate 均执行。
结果路径：

```text
results/phase1/20260617T-w2-nginx-real-hardgate-smoke-v1/
results/phase1/20260617T-w2-nginx-macrobench-hardgate-smoke-v1/
results/phase1/20260617T-w2-nginx-baseline-hardgate-smoke-v1/
```

读回 summary：

- real health oracle：`w2-nginx-real-summary` 为 `pass=true`、`failures=0`。
- policy macrobench：`samples=2`、`setup_rows=2`、`update_rows=2`、
  `correctness_rows=2`、`pass=true`、`failures=0`、`policy_executed=true`、
  `kvm_validated=true`。
- baseline macrobench：`samples=2`、`baseline_count=5`、`setup_rows=10`、
  `update_rows=10`、`correctness_rows=10`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true`。

以下 input manifests 均通过本机回读校验：

```text
results/phase1/20260617T-w2-nginx-real-hardgate-smoke-v1/w2-nginx-real-inputs.sha256
results/phase1/20260617T-w2-nginx-macrobench-hardgate-smoke-v1/w2-nginx-macrobench-inputs.sha256
results/phase1/20260617T-w2-nginx-baseline-hardgate-smoke-v1/w2-nginx-baseline-macrobench-inputs.sha256
```
