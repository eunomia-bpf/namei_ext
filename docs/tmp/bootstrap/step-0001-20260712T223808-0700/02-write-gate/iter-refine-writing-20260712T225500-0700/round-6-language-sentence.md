# Round 6 Language: Sentence Structure

Started: 2026-07-12T23:31:00-0700  
Completed: 2026-07-12T23:35:11-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-5-consistency  
Status: completed

## Question And Entry

This round checked sentence-level mechanics without changing claims, RQs,
scope, or evidence status. BOOTSTRAP placeholders were protected.

## Inputs And Method

A read-only reviewer invoked `paper-writing-style` with focus on sentence
structure and read the current paper under `docs/paper/`.

The main agent also read `paper-writing-style/SKILL.md` and applied the
reported fixes directly.

## Raw Review Findings

Must-fix:

- Several semicolons joined independent clauses.
- Several colons introduced explanations or unlabeled lists.
- Introduction used the awkward phrasing "it is which existing object..."

Should-fix:

- Motivation used a colon in "The evidence status matters: ..."
- Several sentences started with vague "This ..." subjects.
- Implementation's prototype coverage paragraph packed implemented coverage,
  unsupported operations, and future evidence into one long chain.
- Related Work had a long projected-volume sentence that mixed the condition
  and consequence.

Consider:

- Split one abstract sentence that stacked source families, conditional
  service/config breadth, and boundary separation.
- Smooth the conclusion's prototype sentence.

## Applied Fixes

`docs/paper/main.tex`:

- Split the abstract source-characterization sentence into source-family and
  boundary-separation sentences.

`docs/paper/sections/01-introduction.tex`:

- Replaced the semicolon and awkward phrase with "Instead, the needed change is
  choosing which existing object a name denotes..."
- Removed the colon after the BOOTSTRAP contribution lead-in.

`docs/paper/sections/02-background.tex`:

- Replaced the explanatory colon in the `sched_ext` analogy with two sentences.

`docs/paper/sections/02-motivation.tex`:

- Rewrote the evidence-status sentence without a colon.
- Replaced "This implies" with an explicit subject.
- Split the service/config deferred-status sentence.

`docs/paper/sections/03-design.tex`:

- Rewrote the "The hook is narrow:" sentence with "because."
- Replaced an explanatory colon in the goal mapping paragraph.
- Rewrote the policy-output colon sentence as a direct verb list.
- Replaced "This boundary" with "The boundary."

`docs/paper/sections/04-implementation.tex`:

- Split the registered directory-target support sentence.
- Split prototype coverage into supported and fail-closed sentences.
- Replaced "This choice" with an explicit subject.

`docs/paper/sections/05-evaluation.tex`:

- Rewrote the RQ3 custom-filesystem comparison to avoid a semicolon.

`docs/paper/sections/06-related-work.tex`:

- Replaced the access-control hook explanatory colon with two sentences.
- Split the source-oracle conditional sentence for service/config.

`docs/paper/sections/07-limitations.tex`:

- Replaced the deployment-model colon with two sentences.

`docs/paper/sections/08-conclusion.tex`:

- Split the conditional service/config sentence.
- Smoothed the prototype sentence.
- Replaced a colon before the final claim sentence.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n ';|: [a-z]|\\bIt is\\b|\\bThere are\\b|\\bThis implies\\b|\\bThis choice\\b|\\bThis boundary\\b|same-oracle evaluation planning make' docs/paper/main.tex docs/paper/sections/*.tex
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF remains 14 pages.
- Remaining semicolon/colon scan hits are table cells, paragraph labels, or
  expected LaTeX/reporting contexts rather than narrative sentence violations.

## Scientific Impact And Decision

Round 6 did not change the scientific contract. It made the opening,
Motivation, Design, Implementation, Evaluation, Related Work, Discussion, and
Conclusion more readable while preserving BOOTSTRAP status and the three RQs.

## Completion And Next Action

Round 6 completed. Next node: Round 7 language word choice. The next reviewer
should check jargon inflation, nominalizations, vague referents, redundant
hedging, and verbose phrases.
