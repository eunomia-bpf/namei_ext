# BFS Experiment Slate After Epoch-Switch Release

Date: 2026-07-24
Status: strategy correction after user feedback; Candidate A smoke passed

## Correction

The next research step should be breadth-first search, not depth-first
polishing of one path. The project already has a strong story and two main
workload families. What remains uncertain is which next small real probe gives
the largest paper value:

- completing more build/cache state cells;
- showing the result survives as one integrated `experiment-env-cache` package;
- preparing upstream-facing selftests and a small demo;
- or testing whether another traditional workload family has comparable value.

The breadth-first search is still bounded. It does not reopen table-only as the
novelty line, does not add weak baselines, and does not start unrelated
metadata benchmark comparisons. Every candidate below must use the same current
story:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The main comparison remains `namei_ext` versus feature-equivalent FUSE when a
matched run is needed. Native systems remain correctness controls or source
oracles, not main baselines.

## Current Evidence Before BFS

Already valid:

- Agent workspace RQ1 formal KVM runs.
- Traditional Redis/nginx ccache verified-hot-cache compile release.
- Trace-derived build/cache state row.
- Real Redis/nginx ccache epoch-switch compile release:
  `results/phase1/20260724T-epoch-switch-release-v2/`.

Still open:

- real compile miss cell;
- real compile stale reject/fallback cell;
- real compile corrupt reject/fallback cell;
- integrated `make experiment-env-cache` package containing the epoch-switch
  row;
- upstream-facing selftests and small demo.

## BFS Round 1 Candidates

| Candidate | Type | Smallest real probe | Oracle | Main comparison | What a positive result unlocks | Stop condition |
| --- | --- | --- | --- | --- | --- | --- |
| A. Integrated package | Packaging/integration | `make experiment-env-cache BUILD_CACHE_SAMPLES=1` after adding epoch-switch to the matrix | Existing hot-cache, trace-state, native/FUSE, and epoch-switch gates all pass in one result root | Existing feature-equivalent FUSE rows | Removes reviewer objection that epoch-switch is a standalone side result | Stop after 1-sample smoke; do not run a 20-sample release until BFS chooses this path |
| B. Stale-local fallback | Build/cache state | Create stale local backing objects plus correct canonical objects; policy must hide/reject local and select canonical during real compile | Output hash matches hot oracle; bad local hash is not used; direct-hit evidence and cache-object ops cover sources | Feature-equivalent FUSE cache view with the same stale local/canonical backing | Strongest missing state-cell evidence; closes more of Experiment B without changing workload | Stop if ccache cannot be forced to exercise the selected object path under the oracle |
| C. Corrupt-local fallback | Build/cache state | Same as stale, but corrupt local objects with invalid payload while canonical remains correct | Compile succeeds; output matches hot oracle; corrupt object hash is never observed as output/input-selected backing | Feature-equivalent FUSE | Strong fail-closed story: bad local state is rejected while lower FS/data semantics remain external | Stop if corruption causes ccache to bypass object lookup rather than exercise policy |
| D. Local miss to canonical hit | Build/cache state | Remove verified local objects before compile and select canonical backing as fallback | Output matches hot oracle; local object absent; canonical object selected; direct-hit evidence covers sources | Feature-equivalent FUSE | Clarifies whether "miss" can be represented as local-view miss with canonical cache hit | Stop if semantics collapse into the already-proven epoch2 row without a distinguishable oracle |
| E. Upstream minimal selftest/demo | Upstream readiness | Add a tiny KVM/selftest-style demo for pass/hide/select/readdir/invalid decision | Selftest passes; invalid policy fails closed; lower-FS permission/write behavior preserved | No FUSE baseline; this is not RQ2 | Makes LPC/RFC discussion credible independent of workload size | Stop before broad selftest suite; only prove the proposed ABI skeleton is testable |
| F. Service/config lookup-time selection | Breadth workload | Tiny nginx or Redis config/cert epoch where lookup-time object selection changes `nginx -t` or service-visible behavior | Good config passes; bad staged config is hidden/fallback; rollback restores behavior | Feature-equivalent FUSE if admitted | Tests whether a third non-agent workload is worth pursuing | Stop if behavior is merely projected-volume/materialization or app reload, not lookup-time selection |

## Round 1 Order

Run or prepare probes in this order:

1. Candidate A, because it is a cheap validation of existing evidence packaging,
   not a new research direction.
2. Candidate B and C as the highest-value build/cache BFS branches. They target
   the missing stale/corrupt cells directly and keep the strongest current
   workload.
3. Candidate E in parallel or immediately after B/C if upstream discussion is
   the next deadline pressure.
4. Candidate F only if B/C are blocked or reviewers demand a third workload
   family. It should not displace build/cache unless it produces a clearer
   oracle quickly.

Candidate D is only useful if it produces a distinguishable oracle from the
already-passed epoch2 row. Otherwise it should be merged into B/C or dropped.

## Interpretation Rules

- Do not weaken the paper hypothesis because one probe fails. A failed probe
  records a mechanism/workload boundary and informs which BFS branch to try
  next.
- Do not promote a one-sample smoke result into a paper result.
- Do not add more baselines to look comprehensive. Each candidate uses either
  the feature-equivalent FUSE comparison or no baseline when the task is
  upstream selftest readiness.
- Do not claim a state cell is complete unless the real compile oracle, bad
  state non-use evidence, direct-hit/cache-object evidence, FUSE comparison,
  raw artifacts, and result review all pass.

## Immediate Implementation State

Candidate A has an implementation in `mk/kvm.mk`: the epoch-switch guest target
is wired into `__experiment_build_cache_matrix`, and the final matrix summary
now has a `real_compile_epoch_switch_row` field. This passed a Make parse-only
check and a one-sample integrated KVM smoke.

The next concrete action is a one-sample integrated smoke:

```sh
make experiment-env-cache \
  BUILD_CACHE_SAMPLES=1 \
  RUN_ID=20260724T-build-cache-bfs-integrated-smoke-v1
```

Result root:

```text
results/experiments/build-cache/20260724T-build-cache-bfs-integrated-smoke-v1/
```

Result: passed. The matrix has one `build-cache-matrix-summary`, one done row,
zero failed rows, and a clean dmesg gate. The summary includes the existing
hot-cache compile, trace-derived state row, native control, FUSE compile row,
and the new `real_compile_epoch_switch_row`.

Candidate A interpretation: packaging/integration positive. This removes the
standalone-result objection for the epoch-switch row at smoke scale, but it is
not a new paper result and does not justify running a 20-sample integrated
release before trying B/C.

Next action: prepare the smallest real stale-local and corrupt-local fallback
probes, then choose which one deserves implementation depth.
