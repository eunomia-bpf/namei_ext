# Spindle HPC File-Staging Experiment Plan

## Status And Revision

Revision 4 records a source-input packaging correction found by the second KVM
preflight. It does not change the source command, focal objects, policy,
hypothesis, or acceptance rule.

Revision 1 proposed copying the complete Spindle testsuite to tmpfs and
selecting that copied directory. Review rejected it because the copy was not
Spindle's cache, `--nompi` does not print `PASSED.`, the executable environment
was incomplete, and the formal execution contract was underspecified.

Revision 2 instead consumes the exact cache files produced by an unmodified
Spindle source run. It narrows the focal source oracle to the loader behavior
actually executed by `test_driver --dlopen --nompi` and uses exit status, not a
nonexistent terminal message, as the test result.

Revision 3 follows the second review. Kernel commit `621aff8d1bb5` and complete
Phase 1 root `results/phase1/20260729T220000Z-f1e5e1e1/` now supply the
previously missing final regular-file action: 117/117 functional cases passed
on the modified kernel. This revision also freezes the absolute build/prefix
layout, clean execution environment, exact source and application commands,
and all 47 distinct regular-file payloads exercised by the selected loader
slice.

Revision 4 follows result root
`20260729T143220Z-spindle02`. Contrary to Revision 3's fixture note,
`--nompi` still executes `run_readlinks()` and requires `hello_.py` to exist.
The packaged runtime now reconstructs `hello_.py` and the upstream
`hello_x.py` companion from the exact checked-in `hello.py` bytes used by the
upstream Makefile, applies the upstream modes during the workload window,
records their metadata before and after the conditions, and restores readable
transport modes during cleanup.

## Research Question And Role

This experiment tests RQ1:

> Can a narrow VFS name-resolution extension express real state-dependent
> path-view policies without taking over filesystem semantics?

Its role is supporting but consequential RQ1 breadth. It adds a traditional
HPC workflow whose production objective, source implementation, source-native
testsuite, and shared-to-local pathname behavior differ from the completed
application-sharing, Agent-workspace, and Bazel-action cases.

The experiment does not test whether a table is sufficient. It does not claim
that `namei_ext` distributes files, recognizes libraries, populates a cache,
or replaces Spindle.

## Paper-Value Admission

LLNL Spindle addresses a production problem: large jobs repeatedly search and
load libraries, executables, Python modules, and selected data from a shared
filesystem. Spindle designates readers, distributes bytes, stores objects on
node-local storage, and directs applications to those objects. LLNL documents
Spindle as automatically enabled on El Capitan and Tuolumne.

The paper already has deep Agent-workspace and VFS microbenchmark evidence. It
does not have a completed traditional case in which an unmodified dynamic
loader consumes source-system-populated objects on another filesystem. A
positive result would show that Spindle's final existing-object selection step
fits the `namei_ext` boundary while Spindle retains cache population. A
contradictory result would bound cross-filesystem target selection, loader
compatibility, or the claimed existing-object boundary. It would not falsify
unrelated workloads.

This has higher expected paper value than Toolchain and Dependency
Environments as the next case. Nix, Guix, and Spack primarily construct or
activate materialized profile trees. Spindle directly implements the
lookup-facing shared-to-local relocation and publishes a loader test.

## Frozen Source

- Repository: `https://github.com/LLNL/Spindle`
- Commit: `8853636d2d774729a5a728f5cf6c296b65a1099c`
- Archive:
  `https://codeload.github.com/LLNL/Spindle/tar.gz/8853636d2d774729a5a728f5cf6c296b65a1099c`
- License files: `COPYRIGHT` and `LGPL`
- Source-native application: upstream `testsuite/test_driver.c`, built only
  through the upstream build system
- Focal application: generated upstream ELF `test_driver`
- Identical application arguments in all three conditions:
  `--dlopen --pull --nompi`
- Source mechanism: official `spindle` executable, serial launcher, pull mode
- Guest-only security mode: null security in one isolated KVM guest

The project Makefile computes and records these absolute paths:

