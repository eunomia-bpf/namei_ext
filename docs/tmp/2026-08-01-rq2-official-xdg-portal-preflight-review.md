# Result Review: Official XDG Documents Portal RQ2 Preflight

## Scope

This independent review closes the three-attempt real preflight for the frozen
official-source RQ2 comparison. The final result root is:

`results/experiments/application-file-sharing-rq2-official-preflight/20260801T113049Z-3ee783a/`

The approved protocol is recorded in
`docs/tmp/2026-08-01-rq2-official-xdg-portal-performance-plan.md`. It permits
one 100-transaction pair only as a real-path preflight. A paper-facing estimate
would require ten pairs with 10,000 measured transactions per boot after a
successful preflight and independent review.

## Independent Evidence Review

Both fresh modified-kernel KVM boots completed their mechanism, ext4 cleanup,
post-run inventory, and dmesg checks. All four measured streams contain exactly
samples 0 through 99 and every transaction passed its stat, open/read, and
directory-enumeration oracle. The immediate post-grant observations returned
the complete 27-byte payload and listed the document; the immediate post-revoke
observations returned `ENOENT` and omitted it.

Both mechanisms demonstrably served the measured transaction. The official
portal recorded measured deltas of 100 `OPEN`, 100 `READ`, 100 `OPENDIR`, and
200 `READDIR` requests. The `namei_ext` measured interval increased `SELECT`
from 33 to 333 and scope-matched visible `READDIR` from 11 to 111. These facts
establish narrow mechanism correctness for the preflight. They do not make the
entire preflight valid or authorize a performance result.

The frozen analysis failed because the portal daemon's captured thread set was
not stable. PID 262 had nine threads before the measured interval and ten
afterward; TID 272 appeared only in the after snapshot. The analyzer requires
the same nonempty TID set so that all-thread CPU and scheduler deltas have a
defined subtraction. It raised `unstable or missing
xdg-document-portal/portal-daemon thread snapshot` and produced no analysis
summary, report, confidence interval, latency decomposition, or resource table.

The root was then marked failed manually because the outer Make target did not
yet propagate finalizer or analyzer failures into `run.json`. Its specific
`analysis-unstable-portal-thread-set` failure label is therefore out-of-band
metadata, and no analyzer stdout/stderr status artifact was captured. The raw
before/after thread records independently prove the mismatch, but the manual
terminal mutation makes the root inadmissible for any paper number. The root
is closed and must not be finalized, analyzed, repaired, or reused.

The review also found that the pre-warmup direct control was mislabeled as
`policy-view`. The 100 measured direct rows are labeled correctly, so this did
not cause the analysis failure. The shared emitter now accepts an explicit
stream name for future runs. The parent Make target now marks finalizer and
analysis failures automatically.

## Judgment

- Run status: invalid.
- Tested hypothesis: inconclusive.
- Research value: dependency-only.
- Paper impact: none.
- Next paper decision: do not execute the formal ten-pair comparison and do
  not report any latency, ratio, confidence interval, tail, or resource number
  from this preflight.

All three permitted real preflight attempts are exhausted. Existing reviewed
W1 correctness evidence remains valid and unchanged; this failed RQ2 protocol
adds no performance claim.

Final verdict: NO-GO
