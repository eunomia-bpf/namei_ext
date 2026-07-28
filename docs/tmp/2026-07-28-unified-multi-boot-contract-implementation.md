# Unified Multi-Boot Contract Implementation

## Motivation

Formal Agent workspace, FxMark, FxMark fast-path, and Service Configuration
Rotation suites independently implemented the same host and boot lifecycle
mechanics. This duplication made timeout, provenance, and artifact fixes easy
to apply to only one suite.

The repository audit approved a minimal shared contract before adding more
formal workloads. The first migration uses Agent workspace RQ2 because it has a
completed ten-pair result and a strict analyzer.

## Shared Boundary

`mk/multi_boot.mk` now owns:

- boot-root and expected-boot initialization;
- pinned-host CPU, frequency, `/proc`, and virtme-ng provenance capture;
- guest Makefile line-count, absolute-path, and checksum sealing;
- exact per-boot observation-file count and deterministic concatenation; and
- exact boot count plus required per-boot artifact existence.

The shared layer does not define matrices, condition order, correctness
oracles, BPF/FUSE engagement, boot schemas, affinity semantics, statistics, or
paper verdicts. Those remain suite-owned.

## Agent Workspace Migration

`mk/experiments/agent_workspace_rq2.mk` uses the shared helpers for the
mechanical steps above. Its alternating namei_ext/FUSE order, 1,000-sample
operation matrix, AgentFS-derived lifecycle oracle, launch-order schema,
per-boot kernel identity, affinity checks, and analysis are unchanged.

The required Agent boot file list remains suite-owned and is passed to the
shared existence validator.

## Validation

`tests/infrastructure/Makefile` includes a two-boot fixture. It proves that
observation collection is complete and deterministic and that a missing
declared per-boot artifact fails the Make target. Nested boot metadata and
nested observations are negative fixtures: only exactly the declared direct
boot directories can satisfy the contract, and extra nested files using either
reserved evidence filename are rejected rather than silently omitted. The
existing result-contract and Agent analyzer tests remain required.

The completed Agent workspace RQ2 formal result is reanalyzed from its preserved
raw observations after the migration. This checks analysis compatibility; its
historical `inputs.sha256` intentionally binds the original source commit and
is not rewritten.

The reanalysis of
`20260727T-agent-workspace-rq2-formal-v3` reproduced `summary.json` and
`summary.csv` byte for byte: all 20 boots, 20,000 lifecycle samples, and 960
required oracle observations remained present and passing.

## Remaining Work

FxMark and Service Configuration Rotation are not migrated in this change.
They should move only after the Agent suite passes local contract tests,
historical-result reanalysis, and a real KVM preflight. Positional KVM launch
arguments remain a separate follow-up because changing that interface has a
larger blast radius.
