# MEnvData-SWE Workload Reproduction

Date: 2026-07-02

## Motivation

MEnvData-SWE is a W4 environment/cache workload seed because it releases public
Docker image names, repository state, eval scripts, and language-specific test
commands for software-engineering tasks. For `namei_ext`, these rows are useful
as real environment/cache replay inputs with correctness oracles.

This record separates MEnvData-SWE from the earlier combined environment-source
record and reruns three selected image/eval rows: two passing rows and one
preserved negative row.

## Source

- Source repository: <https://github.com/ernie-research/MEnvAgent>
- Local source checkout: `.cache/source-inspection/menvagent`
- Source commit: `d9e63881f7c4a4670bb536c89add24573459bbee`
- Dataset: `ernie-research/MEnvData-SWE`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl`
- Dataset rows in local file: 3005
- Docker namespace convention used here: `mcatwj/<image_name>`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe/`

## Commands

Environment and source inspection:

```sh
install -d results/reproduction/2026-07-02-official-workloads/menvdata-swe
python3 --version
docker --version
git -C .cache/source-inspection/menvagent remote -v
git -C .cache/source-inspection/menvagent rev-parse HEAD
wc -l .cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl
docker image inspect mcatwj/swe-images-python:python-attrs-attrs-pr-586
docker image inspect mcatwj/swe-images-go:go-task-task-pr-1814
docker image inspect mcatwj/swe-images-rust:eyre-rs-color-eyre-pr-114
```

Each row was rerun by mounting the preserved official eval script into the
corresponding public image:

```sh
docker run --rm -v "$eval_script:/eval.sh:ro" "$image" /bin/bash /eval.sh
```

The rerun used eval scripts and instance JSON preserved from the 2026-07-01
row extraction under:

- `results/reproduction/2026-07-01-official-workloads/menvdata-python-attrs-586/`
- `results/reproduction/2026-07-01-official-workloads/menvdata-go-task-1814/`
- `results/reproduction/2026-07-01-official-workloads/menvdata-rust-color-eyre-114/`

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/menvdata-swe/summary.json`.

Raw artifacts:

- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/source-inspection.log`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/python-attrs-586/instance.json`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/python-attrs-586/eval.sh`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/python-attrs-586/eval.log`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/python-attrs-586/eval.status`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/go-task-1814/instance.json`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/go-task-1814/eval.sh`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/go-task-1814/eval.log`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/go-task-1814/eval.status`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/rust-color-eyre-114/instance.json`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/rust-color-eyre-114/eval.sh`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/rust-color-eyre-114/eval.log`
- `results/reproduction/2026-07-02-official-workloads/menvdata-swe/rust-color-eyre-114/eval.status`

### Python Row

- instance: `python-attrs__attrs-586`
- repository: `python-attrs/attrs`
- language: Python
- image: `mcatwj/swe-images-python:python-attrs-attrs-pr-586`
- image digest:
  `mcatwj/swe-images-python@sha256:e2ecdf70851ff2b86634db9ab55630e5774583bb075204c42300604bf344799e`
- Docker run status: 0
- pytest summary: `21 passed, 1 warning in 0.08s`
- eval marker: `OMNIGRIL_EXIT_CODE=0`
- completion marker: `COMMAND_EXECUTION_COMPLETE`

### Go Row

- instance: `go-task__task-1814`
- repository: `go-task/task`
- language: Go
- image: `mcatwj/swe-images-go:go-task-task-pr-1814`
- image digest:
  `mcatwj/swe-images-go@sha256:8609760e2d29f163a6e31d8a0457feefd9adb09573f7a77b051181745fbd78c9`
- Docker run status: 0
- target command:
  `go test -v -p 8 -parallel 8 -count=1 -run '^TestExitCode(One|Zero)$' ./`
- passed tests: `TestExitCodeZero`, `TestExitCodeOne`
- package summary: `ok github.com/go-task/task/v3 0.014s`
- eval marker: `OMNIGRIL_EXIT_CODE=0`

### Rust Row

- instance: `eyre-rs__color-eyre-114`
- repository: `eyre-rs/color-eyre`
- language: Rust
- image: `mcatwj/swe-images-rust:eyre-rs-color-eyre-pr-114`
- image digest:
  `mcatwj/swe-images-rust@sha256:b285cb4df1e04f15416e0c7bc6312234138b9853a075eaddb08eac9474d59b9b`
- Docker run status: 1
- failure stage: test-patch application
- evidence: `error: tests/install.rs: already exists in working directory`
- eval marker: no `OMNIGRIL_EXIT_CODE`

This is a preserved negative row. I did not adapt the eval script by deleting
the pre-existing file because the goal is to preserve public artifact behavior.

## Workload Shapes Reproduced

This evidence covers:

- public Docker image/eval rows;
- official eval scripts mounted into released images;
- repository state reset inside images;
- test patch application;
- language-specific test commands;
- `OMNIGRIL_EXIT_CODE` and completion-marker oracles;
- negative artifact replay when a public row is not cleanly executable.

## Boundaries

This is not full MEnvAgent runtime reproduction. The public repository is used
as source context, while the executable evidence comes from released
MEnvData-SWE rows.

Two passing rows and one negative row do not cover all 10 dataset languages.
The result supports MEnvData-SWE as a strong W4 workload source, but each
paper-facing row must carry its own raw image/eval evidence.

The rows validate released image/eval behavior. They are not a full
before/after fail-to-pass benchmark for every dataset item.

## Use In `namei_ext`

Use MEnvData-SWE as a W4 environment/cache source with public image identities,
eval scripts, language-specific test commands, and per-row oracles. For a
paper workload, select rows only after preserving raw pull/image/eval evidence
and deciding whether the row is a passing oracle or a negative artifact caveat.

Correctness should gate performance: a row can be a positive workload only when
the Docker run status is 0 and the eval marker reports `OMNIGRIL_EXIT_CODE=0`.
