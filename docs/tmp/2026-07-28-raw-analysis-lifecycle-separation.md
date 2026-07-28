# Raw Collection and Analysis Lifecycle Separation

## Motivation

The shared result contract previously left some formal runs in the `running`
state until statistical analysis and figure generation succeeded. Agent
workspace and FxMark fast-path analysis also rewrote an otherwise valid raw run
to `failed` when a derived analysis step failed. This coupled expensive KVM
collection to repeatable post-processing and made recovery from an analyzer
defect ambiguous.

The repository already has common Make, KVM, multi-boot, provenance, and result
infrastructure. This change repairs one inconsistent lifecycle boundary rather
than introducing another runner or moving directories.

## Inspected Paths

- `mk/results.mk`
- `mk/experiments/agent_workspace_rq2.mk`
- `mk/experiments/fxmark_fast_path.mk`
- `mk/experiments/service_config_rotation.mk`
- `mk/README.md`
- `tests/infrastructure/Makefile`
- `tests/infrastructure/test_analysis_lifecycle.py`
- sibling `../bpf-benchmark/Makefile` and `../bpf-benchmark/AGENTS.md`

## Design

`run.json.status = "completed"` now has one meaning: collection completed and
the suite validated its raw observations, correctness gates, provenance, and
artifact contract. Analysis consumes a completed run and produces derived
files. An analyzer or figure-generation failure still fails its Make target,
but it does not rewrite the immutable collection status.

The shared `NAMEI_EXT_RUN_VALIDATE_COMPLETE` helper checks the completed state
and minimum run identity before an analysis target starts. Derived outputs are
first written to a temporary sibling directory and replace `analysis/` only
after the suite validates every required output, so a partial analyzer failure
can be retried without losing a previously complete analysis. The affected
suites now use the same order:

```text
start -> collect -> finalize raw evidence -> mark complete -> analyze -> report
```

The unused Agent-workspace analysis-failure state target was removed. No
workload, policy, guest command, matrix, sample count, analyzer, or published
result was changed.

## Validation

`tests/infrastructure/test_analysis_lifecycle.py` invokes the Agent workspace,
FxMark fast-path, and Service Configuration Rotation analysis entrypoints with
an analyzer that writes an execution marker and then exits unsuccessfully. Each
Make target must reach the analyzer and fail, while the completed `run.json`
remains byte-for-byte unchanged. The test also checks the formal and preflight
Make recipes that run analysis, requiring raw finalization and completion to
precede the analysis entrypoint.

`make result-contract` passed. It included:

- nine publication-validator unit tests;
- the new three-suite analysis-lifecycle regression;
- replay of all three indexed formal analysis bundles;
- 19 FxMark analyzer tests;
- eight Agent-workspace analyzer tests; and
- the existing source-state, kernel-identity, canonical-result, and multi-boot
  positive and negative contract cases.

KVM was not rerun because this change does not alter guest execution, runtime
artifacts, workload behavior, policy behavior, or the measurement protocol.
A temporary result root containing the published FxMark fast-path raw
observations was also passed through the modified Make analysis target. The
target replaced a pre-existing derived directory, generated all five expected
outputs and `analysis/analysis.sha256`, and left no `.tmp` or `.old`
directory. The shared publish tests also cover recovery from an interrupted
directory swap and rollback when the staged directory is missing.

## Alternatives Rejected

A new Python suite orchestrator or a repository-wide directory rearrangement
would duplicate the existing Make/KVM/result contracts without fixing the
lifecycle error. Encoding analysis success inside the raw run status was also
rejected because analysis is deterministic, replayable post-processing while
KVM collection is the expensive observation-producing operation.

## Remaining Work

The positional `NAMEI_EXT_KVM_RUN_CAPTURE` interface, repeated guest
provenance, and split workload acquisition remain bounded consistency work.
They should be reduced while migrating a real suite, with parity tests, rather
than through an unvalidated repository-wide rewrite.
