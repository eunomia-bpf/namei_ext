# FxMark Fast-Path Confirmatory Implementation

## Motivation

The clean FxMark formal-v3 matrix supported the active `SELECT` versus cached
FUSE comparison but left two of three stock-versus-patched-unattached MRPL
confidence bounds below the predeclared lower threshold. This implementation
adds the independent host-pinned replication specified in
`2026-07-28-rq2-fxmark-fast-path-confirmatory-plan.md`. It does not modify or
pool the formal-v3 result.

## Shared Infrastructure Changes

- `tools/kvm/verify_vcpu_affinity.py` now verifies the ordered mapping from
  each QMP vCPU index to the corresponding requested host CPU. A permuted CPU
  set no longer passes. The verified mapping is written through the existing
  temporary-file replacement path.
- `mk/kvm.mk` owns the shared host-CPU range, online-state, performance
  governor, maximum-frequency, and turbo-disabled checks. The Agent Workspace
  experiment now calls this common validation macro.
- `mk/benchmarks/fxmark.mk` accepts an explicit guest affinity requirement.
  When enabled, the guest waits for the positive QMP record before mounting
  tmpfs or starting FxMark. It records the QMP verifier time and the later
  guest barrier-crossing time separately.
- FxMark guest boot records are written atomically and require a nonempty
  completion timestamp. Existing FxMark finalizers now reject empty
  `completed_at` fields.
- The confirmatory path captures direct pre/post inventories of loaded BPF
  programs, cgroup BPF attachments, FUSE mounts, and open `/dev/fuse` file
  descriptors. Both snapshots must be empty and byte-identical. The BPF
  inventory uses a hashed `bpftool` ELF copied into the result runtime
  artifacts, not guest `PATH` resolution.

## Confirmatory Runner

`mk/experiments/fxmark_fast_path.mk` provides one Make-only workflow:

```text
make kvm-fxmark-fast-path-preflight RUN_ID=<fresh-id>
make experiment-fxmark-fast-path RUN_ID=<fresh-id>
```

The formal target runs 30 alternating paired blocks. Each condition receives a
fresh four-vCPU boot and runs source-pinned FxMark MRPL at 1, 2, and 4 workers.
Only `stock` and patched `unattached` are measured. BPF statistics must be
disabled, no BPF policy is attached, and no FUSE process or filesystem may
engage.

For every boot, the host records nanosecond-resolution start/end times and the
actual launch order. The finalizer requires:

- exact expected and observed boot/cell tuples;
- 60 completed boots and 180 passing cells in the formal configuration;
- strict odd/even condition alternation;
- exact `vCPU0->4`, `vCPU1->5`, `vCPU2->6`, `vCPU3->7` records;
- separate QMP verification and later guest barrier timestamps in causal order;
- nonempty host and guest completion times with one-to-one launch/boot joins;
- immutable source, kernel, runtime, input, and artifact identities;
- stable TSC, clean dmesg, and no launcher affinity errors.

Any failed boot or failed gate stops the run. It is not replaced within the
result root. The formal target also rejects overrides to the frozen block
count, duration, vCPU count, host CPU range, memory, tmpfs size, timeout,
analysis seed, BPF-stats state, kernel commits, FxMark source archive, kernel
command line, or module flags.

## Analysis

`analysis/fxmark_fast_path/analyze.py` consumes only the new two-condition
result root. It validates the run matrix, launch order, correctness fields,
tree cardinality, cgroup placement, and absence of BPF/FUSE activity before
computing any performance result.

For each worker count it reports 30 paired `unattached / stock` throughput
ratios, their median, and a 95% percentile-bootstrap interval with 10,000
fixed-seed resamples. The positive, contradictory, and inconclusive rules are
the unchanged rules from the plan. Outputs are JSON, CSV, Markdown, PNG, and
PDF. Raw validation leaves the run in `running` state. Analysis failure marks
it failed; only successful output generation and `analysis.sha256` validation
mark it completed.

## Validation Performed

- `python3 analysis/fxmark_fast_path/test_analyze.py`: five tests pass.
- `python3 tools/kvm/test_verify_vcpu_affinity.py`: seven tests pass, including
  permuted and duplicate vCPU-index failures.
- `make -n kvm-fxmark-fast-path-preflight`: the complete two-boot preflight
  dependency graph, guest invocation, finalizer, and analysis path expand
  successfully.
- `git diff --check`: passes.

## Remaining Gate

The independent code/protocol review returned `GO`. The implementation still
requires a successful real two-boot KVM preflight. Preflight v1 preserved a
fail-fast guest-tool resolution failure; the frozen runtime-artifact repair is
recorded in `2026-07-28-fxmark-fast-path-preflight-v1-failure.md`. A successful
preflight proves only executability; the 30-block formal run is required for
paper evidence.
