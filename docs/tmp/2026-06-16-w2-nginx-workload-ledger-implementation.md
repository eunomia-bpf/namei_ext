# W2 nginx workload macrobench ledger 实现记录

日期：2026-06-16

阶段：Phase 1 implementation documentation

## 动机

W2 nginx 已有两类 raw input：

- proposed system：`sandbox_fixture_view.bpf.c` 在修改内核 KVM 中运行 20 个
  setup/update/correctness samples；
- feature baseline：`copy_tree` 和 `symlink_forest` 在同一个 nginx fixture 上运行 20 个
  setup/update/correctness samples。

这些证据仍然不是 C2 结论。需要一个 Makefile-owned ledger 把两边 raw rows 合并成
claim-level 判定，并明确 partial baseline 不能通过 C2 hard gate。

## 修改文件

- `mk/eval_osdi.mk`
- `Makefile`

## 实现内容

新增 target：

```text
make eval-osdi-w2-nginx-workload-macrobench-ledger
make eval-osdi-w2-nginx-workload-macrobench
```

必需输入：

```text
EVAL_OSDI_W2_NGINX_POLICY_RUN_ID
EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID
```

ledger 读取：

- `results/phase1/<policy-run>/w2-nginx-macrobench.jsonl`
- `results/phase1/<policy-run>/w2-nginx-macrobench-inputs.sha256`
- `results/phase1/<baseline-run>/w2-nginx-baseline-macrobench.jsonl`
- `results/phase1/<baseline-run>/w2-nginx-baseline-macrobench-inputs.sha256`

ledger 写出：

- `results/eval-osdi/paper/<run-id>/b3-macrobench/w2-nginx-workload-macrobench.jsonl`
- `results/eval-osdi/paper/<run-id>/b3-macrobench/w2-nginx-workload-macrobench-inputs.sha256`
- `results/eval-osdi/paper/<run-id>/b3-macrobench/w2-nginx-workload-macrobench-manifest.json`
- `results/eval-osdi/paper/<run-id>/b3-macrobench/w2-nginx-workload-macrobench-summary.md`

summary gate 明确区分：

- `policy_release_input_pass=true`：proposed-system 20-sample KVM rows 完整；
- `baseline_release_input_pass=true`：copy/symlink 20-sample KVM rows 完整；
- `copy_symlink_baselines_pass=true`：已观察到 `copy_tree` 和 `symlink_forest`；
- `full_feature_equivalent_baseline_pass=false`：仍缺 bind/FUSE/projected-volume 或等价 baseline；
- `storage_footprint_pass=false`：尚未做 storage footprint 聚合；
- `threshold_pass=false`：尚未声明并满足 C2 setup/storage/update 阈值；
- `c2_supported=false`、`release_gate_pass=false`：该 ledger 是 partial input，不是 C2 通过。

`make eval-osdi-w2-nginx-workload-macrobench` 是 hard gate：它先生成同一份 artifacts，
随后要求 summary 同时满足 `release_gate_pass=true` 和 `c2_supported=true`。当前证据下
该 target 必须非零退出。

## 验证

ledger run：

```text
make eval-osdi-w2-nginx-workload-macrobench-ledger \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-ledger-v1 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v1
```

通过。summary：

- `required_samples=20`
- `policy_release_input_pass=true`
- `baseline_release_input_pass=true`
- `copy_symlink_baselines_pass=true`
- `baseline_count_observed=2`
- `full_feature_equivalent_baseline_pass=false`
- `storage_footprint_pass=false`
- `threshold_pass=false`
- `c2_supported=false`
- `release_gate_pass=false`

feature baseline rows：

- `copy_tree`：20 setup rows、20 update rows、20 correctness rows，setup 7.90--13.83 ms，
  update 15.5--91.4 us，pass。
- `symlink_forest`：20 setup rows、20 update rows、20 correctness rows，
  setup 9.70--12.64 ms，update 7.65--26.2 us，pass。

expected-fail hard gate：

```text
make eval-osdi-w2-nginx-workload-macrobench \
  RUN_ID=20260616T-eval-w2-nginx-workload-macrobench-hardgate-v1 \
  EVAL_OSDI_W2_NGINX_POLICY_RUN_ID=20260615T-w2-nginx-c2-macrobench-release-sample-v1 \
  EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID=20260616T-w2-nginx-baseline-macrobench-release-sample-v1
```

按预期非零退出。该 target 已写出 artifacts，但最终 `jq -e` 找不到
`release_gate_pass=true` 且 `c2_supported=true` 的 summary。

## 判读

这一步把 W2 C2 证据从“两个分散的 KVM raw result roots”推进为“有 Make-owned
claim-level ledger 和 hard gate”。它仍不能支撑 C2，因为当前只覆盖 copy/symlink
两类 materialization baseline，尚未覆盖：

