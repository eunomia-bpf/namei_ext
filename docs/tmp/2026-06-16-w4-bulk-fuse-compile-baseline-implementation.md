# W4 Bulk FUSE Compile Baseline Implementation

## Motivation

The W4 bulk ccache evaluation already had a read-oriented FUSE cache-view
baseline. That closed the setup/update view baseline, but it did not answer the
stronger reviewer question: can the same Redis/nginx hot ccache compile run
with `CCACHE_DIR` served through the FUSE baseline?

This step adds a Make-owned KVM target for that compile-through-FUSE baseline.
It is an external baseline input only. It does not make C2 or C8 supported.

## Code Paths

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Added `--ccache-bulk-fuse-compile`.
  - Reuses the existing W4 FUSE daemon operations.
  - Copies the hot trace-derived `CCACHE_DIR` into a per-sample tree, renames it
    as the FUSE backing tree, and mounts FUSE at the original cache path.
  - Runs all source manifest compiles with `CCACHE_DIR` pointing at the FUSE
    mount.
- `mk/kvm.mk`
  - Added `kvm-w4-ccache-bulk-fuse-compile`.
  - The target depends on bulk trace and trace-derived policy bridge evidence.
  - The guest target writes raw JSONL, input hashes, output hashes, and dmesg.
- `Makefile`
  - Exposes the new target in `.PHONY` and `make help`.

## Design Choices

The FUSE compile baseline keeps the cache view read-only. ccache is run with
`CCACHE_READONLY=1`, `CCACHE_READONLY_DIRECT=1`, `CCACHE_NOSTATS=1`, and a
sample-local `CCACHE_TEMPDIR`, so ccache does not try to write stats or
temporary files into the FUSE mount.

Because stats are disabled, the direct hit count comes from `CCACHE_LOGFILE`
instead of `ccache --print-stats`. Each sample must show at least one
`direct_cache_hit` per compiled source, every output object must match the hot
native object, and strace must observe cache-object file operations under the
FUSE-mounted `CCACHE_DIR`.

## Alternatives Rejected

- Extending the existing read-only FUSE cache-view baseline and treating it as
  compile-through-FUSE: rejected because it never runs ccache through the FUSE
  mount.
- Adding write support for stats/tmp paths in the FUSE daemon: rejected for this
  step because ccache has documented read-only and no-stats modes, and the
  baseline should preserve the read-only cache-view semantics.
- Running the FUSE compile on the host: rejected because Phase 1 validation must
  boot the modified kernel in KVM.

## Validation Performed

Initial validation ran:

```text
make w1-oracle
make kvm-w4-ccache-bulk-fuse-compile RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-smoke-v1 W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=1
```

The first KVM smoke failed correctly because the log parser only counted
`Result: direct_cache_hit`, while the read-only no-stats ccache log records one
`Succeeded getting cached result` line for each successful cached compile. The
runner was fixed to count both forms as direct cached-result evidence.

The fixed target passed:

```text
make w1-oracle
git diff --check -- Makefile mk/kvm.mk tests/w1_oracle/namei_ext_w1_oracle.c docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md
make kvm-w4-ccache-bulk-fuse-compile RUN_ID=20260616T-w4-ccache-bulk-fuse-compile-smoke-v2 W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=1
```

The raw JSONL summary in
`results/phase1/20260616T-w4-ccache-bulk-fuse-compile-smoke-v2/w4-ccache-bulk-fuse-compile.jsonl`
recorded one passing sample, 20 source-manifest compiles, 20 output matches, 20
ccache cached-result log hits, one FUSE mount, 300 cache-path file operations,
160 cache-object operations, and `read_oriented_cache_view_only=false`.

The KVM target fails if any sample lacks a FUSE mount, has fewer ccache cached
result log hits than source-manifest entries, produces a mismatched object, or
records kernel BUG/WARNING/Oops/panic messages.

## Remaining Risks

This is still an external baseline, not a proposed-system release result. It
does not prove operation-weighted policy cache hit rate for C8, and it does not
resolve W4 stale/corrupt/update-window evidence. If it passes, the next step is
to integrate the FUSE compile input into the W4 workload ledger without turning
the negative C2/C8 verdict positive.
