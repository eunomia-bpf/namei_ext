# W1 KVM Policy Preprocessing Replay Witness

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-14
Stage at update: Phase 1 implementation
Source/command: `make kvm-w1-build-replay RUN_ID=20260614T-w2-nginx-probes-phase1`
Completeness: partial

## 背景和动机

W1 build-graph family 的发布级目标是证明 `build_graph_view.bpf.c` 能在真实构建
路径中表达 generated/source/toolchain/deps precedence，并最终用 release binary output
hash 证明 policy path 与 baseline path 等价。此前已有三类证据：

- host source-build trace 和 trace-witness manifest，说明 Redis/nginx 真实构建会访问一组候选 alias；
- host build-output oracle，说明真实 host build 的 binary 路径和 SHA256 可审计；
- KVM path oracle，说明这些候选 entries 能在修改后的 kernel guest 中沿真实 attach path 执行 lookup/readdir。

这些证据仍不能证明 policy attach path 会影响真实源码构建过程。因此本步骤新增一个
KVM policy preprocessing replay witness：在 guest 内 attach `build_graph_view.bpf.c`，
对真实 Redis/nginx source file 运行 C preprocessor，并和未 attach policy 的 baseline
preprocessor output 做 byte-for-byte 比较。

这个 witness 只覆盖 preprocessing，不是完整 `make redis-server` 或 nginx release binary
replay，所以仍不能计入 C1/C8。它的作用是缩小 W1 从 synthetic per-entry path oracle 到
真实源码构建 replay 之间的缺口。

## 调研和代码路径

本步骤检查并修改了以下代码路径：

- `mk/kvm.mk`
  - 新增 `kvm-w1-build-replay` target；
  - 新增 guest-side `__phase1_guest_w1_build_replay`；
  - 在 guest 中复制 Redis/nginx source tree 到 `/tmp/namei-ext-w1-build-replay-$(RUN_ID)`；
  - 记录 `w1-build-replay-inputs.sha256` 和 `w1-build-replay-outputs.sha256`；
  - 捕获 `dmesg-w1-build-replay.log`；
  - 清理 guest 临时目录。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 `--build-replay` mode；
  - 新增 baseline preprocessing、policy preprocessing、alias materialization、toolchain alias、include fallback 和 output compare 逻辑；
  - 复用真实 `cgroup/namei_ext` attach path，加载 `build_graph_view.bpf.o` 并填充 redirect map；
  - 输出 `w1-build-replay.jsonl` raw rows。
- `mk/report.mk`
  - 新增 report hard gate，检查 input/output SHA256 清单、row 数、summary 字段、Redis/nginx baseline-policy hash equality；
  - 在 `summary.md` 中新增 W1 KVM Policy Build Replay Witness 小节。
- `Makefile`
  - 将 `kvm-w1-build-replay` 纳入 `phase1` 流程，并在 help 中暴露。

## 设计选择

### 为什么做 preprocessing replay

完整 release binary build replay 需要把更多 trace-derived alias、generated header、
toolchain selection、external dependency fallback、negative/poison oracle 和 build output
hash 全部接到同一个 KVM run 中。这个步骤的实现成本和调试面更大。

Preprocessing replay 是更小的中间 gate：

- 仍然运行在修改后的 kernel KVM guest 中；
- 仍然走 `cgroup/namei_ext` attach path；
- 使用真实 Redis/nginx source tree，而不是 synthetic source text；
- 产生可 byte-for-byte 比较的 deterministic output；
- 能证明 policy redirect 会影响真实源码解析路径。

因此它比 per-entry path oracle 强，但比 release binary replay 弱。

### 为什么不把它记为 release-level row

所有 `event=w1-build-replay` data rows 和 `w1-build-replay-summary` 都明确记录：

- `result_level=kvm_policy_build_replay_witness`
- `run_environment=kvm`
- `output_hash_oracle=false`
- `policy_replay_output_hash_oracle=true`
- `release_output_hash_oracle=false`
- `output_hash_oracle_scope=kvm_policy_preprocess`
- `qualified_for_c8=false`

原因是该 witness 只比较 `.i` preprocessor output，不比较最终 Redis/nginx binary output；
也没有覆盖完整 trace-derived alias set、undeclared poison、negative fallback、operation-weighted
redirected hit rate 或 table/update budget counterfactual。

### 为什么仍然用 Makefile