```text
SOURCE_ROOT = $(abspath .cache/workloads/spindle/8853636d2d774729/source)
BUILD_ROOT = $(abspath .build/workloads/spindle/8853636d2d774729/build)
PREFIX = $(abspath .build/workloads/spindle/8853636d2d774729/prefix)
TEST_DIR = $(BUILD_ROOT)/testsuite
SPINDLE_BIN = $(PREFIX)/bin/spindle
CACHE_ROOT = /tmp/namei-ext-spindle-cache
COMM_ROOT = /tmp/namei-ext-spindle-comm
TMP_ROOT = /tmp/namei-ext-spindle-tmp
```

Each path is resolved with `realpath` after creation and emitted in the raw
metadata. `SOURCE_ROOT` is reconstructed from the pinned archive, not used
from the exploratory checkout.

The build follows Spindle's current serial-container configuration except that
null security replaces a guest munge daemon:

```text
SOURCE_ROOT/configure --prefix=PREFIX \
  --enable-sec-none --with-rm=serial --with-testrm=serial \
  --with-cachepaths=CACHE_ROOT --with-commpath=COMM_ROOT \
  CFLAGS="-O2 -g" CXXFLAGS="-O2 -g"
```

The null-security choice affects connection authentication, not loader,
staging, cache-path, or application semantics. It is recorded as an isolated
guest deviation.

The official upstream pull row is `./run_driver --dlopen --pull`.
`run_driver_template` changes to `TEST_DIR`, sets `SPINDLE_TEST=1`, appends
`TEST_DIR` to `LD_LIBRARY_PATH` and `PATH`, selects `test_driver`, and asks
`run_driver_serial` to execute:

```text
PREFIX/bin/spindle --level=high --pull --launcher=serial \
  TEST_DIR/test_driver --dlopen --pull
```

The experiment invokes that same installed Spindle binary, generated test ELF,
pull mode, launcher, working directory, and test arguments directly.
It adds only `--noclean=yes` and `--strip=no` to preserve byte-identical cache
objects for observation, and `--nompi` to isolate the upstream loader slice
whose exit status is the frozen oracle. Direct invocation is necessary because
the generated `run_driver` overwrites `SPINDLE_FLAGS` and exposes neither
observation flag.

## Focal Source Oracle

The exact source-derived slice is dynamic-library loading, not the complete
Spindle testsuite:

- generated DSOs are opened through the absolute `LPATH` compiled by upstream;
- constructors, exported functions, dependency chains, symbol tables, TLS,
  C++ exceptions, `$ORIGIN`, missing-library behavior, readlink fixtures, and
  alias paths are checked by the unmodified test binary;
- `--nompi` deliberately excludes upstream exec and stat suites;
- successful `--nompi` execution returns zero but prints neither `PASSED.` nor
  `FAILED.`;
- Spindle's private-path leak diagnostic is not part of the `namei_ext`
  claim. In the no-Spindle conditions,
  `LDCS_CHOSEN_PARSED_CACHEPATH=/__namei_ext_no_spindle_cache__` lets the
  unchanged binary execute that diagnostic without pretending the Spindle
  client is present.

The source Spindle condition and the `namei_ext` condition use the same
upstream test ELF, arguments, working directory, user ID, source tree, generated
libraries, and base environment. The only intentional environment difference
is the source Spindle runtime and its injected `LD_AUDIT`/`LDCS_*` state versus
the attached `namei_ext` policy and one inert cache-path string required by the
upstream leak check.

## Hypothesis

After source Spindle has populated a node-local tmpfs cache, `namei_ext` can
make the same source pathname lookups select those exact cached DSOs. The
unmodified `test_driver --dlopen --nompi` command should return zero without a
Spindle daemon or client. If the required source object is unavailable and its
target mapping is withdrawn, the same command should fail.

The expected result is:

1. source Spindle returns zero and produces mandatory global-to-local mapping
   evidence for the focal testsuite DSOs;
2. every mapped local payload is a Spindle-created tmpfs object whose bytes
   match its source object under `--strip=no`;
3. `namei_ext` returns zero while selecting those same cache objects through
   the original source paths;
4. every required focal object records at least one selection hit;
5. withdrawing the `libtest10.so` target while its source implementation is
   covered makes the identical command fail;
6. source bytes and metadata and cached payload bytes remain unchanged.

The result contradicts the expectation if the source condition and cache
evidence pass but the `namei_ext` condition cannot load the valid cache
objects, selects a different object, changes test output, bypasses lower
permissions, or mutates source or cached payloads.

