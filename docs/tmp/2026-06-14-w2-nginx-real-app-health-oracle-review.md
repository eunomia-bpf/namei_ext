# W2 Nginx 真实 Worker Health Oracle 对抗审查记录

日期：2026-06-14

范围声明：本文档只记录单一 W2 nginx real-app health oracle 增量的 scoped review。
这里的 scoped weak accept 不代表整篇 OSDI paper、整个项目或 C1/C8 主张已经达到
weak accept。

## 审查范围

本次审查覆盖 W2 nginx real-app health oracle 增量，以及 Phase 1、evaluation 和 paper
文档中的 claim 边界。重点文件和结果：

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `mk/report.mk`
- `workload/w2-nginx-fixture/evidence.md`
- `docs/tmp/2026-06-14-w2-nginx-real-app-health-oracle.md`
- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/evaluation.md`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-health.response`

审查由 subagent `019ec7b9-08da-7a51-a72b-a61c21bff14b` 以只读方式完成；subagent
未修改文件，也没有重新运行会写结果的 Make target。

## 审查结论

Blocking findings：无。

Subagent verdict：达到 `scoped weak accept for Phase 1 W2 health oracle`。

可声称的范围：

- 在 KVM + modified kernel + 真实 `cgroup/namei_ext` attach path 下，真实 nginx
  worker 能通过 eBPF path-resolution redirect 的 config 启动并返回 HTTP health。

不能声称的范围：

- 不能计入 C1/C8。
- 不能声称 no-real-secret、endpoint remap、poison detection、startup trace、
  operation-weighted hit rate、table/update budget 或发布级 production workload oracle。

## Non-blocking findings 和处理

1. 文档仍有 “config oracle/config gate” 旧术语残留。
   - 处理：把 paper 中 W2 nginx real gate 统一改为 health oracle/health gate。
2. `mk/report.mk` 没有单独要求 `load`、`attach`、`detach` 各出现一次并成功。
   - 处理：新增 hard gates，要求 `load`、`attach`、`detach` 各一条且
     `pass=true`、`exit_code=0`。
3. `attached_nginx_quit` 的成功文案 `nginx daemon stopped cleanly` 容易暗示已经验证
   pid/listener 消失。
   - 处理：收窄为 `nginx quit command succeeded`。后续发布级 oracle 可补
     pid/socket-gone gate。
4. HTTP checker 是最小实现，只匹配 `200 OK` 和固定 body，没有严格 status-line parser
   或 read timeout。
   - 处理：记录为发布级后续工作；Phase 1 scoped oracle 当前不升级该部分。
5. W2 real health oracle 只消费 `nginx.conf -> nginx.test.conf` 真实应用路径，不消费
   fixture manifest 中的 cert/endpoint/poison entries。
   - 处理：保留文档边界，明确仍缺 no-real-secret/endpoint/poison/startup trace/table
     budget。

## 复验

处理 non-blocking findings 后重新运行：

```text
make phase1 RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
```

结果：命令退出 0。

关键 raw evidence 更新后仍满足：

- `attached_nginx_start`：`pass=true`，`exit_code=0`
- `attached_http_health`：`pass=true`，`exit_code=0`
- `attached_nginx_quit`：`pass=true`，`exit_code=0`，detail 为
  `nginx quit command succeeded`
- `w2-nginx-real-summary`：`pass=true`，`failures=0`，
  `qualified_for_c8=false`

`mk/report.mk` 现在还额外要求 `load`、`attach`、`detach` 三个 lifecycle case 各自
通过，避免只有 health/start/quit case 时误判为完整 attach-path run。
