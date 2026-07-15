# Round 5: Consistency

Started: 2026-07-15T00:24:00-0700  
Completed: 2026-07-15T00:40:00-0700

Parent step: `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`

## Objective

Check terminology, claim status, architecture/workflow consistency, RQ wording,
design-goal to evidence alignment, and abstract/introduction/body/conclusion
alignment.

## Review Method

Spawned one read-only subagent to invoke `check-terminology-infoflow` in
paper-consistency scope. The subagent did not edit files and reported that the
paper build was up-to-date.

## Raw Findings

Must-fix findings:

- Environment/cache status conflicted across abstract/evaluation, Motivation,
  Discussion, and Implementation because final-file target selection appeared as
  both a primary workload need and future extension.
- Abstract and Conclusion used stronger result-status verbs than Evaluation's
  explicit `Unanswered` and `[Result]` placeholders.
- RQ3's fail-closed claim appeared in Design and prose but not in the main RQ3
  evidence table.
- The reviewer suggested adding a synthesized current-instruction block to
  `docs/user-instruction.md`.

Should-fix findings:

- `SELECT_TARGET`, registered target, directory-target, and final-file wording
  drifted.
- Agent workload source wording drifted between AgentFS-derived and
  AgentFS-style.
- Related Work blurred FUSE and stackable/custom boundaries in the RQ2 paragraph.
- Canonical phase docs still need update to active BOOTSTRAP step 0005.

## Applied Fixes

- Standardized main-paper mechanism terminology to `SELECT_TARGET` over
  kernel-registered lower paths.
- Replaced AgentFS-style wording with AgentFS-derived source oracle where the
  workload source is AgentFS.
- Removed final-file/future-extension wording from the main paper and described
  environment/cache as using `SELECT_TARGET` over kernel-registered lower paths.
- Reworded Abstract and Conclusion so result slots are "structured to answer" or
  "define the evidence needed" rather than claiming to already answer or close
  the RQs.
- Added a fail-closed evidence column to the RQ3 boundary table.
- Kept FUSE as RQ2 cost pressure in Related Work and moved stackable/custom
  responsibility to the RQ3 context.

## Rejected Or Deferred Fixes

- Did not edit `docs/user-instruction.md` with a synthesized "Current fixed
  instructions" block. The orchestrator skill restricts that file to verbatim
  user-authored prompts only. Current fixed instructions are recorded in
  `docs/idea-story.md`, canonical docs, and this step report instead.
- Did not fill result placeholders with final evidence. That belongs to
  BUILD_AND_EVALUATE.
- Deferred canonical phase-doc updates until the writing pass finishes, so they
  can point to the completed step outcome rather than a mid-round state.

## Verification

- `make -C docs/paper paper` succeeded.
- Output PDF: `.build/paper/main.pdf`, 15 pages.
- Grep found no remaining `final-file`, `AgentFS-style`,
  `stackable-filesystem request path`, `registered-target selection`, or
  `directory-target` wording in the paper source.
- Remaining LaTeX warnings are underfull boxes in a compact design table and
  bibliography entries.

## Next Node

Proceed to Round 6 language/sentence-structure review.

