# W2 nginx endpoint health oracle 实现记录

日期：2026-06-14

## 背景和目标

W2 的 sandbox fixture family 需要证明它不只是把 `nginx.conf` 这个单一配置文件
redirect 到 fixture，还能让真实服务请求路径消费 endpoint 类 path-resolution 决策。
此前 `make kvm-w2-nginx-real` 已经在修改后的 kernel KVM guest 内运行真实 nginx
`1.26.3` binary，覆盖 `nginx -t`、worker start、HTTP health 和 `nginx -s quit`，
但 HTTP health 仍主要证明 config alias 可被真实 nginx 观察到。为了让 W2 evidence
更接近真实 sandbox/fixture 场景，本次把 nginx fixture config 改为包含一个可被
policy redirect 的 `include upstream.sock`，并要求请求经过本地 fake upstream。

本步骤仍是 `functional_only`。它证明一次真实 endpoint path 被消费，但还不是
release-level no-real-secret/cert/poison oracle，也不是 table/update budget
counterfactual，因此不能计入 C1/C8。

## 调研和检查的代码路径

- `tests/w1_oracle/namei_ext_w1_oracle.c`：现有 W1/W2/W3/W4 path oracle runner，
  以及 W2 nginx real-app health oracle。
- `mk/workload.mk`：W2 nginx fixture manifest、endpoint fixture 和 oracle TSV 的生成。
- `mk/kvm.mk`：`kvm-w2-nginx-real` guest target 的输入哈希、KVM 执行命令和 runner 参数。
- `mk/report.mk`：Phase 1 report 对 W2 nginx real-app raw JSON 和 input hash 的 gate。
- `workload/w2-nginx-fixture/nginx.test.conf`：新增的 workload-owned nginx fixture config。
- `workload/w2-nginx-fixture/evidence.md`、`docs/research_plan.md`、
  `docs/experiment-plans/osdi-evaluation.md`、`docs/paper/`：中文 evidence 和论文草稿边界。

## 设计选择

1. workload config 放在 `workload/w2-nginx-fixture/nginx.test.conf`，遵守 workload
   的启动脚本和配置都归档在对应 workload 子目录的规则。
2. `nginx.test.conf` 使用 nginx 自身配置语义：
   `include mime.types` 和 `include upstream.sock`。在 `-p <prefix>/ -c conf/nginx.conf`
   下，这会解析到 `prefix/conf/` 内的文件。
3. KVM guest 内只 materialize `conf/nginx.test.conf` 和 `conf/upstream.local`，刻意不创建
   `conf/nginx.conf` 和 `conf/upstream.sock`。attach 前和 detach 后 `nginx -t` 必须失败。
4. `sandbox_fixture_view.bpf.c` 继续作为 eBPF policy，负责两个 literal aliases：
   `nginx.conf -> nginx.test.conf` 和 `upstream.sock -> upstream.local`。
5. runner 在 guest 内启动 `127.0.0.1:18080` 的本地 upstream server。nginx worker 对
   `127.0.0.1:80` 的 health request 必须通过 redirected `upstream.sock` include 代理到它。
6. raw JSON 增加两个 gate：
   `attached_upstream_start` 和 `attached_endpoint_upstream`。后者为 true 才能说明 fake
   upstream 实际收到 nginx 请求，而不是 nginx 直接返回静态文件。
7. `w2-nginx-real-inputs.sha256` 增加 workload fixture config 和 endpoint fixture，确保 report
   绑定本次 oracle 的真实输入。

## 拒绝的替代方案

- 不采用 shell helper。所有流程继续由 Makefile target 驱动。
- 不把 endpoint 写成 YAML/JSON 配置语言。policy 仍是 `bpf/policies/*.bpf.c`。
- 不把 health request 改成静态 root 文件读取。那只能证明 config alias，不能证明 endpoint alias。
- 不把本地 upstream 放到 host。它必须在 KVM guest 内启动，跟被测 nginx 和 policy attach path
  处在同一个验证环境。
- 不把这一步升级为 C1/C8 evidence。它还缺 no-real-secret/cert/poison、startup trace、
  operation-weighted hit rate、table/update budget 和 repetition。

## 实现细节

