# w2-nginx-fixture 证据

> 2026-06-29 baseline scope update: older gate language is superseded by claim-driven baseline selection. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.


状态：`functional_only_kvm_path_oracle` + `functional_only_kvm_real_app_endpoint_health_oracle` + `functional_only_kvm_fixture_content_probes` + `kvm_c2_setup_update_release_input` + `copy_symlink_bind_projected_fuse_feature_baseline_input` + `w2_storage_threshold_supported_slice`；不能计入 C1/C8，且只能支撑 W2 slice，不能单独支撑全局 C2。

Policy family：`sandbox_fixture_view.bpf.c`

## 真实来源

- nginx documentation: https://nginx.org/en/docs/beginners_guide.html
- Kubernetes projected volumes: https://kubernetes.io/docs/concepts/storage/projected-volumes/
- Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Docker Compose configs: https://docs.docker.com/reference/compose-file/configs/
- Docker Compose secrets: https://docs.docker.com/compose/how-tos/use-secrets/

## 当前已实现的 provenance 和 gates

- 固定 nginx 源码版本：nginx `1.26.3`
- Source tarball SHA256：`69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa`
- nginx sample config SHA256：`95363d79620c1b3eb6951711b6630a411f147bc9197bc91442c0605cf6688e46`
- workload fixture config：`workload/w2-nginx-fixture/nginx.test.conf`
- workload fixture config SHA256：`2d37a18dbf88e9e6d14f59efbbda76f003304d79b6ef944c372b0aa1be442532`
- endpoint fixture SHA256：`d3b36896c2c2f936de7f35bdf7cd296177f984f612919ecabef6220120e2cbd2`
- Source provenance target：`make workload-nginx-build-fetch`，与 W1 nginx source provenance 共享
- Source provenance result：`results/workloads/provenance/nginx-source.json`
- Fixture manifest result：
  `results/workloads/runs/20260614T-workloads-git-ceiling/w2-nginx-fixture/fixture-manifest.json`
- KVM path oracle result：
  `results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`
- Input hash manifest：
  `results/phase1/20260614T-workloads-git-ceiling/w2-oracle-inputs.sha256`
- KVM real nginx endpoint health oracle result：
  `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl`
- KVM real nginx endpoint health oracle input hash manifest：
  `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real-inputs.sha256`
- KVM nginx setup/update macrobench smoke result：
  `results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/w2-nginx-macrobench.jsonl`
- KVM nginx setup/update macrobench 20-sample input result：
  `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`
- KVM nginx setup/update macrobench 20-sample input hash manifest：
  `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench-inputs.sha256`
- KVM nginx copy/symlink/bind/projected-volume/FUSE baseline macrobench 20-sample input result：
  `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl`
- KVM nginx copy/symlink/bind/projected-volume/FUSE baseline macrobench 20-sample input hash manifest：
  `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench-inputs.sha256`
- W2 nginx workload macrobench ledger result：
  `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
- Fixture manifest target：`make workload-nginx-fixture-manifest`
- Combined W2 TSV target：`make workload-w2-oracle-entries`
- KVM path oracle target：`make kvm-w2-oracle`
- KVM real nginx endpoint health oracle target：`make kvm-w2-nginx-real`
- KVM setup/update macrobench target：`make kvm-w2-nginx-macrobench`
- KVM copy/symlink/bind/projected-volume/FUSE baseline macrobench target：`make kvm-w2-nginx-baseline-macrobench`
- W2 workload macrobench ledger target：`make eval-osdi-w2-nginx-workload-macrobench-ledger`

## 当前 path-oracle witness

- production config -> fixture
- production cert/secret -> fake fixture
- external endpoint -> local fake service
- dangerous/prod-only path -> poison sentinel

## 当前 oracle

- fixture manifest 结构和 source hash 检查
- 通过真实 `cgroup/namei_ext` attach path 在 KVM guest 中执行
- 每个声明 fixture entry 的 lookup 内容匹配
- readdir visible set 包含 alias，并按当前 oracle 检查 backing 处理
- detach 后 alias 再次不可达
- `w2-oracle-inputs.sha256` 固定 TSV、manifests、policy source/object 和 runner source/binary
- 真实 nginx `1.26.3` binary 在 KVM guest 内执行 `nginx -t`，并使用
  `workload/w2-nginx-fixture/nginx.test.conf` 作为 `nginx.test.conf`
- attach 前 `conf/nginx.conf` 缺失，`nginx -t` 失败；attach 后同一路径由
  `sandbox_fixture_view.bpf.c` 重定向到 `nginx.test.conf`，`nginx -t` 成功；detach
  后再次失败
- workload fixture config 包含 `include upstream.sock`；attach 后同一路径由
  `sandbox_fixture_view.bpf.c` 重定向到 `upstream.local`，其内容为
  `proxy_pass http://127.0.0.1:18080;`
