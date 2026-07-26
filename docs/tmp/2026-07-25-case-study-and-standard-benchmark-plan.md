# 2026-07-25 Industrial Case-Study And Standard-Benchmark Plan

Date: 2026-07-25
Status: source-grounded evaluation plan; implementation is incomplete

## Objective

This research step reorganizes the evaluation around:

1. real source-system case studies for RQ1;
2. standard filesystem benchmarks and feature-equivalent FUSE for RQ2; and
3. workload-specific ownership accounting for RQ3.

It explicitly does not try to prove that tables, mounts, symlinks, or other
mechanisms cannot implement a workload. The claim under test is that one
bounded VFS name-resolution decision boundary can implement the path-view
subset of several real systems while the VFS and lower filesystem retain
filesystem semantics.

The paper-facing plan is in `docs/evaluation.md`. This record preserves the
source search, selection rationale, inspected code, rejected candidates, and
remaining risks.

## Admission Rule

An industrial workflow becomes a case study only if:

- an unmodified POSIX application consumes pathnames;
- runtime or workload state changes which existing object a path denotes, or
  whether the object is visible;
- the source behavior has an executable correctness oracle;
- the experiment can isolate a path-view subset without claiming ownership of
  synthetic contents, package solving, file transfer, COW writes, persistence,
  transactions, or application orchestration.

A case study is not the same thing as a performance benchmark. Every admitted
case gets an RQ1 correctness cell and an RQ3 scope/ownership row. RQ2 uses
standard benchmarks plus a smaller number of representative macro workloads
with feature-equivalent FUSE.

Cases are separated by the production workflow: user, operational objective,
trigger, source system, and correctness oracle. They are not separated or
merged by a shared `HIDE`, `SELECT`, epoch-switch, or remapping action.

## Admitted Industrial Workflows

| ID | Industrial workflow | Source systems | Reusable behavior | Candidate oracle | Excluded source behavior |
| --- | --- | --- | --- | --- | --- |
| W1 | Sandboxed Application File Sharing | xdg-desktop-portal Documents portal | Per-application grant/revoke; lookup/readdir exposes an existing host document or hides it | Two application identities, grant, open/stat/readdir, revoke, expected visibility and bytes | Synthetic document-ID hierarchy, UI, persistent permission store, mode synthesis |
| W2 | Agent Workspaces | AgentFS, BranchFS, YoloFS | Base/staged/hidden selection across workspace fork, staging, and rollback | Existing AgentFS-derived lifecycle trace, final-tree oracle, and concurrent branch isolation | COW copy-up, commit, conflict resolution, audit storage |
| W3 | Build Action Sandboxing | Bazel sandboxfs and action sandboxing | Per-action mappings from execroot paths to declared existing inputs; hide undeclared input | Real Bazel build/test, output hash, undeclared-input failure, concurrent action isolation | CAS transfer, remote execution, output upload, process sandboxing |
| W4 | Service Configuration and Secret Rotation | Kubernetes AtomicWriter, ConfigMap, ingress-nginx | Current/canary/rollback object selection after native validation | `nginx -t`, service response, bad-candidate rejection, rollback | Validation implementation, secret generation, reload orchestration, old-fd replacement |
| W5 | Checkpoint/Restore and Migration | DMTCP path-virtualization plugin | Remembered pre-checkpoint path selects the restored existing object | Checkpoint, moved root, restart, reopen, matching bytes/metadata, unmapped failure | Checkpoint image, descriptor restoration, distributed coordination, content transfer |
| W6 | HPC File Staging | LLNL Spindle | After the controller stages the same object locally, open/stat/exec selects it instead of the shared original | Spindle tests or Pynamic/MPI/Python launch, object hash/output, shared-FS request count, stale rejection | Distribution, cache population, library recognition, coherency protocol |
| W7 | Toolchain and Dependency Environments | Nix, Guix, Spack, venv, Conda, nvm, rbenv, Lmod, update-alternatives, CernVM-FS variant symlinks | A project/job environment selects an installed executable, library/dependency tree, or site-specific target | Two real environments; version/build/import output; concurrent isolation; switch and rollback | Solver, install/build, activation scripts, ABI compatibility |