## Required Focal Objects

The source run must produce valid `spindlens-file` mappings for all 47 distinct
regular-file payloads exercised by the upstream `--dlopen` dependency graph:

```text
libtest10.so libtest11.so libtest12.so libtest13.so libtest14.so
libtest15.so libtest16.so libtest17.so libtest18.so libtest19.so
libtest20.so libtest50.so libtest100.so libtest500.so libtest1000.so
libtest2000.so libtest4000.so libtest6000.so libtest8000.so
libtest10000.so
libdepA.so libdepB.so libdepC.so
libcxxexceptA.so libcxxexceptB.so
liboriginlib.so liborigintarget.so
libtls1.so libtls2.so libtls3.so libtls4.so libtls5.so
libtls6.so libtls7.so libtls8.so libtls9.so libtls10.so
libtls11.so libtls12.so libtls13.so libtls14.so libtls15.so
libtls16.so libtls17.so libtls18.so libtls19.so libtls20.so
```

The inventory is derived from `testsuite/test_driver.c` and
`testsuite/Makefile.am`. The 20 TLS objects are mandatory because
`checkTlsSum()` explicitly calls `dlopen()` for each one and requires the sum
210. The dependency loader pulls `libdepB.so`, `libdepC.so`,
`libcxxexceptB.so`, and `liborigintarget.so` through the declared dependency
and `$ORIGIN` chains.

`libsymlink.so` is a symlink fixture whose referent is the already counted
`libtest10.so`; it must pass the upstream dlopen and readlink checks but is not
a second regular payload. `liblocal.so` is copied, modified, and loaded from
`TMP_ROOT` by the test itself. `libnoexist.so` and `libnosuchlib.so` are
negative fixtures. `libtestoutput`, `libfuncdict`, `libspindle`, the test ELF,
the shell, and system libraries are startup/runtime
dependencies and remain ordinary source or system lookups. Scripts, alias
files, and readlink fixtures also remain ordinary source lookups. None may be
counted toward the 47 selection groups.

## Frozen Base Environment

The adapter changes directory to `TEST_DIR`, drops to the recorded
unprivileged result-root owner, and executes through `env -i`. Every condition
uses:

```text
HOME=<recorded run-user home>
USER=<recorded run user>
LOGNAME=<recorded run user>
SHELL=/bin/sh
PATH=/usr/bin:/bin:TEST_DIR
LD_LIBRARY_PATH=TEST_DIR
SPINDLE_TEST=1
SPINDLE_DEBUG=3
TMPDIR=TMP_ROOT
LC_ALL=C
LANG=C
TZ=UTC
```

The generated ELF's exact path, ELF type, dependencies, and RUNPATH are
recorded. Before each command, `LD_PRELOAD`, `LD_AUDIT`,
`SPINDLE_LD_PRELOAD`, `SPINDLE_FLAGS`, `SPINDLE_OPTS`, `LIBRARY_LIST`,
`TEST_EXEC`, `SPINDLE_DEBUG_SOCKET`, and all `LDCS_*` variables are absent.
Source Spindle may then inject its documented client variables. The
`namei_ext` and withdrawn conditions add only
`LDCS_CHOSEN_PARSED_CACHEPATH=/__namei_ext_no_spindle_cache__` so the unchanged
upstream leak checker has a non-cache sentinel to inspect.

## Conditions

One fresh modified-kernel KVM boot executes all three conditions. The order is
fixed because source Spindle must populate the cache before `namei_ext`
consumes it.

### 1. Source Spindle Positive Control

Run as the unprivileged result-root owner from `TEST_DIR`:

```text
SPINDLE_BIN --level=high --launcher=serial --pull \
  --noclean=yes --strip=no TEST_DIR/test_driver \
  --dlopen --pull --nompi
```

The configured cache and communication roots are dedicated tmpfs directories.
Require launcher exit status zero, successful process-group cleanup, and an
empty upstream stderr stream. Spindle's serial launcher can mask the child
`test_driver` status, so exit status alone is not the source oracle. Preserve
stdout, stderr, all Spindle debug logs, and the complete cache inventory.

This is a source-system positive control, not a performance baseline.

