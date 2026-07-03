# Case-Study Matrix Research Record

Date: 2026-06-29

## Motivation

The project had workload, baseline, and citation material spread across the
evaluation plan, research state, and dated source-audit notes, but did not have
one dedicated case-study document. That made it easy to over-rotate on baseline
mechanics instead of explaining why each case exists and how it supports the
paper story.

This record adds `docs/case_studies.md` as the canonical case-study matrix. The
document aligns the cases with the current story: `namei_ext` is a general but
narrow programmable filesystem abstraction for dynamic path views, not a BPF
filesystem and not a claim about one baseline family.

## Files Inspected

- `docs/research_plan.md`
- `docs/experiment-plans/osdi-evaluation.md`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/02-motivation.tex`
- `docs/paper/sections/06-related-work.tex`
- `docs/paper/sections/07-limitations.tex`
- `docs/paper/refs.bib`
- `docs/tmp/2026-06-14-real-workload-source-signal-ledger.md`
- `docs/tmp/2026-06-16-real-workload-source-citation-audit.md`
- `docs/reference/INDEX.md`
- `research/STATE.md`

## Finding

No dedicated case-study matrix existed. The closest documents were:

- `docs/experiment-plans/osdi-evaluation.md`, which has detailed workload,
  claim, baseline, and oracle tables;
- `docs/tmp/2026-06-16-real-workload-source-citation-audit.md`, which records
  W1-W4 primary sources and citation keys;
- `research/STATE.md`, which records the current evidence status and blockers.

Those documents are too operational for a reader-facing case-study overview.
They also mix historical gates, negative ledgers, release blockers, and
workload definitions.

## Design Choice

The new `docs/case_studies.md` separates four concerns:

1. the conceptual mechanism comparison: FUSE/userspace FS, kernel/custom FS,
   static/materialized views, and `namei_ext`;
2. the case-study matrix: why each case exists, its lineage, citation anchors,
   natural baselines, oracle, and current status;
3. the academic evolution route from materialized views to userspace/stackable
   filesystems, kernel filesystems, and narrow programmable VFS path views;
4. the rule for keeping W1/W3/W4 as motivation or boundary evidence unless new
   release runs close their blockers.

The matrix intentionally treats bind mount, OverlayFS, projected volumes,
symlink forests, copy trees, cache mirrors, and materialized restore trees as
workload-specific baselines. They are not the main story. The main comparison is
the tradeoff among expressiveness, safety, and efficiency in FUSE/userspace
filesystems, kernel/custom filesystems, and `namei_ext`.

## Citation Anchors

The matrix reuses existing BibTeX keys from `docs/paper/refs.bib`:

- W1: `bazel_sandboxing`, `bazel_hermeticity`, `bazel_dependencies`,
  `bazel_toolchains`, `redis_repo`, `nginx_docs`
- W2: `kubernetes_projected_volumes`, `kubernetes_secrets`,
  `docker_compose_configs`, `docker_compose_secrets`, `nginx_docs`,
  `nginx_official_image`, `postgres_file_locations`
- W3: `podman_checkpoint`, `criu_main`, `criu_checkpoint_restore`,
  `criu_external_bind_mounts`, `dmtcp_path_virtualization`, `redis_repo`,
  `nginx_docs`
- W4: `ccache_manual`, `docker_buildkit_cache`, `bazel_remote_cache`,
  `bazel_remote_execution_api`, `nix_binary_cache_substituter`,
  `nix_content_addressed_store`, `prometheus_repo`, `prometheus_go_mod`
- Mechanism comparison: `linux_fuse`, `linux_fuse_passthrough`, `extfuse`,
  `bento`, `linux_overlayfs`

Local reference PDFs in `docs/reference/` are treated as reference candidates
until corresponding BibTeX entries are added.

## Remaining Risks

- `docs/case_studies.md` is a planning and story document. It does not upgrade
  any workload status by itself.
- W2 remains the only positive scoped setup/materialization case today.
- W1, W3, and W4 remain motivation, boundary, partial, or negative evidence
  unless their release blockers are closed.
- W4 now has trace-derived ccache cache-epoch table-budget boundary evidence,
  but it is still not a live stale/corrupt/update-window release workload.
- The paper still needs final LaTeX synchronization once the case-study verdicts
  are frozen for submission.
