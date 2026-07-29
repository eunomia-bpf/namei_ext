# Complete Experiment Status

Date: 2026-07-28

## Purpose

This document is the single current inventory of every experiment relevant to
the paper. It separates publication evidence from supporting diagnostics,
failed protocols, and future portfolio cases. A development run is not promoted
merely because it booted or emitted plausible numbers.

The paper has three research questions:

1. **RQ1, expressiveness:** can the narrow hook implement a real source-derived
   path-view behavior while the lower filesystem keeps ordinary semantics?
2. **RQ2, cost versus FUSE:** under the same correctness oracle, what does the
   VFS policy path cost relative to a feature-equivalent FUSE implementation?
3. **RQ3, boundary versus custom/stackable FS:** for name-resolution-only
   behavior, which filesystem methods and failure responsibilities must each
   mechanism own?

## Mechanism Validation

Before case studies, the Phase 1 KVM suites established that the modified
kernel can load and attach real `cgroup/namei_ext` BPF programs and execute the
bounded action families:

- `PASS` continues ordinary VFS lookup.
- `HIDE` returns absence for lookup and suppresses the matching readdir entry.
- `REDIRECT` replaces one bounded same-parent component.
- `SELECT_TARGET` resolves through a kernel-registered existing lower path.
- malformed or unsupported decisions return declared errors rather than
  silently falling back.

These functional and ABI suites are regression gates. They establish that the
prototype works but do not answer a paper RQ by themselves.

## RQ1: Source-Derived Case Studies

### W1 Sandboxed Application File Sharing

Source behavior: XDG Documents portal per-application grant and revoke.

Implemented slice: two application cgroups, one logical document, an existing
host target, grant, revoke, cross-application isolation, lookup/readdir/open/stat
checks, and lower-object preservation.

Result: passed one reviewed KVM preflight with zero failures. Policy engagement
was 123 lookup events, 30 readdir events, two selections, eight lookup hides,
and four readdir hides.

Evidence:

```text
results/experiments/application-file-sharing/
  20260725T-sandboxed-file-sharing-preflight-v3/
```

Status: supporting RQ1 breadth, not a formal FUSE performance result.

### W2 Agent Workspaces

Source behavior: an AgentFS-derived branch/stage/hide lifecycle over existing
base and staged objects.

RQ1 result: three terminal KVM runs passed the fixed lookup/readdir/open/stat,
whiteout, symlink, mutation, and final-tree oracle. Each run emitted 1,176
records with zero failures and clean dmesg.

Evidence:

```text
results/experiments/agent-workspace-matrix/
  20260722T020120Z-rq1run1/
  20260722T020210Z-rq1run2/
  20260722T020245Z-rq1run3/
```

Status: headline RQ1 case and the shared workload for the formal RQ2 and RQ3
experiments.

### W3 Build Action Sandboxing

Source behavior: Bazel/sandboxfs action-specific input views.

Implemented slice: two real Bazel 6.5.0 genrules execute concurrently. They use
the same logical input pathname but select different declared roots. An existing
undeclared input must be absent from lookup and readdir.

Result: passed one reviewed KVM preflight. Both actions completed and produced
their distinct expected 17-byte outputs. The policy recorded four selections,
two lookup hides, and two readdir hides. Declared and undeclared lower objects
were unchanged.

Evidence:

```text
results/experiments/build-action-sandboxing/
  20260726T-build-action-sandboxing-preflight-v3/
```

Status: supporting traditional RQ1 breadth.

### W4 Service Configuration And Secret Rotation

Source behavior: Kubernetes AtomicWriter publication plus nginx live reload.
The frozen oracle contains current, canary, invalid-candidate, and rollback
states and checks nginx validation, PID/worker behavior, responses, hashes, and
lower-object preservation.

Implementation exists, but the dependency protocol exhausted three failed KVM
preflights. The final root points to a missing guest
`CONFIG_PROC_CHILDREN` requirement as the strongest timeout explanation.

Status: not a paper result. Failed roots are preserved; no formal run is
authorized without a new reviewed dependency plan.

### W5 Checkpoint/Restore And Migration

Source behavior: DMTCP path virtualization translates a pathname remembered
before checkpoint to the restored location after migration.

Status: the DMTCP-derived application, restart-path plugin, Make-owned KVM
runner, analyzer, and source contracts are implemented. The frozen protocol
exhausted three KVM attempts on a hidden DMTCP assertion, a guest UID mismatch,
and a Make per-line-shell UID/GID propagation error. The final harness repair
passes source tests, but the closed protocol does not authorize a fourth run.
There is no completed checkpoint/restore paper result.

### W6 HPC File Staging

Source behavior: LLNL Spindle redirects library, executable, Python, and data
lookups from shared storage to prepared node-local objects.

Status: source and industrial deployment are identified. The exact
Pynamic/MPI/Python trace is not frozen, and cross-filesystem target selection
has not passed its dependency preflight.

### W7 Toolchain And Dependency Environments

Source behavior: Nix/Guix/Spack profiles and language environments select
installed tool and dependency views.

Status: source family and oracle shape are identified, but one exact
Spack/Nix/Python workflow has not been selected or executed.

