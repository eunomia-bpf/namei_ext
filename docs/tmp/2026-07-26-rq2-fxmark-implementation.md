# RQ2 FxMark Implementation

## Motivation

The existing custom lookup benchmark and ccache macrobenchmark cannot isolate
the cost of the patched-but-unattached VFS path from compiler work, nor do they
compare against a matched stock kernel and a strongly cached FUSE
implementation. This implementation adds the standard FxMark path-resolution
matrix specified in
`docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md`.

The implementation follows the repository's unified infrastructure rules:

- one top-level Make entrypoint owns source acquisition, build, KVM execution,
  raw artifacts, and analysis;
- the real modified kernel and `cgroup/namei_ext` attach path run in KVM;
- benchmark-specific code is isolated under `bench/fxmark/`;
- generic stock/patched kernel construction stays in `mk/kernel.mk`;
- collectors write raw JSONL and resource files, while
  `analysis/fxmark/analyze.py` computes ratios, uncertainty, reports, and
  figures;
- no checked-in shell script, policy configuration language, or second
  experiment-control schema is introduced.

After the initial implementation, the suite was converged onto the shared
infrastructure rather than retaining a benchmark-specific lifecycle:

- `mk/kvm.mk` launches both stock and patched images through the same
  image-parameterized KVM executor;
- `mk/results.mk` owns `namei_ext.run.v1` start, completion, and validation;
- both preflight and full runs use `layout="boot-matrix"`;
- input sources and built artifacts have separate hash manifests; and
- each boot must prove the selected kernel by matching in-guest kernel notes
  and BTF hashes to the sections extracted from the selected `vmlinux`, plus
  checking `namei_ext_lookup` symbol presence, then preserve its GNU build ID,
  config, release, `/proc/version`, CPU snapshots, observations, launcher
  logs, and dmesg before the root is completed.

## Source And Published Protocol

The Makefile downloads the official FxMark archive at commit
`3f29552ce7ba6be24c4172e6e2c2c1f603209953` from the GitHub codeload endpoint
and checks SHA-256
`b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae`.
The source is extracted under `.build/fxmark-source`; the downloaded archive
lives under `.cache/benchmarks/fxmark`.

The selected official tests are:

- `MRPL`: private five-component path, repeated `stat()`;
- `MRPM`: random `stat()` over 32,768 files in a five-level, eight-way tree;
- `MRPH`: repeated `stat()` of one shared five-level path.

The pinned source uses `stat()` even though the ATC 2016 paper's table
describes open/close. The result is therefore explicitly scoped to the pinned
source behavior.

## Correctness-Only FxMark Patch

The pinned binary can return zero even when a worker, fork, or affinity setup
fails. `bench/fxmark/fxmark-correctness.patch` is applied with
`patch --fuzz=0` and makes four changes:

1. propagate `sched_setaffinity()` failure into `worker->ret`;
2. terminate a fork-failed run instead of spinning on an unstarted worker;
3. reject invalid worker/background/duration arguments;
4. return nonzero if any worker reports failure.

The patch does not add a measured operation or change a successful operation.
The official works/second computation and test bodies remain unchanged.

Upstream CPU topology generation requires Python 2 and host `sudo`.
`bench/fxmark/cpupol.h` supplies the exact four-vCPU sequence
`{0,1,2,3}` used by the KVM configuration. This is a build adapter, not a
benchmark-operation rewrite.

## Matched Kernel Pair

`mk/kernel.mk` now provides:

- `kernel-stock-source`;
- `kernel-stock-config`;
- `kernel-stock`;
- `kernel-stock-provenance`.

The stock source is produced by `git archive` at commit
`062871f1371b2e02a272ff5279c6479aff0a37ef`, the ancestor of patched commit
`6641100ef13462121bf8d8bea9392d77532c86d5`. It is extracted under
`.build/kernel-stock-src` and built out of tree under `.build/kernel-stock`.
This does not create a Git worktree or modify kernel-submodule metadata.

`make fxmark-kernel-pair` fails unless:

