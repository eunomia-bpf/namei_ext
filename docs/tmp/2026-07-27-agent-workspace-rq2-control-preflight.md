# Agent Workspace RQ2 Publication-Control Preflight

## Purpose

This preflight is the real KVM gate for the publication-control repair applied
after formal v1. It tests the same AgentFS-derived workspace workload and
feature-equivalent FUSE baseline, with positive vCPU-affinity proof, complete
FUSE callback accounting, release-drain barriers, distinguishable epoch
metadata, 1,000 samples per operation, and versioned artifacts.

The result root is:

```text
results/experiments/agent-workspace-rq2-preflight/20260727T-agent-workspace-rq2-control-preflight-v1
```

## Identity

- Source commit: `e731ba415ce3bd8d7958a9dd150a4d9dfafadbfc`
- Modified kernel commit:
  `bdc9a83e3dfbef8ff2017f9188c7c86025962183`
- Base run schema: `namei_ext.run.v2`
- Suite protocol schema: `namei_ext.agent_workspace_rq2.protocol.v2`
- Source and kernel trees: clean
- KVM matrix: one paired block, two independent boots
- Condition order: `namei_ext`, then FUSE
- Guest clocksource: TSC in both boots

All captured input and runtime artifact hashes validated after both boots.
Both dmesg gates passed.

## Affinity And Host Controls

The host used four KVM vCPUs, performance governor, disabled Intel turbo, and
the homogeneous host CPU range 4-7. The QMP verifier completed before either
runner started:

| Condition | Verification attempts | vCPU to host CPU |
| --- | ---: | --- |
| namei_ext | 12 | 0:4, 1:5, 2:6, 3:7 |
| FUSE | 12 | 0:4, 1:5, 2:6, 3:7 |

Every observed `Cpus_allowed_list` was a singleton. The expected set matched
`host-cpu-pin.json`, the vCPU count, and `run.json`. Each guest copied the
atomic verification timestamp into `affinity-barrier.txt` and `boot.json`
before collecting any timing sample.

## Correctness

The required-oracle manifest contains 49 namei_ext and 47 FUSE oracles. Every
required case and manifest appeared exactly once in its condition and passed.
There were 16,169 raw observation rows and no row with false or missing
`pass:true`.

The repaired epoch-coherence check passed:

- base `denied.txt` resolved with mode 0000 and denied unprivileged read;
- upper `denied.txt` resolved with mode 0100 and still denied unprivileged
  read; and
- FUSE performed six targeted invalidations with zero errors.

This distinguishes the selected base and upper objects while preserving the
permission oracle.

## Sample Contract

Each condition produced exactly 1,000 passing samples for:

```text
lifecycle stat open access readdir exec
lower-filesystem stat lower-filesystem readdir
```

The preflight therefore contains 16,000 passing timing/control samples. The
Make gate, compiled runner constants, run manifest, and raw observations agree
on every count.

## FUSE Accounting

The timed FUSE resource window passed both quiescence barriers. Its raw
observation records:

| Field | Value |
| --- | ---: |
| callback requests | 22,003 |
| daemon CPU runtime | 84,646,180 ns |
| run-queue wait | 205,988 ns |
| timeslices | 23,005 |
| voluntary context switches | 22,999 |
| involuntary context switches | 6 |
| threads before / after | 2 / 2 |

The full-run engagement counters also satisfied:

```text
handle_opened = release = release_completed = 4,012
request_total = 22,080
invalidate_attempt = 6
invalidate_error = 0
```

The request total equals the sum of every implemented high-level FUSE
callback. The pre-window and post-window gates required completed releases to
match successful handles and the callback count to remain stable for 20 ms.

## Result

The preflight passed on its first real execution. It validates the repaired
protocol and permits the unchanged ten-paired-block, twenty-boot formal-v2
matrix. No preflight timing value will be combined with the formal result.
