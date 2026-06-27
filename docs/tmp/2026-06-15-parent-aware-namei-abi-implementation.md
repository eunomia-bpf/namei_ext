Last updated: 2026-06-15
Stage at update: implementation / validation
Source/command: `make report RUN_ID=20260615T-parent-key-poc`
Completeness: complete for Phase 1 parent-aware ABI PoC; release-level W1/C8仍未完成

# Parent-Aware `namei_ext` ABI 实现记录

## 动机

W1 build-graph policy 原先的 map key 只包含 `event`、`cgroup_id` 和 component
name。真实 Redis/nginx 构建中，同名 component 可能出现在不同 parent directory；
component-only key 不能表达 parent-sensitive rule，也会把完整 release binary replay
需要的 rule identity 压扁成一个 redirect table。

本步骤实现一个最小 parent-aware ABI PoC：kernel 在 lookup 和 readdir event 的 BPF
ctx 中追加 parent object identity；map-backed policy 使用 parent `dev/ino` 作为 key
的一部分；W1 real-source preprocessing replay 在 guest 内按真实 parent directory
填充 map key。

## 修改范围

### Kernel UAPI

修改文件：

- `kernel/include/uapi/linux/bpf.h`
- `kernel/tools/include/uapi/linux/bpf.h`
- `bpf/include/namei_ext.h`

`struct bpf_namei_ext_ctx` 采用 append-only 扩展，在 `redirect_name` 之后追加：

```c
__u64 parent_dev;
__u64 parent_ino;
__u32 parent_generation;
__u32 parent_flags;
```

旧字段 offset 不变。ABI test 现在固定：

- `parent_dev` offset 160
- `parent_ino` offset 168
- `parent_generation` offset 176
- `parent_flags` offset 180
- ctx size 184

### Kernel ctx 填充

修改 `kernel/fs/namei_ext.c`：

- `namei_ext_init_ctx()` 新增 `const struct path *parent` 参数；
- lookup path 直接传入 `namei_ext_lookup()` 已有的 `parent`；
- readdir path 传入 `&namei_ctx->file->f_path`；
- helper 从 `d_backing_inode(parent->dentry)` 填充：
  `parent_dev = inode->i_sb->s_dev`、`parent_ino = inode->i_ino`、
  `parent_generation = inode->i_generation`。

这不改变 `PASS/REDIRECT` 动作，不改变 same-parent redirect 约束，也不让 BPF 持有
VFS object 指针。

### Verifier access

修改 `kernel/kernel/bpf/cgroup.c`：

- 允许 BPF 以只读方式访问 `parent_dev` 和 `parent_ino`，字段大小为 64 bit；
- 允许 BPF 以只读方式访问 `parent_generation` 和 `parent_flags`，字段大小为 32 bit；
- 写权限仍只限 `redirect_name_len` 和 `redirect_name`。

### Policy key

修改 `bpf/include/namei_ext_policy.h` 和
`tests/w1_oracle/namei_ext_w1_oracle.c`，将 map-backed policy key 扩展为：

```c
struct namei_ext_component_key {
	__u32 event;
	__u32 name_len;
	__u64 cgroup_id;
	__u64 parent_dev;
	__u64 parent_ino;
	__u8 name[BPF_NAMEI_EXT_NAME_MAX];
};
```

当前 key 没有使用 `parent_generation`。原因是 kernel ctx 可以读 inode generation，
但 userspace runner 需要在 map update 时构造同一个 key；普通 `stat()` 没有可移植
generation 字段。把 generation 放进 key 会让用户态无法可靠填充 map，反而制造 false
miss。Phase 1 先把 generation 暴露给 BPF 和 ABI test，作为后续 stable parent cookie、
mount identity 或 generation registry 的扩展点。

### W1 runner

修改 `tests/w1_oracle/namei_ext_w1_oracle.c`：

- `fill_key()` 现在接收 `parent_dir`，对该目录执行 `stat()`，写入 `st_dev/st_ino`；
- `update_rule()` 和 `update_cache_rule()` 都通过 parent-aware key 更新 map；
- synthetic path oracle 使用每个 entry 的临时 parent directory；
- W1 build replay 新增 `assign_build_replay_parent_dirs()`：
  - toolchain branch 使用 guest 中的 `toolchain_dir`；
  - external dependency branch 使用 guest 中的 `include_dir`；
  - Redis/nginx branch 使用 guest 中复制出来的真实 source root 和 manifest 的
    `parent_relative`；
- `run_build_replay()` 在 map population 前先为每条 entry 绑定 guest runtime parent
  directory。