### RQ1 Answer So Far

The real KVM path has expressed three distinct existing-object workflows:
per-application grant/revoke, concurrent Agent workspace views, and concurrent
Bazel action views. This supports the mechanism's breadth across security,
agent, and traditional build workflows. It does not yet support all seven
portfolio cases, and the paper must not report W4-W7 as completed.

## RQ2: Cost And Overhead

### Agent Workspace Lifecycle Versus FUSE

Protocol: ten paired blocks, one fresh `namei_ext` KVM boot and one fresh FUSE
KVM boot per block, with the same 48 required lifecycle oracles and 10,000
samples per mechanism.

Result:

- 20/20 boots completed.
- 20,000/20,000 lifecycle samples and 960/960 required oracles passed.
- lifecycle p50: `namei_ext` 5.51 us, FUSE 62.64 us.
- paired FUSE/`namei_ext` ratio: 11.32x, 95% CI [11.24, 11.64].
- `open`: 8.35x in favor of `namei_ext`.
- `readdir`: 13.59x in favor of `namei_ext`.
- cache-hit `stat` and `access` favored FUSE; `exec` was inconclusive.

This is a scoped lifecycle mechanism result, not an end-to-end agent-task
speedup and not a universal statement about FUSE.

Evidence:

```text
results/experiments/agent-workspace-rq2/
  20260727T-agent-workspace-rq2-formal-v3/
```

### FxMark Active Path Versus Optimized FUSE

Protocol: cache-hot FxMark MRPL, MRPM, and MRPH at one, two, and four workers
across stock, patched-unattached, attached `PASS`, attached same-filesystem
`SELECT`, and multithreaded cached FUSE. The formal matrix used 50 fresh KVM
boots and 450 cells.

Result:

- 450/450 cells passed.
- `SELECT`/FUSE median throughput ratio was 1.052-1.088; every paired 95% CI
  was above one, and `SELECT` won 89/90 individual pairs.
- `PASS` retained 0.901-0.934 of patched-unattached throughput.
- `SELECT`/`PASS` was 0.981-0.999.
- the complete `SELECT` path retained 0.895-0.931 of unattached throughput.
- the FUSE baseline had metadata/kernel caching and only 0-19 measured requests
  per cell, so this was not a one-round-trip-per-lookup straw baseline.

Evidence:

```text
results/experiments/fxmark-rq2/
  20260728T-rq2-rcu-target-formal-v3/
```

### Patched-But-Unattached Fast Path

Protocol: a separate host-pinned confirmation measured stock versus the
patched kernel with no attached policy across 30 paired blocks, 60 fresh KVM
boots, and 180 cells.

Result: patched-unattached/stock was
`1.0009 [0.9921, 1.0036]`, `1.0083 [0.9950, 1.0179]`, and
`1.0007 [0.9918, 1.0139]` at one, two, and four workers.

This closes the predeclared unused-fast-path gate for cache-hot MRPL on this
host. It does not prove literal zero overhead, cold-cache behavior, tail
latency, or cross-machine generality.

Evidence:

```text
results/experiments/fxmark-fast-path/
  20260728T-fxmark-fast-path-formal-v1/
```

### ccache Compile Macrobenchmark

This is retained as supporting macro evidence, not as the paper's core use-case
motivation because ccache already performs cache lookup and validation in user
space.

Result:

- verified hot-cache: 400/400 output hashes per mechanism; observed
  FUSE/`namei_ext` compile-time ratio 2.18x and native/`namei_ext` ratio 0.945x,
  meaning the `namei_ext` total compile time was about 5.8% above native in
  that run.
- epoch switch: 800/800 output matches; observed FUSE/`namei_ext` ratio 2.10x;
  20 policy-session updates versus 800 FUSE backing invalidations.
- one-sample stale-local and corrupt-hidden fallback probes passed.
- real compile miss and release-scale stale/corrupt cells remain open.
- no independent-run confidence interval was computed.

The valid claim is the exact observed ratio for these runs. “Near native” and
a complete cache-state-machine claim are not supported.

### Bazel/Sandboxfs RQ2 Attempt

The matched official sandboxfs 0.2.0 protocol exhausted three dependency
preflights before producing a valid pair. The final attempt reached both real
Bazel actions and exposed a newline mismatch in the harness oracle. The code
was repaired, but the frozen three-attempt protocol is closed.

Status: no performance result. The failed attempts must not be combined with
the successful W3 correctness preflight.

### Corrected Directory Enumeration Preflight

The paper-level RQ2 evidence is currently strong for cache-hot FxMark MRPL,
MRPM, and MRPH and the Agent workspace lifecycle. A corrected FxMark
`MRDL`/`MRDM` private/shared-directory suite is now implemented with exact
logical-name, candidate-entry BPF attribution, offset-correct FUSE, five-boot
preflight, 50-boot formal, and analyzer gates.

