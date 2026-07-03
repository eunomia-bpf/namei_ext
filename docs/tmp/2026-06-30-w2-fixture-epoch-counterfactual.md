# W2 fixture epoch counterfactual

## Motivation

This record documents an already-run targeted W2 boundary experiment. The
existing W2 nginx fixture work is the strongest positive setup/update slice, but
this record is not the next research direction and should not be used to frame
future work around redirect-table diagnostics. The experiment keeps the visible names
stable while the correct backing epoch changes, giving a controlled
state-dependent path-view fixture.

The result is not full C8 release evidence. It is a fixture-shaped mechanism
counterfactual, not a real nginx reload trace. The run explicitly records
`real_nginx_trace=false`, `qualified_for_c8=false`, and
`release_gate_pass=false`.

## Code paths changed

- `bpf/policies/sandbox_fixture_view.bpf.c`
  - added `fixture_sessions`, keyed by `cgroup_id`, carrying `fixture_epoch`;
  - added `fixture_epoch_rules`, keyed by component, path class, and epoch;
  - kept the existing literal nginx/PostgreSQL fixture redirects unchanged;
  - made the fallback path consult epoch rules for config, secret, cert,
    endpoint, and poison path classes.
- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - mirrored the new BPF map ABI structs;
  - added `update_sandbox_fixture_session()` and
    `update_sandbox_fixture_epoch_rule()`;
  - added `--sandbox-fixture-epoch-counterfactual`;
  - implemented five systems under the same oracle:
    `sandbox_fixture_epoch_policy`, `table_redirect_static_fixture_epoch1`,
    `table_redirect_updated_fixture_exact`,
    `materialized_fixture_epoch_view`, and `fuse_fixture_epoch_view`.
- `mk/kvm.mk`
  - added `kvm-w2-fixture-epoch-counterfactual` and the guest target;
  - added input SHA256 capture, summary-field jq gate, and dmesg hard gate.
- `Makefile`
  - exposed the new target in `.PHONY` and `make help`.

## Experiment design

Each sample creates 16 visible fixture names spread across five path classes:
config, secret, cert, endpoint, and poison. Each visible name has two backing
objects, epoch 1 and epoch 2.

The oracle checks both lookup and directory enumeration:

- epoch 1: visible name resolves to the epoch-1 backing content;
- epoch 2: the same visible name resolves to the epoch-2 backing content;
- readdir: the visible alias is present and both backing names are hidden.

The systems are feature-equivalent at the oracle level:

- `sandbox_fixture_epoch_policy` preloads both epoch rule sets and switches the
  current epoch with one `fixture_sessions[cgroup_id]` update.
- `table_redirect_static_fixture_epoch1` is fixed to epoch 1 and is expected to
  fail the epoch-2 oracle.
- `table_redirect_updated_fixture_exact` externally rewrites exact lookup rows
  to epoch 2.
- `materialized_fixture_epoch_view` copies epoch-1 files into visible files and
  then copies epoch-2 files over them.
- `fuse_fixture_epoch_view` exposes stable visible aliases and rewrites private
  FUSE shadow backing files to epoch 2.

The declared budget is the existing C8 diagnostic threshold:
`max_table_update_write_ratio=10`. With 16 objects, a one-write policy epoch
switch implies that any per-object update path has ratio 16.

## Validation

Smoke:

```sh
make kvm-w2-fixture-epoch-counterfactual \
  RUN_ID=20260629T-w2-fixture-epoch-c8-smoke-v1 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES=2 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Release-style:

```sh
make kvm-w2-fixture-epoch-counterfactual \
  RUN_ID=20260629T-w2-fixture-epoch-c8-release-v1 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

The release run wrote:

- `results/phase1/20260629T-w2-fixture-epoch-c8-release-v1/w2-fixture-epoch-counterfactual.jsonl`
- `results/phase1/20260629T-w2-fixture-epoch-c8-release-v1/w2-fixture-epoch-counterfactual-inputs.sha256`
- `results/phase1/20260629T-w2-fixture-epoch-c8-release-v1/dmesg-w2-fixture-epoch-counterfactual.log`

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w2-fixture-epoch-c8-release-v1/w2-fixture-epoch-counterfactual-inputs.sha256
```

The dmesg hard-gate pattern found zero issues.

## Result summary

The release summary row reports:

- `samples=20`
- `objects=16`
- `setup_rows=100`
- `correctness_rows=200`
- `update_rows=80`
- `dynamic_fixture_classes=5`
- `static_wrong_fixture_hits=320`
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
- `state_dependent_branch_not_static_table_expressible=true`
- `real_nginx_trace=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is archived boundary evidence for W2's dynamic fixture mechanism. It
records how a controlled fixture-epoch oracle behaved under five systems. It is
not a mainline result and should not motivate more table experiments.

The evidence should be cited narrowly. It does not establish the full C8 claim
because it does not run a real nginx reload/update trace, does not measure real
application stale windows, and does not add safety/semantic-boundary evidence
beyond the fixture oracle.

## Remaining risks

- The run uses synthetic fixture epoch payloads rather than a real nginx reload
  or PostgreSQL secret rotation trace.
- The update-window measurement is the observed update-and-check interval, not
  a concurrent operation issued during the stale window.
- C8 remains scoped out until real workload evidence aligns expressiveness,
  safety boundary, and efficiency across the chosen policy families.
