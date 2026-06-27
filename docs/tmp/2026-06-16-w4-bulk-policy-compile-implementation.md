# W4 bulk policy-attached ccache compile implementation

来源：Phase 1 OSDI evaluation gate loop，针对 W4 ccache bulk workload 仍缺
proposed-system policy-attached compile witness 的缺口。

## Motivation

已有 W4 bulk trace 和 policy bridge 证明 Redis/nginx 多 source ccache hot compile 会触达
真实 `CCACHE_DIR`，且 trace-derived cache objects 能通过 `cache_locality_view.bpf.c`
content oracle。但这仍不是 proposed system 的 compile witness：policy bridge 只在
cache-object oracle 中执行 BPF policy，真实 ccache compile 没有在 policy attached 状态下
运行。

本步骤增加一个 Make-owned KVM target，让同一 bulk source manifest 下的 hot ccache compiles
在 attached `cache_locality_view.bpf.c` policy 下运行，并逐个比较 policy output object
与 bulk trace hot object。该步骤仍不声明 C2/C8 通过；它只补 W4 bulk proposed-system
raw input。

## Code paths inspected

- `mk/kvm.mk`
  - `kvm-w4-ccache-bulk-trace`
  - `kvm-w4-ccache-bulk-policy-bridge`
  - sampled `kvm-w4-ccache-policy-compile`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - `run_ccache_policy_compile()`
  - `ccache_entry_from_source()`
  - `run_ccache_redis_compile()`
  - `run_ccache_nginx_compile()`
- `Makefile`
  - public target list and help text

## Design

The new target is:

```text
make kvm-w4-ccache-bulk-policy-compile
```

It depends on `kvm-w4-ccache-bulk-policy-bridge`, then boots the modified kernel
again and runs:

```text
namei_ext_w1_oracle --ccache-bulk-policy-compile
```

The runner reuses the existing ccache policy compile path, with bulk-specific
inputs:

- bulk entries TSV from `w4-ccache-bulk-policy-bridge`;
- source manifest from `w4-ccache-bulk-trace`;
- copied hot `CCACHE_DIR`;
- baseline hot object directory from the bulk trace work tree.

For every source in the manifest, the runner writes:

- `<kind>-<source>.policy.o`;
- `<kind>-<source>.policy.stdout`;
- `<kind>-<source>.policy.stderr`;
- `<kind>-<source>.policy.strace.log`.

The owning Make target fails if source count, policy output count, strace count,
compile jobs, output matches, ccache direct hits, policy object ops, or dmesg
scan do not pass.

## Implementation details

- `ccache_entry_from_source()` now accepts both `trace-derived/<source>/...` and
  `trace-derived-bulk/<source>/...`, preserving sampled W4 behavior while making
  bulk bridge entries eligible for compile optrace accounting.
- `struct w4_ccache_source` and source-manifest parsing were added to
  `tests/w1_oracle/namei_ext_w1_oracle.c`.
- `run_ccache_policy_compile()` now has optional bulk inputs. Existing sampled,
  parent-rule, and table-redirect call sites pass `NULL` bulk inputs and keep the
  previous event names.
- Bulk mode overrides events to `w4-ccache-bulk-policy-compile` and summary event
  `w4-ccache-bulk-policy-compile-summary`.
- The summary records `bulk_policy_compile`, `source_manifest_count`,
  `attached_compile_jobs`, and `attached_compile_output_matches`.
- `mk/kvm.mk` adds `kvm-w4-ccache-bulk-policy-compile` and
  `__phase1_guest_w4_ccache_bulk_policy_compile`.
- The top-level `Makefile` exposes the target in `.PHONY` and `make help`.

## Validation plan

1. Build the runner and BPF objects:

```text
make w1-oracle bpf
```

2. Run the KVM target:

```text
make kvm-w4-ccache-bulk-policy-compile RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1
```

3. Verify input sha:

```text
sha256sum -c results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile-inputs.sha256
```

## Validation performed

Host build:

```text
make w1-oracle bpf
```

passed. `w1-oracle` rebuilt
`.build/w1-oracle/namei_ext_w1_oracle`; BPF objects were already current.

KVM target:

```text
make kvm-w4-ccache-bulk-policy-compile \
  RUN_ID=20260616T-w4-ccache-bulk-policy-compile-smoke-v1
```

passed. The run produced:

```text
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-trace.jsonl
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-bridge.jsonl
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile.jsonl
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile-inputs.sha256
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile-outputs.sha256
results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/dmesg-w4-ccache-bulk-policy-compile.log
```

Host-side input verification:

```text
sha256sum -c results/phase1/20260616T-w4-ccache-bulk-policy-compile-smoke-v1/w4-ccache-bulk-policy-compile-inputs.sha256
```

passed for all recorded inputs.

Key summary fields from
`w4-ccache-bulk-policy-compile-summary`:

```text
workload=w4-ccache-bulk-redis-nginx
bulk_policy_compile=true
source_manifest_count=20
attached_compile_jobs=20
attached_compile_output_matches=20
policy_executed=true
ccache_compile_policy_executed=true
output_hash_match=true
policy_redirected_cache_objects=40
redis_trace_objects=20
nginx_trace_objects=20
pass=true
failures=0
attached_optrace_collected=true
attached_cache_path_file_ops=400
attached_policy_cache_object_ops=160
direct_cache_hit=20
local_storage_hit=20
qualified_for_c8=false
```

The work directory contains 40 checked files: 20 `*.policy.o` outputs and
20 `*.policy.strace.log` files. The dmesg BUG/WARNING/Oops/hung-task scan for
`dmesg-w4-ccache-bulk-policy-compile.log` returned 0.

## Remaining risks

- This target closes only the bulk proposed-system policy-attached compile witness.
  W4 still needs bulk external baselines beyond materialized-cache view, including
  the requested FUSE/cache-remap-style baseline if it is to support a stronger C2
  comparison.
- `operation_weighted_policy_cache_hit_rate` remains false because this target
  records raw strace-derived counts but does not yet perform the release-level
  operation-weighted ledger.
- The target does not upgrade C8. Table-only comparators and stale/corrupt/update
  transition gates still decide whether W4 can support a distinct-policy claim.
