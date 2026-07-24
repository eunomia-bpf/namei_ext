# Build/Cache State Row Implementation

Date: 2026-07-23
Scope: implementation record for adding a trace-derived policy/FUSE state row
to Experiment B.

## Motivation

The 2026-07-23 build/cache release row already showed real Redis/nginx ccache
hot-cache compiles through `namei_ext`, native ccache, and a
feature-equivalent FUSE cache view. Its honest limit was state coverage: the
real compile row did not exercise epoch/state transitions beyond verified hot
hits.

The next useful increment is a state-transition row inside the same
`experiment-env-cache` matrix. This row should not revive table-only novelty or
a materialized-namespace shootout. It should answer a narrower question: over
real ccache object names extracted from the trace, can the
`cache_locality_view.bpf.c` epoch policy and a feature-equivalent FUSE view
both satisfy the same lookup/readdir state oracle?

## Files Changed

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Added `--ccache-bulk-cache-state-policy-fuse`.
  - Added a clean terminal summary event:
    `w4-ccache-bulk-cache-state-policy-fuse-summary`.
  - Reused the existing cache epoch policy and FUSE state-oracle helpers, but
    omitted the legacy table/materialized systems from this runner.
- `mk/kvm.mk`
  - Added `W4_CCACHE_BULK_CACHE_STATE_*` artifact variables.
  - Added `kvm-w4-ccache-bulk-cache-state-policy-fuse` and the guest target
    `__phase1_guest_w4_ccache_bulk_cache_state_policy_fuse`.
  - Integrated the state row into `kvm-build-cache-matrix` and therefore
    `make experiment-env-cache`.
  - Added state-row input hashes, dmesg preservation, hard `jq` gates, copied
    raw JSONL artifacts, and a nested `trace_derived_state_row` object in the
    build-cache matrix summary.

## State Oracle

The row uses ccache cache-object component names from
`w4-ccache-bulk-policy-bridge-entries.tsv`. For each sample it constructs:

```text
verified epoch -> visible object resolves to local verified object
epoch update   -> one namei_ext session update switches visible object
                  to canonical backing object
FUSE row       -> same visible object reaches canonical backing after
                  feature-equivalent backing updates
```

The summary records:

- `state_coverage.verified_hit_to_local = true`
- `state_coverage.epoch_update_to_canonical = true`
- `state_coverage.canonical_fallback = true`
- `real_ccache_trace_basis = true`
- `trace_derived_state_oracle = true`

This is not a full real compile state-machine row. It does not claim that real
compiler execution covered miss, stale, corrupt, and epoch-switch cells.

## Validation

Local compile gate:

```sh
make w1-oracle bpf
```

KVM smoke:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=1 RUN_ID=20260723T-build-cache-state-smoke-v1
```

KVM release:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-state-release-v1
```

Both KVM runs passed. The release run preserved raw artifacts under:

```text
results/experiments/build-cache/20260723T-build-cache-state-release-v1/
```

Additional checks after the release run:

```sh
sha256sum -c results/experiments/build-cache/20260723T-build-cache-state-release-v1/build-cache-matrix-inputs.sha256
grep -E 'BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN' results/experiments/build-cache/20260723T-build-cache-state-release-v1/dmesg-build-cache-matrix.log
```

The input hash check passed. The dmesg grep produced no matches. The captured
`stderr-build-cache-matrix.log` is 0 bytes.

## Remaining Work

- Real compile miss and epoch-switch cells still need a ccache setup whose
  oracle proves the compiler output is correct and the policy branch engaged.
- Real stale/corrupt reject/fallback cells need an oracle that proves a bad
  local cache object was not consumed.
- The state row strengthens Experiment B, but the paper should still describe
  the broad miss/stale/corrupt/epoch compile claim as open until those cells
  run under the same correctness oracle.
