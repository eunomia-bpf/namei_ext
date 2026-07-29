# Build Action RQ2 KVM Preflight Attempt 2

## Scope

This record covers the second real paired-preflight attempt for the
Bazel/official-sandboxfs RQ2 experiment:

`results/experiments/build-action-rq2-preflight/20260729T023952Z-build-action-rq2-preflight-v2/`

The attempt used clean source commit
`49d2b350543afbae53217476526a0f666924e168` and clean modified-kernel
commit `bdc9a83e3dfbef8ff2017f9188c7c86025962183`.

## Result

The attempt is terminally failed and immutable. It completed the first
`namei_ext` boot's external mechanism-engagement check but failed its first
Bazel sample. The sandboxfs boot did not start. This root contains no paired
correctness or timing result and is not paper evidence.

## Evidence From The Attempt-1 Repair

The kernel-source bpftool repair worked:

- the copied artifact reports bpftool 7.8.0 with libbpf 1.8;
- its source commit equals the modified-kernel commit;
- its SHA-256 is
  `042322ac211a3fc915249af5aa3d85d57849ab8e525a30b65b482e66bbd3bcc5`;
- the manifest hash equals the copied runtime artifact;
- `bpf-programs-middle.json` records the live `namei_ext_policy`; and
- `bpf-cgroup-middle.json` records that program with attach type
  `cgroup_namei_ext` on `/sys/fs/cgroup`.

The 4,096-entry policy-map fill/read/clear capacity probe also passed.

## Failure

The runner emitted one failed sample with `errno=EIO`. Both Bazel stdout and
stderr files are empty, and no action-started or action-finished evidence was
produced.

The copied Bazel path in `guest.mk` is repository-relative. The action child
opens its result logs, changes directory to its temporary Bazel workspace, and
then calls `execl()` with that relative artifact path. After the `chdir()`, the
path no longer names the copied Bazel binary. The child therefore exits at its
declared `execl` failure code before Bazel starts, and the parent reports
`EIO` when waiting for the action-ready files.

This is an execution-path bug in the new paired runner, not a failed Bazel
build, policy correctness failure, or comparison result.

## Repair

The runner now resolves `argv[4]` with `realpath()` before creating any action
child. Both children retain that absolute path across their workspace
`chdir()` and execute the copied, manifest-hashed Bazel artifact. The
infrastructure contract requires the canonicalization to precede the child
`chdir()`.

No workload, input scale, policy, source oracle, sandboxfs configuration,
sample count, timing boundary, or statistical rule changed.

## Validation And Independent Review

The repaired runner rebuilt cleanly with `-Wall -Wextra`. The Build Action
analysis tests, infrastructure tests, complete result contract, Makefile
parse, Python compile checks, and `git diff --check` passed. The modified
kernel tree remained clean.

An independent read-only review traced the relative Bazel path from the
captured guest Makefile through the child `chdir()` and `execl()` call,
confirmed that the empty Bazel logs and `EIO` record are consistent with that
failure, and verified that `realpath()` executes before either action child is
created. It found no blocker or high-severity defect and returned
`ATTEMPT 3 GO`.

The reviewer noted two non-blocking evidence limitations: the parent reduces
an early child exit to `EIO` instead of preserving the exact child exit code,
and the new contract is a source-order check rather than a standalone
behavioral test. Neither changes the source-grounded diagnosis or the repair
needed for the final real preflight.

## Decision

Attempt 2 remains failed and is not analyzed or promoted. The frozen protocol
allows one final real preflight attempt. The repair, local contracts, and
independent review satisfy its admission gate. Attempt 3 is authorized.
