# W4 trace-derived cache epoch counterfactual

## Motivation

The earlier W4 cache-epoch counterfactual proved the exact-table update-budget
boundary on synthetic ccache-shaped objects. That was useful mechanism evidence,
but an OSDI reviewer could still ask whether the same exact-table limitation
appears on a real cache trace shape. This step lifts the epoch fanout experiment
onto the bulk ccache trace/bridge objects derived from Redis and nginx compiles.

The goal is narrow: test whether `table_redirect.bpf.c` remains enough when the
visible cache-object set comes from a real ccache trace and the correct backing
epoch changes for many objects at once. This is still a counterfactual dynamic
epoch test, not a full real stale/corrupt compile workload.

## Files inspected or changed

- `tests/w1_oracle/namei_ext_w1_oracle.c`: added a trace-derived variant of the
  W4 cache-epoch runner. It reads `w4-ccache-bulk-policy-bridge-entries.tsv`,
  selects trace-derived cache object names and source SHA provenance, prepares
  deterministic local/canonical epoch payloads, and reuses the five-system
  cache-epoch comparison.
- `mk/kvm.mk`: added `kvm-w4-ccache-bulk-cache-epoch-counterfactual` and the
  corresponding guest target. The target depends on the Make-owned bulk
  ccache trace/bridge target, validates input hashes, attaches the real
  `cache_locality_view.bpf.c` and `table_redirect.bpf.c` policies, and runs in
  the modified-kernel KVM guest.
- `bpf/policies/cache_locality_view.bpf.c` and
  `bpf/policies/table_redirect.bpf.c`: used as input policies; no new policy
  language or YAML/JSON control plane was added.

## Design

The target compares the same five systems as the synthetic W4 cache-epoch gate:

1. `cache_locality_epoch_policy`: one eBPF policy state update switches the
   session from verified-local epoch to canonical epoch.
2. `table_redirect_static_verified_epoch`: exact table fixed to local objects;
   expected to fail after the epoch change.
3. `table_redirect_updated_exact_epoch`: exact table externally rewritten for
   every object; expected to pass correctness but pay per-object updates.
4. `materialized_cache_epoch_view`: external materialized view that copies the
   canonical epoch over the visible files.
5. `fuse_cache_epoch_view`: external FUSE view that reaches the same oracle by
   rewriting private backing shadows.

The trace-derived variant differs from the synthetic gate in its object set:
visible names and source SHA provenance come from the real Redis/nginx ccache
bulk trace bridge. The epoch payloads are generated deterministically from that
provenance rather than copied from the original ccache object bytes. This keeps
the counterfactual focused on path-resolution/update fanout while preserving the
trace-derived name distribution and object count.

## Alternatives rejected

- Treating the real ccache hot-compile release run as C8 proof was rejected. It
  has output-hash correctness and operation-weighted cache-path activity, but it
  does not inject stale/corrupt or epoch-changing backing state.
- Copying real ccache object bytes directly into both epochs was rejected for
  this gate because the epoch oracle needs controlled local-vs-canonical content
  transitions. The original object hashes remain input provenance, while the
  dynamic payload is generated for the oracle.
- Marking the run as `qualified_for_c8=true` was rejected. It is stronger than
  the synthetic gate, but it is still not a real compile-time stale-window or
  corrupt-cache workload.

## Validation

Smoke:

```sh
make kvm-w4-ccache-bulk-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-ccache-bulk-cache-epoch-c8-smoke-v3 \
  W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES=2 \
  W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS=16
```

Release-sized:

```sh
make kvm-w4-ccache-bulk-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1 \
  W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES=20 \
  W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS=16
```

Input provenance check:

```sh
sha256sum -c \
  results/phase1/20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1/w4-ccache-bulk-cache-epoch-counterfactual-inputs.sha256
```

The Make-owned KVM target's dmesg hard gate reported zero issue matches under
the repository pattern:

```sh
awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' \
  results/phase1/20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1/dmesg-w4-ccache-bulk-cache-epoch-counterfactual.log
```

## Result

Summary row:
`results/phase1/20260629T-w4-ccache-bulk-cache-epoch-c8-release-v1/w4-ccache-bulk-cache-epoch-counterfactual.jsonl`

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

## Interpretation

This is the strongest current W4 table-only boundary evidence. A static exact
table fails the epoch oracle. An externally updated exact table can preserve
correctness, but only by rewriting one row per trace-derived object, producing a
16x update-write ratio over the one-session-update eBPF policy. Materialized and
FUSE views preserve correctness under the same oracle, but pay the same
per-object update count.

The result strengthens the C8 mechanism argument because the object set is
derived from a real ccache bulk trace rather than from a synthetic fixture. It
still does not prove the complete C8 claim. The run does not execute a real
compile while stale/corrupt objects are consumed, does not measure an
operation-issued-during-stale-window failure, and deliberately leaves
`qualified_for_c8=false`.

## Remaining risk

- A final W4 C8 claim still needs a real ccache or BuildKit stale/corrupt/update
  window run with output-hash and reject/fallback oracles under operations in
  flight.
- The current trace-derived payloads are controlled oracle fixtures. They should
  be described as trace-derived dynamic counterfactual evidence, not as a real
  ccache object-format semantics result.
- The result should be used as boundary evidence unless a future claim ledger
  combines it with natural cache mechanisms, safety/semantic-boundary evidence,
  and real workload stale-window coverage.
