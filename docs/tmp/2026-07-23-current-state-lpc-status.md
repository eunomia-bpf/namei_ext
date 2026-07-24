# Current State For LPC/Upstream Framing

Date: 2026-07-23
Repository: `/home/yunwei37/workspace/namei_ext`
Current pushed commit inspected: `ce87d81 Add build cache experiment matrix`
Branch status before this document: `main...origin/main`

## One-Sentence State

`namei_ext` now has enough evidence for a concrete LPC/upstream discussion:
the patch is a narrow VFS name-resolution extension point with KVM-tested
Agent-workspace and traditional build/cache evidence, but it still needs a
smaller upstream demo, API documentation, kernel selftests, and real
miss/stale/corrupt/epoch compile cells before the broad build/cache
state-machine claim is closed.

## Current Story

The project is not a BPF filesystem and not a table-redirection paper. The
current story is:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

`namei_ext` tests a missing middle: a verifier-bounded BPF policy participates
in VFS name resolution, while the kernel and lower filesystem retain VFS
object, data-path, write, permission, page-cache, and persistence semantics.
The analogy is `sched_ext`: policy is programmable, but the subsystem machinery
stays in the kernel.

## Research Questions In Force

| RQ | Current form | Current evidence status |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Agent-workspace RQ1 rows are complete; build/cache verified-hot-cache row is complete; full build/cache state machine remains open. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with feature-equivalent FUSE? | Build/cache has a matched FUSE row and timing; Agent workspace still needs final timing interpretation before broad RQ2 claims. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` give a narrower verifier-bounded boundary than building a custom or stackable filesystem when the needed behavior is name resolution? | Boundary rows exist for Agent workspace and build/cache; upstream-ready safety/API documentation is still missing. |

## Implementation State

Implemented and exercised paths:

- BPF policy family under `bpf/policies/*.bpf.c`, including
  `cache_locality_view.bpf.c`.
- Real KVM validation path through the modified kernel and
  `cgroup/namei_ext` attach.
- Make-owned experiment entrypoints; `make experiment-env-cache` now runs the
  traditional Redis/nginx ccache build/cache matrix.
- Build/cache result collection now preserves command, kernel config, uname,
  proc version, kernel cmdline, dmesg logs, stdout/stderr, copied raw JSONLs,
  and input/output SHA files.
- Attached ccache policy compile rows now record compile timing as
  `compile_ns` and `compile_ns_avg`.

Still missing for upstream-quality patch review:

- kernel selftests focused on the proposed ABI;
- concise user-facing kernel documentation for the hook contract;
- verifier/safety explanation for allowed actions, failure modes, and
  containment;
- minimal upstream demo target that runs in minutes;
- review of locking/RCU-walk/ref-walk constraints at the exact hook point.

## Completed Evidence

### Agent Workspace RQ1

Formal KVM runs:

- `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`
- `results/experiments/agent-workspace-matrix/20260722T020210Z-rq1run2/`
- `results/experiments/agent-workspace-matrix/20260722T020245Z-rq1run3/`

Each run has 1,176 JSONL records, zero failed records, successful
`namei_ext` and FUSE same-oracle summaries, successful source-trace artifact
and replay gates for both implementations, 16 recorded measurements, empty
stderr, and clean dmesg failure-signature gates. The covered behavior includes
epoch selection, whiteout lookup/readdir coherence, `.git` and source
visibility, symlink and executable behavior, cached-negative creation, rename,
unlink, final-tree state, lower-tree non-materialization, and
unregistered-target containment.

Claim status: good RQ1 evidence for the Agent workspace family. It does not by
itself close RQ2 timing or RQ3 upstream safety.

### Traditional Build/Cache Verified Hot-Cache Row

Release command:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-release-v1
```

Raw root:

```text
results/experiments/build-cache/20260723T-build-cache-release-v1/
```

Terminal summary:

| Metric | `namei_ext` | Native hot ccache | Feature-equivalent FUSE |
| --- | ---: | ---: | ---: |
| Samples | 20 | 20 | 20 |
| Compile jobs | 400 | 400 | 400 |
| Output hash matches | 400 | 400 | 400 |
| Total compile ns | 152,263,433,153 | 157,443,184,178 | 267,748,534,960 |
| Average ns/job | 380,658,582.9 | 393,607,960.4 | 669,371,337.4 |
| Cache path file ops | 8,000 | 8,000 | 6,000 |
| Cache object ops | 3,200 | 3,200 | 3,200 |
| Redirected/direct cache hits | 800 redirected objects | 400 direct hits | 400 direct hits |

Derived ratios:

- FUSE/namei_ext total compile time: `1.758x`.
- Native/namei_ext total compile time: `1.034x`.

Claim status: good scoped RQ1/RQ2 evidence for real Redis/nginx ccache
verified-hot-cache object selection. The strongest interpretation is
correctness plus boundary value; timing is a release-run observation, not yet a
statistical performance claim.

## Claims We Can Make Now

- A real traditional build/cache workload can run through the modified kernel,
  the real `cgroup/namei_ext` attach path, and an attached
  `cache_locality_view.bpf.c` policy.
- The build/cache row passes the same output-object oracle as native hot
  ccache and a feature-equivalent FUSE cache-view implementation.
- The matched FUSE implementation passes the same oracle but has a broader
  filesystem-service boundary: daemon/mount lifecycle and filesystem method
  ownership for `getattr/readdir/open/read/release`.
- `namei_ext` keeps the cache data path and write path owned by ccache and the
  lower filesystem for the tested row.
- The Agent-workspace family has stronger RQ1 coverage than before and is no
  longer just a synthetic preflight.

## Claims We Must Not Make Yet

- Do not claim that real ccache compile workload covers the full
  miss/stale/corrupt/epoch state machine. It currently covers verified
  hot-cache object selection.
- Do not claim broad performance superiority over all FUSE configurations.
  Optimized FUSE and passthrough remain related mechanism pressure.
- Do not claim upstream acceptability without selftests, API documentation,
  and hook-point safety review.
- Do not revive static table or materialized namespace failure as the novelty
  line.

## Immediate Next Experiments

The next experiment work should add state coverage without creating a new weak
baseline catalog.

| Priority | Work | Expected value | Risk |
| --- | --- | --- | --- |
| P0 | Integrate existing `kvm-w4-ccache-bulk-cache-epoch-counterfactual` into `experiment-env-cache` as a trace-derived state row. | Quickly records epoch/state policy over real ccache trace objects with `namei_ext`, FUSE, materialized, and table accounting. | Still not real compile execution. Must be labeled as trace-derived. |
| P1 | Add real compile `miss` and `epoch switch` cells to the current bulk ccache runner. | Extends the real compile oracle beyond hot hits while preserving same output-hash and FUSE comparison structure. | Requires careful ccache setup so the measured behavior is path policy, not only ccache internals. |
| P2 | Add real compile `stale` and `corrupt reject/fallback` cells. | Closes the broad build/cache state-machine claim. | Hardest cell: oracle must prove the bad local object was not exposed to the compile path. |

The current best path is P0 plus P1. P2 should follow only after the miss/epoch
runner proves the compile-state machinery is sound.

## LPC Readiness

The project is ready for an LPC discussion draft, not a final upstream patch
submission. The proposal should ask for subsystem feedback on:

- whether VFS name resolution is an acceptable extension-point boundary;
- which hook location and locking/RCU constraints are acceptable;
- which BPF verifier restrictions are required;
- whether a cgroup-scoped API is the right attachment model;
- which kernel selftests would make reviewers comfortable;
- how to position this relative to eBPF LSM, FUSE, OverlayFS, and custom
  filesystems.

As of 2026-07-23, LPC 2026's official Refereed Track deadline has already
passed, so the current document should be treated as a proposal draft for
microconference discussion, maintainer outreach, or a later venue.
