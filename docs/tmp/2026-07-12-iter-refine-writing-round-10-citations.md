# Iter-Refine-Writing Round 10: Citation Gate

Date: 2026-07-12

Scope: run the final citation gate for the current paper draft after the
idea-restoration and writing rounds. This round did not modify any skill files.

## Inputs

- Paper draft: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Bibliography: `docs/paper/refs.bib`.
- Citation verifier:
  `/home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py`.
- Local reference PDFs:
  - `docs/reference/sc21-zheng-deltafs.pdf`
  - `docs/reference/sc14-ren-indexfs.pdf`
  - `docs/reference/atc13-ren-tablefs.pdf`
- Source repository checks:
  - `https://github.com/redis/agent-filesystem.git`
  - `https://github.com/strukto-ai/mirage.git`

## Problems Found

The pre-pass found 20 active cited entries, all annotated, and 27 unused
unannotated carryover entries tagged `STATUS: unused`. The active citation set
still had source-level gaps:

- the introduction used namespace construction and programmable filesystem
  mechanisms before citing OverlayFS, projected volumes, FUSE, and stackable
  filesystems;
- the workload characterization table named Mirage and Redis AFS without active
  bibliography entries;
- the related-work section named DeltaFS, IndexFS, and TableFS without active
  bibliography entries.

The unused unannotated entries remain carryover bibliography material and are not
part of the active citation set.

## Edits

1. Added citations in the introduction for namespace construction and broader
   programmable filesystem boundaries:
   `linux_overlayfs`, `kubernetes_projected_volumes`, `linux_fuse`, and
   `wrapfs`.
2. Added a source-corpus citation paragraph in workload characterization that
   cites agent filesystems, multi-backend agent filesystems, agent runtimes,
   Docker-backed environment sources, and projected service/config views.
3. Added Mirage and Redis AFS as neighboring multi-backend / indexed workspace
   source context in the representative-workload discussion.
4. Added DeltaFS, IndexFS, and TableFS citations in related work and kept their
   role as metadata-service / specialized-filesystem boundary anchors, not main
   `namei_ext` workloads.
5. Added annotated active bibliography entries for:
   - `mirage_repo`
   - `redis_afs_repo`
   - `deltafs_sc21`
   - `indexfs`
   - `tablefs`

## Verification

Active-citation inventory after edits:

```text
cited_count 54 unique 25
bib_entries 52 annotated 25
missing_from_bib []
cited_missing_annotations []
unused_unannotated_count 27
```

Citation verifier:

```text
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
Found 52 bib entries (25 active)
Total entries checked: 25
Errors (must fix): 0
Warnings (should review): 0
OK: No VERIFIED entries have mismatches
```

The first verifier run caught two venue mismatches:

```text
deltafs_sc21: bib venue was long-form SC title, API venue was "SC"
tablefs: bib venue was "USENIX Annual Technical Conference", API venue was "USENIX ATC"
```

Both were fixed in `refs.bib`.

Paper checks:

```text
make -C docs/paper check
# passed

make -C docs/paper paper
# passed, generated .build/paper/main.pdf
```

Final log and formatting checks:

```text
rg -n "undefined|Undefined|Overfull|LaTeX Warning: There were undefined|Reference .* undefined|Citation .* undefined" .build/paper/main.log || true
# no matches

pdfinfo .build/paper/main.pdf
# Pages: 15

git diff --check
# passed
```

Old-route scan:

```text
rg -n "table-only|C8|precomputed-map|table-centered|static-table|two-transition|table_redirect|direct baselines|same-oracle source-system, FUSE|source/FUSE behavior|FUSE/source-system|registered lower|kernel-registered|current draft|full OSDI|OSDI/SOSP" docs/paper docs/design.md docs/implementation.md docs/idea-story.md docs/evaluation.md docs/background-related-work.md research || true
# no matches
```

## Remaining Boundary

Citation quality for the active draft is now clean. This does not close the
experimental evidence boundary:

- representative KVM workloads are still required for mechanism sufficiency and
  boundary value;
- the current implementation still supports the prototype subset, pass-through
  plus validated same-parent replacement-component redirect;
- broader design actions such as hide, registered-target selection, and optional
  attachment-mode deny remain design targets until implemented and validated;
- dense tables still produce underfull hbox warnings, but the final log has no
  undefined references and no overfull boxes.
