# SWE-rebench V2 HF Sample Reproduction

Date: 2026-07-02

## Motivation

The earlier SWE-rebench V2 record reproduced only the repository README
`sample.json` task. This record closes part of that boundary by replaying one
task selected from the public Hugging Face 20-task sample through the official
SWE-rebench V2 evaluator.

For `namei_ext`, this is still W4 environment/cache workload evidence: the
task provides a real repository, base commit, prebuilt Docker image, gold patch,
test patch, test command, and fail-to-pass oracle. It should be used as a
source-backed build/test environment seed, not as proof that the workload
requires eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-sample/`

Selected workload:

- instance: `pilosus__pip-license-checker-119`
- repository: `pilosus/pip-license-checker`
- base commit: `22d2f959e31e0d967ec4c19dc312f46e49e0e112`
- language: Clojure
- image: `docker.io/swerebenchv2/pilosus-pip-license-checker:119-22d2f95`
- test command: `lein test`
- expected fail-to-pass tests: 11
- expected pass-to-pass tests: 0

## Commands

Evaluation command:

```sh
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-sample"
install -d "$OUT"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids pilosus__pip-license-checker-119 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_pilosus__pip-license-checker-119.json"
```

The selected HF spec was also saved from the evaluator's `load_specs_from_hf`
path to:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-sample/selected_spec_pilosus__pip-license-checker-119.json
```

Residual Docker check:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'pilosus|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'pilosus|swerebench' || true
```

## Result

Raw files:

- `eval_pilosus__pip-license-checker-119.exitcode`
- `eval_pilosus__pip-license-checker-119.log`
- `eval_report_pilosus__pip-license-checker-119.json`
- `pilosus__pip-license-checker-119_log.txt`
- `selected_spec_pilosus__pip-license-checker-119.json`

The evaluator passed:

- evaluator exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `exit_code`: 0
- `passed_match`: true
- `failed_from_pass_to_pass`: empty
- `error`: empty

The report lists all 11 expected fail-to-pass tests as passed:

- `pip-license-checker.core-test`
- `pip-license-checker.exception-test`
- `pip-license-checker.external-test`
- `pip-license-checker.file-test`
- `pip-license-checker.filters-test`
- `pip-license-checker.github-test`
- `pip-license-checker.http-test`
- `pip-license-checker.license-test`
- `pip-license-checker.pypi-test`
- `pip-license-checker.report-test`
- `pip-license-checker.version-test`

The preserved container log records reset to `22d2f95`, `lein test`, 62 tests
with 12,286 assertions and 0 failures/errors, clean gold-patch application,
clean test-patch application, and JVM/Clojure compile output. No matching
SWE-rebench or `pilosus` Docker images or containers remained after the run.

## Workload Shapes Reproduced

This selected HF sample adds a second SWE-rebench V2 source-backed workload
shape beyond the README `sample.json` C project:

- Clojure project with `lein test`;
- prebuilt per-instance Docker image;
- base-commit reset inside the container;
- gold patch plus test patch application;
- fail-to-pass oracle with no pass-to-pass tests for this row;
- official evaluator report and container log preservation.

## Boundaries

This is one selected task from the public HF 20-task sample, not a full
20-task sample replay and not a full SWE-rebench V2 corpus reproduction.

This run uses the public prebuilt per-instance image. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

This is evaluator/workload evidence only. Do not claim that SWE-rebench V2,
Clojure build/test tasks, or this selected row require eBPF or `namei_ext`.

## Use In `namei_ext`

Use this row as an additional W4 seed when selecting a release workload. The
natural correctness gate is the SWE-rebench V2 evaluator report: `all_ok=true`,
`passed_match=true`, empty `failed_from_pass_to_pass`, and all 11
fail-to-pass tests present in the passed set.

The next `namei_ext` step is still implementation, not more source discovery:
pick one environment/cache row and build a Make-owned KVM workload that
preserves the source oracle while recording lookup/readdir policy behavior and
natural baseline behavior.
