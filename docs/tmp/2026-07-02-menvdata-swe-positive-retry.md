# MEnvData-SWE Positive Retry

Date: 2026-07-02

## Motivation

The prior MEnvData-SWE language extension attempted all 10 dataset languages,
but the first selected `TypeScript`, `C++`, and `Rust` rows were negative
artifact examples. That left the polyglot W4 evidence useful but uneven: it
showed the dataset had broad released image/eval coverage, but only seven
languages had positive selected-row evidence.

This retry selects alternate official released image/eval rows for those three
languages. The goal is not to erase the earlier negative rows. The goal is to
separate row-local artifact failures from language coverage and decide whether
MEnvData-SWE can provide positive selected workload seeds across the full
language set.

## Source

- Source repository: <https://github.com/ernie-research/MEnvAgent>
- Local source checkout: `.cache/source-inspection/menvagent`
- Source commit: `d9e63881f7c4a4670bb536c89add24573459bbee`
- Dataset: `ernie-research/MEnvData-SWE`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl`
- Dataset rows in local file: 3005
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-positive-retry/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-positive-retry/summary.json`

## Method

The row manifest was extracted from the dataset JSONL into:

- `results/reproduction/2026-07-02-official-workloads/menvdata-swe-positive-retry/run-manifest.tsv`
- per-row `instance.json`
- per-row official `eval.sh`

Each row was run by mounting the preserved official eval script into the
released public image:

```sh
docker pull "$image"
docker run --rm -v "$PWD/$row_dir/eval.sh:/eval.sh:ro" "$image" /bin/bash /eval.sh
```

Each row preserves:

- `pull.log` and `pull.status`;
- `image.inspect.after.json`;
- `eval.log` and `eval.status`;
- `rmi.log` and `rmi.status`;
- `lifecycle.log` and `disk-after.log`.

The run did not use broad Docker pruning. Images newly pulled for this retry
were removed row-by-row after their eval completed.

## Result

| Row | Language | Image digest | Eval result |
| --- | --- | --- | --- |
| `sindresorhus__type-fest-818` | TypeScript | `mcatwj/swe-images-typescript@sha256:ea57edbff856723921c939a42077f47297779f47eab6a1a0147343e98ba26c58` | passed, Docker status 0, repeated `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `CLIUtils__CLI11-926` | C++ | `mcatwj/swe-images-cpp@sha256:0208d2a5e4270ec245d59eae87663ef561cf57f70e5d0542596af20c0684aa25` | passed, Docker status 0, `HelpTest` passed 305 assertions in 90 test cases, `SubcommandTest` passed 485 assertions in 112 test cases, `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `cobalt-org__liquid-rust-403` | Rust | `mcatwj/swe-images-rust@sha256:ab94a5dfceec8c028af9ab9da5af414a6ef5c7c688f2c77b86e57e9c0eeb41d2` | passed, Docker status 0, conformance tests report 459 passed / 0 failed / 1 ignored, `OMNIGRIL_EXIT_CODE=0`, completion marker present |

Aggregate for this retry:

- selected rows: 3
- passing rows: 3
- negative rows: 0
- languages attempted: `TypeScript`, `C++`, `Rust`
- languages passed: `TypeScript`, `C++`, `Rust`

Combined with
`docs/tmp/2026-07-02-menvdata-swe-workload-reproduction.md` and
`docs/tmp/2026-07-02-menvdata-swe-language-extension.md`, the MEnvData-SWE
selected-row evidence now has at least one positive official image/eval row for
all 10 dataset languages: `C`, `C++`, `Go`, `Java`, `JavaScript`, `PHP`,
`Python`, `Ruby`, `Rust`, and `TypeScript`.

## Boundaries

This is selected image/eval row replay, not full MEnvAgent runtime
reproduction and not full 3005-row benchmark reproduction.

The retry does not invalidate the earlier negative rows:

- `colinhacks__zod-4568` still records a released TypeScript row where
  `/testbed` was not a git repository;
- `Tencent__rapidjson-2207` still records a released C++ row where `ctest`
  returned `OMNIGRIL_EXIT_CODE=8`;
- `eyre-rs__color-eyre-106` and `eyre-rs__color-eyre-114` still record
  released Rust rows where new-file test patches collided with files already
  present in the image.

Those rows are artifact caveats. They should not be generalized into a language
or dataset failure.

Correctness remains row-local. A paper-facing W4 workload row should cite its
own `image_name`, digest, eval script, eval status, `OMNIGRIL_EXIT_CODE`,
completion marker, and raw log.

## Use In `namei_ext`

Use MEnvData-SWE as a polyglot W4 environment/cache workload source with
positive selected-row evidence across all dataset languages. Candidate rows now
include:

- Python `python-attrs__attrs-586`
- Go `go-task__task-1814`
- JavaScript `mishoo__UglifyJS-4449`
- Ruby `ruby-i18n__i18n-701`
- PHP `PHP-CS-Fixer__PHP-CS-Fixer-6824`
- Java `casbin__jcasbin-431`
- C `libgit2__libgit2-6125`
- TypeScript `sindresorhus__type-fest-818`
- C++ `CLIUtils__CLI11-926`
- Rust `cobalt-org__liquid-rust-403`

For final `namei_ext` evaluation, choose a small subset whose correctness
oracle is stable under the Make/KVM workflow and whose path activity can be
traced at lookup/readdir granularity.
