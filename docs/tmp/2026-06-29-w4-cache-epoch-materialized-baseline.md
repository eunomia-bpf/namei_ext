# W4 cache epoch materialized baseline update

> 2026-06-29 story scope update: this note is targeted mechanism evidence, not the main paper story. Current C8 is the balanced dynamic path-view claim in `docs/tmp/2026-06-29-paper-story-scope-update.md`; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the relevant alternative.

## Motivation

This record documents the follow-up implementation and validation step for the
W4 C8 cache-epoch counterfactual. The earlier W4 cache-epoch run compared the
proposed eBPF policy with static and externally updated exact tables. That was
enough to show the table update-write budget failure, but it did not include an
external materialized-view baseline under the same dynamic oracle.

The follow-up adds `materialized_cache_epoch_view` to the same
`kvm-w4-cache-epoch-counterfactual` run. The goal is not to turn the synthetic
fixture into full W4 release evidence. The goal is to make the counterfactual
more reviewer-clean: policy, static table, externally updated table, and an
external materialized view now see the same epoch transition and the same
lookup/readdir correctness oracle.

## Files inspected and changed

Inspected paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `docs/tmp/2026-06-29-w4-cache-epoch-counterfactual.md`
- `docs/tmp/2026-06-29-c8-killer-experiment-update.md`
- `research/CLAIM_LEDGER.md`
- `research/EXPERIMENT_TRACKER.md`
- `research/RESULTS_SUMMARY.md`

Changed implementation paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`

No project-owned shell script was added. The workflow remains Make-owned and
writes raw results under `results/phase1/<RUN_ID>/`.

## Implementation details

The runner now adds a fourth system:

- `materialized_cache_epoch_view`

For each sample, the runner creates a backing directory containing the same
ccache-shaped objects used by the policy and table systems:

- `<visible>.local`: verified local cache object for epoch 1;
- `<visible>.canon`: canonical backing object for epoch 2.

The materialized baseline uses a separate view directory containing only the
visible names. Setup copies every epoch-1 local backing into the view. The epoch
switch copies every epoch-2 canonical backing over the visible file. It does not
execute a `namei_ext` policy, does not attach eBPF, and does not expose `.local`
or `.canon` names through readdir.

The JSON rows now distinguish provenance:

- policy and table rows use `row_kind="policy_or_table"` and
  `policy_executed=true`;
- materialized rows use `row_kind="external_baseline"`,
  `policy_executed=false`, and `feature_equivalent_baseline=true`.

The summary row now includes:

- `materialized_setup_writes`
- `materialized_update_writes`
- `materialized_update_write_ratio`
- `materialized_current_oracle_pass`
- `materialized_feature_equivalent_baseline`
- `materialized_update_budget_failure`

The Make hard gate now requires the materialized baseline to pass the same
oracle and to exceed the declared update-write ratio budget, just like the
externally updated table.

## Validation performed

Build checks:

```sh
make w1-oracle
make bpf
```

KVM validation:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-materialized-v3 \
  W4_CACHE_EPOCH_SAMPLES=20 \
  W4_CACHE_EPOCH_OBJECTS=16
```

The target booted the modified kernel in KVM, ran the real
`cgroup/namei_ext` attach path for the policy/table systems, and verified the
materialized external baseline in the same guest run.

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w4-cache-epoch-c8-materialized-v3/w4-cache-epoch-counterfactual-inputs.sha256
```

The JSONL file contains 304 rows:

```sh
wc -l \
  results/phase1/20260629T-w4-cache-epoch-c8-materialized-v3/w4-cache-epoch-counterfactual.jsonl
```

The dmesg issue scan found zero configured kernel diagnostics.

## Result summary

The 20-sample summary row reports:

- `samples=20`
- `objects=16`
- `setup_rows=80`
- `correctness_rows=160`
- `update_rows=60`
- `static_wrong_local_hits=320`
- `policy_setup_writes=1940`
- `table_setup_writes=1920`
- `materialized_setup_writes=320`
- `policy_update_writes=20`
- `table_update_writes=320`
- `materialized_update_writes=320`
- `table_update_write_ratio=16`
- `materialized_update_write_ratio=16`
- `max_table_update_write_ratio=10`
- `table_static_current_oracle_pass=false`
- `table_static_expected_failure_observed=true`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=true`
- `materialized_current_oracle_pass=true`
- `materialized_feature_equivalent_baseline=true`
- `materialized_update_budget_failure=true`
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

This is the strongest current W4 cache-epoch counterfactual. It preserves the
previous exact-table result and adds an external materialized baseline under the
same dynamic oracle.

The narrow evidence is:

- static exact table fails the epoch-2 correctness oracle by returning local
  objects after the policy should use canonical objects;
- externally updated exact table preserves correctness but needs one lookup
  rewrite per visible object;
- external materialization also preserves correctness but needs one visible file
  copy per object;
- the eBPF policy switches the active epoch with one session update after both
  epoch rule sets are preloaded.

With 16 objects, both table and materialized updates are 16x the policy update
write count, exceeding the configured budget of 10.

The claim remains narrow. The run still records `real_ccache_trace=false`,
`qualified_for_c8=false`, and `release_gate_pass=false`. It is mechanism
evidence for update-budget pressure, not full W4 C8 release evidence.

## Remaining risks and follow-up

- Lift the epoch transition to trace-derived real ccache or BuildKit objects.
- Add operation-weighted branch metrics from real cache-path operations.
- Add a stale-window run that issues operations during table/materialized
  rewrite and checks output hashes or reject/fallback behavior.
- The targeted FUSE cache-epoch baseline was added in
  `docs/tmp/2026-06-29-w4-cache-epoch-fuse-baseline.md`; the remaining FUSE
  gap is a complete compile-through-FUSE release workload, not this synthetic
  cache-epoch fixture.
