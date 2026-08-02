# Experiment Plan: RQ2 mdtest Cold Metadata Reconsideration

## Research Question

- RQ exactly as written in the paper: What is the cost of programmable policy
  on the VFS name-resolution path compared with a feature-equivalent FUSE
  policy?
- Specific uncertainty tested here: whether the cache-hot FxMark result extends
  to standard file creation, cache-cold stat, and cache-cold removal over a
  large ext4 namespace.
- Why the answer matters: the current standard-benchmark evidence can be
  dismissed as read-mostly and cache-hot. Agent-workspace timing is a real
  matched workload, but it cannot answer this operation-level objection.

## Paper-Value Admission

- Planned role: decisive for the cold and mutating metadata scope of RQ2.
- Largest credible paper story this experiment could unlock: the lower
  filesystem continues to execute metadata operations after `namei_ext`
  selects a directory, avoiding the filesystem-method forwarding cost visible
  in a matched FUSE view across both hot and cold metadata paths.
- Strongest reviewer reject argument addressed: the apparent FUSE gap may be
  confined to cached lookup and directory enumeration and may disappear for
  cold or mutating metadata.
- Independent evidence added beyond existing runs: official mdtest 4.0.0
  create/stat/remove rates, explicit cache drops, fresh ext4 filesystems,
  one- and four-rank execution, and a matched official libfuse passthrough.
- Why the result is not tautological or already settled: neither published
  mdtest/FUSE measurements nor the existing FxMark matrix measure this VFS
  hook under the same cold and mutating operation stream.
- Paper decision if positive: answer RQ2 with the Agent-workspace macro result,
  cache-hot FxMark paths, and cold/mutating mdtest paths.
- Paper decision if contradictory, mixed, or inconclusive: retain the valid
  Agent and FxMark results and report the operation-specific boundary; do not
  average a losing or inconclusive cell into a favorable summary.
- Best alternative experiment and why this one has higher decision value for
  the selected RQ: DMTCP and Spindle remain required W5/W6 workload work, but
  they answer RQ1 rather than this RQ2 cold/mutating-cost uncertainty. A custom
  cold FxMark loop would be less standard and would not add create/remove.
  Reopening the closed Bazel/sandboxfs protocol would repeat an exhausted
  workload branch.

## Why Reconsideration Is Scientifically Legitimate

The reviewed 2026-07-29 mdtest plan remains the scientific protocol. Its three
preflights are closed and remain negative infrastructure evidence. None entered
the guest workload, so none supplies or contradicts an mdtest result.

This reconsideration is admitted only because the failed dependency now has an
official upstream replacement. The host still provides virtme-ng 1.40. The old
runner injected QMP and used a project-authored asynchronous pinning controller.
Attempt 3 verified the intended vCPU masks, but the launcher exited before the
guest barrier and did not preserve enough evidence to distinguish launcher,
QEMU, and guest-command failure. Upstream virtme-ng commit
`8f74cceecb163a5d5b08e70c101de85920eb624c` moves `--pin` into `virtme-run`
after module preparation and immediately before QEMU launch. This directly
addresses the documented QMP timing failure mode.

The new execution path must use that exact official commit and native
`--pin 8-15`; it must not invoke the project-authored pinning controller.
Upstream's pin thread has five attempts separated by one second. The host first
waits for the QMP TCP listener using a non-connecting socket-listener check.
After the listener appears, the mandatory read-only verifier waits six more
seconds before its first QMP connection, so native pinning has either completed
or exhausted its retry window even if launcher preparation was slow. It then
confirms all eight exact singleton masks and publishes the existing
verified-affinity record. The guest already waits for that record and may not
cross the workload barrier until verification succeeds; its 60-second bound
covers the 30-second listener wait, six-second separation, verifier retries,
and scheduling margin. A failed verifier
publishes a failed record and terminates the run. The launcher runs in verbose
mode; its combined launcher/QEMU exit status, verifier status, and guest
barrier/completion records are preserved separately. This is a new official
launcher dependency, not a fourth attempt under the old protocol.

## Expected And Alternative Outcomes

- Current expected answer: `SELECT` has higher median mdtest aggregate
  operations/s than FUSE for create, cold stat, and cold remove at one and four
  ranks, with each paired 95% bootstrap interval above one.
- Strongest competing explanation: ext4 and cache-drop work dominates, or
  `namei_ext` dispatch and selected-target continuation cost as much as the
  FUSE path for these operations.
- Result that contradicts the expectation: any valid operation/rank cell has a
  paired `SELECT/FUSE` interval entirely below one. An interval crossing one is
  inconclusive for that cell.

## Published Precedent And Real Assets

- Benchmark: official IOR/mdtest 4.0.0 at
  `967a9f65109760db8a3ac14a7fdd007f337d2960`.
- FUSE baseline: unmodified libfuse 3.18.2 low-level
  `example/passthrough_ll.c` at
  `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7`.
- Launcher: official virtme-ng at
  `8f74cceecb163a5d5b08e70c101de85920eb624c`, run from a Make-built cache.
- Filesystem and runtime: a fresh 2 GiB ext4 image per rank-count cell on a
  guest-local tmpfs; Open MPI 4.1.6; eight guest vCPUs mapped in order to host
  CPUs 8--15.
- Necessary glue: the existing controller creates the logical view, invokes
  unmodified mdtest phases, drops caches, checks the resulting tree, and
  records BPF/FUSE engagement. No benchmark or FUSE source patch is allowed.

## Comparison

- Proposed mechanism: `SELECT` maps the logical `view` directory to a
  registered ext4 directory and then returns metadata operations to normal
  VFS/lower-ext4 execution.