- attach 后同一真实 nginx binary 会以 redirected config 启动 worker；runner 启动
  `127.0.0.1:18080` 本地 upstream，对 `127.0.0.1:80` 执行 HTTP GET，并要求响应包含
  `200 OK` 和 `namei_ext nginx health`
- runner 记录 `attached_endpoint_upstream=true`，证明本地 upstream 实际收到 nginx
  代理请求，而不是仅返回静态 root 文件
- nginx worker 会在 policy 仍 attached 时通过 `nginx -s quit` 成功退出
- policy attached 后，runner 还用普通 VFS `open/read` 执行五个 fixture content
  probes：`nginx.conf -> nginx.test.conf`、`upstream.sock -> upstream.local`、
  `server.crt -> server.fake.crt`、`db.password -> db.fake.pass` 和
  `prod.token -> poison.secret`。每个 probe 同时要求 visible alias 内容不等于同目录
  production-like decoy。
- `w2-nginx-real-inputs.sha256` 固定 nginx binary、workload fixture config、
  endpoint fixture、`mime.types`、fixture manifest、policy source/object 和 runner
  source/binary
- `make kvm-w2-nginx-macrobench RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  W2_NGINX_MACROBENCH_SAMPLES=20` 在 KVM guest 内重复 20 个 sample：每个 sample
  materialize nginx prefix，记录 setup object count、bytes written/copied，attach
  `sandbox_fixture_view.bpf.c` 后运行 `nginx -t`、config/endpoint/cert/secret/poison
  probes，随后修改 `upstream.local`、`server.fake.crt`、`db.fake.pass` 并再次运行
  post-update `nginx -t` 与 probes。
- 20-sample macrobench raw result 包含 20 条 `w2-nginx-macrobench-setup`、20 条
  `w2-nginx-macrobench-update`、20 条 `w2-nginx-macrobench-correctness` 和 1 条
  summary；summary 为 `pass=true`、`failures=0`、`policy_executed=true`、
  `kvm_validated=true`、`c2_supported=false`、`release_gate_pass=false`。
- 该 macrobench 只证明 W2 nginx 的 setup/update raw-row path 和 correctness gate 已在
  修改内核 KVM 中可运行；结合下面的 copy/symlink/bind/projected-volume/FUSE baseline 和
  v5 storage/threshold ledger 后，它可以支撑 W2 slice，但仍没有 W1/W3/W4 对等
  macrobench，因此不能单独支撑全局 C2。
- `make kvm-w2-nginx-baseline-macrobench RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4
  W2_NGINX_BASELINE_MACROBENCH_SAMPLES=20` 在 KVM guest 内对同一个 nginx fixture 运行
  五类 materialized/bind/projected/FUSE baseline：`copy_tree` 把 config/endpoint/cert/secret/poison
  backing 复制成 visible alias，`symlink_forest` 为相同 alias 建同目录 symlink，
  `bind_mount` 为相同 alias 建同目录 file bind mount，`projected_volume` 使用
  `.projected/..data` generation symlink 表达 Kubernetes atomic-writer 风格更新，
  `fuse_redirect` 把 visible `conf/` mount 到最小 libfuse path-remapping daemon，并把
  visible config/endpoint/cert/secret/poison alias 映射到 backing files。每个
  sample 都运行真实 `nginx -t`，执行 config/endpoint/cert/secret/poison probes，随后
  更新 endpoint/cert/secret backing 并再次运行 post-update `nginx -t` 和 probes。
