# MEnvData-SWE Second Sample Reproduction

Date: 2026-07-02

## Motivation

Earlier MEnvData-SWE runs established at least one positive official image/eval
row for each of the dataset's 10 languages. That closed the language-coverage
gap, but most languages still had only one positive row. This run adds a second
sample across five high-cardinality languages using previously unrun released
rows with small eval scripts and test patches.

For `namei_ext`, these rows strengthen W4 environment/cache workload sourcing:
they provide additional real repositories, prebuilt images, eval scripts, test
outputs, image digests, and row-local correctness oracles without hand-writing
environment definitions.

## Source

- Source repository: <https://github.com/ernie-research/MEnvAgent>
- Local source checkout: `.cache/source-inspection/menvagent`
- Source commit: `d9e63881f7c4a4670bb536c89add24573459bbee`
- Dataset: `ernie-research/MEnvData-SWE`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/ernie-research__MEnvData-SWE/swe-images.jsonl`
- Dataset rows in local file: 3005
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-second-sample/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/menvdata-swe-second-sample/summary.json`

## Method

The selected rows were extracted from the dataset JSONL into:

- `run-manifest.tsv`
- `dataset-slice.json`
- per-row `instance.json`
- per-row official `eval.sh`

Each row was run by mounting the preserved official eval script into the
released public image:

```sh
docker pull "$image"
timeout 1800 docker run --rm -v "$row_dir/eval.sh:/eval.sh:ro" "$image" /bin/bash /eval.sh
```

Each row preserves:

- `pull.log` and `pull.status`
- `image.inspect.before.*` and `image.inspect.after.*`
- `eval.log` and `eval.status`
- `rmi.log` and `rmi.status` when the image was not already present
- `lifecycle.log` and `disk-after.log`

The run did not use broad Docker pruning. Images newly pulled for this run were
removed row-by-row after their eval completed.

## Result

| Row | Language | Image digest | Eval result |
| --- | --- | --- | --- |
| `PyCQA__pycodestyle-859` | Python | `mcatwj/swe-images-python@sha256:5e5813ac5bca4e70999c99f748156b4763a5159b24e3135563020ce53af2164a` | passed, Docker status 0, `Test passed.`, `OMNIGRIL_EXIT_CODE=0`, completion marker present |
| `go-yaml__yaml-353` | Go | `mcatwj/swe-images-go@sha256:e8e87355fbd301f8ff111b4a69060b06ad5fdd575f156b7fdc85744dca598e43` | passed, Docker status 0, `go test` reports `OK: 6 passed`, `OMNIGRIL_EXIT_CODE=0`; the official eval script did not print `COMMAND_EXECUTION_COMPLETE` |
| `AlaSQL__alasql-970` | JavaScript | `mcatwj/swe-images-js@sha256:4a23d30e65758121b2dbaae032d6fd984bc88dc497b507b7dc11601782086c2d` | passed, Docker status 0, Mocha reports 1 passing test, `OMNIGRIL_EXIT_CODE=0`, completion marker present; eval log records that `test/test620.js` already existed before the test patch |
| `pest-parser__pest-702` | Rust | `mcatwj/swe-images-rust@sha256:67f25c8a9b1559fd4876417360d5213351041588f6265e9d8aad59ccfb4e1bc9` | passed, Docker status 0, grammar tests report 74 passed / 0 failed, `OMNIGRIL_EXIT_CODE=0`, completion marker present; log includes panic/backtrace output from expected parser-error cases |
| `refined-github__refined-github-7041` | TypeScript | `mcatwj/swe-images-typescript@sha256:c9224d269a16b6653da70912a39ad08dcc6a88fb352f8b815371ff4b96ccc40e` | passed, Docker status 0, Vitest reports 1 test file passed and 1 test passed, `OMNIGRIL_EXIT_CODE=0`, completion marker present |

Aggregate for this run:

- selected rows: 5
- passing rows: 5
- negative rows: 0
- languages attempted: `Go`, `JavaScript`, `Python`, `Rust`, `TypeScript`
- languages passed: `Go`, `JavaScript`, `Python`, `Rust`, `TypeScript`
- matching containers/images after cleanup: 0

Combined with the earlier MEnvData-SWE records, selected-row evidence now has
15 passing official image/eval rows across all 10 dataset languages. The four
earlier negative released rows remain preserved artifact caveats.

## Boundaries

This is selected image/eval row replay, not full MEnvAgent runtime
reproduction and not full 3005-row benchmark reproduction.

The JavaScript row is a positive evaluator row with an artifact caveat: the
test file already existed in the image, so `git apply` printed an error before
the test ran and passed. The Go row is a positive evaluator row whose official
eval script does not emit `COMMAND_EXECUTION_COMPLETE`.

Correctness remains row-local. A paper-facing W4 workload row should cite its
own `image_name`, digest, eval script, eval status, `OMNIGRIL_EXIT_CODE`,
completion marker when present, and raw log.

## Use In `namei_ext`

Use this batch to broaden MEnvData-SWE beyond one positive row per language.
The strongest second-sample candidates are:

- Python `PyCQA__pycodestyle-859`
- Go `go-yaml__yaml-353`
- Rust `pest-parser__pest-702`
- TypeScript `refined-github__refined-github-7041`

For final `namei_ext` evaluation, choose a small stable subset whose
correctness oracle can gate Make/KVM runs and whose path activity can be traced
at lookup/readdir granularity.
