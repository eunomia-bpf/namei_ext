# Terminal-Bench Compile/System Suite Reproduction

Date: 2026-07-01

## Motivation

This run continues upstream workload reproduction by extending selected
Terminal-Bench coverage to compiler migration, polyglot source generation,
instrumented database builds, and QEMU-attached toolchain materialization. These
tasks are useful as W4 environment/build seeds because they combine source-tree
state, generated artifacts, compiler/toolchain setup, executable tests, and
containerized task oracles.

This is upstream workload reproduction only. It is not a `namei_ext` KVM
validation run and not evidence that any workload requires eBPF.

## Command

Run from `.cache/source-inspection/terminal-bench`:

```bash
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache timeout 7200 uv run tb run \
  --dataset-path original-tasks \
  --task-id modernize-fortran-build \
  --task-id polyglot-c-py \
  --task-id sqlite-with-gcov \
  --task-id build-tcc-qemu \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-compile-system-oracle-suite \
  --output-path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite \
  --no-upload-results \
  --cleanup
```

## Raw Artifacts

- Summary: `results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite/summary.json`
- Results: `results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite/2026-07-01__terminal-bench-compile-system-oracle-suite/results.json`
- Metadata: `results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite/2026-07-01__terminal-bench-compile-system-oracle-suite/run_metadata.json`
- Run log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite/2026-07-01__terminal-bench-compile-system-oracle-suite/run.log`
- Top-level harness log: `results/reproduction/2026-07-01-official-workloads/terminal-bench-compile-system-oracle-suite/tb-run.log`

## Result

The upstream harness completed four official tasks with the oracle agent:

- `n_resolved=4`
- `n_unresolved=0`
- `accuracy=1.0`
- parser checks: 8 passed, 0 failed

| Task | Result | Parser checks | Workload shape |
| --- | --- | --- | --- |
| `modernize-fortran-build` | resolved | 3/3 passed | Migrate a Fortran Makefile to `gfortran`, build an executable, and verify generated output. |
| `polyglot-c-py` | resolved | 1/1 passed | Generate one source file that runs under Python and compiles under C, with Fibonacci output oracle. |
| `sqlite-with-gcov` | resolved | 3/3 passed | Build vendored SQLite with gcov instrumentation and verify PATH-visible executable. |
| `build-tcc-qemu` | resolved | 1/1 passed | Build TCC, materialize it into an ISO, attach it to a QEMU boot, and verify in-guest compiler use. |

## Reuse Decision

Reusable workload shapes:

- compiler/build-system migration over a source tree;
- single-file generated artifact with multi-runtime execution;
- vendored source package build with instrumentation and PATH materialization;
- QEMU-attached artifact materialization and in-guest tool execution.

These are good W4 environment/build workload seeds. They are still upstream
terminal tasks rather than `namei_ext` experiments; a paper-facing run needs a
Make-owned KVM workload that extracts the relevant build/cache/path-view state
transitions and compares native/source behavior, FUSE/source-system behavior,
and materialized views under the same correctness oracle.

## Boundary

This run should be described as selected official Terminal-Bench task
reproduction, not full Terminal-Bench-Core reproduction.