- 20-sample baseline raw result 覆盖 `copy_tree`、`symlink_forest`、`bind_mount`、
  `projected_volume` 和 `fuse_redirect`：
  每个 baseline 20 条 setup rows、20 条 update rows 和 20 条 correctness rows；
  summary 为 `baseline_count=5`、`samples=20`、`setup_rows=100`、`update_rows=100`、
  `correctness_rows=100`、`pass=true`、`failures=0`、
  `policy_executed=false`、`kvm_validated=true`、`feature_equivalent_baseline=true`、
  `c2_supported=false`、`release_gate_pass=false`。
- `make eval-osdi-w2-nginx-workload-macrobench-ledger
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v5
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v4`
  已把 W2 proposed-system rows 和 copy/symlink/bind/projected/FUSE baseline rows 合并到 claim-level ledger。
  summary 为 `policy_release_input_pass=true`、`baseline_release_input_pass=true`、
  `copy_symlink_baselines_pass=true`、`bind_baseline_pass=true`、
  `projected_volume_baseline_pass=true`、`fuse_baseline_pass=true`、
  `all_feature_baselines_pass=true`、`full_feature_equivalent_baseline_pass=true`、
  `storage_footprint_pass=true`、`setup_latency_threshold_pass=true`、
  `update_latency_threshold_pass=true`、`update_materialization_threshold_pass=true`、
  `threshold_pass=true`、`w2_c2_slice_supported=true`，但全局
  `c2_supported=false`、`release_gate_pass=false`。
  `missing_evidence` 只列出 W1/W3/W4 workload setup/storage/update macrobench。
  hard gate
  `make eval-osdi-w2-nginx-workload-macrobench` 按预期非零退出。

## 进入 C1/C8 前仍需完成的发布级 oracle

- trace-level no-real secret/config/cert backing hash opened checker
- release-level endpoint matrix checker
- poison access trace/report
- startup trace 和 operation-weighted redirected hit rate
- workload-appropriate baseline comparison
- W1/W3/W4 对等 setup/storage/update macrobench；若用于 C1/C8，则还需要 W2
  workload-appropriate baseline comparison

## 当前 raw results

- `results/workloads/runs/20260614T-workloads-git-ceiling/w2-nginx-fixture/`
- `results/phase1/20260614T-workloads-git-ceiling/w2-oracle.jsonl`
- `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real.jsonl`
- `results/phase1/20260614T-w2-nginx-probes-phase1/w2-nginx-real-app/`
- `results/phase1/20260615T-w2-nginx-c2-macrobench-smoke-v1/w2-nginx-macrobench.jsonl`
- `results/phase1/20260615T-w2-nginx-c2-macrobench-release-sample-v1/w2-nginx-macrobench.jsonl`
- `results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl`
- `results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl`

## 当前限制

- 这是 per-entry synthetic-directory KVM path oracle。
- 真实 nginx endpoint health oracle 会运行 `nginx -t`、启动真实 worker、执行 HTTP
  health check、确认 redirected endpoint upstream 收到请求，并退出 worker，验证真实
  nginx 配置解析和服务路径会观察到 `namei_ext` alias。
- fixture content probes 覆盖 config、endpoint、cert、secret 和 poison 分支，但
  cert/secret/poison 仍是 direct VFS probes，不是 nginx worker startup trace。
- 它尚未证明 trace-level no-real-secret/config/cert backing、release-level endpoint
  matrix、poison access trace/report、startup trace、operation-weighted hit rate 或
- workload-appropriate baseline comparison。
- C2 setup/update macrobench 已有 W2 nginx `namei_ext` 侧 20-sample raw input，以及同
  workload `copy_tree`/`symlink_forest`/`bind_mount`/`projected_volume`/`fuse_redirect`
  baseline input；v5 ledger 也已给出 W2 storage/threshold-supported slice。但全局 C2
  仍缺 W1/W3/W4 对等 run，所以仍不能写成完整 C2 结果。
