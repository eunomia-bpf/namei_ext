# W2 nginx endpoint health oracle 对抗 review 记录

日期：2026-06-14

范围声明：本文档只记录单一 W2 nginx endpoint health oracle 增量的 scoped review。
这里的 scoped weak accept 不代表整篇 OSDI paper、整个项目或 C1/C8 主张已经达到
weak accept。

## Review 范围

本次 review 针对 W2 nginx endpoint health oracle：

- `mk/kvm.mk` 的 `kvm-w2-nginx-real` 和 guest target；
- `mk/report.mk` 的 W2 real-app report gate；
- `tests/w1_oracle/namei_ext_w1_oracle.c` 的 `--sandbox-nginx-smoke` 模式；
- `workload/w2-nginx-fixture/nginx.test.conf`；
- `workload/w2-nginx-fixture/evidence.md`；
- `docs/research_plan.md`；
- `docs/experiment-plans/osdi-evaluation.md`；
- `docs/paper/`；
- `docs/tmp/2026-06-14-w2-nginx-endpoint-health-oracle.md`。

review 标准使用 OSDI/SOSP 系统实验标准：真实 workload、明确 oracle、raw evidence、
claim 降级、KVM 修改内核验证、Makefile-only orchestration 和不把 functional-only
结果计入 C1/C8。

## Subagent 结论

独立 subagent 没有发现 blocker，给出 Phase 1 scoped weak accept。它确认：

- `kvm-w2-nginx-real` 通过 `vng --run $(KERNEL_IMAGE)` 在修改后的 KVM kernel guest 内运行；
- runner 真实 load/attach `sandbox_fixture_view.bpf.o` 到 `BPF_CGROUP_NAMEI_EXT`；
- eBPF policy 包含 `nginx.conf -> nginx.test.conf` 和 `upstream.sock -> upstream.local`；
- workload-owned `nginx.test.conf` 通过 `include upstream.sock` 触发 endpoint alias；
- raw evidence 中 `attached_nginx_test`、`attached_nginx_start`、
  `attached_upstream_start`、`attached_http_health`、`attached_endpoint_upstream`、
  `attached_nginx_quit`、`detach`、`post_detach_nginx_test` 都通过；
- summary 仍为 `qualified_for_c8=false`。

subagent 同时指出三个 Major：

1. report gate 可以更硬：如果 fixture config 被改成直接 `proxy_pass`，local upstream
   仍可能收到请求，但 endpoint alias 不会被消费。
2. endpoint 实现文档还写着 full `make phase1`、`make report`、paper build 和独立
   review 待运行，和当前状态不一致。
3. 仍有少量英文标题，不完全满足“文档全部中文写”的形式要求。

Minor：

- local upstream 只检查收到任意请求，未记录 request line；
- `attached_endpoint_upstream` 的 detail 依赖配置语义，未来最好补 policy hit counter；
- 未发现项目自有 `.sh` 控制面。

## 已完成修订

- 在 `mk/kvm.mk` 的 guest target 中增加机器检查：
  - `nginx.test.conf` 必须包含 `include upstream.sock;`；
  - endpoint fixture 必须精确包含 `proxy_pass http://127.0.0.1:18080;`。
- 在 `mk/report.mk` 中增加同样检查，防止 report 阶段接受绕过 endpoint alias 的结果。
- 更新 `docs/tmp/2026-06-14-w2-nginx-endpoint-health-oracle.md`，记录 full Phase 1、
  report、paper build、paper check、log grep、whitespace 和 no-`.sh` 检查结果。
- 将 `docs/research_plan.md` 的英文章节标题改成中文。
- 将 `docs/paper/evaluation.md` 的主要英文标题改成中文。

## 当前结论

修订后，W2 nginx endpoint health oracle 仍是 Phase 1 scoped weak accept：

- 它证明真实 nginx 在修改后的 KVM kernel guest 内，通过真实 `namei_ext` attach path
  消费 config alias 和 endpoint alias；
- 它的 raw result、input hashes、KVM target、report gate 和中文文档都保持一致；
- 它明确保持 `qualified_for_c8=false`。

它仍不能计入 C1/C8。剩余不计入主结论的风险包括：

- 没有 no-real-secret/config/cert backing oracle；
- 没有 poison access report；
- 没有 release-level endpoint matrix；
- 没有 startup trace 和 operation-weighted redirected hit rate；
- 没有 table/update budget counterfactual；
- 没有发布级 repetition；
- 没有 policy hit counter 或 upstream request-line artifact。