- the stock commit is an ancestor of the patched commit;
- the patched config contains `CONFIG_NAMEI_EXT=y`;
- the stock config has no `CONFIG_NAMEI_EXT`;
- the final configs are byte-for-byte identical after removing the one
  `CONFIG_NAMEI_EXT=y` line.

The matched stock `bzImage` built successfully. The config comparison produced
no differences.

## Initial Policy Instrumentation (Invalidated)

`bpf/policies/fxmark_pass.bpf.c` always returns `PASS`.

`bpf/policies/fxmark_select.bpf.c` returns `SELECT_TARGET` for the logical
component `view`, selecting registered target 1. The target is the existing
same-tmpfs lower directory. Other components pass normally.

The first implementation made both policies maintain:

- whole-cell total, lookup, readdir, select, and pass counters;
- separate measured-phase versions of the same counters;
- one array-map phase flag.

FxMark's official `profbegin` and `profend` commands call
`bench/fxmark/fxmark_phase.c` through a pinned BPF phase map. Thus setup path
operations cannot satisfy the measured-phase engagement gate. A `SELECT` cell
must observe at least one measured selection per reported successful FxMark
operation.

This instrumentation was removed after the first full run showed that the map
lookups and atomic updates materially perturbed the measured policy path. No
performance observation from that run is valid evidence.

## Corrected Policy And Engagement Gate

`fxmark_pass.bpf.c` now immediately returns `PASS`.
`fxmark_select.bpf.c` compares only the current component with `view` and
returns `SELECT_TARGET` for registered target 1 when it matches. Neither policy
contains counters, phase maps, or other benchmark-only work.

The cell runner verifies mechanism engagement without modifying the measured
lookup path:

- it queries the exact attached BPF program ID before and after each attached
  cell and requires the ID to remain unchanged;
- it stops the FxMark leader after moving it into the cell cgroup, records
  `/proc/<pid>/cgroup`, verifies exact membership, then allows `exec` and timing
  to begin;
- workers inherit the leader's cgroup membership;
- the `SELECT` logical path cannot exist without selecting the registered
  lower directory, so successful full-duration `stat()` operations and the
  exact lower-tree oracle jointly validate selection.

## FUSE Baseline

`bench/fxmark/fxmark_fuse.c` implements a feature-equivalent path-based
passthrough over the same existing tmpfs tree. It supplies the methods required
by FxMark setup and measurement: getattr, access, mkdir, create, open, release,
read, write, opendir, readdir, releasedir, and statfs.

The daemon runs:

- in the foreground and multithreaded;
- with `default_permissions`;
- with `kernel_cache`;
- with one-hour attribute, entry, and negative TTLs;
- with affinity to all four guest vCPUs.

The one-hour TTL prevents the 32,768-file setup from expiring metadata before
measurement. At one and two FxMark workers, the daemon may use otherwise idle
vCPUs, which favors the baseline. FUSE runs on the matched stock kernel.

`SIGUSR1` and `SIGUSR2`, invoked by FxMark's profiling hooks, switch request
accounting between setup, measured, and after phases. A measured-phase request
count of zero is valid for a cache-hot run. The baseline instead requires:

- `statfs()` to report `FUSE_SUPER_MAGIC` while the cell is active;
- nonzero setup requests;
- a clean daemon exit and stats record.

The daemon records per-phase operation counts, user/system CPU, and context
switches. These are raw secondary measurements.

## Cell Runner

`bench/fxmark/fxmark_cell.c` owns one condition/test/worker-count cell. It:

1. creates a unique cgroup and tmpfs work tree;
2. prepares an identical logical path `.../view/bench`;
3. mounts FUSE or loads/attaches the selected BPF policy when required;
4. registers the lower target for `SELECT`;
5. queries the attached program ID when applicable;
6. moves and stops the FxMark leader, records and verifies its cgroup, and
   resumes it only after the gate passes;
7. invokes the correctness-patched official FxMark binary;
8. enforces a hard cell timeout and parses official works/second output;
9. rechecks the attached program ID and counts the physical lower tree;
10. cleans up the mount, policy, registry, cgroup, and work tree;
11. appends one raw JSONL observation.

