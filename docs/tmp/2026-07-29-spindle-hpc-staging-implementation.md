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
- Archive SHA-256:
  `a287fd3a30603f595c753324dc486360f335b536d623af7cbe62bb5025cb95b2`
- Build: serial resource manager, null security, dedicated cache and
  communication roots
- Upstream workload:
  `test_driver --dlopen --pull --nompi`
- Focal inventory: 47 regular-file DSO payloads selected by the upstream
  loader test

`configs/benchmarks/workload-sources.mk` pins the source. `mk/workload.mk`
owns download, hash verification, extraction, configure, compile, install,
provenance, and the source-only engagement check. The source check completed
successfully before KVM implementation and preserved 66 first-party file-cache
mappings, exactly 47 of which match the frozen focal inventory.

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
   objects and checks distinct identity, size, and SHA-256;
5. covers source `libtest10.so` with an empty read-only bind mount;
6. registers the 47 existing Spindle objects and attaches the real
   `cgroup/namei_ext` policy;
7. runs the unchanged upstream ELF without Spindle or loader interposition;
8. checks application-only per-target and aggregate selection deltas;
9. checks logical-path device, inode, mode, size, and hash against each
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
execution, guest validation, raw result collection, sealing, and analysis.
The runner, policy, and bpftool execute from the sealed artifact tree. Each
boot extracts the sealed complete Spindle build and prefix into a boot-local
runtime tree. Because upstream embeds build/prefix absolute paths, the guest
bind-mounts that tree over the exact compile-time root. It gates the mount
source/target identity, actual private-library `ldd` resolutions, and compiled
helper paths. Complete regular-file hashes and symlink targets are validated
before and after execution, and the bind mount is removed before the guest
finishes.

## Raw Evidence Contract

Each boot records:

- actual source, `namei_ext`, and withdrawn argv/environment arrays;
- resolved executable, test ELF, and working-directory paths;
- UID/GID and `env -i` status;
- ELF type, program headers, dynamic section, and `ldd` output;
- every source/cache path, device, inode, size, mode, and SHA-256;
- every target's selection counter before, after, and delta;
- aggregate SELECT before, after, delta, and per-target sum;
- actual and expected identity/hash fields for all 47 logical probes;
- permission-probe errno and mode restoration;
- withdrawn-target counter window and diagnostic result;
- before/after source/cache manifests;
- complete Spindle cache tree and first-party debug logs;
- BPF/FUSE inventories, cgroup/tmpfs cleanup, kernel identity/config, and
  dmesg.

The finalizer recomputes the counter, identity, permission, and withdrawal
relations from these raw fields. It does not accept an adapter-provided
boolean without checking the underlying values.

## Independent Implementation Review

The first read-only implementation review returned `NO-GO` before any KVM
result root was created. It found no correctness defect in the source
positive control, exact 47-object policy, application-only counter window, or
withdrawn causal control. It identified four evidence/protocol defects:

1. raw before/after counters and identity values were discarded;
2. sealed artifact copies were not the paths executed in the guest;
3. the plan's four-way terminal wording conflicted with repository fail-fast
   behavior; and
4. exact argv/environment and ELF runtime metadata were absent.

The implementation now records and revalidates the raw values, executes
sealed or hash-chained artifacts, records the runtime contract, and documents
fail-fast preflight/formal semantics. The second review found that upstream
Spindle and `test_driver` embed absolute build/prefix paths, so merely
extracting prefix/testsuite copies did not prevent fallback to unsealed
`.build` libraries and helpers. The runtime artifact was expanded to the
complete build/prefix tree and is bind-mounted over its compile-time root;
actual private-library and helper resolutions are now gates. The same review
also found and prompted a fix for raw counter-delta underflow on a failed
monotonicity check.

The third review found four execution blockers before KVM: the shared
`guest.mk` contract rejects absolute repository paths, four upstream
permission fixtures are intentionally unreadable, `mountpoint` returns a
nonzero code not fixed to one, and failure roots were not sealed after
launcher exit. Guest configuration now stores repository-relative paths and
reconstructs the compile-time root in the Make recipe. The four non-focal
permission fixtures are metadata-sealed and excluded. Mount checks accept any
nonzero not-mounted status. An outer guest target always performs recursive
mount cleanup and writes terminal status evidence, while the host always
seals the boot directory after launcher exit before propagating failure.

A fourth independent implementation review is required before the first real
KVM preflight.

The fourth review found that Bash disables `errexit` inside a compound command
used on the left side of `||`, so an early after-inventory failure could be
masked by a later successful check. It also noted that a Make prerequisite
failure could occur before the outer cleanup recipe started. After-inventory
is now an independent recursive Make target whose recipe lines fail normally.
Guest filesystem preparation is also a status-captured recursive Make call
inside the outer recipe. Both statuses are written separately and recomputed
by the finalizer.

A fifth independent implementation review is required before the first real
KVM preflight.

The fifth read-only review returned `GO for first real KVM preflight`. It
verified that after-inventory failures propagate through the independent
recursive Make target, prepare failures still reach structured cleanup and
boot status, host sealing occurs after launcher exit, and the success
finalizer checks all five status channels and pre/post mount state. This is an
implementation-readiness verdict, not a workload result.

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

No Spindle KVM preflight or formal boot has been run as part of this
implementation record.

## Remaining Gate And Risks

The immediate gate is to commit and push the reviewed source state, then run
exactly one fresh modified-kernel KVM preflight. The preflight may still expose guest
dependency, loader `$ORIGIN`, cgroup cleanup, artifact-path, or final-file
selection behavior that cannot be established by host builds.

Three formal fresh boots are permitted only after the preflight raw root
passes independent review. Until then, this experiment contributes no paper
result.
