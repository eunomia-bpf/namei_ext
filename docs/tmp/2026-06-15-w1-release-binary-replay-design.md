Last updated: 2026-06-15

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Stage at update: implementation planning
Source/command: audit of `mk/workload.mk`, `mk/kvm.mk`, `tests/w1_oracle/namei_ext_w1_oracle.c`, and `results/workloads/runs/20260615T-parent-key-poc/`
Completeness: complete for choosing the next W1 release-binary replay implementation step

# W1 Release Binary Replay 设计记录

## 动机

当前 W1 已有两个 KVM 证据：

- `kvm-w1-oracle`：对 trace-derived entries 做 per-entry lookup/readdir path oracle；
- `kvm-w1-build-replay`：在真实 Redis/nginx source tree 上做 `cc -E` preprocessing
  output compare。

这两个 gate 都证明 policy attach path 可运行，但还没有让真实 release binary 在 policy
alias 下重新构建并比较 output hash。下一步最小实现应补一个 KVM release-binary replay
witness：在 guest 中对 Redis/nginx 分别跑 baseline build 和 policy build，比较最终
binary hash，同时继续标记 C8 不合格，直到完整 alias set、poison/negative real hit、
operation-weighted hit rate 和 table/update budget counterfactual 也通过。

## 已检查现状

### Host build recipe

`mk/workload.mk` 已经定义真实 host build：

- Redis：`make -C <redis-src> -j$(JOBS) BUILD_TLS=no MALLOC=libc redis-server`
- nginx：`./configure --prefix=<prefix> --with-cc=cc --without-http_rewrite_module --without-http_gzip_module`
  后接 `make -C <nginx-src> -j$(JOBS)`

这些 target 生成：

- `results/workloads/runs/<run-id>/w1-redis-build/build.json`
- `results/workloads/runs/<run-id>/w1-nginx-build/build.json`
- 对应 `manifest.json` 和 `alias-manifest.json`

`20260615T-parent-key-poc` 的 host build output hash 已可审计：

- Redis host build binary SHA256:
  `57c5b7bce18d1db7d3ef3e5176d2fbbf7076749574906c76acf75246b53b3087`
- nginx host build binary SHA256:
  `157d4e22b3daa1236fb0505a867e43938da340c03d498bd5df55f289af0466d3`

### Existing KVM build replay

`mk/kvm.mk` 的 `kvm-w1-build-replay`：

- 复制 `$(REDIS_TRACE_SRC)` 和 `$(NGINX_TRACE_SRC)` 到 guest `/tmp` workdir；
- 在未 attach policy 时生成 baseline `.i`；
- materialize shadow aliases；
- attach `build_graph_view.bpf.c`；
- 生成 policy `.i` 并做 byte-for-byte 比较；
- 写 `w1-build-replay.jsonl` 和 `w1-build-replay-outputs.sha256`。

`tests/w1_oracle/namei_ext_w1_oracle.c` 已有可复用能力：

- `read_entries()` 读取 W1 TSV；
- `assign_build_replay_parent_dirs()` 将 entries 绑定到 guest runtime parent dirs；
- `populate_policy_map()` 使用 parent-aware key 填 map；
- `prepare_replay_aliases()` 把 visible component 复制到 shadow backing 并删除 visible；
- `run_child_capture()` 可以 exec `make` 或 `cc` 并捕获 stdout/stderr；
- `emit_build_replay_case()` 已有 conservative result fields，但语义是 preprocessing witness。

## 设计选择

### 选择 A：直接把现有 preprocessing gate 改成 release build gate

拒绝。这样会破坏已有 report gate 和历史证据边界。preprocessing witness 仍有价值，
应该保留为单独 target。

### 选择 B：新增 `kvm-w1-release-build-replay`

采用。新增 target 最小侵入：

- 不改变现有 `kvm-w1-build-replay`；
- 复用同一个 C runner，新增 `--release-build-replay` mode；
- 复用 W1 TSV、policy object、source manifests、alias manifests 和 parent-aware key；
- 生成独立 JSONL、input SHA256、output SHA256 和 dmesg；
- 初始实现可以先作为独立 target；一旦 KVM runner、hash gate 和字段边界都通过，
  再把它纳入 `make report` 的硬校验。后续实现已采用这一收敛路径，见
  `docs/tmp/2026-06-15-w1-release-binary-replay-implementation.md`。

### 源树选择

