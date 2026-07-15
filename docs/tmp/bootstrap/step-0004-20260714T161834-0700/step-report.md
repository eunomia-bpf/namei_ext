# BOOTSTRAP Step 0004 Report

Timestamp: 2026-07-14T16:18:34-0700
Phase: BOOTSTRAP
Status: complete
Current gate: REVIEW_GATE complete; frozen route to BUILD_AND_EVALUATE

## Step Objective

Re-enter BOOTSTRAP under the user's renewed instruction:

```text
按照新的 skills 重新回到 BOOTSTRAP 阶段, 重新整理完善论文
```

This step starts after BOOTSTRAP step 0003 had already recorded a renewed
BUILD_AND_EVALUATE route. The renewed instruction makes that route historical
until this step finishes. The objective is to make the paper and canonical
documents consistently express the strongest current story before any
experiment continuation:

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point;
- the contribution is the design and Linux implementation of that extension
  point as one systems boundary;
- RQ1 is expressiveness/sufficiency;
- RQ2 is overhead versus feature-equivalent FUSE;
- RQ3 is a verifier-bounded, fail-closed ownership boundary versus custom or
  stackable filesystem ownership;
- Agent workspace and environment/cache are the two primary complete
  experiment families, with service/config conditional;
- table-only, materialized-view shootouts, and scattered baseline catalogs are
  historical diagnostics or related-work context, not the novelty line.

## Gate Entry And Instruction Alignment

Inputs read at entry:

- `auto-research-orchestrator/SKILL.md`;
- `auto-research-orchestrator/references/hierarchical-research-state-machine.md`;
- `iter-refine-writing/SKILL.md`, because BOOTSTRAP WRITE gates require it;
- `docs/user-instruction.md`;
- `docs/questions-for-author.md`;
- `docs/idea-story.md`;
- `docs/evaluation.md`;
- `docs/design.md`;
- `docs/implementation.md`;
- `docs/background-related-work.md`;
- `research/STATE.md`;
- `docs/tmp/bootstrap/step-0003-20260714T155854-0700/step-report.md`;
- `docs/tmp/bootstrap/step-0003-20260714T155854-0700/outer-audit-20260714T160549-0700.md`;
- `docs/paper/main.tex` and `docs/paper/sections/*.tex`.

Instruction alignment: `docs/user-instruction.md` contains the renewed
BOOTSTRAP request and the fixed scientific constraints. The cleanup below does
not edit skills, does not reopen table-only proof work, does not add fragmented
baselines, and does not shrink the hypothesis around current prototype gaps.

## EXPERIMENT_GATE

Skipped in this partial root-cleanup step.

Entry condition checked: BOOTSTRAP EXPERIMENT_GATE would rerun
literature/novelty pressure if the central position or RQ set changed. This
node did not change the scientific position, RQs, workload families, comparison
families, or evaluation promise. It only corrected phase drift and evidence
promise ambiguity introduced by the renewed user instruction.

Evidence checked:

- `docs/idea-story.md` still preserves the `sched_ext`-style VFS
  name-resolution story;
- `docs/background-related-work.md` still identifies FUSE as the RQ2 baseline
  and custom/stackable filesystems as the RQ3 boundary comparison;
- `docs/evaluation.md` still has two primary complete experiments and one
  conditional service/config experiment.

Decision: no new literature node in this cleanup pass. A full BOOTSTRAP
EXPERIMENT_GATE remains required if later review finds a real story/RQ change.

## WRITE_GATE

Status: completed full `iter-refine-writing` run after initial root cleanup.

Question: do the current paper and canonical documents still claim an active
BUILD_AND_EVALUATE freeze after the user explicitly asked to return to
BOOTSTRAP?

Result: yes, before this cleanup. `docs/idea-story.md`, `docs/evaluation.md`,
`docs/design.md`, `docs/implementation.md`, and `research/STATE.md` all pointed
to active or frozen BUILD_AND_EVALUATE routing. That conflicted with the newest
instruction.

Edits applied:

- `docs/idea-story.md`: changed the current phase to BOOTSTRAP step 0004,
  recorded step 0003 as historical, and appended evolution rows for the new
  re-entry.
- `docs/evaluation.md`: changed the evaluation plan from a frozen
  BUILD_AND_EVALUATE promise to a BOOTSTRAP candidate promise while preserving
  the RQ meanings and complete experiment families.
- `docs/design.md`: changed the design from an active frozen contract to a
  BOOTSTRAP candidate and renamed proof obligations accordingly.
