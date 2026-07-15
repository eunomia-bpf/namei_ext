# Round 11: Meaning Preservation And Final Drift Audit

Date: 2026-07-14

## Scope

This round performed the final meaning-preservation audit for the
`iter-refine-writing` WRITE_GATE pass. The audit compared the current paper
against the reviewed direction from the preceding rounds and against the
repository baseline where possible.

The expected `entry-snapshot/` directory was not present in this run directory.
As a fallback, the audit used `git show HEAD:docs/paper/...` for the paper
baseline and the Round 0--10 reports in this directory for the accepted
writing direction. This fallback is weaker than a complete entry snapshot and
is recorded as residual process risk.

## Findings

The audit found two must-fix drift points:

1. The abstract and evaluation language still risked presenting
   environment/cache file-object evidence as already covered, even though that
   evidence requires final-file target selection.
2. The evaluation setup risked changing RQ3 from an ownership-boundary account
   into an executed custom/stackable correctness row. The intended RQ3 evidence
   is a same-oracle boundary comparison of responsibilities and containment,
   not a claim that every custom or stackable filesystem row is executed.

The audit also found two smaller terminology mismatches:

1. The introduction said `custom-filesystem comparisons` where the accepted
   story requires `custom/stackable-filesystem comparisons`.
2. The environment/cache comparison used wording that sounded like a completed
   cache ownership table rather than an ownership-boundary account.

## Fixes Applied

The abstract now keeps environment/cache as a source of correctness oracles but
explicitly gates file-object evidence on final-file target selection.

The evaluation setup now says that same-oracle mechanism comparisons require
the executed `namei_ext` and feature-equivalent FUSE rows to pass the same
source condition. RQ3 boundary accounts use the same oracle to compare
responsibilities and containment, rather than claiming an executed
custom/stackable correctness row.

The environment/cache matrix row now labels final-file target selection as
required for file-object evidence and describes the RQ3 comparison as a
source-native and custom/stackable ownership-boundary account.

The introduction and conclusion now use `custom/stackable` terminology and
carry the final-file target selection qualifier where environment/cache
file-object evidence is mentioned.

## Validation

Commands run:

```text
make -C docs/paper paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages'
perl -0ne '...' docs/paper/main.tex
rg -n 'undefined|Citation .* undefined|There were undefined references|LaTeX Warning' .build/paper/main.log
rg -n 'custom-boundary rows to pass|custom/stackable cache ownership table|custom-filesystem comparisons|environment/cache systems to ask|environment/cache oracles to test|Rows that require final-file target selection are outside' docs/paper/main.tex docs/paper/sections -g '*.tex'
```

Results:

- `make -C docs/paper paper` succeeded and regenerated
  `.build/paper/main.pdf`.
- The generated PDF has 15 pages.
- The abstract has 240 words.
- No undefined citations or undefined references were reported.
- The targeted drift phrases were absent after the final fix.
- Remaining LaTeX output is limited to existing font/underfull-box warnings,
  not citation or build failures.

## Residual Risks

The paper is structurally reorganized, but the final evidence is still not
complete. Environment/cache file-object evidence remains gated on final-file
target selection. Final KVM same-oracle runs, feature-equivalent FUSE overhead
rows, and reviewed RQ3 boundary accounts are still needed before the paper can
answer the RQs with results.

The paper is also 15 pages in the current `article` layout and will need venue
formatting and compression after the results are fixed.
