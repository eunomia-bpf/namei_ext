# Round 7: Language Word Choice

Started: 2026-07-12T23:36:00-07:00
Completed: 2026-07-12T23:43:00-07:00
Cycle: BOOTSTRAP step 0001
Gate: 02-write-gate
Parent node: `docs/tmp/bootstrap/step-0001-20260712T223808-0700/02-write-gate/000-gate-entry-20260712T225200-0700.md`

## Objective

Run Round 7 of `iter-refine-writing`: word choice, jargon inflation, vague
referents, nominalizations, redundant hedging, and verbose phrases. The round
is writing-only. RQ meaning, contribution scope, baseline families, and
BOOTSTRAP evidence placeholders are read-only.

## Inputs Read

- `docs/user-instruction.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/tmp/bootstrap/step-0001-20260712T223808-0700/step-report.md`

## Method

A read-only subagent reviewed the complete paper with `paper-writing-style`
focused on word choice. The main agent applied fixes subsection by subsection,
accepted all Must-fix and Should-fix findings, accepted all Consider findings
that improved clarity without changing scientific meaning, then compiled the
paper.

## Raw Subagent Findings

Must-fix findings:

- `sections/01-introduction.tex`: “The structural cause is that workload state
  changes the right pathname-to-object relation...” was jargon-heavy.
- `sections/03-design.tex`: “The boundary is a strength only when the source
  transition fits it” used vague referents.
- `sections/08-conclusion.tex`: “Together, these pieces” had a vague referent.

Should-fix findings:

- `main.tex`: abstract opening stacked “agent, build, and service systems,”
  “task-specific filesystem views,” “pathname binding risk,” and
  “lower-filesystem responsibilities.”
- `sections/02-motivation.tex`: source evidence sentence read like process
  inventory.
- `sections/02-motivation.tex`: epoch list piled abstract nouns.
- `sections/03-design.tex`: “subsystem ownership” and “subsystem machinery”
  were vague.
- `sections/05-evaluation.tex`: “direct programmable-filesystem-service
  comparison” was a compound pileup.
- `sections/06-related-work.tex`: “Agent-filesystem systems” was awkward.

Consider findings:

- `sections/04-implementation.tex`: “The final validation path connects...”
  sounded like a checklist.
- `sections/05-evaluation.tex`: “workload admission evidence” was bureaucratic.
- `sections/07-limitations.tex`: “Use \namei only when...” was imperative.

## Applied Fixes

All Must-fix items were accepted.

- Replaced the abstract and introduction wording around “pathname binding
  risk” with the concrete risk of binding a pathname to the wrong lower object.
- Replaced the design boundary sentence with an explicit lookup-selection and
  directory-visibility boundary.
- Replaced the conclusion’s vague “these pieces” with “the characterization,
  mechanism, and evaluation contract.”

All Should-fix items were accepted.

- Split the abstract opening into shorter sentences.
- Rewrote source-evidence wording around evidence strength.
- Replaced the epoch noun pile with “each workload carries its own state.”
- Rewrote the `sched_ext` analogy around BPF policy and kernel/VFS ownership.
- Rewrote the FUSE comparison as “places equivalent policy in a filesystem
  service.”
- Replaced “Agent-filesystem systems” with “Agent filesystems.”

All Consider items were accepted because they made the BOOTSTRAP draft less
checklist-like and more reviewer-facing.

- Rewrote final validation as a requirement for final reviewed runs.
- Replaced “workload admission evidence” with “Source characterization decides
  which workloads are eligible for evaluation.”
- Replaced imperative limitation wording with intended-use wording.

## Rejected Fixes

No subagent finding was rejected. No RQ, contribution, workload family, baseline
family, mechanism claim, citation, or quantitative value was changed.

## Verification

Compilation:

```text
make -B -C docs/paper
```

Result: pass.

PDF page count:

```text
Pages: 14
```

Targeted scan:

```text
rg -n 'pathname binding risk|structural cause|boundary is a strength|Together, these pieces|Agent-filesystem|programmable-filesystem-service|Use \\namei only|source characterization as workload admission evidence|fixed hook cost from policy cost;' docs/paper/main.tex docs/paper/sections
```

Result: no matches after the final introduction cleanup.

Citation preservation: no citation commands were removed.

## User-Instruction Check

The edits preserve the active user direction: stronger story, no table-only
mainline, RQ2 versus FUSE, RQ3 as the custom/stackable filesystem boundary, and
`namei_ext` as a `sched_ext`-style VFS extension point between namespace
materialization/eBPF LSM and FUSE/custom filesystems.

## Remaining Concerns

The paper remains a BOOTSTRAP draft with explicit evidence placeholders. The
language is clearer, but Round 8 must still check terminology stability and
claim tone.

## Next Node

Proceed to Round 8: terminology and claim tone.