使用 `$(REDIS_TRACE_SRC)` 和 `$(NGINX_TRACE_SRC)` 作为输入，和 preprocessing gate 一致。
这些 tree 已经由真实 trace build 生成 necessary generated/configured files，例如 Redis
`src/release.h` 和 nginx `objs/ngx_auto_config.h`。新 runner 在 guest 中复制为两份：

- baseline source tree；
- policy source tree。

baseline tree 不 attach policy，直接 rebuild release binary。
policy tree 在 attach policy 前 materialize aliases，并通过 policy path 读取 visible
component。

### 如何让 build 真正执行

不能依赖已构建 tree 中的现有 binary。runner 应在 baseline/policy tree 中删除可重建
输出，再执行 build：

- Redis：删除 `src/redis-server` 和 source tree 下的 `*.o`；
- nginx：删除 `objs/nginx` 和 source tree 下的 `*.o`。

这样可以在不重新运行 nginx `configure`、不触发更多 generated-file create semantics 的前提下，
强制 compiler/linker 消费 source/header path。它比 preprocessing 更接近 release binary
oracle，但仍不是 “fresh configure from pristine tarball under policy”。

### Build commands

Redis baseline/policy command:

```text
make -C <redis-tree> -j1 BUILD_TLS=no MALLOC=libc redis-server
```

nginx baseline/policy command:

```text
make -C <nginx-tree> -j1
```

Phase 1 release replay 先使用 `-j1`，减少 parallel build nondeterminism 和调试面。
发布级性能实验可以后续按 committed config 提高并记录 `JOBS`。

policy run 使用 `PATH=<toolchain_dir>:...`，使 `cc` toolchain branch 能命中
same-parent redirect。external dependency branch 仍通过 `include_dir` 绑定，但完整 build
默认不会把该目录加入 compiler include path；因此 external dependency branch 不能由该
release replay 计为真实 hit，仍需要后续 operation-weighted trace/hit-rate gate。

## 输出语义

新增 JSONL 使用：

- `event="w1-release-build-replay"`；
- `result_level="kvm_policy_release_build_replay_witness"`；
- `run_environment="kvm"`；
- `policy_executed=true` 只用于 policy build 和 output compare rows；
- `kvm_validated=true`；
- `release_binary_hash_match=true` 用于 baseline/policy binary hash 相同；
- `release_output_hash_oracle=false` 和 `qualified_for_c8=false` 保持 false。

保持 false 的原因是该 gate 仍使用候选 alias set，不是完整 trace-derived alias set；
它也没有 poison/negative real hit、operation-weighted redirected hit rate 或 table/update
budget counterfactual。它可以证明“policy 下 release binary rebuild 没有改变 output”，
不能证明 W1 已经是 C1/C8 qualifying workload。

## 最小实现步骤

1. `mk/kvm.mk`
   - 新增变量 `W1_RELEASE_REPLAY_JSON`、`W1_RELEASE_REPLAY_RESULT_DIR`、
     `W1_RELEASE_REPLAY_WORK_DIR`。
   - 新增 target `kvm-w1-release-build-replay` 和 guest target
     `__phase1_guest_w1_release_build_replay`。
   - target 输入包括 W1 TSV、Redis/nginx manifests、alias manifests、
     `build_graph_view.bpf.c` source/object 和 runner source/binary。

2. `tests/w1_oracle/namei_ext_w1_oracle.c`
   - 新增 recursive `remove_suffix_under()` helper，用于删除 `*.o`。
   - 新增 release build runner：
     - 复制/使用 baseline and policy source dirs；
     - baseline 删除 build outputs 后运行 make；
     - policy 填 map、materialize aliases、attach policy、删除 build outputs 后运行 make；
     - 比较 `src/redis-server` 和 `objs/nginx`。
   - 新增 CLI mode `--release-build-replay`。

3. 文档
   - 新增本设计记录；
   - 实现后新增独立 implementation record；
   - 更新 research/evaluation docs，明确它是 release-binary witness，但仍非 C8。

## 风险

- Redis/nginx build tree 中已有 generated/configured files；本 gate 不是从 pristine
  tarball 开始的 full configure/release build。
- 删除 `*.o` 但保留 generated headers 是一个有意折中：可以强制编译/链接，又避免
  当前 same-parent redirect 在 create/write path 上遇到未实现语义。
- external dependency branch 不一定在 release rebuild 中命中；不能用该 gate 证明所有
  build-graph branch 都有真实 release hit。
- 若 binary hash 因路径、timestamp 或 build id 不稳定而不同，应保留 raw failure，不应
  降级为 warning。
