# Build Action Sandboxing Experiment Plan

Date: 2026-07-26

## Question

Can the current `namei_ext` prototype provide two concurrent Bazel actions
with different declared-input views at the same logical pathname, hide an
undeclared existing input, and leave the lower filesystem responsible for the
objects and data path?

This is a W3 Build Action Sandboxing RQ1 preflight. It is a correctness and
concurrency-isolation experiment, not an RQ2 performance comparison.

## Source Behavior

Bazel's official sandboxing documentation says that an action should see only
its known inputs and that undeclared inputs can cause incorrect incremental
builds and remote-cache behavior:

- <https://bazel.build/docs/sandboxing>

The archived sandboxfs implementation represents a stronger source-system
precedent for constructing action-specific views from many mappings without
building a symlink forest:

- <https://github.com/bazelbuild/sandboxfs>
- <https://blog.bazel.build/2017/08/25/introducing-sandboxfs.html>

The experiment uses the official Bazel 6.5.0 Linux x86-64 LTS release binary,
pinned by the upstream SHA-256 file. Bazel 6.5.0 keeps the basic native
`genrule` path self-contained, so the KVM run does not fetch rule sets from the
network:

- <https://github.com/bazelbuild/bazel/releases/tag/6.5.0>
- expected SHA-256:
  `a40ac69263440761199fcb8da47ad4e3f328cbe79ffbf4ecc14e5ba252857307`

This is source-derived behavior, not a claim that `namei_ext` reproduces
Bazel's process sandbox, remote execution, CAS transfer, or full sandboxfs.

## Hypothesis

A bounded policy on VFS lookup and directory enumeration can implement the
existing-object portion of a Bazel action view:

1. action A and action B use the same logical action-root pathname;
2. the action identity selects A's or B's registered existing input root;
3. `private.txt` physically exists in both lower roots but is hidden from the
   action through both lookup and directory enumeration;
4. each real Bazel action produces output from only its declared input;
5. lower input files and metadata remain unchanged.

## Fixture And Real Path

The KVM runner creates:

```text
view/action/                 shared logical pathname
target-a/input.txt           declared bytes for action A
target-a/private.txt         physically present undeclared input
target-b/input.txt           declared bytes for action B
target-b/private.txt         physically present undeclared input
workspace-a/BUILD.bazel      real Bazel genrule
workspace-b/BUILD.bazel      real Bazel genrule
```

Each Bazel process is placed in a distinct cgroup. Its genrule inherits that
identity. Both genrules publish a ready marker and wait for a shared release
marker, so the runner verifies that both action processes overlap before
allowing pathname access.

The policy is loaded and attached through the modified kernel's real
`cgroup/namei_ext` path. The target directories are registered through the
kernel target registry. No host-only result counts as this preflight.

## Correctness Oracle

The run is valid only if all of the following pass:

- Bazel 6.5.0 starts from the pinned binary;
- both genrules reach the action barrier concurrently;
- both Bazel builds exit successfully;
- action A's output equals `declared-input-A`;
- action B's output equals `declared-input-B`;
- `test ! -e private.txt` succeeds in each action;
- directory enumeration returns no `private.txt`;
- policy counters record lookup, readdir, select, lookup-hide, and
  readdir-hide actions;
- lower declared and undeclared files retain their inode-backed metadata and
  contents;
- the policy detaches and both target registries clear;
- guest dmesg contains no declared kernel failure signature.

Any missing capability, Bazel failure, timeout, false oracle record, absent
counter, cleanup failure, or kernel signature fails the Make target.

## Artifacts

The canonical target is:

```text
make kvm-build-action-sandboxing-preflight RUN_ID=<id>
```

Raw artifacts are preserved under:

```text
results/experiments/build-action-sandboxing/<id>/
```

The result root must include JSONL case records, per-action stdout/stderr,
output files and hashes, source and binary hashes, Bazel version, command,
kernel identity/configuration, and dmesg.

## Interpretation Boundary

A pass supports the narrow claim that the current mechanism can express this
source-derived concurrent action-view transition with real Bazel actions. It
does not establish:

- a complete Bazel sandbox replacement;
- process, network, syscall, or write isolation;
- remote execution or cache correctness;
- performance relative to sandboxfs, symlink forests, or FUSE;
- acceptable VFS fast-path overhead.

Those require separate integrated experiments with their natural baselines.
