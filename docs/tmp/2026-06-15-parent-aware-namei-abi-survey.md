Last updated: 2026-06-15

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

Stage at update: design / implementation planning
Source/command: manual audit with `rg` and `sed` over `kernel/fs/namei_ext.c`, `kernel/fs/namei.c`, `kernel/fs/readdir.c`, `kernel/include/linux/namei_ext.h`, `kernel/include/uapi/linux/bpf.h`, `kernel/kernel/bpf/cgroup.c`, `bpf/include/namei_ext.h`, and `tests/abi/namei_ext_abi.c`
Completeness: complete for choosing a Phase 1 parent-aware ABI direction; implementation PoC completed and recorded separately

# Parent-Aware `namei_ext` ABI 调研

## 动机

W1 build-graph policy 的 release-level blocker 是 parent/path context。当前 BPF policy key 只区分：

```text
event + cgroup_id + component name
```

这无法表达真实构建中的同名 component。例如 `config.h`、`version.h`、`stdio.h`、`nginx.conf` 这类名字可能出现在多个 parent directory 中；如果 policy 只按 component 匹配，就会把不同目录下的语义误合并。完整 release binary replay、operation-weighted hit rate 和 table/update counterfactual 都依赖更强的 rule identity。

本调研回答一个问题：能不能用最小、可上游解释的方式把 parent identity 暴露给 eBPF policy，同时保持 `namei_ext` 仍然是窄 VFS path-resolution extension，而不是 BPF filesystem。

## 已检查路径

### UAPI ctx

`kernel/include/uapi/linux/bpf.h` 当前定义：

```c
struct bpf_namei_ext_ctx {
	__u32 event;
	__u32 flags;
	__u32 name_len;
	__u32 name_hash;
	__u64 cgroup_id;
	__u8 name[BPF_NAMEI_EXT_NAME_MAX];
	__u32 redirect_name_len;
	__u32 reserved;
	__u8 redirect_name[BPF_NAMEI_EXT_NAME_MAX];
};
```

`bpf/include/namei_ext.h` 是 BPF-local mirror。`tests/abi/namei_ext_abi.c` 当前固定验证 offset 和 size：

- `event` offset 0
- `flags` offset 4
- `name_len` offset 8
- `name_hash` offset 12
- `cgroup_id` offset 16
- `name` offset 24
- `redirect_name_len` offset 88
- `reserved` offset 92
- `redirect_name` offset 96
- ctx size 160

因此最小 ABI 扩展不能随意移动已有字段。若要降低破坏面，应采用 append-only 字段，让旧字段 offset 保持不变，只更新 size gate 和新增字段 gate。

### BPF verifier access

`kernel/kernel/bpf/cgroup.c` 中 `namei_ext_is_valid_access()` 只允许：

- BPF 读 `event`、`flags`、`name_len`、`name_hash`、`cgroup_id`、`redirect_name_len`、`reserved`；
- BPF 按 byte 读 `name` 和 `redirect_name`；
- BPF 写 `redirect_name_len` 和 `redirect_name`；
- 不允许写其他字段。

任何新增 parent identity 字段都必须加入 read-only access allowlist，并且不能允许 BPF 写入。

### lookup 调用点

`kernel/fs/namei.c` 在 `walk_component()` 和 `open_last_lookups()` 中调用：

```c
namei_ext_lookup(&nd->path, &nd->last, NAMEI_EXT_LOOKUP, nd->flags, &redirect);
```

这里的 `nd->path` 是当前 parent path。也就是说，内核在构造 BPF ctx 时已经持有 parent `struct path`，不需要额外路径解析，也不需要 BPF 访问 dentry/inode 指针。

`namei_ext_lookup()` 在 `kernel/fs/namei_ext.c` 中接收：

```c
int namei_ext_lookup(const struct path *parent, const struct qstr *name,
		     u32 event, u32 lookup_flags,
		     struct namei_ext_redirect *redirect)
```

因此 lookup event 可以直接从 `parent->dentry->d_inode` 和 `parent->dentry->d_inode->i_sb` 取 parent object identity。

### readdir 调用点

`kernel/fs/readdir.c` 在 `iterate_dir()` 中调用：

```c
namei_ext_iterate_dir(file, ctx, file->f_op->iterate_shared);
```

`kernel/fs/namei_ext.c` 的 wrapper 把 `file` 保存到 `struct namei_ext_dir_context`。`namei_ext_filldir()` 对每个 lower entry 调用 BPF policy 时可以访问：

```c
namei_ctx->file->f_path.dentry
```

这就是 readdir event 的 parent directory。lookup 和 readdir 可以使用同一个 parent identity 生成规则，从而保持 “lookup 能看到的 alias” 和 “readdir 列出的 alias” 共享 key 语义。