All seven workflows remain in the portfolio. Similar source systems are merged
within one workflow, while similar pathname actions do not collapse different
production workflows:

| Potential confusion | Non-overlap boundary |
| --- | --- |
| W2 vs W5 | Agent Workspaces creates concurrent branches for agents; Checkpoint/Restore resumes a traditional application after restart or migration. |
| W3 vs W7 | Build Action Sandboxing restricts declared action inputs; Toolchain and Dependency Environments selects installed compilers, runtimes, and dependencies. |
| W6 vs W7 | HPC File Staging moves the same object to node-local storage; Toolchain and Dependency Environments selects a different software variant. |
| W4 vs W7 | Service Configuration and Secret Rotation publishes validated runtime configuration to a service; Toolchain and Dependency Environments configures software for a user, project, or job. |

## Toolchain And Software-View Findings

Toolchain and Dependency Environments is a formal breadth case study, not just
a list of examples:

- The Nix LISA'04 paper identifies simultaneous component variants as a
  deployment requirement. A user environment is a directory of symlinks to
  selected store objects; the current profile is another symlink to a
  generation, enabling atomic upgrade and rollback.
- Guix preserves the same store/profile model and adds transactional rollback
  and per-user profiles. Its 2013 paper also records the older GNU Hurd
  `stowfs`, a dynamic filesystem approach to profile views. `stowfs` is a
  related-work precedent, not a Linux workload.
- Spack's SC'15 paper establishes the production HPC need for many compiler,
  MPI, dependency, and build variants. Current Spack documentation defines an
  environment filesystem view as a linked `bin/lib/include` tree and permits
  symlink, hardlink, or copy materialization.
- Python venv and Conda create environment prefixes and change `PATH` plus
  other environment variables. nvm, rbenv, and Lmod similarly switch the
  executable and library search view. Debian update-alternatives switches a
  system-wide group of symlinks.
- CernVM-FS is a production FUSE filesystem for global HPC software
  distribution. Its "variant symlink" is direct evidence of policy inside
  filesystem pathname handling: the same software or certificate path is
  expanded to a target selected by client configuration at access time.

These sources prove a common path-view workload shape and supply real inputs
and oracles. They do not prove that the source mechanisms are wrong or that
eBPF is necessary.

## Strong New Traditional Case: HPC File Staging With LLNL Spindle

Spindle is a better W6 source than an abstract remote-cache example.

Official production documentation says Spindle is automatically enabled for
jobs on El Capitan and Tuolumne. It coordinates shared-library, executable,
Python, and selected data-file loading so one shared-filesystem read can be
distributed to node-local storage. The application then loads the local
object.

The public source was inspected at commit
`8853636d2d774729a5a728f5cf6c296b65a1099c`:

- `src/client/client/intercept_open.c` obtains a relocated pathname and calls
  the original `open`/`fopen` on that local path.
- `src/client/client/intercept_stat.c` interposes `stat` variants.
- `src/client/client/intercept_exec.c` and
  `src/client/client/intercept_readlink.c` cover additional pathname users.
- `src/client/client/should_intercept.c` chooses read-only libraries, Python
  files, and configured prefixes while leaving writes on the original path.
- launcher code injects `LD_AUDIT`/`LD_PRELOAD`; the source testsuite covers
  library, exec, Python, and interposition behavior.

This gives a clean mechanism split for `namei_ext`: retain Spindle's
distribution and cache control plane, but move only the final existing-object
selection out of loader/libc interposition and into VFS pathname resolution.
The experiment must not claim to replace Spindle's scalable broadcast or
cache.

## Similar Systems Considered

