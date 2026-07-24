# Build/Cache Real Compile Epoch-Switch Implementation

Date: 2026-07-24
Status: implemented; standalone KVM release and integrated smoke passed

## Motivation

The 2026-07-23 build/cache release run already covered a real Redis/nginx
ccache hot-cache compile path and a separate trace-derived state row over real
ccache object names. The remaining reviewer gap was that the epoch/state row
was not connected to compiler output. A reviewer could reasonably argue that
the state mechanism was only a lookup/readdir oracle and that the real compiler
path had not observed an epoch transition.

This implementation adds a direct real-compile epoch-switch row for Experiment
B. It does not revive table-only baselines and does not change the paper story.
The main comparison remains `namei_ext` versus a feature-equivalent FUSE cache
view under the same output-object oracle.

## Files Changed

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md`

## Runner Design

The new runner entrypoint is:

```text
--ccache-bulk-compile-epoch-switch OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST REDIS_BUILD_SRC NGINX_BUILD_SRC BASELINE_HOT_DIR CACHE_POLICY
```

For each trace-derived ccache object, the runner prepares two lower-filesystem
backing names:

- epoch 1 local object: `<visible>.local`
- epoch 2 canonical object: `<visible>.e2.local`

The direct visible object is removed. Under `namei_ext`, the BPF policy maps
the visible ccache object name to the epoch-specific backing name. Under FUSE,
the feature-equivalent cache view exposes the same visible path and updates the
backing state between epochs.

The test sequence for each sample is:

1. Copy the trace ccache directory into an isolated sample work directory.
2. Prepare epoch 1 and epoch 2 backing files for each selected ccache object.
3. Load `cache_locality_view.bpf.c` as the `cache_locality_epoch` policy.
4. Populate lookup and readdir rules for the actual nested ccache parent
   directories.
5. Attach through the real `cgroup/namei_ext` KVM path.
6. Run Redis/nginx ccache compiles in epoch 1 and compare every output object
   to the native hot-object oracle.
7. Delete epoch 1 local backing files.
8. Update the BPF session to epoch 2.
9. Run the same compiles again and compare every output object to the same hot
   oracle.
10. Run the matched FUSE cache view with the same source manifest and backing
    objects.

Deleting epoch 1 local objects before epoch 2 is important: it prevents a false
pass where ccache accidentally reuses the old local backing after the policy
session update.

## Make Targets

The new standalone KVM target is:

```sh
make kvm-w4-ccache-bulk-compile-epoch-switch \
  W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=1 \
  RUN_ID=20260724T-epoch-switch-smoke-v2
```

The target depends on:

- `$(KERNEL_IMAGE)`
- `bpf`
- `w1-oracle`
- `kvm-w4-ccache-bulk-policy-bridge`

The guest target writes raw JSONL, input SHA files, output SHA files, strace
logs, ccache logs/stats, and dmesg logs under:

```text
results/phase1/<RUN_ID>/
```

While validating this target, the standalone W4 bulk KVM entrypoints were also
fixed to pass `ENABLE_LEGACY_DIAGNOSTICS=1` into guest Make invocations. Without
that flag, the guest Makefile did not include the workload path definitions
needed by the Redis/nginx source manifest.

## Correctness Gates

The guest Make target fails unless all of the following hold:

- the source manifest has the expected Redis/nginx source count;
- both `namei_ext` epochs compile every source;
- both FUSE epochs compile every source;
- every epoch output object matches the native hot ccache oracle;
- ccache direct-hit evidence covers every source in both epochs;
- cache-path and cache-object operation traces are preserved;
- `namei_ext` records one policy session update per sample;
- FUSE records one mount per sample;
- `real_compile_epoch_switch == true`;
- `feature_equivalent_fuse == true`;
- `miss_stale_corrupt_compile_cells_closed == false`;
- dmesg has no BUG/WARNING/Oops/panic/hung-task signatures.

The explicit `miss_stale_corrupt_compile_cells_closed == false` gate keeps the
claim boundary honest: this row closes real compile coverage for epoch switch,
not the full miss/stale/corrupt state machine.

## Validation Performed

Local build validation:

```sh
make w1-oracle bpf
```

Result: passed.

KVM smoke:

```sh
make kvm-w4-ccache-bulk-compile-epoch-switch \
  W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=1 \
  RUN_ID=20260724T-epoch-switch-smoke-v2
```

Result root:

```text
results/phase1/20260724T-epoch-switch-smoke-v2/
```

Smoke summary:

| Metric | `namei_ext` | FUSE |
| --- | ---: | ---: |
| Samples | 1 | 1 |
| Source manifest entries | 20 | 20 |
| Epoch 1 compile jobs | 20 | 20 |
| Epoch 1 output matches | 20 | 20 |
| Epoch 1 direct cache hits | 20 | 20 |
| Epoch 2 compile jobs | 20 | 20 |
| Epoch 2 output matches | 20 | 20 |
| Epoch 2 direct cache hits | 20 | 20 |
| Policy session updates | 1 | n/a |
| FUSE mounts | n/a | 1 |

Full 20-sample release run:

```sh
make kvm-w4-ccache-bulk-compile-epoch-switch \
  W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=20 \
  RUN_ID=20260724T-epoch-switch-release-v2
```

Result root:

```text
results/phase1/20260724T-epoch-switch-release-v2/
```

Result: passed with host exit code 0, 40/40 sample rows, one summary row, one
done row, zero failed rows, and clean dmesg gate.

Release summary:

| Metric | `namei_ext` | FUSE |
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

Derived timing observation for this release run:

- FUSE/namei_ext total epoch compile time: `2.095x`.

The timing ratio is a release-run observation, not a broad FUSE performance
claim. The correctness result is the load-bearing evidence: both mechanisms
pass the same real compiler-output oracle across the epoch switch.

## Claim Impact

Experiment B can now say:

- real Redis/nginx compile execution covers the epoch-switch row;
- the same output-object oracle passes for `namei_ext` and FUSE;
- `namei_ext` performs the epoch switch with BPF session update while ccache
  and the lower filesystem keep data/write semantics;
- the FUSE comparison remains feature-equivalent and owns the daemon/mount
  filesystem boundary.

Experiment B still cannot say:

- real compile miss/stale/corrupt rejection cells are closed;
- `namei_ext` is broadly faster than all FUSE designs;
- upstream safety is settled without selftests and hook-point review.

## Integrated Matrix Smoke

After the 20-sample standalone release, the epoch-switch row was folded into
`make experiment-env-cache` as a packaging/integration candidate. The integrated
matrix now copies the epoch-switch raw JSONL, input SHA, output SHA, and dmesg
artifacts into the build-cache result root and adds a
`real_compile_epoch_switch_row` field to `build-cache-matrix-summary`.

Integrated smoke command:

```sh
make experiment-env-cache \
  BUILD_CACHE_SAMPLES=1 \
  RUN_ID=20260724T-build-cache-bfs-integrated-smoke-v1
```

Result root:

```text
results/experiments/build-cache/20260724T-build-cache-bfs-integrated-smoke-v1/
```

Result: passed with one build-cache matrix summary, one done row, zero failed
rows, and clean dmesg gate. This validates the integrated packaging path at
smoke scale. It is not a 20-sample integrated paper result.

## Remaining Risks

- The integrated `make experiment-env-cache` path has passed one-sample smoke,
  but it has not been rerun as a 20-sample integrated release.
- The broad build/cache state-machine claim still needs real miss, stale, and
  corrupt rejection compile cells.
- The upstream version needs a much smaller demo and kernel selftests.
