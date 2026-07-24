# Current State, LPC Packet, And Experiment Status

Date: 2026-07-24
Repository: `/home/yunwei37/workspace/namei_ext`

## One-Sentence State

`namei_ext` is now framed as a sched_ext-style VFS name-resolution extension
point between bind/Overlay/materialization, eBPF LSM, and FUSE/custom
filesystems. The strongest current evidence is Agent workspace RQ1 plus a
traditional Redis/nginx ccache build/cache workload with feature-equivalent
FUSE comparison. The 2026-07-24 standalone release closes real compiler-output
coverage for the epoch-switch row, and a one-sample integrated
`experiment-env-cache` smoke confirms packaging. Real miss/stale/corrupt
release cells remain open, but one-sample BFS probes now pass for stale-local
fallback and corrupt-hidden non-use under the same Redis/nginx ccache oracle.

## Current Story

The paper is not a table-redirection paper and not a BPF filesystem paper. The
current story is:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

`namei_ext` lets a verifier-bounded BPF policy participate in VFS name
resolution. The kernel and lower filesystem retain ownership of VFS objects,
permissions, data path, writes, page cache, persistence, and filesystem-specific
semantics. The analogy to discuss with kernel people is `sched_ext`: the policy
is programmable, while the subsystem machinery remains in the kernel.

## Research Questions

| RQ | Current form | Current status |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Agent workspace RQ1 rows are complete. Build/cache verified-hot-cache compile and real epoch-switch compile rows are complete. One-sample stale-local and corrupt-hidden fallback probes pass. Miss and release-scale stale/corrupt compile rows remain open. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with feature-equivalent FUSE? | Build/cache has same-oracle FUSE comparisons for hot-cache compile, trace-derived state selection, real compile epoch switch, and one-sample stale/corrupt-hidden BFS probes. Timing is release-run or probe evidence, not a broad FUSE claim. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed behavior is only name resolution? | Boundary framing is documented. Upstream-quality selftests, API documentation, and hook-point safety review are still missing. |

## Latest Build/Cache Evidence

### Verified Hot-Cache Compile Release

Command:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-state-release-v1
```

Raw root:

```text
results/experiments/build-cache/20260723T-build-cache-state-release-v1/
```

Summary:

| Metric | `namei_ext` | Native hot ccache control | Feature-equivalent FUSE |
| --- | ---: | ---: | ---: |
| Samples | 20 | 20 | 20 |
| Compile jobs | 400 | 400 | 400 |
| Output hash matches | 400 | 400 | 400 |
| Total compile ns | 145,877,006,283 | 137,824,038,806 | 317,994,708,330 |
| Average ns/job | 364,692,515.7 | 344,560,097.0 | 794,986,770.8 |
| Cache path file ops | 8,000 | 8,000 | 6,000 |
| Cache object ops | 3,200 | 3,200 | 3,200 |
| Redirected/direct cache hits | 800 redirected objects | 400 direct hits | 400 direct hits |

Derived observation: `FUSE/namei_ext = 2.180x` by total compile time in this
run. This is a release-run observation, not a broad FUSE performance claim.

### Trace-Derived State Row

Same release root:

```text
results/experiments/build-cache/20260723T-build-cache-state-release-v1/
```

Summary:

| Metric | `namei_ext` | Feature-equivalent FUSE |
| --- | ---: | ---: |
| Samples | 20 | 20 |
| Objects per sample | 16 | 16 |
| State oracle | verified-hit to local; epoch update to canonical | same |
| Pass | true | true |
| Setup writes | 1,940 | 320 |
| Update writes | 20 | 320 |
| FUSE mounts | 0 | 20 |

Claim boundary: this row uses real ccache trace-derived object names and real
KVM attachment, but it is a lookup/readdir state row, not a real compiler-output
state-machine row.

### Real Compile Epoch-Switch Release

Command:

```sh
make kvm-w4-ccache-bulk-compile-epoch-switch \
  W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=20 \
  RUN_ID=20260724T-epoch-switch-release-v2
