# User-Instruction And Design Readiness Audit

Timestamp: 2026-07-12T20:36:00-0700
Cycle: 0000
Phase: BOOTSTRAP
Node: 00-bootstrap-idea
Status: complete

## Question And Entry

The active user objective asks to analyze the repo's prior user instructions
and dialogue, add important instructions to `docs/user-instruction.md`, decide
whether the current system and experiment design are organized, judge whether
they meet an OSDI/SOSP bar, and continue without returning to scattered
experiments.

This audit runs inside BOOTSTRAP. It does not freeze the story and does not
admit final BUILD_AND_EVALUATE experiments.

## Inputs And Method

Inputs read:

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/evaluation.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- `research/STATE.md`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/tmp/2026-07-12-idea-shrinkage-trajectory-audit.md`
- `docs/tmp/2026-07-13-user-instruction-and-complete-experiment-audit.md`
- `docs/tmp/2026-07-13-osdi-sosp-readiness-audit.md`
- `docs/tmp/2026-07-13-story-drift-audit.md`
- detailed complete-experiment plans for Agent workspace and environment/cache

Repository search did not find a standalone checked-in chat transcript. This
audit therefore used the current visible dialogue, `docs/user-instruction.md`,
and the repo's existing trajectory/readiness audit records as the available
instruction evidence.

## User-Instruction Coverage

Updates made to `docs/user-instruction.md`:

- appended the current active objective verbatim;
- appended recovered prior prompts that were direction-setting but previously
  represented mainly as summaries: stop proving static-table/dynamic-necessity
  claims, think carefully about what must be proved, revisit DeltaFS/YoloFS/
  AgentFS source roles, analyze reusable systems and the core idea, converge
  docs to the skills layout, and commit/push only when explicitly requested.

Coverage verdict: materially improved, but not perfect as a historical log.
Older entries still contain summarized instructions created before the new
orchestrator rule required verbatim-only prompt logging. The safe forward rule
is to append future user-authored instructions verbatim and keep derived
interpretation in node reports, not in `docs/user-instruction.md`.

## System Design Audit

System design is organized as a BOOTSTRAP candidate:

- `namei_ext` is framed as a `sched_ext`-style VFS name-resolution extension
  point, not a BPF filesystem or a table mechanism.
- The mechanism sequence is consistently:
  bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS.
- `docs/design.md` states the one-decision-function ABI, lookup/readdir event
  model, lower-filesystem ownership boundary, bounded/verifiable actions, and
  out-of-scope responsibilities.
- `docs/implementation.md` honestly separates current `PASS`/`REDIRECT`/
  `HIDE`/`SELECT_TARGET` feasibility from full experiment evidence.

Remaining design gaps before OSDI/SOSP evidence:

- the story is not BOOTSTRAP-frozen;
- the current prototype still lacks final-file target selection and synthetic
  parent-directory alias behavior if the admitted Agent workspace oracle needs
  them;
- RQ3 boundary evidence needs a concrete method for counting owned filesystem
  methods, privileged code surface, daemon/state responsibility, and invalid
  decision containment for each same-oracle workload.

Verdict: system design is coherent enough for BOOTSTRAP review and stronger
than the earlier table/materialization-centered story. It is not yet proven by
final evidence.

## Experiment Design Audit

Experiment design is organized as a small complete-experiment program, not as
scattered rows:

- Experiment A: AgentFS-derived agent workspace lifecycle.
- Experiment B: environment/cache transition from SWE-Factory-Gym,
  MEnvData-SWE, or SWE-rebench V2.
- Experiment C: service/config only if a real source oracle depends on
  lookup-time object selection.

The complete-experiment template requires same-oracle `namei_ext` KVM runs,
feature-equivalent FUSE comparison for RQ2, custom/stackable-FS boundary
evidence for RQ3, lower-FS semantic checks, controls/ablations, raw artifacts,
and result review.

Current evidence is still preflight/dependency evidence:

- `make kvm-functional` passed under
  `results/phase1/20260713T031516Z-997cf1c7/`.
- `make kvm-agent-workspace-preflight` passed under
  `results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/` and records
  nonzero `namei_ext` and FUSE operation counters.

Those runs prove mechanism engagement for a bounded slice. They do not answer
RQ1/RQ2/RQ3 because they lack the full AgentFS-derived lifecycle oracle,
full-lifecycle feature-equivalent FUSE comparison, calibrated RQ2 measurements,
result review, and custom/stackable boundary audit.

Verdict: experiment design is OSDI/SOSP-shaped as a plan. It is not
OSDI/SOSP-grade empirical support yet.

## Paper Readiness Audit

The paper source has the right high-level story, but it is not ready to exit
BOOTSTRAP. The introduction still states the third contribution as an
"empirical plan" and says representative KVM workloads are required to
establish the main claims. Under the new orchestrator, BOOTSTRAP WRITE must
produce a submission-shaped paper with explicit placeholders for missing
numbers and result-dependent sentences; it should not read like a proposal.

Verdict: the paper is aligned with the candidate story, but needs a BOOTSTRAP
WRITE_GATE pass before freeze.

## OSDI/SOSP Readiness Judgment

Current status: plan-level readiness, not evidence-level readiness.

What is currently strong enough:

- problem and design-space positioning;
- RQ structure;
- mechanism boundary;
- experiment admission discipline;
- source-system inventory and reusable workload evidence;
- separation of related-work/background mechanisms from central experiments.

What is not yet strong enough:

- complete paper text under the new BOOTSTRAP convention;
- root idea disposition after read-only idea discussion;
- mandatory literature/novelty pressure under the new lifecycle;
- final Agent workspace and environment/cache full matrices;
- result reviews and paper-ready figures/tables.

## Scientific Decision

Continue BOOTSTRAP. Do not resume implementation just because detailed
experiment plans exist. The next scientific action is to complete the
BOOTSTRAP idea/root-disposition node, then run the mandatory
`research-literature-novelty` pressure before the first empirical plan review.

After BOOTSTRAP freeze, the first BUILD_AND_EVALUATE work should be the
AgentFS-derived complete experiment, followed by the environment/cache complete
experiment. Table-only, static-table impossibility, dynamic-necessity proof,
and scattered baseline rows remain out of the mainline.

## Completion And Next Action

This audit node is complete.

Next node remains:

```text
docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/000-entry-20260712T202757-0700.md
```

Completion condition: produce the BOOTSTRAP idea/root-disposition report. It
must read the full `docs/user-instruction.md` and `docs/idea-story.md`, decide
whether the current candidate story is the strongest defensible story, record
accepted/rejected changes, and hand off to BOOTSTRAP EXPERIMENT_GATE
literature/novelty pressure.
