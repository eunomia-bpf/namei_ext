# namei_ext dispatch/context 热路径成本调研

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Last updated: 2026-06-15
Stage at update: execute/gate
Source/command: `nl`/`rg` inspect `kernel/fs/namei_ext.c`, `kernel/kernel/bpf/cgroup.c`, `kernel/include/linux/bpf.h`, `kernel/include/linux/cgroup.h`, `kernel/include/linux/bpf-cgroup.h`, `bpf/policies/*.bpf.c`, `bpf/include/namei_ext_policy.h`, `bench/workloads/namei_ext_bench.c`
Completeness: complete for survey; no code change in this step

## 背景

Batch=64 release comparison 已证明 B2/B8 不再是 input-blocked，而是 threshold
negative：canonical batch=64 comparison 中 max policy/native p99 为 1.77x，
min policy/FUSE p99 speedup 为 1.33x，max pass-only/native p99 为 1.71x。
随后两轮 RCU-pass fastpath PoC 都被拒绝：它们降低 pass-only residual，但恶化
redirect policy 的 worst-case policy/native p99。

因此下一步不能继续沿 RCU-only fastpath 走，而要检查非 RCU 部分：ctx 构造、
cgroup BPF dispatch、BPF run context、policy map hot path，以及这些成本是否能用
最小、可上游接受的改动降低。

## 查看过的代码路径

### VFS/namei_ext ctx 构造

- `kernel/fs/namei_ext.c`
  - `namei_ext_init_ctx()` 每次 `memset(ctx, 0, sizeof(*ctx))`。
  - 每次填 `event`、`flags`、`name_len`、`name_hash`。
  - parent-aware ABI 启用后，每次从 parent dentry 取 backing inode，填
    `parent_dev`、`parent_ino`、`parent_generation`。
  - 每次复制最多 `BPF_NAMEI_EXT_NAME_MAX=64` 字节到 `ctx->name`。
  - lookup 和 readdir 都走同一个初始化路径。
- `kernel/include/uapi/linux/bpf.h`
  - 当前 `struct bpf_namei_ext_ctx` 大小为 184 字节。
  - `name` 和 `redirect_name` 各 64 字节，`redirect_name_len` 和 output buffer 必须
    预清零，否则 BPF 未写 output 时 kernel 可能读到旧值。

### cgroup BPF dispatch

- `kernel/kernel/bpf/cgroup.c`
  - `__cgroup_bpf_run_namei_ext()` 每次执行：
    - `memset(&run_ctx, 0, sizeof(run_ctx))`；
    - `rcu_read_lock_dont_migrate()`；
    - `task_dfl_cgroup(current)`；
    - `ctx->cgroup_id = cgroup_id(cgrp)`；
    - `rcu_dereference(cgrp->bpf.effective[CGROUP_NAMEI_EXT])`；
    - 如果 array 非空，设置 `bpf_cg_run_ctx`；
    - 逐个 `bpf_prog_run(prog, ctx)`，遇到 `REDIRECT` 或 invalid return 即停止。
  - `bpf_cg_run_ctx` 只有 `run_ctx`、`prog_item`、`retval` 三个字段，但不能直接移除：
    `namei_ext_func_proto()` 复用 `cgroup_common_func_proto()`，因此 BPF 程序理论上可以用
    cgroup local storage、`bpf_get_retval`/`bpf_set_retval` 等依赖 `current->bpf_ctx`
    的 helper。
- `kernel/include/linux/cgroup.h`
  - `task_dfl_cgroup(current)` 是读取当前 task css_set 的 default cgroup。
  - `cgroup_id(cgrp)` 读取 `cgrp->kn->id`。
- `kernel/include/linux/bpf-cgroup.h`
  - `namei_ext_enabled()` 只是全局 static key：
    `cgroup_bpf_enabled(CGROUP_NAMEI_EXT)`。
  - 只要系统内该 attach type 有程序，所有进入 namei_ext hook 的 task 都会过全局
    enabled 判断；真正 per-task/cgroup 是否有 program 要到 run 函数里看
    effective array。

### policy 和 benchmark

- `bpf/policies/pass_only.bpf.c`
  - 只返回 `PASS`，不读 `cgroup_id`、parent identity、name，也不写 redirect。
- `bpf/policies/redirect_alias.bpf.c`
  - 只按 `event` 和 component literal 判断，不读 `cgroup_id` 或 parent identity。
- `bpf/policies/table_redirect.bpf.c` 和主 policy helper
  - `namei_ext_component_key` 包含 `event`、`name_len`、`cgroup_id`、`parent_dev`、
    `parent_ino` 和 `name[64]`。
  - table/policy family 通过 `cgroup_id + parent identity + component` 做隔离和
    parent-scoped decision。
- `bench/workloads/namei_ext_bench.c`
  - `pass_only`、`table_redirect_empty`、`table_redirect_hit` 和 `policy` 都走真实
    `cgroup/namei_ext` attach path。
  - release comparison 的敏感 case 包括 `access_tool_redirect`、
    `build_tree_stat_walk` 和 `exec_tool_redirect`。

## 当前成本归因

当前 pass-only residual 不能解释为“只有 static branch”：

1. `namei_ext_enabled()` 的全局 static key；
2. 当前 hook placement 导致 RCU-walk 降级；
3. 184 字节 `bpf_namei_ext_ctx` 清零；
4. component name copy；
5. parent inode identity 读取；
6. `task_dfl_cgroup(current)`；
7. `cgroup_id(cgrp)`；
8. cgroup effective program array 读取；
9. `bpf_cg_run_ctx` 设置/reset；
10. BPF dispatch 和 program 执行；
11. 对 readdir，每个 dirent 重复上述路径。

