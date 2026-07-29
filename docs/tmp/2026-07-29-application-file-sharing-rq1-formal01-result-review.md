# Result Review: RQ1 Sandboxed Application File Sharing Formal01

## Verdict

- Result classification: positive.
- Run status: valid.
- Tested hypothesis: supported.
- Research value: supporting RQ1 evidence.

The result adds an application-sandbox workflow to the RQ1 breadth evidence.
It does not independently answer all of RQ1.

## Executed Protocol

The dependency preflight completed one modified-kernel KVM boot at:

`results/experiments/application-file-sharing-rq1-preflight/20260729T-w1-rq1-preflight01/`

The unchanged formal workload completed three fresh KVM boots at:

`results/experiments/application-file-sharing-rq1/20260729T1824Z-w1-formal01/`

The preflight and formal run used clean source commit
`f7db82bd89cbe438d39d3d0b4407501a81e9e057`, kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`, the same policy, the same five
states, and the same correctness checks. Only the planned repetition count
changed from one to three. The three formal boot records completed at
18:23:20Z, 18:23:25Z, and 18:23:29Z; every dmesg begins at kernel time zero and
each launcher names its own repetition directory.

## Correctness Evidence

The formal run contains 75 raw records and no failed record:

- 15/15 lifecycle states passed;
- 3/3 granted states were visible;
- 12/12 pre-grant, cross-application, and post-revoke states were hidden;
- 39/39 setup, lifecycle, and cleanup cases passed.

In every hidden state, document `stat`, payload `stat`, and payload open/read
returned `ENOENT`. `opendir`, complete `readdir`, and `closedir` succeeded, but
`document` was absent from enumeration. The registered lower document and
payload remained directly accessible.

In every granted state, lookup, payload stat/read, and enumeration succeeded;
the payload bytes matched and `document` appeared in enumeration. The logical
document matched lower device/inode `49/11` in all boots. The logical payload
matched its lower object at `50/464`, `50/466`, and `50/464` in the three
boots.

All 15 unrelated-path reads returned the expected bytes. All three
lower-object records preserved device, inode, mode `100644`, size 27, and
expected bytes. The three saved lower payloads and three saved unrelated
payloads matched their expected files directly.

## Mechanism And Cleanup Evidence

Each boot recorded:

- 210 lookup and 30 readdir policy events;
- 3 `SELECT`, 12 lookup-`HIDE`, and 4 readdir-`HIDE` decisions;
- one successful grant and revoke;
- one successful detach and target-registry clear;
- two successful application-cgroup removals.

Across all six before/after inventory points, no external BPF program, cgroup
attachment, FUSE mount, or open `/dev/fuse` descriptor was present. All three
dmesg failure-pattern scans passed.

## Interpretation

The evidence supports this claim:

> Across three fresh KVM boots, `namei_ext` implemented the tested
> existing-object subset of the XDG Documents portal: one application's
> document became visible after grant and hidden again after revoke, a second
> application remained isolated, lookup and directory enumeration agreed, and
> the selected pathname resolved to the registered lower object. The lower
> payload and an unrelated same-named path remained unchanged.

The granted readdir path exposes the logical placeholder name with `PASS`;
object selection occurs during lookup. The result therefore supports
enumeration visibility and lookup-time object identity, not readdir metadata
synthesis.

The workload is a source-derived C probe, not the portal implementation. This
result does not claim complete portal compatibility, synthetic document
hierarchies, permission persistence, mode or xattr synthesis, concurrency
behavior, or performance.

## Independent Review

A fresh read-only reviewer independently inspected the per-boot observations,
saved payloads, metadata, inventory, cleanup, dmesg, source/kernel identities,
and preflight/formal continuity. The reviewer found no defect that invalidates
the exact hypothesis and classified the result as valid supporting RQ1
evidence.
