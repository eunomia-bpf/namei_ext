# Round 11: Meaning-Preservation Audit

Started: 2026-07-15T02:04:59-0700
Completed: 2026-07-15T02:11:37-0700

## Scope

This final `iter-refine-writing` round compared the entry snapshot under
`entry-snapshot/` with the current paper under `docs/paper/`. The audit was
read-only and allowed only restoration of cumulative meaning drift. It did not
introduce new polish or new scientific claims.

The protected scientific contract was:

- RQ1: expressiveness/sufficiency for real state-dependent path-view policies;
- RQ2: cost/overhead versus feature-equivalent FUSE;
- RQ3: safety and ownership boundary versus custom or stackable filesystem
  ownership;
- contribution: design plus Linux implementation of a `sched_ext`-style VFS
  name-resolution extension point.

## Initial Audit Findings

The read-only audit reported two Must-fix items:

1. `sections/05-evaluation.tex` had lost measurement-protocol fields from the
   entry snapshot: hardware/filesystem configuration, run count, warmup rule,
   confidence-interval method, cache-hot/cache-cold protocol, and the definition
   of operation-weighted metrics. It also lost pass-through/action-specific
   overhead and matched action mix from the RQ2 metric contract.
2. `sections/05-evaluation.tex` had lost the RQ3 evidence requirement that
   per-source rows report privileged code surface and policy code size.

The audit also reported two Should-fix items:

- restore page-cache preservation in the RQ3 lower-filesystem responsibility
  text;
- restore the conclusion's lookup/readdir evaluation triad.

It reported one Consider item:

- restore concrete workload-family anchoring in the abstract.

## Restorations Applied

Applied restorations:

- `docs/paper/sections/05-evaluation.tex`: restored operation-weighted metric
  definition and the final-run measurement protocol fields.
- `docs/paper/sections/05-evaluation.tex`: restored RQ2 metric contract fields
  for pass-through overhead, action-specific overhead, cache-hot/cache-cold
  behavior, operation-weighted invocation rate, matched action mix, and FUSE
  daemon/request-path cost.
- `docs/paper/sections/05-evaluation.tex`: restored page-cache preservation in
  RQ3 lower-filesystem responsibility cells.
- `docs/paper/sections/05-evaluation.tex`: restored RQ3 ownership-table
  requirements for owned filesystem methods, state responsibility, privileged
  code surface, and policy code size with source evidence.
- `docs/paper/sections/08-conclusion.tex`: restored the conclusion's
  lookup/readdir evaluation triad: expressiveness, FUSE placement cost, and
  ownership/containment versus custom or stackable filesystems.
- `docs/paper/main.tex`: restored abstract anchoring for agent/workspace and
  environment/cache workload families, plus the service/config conditional
  scope qualifier.

## Confirmation Audit

The same read-only audit agent reran the Round 11 check after restoration and
reported:

- previous measurement protocol / RQ2 metric contract Must-fix: resolved;
- previous RQ3 privileged code surface / policy code size Must-fix: resolved;
- previous page-cache Should-fix: resolved;
- previous conclusion Should-fix: resolved;
- no remaining Must-fix;
- no remaining Should-fix;
- the remaining abstract conditional-scope Consider was addressed by restoring
  the service/config qualifier.

## Verification

Commands:

```text
make -C docs/paper clean paper
make -C docs/paper paper
rg -n 'undefined references|Citation `|Reference `|There were undefined|Overfull|LaTeX Error|!' .build/paper/main.log .build/paper/main.blg
pdfinfo .build/paper/main.pdf
```

Results:

- paper builds successfully;
- generated PDF: `.build/paper/main.pdf`;
- page count: 15;
- no undefined citation/reference warning found in the final log check;
- no LaTeX error or overfull box found in the final log check;
- remaining build warnings are underfull boxes and CJK font-script warnings.

## Gate Result

Passed. No unrestored meaning drift remains from the step-0005 entry snapshot.
