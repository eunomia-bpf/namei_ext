# Round 4: Abstract And Introduction Rebuild

Started: 2026-07-12T21:29:39-0700
Cycle: 0000
Phase: BOOTSTRAP
Gate: 02-write-gate
Parent: `000-gate-entry-20260712T210327-0700.md`
Status: in progress

## Objective

Run the `rewrite-abstract-intro` process inside `iter-refine-writing`: map the
current opening to canonical abstract/introduction roles, diagnose logic jumps,
write the reorganization plan, rewrite introduction paragraphs, derive the
abstract last, compile, and self-check.

## Inputs Read

- `rewrite-abstract-intro/SKILL.md`
- `rewrite-abstract-intro/references/abstract-intro-revision.md`
- `rewrite-abstract-intro/references/abstract-intro-structure.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- Body sections under `docs/paper/sections/`

## Mapping Diagnosis

| Current text | Current role | Target role | Diagnosis |
| --- | --- | --- | --- |
| Abstract sentences 1-2 | background/problem | abstract S1-S2 | Good material, but long and not cleanly tied to intro paragraphs. |
| Abstract sentence 3 | existing solutions | abstract S4 | Good, but root-cause/insight boundary is compressed. |
| Abstract sentence 4 | insight | abstract S5 | Needs to state policy at VFS name resolution as the thesis. |
| Abstract sentences 5-6 | system/design | abstract S6-S7 | Good material, but current action set needed deny cleanup. |
| Abstract sentences 7-9 | characterization/evaluation/status | abstract S8-S9 | Keep evidence boundary explicit. |
| Intro ¶1 | background | background | Good. |
| Intro ¶2 | problem plus cause | problem/root cause | Keep merged because the root cause is concise: wrong pathname binding while lower-FS semantics should remain lower-FS owned. |
| Intro ¶3 | existing solutions | existing solutions | Good; preserve citations. |
| Intro ¶4 | insight | insight | Good but can be sharpened as "policy belongs at VFS name resolution." |
| Intro ¶5 | this paper/system | this paper/system | Good; should answer the insight directly. |
| Intro ¶6 | methodology/evidence boundary | methodology/results placeholder | Good after Round 3; make relation to RQs explicit. |
| Intro ¶7 | contributions | contributions | Good; keep deliverables. |

Optional paragraphs:

- Root cause: folded into the end of the problem paragraph. A standalone root
  cause paragraph is not necessary because the structural cause is one concise
  statement.
- Challenges: omitted. The paper's main challenge is boundary placement and
  evidence, already represented by design goals and evaluation placeholders;
  fabricating a challenge paragraph would add terminology without claim value.

## Reorganization Plan

- Rewrite Introduction paragraphs in the same seven-role order while preserving
  citations and the current RQ meanings.
- Keep same-oracle details in Evaluation, not the opening.
- Preserve the evidence boundary: characterization and prototype coverage are
  established; RQ1/RQ2/RQ3 final answers remain unanswered until the full
  KVM/FUSE/boundary matrix runs.
- Derive the abstract last from the rewritten Introduction in 8-9 sentences.

## Applied Rebuild

Rewrote `docs/paper/sections/01-introduction.tex` in seven paragraphs:

1. Background and workload context.
2. Problem and concise root cause.
3. Existing mechanisms and their limits for this problem.
4. Key insight: policy belongs at VFS name resolution while filesystem
   ownership remains below it.
5. This paper/system: `namei_ext` as a `sched_ext`-style VFS extension point.
6. Methodology and evidence boundary: source characterization, prototype, and
   RQ1/RQ2/RQ3 result slots.
7. Contributions.

Then rewrote the abstract as a one-paragraph compression of those roles. It
uses nine sentences and no claim that is absent from the introduction.

## Preservation Checks

- RQ meanings were not changed.
- Existing introduction citations were preserved. Citation occurrence count is
  29:
  `rg -o -F '\\cite{' docs/paper/main.tex docs/paper/sections docs/paper/refs.bib | wc -l`.
- Abstract length is 9 sentences and approximately 221 words.
- Deny is not listed as a current action set; service/config remains
  conditional; no table-only or materialization-as-mainline direction appears.

## Compilation Evidence

Command:

```sh
make -B -C docs/paper
```

Result: success. The build produced `.build/paper/main.pdf`, 17 pages. The log
contains only underfull/font warnings; no LaTeX error occurred.

## Self-Check

The abstract and introduction now follow the same causal order:
background, problem/root cause, existing-solution gap, insight, system,
methodology/evidence boundary, and contributions. The dominant thesis appears
in both: pathname policy belongs at VFS name resolution while the kernel and
lower filesystem retain filesystem ownership.

Open item: final RQ result values remain intentionally unanswered in BOOTSTRAP.

## Next Node

Round 5 consistency.

