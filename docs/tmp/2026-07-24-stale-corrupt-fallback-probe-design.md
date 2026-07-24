# Stale And Corrupt Fallback Probe Design

Date: 2026-07-24
Status: BFS Round 1 candidate design, not yet implemented

## Purpose

After the real compile epoch-switch row passed, the next breadth-first probes
should test whether stale or corrupt local cache state can be rejected while a
real Redis/nginx ccache compile still succeeds through canonical backing object
selection.

This is more valuable than immediately deepening the integrated epoch-switch
release because it attacks the remaining build/cache state-machine gap:

```text
hit     -> verified local object
miss    -> canonical backing
stale   -> reject/hide local, fallback canonical
corrupt -> reject/hide local, fallback canonical
epoch   -> switch selected backing generation
```

The epoch row is now covered by real compile. Stale and corrupt are the next
highest-value cells.

## Existing Mechanism Surface

`bpf/policies/cache_locality_view.bpf.c` already exposes the relevant state
names:

```c
CACHE_STATE_VERIFIED_HIT = 1
CACHE_STATE_MISS         = 2
CACHE_STATE_STALE        = 3
CACHE_STATE_CORRUPT      = 4
```

The non-epoch `cache_rules` path has state-specific semantics:

- `VERIFIED_HIT` plus matching witness selects `verified_hit`;
- `MISS` or `STALE` selects `canonical`;
- `CORRUPT` or hash-witness mismatch selects `reject`.

The epoch-rule path currently ignores the state except for recording it and
directly applies the stored redirect. The existing real compile epoch-switch
runner uses epoch rules because it is testing a session update. Stale/corrupt
fallback should first try the non-epoch `cache_rules` path or a small extension
that preserves the same visible/canonical setup while making bad-local non-use
observable.

## Candidate B: Stale-Local Fallback

Hypothesis: a stale local ccache object can exist in the lower tree, but the
visible ccache path resolves to the canonical backing object during real compile
and the output still matches the hot-object oracle.

Minimal setup for one sample:

1. Copy the trace ccache directory to a sample work directory.
2. For each selected ccache object, create:
   - a bad local file: `<visible>.local` containing stale bytes;
   - a correct canonical file: `<visible>.canonical.local` or equivalent hidden
     backing containing the original trace object bytes.
3. Remove the direct visible object.
4. Install a `CACHE_STATE_STALE` rule for the visible object that selects the
   canonical backing.
5. Compile the Redis/nginx source manifest through ccache.
6. Compare every output object to the native hot-object oracle.
7. Record that bad local files existed and their hashes differ from both the
   canonical backing and output objects.

Oracle:

- all compile jobs pass;
- every output object matches the hot oracle;
- bad local object hashes differ from canonical/hot outputs;
- direct-hit or cache-object evidence covers every source;
- ccache path operations include selected ccache object names;
- dmesg gate is clean.

Matched FUSE row:

- expose the same visible ccache path through the FUSE cache view;
- keep the bad local file hidden or rejected;
- select/read the canonical backing for the visible object;
- use the same output-object oracle.

Positive result claim:

Real compiler-output stale-local fallback is supported for the selected
Redis/nginx ccache manifest.

Negative result interpretation:

If ccache bypasses the visible object or treats the setup as a different cache
mode, the result is an implementation/workload-boundary finding, not a reason to
weaken the paper hypothesis.

## Candidate C: Corrupt-Local Reject/Fallback

Hypothesis: a corrupt local ccache object can be rejected or hidden while real
compile falls back to a correct canonical backing and produces the hot-object
oracle output.

There are two possible probe shapes:

### C1: Corrupt Hidden, Canonical Selected

This is closest to stale-local fallback. The local corrupt object exists but is
not selected; the visible path maps to canonical. The oracle proves non-use by
hash mismatch and output equality.

Pros:

- likely implementable with the same structure as stale fallback;
- directly tests "bad local state does not affect compile output";
- feature-equivalent FUSE row is straightforward.

Cons:

- weaker than explicit reject, because the corrupt object is avoided rather
  than selected-and-rejected.

### C2: Explicit Corrupt Reject Then Canonical Fallback

The policy first rejects/hides the corrupt local view and then permits a
canonical lookup path. This requires a precise path sequence where ccache or the
runner attempts the corrupt local object and then canonical backing.

Pros:

- stronger fail-closed story;
- exercises `CACHE_STATE_CORRUPT` or hash-witness mismatch semantics more
  directly.

Cons:

- may require more runner glue to avoid turning the test into a self-authored
  policy protocol;
- ccache may not naturally retry a different object path after an explicit
  lookup rejection.

Round 1 should try C1 first. C2 should only be pursued if C1 passes and there is
evidence that explicit reject/fallback is observable without inventing a new
control interface.

## Smallest Implementation Plan

Do not create a new top-level experiment family. Add one Make-owned KVM target
only if the stale/corrupt runner cannot be expressed as an option of the current
W4 oracle binary.

Preferred runner shape:

```text
--ccache-bulk-compile-bad-local-fallback \
  OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV \
  SOURCE_MANIFEST REDIS_BUILD_SRC NGINX_BUILD_SRC BASELINE_HOT_DIR \
  CACHE_POLICY MODE
```

Where `MODE` is one of:

```text
stale
corrupt-hidden
```

The target should preserve raw observations only:

- JSONL sample rows and summary;
- input SHA;
- output SHA;
- bad-local manifest with hashes;
- strace logs;
- ccache stats/logs;
- dmesg.

## BFS Decision Rule

Run one-sample stale and corrupt-hidden probes before deciding which path gets
full implementation depth.

- If stale passes and corrupt-hidden passes: implement a combined
  stale/corrupt fallback row and then run result review.
- If stale passes but corrupt-hidden fails: stale becomes the next deep path;
  corrupt is recorded as a separate boundary and revisited only if needed.
- If both fail because ccache does not exercise the object path: try Candidate D
  local-miss/canonical-hit or switch to upstream selftest/demo work.
- If implementation requires a new policy-control language, reject that route;
  policies must remain BPF C and Make-owned orchestration.

## Claim Boundary

These probes cannot claim the full build/cache state machine until the matched
`namei_ext` and FUSE rows pass, raw artifacts are preserved, and result review
classifies the run as valid. One-sample probes are BFS evidence only.