- bind mount baseline；
- FUSE redirect baseline；
- projected volume 或等价 config/secret injection baseline；
- storage footprint aggregation；
- 显式 C2 setup/storage/update 成功阈值；
- W1/W3/W4 对等 workload macrobench。

因此当前正确论文表述是：W2 已有 release-input-quality proposed-system rows 和两类
partial feature baseline rows；C2 仍为 unsupported。

## 2026-06-16 追加：bind baseline 后的 v2 ledger

后续 `docs/tmp/2026-06-16-w2-nginx-bind-baseline-implementation.md` 补上了同一 W2 nginx
workload 的 `bind_mount` baseline，并把 canonical W2 feature-baseline run 推进到：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v2/w2-nginx-baseline-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v2/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

v2 baseline summary 为 `baseline_count=3`、`setup_rows=60`、`update_rows=60`、
`correctness_rows=60`、`pass=true`、`failures=0`，覆盖 `copy_tree`、
`symlink_forest` 和 `bind_mount`。v2 ledger summary 新增
`bind_baseline_pass=true` 和 `copy_symlink_bind_baselines_pass=true`。

判读不变：W2 仍是 partial C2 input。缺口从 `bind/FUSE/projected-volume-equivalent`
缩小为 FUSE/projected-volume-equivalent baseline、storage footprint aggregation 和
显式 C2 setup/storage/update 阈值。

## 2026-06-16 追加：projected-volume baseline 后的 v3 ledger

后续 `docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md` 补上了
同一 W2 nginx workload 的 `projected_volume` baseline，并把 canonical W2
feature-baseline run 推进到：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v3/w2-nginx-baseline-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v3/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

v3 baseline summary 为 `baseline_count=4`、`setup_rows=80`、`update_rows=80`、
`correctness_rows=80`、`pass=true`、`failures=0`，覆盖 `copy_tree`、
`symlink_forest`、`bind_mount` 和 `projected_volume`。v3 ledger summary 新增
`projected_volume_baseline_pass=true` 和
`copy_symlink_bind_projected_baselines_pass=true`。

判读不变：W2 仍是 partial C2 input。缺口缩小为 FUSE baseline、storage footprint
aggregation 和显式 C2 setup/storage/update 阈值。

## 2026-06-16 追加：FUSE baseline 后的 v4 ledger

后续 `docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md` 补上了同一 W2 nginx
workload 的 `fuse_redirect` baseline，并把 canonical W2 feature-baseline run 推进到：

```text
results/phase1/20260616T-w2-nginx-baseline-macrobench-release-sample-v4/w2-nginx-baseline-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v4/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

v4 baseline summary 为 `baseline_count=5`、`setup_rows=100`、`update_rows=100`、
`correctness_rows=100`、`pass=true`、`failures=0`，覆盖 `copy_tree`、
`symlink_forest`、`bind_mount`、`projected_volume` 和 `fuse_redirect`。v4 ledger summary
新增 `fuse_baseline_pass=true`、`all_feature_baselines_pass=true` 和
`full_feature_equivalent_baseline_pass=true`。

判读不变：W2 仍是 partial C2 input。缺口从 FUSE/storage/threshold 缩小为 storage
footprint aggregation 和显式 C2 setup/storage/update 阈值。

## 2026-06-16 追加：storage/threshold 后的 v5 ledger

后续 `docs/tmp/2026-06-16-w2-nginx-storage-threshold-design.md` 和
`docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md` 把 W2 workload ledger
从五类 baseline input 推进为 thresholded slice。canonical ledger run 推进到：

```text
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-ledger-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl
results/eval-osdi/paper/20260616T-eval-w2-nginx-workload-macrobench-hardgate-v5/b3-macrobench/w2-nginx-workload-macrobench.jsonl
```

v5 ledger summary 为 `storage_footprint_pass=true`、
`setup_latency_threshold_pass=true`、`update_latency_threshold_pass=true`、
`update_materialization_threshold_pass=true`、`threshold_pass=true` 和
`w2_c2_slice_supported=true`。关键均值为：

- proposed setup latency 7.50 ms，最快 baseline setup latency 9.96 ms；
- proposed update latency 13.91 us，最快 baseline update latency 14.04 us；
- proposed setup objects 17，最少 baseline setup objects 19；
- proposed setup bytes 5931，最少 baseline setup bytes 5931。

全局 `c2_supported=false` 和 `release_gate_pass=false` 不变，因为当前缺口已经变成
W1/W3/W4 workload setup/storage/update macrobench。正确论文表述也随之变化：W2 nginx
fixture slice 可以写成 storage/threshold-supported，但全局 C2 仍是 unsupported。
