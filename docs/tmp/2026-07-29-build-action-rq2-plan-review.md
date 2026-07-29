# Build Action RQ2 Plan Review

## Scope

This read-only review checked whether the frozen Build Action RQ2 plan could
execute, compare feature-equivalent mechanisms, and answer the paper's cost
question. It also checked whether repository reorganization was a prerequisite.

## Initial Verdict

The initial plan was `NO-GO` for three reasons:

1. The existing policy map allowed 256 entries, while the 2,048-input
   two-action cell requires 4,096 declared-input entries.
2. The existing `namei_ext` policy used a negative hide list while sandboxfs
   used a positive declared-input view. A file created after setup would
   therefore be visible only through `namei_ext`.
3. Three samples could reuse Bazel state and skip the genrule after the first
   execution.

The repository infrastructure itself was `GO`. Commit `3a2ad6e` already
centralized run lifecycle, named KVM capture, multi-boot evidence, host pinning,
and analysis publication. A directory migration or second runner was not
needed.

## Required Revisions

The plan now requires:

- a dedicated allowlist map with at least 8,192 entries and a preflight that
  fills, reads back, and clears the 4,096 entries needed at maximum scale;
- default-hide behavior under each selected action root, with only declared
  names exposed by both mechanisms;
- an unknown file injected after setup and checked through lookup and readdir;
- a fresh Bazel output base and unique barrier, execution, and output records
  for every sample;
- primary timing from barrier release to the two action-finished records; and
- rotated scale order across paired blocks.

## Infrastructure Decision

The only shared cleanup justified before implementation is external-inventory
capture. FxMark and Checkpoint/Restore already duplicate BPF program, cgroup
attachment, FUSE mount, and `/dev/fuse` owner collection; Build Action would be
the third user. The capture belongs in `mk/multi_boot.mk`. Whether an inventory
must be empty or contain a particular daemon remains suite-owned.

The following remain Build Action semantics and must not move into a generic
experiment template:

- condition order and paired-block schema;
- Bazel output-base and action-execution evidence;
- declared-input and unknown-file visibility;
- sandboxfs lifecycle and resource metrics;
- scale, sample count, correctness gates, and statistical verdict; and
- sandboxfs source, Cargo dependency lock, and build provenance.

## Revised Verdict

`GO` for implementation after the plan revisions above. The implementation
must pass source-level contract tests and an independent code review before the
first real KVM preflight.

## Official-Source Follow-up

A subsequent read-only audit of sandboxfs 0.2.0 found one fairness defect in
the frozen wording: the plan gave sandboxfs read-only mappings while
`namei_ext` retained lower-filesystem write semantics. That would compare a
view mechanism plus an extra sandboxfs-specific denial policy against a view
mechanism alone.

The plan now sets sandboxfs mappings to `writable:true`. Both conditions
therefore rely on the same lower object modes and ownership, while the
generated action performs the same read-only command. This change repairs
feature equivalence; it does not change the RQ, hypothesis, workload, baseline,
primary metric, scale, sample count, or positive-result criterion.

The same source audit also made two lifecycle requirements explicit:

- use a unique sandbox ID for every action and lifecycle sample, because
  sandboxfs provides create and destroy requests but no reset request; and
- wait for matching create/destroy acknowledgements, verify destroyed IDs
  disappear, close the reconfiguration stream, unmount, and require a clean
  daemon exit.

With those corrections, the implementation verdict remains `GO`.
