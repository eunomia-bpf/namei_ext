# W2 Nginx 真实 Worker Health Oracle 实现记录

日期：2026-06-14

## 动机

上一版 W2 真实应用 oracle 只运行真实 nginx `1.26.3` binary 的 `nginx -t` config
parser。它证明真实应用配置解析路径会观察到 `namei_ext` 的
`nginx.conf -> nginx.test.conf` 重定向，但仍没有证明 nginx worker 能在同一
redirected config 下启动并对外提供预期响应。

本次实现把 `make kvm-w2-nginx-real` 从 config parser oracle 升级为真实 worker
health oracle：在修改后的内核 KVM guest 中，policy attach 后启动 nginx worker，
对 `127.0.0.1:80` 发起 HTTP GET，要求响应包含 `200 OK` 和固定 body，然后在 policy
仍 attached 时执行 `nginx -s quit`。

该结果仍是 `functional_only`。它证明真实 nginx config parser 和 worker 启动路径能
观察到 `namei_ext` 决策，但仍不做 no-real-secret、endpoint、poison、startup trace、
operation-weighted hit rate 或 table/update budget counterfactual，因此不能计入 C1/C8。

## 调研过的代码和产物

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 复用已有 `--sandbox-nginx-smoke` runner、libbpf loader、cgroup attach/detach 和
    JSONL emission。
  - 新增 daemon start/quit helper 和最小 C socket HTTP client，避免引入 curl 等额外
    guest runtime dependency。
- `mk/kvm.mk`
  - 继续由 `kvm-w2-nginx-real` 和 `__phase1_guest_w2_nginx_real` 驱动，不新增 shell
    控制面。
- `mk/report.mk`
  - 把 W2 real-app result level 改为 `kvm_real_app_health_oracle`，并新增 start、HTTP
    health 和 quit 的 hard gate。
- `.build/workloads/runs/20260614T-workloads-git-ceiling/w1-nginx-build/src/objs/nginx`
  - 真实 nginx `1.26.3` binary。
- `.build/workloads/nginx-1.26.3/conf/nginx.conf`
  - upstream sample config，作为 `conf/nginx.test.conf` materialize。
- `.build/workloads/nginx-1.26.3/conf/mime.types`
  - upstream `mime.types`，供真实 nginx worker 服务静态文件时读取。

## 设计选择

新的 `--sandbox-nginx-smoke` 运行流程：

1. 在 KVM guest `/tmp/namei-ext-w2-nginx-real-XXXXXX` 下创建 nginx prefix。
2. 复制 upstream sample config 为 `conf/nginx.test.conf`。
3. 复制 upstream `mime.types` 为 `conf/mime.types`。
4. 写入 `html/index.html`，内容为 `namei_ext nginx health\n`。
5. 保证 `conf/nginx.conf` 不存在。
6. attach 前运行真实 `nginx -t -p <prefix>/ -c conf/nginx.conf -g "user root;"`
   并要求失败。
7. load/attach `sandbox_fixture_view.bpf.o` 到当前 cgroup。
8. attach 后运行同一条 `nginx -t` 并要求成功。
9. attach 后启动真实 nginx daemon：
   `nginx -p <prefix>/ -c conf/nginx.conf -g "user root;"`。
10. 用 runner 内置 socket client 连接 `127.0.0.1:80`，发送 HTTP/1.0 GET `/`，
    保存完整 response，并要求包含 `200 OK` 和 `namei_ext nginx health`。
11. policy 仍 attached 时运行
    `nginx -s quit -p <prefix>/ -c conf/nginx.conf -g "user root;"`，要求成功。
12. detach policy。
13. detach 后再次运行同一条 `nginx -t`，要求失败。

HTTP client 用 C 实现，原因是 Phase 1 KVM guest 不应依赖未声明的 host 工具或临时安装
的 curl。runner 保存完整 response 到
`results/phase1/<run-id>/w2-nginx-real-app/attached-health.response`，report 只做硬
校验，不在低层 collector 中计算论文摘要。

