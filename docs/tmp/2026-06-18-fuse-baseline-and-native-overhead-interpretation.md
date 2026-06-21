# FUSE baseline and native-overhead interpretation

## Motivation

This note records the evaluation interpretation discussed after the scoped
weak-accept audit. The key question was whether the paper should primarily
compare `namei_ext` against FUSE, what the current FUSE results show, why the
full-suite native-overhead gate still fails, and whether the current
microbenchmark suite is measuring the right thing.

## Baseline taxonomy

The current evaluation uses two different kinds of baselines.

For setup, update, storage, and materialization costs, the feature-equivalent
baseline set is:

- `copy_tree`
- `symlink_forest`
- `bind_mount`
- `projected_volume`
- `fuse_redirect`

For metadata latency, the comparison set is:

- `native`: lower filesystem/VFS without a `namei_ext` policy attached;
- `pass_only`: `namei_ext` hook attached, but the policy always returns
  `PASS`;
- `policy`: redirect policy attached;
- `table_redirect_hit`: exact-table redirect policy attached;
- `fuse_redirect`: user-space FUSE path-view baseline.

The strongest reviewer-facing programmable-path baseline is FUSE. Native is not
a feature-equivalent programmable baseline; it is the overhead floor used to
bound how far the current hook placement is from ordinary VFS path resolution.

## Current FUSE comparison

The current release comparison run is:

```text
results/eval-osdi/paper/20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v6/b2-performance/performance-comparison.jsonl
```

All seven shared metadata benches pass the FUSE speedup threshold. The current
policy/FUSE p99 speedups are:

- `lookup_native_hot`: 51.07x
- `lookup_tool_redirect`: 46.30x
- `access_tool_redirect`: 50.05x
- `open_tool_redirect`: 39.90x
- `exec_tool_redirect`: 2.26x
- `readdir_alias_view`: 7.35x
- `build_tree_stat_walk`: 98.97x

This means the current evidence supports a FUSE-alternative story: `namei_ext`
keeps path-view decisions in the VFS/kernel path and is substantially faster
than the current FUSE redirect baseline on these metadata microbenchmarks.

## Why full-suite native overhead still fails

The same comparison does not support a full-suite near-native claim. The failing
native-overhead rows are:

- `lookup_native_hot`: policy/native p99 = 1.526x;
- `readdir_alias_view`: policy/native p99 = 4.374x;
- `build_tree_stat_walk`: policy/native p99 = 1.750x.

The largest ratio comes from `readdir_alias_view`, where native p99 is about
209 ns/op and policy p99 is about 915 ns/op. This row is still faster than FUSE,
but it is not close to native.

The implementation has two current overhead sources that explain the native
gate failure:

1. Lookup with `namei_ext_enabled()` currently rejects RCU path walk by returning
   `-ECHILD`, forcing ref-walk. This affects even paths that do not redirect and
   helps explain why `pass_only` is also slower than native.
2. Readdir currently constructs a `bpf_namei_ext_ctx` and runs the cgroup BPF
   dispatch for each directory entry. In a tiny directory, this fixed per-dirent
   cost is large relative to native readdir.

The current `pass_only` rows show that the problem is not only policy logic or
map lookup. Several rows are dominated by common hook/dispatch overhead.

## Benchmark interpretation

The current metadata suite is useful, but not all rows should carry the same
paper weight.

- `lookup_tool_redirect`, `access_tool_redirect`, `open_tool_redirect`, and
  `exec_tool_redirect` are the strongest scoped C3 rows. They pass both native
  and FUSE thresholds.
- `readdir_alias_view` is a diagnostic stress row for per-dirent dispatch. It
  uses a tiny directory and magnifies fixed hook cost.
- `lookup_native_hot` is a control row for collateral overhead on paths that do
  not need redirection.
- `build_tree_stat_walk` is a small tree-walk control row that exposes common
  hook overhead across many path components.

Therefore the paper should not use the current full suite to claim
near-native overhead across all metadata operations. It can use the full suite
to show that the FUSE baseline is beaten, and then explicitly report the
remaining native-overhead blockers.

## Workload interpretation

For C2 setup/update/materialization, FUSE is also an important baseline but the
result is mixed by workload.

- W2 nginx fixture: policy setup is faster than FUSE setup, and update is
  essentially tied. This is the strongest positive C2 slice.
- W1 build graph: policy setup is faster than FUSE setup, but policy update is
  slower than FUSE update, and stronger non-FUSE baselines also beat the policy.
- W3 Redis checkpoint replay: policy setup is faster than FUSE setup, but a
  materialized checkpoint-view baseline has lower setup time.
- W4 ccache bulk: policy setup is faster than FUSE setup, but policy update is
  slower than the best external baseline.

This supports making FUSE the primary programmable-path baseline while keeping
copy/symlink/bind/projected/materialized/native-tool baselines as required
feature-equivalence checks.

## Next actions

The highest-value next work is not another paper wording pass. It is a
Make-owned performance/root-cause iteration:

1. Add a KVM diagnostic or implementation variant that isolates the RCU
   fallback cost. The decision point is whether `pass_only/native` drops toward
   the 1.10x threshold when non-redirecting paths can stay on the fast path.
2. Add a readdir fast-path or scope filter so directories without relevant
   policy state do not invoke BPF on every entry. Then rerun
   `readdir_alias_view`.
3. Rerun the performance comparison, C3 residual diagnostic, C5 rusage/no-hook
   ablation, and claim verdict ledgers.
4. Keep the paper's main performance story centered on FUSE unless the native
   gate becomes clean enough to support a near-native full-suite claim.

Until those runs exist, the correct claim is: `namei_ext` is a strong
FUSE-alternative for the measured metadata path-view operations, while the
current Phase 1 hook placement still has native-overhead blockers.
