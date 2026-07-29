# Spindle HPC Staging Experiment Implementation

## Purpose

This step implements the frozen Spindle source-derived RQ1 case study. It asks
whether `namei_ext` can perform the final existing-file selection step for a
real Spindle-populated node-local cache while Spindle retains cache population
and distribution ownership.

The implementation does not reproduce Spindle performance, replace Spindle,
implement a new loader test, or compare against FUSE. The source system is the
positive control and a withdrawn target is the causal control.

## Source And Build

- Upstream: LLNL Spindle
- Commit: `8853636d2d774729a5a728f5cf6c296b65a1099c`
- Build: serial resource manager, null security, dedicated cache and
  communication roots
- Upstream workload:
  `test_driver --dlopen --pull --nompi`
- Focal inventory: 47 regular-file DSO payloads selected by the upstream
  loader test

`configs/benchmarks/workload-sources.mk` pins the source. `mk/workload.mk`
owns download, archive-structure checks, extraction, configure, compile,
install, source identity, and the source-only engagement check. The current
source check completed with empty stderr and produced first-party staging
records; the KVM adapter performs the exact 47-object match.

## Implemented Components

`bpf/policies/spindle_staging.bpf.c` contains one
`cgroup/namei_ext` decision function. Lookup keys include cgroup identity,
parent identity, and exact basename. A bounded hash map selects registered
targets; other events and unmatched lookups pass. Aggregate and per-target
counters are raw observations.

`experiments/spindle_staging/namei_ext_spindle_staging.c` is the userspace
adapter. It:

1. creates dedicated tmpfs cache, communication, and temporary roots;
2. runs the installed upstream Spindle command as an unprivileged user;
3. parses only first-party `spindlens-file` mapping records;
4. requires one valid tmpfs cache object for each of the 47 focal source
   objects and checks distinct identity, size, and direct byte equality;
5. covers source `libtest10.so` with an empty read-only bind mount;
6. registers the 47 existing Spindle objects and attaches the real
   `cgroup/namei_ext` policy;
7. runs the unchanged upstream ELF without Spindle or loader interposition;
8. checks application-only per-target and aggregate selection deltas;
9. checks logical-path device, inode, mode, and size against each
   registered cache object;
10. checks that lower-file `000` mode causes unprivileged `EACCES`;
11. withdraws only the `libtest10.so` rule and requires the same command to
    fail with the upstream missing-library diagnostic; and
12. restores the covering mount, verifies source/cache preservation, detaches
    policy state, removes the cgroup, and unmounts all tmpfs roots.

The shared harness file-registration API now accepts either a regular file or
directory through `O_PATH`. Existing directory-based experiments still call
the same function and were rebuilt after the change.

`mk/experiments/spindle_staging.mk` owns artifact capture, fresh-boot KVM
execution, guest validation, raw result collection, and analysis.
The runner, policy, and bpftool execute from the packaged artifact tree. Each
boot extracts the complete Spindle build and prefix into a boot-local
runtime tree. Because upstream embeds build/prefix absolute paths, the guest
bind-mounts that tree over the exact compile-time root. It gates the mount
source/target identity, actual private-library `ldd` resolutions, and compiled
helper paths. Required fixtures are compared byte-for-byte with their upstream
source, symlink targets are recorded, and the bind mount is removed before the
guest finishes.

## Raw Evidence Contract

Each boot records:

- actual source, `namei_ext`, and withdrawn argv/environment arrays;
- resolved executable, test ELF, and working-directory paths;
- UID/GID and `env -i` status;
- ELF type, program headers, dynamic section, and `ldd` output;
- every source/cache path, device, inode, size, mode, and direct comparison
  result;
- every target's selection counter before, after, and delta;
- aggregate SELECT before, after, delta, and per-target sum;
- actual and expected identity fields for all 47 logical probes;
- permission-probe errno and mode restoration;
- withdrawn-target counter window and diagnostic result;
- before/after source/cache metadata inventories;
- complete Spindle cache tree and first-party debug logs;
- BPF/FUSE inventories, cgroup/tmpfs cleanup, kernel identity/config, and
  dmesg.

The finalizer recomputes the counter, mapping, identity, permission,
preservation, and withdrawal relations from raw fields. It also normalizes and
directly compares the complete before/after metadata inventories.

## Execution Defects Found Before The Remaining Preflight

Read-only reviews and the first two KVM attempts found concrete execution
defects before a valid workload result existed:

- The adapter initially discarded raw counter and identity relations. It now
  records those fields and the finalizer recomputes them.
- Spindle and `test_driver` embed absolute build and prefix paths. The complete
  build/prefix tree is now bind-mounted over the compile-time root, and actual
  private-library and helper resolutions are checked.
