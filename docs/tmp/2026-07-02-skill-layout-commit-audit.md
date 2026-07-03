# Skill Layout Commit Audit

Date: 2026-07-02.
Stage: documentation and artifact routing audit before commit/push.
Source/command: `research-literature-novelty` skill, `git status`,
`git submodule status --recursive`, `git ls-files docs/reference`, `find
docs/tmp`, and local inspection of canonical documentation files.

## Motivation

The project has accumulated source-reproduction records, reference PDFs, paper
draft stubs, and historical research notes. This audit checks whether the
repository is now in the intended skill-compatible shape before committing and
pushing the documentation/PDF state.

The main risk is not a missing paper source. The main risk is letting old
planning files, paper drafts, or table-centered records look like current
claim owners after the paper direction changed.

## Files And Paths Inspected

- `docs/idea-story.md`
- `docs/background-related-work.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/reference/INDEX.md`
- `docs/reference/*.pdf`
- `docs/research_plan.md`
- `docs/case_studies.md`
- `docs/experiment-plans/*.md`
- `docs/phase1_design.md`
- `docs/paper/README.md`
- `docs/paper/*.md`
- `docs/paper/sections/*.tex`
- `research/*.md`
- `docs/tmp/`
- `kernel` submodule status

## Current Layout Verdict

The current durable layout is the intended one:

| Need | Owner |
| --- | --- |
| Idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, closest work, source-use verdicts, and mandatory baselines | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Standalone research and implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, benchmark outputs, and generated summaries | `results/` |
| Historical plans and paper drafts | routing stubs only |

`docs/background-related-work.md` now includes the skill-required major
sections: Search Log, PDF Corpus, Claim-Oriented Novelty Map, Closest Work,
Mandatory Baselines, Baseline Candidates, Absorbable Ideas, Adjacent
Communities, Venue Evaluation Patterns, Must-Read List, and Novelty Verdict.

## Artifact And Git State

- Parent repository status before this audit record: clean relative to
  `origin/main` except for untracked `.agentfs/`.
- `kernel` submodule points at pushed commit
  `9f6695adf2370c511374a74a07305f6ba1bb9299`.
- All reference PDFs under `docs/reference/` are tracked by git.
- `.build/paper/main.pdf` exists as a generated build artifact and was not
  staged. Generated build outputs belong under `.build/` and should not become
  committed source artifacts unless the paper-release policy changes.
- No code changes were pending in the parent repository during this audit.

## Boundary Decisions

- Do not revive table-centered C8 as the main paper route.
- Do not claim that selected workloads require eBPF, `namei_ext`, dynamic
  policy logic, or that static tables are impossible.
- Keep DeltaFS, IndexFS, TableFS, ExtFUSE, Bento, FUSE studies, and Wrapfs as
  related-work or appendix/baseline context unless a future explicit
  experiment makes them paper-facing.
- Keep source-system workload evidence separate from claims that `namei_ext`
  is necessary for those workloads.

## Validation Performed

- `docs/tmp/` contains no nested directories at max-depth 1.
- `docs/tmp/` contains no non-Markdown files.
- Top-level Markdown records under `docs/tmp/` follow the
  `YYYY-MM-DD-*.md` naming rule.
- `git ls-files docs/reference` lists `CODE_SOURCES.md`, `INDEX.md`, and the
  local reference PDF corpus.
- `git status --short --branch` showed no staged or unstaged tracked changes
  before this audit record was created.

## Remaining Risks

- The current layout is ready for next experiment design, not for final paper
  claims.
- The next technical gate is still a Make-owned, KVM-validated AI agent
  workspace lifecycle workload, followed by one W4 environment/cache workload.
- The paper draft under `docs/paper/` is intentionally a routing stub. A future
  paper-writing pass should rebuild prose from the canonical idea and
  related-work documents rather than editing old draft claims in place.
