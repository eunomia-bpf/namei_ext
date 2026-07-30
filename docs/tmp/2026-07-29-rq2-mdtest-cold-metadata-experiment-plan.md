# Experiment Plan: RQ2 mdtest Cold Metadata

Status: independently reviewed and approved for implementation and one real KVM
preflight. Formal execution remains prohibited until the implementation and
preflight evidence receive their own reviews.

The 2026-07-30 revision resolves the paused draft's source and baseline
questions:

1. pin the current official IOR 4.0.0 release at commit
   `967a9f65109760db8a3ac14a7fdd007f337d2960`; its release notes explicitly
   include broad mdtest correctness fixes;
2. build the official libfuse 3.18.2 low-level
   `example/passthrough_ll.c` at commit
   `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7` and use that unmodified binary
   for timing;
3. include a matched stock-kernel control in the same workload matrix;
4. require the real preflight to prove intermediate-directory selection for
   unmodified mdtest create, cold stat, and cold remove; and
5. use five conditions, ten paired blocks, and 50 formal boots after fixing the
   cache and CPU-allocation protocol below.

The independent review on 2026-07-30 returned NO-GO on the first review round.
This revision adds mdtest's official hard-warning mode, freezes the exact
summary statistic, uses homogeneous host cores, supplies complete root-safe MPI
and foreground FUSE commands, aligns the selected component with the logical
path, and fixes the ext4 construction protocol. A follow-up review confirmed
that all six blocking findings are closed and returned GO. The review history is
`docs/tmp/2026-07-30-rq2-mdtest-cold-metadata-plan-review.md`.

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

- Planned role: decisive for the cache-cold and mutating-metadata scope of RQ2.
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

- Current expected answer: `SELECT` has higher median mdtest per-iteration
  aggregate operations per second than feature-equivalent FUSE for file
  creation, cold stat, and cold removal at both one and four ranks; each paired
  95% bootstrap interval for `SELECT/FUSE` is above one.
- Strongest competing explanation: ext4 and cache-drop costs dominate enough
  that the FUSE request path no longer matters, or policy dispatch and target
  selection cost as much as FUSE after metadata caches are discarded.
- Result that contradicts the expectation: any operation/rank cell has a paired
  `SELECT/FUSE` confidence interval entirely below one. An interval crossing
  one is inconclusive for that cell.

## Published Precedent And Real Assets

- Official benchmark: IOR/mdtest 4.0.0, commit
  `967a9f65109760db8a3ac14a7fdd007f337d2960`, from
  <https://github.com/hpc/ior>.
- Official operation definitions: mdtest's POSIX file create, stat, and remove
  phases and its reported per-iteration aggregate operation rate. For rates,
  mdtest takes the slowest post-barrier rank rate, multiplies it by the rank
  count, and summarizes that aggregate across internal iterations. With
  `-i 1`, the per-iteration Max, Min, and Mean columns contain the same one
  aggregate observation. The parser uses the Mean column from the matching
  `SUMMARY rate` row.
- Published use: metadata-service papers including IndexFS and InfiniFS use
  mdtest create/stat/remove rates; InfiniFS follows prior work in using
  zero-length files to isolate metadata performance.
- Official FUSE baseline: libfuse 3.18.2, commit
  `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7`, using its unmodified
  low-level `example/passthrough_ll.c`. Meson builds a release-mode static
  libfuse and links the example against that pinned library, so no host
  libfuse can enter the measured baseline.
- Filesystem: every rank-count cell creates a 2 GiB sparse image under a
  guest-local 4 GiB tmpfs, formats it as ext4 with 262,144 inodes and
  `lazy_itable_init=0,lazy_journal_init=0`, and mounts it with `noatime`.
  The source/target directory is a new empty `bench` directory under that
  ext4 mount. The maximum formal cell creates 131,072 zero-length files.
- Runtime: Open MPI 4.1.6 with one or four local ranks.
- Necessary glue: one controller configures the logical view, launches the
  unmodified mdtest binary, remounts the official FUSE view between phases,
  drops caches before stat and removal, validates the resulting tree, and
  records BPF or FUSE engagement. No mdtest or libfuse passthrough source patch
  is allowed in the timed comparison.

