# OSDI/SOSP Readiness Audit

Date: 2026-07-13
Scope: current repository state after the user-instruction and complete
experiment cleanup, `HIDE`/initial `SELECT_TARGET` implementation, and Phase 1
Make routing cleanup. Later same-day update: Agent workspace dependency
preflight and story-drift audit. Later final-directory update:
`make kvm-functional` passed under
`results/phase1/20260713T031516Z-997cf1c7/` and
`make kvm-agent-workspace-preflight` passed under
`results/experiments/agent-workspace/20260713T031638Z-46918d26/`, resolving the
earlier selected-root final-directory, selected-root readdir, upper-root stat,
and stale-target cleanup gaps without changing its dependency-only status.

## Question

The active user objective asks whether the repository has correctly absorbed
the past user instructions, whether the system and experiment design are now
organized, and whether the result meets an OSDI/SOSP bar. It also requires that
experiments be complete integrated experiments, not scattered small runs.

## Current Verdict

The system story and experiment protocol are now organized in the right shape:

- `namei_ext` is framed as a `sched_ext`-style VFS extension point;
- the mechanism sequence is
  bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom FS;
- the RQs are expressiveness/sufficiency, cost versus feature-equivalent FUSE,
  and safety/boundary versus custom or stackable filesystems;
- table-only, `table_redirect`, static-table impossibility, weak baselines,
  smoke tests, and scattered run rows are no longer the paper mainline;
- the headline experiment is an AgentFS-derived integrated workspace lifecycle,
  with the decisive second experiment as an integrated environment/cache
  transition.

This is OSDI/SOSP-grade as a design and evaluation plan, and the default
project-owned validation path no longer advertises the archived W1-W4/table
diagnostics as the active paper experiment. It is still not OSDI/SOSP-grade
empirical evidence, because the admitted complete experiments have not been
implemented and run through the full KVM/FUSE/result-review matrix.

## Requirement Audit

| Requirement | Current evidence | Verdict |
| --- | --- | --- |
| Preserve important user instructions | `docs/user-instruction.md` records the no-skill-edit instruction, RQ reset, FUSE comparison, no negative-result paper framing, mechanism ordering with eBPF LSM, no weak/scattered baselines, and no table-only mainline. | Organized. |
| Restore the larger idea | `docs/idea-story.md`, `docs/design.md`, `docs/evaluation.md`, and the paper draft frame `namei_ext` as a narrow VFS name-resolution policy boundary, not a BPF filesystem or table experiment. | Organized. |
| System design clarity | `docs/design.md` defines the mechanism position, one decision function, lookup/readdir events, lower-FS ownership, proof obligations, and out-of-scope responsibilities. | Organized as a systems abstraction. |
| Implementation boundary | `docs/implementation.md` states current `PASS`/same-parent `REDIRECT`/`HIDE`/`SELECT_TARGET`, KVM validation boundary, fail-fast requirement, and the remaining parent-alias/final-file/full-lifecycle gaps. | Honest and actionable, but incomplete for headline evidence. |
| Experiment design is not scattered | `docs/evaluation.md` admits two complete experiments plus one conditional experiment; each includes same-oracle `namei_ext`, feature-equivalent FUSE comparison, controls, boundary evidence, raw results, and result review. `docs/experiment-plans/osdi-evaluation.md` routes to the canonical plan files instead of owning a competing matrix. | Organized. |
| Headline experiment is concrete | `docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md` states paper-value admission, source assets, hypothesis, implementation preconditions, workload, oracle, comparisons, planned runs, metrics, and interpretation. | Concrete plan exists. |
| Decisive environment/cache experiment is concrete | `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md` states paper-value admission, expected outcomes, source assets, candidate row suite, path-view admission manifest, cache state machine, FUSE comparison, controls, planned runs, execution rule, metrics, and interpretation. | Concrete plan exists. |
| Default executable route matches story | `Makefile` now routes `phase1` to `phase1-smoke`, `kvm-policy-load`, and `kvm-functional`; W1-W4/table/report diagnostics are preserved behind `phase1-legacy-diagnostics`; default `POLICY_LOAD_OBJECTS` lists current validation policies instead of globbing `table_redirect`. | Organized and KVM-validated. |
| Agent workspace preflight exists | `make kvm-agent-workspace-preflight` now runs a KVM dependency preflight for stable logical workspace path selection across base/upper registered targets, selected-root final directory lookup/readdir, whiteout-style hiding, lower-FS symlink metadata, lower-FS write placement, and target-registry cleanup. Latest passing root: `results/experiments/agent-workspace/20260713T031638Z-46918d26/`. | Useful dependency, not paper evidence. |
| Story drift checked | `docs/tmp/2026-07-13-story-drift-audit.md` compares the archived shrunken story against the current story and identifies remaining drift risks. | No major canonical drift; execution-layer risks remain. |
| Full OSDI/SOSP empirical support | Post-audit implementation work adds and KVM-validates `BPF_NAMEI_EXT_HIDE`, selected-target directory selection, selected-root final directory lookup/readdir, and target-registry cleanup, but full Agent workspace semantics and the complete Agent workspace matrix are still missing. No `results/experiments/agent-workspace/<RUN_ID>/` full matrix exists. | Not achieved yet. |
| Avoid misleading completion claims | Current docs state the full experiment requires missing bounded actions and that redirect-only runs are preflight, not paper results. | Good. |

