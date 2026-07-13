# Iter Refine Writing Round 2: Section Conventions

Date: 2026-07-10

## Findings

Subagent finding summary:

- The abstract was too short and did not cleanly follow the context, problem,
  paper, and evidence/result beats.
- The introduction mixed background, concrete failure examples, and root cause
  in one opening paragraph.
- The Design section began directly with the model instead of an overview and
  explicit design goals.
- The Evaluation Plan listed RQs, but the following subsections did not map
  evidence and gates back to those RQs. Setup details were also buried under
  metrics.
- The related-work workload-source paragraph read like a list rather than a
  comparison against prior systems.
- The conclusion used an internal "next evidence gate" phrasing.

## Changes Made

- `docs/paper/main.tex`
  - Expanded the abstract from 135 to 179 words.
  - Reorganized it into context, concrete problem, proposed boundary, and
    planned evidence gate.

- `docs/paper/sections/01-introduction.tex`
  - Split the opening into background and concrete failure/root-cause
    paragraphs.
  - Expanded the status-quo paragraph so each mechanism states the boundary it
    chooses.

- `docs/paper/sections/03-design.tex`
  - Added a Design overview paragraph.
  - Moved Design Goals before the model.
  - Reworked the goals table into `Goal / Motivation / Mechanism / RQ`.

- `docs/paper/sections/05-evaluation.tex`
  - Added an RQ-to-evidence table.
  - Split `Evaluation Setup` from `Metrics`.

- `docs/paper/sections/06-related-work.tex`
  - Replaced the workload-source list with comparison subsections for agent
    workspace filesystems and agent environment/build workloads.

- `docs/paper/sections/08-conclusion.tex`
  - Replaced the internal "next evidence gate" sentence with a proposal-facing
    accept/reject evidence statement.

- `docs/paper/sections/02-motivation.tex`
  - Tightened table column padding to reduce layout pressure.

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `git diff --check` passed.
- Abstract word count check reports 179 words.
- Fixed-string checks found no `\paragraph{}`, `\textbf{}`, or defensive
  self-attack phrases from the common-pitfalls list.
- Citation-site count did not decrease.
- PDF page count is 9.

## Remaining Concerns

- The draft remains intentionally proposal-framed until KVM transition evidence
  exists.
- The table-heavy proposal layout is readable but still produces underfull box
  warnings; final formatting can revisit table compactness after later writing
  rounds.
