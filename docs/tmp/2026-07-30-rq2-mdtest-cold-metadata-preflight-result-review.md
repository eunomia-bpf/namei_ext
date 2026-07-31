# RQ2 mdtest Cold Metadata Preflight Result Review

## Scope

This review closes the real preflight for the reviewed RQ2 mdtest cold and
mutating metadata experiment. It examines all three immutable result roots:

```text
results/experiments/mdtest-cold-metadata-rq2-preflight/20260730T233331Z-mdtest-preflight01/
results/experiments/mdtest-cold-metadata-rq2-preflight/20260730T235638Z-mdtest-preflight02/
results/experiments/mdtest-cold-metadata-rq2-preflight/20260731T002221Z-mdtest-preflight03/
```

The review also checks the experiment plan, the three attempt records, the
vCPU-affinity repair and review, the current launcher code, and the relevant
upstream virtme-ng fixes.

## Independent Review

Independent reviewer `019fb591-5fc4-78a3-b7d6-48d52add2a80` returned:

```text
run status: incomplete
claim verdict: unresolved
artifact validity: three preflights produced no valid workload observation;
  attempt 3 validly proves only vCPU pinning and independent verification
next paper decision: formal cannot run; close the experiment as incomplete
Final verdict: NO-GO
```

The reviewer also found two over-attributions in the attempt records. The
records were corrected to state only what the artifacts prove:

- attempts 1 and 2 do not establish which QMP client connected first, which
  client owned the endpoint, or why the server closed; and
- commit `3beedfe9f86e1cf34335282c4f7df4156748b83d` is included in
  virtme-ng v1.41, while the later timing repair
  `8f74cceecb163a5d5b08e70c101de85920eb624c` is not.

## Artifact Judgment

Attempt 1 failed before the workload because the exact vCPU-affinity gate found
host-wide masks. Attempt 2 failed before the workload because the installed
asynchronous QMP pin path failed capability negotiation and the independent
verifier could not connect.

Attempt 3 proves that the replacement controller and independent verifier both
produced the exact ordered singleton mapping for all eight vCPUs. The launcher
then exited before the guest affinity barrier. It produced no guest, ext4,
mdtest, MPI, FUSE, BPF, phase, or performance observation.

The affinity artifacts are valid infrastructure evidence. They are not an RQ2
workload result. None of the three roots can support a correctness,
throughput, latency, or FUSE-comparison claim.

## Decision

```text
run status: incomplete
tested hypothesis: inconclusive
research value: dependency-only
paper impact: none
next paper decision: do not run formal and do not cite this experiment
Final verdict: NO-GO
```

All three allowed real preflight attempts are exhausted. This experiment closes
without RQ2 evidence. Reopening it would require a new reviewed experiment plan
and an official launcher path that preserves separate launcher, QEMU, guest,
controller, and verifier failure evidence.
