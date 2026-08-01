# Plan Review: RQ2 official Documents portal comparison

## Round 1: No-Go

The independent review rejected the initial plan before implementation for
four paper-affecting reasons:

1. The plan pinned 1.18.4 but described it as current practice. The corrected
   plan uses the unmodified 1.22.1 release at peeled commit
   `1d20fadc304f6601452b5db65ed91197dba77041` and requires its current unit and
   Documents integration source gates.
2. The initial interpretation could attribute a difference against the
   broader portal implementation to hook placement. The corrected role is a
   decisive baseline-credibility test supporting RQ2. Agent/FxMark remain the
   feature-equivalent causal comparisons; this row tests W1 official-source
   external validity only.
3. The operation stream and cache treatment were underspecified. The corrected
   plan freezes the pre-opened parent, 22-byte document component, exact
   `fstatat`/`openat`/read/`getdents64` transaction, equal parent contents,
   fresh readdir fd, source-defined portal cache behavior, and FUSE counts by
   portal connection and opcode.
4. The estimator and controls were underspecified. The corrected primary is
   the per-boot transaction median, ten pair log ratios, their geometric mean,
   and a pair-level bootstrap confidence interval. Every direct-lower control
   receives the same 1,000 warmups and 10,000 samples; order and lower-control
   results are predeclared sensitivity analyses rather than post-hoc vetoes.

The review also requested all-thread daemon resource accounting, separate
grant/revoke reporting, and a paper figure that distinguishes causal matched
comparisons from the official-source external-validity row. All are now frozen
in the plan.

## Round 2

The bounded follow-up returned **GO** with no remaining paper-affecting P1.
It confirmed that the corrected plan closes the version, causal-scope,
path/cache matching, mechanism-attribution, estimator, direct-control, and
all-thread resource-accounting blockers. Implementation may proceed under the
corrected frozen plan.
