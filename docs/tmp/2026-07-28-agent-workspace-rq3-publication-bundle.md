# Agent Workspace RQ3 Publication Bundle

Date: 2026-07-28

## Motivation

The first successful RQ3 formal target preserved all three KVM boot roots and
generated a formal summary and report, but it did not use the repository's
`namei_ext.run.v2` publication contract. The raw result also referred to
build-tree artifacts through host-absolute hash-manifest paths. That was enough
for local result review but not for a committed bundle that another checkout
could re-analyze.

## Implementation

`analysis/agent_workspace_rq3/package_formal.py` now converts a completed
three-boot RQ3 root into a portable publication bundle. It does not change the
observations, verifier logs, kprobe traces, provenance, or original per-boot
manifests.

The packager:

1. requires the formal summary to report 3/3 complete passing boots;
2. requires clean, identical project and kernel provenance across boots;
3. verifies every original source and binary hash before copying;
4. retrieves a tested source blob from the recorded Git commit when the current
   working-tree copy has changed since the formal run;
5. copies tested source and runtime artifacts under `artifacts/`;
6. emits portable per-boot source and binary manifests;
7. combines all raw observations without aggregation;
8. emits `run.json`, commit/status files, top-level hash manifests, and an
   artifact manifest; and
9. runs the tracked analyzer against the captured tested source tree and
   requires byte-exact agreement with the reviewed `report.json` and
   `report.md`.

The analyzer supports both the original direct formal-directory interface and
the common `--input --run --output --seed` replay interface used by the
publication validator. The replay requires top-level `observations.jsonl` to be
the exact ordered concatenation of the three boot observation files.
Source-accounting paths are repository-relative, and the tracked analyzer reads
the captured tested source tree rather than the current checkout for source
accounting.

The formal Make target now invokes
`make agent-workspace-rq3-publication-bundle` after result analysis. The
published-result validator recursively requires every declared source/runtime
artifact to be tracked before it executes an analyzer.

## Validation

The existing clean formal root was packaged with:

```text
make agent-workspace-rq3-publication-bundle \
  RUN_ID=20260728-rq3-formal-v3
```

Validation passed:

- all portable source and runtime hashes verified;
- direct and publication-replay JSON summaries were byte-identical;
- direct and publication-replay Markdown reports were byte-identical;
- all eight RQ3 analyzer tests passed;
- the RQ3 run is listed in
  `configs/publication/published-formal.json`; and
- `make result-contract` replays the committed formal analysis.

The publication conversion does not claim a new experiment. It makes the
already reviewed formal-v3 observations, tested inputs, binaries, and analysis
portable and independently replayable.
