# Iter Refine Writing Round 5: Consistency

Date: 2026-07-10

## Findings

Subagent finding summary:

- The acceptance gate was inconsistent across abstract, evaluation, and
  limitations. The paper needed two explicit claim layers: boundary validity
  and practical value/cost.
- Workload provenance remained too loose because rows used `related`, `or`, and
  `companion` sources where the evaluation needs two source-derived KVM
  transitions.
- The write-leak example needed a bridge to the ABI/action surface so readers
  know create/open path walks are part of lookup events.
- Terminology drifted among `path-object`, `pathname-object`,
  `state-transition path view`, and `object selection and visibility`.
- Action names in Design and Implementation needed an explicit mapping for
  readdir visibility.
- Several scope sentences used defensive `does not claim` phrasing.

## Changes Made

- `docs/paper/main.tex`
  - Reframed the abstract evidence sentence around two claim layers:
    boundary validity and practical value/cost.

- `docs/paper/sections/02-motivation.tex`
  - Changed the workload table to separate selected source, oracle source,
    policy-controlled effects, preserved lower-FS checks, and companion
    motivation.
  - Bound the planned workspace row to AgentFS.
  - Bound the planned W4 row to SWE-Factory-Gym.
  - Moved BranchFS, Sandlock, YoloFS, MEnvData-SWE, and SWE-rebench V2 to
    companion motivation rather than oracle ownership.

- `docs/paper/sections/01-introduction.tex`
  - Made the bounded claim explicitly separate boundary evidence from
    practical value/cost baseline evidence.
  - Changed `pathname-object` to `pathname-to-object`.

- `docs/paper/sections/03-design.tex`
  - Added that visibility is represented by hide or pass-through/expose
    decisions.
  - Added that lookup events include open/create path walks and that
    final-component create may select the branch parent before lower-FS create
    and write semantics run.

- `docs/paper/sections/04-implementation.tex`
  - Added operation context for open/create path walks to the ABI prose.
  - Mapped readdir visibility to hide or pass-through decisions.

- `docs/paper/sections/05-evaluation.tex`
  - Made the acceptance matrix distinguish boundary-validity gates from
    practical value/cost baseline evidence.
  - Replaced defensive baseline wording with neutral scope language.

- `docs/paper/sections/06-related-work.tex`
  - Replaced `path-object policy decision` with `object-selection policy
    decision`.

- `docs/paper/sections/07-limitations.tex`
  - Rewrote defensive non-claim sentences into neutral artifact-boundary
    language.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- The LaTeX log has no overfull boxes, undefined references, or undefined
  citations.
- Fixed-string checks found no `path-object`, `pathname-object`, `does not
  claim`, `do not claim`, `\paragraph{}`, or `\textbf{}`.
- Citation-site count is 12.
- PDF page count is 10.

## Remaining Concerns

- The paper is now internally consistent, but still verbose for a proposal.
  Language rounds should compress without weakening the two-layer claim
  boundary.
