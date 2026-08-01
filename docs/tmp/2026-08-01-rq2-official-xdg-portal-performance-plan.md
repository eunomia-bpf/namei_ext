# Experiment Plan: RQ2 official Documents portal comparison

## Research Question

- RQ exactly as written in the paper: What is the cost of putting
  programmable policy on the VFS name-resolution path compared with a
  feature-equivalent FUSE policy implementation?
- Specific uncertainty tested here: does the W1 application-visible cost show
  the same direction in an unmodified official FUSE implementation after
  restricting measurement to the existing-object grant/view behavior that
  both mechanisms already implement correctly?
- Why the answer matters: the current Agent and FxMark FUSE implementations
  are project-owned. A reviewer can attribute their results to daemon design
  choices rather than the name-resolution placement boundary.

## Paper-Value Admission

- Planned role: decisive baseline-credibility test supporting RQ2.
- Largest credible paper story this experiment could unlock: the direction
  established by the causal feature-equivalent Agent/FxMark comparisons is
  also visible in the W1 application path of an unmodified official FUSE
  implementation.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the existing FUSE baselines may be weak or tuned in favor of `namei_ext`.
- Independent evidence added beyond existing runs and published results:
  official `xdg-document-portal` 1.22.1 supplies the executed FUSE baseline,
  its own grant/revoke behavior supplies the oracle, and kernel tracepoint plus
  process observations attribute FUSE requests and daemon cost.
- Why the result is not tautological, already settled, or dominated: the
  completed W1 run established state-by-state correctness but deliberately
  collected no performance result. Published portal behavior does not provide
  a matched numerical comparison on this host and operation stream.
- Paper decision if positive: retain the feature-equivalent Agent/FxMark rows
  as the only placement-causal comparison and add the portal row as
  official-source external-validity evidence for W1.
- Paper decision if contradictory, mixed, or inconclusive: retain the existing
  feature-equivalent RQ2 answer but do not claim that its direction generalizes
  to the W1 official implementation.
- Best alternative experiment and why this one has higher decision value:
  more syscall or cold-cache breadth would leave baseline credibility
  unchanged; another RQ1 or Wrapfs workload would repeat already established
  expressiveness or ownership structure.

## Expected And Alternative Outcomes

- Current expected answer: `namei_ext` has lower W1 state-observation latency
  and auxiliary CPU/context-switch cost than the official portal path. This
  experiment cannot attribute the whole difference to hook placement because
  the complete implementations and their cache policies are not
  feature-equivalent.
- Strongest competing explanation: the portal's kernel caching may absorb most
  lookups, or the operation bundle may be dominated by lower-file read and
  directory work, making the two mechanisms indistinguishable.
- Result that would contradict the expectation: the paired confidence
  interval for portal/`namei_ext` primary latency is at or below one while all
  correctness and fairness checks pass.

## Published Precedent And Real Assets

- Closest published protocol: the official Documents portal API and its
  upstream `test-doc-portal` behavior; the existing RQ1 formal run already
  executes the source implementation and five-state oracle.
- Official system/model/data/benchmark/tool and version:
  unmodified `xdg-document-portal` 1.22.1 at peeled release commit
  `1d20fadc304f6601452b5db65ed91197dba77041`.
- What is reused: the unmodified portal and permission-store binaries, private
  D-Bus fixture, `Add`, `GrantPermissions`, `RevokePermissions`, by-application
  view, lower payload, modified-kernel KVM path, and current `namei_ext` policy.
- Necessary deviations or custom glue: timed application observations,
  matched relative path layout for the `namei_ext` arm, per-thread resource
  snapshots, portal-connection FUSE tracepoint counts during the isolated
  measured window, pairing, and statistical analysis. The official source is
  not patched. The source gate runs its current `unit` and
  `integration/documents` Meson suites before the project W1 oracle.

## Comparison

- Proposed system or method: `namei_ext` selecting or hiding the registered
  existing document directory for application A.
- Main baseline and competing position: unmodified official Documents portal
  FUSE is an official-source external-validity baseline. It represents
  implementing this path view inside a maintained filesystem service.
- Why the main baseline needs a matched run instead of citation alone: its
  cache behavior, request path, daemon cost, and guest performance are not
  available from a publication for this exact existing-object oracle.
- Controls or ablations: direct lower-object operations calibrate lower-FS and
  clock cost; the existing five-state source/namei oracle gates both arms.
  These are controls, not competing baselines.
- Conclusion if the baseline matches or wins: the W1 official-source result
  does not generalize the feature-equivalent advantage; it does not refute the
  Agent/FxMark placement result.
- Information, tuning, and compute fairness: both arms pre-open the
  application-view parent, not the selected document. From that dirfd, both
  use a two-component relative path whose document-ID component is exactly 22
  bytes and whose payload component is exactly `payload.txt`. The official ID
  is source-generated; the `namei_ext` arm uses a fixed 22-byte ID because the
  arms run in separate fresh boots. Both use the same payload bytes, syscall
  sequence, flags, timing boundaries, warmup, sample count, four vCPUs, ext4
  lower storage, and pinned host CPUs. The portal remains unmodified with its
  source-defined cache policy. The ten boot pairs alternate arm order.

The baseline is not called feature-equivalent as a whole. Its D-Bus service,
permission store, synthetic hierarchy, metadata presentation, and broader
portal semantics remain additional responsibilities. Only the timed
application-visible transaction has a matched correctness oracle. The portal
also gives virtual directories 60-second entry/attribute validity while
physical entries use zero-second validity. `namei_ext` follows the lower ext4
cache behavior. These source-defined policies are recorded, not presented as
cache-equivalent.