- Main baseline: official libfuse passthrough exposes the same lower directory
  at the same logical path, with favorable `cache=always`, long attribute
  timeout, `clone_fd`, a multithreaded daemon, and a 262,144 soft open-file
  limit. A matched run is necessary because published FUSE results do not use
  this policy, path, ext4 image, or mdtest matrix.
- Controls: stock kernel, patched kernel unattached, and attached `PASS`.
  These are lower-bound and mechanism-cost controls, not additional competing
  systems.
- Conclusion if FUSE matches or wins: no RQ2 advantage may be claimed for that
  operation/rank cell.
- Fairness: every condition uses the same ext4 format, logical path length,
  item count, rank placement, cache-drop sequence, and host CPU set. Clients
  use guest vCPUs 0--3; FUSE receives separate guest vCPUs 4--7, and its daemon
  CPU and context switches are reported.

## Workloads And Metrics

- Workload: unmodified mdtest POSIX file-only create, stat, and remove phases,
  using unique per-rank directories and zero-length files.
- Primary metrics: mdtest-reported per-iteration aggregate file creation,
  cache-cold file stat, and cache-cold file removal operations/s.
- Primary comparison: paired median `SELECT/FUSE` ratio and paired 95%
  bootstrap interval for each operation and rank count.
- Correctness: mdtest exits zero with warnings treated as errors; file and
  directory cardinality matches after create/stat; the lower tree is empty
  after remove; the intended BPF or FUSE mechanism is engaged; exact vCPU
  mapping, cleanup, and the declared kernel diagnostic scan pass.
- The summary parser and detailed per-phase oracle are exactly those frozen in
  the approved 2026-07-29 plan's "Workload And Metrics" section; this
  reconsideration does not weaken or reinterpret them.
- Repetitions: one real preflight block, then ten paired formal blocks. No
  preflight sample enters formal analysis.

## Planned Runs

| Run group | Role | Conditions | Ranks | Items/rank | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | ---: | --- |
| first preflight boot | dependency | stock only | 1, 4 | 4,096 | first boot of the real preflight | official launcher reaches the guest, exact pinning is independently observed, and real mdtest create/stat/remove lifecycles complete before any policy comparison runs |
| real preflight | dependency | stock, unattached, PASS, SELECT, FUSE | 1, 4 | 4,096 | 1 paired block | complete official benchmark, ext4, cache-drop, policy, FUSE, MPI, pinning, and cleanup paths execute |
| formal matrix | decisive | stock, unattached, PASS, SELECT, FUSE | 1, 4 | 32,768 | 10 paired blocks | supplies six operation/rank comparisons and mechanism-cost decomposition |

Attempt 1 is one fresh result root. Its first stock boot is the launcher probe;
only after that boot completes do the remaining four conditions execute in the
same root. The probe is not an independent paper experiment or separate result
root. The rotating order starts with stock, and Make stops before the other
conditions if it fails. Repair is allowed only when the pinned official source
did not execute as documented. A repeat of the old asynchronous QMP/controller
failure closes reconsideration immediately. At most three new real preflight
attempts are allowed.

## Execution

- Authoritative dependency and experiment paths must be Make targets. No host
  package upgrade or manually activated Python environment is part of the
  protocol.
- Real preflight entrypoint:
  `make kvm-mdtest-cold-metadata-preflight RUN_ID=<fresh-id>`.
- Formal entrypoint:
  `make experiment-mdtest-cold-metadata-rq2 RUN_ID=<fresh-id>`.
- Preflight raw root:
  `results/experiments/mdtest-cold-metadata-rq2-preflight/<RUN_ID>/`.
- Formal raw root:
  `results/experiments/mdtest-cold-metadata-rq2/<RUN_ID>/`.
- Full completion requires every declared condition, rank, operation, and
  repetition plus correctness, engagement, placement, and cleanup evidence.
  Missing cells are incomplete, not filtered.

## Interpretation

- Positive: all six valid `SELECT/FUSE` intervals are above one.
- Contradictory: at least one valid interval is entirely below one.
- Mixed: no interval is entirely below one and at least one crosses one.
- Inconclusive: correctness, mechanism engagement, comparison fairness, or
  matrix completion fails.
- Target paper figure: create, cold stat, and cold remove throughput grouped by
  rank count and normalized to FUSE, with paired confidence intervals. A small
  table reports raw operations/s, `PASS/unattached`, `SELECT/PASS`, client CPU,
  and FUSE daemon CPU/context switches.

## Reproducibility Notes

- The benchmark, FUSE implementation, launcher, kernel pair, and BPF policies
  are pinned by source revision.
- The old immutable preflight roots remain unchanged and are not inputs to the
  new result.
- The existing mdtest scientific matrix, parser, cache-drop sequence, and
  oracle remain fixed. Implementation changes are limited to selecting and
  invoking the official launcher, preserving its logs/status, and adapting the
  placement check to native `--pin` output plus independent verification.
- Remaining execution risk: the upstream pinning fix may still be incompatible
  with this host or guest setup. That is resolved only by the launcher probe;
  it is not paper evidence.

## Final Execution Outcome

All three permitted preflights were consumed. The final attempt completed the
stock, patched-unattached, `PASS`, and `SELECT` conditions with 24/24 passing
cells, but the official FUSE child exited before mounting because the guest's
initial `RLIMIT_NOFILE` hard limit was 4,096. The five-condition matrix is
incomplete, no formal run is authorized, and this protocol is closed. The
standalone execution record is
`docs/tmp/2026-08-02-rq2-mdtest-reconsideration-preflight-attempt-3.md`.
