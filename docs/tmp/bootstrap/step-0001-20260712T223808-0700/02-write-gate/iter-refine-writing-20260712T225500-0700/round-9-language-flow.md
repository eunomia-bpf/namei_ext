# Round 9: Language Flow And Polish

Started: 2026-07-12T23:52:30-07:00
Completed: 2026-07-12T23:57:00-07:00
Cycle: BOOTSTRAP step 0001
Gate: 02-write-gate
Parent node: `docs/tmp/bootstrap/step-0001-20260712T223808-0700/02-write-gate/000-gate-entry-20260712T225200-0700.md`

## Objective

Run Round 9 of `iter-refine-writing`: topic position, stress position,
old-to-new information flow, paragraph transitions, and register consistency.
The round is writing-only and must preserve the three fixed RQs and the
accepted story.

## Inputs Read

- `docs/user-instruction.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/tmp/bootstrap/step-0001-20260712T223808-0700/step-report.md`

## Method

A read-only subagent invoked `paper-writing-style` focused on flow and polish.
The main agent applied all Must-fix and Should-fix findings and accepted the
Consider findings that made the paper more submission-shaped without inventing
final data.

## Raw Subagent Findings

Must-fix findings:

- `sections/06-related-work.tex`: a broken sentence read `\namei A
  service/config row...`.
- `sections/03-design.tex`: four short negative sentences made the boundary
  read like a limitation checklist.
- `sections/05-evaluation.tex`: RQ2 repeated the same FUSE point three times.

Should-fix findings:

- `main.tex`: abstract ended in project-plan wording.
- `sections/01-introduction.tex`: “useful only if” was defensive.
- `sections/02-motivation.tex`: two consecutive “These observations...”
  transitions were mechanical.
- `sections/02-motivation.tex`: “therefore stays small” sounded like scope
  shrinkage.
- `sections/04-implementation.tex`: “The next subsection separates...” was weak
  paper-internal navigation.
- `sections/05-evaluation.tex`: the RQ1 paragraph repeated the admission
  process from setup.
- `sections/06-related-work.tex`: the FUSE paragraph repeated service/request
  path wording.

Consider findings:

- Replace “These design choices lead...” with a boundary-following transition.
- Replace “Evidence slot for final runs” with “Final-run evidence
  requirements.”
- End the conclusion on the boundary claim rather than testability.

## Applied Fixes

All Must-fix items were accepted.

- Removed the stray `\namei` token before the service/config row sentence in
  Related Work.
- Compressed the Boundary subsection into one positive boundary sentence about
  what remains outside the hook.
- Rewrote RQ2 to compare \namei with a feature-equivalent FUSE policy service
  under the same source oracle and isolate request-path cost once.

All Should-fix items were accepted.

- Rewrote the abstract ending to ask whether the boundary satisfies
  source-derived oracles, avoids FUSE request-path cost, and reduces ownership
  compared with custom or stackable filesystems.
- Replaced defensive introduction phrasing with “This separation creates three
  requirements.”
- Consolidated Motivation transitions so the comparison rule flows into Design
  and Evaluation.
- Replaced “therefore stays small” with “This filter yields two primary
  representative workloads.”
- Replaced paper-internal implementation navigation with a direct statement
  about directory-target and final-file target support.
- Removed repeated workload-inclusion process from the RQ1 opening.
- Compressed the FUSE related-work paragraph.

All Consider items were accepted.

- Changed the Evaluation transition after the mechanism paragraph.
- Renamed evidence slot labels to “Final-run evidence requirements.”
- Rewrote the conclusion to end on the path-view boundary claim.

## Rejected Fixes

No subagent finding was rejected. The final-run evidence requirement paragraphs
remain because the BOOTSTRAP paper must not invent final data.

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

Citation preservation:

```text
rg -o '\\cite[t|p]?\\{[^}]+\\}' docs/paper/main.tex docs/paper/sections | wc -l
28
```

Targeted scan:

```text
rg -n ': |;|\\namei A|Evidence slot|Status:|BOOTSTRAP|TODO|prototype matrix|generic claim|makes \\code\\{sched_ext\\} useful|out of scope by design|would evaluate whether|These design choices lead|useful only if|therefore stays small|The next subsection' docs/paper/main.tex docs/paper/sections
```

Result: no broken sentences or project-status phrases remain. Remaining
punctuation hits are section titles or table cells.

## User-Instruction Check

The fixes preserve the active user instructions. The story remains stronger and
submission-shaped, not a table-only counterexample paper. RQ2 remains a FUSE
comparison, and RQ3 remains a custom/stackable filesystem safety and ownership
boundary.

## Remaining Concerns

Round 10 must complete the citation gate. Preflight during this round found
that `refs.bib` entries appear to have the required annotation fields and no
`REAL: unverified` entries, so Round 10 should run the missing-citation pass
unless a second check finds missing annotations.

## Next Node

Proceed to Round 10: citation gate.
