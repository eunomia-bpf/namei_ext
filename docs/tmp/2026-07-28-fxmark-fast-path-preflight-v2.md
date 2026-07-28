# FxMark Fast-Path Preflight v2

## Command And Result

Command:

```text
make kvm-fxmark-fast-path-preflight \
  RUN_ID=20260728T-fxmark-fast-path-preflight-v2
```

Result root:
`results/experiments/fxmark-fast-path-preflight/20260728T-fxmark-fast-path-preflight-v2/`.

The preflight completed successfully from clean source commit
`a0c634047824fcebd16afc1f05b7dc231204324d`.

## Frozen Inputs

- patched kernel: `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- stock kernel: `062871f1371b2e02a272ff5279c6479aff0a37ef`
- FxMark: `3f29552ce7ba6be24c4172e6e2c2c1f603209953`
- host CPUs: `4-7`, one exact singleton per vCPU
- guest: four vCPUs, 8 GiB memory, 1-GiB tmpfs
- preflight cells: MRPL at 1, 2, and 4 workers for two seconds
- conditions: stock first, patched-unattached second

The packaged `bpftool` artifact has SHA-256
`8d90219edf52eacd3416ded92f2137f7ab87eeef2379b5d4b24e5395a79c9587`.

## Gates

- 2 of 2 fresh boots completed.
- 6 of 6 FxMark cells passed process, duration, work-count, tree-cardinality,
  and cgroup-membership checks.
- Both QMP records prove the ordered mapping
  `vCPU0->4`, `vCPU1->5`, `vCPU2->6`, `vCPU3->7`.
- Both guests crossed the affinity barrier before inventory or benchmark
  setup.
- Direct pre/post BPF program and cgroup-attachment inventories were empty and
  byte-identical in both boots.
- Direct pre/post FUSE mount and `/dev/fuse` open-file inventories were empty
  and byte-identical in both boots.
- All five timestamps in each boot passed
  `host start <= QMP verify <= guest barrier <= guest completion <= host completion`.
- Source, kernel, input, runtime, and artifact hashes passed.
- Dmesg, TSC, guest boot identity, alternating order, and host frequency gates
  passed.
- JSON, CSV, Markdown, PNG, and PDF analysis outputs were generated and
  hashed before `run.json` became `completed`.

## Smoke Measurements

The one-block `unattached / stock` ratios were:

| Workers | Ratio |
| ---: | ---: |
| 1 | 0.9781 |
| 2 | 0.9964 |
| 4 | 0.9810 |

These values are not paper evidence. With one block, the bootstrap interval
collapses to the single observation and the generated verdict is only a path
smoke result. The preflight establishes executability; the frozen 30-block
formal run determines the confirmatory result.

## Decision

Preflight is complete. No protocol change is required before
`make experiment-fxmark-fast-path RUN_ID=<fresh-id>`.
