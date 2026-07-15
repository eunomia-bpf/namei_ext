# Research State Handoff Condensation

## Motivation

The first BOOTSTRAP step-0004 outer audit found that `research/STATE.md` was too
long for a handoff pointer because it embedded a detailed source-reproduction
inventory. That duplicated canonical source records and made the current routing
hard to find.

The user also asked to converge documents according to the skills layout. For
this project, `research/STATE.md` should point to canonical records rather than
own related-work, novelty, source-use, workload-selection, or result verdicts.

## Files Inspected

- `research/STATE.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/background-related-work.md`
- `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md`
- `docs/tmp/bootstrap/step-0004-20260714T161834-0700/step-report.md`
- `docs/tmp/bootstrap/step-0004-20260714T161834-0700/iter-refine-writing-20260714T162746-0700/round-*.md`

## Design Choice

The long source-reproduction inventory was removed from `research/STATE.md` and
replaced with pointers to the canonical records:

- `docs/reference/CODE_SOURCES.md` owns repository/artifact links and dated
  evidence-record indexing.
- `docs/background-related-work.md` owns related-work, novelty risk,
  comparison roles, workload-source verdicts, and source-use conclusions.
- `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md` owns the
  consolidated workload reuse decision.
- Individual dated `docs/tmp/YYYY-MM-DD-*.md` files own reproduction details,
  commands, caveats, and raw-result roots.

This preserves prior measurements, caveats, and reproduction status while
returning `research/STATE.md` to a compact handoff pointer.

## Validation

Before condensation, the source inventory was checked against the canonical
records with `rg` over `docs/background-related-work.md`,
`docs/reference/CODE_SOURCES.md`, and
`docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md`. The checked
records include the source families previously listed in `research/STATE.md`:
AgentFS, Redis AFS, Mirage, YoloFS, BranchFS, Sandlock, OpenHands, SWE-agent,
SWE-ReX, SWE-rebench V2, SWE-Factory-Gym, MEnvData-SWE, DockSmith,
Multi-Docker-Eval, Terminal-Bench, DeltaFS, IndexFS, and TableFS.