### redirect 语义

当前 `namei_ext_redirect_valid()` 只允许同父目录 component redirect：

- redirect name 非空；
- 长度不超过 `BPF_NAMEI_EXT_NAME_MAX`；
- 不能是 `.` 或 `..`；
- 不能包含 `/` 或 NUL。

`namei_ext_fill_redirect()` 使用原 parent dentry 计算 redirect hash：

```c
redirect->hash = full_name_hash(parent->dentry, redirect->name, redirect->len);
```

因此 parent-aware key 不改变 Phase 1 same-parent redirect 语义，只让 policy 能按 parent 决定是否 redirect。

## 可选设计

### 选项 A：暴露 parent path string

把完整 parent path 或 bounded prefix 暴露给 BPF。

拒绝理由：

- 需要路径字符串构造，开销和锁语义复杂；
- path string 不稳定，受 mount namespace、chroot、rename 影响；
- verifier 需要处理可变长字符串；
- 容易把 `namei_ext` 推向 path rewrite system，而不是 VFS object-aware extension。

### 选项 B：暴露 dentry/inode 指针或 kptr

把 parent dentry 或 inode 指针暴露给 BPF。

拒绝理由：

- lifetime、RCU、refcount 和 verifier 模型复杂；
- 指针值不是可持久化 rule key；
- 上游接受风险高；
- policy 可能被诱导依赖内核对象布局。

### 选项 C：使用用户态 parent class ID

loader/materializer 维护 parent directory 到 `parent_class_id` 的映射，再把 class id 写进 BPF map。

优点：

- policy key 小；
- 可以隐藏 inode/dev 细节；
- 对跨机器或跨 run 的 reproducibility 更友好。

缺点：

- kernel 在 lookup/readdir 时仍需要知道当前 parent 属于哪个 class；
- 如果 class lookup 也要在内核中做，就需要 kernel registry；
- 如果只在用户态做，BPF ctx 无法获得当前 parent class；
- Phase 1 会引入额外 registry ABI，代码量和调试面都更大。

### 选项 D：append-only parent object identity

在 `struct bpf_namei_ext_ctx` 末尾追加只读字段：

```c
__u64 parent_dev;
__u64 parent_ino;
__u32 parent_generation;
__u32 parent_flags;
```

生成规则：

- 若 parent dentry/inode 存在：
  - `parent_dev = inode->i_sb->s_dev`
  - `parent_ino = inode->i_ino`
  - `parent_generation = inode->i_generation`
  - `parent_flags = 0`，保留给后续标记，例如 generation unavailable、mount-id included、synthetic。
- 若 parent 无 inode，则填 0，并由 policy fail/pass 自行决定。

优点：

- 不暴露对象指针；
- 不构造 path string；
- lookup 和 readdir 都已有 parent object；
- append-only 可以保持已有 ctx field offsets；
- policy 可以把 key 从 component-only 扩展为 `(event, cgroup_id, parent_dev, parent_ino, name)`；ctx 仍暴露 `parent_generation` 作为后续 collision hardening 字段，但当前 map key 不依赖它；
- table baseline 也可以使用相同 key，便于公平 counterfactual。

缺点：

- `i_generation` 并非所有 filesystem 都可靠非零，且普通用户态 `stat()` 不能可移植地读取它来填充 BPF map key；
- `s_dev + i_ino` 在极端情况下可能跨 filesystem 或 overlay 层有语义差异；
- bind mount 下同一 object 会得到同一 parent identity，这通常合理，但如果 use case 需要区分 mount instance，后续还要追加 mount identity；
- UAPI size 会变化，需要同步 kernel/tools UAPI、BPF-local header、ABI tests、policy key 和 userspace map population。

## 推荐设计

推荐 Phase 1 采用选项 D：append-only parent object identity。

理由：

1. 代码量最小。只需修改 `bpf_namei_ext_ctx`、ctx init helper、verifier access、BPF-local header、ABI tests 和 policy key。
2. 不改变 `PASS/REDIRECT` 动作集，不引入 `DENY`、`HIDE`、path string rewrite 或 target registry。
3. 不改变 same-parent redirect 安全边界。kernel 仍负责 `.`、`..`、slash、NUL 和 `LOOKUP_CREATE` rejection。
4. 直接解除 W1/W2/W3/W4 中大多数同名 component collision blocker；`parent_generation` 和 mount identity 仍保留为后续更强 collision audit 的扩展点。
5. 能自然支持 table-only baseline 的同等 key，使 C8 反事实更公平。

## 最小实现计划

### Step 1: UAPI append-only 扩展

修改：