- 新增 `workload/w2-nginx-fixture/nginx.test.conf`。该配置在 `/` location 中
  `include upstream.sock`，endpoint fixture `upstream.local` 的内容为
  `proxy_pass http://127.0.0.1:18080;`。
- `mk/workload.mk` 的 W2 nginx fixture manifest 将 config entry 的
  `original_backing_path` 改为 workload fixture config，并保留 upstream sample config
  的 provenance hash 作为真实来源记录。
- `mk/kvm.mk` 将 `kvm-w2-nginx-real` 输入从 `W2_NGINX_SAMPLE_CONF` 改为
  `W2_NGINX_FIXTURE_CONF` 和 `W2_NGINX_ENDPOINT_FIXTURE`，并把两者写入 input hash 和
  `w2-nginx-real-input` JSON event。
- `tests/w1_oracle/namei_ext_w1_oracle.c` 的 `--sandbox-nginx-smoke` 模式现在接收
  `FIXTURE_CONF ENDPOINT_FIXTURE MIME_TYPES SANDBOX_POLICY`。runner 会：
  - 创建 nginx prefix；
  - materialize `conf/nginx.test.conf`、`conf/upstream.local` 和 `conf/mime.types`；
  - attach 前验证 `conf/nginx.conf` 缺失；
  - load/attach `sandbox_fixture_view.bpf.o`；
  - 运行 `nginx -t`；
  - 启动 nginx worker；
  - 启动 local upstream；
  - 发起 HTTP health request；
  - 等待 local upstream 子进程退出并记录 `attached_endpoint_upstream`；
  - `nginx -s quit`；
  - detach 后验证 alias 再次不可达。
- `mk/report.mk` 要求 `w2-nginx-real-inputs.sha256` 有 9 行，并要求新增的
  `attached_upstream_start`、`attached_endpoint_upstream` gate 均为 pass。
- `mk/kvm.mk` 和 `mk/report.mk` 都检查 workload fixture config 必须包含
  `include upstream.sock;`，endpoint fixture 必须精确包含
  `proxy_pass http://127.0.0.1:18080;`。这避免 fixture config 被改成直接
  `proxy_pass` 后绕过 endpoint alias 仍然通过。

## 验证

已运行：

```text
make workload-nginx-fixture-manifest RUN_ID=20260614T-workloads-git-ceiling
make w1-oracle
make kvm-w2-nginx-real RUN_ID=20260614T-workloads-git-ceiling
make phase1 RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
make report RUN_ID=20260614T-workloads-git-ceiling SAMPLES=1 BENCH_ITERS=2000
make -C docs/paper paper
make -C docs/paper check
```

KVM raw result 中关键事件均通过：

```text
attached_nginx_test=true
attached_nginx_start=true
attached_upstream_start=true
attached_http_health=true
attached_endpoint_upstream=true
attached_nginx_quit=true
post_detach_nginx_test=true
```

`w2-nginx-real-summary` 为 `pass=true`、`failures=0`、
`qualified_for_c8=false`，detail 为 `nginx real-app endpoint health oracle passed`。

额外检查：

```text
rg -n "Undefined control sequence|LaTeX Warning: Reference|Citation.*undefined|Overfull|Fatal error|Emergency stop" .build/paper/main.log
git diff --check
find . -path ./kernel -prune -o -path ./.build -prune -o -path ./.cache -prune -o -path ./results -prune -o -name '*.sh' -print
```

上述检查均无阻塞输出。独立 subagent review 给出 Phase 1 scoped weak accept，
但指出需要加硬 endpoint alias 机器门禁和同步本文档最终验证状态；对应修订已完成。

## 剩余风险和后续工作

- 这只是一个 endpoint path 的真实请求 oracle，不是 endpoint matrix。release-level W2 仍需要多个
  endpoint/backend/profile/worker 组合。
- 仍未验证真实 secret/config/cert backing 没有被打开。
- 仍未验证 poison path 是否被访问并正确报告。
- 仍未记录 startup file-operation trace 和 operation-weighted redirected hit rate。
- 仍未与 table-only、projected volume、copy-tree、symlink forest、bind fanout 或 FUSE 做公平对比。
- 当前 subagent review 仍建议未来加入 policy hit counter 或 upstream request-line 记录，
  以把 “through redirected include” 从配置语义推断进一步升级为 branch-hit 机器事实。
