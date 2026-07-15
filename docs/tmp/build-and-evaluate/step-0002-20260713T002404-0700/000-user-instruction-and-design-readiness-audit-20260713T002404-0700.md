# User Instruction And Design Readiness Audit

Timestamp: 2026-07-13T00:24:04-07:00
Phase: BUILD_AND_EVALUATE
Step: 0002
Status: complete

## Question

The active user objective asks to analyze the repo's prior user instructions
and conversation, add important items to `docs/user-instruction.md`, assess
whether the experiment design and system design are organized for OSDI/SOSP,
and continue with complete rather than scattered experiments.

## User Instruction Coverage

`docs/user-instruction.md` was read before this audit. It already contained the
major earlier instructions that shape the paper:

- retire table-only/static-table as the main novelty;
- keep the story strong and attractive rather than a negative-result paper;
- set RQ1 to expressiveness/sufficiency;
- set RQ2 to cost/overhead versus FUSE;
- set RQ3 to safety/boundary versus custom filesystem ownership;
- position `namei_ext` as a `sched_ext`-style VFS extension point between
  eBPF LSM and FUSE/custom filesystems;
- avoid scattered weak baselines and incomplete experiment switching;
- run the new skill hierarchy and return to BOOTSTRAP.

The current active objective was missing and has now been appended verbatim:

```text
你需要分析一下我们过去完整的这个 repo 里面的用户指令和对话, 重要的加进 user insn. 现在实验设计, 系统设计都整理好了吗? 符合 OSDI/SOSP 的要求吗? 继续做? 实验不要零散的实验, 要是完整的实验.
```

No assistant interpretation, summary, or supersession statement was added to
`docs/user-instruction.md`.

## System Design Readiness

The system design is organized enough to enter BUILD_AND_EVALUATE:

- `docs/idea-story.md` freezes the missing-middle claim: policy at VFS name
  resolution, lower filesystem semantics below.
- `docs/design.md` defines the boundary, one-decision BPF ABI, lookup/readdir
  event split, bounded action set, and proof obligations.
- `docs/implementation.md` records the actual KVM attach path, Make-only
  workflow, implemented `PASS`/`REDIRECT`/`HIDE`/`SELECT_TARGET` subset, and
  missing semantics that cannot yet be claimed as final evidence.
- The paper under `docs/paper/` compiles and expresses the same three-RQ
  contract.

The design is not yet submission-complete because the proof obligations still
depend on BUILD_AND_EVALUATE result review. This is an evidence gap, not a
story or system-design drift.

## Experiment Design Readiness

The evaluation design is now shaped correctly for OSDI/SOSP:

- a small number of complete same-oracle experiments;
- Experiment A as the headline Agent workspace matrix;
- Experiment B as the decisive environment/cache matrix after path-view
  admission;
- service/config only if a concrete lookup-time source oracle is found;
- FUSE as the central RQ2 comparison;
- custom/stackable filesystem ownership as the RQ3 boundary comparison;
- materialized namespace mechanisms as background unless a source oracle makes
  one directly decision-relevant.

The existing Agent workspace artifacts are not yet enough for a final
OSDI/SOSP result. The current `make experiment-agent-workspace` matrix is
useful implementation evidence, but before paper interpretation it still needs
formal admission, plan review, complete execution under the frozen plan, result
review, and a stricter audit that it is the full admitted AgentFS-derived
workspace lifecycle rather than a preflight-sized fixture.

## OSDI/SOSP Readiness Verdict

Story and design: ready to evaluate.

Evidence program: correctly organized, but not complete. The paper is not yet
OSDI/SOSP-ready for submission because final RQ evidence is missing. The next
valid action is not another small diagnostic or baseline; it is BUILD_AND_EVALUATE
Experiment A as one complete matrix.

## Next Action

Open BUILD_AND_EVALUATE Step 0002 EXPERIMENT_GATE for Experiment A. Use
`research-experiment-design` full-loop discipline:

1. admit or revise the Agent workspace matrix against RQ1 with RQ2/RQ3 cells;
2. review the plan with independent reviewers;
3. run the smallest real preflight only if needed;
4. run every planned `namei_ext`, FUSE, control, containment, and boundary cell;
5. preserve raw results;
6. perform result review before any paper claim.