| System | Finding | Disposition |
| --- | --- | --- |
| Spack, Conda, Guix | Strengthen the same dependency/toolchain view family; they do not require separate paper case studies | Add as W7 sources and possible real workflow inputs |
| CernVM-FS variant symlinks | Direct FUSE implementation of configuration-dependent software/certificate path selection | Add to W7 source evidence and RQ2/RQ3 related work |
| GNU Hurd `stowfs` and translators | Prior dynamic filesystem approach for software profiles; broader userspace filesystem server model and not Linux | Cite as prior work, do not reproduce as a main baseline |
| systemd-sysext/systemd-confext | Dynamically merges read-only `/usr`, `/opt`, or `/etc` extension images with OverlayFS | Natural source/mechanism evidence for W4/W7; no separate case |
| NVIDIA Container Toolkit | OCI hooks inject devices and mounts before container start | Setup-time container composition; related motivation, not a runtime lookup case |
| glibc dynamic linker search | Application runtime selects shared objects through its own search rules | Explains why W7/Spindle often interpose at the loader; not a separate filesystem case |
| lakeFS/DVC | Versions object-store data through APIs and metadata services | No normal VFS pathname oracle; related work only |
| SELinux polyinstantiation | Static per-context private directory instances configured at login | Closest shipping Linux precedent for RQ3; citation/ownership comparison, not a new workload |

## Standard Performance Plan

### FxMark

FxMark is the primary standard VFS benchmark. The official repository was
inspected at commit `3f29552ce7ba6be24c4172e6e2c2c1f603209953`.
Relevant source operations are:

- `MRPL`: repeated `stat` on each worker's private multi-component path;
- `MRPM`: random `stat` in the generated branching path tree;
- `MRPH`: all workers `stat` the same path;
- `MRDL`: directory iteration on private directories;
- `MRDM`: directory iteration on a shared directory;
- `MWCL`: per-worker file creation, used as a control rather than an RQ1
  workload.

The paper should report operation throughput versus vCPU/thread count for:

1. stock kernel;
2. patched kernel with no attached policy;
3. attached `PASS`;
4. attached same-filesystem `SELECT`;
5. feature-equivalent FUSE.

The patched-but-unattached comparison is the kernel-admission result. Attached
`PASS` measures invocation cost. `SELECT` measures the intended mechanism.

### mdtest/IOR And Filebench

IOR/mdtest was inspected at commit
`5fcf0ba995fd92164d50e344597e2d8203298c08`. Selected metadata
create/stat/open/rename/remove operations provide standard breadth. Filebench
fileserver and webserver profiles provide a mixed macro control. Neither is a
case-study argument for RQ1.

### Mechanism-Specific Tests

The project benchmark remains responsible for behavior no standard suite
exposes:

- `PASS`, `HIDE`, same-filesystem `SELECT`, cross-filesystem `SELECT`;
- invalid/fail-closed decision behavior;
- `open`, `stat`, `access`, `exec`, multi-component walks, and `readdir`;
- p50/p95/p99 latency, cycles, instructions, branch misses;
- update-to-visible latency and stale observations after an acknowledged
  policy update.

## Planned Figures

1. **RQ1 industrial case-study matrix:** rows W1--W7; columns source oracle,
   `namei_ext`, FUSE, and out-of-bound behavior. Cells show pass/fail and
   operation-weighted action mix.
2. **RQ2 fast-path figure:** FxMark throughput normalized to stock Linux
   across vCPU counts for patched-unattached, attached `PASS`, `SELECT`, and
   FUSE.
3. **RQ2 latency figure:** p50/p95/p99 for lookup/open/stat/readdir by action,
   with CPU and context-switch accounting.
4. **RQ2 macro figure:** representative Agent, Bazel/Spindle, and service or
   toolchain runtimes for source behavior, `namei_ext`, and FUSE.
5. **RQ3 boundary table:** filesystem methods, daemon/lifetime, data/write
   path, metadata/persistence, cache/coherency, and invalid-policy containment
   for each source mechanism, FUSE, and `namei_ext`.

## Current Evidence

- W1 Sandboxed Application File Sharing passed its source-derived supporting
  preflight through the real KVM attach path. Two application cgroups exercised
  hidden-before-grant, visible-after-grant, cross-application isolation, and
  hidden-after-revoke behavior with an unchanged lower object and zero
  failures. Raw result:
  `results/experiments/application-file-sharing/20260725T-sandboxed-file-sharing-preflight-v3/`.
