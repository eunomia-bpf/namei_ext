# Research State

Last updated: 2026-07-18
Status: handoff pointer only; current orchestrator phase is BUILD_AND_EVALUATE
after BOOTSTRAP step 0005.

This file intentionally does not own related-work, novelty, comparison,
workload-source, reproduction, or result verdicts. Update the canonical files
below instead of adding long inventories here.

## Canonical Layout

| Need | Read/update |
| --- | --- |
| Paper idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Mechanism boundary | `docs/design.md` |
| Implementation and validation boundary | `docs/implementation.md` |
| Current evaluation plan | `docs/evaluation.md` |
| Traditional workload evaluation plan | `docs/tmp/2026-07-18-traditional-workloads-evaluation-plan.md` |
| Related work, novelty risk, closest work, source-use verdicts, central comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| PDF inventory | `docs/reference/INDEX.md` |
| Formal orchestrator reports | `docs/tmp/<phase>/step-<NNNN>-<timestamp>/` |
| Dated research, reproduction, and implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `results/` |
| Historical plans and paper drafts | `docs/research_plan.md`, `docs/case_studies.md`, `docs/experiment-plans/*.md`, `docs/phase1_design.md`, `docs/paper/README.md`, `docs/paper/*` routing stubs |

## Current Project State

- Last completed orchestrator node: BOOTSTRAP step 0005 at
  `docs/tmp/bootstrap/step-0005-20260714T174151-0700/step-report.md`.
- Why this step exists: the user again instructed the project to return to
  BOOTSTRAP under the new skills and reorganize/improve the paper.
- Current status: step 0005 completed full `iter-refine-writing`, citation
  verification, meaning-preservation audit, paper build verification, root
  disposition, and independent outer audit with no blocking findings. The
  scientific contract is frozen again for BUILD_AND_EVALUATE.
- Next BUILD_AND_EVALUATE work resumes from
  `docs/tmp/build-and-evaluate/step-0003-20260714T154705-0700/`, recording
  BOOTSTRAP step 0005 as its parent.

## Current Story

- `namei_ext` is a `sched_ext`-style VFS name-resolution extension point, not a
  BPF filesystem.
- The contribution is the design and Linux implementation of that extension
  point as one systems boundary. eBPF chooses bounded lookup/readdir policy;
  the kernel and lower filesystem keep VFS object ownership, path walking,
  permissions, data path, writes, page cache, persistence, and consistency.
- RQ1 asks expressiveness/sufficiency for source-derived state-dependent
  path-view policies.
- RQ2 measures cost versus feature-equivalent FUSE.
- RQ3 evaluates the verifier-bounded, fail-closed ownership boundary versus
  custom or stackable filesystem ownership.
- The two primary workload families are Agent workspace and traditional
  build/cache. MEnv/SWE-Factory/SWE-rebench rows may serve as build/test oracle
  sources, but the workload should be framed as traditional build/cache rather
  than agent workload. Service/config and checkpoint/restart path remapping
  remain conditional on concrete lookup-time source oracles.
- Do not reopen table-only, materialized-view, or scattered-baseline side
  experiments as the novelty line.

## Current Evidence State

- Paper draft: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Current PDF: `.build/paper/main.pdf`, 15 pages after the step-0005 writing
  pass.
- Latest paper build checks during WRITE_GATE: `make -C docs/paper clean paper`
  and `make -C docs/paper paper` succeeded; citation verifier passed for 35
  active entries; no undefined citation/reference, LaTeX error, or overfull-box
  target failure was found.
- Latest implementation/preflight evidence remains supporting evidence only,
  not final paper RQ evidence. See `docs/implementation.md`,
  `docs/evaluation.md`, and the result roots listed in the active step report.
- Source-reproduction inventory is intentionally not repeated here. See
  `docs/reference/CODE_SOURCES.md`,
  `docs/background-related-work.md`, and
  `docs/tmp/2026-07-03-workload-inventory-and-reuse-decision.md`.

## Next Action

Start BUILD_AND_EVALUATE with the complete Agent workspace lifecycle experiment
or the traditional build/cache preflight if the next goal is to establish the
non-agent workload. The build/cache plan is
`docs/tmp/2026-07-18-traditional-workloads-evaluation-plan.md`: one traditional
build/test row, fixed hit/miss/stale/corrupt/epoch state machine, real KVM
`cgroup/namei_ext` attach path, same-oracle feature-equivalent FUSE row,
operation-weighted lookup/readdir/open/stat traces, raw results under
`results/`, and RQ3 custom/stackable filesystem boundary evidence.

Do not perform Git mutation unless explicitly requested after status/diff
inspection.
