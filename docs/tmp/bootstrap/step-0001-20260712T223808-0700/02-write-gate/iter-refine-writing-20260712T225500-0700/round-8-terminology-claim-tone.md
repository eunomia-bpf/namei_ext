# Round 8: Terminology And Claim Tone

Started: 2026-07-12T23:43:00-07:00
Completed: 2026-07-12T23:52:28-07:00
Cycle: BOOTSTRAP step 0001
Gate: 02-write-gate
Parent node: `docs/tmp/bootstrap/step-0001-20260712T223808-0700/02-write-gate/000-gate-entry-20260712T225200-0700.md`

## Objective

Run Round 8 of `iter-refine-writing`: terminology stability, definition order,
synonym drift, cross-section concept consistency, and claim tone. The round is
writing-only. It must not change the three RQs, the central
`sched_ext`-style VFS extension-point story, or the accepted baseline families.

## Inputs Read

- `docs/user-instruction.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/03-design.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/08-conclusion.tex`
- `docs/tmp/bootstrap/step-0001-20260712T223808-0700/step-report.md`

## Method

A read-only subagent invoked `check-terminology-infoflow` and
`paper-writing-style` for terminology and claim tone. The main agent applied
the findings subsection by subsection. All Must-fix and Should-fix findings
were applied. Consider findings that improved paper-facing tone without hiding
missing result evidence were also applied.

## Raw Subagent Findings

Must-fix findings:

- `path-view` appeared before a definition in the abstract and introduction.
- `conditional service/config breadth` was internal shorthand.
- `source-oracle KVM expressiveness` was a dense abstract compound.
- `prototype matrix roots` was internal artifact vocabulary.

Should-fix findings:

- `transition`, `policy`, and `action` needed a bridge definition.
- `candidate`, `admitted`, and `headline row` read like review-process
  vocabulary in workload and evaluation prose.
- “does not rely on a generic claim that FUSE is slow” was defensive.
- “not to build a fully expressive filesystem” shrank the story before stating
  the positive design boundary.
- “BOOTSTRAP implementation gap” sounded like project status.
- `lower-FS` drifted from `lower filesystem`.
- The conclusion overclaimed by saying the split makes `sched_ext` useful.

Consider findings:

- `Status: unanswered in BOOTSTRAP` was honest but self-attacking.
- Service/config related-work phrasing was too hypothetical.
- The `sched_ext` analogy in Background had a defensive scope sentence.
- “out of scope by design” in metadata-service related work was negative.

## Applied Fixes

Terminology and definition order:

- Defined state-dependent path view in the introduction before using it as the
  central term.
- Added a bridge sentence distinguishing transition, policy, and action.
- Replaced `conditional service/config breadth` with service/config workloads
  included only when the oracle is lookup-time object selection.
- Replaced `source-oracle KVM expressiveness` with KVM runs that test
  expressiveness against source-derived oracles.
- Unified table wording to `lower-filesystem`.

Claim tone and paper-facing language:

- Replaced `BOOTSTRAP`/`TODO`/`Status: unanswered` paper prose with
  `Evidence slot for final runs` and `Required evidence`.
- Replaced `prototype matrix roots` with preflight runs treated as feasibility
  checks and not RQ evidence.
- Replaced `candidate`, `admitted`, and `headline` wording with
  representative workload and included-after-reviewed-run wording.
- Rewrote the FUSE comparison as isolating the request-path cost of placing
  equivalent policy in a filesystem service.
- Rewrote the design goal as a positive boundary: a small kernel extension for
  name-resolution policy while full filesystem expressiveness remains with FUSE,
  stackable, or custom filesystems.
- Rewrote final-file target selection as an implementation requirement before
  file-object-selection workloads are evaluated.
- Rewrote the metadata-service boundary as a positive requirement for metadata
  services or full filesystem boundaries.

## Rejected Fixes

No subagent finding was rejected. The paper still contains explicit evidence
slots because the BOOTSTRAP phase has not produced final RQ results. Those
slots were preserved to avoid inventing evidence.

## Verification

Compilation:

```text
make -B -C docs/paper
```

Result: pass.

PDF page count:

```text
Pages: 14
```

Citation preservation:

```text
rg -o '\\cite[t|p]?\\{[^}]+\\}' docs/paper/main.tex docs/paper/sections | wc -l
28
```

Targeted scan:

```text
rg -n 'BOOTSTRAP|Evidence TODO|TODO|prototype matrix roots|headline|admitted|admission|conditional service/config breadth|source-oracle KVM|generic claim that FUSE is slow|BOOTSTRAP implementation gap|lower-FS|makes sched_ext useful|out of scope by design|would evaluate whether|Status: unanswered|subsystem machinery|evaluation candidate|evaluation candidates' docs/paper/main.tex docs/paper/sections
```

Result: no paper-facing matches after relabeling the workload table.

## User-Instruction Check

The edits preserve the active user direction. They keep the stronger story,
remove table-only framing from the paper, preserve RQ2 as the FUSE comparison,
preserve RQ3 as the custom/stackable-filesystem safety and ownership boundary,
and describe \namei as a `sched_ext`-style VFS name-resolution extension point.

## Remaining Concerns

Some placeholder labels remain in the paper as evidence slots. That is
intentional for BOOTSTRAP and should be replaced with final data during
BUILD_AND_EVALUATE or WRITING after final runs exist. Round 9 should now focus
on flow and transition quality after the terminology cleanup.

## Next Node

Proceed to Round 9: language flow and polish.
