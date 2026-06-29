# KVM bench policy baseline variants 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: Phase 1 implementation / OSDI performance baseline plumbing
Source/command: `make bench`; `make bpf`; `make eval-osdi-performance-ledger RUN_ID=20260615T-eval-contract EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix`
Completeness: complete for runner plumbing; blocked for fresh KVM release evidence

## 动机

OSDI performance gate 已经把当前 `bench.jsonl` 正确降级为
`phase1_kvm_microbench_smoke`。但旧 KVM bench 只有 `baseline` 和 `policy`
两个 variant，无法区分：

- 不 attach policy 的 VFS 原生路径；
- attach 一个只返回 PASS 的 eBPF policy 后，static branch、BPF 调用和 attach
  剩余成本；
- attach 一个通用 exact-table policy 但 miss 的 map lookup 成本；
- attach 一个已填充 exact-table policy 的 map hit redirect 成本；
- 真正 redirect-alias policy 的功能路径成本。

如果这些 variant 不进入 raw `bench.jsonl`，后续 performance gate 只能持续报告
pass-only 和 table-redirect-hit baseline 缺失。这个实现步的目标是用最小代码量让
`make kvm-bench` 在修改内核 KVM guest 中一次性采集这些真实 eBPF attach variant。

## 调研和检查过的文件

- `bench/workloads/namei_ext_bench.c`：原 runner 只接受一个 policy object，先跑
  `baseline`，再 attach `redirect_alias.bpf.o` 跑 `policy`。
- `mk/kvm.mk`：`__phase1_guest_bench` 负责在 KVM guest 内挂载 bpffs/debugfs/cgroup2
  并调用 runner。
- `bpf/policies/pass_only.bpf.c`：真实 eBPF policy，唯一行为是返回 PASS。
- `bpf/policies/table_redirect.bpf.c`：真实 eBPF exact-table policy；空 map 情况下
  代表 table miss path。
- `mk/eval_osdi.mk`：performance ledger 从已有 `bench.jsonl` 读取实际出现的
  variant，并生成 missing baseline 列表。

## 实现内容

`bench/workloads/namei_ext_bench.c` 现在支持可选的 `PASS_ONLY_BPF_O` 和
`TABLE_REDIRECT_BPF_O` 参数，带 pass/table 参数时仍然使用第五个参数作为 cgroup
路径：

```text
namei_ext_bench RESULT_JSONL REDIRECT_POLICY_BPF_O SAMPLES ITERATIONS \
  [CGROUP [PASS_ONLY_BPF_O [TABLE_REDIRECT_BPF_O]]]
```

runner 顺序为：

1. 不 attach policy，输出 `baseline`。
2. attach `pass_only.bpf.o`，输出 `pass_only`，路径选择保持 lower-FS 原生行为。
3. attach `table_redirect.bpf.o`，输出 `table_redirect_empty`，路径选择保持 lower-FS
   原生行为；此时 map 为空，只测量 exact-table miss path，不代表 populated
   table-hit baseline。
4. attach `table_redirect.bpf.o`，填充 `exact_redirects`，输出
   `table_redirect_hit`。填充规则包括 root 目录下 `tool -> tool.real` lookup、
   `tool.real -> tool` readdir，以及每个 tree parent 下 `tool -> tool.real`
   lookup。
5. attach `redirect_alias.bpf.o`，输出 `policy`，路径选择使用 alias 并验证 lookup
   和 readdir redirect 行为。

每个 attach variant 都独立 attach/detach。attach 或 detach 失败会写
`bench_attach`/`bench_detach` failure row，并让 runner 返回失败，保持 fail-fast。

`mk/kvm.mk` 的 `__phase1_guest_bench` 现在在 guest 内检查三个 BPF object 均存在，并
把 pass-only 与 table-redirect object 传给 runner。`bench-start` row 也记录：

```json
{"policy_variants":["pass_only","table_redirect_empty","table_redirect_hit","policy"]}
```

`mk/eval_osdi.mk` 的 `eval-osdi-performance-ledger` 现在从 raw `bench.jsonl`
实际观察到的 variant 中识别：

- `has_pass_only_baseline`
- `has_table_redirect_empty_baseline`
- `has_table_redirect_hit_baseline`

只有当 raw bench row 中真的出现对应 variant 时，`missing_release_baselines` 才会移除
`pass_only` 或 `table_redirect_hit`。`table_redirect_empty` 会作为 miss-path overhead
证据记录，但不会被当成 populated table-hit release baseline。代码支持但尚未重跑 KVM
的 baseline 不能计入证据。

为降低用户态 bench 复制 policy map ABI struct 后发生漂移的风险，
`tests/abi/namei_ext_abi.c` 现在在 BPF header 模式下额外检查
`struct namei_ext_component_key` 和 `struct namei_ext_redirect_rule` 的 field offsets
和 size。`bpf/include/namei_ext_policy.h` 新增 `NAMEI_EXT_POLICY_LAYOUT_ONLY` guard，
让 ABI 测试可以只编译 layout，不引入 BPF helper stub warning。

