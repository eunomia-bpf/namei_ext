# Round 4 Abstract And Introduction Rebuild

Started: 2026-07-12T23:25:00-0700  
Completed: 2026-07-12T23:29:00-0700  
Phase: BOOTSTRAP  
Step: step-0001-20260712T223808-0700  
Gate: 02-write-gate  
Parent node: round-3-logic-flow  
Status: completed

## Question And Entry

This round ran the main-agent `rewrite-abstract-intro` pass required by
`iter-refine-writing` Round 4. The pass used the paper body as the source of
truth and preserved the accepted RQs, scope, citations, and BOOTSTRAP evidence
state.

## Inputs And Method

Skill files read:

- `rewrite-abstract-intro/SKILL.md`
- `rewrite-abstract-intro/references/abstract-intro-revision.md`
- `rewrite-abstract-intro/references/abstract-intro-structure.md`

Paper files read:

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/05-evaluation.tex`

## Mapping And Plan

Current introduction role mapping:

| Current paragraph | Role | Diagnosis |
|---|---|---|
| ¶1 | Background/context | Establishes agent/workspace, environment/cache, and service/config context with citations. |
| ¶2 | Problem plus root cause | Names pathname binding risk and the structural cause. Root-cause content fits here because it is short. |
| ¶3 | Existing solutions | Names namespace construction, eBPF LSM, FUSE, stackable/custom FS, and why each sits at a different boundary. |
| ¶4 | Insight | States the missing abstraction: policy at VFS name resolution. |
| ¶5 | Challenges | Names expressiveness, lower-FS preservation, and comparison against FUSE/custom FS. |
| ¶6 | This paper/system | Presents `namei_ext` as a `sched_ext`-style VFS extension point. |
| ¶7 | Evaluation questions | States RQ1/RQ2/RQ3. |
| ¶8 | Contributions | Lists source characterization, design/implementation, and BOOTSTRAP evaluation contract. |

Abstract sentence mapping:

| Abstract sentence | Intro source | Diagnosis |
|---|---|---|
| 1 | ¶1 | Background. |
| 2 | ¶2 | Problem/root cause. |
| 3 | ¶3 | Existing mechanisms. |
| 4 | ¶4 | Insight. |
| 5 | ¶6 | System. |
| 6 | ¶6/Design | Mechanism summary. |
| 7 | ¶8/Motivation | Characterization and scope. |
| 8 | Implementation | Prototype state. |
| 9 | Evaluation | BOOTSTRAP evidence slots. |

The sequence already matched the required causal order after Rounds 0--3. The
main remaining issue was terminology leakage: the introduction used the
implementation enum name `SELECT_TARGET`, which belongs in Implementation, not
in the paper opening.

Planned edits:

- Preserve the paragraph order and abstract structure.
- Replace the introduction's enum name with mechanism-level registered-target
  wording.
- Leave the abstract's BOOTSTRAP evidence-slot sentence intact because no final
  RQ results exist yet.

## Applied Fixes

`docs/paper/sections/01-introduction.tex`:

- Replaced `registered-target selection (SELECT_TARGET)` with
  `kernel-registered target-selection actions`.

No abstract rewrite was needed after the role mapping. The abstract already
matches the introduction's order and explicitly marks missing results as
BOOTSTRAP evidence slots.

## Self-Check

Abstract-to-introduction correspondence:

- Background maps to intro ¶1.
- Problem and root cause map to intro ¶2.
- Existing-mechanism limitation maps to intro ¶3.
- Thesis maps to intro ¶4.
- Challenge sentence maps to intro ¶5.
- System and mechanism sentences map to intro ¶6 and Design.
- Scope/evidence sentences map to the contribution list and Evaluation.

Logic chain:

```text
task-specific filesystem views
-> pathname binding risk
-> existing mechanisms sit at the wrong ownership boundary for path-view-only effects
-> VFS name resolution is the missing policy boundary
-> the boundary must satisfy expressiveness, lower-FS preservation, and comparison constraints
-> namei_ext implements a sched_ext-style VFS extension point
-> evaluation contract tests RQ1/RQ2/RQ3
```

The chain preserves the accepted story and does not reintroduce table-only,
static-table, or generic FUSE-vs-kernel framing.

## Verification

Commands:

```sh
make -B -C docs/paper
pdfinfo /home/yunwei37/workspace/namei_ext/.build/paper/main.pdf | rg '^Pages:'
rg -n 'SELECT_TARGET|SELECT\\_TARGET|table-only|table_redirect|static-table|BPF filesystem|BOOTSTRAP evidence slots|Status: unanswered|Evidence TODO|conditional service/config' docs/paper
```

Results:

- `make -B -C docs/paper` completed successfully.
- The PDF is 14 pages.
- Implementation still names `SELECT_TARGET` in the ABI subsection, which is
  appropriate. Design and Introduction no longer expose the enum.
- No paper-facing table-only/static-table/table_redirect novelty line appears.

## Scientific Impact And Decision

Round 4 preserves the stronger story and avoids making the opening look like an
implementation/API paper. The introduction now presents registered-target
selection at the mechanism level while leaving ABI names to Implementation.

## Completion And Next Action

Round 4 completed. Next node: Round 5 consistency. The next reviewer should
check architecture/workflow contradictions, claim drift, cross-references,
figure/table alignment, design goals to RQs, and abstract-intro-body alignment.
