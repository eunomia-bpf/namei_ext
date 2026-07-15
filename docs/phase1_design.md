# Historical Phase 1 Design

Status: historical provenance only.
Last routing update: 2026-07-02.

This file used to contain the early KVM-runnable same-parent PASS/REDIRECT PoC
design. It is intentionally no longer the current design, claim, or evaluation
owner. The old detailed text predates the current source-backed workload
direction and should not compete with the skill-compatible canonical docs.

## Current Routing

| Current question | Canonical file |
| --- | --- |
| Current idea, claim scope, non-goals, and next action | `docs/idea-story.md` |
| Related work, novelty risk, closest work, source-use verdicts, and mandatory comparisons | `docs/background-related-work.md` |
| Source repositories, datasets, artifacts, and evidence-record links | `docs/reference/CODE_SOURCES.md` |
| Current handoff pointer | `research/STATE.md` |
| Standalone research/implementation records | `docs/tmp/YYYY-MM-DD-*.md` |
| Raw logs, JSON/JSONL, generated summaries, benchmark outputs | `results/` |

## Current Boundary

- `namei_ext` is not a BPF filesystem, mount namespace replacement, or access
  control framework.
- A policy is an eBPF program under `bpf/policies/*.bpf.c`; no YAML/JSON policy
  language owns project semantics.
- The next claim-moving implementation should be Make-owned and KVM-validated,
  using real source-backed agent workspace, environment/cache, or service/config
  workload evidence.

Historical detailed design text is recoverable through Git history and dated
records under `docs/tmp/`.
