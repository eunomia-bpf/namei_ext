# C8 mechanism update: exact-map boundary evidence

> 2026-06-29 story scope update: this targeted mechanism note preserves historical reasoning and results, but the current paper story is `docs/tmp/2026-06-29-paper-story-scope-update.md`. C8 is now a balanced dynamic path-view claim over expressiveness, safety, and efficiency; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the relevant alternative.

## Motivation

本记录回应 2026-06-29 的 C8 机制问题：不能只说相关工作用了 FUSE 或自定义文件系统，也不能用
"eBPF 能跑"替代证据。按当前 story，这不是 C8 主线，只是 exact-map boundary evidence：

> 在真实或真实形状的动态 workload 中，`table_redirect.bpf.c` 的 exact table 是否能在同等
> correctness、update budget、stale-window budget 和 materialization budget 下替代
> eBPF policy logic？

本次使用 `osdi-experiment-design` skill 的实验标准：正确性先 gate，性能/成本数字只在正确性成立后解释；
每个 claim 必须有对应自然机制或 workload-specific baseline；负结果必须保留，不能把 table-only
也能通过的结果写成 C8 正证据。

## Related-work inputs downloaded

本次把 C8 相关论文 PDF 下载到 `docs/reference/`，并新增 `docs/reference/INDEX.md` 记录来源、用途和
SHA256。覆盖的设计点包括：

- FUSE 性能和扩展：FAST 2017 "To FUSE or Not to FUSE"、ATC 2019 ExtFUSE。
- 用户态 FS 实用性和 stackable FS：HotStorage 2015 Terra Incognita、USENIX 1999 Wrapfs。
- 自定义/内核文件系统动机：FAST 2021 Bento、FAST 2016 NOVA。
- metadata/layout-oriented filesystems：ATC 2013 TABLEFS、SC 2014 IndexFS、FAST 2015 BetrFS、
  FAST 2016 Composite-file FS。
- 动态 namespace/metadata state：SC 2021 DeltaFS、PDSW 2017 DeltaFS Indexed Massive Directory。
- checkpoint/path virtualization：DMTCP path virtualization material。
- agent workspace filesystem：YoloFS、BranchFS。

这些论文不能替我们证明 `table_redirect.bpf.c` 对 W3/W4 不够。它们只能说明为什么现实系统会选择
FUSE、自定义 FS、stackable FS 或 namespace service：它们需要动态状态、生命周期、write path、
remote/object backing、snapshot/rollback、permission/audit 或 metadata-log semantics。C8 仍必须由
本项目的 workload counterfactual 实验回答。

## Existing W4 dynamic gate inspected

代码中已有专门的 W4 transition gate：

- runner: `tests/w1_oracle/namei_ext_w1_oracle.c`
- mode: `--cache-transition-counterfactual`
- Make target: `make kvm-w4-cache-transition-counterfactual`
- raw output: `results/phase1/<RUN_ID>/w4-cache-transition-counterfactual.jsonl`

该 gate 每个 sample 跑三个系统：

1. `cache_locality_state_policy`: `cache_locality_view.bpf.c`，根据 cache state 在
   verified/local、stale/canonical、corrupt/reject 之间切换。
2. `table_redirect_static_verified`: `table_redirect.bpf.c`，把 stateful entries 固定指向
   verified local cache target。它应该在 stale/corrupt 当前 oracle 下产生 wrong-local hit。
3. `table_redirect_updated_exact`: `table_redirect.bpf.c`，外部更新 exact lookup/readdir table 后再检查
   correctness。它若通过，说明当前证据仍不能支持 C8，只能说明 static table 不够。

这个实验比原来的 W4 cache-content comparator 更接近 C8，因为它同一个 visible name 会跨状态改变
解析目标。

## Validation run on 2026-06-29

Smoke run:

```sh
make kvm-w4-cache-transition-counterfactual \
  RUN_ID=20260629T-w4-cache-transition-c8-smoke-v1 \
  W4_CACHE_TRANSITION_SAMPLES=1
```

Release-style run:

```sh
make kvm-w4-cache-transition-counterfactual \
  RUN_ID=20260629T-w4-cache-transition-c8-release-v1 \
  W4_CACHE_TRANSITION_SAMPLES=20
```

