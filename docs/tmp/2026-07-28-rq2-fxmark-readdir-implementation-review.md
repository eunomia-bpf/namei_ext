# FxMark Readdir Implementation Review

## Scope

Two independent read-only reviews inspected the corrected FxMark `MRDL` and
`MRDM` source, cell controller, FUSE comparator, Make-owned KVM matrix,
analyzer, tests, documentation, and the relevant kernel lookup and directory
iteration paths. No reviewer edited the implementation.

## First Review: NO-GO

The first implementation review blocked KVM execution for six reasons:

1. FUSE measured-phase changes used unacknowledged signals while upstream
   FxMark ignored profile-command status.
2. Published analysis did not bind `run.json` and `observations.jsonl`.
3. Analyzer `--run` mode did not require an exact frozen preflight or formal
   matrix.
4. A double unmount failure could leave the FUSE daemon alive.
5. Python equality allowed a Boolean worker value to alias worker one.
6. The cell controller wrote path fields without JSON escaping.

## Repairs

The implementation now:

- uses an acknowledged Unix-domain control channel and a monotonic FUSE phase
  state machine;
- requires exactly one measured transition, one after transition, and zero
  invalid commands;
- publishes and verifies `raw-inputs.sha256` over the completed run manifest
  and raw observations;
- accepts only the exact five-boot preflight or 50-boot formal protocol in
  analyzer `--run` mode;
- kills and reaps the FUSE process when both unmount methods fail;
- validates worker and matrix number types strictly; and
- JSON-escapes every emitted path field.

## Final Review

A fresh final-gate reviewer checked all six repairs and searched for new
correctness, provenance, and fairness problems. It reported no remaining
blocking finding.

The reviewed local evidence was:

- 24/24 readdir analyzer tests;
- 7/7 host-vCPU affinity verifier tests;
- complete 8,192-entry host FUSE enumeration across multiple readdir
  requests;
- warning-free `-Werror` and GCC static-analyzer builds of `fxmark_cell.c` and
  `fxmark_fuse.c`;
- rejection of frozen-matrix mutations;
- complete Make-generated shell syntax validation; and
- `git diff --check`.

No KVM workload was run during implementation review.

## Verdict

Final verdict: GO

The implementation may be committed and pushed, after which the five-boot,
20-cell KVM preflight may run from a clean tree.
