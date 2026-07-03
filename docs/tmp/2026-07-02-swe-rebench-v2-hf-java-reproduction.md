# SWE-rebench V2 HF Java Reproduction

Date: 2026-07-02

## Motivation

The prior SWE-rebench V2 records covered the README C sample, all public HF
Clojure sample rows, and selected public HF JavaScript, Dart, and Go rows. This
record expands selected HF sample coverage to a Java workload.

For `namei_ext`, this row is useful W4 environment/cache workload evidence: it
has a real repository, base commit, per-instance Docker image, gold patch, test
patch, Maven test command, and both fail-to-pass and pass-to-pass oracles. It
is source-backed workload evidence only; it does not prove that Java or
SWE-rebench workloads require eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-java/`

Selected row:

- instance: `spoonlabs__gumtree-spoon-ast-diff-171`
- repository: `SpoonLabs/gumtree-spoon-ast-diff`
- base commit: `b43339bdec8a164e5f4c7c14634a187a186a7f22`
- language: Java
- image:
  `docker.io/swerebenchv2/spoonlabs-gumtree-spoon-ast-diff:171-b43339b`
- test command: `mvn test -B --no-transfer-progress`
- expected fail-to-pass tests: 2
- expected pass-to-pass tests: 2

The selected task spec is saved in:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-java/selected_spec_spoonlabs__gumtree-spoon-ast-diff-171.json
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
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-java"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids spoonlabs__gumtree-spoon-ast-diff-171 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_spoonlabs__gumtree-spoon-ast-diff-171.json"
```

Cleanup checks:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'spoonlabs|gumtree|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'spoonlabs|gumtree|swerebench' || true
```

## Result

Raw files:

- `selected_spec_spoonlabs__gumtree-spoon-ast-diff-171.json`
- `eval_spoonlabs__gumtree-spoon-ast-diff-171.log`
- `eval_spoonlabs__gumtree-spoon-ast-diff-171.exitcode`
- `eval_report_spoonlabs__gumtree-spoon-ast-diff-171.json`
- `spoonlabs__gumtree-spoon-ast-diff-171_log.txt`

The evaluator passed:

- evaluator exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `passed_match`: true
- instance raw `exit_code`: 0
- expected fail-to-pass tests passed: 2/2
- failed pass-to-pass tests: 0/2
- `error`: empty

The preserved container log records reset to commit `b43339b`, Maven build and
test phases, compiler and project-version warnings, Surefire test execution,
and clean patch/test-patch application. Docker residual checks found no
matching SWE-rebench, `spoonlabs`, or `gumtree` images or containers after the
run.

## Workload Shapes Reproduced

This row adds Java coverage to the selected SWE-rebench V2 workload set:

- a Maven Java project evaluated by `mvn test -B --no-transfer-progress`;
- fail-to-pass and pass-to-pass oracle coverage;
- build-tool warnings preserved in raw logs rather than hidden;
- clean evaluator and raw row exit status.

## Boundaries

Together with earlier records, selected SWE-rebench V2 coverage now includes
the README C row, all four public HF Clojure rows, one public HF JavaScript
row, one public HF Dart row, one public HF Go row, and one public HF Java row.
It is still not full 20-task HF sample reproduction and not full SWE-rebench
V2 corpus reproduction.

This run uses the public prebuilt per-instance image. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

Do not claim that Java/SWE-rebench workloads require `namei_ext`. Use this row
as a source-backed W4 oracle with a clean raw exit status.

## Use In `namei_ext`

`spoonlabs__gumtree-spoon-ast-diff-171` is a good W4 candidate when the paper
needs a compact Java/Maven row with both F2P and P2P checks. A later Make-owned
KVM workload can reuse the same image identity, repository state, patches, and
Maven test oracle while measuring path-view behavior and natural baselines.
