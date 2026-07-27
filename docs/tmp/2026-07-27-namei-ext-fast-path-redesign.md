# namei_ext Fast-Path Redesign

## Motivation

The valid full-v2 FxMark result contradicts both predeclared RQ2 performance
predictions. Patched-unattached throughput is 6--13% below matched stock, and
the attached policy path is substantially slower than both unattached and a
cache-hot FUSE view.

The result does not justify weakening the hypothesis or replacing the FUSE
baseline. It requires a mechanism redesign followed by a fresh run of the same
approved matrix.

## Evidence Inspected

- `docs/tmp/2026-07-27-rq2-fxmark-result-review.md`;
- all 450 full-v2 observations and the generated paired analysis;
- `kernel/fs/namei.c`, `kernel/fs/namei_ext.c`, and
  `kernel/include/linux/namei_ext.h`;
- matched patched and stock `fs/namei.o` disassembly and symbol sizes; and
- the existing cgroup-BPF static-key implementation.

The inactive branch already uses the cgroup-BPF static key. The problem is
that attached-only local state and restore control flow remain in the inlined
`walk_component` and final-open code even when the key is false. In the matched
objects:

| Object property | Stock | Patched |
| --- | ---: | ---: |
| `link_path_walk` text | 1,605 bytes | 2,372 bytes |
| `link_path_walk` stack allocation | `0x18` | `0x88` |

For the active path, `PASS` explains almost all of the measured loss:
`PASS`/unattached is `0.298--0.547`, while `SELECT`/`PASS` is
`0.980--1.004`. The implementation currently returns `-ECHILD` before running
the BPF program whenever lookup begins in RCU walk, so every active component
is retried in ref-walk mode.

## Alternatives

### A. Out-Of-Line Attached Slow Path

Keep the static-key check in the normal function, but move redirect state,
policy invocation, target application, and redirect restoration into a
non-inlined helper. Put the stock lookup body in an always-inlined common
helper used by both paths.

Expected effect:

- inactive code generation and stack use return close to stock;
- ABI and attached semantics do not change;
- active BPF/RCU cost remains.

Risks:

- the common helper must preserve every stock early return;
- redirect-name storage must remain alive until lookup completes;
- final-open target and `O_CREAT` restrictions must remain unchanged.

Decision: implement first. It is necessary for kernel integration regardless
of later active-path work and has an exact object-code gate.

### B. Execute Policy During RCU Walk

Allow the BPF decision to run in RCU walk. `PASS` can continue without retry.
Actions that require refcounted target acquisition can return `-ECHILD` and
run again after unlazy/restart.

Expected effect:

- removes the unconditional double walk for the common `PASS` components;
- preserves per-lookup policy evaluation;
- keeps `SELECT` target acquisition on the ref-walk path.

Risks:

- cgroup dispatch, every permitted BPF helper/map type, parent inode reads, and
  context initialization must be proven RCU-safe;
- current programs may write maps or emit perf events; fallback or path-walk
  retry can replay those side effects, so replay semantics or an RCU-fast-path
  program restriction must be explicit;
- a policy can observe state twice around fallback, so fail-closed semantics
  and update races need an explicit rule;
- redirect and hide actions need separate RCU analysis.

Decision: analyze and prototype only after Alternative A restores the inactive
path. It is the smallest semantics-preserving active-path repair.

### C. Cache Decisions With Explicit Invalidation

Cache a cgroup/path policy decision and let the policy manager invalidate it
when state changes, analogous to FUSE entry invalidation.

Expected effect:

- can approach ordinary dcache throughput for stable epochs;
- makes a cached-FUSE comparison semantically symmetric if both sides use
  explicit invalidation.

Risks:

- introduces cache key, lifetime, invalidation, target refcount, mount,
  rename, and negative-dentry semantics;
- arbitrary BPF map updates do not identify which cached decision became
  stale;
- a hidden cache-control ABI could make the extension substantially wider.

