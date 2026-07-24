# Build/Cache State Row Result Report

Date: 2026-07-23
Run ID: `20260723T-build-cache-state-release-v1`
Raw root:
`results/experiments/build-cache/20260723T-build-cache-state-release-v1/`

## Question

Experiment B now asks for two pieces of evidence in one build/cache matrix:

1. Real Redis/nginx ccache hot-cache compiles pass through `namei_ext`, native
   ccache, and feature-equivalent FUSE under the same output-object oracle.
2. Over real ccache cache-object names from the trace, `namei_ext` and FUSE
   both satisfy a state-transition lookup/readdir oracle for verified-local to
   canonical epoch selection.

The second row is a trace-derived state oracle, not a full real compiler
miss/stale/corrupt/epoch-switch execution.

## Command

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-state-release-v1
```

The command completed in KVM through the real modified-kernel
`cgroup/namei_ext` attach path.

## Terminal Summary

The terminal `build-cache-matrix-summary` row reports:

| Metric | `namei_ext` | Native hot ccache | Feature-equivalent FUSE |
| --- | ---: | ---: | ---: |
| Samples | 20 | 20 | 20 |
| Compile jobs | 400 | 400 | 400 |
| Output hash matches | 400 | 400 | 400 |
| Total compile ns | 145,877,006,283 | 137,824,038,806 | 317,994,708,330 |
| Average ns/job | 364,692,515.7 | 344,560,097.0 | 794,986,770.8 |
| Average ns/sample | 7,293,850,314.2 | 6,891,201,940.3 | 15,899,735,416.5 |
| Cache path file ops | 8,000 | 8,000 | 6,000 |
| Cache object ops | 3,200 | 3,200 | 3,200 |
| Redirected/direct cache hits | 800 redirected objects | 400 direct hits | 400 direct hits |

Derived release-run ratios:

- FUSE/namei_ext total compile time: `2.180x`.
- Native/namei_ext total compile time: `0.945x`.

These are release-run observations, not confidence intervals.

## State Row

The nested `trace_derived_state_row` reports:

| Field | Value |
| --- | --- |
| Samples | 20 |
| Objects per sample | 16 |
| Real trace entries available | 40 |
| Oracle | trace-derived lookup/readdir state transition over real ccache object names |
| State coverage | verified-hit to local, epoch update to canonical, canonical fallback |
| `namei_ext` pass | true |
| FUSE pass | true |
| `namei_ext` setup writes | 1,940 |
| `namei_ext` update writes | 20 |
| FUSE setup writes | 320 |
| FUSE update writes | 320 |
| FUSE mounts | 20 |

Interpretation: the state row demonstrates the epoch/state policy mechanism
over ccache-derived object names and a feature-equivalent FUSE row. It is
useful RQ1 mechanism evidence and RQ2/RQ3 boundary evidence. It is not a
compiler-output state-machine row.

## Validation

Post-run checks:

```sh
sha256sum -c results/experiments/build-cache/20260723T-build-cache-state-release-v1/build-cache-matrix-inputs.sha256
grep -E 'BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN' results/experiments/build-cache/20260723T-build-cache-state-release-v1/dmesg-build-cache-matrix.log
jq -s '[.[] | select(.pass? == false)] | length' results/experiments/build-cache/20260723T-build-cache-state-release-v1/*.jsonl
```

Results:

- input hash check: all runtime code/result inputs still match, with one
  expected post-run documentation drift in
  `docs/tmp/2026-07-23-build-cache-experiment-b-plan.md`
  (`51261bca...` recorded during the run, `ae7f6cd7...` after the plan was
  updated to describe this state-row result);
- dmesg failure-signature grep: no matches;
- captured stderr: 0 bytes;
- failed JSONL rows across the result root: 0.

## Result Review

- Run status: valid for the scoped hot-cache compile plus trace-derived state
  row.
- Tested hypothesis: supported for verified-hot-cache compile correctness and
  trace-derived verified-local to canonical epoch state selection.
- Research value: stronger than the previous hot-cache-only Experiment B row,
  because the state mechanism is now inside the same `experiment-env-cache`
  matrix rather than a separate legacy diagnostic.
- Paper impact: supports the non-agent build/cache story and gives the LPC
  packet a concrete state-transition answer without reopening table-only as the
  novelty line.
- Remaining uncertainty: full real compile miss/stale/corrupt/epoch-switch
  cells remain open.

## Claim Boundary

Can claim now:

- `make experiment-env-cache` runs a KVM build/cache matrix with real ccache
  hot-cache compiles, feature-equivalent FUSE, and a trace-derived state row.
- The state row uses ccache trace-derived object names and passes under both
  `namei_ext` and FUSE.
- For the state row, `namei_ext` reaches canonical epoch selection with one
  session update per sample, while FUSE updates per-object backing state.

Must not claim yet:

- the real compile workload covered miss/stale/corrupt/epoch-switch
  compiler-output behavior;
- broad FUSE performance superiority across optimized FUSE/passthrough designs;
- final upstream acceptability without selftests, API docs, and hook-point
  safety review.
