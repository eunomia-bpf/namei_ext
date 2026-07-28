# Agent Workspace RQ2 Experiment Infrastructure

Date: 2026-07-27

## Motivation

The existing Agent workspace matrix established source-derived correctness, but
it could not support a paper-quality RQ2 result. It ran both mechanisms in one
boot, used a FUSE configuration with all metadata timeouts disabled, reported a
macro timer contaminated by result emission, and had no independent-boot
uncertainty.

This implementation adds a separate formal experiment. It does not change the
`namei_ext` ABI or broaden the workload. It makes the same reduced
AgentFS-derived lifecycle measurable under one strong, cache-coherent FUSE
baseline and one `namei_ext` condition.

## Source Paths Inspected

- `experiments/agent_workspace/namei_ext_agent_workspace.c`
- `experiments/agent_workspace/namei_ext_agent_workspace_fuse.c`
- `experiments/agent_workspace/agentfs_lifecycle_trace.txt`
- `mk/experiments/agent_workspace.mk`
- `mk/benchmarks/fxmark.mk`
- `mk/results.mk`
- `mk/kvm.mk`
- AgentFS commit `0a014ebd4918615baff589ed17486e557e7c6a23`
- Libfuse tag `fuse-3.14.0`

The AgentFS inspection focused on the official bash, git, overlay whiteout,
base-directory delta, symlink, and FUSE cache-invalidation tests. The libfuse
inspection verified the high-level `fuse_invalidate_path()` interface and its
3.14.0 implementation.

## Design Choices

### One formal FUSE baseline

The FUSE runner now compiles against official libfuse 3.14.0 headers and uses
the installed matching runtime. The formal configuration is fixed:

```text
entry_timeout=3600
attr_timeout=3600
negative_timeout=3600
default_permissions
no kernel_cache
```

The FUSE daemon owns the epoch transition. A control thread changes the active
epoch and invalidates the five primed logical inodes whose selected backing
objects change. The benchmark process proceeds only after receiving a
successful acknowledgement. Exactly five attempts and zero errors are required.

This replaces the old direct write to a shared epoch integer. It avoids
disabling stable metadata and negative caches merely to preserve correctness.

### Stronger source and correctness binding

The trace now names the fixed AgentFS commit and maps each local phase to a
concrete upstream test and source operation. The formal artifacts preserve the
trace, pinned AgentFS and libfuse archives, and the six AgentFS test files used
by the binding.

The runners additionally check:

- base and upper content plus mode changes through the same logical path;
- denied unprivileged access to a mode-000 lower object;
- cached-negative create followed by logical-path `stat` and read;
- logical old-name absence and new-name content after rename;
- logical `ENOENT` after unlink;
- final base object and absence preservation.

### Uncontaminated lifecycle samples

The new `--rq2` mode records exactly 20 lifecycle samples per boot. Each
iteration restores and verifies two absent paths before timing. The timed
region contains only:

1. negative `stat`;
2. regular-file creation through `mknod`;
3. rename;
4. unlink.

Postconditions, reset, JSON output, and flushing occur outside the timer. Every
sample records elapsed nanoseconds, pass/fail, errno, and the first failing
stage. The old macro metric remains historical output and is not analyzed.

### Independent paired boots

`mk/experiments/agent_workspace_rq2.mk` adds:

- `kvm-agent-workspace-rq2-preflight`: one two-boot pair;
- `kvm-agent-workspace-rq2`: ten two-boot pairs;
- `experiment-agent-workspace-rq2`: formal matrix plus analysis report.

Condition order alternates by pair. Every boot uses the same run-local kernel,
runner, policy, trace, and libfuse artifacts. The guest verifies kernel commit,
release, build ID, BTF, notes, clocksource, sample counts, mechanism
engagement, every entry in the fixed required-oracle manifest, and dmesg
before writing `boot.json`.

The FUSE runner also records daemon CPU ticks, context switches, and request
count over the same lifecycle-plus-path-operation measurement window.

### Analysis

`analysis/agent_workspace/analyze.py` treats the boot as the independent unit.
It takes each boot's median, forms ten paired FUSE/`namei_ext` ratios, and
bootstraps whole pairs 10,000 times with a fixed seed. The lifecycle is the
predeclared decision metric. `stat`, `open`, `access`, `readdir`, and `exec`
are mechanism decompositions.

An interval wholly above one supports the predicted FUSE cost. An interval
wholly below one contradicts it. An interval containing one is inconclusive;
the experiment does not claim equivalence.

The formal `run.json` remains `running` after raw-matrix validation. It changes
to `completed` only after the analysis script succeeds and all report and
figure artifacts pass their completion gates. A failed analysis therefore
cannot leave a formally completed run.

## Files Added Or Changed

- `configs/benchmarks/agent_workspace.mk`
- `mk/experiments/agent_workspace_rq2.mk`
- `analysis/agent_workspace/analyze.py`
- `analysis/agent_workspace/test_analyze.py`
- `experiments/agent_workspace/Makefile`
- both Agent workspace runners and the source trace
- root `Makefile` and infrastructure test entry point

## Validation Performed Before KVM

- both runners compile with `-Wall -Wextra`;
- the official libfuse and AgentFS archives pass pinned SHA-256 checks;
- required AgentFS source files and semantic tokens are present;
- three analysis unit tests pass;
- the shared result-contract suite passes;
- `git diff --check` passes.

## Alternatives Rejected

- Keeping all FUSE metadata timeouts at zero was rejected because it is a
  weaker performance baseline.
- Adding a second weak FUSE row was rejected because it would fragment the
  comparison without answering another research question.
- Rewriting the runner around low-level FUSE was rejected because libfuse 3
  provides sufficient high-level invalidation for this stable-name epoch
  transition.
- Reusing the old macro timer was rejected because it includes oracle and JSON
  work.
- Treating per-operation samples within one boot as independent repetitions was
  rejected; formal inference is across paired boots.

## Remaining Risks And Follow-Up

The real two-boot preflight has not yet run. It must confirm that all five
primed FUSE inodes can be invalidated under KVM, that long negative caching is
coherent across create/rename/unlink, that `default_permissions` passes the
denial oracle, and that teardown exits normally. Any failure is preserved
under the preflight result root and blocks the 20-boot run.
