# Round 3: Logic Flow

Started: 2026-07-14T16:53:00-0700
Completed: 2026-07-14T17:00:00-0700
Parent step: `docs/tmp/bootstrap/step-0004-20260714T161834-0700/`
Objective: check whether the paper's argument remains coherent from abstract
through conclusion without changing the fixed scientific contract.

## Inputs

- Paper source after Round 2
- Fixed story: `namei_ext` is a `sched_ext`-style VFS name-resolution
  extension point between eBPF LSM and FUSE/custom filesystem ownership.
- Fixed contribution: design plus Linux implementation as one systems boundary.
- Fixed RQs: expressiveness/sufficiency, cost versus feature-equivalent FUSE,
  and verifier-bounded fail-closed boundary versus custom/stackable
  filesystems.

## Raw Review Findings

Read-only reviewer: subagent `019f6302-1a70-7b61-a09b-fb7d78f06dc7`.

Must-fix:

- None. The reviewer found no new blocking logic-flow issue.

Should-fix:

- Add an explicit bridge explaining that environment/cache remains a primary
  target even though final-file target support gates evidence.
- Rephrase the RQ2 closure so it characterizes cost and support for the
  boundary claim, rather than treating RQ2 as a binary benchmark contest.
- Make RQ3 boundary evidence require source-to-responsibility rows that name
  methods and state owned by source/custom/stackable boundaries.
- Keep the current conclusion's draft-status language for now, but replace it
  with real RQ answers after experiments.

## Applied Fixes

- Added an RQ1 bridge sentence: the environment/cache matrix remains a primary
  target of the hypothesis, but is not reported as evidence until final-file
  target selection is implemented and reviewed.
- Rephrased the RQ2 closure to say lower lookup/readdir placement cost supports
  the boundary claim, while comparable/lower FUSE cost weakens it.
- Added a `Source responsibility map` row to the RQ3 evidence table requiring
  per-source rows for lookup/readdir-only policy, create/unlink/rename,
  daemon/runtime state, COW/checkpoint, data path, and metadata persistence
  where applicable.

Skipped or deferred:

- Did not rewrite the conclusion with final answers because no final reviewed
  RQ evidence exists yet.
- Did not change the hypothesis or remove environment/cache from the primary
  workload set.

## Verification

Commands:

```text
make -C docs/paper paper
pdfinfo .build/paper/main.pdf | rg '^Pages|^Creator|^Producer'
rg -n 'undefined|Citation .* undefined|There were undefined references|Overfull' .build/paper/main.log
rg -n 'environment/cache matrix remains|RQ2 supports|Source responsibility map|organized to fill' docs/paper/sections/05-evaluation.tex docs/paper/sections/08-conclusion.tex
```

Results:

- Build succeeded.
- PDF page count: 15.
- No undefined references, undefined citations, or overfull boxes were present
  in the final log.
- The RQ1/RQ2/RQ3 logic-flow bridges are present.

## Preservation Check

The core argument still flows from missing VFS name-resolution boundary to a
bounded eBPF extension point, lower-filesystem ownership, and RQ evidence slots.
No table-only or materialized-view novelty line was introduced. Prototype gaps
remain evidence gaps, not reasons to weaken the hypothesis.

Next round: Round 4 abstract/introduction rebuild.