The 20-sample KVM run completed successfully in the modified kernel. Input hash
verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w4-cache-transition-c8-release-v1/w4-cache-transition-counterfactual-inputs.sha256
```

The dmesg hard gate found zero kernel diagnostics matching the configured
`BUG`, `WARNING`, `Oops`, panic, hung-task, or kernel-BUG pattern.

## Result summary

`results/phase1/20260629T-w4-cache-transition-c8-release-v1/w4-cache-transition-counterfactual.jsonl`
contains 464 raw JSONL rows. The summary row reports:

- `samples=20`
- `setup_rows=60`
- `correctness_rows=240`
- `update_rows=160`
- `entries=4`
- `stateful_entries=2`
- `static_wrong_local_hits=40`
- `policy_transition_rows=80`
- `table_transition_rows=80`
- `policy_transition_passes=80`
- `table_transition_passes=80`
- `state_transition_hit_rate=1`
- `policy_update_writes=160`
- `table_update_writes=160`
- `table_update_write_ratio=1`
- `table_static_current_oracle_pass=false`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This run answers one important part of C8:

- A static exact table fixed to verified local targets is not enough for W4 stale/corrupt dynamic semantics.
- The failure is a correctness-oracle failure, not only a performance or setup-cost difference.
- The failure happens under KVM with the real `cgroup/namei_ext` attach path.

But it does not prove full C8:

- The externally updated exact table still passes.
- The measured update-write ratio is `1`, so this run does not show table/update writes over budget.
- The run uses make-owned cache-state fixtures derived from Redis/nginx/Prometheus sources; it is not yet a real
  ccache stale/corrupt transition trace or BuildKit/Prometheus Go-cache transition trace.
- Therefore the correct paper wording is: "static exact table fails W4 cache-state transitions; exact table with
  external updates remains a viable counterfactual for this fixture, so C8 remains unsupported."

## New W2 fixture epoch gate

After the W3/W4 targeted gates, this update added a W2 fixture-epoch counterfactual because W2 is the current positive
setup/update slice but did not yet test whether fixture selection needs policy state rather than a static table. The new
target keeps visible fixture names stable while the backing epoch changes across config, secret, cert, endpoint, and
poison path classes.

New Make target:

```sh
make kvm-w2-fixture-epoch-counterfactual
```

Release-style validation run:

```sh
make kvm-w2-fixture-epoch-counterfactual \
  RUN_ID=20260629T-w2-fixture-epoch-c8-release-v1 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

The implementation and validation record is
`docs/tmp/2026-06-30-w2-fixture-epoch-counterfactual.md`.

The target compares five systems:

1. `sandbox_fixture_epoch_policy`: `sandbox_fixture_view.bpf.c` preloads both epoch rule sets and switches
   `fixture_sessions[cgroup_id].fixture_epoch` with one map update.
2. `table_redirect_static_fixture_epoch1`: `table_redirect.bpf.c` fixed to epoch 1, expected to fail epoch 2.
3. `table_redirect_updated_fixture_exact`: `table_redirect.bpf.c` externally rewrites exact lookup rows from epoch 1
   to epoch 2, expected to pass correctness but pay per-object updates.
4. `materialized_fixture_epoch_view`: external materialized view that copies epoch-1 fixture backings into visible
   files and then copies epoch-2 backings over those visible files.
5. `fuse_fixture_epoch_view`: external FUSE view that exposes stable visible names and switches epoch by copying each
   epoch-2 object into a private FUSE shadow backing.

