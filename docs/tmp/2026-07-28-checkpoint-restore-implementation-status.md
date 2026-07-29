# Checkpoint/Restore Implementation Status

## Purpose

This record captures the implementation state of the DMTCP-derived
Checkpoint/Restore and Migration experiment. It distinguishes completed source
and build work from host dependency evidence. No result described here is
Phase 1 evidence for `namei_ext`.

## Implemented Scope

The current tree contains:

- pinned DMTCP source acquisition, checksum verification, extraction,
  configure, build, install, and provenance targets in
  `configs/benchmarks/workload-sources.mk` and `mk/workload.mk`;
- a frozen preflight configuration in
  `configs/benchmarks/checkpoint_restore.mk`;
- a focused DMTCP application in
  `experiments/checkpoint_restore/checkpoint_restore_app.c`;
- a lifecycle controller in
  `experiments/checkpoint_restore/namei_ext_checkpoint_restore.c`;
- a local experiment build entrypoint in
  `experiments/checkpoint_restore/Makefile`; and
- a lookup-only directory-selection policy in
  `bpf/policies/checkpoint_restore_migration.bpf.c`;
- a shared-lifecycle KVM suite in
  `mk/experiments/checkpoint_restore.mk`; and
- an independent result analyzer and focused rejection tests in
  `analysis/checkpoint_restore/`.

The application closes pathname-derived file descriptors before checkpoint and
uses `fopen`, `fstat`, and `opendir`/`readdir` after restart. The controller
creates immutable A and B directory fixtures, captures lower-object hashes and
metadata, coordinates checkpoint/restart, records process cgroups and
checkpoint images, and emits raw JSONL case and lifecycle records. The
`namei_ext` condition replaces target ID 1 from A to B; the withdrawn control
removes its component mapping and expects `ENOENT`.

## Validation Completed

The pinned DMTCP source at commit
`068559d9b14c5f96a57869753bba7c066cbf9653` builds and installs through
`make workload-dmtcp-build`. Acquisition verifies and applies
`thirdparty/patches/dmtcp/restart-env-scan-count.patch`, then records the
archive, patch, patched source file, installation, and binary hashes. Its
official unchanged-mapping pathvirt test also passes on the host, as recorded in
`2026-07-28-dmtcp-source-feasibility.md`.

The focused application and controller compile warning-free against the pinned
DMTCP installation. The BPF policy compiles with the existing policy build.
These checks validate source dependencies and local compilation only.

## Initial Source-Baseline Preflight Failure

The focused host-side `pathvirt` preflight performs a real checkpoint and
restart. Before checkpoint, the logical workspace resolves through mapping A,
and the pre-checkpoint oracle passes. The restart process and `mtcp_restart`
are launched with an environment containing the requested A-to-B
`DMTCP_PATH_MAPPING` change. After restart, however, the restored application
still reads generation A.

Additional application attribution calls `dmtcp_get_restart_env` after restart.
It reports `RESTART_ENV_NOTFOUND` for `DMTCP_PATH_MAPPING`, while the ordinary
restored process environment contains the checkpoint-time A mapping. The
current upstream `pathvirt` integration test does not exercise a changed
mapping: it uses the same mapping before checkpoint and after restart.

This initial failure was not a failed `namei_ext` result and is not paper
evidence.

## Root Cause and Causal Repair

`dmtcp_get_restart_env()` reads a flattened restart environment into a dynamic
buffer and returns the byte count as `count`. Its scan nevertheless used
`sizeof(env_buf)`, where `env_buf` is a pointer. On this x86-64 build the scan
therefore stopped after eight bytes and could not find
`DMTCP_PATH_MAPPING`.

The checksum-pinned patch changes only that scan bound from
`sizeof(env_buf)` to `count`. It does not modify PathTranslator's mapping,
wrapper dispatch, checkpoint protocol, or the experiment oracle. With the fix,
the focused host A-to-B lifecycle passes:

- the pre-checkpoint observation resolves the logical workspace to generation
  A and reports `restarts=0`;
- the post-restart observation reports `restarts=1`,
  `restart_env_status=0`, and the generation-B restart mapping;
- the same logical pathname resolves to the generation-B inode;
- directory enumeration contains `new.txt` and not `stale.txt`; and
- all six lower objects preserve their bytes, modes, sizes, timestamps, and
  inode identities.

The raw causal run is
`results/workloads/preflight/checkpoint-restore-pathvirt/20260728T-dmtcp-pathvirt-contract-v4/`.
Its checkpoint duration was 40.3 ms, mapping update 35 ns, restart-to-oracle
202.7 ms, and total controller lifecycle 676.8 ms. These durations are
diagnostic only. The completed shared `run.json` marks this as a dirty-source
host dependency preflight, not a formal experiment.

