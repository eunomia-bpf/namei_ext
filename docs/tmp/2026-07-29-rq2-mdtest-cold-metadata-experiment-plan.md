# Experiment Plan: RQ2 mdtest Cold Metadata

Status: paused draft. This plan has not passed independent plan review. Do not
implement or run its KVM targets until the baseline and source decisions below
are repaired and reviewed.

Before admission, the next revision must:

1. verify the current official IOR/mdtest release and pin a reviewed upstream
   commit rather than assuming the feasibility-probe revision remains the
   final experiment source;
2. use or extend the official libfuse low-level passthrough example, with
   explicit callback coverage and cache settings, instead of assuming the
   existing project loopback is a sufficient create/stat/remove baseline;
3. include a matched stock-kernel condition in the same mdtest matrix, or
   obtain explicit plan-review approval for excluding it based on stronger
   same-workload evidence;
4. verify in a dependency preflight that selecting the intermediate ext4
   directory exercises the intended hook for create, cold stat, and remove
   without changing mdtest; and
5. re-evaluate the proposed 40-boot budget only after the official source,
   FUSE baseline, cache-drop method, and operation parser are concrete.

## Research Question

- RQ exactly as written in the paper: What is the cost of putting programmable
  policy on the VFS name-resolution path compared with a feature-equivalent
  FUSE policy implementation?
- Specific uncertainty tested here: whether the existing cache-hot lookup and
  directory-enumeration results extend to standard file creation, cache-cold
  stat, and cache-cold removal over a large ext4 namespace.
- Why the answer matters: the current RQ2 answer could be dismissed as a
  read-mostly, cache-hot result in which FUSE metadata caching hides daemon
  crossings and lower-filesystem work is small.

## Paper-Value Admission

- Planned role: decisive RQ2 breadth experiment.
- Largest credible paper story this experiment could unlock: `namei_ext`
  retains the lower filesystem's metadata path for both read-only and mutating
  operations, while a feature-equivalent FUSE view remains responsible for
  metadata requests even with favorable kernel caching.
- Strongest reviewer reject argument addressed: the measured advantage may
  disappear when dentries and inodes are cold or when the workload creates and
  removes objects rather than repeatedly reading cached metadata.
- Independent evidence added beyond existing runs: official mdtest file
  create/stat/remove phases, explicit cache dropping before stat and removal,
  a fresh ext4 filesystem per cell, a large namespace, and one- and four-rank
  MPI execution.
- Why the result is not tautological or already settled: published mdtest and
  FUSE results do not measure this VFS hook, its BPF dispatch, registered-target
  selection, or the matched policy view. Existing project results cover
  cache-hot FxMark stat and readdir, not cold or mutating metadata.
- Paper decision if positive: add one mdtest figure beside FxMark and answer
  RQ2 across cache-hot lookup, directory enumeration, and cold/mutating
  metadata.
- Paper decision if contradictory: retain the existing FxMark result, redesign
  the mechanism only if `namei_ext` itself causes the loss, and state that the
  cost advantage does not extend to the contradicted mdtest operations.
- Paper decision if mixed or inconclusive: report the operation-specific
  boundary without averaging it into a favorable geomean.
- Best alternative experiment: a second RQ3 workflow would strengthen boundary
  generality, but current reviewers can already reject the performance claim
  as cache-hot and read-mostly. A cache-cold FxMark extension would be less
  standard and would repeat stat without adding create/remove.

## Expected And Alternative Outcomes

- Current expected answer: `SELECT` has higher median mdtest mean operations
  per second than feature-equivalent FUSE for file creation, cold stat, and
  cold removal at both one and four ranks; each paired 95% bootstrap interval
  for `SELECT/FUSE` is above one.
- Strongest competing explanation: ext4 and cache-drop costs dominate enough
  that the FUSE request path no longer matters, or policy dispatch and target
  selection cost as much as FUSE after metadata caches are discarded.
- Result that contradicts the expectation: any operation/rank cell has a paired
  `SELECT/FUSE` confidence interval entirely below one. An interval crossing
  one is inconclusive for that cell.

## Published Precedent And Real Assets