- Guest setup could bypass cleanup or mask an inventory failure. Preparation,
  workload, cleanup, after-inventory, and dmesg capture now have separate
  statuses that the finalizer checks.
- The first KVM attempt exposed a bad artifact path. The obsolete check was
  removed.
- The second KVM attempt exposed missing upstream readlink fixtures and a
  launcher that masked the child diagnostic. The fixtures are reconstructed
  from upstream source, and the adapter now requires both process success and
  empty stderr.

These corrections preserve the source command, 47 focal objects, BPF policy,
and acceptance oracle.

## Validation Performed

- `make -j4 spindle-staging bpf`: passed with GCC and the project BPF build
- separate Clang build of the adapter: passed
- Clang static analyzer: no adapter diagnostic
- `make result-contract`: passed all infrastructure and analysis tests
- top-level Make database parse: passed
- guest and finalizer recipe expansion with all required variables: passed
- `git diff --check`: passed
- existing Spindle source check: official command exit zero, 66 total
  first-party file mappings, exactly 47 focal mappings

The host checks above pass. The two KVM attempts below failed during experiment
setup and therefore supply no RQ1 workload result.

## Remaining Gate And Risks

The immediate gate is one fresh modified-kernel KVM preflight from the
corrected committed source state. It must establish the source condition, all
47 cache mappings, the real `cgroup/namei_ext` condition, the withdrawn causal
control, preservation, and cleanup in one boot.

Three formal fresh boots are permitted only after the preflight raw root
passes independent review. Until then, this experiment contributes no paper
result.

## First KVM Preflight Attempt

The first real preflight used result root
`results/experiments/spindle-staging-preflight/20260729T142246Z-spindle01/`.
The intended modified kernel booted, preparation succeeded, and the structured
failure wrapper completed cleanup, after-inventory, dmesg capture, and host
evidence capture. The inner target failed before mounting the packaged runtime
tree or executing any workload condition: it passed a repository-relative
runtime manifest path to `sha256sum` after changing into the packaged runtime
directory.

This is a packaging-path defect and supplies no workload result. The detailed
identity, status, diagnostic, and narrowly scoped fix are
recorded in
`docs/tmp/2026-07-29-spindle-hpc-staging-preflight-attempt-1.md`. The guest
Makefile continues to store paths relative to the repository root. The
checksum path that caused this failure has since been removed rather than
repaired or retained as an experiment gate.

## Second KVM Preflight Attempt

The second preflight used result root
`results/experiments/spindle-staging-preflight/20260729T143220Z-spindle02/`.
It passed the corrected runtime-manifest path and entered the real source
Spindle condition. The upstream test then diagnosed
`readlink(hello_.py) expected error 22. Got error 2`: the archive had omitted
that write-only fixture, so a regular-file `EINVAL` became `ENOENT`. The
source execution was invalid despite the Spindle launcher returning zero. No
BPF condition ran.

The original adapter did not inspect stderr and did not preserve the runner
error that actually controlled `pass=false`; the earlier attribution to an
adapter stderr gate was incorrect. The stderr log independently proves the
upstream source test failed. A later dry-run command also rewrote five files
in this result root, so the root is contaminated and must not be reused.

The detailed source control flow and correction are recorded in
`docs/tmp/2026-07-29-spindle-hpc-staging-preflight-attempt-2.md`. The archive
now reconstructs the two upstream `hello.py` readlink fixtures from the exact
source bytes, applies their original modes only during the workload window,
and restores readable transport modes on every guest exit path. The two
`retzero` exec fixtures remain excluded because `--nompi` skips their suite.
The adapter now records `runner_errno` explicitly and requires empty stderr
for both successful conditions. Source/cache equality uses direct byte
comparison, and checksum manifests and checksum gates have been removed from
the Spindle build and experiment paths.

The corrected host source check completed with empty stderr, and the
Make-owned packaging preflight directly compared both reconstructed fixtures
with upstream `hello.py`. These checks are dependencies for the remaining
real KVM preflight, not paper results.

## Third KVM Preflight Attempt

The third preflight used result root
`results/experiments/spindle-staging-preflight/20260729T164002Z-spindle03/`.
The source Spindle command returned zero with empty stderr, but the wrapper
reported `EBUSY` because its process group still existed ten seconds after the
leader exited. The run stopped before mapping collection or BPF attachment.

The raw source log shows the loader workload completed and Spindle began
shutdown. The added process-group disappearance rule is not Spindle's source
oracle and can remain false for zombies. This is a wrapper completion defect,
not an RQ1 result. The exact evidence is recorded in
`docs/tmp/2026-07-29-spindle-hpc-staging-preflight-attempt-3.md`.

The three-attempt preflight is closed. No fourth Spindle run is started, and
W6 remains without KVM workload evidence.
