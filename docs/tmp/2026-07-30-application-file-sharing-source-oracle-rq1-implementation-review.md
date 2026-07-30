# Application File Sharing Source-Oracle RQ1 Implementation Review

## Scope

An independent read-only reviewer inspected the complete implementation for
the official `xdg-document-portal` control and matched `namei_ext` W1 arm.
The review covered the frozen experiment plan, both C controllers, the pinned
source build, Make/KVM lifecycle, finalizer, analysis, suite admission, and
the dated implementation record.

No KVM execution or Git mutation occurred during review.

## Round 1

The first implementation review returned `NO-GO` with two blockers, four
major findings, and one minor finding:

1. the finalizer compared controller-reported `pass` rows without
   independently executing the exact visible and hidden state oracle;
2. the Phase 1 implementation record was missing;
3. the portal version assumption was first checked inside KVM;
4. the formal experiment entered the aggregate suite before preflight;
5. analysis assigned `verdict:"supported"` beyond its own checks;
6. D-Bus and child-process failure details were discarded; and
7. both controllers used one `read()` rather than reading payloads through
   EOF.

The implementation was repaired without changing the five states or
correctness hypothesis. The finalizer now independently evaluates the errno,
listing, and payload tuple; the source build checks the exact portal version;
formal aggregate admission is deferred; analysis only summarizes completed
raw results; D-Bus and wait status are preserved; and both arms read through
EOF. A standalone implementation record was added.

## Round 2

The second review confirmed those repairs and found three remaining issues:

1. abnormal service exits were recorded but not rejected;
2. the visible `namei_ext` logical-to-registered-lower object identity still
   relied on the controller's `pass`; and
3. D-Bus errors during service-readiness polling were cleared without being
   logged.

The source controller now accepts an initiated service only when it exits with
code zero or the controller's expected `SIGTERM`. The finalizer independently
consumes two raw process-exit records and rejects other statuses. It also
independently compares visible logical and lower device/inode fields for both
the document and payload. Readiness polling logs every actual `GError` before
clearing it.

Positive and negative synthetic rows verified that the process and object
identity gates accept the expected evidence and reject abnormal exits and
mismatched objects.

## Final Recheck

The reviewer read the final snapshot after all Round 2 repairs and reported:

```text
No remaining P0-P2 findings.

Verdict: GO for commit and the first real KVM preflight.
```

The reviewed snapshot passes strict compilation of both controllers,
`make application-file-sharing`, `make application-file-sharing-source`,
`make help`, and `git diff --check`. The pinned source control reports five
passing upstream subtests, zero skip/failure/timeout, and exact version
`xdg-desktop-portal 1.18.4`.

## Disposition

The implementation is admitted for one real modified-kernel KVM preflight.
The review does not establish an RQ1 result. Formal evidence still requires
the unchanged one-boot preflight, three fresh formal boots, and independent
raw-result review.
