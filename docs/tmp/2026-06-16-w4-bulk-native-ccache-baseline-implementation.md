# W4 Bulk Native ccache Baseline Implementation

Date: 2026-06-16

## Motivation

The W4 bulk ccache ledger already contains proposed-system setup/update input,
a policy-attached compile smoke witness, a materialized cache-view baseline,
and a FUSE cache-view baseline. Review still flagged a missing native or
cache-remap baseline. This step adds a Make-owned KVM baseline that runs native
ccache hot compiles on the same 20-source bulk Redis/nginx shape without
attaching any `namei_ext` policy.

This target is a baseline input. It must not mark C2 or C8 as supported by
itself.

## Code Paths Inspected

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Existing W4 bulk policy compile witness.
  - Existing ccache source manifest parser and compile helpers.
  - Existing ccache strace operation counter.
- `mk/kvm.mk`
  - W4 bulk trace, policy bridge, policy compile, and macrobench targets.
- `Makefile`
  - Top-level target and help entries.

## Design

The new runner mode is `--ccache-bulk-native-compile`. For each sample, it:

1. copies the hot `CCACHE_DIR` captured by the W4 bulk trace target;
2. sets `CCACHE_DIR` to that sample-local copy;
3. runs the same Redis/nginx source compile set from the source manifest;
4. records strace cache-path operations for each compile;
5. compares each output object with the hot baseline object; and
6. prints ccache stats for the sample.

The emitted rows are `w4-ccache-bulk-native-compile-sample` and
`w4-ccache-bulk-native-compile-summary`. They record compile latency, cache-path
operations, object operations, direct cache hits, local storage hits, and output
hash matches. All rows record `policy_executed=false`,
`feature_equivalent_baseline=true`, `c2_supported=false`, and
`release_gate_pass=false`.

## Alternatives Rejected

- Reusing the policy-attached compile witness as a native baseline was rejected
  because that witness renames cache objects to `.local` backing files and
  attaches `cache_locality_view.bpf.c`.
- Treating the existing FUSE cache-view target as a full native-cache baseline
  was rejected because it does not execute ccache create/write/rename behavior.
- Running ccache directly from an ad hoc command was rejected because project
  workflows must go through Make targets.

## Validation Plan

1. Build the W1/W4 runner with `make w1-oracle`.
2. Run a 1-sample KVM smoke:
   `make kvm-w4-ccache-bulk-native-compile
   RUN_ID=20260616T-w4-ccache-bulk-native-compile-smoke-v1
   W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=1`.
3. Check sample row count, summary fields, direct-hit count, output hashes,
   input hashes, and dmesg issue scan.
4. If the smoke passes, run a 20-sample release input and integrate it into the
   W4 ledger as a native external baseline.

## Remaining Risks

The target measures native ccache hot compiles over the same source/object
shape, but it does not by itself prove a table-only budget failure or stale
window. If native ccache is faster than `namei_ext`, the result should be
reported as negative W4 evidence and used to narrow the claim.

## Release Validation

The 20-sample KVM release input was run through the Make target:

```text
make kvm-w4-ccache-bulk-native-compile \
  RUN_ID=20260616T-w4-ccache-bulk-native-compile-release-v1 \
  W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=20
```

The release JSONL is
`results/phase1/20260616T-w4-ccache-bulk-native-compile-release-v1/w4-ccache-bulk-native-compile.jsonl`.
Its summary row records `pass=true`, 20 samples, 20 compile rows, 400 total
compile jobs, 400 output-object matches, 400 direct cache hits, zero ccache
misses, 400 local-storage hits, 8000 cache-path file operations, 3200 cache
object operations, sampled operation hit rate 0.40, and
`operation_weighted_native_hit_rate_is_release=true`.

The native run remains an external baseline: it has `policy_executed=false` and
`feature_equivalent_baseline=true`. It is suitable for W4 comparison input but
does not support C2/C8 by itself.
