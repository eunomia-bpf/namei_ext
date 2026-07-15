# Round 10: Citation Gate

## Skill Step

`iter-refine-writing` round 10: citation gate. Per the skill, this round first
checks `.bib` annotation blocks. Because all entries were annotated and marked
`REAL: yes`, the round ran Pass 3 for missing citations rather than a full
citation-verification run.

## Annotation Check

- `.bib` entries checked: 61.
- Entries missing any of `VERIFIED`, `REAL`, `PDF`, `ABSTRACT`, or `USED_FOR`:
  0.
- Entries with `REAL` other than `yes`: 0.

## Citation-Key Check

- Citation keys used in the paper: 31.
- Used citation keys missing from `refs.bib`: 0.
- Unused bib entries remain in `refs.bib` with annotations, as required by the
  citation skill.

## Missing-Citation Pass

The pass scanned named systems and mechanisms in the paper. Most first body
mentions already had citations, including Docker, FUSE, OverlayFS, bind mounts,
projected volumes, Landlock, BPF LSM, fanotify, `sched_ext`, VFS pathname
lookup, AgentFS, BranchFS, Sandlock, YoloFS, SWE-Factory-Gym, MEnvData-SWE,
SWE-rebench V2, ExtFUSE, Bento, Wrapfs, DeltaFS, IndexFS, and TableFS.

One missing citation was found:

- KVM was used as the evaluation environment without a citation at the
  Evaluation setup's first KVM mention.

## Fixes Applied

- Added `\cite{linux_kvm}` at the first Evaluation setup mention:
  `All \namei mechanism runs execute in KVM~\cite{linux_kvm} ...`

## Validation

- `make -C docs/paper paper` passed.
- The final LaTeX log has no undefined citation/reference warnings.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- Page count remains 15.

## Remaining Risks

- This was not a full re-verification of every citation against the web because
  every bib entry already had complete annotation blocks and `REAL: yes`.
- Future result paragraphs may introduce new named workloads, metrics, or
  mechanisms that require citations.
