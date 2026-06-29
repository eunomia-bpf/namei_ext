# W2 Nginx 真实配置解析 Oracle 实现记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14

## 动机

此前 W2 只有两类证据：

- host fixture-witness manifest：证明 nginx/PostgreSQL fixture inputs 与真实 upstream
  provenance 绑定；
- KVM path oracle：证明 `sandbox_fixture_view.bpf.c` 和 `table_redirect.bpf.c` 能在
  synthetic directory 中完成 lookup/readdir alias 语义。

这些证据仍然离真实 workload 太远。为了向发布级 B4/B12 迈进一步，本次实现了一个最小
真实应用 oracle：在修改后的内核 KVM guest 内运行真实 nginx `1.26.3` binary 的
`nginx -t` config parser，让真实应用通过 `conf/nginx.conf` 这个路径观察
`sandbox_fixture_view.bpf.c` 的 `nginx.conf -> nginx.test.conf` 重定向。

该 oracle 仍然是 `functional_only`。它证明真实 nginx 配置解析路径能观察到
`namei_ext` 决策，但不启动 nginx worker，不做 HTTP health、no-real-secret、endpoint、
poison 或 table/update budget oracle，因此不能计入 C1/C8。

## 调研过的代码和产物

- `bpf/policies/sandbox_fixture_view.bpf.c`
  - 确认 policy 对 basename `nginx.conf` 做 literal redirect 到
    `nginx.test.conf`，不依赖绝对路径。
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 复用已有 libbpf loader、cgroup attach/detach、JSONL emission 和 fail-fast 结构。
- `mk/kvm.mk`
  - 增加 KVM guest target，保持所有流程由 Make target 驱动。
- `mk/report.mk`
  - 增加 raw result、input hash、case table 和 hard gates。
- `Makefile`
  - 将新 target 接入 `phase1`，并加入 `help`。
- `.build/workloads/runs/20260614T-workloads-git-ceiling/w1-nginx-build/src/objs/nginx`
  - 确认真实 nginx binary 可执行，版本来自固定 nginx `1.26.3` source provenance。
- `.build/workloads/nginx-1.26.3/conf/nginx.conf`
  - upstream sample config，SHA256：
    `95363d79620c1b3eb6951711b6630a411f147bc9197bc91442c0605cf6688e46`。
- `.build/workloads/nginx-1.26.3/conf/mime.types`
  - upstream `mime.types`，SHA256：
    `6f95d1d7d75e3c072907d845622a69d23110d1266c16ff122b3109b8b21f3ae9`。

## 设计选择

新增 runner mode：

```text
namei_ext_w1_oracle --sandbox-nginx-smoke \
  OUT_JSONL CGROUP_MOUNT WORK_DIR NGINX_BIN SAMPLE_CONF MIME_TYPES SANDBOX_POLICY
```

运行流程：

1. 在 KVM guest `/tmp/namei-ext-w2-nginx-real-XXXXXX` 下创建 nginx prefix。
2. 把 upstream sample config 复制为 `conf/nginx.test.conf`。
3. 把 upstream `mime.types` 复制为 `conf/mime.types`。
4. 保证 `conf/nginx.conf` 不存在。
5. attach 前运行真实 nginx：
   `nginx -t -p <prefix>/ -c conf/nginx.conf -g "user root;"`
   预期失败。
6. load/attach `sandbox_fixture_view.bpf.o` 到当前 cgroup。
7. attach 后运行同一条 nginx config test，预期成功。
8. detach 后再次运行同一条 nginx config test，预期失败。
9. 把 stdout/stderr、JSONL、dmesg 和输入 sha256 写入
   `results/phase1/<run-id>/`。

nginx prefix 放在 guest `/tmp`，而不是 host 9p 共享的 result 目录。原因是 `nginx -t`
在配置语法通过后会对临时目录执行 `chown()`；9p 共享目录会返回 `EPERM`，导致真实
路径重定向已经成功后仍被共享文件系统限制误判为失败。stdout/stderr 仍写入持久 result
目录，保证原始观测可审计。

## 拒绝的替代方案

