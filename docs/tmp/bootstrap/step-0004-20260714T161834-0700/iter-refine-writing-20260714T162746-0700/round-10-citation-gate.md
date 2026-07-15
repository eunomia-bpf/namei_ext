# Round 10: Citation Gate

## Skill Route

- `iter-refine-writing`, round 10.
- Citation skill: `check-paper-citations`.
- Required mechanical check: `scripts/verify_bib.py`.

## Checks Performed

- Ran:
  `python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib`.
- Checked annotation coverage in `docs/paper/refs.bib`.
- Scanned named systems, mechanisms, datasets, benchmarks, and source
  repositories in the paper for first-mention citation coverage.
- Rebuilt the paper with `make -C docs/paper paper`.
- Checked the LaTeX log for undefined citations/references and overfull boxes.

## Findings And Fixes

The verifier initially found two blocking metadata errors:

1. `linux_fuse_passthrough` was missing a `year` field.
2. `fuse_bpf_patch` was missing a `year` field.

Fixes applied:

- Added `year = {2026}` to `linux_fuse_passthrough`.
- Added `year = {2023}` to `fuse_bpf_patch`.
- Added `kubernetes_configmaps` and `kubernetes_secrets` to the introduction's
  first service/config citation, so projected configuration and secrets are
  supported at first mention.

## Results

- `verify_bib.py` result: 61 bib entries found, 35 active entries checked,
  0 errors, 0 warnings.
- Annotation coverage: 61 `@...` entries and 61 each of `VERIFIED`, `REAL`,
  `PDF`, `ABSTRACT`, and `USED_FOR`.
- Missing-citation scan: no blocking missing-citation gap found after adding
  the service/config first-mention citations.
- Build result: `make -C docs/paper paper` succeeded and produced
  `.build/paper/main.pdf`.
- Build-log check: no undefined citation/reference, multiply-defined label,
  overfull box, or targeted LaTeX warning was found.
- Known warnings remain fontspec CJK warnings and underfull hbox warnings.
- Page count after this round: 16 pages.
