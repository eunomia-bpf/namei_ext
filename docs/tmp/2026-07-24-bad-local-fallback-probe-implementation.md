# Bad-Local Fallback Probe Implementation

Date: 2026-07-24
Status: implemented and smoke-validated in KVM

## Motivation

The build/cache experiment already has real compiler-output evidence for
verified hot-cache selection and epoch switching. The next bounded
breadth-first question was whether stale or corrupt local cache objects can be
kept out of the visible ccache path while the compile still reads a correct
canonical backing object.

This is a BFS probe, not a final release result. It tests whether this branch is
worth promoting before spending a full run budget.

## Code Paths Changed

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Added `--ccache-bulk-bad-local-fallback`.
  - Added two modes: `stale` and `corrupt-hidden`.
  - Reused the existing Redis/nginx ccache source manifest, trace-derived cache
    objects, hot-object output oracle, cgroup attach path, and FUSE cache-view
    implementation.
  - Added JSONL sample and summary rows under schema
    `namei_ext.eval_osdi.w4_ccache_bulk_bad_local_fallback.v1`.
- `mk/kvm.mk`
  - Added `kvm-w4-ccache-bulk-bad-local-fallback`.
  - Added guest target `__phase1_guest_w4_ccache_bulk_bad_local_fallback`.
  - Added input/output SHA files and dmesg gates.

## Design

For each selected ccache object, the runner prepares:

```text
visible object path       -> the path ccache asks for
<visible>.local           -> stale or corrupt bad local object
<visible>.e2.local        -> correct canonical backing object
```

For `namei_ext`, the direct visible file is removed from the lower tree. The
attached `cache_locality_view.bpf.c` policy installs `cache_rules` entries so
lookup of the visible name resolves to the canonical hidden backing while the
bad local file remains present in the lower tree.

For FUSE, the feature-equivalent cache view exposes the same visible ccache
path while hiding `.local` names. The backing tree keeps the bad local file and
also leaves the direct visible file as the good object, which matches the FUSE
implementation's current direct-first behavior.

The correctness oracle is:

- all Redis/nginx ccache compile jobs finish;
- every output object matches the hot-cache object oracle;
- direct cache-hit evidence covers every source row;
- bad local objects exist;
- visible path content matches the canonical object and differs from the bad
  local object;
- dmesg has no kernel failure signatures.

## Validation

Build validation:

```sh
make w1-oracle bpf
```

Result: passed.

Make parse check:

```sh
make -q -p __phase1_guest_w4_ccache_bulk_bad_local_fallback \
  RUN_ID=make-parse \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=stale
```

Result: Make parsed the target. Exit status was 1 because the phony target was
out of date, not because of a parse error.

Stale KVM probe:

```sh
make kvm-w4-ccache-bulk-bad-local-fallback \
  RUN_ID=20260724T-bad-local-stale-smoke-v1 \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=stale \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES=1
```

Result root:

```text
results/phase1/20260724T-bad-local-stale-smoke-v1/
```

Summary:

- `pass=true`, `failures=0`;
- 20 compile jobs for `namei_ext`, 20 output matches, 20 direct hits;
- 20 compile jobs for FUSE, 20 output matches, 20 direct hits;
- 40 bad local objects in each row;
- 80/80 bad-local non-use checks passed in each row;
- dmesg gate passed.

Corrupt-hidden KVM probe:

```sh
make kvm-w4-ccache-bulk-bad-local-fallback \
  RUN_ID=20260724T-bad-local-corrupt-hidden-smoke-v1 \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=corrupt-hidden \
  W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES=1
```

Result root:

```text
results/phase1/20260724T-bad-local-corrupt-hidden-smoke-v1/
```

Summary:

- `pass=true`, `failures=0`;
- 20 compile jobs for `namei_ext`, 20 output matches, 20 direct hits;
- 20 compile jobs for FUSE, 20 output matches, 20 direct hits;
- 40 bad local objects in each row;
- 80/80 bad-local non-use checks passed in each row;
- dmesg gate passed.

## Remaining Risks

- These are one-sample BFS probes. They should not be described as final
  release evidence without a larger run and result review.
- `corrupt-hidden` proves that a corrupt local object is not selected. It does
  not yet prove an explicit selected-corrupt reject followed by a natural ccache
  retry.
- The real compile miss cell is still open.
- The integrated `experiment-env-cache` package does not yet include this
  bad-local fallback row.
