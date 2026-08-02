# RQ2 mdtest Cold Metadata Reconsideration Plan Review

## Round 1

Independent reviewer `019fc17a-62ac-7d62-8d8c-bf452ce3e486` found the
reconsideration scientifically legitimate and higher-value than another RQ1
breadth case. The reviewer accepted official mdtest aggregate rates, the
unmodified libfuse passthrough baseline, the correctness oracle, and the
three-attempt budget. The initial verdict was `NO-GO` for one execution
blocker: the plan allowed the external verifier to connect while the upstream
native pin thread might still own or retry QMP.

The plan now freezes this ordering:

1. official virtme-ng commit `8f74ccee...` starts QEMU and native
   `--pin 8-15`;
2. the host observes the QMP TCP listener without opening a connection;
3. the external verifier then waits six seconds, longer than upstream's
   complete five-attempt, one-second retry window;
4. the verifier confirms all eight exact singleton masks and writes the
   verified-affinity record; and
5. the guest crosses its existing workload barrier only after that record is
   present and passing.

The revised plan also states that the first stock boot and the remaining
preflight conditions share one fresh result root, and explicitly incorporates
the original approved parser and detailed oracle without change.

## Follow-Up

The same reviewer examined the repaired ordering and returned:

```text
Blockers: none
Final verdict: GO
```

The reviewer requested one implementation check: bound the listener wait,
record when the listener was observed, and measure the six-second no-connect
window from that observation. Implementation review must verify those details
before a real KVM preflight.
