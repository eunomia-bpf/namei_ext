# W4 Bulk Policy Macrobench Implementation

## Motivation

The W4 bulk ccache evidence already had two external cache-view baselines:
`materialized_cache_view` and `fuse_redirect`. It also had a policy-attached
compile smoke witness for Redis and nginx source objects. The missing release
input was a repeated proposed-system setup/update ledger over the same
trace-derived bulk ccache object set. Without that row family, the W4 bulk
ledger could not compare policy view setup and update costs against the FUSE
and materialized baselines.

## Files Inspected

- `tests/w1_oracle/namei_ext_w1_oracle.c`
- `mk/kvm.mk`
- `Makefile`
- `configs/eval-osdi/w4-ccache-workload-macrobench.jq`
- `docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md`
- `docs/tmp/2026-06-16-w4-bulk-fuse-cache-baseline-implementation.md`
- `docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md`

## Design

The new runner mode is:

```text
--ccache-bulk-policy-macrobench OUT_JSONL CGROUP_MOUNT SAMPLES WORK_DIR TRACE_CACHE_DIR ENTRIES_TSV SOURCE_MANIFEST CACHE_POLICY
```

For each sample it copies the traced ccache directory into an isolated sample
directory, then measures only the proposed-system setup path: renaming visible
cache objects to `.local` backing objects, loading `cache_locality_view.bpf.c`,
populating exact lookup and readdir rules, and attaching the policy to the
current KVM cgroup. The sample then measures a cache-object update by writing a
new sample-local backing object and installing lookup/readdir rules for it.

Correctness for each sample checks attached lookup, attached directory
enumeration, post-update lookup/readdir, and post-detach absence of the visible
aliases. The real ccache compile output oracle remains in the separate
`kvm-w4-ccache-bulk-policy-compile` witness so the setup/update macrobench does
not become a repeated compile-throughput benchmark.

## Implementation

The implementation adds `w4-ccache-bulk-policy-macrobench-{setup,update,correctness,summary}`
JSONL rows with result level `kvm_workload_bulk_policy_setup_update_input`.
The Make target `kvm-w4-ccache-bulk-policy-macrobench` boots the modified
kernel under KVM, validates the bulk trace and bridge artifacts, hashes all
declared inputs, runs the C runner, checks the expected row counts, and scans
dmesg for kernel warnings and crashes.

The target uses the same bulk trace-derived TSV consumed by the FUSE and
materialized baselines:

```text
results/phase1/$RUN_ID/w4-ccache-bulk-policy-bridge-entries.tsv
```

No shell helper scripts or non-Make control plane were added.

## Alternatives Rejected

- Reusing the bulk policy compile JSONL as the release setup/update input was
  rejected because it has one compile witness, not repeated setup/update rows.
- Running the full source compile for every setup/update sample was rejected
  because it would mostly measure compiler and ccache runtime rather than VFS
  policy view setup and update costs. The compile correctness oracle remains a
  hard separate input to the W4 bulk ledger.
- Adding a host-only runner was rejected because Phase 1 validation requires
  the modified kernel in KVM.

## Validation Plan

Run a smoke sample first:

```text
make kvm-w4-ccache-bulk-policy-macrobench RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-smoke-v1 W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES=1
```

Then run the release repetition count:

```text
make kvm-w4-ccache-bulk-policy-macrobench RUN_ID=20260616T-w4-ccache-bulk-policy-macrobench-release-v1 W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES=20
```

After the release run, update the W4 workload ledger to consume both this
macrobench and the existing bulk policy compile witness.

## Risks And Follow-Up

The setup timer excludes copying the trace ccache tree into each sample
directory. It includes the metadata work needed to convert visible objects to
policy backing names, load and populate the policy, and attach it. This matches
the proposed-system view activation path, while the materialized and FUSE
baselines measure their own view materialization paths over the same
trace-derived object set. The ledger must continue to report the separate
compile witness rather than treating setup/update rows alone as full W4
application correctness.
