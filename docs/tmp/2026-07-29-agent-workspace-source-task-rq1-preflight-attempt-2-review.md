# Agent Workspace Source-Task RQ1 Preflight Attempt 2 Review

## Scope

An independent reviewer inspected the admitted plan, policy and controller,
import probe, Make finalizer, modified-kernel target-selection path, and the raw
attempt 2 root:

`results/experiments/agent-workspace-source-task-rq1-preflight/20260729T-agent-source-task-preflight02/`.

The review asked whether the failed cwd string oracle was valid and whether a
third and final real preflight was ready.

## Verdict

NO-GO until three bounded implementation repairs are complete. The reviewer
found no mechanism contradiction and did not request a change to the research
question, source task, state machine, or primary oracle.

## Findings

### Current-directory semantics

`namei_ext_apply_target()` replaces `nd->path` with the registered target path
and marks the walk as jumped. A successful `chdir()` therefore stores the
selected lower target as the current directory. `getcwd()` reconstructs that
object's physical path; it does not retain the caller's logical pathname
spelling.

Attempt 2 is consistent with this behavior. Both concurrent children recorded
that cwd was not the logical spelling; the v1 record did not preserve the
actual cwd string. Their exact logical `PYTHONPATH`, module paths, source/test
object identities, and pytest outcomes selected the intended completed and base
trees. Kernel target-selection and `getcwd()` semantics explain why a
lower-object cwd is expected.

Required repair: preserve the actual cwd string as a raw observation and replace
string equality with exact device/inode equality among the current directory,
logical workspace root, and assigned lower workspace root. The import record
schema must change, and the Make finalizer must compare the recorded identities
directly.

### Hard-coded summary counts

The controller wrote `pytest_runs=6` and `concurrent_pairs=1` in its terminal
summary regardless of where fail-fast stopped. Attempt 2 produced only four
task-state records, while attempt 1 stopped before a concurrent record.

Required repair: remove these hard-coded fields and their summary-level
validator. The finalizer and analysis already derive actual state and concurrent
counts from the raw event stream.

### Error attribution

`prepare_environment()` combined cgroup movement with privilege and environment
setup, while its caller mapped every failure to `move_errno`.

Required repair: execute and record the cgroup move separately. Privilege,
pathname construction, `clearenv`, and `setenv` failures belong only in
`internal_errno`.

## Evidence Still Required

Attempt 2 did not execute switch, rollback, withdrawal, policy counters, or a
passing complete summary. After the bounded repairs receive a static follow-up
review, the third preflight must run the complete one-boot workflow. Attempt 2
cannot be promoted to an RQ1 result.

## Follow-up Review

The reviewer confirmed that all three code blockers are repaired: import schema
v2 and the finalizer agree on exact object identities, the raw summary no
longer hard-codes event counts, and only the cgroup move can set `move_errno`.
After the evidence wording above was corrected to avoid claiming an unrecorded
cwd string, the implementation is GO for commit and the third and final
preflight.