The exact tree oracle is:

- `MRPL`: `ncore` files and `1 + 4*ncore` directories;
- `MRPM`/`MRPH`: 32,768 files and 4,681 directories.

FxMark's parent process does not reap all worker processes, so a parent
`wait4()` record is not an aggregate client resource metric. The implementation
does not use it as a paper metric.

## KVM Matrix

`mk/benchmarks/fxmark.mk` provides:

- `make kvm-fxmark-rq2-preflight`;
- `make kvm-fxmark-rq2`;
- `make fxmark-rq2-report`;
- `make experiment-fxmark-rq2`.

Every condition gets a fresh VM:

| Condition | Kernel |
| --- | --- |
| stock | matched stock |
| patched-unattached | patched |
| attached `PASS` | patched |
| attached `SELECT` | patched |
| optimized FUSE | matched stock |

One repetition is a five-boot block. A fixed Latin rotation balances condition
order across ten blocks. Each full boot runs `MRPL`, `MRPM`, and `MRPH` at 1,
2, and 4 workers for 30 seconds each. The lower store is a 1-GiB `noatime`
tmpfs under the vng-provided writable `/tmp` overlay.

The corrected uninstrumented implementation passed the five-boot, two-second
KVM preflight under run
`20260726T-unified-fxmark-preflight-v3`: all conditions passed, planned and
observed boot/cell key sets were identical, and in-guest kernel-notes/BTF
hashes and kernel-flavor checks matched the selected stock and patched builds.
These results validate the experimental path only; they are not used as
performance evidence.

Raw results live under
`results/experiments/fxmark-rq2/<RUN_ID>/boots/`. Each boot preserves its
kernel config and expected commit, GNU build ID, actual kernel-notes/BTF hashes
and kernel flavor, release, uname, command line, before/after `/proc/stat`,
launcher stdout/stderr, FUSE stats where applicable, observation JSONL, and
dmesg. Completion requires exact equality between the planned and observed
boot/cell key sets, not only matching row counts.

## Analysis

`analysis/fxmark/analyze.py` requires the complete 450-row matrix. It refuses
duplicates, missing rows, failed cells, nonpositive metrics, unplanned
conditions, unverified cgroup membership, unstable attached program IDs, and
an unverified `SELECT` logical view.

For each operation and worker count, it computes:

- median works/second and a 95% bootstrap confidence interval;
- paired condition/stock ratios within each five-boot block;
- paired `SELECT`/FUSE ratios;
- median FUSE setup and measured request counts.

The committed bootstrap seed is `20260726` with 10,000 resamples. Output is
ordinary JSON, CSV, Markdown, PNG, and PDF under the run's `analysis/`
directory. A synthetic 450-row structural test completed successfully.

## Validation Performed

- Official archive hash: passed.
- Correctness patch with zero fuzz: passed.
- Initial local FxMark, cell runner, phase helper, and FUSE build: passed.
- Both BPF policies: passed Clang BPF compilation.
- Matched stock source/config construction: passed.
- Full matched stock `bzImage`: passed.
- Patched/stock config equality excluding `CONFIG_NAMEI_EXT`: passed.
- Five-condition real KVM preflight: passed on attempt 3 for executability, but
  its attached-policy performance values were later invalidated by the
  instrumentation defect.
- Corrected counter-free policies and cgroup-membership gate: passed local
  build with no new warnings.

## Remaining Risks

- The full `MRPM`/`MRPH` cells exercise much larger setup trees than preflight.
- The corrected implementation still requires a fresh real KVM full run; the
  invalidated run cannot be reused.
- The cache-hot FUSE baseline may serve most measured `stat()` operations
  without daemon requests and may outperform attached BPF. This is a valid
  contradictory outcome under the fixed plan, not a baseline failure.
- One preflight sample showed lower patched-unattached throughput than stock;
  only ten paired blocks can distinguish fast-path cost from boot noise.
- This matrix does not answer open, readdir, cache-cold, or tail-latency costs.