The summary row from
`results/phase1/20260629T-w2-fixture-epoch-c8-release-v1/w2-fixture-epoch-counterfactual.jsonl` reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `dynamic_fixture_classes=5`
- `static_wrong_fixture_hits=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `fuse_update_writes=320`
- `fuse_mounts=20`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `fuse_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=true`
- `materialized_current_oracle_pass=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
- `fuse_current_oracle_pass=true`
- `fuse_feature_equivalent_baseline=true`
- `fuse_update_budget_failure=true`
- `targeted_c8_budget_failure=true`
- `state_dependent_branch_not_static_table_expressible=true`
- `real_nginx_trace=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

Input hash verification passed and the dmesg hard gate found zero matching kernel diagnostics. This is stronger than
the prior W2 setup/update evidence for one C8 criterion: static exact table fails the state-dependent epoch oracle, and
the externally updated exact table, materialized view, and FUSE view preserve correctness only with 16x update writes.
It is still not a full W2 C8 result because it is a targeted fixture-epoch oracle, not a real nginx reload/update trace.

## New W3 checkpoint epoch gate

After the W4 result, this update added a W3 targeted epoch counterfactual because the existing Redis checkpoint
replay was a negative C8 control: `table_redirect.bpf.c` could pass the same static `dump.rdb` remap. The new target
forces the visible checkpoint names to stay fixed while the correct backing epoch changes.

New Make target:

```sh
make kvm-w3-checkpoint-epoch-counterfactual
```

Release-style validation run:

```sh
make kvm-w3-checkpoint-epoch-counterfactual \
  RUN_ID=20260629T-w3-checkpoint-epoch-c8-fuse-v2 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

The target now compares five systems:

1. `checkpoint_epoch_policy`: `checkpoint_restore_view.bpf.c` preloads rules for both epochs and switches
   `checkpoint_sessions[cgroup_id].checkpoint_epoch` with one map update.
2. `table_redirect_static_epoch1`: `table_redirect.bpf.c` fixed to epoch 1, expected to fail epoch 2.
3. `table_redirect_updated_exact`: `table_redirect.bpf.c` externally rewrites exact lookup rows from epoch 1 to
   epoch 2, expected to pass correctness but pay per-object updates.
4. `materialized_checkpoint_epoch_view`: external materialized view that copies epoch-1 checkpoint backings into
   visible files and then copies epoch-2 backings over those visible files.
5. `fuse_checkpoint_epoch_view`: external FUSE view that exposes stable visible names and switches epoch by copying
   each epoch-2 object into a private FUSE shadow backing.

The summary row from
`results/phase1/20260629T-w3-checkpoint-epoch-c8-fuse-v2/w3-checkpoint-epoch-counterfactual.jsonl` reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `static_wrong_epoch_hits=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `fuse_update_writes=320`
- `fuse_mounts=20`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `fuse_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=true`
- `materialized_current_oracle_pass=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
- `fuse_current_oracle_pass=true`
- `fuse_feature_equivalent_baseline=true`
- `fuse_update_budget_failure=true`
- `targeted_c8_budget_failure=true`
- `real_podman_criu_restore=false`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

This is stronger than the original W3 table diagnostic for one C8 criterion: the externally updated exact table keeps
correctness but exceeds the declared update-write budget, and both external materialized and FUSE checkpoint views pay
the same per-object update count. It is still not full W3 C8 evidence because it is a targeted epoch fixture, not a
real Podman/CRIU restore.

## New W4 cache epoch gate

The W4 transition result above only proved static-table failure. This update added a second W4 targeted counterfactual
that forces many ccache-shaped visible names to change backing epoch together:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-fuse-v1 \
  W4_CACHE_EPOCH_SAMPLES=20 \
  W4_CACHE_EPOCH_OBJECTS=16
```

The target now compares five systems:

1. `cache_locality_epoch_policy`: `cache_locality_view.bpf.c` preloads verified-local and canonical epoch rules and
   switches `cache_epoch_sessions[cgroup_id].cache_epoch` with one map update.
2. `table_redirect_static_verified_epoch`: `table_redirect.bpf.c` fixed to verified local objects, expected to fail
   when the oracle switches to canonical objects.
3. `table_redirect_updated_exact_epoch`: `table_redirect.bpf.c` externally rewrites exact lookup rows to canonical
   objects, expected to pass correctness but pay per-object updates.
4. `materialized_cache_epoch_view`: external materialized view that copies epoch-1 local objects into visible files
   and then copies epoch-2 canonical objects over those files.
5. `fuse_cache_epoch_view`: external FUSE view that exposes stable visible names and switches epoch by copying each
   canonical object into a private FUSE shadow backing.

The summary row from
`results/phase1/20260629T-w4-cache-epoch-c8-fuse-v1/w4-cache-epoch-counterfactual.jsonl` reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `static_wrong_local_hits=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `fuse_update_writes=320`
- `fuse_mounts=20`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `fuse_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=true`
- `materialized_current_oracle_pass=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
- `fuse_current_oracle_pass=true`
- `fuse_feature_equivalent_baseline=true`
- `fuse_update_budget_failure=true`
- `targeted_c8_budget_failure=true`
- `real_ccache_trace=false`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

This is the strongest current W4 targeted result: the externally updated exact table preserves correctness but loses
the update-write budget gate, and the external materialized and FUSE views also preserve correctness only by paying
the same per-object update count. It is still not full W4 C8 evidence because it is a targeted cache-epoch fixture,
not an operation-weighted ccache or BuildKit trace.

## W4 real ccache compile release refresh

After the targeted cache-epoch result, this update refreshed the real ccache bulk compile side of W4 so that the
operation-weighted workload input is no longer only a smoke witness. The implementation and validation record is
`docs/tmp/2026-06-29-w4-bulk-compile-release-refresh.md`.

Commands:

```sh
make kvm-w4-ccache-bulk-policy-compile \
  RUN_ID=20260629T-w4-ccache-bulk-policy-compile-release-v1 \
  W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES=20
