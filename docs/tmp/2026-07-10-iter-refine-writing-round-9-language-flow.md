# 2026-07-10 Iter-Refine-Writing Round 9: Language Flow

Date: 2026-07-10

## Findings

Round 9 checked topic position, stress position, old-to-new information flow,
paragraph transitions, and register consistency after the idea-layer rewrite.

Subagent findings, summarized:

- Must-fix: the abstract and introduction still read partly like a planning
  memo; proposal-style phrasing kept the reader in planning mode rather than
  paper mode.
- Must-fix: the workload characterization used future-tense transition language
  after the surrounding text had already selected two source-derived transitions.
- Should-fix: the motivation, evaluation, related work, limitations, and
  conclusion repeated the boundary claim with slightly different wording,
  weakening old-to-new flow.
- Should-fix: the paper still had residues of the previous table-centered
  argument, which could make readers think the novelty claim depends on proving
  a static-table impossibility result.

## Changes Made

- Reframed the workload-characterization table caption and source paragraphs:
  future-tense transition/trace wording became selected-transition wording in
  `docs/paper/sections/02-motivation.tex:40` and
  `docs/paper/sections/02-motivation.tex:44-65`.
- Tightened the evaluation acceptance paragraph so the stress position is the
  boundary verdict: if either selected transition is out of model or fails the
  KVM oracle, the claim narrows or becomes a negative result
  (`docs/paper/sections/05-evaluation.tex:57-76`).
- Replaced the limitations sentence that named "Tables" with a mechanism-neutral
  boundary statement: "Precomputed maps, FUSE, agent filesystems, and metadata
  services remain valid mechanisms outside that scope"
  (`docs/paper/sections/07-limitations.tex:9-16`).
- Updated the historical routing notes to avoid reviving the old table-centered
  framing (`docs/paper/README.md`, `docs/paper/evaluation.md`).
- Synchronized `docs/idea-story.md` with the same flow: two selected upstream
  transitions, source-derived oracles, natural baselines, and no claim that
  competing mechanisms are impossible (`docs/idea-story.md:10-191`).

## Verification

- `make -C docs/paper` passed and produced `.build/paper/main.pdf`.
- `rg` over `docs/paper` and `docs/idea-story.md` found no remaining old
  workload labels, table-centered framing, future-transition phrasing, or
  proposal-memo phrasing
  relevant to the current paper.

## Remaining Concerns

- The paper is still a proposal-style draft: the selected transitions are
  specified, but their KVM workload implementations and same-oracle baseline
  measurements remain future work.
