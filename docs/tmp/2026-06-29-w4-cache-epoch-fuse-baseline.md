# W4 cache epoch FUSE baseline update

> 2026-06-29 story scope update: this note is targeted mechanism evidence, not the main paper story. Current C8 is the balanced dynamic path-view claim in `docs/tmp/2026-06-29-paper-story-scope-update.md`; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the relevant alternative.

## Motivation

This record documents the W4 FUSE follow-up for the cache-epoch counterfactual.
The previous follow-up added `materialized_cache_epoch_view`; this note adds a
FUSE view because FUSE is a relevant conceptual comparison when a workload can
be implemented as a userspace filesystem view.

The goal is narrow: make W4's targeted dynamic oracle compare
`cache_locality_view.bpf.c`, static exact table, externally updated exact table,
materialized view, and FUSE view in the same KVM run. The run remains a
synthetic cache-epoch fixture, not a real ccache or BuildKit trace.

## Files inspected and changed

Inspected paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `docs/tmp/2026-06-29-w4-cache-epoch-counterfactual.md`
- `docs/tmp/2026-06-29-c8-killer-experiment-update.md`
- `research/CLAIM_LEDGER.md`
- `research/EXPERIMENT_TRACKER.md`
- `research/RESULTS_SUMMARY.md`
- `research/STATE.md`

Changed implementation paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`

No project-owned shell script was added. The workflow remains Make-owned and
writes raw observations under `results/phase1/<RUN_ID>/`.

## Implementation details

The runner now adds a fifth system:

- `fuse_cache_epoch_view`

For each sample, the runner creates two directories:

- `source/`: contains cache epoch source objects `<visible>.local` and
  `<visible>.canon`;
- `view/`: becomes a FUSE mount exposing only the stable ccache-shaped visible
  names.

The FUSE setup reuses the existing `setup_w1_fuse_mount` helper. Each visible
name maps to a short private shadow backing such as `w4f00`. Setup initializes
that shadow from the verified-local source object. The epoch switch copies each
canonical source object into the corresponding private shadow backing.

The FUSE correctness oracle checks:

- visible content matches the selected epoch source object;
- the visible name appears in readdir;
- `.local`, `.canon`, and the private FUSE shadow do not appear in readdir.

The summary row now includes:

- `fuse_setup_writes`
- `fuse_update_writes`
- `fuse_mounts`
- `fuse_update_write_ratio`
- `fuse_current_oracle_pass`
- `fuse_feature_equivalent_baseline`
- `fuse_update_budget_failure`

The Make hard gate requires `fuse_current_oracle_pass=true`,
`fuse_feature_equivalent_baseline=true`, `fuse_update_budget_failure=true`,
`fuse_update_write_ratio > OSDI_TABLE_MAX_UPDATE_WRITES_RATIO`, and
`fuse_mounts == samples`.

## Validation performed

Build check:

```sh
make w1-oracle
```

KVM validation:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-fuse-v1 \
  W4_CACHE_EPOCH_SAMPLES=20 \
  W4_CACHE_EPOCH_OBJECTS=16
```

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w4-cache-epoch-c8-fuse-v1/w4-cache-epoch-counterfactual-inputs.sha256
```

The JSONL file contains 384 rows:

```sh
wc -l \
  results/phase1/20260629T-w4-cache-epoch-c8-fuse-v1/w4-cache-epoch-counterfactual.jsonl
```

The KVM dmesg issue scan found zero configured kernel diagnostics.

## Result summary

The 20-sample summary row reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `static_wrong_local_hits=320`
- `policy_setup_writes=1940`
- `table_setup_writes=1920`
- `materialized_setup_writes=320`
- `fuse_setup_writes=320`
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
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is the strongest current W4 cache-epoch counterfactual. Under the same
lookup/readdir oracle:

- static exact table fails after the cache epoch changes;
- externally updated exact table preserves correctness but rewrites one lookup
  row per visible cache object;
- materialized view preserves correctness but copies one visible file per cache
  object;
- FUSE preserves correctness but rewrites one private backing shadow per cache
  object;
- the eBPF policy switches the active epoch with one session update after both
  epoch rule sets are preloaded.

With 16 objects, table, materialized, and FUSE updates are all 16x the policy
update write count, exceeding the configured budget of 10.

The claim remains narrow. The run still records `real_ccache_trace=false`,
`qualified_for_c8=false`, and `release_gate_pass=false`. It is reviewer-useful
mechanism evidence for table/materialization/FUSE update pressure, not a full
W4 C8 release result.

## Remaining risks and follow-up

- Lift the epoch transition to trace-derived real ccache or BuildKit objects.
- Add operation-weighted branch metrics from real cache-path operations.
- Add a stale-window run that issues operations during table/materialized/FUSE
  rewrite and checks output hashes or reject/fallback behavior.
- Add a complete compile-through-FUSE or cache-remap/native baseline under the
  same release workload before claiming W4 as a novelty workload.
