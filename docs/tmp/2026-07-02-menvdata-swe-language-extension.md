# MEnvData-SWE Language Coverage Extension

Date: 2026-07-02

## Motivation

The prior MEnvData-SWE reproduction covered two passing languages
(`Python`, `Go`) and one negative `Rust` row. The local dataset has 3005 rows
over 10 languages, so that evidence was useful but too narrow for a polyglot
W4 environment/cache workload source.

This run extends coverage by replaying one official released image/eval row
for each language that did not already have positive evidence where feasible:
`JavaScript`, `TypeScript`, `Ruby`, `PHP`, `Java`, `C`, `C++`, and `Rust`.
Rows were not adapted after extraction. Failures are preserved as artifact
behavior.

## Source

- Source repository: <https://github.com/ernie-research/MEnvAgent>
- Local source checkout: `.cache/source-inspection/menvagent`
- Source commit: `d9e63881f7c4a4670bb536c89add24573459bbee`
- Dataset: `ernie-research/MEnvData-SWE`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl`
- Dataset rows in local file: 3005
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-language-extension/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-language-extension/summary.json`

## Method

The row manifest was extracted from the dataset JSONL into:

- `results/reproduction/2026-07-02-official-workloads/menvdata-swe-language-extension/run-manifest.tsv`
- per-row `instance.json`
- per-row official `eval.sh`

Each row was run as:

```sh
docker pull "$image"
docker run --rm -v "$PWD/$row_dir/eval.sh:/eval.sh:ro" "$image" /bin/bash /eval.sh
```

Each row preserves:

- `pull.log` and `pull.status`;
- `image.inspect.after.json`;
- `eval.log` and `eval.status`;
- `rmi.log` and `rmi.status` when the image was not present before this run;
- `lifecycle.log` and `disk-after.log`.

The runner did not use broad Docker pruning. Images newly pulled for this run
were removed row-by-row after their eval completed.

## Result

| Row | Language | Image digest | Eval result |
| --- | --- | --- | --- |
| `mishoo__UglifyJS-4449` | JavaScript | `mcatwj/swe-images-js@sha256:315982c96f0708e7e34426c767e63513cb790374406f88d2519671468bfb2d3f` | passed, Docker status 0, `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `colinhacks__zod-4568` | TypeScript | `mcatwj/swe-images-typescript@sha256:c5bb22d4c901f195e2385d373cdcd631f29e967d3be76b783d5c46d103061e06` | negative artifact, Docker status 128, failed at `fatal: not a git repository` in `/testbed` |
| `ruby-i18n__i18n-701` | Ruby | `mcatwj/swe-images-ruby@sha256:9bfdb757c8504c02a6ad2a99f0c1c55869767df1733bd971115a2b94355868c4` | passed, 6 runs / 6 assertions / 0 failures, `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `PHP-CS-Fixer__PHP-CS-Fixer-6824` | PHP | `mcatwj/swe-images-php@sha256:7f30befada9a86f837ad87d62cb281ac5c30a44c64b3368872230a7df6188148` | passed, Docker status 0, `OMNIGRIL_EXIT_CODE=0`, completion marker present; eval log includes Xdebug connection warnings |
| `casbin__jcasbin-431` | Java | `mcatwj/swe-images-java@sha256:b3a86f1ac6e99e9b79ac01da43f300bf1610238a4eabb0bd4db60a9541c2c9d0` | passed, Maven `Tests run: 7, Failures: 0, Errors: 0, Skipped: 0`, `BUILD SUCCESS`, `OMNIGRIL_EXIT_CODE=0` |
| `libgit2__libgit2-6125` | C | `mcatwj/swe-images-c@sha256:617f49931797b01125a3a549405d922bb495b201c2f605f5534a74e60aec144f` | passed, `commit::commit.....`, `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `Tencent__rapidjson-2207` | C++ | `mcatwj/swe-images-cpp@sha256:4d2873309b5f154941a23e061bca2dc7d9495cf921a832a7f1ee0745c27e0e03` | negative artifact, Docker status 0 but eval marker `OMNIGRIL_EXIT_CODE=8`; `ctest` reports `0% tests passed, 1 tests failed out of 1` |
| `eyre-rs__color-eyre-106` | Rust | `mcatwj/swe-images-rust@sha256:fbc2a292e53f8f42db9cf197895ead6e78d4ae5377a8c39ae5ad495b34427e62` | negative artifact, Docker status 1, test patch failed because `tests/location_disabled.rs` already exists |

Aggregate for this extension:

- selected rows: 8
- passing rows: 5
- negative rows: 3
- languages attempted: C, C++, Java, JavaScript, PHP, Ruby, Rust, TypeScript
- languages passed: C, Java, JavaScript, PHP, Ruby
- languages negative in this sample: C++, Rust, TypeScript

Combined with `docs/tmp/2026-07-02-menvdata-swe-workload-reproduction.md`,
the MEnvData-SWE evidence now attempts all 10 dataset languages. Positive
official image/eval rows exist for `Python`, `Go`, `JavaScript`, `Ruby`, `PHP`,
`Java`, and `C`. The attempted `TypeScript`, `C++`, and `Rust` examples remain
negative artifact rows and need alternate row selection if positive coverage
for those languages becomes necessary.

## Boundaries

This is selected MEnvData-SWE image/eval replay, not full MEnvAgent runtime
reproduction and not full 3005-row benchmark reproduction.

Negative rows were not repaired by modifying images, removing pre-existing
files, or changing eval scripts. They are useful evidence about released
artifact behavior, but they should not be presented as failing the whole
dataset.

Correctness remains row-local. A paper-facing W4 workload row should cite its
own `image_name`, digest, eval script, eval status, `OMNIGRIL_EXIT_CODE`,
completion marker, and raw log.

## Use In `namei_ext`

Use MEnvData-SWE as a polyglot W4 environment/cache workload source. The best
current positive candidates are:

- Python `python-attrs__attrs-586`
- Go `go-task__task-1814`
- JavaScript `mishoo__UglifyJS-4449`
- Ruby `ruby-i18n__i18n-701`
- PHP `PHP-CS-Fixer__PHP-CS-Fixer-6824`
- Java `casbin__jcasbin-431`
- C `libgit2__libgit2-6125`

For a final `namei_ext` workload, choose rows whose eval scripts can be run
inside the project-owned Make/KVM workflow and whose correctness oracle is
stable enough to gate any cache/path-view performance measurement.