```

Raw root:

```text
results/phase1/20260724T-epoch-switch-release-v2/
```

Terminal status:

- host exit code: 0;
- JSONL sample rows: 40/40;
- failed rows: 0;
- summary rows: 1;
- done rows: 1;
- dmesg failure-signature count: 0.

Summary:

| Metric | `namei_ext` | Feature-equivalent FUSE |
| --- | ---: | ---: |
| Samples | 20 | 20 |
| Source manifest entries | 20 | 20 |
| Epoch 1 compile jobs | 400 | 400 |
| Epoch 1 output matches | 400 | 400 |
| Epoch 1 direct cache hits | 400 | 400 |
| Epoch 1 compile ns | 142,918,676,763 | 285,034,552,484 |
| Epoch 2 compile jobs | 400 | 400 |
| Epoch 2 output matches | 400 | 400 |
| Epoch 2 direct cache hits | 400 | 400 |
| Epoch 2 compile ns | 140,874,419,542 | 309,449,913,726 |
| Total epoch compile jobs | 800 | 800 |
| Total output matches | 800 | 800 |
| Total epoch compile ns | 283,793,096,305 | 594,484,466,210 |
| Average ns/job | 354,741,370.4 | 743,105,582.8 |
| Cache path file ops | 16,000 | 12,000 |
| Cache object ops | 6,400 | 6,400 |
| Policy session updates | 20 | n/a |
| FUSE mounts | n/a | 20 |
| Setup writes | 6,420 | n/a |
| Update writes | 20 | 800 |
| Backing invalidations | 800 | 800 |

Derived observation: `FUSE/namei_ext = 2.095x` by total epoch compile time in
this run.

Claim impact: Experiment B can now say the real Redis/nginx compiler-output
oracle covers epoch-switch object selection for both `namei_ext` and
feature-equivalent FUSE. It still cannot say that real compile miss, stale, or
corrupt rejection cells are complete.

### Integrated Build/Cache Smoke

Command:

```sh
make experiment-env-cache \
  BUILD_CACHE_SAMPLES=1 \
  RUN_ID=20260724T-build-cache-bfs-integrated-smoke-v1
```

Raw root:

```text
results/experiments/build-cache/20260724T-build-cache-bfs-integrated-smoke-v1/
```

Status:

- one `build-cache-matrix-summary`;
- one done row;
- zero failed rows;
- clean dmesg gate;
- summary includes `real_compile_epoch_switch_row`.

Claim boundary: this is an integrated packaging smoke, not a 20-sample
integrated release and not a new paper result. It shows the standalone
epoch-switch evidence can be included in the build/cache matrix machinery.

### Bad-Local Fallback BFS Probes

Implementation record:

```text
docs/tmp/2026-07-24-bad-local-fallback-probe-implementation.md
```

Stale command:

```sh
make kvm-w4-ccache-bulk-bad-local-fallback \
  RUN_ID=20260724T-bad-local-stale-smoke-v1 \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=stale \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES=1
```

Raw root:

```text
results/phase1/20260724T-bad-local-stale-smoke-v1/
```

Corrupt-hidden command:

```sh
make kvm-w4-ccache-bulk-bad-local-fallback \
  RUN_ID=20260724T-bad-local-corrupt-hidden-smoke-v1 \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=corrupt-hidden \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES=1
