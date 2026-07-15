# Iter-Refine-Writing Round 5: Consistency

Date: 2026-07-12
Skill: `iter-refine-writing`
Round: 5, Consistency

## Objective

Check consistency across canonical docs and the paper: idea scope, terminology,
evidence status, workload families, RQs, baselines, and claims versus pending
work. Preserve the current scope: `namei_ext` is a `sched_ext`-style VFS
extension point between bind/Overlay/materialization and FUSE/custom
filesystems.

## Inputs

- `docs/user-instruction.md`
- `docs/idea-story.md`
- `docs/design.md`
- `docs/implementation.md`
- `docs/evaluation.md`
- `docs/background-related-work.md`
- `research/STATE.md`
- `docs/paper/main.tex`
- `docs/paper/sections/*.tex`
- `iter-refine-writing/SKILL.md`

## Reviewer Findings

The read-only reviewer found that the scope was restored, but the largest
consistency risk was drift back to two workloads because some canonical docs
omitted service/config. Must-fix findings were:

1. `docs/idea-story.md` contributions and C1 claim listed only
   agent/workspace and environment/cache.
2. `docs/background-related-work.md` safe claims and next action omitted
   service/config.
3. RQ1 wording drifted between `how often` and `where`.
4. RQ3 baseline scope drifted between natural alternatives and custom/full-FS
   mechanisms.
5. Evidence status language remained slightly too strong in the paper.
6. Canonical contributions still implied completed KVM evaluation while the
   paper correctly says pending KVM workload plan.

Should-fix findings were:

1. Make YoloFS evidence wording precise.
2. Make service/config evidence status explicit and name concrete source/oracle
   candidates.
3. Add service/config related work.
4. Clarify optional `deny` relative to access-control hooks.
5. Clarify implementation summary so representative workload targets are not
   implied to be complete.

## Applied Fixes

- Updated `docs/idea-story.md` contributions and C1 to include service/config.
- Reworded RQ1 to `where` across canonical docs.
- Synchronized RQ3 and baseline scope to include custom/full-filesystem
  mechanisms only when they are the natural broader boundary.
- Updated `docs/background-related-work.md` safe claims, mandatory baselines,
  and next action to include service/config.
- Changed paper evidence language from `establishes` to prototype
  `implements` the proposed boundary.
- Reworded YoloFS evidence as public FS/e2e plus paper-derived agent oracle,
  with original private agent/perf benchmark not reproduced.
- Marked service/config as Kubernetes projected-volume source/API inspection
  plus pending concrete service reload source record.
- Added a Service Configuration Views related-work subsection.
- Clarified optional attachment-mode deny is not the primary access-control
  claim.
- Clarified the implementation summary: prototype infrastructure exists,
  representative workload targets are pending.

## Scope Preservation

The changes explicitly protect the three-family workload scope:
agent/workspace, environment/cache, and service/config. They do not revive
diagnostic-baseline or exclusivity claims.

## Validation

Validation is run after this round in the main workflow.
