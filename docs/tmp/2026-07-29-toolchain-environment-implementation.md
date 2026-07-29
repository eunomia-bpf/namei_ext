# Toolchain Environment RQ1 Implementation

## Motivation

The existing RQ1 evidence covers Agent workspaces, application file sharing,
and Bazel action inputs. This implementation adds a traditional installed
software environment: two process groups use the same executable pathname but
select different complete Python virtual environments. It tests whether
directory-target selection preserves the interpreter's own environment
discovery instead of merely returning the expected bytes from one file.

## Source Assets

- Ubuntu CPython 3.10.19 and 3.12.3 executables.
- The standard-library `venv` module creates each lower environment with
  copied interpreters.
- Each environment's installed `pip check` command validates package
  consistency.
- Python's documented `sys.prefix`, `sys.executable`, and import behavior form
  the source-system oracle.

The project code does not install packages or implement environment
activation. It only creates the two environments, selects an existing
directory during lookup, and records the unmodified interpreter's behavior.

## Implementation

- `bpf/policies/toolchain_environment.bpf.c` maps an exact
  cgroup/parent/name key to one pre-registered target directory.
- `experiments/toolchain_environment/namei_ext_toolchain_environment.c`
  creates two workload cgroups, registers the two lower environments, attaches
  the real `cgroup/namei_ext` program, runs the transition lifecycle, and
  records raw observations.
- `experiments/toolchain_environment/probe.py` checks the selected interpreter
  version, executable and prefix paths, SOABI, package path, environment
  marker, and imports of `venv`, `ssl`, `sqlite3`, and `pip`.
- `mk/experiments/toolchain_environment.mk` owns one-boot preflight and
  three-boot formal entrypoints, guest setup, raw artifact capture, correctness
  checks, and report generation.

The lifecycle includes direct physical controls, concurrent Python 3.10 and
3.12 execution through the same logical pathname, a 3.10-to-3.12 switch,
rollback, a withdrawn mapping that must return `ENOENT`, and a lower
interpreter permission check that must return `EACCES`.

## Lower-Filesystem Ownership Check

Before policy attachment, the guest records metadata for both completed
virtual-environment trees. It repeats the inventory after policy cleanup and
requires exact equality. The permission control restores the interpreter mode
before the final inventory. Probe execution disables bytecode writes and pip
cache activity so that reads do not create an artificial lower-tree change.

## Validation Performed

- Both Ubuntu Python versions created copied virtual environments on the host.
- Direct probes observed the expected version, prefix, SOABI, imports, and
  successful `pip check`.
- The C runner and BPF policy compiled locally without warnings after const
  corrections.
- An independent KVM-blocker review returned GO. Its one actionable execution
  risk was repaired by closing unused barrier pipe ends in concurrent children,
  so a child failure before the ready signal terminates instead of waiting for
  the KVM timeout.

The modified-kernel preflight passed at
`results/experiments/toolchain-environment-preflight/
20260729T171312Z-toolchain01/`. The unchanged three-boot matrix then passed at
`results/experiments/toolchain-environment/
20260729T171551Z-toolchain-formal01/`. Across the formal run, all 18
physical/logical state records, 24 Python probes, 18 `pip check` commands,
three paired starts, three permission controls, and three withdrawn controls
passed. All three boots completed cleanup and the declared dmesg check.

An independent result review validated the run as supporting RQ1 evidence.
It explicitly does not support performance, FUSE/custom-filesystem
superiority, all toolchain managers, or unobserved filesystem semantics.

## Remaining Risks

- The errno controls observe `EACCES` and `ENOENT` after their declared state
  changes, but their helper does not separately encode child setup failure
  versus `execv()` failure.
- The paired-start barrier proves that both cgroups reached the same release
  point and then observed distinct environments; it does not measure execution
  overlap duration.
- The lower inventory covers type, mode, UID/GID, size, device, inode, and
  mtime. It does not cover ctime or establish a byte-for-byte content claim.
