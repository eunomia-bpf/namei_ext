# Recovery Node: BOOTSTRAP Re-Entry Under Current Skills

Timestamp: 2026-07-12T22:38:08-07:00
Phase: BOOTSTRAP
Step: 0001
Status: complete for phase re-entry; BOOTSTRAP step remains active
Parent: explicit user instruction after earlier cycle-0 freeze and
BUILD_AND_EVALUATE dependency repair

## Question And Entry

The user instructed: `按照新的 skills 重新回到 BOOTSTRAP 阶段`.

This node reopens BOOTSTRAP under the current `auto-research-orchestrator`
rules. The earlier `docs/tmp/cycle-0000-20260712T202757-0700/step-report.md`
recorded a BOOTSTRAP freeze and routed to BUILD_AND_EVALUATE, but the current
skill explicitly allows an explicit new user instruction to reopen BOOTSTRAP.
The project must therefore stop treating the cycle-0 freeze as the active
scientific contract.

## Inputs And Method

Read:

- `auto-research-orchestrator/SKILL.md`
- `auto-research-orchestrator/references/hierarchical-research-state-machine.md`
- `auto-research-orchestrator/references/bootstrap-research-project.md`
- `docs/user-instruction.md`
- `docs/idea-story.md`
- `research/STATE.md`
- `docs/evaluation.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/background-related-work.md`
- historical cycle-0 step report:
  `docs/tmp/cycle-0000-20260712T202757-0700/step-report.md`
- historical BUILD_AND_EVALUATE gate report:
  `docs/tmp/build-and-evaluate/step-0001-20260712T222428-0700/01-experiment-gate/999-gate-report-20260712T223146-0700.md`

Checked for in-flight experiment processes with `ps`; no `make
experiment-agent-workspace`, `virtme`, `qemu`, or agent-workspace runner
process remained active.

Checked for raw matrix artifacts under
`results/experiments/agent-workspace-matrix/`.

## Results And Raw Evidence

The current skill definition changes two important routing facts:

- `docs/user-instruction.md` must be a verbatim user-prompt log. It cannot
  contain assistant summaries, normalized instructions, supersession claims, or
  reviewer findings.
- A BOOTSTRAP freeze is not immutable when a new explicit user instruction
  reopens BOOTSTRAP. After re-entry, idea, RQ, workload coverage, baseline
  family, and evaluation promise are again BOOTSTRAP matters until the new
  EXPERIMENT, WRITE, and REVIEW gates accept a renewed freeze.

The workspace had no live experiment process. It did have two raw
`agent-workspace-matrix` roots:

- `results/experiments/agent-workspace-matrix/20260713T053547Z-77bb2b4d/`
- `results/experiments/agent-workspace-matrix/20260713T053556Z-e2d462d9/`

A quick raw check found no `pass == false` rows in either JSONL file, but these
roots were produced after the now-superseded BUILD_AND_EVALUATE routing and
before renewed BOOTSTRAP admission/result review. They are preserved as raw
prototype artifacts only.

## Scientific Impact And Decision

Decision: re-enter BOOTSTRAP now.

The candidate scientific story remains the strong one requested by the user:
`namei_ext` is a `sched_ext`-style VFS name-resolution extension point in the
sequence:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The story is no longer frozen. BOOTSTRAP must pressure whether the current RQs,
source workload choices, comparison families, and evaluation promise are strong
enough for OSDI/SOSP. The repair is not to shrink the claim around the current
prototype matrix. It is to run the proper BOOTSTRAP gates under the current
skill hierarchy.

## State Updates

Updated:

- `docs/user-instruction.md`: replaced the previous assistant-normalized
  instruction ledger with the visible user-authored prompts only.
- `docs/idea-story.md`: converted the file to the current skill layout with an
  Initial Narrative, active BOOTSTRAP frontier, hypothesis frontier, dormant
  paths, and narrative evolution.
- `research/STATE.md`: changed active phase from BUILD_AND_EVALUATE to
  BOOTSTRAP re-entry.
- `docs/evaluation.md`: changed the evaluation promise from frozen contract to
  BOOTSTRAP candidate and marked the prototype matrix roots as unreviewed.
- `docs/implementation.md`: changed implementation status from
  BUILD_AND_EVALUATE evidence to BOOTSTRAP prototype/dependency evidence.
- `docs/design.md`: marked the design as a BOOTSTRAP candidate.

No global skill files were changed. No Git add, commit, or push was performed.

## Completion And Next Action

This recovery node completes the phase re-entry. The active step is now:

```text
docs/tmp/bootstrap/step-0001-20260712T223808-0700/
```

Next action: enter BOOTSTRAP `01-experiment-gate` and run literature/novelty
pressure under the current hierarchy before any renewed freeze. The gate should
check whether the current candidate story, RQs, workload families, and baseline
families are still the strongest supportable OSDI/SOSP story.
