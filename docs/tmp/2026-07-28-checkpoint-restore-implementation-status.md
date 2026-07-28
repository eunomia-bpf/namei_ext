# Checkpoint/Restore Implementation Status

## Purpose

This record captures the implementation state of the DMTCP-derived
Checkpoint/Restore and Migration experiment. It distinguishes completed source
and build work from an unresolved source-baseline failure. No result described
here is Phase 1 evidence for `namei_ext`.

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
`make workload-dmtcp-build`. Its official unchanged-mapping pathvirt test also
passes on the host, as recorded in
`2026-07-28-dmtcp-source-feasibility.md`.

The focused application and controller compile warning-free against the pinned
DMTCP installation. The BPF policy compiles with the existing policy build.
These checks validate source dependencies and local compilation only.

## Source-Baseline Preflight Failure

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

This is an unresolved source-baseline failure. It must not be represented as a
failed `namei_ext` result, a completed baseline, or evidence for a paper claim.

## Files and Code Paths Inspected

The diagnosis inspected:

- DMTCP `src/plugin_pathtranslator.cpp`, including its restart event;
- DMTCP `src/dmtcpplugin.cpp`, including `dmtcp_get_restart_env`;
- DMTCP `src/dmtcprestartinternal.cpp`, including `setEnvironFd`;
- DMTCP `test/pathvirt1.c` and the `pathvirt` autotest definition; and
- process `execve` environments for `dmtcp_restart` and `mtcp_restart`.

## Not Yet Implemented or Validated

The experiment is not connected to the repository-wide suite registry, KVM
guest lifecycle, result analyzer, or formal-run configuration. The
`namei_ext` and withdrawn conditions have not run on the modified kernel.
There is no independent implementation review or result review, and no formal
run is authorized.

## Next Decision

Before more integration work, run a bounded source-baseline audit:

1. determine whether the pinned DMTCP release has a documented restart
   environment mechanism that supports changing the pathvirt mapping;
2. test one independently justified DMTCP release or commit if the pinned
   revision is demonstrably broken; and
3. stop this workload if no source-native A-to-B pathvirt baseline can be made
   to pass without a project-created DMTCP patch.

If the source baseline passes, proceed to suite integration and a real KVM
preflight. If it does not, record the workload as blocked and move to the next
predeclared breadth-first case study.
