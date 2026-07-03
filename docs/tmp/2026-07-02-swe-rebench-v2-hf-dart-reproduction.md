# SWE-rebench V2 HF Dart Reproduction

Date: 2026-07-02

## Motivation

The prior SWE-rebench V2 records covered the README C sample, all public HF
Clojure sample rows, and one public HF JavaScript row. This record expands
selected HF sample coverage to a Dart workload.

For `namei_ext`, this row is useful W4 environment/cache workload evidence: it
has a real repository, base commit, per-instance Docker image, gold patch, test
patch, Dart test command, nontrivial fail-to-pass tests, and a large
pass-to-pass set. It remains source-backed workload evidence, not proof that
the workload requires eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-dart/`

Selected row:

- instance: `nyxx-discord__nyxx-547`
- repository: `nyxx-discord/nyxx`
- base commit: `bfbe4e5dfa19f44083ef29e9bf4d1a5ca674eb06`
- language: Dart
- image: `docker.io/swerebenchv2/nyxx-discord-nyxx:547-bfbe4e5`
- test command: `dart run test --reporter json --no-color`
- expected fail-to-pass tests: 15
- expected pass-to-pass tests: 520

The selected task spec is saved in:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-dart/selected_spec_nyxx-discord__nyxx-547.json
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
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-dart"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids nyxx-discord__nyxx-547 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_nyxx-discord__nyxx-547.json"
```

Cleanup checks:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'nyxx|discord|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'nyxx|discord|swerebench' || true
```

## Result

Raw files:

- `selected_spec_nyxx-discord__nyxx-547.json`
- `eval_nyxx-discord__nyxx-547.log`
- `eval_nyxx-discord__nyxx-547.exitcode`
- `eval_report_nyxx-discord__nyxx-547.json`
- `nyxx-discord__nyxx-547_log.txt`

The evaluator passed:

- evaluator exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `passed_match`: true
- instance raw `exit_code`: 0
- expected fail-to-pass tests passed: 15/15
- failed pass-to-pass tests: 0/520
- `error`: empty

The preserved container log records reset to commit `bfbe4e5d`, Dart JSON
test-run output across integration and unit suites, skipped integration cases
when no live Discord test token or guild was provided, final test-run
`success=true`, and clean patch/test-patch application. Docker residual checks
found no matching SWE-rebench, `nyxx`, or `discord` images or containers after
the run.

## Workload Shapes Reproduced

This row adds Dart coverage to the selected SWE-rebench V2 workload set:

- a Dart package evaluated by `dart run test --reporter json --no-color`;
- both fail-to-pass and a large pass-to-pass oracle;
- JSON test output with skipped live-token integration cases preserved in the
  raw log;
- clean evaluator and raw row exit status.

## Boundaries

Together with earlier records, selected SWE-rebench V2 coverage now includes
the README C row, all four public HF Clojure rows, one public HF JavaScript
row, and one public HF Dart row. It is still not full 20-task HF sample
reproduction and not full SWE-rebench V2 corpus reproduction.

This run uses the public prebuilt per-instance image. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

Do not claim that Dart/SWE-rebench workloads require `namei_ext`. Use this row
as a source-backed W4 oracle with a clean raw exit status and large P2P set.

## Use In `namei_ext`

`nyxx-discord__nyxx-547` is a good W4 candidate when the paper needs a
non-Python, non-JavaScript workload with both F2P and P2P correctness checks.
A later Make-owned KVM workload can reuse the same image identity, repository
state, patches, and Dart test oracle while measuring path-view behavior and
natural baselines.
