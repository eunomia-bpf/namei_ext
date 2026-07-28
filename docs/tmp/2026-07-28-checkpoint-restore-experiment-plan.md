# Experiment Plan: Checkpoint/Restore Path Remapping

## Research Question

- Paper RQ: Can a narrow VFS name-resolution extension express real
  state-dependent path-view policies without taking over filesystem semantics?
- Exact hypothesis: after a real DMTCP checkpoint is restarted under a changed
  filesystem layout, `namei_ext` can make the application's remembered
  pathname resolve to the restored existing directory, while DMTCP retains
  ownership of process checkpoint/restart and the lower filesystem retains
  ownership of directory contents and file operations.
- Source demand: DMTCP-PV identifies changed mount points and pathname prefixes
  after migration as a checkpoint/restart problem. Its path-virtualization
  plugin wraps pathname operations and translates remembered virtual paths to
  current physical paths. Current upstream DMTCP includes both the path
  translator and an unchanged-mapping restart test.

This experiment does not test whether pathname remapping is needed, whether a
table is sufficient, or whether `namei_ext` can replace DMTCP. It tests the
mechanism boundary on one source-derived behavior already implemented by
DMTCP.

## Admission

This is the next highest-value experiment after the completed Agent Workspace
and FxMark results:

- it adds a traditional, non-agent source workload;
- it exercises a real process checkpoint and restart, rather than a simulated
  epoch switch;
- it has an upstream implementation from which to derive a natural baseline;
- its correctness oracle is application-visible and independent of timing;
- it isolates a pathname-resolution responsibility that DMTCP currently
  implements by wrapping pathname operations.

Toolchain environments remain useful breadth, but Nix, Guix, and Spack
normally materialize profiles or link trees. Their first experiment would
entangle package installation and environment construction with the lookup
mechanism. DMTCP provides a narrower source-derived comparison.

## Frozen Source

- Project: DMTCP
- Commit: `068559d9b14c5f96a57869753bba7c066cbf9653`
- Archive:
  `https://github.com/dmtcp/dmtcp/archive/068559d9b14c5f96a57869753bba7c066cbf9653.tar.gz`
- Archive SHA-256:
  `e2f15525073fc631efd994640ef645461f2c910843da60f9e8929d593ed49c7e`
- Source implementation:
  `src/plugin_pathtranslator.cpp`
- Disclosed correctness patch:
  `thirdparty/patches/dmtcp/restart-env-scan-count.patch`
- Patch SHA-256:
  `7c945ba6f4bfc375b3c83f5714ed9546660a164a4c9e235999f1e9e55ca3c127`
- Upstream test shape:
  `test/pathvirt1.c` and the `pathvirt` case in `test/autotest.py`
- Paper:
  `docs/reference/cluster16-ansel-dmtcp-path-virtualization.pdf`

The repository will acquire, verify, patch, build, package, and invoke DMTCP
only through Make targets. The patch changes only the byte bound used by
`dmtcp_get_restart_env()` when it scans DMTCP's flattened restart environment;
it does not implement pathname translation. The baseline is **patched DMTCP
PathTranslator at commit `068559d9b14c`, with a disclosed one-line restart-
environment scan-bound fix**. It must never be called stock or unmodified
DMTCP.

Every result root preserves the original archive, patch, patched and unmodified
source files used by the workload, build provenance, complete install manifest,
and built binary hashes. The host dependency result additionally copies and
executes a complete DMTCP install tree from its own result root. Formal KVM
roots must preserve the same self-contained source and runtime boundary.

## Source-Derived Lifecycle

The application retains one logical pathname across checkpoint/restart:

```text
<logical-parent>/workspace/state.txt
```

Two immutable existing directory trees model the old and restored mount:

```text
<fixture>/generation-a/workspace/{state.txt,shared.txt,stale.txt}
<fixture>/generation-b/workspace/{state.txt,shared.txt,new.txt}
```

