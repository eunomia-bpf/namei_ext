# SWE-rebench V2 HF JavaScript Reproduction

Date: 2026-07-02

## Motivation

The previous SWE-rebench V2 HF records covered the README C sample and four
Clojure rows from the public Hugging Face sample. This record expands coverage
to a JavaScript workload from the same public 20-task HF sample.

For `namei_ext`, this is W4 environment/cache workload evidence: the row
provides a real repository, base commit, per-instance Docker image, gold patch,
test patch, `npx mocha` test command, and a large fail-to-pass oracle. It is
source-backed workload evidence only; it does not prove that this workload
requires eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-js/`

Selected row:

- instance: `pbiswas101__mathball-153`
- repository: `pbiswas101/Mathball`
- base commit: `d8bd138c1d7522b9f79de9b1002574b9ddac75a0`
- language: JavaScript
- image: `docker.io/swerebenchv2/pbiswas101-mathball:153-d8bd138`
- test command: `npx mocha --require babel-core/register --reporter spec`
- expected fail-to-pass tests: 406
- expected pass-to-pass tests: 0

The selected task spec is saved in:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-js/selected_spec_pbiswas101__mathball-153.json
```

## Commands

Spec extraction:

```sh
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python - <<'PY'
from scripts.eval import load_specs_from_hf
...
PY
```

Official evaluator replay:

```sh
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-js"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids pbiswas101__mathball-153 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_pbiswas101__mathball-153.json"
```

Cleanup checks:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'pbiswas|mathball|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'pbiswas|mathball|swerebench' || true
```

## Result

Raw files:

- `selected_spec_pbiswas101__mathball-153.json`
- `eval_pbiswas101__mathball-153.log`
- `eval_pbiswas101__mathball-153.exitcode`
- `eval_report_pbiswas101__mathball-153.json`
- `pbiswas101__mathball-153_log.txt`

The evaluator passed:

- evaluator exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `passed_match`: true
- instance raw `exit_code`: 0
- expected fail-to-pass tests passed: 406/406
- failed pass-to-pass tests: 0/0
- `error`: empty

The preserved container log records reset to commit `d8bd138`, the Mocha suite
reporting 739 passing tests, clean patch/test-patch application after direct
application fallback for new files, and npm version notices. Docker residual
checks found no matching SWE-rebench, `pbiswas`, or `mathball` images or
containers after the run.

## Workload Shapes Reproduced

This row adds JavaScript coverage to the SWE-rebench V2 selected workload set:

- a Node/npm project evaluated by `npx mocha`;
- a large fail-to-pass-only oracle with 406 expected tests;
- new-file patch/test-patch application paths that require fallback from index
  checks to direct application;
- per-instance Docker image replay with no residual container/image cleanup
  issue observed.

## Boundaries

Together with earlier records, this means selected SWE-rebench V2 coverage now
includes the README C row, all four public HF Clojure rows, and one public HF
JavaScript row. It is still not full 20-task HF sample reproduction and not a
full SWE-rebench V2 corpus reproduction.

This run uses the public prebuilt per-instance image. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

Do not generalize this row into a claim that JavaScript SWE workloads require
`namei_ext`. It should be used as a source-backed W4 row with a strong
correctness oracle.

## Use In `namei_ext`

`pbiswas101__mathball-153` is a good W4 candidate when the paper needs a
high-cardinality JavaScript fail-to-pass oracle with clean evaluator and raw
exit status. A later Make-owned KVM workload can reuse the same image identity,
repository state, patches, and Mocha oracle while measuring path-view behavior
and natural baselines.