- `docs/implementation.md`: changed phase routing to BOOTSTRAP candidate and
  explicitly recorded final-file target selection as an implementation gap to
  close, not a reason to shrink environment/cache.
- `docs/background-related-work.md`: updated the novelty frontier and next
  action to step 0004.
- `docs/questions-for-author.md`: updated the default action pointer to step
  0004.
- `research/STATE.md`: changed the handoff pointer from active
  BUILD_AND_EVALUATE step 0003 to active BOOTSTRAP step 0004, preserving
  BUILD_AND_EVALUATE step 0003 as paused work.
- `docs/paper/sections/05-evaluation.tex`: added that the unit of evidence is
  a complete source-oracle matrix, not a catalog of one-off baselines or smoke
  tests.
- `docs/paper/evaluation.md`: updated the paper-directory routing note to the
  BOOTSTRAP step 0004 draft.

Full `iter-refine-writing` pass:

- Run directory:
  `docs/tmp/bootstrap/step-0004-20260714T161834-0700/iter-refine-writing-20260714T162746-0700/`.
- Entry snapshot captured `docs/paper/main.tex`, `docs/paper/refs.bib`, and
  `docs/paper/sections/*.tex` before Round 0.
- Rounds 0 through 11 completed: macro structure, micro structure, section
  conventions, logic flow, abstract/intro rebuild, consistency, sentence
  structure, word choice, terminology/claim tone, flow/polish, citation gate,
  and meaning-preservation audit.
- The Evaluation section now has paper-facing result slots for RQ1, RQ2, and
  RQ3 instead of protocol-only prose.
- Round 10 citation verification passed after fixing missing `year` fields for
  `linux_fuse_passthrough` and `fuse_bpf_patch`, and after adding
  ConfigMap/Secrets citations to the first service/config mention.
- Round 11 restored two pieces of technical content lost during rewriting:
  Agent workspace `whiteout/hide` oracle detail, and RQ3 `state
  responsibility`, `privileged code surface`, and `policy code size`.

Documentation condensation:

- `research/STATE.md` was shortened from a long source-reproduction inventory
  to an 85-line handoff pointer.
- Condensation record:
  `docs/tmp/bootstrap/step-0004-20260714T161834-0700/2026-07-14-research-state-handoff-condensation.md`.
- The detailed source inventory remains owned by
  `docs/reference/CODE_SOURCES.md`, `docs/background-related-work.md`,
  `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md`, and dated
  `docs/tmp/YYYY-MM-DD-*.md` reproduction records.

Rejected actions:

- Did not resume Experiment A implementation, because the current instruction
  is paper/BOOTSTRAP convergence.
- Did not claim the step is frozen after the writing pass. A fresh outer audit
  remains required.
- Did not edit the current skills.
- Did not perform Git mutation.

## Verification

Commands run:

```text
rg -n 'Current phase: BUILD_AND_EVALUATE|Orchestrator phase: BUILD_AND_EVALUATE|Current status: frozen BUILD_AND_EVALUATE|Current active BUILD_AND_EVALUATE|frozen evaluation promise|frozen BUILD_AND_EVALUATE' docs/idea-story.md docs/evaluation.md docs/design.md docs/implementation.md docs/background-related-work.md docs/questions-for-author.md research/STATE.md docs/paper
rg -n 'table-only|static table|table_redirect|materialized-view shootout|scattered-baseline|two primary contributions' docs/paper docs/idea-story.md docs/evaluation.md docs/design.md docs/implementation.md docs/background-related-work.md research/STATE.md
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages|^Title|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
rg -n 'Evidence TODO|Unanswered|current draft|lower-FS' docs/paper/main.tex docs/paper/sections
```

Results:

- Stale active-phase scan found only historical narrative rows in
  `docs/idea-story.md`, not current active-state claims.
- Table/static-table scan found only guardrail or rejected-path records, not
  current paper novelty or evaluation mainline text.
- `make -C docs/paper paper` succeeded.
- `.build/paper/main.pdf` has 16 pages after the full writing pass.
- The LaTeX log has no undefined citation/reference, multiply-defined label,
  overfull-box, or targeted LaTeX warning.
- Citation verifier checked 35 active entries and reported 0 errors and 0
  warnings.
- `docs/paper/refs.bib` has complete annotation coverage for all 61 entries:
  `VERIFIED`, `REAL`, `PDF`, `ABSTRACT`, and `USED_FOR`.
- Stale project-status prose such as `Evidence TODO`, `Unanswered`, `current
  draft`, and `lower-FS` no longer appears in paper text.

Final verification after the fresh audit:

