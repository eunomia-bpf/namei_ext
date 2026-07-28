# Service Configuration Rotation V2 Result Review

## Scope

Selected RQ:

> Can a narrow VFS name-resolution extension express real state-dependent
> path-view policies without taking over filesystem semantics?

Reviewed inputs:

- the V2 recovery plan and plan review;
- all three V2 preflight roots;
- final raw root
  `20260728T-service-config-rotation-v2-preflight-v3`;
- source commit `ac916d63aac8a310291b07c2a16ce1969d7aac4b`;
- kernel commit `bdc9a83e3dfbef8ff2017f9188c7c86025962183`;
  and
- runner, policy, kernel configuration, pinned kernel source, and Make
  finalization rules.

## Recomputed Checks

For V2 attempt 3:

- raw events: 16;
- completed state rows: 0 of 4;
- emitted state rows: 1 failed `current` row;
- case rows: 13 of the 15 required by the analyzer;
- policy-counter rows: 0 of 3;
- failed rows: the current state and final summary;
- artifact hashes: 9 of 9 valid; and
- input hashes: 26 of 26 valid.

The summary field `states: 4` is a declared workload constant, not evidence
that four states ran.

## Findings

### Acceptance Gate Failed

The run stopped in the first current-state readiness loop. Canary, invalid
reload, rollback, real worker temporary-file I/O, lower-object revalidation,
counter validation, dmesg gating, boot completion, and analysis did not run.
The result cannot answer the RQ or authorize the formal matrix.

### Undeclared Kernel Dependency

`read_single_worker()` requires
`/proc/<pid>/task/<pid>/children`. The captured Phase-1 kernel has
`CONFIG_PROC_CHILDREN` disabled, and the pinned kernel source exposes that file
only when the option is enabled. This is the strongest explanation for the
five-second readiness timeout. The proc failure short-circuits the combined
worker/HTTP/body condition before the HTTP probe.

The runner did not preserve the exact failing subcondition or errno. The
missing proc interface is direct evidence; the repeated `ENOENT` and HTTP
short-circuit are source-grounded inference.

### Partial Mechanism Engagement

The real policy attached, and current target 1 produced matching logical and
physical configuration hashes. The logical identity check also included an
in-cgroup directory probe. This confirms that the current lookup path engaged,
but there is no completed transition or final policy-counter evidence.

### No False Positive

The runner failed closed. It did not emit completed observations, seal boot
evidence, run the analyzer, or promote the root. Cleanup still reaped nginx,
captured its non-empty log, removed runtime state, detached the policy, cleared
targets, and removed the cgroup.

## Verdict

- Overall category: dependency evidence.
- Run status: terminally failed and incomplete.
- Tested hypothesis: not tested.
- Paper value: none.
- Paper decision: do not report W4 or any number from these roots.
- Repository decision: preserve all roots, close V2 after three attempts, keep
  the formal service-rotation entrypoint blocked, and remove its preflight from
  the current aggregate gate.

Any future execution requires a separately reviewed dependency plan. It must
not be represented as continuation of V2 or as a change to the selected RQ.
