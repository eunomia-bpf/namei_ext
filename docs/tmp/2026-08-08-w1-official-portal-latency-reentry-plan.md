# Experiment Plan: RQ2 Official Documents Portal Latency Re-entry

## Research Question

- RQ exactly as written in the paper: **What is the cost of putting
  programmable policy on the VFS name-resolution path compared with a
  feature-equivalent FUSE policy implementation?**
- Specific uncertainty tested here: Whether the application-visible latency
  direction established with project-owned FUSE implementations also appears
  when W1 runs through the unmodified official Documents portal FUSE service.
- Why the answer matters: Without an official-system comparison, a reviewer
  can attribute the existing Agent and FxMark results to the project's FUSE
  daemon implementations rather than the placement boundary.

This is an official-source external-validity comparison. The complete portal
is not feature-equivalent to `namei_ext`, so placement causality remains with
the controlled Agent and FxMark experiments.

## Paper-Value Admission

- Planned role: decisive for RQ2 baseline credibility; supporting for the
  overall paper.
- Largest credible paper story this experiment could unlock: The lower
  application-visible cost observed in controlled comparisons is also present
  in a maintained, unmodified FUSE system that implements W1's industrial
  grant/view workflow.
- Strongest reviewer reject argument addressed: Existing FUSE baselines may be
  weak or tuned in favor of `namei_ext`.
- Independent evidence added: Ten paired modified-kernel KVM blocks using
  official `xdg-document-portal` 1.22.1, its source grant/revoke lifecycle,
  source-defined cache policy, and an identical application transaction.
- Why this is not already settled: Published portal behavior and the completed
  W1 correctness run provide no matched latency estimate. The previous timing
  protocol reached both mechanisms but invalidated the entire result because
  the portal daemon created a thread between two resource snapshots.
- Paper decision if positive: Add one official-source W1 latency row, clearly
  separated from the feature-equivalent causal comparisons.
- Paper decision if contradictory, mixed, or inconclusive: Keep W1 correctness
  and the controlled RQ2 results, but make no official-portal latency claim.
- Best alternative: W3 official sandboxfs has similar value but is closed for
  this breadth-first cycle after its single reviewed re-entry exposed an
  unexecuted readdir oracle. W5 total restart cost is dominated by DMTCP, and
  W7 version probes are dominated by Python startup. W1 is the strongest
  runnable official-system comparison whose primary path already executed.

## Re-entry Boundary

The prior plan and its three immutable preflights remain closed. The final
root completed 100 official-portal and 100 `namei_ext` transactions, exact
payload and directory oracles, FUSE request attribution, BPF action
attribution, cleanup, and dmesg checks. It became invalid because daemon thread
identity changed, making a secondary per-thread CPU subtraction undefined.

That resource statistic is unrelated to the primary client transaction
latency and does not invalidate correctness, mechanism engagement, baseline
fairness, or the latency clock interval. This protocol therefore removes
daemon CPU, scheduler runtime, context-switch deltas, and stable thread-set
matching from the declared result. It does not reinterpret or reuse latency
from the invalid root. It authorizes one fresh paired preflight and, only if
that passes, the unchanged ten-pair formal latency matrix.

## Expected And Alternative Outcomes

- Current expected answer: The paired confidence interval for official portal
  FUSE divided by `namei_ext` median transaction latency is above one.
- Strongest competing explanation: The portal's kernel caching absorbs most
  FUSE work, or ext4 reads and directory enumeration dominate both paths.
- Result that would contradict the expectation: Both mechanisms and every
  oracle pass, but the paired interval is entirely at or below one.

## Published Precedent And Real Assets

- Closest published protocol: The official Documents portal API and upstream
  `test-doc-portal` behavior define grant, application isolation, revoke, and
  the by-application view.
- Official system: unmodified `xdg-document-portal` 1.22.1 at peeled release
  commit `1d20fadc304f6601452b5db65ed91197dba77041`.
- Reused assets: official portal and permission-store binaries, private D-Bus
  fixture, `Add`, `GrantPermissions`, `RevokePermissions`, existing W1
  five-state oracle, the real `cgroup/namei_ext` path, and the existing timed
  client transaction.
- Necessary glue: A dedicated ext4 fixture, paired KVM orchestration,
  per-connection FUSE request counts, BPF action counts, and paired analysis.
  The official source and cache policy remain unchanged.

## Comparison

- Proposed mechanism: `namei_ext` selects or hides the registered existing
  document directory for application A.
- Main baseline: The unmodified official Documents portal FUSE service. It is
  the maintained filesystem implementation of the W1 application-sharing
  workflow.
- Why a matched run is necessary: No publication reports this exact client
  transaction on the same kernel, lower object, cache state, and host.
- Controls: Direct ext4 executes the same transaction; FUSE connection/opcode
  and BPF action counts gate mechanism engagement. The source lifecycle,
  application B, revoke, lower-object, cleanup, and dmesg checks gate
  correctness. They are controls, not additional baselines.
