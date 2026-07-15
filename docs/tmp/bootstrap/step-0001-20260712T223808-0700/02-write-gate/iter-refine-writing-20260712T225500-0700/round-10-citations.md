# Round 10: Citation Gate

Started: 2026-07-12T23:57:00-07:00
Completed: 2026-07-13T00:04:17-07:00
Cycle: BOOTSTRAP step 0001
Gate: 02-write-gate
Parent node: `docs/tmp/bootstrap/step-0001-20260712T223808-0700/02-write-gate/000-gate-entry-20260712T225200-0700.md`

## Objective

Run Round 10 of `iter-refine-writing`: citation gate. Check whether `refs.bib`
has complete annotation blocks and whether any entry is `REAL: unverified`.
Because annotations are complete and all entries are marked real, run Pass 3
only for missing citations in the LaTeX text.

## Inputs Read

- `docs/user-instruction.md`
- `docs/paper/main.tex`
- `docs/paper/refs.bib`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-background.tex`
- `docs/paper/sections/04-implementation.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/06-related-work.tex`
- Linux kernel documentation pages for VFS, pathname lookup, BPF, eBPF verifier,
  KVM, and mount.
- Docker overview documentation.
- Kubernetes ConfigMap documentation.

## Method

The main agent checked `.bib` annotation completeness and missing citation keys.
A read-only subagent invoked `check-paper-citations` in gate-check mode and ran
Pass 3 for missing citations. The main agent applied the citation fixes, added
annotated primary documentation entries, compiled the paper, and checked the
final LaTeX log for undefined references.

## Bib Annotation Gate

Pre-check result:

```text
entries 60
missing_annotation_entries 0
```

No entry has `REAL: unverified` or `REAL: no`. Therefore the full
`check-paper-citations` verification run was not triggered in this writing
round.

## Raw Subagent Findings

Must-fix findings:

- VFS pathname-resolution background needed a VFS/path lookup citation.
- General eBPF/verifier background needed BPF/verifier citations rather than
  relying on BPF LSM.
- The workload evidence table named source systems without row-level citations.
- The first `Docker` mention lacked a Docker source citation.

Should-fix findings:

- Namespace-construction background needed support for bind mounts and should
  avoid unsupported `symlink forests` wording.
- Background should cite stackable/custom filesystem sources when naming that
  boundary.
- Service/config related work should cite Kubernetes Secrets and ConfigMap
  documentation.
- The introduction's metadata-service mention should cite DeltaFS/IndexFS/TableFS
  or move to Related Work.

Consider findings:

- The Introduction correctness-risk examples could rely on preceding source
  citations; no extra citation was added because the source-family sentence
  already cites the relevant source families.
- The Design `sched_ext` analogy is already cited in the Introduction and
  Background; no redundant citation was added there.

## Applied Fixes

Added annotated bibliography entries:

- `linux_vfs_docs`
- `linux_path_lookup`
- `linux_bpf_docs`
- `linux_bpf_verifier`
- `linux_mount`
- `linux_kvm`
- `docker_overview`
- `kubernetes_configmaps`

Added or adjusted citations:

- VFS/path lookup background now cites `linux_vfs_docs` and
  `linux_path_lookup`.
- General eBPF/verifier background now cites `linux_bpf_docs` and
  `linux_bpf_verifier`.
- Implementation KVM mention cites `linux_kvm`.
- Introduction Docker mention cites `docker_overview`.
- Namespace-construction mentions cite `linux_mount`, `linux_overlayfs`, and
  `kubernetes_projected_volumes`; unsupported `symlink forests` wording was
  removed from the paper-facing list.
- Stackable/custom filesystem boundary background cites `linux_fuse`, `wrapfs`,
  and `bento`.
- Metadata-service boundary mention in the Introduction cites
  `deltafs_sc21`, `indexfs`, and `tablefs`.
- Evaluation source rows now cite AgentFS, environment/cache sources, and
  Kubernetes service/config sources directly.
- Related Work service/config paragraph now cites projected volumes,
  ConfigMaps, and Secrets.

## Rejected Fixes

No Must-fix or Should-fix citation finding was rejected. The Consider request
to add extra citations to the correctness-risk examples was not applied because
the preceding paragraph already cites the relevant source families, and adding
another long citation chain would hurt flow. The Consider request to repeat the
`sched_ext` citation in Design was not applied because the same analogy is cited
in Introduction and Background.

## Verification

Compilation:

```text
make -B -C docs/paper
```

Result: pass.

Final LaTeX log check:

```text
rg -n 'undefined|Citation .* undefined|There were undefined references|Rerun to get cross-references' .build/paper/main.log
```

Result: no matches.

Citation key check:

```text
cited_count 71
unique_cited_count 32
missing_bib_keys []
unused_bib_count 28
entries 60
missing_annotation_entries 0
```

PDF page count:

```text
Pages: 14
```

## User-Instruction Check

The citation fixes preserve the active user direction. They support the current
story and baselines without reviving the retired table-only experiment. RQ2
remains the FUSE comparison, and RQ3 remains the custom/stackable filesystem
safety and ownership boundary.

## Remaining Concerns

The bibliography contains unused but annotated entries retained for nearby
source and workload context. That is allowed by `check-paper-citations`, which
explicitly says not to remove unused real entries.

## Next Node

The 11-round `iter-refine-writing` loop is complete. Proceed to WRITE_GATE
outer audit and gate report.
