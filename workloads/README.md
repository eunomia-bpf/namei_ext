# Workload Sources And Fixtures

This directory stores checked-in source-system evidence and small fixtures.
It is not the experiment control plane.

Current ownership:

- pinned upstream URLs, versions, commits, and archive hashes:
  `configs/benchmarks/workload-sources.mk`;
- downloaded archives and binaries: `.cache/workloads/`;
- extracted or per-run build trees: `.build/workloads/`;
- formal industrial case runners and source-native oracles: `experiments/`;
- raw workload provenance and observations: `results/`;
- historical evidence from the pre-W1--W7 numbering scheme:
  `workloads/legacy/`.

Formal case identities are the descriptive names in `docs/evaluation.md`.
New code and documents must not use legacy identifiers such as
`w1-redis-build` or `w4-ccache-redis-nginx` as if they were current W1--W7
case numbers.

Project-owned acquisition, build, KVM, benchmark, and report workflows remain
Make-only. Workload directories must not add checked-in orchestration scripts.