RCU PoC 已证明第 2 项确实贡献一部分开销，但单独优化它会恶化 redirect path。因此后续
优化应把第 3-10 项作为主要对象，并保持 redirect policy 不能回退。

## 不能贸然做的优化

### 不能无条件删除 `bpf_cg_run_ctx`

`namei_ext_func_proto()` 当前复用 cgroup common helper 集。只要这些 helper 保持可用，
`bpf_get_local_storage` 需要 `run_ctx.prog_item`，`bpf_get_retval`/`bpf_set_retval`
需要 `run_ctx.retval`。因此一个“直接调用 `bpf_prog_run()`、不设置 run context”的
fastpath 会破坏已暴露 helper 语义，除非同步收窄 helper set，并更新 ABI/文档/测试。

### 不能懒填 `cgroup_id` 而不改 ABI

`cgroup_id` 是 direct ctx field，BPF 程序可以直接读。当前 table policy、cache
policy 和 workload loaders 都把 `cgroup_id` 作为 map key 的一部分。若 kernel 不填该
字段，会破坏现有 policy 隔离。只有在改成 helper、prog-aux read mask 或显式
policy capability flag 之后，才可能跳过 pass-only/redirect_alias 的 `cgroup_id`
填充。

### 不能只缩小 ctx 而不考虑 verifier/readability

`name`、`redirect_name`、parent identity 已经进入 UAPI 和 ABI tests。缩小或重排
ctx 会破坏 ABI。若要降低清零成本，必须保持现有 offset，并证明未写 output 仍为 0。

## 可行的下一轮 PoC 候选

### P1：ctx 初始化拆分，不改 UAPI

目标：减少每次 lookup 的无用写入，同时保持 ABI offset。

候选做法：

- 用显式字段初始化替代整块 `memset()`，只清零 output 字段和 padding：
  `redirect_name_len`、`reserved`、`redirect_name[64]`、parent fields。
- 对 parent identity 保持现状，不改变 policy semantics。
- 风险：编译器可能仍生成类似清零；必须用 KVM benchmark 验证，不能靠 object
  inspection 作为 Phase 1 证据。
- 成功标准：pass-only/native p99 下降，且 policy/native 不恶化；仍通过 ABI tests、
  policy semantic tests 和 batch=64 comparison。

### P2：namei_ext 专用 helper set / no-local-storage fastpath

目标：如果 `namei_ext` policy 不需要 cgroup local storage 和 retval helpers，则让
fastpath 避免 `bpf_cg_run_ctx` setup。

候选做法：

- 收窄 `namei_ext_func_proto()`：只保留当前 policies 真实需要的 helpers，例如
  map lookup 和 perf output；移除 cgroup local storage / retval helpers。
- 或引入 verifier-time flag：只有不使用 run-context helpers 的 program 才走
  no-run-ctx fastpath。
- 风险：这是 ABI/程序能力变化，不是纯性能 patch；需要设计文档、verifier tests、
  negative helper-load tests 和 KVM policy load gates。
- 成功标准：pass-only 和 table/policy p99 同时改善；helper rejection fail-fast；
  不破坏 existing policy family。

### P3：per-cgroup effective array 快速判空

目标：降低“global static key enabled 但当前 cgroup 无 program”的成本。

候选做法：

- 在 hook 前或 run 函数早期快速判当前 task cgroup effective array 是否为空。
- 风险：当前 benchmark attach 的就是当前 cgroup，因此这不能改善 pass-only/policy
  attached path，只能改善非目标 cgroup 的 collateral overhead。
- 成功标准：只能作为 C6/C7 collateral overhead evidence，不能解决当前 C3/C5 失败。

### P4：policy/map hot path 优化

目标：降低 table/policy variant 相对 native 的 p99。

候选做法：

- 对 `table_redirect` 的 key construction 做分支优化，避免总是复制 64 字节 name。
- 对 family policy 的 bounded loops 做 release instruction/count audit，减少无用
  branch checks。
- 风险：容易变成 benchmark-specific hardcode；必须保持四类 family 语义和 table
  counterfactual。
- 成功标准：改善 `access_tool_redirect` 和 `build_tree_stat_walk`，且 B12 policy
  family diversity 不退化。

## 建议执行顺序

1. 先做 P1 ctx 初始化拆分 PoC，因为它不改 ABI、helper set 或 attach semantics。
2. 若 P1 无效，再设计 P2 helper-set/no-run-ctx fastpath；该方向需要独立 ABI/Verifier
   文档，不能直接作为小性能补丁混入。
3. P3 只作为 collateral overhead/stress evidence，不作为当前 C3/C5 remediation。
4. P4 与 C8 互相影响，应在 policy-family table counterfactual 更稳定后做。

## 下一步验证要求

任何实现 PoC 都必须：

- 新增独立 `docs/tmp/YYYY-MM-DD-*.md` 实现记录；
- 先跑 `make kernel`；
- 至少跑 1-sample KVM smoke；
- 再跑 batch=64 internal KVM microbench、external baselines 和 comparison；
- 若 threshold 仍失败，保留负结果并更新 tracker、summary、claim verdict；
- 不把 host-only 或 object-file inspection 算作 Phase 1 validation。

## 当前结论

RCU-only fastpath 已被负结果拒绝。更可信的下一步是一个不改 ABI 的 ctx 初始化拆分
PoC；如果它不能同时改善 pass-only 和 redirect policy，则应考虑收窄 C3/C5，或启动
更重的 helper-set/no-run-ctx ABI 设计，而不是继续微调 RCU 逻辑。
