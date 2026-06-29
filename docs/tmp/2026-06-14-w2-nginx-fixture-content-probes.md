# W2 nginx fixture content probe 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## 动机

W2 已经有两类 Phase 1 证据：

- `make kvm-w2-oracle`：nginx/PostgreSQL fixture witness entries 的 KVM path oracle。
- `make kvm-w2-nginx-real`：真实 nginx `1.26.3` binary 的 config parser、worker
  start、redirected endpoint HTTP health 和 worker quit。

但是原来的真实 nginx oracle 只实际消费 `nginx.conf -> nginx.test.conf` 和
`upstream.sock -> upstream.local` 两条路径。`sandbox_fixture_view.bpf.c` 本身还包含
`server.crt -> server.fake.crt`、`db.password -> db.fake.pass` 和
`prod.token -> poison.secret` 分支，Phase 1 report 没有把这些分支接到真实 KVM
attach 期间的普通 VFS `open/read` probe。

本步骤目标是在不引入 shell 脚本、不改变 kernel ABI、不升级 C1/C8 claim 的前提下，
把 W2 real nginx gate 扩展为：

```text
真实 nginx endpoint health + attach 期间 fixture content probes
```

## 调研的代码路径

- `bpf/policies/sandbox_fixture_view.bpf.c`
  - lookup 分支包含 `nginx.conf`、`postgresql.conf`、`db.password`、
    `server.crt`、`upstream.sock` 和 `prod.token`。
  - readdir 分支把 backing names 映射回 visible aliases。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `run_nginx_real_app()` 已经负责 materialize nginx prefix、load/attach policy、
    运行 `nginx -t`、启动 worker、跑 HTTP health 和 detach。
  - `compare_files()` 已可用于普通 VFS `open/read` 内容比较。
- `mk/report.mk`
  - Phase 1 report 已 hard-gate W2 real nginx 的 start/input、attach、health、
    endpoint upstream、quit、detach 和 summary。

## 实现选择

本步骤新增五个 attach 期间 content probes：

| probe | visible path | expected backing | production-like decoy |
|-------|--------------|------------------|------------------------|
| config | `conf/nginx.conf` | `conf/nginx.test.conf` | `conf/nginx.prod.conf` |
| endpoint | `conf/upstream.sock` | `conf/upstream.local` | `conf/upstream.prod` |
| cert | `conf/server.crt` | `conf/server.fake.crt` | `conf/server.prod.crt` |
| secret | `conf/db.password` | `conf/db.fake.pass` | `conf/db.prod.pass` |
| poison | `conf/prod.token` | `conf/poison.secret` | `conf/prod.real.token` |

每个 probe 在 policy attached 时执行两步：

1. `visible path` 的内容必须等于 expected backing。
2. `visible path` 的内容必须不等于 production-like decoy。

这些 probe 使用普通路径访问，因此仍走真实 `cgroup/namei_ext` attach path 和 VFS
lookup。它们不是直接检查 BPF object，也不是 host mock。

## 明确不做的事

- 不声称 nginx 已经读取了 `server.crt`、`db.password` 或 `prod.token`。当前
  `nginx.test.conf` 没引用这些路径，因此这些 probe 是 direct VFS content probes，
  不是 nginx startup trace。
- 不声称 trace-level no-real-open oracle。完整发布级 W2 仍需要启动/trace 真实应用，
  统计真实 secret/config/cert backing 是否被打开，并保存 operation-weighted hit rate。
- 不把 W2 升级为 `qualified_for_c8`。当前仍没有 release-level endpoint matrix、
  startup trace、table/update budget counterfactual 或 FUSE/materialized baseline。

## 修改内容

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 新增 W2 fixture/decoy 常量。
  - `prepare_nginx_prefix()` 在 guest `/tmp` prefix 下 materialize expected backing 和
    production-like decoy files。
  - 新增 `emit_nginx_probe()` 和 `check_nginx_fixture_probe()`。
  - `run_nginx_real_app()` 在 attach 后、worker start 前执行五个 content probes。
  - summary detail 改为 `nginx real-app endpoint health and fixture content probes passed`。
- `mk/report.mk`
  - Phase 1 report hard-gate 五个新增 op：
    `attached_config_fixture_probe`、`attached_endpoint_fixture_probe`、
    `attached_fake_cert_probe`、`attached_fake_secret_probe`、
    `attached_poison_probe`。
- `workload/w2-nginx-fixture/evidence.md`、`docs/research_plan.md`、
  `docs/experiment-plans/osdi-evaluation.md` 和 paper 草稿同步更新 W2 证据范围。

## 验证

本地构建：

```text
make bpf w1-oracle
```

结果：通过，`namei_ext_w1_oracle` 重新编译成功。

目标 KVM gate：

```text
make kvm-w2-nginx-real RUN_ID=20260614T-w2-nginx-probes
```

结果：通过。Raw result：

```text
results/phase1/20260614T-w2-nginx-probes/w2-nginx-real.jsonl
```

新增 probe 结果：

```text
attached_config_fixture_probe=true
attached_endpoint_fixture_probe=true
attached_fake_cert_probe=true
attached_fake_secret_probe=true
attached_poison_probe=true
```

summary：

```text
pass=true
failures=0
qualified_for_c8=false
detail="nginx real-app endpoint health and fixture content probes passed"
```

输入哈希：

```text
results/phase1/20260614T-w2-nginx-probes/w2-nginx-real-inputs.sha256
```

包含 9 个输入文件，并通过 `sha256sum -c`。

完整 Phase 1 回归：

```text
make phase1 RUN_ID=20260614T-w2-nginx-probes-phase1 SAMPLES=1 BENCH_ITERS=2000
```

结果：通过。Summary：

```text
results/phase1/20260614T-w2-nginx-probes-phase1/summary.md
```

full run 中 W2 real nginx oracle：

```text
results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl
failures=0
fixture_content_probe_count=5
summary.pass=true
summary.qualified_for_c8=false
```

## 剩余风险

- 这些 probe 证明 W2 policy 在 attach 期间能通过普通 VFS path-resolution 选择
  fixture/fake/poison backing；它们不证明真实 nginx worker 已经读取 cert/secret/poison。
- W2 仍缺 trace-level no-real-open checker、release-level endpoint matrix、
  operation-weighted hit rate、startup p99 和 table/update budget counterfactual。
- `table_redirect.bpf.c` 仍可通过当前 path/probe 形态下的大部分 fixture mapping，
  因此该结果不能支撑 C8。