The final allowed preflight completed five fresh KVM boots and 20/20 cells.
Every correctness, attribution, FUSE-engagement, provenance, host-affinity,
inventory, and dmesg gate passed. The one-block `SELECT/FUSE` ratios were
`2.153`, `3.607`, `2.919`, and `0.967` for `MRDL/1`, `MRDL/4`, `MRDM/1`, and
`MRDM/4`, respectively. The frozen analyzer therefore correctly labels the
preflight `contradicted`. Because one observation per cell produces only a
degenerate bootstrap interval, this direction is not a formal performance
conclusion.

An independent result review returned `GO` for preflight validity and for the
unchanged formal protocol. The authorized formal run retains ten paired
five-condition blocks, 50 fresh KVM boots, 30-second cells, one/two/four
workers, and rotating Latin-square condition order. It has not run yet.

Evidence:

```text
results/experiments/fxmark-readdir-preflight/
  20260729T081348Z-fxmark-readdir-preflight-v3/
docs/tmp/2026-07-28-rq2-fxmark-readdir-preflight-result-review.md
```

Cache-cold operations, mdtest/IOR metadata breadth, and Filebench mixed
profiles also have not produced formal matrices.

## RQ3: Ownership And Fault Containment

### Agent Workspace Versus Wrapfs-Derived Stackable FS

Protocol: both mechanisms execute one shared 37-row AgentFS-derived semantic
contract over the same fresh ext4 lower tree in three independent KVM boots.
The stackable implementation is a Linux 7.1 port of official Wrapfs commit
`464802c8fd1a25413b295161c9bb9a4ce7bfa33b`.

Result:

- 37/37 pairwise oracles passed for both mechanisms in every boot.
- 13 Wrapfs method classes were observed at runtime, including superblock,
  lookup, directory, inode, and file operations.
- an already-open `namei_ext` selected descriptor continued through ordinary
  lower-file read/write/fsync/stat/chmod after policy detach and cgroup removal;
  its BPF counter stayed unchanged in 3/3 boots.
- all 21 fail-closed cells passed in 3/3 boots: two verifier rejections and 19
  independent malformed/unsupported runtime decisions.
- every runtime fault preserved eight lower-object statx/SHA-256 records and
  two exact directory manifests.
- source accounting found nine deployed `namei_ext` kernel integration files,
  six compiled Wrapfs sources with 34 unique VFS slots, 12 userspace FUSE
  callbacks, and 15 compiled kernel FUSE client sources.

Evidence:

```text
results/experiments/agent-workspace-rq3-formal/
  20260728-rq3-formal-v3/
```

This root is a tracked portable formal bundle. `make result-contract` validates
its provenance and declared artifacts and replays its analysis.

Supported conclusion: for this existing-object workspace view, policy execution
can remain in lookup/readdir while ordinary operations use the selected lower
object. The matched stackable implementation owns a broader filesystem-method
surface. This is a measured boundary result, not proof of complete-system
security or a claim that custom filesystems are unnecessary.

## Excluded Development Results

The following remain useful engineering history but are excluded from paper
figures and headline claims:

- host-only tests, object inspection, policy-load smoke tests, and initial
  Phase 1 action checks;
- early Agent workspace roots before the fixed AgentFS-derived oracle;
- interrupted or dirty-provenance FxMark matrices;
- short exact-parent, exact-empty, RCU registry, and parent-filter diagnostics
  that led to the final mechanism;
- one-sample ccache stale/corrupt probes as release-scale state-machine cells;
- all W4 and Bazel/sandboxfs failed dependency preflights;
- RQ3 preflights and formal-v1/v2 attempts superseded by formal-v3;
- table-only and materialized-view shootouts, which are retired questions.

## Current Paper Evidence

The strongest defensible paper story is now:

1. One formal Agent-workspace case passes its source-derived correctness
   oracle; two supporting KVM preflights cover application sharing and Bazel
   action views.
2. The same-oracle Agent workspace policy is 11.32x lower median lifecycle
   latency than the matched FUSE implementation.
3. Across cache-hot FxMark MRPL, MRPM, and MRPH, active `SELECT` outperforms an
   optimized cached FUSE view by 1.052-1.088x while retaining 0.895-0.931 of
   unattached throughput.
4. The unused patched fast path meets the predeclared non-regression criterion
   for the tested host and cache-hot MRPL protocol.
5. The matched Agent workspace RQ3 experiment demonstrates a narrower executed
   method boundary and fail-closed behavior without claiming complete-system
   safety.

## Highest-Value Next Experiments

1. Complete W5 DMTCP checkpoint/restore correctness in KVM. It is the strongest
   traditional case that adds a new lifecycle rather than another view-policy
   variant.
2. Add one frozen standard-benchmark breadth matrix: cache-cold lookup plus
   directory enumeration, or selected mdtest operations, across stock,
   unattached, `PASS`, `SELECT`, and optimized FUSE.
3. Freeze and preflight W6 Spindle only after cross-filesystem selection and a
   source Pynamic/MPI oracle are ready.
4. Select one W7 source workflow; do not implement several package managers.
5. Reopen W3/FUSE or W4 only with a new independently reviewed dependency plan,
   not by extending failed protocols.

The next work should broaden one RQ at a time. Adding more small baselines or
reopening table-only does not increase the paper's evidence strength.