- W2 Agent Workspaces RQ1 correctness passed in three terminal KVM runs with
  1,176 records each and zero failures.
- W3 Build Action Sandboxing passed a real modified-kernel KVM preflight with
  two concurrent Bazel 6.5.0 genrules. They used the same logical path,
  selected distinct existing input roots, hid a physically present undeclared
  input from lookup and readdir, and produced distinct expected outputs. Raw
  result:
  `results/experiments/build-action-sandboxing/20260726T-build-action-sandboxing-preflight-v3/`.
- The existing ccache compile matrix has correct output hashes and reports
  observed FUSE/`namei_ext` ratios around 2.1--2.2x. It is retained as macro
  RQ2 evidence, not as the main motivation for W3 or W6.
- W4--W7 have source evidence but no completed `namei_ext` KVM correctness
  matrix.
- No paper-grade FxMark, mdtest, or Filebench result exists yet.
- No release-scale tail-latency result exists for the custom benchmark.

## Breadth-First Execution Order

Before deep optimization, run one hard-failing preflight for each industrial
workflow:

1. stock versus patched-unattached FxMark `MRPL`, `MRPM`, and `MRPH`;
2. W1 Sandboxed Application File Sharing with two identities and grant/revoke
   passed its first KVM preflight; a matched FUSE timing row remains open;
3. W3 Build Action Sandboxing with two concurrent real Bazel actions and an
   undeclared-input lookup/readdir probe passed its RQ1 preflight; matched
   symlink-forest/FUSE cost remains open;
4. W4 Service Configuration and Secret Rotation with valid/bad/rollback nginx
   configurations;
5. W5 Checkpoint/Restore and Migration with one DMTCP moved-root reopen;
6. W6 HPC File Staging with a Spindle serial or local-MPI library/Python launch
   after
   cross-filesystem `SELECT` preflight;
7. W7 Toolchain and Dependency Environments with two Spack/Nix/Python
   environments, concurrent selection, and rollback.

Each preflight must use the real KVM `cgroup/namei_ext` attach path. A source
oracle failure, unsupported action, BPF load/attach failure, or lower-FS
semantic mismatch fails the cell. After all cells have a disposition, deepen
the strongest representative cases and run the full standard RQ2 matrix.

## Validation Performed

- Verified the four downloaded PDFs are valid PDF files and recorded their
  SHA-256 hashes in `docs/reference/INDEX.md`.
- Inspected the checked-out FxMark, IOR/mdtest, and Spindle source at the
  commits recorded above.
- Checked Spindle's official production documentation, current public
  repository, path-interposition source, and testsuite structure.
- Checked official Nix, Guix, Spack, Python, Conda, Lmod,
  update-alternatives, CernVM-FS, XDG portal, Bazel, Kubernetes, DMTCP,
  systemd-sysext/confext, and Linux FS-Cache documentation.
- Built `application_file_sharing.bpf.c` and its dedicated userspace runner
  without compiler warnings.
- Ran
  `make kvm-application-file-sharing-preflight
  RUN_ID=20260725T-sandboxed-file-sharing-preflight-v3`.
  All lifecycle cases and BPF counter gates passed with zero failures; dmesg
  contained no warning, oops, or sanitizer signature. The scoped `v2` run also
  verified that an unrelated path with the same component name passed through
  unchanged.

## Remaining Risks

- W1 intentionally covers only registered existing objects. Synthetic
  document IDs, mode synthesis, persistent permissions, and portal UI remain
  outside the tested boundary. Its matched project FUSE timing row is open.
- W3 needs a current Bazel integration path because sandboxfs is archived.
  The source action oracle is still valid, but harness glue must not be
  described as official sandboxfs reproduction.
- W5 may remain too narrow or operationally weak for the main paper.
- W6 requires cross-filesystem target selection and a clean boundary between
  Spindle's cache controller and `namei_ext`.
- W7 can collapse into a trivial executable switch unless it runs a real
  package-manager/environment workflow with executable and library/import
  checks.
- FxMark is old and its source descriptions are not perfectly consistent with
  every implementation constant. The experiment should report the exact
  checked-out commit and source operation, not rely only on benchmark labels.