Source engagement is a hard gate. From Spindle's own level-3
`Adding <local>, <global>, index=<n>` records emitted by
`add_global_name`, reconstruct every global source path and generated local
`*-spindlens-file-*` path for the 47 required objects. Spindle selects
the `file` cache class when `--strip=no`; a `spindlens-dso` filename would
instead show that stripping remained enabled and invalidates this run. For
every pair:

- both paths exist after Spindle exits with `--noclean=yes`;
- the local path lies below the declared tmpfs cache root;
- the local file has a different device/inode identity from the source file;
- a direct byte-for-byte comparison succeeds because `--strip=no`;
- the global path, local path, basename, mode, owner, size, device, inode,
  and mtime are recorded; and
- there is exactly one accepted mapping for that required original object.

Missing, ambiguous, non-tmpfs, mismatched, or fallback-only cache evidence
invalidates the run before the `namei_ext` condition.

### 2. `namei_ext`

Use the source Spindle mapping records as input; do not copy or rename any DSO.
For each accepted global path, register the existing Spindle cache file as a
`namei_ext` target and install a component rule keyed by cgroup, parent
device/inode, and basename. Install the corresponding cache-parent alias when
selection changes `$ORIGIN` for a dependent lookup. The BPF program exposes
one decision function and one bounded component-to-target map, plus per-rule
and aggregate counters.

The application runs as the same unprivileged user in a dedicated cgroup:

```text
LDCS_CHOSEN_PARSED_CACHEPATH=/__namei_ext_no_spindle_cache__ \
TEST_DIR/test_driver --dlopen --pull --nompi
```

`LD_AUDIT`, `LD_PRELOAD`, and connection-oriented `LDCS_*` variables must be
absent. No Spindle process may remain. The working directory is the upstream
testsuite so readlink and alias fixtures retain their source semantics.

Require:

- exit status zero;
- all 47 focal-object groups record at least one lookup selection;
- aggregate `SELECT_TARGET` count is positive and equals the sum of per-rule
  hits;
- an in-cgroup `stat`/`open` identity probe for every logical focal path
  observes the same device/inode, size, and mode as the registered
  physical cache target;
- the process runs with the recorded unprivileged UID/GID;
- no cache population, Spindle daemon, `LD_AUDIT`, or preload interposition is
  active; and
- source and cached-payload metadata remain unchanged and direct byte
  comparison still succeeds.

An additional permission probe changes one cached focal object's mode to
`000`, requires an unprivileged logical `open` to fail with `EACCES`, restores
the exact mode, and revalidates the target metadata. This probe is outside the
upstream test command and cannot satisfy the source oracle.

### 3. Withdrawn Causal Control

Before either focal run, the controller creates an immutable empty canary file.
After the source Spindle condition, root bind-mounts that file over the
resolved source implementation of `libtest10.so`. The source directory,
test ELF, non-focal fixtures, and every other lower object remain unchanged.

The `namei_ext` condition maps the logical upstream `libtest10.so` lookup
directly to Spindle's cached file, so the covered source implementation is not
used. For the withdrawn control, remove only the target rule for
`libtest10.so`; keep the same cgroup, binary, arguments, working directory,
user, cache, environment, and covering mount.

Require nonzero exit status and an upstream `libtest10.so` load failure. Also
require zero `libtest10.so` selections during the withdrawn command. This is a
causal control, not a competing baseline.

Finally unmount the canary, require the source file's original device/inode,
mode, size, and mtime to reappear, and directly compare every source/cache
pair again. The covering mount and every policy/target/cgroup object must be
gone before boot completion.

## Correctness And Validity Gates

Correctness gates every descriptive duration:

- source Spindle and `namei_ext` exit zero, report no runner error, and satisfy
  their stderr oracle;
- withdrawn exits nonzero for the declared focal missing-object reason;
- the same upstream test ELF, arguments, source tree, and UID/GID are
  used in all conditions;
- the 47 required source-to-cache mappings pass Spindle-log, path, tmpfs,
  identity, and direct byte-comparison checks;
- all 47 focal-object groups are selected during the `namei_ext` command;
- logical identity probes match physical Spindle cache objects;
- lower permission behavior is observed from an unprivileged process;
- source and cache payload metadata and bytes are preserved;
- external BPF and FUSE inventories are empty before and after;
- source Spindle runs without BPF, and no Spindle process or interposition
  remains during `namei_ext` or withdrawn;