## Comparison

### Proposed mechanism

`SELECT` attaches the existing `cgroup/namei_ext` policy to the mdtest process
group. Lookup of the logical `view` component under
`/run/namei-ext-mdtest/logical` selects the registered physical
`/run/namei-ext-mdtest/ext4/bench` directory. File creation, stat, removal,
inode lifetime, and all data and metadata semantics remain lower-ext4
operations.

### Main baseline

Feature-equivalent FUSE is the only main baseline. It exposes the same ext4
directory at the same logical pathname through the official libfuse 3.18.2
low-level passthrough example on the patched kernel with no `namei_ext` program
attached. It runs multithreaded with
`default_permissions`, `cache=always`, `timeout=86400`, and `clone_fd`, which
favor FUSE caching and multithreaded request receipt within each phase. The
source's callback table covers the mdtest-required lookup, getattr, create,
mkdir, unlink, rmdir, open, release, and readdir operations. FUSE is run because
the paper needs a matched numerical comparison on this exact workload;
citation alone cannot establish the cost of this policy.

The FUSE daemon is recreated before create, stat, and remove. The view is
unmounted after each phase, so no FUSE dentry, inode, or attribute cache can
survive into the next phase. The lower ext4 filesystem remains mounted and
retains the same namespace. This gives FUSE favorable caching within a phase
while making the stat and remove phase starts comparable to the cache-dropped
non-FUSE conditions.

If FUSE matches or wins while the correctness and engagement gates pass, the
paper cannot claim an RQ2 advantage for that operation.

### Controls

- `unattached`: the same modified kernel and logical path with no policy. This
  is the lower-bound control for total metadata-path cost. The physical
  `bench` directory is bind-mounted at logical `view`.
- `PASS`: the same exact-parent attachment and operation mix, but the decision
  continues ordinary lookup. The physical `bench` directory is bind-mounted at
  logical `view`; the policy runs on `view` before normal lookup reaches that
  mount. This isolates dispatch and BPF policy cost.
- `SELECT`: the proposed registered-target path.
- `stock`: the matched stock kernel with the same ext4 image and logical bind
  mount. This controls whether the patch changes cold or mutating metadata even
  while unattached.

Stock and patched kernel configurations are identical except for
`CONFIG_NAMEI_EXT`. All five conditions use the same ext4 format, logical path
length, item count, rank placement, phase commands, cache-drop sequence, and
host CPU pin. Filebench is not added because it would introduce a weaker
second workload without changing the paper decision.

The guest has eight vCPUs. mdtest ranks are confined to vCPUs 0--3 in every
condition. The multithreaded FUSE daemon is confined to vCPUs 4--7, so the
four-rank client receives the same four cores as every non-FUSE condition and
the baseline is not starved of daemon CPU. The QEMU vCPUs are pinned in order
to homogeneous host CPUs 8--15, all of which report the same 3.2 GHz maximum
frequency and distinct core IDs. Turbo is disabled and the performance
governor is enabled. Daemon CPU time and context switches are reported
separately rather than hidden from the comparison.

## Workload And Metrics

Each cell runs unmodified mdtest with POSIX, file-only, unique-per-rank
directories, one iteration, and zero-length files:

```text
timeout --signal=TERM --kill-after=10s 900s \
  taskset -c 0-3 mpirun --allow-run-as-root \
  --bind-to core --map-by core --report-bindings -np <ranks> \
  mdtest -a POSIX -F -u -i 1 -n <items-per-rank> \
  --warningAsErrors \
  -d /run/namei-ext-mdtest/logical/view
```

Before each FUSE phase, the controller launches the pinned binary in the
foreground and confines all of its threads to guest vCPUs 4--7:

```text
taskset -c 4-7 passthrough_ll -f \
  -o source=/run/namei-ext-mdtest/ext4/bench \
  -o default_permissions,cache=always,timeout=86400,clone_fd \
  /run/namei-ext-mdtest/logical/view
```

