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
- a focused DMTCP application in
  `experiments/checkpoint_restore/checkpoint_restore_app.c`;
- a lifecycle controller in
  `experiments/checkpoint_restore/namei_ext_checkpoint_restore.c`;
- a local experiment build entrypoint in
  `experiments/checkpoint_restore/Makefile`; and
- a lookup-only directory-selection policy in
  `bpf/policies/checkpoint_restore_migration.bpf.c`.

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

## Not Yet Implemented or Validated

The host dependency preflight now uses the shared run metadata, verified
input/artifact manifests, completion transition, and evidence checksum
contract. It preserves the original DMTCP archive, patch, relevant source,
complete install manifest, and a complete result-owned install tree, and runs
the A-to-B baseline from that copied tree. The experiment is not yet connected
to the KVM guest lifecycle, result analyzer, or formal-run configuration. The
`namei_ext` and withdrawn conditions have not run on the modified kernel.
There is no result review, and no formal run is authorized.

## Next Decision

The source baseline now passes as patched DMTCP PathTranslator at commit
`068559d9b14c`, with a disclosed one-line restart-environment scan-bound fix.
An independent read-only review confirmed that the patch repairs only
restart-environment retrieval, the provenance makes the modified baseline
unambiguous, and the comparison remains fair. Its final verdict is `GO`.

The next step is to connect the suite to the shared KVM and result lifecycle
and run one modified-kernel preflight containing patched DMTCP PathTranslator,
`namei_ext`, and the withdrawn negative control. A separate result review is
required before any formal matrix.
