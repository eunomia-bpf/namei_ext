# Plan Review: RQ2 Spindle Final-Object Selection Versus FUSE

Date: 2026-08-02

## Scope

The reviewer examined
`docs/tmp/2026-08-02-spindle-rq2-fuse-comparison-plan.md` against the exact RQ2,
the completed W6 source oracle, current RQ2 evidence, and the
`research-experiment-design` plan-review criteria. The review did not alter or
reduce the seven mandatory RQ1 cases W1--W7.

## Initial Review

Initial verdict: **BLOCK**.

The reviewer identified five defects that could invalidate a matched
performance result:

1. libfuse 3.14 `read_buf` was weaker than the runnable libfuse 3.18.2
   low-level path with kernel FUSE passthrough.
2. Long-lived FUSE caches required explicit entry/inode invalidation for
   withdrawal and mode changes.
3. The existing W6 runner's 10 ms child polling could quantize a short loader
   measurement; timing and transcript parsing needed separation.
4. Resource attribution needed requester CPU and FUSE daemon CPU over the same
   measured window.
5. One fresh boot per condition was needed to prevent cross-mechanism cache
   leakage; correctness and baseline-engagement failures had to invalidate a
   run rather than become statistically inconclusive data.

## Repair And Verification

Repository inspection confirmed that the modified Linux 7.1-rc7 kernel has
`CONFIG_FUSE_PASSTHROUGH=y`. The pinned local libfuse 3.18.2 source at commit
`033844748010a3b8265bf1c90b9ae8ffe4cd9ca7` exposes
`fuse_passthrough_open()` and the official `passthrough_hp` implementation.

The plan was revised to require:

- multithreaded low-level libfuse 3.18.2 with negotiated kernel passthrough;
- successful positive backing IDs and zero userspace data-read fallback;
- explicit entry/inode invalidation with acknowledged success;
- non-polling process completion, blocking `wait4`, and raw requester rusage;
- same-window daemon CPU, scheduler, context-switch, and callback deltas;
- ten independent condition pairs comprising 20 fresh KVM boots; and
- hard invalidation of any run with failed correctness, engagement, cleanup,
  or comparison fairness.

## Follow-Up Review

Final verdict: **GO**.

The reviewer found no remaining scientific or executability blockers. No
additional baseline or larger Pynamic/MPI scale was required for this scoped
one-node final-object-selection experiment. Negotiated passthrough capability,
valid backing IDs, and successful invalidations remain explicit implementation
gates for preflight and the formal run.