- Official benchmark: IOR/mdtest 3.3.0, commit
  `9959a615fb7ca400a5b21b93be76f466cbb42b95`, from
  <https://github.com/hpc/ior>.
- Official operation definitions: mdtest's POSIX file create, stat, and remove
  phases and its reported mean operations per second. The upstream source
  computes each rank's aggregate operation rate and reports max, min, mean,
  and standard deviation.
- Published use: metadata-service papers including IndexFS and InfiniFS use
  mdtest create/stat/remove rates; InfiniFS follows prior work in using
  zero-length files to isolate metadata performance.
- Filesystem: a new local ext4 image for every cell. The image is formatted
  with enough inodes for the declared namespace and mounted inside the guest.
- Runtime: Open MPI 4.1.6 with one or four local ranks.
- Necessary glue: one controller configures the logical view, launches the
  unmodified mdtest binary, drops caches between official phases, validates the
  resulting tree, and records BPF or FUSE engagement. No mdtest source patch is
  allowed.

## Comparison

### Proposed mechanism

`SELECT` attaches the existing `cgroup/namei_ext` policy to the mdtest process
group. Lookup of one `bench` component under the exact logical parent selects a
registered ext4 directory. File creation, stat, removal, inode lifetime, and
all data and metadata semantics remain lower-ext4 operations.

### Main baseline

Feature-equivalent FUSE is the only main baseline. It exposes the same ext4
directory at the same logical pathname through the project's multithreaded
loopback implementation. It keeps
`default_permissions,kernel_cache,attr_timeout=3600,entry_timeout=3600,negative_timeout=3600`
and may use all four guest vCPUs. The implementation must provide every
callback required by the admitted mdtest phases and record measured callback
counts. FUSE is run because the paper needs a matched numerical comparison on
this exact workload; citation alone cannot establish the cost of this policy.

If FUSE matches or wins while the correctness and engagement gates pass, the
paper cannot claim an RQ2 advantage for that operation.

### Controls

- `unattached`: the same modified kernel and logical path with no policy. This
  is the lower-bound control for total metadata-path cost.
- `PASS`: the same exact-parent attachment and operation mix, but the decision
  continues ordinary lookup. This isolates dispatch and BPF policy cost.
- `SELECT`: the proposed registered-target path.

The matched-stock kernel is not rerun. The existing 60-boot host-pinned FxMark
confirmation already answers the unused cache-hot fast-path question, while
the present uncertainty is active-policy cost versus FUSE. Filebench is not
added because it would introduce a second weaker workload without changing the
decision.

All four conditions boot the same modified kernel, use the same ext4 format,
logical path length, item count, rank placement, phase commands, cache-drop
sequence, and host CPU pin. The FUSE daemon's CPU time and callback counts are
reported separately rather than hidden from the comparison.

## Workload And Metrics

Each cell runs unmodified mdtest with POSIX, file-only, unique-per-rank
directories, one iteration, and zero-length files:

```text
mdtest -a POSIX -F -u -i 1 -n <items-per-rank>
```

The controller invokes the official phases separately:

1. create-only (`-C`);
2. verify exactly `items * ranks` regular files and `ranks + 2` directories;
3. `sync`, write `3` to `/proc/sys/vm/drop_caches`, then stat-only (`-T`);
4. verify the namespace is unchanged;
5. `sync`, write `3` to `/proc/sys/vm/drop_caches`, then remove-only (`-r`);
6. verify that the ext4 test root is empty.

The split invocation preserves mdtest's phase implementations while making the
stat and removal phases explicitly cache-cold. The raw record includes
`/proc/sys/fs/dentry-state`, `/proc/sys/fs/inode-state`, `/proc/meminfo`, and
the exact successful cache-drop events before interpreting those phases.

Primary metrics:

- mdtest-reported mean file-creation operations/s;
- mdtest-reported mean cold-file-stat operations/s;
- mdtest-reported mean cold-file-removal operations/s.

Primary comparison: paired `SELECT/FUSE` median ratio and 95% bootstrap
confidence interval for every operation and rank count.

Secondary decomposition:

- `PASS/unattached` and `SELECT/PASS` ratios;
- client and FUSE daemon user/system CPU time and context switches;
- FUSE callback counts by operation;
- BPF program run count and run time, collected after the timed phases;
- cache-state observations immediately before and after each drop.

