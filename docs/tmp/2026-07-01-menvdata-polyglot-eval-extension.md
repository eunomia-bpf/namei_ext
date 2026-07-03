# MEnvData-SWE Polyglot Eval Extension

Date: 2026-07-01

## Motivation

The earlier MEnvData-SWE reproduction closed one executable Python image/eval
row, but MEnvData-SWE is explicitly polyglot. This record extends the
reproduction with additional official rows from other languages so that the W4
environment/cache workload source is not supported by only one Python example.

This is an external workload-source reproduction step. It is not Phase 1
`namei_ext` KVM validation.

## Source

- Dataset: `ernie-research/MEnvData-SWE`
- Local data:
  `.cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl`
- Row count: 3,005 environment rows across C, C++, Go, Java, JavaScript, PHP,
  Python, Ruby, Rust, and TypeScript.
- Registry convention used here:
  `mcatwj/<image_name>`

Raw artifacts are under:

- `results/reproduction/2026-07-01-official-workloads/menvdata-go-task-1814/`
- `results/reproduction/2026-07-01-official-workloads/menvdata-rust-color-eyre-114/`

The earlier Python row artifacts remain under:

- `results/reproduction/2026-07-01-official-workloads/menvdata-python-attrs-586/`

## Go Row

Selected row:

- instance: `go-task__task-1814`
- repo: `go-task/task`
- language: Go
- image: `mcatwj/swe-images-go:go-task-task-pr-1814`
- digest: `mcatwj/swe-images-go@sha256:8609760e2d29f163a6e31d8a0457feefd9adb09573f7a77b051181745fbd78c9`
- base commit: `08a2a911804314e1bc24aa05e709701acd8c4f47`

The official eval script reset the targeted test files, applied the row's test
patch, and ran:

```text
go test -v -p 8 -parallel 8 -count=1 -run '^TestExitCode(One|Zero)$' ./
```

Result:

- Docker pull status: 0
- Docker run status: 0
- `OMNIGRIL_EXIT_CODE=0`
- passed tests: `TestExitCodeZero`, `TestExitCodeOne`
- package summary: `ok github.com/go-task/task/v3`

Interpretation: this is a passing official MEnvData-SWE image/eval row for a
Go task. Like the earlier Python row, the image already contains the patched
repository state; this is not a standalone before/after fail-to-pass
reproduction.

## Rust Row

Selected row:

- instance: `eyre-rs__color-eyre-114`
- repo: `eyre-rs/color-eyre`
- language: Rust
- image: `mcatwj/swe-images-rust:eyre-rs-color-eyre-pr-114`
- digest: `mcatwj/swe-images-rust@sha256:b285cb4df1e04f15416e0c7bc6312234138b9853a075eaddb08eac9474d59b9b`
- base commit: `bbe570561260157272b0daa3434a26b3155cec51`

The official eval script attempted to apply a new-file test patch for
`tests/install.rs`, then run:

```text
cargo test --test install -- --nocapture --test-threads=1
```

Result:

- Docker pull status: 0
- Docker run status: 1
- no `OMNIGRIL_EXIT_CODE` was emitted
- failure stage: test patch application
- evidence: `error: tests/install.rs: already exists in working directory`

Interpretation: this is a negative official row reproduction. I did not adapt
the script by deleting the existing file because the goal is to preserve
source-artifact behavior. The result is an MEnvData-SWE artifact caveat: at
least this Rust row is not cleanly replayable from the public image plus eval
script without modification.

## Current MEnvData-SWE Evidence Level

Passing executable rows:

- `python-attrs__attrs-586`: Python, 21 pytest tests passed,
  `OMNIGRIL_EXIT_CODE=0`.
- `go-task__task-1814`: Go, two targeted Go tests passed,
  `OMNIGRIL_EXIT_CODE=0`.

Negative row:

- `eyre-rs__color-eyre-114`: Rust, image pulled, eval failed before tests
  because the new test file already existed.

The safe paper-facing conclusion is that MEnvData-SWE is a strong W4
environment/cache workload source with real public images and eval scripts, but
not every row should be assumed replayable. Any paper workload row selected
from MEnvData-SWE must carry its own raw pull/eval evidence.

## Remaining Risks

- This does not reproduce the full MEnvAgent runtime system; it only exercises
  released MEnvData image/eval rows.
- Two passing rows and one negative row do not cover all 10 languages.
- The eval rows validate patched image states, not a full fail-to-pass
  before/after evaluator.
