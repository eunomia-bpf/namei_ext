# W4 cache transition counterfactual

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## Motivation

The W4 cache-locality evidence already had KVM path oracle, cache-content
oracle, real ccache trace witnesses, FUSE/native/materialized baselines, and
table-only sampled comparators. The remaining C8 gap was sharper: the paper
needed a stale/corrupt/update-window counterfactual that distinguishes a
stateful cache policy from a static exact-redirect table.

This step does not try to prove C8. It records a narrower result: a static
table fixed to verified local cache objects fails the current stale/corrupt
oracle, while an externally updated exact table still passes after writing the
same transition state. Therefore the new evidence closes a missing W4
measurement shape, but the family remains `qualified_for_c8=false`.

## Files changed

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Added `--cache-transition-counterfactual`.
  - Added three W4 systems per sample:
    - `cache_locality_state_policy` uses `cache_locality_view.bpf.c`, materializes
      current state, and updates stale/corrupt entries between local verified,
      canonical fallback, and reject targets.
    - `table_redirect_static_verified` uses `table_redirect.bpf.c` with exact
      redirects fixed to local verified cache targets. It is expected to fail
      stale/corrupt current-oracle checks by producing wrong local hits.
    - `table_redirect_updated_exact` uses `table_redirect.bpf.c` after external
      map updates to match the current target. This passes, so it prevents a C8
      upgrade.
  - Added raw JSONL rows for setup, correctness, update-window transitions, and
    a summary.
- `mk/kvm.mk`
  - Added `kvm-w4-cache-transition-counterfactual` and the guest target
    `__phase1_guest_w4_cache_transition_counterfactual`.
  - The guest target runs in the modified kernel, checks inputs and policy
    objects, writes an input hash manifest, executes the oracle runner, saves
    dmesg, and hard-gates the summary with `jq`.
- `Makefile`
  - Exposed the new KVM target in `.PHONY` and `make help`.
  - Added the target to the default `phase1` dependency chain so the evidence is
    owned by the Phase 1 Makefile control plane.

## Review hardening

Post-review hardening added three checks before treating the result as paper
evidence:

- The W4 transition guest target now runs `sha256sum -c` on
  `w4-cache-transition-counterfactual-inputs.sha256` inside the target.
- The W4 transition guest target now fails on dmesg `BUG`, `WARNING`, `Oops`,
  `Call Trace`-style kernel diagnostics covered by the existing Phase 1 awk
  gate pattern.
- The static exact-table branch now measures the current oracle directly and
  counts a static wrong-local hit only when the table observes a local verified
  cache object while the current stale/corrupt oracle fails.

## Validation

Build and local runner validation:

```sh
make w1-oracle
```

KVM smoke:

```sh
make kvm-w4-cache-transition-counterfactual \
  RUN_ID=20260617T-w4-cache-transition-hardgate-smoke-v1 \
  W4_CACHE_TRANSITION_SAMPLES=1
```

KVM release-style run:

```sh
make kvm-w4-cache-transition-counterfactual \
  RUN_ID=20260617T-w4-cache-transition-hardgate-release-v1 \
  W4_CACHE_TRANSITION_SAMPLES=20
```

Release result root:

```text
results/phase1/20260617T-w4-cache-transition-hardgate-release-v1/
```

Input hash verification passed for:

```text
results/phase1/20260617T-w4-cache-transition-hardgate-release-v1/w4-cache-transition-counterfactual-inputs.sha256
```

The dmesg log
`results/phase1/20260617T-w4-cache-transition-hardgate-release-v1/dmesg-w4-cache-transition-counterfactual.log`
has no `BUG:`, `Oops`, `Call Trace`, `WARNING:`, or `verifier` hit.

## Release summary

The release-style JSONL summary is:

- `samples=20`
- `setup_rows=60`
- `correctness_rows=240`
- `update_rows=160`
- `entries=4`
- `stateful_entries=2`
- `static_wrong_local_hits=40`
- `policy_transition_rows=80`
- `table_transition_rows=80`
- `policy_transition_passes=80`
- `table_transition_passes=80`
- `state_transition_hit_rate=1`
- `policy_update_writes=160`
- `table_update_writes=160`
- `table_update_write_ratio=1`
- `table_static_current_oracle_pass=false`
- `table_updated_current_oracle_pass=true`
- `table_requires_external_state_updates=true`
- `table_update_budget_failure=false`
- `release_sample_budget_pass=true`
- `pass=true`
- `failures=0`
- `policy_executed=true`
- `kvm_validated=true`
- `qualified_for_c8=false`
- `release_gate_pass=false`

## Interpretation

This run is useful negative evidence. It proves that a static exact table that
keeps redirecting stale/corrupt objects to local verified cache targets violates
the current cache-state oracle. However, once user space performs external
exact-table updates, the table-only policy still passes with the same number of
update writes as the programmable policy. The observed table update-write ratio
is `1`, and `table_update_budget_failure=false`.

Therefore this result should be cited as a W4 stale/corrupt/update-window
counterfactual, not as a C8-supporting result. W4 still needs release-level
operation-weighted policy hit rate, a real stale/corrupt ccache transition,
BuildKit/Prometheus cache-path workload evidence, and a table-only budget,
stale-window, or over-materialization failure before it can qualify for C8.