- If the baseline matches or wins: Do not generalize the controlled FUSE
  advantage to the official portal.
- Fairness: Both arms start from a pre-opened application-view parent and use
  the same two-component relative path length, payload bytes, syscall sequence,
  flags, warmup, sample count, vCPU allocation, ext4 lower storage, host CPU
  placement, and timing boundaries. Ten pairs alternate mechanism order.

The portal retains its source-defined metadata and entry caching, D-Bus
service, permission store, and synthetic hierarchy. These additional
responsibilities are why the result is external validity, not a
feature-equivalent placement comparison.

## Workload And Metrics

- Workload: Application A observes one granted existing host document through
  `by-app/<app>/<22-byte-document-id>/payload.txt`; application B and the
  revoked application observe absence.
- Frozen transaction: From the pre-opened application-view parent, run
  `fstatat` on the document ID, `fstatat` and `openat`/read/close on
  `payload.txt`, then open and fully enumerate the parent directory. Timing
  begins immediately before the first `fstatat` and ends after the directory
  descriptor closes.
- Primary metric: Per-boot median transaction latency. Compute one log
  official-portal/`namei_ext` ratio per paired block and report its geometric
  center and pair-level bootstrap 95% confidence interval.
- Secondary metrics: p95 and p99 transaction latency, per-operation latency,
  direct-ext4 sensitivity, FUSE request counts by opcode, and BPF lookup,
  `SELECT`, and scope-matched visible-readdir counts. No daemon or client
  resource-delta metric is declared.
- Correctness: The complete five-state W1 oracle, every timed sample, exact
  payload bytes, exact directory membership, isolation, immediate revoke,
  lower-object preservation, source tests, mechanism engagement, cleanup, and
  dmesg must pass before latency is interpreted.
- Repetitions and uncertainty: One paired preflight with 100 measured
  transactions per arm. Formal execution uses ten independent pairs, 1,000
  warmups and 10,000 measured transactions per boot, alternating arm order,
  and 10,000 pair-level bootstrap resamples with seed 20260801.
- Cost: Two preflight boots, then 20 formal boots if admitted.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| preflight | real-path gate | Five-state oracle plus visible transaction | official portal and `namei_ext` | one pair, 100 transactions per arm | Authorizes formal execution only if complete |
| formal | proposed | Frozen W1 transaction | `namei_ext` | ten boots, 10,000 transactions each | Proposed side of official-source result |
| formal | baseline | Frozen W1 transaction | official portal FUSE | ten boots, 10,000 transactions each | Tests official-source external validity |
| formal | control | Same operation bundle on direct ext4 | direct ext4 | 10,000 transactions per boot | Detects lower-storage and boot sensitivity |

## Execution

- Authoritative preflight:
  `make kvm-application-file-sharing-rq2-official-preflight RUN_ID=<fresh-id>`.
- Authoritative formal run:
  `make experiment-application-file-sharing-rq2-official RUN_ID=<fresh-id>`.
- Real preflight completion: Two fresh modified-kernel KVM boots reach the
  official portal and real `cgroup/namei_ext` mechanisms; all source,
  transaction, engagement, cleanup, and dmesg checks pass; analysis completes
  without requiring a stable process/thread identity set.
- Formal completion: Exactly 20 completed boots, ten complete alternating
  pairs, 200,000 passing measured transactions, complete direct controls,
  mechanism attribution, and paired analysis.
- Raw roots:
  `results/experiments/application-file-sharing-rq2-official-preflight/<RUN_ID>/`
  and `results/experiments/application-file-sharing-rq2-official/<RUN_ID>/`.
- Recovery: Result roots are immutable. This re-entry permits one preflight;
  a correctness, mechanism, or latency-analysis failure closes W1 for the
  current breadth-first cycle rather than starting another repair loop.

## Interpretation

- Positive: All gates pass and the paired portal/`namei_ext` interval is
  entirely above one. Report the exact ratio, interval, absolute latency,
  operation decomposition, and mechanism request counts.
- Negative: All gates pass and the interval is entirely at or below one. Make
  no official-source advantage claim.
- Mixed or inconclusive: The interval crosses one. Record the workload boundary
  and keep the row outside the paper superiority claim.
- Target paper result: One compact official-source latency row adjacent to,
  but visually distinct from, the causal feature-equivalent RQ2 comparisons.

## Reproducibility Notes

- Versions: portal 1.22.1 at the commit above; project and kernel commits,
  kernel release, libfuse version, and source test results captured per run.
- Configuration: Four guest vCPUs, 8 GiB memory, host CPUs 4--7, fixed 27-byte
  payload, fixed transaction, warmup and sample counts, and bootstrap seed.
- Known boundary: The result compares one matched application-visible slice,
  not complete filesystem functionality, startup, grant storage, daemon CPU,
  or total portal lifecycle cost.
