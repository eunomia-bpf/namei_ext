# Active Routing Cleanup And Completion Audit

Date: 2026-07-12

Scope: audit whether the active repository state now matches the restored
research direction:

`namei_ext` is a `sched_ext`-style VFS extension point between namespace
materialization and full programmable filesystems.

This record did not modify any skill files.

## Requirement Audit

| Requirement | Evidence inspected | Status |
| --- | --- | --- |
| Restore the larger idea | `docs/idea-story.md`, `docs/design.md`, `docs/evaluation.md`, `docs/implementation.md`, `research/STATE.md`, and `docs/paper/*.tex` all describe a `sched_ext`-style VFS extension point with lower-filesystem ownership. | Satisfied for active docs and paper. |
| Keep the system between materialization and full filesystem ownership | Active docs and paper use the bind/Overlay/materialization versus FUSE/custom-filesystem boundary and route source systems through same-oracle natural baselines. | Satisfied. |
| Rewrite the paper around the restored idea | `docs/paper/main.tex` and sections now present the restored title, abstract, background, workload characterization, design, implementation, evaluation, related work, discussion, and conclusion. | Satisfied. |
| Continue the skill-guided iteration | `docs/tmp/2026-07-12-iter-refine-ideas-restoration-round-{1,2,3}.md` and `docs/tmp/2026-07-12-iter-refine-writing-round-{0..10}-*.md` exist. | Satisfied. |
| Do not edit current skills | Only repository docs were edited in this pass. A read-only status check of `/home/yunwei37/workspace/my-paper-work/academic-writing-skills` still shows pre-existing dirty files under `skills/auto-research-orchestrator/`; this pass did not touch them. | Satisfied for this pass. |
| Archive misleading old routing | `docs/experiment-plans/osdi-evaluation.md` was converted to a current routing entry, and the old detailed plan was archived as `docs/tmp/2026-07-12-archived-osdi-evaluation-plan.md`. Existing old-route records remain under `docs/tmp/` as provenance. | Satisfied. |
| Remove old-route wording from active docs | Active `docs/` and `research/` paths were scanned excluding `docs/tmp/` and `docs/paper/Makefile`; no old-route matches remained. The paper Makefile intentionally keeps guard patterns. | Satisfied. |
| Preserve evidence boundaries | Current docs state that representative KVM workloads are still needed for mechanism sufficiency and boundary value, and that the current artifact implements the prototype subset. | Satisfied. |

## Additional Edits In This Pass

- Replaced `docs/experiment-plans/osdi-evaluation.md` with a short current
  evaluation routing entry.
- Archived the old active evaluation plan under `docs/tmp/`.
- Updated `docs/experiment-plans/phase1.md`, `docs/research_plan.md`,
  `research/CLAIM_LEDGER.md`, and `research/RESULTS_SUMMARY.md` to remove
  legacy diagnostic wording from active routing.

## Verification Commands

```text
rg -n "table-only|C8|precomputed-map|table-centered|static-table|externally-updated exact table|table_redirect|redirect table|operation-weighted policy branch|killer experiment|same-oracle FUSE|same-oracle source-system, FUSE|source/FUSE behavior|FUSE/source-system|direct baselines|full OSDI|OSDI/SOSP|weak accept|operation_weighted_alias_hit_rate|exact-map" docs research --glob '!docs/tmp/**' --glob '!docs/paper/Makefile' || true
# no matches
```

```text
make -C docs/paper check
# passed
```

```text
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
# Total entries checked: 25
# Errors: 0
# Warnings: 0
```

```text
git diff --check
# passed
```

## Remaining Work After The Restoration Goal

The restored idea and active documentation are now aligned. The next research
work is not more table-centered argumentation; it is implementation and
evaluation:

1. Build the first Make-owned KVM AgentFS-derived workspace lifecycle workload.
2. Build the environment/cache transition workload from SWE-Factory-Gym or
   MEnvData-SWE source evidence.
3. Add the service/config transition workload.
4. Run same-oracle source-system, filesystem-service, materialized, native, and
   full-filesystem baselines where they are the natural comparison.