- `kernel/include/uapi/linux/bpf.h`
- `kernel/tools/include/uapi/linux/bpf.h`
- `bpf/include/namei_ext.h`

新增字段放在 `redirect_name` 之后，避免改变已有 offset：

```c
__u64 parent_dev;
__u64 parent_ino;
__u32 parent_generation;
__u32 parent_flags;
```

### Step 2: kernel ctx 填充

修改 `kernel/fs/namei_ext.c`：

- 将 `namei_ext_init_ctx()` 参数从 `const struct qstr *name` 扩展为 `const struct path *parent, const struct qstr *name`；
- lookup path 传入 `parent`；
- readdir path 传入 `&namei_ctx->file->f_path`；
- helper 内从 parent inode 填充字段。

### Step 3: verifier read-only 访问

修改 `kernel/kernel/bpf/cgroup.c`：

- 允许读 `parent_dev`、`parent_ino` 作为 64-bit fields；
- 允许读 `parent_generation`、`parent_flags` 作为 32-bit fields；
- 不允许 BPF 写入这些字段。

### Step 4: ABI tests

修改 `tests/abi/namei_ext_abi.c`：

- 保持旧字段 offset assertions 不变；
- 新增 parent field offset assertions；
- ctx size 从 160 更新为 184；
- 输出 JSON 增加 parent offset/size 字段。

### Step 5: BPF policy key

修改 `bpf/include/namei_ext_policy.h`：

- 新增 parent-aware key struct，或扩展 `struct namei_ext_component_key`；
- 推荐直接扩展现有 key，以便所有 map-backed policy family 共享 parent identity。
  当前 PoC key 使用 `parent_dev` 和 `parent_ino`，不使用 `parent_generation`：
  kernel ctx 会填 `parent_generation`，但 W1/W4 userspace runner 需要用 `stat()`
  在 guest 中预先填 map key，普通 `stat()` 没有可移植 inode generation 字段。
  因此 Phase 1 先把 generation 作为只读 ctx 字段和后续 hardening hook 保留，而不把它
  放进当前 map key。

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

### Step 6: userspace map population

修改 `tests/w1_oracle/namei_ext_w1_oracle.c` 中的 map update key builder：

- synthetic directory path oracle：在创建 parent directory 后用 `stat()` 读取 dev/ino；
- real source replay：对 manifest 中 parent-relative directory 做 `stat()`，用当前 guest 中的 dev/ino 写 key；
- lookup/readdir 的 map-backed entries 才依赖 parent-aware key，hard-coded literal branch 可保留为 branch witness，但不能作为 release-level 主证据。

### Step 7: KVM gate

新增或扩展 KVM oracle：

- 同一个 visible component name 在两个不同 parent directory 下映射到不同 backing；
- attach 后 lookup/readdir 必须按 parent 区分；
- table baseline、build-graph policy 和 cache-locality map-backed policy 都用同一
  parent-aware key；
- report gate 检查 parent collision case 的 raw rows。

## 不在本步骤做的事

- 不支持 cross-directory target registry；
- 不支持 path string rewrite；
- 不支持 multiple redirect actions；
- 不支持 create/unlink/rename；
- 不支持 hide/deny；
- 不暴露 dentry、inode、mount pointer；
- 不把 `namei_ext` 变成 BPF filesystem。

## 风险和缓解

- `i_generation` 可能为 0，且用户态 map population 不可移植：当前 key 不使用
  generation；后续若需要更强 identity，应实现 kernel-provided stable parent cookie
  或显式 mount/generation registry，而不是在 userspace 猜测。
- `s_dev + i_ino` 不是跨 reboot 稳定 ID：Phase 1 policy maps 是 per-run loader 填充，不要求跨 reboot 持久。
- overlay/bind mount 语义：Phase 1 先按 lower VFS object identity 处理；需要 mount-instance 区分时再追加 mount id。
- ABI size 变化：使用 append-only，旧字段 offset 不变；ABI test 明确记录新 size。
- verifier access：新增字段 read-only，写入仍 hard fail。

## 当前决策

已完成一个小型 kernel patch，使 ctx 带 append-only parent identity，并让
map-backed policy key 使用 `parent_dev` 和 `parent_ino`。对应实现记录是
`docs/tmp/2026-06-15-parent-aware-namei-abi-implementation.md`。

这一步已经让 W1 KVM path oracle 和 W1 KVM policy preprocessing replay witness
可以在真实 guest parent directory 上填充 map key。它仍不是完整 release-build replay；
W1 要进入 C1/C8 还必须继续补完整 release binary build replay、真实 poison/negative
workload hit、operation-weighted redirected hit rate、table/update budget
counterfactual，以及必要时的 generation/mount collision audit。