- the modified kernel and real `cgroup/namei_ext` attach path are recorded;
- every map, target, link, cgroup, mount, and child process is cleaned up; and
- dmesg has no declared warning, BUG, oops, lockdep, or sanitizer failure.

The test is invalid, not negative, if source Spindle fails, any required cache
mapping is absent or ambiguous, a cache object does not match the source under
`--strip=no`, the canary is ineffective, provenance is dirty, or mechanism
engagement cannot be attributed.

## Metrics

Paper-facing RQ1 metrics:

- source test result per condition;
- required focal objects mapped and selected, out of 47;
- global source path to physical cache identity and byte agreement;
- per-object and aggregate target-selection counts;
- lower-object and permission preservation.

Descriptive dependency data:

- condition duration;
- complete Spindle cache object/file/byte counts;
- source and cache filesystem identities;
- Spindle request/cache diagnostics.

No performance or scaling hypothesis is attached. The Spindle paper's Pynamic
results remain cited production-scale evidence, not reproduced numbers.

## Comparison And Scope

The source Spindle condition represents the production system's behavior and
produces the cache used by the proposed condition. The withdrawn row is a
causal control. No FUSE baseline is needed to answer this RQ1 sufficiency
question, and no performance conclusion is admissible. A later RQ2 plan would
need a matched FUSE implementation and a performance-relevant workload.

Supported scope if the formal matrix passes:

- lookup-time selection of Spindle-populated node-local DSOs;
- unmodified loader use of original source pathnames;
- cross-filesystem file selection and target withdrawal;
- constructors, dependency chains, symbols, TLS, C++ exceptions, and
  `$ORIGIN` in the declared source-derived slice; and
- lower-file identity, bytes, and permission behavior.

Out of scope:

- cache population, invalidation, broadcast, sessions, and request coalescing;
- exec/stat suites excluded by upstream `--nompi`;
- Spindle's private-path hiding implementation;
- multi-node scaling and shared-filesystem request reduction;
- Pynamic performance reproduction;
- Python/data-file staging, writes through staged paths, and cache recognition;
- replacement of Spindle as a production system.

## Implementation Boundary

Project code may provide only:

- Make targets for pinned acquisition, upstream build, KVM execution, and
  analysis;
- one eBPF policy implementing component-to-registered-target selection;
- one userspace adapter that parses preserved first-party mapping records,
  registers targets, installs rules, creates the cgroup, launches the
  unmodified upstream test ELF, collects counters, and cleans up;
- the canary covering mount, object inventory, and focused result analysis;
  and
- source-level contract tests for the frozen protocol.

Project code must not implement a loader test, library generator, cache,
distribution protocol, filename mirror, Spindle client, or project-owned shell
control plane.

## Reproducibility And Commands

Planned commands:

```text
make workload-spindle-build
make kvm-spindle-staging-preflight RUN_ID=<fresh-id>
make experiment-spindle-staging RUN_ID=<fresh-id>
```

Raw roots:

```text
results/experiments/spindle-staging-preflight/<RUN_ID>/
results/experiments/spindle-staging/<RUN_ID>/
```

The result captures archive/commit/configure/build provenance, source files
that define the oracle, kernel commit/config/image, modified-kernel bpftool,
executed policy/adapter paths, exact commands and environments, stdout/stderr,
first-party debug logs, raw mapping and counter observations, source/cache
metadata inventories, mount and external inventories, cleanup evidence, and
dmesg.

Frozen timeouts:

- source Spindle condition: 180 seconds;
- `namei_ext` condition: 120 seconds;
- withdrawn condition: 120 seconds;
- one preflight boot: 600 seconds;
- one formal boot: 600 seconds.

## Preflight, Formal Matrix, And Interpretation

Preflight uses one fresh boot and the complete three-condition lifecycle. At
most three real preflight roots are allowed. A failure after root creation
counts. Runner or packaging repairs may not change source, focal objects,
command, conditions, oracle, timeout, or interpretation.

A passing preflight requires independent raw-result review before formal work.
Formal execution repeats the unchanged lifecycle in three fresh KVM boots.
Completion requires three terminal boots, all three conditions in each boot,
141 accepted focal source-to-cache mappings, 141 focal-object selection groups,
three effective withdrawn controls, complete command/object/inventory evidence,
and no excluded or replaced boot.