Decision: defer. Consider it only if the RCU-safe policy path cannot meet the
unchanged hypothesis and only with an explicit update-to-visible oracle.

### D. Invoke Policy Only On Dcache Miss

This would make the microbenchmark fast by definition, but silently changes
the promised per-lookup state-dependent behavior and can leave policy changes
invisible indefinitely.

Decision: reject.

## Staged Implementation

1. Refactor component lookup and final-open lookup so inactive execution uses
   stock-shaped always-inlined common bodies and attached-only state is
   out-of-line.
2. Compile matched `fs/namei.o`; compare `link_path_walk`, `path_lookupat`, and
   open-path text/stack against stock before running performance tests.
3. Run touched kernel-object builds, ABI/BPF/userspace builds, and real KVM
   smoke/load/functional suites.
4. Use a short real FxMark diagnostic to verify direction. Do not promote it
   to paper evidence or rerun the eight-hour final matrix while the active path
   remains structurally unchanged.
5. Audit and prototype the RCU-safe policy path with explicit action-specific
   fallback.
6. Only after inactive and active mechanisms are repaired, run the same
   450-cell approved matrix under a new immutable run ID and obtain a fresh
   result review.

## Validation Gates

- no BPF ABI, action semantics, cgroup scoping, target registry, workload,
  baseline, or interpretation threshold changes;
- patched-unattached object code does not carry redirect buffers or restore
  branches in the normal inlined body;
- all existing redirect, hide, selected-directory, final-directory,
  permissions, create rejection, clear-target, readdir, and failure tests pass
  in the modified-kernel KVM;
- no result from full-v2 is reclassified or removed; and
- the final RQ2 verdict changes only through a fresh full run of the unchanged
  approved matrix.

## Alternative A Implementation Result

`walk_component_common` and `open_last_lookups_common` now contain the
stock-shaped lookup bodies. The static-key wrappers call non-inlined
namei_ext helpers only when the global attach type is active. Redirect buffers,
saved names, target application, and restore control flow therefore no longer
occupy the inactive inlined path.

Matched object-code results:

| Object property | Stock | Before | After |
| --- | ---: | ---: | ---: |
| `link_path_walk` text | 1,605 bytes | 2,372 bytes | 1,639 bytes |
| `link_path_walk` stack allocation | `0x18` | `0x88` | `0x18` |
| `path_lookupat` text | 654 bytes | 260 bytes | 677 bytes |
| `path_lookupat` stack allocation | `0x8` | not comparable after prior compiler split | `0x8` |

The apparent pre-refactor `path_lookupat` text reduction came from compiler
splitting, not a smaller complete lookup path. After the repair, the normal
component-walk code is 34 bytes above stock and has the same stack shape.

Validation completed:

- full patched kernel build;
- ABI: 3 records, zero failures;
- policy load: 10 records, zero failures;
- functional KVM: 51 records, zero failures;
- policy-semantic KVM: 79 records, zero failures;
- no declared dmesg failure signature; and
- five-condition real KVM FxMark preflight: 5/5 passing cells with exact
  kernel identity and result gates.

The two-second `MRPL`, one-worker preflight is directional only. It reported
2.394M ops/s for patched-unattached versus 2.412M for stock
(`0.992`), compared with the full-v2 MRPL-1 median ratio of `0.870`.
Attached `PASS` and `SELECT` remained near 0.97M ops/s versus 2.025M for cached
FUSE. Alternative A therefore repaired the inactive code-generation problem
without hiding the active-path problem. No final performance claim is made
from this single short sample.

An independent code review found no blocking semantic issue in Alternative A.
It verified redirect-name lifetime, target-reference transfer and error puts,
dot handling, final-open behavior, `LOOKUP_CREATE` rejection, and restoration
across common-body early returns. The review also corrected Alternative B's
assumption: the current BPF program type is not read-only, so any RCU design
must account for replayable map/perf side effects before implementation.
