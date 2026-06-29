# W3 checkpoint epoch materialized baseline update

> 2026-06-29 story scope update: this note is targeted mechanism evidence, not the main paper story. Current C8 is the balanced dynamic path-view claim in `docs/tmp/2026-06-29-paper-story-scope-update.md`; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the relevant alternative.

## Motivation

This record documents the W3 follow-up C8 experiment on 2026-06-29. The earlier
W3 checkpoint epoch counterfactual compared the proposed checkpoint eBPF policy
with static and externally updated exact tables. That was enough to show an
exact-table update-write budget failure, but it did not include an external
materialized-view baseline under the same dynamic epoch oracle.

The follow-up adds `materialized_checkpoint_epoch_view` to the same
`kvm-w3-checkpoint-epoch-counterfactual` run. This makes the targeted W3
counterfactual stronger: policy, static table, externally updated table, and
external materialization now see the same visible checkpoint names, the same
epoch switch, and the same lookup/readdir correctness oracle.

## Files inspected and changed

Inspected paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `docs/tmp/2026-06-29-w3-checkpoint-epoch-counterfactual.md`
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

- `materialized_checkpoint_epoch_view`

For each sample, the runner creates a backing directory with the same synthetic
checkpoint epoch objects used by the policy and table systems:

- `stateNN.e1`: epoch-1 checkpoint backing;
- `stateNN.e2`: epoch-2 checkpoint backing.

The materialized baseline uses a separate view directory that contains only the
visible checkpoint names, `stateNN.rdb`. Setup copies every epoch-1 backing into
the view. The epoch switch copies every epoch-2 backing over the visible file.
It does not attach a `namei_ext` policy and does not expose epoch backing names
through readdir.

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
oracle and to exceed the declared update-write ratio budget.

## Validation performed

Build check:

```sh
make w1-oracle
```

KVM validation:

```sh
make kvm-w3-checkpoint-epoch-counterfactual \
  RUN_ID=20260629T-w3-checkpoint-epoch-c8-materialized-v1 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w3-checkpoint-epoch-c8-materialized-v1/w3-checkpoint-epoch-counterfactual-inputs.sha256
```

The JSONL file contains 304 rows:

```sh
wc -l \
  results/phase1/20260629T-w3-checkpoint-epoch-c8-materialized-v1/w3-checkpoint-epoch-counterfactual.jsonl
```

The KVM dmesg issue scan found zero configured kernel diagnostics.

## Result summary

The 20-sample summary row reports:

- `samples=20`
- `objects=16`
- `setup_rows=80`
- `correctness_rows=160`
- `update_rows=60`
- `static_wrong_epoch_hits=320`
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
- `real_podman_criu_restore=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is the strongest current W3 checkpoint-epoch counterfactual. It preserves
the earlier exact-table result and adds an external materialized baseline under
the same dynamic oracle.

The narrow evidence is:

- static exact table fails after the checkpoint epoch changes;
- externally updated exact table preserves correctness but needs one lookup
  rewrite per visible checkpoint object;
- external materialization preserves correctness but needs one visible file
  copy per checkpoint object;
- the eBPF policy switches epoch with one session update after both epoch rule
  sets are preloaded.

With 16 objects, both table and materialized updates are 16x the policy update
write count, exceeding the configured budget of 10.

The claim remains narrow. The run still records `real_podman_criu_restore=false`,
`qualified_for_c8=false`, and `release_gate_pass=false`. It is mechanism
evidence for update-budget pressure, not full W3 Podman/CRIU release evidence.

## Remaining risks and follow-up

- Lift the epoch transition to a real Podman/CRIU or equivalent checkpoint
  restore workload.
- Add a stale-window run that issues operations during table/materialized
  rewrite and checks for mixed epoch exposure.
- FUSE checkpoint-epoch behavior was added in
  `docs/tmp/2026-06-29-w3-checkpoint-epoch-fuse-baseline.md`; the remaining
  FUSE gap is a real checkpoint/restore transition, not this targeted fixture.
- Preserve restore logs, checkpoint archive identity, post-restore health, and
  path traces before claiming W3 as a release-level novelty workload.
