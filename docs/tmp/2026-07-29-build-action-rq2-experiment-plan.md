# Experiment Plan: RQ2 Build Action View Cost

## Research Question

- RQ exactly as written in the paper: What is the cost of putting
  programmable policy on the VFS name-resolution path compared with a
  feature-equivalent FUSE policy implementation?
- Specific uncertainty tested here: whether the RQ2 advantage already seen in
  the AgentFS-derived lifecycle and cache-hot FxMark persists for a traditional
  Bazel action view with hundreds to thousands of existing inputs.
- Why the answer matters: Bazel's sandboxfs is the closest source-system
  precedent for arbitrary action views and explicitly trades cheap view setup
  for FUSE data-path overhead.

## Paper-Value Admission

- Planned role: supporting.
- Largest credible paper story this experiment could unlock: `namei_ext`
  preserves the source-derived Bazel action oracle while avoiding an official
  FUSE view's daemon data path on an input-heavy build action.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  the existing Agent result may be workload-specific and FxMark is synthetic;
  no traditional build action currently has a matched FUSE macro comparison.
- Independent evidence added beyond existing runs and published results: a
  real Bazel action, official sandboxfs, concurrent per-action views, and
  scale-dependent setup and action-execution measurements.
- Why the result is not tautological, already settled, or dominated: published
  sandboxfs results compare FUSE with symlink construction, not with a
  VFS-resident policy on the same action and host.
- Paper decision if positive: add a traditional build-action macro result to
  RQ2 and retain Build Action Sandboxing as supporting RQ1 breadth.
- Paper decision if contradictory, mixed, or inconclusive: retain the valid
  correctness result, report that this action shape does not establish a
  macro-cost advantage, and do not generalize the Agent/FxMark result to Bazel.
- Best alternative experiment and why this one has higher decision value:
  Toolchain/Dependency Environments are not yet implemented and have no
  source-native preflight. Build Action Sandboxing already has a passing real
  Bazel KVM oracle and an official FUSE comparator.

## Expected And Alternative Outcomes

- Current expected answer: at 2,048 declared inputs, `namei_ext` has lower
  barrier-to-completion action time than sandboxfs while both pass the same
  output, isolation, and lower-object oracles.
- Strongest competing explanation: Bazel and shell work dominate the action,
  kernel caching amortizes sandboxfs requests, or sandboxfs's positive mapping
  representation is better matched to the declared-input set.
- Result that would contradict the expectation: the paired 95% confidence
  interval for `sandboxfs / namei_ext` action time is at or below one at the
  primary scale, with both mechanisms correct and engaged.

## Published Precedent And Real Assets

- Closest published protocol: Bazel's 2018 sandboxfs evaluation used clean
  builds, ten repetitions, symlinked and sandboxfs execroots, and total build
  time:
  <https://blog.bazel.build/2018/04/13/preliminary-sandboxfs-support.html>.
- Official system/model/data/benchmark/tool and version:
  - Bazel 6.5.0 Linux x86-64, already checksum-pinned and validated in KVM.
  - sandboxfs 0.2.0 at commit
    `2305d34fe764a64cf4783b43315e6eb5322310d6`.
  - Source archive:
    `https://codeload.github.com/bazelbuild/sandboxfs/tar.gz/2305d34fe764a64cf4783b43315e6eb5322310d6`.
  - Archive SHA-256:
    `6e2388a8c3e4eda6f12a17eef7323f8b99938ef9187040295d43f3a84cc2541d`.
- What is reused: the official sandboxfs mapping/reconfiguration protocol, the
  existing Bazel binary and two-action concurrency barrier, the current
  `cgroup/namei_ext` policy path, and lower-object/output oracles.
- Necessary deviations or custom glue: the official sandboxfs source has no
  `Cargo.lock`, so the experiment pins a generated dependency lock. A runner
  creates two sandbox IDs and gives each Bazel process a private mount
  namespace that bind-mounts its sandboxfs view at the same absolute action
  path used by `namei_ext`.

## Comparison

- Proposed system or method: one `namei_ext` program attached at the cgroup
  root; action cgroup identity selects one existing input root and hides
  undeclared entries during lookup and readdir.
- Main baseline and competing position: official sandboxfs 0.2.0 represents
  the source system's answer that a reconfigurable FUSE filesystem should
  construct each action's arbitrary view.
- Why the main baseline needs a matched run instead of citation alone:
  published sandboxfs numbers use different applications, machines, kernels,
  and symlink baselines and cannot quantify the matched action data path here.
- Controls or ablations: none. Published symlink-forest results are cited, not
  rerun. Correctness, mechanism engagement, and empty pre/post external
  inventory are gates rather than baselines.
- Conclusion if the main baseline matches or wins: `namei_ext` remains
  expressive for this action oracle but has no demonstrated macro-cost
  advantage for the tested Bazel action shape.