- 不使用 host-only nginx 测试：Phase 1 validation 必须在修改后的内核 KVM guest 中运行。
- 不把 nginx config oracle 写成 shell script：项目控制面必须是 Makefile-only。
- 不把 `nginx.conf -> nginx.test.conf` 写成 YAML/JSON policy：policy 必须是
  `bpf/policies/*.bpf.c` 下的 eBPF 程序。
- 不把 `nginx -t` 的 chown 失败当成可接受 partial success：失败必须 hard fail。最终
  通过把 prefix 放在 guest `/tmp` 消除了 9p 环境噪声。
- 不把该结果升级为 C8：这个 oracle 没有 table/update budget counterfactual，也没有
  no-real-secret 或 service health。

## 实现内容

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - 增加 `--sandbox-nginx-smoke` 模式；
  - 增加 nginx prefix materialization、stdout/stderr 捕获、真实 `nginx -t` 执行；
  - 增加 pre-attach、attached、post-detach 三阶段 JSONL case；
  - 所有 summary 记录 `qualified_for_c8=false`。
- `mk/kvm.mk`
  - 增加 `kvm-w2-nginx-real` 和 `__phase1_guest_w2_nginx_real`；
  - guest target 检查 nginx binary、sample config、`mime.types`、fixture manifest、
    policy source/object 和 runner source/binary；
  - 写入 `w2-nginx-real-inputs.sha256` 和 `dmesg-w2-nginx-real.log`。
- `mk/report.mk`
  - 增加 `w2-nginx-real.jsonl` 和 input sha256 hard gate；
  - 检查 pre-attach 非零退出、attach 后 0 退出、detach 后非零退出；
  - 检查 result level 为 `kvm_real_app_config_oracle`，summary 为 0 failure 且
    `qualified_for_c8=false`。
- `Makefile`
  - 将 `kvm-w2-nginx-real` 接入 `phase1` 和 `help`。

## 验证

单独编译 runner：

```text
make w1-oracle
```

单独运行新增 KVM gate：

```text
make kvm-w2-nginx-real RUN_ID=20260614T-workloads-git-ceiling
```

结果：命令退出 0。

完整 Phase 1 回归：

```text
make phase1 RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
```

结果：命令退出 0。该 run 重新生成 W1/W2/W3/W4 oracle input sha256，并在 summary 中
加入 `W2 Nginx Real App Config Oracle Cases`。

关键 raw evidence：

- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real.jsonl`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-inputs.sha256`
- `results/phase1/20260614T-workloads-git-ceiling/w2-nginx-real-app/attached.stderr`
- `results/phase1/20260614T-workloads-git-ceiling/dmesg-w2-nginx-real.log`

JSONL 关键 case：

- `pre_attach_nginx_test`：`pass=true`，`exit_code=1`
- `attached_nginx_test`：`pass=true`，`exit_code=0`
- `post_detach_nginx_test`：`pass=true`，`exit_code=1`
- `w2-nginx-real-summary`：`pass=true`，`failures=0`，
  `qualified_for_c8=false`

`attached.stderr` 证明真实 nginx 接受同一路径：

```text
nginx: the configuration file /tmp/namei-ext-w2-nginx-real-.../conf/nginx.conf syntax is ok
nginx: configuration file /tmp/namei-ext-w2-nginx-real-.../conf/nginx.conf test is successful
```

`w2-nginx-real-inputs.sha256` 已用 `sha256sum -c` 验证通过。

## 剩余风险和下一步

- 这不是 nginx 服务启动，也没有 HTTP health response。
- 这不验证 no-real-secret/config/cert backing hash never opened。
- 这不验证 endpoint remap、poison access report、startup trace 或 redirected operation
  hit rate。
- 这没有运行 `table_redirect.bpf.c` 的真实 nginx config counterfactual，也没有
  table/update budget 或 stale window 证据。
- prefix 在 guest `/tmp` 中创建，stdout/stderr 和 JSONL 持久化到 result root；后续如果
  需要审计 prefix tree，应增加显式 manifest，而不是依赖 `/tmp` 残留。
- 下一步 W2 发布级工作应启动 nginx worker、运行 HTTP health checker、记录 startup
  VFS trace，并同时运行 projected-volume/copy/symlink/bind/FUSE/table-only baselines。
