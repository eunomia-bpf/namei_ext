# Source-to-signal ledger review 修订记录

日期：2026-06-14
阶段：Phase 1 文档复审修订
类型：实现/文档记录

## 动机

独立 subagent 对 `docs/tmp/2026-06-14-real-workload-source-signal-ledger.md`、
OSDI evaluation plan、paper sections 和 workload evidence 做了只读对抗 review。结论是：
当前文档没有明显把 `functional_only` 证据 overclaim 成 C1/C8 或性能结果，但仍有几处
cross-section drift 会降低 reviewer 对证据链的信任。

## Review 指出的问题

1. W1 Redis/nginx `evidence.md` 仍写 KVM policy oracle 未验证，但 research plan 和
   evaluation plan 已经记录 W1 KVM path oracle 通过。
2. W2 implementation 段落容易被误读为 cert/secret/poison 也被 nginx worker 消费。
3. `docs/paper/evaluation.md` 把 endpoint health 描述成对 `127.0.0.1:80` 的 redirected
   endpoint health，端口语义不够精确；实际是 nginx listener 接受 health request，再把
   upstream 请求代理到 runner 的 `127.0.0.1:18080`。
4. OSDI evaluation plan 的 `5x` setup、`1.5x` kernel p99 和 `2x` FUSE p99 缺少阈值依据。
5. Redis Makefile 链接使用浮动 `unstable` 分支，而 workload 已经固定到 Redis `7.2.14`
   commit。
6. `03-design.tex` 的 policy family 状态表低估了 W2 nginx health 和 W4 cache content
   oracle。
7. `02-motivation.tex` 对 static redirect table 的语气偏强，应该明确最终仍要由
   table-only 反事实验证。

## 修订

- 更新 `workload/w1-redis-build/evidence.md` 和
  `workload/w1-nginx-build/evidence.md`：状态改为
  `source-build-trace` + `functional_only_kvm_path_oracle`，新增 W1 KVM path oracle
  raw result 和 input hash manifest，保留完整 output oracle 与 C8 blocker。
- 更新 `docs/paper/sections/04-implementation.tex`：明确 nginx app oracle 只覆盖
  config alias、include endpoint alias、worker start 和一次 HTTP health path；
  fake cert、fake secret 和 poison alias 只由 direct VFS `open/read` probes 覆盖。
- 更新 `docs/paper/evaluation.md`：修正 endpoint health 端口语义。
- 更新 `docs/experiment-plans/osdi-evaluation.md`：为 `5x`、`1.5x` 和 `2x` 默认阈值
  增加 reviewer-facing rationale，并把 Redis Makefile 链接固定到 commit。
- 更新 `docs/paper/evaluation.md` 和 W1 evidence：把 Redis Makefile 链接固定到
  `f2262eccb855eadd1afb0c457ea583ef9d5400b5`。
- 更新 `docs/paper/sections/03-design.tex`：同步 policy family 当前状态，记录 W2 nginx
  health/direct probes 和 W4 cache content oracle。
- 更新 `docs/paper/sections/02-motivation.tex`：把“不是静态 redirect table”改为“必须用
  同等 budget 的 table-only 反事实验证”。

## 验证计划

本次修订完成后需要重新运行：

- `make -C docs/paper paper`
- `make -C docs/paper check`
- `git diff --check`
- 最终 LaTeX log 的 undefined reference、undefined citation、fatal、overfull 扫描
- Redis `unstable` 链接残留扫描

## 剩余 blocker

本次修订不改变研究状态：C1/C8 仍没有任何 `qualified_for_c8` family。下一步仍需要把
每个 family 至少两个真实 workload row 升级到发布级 oracle，并在公平 table/update budget
下实验证明 table-only 无法同时满足语义和成本门槛。