Mount readiness has a 30-second timeout. Every mdtest phase has the 900-second
timeout shown above; FUSE shutdown has a 30-second timeout; and each KVM boot
has a 7,200-second hard timeout. Any timeout fails the cell or boot.

The controller invokes the official phases separately:

1. mount or select the logical view and run create-only (`-C`);
2. verify the source-derived exact file and directory cardinality;
3. for FUSE, unmount the create view; then `sync`, write `3` to
   `/proc/sys/vm/drop_caches`, remount FUSE when applicable, and run stat-only
   (`-T`);
4. verify the namespace is unchanged;
5. unmount FUSE when applicable; then `sync`, write `3` to
   `/proc/sys/vm/drop_caches`, remount FUSE when applicable, and run
   remove-only (`-r`);
6. verify that the ext4 test root is empty.

The split invocation preserves mdtest's phase implementations while making the
stat and removal phases explicitly cache-cold. The source preflight must first
confirm that the separate 4.0.0 invocations create, stat, and remove the same
names without an mdtest patch. Raw output preserves each mdtest stdout/stderr,
mount state, `/proc/meminfo` before and after each drop, and the requested
cache-drop value, requested bytes, actual `write(2)` return value, and `errno`.

Primary metrics:

- mdtest-reported per-iteration aggregate file-creation operations/s;
- mdtest-reported per-iteration aggregate cold-file-stat operations/s;
- mdtest-reported per-iteration aggregate cold-file-removal operations/s.

The parser first locates `SUMMARY rate: (of 1 iterations)`, then matches exactly
one `File creation`, `File stat`, or `File removal` row. With default
per-rank-detail output disabled, each row must contain exactly four numeric
columns: per-iteration Max, Min, Mean, and Std Dev. The parser records the third
numeric column, Mean. Because `-i 1`, it also requires Max, Min, and Mean to
agree within printed precision and Std Dev to be zero. It rejects duplicate or
missing summaries, non-finite values, and any warning or error output. It does
not recompute throughput from controller wall time.

Primary comparison: paired `SELECT/FUSE` median ratio and 95% bootstrap
confidence interval for every operation and rank count.

Secondary decomposition:

- `PASS/unattached` and `SELECT/PASS` ratios;
- client and FUSE daemon user/system CPU time and context switches;
- FUSE daemon liveness and `/dev/fuse` ownership during each phase;
- BPF attachment identity and an untimed post-phase operation-attribution
  probe;
- cache-state observations immediately before and after each drop.

Correctness gates timing:

- every mdtest phase exits zero and reports the expected nonzero create, stat,
  or remove rate with the other file-operation rates zero;
- every phase uses `--warningAsErrors`, and neither stdout nor stderr contains
  an mdtest warning or error;
- exact file and directory cardinality holds after create and stat;
- after create and stat, recursive cardinality including the physical `bench`
  root is exactly `items * ranks` regular files and `ranks + 2` directories;
  after removal, `bench` exists and has no children;
- in every condition, the process leader and the exact
  `OMPI_COMM_WORLD_RANK=0..ranks-1` set are observed in the declared cgroup;
- `PASS` and `SELECT` retain one stable attached program identity;
- the untimed `PASS` and `SELECT` probes exercise the attached program after
  each measured phase without enabling BPF runtime statistics during timing;
- `SELECT` resolves the logical root to the registered ext4 object;
- every FUSE phase uses the official low-level passthrough binary, has a live
  daemon that owns `/dev/fuse`, and exposes FUSE_SUPER_MAGIC at the logical
  path; exact lower-tree creation and removal prove the mounted path forwarded
  the mutating operations;
- the phase row contains the actual ext4 `statfs(2)` filesystem type, lower
  ext4 is mounted in every condition, all cleanup completes, and no
  residual BPF attachment, FUSE mount, open `/dev/fuse` descriptor, loop
  device, or workload cgroup remains;
- the declared kernel failure scan has no project-relevant diagnostic.

The benchmark records source and kernel Git commits, config, commands, raw
stdout/stderr, mount information, observations, CPU placement, and tool
versions.