make kvm-w4-ccache-bulk-native-compile \
  RUN_ID=20260629T-w4-ccache-bulk-native-compile-release-v2 \
  W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=20
make kvm-w4-ccache-bulk-fuse-compile \
  RUN_ID=20260629T-w4-ccache-bulk-fuse-compile-release-v2 \
  W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=20
```

The proposed policy-attached compile run reports:

- `samples=20`
- `compile_rows=20`
- `attached_compile_jobs=400`
- `attached_compile_output_matches=400`
- `policy_executed=true`
- `ccache_compile_policy_executed=true`
- `policy_redirected_cache_objects=800`
- `attached_cache_path_file_ops=8000`
- `attached_policy_cache_object_ops=3200`
- `attached_sampled_operation_hit_rate=0.4`
- `pass=true`
- `failures=0`

The native ccache compile baseline reports `samples=20`, `total_compile_jobs=400`,
`total_compile_output_matches=400`, `compile_ns_avg=7562011642.3500004`,
`cache_path_file_ops=8000`, `cache_object_ops=3200`, `direct_cache_hit=400`, and `pass=true`.

The FUSE compile baseline reports `samples=20`, `total_compile_jobs=400`,
`total_compile_output_matches=400`, `compile_ns_avg=14030225541.1`,
`cache_path_file_ops=6000`, `cache_object_ops=3200`, `direct_cache_hit=400`,
`fuse_mounts=20`, and `pass=true`.

The derived W4 ledger
`results/eval-osdi/paper/20260629T-eval-w4-ccache-workload-macrobench-ledger-v10/b3-macrobench/w4-ccache-workload-macrobench.jsonl`
now records `bulk_policy_compile_release_input_pass=true`, `bulk_native_compile_baseline_pass=true`,
`bulk_fuse_compile_baseline_pass=true`, and `bulk_external_baseline_release_input_pass=true`. The same summary still
records `bulk_release_comparison_pass=false`, `w4_c2_slice_supported=false`, `c2_supported=false`, and
`release_gate_pass=false`.

This closes a W4 compile-input gap, not the C8 proof. The real ccache runs show policy-attached compile correctness,
operation-weighted cache-path activity, and feature-equivalent native/FUSE compile baselines. They do not yet inject
stale/corrupt state, measure stale windows, or show that an externally updated exact table fails or exceeds budget
under real trace-derived dynamic conditions.

## W4 trace-derived cache epoch counterfactual

After the real ccache compile refresh, this update added a trace-derived version of the cache-epoch counterfactual.
The implementation and validation record is
`docs/tmp/2026-06-29-w4-trace-derived-cache-epoch-counterfactual.md`.

Command:

```sh
make kvm-w4-ccache-bulk-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1 \
  W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES=20 \
  W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS=16