项目约束要求所有 orchestration 走 Makefile，不能引入 checked-in `.sh`。因此 guest
commands 继续由 `mk/kvm.mk` target 组织，runner binary 只负责测试逻辑和 raw JSONL 输出。
Docker/KVM/report 仍由 Make dependency graph 串起来。

## 实现细节

`kvm-w1-build-replay` 的执行流程：

1. 确认 W1 entries TSV、Redis/nginx manifests、alias manifests、policy source/object 和 runner source/binary 存在。
2. 复制真实 Redis/nginx source tree 到 guest 临时目录。
3. 写入 `w1-build-replay-inputs.sha256`，覆盖 entries、manifests、policy 和 runner。
4. 在未 attach policy 时，对 Redis `src/server.c` 和 nginx `src/core/nginx.c` 生成 baseline preprocessed output。
5. Materialize W1 alias backing：
   - source/generated/component aliases 复制到 shadow backing 后移除 visible component；
   - Redis `config.h` 和 `version.h` 准备为 policy 内置 redirect backing；
   - toolchain alias 准备 `cc -> cc.real -> /usr/bin/gcc`；
   - include fallback 准备 `.namei_ext.external.stdio.h`。
6. 加载并 attach `build_graph_view.bpf.o`。
7. 填充 W1 redirect map。
8. 在 policy attach window 中通过 alias path 生成 policy preprocessed output。
9. 比较 baseline 和 policy output，写入 raw JSONL。
10. Detach policy，写入 summary、output SHA256 和 dmesg。

该 preprocessing replay 不单独声称完整 toolchain branch proof。当前 toolchain alias
只保证 replay 环境中有可审计的 compiler path；toolchain/external-dep 分支的完整
release-level 证据仍需要 full alias set、真实 build replay 和 operation-weighted trace
hit rate。

## 验证结果

已运行：

```text
make w1-oracle
make kvm-w1-build-replay RUN_ID=20260614T-w2-nginx-probes-phase1
make kvm-w1-oracle RUN_ID=20260614T-w2-nginx-probes-phase1
make kvm-w2-oracle kvm-w2-nginx-real kvm-w3-oracle kvm-w4-oracle kvm-w4-cache-content RUN_ID=20260614T-w2-nginx-probes-phase1
make report RUN_ID=20260614T-w2-nginx-probes-phase1
```

关键 raw artifacts：

- `results/phase1/20260614T-w2-nginx-probes-phase1/w1-build-replay.jsonl`
- `results/phase1/20260614T-w2-nginx-probes-phase1/w1-build-replay-inputs.sha256`
- `results/phase1/20260614T-w2-nginx-probes-phase1/w1-build-replay-outputs.sha256`
- `results/phase1/20260614T-w2-nginx-probes-phase1/dmesg-w1-build-replay.log`

Output hashes：

- Redis baseline: `ebd59fd7d8977bda0dfcd91d6564032f07932e22568df9e2247b04dc8ac40d97`
- Redis policy: `ebd59fd7d8977bda0dfcd91d6564032f07932e22568df9e2247b04dc8ac40d97`
- nginx baseline: `e10e431117efe8f2a8610a9ba144e91fbdb080dedb5b48e559269094a5962c14`
- nginx policy: `e10e431117efe8f2a8610a9ba144e91fbdb080dedb5b48e559269094a5962c14`

`w1-build-replay-summary` 记录：

- `pass=true`
- `failures=0`
- `workloads=2`
- `entries=9`
- `policy_executed=true`
- `kvm_validated=true`
- `policy_replay_output_hash_oracle=true`
- `release_output_hash_oracle=false`
- `qualified_for_c8=false`

## 剩余风险和后续工作

这个步骤仍有以下 release blockers：

- 没有运行完整 Redis/nginx release binary build replay；
- 没有从完整 trace 自动生成 full alias set；
- 没有覆盖 undeclared poison 和 negative fallback 的真实 workload hit；
- 没有 operation-weighted redirected hit rate；
- 没有 table/update budget counterfactual；
- 当前 ABI 仍偏向 same-parent component redirect，真实 shared store mapping 还需要更完整的 target registry 或等价机制。

下一步应优先把 W1 从 preprocessing replay 推进到完整 release binary build replay，并让
report gate 继续保持 `qualified_for_c8=false`，直到 release binary output hash、
negative/poison oracle 和 table/update budget counterfactual 同时通过。
