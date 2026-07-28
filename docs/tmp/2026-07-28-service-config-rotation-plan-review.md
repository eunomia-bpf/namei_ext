# Service Configuration Rotation Plan Review

## Reviewer And Scope

A fresh read-only reviewer checked
`2026-07-28-service-config-rotation-experiment-plan.md` against RQ1, the
source-system oracle, the repository's KVM/result infrastructure, and the
experiment-design baseline rules. The reviewer did not edit the plan.

## Round 1

Verdict: `NO-GO`.

Blocking findings:

1. Kubernetes AtomicWriter validates projected path structure, not nginx
   configuration semantics. The original plan incorrectly attributed
   bad-configuration rejection and retained old generations to AtomicWriter.
2. An unchanged HTTP response after a rejected candidate could false-pass
   because existing nginx workers retain already-loaded configuration.
3. The plan did not freeze enough live-reload mechanics to distinguish reload
   from restart or to prove worker replacement and bounded cleanup.

The plan was revised to publish the invalid generation at the logical path,
require its logical hash, send `SIGHUP` directly to one unchanged nginx master,
observe nginx's native failed-reload behavior, and publish rollback as a new
generation. It also froze worker histories, error-log evidence, monotonic
deadlines, and graceful shutdown.

## Round 2

Verdict: `NO-GO`.

Two blocking consistency defects remained:

1. one contradictory-outcome sentence still treated invalid-generation
   visibility as failure even though visibility is required before nginx
   rejects the reload;
2. the static response trees were not explicitly outside the selected
   configuration path, so an HTTP-body change could be caused directly by
   policy selection rather than successful nginx worker replacement.

Both statements were corrected. The invalid logical hash is required, and
each configuration uses a direct physical static-content path outside
`<fixture>/view/live`.

## Round 3

Verdict: `GO`.

The reviewer confirmed that both remaining blockers were resolved. The
approved plan uses no FUSE row because it is an RQ1 correctness case and makes
no cost or superiority claim. Its formal matrix remains ten fresh KVM boots
with all state and cleanup oracles required in every boot.