## Files and Code Paths Inspected

The diagnosis inspected:

- DMTCP `src/plugin_pathtranslator.cpp`, including its restart event;
- DMTCP `src/dmtcpplugin.cpp`, including `dmtcp_get_restart_env`;
- DMTCP `src/dmtcprestartinternal.cpp`, including `setEnvironFd`;
- DMTCP `test/pathvirt1.c` and the `pathvirt` autotest definition; and
- process `execve` environments for `dmtcp_restart` and `mtcp_restart`.

## Modified-Kernel Preflight Integration

`make kvm-checkpoint-restore-preflight` now captures a self-contained artifact
set and runs three conditions in one modified-kernel guest:

- patched DMTCP PathTranslator maps the logical workspace from generation A to
  generation B across restart;
- `namei_ext` replaces registered target ID 1 from generation A with generation
  B; and
- the withdrawn control removes the mapping and must return `ENOENT`.

The guest first runs DMTCP's official unchanged-mapping `pathvirt` autotest. It
then runs the same focused application and lower-object oracle for all three
conditions. Result completion requires exact condition membership, successful
controller rows, checkpoint-image hashes, immutable lower-object evidence,
empty before/after BPF and FUSE inventories, kernel identity, and complete
artifact manifests. Analysis starts only after the raw run transitions to
`completed`; failed analysis cannot rewrite that status.

The analyzer independently reconstructs the application oracle, DMTCP restart
mapping, `namei_ext` program/cgroup identity, SELECT counter change, withdrawn
`ENOENT`, and lower-object invariance. Ten focused analyzer tests and the
shared result-contract tests pass. A dry run validates the full Make dependency
graph and `finalize`/`complete`/`analyze` ordering.

## Not Yet Validated

The host dependency preflight now uses the shared run metadata, verified
input/artifact manifests, completion transition, and evidence checksum
contract. It preserves the original DMTCP archive, patch, relevant source,
complete install manifest, and a complete result-owned install tree, and runs
the A-to-B baseline from that copied tree. The `namei_ext` and withdrawn
conditions have not yet run on the modified kernel. There is no KVM preflight
result review, and no formal run is authorized.

The first clean-source KVM attempt,
`results/experiments/checkpoint-restore-preflight/20260728T232936Z/`, booted the
modified kernel and passed artifact and DMTCP installation validation. DMTCP's
official unchanged-mapping `pathvirt` control checkpointed successfully but its
restored worker exited with assertion code 99 before the three focused
conditions began. The failed run remains preserved and was not analyzed. The
next attempt enables the upstream harness's verbose mode and copies its failure
artifact directory into the result root; it does not weaken the control.

The second clean-source KVM attempt,
`results/experiments/checkpoint-restore-preflight/20260728T233617Z/`, preserved
the exact DMTCP assertion. The guest process ran as UID 0 while the checkpoint
image in the host-shared result tree was owned by UID 1000. DMTCP's strict
restart ownership check rejected that mismatch. The next repair keeps strict
checking: the root controller retains BPF and cgroup setup, then launches all
DMTCP children as the UID/GID that owns the result directory. The upstream
control uses the same identity, and application rows plus the analyzer record
and verify it.

The third clean-source KVM attempt,
`results/experiments/checkpoint-restore-preflight/20260729T001040Z/`, booted
the modified kernel and verified its identity, the `namei_ext_lookup` symbol,
and the copied DMTCP install tree. The upstream control did not start because
its `setpriv` recipe reused UID/GID shell variables assigned on an earlier Make
recipe line; GNU Make's per-line shell execution left both values empty. The
repair computes both values inline in the `setpriv` command and has a source
contract test. This was the third counted preflight, so the bounded attempt
budget is exhausted. The failed root is preserved, no formal run is
authorized, and the workload remains without KVM sufficiency evidence.

## Next Decision

The source baseline now passes as patched DMTCP PathTranslator at commit
`068559d9b14c`, with a disclosed one-line restart-environment scan-bound fix.
An independent read-only review confirmed that the patch repairs only
restart-environment retrieval, the provenance makes the modified baseline
unambiguous, and the comparison remains fair. Its final verdict is `GO`.

The current preflight is closed after three failed attempts. No formal matrix
is authorized, and the inline UID/GID repair is runtime-unvalidated. Any future
KVM execution requires a new protocol with an explicit methodological reason,
a new attempt budget, and independent plan review; it must not be described as
a continuation or replacement of these three roots. The current experiment
budget moves to another predeclared source-derived workload.
