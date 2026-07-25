# 2026-07-25 Repository Cleanup: Retired Machinery Deleted, Process Docs Archived

Date: 2026-07-25
Status: implementation record; no experiment result is claimed here

## Motivation

A repository review found retired-story machinery and process red tape that
misled agents about the live research frontier:

1. The C8 table-only insufficiency claim and the C1–C8 claim-verdict system
   were retired as a story line, yet the Make control plane still carried the
   full ledger machinery, so every run emitted `qualified_for_c8=false` and
   `release_gate_pass=false`.
2. Per-experiment results were coupled to repo-global gate conditions, so no
   run could ever pass its gate.
3. `research/` held six "historical provenance only" pointer stubs; `docs/`
   held process documents (evaluation plan, research plan, experiment plans)
   whose admission/gate/completion rules belong to the orchestrator skill,
   not to the repository.
4. The user's decision: delete retired machinery outright instead of keeping
   it behind flags with explanatory notes; archive old records to `docs/tmp/`
   instead of deleting them.

## What Was Deleted (Make Control Plane)

- `mk/eval_osdi.mk` (2,164 lines): the entire C1–C8 claim-verdict ledger.
- `mk/table_budget.mk`: C8 table-budget machinery.
- `mk/report.mk`: legacy report/provenance flow.
- `configs/eval-osdi/`: `policy-budgets.mk` and all seven jq gate filters.
  The two still-needed files (`workloads.mk`, `workload-sources.mk`) moved to
  `configs/benchmarks/`.
- `tests/table_conformance/`: ABI tests for the retired `table_redirect`
  conformance line.
- Top-level `Makefile`: the `LEGACY_DIAGNOSTIC_GOALS` /
  `ENABLE_LEGACY_DIAGNOSTICS` conditional include block, the
  `phase1-legacy-diagnostics` and `table-conformance` targets, and the legacy
  help section. `mk/workload.mk` is now an unconditional include.
- `mk/kvm.mk` (2,234 → 747 lines): all legacy W1–W4 KVM diagnostic targets
  and their guest helpers (counterfactuals, table replays/compiles,
  macrobench baselines, eval-osdi baselines). Kept: phase1 validation,
  agent-workspace preflight/matrix, build-cache matrix, and the bulk ccache
  chain (trace, policy-bridge, cache-state-policy-fuse, policy/native/fuse
  compile, compile-epoch-switch, bad-local-fallback).
- `mk/workload.mk` (854 → 181 lines): only the Redis/nginx build closure
  required by the current build-cache matrix remains.
- `configs/benchmarks/phase1.mk`: dead `BASELINE_*` / `EVAL_OSDI_BASELINES`
  variables.
- `tests/w1_oracle/namei_ext_w1_oracle.c`: 91 emissions of retired fields
  (`qualified_for_c8`, `c2_supported`, `release_gate_pass`). Schema strings
  (`namei_ext.eval_osdi.*`) intentionally kept as identifiers for
  compatibility with archived raw results.

Deliberately kept: `bpf/policies/table_redirect.bpf.c` (still referenced by
`kvm-bench` variants) and the archived raw results under `results/`
(provenance, not repo complexity).

## What Was Archived (Not Deleted)

- `research/{CLAIM_LEDGER,CLAIM_VERDICT,EXPERIMENT_PLAN,EXPERIMENT_TRACKER,FOLLOWUP_PLAN,RESULTS_SUMMARY}.md`
  → `docs/tmp/2026-07-25-deprecated-research-stubs/`.
  `research/` now holds only `STATE.md`.
- `docs/{evaluation.md,research_plan.md,phase1_design.md,case_studies.md,experiment-plans/}`
  → `docs/tmp/2026-07-25-archived-process-docs/`, plus a full-history copy of
  `idea-story.md` (`idea-story-full.md`).

## What Was Rewritten

- `docs/idea-story.md`: slimmed to the narrative, RQs, contribution/evidence
  program, current evidence highlights, rejected paths, and guardrails. The
  orchestrator process tables (Claim Evolution, Narrative Evolution,
  Hypothesis Frontier) live only in the archived full copy.
- `research/STATE.md`: slimmed to a handoff pointer with the canonical
  layout, current story, and current evidence state.
- `README.md`: points to `docs/idea-story.md` and `docs/design.md`.
- `docs/paper/evaluation.md`: routing note updated to the new layout.

## Validation

- `make help`, `make -n phase1`, `make -n experiments`,
  `make -n kvm-w4-ccache-bulk-compile-epoch-switch`,
  `make -n kvm-w4-ccache-bulk-bad-local-fallback`,
  `make -n kvm-agent-workspace-preflight`, `make -n clean`,
  `make -n clean-results` all expand without structural errors (verified with
  a `VNG=true` shim where `-n` executes nested `$(MAKE)` lines).
- Grep over `Makefile mk/ configs/ bpf/ tests/ bench/`:
  no `ENABLE_LEGACY_DIAGNOSTICS`, `eval-osdi`/`eval_osdi` Make references,
  `table-budget`, `policy-budgets`, `qualified_for_c8`, `c1_c8_gate`,
  `release_gate_eligible`, `release_gate_pass`, `c2_supported` remain
  (schema-name strings in C sources excepted, kept deliberately).
- `tests/w1_oracle` rebuilds clean with `-Wall -Wextra` after the field
  strip; edited emit sites produce valid JSON.

## Remaining Notes

- `docs/review/` discussion records still cite the old `docs/evaluation.md`
  line numbers; they are dated discussion records and were not rewritten.
- `bench/workloads/*.c` keep `namei_ext.eval_osdi.*` schema names as artifact
  identifiers.
- Raw results under `results/` are untouched provenance, including the old
  `results/eval-osdi/` claim-verdict ledgers.