Interpretation:

- **supported**: all three formal boots pass every source, cache, `namei_ext`,
  withdrawn, lower-object, cleanup, provenance, and dmesg gate;
- **contradicted**: source Spindle and cache evidence are valid, but the
  unchanged `namei_ext` condition consistently fails the focal loader oracle
  or selects an incorrect existing object;
- **mixed/inconclusive**: correctness evidence reaches the focal mechanism but
  differs across the three complete boots without a supported or contradicted
  direction;
- **invalid**: source control, cache population/mapping, canary, provenance,
  inventory, or engagement evidence is insufficient.

Target paper artifact: one compact RQ1 table row reporting 47/47 selected
objects, three source/namei/withdrawn outcomes, and lower-object preservation.
No duration ratio appears in the paper from this experiment.

## Pre-Execution Evidence Corrections

The Make-owned source check established that the frozen Spindle build emits
the first-party mapping record as:

```text
add_global_name - Adding LOCAL, GLOBAL, index=N
```

The earlier angle brackets were explanatory notation, not literal log
characters. The adapter accepts only this exact prefix, the two comma
delimiters, and a local name containing `-spindlens-file-`. This correction
does not change the accepted global/local fields or the 47-object inventory.

Each run packages the complete Spindle build and installed prefix as one
runtime archive. Spindle embeds its build
and prefix roots in ELF RUNPATH and helper paths, so the archive is not
treated as relocatable. Each fresh guest extracts a boot-local runtime
tree inside that boot's result directory and bind-mounts it over the exact
root used at compile time. The guest requires the mounted root to have the
same device/inode as the extracted source, requires `ldd` to resolve
`libtestoutput`, `libfuncdict`, and `libspindle` inside that mounted tree, and
checks the compiled `spindle_be`/bootstrap paths there. The source Spindle,
`namei_ext`, and withdrawn conditions therefore use the same per-boot
`test_driver`, DSO/helper tree, working directory, UID/GID, and environment.
The runner, BPF object, and modified-kernel bpftool execute directly from the
packaged artifact tree. Required executables, direct fixture comparisons, and
symlink targets are checked before execution; the bind mount must be gone at
boot completion. This replaces direct use of provisional `.build/`
contents; it does not change source commit, build, command, focal objects,
conditions, or oracle.

Four upstream permission-test fixtures (`retzero_`, `retzero_x`, `hello_.py`,
and `hello_x.py`) deliberately have owner modes `0200` or `0300`. The
unprivileged artifact builder cannot read their built paths. The `retzero`
exec tests are skipped by `--nompi`, so those two non-focal binaries remain
recorded by metadata and absent. The readlink suite is not skipped: it requires
`hello_.py` to be a regular file and checks that `hello_l.py` contains the
literal target string `hello_x.py`; it does not dereference that target.
The upstream Makefile creates both from checked-in `hello.py`. The runtime
archive therefore carries two byte-identical entries derived from that source
file. They use `0600` and `0700` while the host transports the archive; the
guest applies the upstream `0200` and `0300`
before the source condition. Their path, mode, owner, size, device, inode, and
bytes must remain unchanged through all three conditions, after which the
outer cleanup restores the transport modes. They are not among the 47 focal
objects.

The guest uses an outer cleanup target around the fail-fast workload target.
On either success or failure it recursively removes the runtime bind mount,
captures external BPF/FUSE inventory and dmesg, and writes a terminal
`boot.json` with inner, cleanup, inventory, and dmesg statuses. After the VM
launcher exits, the host propagates failure without rewriting the guest's raw
observations. A failed root may be partial by definition and is never repaired
or reused as a successful result.

The repository's fail-fast experiment contract is authoritative. A failed
preflight preserves the failed run root and stops before formal execution.
Formal execution is eligible only after a supported preflight and independent
raw-result review; any formal boot failure stops the target and preserves the
failure rather than manufacturing a completed `contradicted` or `mixed`
analysis. Therefore the published analyzer classifies only a complete
three-boot confirmation as `supported`. A scientific failure is inspected
from its raw failed root and causes the hypothesis or implementation to be
revisited before any new frozen experiment. The previous four-way terminal
classification described the interpretation space, not behavior that the
Make target should synthesize after a hard workload failure.
