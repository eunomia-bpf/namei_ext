最后更新：2026-06-15
更新阶段：Phase 1 documentation/report hardening
来源：独立 subagent 对 W1 release replay 与 branch-probe claim 的对抗 review
完成度：已修复 review 指出的 claim-to-evidence 一致性问题；不改变 C1/C8 qualification

# W1 Branch-Probe Review 修复记录

## 动机

独立 review 没有发现当前实现把 KVM branch probes 错写成 release-level natural
workload hit，也没有发现 W1 release/branch witness 被计入 C8。但 review 指出两个
必须修复的问题：

- W1 Redis/nginx evidence 文档已经说 KVM release-binary replay 通过，但 oracle
  要求和 raw results 仍保留 `TBD`，没有列出 release replay JSONL 和 output hash
  manifest。
- W1 trace-line 数字跨文档混用多个 run，论文表没有绑定 raw run id，容易导致 B1/B3
  证据不可追溯。

## 修改内容

- `workload/w1-redis-build/evidence.md`
  - 把当前 W1 Redis evidence 统一到 run id `20260615T-parent-key-poc`。
  - 将 trace line、candidate hit rate、manifest path 和 KVM path oracle path 指向同一
    canonical run。
  - 补充 KVM release-binary replay witness 的 Redis normalized binary hash：
    `65c8f5155d78a1a04ebb937cf7c85483b8320e1444686a691694c46e83f2de8b`。
  - 补充 raw artifacts：
    `w1-release-build-replay.jsonl` 和
    `w1-release-build-replay-outputs.sha256`。

- `workload/w1-nginx-build/evidence.md`
  - 把当前 W1 nginx evidence 统一到 run id `20260615T-parent-key-poc`。
  - 将 trace line、candidate hit rate、manifest path 和 KVM path oracle path 指向同一
    canonical run。
  - 补充 KVM release-binary replay witness 的 nginx normalized binary hash：
    `f9e214c23512996723d8409b0d0eda40070c135fc28f25d6f207ea85b4974544`。
  - 补充 raw artifacts：
    `w1-release-build-replay.jsonl` 和
    `w1-release-build-replay-outputs.sha256`。

- `docs/paper/sections/05-evaluation.tex`
  - workload 状态表同步 W1 release replay 和 branch probes。
  - W1 当前证据表绑定 canonical run
    `results/workloads/runs/20260615T-parent-key-poc/`。
  - W1 trace line 更新为 Redis `1,224,839`、nginx `1,796,476`。

- `docs/paper/sections/04-implementation.tex`、`docs/experiment-plans/osdi-evaluation.md`
  和 `docs/research_plan.md`
  - 当前 W1 evidence 统一到 `20260615T-parent-key-poc`。
  - preprocessing replay hash 更新为当前 run 的 raw output hash：
    Redis `c4fc64fce52917575d2e4c7d0735a45685f54be29f68303a730f69bfeb588422`，
    nginx `dbb253e0d661fce0dabbd9b0ad2c42e349ed99277dc6f9168974a589e3048c5e`。

- `mk/kvm.mk` 和 `mk/report.mk`
  - `w1-branch-probes-hit-rate` row 拆分记录
    `artifact_environment=kvm` 和 `metric_basis_environment=host`。
  - report gate 强制检查这两个字段，防止把 host trace candidate hit rate 误读成 KVM
    release-level operation-weighted metric。

## 保持不变的边界

这些修复只提升 claim-to-evidence 可追溯性，不把 W1 推进到 C1/C8。W1 仍然缺：

- 完整 trace-derived alias set；
- release-level poison/negative natural workload hit；
- release-level operation-weighted redirected hit rate；
- 同等 table/update budget 下 table-only baseline 失败的 counterfactual。

因此 release-binary replay 和 branch probes 仍只是 Phase 1 KVM witness，所有相关
raw rows 仍必须记录 `qualified_for_c8=false`。