The owning target validates raw observations and publishes analysis while the
run state is still `running`. Only after successful atomic analysis publication
does it mark the run `completed`; the analysis target rejects completed runs
and pre-existing final analysis output.

## Planned Runs

| Run group | Role | Conditions | Ranks | Items/rank | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | ---: | --- |
| real preflight | dependency | stock, unattached, PASS, SELECT, FUSE | 1, 4 | 4,096 | 1 paired block | proves the exact source, ext4, cache-drop, policy, FUSE, MPI, parser, CPU placement, and cleanup paths run |
| formal matrix | decisive | stock, unattached, PASS, SELECT, FUSE | 1, 4 | 32,768 | 10 paired blocks | supplies six primary operation/rank comparisons and active-cost decomposition |

Each condition receives a fresh KVM boot. Conditions rotate across blocks.
Within a boot, the one- and four-rank cell order alternates by block, and every
cell receives a new ext4 image. Formal execution therefore consists of 40
fresh patched-kernel boots plus ten stock-kernel boots and 100 complete mdtest
lifecycles; no preflight sample enters the formal analysis.

## Execution

- Authoritative entrypoints:
  `make kvm-mdtest-cold-metadata-preflight RUN_ID=<fresh-id>` and
  `make experiment-mdtest-cold-metadata-rq2 RUN_ID=<fresh-id>`.
- Preflight result root:
  `results/experiments/mdtest-cold-metadata-rq2-preflight/<RUN_ID>/`.
- Formal result root:
  `results/experiments/mdtest-cold-metadata-rq2/<RUN_ID>/`.
- A preflight passes only when all ten cells complete and an independent
  reviewer recomputes the source, correctness, engagement, cache-drop, and
  cleanup evidence.
- At most three real preflight attempts are allowed. Host build failures before
  result-root creation do not count. A failed KVM root counts and remains
  immutable.
- The formal matrix is authorized only after implementation review and a valid
  preflight review. It completes only when all 100 cells and all 50 boots
  terminate and the analysis includes every declared cell.

## Interpretation

Validity is decided first. Any correctness, engagement, source, cache-drop,
cleanup, comparison-fairness, or matrix-completion failure makes the run
invalid/incomplete, and no performance verdict is assigned. For a valid complete
matrix:

- Positive: all six `SELECT/FUSE` intervals are above one.
- Contradictory: at least one interval is entirely below one.
- Mixed: no interval is entirely below one and at least one interval crosses
  one.

The target paper figure groups create, cold stat, and cold remove by rank,
normalized to FUSE with confidence intervals. A companion table reports raw
operations/s, active-policy ratios, untimed BPF attribution, FUSE daemon
resource use, and client CPU cost.
No geomean can turn a mixed or contradicted cell into a positive result.

## Reproducibility Notes

- IOR/mdtest: 4.0.0,
  `967a9f65109760db8a3ac14a7fdd007f337d2960`.
- libfuse: 3.18.2,
  `033844748010a3b8265bf1c90b9ae8ffe4cd9ca7`.
- Open MPI: 4.1.6 in the current build/runtime environment.
- IOR build: `CC=mpicc CFLAGS=-O2`, with the resulting unmodified `mdtest`
  binary and build log captured.
- libfuse build: Meson release mode with
  `default_library=static`, `examples=true`, `tests=false`, `utils=false`, and
  `enable-io-uring=false`; the static link and version output are checked
  before KVM.
- Kernel: the clean current modified-kernel commit captured by the run.
- Guest: eight vCPUs, 8 GiB memory, host CPUs 8--15, turbo disabled,
  performance governor, and the existing stable-TSC KVM command line.
- Formal analysis bootstrap seed: `20260729`.
- Formal analysis uses 10,000 paired bootstrap resamples and the percentile
  2.5th and 97.5th quantiles for each median-ratio interval.
- Expected wall time is two to eight hours for the complete 50-boot formal
  matrix on the current host; this estimate is scheduling information, not a
  correctness or result gate.
- The earlier source-feasibility probe covered mdtest 3.3.0 only and is now
  superseded. The real preflight must build and exercise the pinned 4.0.0
  source and official libfuse 3.18.2 baseline.
