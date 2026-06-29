# W4 cache epoch C8 counterfactual

> 2026-06-29 baseline scope update: this note is targeted mechanism evidence, not the main novelty story. Current evaluation uses claim-driven, workload-appropriate baselines. Exact-map diagnostics are optional and only relevant when precomputed mapping is the competing claim.

## Motivation

This record documents the W4 targeted C8 experiment added on 2026-06-29. The
existing W4 cache transition gate showed that a static exact table can be wrong
when cache state changes from verified local to stale/corrupt fallback. It did
not make the externally updated exact table lose: the updated table preserved
correctness with `table_update_write_ratio=1`.

The sharper W4 C8 question is whether a cache policy can switch a generation
or epoch for many visible cache objects with less update work than an exact
table. The new experiment therefore creates a fanout cache epoch workload:
the visible ccache-shaped names stay fixed, but the correct backing changes
from verified local objects to canonical objects when the cache epoch changes.

This is a targeted C8 fixture. It runs through the real modified-kernel KVM
`cgroup/namei_ext` attach path, but it is not a real ccache or BuildKit trace.
It should be used as mechanism evidence for update-budget pressure, not as a
release-level W4 workload claim.

## Files inspected and changed

Inspected paths:

- `bpf/policies/cache_locality_view.bpf.c`
- `bpf/policies/table_redirect.bpf.c`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`

Changed paths:

- `bpf/policies/cache_locality_view.bpf.c`
- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`

No project-owned shell script was added. The workflow is Make-owned and writes
raw results under `results/phase1/<RUN_ID>/`.

## Policy mechanism

`cache_locality_view.bpf.c` now has an additional epoch rule path:

- `cache_epoch_sessions`: keyed by cgroup id; stores the active cache epoch.
- `cache_epoch_rules`: keyed by component plus cache epoch; stores redirect
  rules for lookup and directory enumeration.

The kernel-facing ABI is unchanged. Lookup and readdir are still event types
passed to the one `cgroup/namei_ext` decision function. The new maps are only
policy-owned state.

The targeted workload preloads two rule sets:

- epoch 1: visible object redirects to the verified local backing;
- epoch 2: the same visible object redirects to the canonical backing;
- both epochs hide local and canonical backing names from readdir by redirecting
  backing names to the visible name.

The eBPF policy changes epoch with one `cache_epoch_sessions[cgroup_id]`
update. An exact table has no epoch dimension, so the externally updated table
must rewrite one lookup row per visible object to preserve the same correctness
oracle.

## Experiment design

Each sample creates 16 ccache-shaped visible names. For every visible name, the
fixture creates two distinct backing files:

- `<visible>.local`: verified local cache object;
- `<visible>.canon`: canonical fallback object.

The current strongest validation compares four systems:

1. `cache_locality_epoch_policy`: preloads both cache epochs and switches the
   active epoch with one session update.
2. `table_redirect_static_verified_epoch`: exact table fixed to verified local
   objects. It should pass epoch 1 and fail epoch 2 by returning stale local
   content.
3. `table_redirect_updated_exact_epoch`: exact table fixed to verified local
   objects, then externally rewritten to canonical targets. It should pass
   correctness but pay one lookup-row update per object.
4. `materialized_cache_epoch_view`: external materialized view that copies
   epoch-1 local objects into visible files during setup and copies epoch-2
   canonical objects over those visible files during the epoch switch.

Correctness oracle:

- opening each visible name must match the selected epoch's backing content;
- readdir must show the visible name;
- readdir must hide both `.local` and `.canon` backing names;
- the static table must expose wrong-local hits after the epoch change.

Budget oracle:

- policy update writes are counted as cache epoch session updates;
- table update writes are counted as exact lookup rewrites;
- materialized update writes are counted as visible file copies;
- the run must fail the targeted table budget when
  `table_update_write_ratio > OSDI_TABLE_MAX_UPDATE_WRITES_RATIO`.

With 16 objects and the current budget of 10, the expected ratio is 16.

## Alternatives rejected

### Reuse the previous W4 cache transition gate

Rejected. That gate is useful static-table failure evidence, but it updates the
policy and table at the same per-object granularity. It therefore cannot prove
that externally updated exact tables exceed the update-write budget.

### Count only setup rule writes

Rejected. Setup writes show materialization cost, but the C8 novelty question
is dynamic correctness across state transitions. The target therefore gates on
update writes after a cache epoch change.

### Claim real ccache evidence

Rejected. The fixture uses ccache-shaped object names and cache semantics, but
it does not replay a real ccache or BuildKit trace. The summary explicitly
records `real_ccache_trace=false`, `qualified_for_c8=false`, and
`release_gate_pass=false`.

## Validation performed

Build validation:

```sh
make bpf
make w1-oracle
```

Smoke KVM run:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-smoke-v1 \
  W4_CACHE_EPOCH_SAMPLES=1 \
  W4_CACHE_EPOCH_OBJECTS=16
```

Release-style KVM run:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-release-v1 \
  W4_CACHE_EPOCH_SAMPLES=20 \
  W4_CACHE_EPOCH_OBJECTS=16
```

Follow-up release-style KVM run with the materialized baseline included:

```sh
make kvm-w4-cache-epoch-counterfactual \
  RUN_ID=20260629T-w4-cache-epoch-c8-materialized-v1 \
  W4_CACHE_EPOCH_SAMPLES=20 \
  W4_CACHE_EPOCH_OBJECTS=16
```

Input hash verification passed:

```sh
sha256sum -c \
  results/phase1/20260629T-w4-cache-epoch-c8-materialized-v1/w4-cache-epoch-counterfactual-inputs.sha256
```

The materialized follow-up JSONL contains 304 rows:

```sh
wc -l \
  results/phase1/20260629T-w4-cache-epoch-c8-materialized-v1/w4-cache-epoch-counterfactual.jsonl
```

The dmesg issue scan found zero configured kernel diagnostics.

## Release summary

The latest 20-sample materialized follow-up summary row reports:

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

This is the first W4 evidence where an externally updated exact table loses one
of the declared C8 gates while preserving correctness. The static exact table
fails after the cache epoch changes because it keeps returning verified-local
objects when the oracle expects canonical objects. The externally updated table
passes correctness, but it performs one lookup rewrite per visible object,
while the eBPF policy changes epoch with one session update. With 16 objects,
the table update-write ratio is 16, exceeding the declared budget of 10.

The follow-up materialized baseline reaches the same correctness oracle, but it
also needs one visible file copy per object after the epoch switch. Its update
write ratio is also 16. This strengthens the counterfactual by showing that the
same dynamic epoch oracle is expensive for both exact-table rematerialization
and external materialized views.

The correct claim wording is narrow:

- This targeted W4 fixture demonstrates that dynamic cache epoch policy can
  beat exact-table rematerialization under an update-write budget.
- It does not prove full W4 C8 for real ccache or BuildKit because the run is
  not trace-derived and does not report operation-weighted branch hit rates.
- It should be paired with real ccache/BuildKit trace evidence before the paper
  claims W4 as a release-level novelty workload.

## Remaining risks and follow-up

- A real W4 C8 run still needs operation-weighted cache-path branch rates from
  ccache or BuildKit, with output hashes and stale/corrupt reject oracles.
- This fixture proves update-write pressure, not stale-window exposure. A
  stronger version should issue operations during table rewrite and measure
  stale local hits before the table catches up.
- The budget threshold is an experimental gate. The paper must justify it using
  real transition frequency, object fanout, and acceptable stale-window policy.
- FUSE and materialized baselines still need to be compared under the same real
  dynamic cache transitions for release-level W4 claims.