- Information, tuning, and compute fairness:
  - each action has `N` declared and `N` undeclared existing files;
  - both mechanisms receive the same declared and undeclared sets;
  - `namei_ext` installs `N` hide decisions plus one root selection per action;
  - sandboxfs installs `N` read-only mappings per action, omitting undeclared
    files;
  - the generated BUILD file, command, expected output hash, lower objects,
    Bazel flags, CPU count, memory, and action concurrency barrier are
    byte-identical across mechanisms;
  - both conditions use the modified kernel so the kernel image is not a
    confounder, and no `namei_ext` program is loaded in the sandboxfs boot.

## Workloads And Metrics

- Real workload: two concurrent Bazel 6.5.0 genrules. Each action enumerates
  its view, verifies no undeclared name is visible, reads every declared file
  in lexical order, and emits the expected aggregate SHA-256.
- Input scales: 64, 512, and 2,048 declared files per action with the same
  number of physically existing undeclared files. The 2,048-file cell is
  primary because Bazel identifies hundreds or thousands of mappings as the
  motivating regime.
- Primary metric: per-block ratio of sandboxfs to `namei_ext`
  barrier-release-to-both-actions-complete time at 2,048 inputs.
- Secondary metrics: the same action-time ratio at 64 and 512 inputs; view
  setup time; total lifecycle time; daemon CPU time, context switches, and peak
  RSS; policy counters; sandboxfs mount and process identity.
- Correctness check or ground truth:
  - both Bazel actions overlap and exit zero;
  - action-specific aggregate output hashes match independently constructed
    expected hashes;
  - lookup and readdir expose every declared file and no undeclared file;
  - lower file identity, mode, size, and content hashes remain unchanged;
  - `namei_ext` records lookup, readdir, select, and hide actions;
  - sandboxfs is the mounted filesystem serving both action views and its
    daemon remains live for the measured window;
  - detach/unmount and process cleanup complete; dmesg is clean.
- Repetitions, seeds, and uncertainty: ten paired boot blocks, alternating
  condition order. Each boot runs three lifecycle samples per scale and reduces
  them to a per-boot median. Report paired ratios and a deterministic
  10,000-resample percentile bootstrap 95% confidence interval.
- Cost estimate: one paired preflight, then 20 formal KVM boots and 180
  two-action lifecycle samples.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| preflight | dependency | 64-input two-action Bazel oracle | `namei_ext`, sandboxfs | 1 paired block, 1 sample | proves both real paths execute; no paper claim |
| formal | proposed | 64/512/2,048-input two-action Bazel oracle | `namei_ext` | 10 boots, 3 samples/scale | proposed arm |
| formal | main baseline | same | sandboxfs 0.2.0 | 10 boots, 3 samples/scale | tests matched FUSE alternative |

## Execution

- Authoritative command or workflow:
  `make experiment-build-action-rq2 RUN_ID=<fresh-id>`.
- Real preflight case:
  `make kvm-build-action-rq2-preflight RUN_ID=<fresh-id>`.
- Full completion rule: exactly 20 completed formal boot roots, 180 passing
  lifecycle samples, 60 per scale, ten complete paired block ratios per scale,
  no missing/replaced/excluded cells, and all artifact and correctness gates
  pass before analysis.
- Raw-result path:
  `results/experiments/build-action-rq2/<RUN_ID>/`.
- Checkpoint or recovery approach: each boot is immutable. A failed boot fails
  the result root; it is never replaced inside that run.

## Interpretation

- Positive result: all correctness gates pass and the primary paired 95%
  confidence interval for `sandboxfs / namei_ext` action time is above one.
- Negative or contradictory result: all correctness gates pass and the primary
  interval is at or below one.
- Mixed or inconclusive result: correctness passes but the primary interval
  crosses one; scale trends and secondary costs are reported without a
  superiority claim.
- Target paper figure or table: one log-scale plot of action time and view
  setup time versus input count, plus a compact correctness/ownership row.

## Reproducibility Notes

- Software and data versions: Bazel 6.5.0; sandboxfs 0.2.0 commit and archive
  above; libfuse 2.9.9 ABI; the committed modified-kernel identity.
- Config and seed notes: four vCPUs, 8 GiB guest memory, fixed host CPU range,
  three samples per scale, ten alternating paired blocks, and a frozen
  bootstrap seed in committed configuration.
- Known deviations: the workload exercises sandboxfs through its official
  mapping protocol rather than Bazel's deprecated
  `--experimental_use_sandboxfs` integration so both arms use the identical
  generated action and explicit view lifecycle. It evaluates existing-object
  view construction, not Linux namespace/process/network sandboxing, remote
  execution, CAS transfer, or output upload.
