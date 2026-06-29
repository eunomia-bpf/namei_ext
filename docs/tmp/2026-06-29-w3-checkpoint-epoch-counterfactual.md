# W3 checkpoint epoch C8 counterfactual

> 2026-06-29 baseline scope update: this note is targeted mechanism evidence, not the main novelty story. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

## Motivation

This record documents the W3 targeted C8 experiment added on 2026-06-29. The
previous W3 Redis checkpoint replay was negative evidence for C8 because
`table_redirect.bpf.c` could replay the same `dump.rdb -> checkpoint backing`
mapping with the same correctness oracle. That result showed the current W3
workload did not require programmable policy logic.

The sharper C8 question is whether an exact table can stay correct across
checkpoint epoch changes without exceeding an update budget. This experiment
therefore creates a dynamic epoch workload where the visible names stay fixed,
but the correct backing object changes when the checkpoint session epoch
changes.

This is a targeted C8 fixture, not a real Podman/CRIU restore. It is intended
to answer the mechanism question under the real KVM attach path while keeping
the claim scoped: it can show exact-table update pressure, but it cannot by
itself support a real W3 checkpoint/restore paper claim.

## Files inspected and changed

Inspected policy and orchestration paths:

- `bpf/policies/checkpoint_restore_view.bpf.c`
- `bpf/policies/table_redirect.bpf.c`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`

Changed paths:

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`

No project-owned shell script was added. The workflow is owned by Make targets
and runs inside the modified-kernel KVM path.

## Experiment design

The runner creates a synthetic checkpoint directory with stable visible names
and two checkpoint epochs. For each object `stateNN.rdb`, epoch 1 and epoch 2
have distinct backing files and distinct content. Correctness is checked by
opening the visible name and verifying that the content matches the currently
selected epoch.

The latest experiment runs four feature-equivalent systems:

1. `checkpoint_epoch_policy`: uses `checkpoint_restore_view.bpf.c`. The runner
   preloads map rules for both epochs and switches
   `checkpoint_sessions[cgroup_id].checkpoint_epoch` between epoch 1 and
   epoch 2. The epoch switch costs one session map update per sample.
2. `table_redirect_static_epoch1`: uses `table_redirect.bpf.c` with exact
   lookup rows fixed to epoch 1. It should pass the epoch-1 oracle and fail the
   epoch-2 oracle.
3. `table_redirect_updated_exact`: uses `table_redirect.bpf.c` with exact
   lookup rows externally rewritten from epoch 1 to epoch 2. It should pass the
   current correctness oracle, but the update cost is charged as one exact-row
   rewrite per visible object.
4. `materialized_checkpoint_epoch_view`: external materialized view that copies
   epoch-1 backing objects into visible files during setup and copies epoch-2
   backing objects over those visible files during the epoch switch.

The default targeted gate uses 16 checkpoint objects and a maximum table update
write ratio of 10. With one policy epoch update and 16 table lookup rewrites,
the externally updated table has a ratio of 16 and must fail the declared C8
update-budget gate even though it remains correct.

The runner emits raw JSONL events:

- `w3-checkpoint-epoch-setup`
- `w3-checkpoint-epoch-correctness`
- `w3-checkpoint-epoch-update-window`
- `w3-checkpoint-epoch-summary`

The Make target hard-gates on the expected result shape:

- static table current oracle must fail;
- static table expected failure must be observed;
- externally updated table current oracle must pass;
- table update writes must exceed the declared ratio budget;
- materialized view current oracle must pass;
- materialized update writes must exceed the declared ratio budget;
- the run must stay marked `qualified_for_c8=false` and
  `release_gate_pass=false` because it is not a real Podman/CRIU restore.

## Alternatives rejected

### Reuse the existing Redis replay

Rejected. The existing replay is a useful negative control, but it has a
single stable mapping. Since `table_redirect.bpf.c` passes it, it cannot answer
whether dynamic checkpoint epochs require policy logic or excessive table
updates.

### Use literal `dump.rdb` and `appendonly.aof` rules

Rejected for this targeted experiment. `checkpoint_restore_view.bpf.c` already
has literal redirects for fixed Redis checkpoint names, which would bypass the
map-driven epoch rule path. The targeted fixture uses non-literal state object
names so the epoch-keyed rule machinery is exercised.

### Claim real checkpoint/restore support from the fixture

Rejected. The host Podman/CRIU capability audit remains blocked, and this
fixture does not restore a real process. The summary explicitly records
`real_podman_criu_restore=false`, `qualified_for_c8=false`, and
`release_gate_pass=false`.

### Add the target to the default Phase 1 flow

Rejected for now. This target is a C8 killer counterfactual, not a default
Phase 1 release gate. Keeping it explicit prevents synthetic mechanism
evidence from being mixed into the default claim path.

## Validation performed

Build:

```sh
make w1-oracle
```

Smoke KVM run:

```sh
make kvm-w3-checkpoint-epoch-counterfactual \
  RUN_ID=20260629T-w3-checkpoint-epoch-c8-smoke-v1 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=1 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Release-style KVM run:

```sh
make kvm-w3-checkpoint-epoch-counterfactual \
  RUN_ID=20260629T-w3-checkpoint-epoch-c8-release-v1 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Follow-up release-style KVM run with the materialized baseline included:

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

The materialized follow-up JSONL contains 304 rows:

```sh
wc -l \
  results/phase1/20260629T-w3-checkpoint-epoch-c8-materialized-v1/w3-checkpoint-epoch-counterfactual.jsonl
```

The KVM dmesg issue scan found zero configured kernel diagnostics.

## Release summary

The latest 20-sample materialized follow-up summary row reports:

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
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is the first W3 evidence where an externally updated exact table loses one
of the declared C8 gates while preserving correctness. The static exact table
fails the epoch-2 correctness oracle. The externally updated exact table passes
correctness, but it needs one lookup-row rewrite per visible object, while the
policy switches epoch with one session update. With 16 objects, the table
update-write ratio is 16, exceeding the declared budget of 10.

The follow-up materialized baseline reaches the same correctness oracle, but it
also needs one visible file copy per object after the epoch switch. Its update
write ratio is also 16. This strengthens the counterfactual by showing that the
same dynamic checkpoint-epoch oracle is expensive for both exact-table
rematerialization and external materialized views.

The correct paper wording is narrow:

- This targeted W3 fixture demonstrates a mechanism by which dynamic epoch
  policy can beat exact-table materialization under an update-write budget.
- It does not prove the full W3 checkpoint/restore claim because it is not a
  real Podman/CRIU restore and does not include process state, external bind
  mounts, restore health, or post-restore workload behavior.
- It should be used to motivate the next real W3 restore experiment, not to
  replace it.

## Remaining risks and follow-up

- A real W3 C8 run still needs Podman/CRIU capability, a restored Redis or
  nginx workload, post-restore path traces, and a zero mixed-epoch oracle.
- The fixture currently proves update-write pressure, not stale-window
  behavior. A stronger version should issue operations during the externally
  updated table's rewrite window and measure stale or mixed-epoch exposure.
- The current threshold is an explicit experimental budget, not a universal
  theorem. The paper must justify the budget from real workload transition
  frequency and operation mix before using it as a main-claim number.
- FUSE baseline behavior under the same checkpoint-epoch oracle is still
  missing.
- Real W3 FUSE and materialized-view baselines remain the release-level
  comparison; this fixture still compares a synthetic epoch mechanism rather
  than real process restore.