```

The target first runs the Make-owned bulk ccache trace/bridge flow, then uses the 40 Redis/nginx trace-derived cache
objects as the candidate object set for the dynamic epoch oracle. The summary row from
`results/phase1/20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1/w4-ccache-bulk-cache-epoch-counterfactual.jsonl`
reports:

- `samples=20`
- `objects=16`
- `trace_entries=40`
- `static_wrong_local_hits=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `fuse_update_writes=320`
- `fuse_mounts=20`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `fuse_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_update_budget_failure=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
- `fuse_feature_equivalent_baseline=true`
- `fuse_update_budget_failure=true`
- `targeted_c8_budget_failure=true`
- `real_ccache_trace=true`
- `trace_derived_counterfactual=true`
- `trace_derived_targeted_c8_pass=true`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

This strengthens the W4 exact-table boundary compared with the synthetic cache-epoch fixture: the dynamic object set is
derived from a real ccache Redis/nginx trace, and all five systems are compared under the same correctness oracle.
The result shows that static exact table fails and externally updated exact table, materialized view, and FUSE view
only preserve correctness by paying 16x the policy update writes.

The boundary remains important. The run uses trace-derived names and SHA provenance, but the epoch payloads are
controlled oracle payloads rather than real ccache object bytes consumed by a live compile. It is therefore
trace-derived C8 mechanism evidence, not full W4 release evidence; the correct summary stays `qualified_for_c8=false`.

## W1 build-epoch counterfactual

After W2/W3/W4 had five-system targeted epoch/cache counterfactuals, this update added the same shape for W1 build
graph state. The implementation and validation record is
`docs/tmp/2026-06-30-w1-build-epoch-counterfactual.md`.

Command:

```sh
make kvm-w1-build-epoch-counterfactual \
  RUN_ID=20260630T-w1-build-epoch-c8-release-v1 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

The target compares five systems:

1. `build_graph_epoch_policy`: `build_graph_view.bpf.c` preloads both epoch rule sets and switches
   `build_graph_sessions[cgroup_id].build_epoch` with one map update.
2. `table_redirect_static_build_epoch1`: `table_redirect.bpf.c` fixed to epoch 1, expected to fail epoch 2.
3. `table_redirect_updated_build_exact`: `table_redirect.bpf.c` externally rewrites exact lookup rows from epoch 1
   to epoch 2, expected to pass correctness but pay per-object updates.
4. `materialized_build_epoch_view`: external materialized view that copies epoch-1 build backings into visible files
   and then copies epoch-2 backings over those visible files.
5. `fuse_build_epoch_view`: external FUSE alias view that switches epoch by copying each epoch-2 object into a
   private FUSE shadow backing.

The summary row from
`results/phase1/20260630T-w1-build-epoch-c8-release-v1/w1-build-epoch-counterfactual.jsonl` reports:

- `samples=20`
- `objects=16`
- `dynamic_build_branches=5`
- `static_wrong_epoch_hits=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `fuse_update_writes=320`
- `fuse_mounts=20`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `fuse_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=true`
- `materialized_current_oracle_pass=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
- `fuse_current_oracle_pass=true`
- `fuse_feature_equivalent_baseline=true`
- `fuse_update_budget_failure=true`
- `targeted_c8_budget_failure=true`
- `state_dependent_branch_not_static_table_expressible=true`
- `real_redis_nginx_trace=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

Input hash verification passed, `git diff --check` passed, and the dmesg hard gate found zero matching kernel
diagnostics. The result gives W1 the same targeted boundary evidence as W2/W3/W4: static exact table fails the
state-dependent epoch oracle, while externally updated exact table, materialized view, and FUSE view preserve
correctness only with 16x the policy update writes. It is not a full W1 C8 result because it does not replay live
Redis/nginx build operations or measure operation-weighted branch distribution under a real build trace.

## What an OSDI reviewer would still ask

For W1, the targeted build-epoch gate now answers the narrow update-budget mechanism: static exact table fails the
state-dependent build epoch oracle, while externally updated exact table, materialized build view, and FUSE build view
all need 16x the policy's epoch-switch update writes. The next reviewer-level step is to lift this into a real build
workload:

- run Redis/nginx or another real build trace across generated/source/toolchain/dependency/poison epoch changes;
- preserve compile success, output hashes, trace provenance, and operation-weighted branch distribution;
- issue operations during the table-update stale window and check output hash or poison rejection;
- compare copy, symlink, bind, projected/Overlay where applicable, FUSE, and exact table under the same build epoch
  oracle.

For W2, the targeted fixture-epoch gate now answers the narrow update-budget mechanism: static exact table fails the
state-dependent fixture epoch oracle, while externally updated exact table, materialized fixture view, and FUSE fixture
view all need 16x the policy's epoch-switch update writes. The next reviewer-level step is to lift this into a real
service fixture workload:

- run a real nginx reload/update or PostgreSQL secret/config rotation trace rather than controlled epoch payloads;
- preserve real app health, endpoint response, config/secret/cert hash, no-production-open trace, and poison coverage;
- issue operations during the stale window and check whether static/external table update lag can expose the wrong
  fixture epoch;
- compare projected-volume or Compose-style native mechanisms, FUSE, and materialized views under the same update
  oracle.

For W4, the targeted epoch gate now answers the narrow update-budget mechanism: static exact table fails the cache epoch
oracle, while externally updated exact table, materialized cache view, and FUSE cache view all need 16x the policy's
epoch-switch update writes. The trace-derived ccache bulk cache-epoch gate repeats that result on real trace-derived
object names and SHA provenance, but it still does not run a live compile through stale/corrupt/update-window
conditions. The next reviewer-level step is to lift this into a real cache workload:

1. `correctness oracle fail`: run real ccache or BuildKit where the table cannot observe or update state before an
   operation consumes stale/corrupt local content.
2. `table/update writes over budget`: reproduce the epoch fanout using trace-derived ccache or BuildKit objects, not
   only the targeted fixture.
3. `stale window over budget`: measure time from backing-state change to table update completion, with operations
   issued during the window and checked by output hash / reject oracle.
4. `operation-weighted branch cannot be static table`: report cache-path operations, branch distribution, and
   wrong-local attempts under the actual compile/build trace, not just four fixture entries.
5. `same correctness, worse materialization`: compare FUSE, materialized view, copy/symlink/bind/projected/Overlay
   where applicable under the same dynamic state transitions.

For W3, the targeted epoch gate now answers the narrow update-budget mechanism: static exact table fails the epoch
oracle, while externally updated exact table, materialized checkpoint view, and FUSE checkpoint view all need 16x the
policy's epoch-switch update writes. The next reviewer-level step is to lift this into a real checkpoint/restore
workload:

- run real Podman/CRIU or an equivalent restored Redis/nginx workflow after the capability blocker is cleared;
- preserve restore stdout/stderr, checkpoint archive identity, post-restore health, output hash, and VFS trace;
- prove zero mixed epoch under lookup and readdir, including a poison object;
- measure stale window while the externally updated table rewrites lookup/readdir rows;
- compare FUSE and materialized checkpoint views under the same restore epoch transitions.

## Claim impact

The current C8 status is improved but still unsupported:

- W1 now has a targeted build-epoch counterfactual where static table fails and externally updated table plus
  materialized build view plus FUSE build view all exceed the update-write budget, but the run explicitly records
  `real_redis_nginx_trace=false`, `qualified_for_c8=false`, and `release_gate_pass=false`.
- W2 now has a targeted fixture-epoch counterfactual where static table fails and externally updated table plus
  materialized fixture view plus FUSE fixture view all exceed the update-write budget, but the run explicitly records
  `real_nginx_trace=false`, `qualified_for_c8=false`, and `release_gate_pass=false`.
- W4 now has both a static-table failure under dynamic state and a targeted cache-epoch update-budget failure for
  externally updated exact tables; the same run also includes feature-equivalent materialized and FUSE cache-epoch
  views that pass correctness but pay the same 16x update-write ratio. W4 now also has 20-sample real ccache
  policy/native/FUSE compile release inputs, and a trace-derived ccache bulk cache-epoch counterfactual where
  `real_ccache_trace=true` and the exact-table/materialized/FUSE update ratio is again 16. These runs are still
  boundary evidence; they do not yet include stale/corrupt/update-window table-only failure during a live compile.
- W3 now has a targeted epoch fixture where static table fails and externally updated table plus materialized
  checkpoint view plus FUSE checkpoint view all exceed the update-write budget, but the run explicitly records
  `real_podman_criu_restore=false`, `qualified_for_c8=false`, and `release_gate_pass=false`.
- Literature supports the motivation for dynamic filesystem/path-state mechanisms, but the C8 proof must come from
  these counterfactual experiments.
