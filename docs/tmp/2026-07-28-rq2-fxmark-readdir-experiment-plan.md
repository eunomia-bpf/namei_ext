# Experiment Plan: RQ2 FxMark Directory Enumeration

## Research Question

- Paper RQ: What is the cost of putting programmable policy on the VFS
  name-resolution path compared with a feature-equivalent FUSE policy
  implementation?
- Exact uncertainty: does the `namei_ext` cost result extend from cache-hot
  `stat()` and an AgentFS-derived lifecycle to standard directory enumeration,
  where the policy decision executes once for every returned directory entry?
- Exact hypothesis: for corrected FxMark `MRDL` and `MRDM`, same-filesystem
  `SELECT` has higher median entry throughput than the matched FUSE view in
  every test/worker cell, with each paired 95% bootstrap interval above one.

Correctness gates every timing result. The experiment does not claim that all
FUSE filesystems, all directory workloads, or cache-cold pathname lookup have
the same result.

## Paper-Value Admission

- Planned role: primary RQ2 breadth result.
- Largest credible story unlocked: the cost advantage is not confined to
  cache-hit `stat()` or to the custom Agent workload; it also holds for
  standardized private- and shared-directory enumeration.
- Strongest reviewer objection addressed: `namei_ext` invokes a BPF decision
  for every returned directory entry, so the existing lookup-only FxMark result
  may conceal the mechanism's most expensive event type.
- Independent evidence added: `opendir`/`readdir`/`closedir`, private and
  shared directories, deterministic directory cardinality, per-entry policy
  execution, and measured FUSE directory requests.
- Why this is not redundant: the formal FxMark matrix contains only
  `MRPL`/`MRPM`/`MRPH` `stat()` tests. The Agent result includes readdir but is
  a project-specific lifecycle, not a standard filesystem benchmark.
- Positive paper decision: add one standard directory-enumeration figure and
  report `SELECT/FUSE`, `PASS/unattached`, and `SELECT/PASS` separately.
- Contradictory or mixed paper decision: retain the lookup result, report that
  directory enumeration does not show the same advantage, and do not
  generalize RQ2 across event types.
- Best alternative: mdtest provides broader create/stat/remove coverage, but
  it does not isolate the directory-enumeration event, adds an MPI/runtime
  dependency, and partly repeats ordinary lower-filesystem operations already
  covered by the Agent boundary matrix. Corrected FxMark directly tests the
  missing ABI event with the existing matched kernels and FUSE view.

## Frozen Source And Corrections

- Project: FxMark from the ATC 2016 filesystem scalability artifact.
- Commit: `3f29552ce7ba6be24c4172e6e2c2c1f603209953`.
- Archive:
  `https://codeload.github.com/sslab-gatech/fxmark/tar.gz/3f29552ce7ba6be24c4172e6e2c2c1f603209953`.
- Archive SHA-256:
  `b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae`.
- Tests: `src/MRDL.c` and `src/MRDM.c`.

The result must be labeled **corrected FxMark** and preserve the original
archive plus both repository patches. The existing correctness patch
propagates affinity and worker failures. A second, separately hashed patch
will make two source-grounded corrections:

1. Replace duration-dependent pre-work with exactly 8,192 files per worker.
   `MRDL` therefore has one private directory and 8,192 files per worker;
   `MRDM` has one shared directory and 8,192 uniquely named files per worker.
2. Treat `result == NULL` from `readdir_r()` as end of directory, close and
   reopen the directory, and count only entries actually returned. The
   uncorrected source repeatedly counts end-of-directory calls after the first
   scan and therefore does not measure repeated enumeration.

These corrections preserve the source operation and private/shared-directory
distinction while making workload size and completed work comparable across
conditions. They are not performance optimizations for `namei_ext`.

## Conditions

| Condition | Kernel | Path view | Expected measured behavior |
| --- | --- | --- | --- |
| `stock` | matched stock kernel | direct tmpfs path | unmodified-kernel control |
| `unattached` | patched kernel | direct tmpfs path, no BPF program | unused fast path |
| `pass` | patched kernel | direct tmpfs path with attached `PASS` | BPF decision for scoped lookup and every returned entry |
| `select` | patched kernel | nonexistent logical `view` component selects an existing tmpfs lower directory | one target selection on path open plus `PASS` for returned entries |
| `fuse` | matched stock kernel | libfuse 2.9.9 view over the same tmpfs lower tree | feature-equivalent userspace filesystem |

The stock and patched configurations must differ only by
`CONFIG_NAMEI_EXT`. FUSE runs on stock, may use all four guest vCPUs, and keeps
the existing favorable cache configuration:
`default_permissions,kernel_cache,attr_timeout=3600,entry_timeout=3600,negative_timeout=3600`.
These caches do not eliminate the need to serve directory reads.

The FUSE callback must obey directory offsets with `seekdir()`/`telldir()` so
large directories remain complete across multiple kernel requests. It must
record measured `opendir`, `readdir`, and `releasedir` request counts. The
setup-to-measured and measured-to-after transitions require acknowledgements
from the FUSE daemon; a cell must observe exactly one of each and no invalid
transition.

The cell controller pre-creates the benchmark root and every `MRDL` worker
directory before loading a policy for all five conditions. An attached policy
uses exact scopes rather than global dispatch:

- `work_root`, so `select` must resolve the nonexistent `view` component;
- the shared benchmark directory for `MRDM`; or
- each private worker directory for `MRDL`.

At four workers this uses five of the kernel's eight exact-scope slots.
Registering only `work_root` is invalid for this experiment because directory
iteration occurs on the selected lower directory, not on `work_root`.

## Workload And Correctness

Two corrected FxMark operations run at one, two, and four workers:

- `MRDL`: each worker repeatedly enumerates its own directory;
- `MRDM`: every worker repeatedly enumerates one shared directory.

Every cell must satisfy:

- FxMark exits zero and reports the declared worker count and duration;
- completed work is positive and equals returned directory entries, not EOF
  calls;
- the physical and logical trees have the exact expected file and directory
  cardinality after measurement;
- a validation child in the cell cgroup sees every physical entry through the
  logical view and records matching lower object identity;
- the benchmark leader is in the exact cell cgroup;
- `pass` and `select` retain one stable attached program ID;
- `select` succeeds only through the nonexistent logical `view` component;
- after timing, the parent enables kernel BPF run statistics and snapshots the
  attached program; an event-attribution child then enters the same cgroup,
  opens all logical directories, and stops at a synchronization barrier;
- the parent snapshots the program at that barrier and records the lookup
  delta;
- after the barrier, the child performs only fixed 4 KiB `getdents64` calls on
  those already-open directory descriptors and sends both the returned-entry
  count and non-empty syscall count through a pipe;
- the exact BPF readdir delta equals returned entries plus one candidate-entry
  retry for each non-final non-empty `getdents64` call on this experiment's
  tmpfs iterator. Thus
  `retry_runs = nonempty_calls - enumerated_directories` and
  `readdir_runs = returned_entries + retry_runs`; BPF statistics are disabled
  again before cleanup;
- FUSE retains a live FUSE superblock through validation, records positive
  measured `opendir`, `readdir`, and `releasedir` counts, then unmounts and
  exits zero;
- pre/post external BPF and FUSE inventories are empty;
- kernel identity, TSC clocksource, input/artifact hashes, and dmesg gates pass.
- the published analysis hashes its completed `run.json` and
  `observations.jsonl`, and the report target revalidates that binding.

Tree cardinality for `N=8192` is:

| Test | Files | Directories, including benchmark root |
| --- | ---: | ---: |
| `MRDL`, `W` workers | `N * W` | `1 + W` |
| `MRDM`, `W` workers | `N * W` | `1` |

## Metrics And Interpretation

- Primary metric: paired per-block `select/fuse` entry-throughput ratio for
  each of six test/worker cells.
- Primary positive rule: all six median ratios exceed one and every paired
  95% bootstrap interval has a lower bound above one.
- Primary contradiction: any cell has a paired interval upper bound at or
  below one.
- Mixed/inconclusive: neither rule holds.
- Mechanism decomposition, reported without a second composite verdict:
  `unattached/stock`, `pass/unattached`, `select/pass`, and
  `select/unattached`.
- Secondary metrics: raw entries/s, FUSE measured request counts, FUSE daemon
  CPU and context switches, client CPU, and scaling from one to four workers.

Analysis uses paired blocks and 10,000 deterministic percentile-bootstrap
resamples with a frozen seed. It reports every cell and does not pool the two
directory shapes.

## Execution Protocol

### Implementation Validation

Before KVM:

- rebuild corrected FxMark, the cell runner, and FUSE server warning-free;
- run a focused host source contract that creates a small corrected private
  and shared directory, proves repeated complete scans, and rejects the
  uncorrected EOF loop;
- test analyzer rejection of missing, duplicate, failed, malformed,
  wrong-cardinality, zero-FUSE-request, invalid phase-handshake,
  non-frozen-run, and mismatched logical/physical rows;
- run shared result-contract and Make dry-run validation; and
- obtain an independent read-only implementation review.

### Real Preflight

- One five-condition block, one fresh KVM boot per condition.
- Both `MRDL` and `MRDM`, at one and four workers, two measured seconds each.
- The exact 8,192-files-per-worker formal setup is retained.
- At most three real preflight attempts once a result root exists. Each failed
  root is immutable and counted.
- No formal run is authorized until the preflight passes and an independent
  result review returns `GO`.

### Formal Matrix

- Ten paired five-condition blocks, with a Latin-square condition order.
- Fifty fresh KVM boots.
- Each boot runs `MRDL` and `MRDM` at one, two, and four workers.
- Thirty measured seconds per cell.
- Positive QMP host-vCPU pinning to CPUs 4--7.
- Kernel BPF run statistics remain disabled throughout each timed interval and
  are enabled only for the post-timing event-attribution handshake.
- Exactly 300 unique completed cells; failed boots are not replaced inside
  the result root.

## Result Layout And Reproducibility

```text
results/experiments/fxmark-readdir-preflight/<RUN_ID>/
results/experiments/fxmark-readdir/<RUN_ID>/
```

Each result owns:

- patched and stock kernel images/configs/BTF/notes and identity;
- original FxMark archive, both correction patches, and patched
  `MRDL.c`/`MRDM.c`;
- executed FxMark, cell runner, FUSE server, BPF policies, and bpftool;
- exact libfuse identity and runtime linkage;
- sealed guest Makefiles, boot order, host CPU/topology evidence, raw stdout,
  stderr, FUSE request records, observations, dmesg, and checksums; and
- separate analyzer outputs and figures after raw-run completion.

Canonical entrypoints:

```text
make kvm-fxmark-readdir-preflight RUN_ID=<fresh-id>
make experiment-fxmark-readdir RUN_ID=<fresh-id>
```

## Scope Of Any Claim

A passing result may support:

> Across corrected FxMark private- and shared-directory enumeration at one,
> two, and four workers, `namei_ext` target selection achieved higher paired
> median entry throughput than the committed libfuse view while preserving
> exact logical and physical directory cardinality.

It cannot support claims about cache-cold lookup, arbitrary FUSE
implementations, network or distributed filesystems, directory mutation during
enumeration, synthetic entries, all core counts, or all machines.
