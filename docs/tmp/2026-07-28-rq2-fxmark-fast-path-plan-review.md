# RQ2 FxMark Fast-Path Confirmatory Plan Review

## Scope

This review covers
`2026-07-28-rq2-fxmark-fast-path-confirmatory-plan.md`. The proposed
replication tests only the stock-versus-patched-unattached MRPL comparison
left inconclusive by formal-v3. It does not repeat or pool the already
supported `SELECT`-versus-FUSE comparison.

## Independent Review

The first review returned `NO-GO` with four blocking defects:

1. The proposed 20 paired blocks had no prospective sensitivity basis.
2. The existing QMP verifier checked only the set of host CPUs, not the exact
   vCPU-index-to-host-CPU mapping, and FxMark lacked a guest startup barrier.
3. The existing FxMark completion checks did not require nonempty guest
   completion times or record actual host launch order and timestamps.
4. The planned two-condition Make target and analyzer did not yet exist.

## Resolution

- The plan now freezes 30 paired blocks before execution. A conservative
  simulation using only centered formal-v3 log-ratio residual vectors estimates
  83.3% probability that all three MRPL cells pass when the true ratio is 0.99;
  20 blocks provide only 65.8%. Formal-v3 samples remain separate.
- The affinity verifier must require exact ordered mappings
  `vCPU0->4`, `vCPU1->5`, `vCPU2->6`, and `vCPU3->7`. Both kernels must wait
  for the atomic positive record before benchmark setup or timing.
- The runner must record actual alternating host launch order, host start/end
  times, the guest barrier time, and nonempty guest completion times. The
  finalizer must reject any missing or inconsistent field.
- A dedicated Make-only target and two-condition analyzer will be implemented
  before real preflight. They must consume only the new result root.

## Execution Gate

The plan remains `NO-GO` until all four repairs have automated tests, the
Make target dry-runs successfully, and an independent implementation review
finds no blocking defect. Only then may the real one-block KVM preflight run.

## Implementation Review Round 1

The first implementation review remained `NO-GO` and found five additional
blocking defects:

1. Command-line overrides could shorten a result still stored under the formal
   result namespace.
2. The planned stock and patched kernel commits were recorded but not enforced.
3. Raw finalization marked `run.json` completed before analysis and PDF
   generation succeeded.
4. Zero-valued observation fields were branch defaults, not an independent
   proof that BPF and FUSE were absent.
5. `affinity-barrier.txt` copied the verifier time instead of recording when
   the guest crossed the barrier, and timestamp order was unchecked.

The implementation now hard-asserts all formal and preflight parameters,
enforces both frozen commits before boot and at finalization, keeps the run
`running` until analysis and output hashes pass, and marks analysis failures
atomically. Each guest captures empty and unchanged pre/post inventories for
loaded BPF programs, cgroup attachments, FUSE mounts, and open `/dev/fuse`
files. Separate QMP verification and guest barrier timestamps are recorded,
joined to host launch records, parsed, and checked in causal order.

A Make dry-run also exposed a recursive-analysis `RUN_ID` mismatch; recursive
analysis invocations now receive the parent run ID explicitly.

## Implementation Review Round 2

The second review confirmed the five round-one repairs but remained `NO-GO`
because the FxMark commit/archive and guest kernel command line/module flags
were still overridable. The shared protocol gate now hard-asserts their exact
values. `run.json` records them as benchmark-source and guest-launch fields,
and finalization checks those fields against literals before analysis.

## Final Follow-Up

The third and final review returned `GO` for the real one-block KVM preflight.
It confirmed that the remaining FxMark archive and guest-launch values are
asserted before execution, recorded in `run.json`, and revalidated during
finalization. No blocking defect remains in the approved preflight scope.
