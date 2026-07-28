# DMTCP Restart-Environment Root Cause

## Purpose

This record explains why the pinned DMTCP PathTranslator failed the
source-derived A-to-B checkpoint/restart preflight, the exact repair, and the
causal host result. It is dependency evidence only. It does not validate
`namei_ext`, the modified kernel, or a paper claim.

## Symptom

The pinned source is DMTCP commit
`068559d9b14c5f96a57869753bba7c066cbf9653`. Before checkpoint, the application
resolved its logical workspace through generation A. The controller then
launched `dmtcp_restart` and `mtcp_restart` with an environment containing the
generation-B `DMTCP_PATH_MAPPING`. After restart, the application still saw
generation A.

The restored application attributed the failure with both environment APIs:

- ordinary `getenv("DMTCP_PATH_MAPPING")` returned the checkpoint-time
  generation-A mapping; and
- `dmtcp_get_restart_env("DMTCP_PATH_MAPPING")` returned
  `RESTART_ENV_NOTFOUND`.

The upstream `pathvirt` autotest did not expose the problem because it uses one
unchanged mapping across checkpoint and restart.

## Source Path

The relevant call chain is:

1. `src/dmtcprestartinternal.cpp` supplies the restart-environment file
   descriptor.
2. `src/dmtcpplugin.cpp:dmtcp_get_restart_env()` reads the flattened
   environment and returns individual entries.
3. `src/plugin_pathtranslator.cpp` calls that API during
   `DMTCP_EVENT_RESTART`.

`dmtcp_get_restart_env()` stores the number of bytes returned by `readLine()` in
`count`, but bounded its subsequent scan with:

```c
while (start_ptr - env_buf < (int)sizeof(env_buf))
```

`env_buf` is a pointer. The expression therefore limits the scan to the pointer
width rather than the bytes read. The requested mapping cannot be found unless
it appears in that first tiny prefix.

## Upstream History

DMTCP pull request
[#658](https://github.com/dmtcp/dmtcp/pull/658) replaced a fixed restart-
environment buffer with a dynamic buffer to support arbitrary environment
sizes. The pinned source contains that change but retains the pointer-size scan
bound. Pull request [#1224](https://github.com/dmtcp/dmtcp/pull/1224) added the
current PathTranslator plugin and its restart-time environment lookup. No exact
upstream issue or merged fix for the remaining scan bound was found during this
audit.

## Repair and Provenance

The repository carries:

```text
thirdparty/patches/dmtcp/restart-env-scan-count.patch
```

Patch SHA-256:

```text
7c945ba6f4bfc375b3c83f5714ed9546660a164a4c9e235999f1e9e55ca3c127
```

It changes only the scan bound:

```c
while (start_ptr - env_buf < count)
```

The acquisition target verifies the original archive and patch independently,
applies the patch with zero fuzz, rejects the old expression, and records the
patch plus the patched `src/dmtcpplugin.cpp` hash in build provenance. The
patched source must be reported as patched DMTCP, not unmodified upstream.

The repair does not implement pathname translation. PathTranslator still parses
the mapping, receives the restart event, and performs virtual-to-real path
translation. The patch only makes DMTCP's existing restart-environment API scan
all bytes that it already read.

## Causal Preflight

The Make-owned host run:

```text
make checkpoint-restore-pathvirt-host-preflight \
  RUN_ID=20260728T-dmtcp-pathvirt-contract-v4 JOBS=4
```

produced:

```text
results/workloads/preflight/checkpoint-restore-pathvirt/
  20260728T-dmtcp-pathvirt-contract-v4/
```

The two application observations establish the intended transition:

| Stage | DMTCP restarts | Restart-env status | Selected generation | Directory view |
| --- | ---: | ---: | --- | --- |
| Pre-checkpoint | 0 | not applicable | A | `stale.txt`, no `new.txt` |
| Post-restart | 1 | 0 | B | `new.txt`, no `stale.txt` |

The post-restart logical inode equals the physical generation-B inode and
differs from generation A. The checkpoint-time mapping remains A, while the
retrieved restart mapping is B. All controller events pass, all six lower
objects are unchanged, a real checkpoint image is present, and the evidence
checksums validate.

Diagnostic timings from this single host run are:

- checkpoint: 40,293,948 ns;
- mapping update: 35 ns;
- restart to completed oracle: 202,661,059 ns; and
- total controller lifecycle: 676,812,385 ns.

They are not performance results.

This causal run also reran the patched source's official unchanged-
mapping `pathvirt` test and stored its logs. The upstream test reported one
passing group, zero failures, and zero skipped groups. The shared raw-run
contract verified its input and artifact manifests before completion. The
result owns the original archive, patch, relevant source files, complete DMTCP
install tree, executed controller/application binaries, runtime evidence,
checkpoint-image hashes, source/kernel revisions, dirty state, and a terminal
`completed` status.

## Boundary and Next Gate

This result establishes only that patched DMTCP PathTranslator at commit
`068559d9b14c`, with the disclosed one-line restart-environment scan-bound fix,
can execute the A-to-B source oracle. It does not establish baseline
superiority, kernel compatibility, cgroup behavior after restart, or
`namei_ext` correctness.

An independent baseline-integrity review returned `GO` after verifying the
patch scope, result-owned runtime, checksum layers, exact oracle, and baseline
label. The suite can enter one real modified-kernel KVM preflight with patched
DMTCP PathTranslator, `namei_ext`, and the withdrawn negative control.