这样 W1 KVM policy preprocessing replay 不再依赖 host manifest path 作为 key，而是在
guest 内用实际 parent object identity 填 map。

## 验证结果

本步骤使用同一个 run id：

```text
RUN_ID=20260615T-parent-key-poc
```

已通过的命令：

```text
make abi RUN_ID=20260615T-parent-key-poc
make bpf
make w1-oracle
make kvm-w1-oracle RUN_ID=20260615T-parent-key-poc
make kvm-w1-build-replay RUN_ID=20260615T-parent-key-poc
make kvm-w2-oracle kvm-w2-nginx-real kvm-w3-oracle kvm-w4-oracle kvm-w4-cache-content RUN_ID=20260615T-parent-key-poc
make kvm-smoke abi kvm-policy-load kvm-policy-semantic table-conformance kvm-functional kvm-bench docker-smoke RUN_ID=20260615T-parent-key-poc
make report RUN_ID=20260615T-parent-key-poc
```

关键 raw artifacts：

- `results/phase1/20260615T-parent-key-poc/summary.md`
- `results/phase1/20260615T-parent-key-poc/abi.jsonl`
- `results/phase1/20260615T-parent-key-poc/policy-load.jsonl`
- `results/phase1/20260615T-parent-key-poc/policy-semantic.jsonl`
- `results/phase1/20260615T-parent-key-poc/w1-oracle.jsonl`
- `results/phase1/20260615T-parent-key-poc/w1-build-replay.jsonl`
- `results/phase1/20260615T-parent-key-poc/w2-nginx-real.jsonl`
- `results/phase1/20260615T-parent-key-poc/w4-cache-content.jsonl`
- `results/phase1/20260615T-parent-key-poc/table-budget.jsonl`

`summary.md` 的 gate 摘要：

- guest smoke events: 2
- ABI failing cases: 0
- policy-load failing cases: 0
- policy-semantic failing cases: 0
- table-conformance failing cases: 0
- W1/W2/W3/W4 oracle summary failures: 0
- W1 KVM policy build replay failures: 0
- W2 nginx real-app summary failures: 0
- W4 cache content summary failures: 0
- table-budget failing accounting rows: 0
- table-budget C8-qualified rows: 0
- functional failing cases: 0
- benchmark failing operations: 0
- docker failing cases: 0
- dmesg warning/oops/panic lines: 0

W1 preprocessing replay 在 parent-aware key 下仍通过：

- Redis baseline/policy `.i` output SHA256:
  `c4fc64fce52917575d2e4c7d0735a45685f54be29f68303a730f69bfeb588422`
- nginx baseline/policy `.i` output SHA256:
  `dbb253e0d661fce0dabbd9b0ad2c42e349ed99277dc6f9168974a589e3048c5e`

这些结果证明 parent-aware ABI PoC 可以在修改后的 kernel/KVM attach path 中运行，
并且没有破坏现有 W1-W4 Phase 1 gates。

## 当前结论

本实现解决了 component-only map key 的一个核心 blocker：map-backed policy 现在可以
区分同一个 cgroup 内不同 parent directory 下的同名 component。它使 W1 完整
release-build replay 有了继续推进的 ABI 基础，也让 table-only baseline 可以使用同等
parent-aware key 做更公平反事实。

但是，本实现仍不能把 W1 或 C8 标为完成。当前结果仍是：

- W1 是 KVM policy preprocessing replay witness，不是完整 release binary build replay；
- W1 alias set 仍是候选 witness，不是完整 trace-derived alias set；
- poison/negative branch 还没有真实 workload hit；
- operation-weighted redirected hit rate 还没有发布级统计；
- table/update budget counterfactual 仍没有 release-level failure；
- `table-budget.jsonl` 中 `qualified_for_c8` 必须保持 `false`。

## 剩余风险和后续工作

- `parent_dev + parent_ino` 对普通 filesystem 足够做 Phase 1 per-run key，但不等于跨
  reboot、overlay 或 bind mount instance 的全局稳定 identity。
- 若后续 workload 需要区分同一 inode 的多个 mount instance，需要追加 mount identity
  或 kernel-provided parent cookie。
- 若后续需要使用 `parent_generation` 进入 key，必须提供 userspace 可验证的填充路径，
  或把 key 生成下沉到 kernel-side stable cookie。
- W1 下一步应实现完整 Redis/nginx release-build replay，并记录完整 binary output
  hash oracle；在此之前，论文和评估计划不能把 preprocessing witness 写成 release result。