## 拒绝的替代方案

- 不使用 shell script 包装 nginx：项目控制面必须是 Makefile-only。
- 不把 HTTP health 交给 curl：这会引入新的 guest dependency，并且需要额外 packaging
  和 input hash 规则。
- 不把 start 成功但 health 失败记成 skipped：真实 worker health 是本 gate 的 declared
  capability，失败必须让 KVM target 或 report hard fail。
- 不把 health oracle 升级为 C1/C8：它仍没有 no-real-secret、endpoint、poison、
  startup trace 和 table/update budget 证据。

## 实现内容

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 增加 `NGINX_HEALTH_BODY`，并在 prefix 中写入 `html/index.html`。
  - 增加 `run_nginx_daemon_cmd()`，支持 daemon start 和 `nginx -s quit`。
  - 增加 `connect_local_http()` 和 `run_http_health()`，用 socket 执行 HTTP GET 并保存
    raw response。
  - 增加 `attached_nginx_start`、`attached_http_health` 和
    `attached_nginx_quit` 三个 JSONL case。
  - 将 `w2-nginx-real` 和 summary result level 改为
    `kvm_real_app_health_oracle`。
- `mk/kvm.mk`
  - 将 `w2-nginx-real-start/input/done` result level 改为
    `kvm_real_app_health_oracle`。
- `mk/report.mk`
  - 要求所有 `w2-nginx-real*` event 的 result level 都是
    `kvm_real_app_health_oracle`。
  - 要求 `attached_nginx_start`、`attached_http_health`、`attached_nginx_quit`
    各出现一次并通过。
  - 对 `attached-health.response` 执行 `grep`，要求包含 `200 OK` 和
    `namei_ext nginx health`。
  - 将 report section 标题改为 `W2 Nginx Real App Health Oracle Cases`。

## 验证

单独编译 runner：

```text
make w1-oracle
```

结果：命令退出 0。

单独运行 W2 nginx KVM gate：

```text
make kvm-w2-nginx-real RUN_ID=20260614T-workloads-git-ceiling
```

结果：命令退出 0。

完整 Phase 1 回归：

```text
make phase1 RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
```

结果：命令退出 0。该 run 重新生成 W1/W2/W3/W4 path oracle input sha256、W2 nginx
real-app input sha256、Docker image tar、metadata 和 summary，并在 summary 中写入
`W2 Nginx Real App Health Oracle Cases`。

关键 raw evidence：

- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached-health.response`
- `results/phase1/20260614T-workloads-git-ceiling/dmesg-w2-nginx-real.log`

JSONL 关键 case：

- `pre_attach_nginx_test`：`pass=true`，`exit_code=1`
- `attached_nginx_test`：`pass=true`，`exit_code=0`
- `attached_nginx_start`：`pass=true`，`exit_code=0`
- `attached_http_health`：`pass=true`，`exit_code=0`
- `attached_nginx_quit`：`pass=true`，`exit_code=0`
- `post_detach_nginx_test`：`pass=true`，`exit_code=1`
- `w2-nginx-real-summary`：`pass=true`，`failures=0`，
  `qualified_for_c8=false`

HTTP response raw evidence 包含：

```text
HTTP/1.1 200 OK
Server: nginx/1.26.3
...
namei_ext nginx health
```

## 剩余风险和下一步

- 当前 health oracle 只覆盖 localhost 静态文件响应，不覆盖 upstream endpoint remap。
- 当前 oracle 不证明真实 production secret/config/cert backing 从未被打开。
- 当前 oracle 不记录 startup VFS trace、redirected hit rate 或 per-operation latency。
- 当前 oracle 没有运行 table-only/FUSE/copy/symlink/bind 等 counterfactual。
- 当前 oracle 仍只验证单 nginx worker fixture；发布级 W2 至少还需要 nginx 和 PostgreSQL
  两个真实服务 row，并需要 no-real-secret、endpoint、poison 和 table/update budget
  全部通过。
