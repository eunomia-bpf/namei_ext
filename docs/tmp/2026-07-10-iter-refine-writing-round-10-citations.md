# 2026-07-10 Iter-Refine-Writing Round 10: Citation Gate

Date: 2026-07-10

## Findings

The citation gate initially failed the mechanical pre-check:

- `verify_bib.py docs/paper/refs.bib` found 47 active entries and 48 errors.
- Most errors came from old unused web/documentation entries without `year`
  fields.
- Active paper-facing errors included wrong ExtFUSE authors, broad venue strings
  for ExtFUSE/Bento/Wrapfs, and an unreachable SWE-Factory URL
  (`https://github.com/SWE-Factory/SWE-Factory`).

## Changes Made

- Marked 31 currently uncited bibliography entries as `% STATUS: unused` so
  they are kept as provenance without blocking the current paper gate.
- Added complete annotation blocks (`VERIFIED`, `REAL`, `PDF`, `ABSTRACT`,
  `USED_FOR`) to the 16 active entries cited by the current paper
  (`docs/paper/refs.bib:33-473`).
- Added `year` fields to active web/documentation/repository entries.
- Fixed ExtFUSE metadata to the two authors shown in the downloaded USENIX ATC
  PDF and DBLP result (`docs/paper/refs.bib:292-305`).
- Fixed Bento metadata to the seven authors shown in the downloaded FAST PDF
  and DBLP result (`docs/paper/refs.bib:307-319`).
- Replaced the mismatched Wrapfs/FiST entry with the downloaded stackable
  template paper metadata (`docs/paper/refs.bib:321-333`).
- Corrected the SWE-Factory repository URL to the reachable public repository
  `https://github.com/DeepSoftwareAnalytics/swe-factory`
  (`docs/paper/refs.bib:433-445`).

## Verification

- `python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib`
  passed: 47 total entries, 16 active entries checked, 0 errors, 0 warnings.
- `make -C docs/paper` passed and produced a 10-page PDF.
- A named-system scan over `docs/paper/main.tex` and `docs/paper/sections`
  confirmed that the paper-facing external systems have nearby citations or are
  ordinary implementation context rather than source claims.

## Remaining Concerns

- Repository citations are verified for reachability and current use, not for
  stable archival persistence. Before submission, replace key GitHub-only
  citations with archived releases, Zenodo DOIs, or paper citations where
  available.
- Unused bibliography entries remain marked as historical provenance. They
  should be verified only if they become active citations again.