## Why The Current State Is Better

The previous trajectory repeatedly pulled the project into smaller questions:
static table insufficiency, materialized-view accounting, W1-W4 row ledgers,
and source reproduction as if it were claim-moving evidence. Those were useful
setup records, but they cannot carry the main paper. The current organization
fixes that by making one admitted experiment answer all relevant parts of the
headline claim under the same oracle:

```text
AgentFS-derived workspace lifecycle
  -> namei_ext KVM policy run
  -> feature-equivalent FUSE policy comparison
  -> no-hook / invalid-policy controls
  -> custom/stackable FS boundary evidence
  -> raw results and result review
```

The same pattern now also has a concrete plan for the decisive
environment/cache experiment:

```text
Environment/cache transition
  -> pre-registered source row suite
  -> cache hit/miss/stale/corrupt/epoch state machine
  -> namei_ext KVM policy run
  -> feature-equivalent FUSE policy comparison
  -> native/source evaluator and invalid-policy controls
  -> custom/stackable FS boundary evidence
  -> raw results and result review
```

This is the right OSDI/SOSP shape because it tests load-bearing reviewer
questions rather than collecting independent weak comparisons.

## Remaining Gaps

1. Extend registered-target selection only as required by the admitted Agent
   workspace oracle: likely directory aliasing and possibly final-object
   semantics. The design record is
   `docs/tmp/2026-07-13-registered-target-selection-design.md`; the initial
   intermediate-directory selection increment is already KVM-validated.
2. Add Make-owned KVM targets for the Agent workspace preflight, full
   `namei_ext` run, feature-equivalent FUSE run, controls, and result review.
   The preflight target now exists; full matrix targets remain missing.
3. Build the AgentFS-derived fixed workspace oracle and operation-weighted
   lookup/readdir trace collection.
4. Run the full Agent matrix to terminal status and preserve raw artifacts under
   `results/`.
5. Write a result-review report before making any paper claim.
6. Then run the decisive environment/cache complete experiment following
   `docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`.

## Latest Phase 1 Validation

The current default control plane was validated with:

```text
make help
make -qp
make phase1
```

`make -qp` expands the current route as:

```text
phase1: phase1-smoke kvm-policy-load kvm-functional
```

`make phase1` passed and wrote raw artifacts under
`results/phase1/20260713T022917Z-d2fd7174/`, then passed again after the Agent
workspace preflight target was added under
`results/phase1/20260713T024221Z-8d9cb9a5/`. The run covered ABI layout, KVM
smoke, policy load for `hide_secret`, `pass_only`, `redirect_alias`, and
`select_portal`, and KVM functional tests for attach rejection, `HIDE`,
intermediate `SELECT_TARGET`, same-parent `REDIRECT`, and detach behavior. No
JSONL failure rows or kernel BUG/Oops/Call Trace/hung-task signals were found.

This validates the current prototype route. It does not validate Experiment A
or B, because those complete experiment targets and FUSE comparison cells still
do not exist.

## Agent Workspace Preflight

`make kvm-agent-workspace-preflight` passed with raw artifacts under
`results/experiments/agent-workspace/20260713T031638Z-46918d26/`.

The preflight validates the current bounded-action slice through the real KVM
attach path:

- stable logical `view/ws/...` selection through registered target ID 1;
- base to upper target transition by re-registering that target;
- whiteout-style `deleted.txt` hiding;
- symlink metadata staying with the lower filesystem;
- a logical write landing in the selected upper target and not in base;
- selected-root final directory lookup and readdir in base and upper epochs;
- Phase-1 target registry cleanup after detach, preventing stale registered
  targets from contaminating later runs.

This is dependency evidence only. It is not the full AgentFS-derived
Experiment A because it lacks the source lifecycle oracle, feature-equivalent
FUSE comparison, operation-weighted traces, parent-directory synthetic alias
enumeration, full result review, and custom/stackable boundary audit.

## Independent Review

A read-only subagent audit checked the canonical files and Make routing after
the cleanup. It found no blocker or major story contradiction: the docs
consistently frame `namei_ext` as a `sched_ext`-style VFS extension point in
the intended mechanism sequence, use the intended three RQs, and demote
`table_redirect`, static-table impossibility, weak baselines, and scattered
rows from the paper mainline.

The remaining minor risk is discoverability: many old W1-W4/table/baseline
targets still exist as callable Make targets for provenance and debugging. This
does not contradict the default route because `phase1` excludes them and
`phase1-legacy-diagnostics` names the archived diagnostic flow explicitly. If
this becomes confusing again, the fix should be documentation and target
organization around the legacy boundary, not restoring those diagnostics to
the active paper path.

## Completion Decision

Do not mark the overall research objective complete yet. The design and
experiment plan are aligned with the user's requested OSDI/SOSP direction, but
the required empirical evidence remains incomplete. The next concrete work is
implementation, not more survey: add the missing bounded actions and build the
Make-owned KVM Agent workspace complete experiment.