## Workloads And Metrics

- Real workload: application A observes one granted existing host document
  through `by-app/<app>/<22-byte-document-id>/payload.txt`; application B and
  the revoked application observe absence.
- Frozen primary transaction: starting from the pre-opened application-view
  parent dirfd, execute in order: (1) `fstatat(document-id,
  AT_SYMLINK_NOFOLLOW)`, (2) `fstatat(document-id/payload.txt, 0)`, (3)
  `openat(document-id/payload.txt, O_RDONLY|O_CLOEXEC)`, read the complete
  27-byte payload through EOF, and close, then (4) fresh
  `openat(".", O_RDONLY|O_DIRECTORY|O_CLOEXEC)`, `getdents64` through EOF,
  and close. Timing starts immediately before the first `fstatat` and ends
  after the directory fd closes. The required parent entries are exactly
  `.`, `..`, and the one 22-byte document ID in both arms.
- Primary metric: per-boot median latency of that frozen W1
  state-observation transaction. For each boot pair, compute the log latency
  ratio and report the geometric mean portal/`namei_ext` ratio over ten pairs
  with a pair-level bootstrap 95% confidence interval.
- Secondary metrics: p95/p99 transaction latency; per-operation latency;
  aggregate CPU runtime, run-queue wait, and voluntary/involuntary context
  switches over every portal daemon thread; client CPU/context switches;
  FUSE requests keyed by the portal connection and opcode; BPF
  lookup/readdir/action counts; grant and revoke acknowledgement latency plus
  the first immediate post-ack oracle. Grant/revoke costs are reported for
  each implementation separately, not as a feature-equivalent ratio.
- Correctness check or ground truth: all five existing W1 states pass exact
  errno, visibility, complete payload-byte, directory-membership, lower-object,
  isolation, revoke, cleanup, and dmesg checks before performance is
  interpreted. Every timed sample must pass the visible-state oracle.
- Repetitions, seeds, and uncertainty: one real preflight pair; formal matrix
  of ten independent pairs (20 fresh boots), alternating arm order. Each boot
  uses 1,000 warmup transactions and 10,000 measured transactions. The direct
  lower control runs the same 1,000 warmups and 10,000 samples in every boot.
  Analysis uses 10,000 pair-level bootstrap resamples with seed 20260801.
- Cost estimate: about 20 formal KVM boots after preflight; source artifacts and
  modified kernel are already built.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| preflight | real path | five-state oracle plus shortened visible loop | portal and `namei_ext` in separate boots | 1 pair | proves source, attach, timing, counters, and cleanup execute |
| formal | proposed | frozen W1 state-observation transaction | `namei_ext` | 10 boots | proposed side of paired external-validity result |
| formal | official-source baseline | frozen W1 state-observation transaction | official portal FUSE | 10 boots | tests baseline credibility and W1 external validity |
| formal | control | same transaction on a direct ext4 layout | ext4 | 10,000 samples per boot | reports lower-storage and boot sensitivity |

## Execution

- Authoritative command or workflow:
  `make experiment-application-file-sharing-rq2-official RUN_ID=<fresh-id>`.
- Real preflight case:
  `make kvm-application-file-sharing-rq2-official-preflight RUN_ID=<fresh-id>`.
- Full completion rule: the unmodified 1.22.1 source build, selected upstream
  test suites, one-pair real KVM preflight, all 20 expected formal boots, every
  five-state and timed-sample oracle, exact source/kernel versions, arm order,
  frozen syscall stream and path layout, positive per-connection/opcode FUSE
  or BPF engagement, all-thread resource windows, cleanup, and dmesg pass;
  then the paired analysis and report complete.
- Raw-result path:
  `results/experiments/application-file-sharing-rq2-official/<RUN_ID>/`.
- Checkpoint or recovery approach: each boot is a separate immutable result
  directory; any failed formal root remains failed and the affected complete
  paired matrix reruns under a fresh run ID after a reviewed implementation
  correction.

## Interpretation

- Positive result: the paired primary interval is entirely above one and all
  correctness/fairness gates pass. This supports official-source external
  validity for W1; placement causality continues to come only from the
  feature-equivalent Agent/FxMark experiments.
- Negative or contradictory result: the interval is entirely at or below one
  under valid gates; do not claim an official-source advantage.
- Mixed or inconclusive result: interval crosses one or mechanism attribution
  is missing; preserve the row outside the paper superiority claim. Arm order
  and direct-lower pair ratios are predeclared sensitivity results and cannot
  be used as a post-hoc veto of an otherwise valid primary estimator.
- Target paper figure or table: keep causal feature-equivalent results and
  official-source external-validity results visually separate. Use one compact
  paired-latency plot for the frozen W1 transaction plus a decomposition table
  for operations, requests, and daemon resources. Startup and total portal
  lifecycle time are excluded.

## Reproducibility Notes

- Software and data versions: portal 1.22.1 at the commit above; modified Linux
  commit recorded at execution; fixed 27-byte host payload; ext4 lower tree.
- Config and seed notes: four guest vCPUs, eight GiB guest memory, host-vCPU
  pinning, fixed warmup/sample counts, bootstrap seed 20260801.
- Known deviations: timed-loop and measurement code are project adapters; the
  official portal source and cache policy are unchanged. The official-source
  baseline owns broader semantics than the `namei_ext` subset, so only the
  matched application-visible slice is compared numerically and no whole-cost
  difference is attributed solely to placement.
