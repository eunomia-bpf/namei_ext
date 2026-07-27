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

### B. Avoid A Full RCU-Walk Restart

First attempt an in-place transition from RCU walk to ref-walk with the
existing `try_to_unlazy()` helper before invoking BPF. If the current path and
link stack can be legitimized, policy execution continues from the current
component. If validation fails, return `-ECHILD` before invoking BPF and let
the caller restart from the beginning.

Expected effect:

- removes the unconditional full-path restart for an attached policy;
- does not replay BPF execution or its map/perf side effects;
- preserves per-lookup policy evaluation;
- keeps all actions and target acquisition on the established ref-walk path.

Risks:

- the attached path still leaves RCU walk and pays refcounting cost;
- long paths still invoke BPF once per component;
- `try_to_unlazy()` failure must return immediately without touching
  `nameidata`, as required by the VFS helper contract.

Decision: implement after Alternative A. This is the smallest
semantics-preserving active-path repair and gives a clean diagnostic before
considering BPF execution inside RCU walk.

If this does not close the active-path gap, the next alternative is to execute
only the decision phase in RCU walk and selectively unlazy actions that require
references. That design is wider: cgroup dispatch, every permitted helper and
map operation, parent inode reads, and retry/replay semantics would need an
explicit contract. It must not be described as read-only because the current
program type permits map updates and perf output.

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
5. Replace the unconditional `-ECHILD` with in-place `try_to_unlazy()` before
   BPF invocation and run the same correctness and short diagnostic gates.
6. If the gap remains material, audit an RCU decision phase with explicit
   action-specific fallback and replay semantics.
7. Only after inactive and active mechanisms are repaired, run the same
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

## Alternatives B And RCU Decision Results

The in-place-unlazy variant passed all correctness gates but improved the
one-worker `MRPL` `PASS` result only from approximately 0.97M to 1.01M
operations/s. Avoiding a full restart was therefore correct but insufficient.

The follow-up RCU decision phase keeps `PASS` in RCU walk and unlazies only
actions or errors that require references or terminal validation. Its
directional preflight improved `PASS` to 1.25M and `SELECT` to 1.10M
operations/s, but cached FUSE remained at 1.85M. Full implementation and
validation details are recorded in
`docs/tmp/2026-07-27-namei-ext-rcu-decision-implementation.md`.

Program run-count attribution then found approximately ten BPF invocations per
FxMark work unit and about 24 ns in the BPF body per invocation. The remaining
problem is dispatch breadth across pathname components, not policy instruction
cost. The raw-counter method and immutable diagnostic result are recorded in
`docs/tmp/2026-07-27-fxmark-bpf-invocation-attribution.md`.
