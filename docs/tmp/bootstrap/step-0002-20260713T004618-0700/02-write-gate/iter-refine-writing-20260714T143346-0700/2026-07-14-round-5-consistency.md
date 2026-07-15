# Round 5: Consistency

## Skill Step

`iter-refine-writing` round 5: consistency. A read-only subagent invoked
`check-terminology-infoflow` in paper-consistency scope.

## Raw Findings

### Must-Fix

1. Evaluation still contained `RQ1/RQ2/RQ3 is unanswered` paragraphs while the
   abstract, introduction, and conclusion framed the paper as an intended
   submission.
2. The abstract claimed "registered target-selection actions" even though the
   implementation currently supports registered directory-target selection and
   not final-file target selection.
3. The RQ1 workload table used "complete lifecycle lookup/readdir..." inside
   the `namei_ext` evidence column, risking attribution of full Agent lifecycle
   behavior to the hook.

### Should-Fix

4. RQ3 drifted between "less filesystem ownership" and the intended narrower
   verifier-bounded, fail-closed boundary claim.
5. The experiment-shape table used "source/custom ownership table" instead of
   custom/stackable boundary language.
6. Related Work used "stacked-filesystem request path" while the rest of the
   paper uses "stackable filesystem."
7. Environment/cache stale/corrupt handling did not explicitly say that
   staleness/corruption comes from source cache metadata/validation, not
   `namei_ext` content inspection.

### Consider

8. Discussion repeats boundary definitions and should become
   implications-focused after results exist.
9. The motivation table used `lower-FS` instead of `lower-filesystem`.

## Fixes Applied

- Removed the three `Unanswered status` paragraphs from the paper body. The
  missing final KVM/FUSE/boundary evidence remains tracked in BOOTSTRAP reports
  and must not be turned into invented result prose.
- Changed abstract, introduction, and contribution text from registered
  target-selection to registered directory-target selection where describing the
  current prototype.
- Rewrote the Agent RQ1 table cell to "lookup/readdir select or hide
  branch-visible lower objects during the lifecycle"; the complete lifecycle
  remains in the delegated/boundary column.
- Standardized RQ3 language around "narrower verifier-bounded, fail-closed
  ownership boundary."
- Replaced `source/custom ownership table` with `source-system and
  custom/stackable ownership boundary account`.
- Replaced `stacked-filesystem request path` with
  `stackable-filesystem request path`.
- Clarified environment/cache stale/corrupt handling as source cache
  metadata/validation state.
- Normalized `lower-FS` to `lower-filesystem`.

## Fixes Deferred

- The Discussion section was not rewritten into a final implications section
  because the suggested change depends on final result values. Rewriting it now
  would either invent evidence or produce generic prose.

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Page count remains 15.
- The following drift/status terms no longer match in paper `.tex` files:
  `lower-FS`, `less filesystem ownership`, `registered target-selection`,
  `stacked-filesystem`, `Unanswered status`, `is unanswered`, `source/custom`,
  `complete lifecycle lookup`, `stale/corrupt local objects based`, and
  `reduce ownership`.

## Remaining Risks

- The paper is structurally cleaner, but the current draft still lacks final
  result-backed RQ answer paragraphs.
- Environment/cache remains dependent on final-file target selection before it
  can become final file-object evidence.
