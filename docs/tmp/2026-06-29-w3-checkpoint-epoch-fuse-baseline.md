# W3 checkpoint epoch FUSE baseline update

> 2026-06-29 story scope update: this note is targeted mechanism evidence, not the main paper story. Current C8 is the balanced dynamic path-view claim in `docs/tmp/2026-06-29-paper-story-scope-update.md`; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the relevant alternative.

## Motivation

This record documents the W3 FUSE follow-up for the checkpoint-epoch
counterfactual. The previous follow-up added an external materialized view; this
note adds a FUSE view because FUSE is a relevant conceptual comparison when a
checkpoint view can be implemented as a userspace filesystem view.

The purpose is narrow: compare `checkpoint_restore_view.bpf.c`,
`table_redirect.bpf.c`, a materialized checkpoint view, and a FUSE checkpoint
view under the same dynamic epoch oracle as targeted mechanism evidence. The run is still a targeted fixture,
not a real Podman/CRIU restore.

## Files inspected and changed

Inspected paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `docs/tmp/2026-06-29-w3-checkpoint-epoch-counterfactual.md`
- `docs/tmp/2026-06-29-c8-killer-experiment-update.md`
- `research/EXPERIMENT_TRACKER.md`
- `research/RESULTS_SUMMARY.md`
- `research/CLAIM_LEDGER.md`

Changed implementation paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`

No project-owned shell script was added. The workflow remains Make-owned and
writes raw observations under `results/phase1/<RUN_ID>/`.

## Implementation details

The runner now adds a fifth system:

- `fuse_checkpoint_epoch_view`

For each sample, the runner creates two directories:

- `source/`: contains epoch source objects `stateNN.e1` and `stateNN.e2`;
- `view/`: becomes a FUSE mount exposing only stable visible names
  `stateNN.rdb`.

The FUSE setup reuses the existing `setup_w1_fuse_mount` helper. Each visible
name maps to a private shadow backing such as `stateNN.fuse`. Setup initializes
that shadow from the epoch-1 source object. The epoch switch copies each epoch-2
source object into the corresponding private shadow backing.

The FUSE correctness oracle checks:

- visible content matches the selected epoch source object;
- `stateNN.rdb` appears in readdir;
- `stateNN.e1`, `stateNN.e2`, and the private FUSE shadow do not appear in
  readdir.

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
make kvm-w3-checkpoint-epoch-counterfactual \
  RUN_ID=20260629T-w3-checkpoint-epoch-c8-fuse-v2 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w3-checkpoint-epoch-c8-fuse-v2/w3-checkpoint-epoch-counterfactual-inputs.sha256
```

The JSONL file contains 384 rows:

```sh
wc -l \
  results/phase1/20260629T-w3-checkpoint-epoch-c8-fuse-v2/w3-checkpoint-epoch-counterfactual.jsonl
```

The KVM dmesg issue scan found zero configured kernel diagnostics.

## Result summary

The 20-sample summary row reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `static_wrong_epoch_hits=320`
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
- `real_podman_criu_restore=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is the strongest current W3 checkpoint-epoch counterfactual. Under the
same lookup/readdir oracle:

- static exact table fails after the checkpoint epoch changes;
- externally updated exact table preserves correctness but rewrites one lookup
  row per visible checkpoint object;
- materialized view preserves correctness but copies one visible file per
  checkpoint object;
- FUSE preserves correctness but rewrites one private backing shadow per
  checkpoint object;
- the eBPF policy switches the active epoch with one session update after both
  epoch rule sets are preloaded.

With 16 objects, table, materialized, and FUSE updates are all 16x the policy
update write count, exceeding the configured budget of 10.

The claim remains narrow. The run still records `real_podman_criu_restore=false`,
`qualified_for_c8=false`, and `release_gate_pass=false`. It is reviewer-useful
mechanism evidence for table/materialization/FUSE update pressure, not a full
W3 C8 release result.

## Remaining risks and follow-up

- Lift the epoch transition to a real Podman/CRIU or equivalent checkpoint
  restore workload.
- Add a stale-window run that issues operations during table/materialized/FUSE
  rewrite and checks for mixed epoch exposure.
- Preserve restore logs, checkpoint archive identity, post-restore health, and
  path traces before claiming W3 as a release-level novelty workload.
