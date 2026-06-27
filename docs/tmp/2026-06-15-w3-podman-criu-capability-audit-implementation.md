# W3 Podman/CRIU capability audit 实现记录

Last updated: 2026-06-15
Stage at update: execute/gate loop
Source/command: continue B12/C8 W3 real restore blocker investigation
Completeness: complete

## 动机

W3 的 C8 blocker 不是“Redis RDB replay 没跑通”，而是当前还没有真实 Podman/CRIU
checkpoint/restore run、restore trace、health oracle 和 0 mixed epoch checker。此前人工检查
发现当前 host 有 `podman`，但没有 `criu`，且 `podman checkpoint --help` 没暴露可用的
checkpoint 子命令。这个事实需要变成 Make-owned、可复现的 raw evidence，而不是只留在对话里。

## 设计约束

- 不把能力审计接入默认 `phase1`，否则当前缺 CRIU 的 host 会阻塞所有已有 smoke evidence。
- 不新增项目自有 shell 脚本。
- 所有控制流在 Makefile recipe 中。
- audit 失败必须返回非零，但在返回前写出 JSONL 和 stdout/stderr raw artifacts。
- audit 只是 host capability evidence，不是 KVM policy validation，也不计入 C8。

## 实现内容

修改 `mk/workload.mk`：

- 新增结果目录：
  `results/workloads/runs/<RUN_ID>/w3-podman-criu-capability/`
- 新增 target：
  `make workload-w3-podman-criu-capability`
- 使用 `FORCE` prerequisite，避免一次失败后因为 `capability.jsonl` 已存在而让
  后续 `make` 误判为成功。
- 生成：
  - `capability.jsonl`
  - `podman-version.stdout`
  - `podman-version.stderr`
  - `podman-checkpoint-help.stdout`
  - `podman-checkpoint-help.stderr`
  - `criu-version.stdout`
  - `criu-version.stderr`
- summary row 只有在以下条件全满足时 `pass=true`：
  - `podman` 存在；
  - `podman --version` 成功；
  - `podman checkpoint --help` 成功；
  - help 输出列出 checkpoint；
  - `criu` 存在；
  - `criu --version` 成功。

修改 `Makefile`：

- `make help` 暴露 `workload-w3-podman-criu-capability`。

## 判读

这个 target 预期在当前机器上失败，并且这种失败是有价值的：它证明当前环境不能声称已经完成
W3 real Podman/CRIU restore。后续如果安装 CRIU 并启用 Podman checkpoint support，应先让
该 target 通过，再实现 KVM 内的真实 restore target。

## 验证结果

- `make -n workload-w3-podman-criu-capability`
- `make workload-w3-podman-criu-capability RUN_ID=20260615T-w3-podman-criu-capability-audit-v1`
- `git diff --check`

dry-run 和 `git diff --check` 均通过。真实 audit 按预期返回非零，并保留 raw artifacts：

`results/workloads/runs/20260615T-w3-podman-criu-capability-audit-v1/w3-podman-criu-capability/`

关键 JSONL 字段：

- `podman_present=true`
- `podman_version_ok=true`
- `podman_checkpoint_help_ok=true`
- `podman_checkpoint_listed=false`
- `criu_present=false`
- `criu_version_ok=false`
- `pass=false`
- `qualified_for_c8=false`

`podman-version.stdout` 显示 `podman version 4.9.3`。`podman-checkpoint-help.stdout`
只显示通用 Podman command list，未列出 checkpoint command。`criu-version.stdout`
为空，因为当前 host 没有 `criu`。

因此当前 W3 real Podman/CRIU restore 仍然 blocked，不能计入 Phase 1 C8 支持。

随后重新运行同一 target，确认它不会因为失败后留下的 `capability.jsonl` 而被缓存为
成功：第二次运行仍返回非零，并重写 summary row。
