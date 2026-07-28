# Unified Multi-Boot Agent RQ2 Preflight

## Command

```text
make kvm-agent-workspace-rq2-preflight \
  RUN_ID=20260728T-multi-boot-agent-rq2-preflight-v1
```

## Purpose

This is dependency validation for the shared multi-boot Make contract and the
migrated Agent workspace RQ2 suite. It is not a new paper experiment and does
not replace the existing ten-pair formal result.

## Result

The command completed in 39.4 seconds with:

- source commit `d3989dcd77c2a027320bb9b0545fc43ae37563a0`,
  clean;
- kernel commit `bdc9a83e3dfbef8ff2017f9188c7c86025962183`,
  clean;
- one namei_ext boot and one feature-equivalent FUSE boot;
- kernel release `7.1.0-rc7-gbdc9a83e3dfb` in both guests;
- TSC clocksource and exact host CPU affinity `4-7` in both guests;
- 2,000 lifecycle samples and 16,169 total raw observation rows;
- zero observations with `pass != true`;
- identical expected and observed boot keys;
- passing input and artifact checksum manifests; and
- no configured dmesg failure pattern.

The immutable raw result is:

```text
results/experiments/agent-workspace-rq2-preflight/
  20260728T-multi-boot-agent-rq2-preflight-v1/
```

## Interpretation

The shared root initialization, guest Makefile sealing, pinned-host capture,
direct-boot tree checks, observation collection, per-boot file validation, and
Agent-owned finalization execute correctly through the real modified-kernel KVM
path.

This run establishes infrastructure compatibility only. The paper-facing Agent
workspace evidence remains
`20260727T-agent-workspace-rq2-formal-v3`, whose preserved raw data was
reanalyzed byte-for-byte after the migration.