## 拒绝的方案

- 不把 pass-only/table baseline 写成文档里的虚拟项。必须由 KVM guest 中真实 attach
  的 eBPF policy 产生 raw bench rows。
- 不把 `table_redirect.bpf.c` 预填 map 后冒充 redirect workload。这里的目标是
  baseline/miss-path 成本；redirect 功能路径仍由 `policy` variant 覆盖。
- 不在 collector 中计算 CI 或 p99。当前 runner 仍输出 aggregate timing；发布级
  distribution、tail latency 和 confidence interval 需要后续独立实现。
- 不引入 shell 脚本或新的控制面。入口仍是 `make kvm-bench` 和
  `make eval-osdi-performance-ledger`。

## 验证

本地编译通过：

```text
make bench
```

BPF object 构建检查通过：

```text
make bpf
```

Policy-map ABI layout 检查通过：

```text
make abi RUN_ID=20260615T-bench-variants-abi
```

用已有 Phase 1 full root 重新生成 performance ledger 通过：

```text
make eval-osdi-performance-ledger \
  RUN_ID=20260615T-eval-contract \
  EVAL_OSDI_PHASE1_RUN_ID=20260615T-full-phase1-gatefix
```

重新生成的 ledger 仍然正确报告旧 root 中只有：

```json
["baseline", "policy"]
```

并保持：

```json
{
  "has_pass_only_baseline": false,
  "has_table_redirect_empty_baseline": false,
  "has_table_redirect_hit_baseline": false,
  "missing_release_baselines": [
    "pass_only",
    "table_redirect_hit",
    "fuse_redirect",
    "copy_tree",
    "symlink_forest",
    "bind_mount",
    "overlayfs"
  ],
  "release_gate_pass": false
}
```

这说明 gate 没有把 runner 代码支持错当成已有实验结果。

输入哈希校验通过：

```text
sha256sum -c results/eval-osdi/paper/20260615T-eval-contract/b2-performance/performance-inputs.sha256
```

随后单独运行修改内核 KVM guest 中的 microbench：

```text
make kvm-bench RUN_ID=20260615T-bench-variants-smoke
```

raw result 位于：

```text
results/phase1/20260615T-bench-variants-smoke/bench.jsonl
```

该 standalone KVM bench run 观察到：

```json
{
  "variants": [
    "baseline",
    "pass_only",
    "policy",
    "table_redirect_empty",
    "table_redirect_hit"
  ],
  "rows": 35,
  "failures": 0,
  "table_redirect_hit_map_updates": 66
}
```

这证明新 runner plumbing 能在修改内核 KVM guest 中真实 attach pass-only、
empty-table、populated-table 和 redirect policy，并且 populated
`table_redirect_hit` 的 `exact_redirects` map update 成功。该 run 仍只是
standalone KVM microbench smoke，不是完整 `phase1` canonical root；因此
`eval-osdi-performance-ledger` 仍以 `20260615T-full-phase1-gatefix` 的旧
`bench.jsonl` 为准，不能把这些新 variant 计入当前 C2/C3/C5 结论。

## 剩余风险和后续工作

- 尚未重跑完整 `make phase1`，因此新的 pass-only/table-empty/table-hit variants 尚未进入
  canonical Phase 1 full evidence root。
- `20260615T-bench-variants-smoke` 只证明 KVM microbench plumbing 和功能 oracle 通过；
  仍缺 release repetition、tail distribution、CI、randomized order 和 system metrics。
- runner 仍然只输出 aggregate `elapsed_ns`，不能支持 p95/p99 或 CI。
- release performance 仍缺 FUSE、copy-tree、symlink-forest、bind mount 和 OverlayFS
  baselines。
- 需要后续实现 warmup、randomized order、repetition budget、系统指标采集，以及从 raw
  distribution 生成 report 的 Make target。

## 后续完整 root 验证

同日后续已把这些 variants 纳入完整 Phase 1 report hard gate，并重新运行：

```text
make phase1 RUN_ID=20260615T-full-phase1-bench-variants
```

新的 canonical root 为：

```text
results/phase1/20260615T-full-phase1-bench-variants/
```

该 root 的 `bench.jsonl` 与 `summary.md` 均确认：

- 5 个 variant：`baseline`、`pass_only`、`policy`、`table_redirect_empty`、
  `table_redirect_hit`；
- 35 个 bench row；
- 0 个 failing op；
- `table_redirect_hit` 写入 66 条 `exact_redirects` map rule；
- 4 个 policy attach 成功。

新的 performance ledger 为：

```text
results/eval-osdi/paper/20260615T-eval-contract-bench-variants/b2-performance/performance.jsonl
```

它确认 `pass_only`、`table_redirect_empty` 和 `table_redirect_hit` 已存在于完整
Phase 1 root 中，但 release gate 仍为 false，因为缺少 release-scale repetitions、
tail latency、confidence interval、随机顺序、系统指标和外部 filesystem baselines。
