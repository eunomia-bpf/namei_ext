# Checkpoint/Restore Requalification Plan Review

## Scope

This review examined
`docs/tmp/2026-07-29-checkpoint-restore-requalification-plan.md` against the
original experiment plan, the three preserved KVM attempts, the current
checkpoint/restore Make and analysis code, and the repository's experiment
rules. No code or result root was created.

## Findings

The proposed run preserves the original DMTCP commit, patch, lifecycle,
conditions, oracle, timeouts, and hypothesis. The three prior attempts all
failed before a focal `pathvirt`, `namei_ext`, or withdrawn-control result, so
there is no evidence of an outcome-driven retry.

Nevertheless, renaming the target, result family, and protocol would not make
the run scientifically distinct. It would be a fourth preflight for the same
contract after the original plan's three-attempt limit and the attempt-3
closure decision. That would reset a stopping rule through experiment naming.

The current implementation also does not contain the proposed gates. It still
uses the old target, result family, schema, analyzer contract, and
`/usr/local/sbin/bpftool`. The proposed runtime identity check would need to
verify both process identity and ownership of a file created through the exact
future DMTCP invocation. These are implementable defects, but implementing
them does not resolve the stopping-rule conflict.

## Decision

Do not implement or execute this proposal. Keep all three old roots immutable,
keep W5 labeled unexecuted in the paper, and move the experiment budget to a
different traditional source-derived workload. DMTCP may be reconsidered only
if the user explicitly approves a fourth attempt as an exception; it must then
remain attempt 4 in the original lineage rather than being presented as a new
protocol.

Final verdict: NO-GO