The lifecycle is:

1. Start the pinned DMTCP checkpoint engine with the disclosed restart-
   environment scan fix.
2. Before checkpoint, the remembered logical path resolves to generation A.
3. The application opens `state.txt` through `fopen`, records the expected
   generation-A bytes and `fstat` object identity, enumerates the directory
   through `opendir`/`readdir`, and closes every pathname-derived descriptor
   before checkpoint.
4. DMTCP creates a real checkpoint image.
5. The original process exits after checkpoint completion.
6. The controller removes access to the old logical mapping, selects
   generation B, and invokes a real DMTCP restart.
7. The restored application uses the same in-memory logical pathname.
8. It must read and stat generation B, enumerate `new.txt`, and observe
   `stale.txt` as absent.
9. The application exits successfully and the controller verifies that both
   lower directory trees are byte-for-byte and metadata unchanged.

Generation B is prepared before checkpoint. `namei_ext` does not copy or
restore files.

## Conditions

### Patched DMTCP Pathvirt

- Launch with upstream `--pathvirt`. `dmtcp_restart` has no `--pathvirt`
  option; the checkpoint image restores the enabled plugin.
- Before checkpoint:
  `DMTCP_PATH_MAPPING=<logical-workspace>:<generation-a-workspace>`.
- Invoke ordinary `dmtcp_restart` with this restart environment:
  `DMTCP_PATH_MAPPING=<logical-workspace>:<generation-b-workspace>`.
- The restored plugin handles its restart event and reads that new environment.
- No BPF program is loaded or attached.

This is patched DMTCP PathTranslator at commit `068559d9b14c`, with the
disclosed one-line restart-environment scan-bound fix. It is the primary
natural baseline. The fix lets the plugin read the restart mapping already
passed by `dmtcp_restart`; it does not add or alter the mapping policy.

### namei_ext

- Launch and restart DMTCP without `--pathvirt`.
- The application and DMTCP restart protocol are otherwise identical.
- A cgroup-scoped policy maps the `workspace` component under the exact logical
  parent to target ID 1.
- The controller registers generation A as target ID 1 before checkpoint and
  atomically replaces that same target ID with generation B before restart.
- DMTCP processes run in the managed cgroup; the coordinator and experiment
  controller remain outside it.

The policy can return only `PASS` or `SELECT_TARGET`. Once `workspace` resolves
to the chosen existing directory, all remaining lookup, directory iteration,
permission, metadata, read, page-cache, and persistence behavior belongs to
the VFS and lower filesystem.

### Negative Control

A short dependency control uses the `namei_ext` mapping for generation A
before checkpoint, then withdraws the policy mapping before ordinary DMTCP
restart. The application's post-restart logical-path oracle must fail. This
control validates that the positive condition depends on restart-time path
remapping; it is not a paper baseline or a performance result.

## Correctness Oracle

Every measured condition must satisfy all of the following:

- DMTCP reports one completed checkpoint and one completed restart.
- The external controller records distinct launch and restart process
  instances. DMTCP's local status reports `num_restarts > 0` in the restored
  application; application-visible `getpid()` is not used as this proof because
  DMTCP virtualizes process IDs.
- The same logical pathname string is recorded before checkpoint and after
  restart. Both conditions use the same `fopen`, `fstat`, `opendir`, and
  `readdir` calls; the result does not generalize to untested pathname APIs.
- Before checkpoint, `state.txt` bytes and `(st_dev, st_ino)` match the
  generation-A object.
- After restart, they match generation B and differ from generation A.
- Before checkpoint, readdir contains `stale.txt` and not `new.txt`.
- After restart, readdir contains `new.txt` and not `stale.txt`.
- `shared.txt` bytes match the expected lower object in both generations.
- Opening `stale.txt` after restart returns `ENOENT`.
- Direct physical reads of both generations match their expected manifests.
- Pre/post hashes, modes, sizes, mtimes, and inode identities of every lower
  object are unchanged.
