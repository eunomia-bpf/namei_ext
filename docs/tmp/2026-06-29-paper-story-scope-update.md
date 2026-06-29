# Paper story scope update

Date: 2026-06-29
Type: research/story record

## Motivation

The paper had recently moved away from making redirect tables or table-only
failure the novelty story. The next cleanup is broader: the paper should not
read as a list of workload-specific baselines. It should present `namei_ext` as
a general but narrow programmable filesystem abstraction centered on dynamic
path views.

This record backs up the superseded framing and records the new story so that
future edits do not drift back to either redirect-table novelty or a baseline
catalog.

## Superseded framing

The previous story was:

- `namei_ext` is a narrow VFS path-resolution eBPF extension point.
- Existing kernel mechanisms are efficient but fixed; FUSE is flexible but
  moves path resolution to userspace.
- Evaluation should compare each workload against its natural baselines:
  copy/symlink/bind/projected-volume/FUSE/materialized views, with exact-map
  diagnostics only when precomputed mappings are relevant.

That framing was useful for avoiding the redirect-table trap, but it still made
the paper sound baseline-driven. It also underplayed the safety/TCB argument
that systems reviewers expect when comparing kernel changes, custom
filesystems, and FUSE.

## New story

The paper should lead with this thesis:

> Existing filesystem-extension mechanisms force a tradeoff among
> expressiveness, safety, and efficiency. `namei_ext` explores a general but
> narrow programmable filesystem abstraction: dynamic path views at VFS name
> resolution, with eBPF-constrained decisions and kernel-owned filesystem
> semantics.

The three axes are:

- Expressiveness: whether the mechanism can express dynamic path-view policy
  such as build precedence, fixture substitution, restore epochs, and cache
  state.
- Safety: whether extension logic expands the kernel trusted computing base,
  introduces daemon failure, or requires reimplementing permissions, cache
  behavior, dentry/inode ownership, readdir consistency, or lower-filesystem
  invariants.
- Efficiency: whether path resolution stays on a short kernel path and avoids
  excessive userspace crossings or materialization work.

The comparison structure should be:

- FUSE/userspace filesystems are expressive and avoid loading arbitrary
  filesystem logic into the kernel, but a daemon remains on the filesystem
  trusted path. Bugs, crashes, permission mistakes, cache incoherence, or
  incomplete POSIX behavior can affect correctness and security, and path
  operations can pay userspace costs.
- Custom in-kernel filesystems or kernel patches can be expressive and fast,
  but they put extension logic in the kernel TCB and are not a general,
  deployable extension point.
- Static/materialized mechanisms such as bind mounts, OverlayFS, projected
  volumes, symlink forests, copy trees, and materialized views preserve kernel
  filesystem semantics, but they are workload-specific baselines rather than
  the main conceptual opponent. They are often static or coarse-grained.

`namei_ext` is not a FUSE replacement. It can redirect into existing lower
filesystems, FUSE mounts, OverlayFS trees, cache directories, or materialized
views. Its contribution is the programmable name-resolution layer in front of
those backends.

## Required document updates

- Paper abstract and introduction: lead with the expressiveness/safety/efficiency
  tradeoff and the dynamic-path-view abstraction.
- Motivation: keep W1--W4 as examples of dynamic path-view policies, not as a
  baseline catalog.
- Design: state the ownership split: BPF owns bounded name-resolution decisions;
  the kernel and lower filesystems own VFS objects, permissions, caches, and
  data path.
- Evaluation: keep scoped results and negative evidence, but explain baselines
  in layers: conceptual comparisons, workload baselines, and optional
  diagnostics.
- Related work: compare against FUSE/userspace FS, custom in-kernel FS/kernel
  patches, and static/materialized view construction.
- Claim ledger/verdict/research plan: define C8 as a balanced dynamic-path-view
  abstraction claim, currently scoped out.

## Remaining risk

This story is stronger than the current positive evidence. The current paper
can claim scoped functional slices, W2 setup/materialization, tool-redirect
latency, and lookup/readdir consistency. It cannot yet claim that the balanced
abstraction is fully proven across all target workloads. C8 therefore remains
scoped out until real workload oracle and baseline comparison evidence support
it.
