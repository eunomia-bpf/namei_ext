# Unified Source Provenance Infrastructure

## Motivation

The repository already routes current builds, KVM validation, formal case
studies, and FxMark through top-level Make targets. Its main infrastructure gap
was source provenance: a run could execute a dirty parent or kernel tree while
recording only the kernel's last commit. That makes an otherwise valid result
impossible to reproduce from the recorded metadata.

This change strengthens the shared result contract before running the complete
RQ2 matrix. It does not reorganize experiment-specific policy or workload code.

## Files Inspected

- `Makefile`
- `mk/results.mk`
- `mk/kernel.mk`
- `mk/kvm.mk`
- `mk/experiments/*.mk`
- `mk/benchmarks/fxmark.mk`
- `tests/infrastructure/Makefile`
- the top-level organization and Make workflow in the parent `bpf-benchmark`
  repository

## Design

All current experiment targets now depend on one shared
`experiment-source-clean` gate. The gate rejects a run if either the main repository
or the kernel submodule has tracked, untracked, staged, or unstaged changes.
Development validation such as `make phase1` remains usable on dirty trees.

The shared run schema is upgraded from `namei_ext.run.v1` to
`namei_ext.run.v2`. Every run created through `NAMEI_EXT_RUN_START` records:

- the main repository commit and dirty state;
- the kernel repository commit and dirty state;
- matching `source-commit.txt`, `source-status.txt`, `kernel-commit.txt`, and
  `kernel-status.txt` files in the result root.

The existing top-level `kernel_commit` field remains as a compatibility alias,
but validation requires it to match `kernel.commit`.

## Alternatives Rejected

### Large directory reorganization

The active repository already has distinct roots for kernel code, BPF policies,
runner code, experiments, shared Make infrastructure, configurations, analysis,
and results. Moving those directories would create churn without fixing the
evidence gap.

### Recording only `git rev-parse HEAD`

This was the previous behavior. It identifies the base commit but not the code
that actually ran when a tree is dirty.

### Silently accepting dirty formal runs

Capturing status is useful for development diagnostics, but a dirty formal run
still lacks a complete immutable source identity, especially for untracked
files. Formal experiment entry points therefore fail instead of treating such a
run as publishable evidence.

## Implementation

- `mk/results.mk` owns source-state capture, schema generation, validation, and
  the clean-tree gate.
- `Makefile` applies the gate to the current case-study gates and both FxMark
  RQ2 run targets.
- `tests/infrastructure/Makefile` checks the new schema, commit files, and
  consistency between JSON and raw provenance files.

## Validation

Completed:

1. `make bpf bench result-contract` passed. The result-contract fixtures reject
   untracked, tracked-unstaged, and tracked-staged changes in both source
   repositories.
2. Make dependency inspection confirmed every current case-study and FxMark
   run target reaches `experiment-source-clean` and expands
   `NAMEI_EXT_REQUIRE_CLEAN=1`.
3. After commit `0f02d6e`, the committed-tree command `make
   kvm-application-file-sharing-preflight
   RUN_ID=20260727T-source-provenance-v2-rerun` passed through the modified
   kernel in KVM.
4. The completed result root is
   `results/experiments/application-file-sharing/20260727T-source-provenance-v2-rerun/`.
   Its v2 record contains source commit `0f02d6e`, kernel commit `8fd1fb52f`,
   `dirty=false` for both repositories, and empty source and kernel status
   files. The grant/revoke correctness oracle passed and the dmesg gate found
   no kernel failure signature.

An earlier invocation used an external one-second command timeout and
terminated the launcher before Make could mark the run failed. Its immutable
root,
`results/experiments/application-file-sharing/20260727T-source-provenance-v2/`,
remains `status=running` and is excluded from evidence.

## Remaining Work

- Run the complete RQ2 matrix from a clean committed tree.
- Keep the large historical build/cache reproduction isolated from the current
  target set.
- Revisit cleanup target naming and legacy Makefile loading separately; neither
  should block correctness or provenance of the current experiments.
