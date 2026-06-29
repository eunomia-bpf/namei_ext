# W2 Nginx 真实配置解析 Oracle 独立审查记录

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

日期：2026-06-14

范围声明：本文档只记录单一 W2 nginx real config oracle 增量的 scoped review。
这里的 scoped weak accept 不代表整篇 OSDI paper、整个项目或 C1/C8 主张已经达到
weak accept。

## 审查范围

本记录保存独立 subagent 对 W2 nginx real config oracle 的 OSDI-style 对抗审查结论。
审查目标是确认新增证据是否真的通过修改后的内核 KVM guest 和真实
`cgroup/namei_ext` attach path，让真实 nginx `1.26.3` 的 `nginx -t` config parser
观察到 `sandbox_fixture_view.bpf.c` 的 `nginx.conf -> nginx.test.conf` alias，并确认
文档没有把该结果错误计入 C1/C8。

## Subagent 结论

结论：`scoped weak accept`。

Blocking findings：无。

Subagent 认为该 oracle 可以作为合格的 Phase 1 functional gate：真实应用、KVM、
真实 attach path、input provenance 和 fail-fast gate 都成立。它仍只是
`kvm_real_app_config_oracle`，不是 W2 release-level workload oracle；不能支撑 HTTP
health、no-real-secret、endpoint、poison、table/update budget 或 C1/C8。

## 审查确认的关键证据

- `bpf/policies/sandbox_fixture_view.bpf.c` 是 `cgroup/namei_ext` 程序，并对 lookup 的
  `nginx.conf` literal redirect 到 `nginx.test.conf`。
- `tests/w1_oracle/namei_ext_w1_oracle.c` 通过 libbpf load object，并使用
  `BPF_CGROUP_NAMEI_EXT` attach 当前 cgroup。
- runner materialize `conf/nginx.test.conf`，保持 `conf/nginx.conf` 不存在，并执行真实
  nginx `-t -p <prefix>/ -c conf/nginx.conf -g "user root;"`。
- raw result `w2-nginx-real.jsonl` 显示 pre-attach 和 post-detach exit code 非 0，
  attached exit code 为 0，summary `qualified_for_c8=false`。
- `attached.stderr` 显示 nginx 看到的路径仍是 `conf/nginx.conf`，并输出配置测试成功。

## Non-blocking Concerns

Subagent 提出三项非阻塞建议：

1. report gate 应强制所有 `w2-nginx-real` case 的 `qualified_for_c8=false`，而不仅是
   summary。
2. report gate 可检查 attached stderr 是否包含 nginx 配置测试成功文本，减少人工审查
   负担。
3. 论文 prose 可以补上 `-g "user root;"`，使复现命令更精确。

## 已处理事项

- `mk/report.mk` 已新增 gate：
  - 所有 `event=="w2-nginx-real"` case 必须 `qualified_for_c8=false`；
  - attached stderr 必须包含 `syntax is ok`；
  - attached stderr 必须包含 `test is successful`；
  - attached stderr 必须包含 `conf/nginx.conf`。
- `docs/paper/sections/05-evaluation.tex` 已补充 `-g` 覆盖 user directive 为 root 的
  命令语义；完整命令保留在本实现记录和 Markdown evaluation 草稿中。
- `docs/paper/evaluation.md` 已同步补充同一命令描述。

## 当前剩余风险

- 该 oracle 不启动 nginx worker，不证明 HTTP health。
- 该 oracle 不证明 no-real-secret/config/cert backing hash never opened。
- 该 oracle 不证明 endpoint remap、poison access report、startup trace、operation-
  weighted redirected hit rate 或 table/update budget。
- W2 仍不能计入 C1/C8；后续需要发布级 B4/B12 runner、baselines 和 table-only
  counterfactual。