Correctness gates timing:

- every mdtest phase exits zero and reports the expected single nonzero
  operation;
- exact file and directory cardinality holds after create and stat;
- removal leaves the test root empty;
- the process leader and all MPI descendants execute in the declared cgroup
  for attached conditions;
- `PASS` and `SELECT` retain one stable attached program identity;
- `PASS` and `SELECT` have positive, operation-attributable policy counts;
- `SELECT` resolves the logical root to the registered ext4 object;
- FUSE is mounted for the complete measured lifecycle and records positive
  create/getattr/unlink/rmdir request counts;
- lower ext4 is mounted in every condition, all cleanup completes, and no
  residual BPF attachment, FUSE mount, open `/dev/fuse` descriptor, loop
  device, or workload cgroup remains;
- the declared kernel failure scan has no project-relevant diagnostic.

The benchmark records source and kernel Git commits, config, commands, raw
stdout/stderr, mount information, observations, CPU placement, and tool
versions.

## Planned Runs

| Run group | Role | Conditions | Ranks | Items/rank | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | ---: | --- |
| real preflight | dependency | unattached, PASS, SELECT, FUSE | 1, 4 | 4,096 | 1 paired block | proves the exact source, ext4, cache-drop, policy, FUSE, MPI, parser, and cleanup paths run |
| formal matrix | decisive | unattached, PASS, SELECT, FUSE | 1, 4 | 32,768 | 10 paired blocks | supplies six primary operation/rank comparisons and active-cost decomposition |

Each condition receives a fresh KVM boot. Conditions rotate across blocks.
Within a boot, the one- and four-rank cell order alternates by block, and every
cell receives a new ext4 image. Formal execution therefore consists of 40
fresh boots and 80 complete mdtest lifecycles; no preflight sample enters the
formal analysis.

## Execution

- Authoritative entrypoints:
  `make kvm-mdtest-cold-metadata-preflight RUN_ID=<fresh-id>` and
  `make experiment-mdtest-cold-metadata-rq2 RUN_ID=<fresh-id>`.
- Preflight result root:
  `results/experiments/mdtest-cold-metadata-rq2-preflight/<RUN_ID>/`.
- Formal result root:
  `results/experiments/mdtest-cold-metadata-rq2/<RUN_ID>/`.
- A preflight passes only when all eight cells complete and an independent
  reviewer recomputes the source, correctness, engagement, cache-drop, and
  cleanup evidence.
- At most three real preflight attempts are allowed. Host build failures before
  result-root creation do not count. A failed KVM root counts and remains
  immutable.
- The formal matrix is authorized only after implementation review and a valid
  preflight review. It completes only when all 80 cells and all 40 boots
  terminate and the analysis includes every declared cell.

## Interpretation

- Positive: all six `SELECT/FUSE` intervals are above one.
- Contradictory: at least one interval is entirely below one.
- Mixed: at least one interval crosses one and none is entirely below one, or
  operation directions differ.
- Invalid/incomplete: any correctness, engagement, source, cache-drop,
  cleanup, comparison-fairness, or matrix-completion gate fails.

The target paper figure groups create, cold stat, and cold remove by rank,
normalized to FUSE with confidence intervals. A companion table reports raw
operations/s, active-policy ratios, BPF runs, FUSE callbacks, and CPU cost.
No geomean can turn a mixed or contradicted cell into a positive result.

## Reproducibility Notes

- IOR/mdtest: 3.3.0,
  `9959a615fb7ca400a5b21b93be76f466cbb42b95`.
- Open MPI: 4.1.6 in the current build/runtime environment.
- Kernel: the clean current modified-kernel commit captured by the run.
- Guest: four vCPUs, 8 GiB memory, host CPUs 4--7, turbo disabled, performance
  governor, and the existing stable-TSC KVM command line.
- Formal analysis bootstrap seed: `20260729`.
- The source-feasibility probe built unmodified mdtest 3.3.0 with the available
  Open MPI toolchain and completed separate create, stat, and remove commands
  with one and two ranks. It is dependency evidence only.
