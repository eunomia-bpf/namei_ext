# Round 4: Abstract And Introduction

## Skill Step

`iter-refine-writing` round 4 invoked `rewrite-abstract-intro`.

## Reorganization Plan

The opening was reorganized around the required causal chain:

| Current content | Target role | Action |
| --- | --- | --- |
| Agent/build/service view examples | Background | Preserve as paragraph 1. |
| Wrong pathname binding and examples | Problem | Split from root cause and keep concrete consequences. |
| Workload state changes object selection while lower FS should own semantics | Root cause | Promote into a standalone boundary-mismatch paragraph. |
| Namespace, eBPF LSM, FUSE/custom/metadata mechanisms | Existing solutions | Preserve focused limitations. |
| VFS name-resolution policy boundary | Insight | Rewrite as thesis, not system description. |
| Lookup placement, bounded outputs, same-oracle comparisons | Challenges | Preserve as the reason the idea is nontrivial. |
| `namei_ext` mechanism | This paper | Keep system description and mechanism answer. |
| RQ/evaluation preview | Methodology preview | Split from system paragraph. |
| Contribution list | Contributions | Keep two primary deliverables: design and Linux/eBPF implementation. |

## Fixes Applied

- Rewrote the abstract to follow the introduction in miniature:
  background, problem, root cause, existing mechanisms, insight, challenge,
  system, prototype, and evaluation methodology.
- Split introduction paragraph 2 into a pure problem paragraph and a standalone
  root-cause paragraph.
- Kept the insight separate from the system: the insight is the narrow VFS
  name-resolution boundary; `namei_ext` is the realization.
- Split the system paragraph from the evaluation preview.
- Reworded RQ3 as a "narrower, verifier-bounded, fail-closed implementation
  boundary" rather than an undefined generic safety claim.

## Self-Check

- Abstract length: 240 words.
- Abstract has 9 sentences and no result sentence with invented numbers.
- Introduction preserves the citation set and keeps the same contribution
  shape.
- No table-only, table_redirect, killer-experiment, BOOTSTRAP, TODO,
  PLACEHOLDER, or selected-slice language remains in the paper `.tex` files.

## Validation

- `make -C docs/paper paper` passed after the final RQ wording adjustment.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.

## Remaining Risks

- The draft is still 15 pages and requires later compression.
- The abstract and introduction describe evaluation questions, not final
  results, because the final KVM/FUSE runs are not yet complete.
