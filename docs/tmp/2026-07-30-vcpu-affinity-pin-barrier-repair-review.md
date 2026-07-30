# vCPU Affinity Pin Barrier Repair Review

## Purpose

This record captures the independent read-only review of the common vCPU
affinity barrier repair after mdtest preflight attempt 1. The review decides
whether the repair is safe to commit and use for preflight attempt 2. It does
not approve formal execution.

## Evidence Reviewed

The reviewer read:

- the failed attempt 1 `run.json`;
- the stock boot's failed `vcpu-affinity.json` and empty launcher logs;
- virtme-ng 1.40's installed `pin_vcpus()` and asynchronous `set_affinity()`
  paths;
- `mk/kvm.mk`;
- `tools/kvm/verify_vcpu_affinity.py`;
- `tools/kvm/test_verify_vcpu_affinity.py`;
- `docs/tmp/2026-07-30-rq2-mdtest-cold-metadata-preflight-attempt-1.md`; and
- `docs/tmp/2026-07-30-vcpu-affinity-pin-barrier-repair.md`.

## Findings

The reviewer confirmed:

1. Attempt 1 discovered all eight QEMU vCPU threads but observed the host-wide
   `0-23` CPU mask on each, correctly failed affinity verification, and never
   entered mdtest.
2. Concurrent verifier polling and virtme-ng's asynchronous QMP pin worker are
   an evidence-supported diagnosis. The old root does not identify a specific
   QMP connection as the cause, so the documents must not claim a traced
   connection history.
3. The three-second interval does not create a false pass. The verifier remains
   read-only, queries QMP after the interval, reads `/proc/TID/status`, and still
   requires the exact ordered singleton mapping.
4. The original 20-second verifier window starts after the interval. The guest
   remains blocked until the verifier atomically publishes `verified` and exits
   immediately on `failed`.
5. Existing four-vCPU artifacts usually completed pin and read-back after about
   1.16 seconds. Three seconds gives the one-second virtme-ng retry loop at
   least two uncontended retries on this host, but remains an empirical
   synchronization interval that attempt 2 must validate for eight vCPUs.

No P0/P1 false-pass or lifecycle blocker remains.

Repair verdict: GO

## Scope

This verdict approves committing the repair and launching preflight attempt 2
under a new result root. It does not allow samples from attempt 1, does not
approve a formal matrix, and does not weaken any workload, affinity, or
correctness gate.
