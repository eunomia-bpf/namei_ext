# W1 build-epoch exact-table counterfactual

## Motivation

This record documents an already-run W1 targeted boundary experiment. It is
historical provenance, not the next research direction. It should not be used
to frame future work as a redirect-table argument.

The experiment is intentionally narrower than a full Redis/nginx build trace.
It exercises the real `cgroup/namei_ext` attach path in the modified kernel
and compares five feature-equivalent systems under one correctness oracle, but
it records `qualified_for_c8=false` because the dynamic epoch payloads are
controlled fixtures rather than live build operations.

## Design

The new dynamic W1 policy path extends `build_graph_view.bpf.c` with:

- `build_graph_sessions[cgroup_id]`, carrying the active build epoch.
- `build_graph_epoch_rules`, keyed by component, branch class, and build epoch.
- Five branch classes: generated output, source fallback, toolchain,
  external dependency, and undeclared poison.

The policy preloads both epochs and switches the whole view with one session
map update. The other systems in this archived comparison rewrite each visible
object to reach the same epoch-2 oracle.

The runner mode is:

```sh
namei_ext_w1_oracle --build-epoch-counterfactual \
  OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR OBJECTS BUILD_POLICY TABLE_POLICY
```

The Make-owned KVM entrypoint is:

```sh
make kvm-w1-build-epoch-counterfactual
```

## Compared systems

The target compares:

- `build_graph_epoch_policy`: `build_graph_view.bpf.c`, preloaded epoch rules
  plus one `build_graph_sessions[cgroup_id].build_epoch` update.
- `table_redirect_static_build_epoch1`: `table_redirect.bpf.c`, fixed to epoch
  1 and expected to fail the epoch-2 oracle.
- `table_redirect_updated_build_exact`: `table_redirect.bpf.c`, externally
  rewriting exact lookup rules for epoch 2.
- `materialized_build_epoch_view`: copied visible files updated per object.
- `fuse_build_epoch_view`: FUSE alias view updated by rewriting per-object
  private FUSE shadow backings.

The oracle checks lookup content and readdir visibility: each stable visible
name must resolve to the current epoch backing, while epoch backing names must
not be exposed in directory enumeration.

## Validation

Smoke run:

```sh
make kvm-w1-build-epoch-counterfactual \
  RUN_ID=20260630T-w1-build-epoch-c8-smoke-v1 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES=2 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Release-sized targeted run:

```sh
make kvm-w1-build-epoch-counterfactual \
  RUN_ID=20260630T-w1-build-epoch-c8-release-v1 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES=20 \
  W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS=16
```

Additional checks:

```sh
make bpf
make w1-oracle
sha256sum -c \
  results/phase1/20260630T-w1-build-epoch-c8-release-v1/w1-build-epoch-counterfactual-inputs.sha256
git diff --check
```

The release-sized KVM target passed its guest jq gate. Input hash verification
passed, and the dmesg hard-gate pattern count was 0.

## Result

Raw result:

```text
results/phase1/20260630T-w1-build-epoch-c8-release-v1/w1-build-epoch-counterfactual.jsonl
```

The summary row reports:

- `samples=20`
- `objects=16`
- `dynamic_build_branches=5`
- `static_wrong_epoch_hits=320`
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
- `state_dependent_branch_not_static_table_expressible=true`
- `real_redis_nginx_trace=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This is archived targeted boundary evidence for W1. It records how a controlled
epoch fixture behaved under five systems. It is not a mainline result and should
not be used to motivate more table experiments.

It does not establish full W1 C8. The run does not replay live Redis/nginx build
operations across epoch changes, does not report operation-weighted branch hit
rate for a real build trace, and does not measure stale windows with build
operations issued during the update. The correct claim remains: W1 now has a
targeted state-dependent boundary result, not release-qualified dynamic
workload evidence.

## Follow-up

A reviewer-level W1 upgrade should use a real Redis/nginx or build-system trace
where generated outputs, source fallback, toolchain dependencies, external
dependencies, and poison paths change across build epochs. It should preserve
compile success, output hashes, operation-weighted branch distribution,
and transition behavior. It should not be scoped as another table-centered
experiment.
