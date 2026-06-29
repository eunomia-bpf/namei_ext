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

## What an OSDI reviewer would still ask

For W4, the targeted epoch gate now answers the narrow update-budget mechanism: static exact table fails the cache epoch
oracle, while externally updated exact table, materialized cache view, and FUSE cache view all need 16x the policy's
epoch-switch update writes. The next reviewer-level step is to lift this into a real cache workload:

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

- W4 now has both a static-table failure under dynamic state and a targeted cache-epoch update-budget failure for
  externally updated exact tables; the same run also includes feature-equivalent materialized and FUSE cache-epoch
  views that pass correctness but pay the same 16x update-write ratio. It still lacks real ccache/BuildKit
  operation-weighted release evidence.
- W3 now has a targeted epoch fixture where static table fails and externally updated table plus materialized
  checkpoint view plus FUSE checkpoint view all exceed the update-write budget, but the run explicitly records
  `real_podman_criu_restore=false`, `qualified_for_c8=false`, and `release_gate_pass=false`.
- Literature supports the motivation for dynamic filesystem/path-state mechanisms, but the C8 proof must come from
  these counterfactual experiments.
