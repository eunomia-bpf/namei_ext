# RQ2 mdtest Cold Metadata Preflight Attempt 1

## Purpose

This record diagnoses the first real KVM preflight attempt for the RQ2 mdtest
cold and mutating metadata experiment. The failed result root is:

`results/experiments/mdtest-cold-metadata-rq2-preflight/20260730T233331Z-mdtest-preflight01/`

The root remains failed and is not reused.

## Execution Reached

The owning Make target passed the clean-source, pinned-source, stock/patched
kernel-pair, build, source-feasibility, and local-analysis gates. It created the
preflight result root and launched the first declared condition, the stock
kernel boot.

No mdtest phase ran. No policy or FUSE condition ran. The attempt therefore has
no correctness or performance result.

## Failure

`run.json` records:

```text
status: failed
failure: vcpu-affinity-verification
```

The host verifier reached QMP and observed all eight QEMU vCPU thread IDs, but
every thread still had `Cpus_allowed_list: 0-23` rather than the required
singleton mapping from vCPU 0--7 to host CPUs 8--15. After the 20-second
verification window, the guest observed the failed barrier and exited. The
launcher logs are empty, and no QEMU, virtme-ng, mdtest, MPI, or FUSE process
owned by this namei_ext attempt remained afterward. An unrelated VM from
another repository is not part of this result and must finish before the next
performance attempt.

This is an infrastructure failure before the workload. It does not answer RQ2
and does not permit formal execution.

## Evidence-Supported Diagnosis

The common capture path starts virtme-ng and the independent QMP verifier at
the same time. Virtme-ng performs `--pin` through a background QMP worker that
retries once per second, while the verifier immediately starts its own QMP
polling loop. The capture path had no synchronization interval for the pin
worker before independent read-back.

The failed artifact proves that the required affinity was absent; it does not
record which verifier connection prevented or delayed the pin worker.
Concurrent QMP polling is therefore an evidence-supported diagnosis from the
failed affinity state and installed virtme-ng control flow, not a directly
traced per-connection event history. The repair must preserve the exact
singleton gate rather than accepting a broader CPU mask.

## Repair

The common verifier now accepts an explicit initial delay. The capture path
waits three seconds before the first independent QMP query, giving virtme-ng's
pin worker three retry opportunities while keeping the guest blocked on the
verification artifact. The verifier's 20-second polling window starts after
that delay, and the output records the delay.

Two unit tests cover the delay and reject negative values. Existing affinity
matching still requires the exact ordered singleton mapping.

## Next Gate

The repair requires local tests, independent implementation review, commit, and
push before preflight attempt 2. Attempt 2 must use a new result root and still
pass all five condition boots; the failed attempt 1 root does not contribute
samples.
