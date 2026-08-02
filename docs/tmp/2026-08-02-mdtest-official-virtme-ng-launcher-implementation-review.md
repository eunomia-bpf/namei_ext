# mdtest Official virtme-ng Launcher Implementation Review

## Round 1

Independent reviewer `019fc188-e540-79f3-b263-8a7bb8f92db0` verified that:

- legacy KVM callers retain the old injected-QMP/controller path;
- native expansion contains official `--verbose --pin 8-15` and no injected
  QMP option;
- the listener observation is non-connecting and bounded;
- verification begins after the listener observation and six-second
  separation;
- the guest cannot cross its 60-second barrier before exact verification;
- listener, verifier, launcher, and guest evidence remain separate; and
- the mdtest matrix, parser, oracle, and main FUSE baseline are unchanged.

The initial verdict was `NO-GO` for one blocker: an existing source stamp did
not revalidate that the launcher actually executed from a clean checkout at
the recorded commit. `git show <expected>` could succeed even if checkout
`HEAD`, tracked files, or an overrideable `MDTEST_VNG` differed.

The implementation now checks, before result-root creation, that:

1. `MDTEST_VNG` is exactly the pinned checkout's non-symlink executable;
2. the source stamp and checkout `HEAD` equal `8f74ccee...`; and
3. the Git index and tracked files are clean.

The captured version record now reads `HEAD`. The run manifest also records
the 60-second guest barrier bound requested as a nonblocking improvement. No
checksum or additional control interface was added.

## Follow-Up

The reviewer rechecked the repaired source path, Make expansion, listener and
verifier ordering, guest barrier, result manifest, and finalizer. No blockers
remain. The reviewer returned:

```text
Verdict: GO for one bounded real KVM preflight.
```

Formal execution remains prohibited until the complete preflight receives an
independent result review. The suggested native-capture fixture is not added:
it would be a dependency-only project-authored control and the admitted real
stock boot directly tests the official launch path.

## Attempt-1 Repair Follow-Up

Attempt 1 failed before the guest workload because the repeated absolute paths
inside `virtme.exec` caused later 9p root arguments to be truncated. The final
bounded follow-up reviewed the single-root repair, the immutable attempt-1 raw
statuses, and the official-launcher dry run. It found no blocker or
nonblocking defect:

- guest Make derives the exact runtime, boot, and kernel-config paths from one
  `MDTEST_RUN_ROOT`;
- the repaired launcher command retains `rootfstype=9p`, full `rootflags`,
  `raid=noautodetect`, and the official `virtme-init` argument;
- simultaneous launcher and verifier failures now have an honest combined
  classification while preserving both raw statuses; and
- conditions, ranks, operations, sample sizes, cache dropping, workload
  parser, oracle, finalizer, and analysis are unchanged.

```text
Verdict: GO for fresh preflight attempt 2 after commit and host gates.
```