- The `namei_ext` condition records a stable program identity, exact cgroup
  membership, target registration, one acknowledged A-to-B state update, and
  positive `SELECT_TARGET` counters before and after restart.
- The DMTCP condition records empty and unchanged BPF-program and cgroup-attach
  inventories.
- Neither condition has a FUSE mount or open `/dev/fuse` file.
- Every process exits with the expected status, cleanup succeeds, dmesg is
  clean under the repository's declared failure patterns, and all evidence
  hashes pass.

Correctness gates the run before any duration is interpreted.

## Measurements

The primary result is a two-column correctness and ownership table, not a
claim that `namei_ext` makes checkpointing faster.

Per repetition, preserve:

- checkpoint completion latency;
- state-update or restart-environment update latency;
- restart-to-oracle completion latency;
- end-to-end lifecycle latency;
- DMTCP pathvirt launch/restart-environment evidence and `namei_ext` policy
  counters;
- DMTCP coordinator, launch, checkpoint, and restart stdout/stderr;
- checkpoint image and restart-script names, sizes, and hashes;
- application observations and lower-object manifests;
- kernel, DMTCP, policy, runner, cgroup, BPF, and mount provenance.

Durations are descriptive secondary metrics. The first paper value is that the
same source-derived restart oracle passes with `namei_ext` while filesystem and
checkpoint machinery remain outside the policy.

## RQ3 Ownership Accounting

The result report must separate observed implementation ownership:

| Responsibility | DMTCP PathTranslator + scan-bound fix | namei_ext condition |
| --- | --- | --- |
| Process checkpoint/restart | DMTCP | DMTCP |
| Restart coordination | DMTCP | DMTCP |
| Pathname policy | DMTCP pathname wrappers/path translator | bounded BPF decision |
| Application modification | none | none |
| Filesystem methods | lower filesystem | lower filesystem |
| Data read/write and page cache | lower filesystem | lower filesystem |
| Existing-object preparation/transfer | experiment controller | experiment controller |
| Policy failure containment | DMTCP/plugin process behavior | verifier plus bounded kernel action/fail-closed checks |

The table must be grounded in source inspection and run artifacts. It must not
infer general safety or maintenance cost from lines of code alone.

## Execution Protocol

### Dependency Preflight

- One fresh modified-kernel KVM boot.
- Run the upstream DMTCP `pathvirt` autotest through its Make entrypoint first.
- Run one patched DMTCP PathTranslator lifecycle, one `namei_ext` lifecycle,
  and the negative control in the same boot, with isolated directories and
  coordinators.
- The preflight validates source build/package compatibility, real checkpoint
  image creation, restart, cgroup inheritance, policy lifetime, A-to-B update,
  and complete artifact collection.
- At most three real dependency-preflight attempts are allowed. A build failure
  before result-root creation does not count; once a KVM result root exists, a
  failed attempt counts and is preserved.

No formal run is authorized until the preflight passes and an independent
result reviewer returns `GO`.

### Formal Matrix

- Three paired blocks.
- Each block uses two fresh KVM boots: DMTCP PathTranslator + scan-bound fix
  and `namei_ext`.
- Alternate condition order by block.
- Each boot performs exactly one checkpoint/restart lifecycle.
- Do not replace a failed boot inside the result root.
- Report all three paired results; no filtering or pooled preflight samples.

Three blocks provide independent terminal correctness replication while
keeping this supporting case study proportional to its paper role. No binary
performance hypothesis, significance threshold, or general latency claim is
declared.

## Result Layout

```text
results/experiments/checkpoint-restore-preflight/<RUN_ID>/
results/experiments/checkpoint-restore/<RUN_ID>/
results/workloads/preflight/checkpoint-restore-pathvirt/<RUN_ID>/
```

Each root follows the shared raw artifact contract and contains immutable
DMTCP source/runtime artifacts. Each boot additionally contains:

```text
application-observations.jsonl
lower-before.jsonl
lower-after.jsonl
dmtcp-coordinator.stdout.log
dmtcp-coordinator.stderr.log
dmtcp-launch.stdout.log
dmtcp-launch.stderr.log
dmtcp-command.stdout.log
dmtcp-command.stderr.log
dmtcp-restart.stdout.log
dmtcp-restart.stderr.log
checkpoint-images.sha256
checkpoint-images.txt
process-cgroups.txt
bpf-programs-before.txt
bpf-programs-after.txt
bpf-cgroup-before.txt
bpf-cgroup-after.txt
fuse-before.txt
fuse-after.txt
policy-counters.json
```

The collector writes raw events and timestamps. A separate analyzer validates
the matrix and generates JSON/Markdown interpretation.

## Implementation Boundary

New project-owned files are limited to:

- one per-suite Makefile under `mk/experiments/`;
- one runner directory under `experiments/checkpoint_restore/`;
- one bounded BPF policy under `bpf/policies/`;
- one analyzer and focused tests under `analysis/checkpoint_restore/`;
- one pinned DMTCP source entry in the workload-source configuration;
- one checksum-pinned DMTCP correctness patch under `thirdparty/patches/`;
- standalone implementation, preflight, and result-review records under
  `docs/tmp/`.

The runner may have an application subcommand and a controller subcommand, but
all canonical build, guest, preflight, formal, and report workflows remain Make
targets. No project-owned shell control script is added.

## Expected And Alternative Outcomes

- Expected: both patched DMTCP pathvirt and `namei_ext` pass all source-derived
  restart oracles; `namei_ext` records only a bounded directory-target
  selection while DMTCP and the lower filesystem retain their responsibilities.
- Dependency failure: current DMTCP cannot checkpoint/restart in the KVM image,
  cgroup membership is not preserved or reconstructed, or required artifacts
  cannot be collected. Preserve the root and close the preflight after the
  bounded attempts.
- Mechanism contradiction: DMTCP PathTranslator + scan-bound fix passes but
  `namei_ext` cannot make the restored process resolve the selected directory
  while preserving the lower-object oracle. Diagnose the mechanism; do not
  weaken the hypothesis or substitute a simulated restart.
- Source-baseline contradiction: pathvirt itself fails the pinned upstream
  workload. Do not treat a `namei_ext` pass as paper evidence until the source
  baseline is repaired or the experiment is rejected.

## Baseline Amendment

The first A-to-B host preflight exposed a bug below PathTranslator:
`dmtcp_get_restart_env()` scanned only `sizeof(env_buf)` bytes even though
`env_buf` is a pointer. Consequently the restart process received the B mapping
but the restored plugin could not retrieve it. The checksum-pinned one-line
patch changes that bound to `count`, the number of bytes returned by DMTCP's
own `readLine()` call.

The baseline remains admissible only under these labels and gates:

- report it as patched DMTCP PathTranslator;
- preserve the original archive and patch independently in provenance;
- run the upstream unchanged-mapping pathvirt test after applying the patch;
- require the source-derived A-to-B oracle to pass before any `namei_ext`
  comparison; and
- do not use this host dependency result as Phase 1 or paper evidence.

The root-cause and causal preflight evidence are recorded in
`2026-07-28-dmtcp-restart-env-root-cause.md`.

## Paper Decision

A valid formal result may support this scoped claim:

> In a source-derived DMTCP checkpoint/restart workload, `namei_ext` preserved
> an application's pathname across a changed directory layout using a bounded
> existing-directory selection, while DMTCP continued to perform process
> checkpoint/restart and the lower filesystem continued to implement file and
> directory semantics.

It cannot support claims about arbitrary migration, open-file-descriptor
restoration, distributed checkpointing, file transfer, all pathname APIs,
overall performance superiority, or replacing DMTCP.