```text
make -C docs/paper paper
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
pdfinfo .build/paper/main.pdf | rg '^Pages|^Title|^Creator|^Producer'
rg -n 'Citation .* undefined|Reference .* undefined|undefined references|Undefined control sequence|multiply defined|Overfull|LaTeX Warning' .build/paper/main.log
rg -n 'Current phase: BOOTSTRAP|Current status: active BOOTSTRAP|Orchestrator phase: BOOTSTRAP|fresh outer audit required|fresh outer BOOTSTRAP audit is still required|Status: in progress|Current gate: REVIEW_GATE fresh' ...
```

Results:

- paper build still succeeds and `.build/paper/main.pdf` remains 16 pages;
- citation verifier still reports 0 errors and 0 warnings for 35 active
  entries;
- targeted LaTeX log scan has no hits;
- current-state scan has no stale active BOOTSTRAP candidate or fresh-audit
  pending claims;
- `lower-FS` now appears only in audit/report text describing an already-fixed
  issue, not in current canonical docs or paper text;
- `scripts/check_progress.py` is absent in this repository, so no progress
  diagnostic output was available for this meta-review. This did not block the
  step because the fresh outer audit independently checked direction,
  efficiency, maintenance, and route.

## REVIEW_GATE

Status: completed.

Outer audit:
`docs/tmp/bootstrap/step-0004-20260714T161834-0700/outer-audit-20260714T162658-0700.md`

The independent audit accepted the story/RQ/contribution direction but found
two must-fix issues:

- step 0004 cannot freeze because BOOTSTRAP WRITE_GATE requires a full
  `iter-refine-writing` pass, while this step had only performed root cleanup;
- the Evaluation section is still protocol-shaped and needs explicit missing
  result slots for RQ1, RQ2, and RQ3.

It also found that `research/STATE.md` is too long for a handoff pointer and
should be shortened after its source-reproduction inventory is archived or
confirmed in canonical source records.

Root disposition: accepted all findings. The full writing pass is now complete,
explicit RQ result slots have been added, and `research/STATE.md` has been
condensed into a handoff pointer.

Fresh outer audit:

- Reviewer: independent read-only subagent
  `019f6325-056e-7233-95d4-9a89a3dee65e`.
- Timestamp recorded in the outer-audit report:
  2026-07-14T17:23:53-0700.
- Verdict: BOOTSTRAP step 0004 can freeze.
- Must-fix findings: none.
- Direction: correct; the paper and canonical docs preserve the
  `sched_ext`-style VFS name-resolution extension-point story, fixed RQs, and
  design-plus-Linux-implementation contribution without shrinking the
  hypothesis around prototype gaps.
- Efficiency: correct; step 0004 completed the required writing loop, added RQ
  result slots, and did not reopen table-only/static-table/materialized-view
  side experiments.
- Maintenance: `research/STATE.md` is now appropriately condensed and no new
  durable `AGENTS.md` rule or repo-local skill is justified.

Should-fix disposition: accepted and fixed. Canonical docs now use
`lower-filesystem` instead of `lower-FS`, and `docs/implementation.md` no
longer describes `make experiments` as owning a frozen program while the
project is in BOOTSTRAP. `docs/paper/evaluation.md` now identifies itself as a
companion note for the frozen BUILD_AND_EVALUATE paper draft. The 16-page paper
length is recorded as a future writing risk, not a BOOTSTRAP blocker.

Scientific-contract audit: freeze the current contract again for
BUILD_AND_EVALUATE. The frozen story is `namei_ext` as a `sched_ext`-style VFS
name-resolution extension point between eBPF LSM and FUSE/custom filesystem
ownership. The contribution is the design and Linux implementation of this
extension point as one systems boundary. RQ1 is expressiveness/sufficiency, RQ2
is cost versus feature-equivalent FUSE, and RQ3 is safety/boundary versus
custom or stackable filesystem ownership.

## Current Routing

Step 0004 is complete. Route to BUILD_AND_EVALUATE.

The next action is the complete Agent workspace lifecycle experiment. It must
use the real KVM `cgroup/namei_ext` attach path, source-derived same-oracle
`namei_ext` and feature-equivalent FUSE rows, lower-filesystem preservation
checks, operation-weighted lookup/readdir traces, raw results under `results/`,
and RQ3 custom/stackable filesystem boundary evidence. Environment/cache
remains the second primary experiment after final-file target support.

## Git Publication

No Git mutation has been performed in this step. The worktree remains dirty
with many historical and current files; repository policy requires explicit
user authorization plus status/diff inspection before staging, committing, or
pushing.
