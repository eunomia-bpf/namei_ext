# RQ Framing And Positive-Hypothesis Cleanup

Date: 2026-07-12

## Motivation

The active paper direction must not become a negative-results paper or a
diagnostic exercise around table-only/materialized namespace mechanisms. The
working hypothesis remains that `namei_ext` is a narrow, useful VFS
name-resolution extension point for state-dependent path-view policies. The
right next step is to design experiments that give this hypothesis the strongest
plausible evidence. The hypothesis should only change if it is impossible, not
because current experiments are incomplete or poorly chosen.

## User Instruction Recorded

The current steering instruction is recorded in `docs/user-instruction.md`:

- combine design and implementation as one contribution;
- use three paper-facing RQs: expressiveness/sufficiency, cost versus FUSE, and
  safety/boundary versus custom or stackable filesystems;
- make RQ2 compare against feature-equivalent FUSE policy implementations;
- make RQ3 compare safety and ownership boundary against broader filesystem
  mechanisms;
- treat bind/Overlay/projected/copy/symlink materialization as related work and
  background comparison material, not as the central experimental opponent;
- do not write the paper as negative results, and do not weaken the hypothesis
  solely because current experiments are incomplete.

## Files Updated

The main paper and routing documents were cleaned to follow the three-RQ story:

- `docs/idea-story.md`
- `docs/evaluation.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/design.md`
- `docs/background-related-work.md`
- `docs/reference/CODE_SOURCES.md`
- `research/STATE.md`
- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/sections/08-conclusion.tex`
- supporting research tracker and claim files under `research/`

The cleanup removed active-document language that steered future work toward:

- table-only or `table_redirect` as the central novelty proof;
- a negative-results or boundary-limit paper;
- old RQ4/workload-characterization/mechanism-sufficiency/boundary-value
  structure;
- materialized namespace mechanisms as mandatory central baselines;
- weakening the hypothesis because current experimental evidence is still
  pending.

Historical reproduction facts remain in dated `docs/tmp/` records and raw
result roots. High-level routing documents now describe host-sensitive or
artifact-specific reproduction gaps as caveats instead of paper-facing negative
results.

## Current Paper Story

`namei_ext` is positioned as a missing middle point between static/materialized
namespace construction and full programmable filesystem ownership. It lets an
eBPF policy choose bounded lookup/readdir path-view actions while the kernel and
lower filesystem keep ownership of dentries, inodes, permissions, file data,
writes, page cache, persistence, and consistency.

The paper-facing RQs are now:

1. Expressiveness / Sufficiency: can a narrow VFS name-resolution extension
   express real state-dependent path-view policies without taking over
   filesystem semantics?
2. Cost / Overhead: what does programmable policy on the VFS name-resolution
   path cost compared with a feature-equivalent FUSE policy implementation?
3. Safety / Boundary: does `namei_ext` provide a narrower and safer
   implementation boundary than custom or stackable filesystems when the needed
   policy is only name resolution?

## Validation

The following checks passed after cleanup:

```text
make -C docs/paper check
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
make -C docs/paper paper
git diff --check
```

The citation verifier checked 25 active verified bibliography entries with 0
errors and 0 warnings. `wrapfs` now uses the official USENIX page URL, which the
verifier can reach.

The final LaTeX log scan found no undefined references, undefined citations,
LaTeX warnings, or overfull boxes after the evaluation-table wording fix.

The active framing scan over `docs/` and `research/`, excluding `docs/tmp/`,
found no matches for old RQ/table-only/negative-result/materialized-baseline
keywords.

## Baseline And Comparison Discipline

A follow-up review found that the active documents could still make the story
look like a collection of small baseline checks. The main documents were
therefore tightened to reserve central experimental comparisons for cases that
change an RQ answer:

- RQ1 uses the source-system oracle as the correctness gate.
- RQ2 uses a feature-equivalent FUSE policy implementation as the overhead
  comparison.
- RQ3 uses custom or stackable filesystem ownership as the safety and
  implementation-boundary comparison.

Materialized namespace mechanisms, native production mechanisms, and partial
metadata-service reproductions now remain background context, related-work
context, workload sources, or appendix material. They should not be promoted into
main experiment rows unless they directly answer one of the three RQs under the
same correctness oracle.

The active docs now avoid `W2`/`W4` shorthand and use descriptive workload-family
names: agent workspace lifecycle, environment/cache transition, and
service/config transition. Source-system characterization is recorded as
workload-selection support, not claim-moving evidence by itself. The
claim-moving evidence must be Make-owned KVM workloads with correctness oracles,
FUSE comparisons, and custom/stackable-FS boundary evidence.

## Mechanism Ordering Update

The user clarified the mechanism positioning:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The active documents were updated to reflect this ordering. eBPF LSM is now
described as a neighboring verified-kernel-policy point for security/access
mediation, while `namei_ext` is the VFS name-resolution policy point for
path-view object selection and directory visibility. This keeps the story
stronger than a simple "between materialization and FUSE" statement and clarifies
why the contribution is not just another LSM hook.

## Next Experimental Direction

The next work should implement positive, Make-owned, KVM-validated workloads:

1. Agent/workspace lifecycle first, likely AgentFS-derived, with source oracle,
   lookup/readdir coherence, lower-FS semantics checks, feature-equivalent FUSE
   comparison, and custom/stackable-FS ownership-boundary evidence.
2. Environment/cache transition second, using SWE-Factory-Gym, MEnvData-SWE, or
   SWE-rebench V2 seeds with stale/corrupt/update/cache-epoch behavior.
3. Service/config transition third, using a concrete config/secret/reload trace
   where lookup-time object selection matters.

The experimental posture is to strengthen the hypothesis by choosing workloads
and oracles that exercise the mechanism's intended boundary. Materialized
namespace mechanisms should remain related-work/background unless a specific
source workload naturally requires them as operational context.