```

Raw root:

```text
results/phase1/20260724T-bad-local-corrupt-hidden-smoke-v1/
```

Summary:

| Mode | Metric | `namei_ext` | Feature-equivalent FUSE |
| --- | --- | ---: | ---: |
| stale | Compile jobs / output matches | 20 / 20 | 20 / 20 |
| stale | Direct cache hits | 20 | 20 |
| stale | Bad-local objects | 40 | 40 |
| stale | Bad-local non-use checks | 80 / 80 passed | 80 / 80 passed |
| stale | Compile ns | 7,838,229,684 | 13,627,383,025 |
| corrupt-hidden | Compile jobs / output matches | 20 / 20 | 20 / 20 |
| corrupt-hidden | Direct cache hits | 20 | 20 |
| corrupt-hidden | Bad-local objects | 40 | 40 |
| corrupt-hidden | Bad-local non-use checks | 80 / 80 passed | 80 / 80 passed |
| corrupt-hidden | Compile ns | 7,982,902,246 | 13,235,264,639 |

Claim boundary: these are one-sample BFS probes. They support promoting
stale-local fallback and corrupt-hidden non-use to a release-scale same-oracle
row, but they do not yet close the full miss/stale/corrupt/epoch real compile
state machine. In particular, `corrupt-hidden` is not an explicit
selected-corrupt reject plus natural ccache retry result.

## Agent Workspace Evidence

Formal KVM RQ1 runs:

- `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`
- `results/experiments/agent-workspace-matrix/20260722T020210Z-rq1run2/`
- `results/experiments/agent-workspace-matrix/20260722T020245Z-rq1run3/`

Each run has zero failed records, successful `namei_ext` and FUSE same-oracle
summaries, source-trace artifact/replay gates for both implementations, empty
stderr, and clean dmesg gates. Covered behavior includes epoch selection,
whiteout lookup/readdir coherence, `.git` and source visibility, symlink and
executable behavior, cached-negative creation, rename, unlink, final-tree
state, lower-tree non-materialization, and unregistered-target containment.

Claim boundary: this is strong RQ1 evidence for the Agent workspace family. It
does not by itself settle final RQ2 timing or RQ3 upstream safety.

## What We Can Claim Now

- `namei_ext` has a concrete source-derived Agent workspace RQ1 result and a
  concrete traditional build/cache result.
- The traditional build/cache workload runs through the modified kernel and the
  real `cgroup/namei_ext` attach path.
- The build/cache hot-cache compile row passes the same output-object oracle as
  native hot ccache and feature-equivalent FUSE.
- The build/cache real compile epoch-switch row passes 20 samples for both
  `namei_ext` and FUSE, with all epoch outputs matching the hot-object oracle.
- The stale-local and corrupt-hidden build/cache BFS probes pass one KVM sample
  each for both `namei_ext` and FUSE, with bad-local non-use evidence and
  output-object equality.
- The FUSE rows are the main RQ2 comparator. Native ccache is an oracle/control,
  not the main baseline.
- `namei_ext` keeps ccache and the lower filesystem responsible for data path,
  writes, page cache, and persistence in the tested build/cache rows.

## What We Must Not Claim Yet

- Do not claim the full real compile miss/stale/corrupt/epoch state machine is
  closed. Hot-cache compile and epoch-switch compile are release-scale closed;
  stale-local and corrupt-hidden fallback are one-sample BFS evidence only.
- Do not claim broad superiority over all FUSE variants. Optimized FUSE,
  passthrough, and recent FUSE systems are related mechanism pressure.
- Do not claim upstream readiness without selftests, concise ABI documentation,
  and hook-point safety review.
- Do not revive table-only or materialized-namespace failure as the novelty
  line.

## LPC Proposal

Use the proposal text in:

```text
docs/tmp/2026-07-24-lpc-proposal-and-upstream-reference.md
```

Short title:

```text
namei_ext: a sched_ext-style eBPF extension point for VFS name resolution
```

Short pitch:

`namei_ext` is a narrow, cgroup-scoped VFS name-resolution BPF extension point.
It lets BPF choose bounded lookup/readdir actions while the VFS and lower
filesystem retain object, permission, data-path, write, page-cache, and
persistence semantics. The talk asks whether this is an acceptable kernel
boundary and what restrictions, actions, selftests, and documentation would be
required for an upstream RFC.

## Upstream Reference Packet

Give upstream reviewers:

- the prototype branch and patch summary;
- kernel hook/API note with action enum, context fields, cgroup attach path,
  registered-target lifetime, verifier restrictions, and fail-closed behavior;
- minimal KVM demo command that runs in minutes;
- selftest plan for lookup, readdir, hide, target selection, invalid actions,
  cgroup scoping, policy unload, and lower-filesystem permission/write
  preservation;
- RCU/ref-walk safety note for the hook point;
- boundary note comparing eBPF LSM, FUSE, OverlayFS/bind mounts, and
  custom/stackable filesystems;
- result summary for Agent workspace and build/cache;
- raw result roots listed in this document.

External references:

- LPC 2026 CFP: `https://lpc.events/event/20/abstracts/`
- Linux pathname lookup:
  `https://docs.kernel.org/filesystems/path-lookup.html`
- `sched_ext`: `https://docs.kernel.org/scheduler/sched-ext.html`
- BPF LSM: `https://docs.kernel.org/bpf/prog_lsm.html`
- FUSE: `https://docs.kernel.org/filesystems/fuse/fuse.html`
- FUSE passthrough:
  `https://docs.kernel.org/next/filesystems/fuse-passthrough.html`

Local references:

- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `docs/reference/INDEX.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md`
- `docs/tmp/2026-07-24-build-cache-real-compile-epoch-implementation.md`
- `docs/tmp/2026-07-24-bad-local-fallback-probe-implementation.md`
- `docs/tmp/2026-07-24-lpc-proposal-and-upstream-reference.md`
- `docs/tmp/2026-07-24-bfs-experiment-slate.md`
- `docs/tmp/2026-07-24-stale-corrupt-fallback-probe-design.md`

## Immediate Next Work

1. Submit the LPC eBPF Track proposal using the 2026-07-24 packet.
2. Prepare an upstream RFC note with the hook/API, safety model, and selftest
   plan.
3. Add kernel selftests and a smaller KVM demo target.
4. Decide whether to promote the stale/corrupt-hidden bad-local fallback probe
   to a 20-sample combined same-oracle run and result review.
5. Keep the real compile miss cell and explicit selected-corrupt reject/retry
   as separate candidates; do not expand baselines before this decision.
