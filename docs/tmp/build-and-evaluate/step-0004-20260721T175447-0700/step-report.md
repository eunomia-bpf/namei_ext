# BUILD_AND_EVALUATE Step 0004 Report

Phase: BUILD_AND_EVALUATE
Step: `docs/tmp/build-and-evaluate/step-0004-20260721T175447-0700/`
Started: 2026-07-21T17:54:47-07:00
Status: completed; outer audit passed

## Recovery And Gate Entry

### Context

Node: recovery-001
Gate: EXPERIMENT_GATE
Parent: completed BOOTSTRAP step
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/`
Status: completed

### Question And Entry

The user asked the project to continue improving RQ1, RQ2, and RQ3 until the
paper reaches at least an eBPF-workshop acceptance level. The frozen contract
requires RQ1 expressiveness/sufficiency, RQ2 cost versus feature-equivalent
FUSE, and RQ3 the verifier-bounded fail-closed boundary versus custom or
stackable filesystem ownership. This step selects exactly RQ1 and the headline
Agent workspace lifecycle because it is the highest-value open evidence gap
and is also the fixed first BUILD_AND_EVALUATE action in the accepted frontier.

### Inputs And Method

The root reread `docs/user-instruction.md`, `docs/questions-for-author.md`, the
complete `docs/idea-story.md`, `docs/evaluation.md`,
`docs/background-related-work.md`, the latest BOOTSTRAP step report, the paper's
Evaluation section, the current Make/KVM entrypoint, Agent workspace runners,
the AgentFS-derived trace, and existing raw matrices. Repository state was
clean at entry on `main` at `79d7dd9` and matched `origin/main`.

Recovery found that the newest paper-facing matrix
`results/experiments/agent-workspace-matrix/20260715T003201Z-a12b8555/` predates
the current evidence expectations and remains classified in canonical memory
as incomplete. The current runner now requires an AgentFS-derived source-trace
path in matrix mode, but `mk/kvm.mk` does not pass that required argument. A
fresh current-tree run would therefore fail before contacting the intended
oracle. This is a runner defect to repair inside the admitted experiment, not
scientific evidence.

### Results And Raw Evidence

- Existing raw matrices establish KVM engagement and feasibility but do not
  close RQ1 under the current protocol.
- The current code covers selected base/upper epochs, hidden-name lookup and
  readdir coherence, symlink metadata, cached-negative creation, rename,
  unlink, executable lookup, lower-FS write placement, policy counters, and an
  unregistered-target containment case.
- No fresh current-revision result exists. The paper still contains explicit
  RQ1--RQ3 result placeholders and says the reviewed final rows are missing.

### Scientific Impact And Decision

Start one full-loop `research-experiment-design` experiment for RQ1 only. The
experiment will test whether the real `cgroup/namei_ext` path can reproduce the
fixed AgentFS-derived lifecycle and preserve lower-FS ownership. Existing FUSE
execution is retained only as an independent same-oracle control in this RQ1
step; its costs are not interpreted until the separate RQ2 step. The source
trace argument and provenance chain must be repaired before preflight.

The scientific contract is unchanged. In particular, this step does not
replace the required traditional build/cache family, turn table-only results
back into the novelty claim, or treat a smoke test as an RQ answer.

### Review, State Updates, And Next Action

User intent was appended verbatim to `docs/user-instruction.md`. No author
question is open. The next node is paper-value admission and fresh plan review
for `experiment-001`; completion requires a reviewed plan, a real KVM preflight,
the complete declared run set, preserved raw artifacts, and fresh result review.

## EXPERIMENT_GATE

Entry alignment: the selected RQ appears verbatim in the paper; the step reads
the active user instruction and frozen contract; the Agent workspace lifecycle
is selected by paper-decision value rather than implementation convenience.

### Experiment 001: RQ1 Agent Workspace Lifecycle

Status: completed; independent result review accepted the scoped result
Plan: `experiment-001/plan.md`

#### Plan Review And Repairs

A fresh independent two-round review is recorded in
`experiment-001/plan-review.md`. Round 1 found three blocking protocol defects:
the Make target did not pass the required AgentFS-derived trace to the
`namei_ext` runner, the completion gate checked a nonexistent event name, and
the FUSE control claimed trace provenance without validating the trace.
Repairs now pass and hash the same trace for both implementations, check the
actual artifact/replay events, and require symmetric FUSE
`stat`/`open`/`access`/`exec`/`readdir` plus lifecycle measurements. Round 2
approved the repaired plan and required conjunctive verification of all three
formal runs.

#### Execution Attempts

- Invalid preflight attempt 1: `make experiment-agent-workspace
  RUN_ID=20260722T011256Z-rq1preflight` failed before KVM execution while
  `pahole v1.30` generated BTF for `.tmp_vmlinux1`; the process segfaulted.
  Memory and disk were available, so this is an infrastructure/build failure,
  not RQ1 evidence.
- Repaired preflight attempt 2:
  `make experiment-agent-workspace
  RUN_ID=20260722T015430Z-rq1preflight2 JOBS=1` kept the kernel config and
  workload fixed while serializing BTF generation. It completed the build,
  KVM boot, real attach, source-trace replay, oracle, artifact gates, and dmesg
  check.
- Formal run 1: `20260722T020120Z-rq1run1` -- terminal pass.
- Formal run 2: `20260722T020210Z-rq1run2` -- terminal pass.
- Formal run 3: `20260722T020245Z-rq1run3` -- terminal pass.

Each formal JSONL contains 1,176 records, no `pass == false` record, one
`namei_ext` summary pass, one FUSE same-oracle summary pass, four successful
source-trace artifact/replay records, 16 successful timing records, and a
terminal done marker. All three stderr files are empty and all three dmesg
files pass the declared BUG/WARNING/Oops signature check. The direct RQ1
oracle covers base/agent epoch selection, `.git` and source visibility,
whiteout lookup/readdir coherence, symlink metadata, cached-negative creation,
create/rename/unlink visibility, executable lookup, the final tree, lower-tree
non-materialization, and an unregistered-target fail-closed control. Policy
counters are nonzero for lookup, readdir, select, hide, and pass actions.

#### Preliminary Interpretation

The declared evidence is consistent with a positive answer for the tested
Agent-workspace slice: all three independent KVM runs reproduce the fixed
AgentFS-derived lifecycle through the real hook while the lower filesystem
continues to own ordinary object and write semantics. This closes only the
Agent-workspace subproblem of RQ1. Traditional build/cache remains required
before RQ1 as a whole is answered, and no timing result is interpreted here;
the collected FUSE costs belong to a separate RQ2 experiment.

Fresh result review is recorded in `experiment-001/result-review.md`. Its
verdict is completed, hypothesis supported, and headline research value for
the scoped Agent-workspace cell. It independently verified all three raw roots,
trace binding, policy engagement, lower-FS observations, final manifests,
FUSE same-oracle control, provenance, stderr, and dmesg. The reviewer retained
a non-blocking clocksource caveat for run 2 and noted that future result targets
should record the parent repository HEAD and dirty state in addition to exact
executed-input hashes.

## WRITE_GATE

Status: targeted RQ1 result write completed. The Agent-workspace row in
`docs/paper/sections/05-evaluation.tex` now reports the reviewed three-of-three
pass, operation mix, and lower-filesystem mutation evidence. RQ2/RQ3 and the
traditional build/cache RQ1 row remain explicitly incomplete.

## REVIEW_GATE

Status: inner result review and independent outer audit passed.

Validation completed before outer audit:

- `make -C docs/paper check` passed.
- `make -C docs/paper paper` passed and generated a 15-page
  `.build/paper/main.pdf` (128,182 bytes).
- `git diff --check` passed.
- Remaining `[Result]` markers are intentionally limited to the traditional
  build/cache RQ1 row and the still-unexecuted RQ2/RQ3 rows; the reviewed
  Agent-workspace RQ1 row no longer contains a placeholder.

### Outer-Audit Disposition

The independent report
`outer-audit-20260721T-current.md` passes the scoped Agent-workspace RQ1 cell
and targeted Evaluation edit. It independently confirms the three raw-root
counts, input hashes, operation counts, lower-FS observations, trace binding,
and scope language. It also confirms that timing is not interpreted as RQ2,
RQ3 remains unclaimed, and paper-level RQ1 remains open for traditional
build/cache. No experiment rerun or paper repair is required for this cell.

### Meta-Review And Ranked Open Objections

1. **Decisive:** the frozen second primary family, traditional build/cache, has
   no admitted current experiment. Until it passes, RQ1 is incomplete and the
   paper cannot advance to milestone acceptance.
2. **Decisive for RQ2:** collected Agent-workspace timings are not an RQ2
   protocol. A fresh same-oracle experiment must specify warmup, repetitions,
   uncertainty, cache-hot/cache-cold handling, and account for the run-2
   clocksource watchdog caveat.
3. **Decisive for RQ3:** the current boundary labels and one missing-target
   control are inputs, not an accepted ownership/containment result. RQ3 needs
   its own source-backed, workload-specific boundary audit and malformed-policy
   controls.
4. **Reproducibility:** future final-result targets should add parent-repository
   HEAD plus dirty-worktree or patch identity to the exact executed-input
   hashes already recorded.
5. **Process/publication:** the repository lacks the optional
   `scripts/check_progress.py` diagnostic, and final workshop publication must
   reconcile the user's PDF commit/push request with the ignored
   `.build/paper/main.pdf` output.

These findings do not justify a skill change: the current gates caught the
runner defects, separated infrastructure failure from scientific evidence,
prevented timing/boundary overclaim, and required independent result and outer
review. The missing progress diagnostic is repository maintenance, not a
workflow-design failure.

### Route

Close step 0004 with one coherent commit and push, then return to
EXPERIMENT_GATE for one exact-RQ1 traditional build/cache experiment. Reuse
legacy Redis/nginx/ccache assets only as implementation inputs; they remain
archived diagnostics until a fresh source-oracle matrix passes plan review,
real KVM execution, result review, targeted paper write, and outer audit.
