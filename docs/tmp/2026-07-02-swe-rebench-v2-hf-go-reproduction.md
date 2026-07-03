# SWE-rebench V2 HF Go Reproduction

Date: 2026-07-02

## Motivation

The prior SWE-rebench V2 records covered the README C sample, all public HF
Clojure sample rows, one public HF JavaScript row, and one public HF Dart row.
This record expands selected HF sample coverage to a Go workload.

For `namei_ext`, this row is useful W4 environment/cache workload evidence: it
has a real repository, base commit, per-instance Docker image, gold patch, test
patch, Go test command, fail-to-pass tests, and a large pass-to-pass set. It is
source-backed workload evidence only; it does not prove that Go/SWE-rebench
workloads require eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-go/`

Selected row:

- instance: `mgechev__revive-1408`
- repository: `mgechev/revive`
- base commit: `24c008dd000c009c35867463b25497be939275d3`
- language: Go
- image: `docker.io/swerebenchv2/mgechev-revive:1408-24c008d`
- test command: `go test -v ./...`
- expected fail-to-pass tests: 2
- expected pass-to-pass tests: 492

The selected task spec is saved in:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-go/selected_spec_mgechev__revive-1408.json
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
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-go"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids mgechev__revive-1408 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_mgechev__revive-1408.json"
```

Cleanup checks:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'mgechev|revive|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'mgechev|revive|swerebench' || true
```

## Result

Raw files:

- `selected_spec_mgechev__revive-1408.json`
- `eval_mgechev__revive-1408.log`
- `eval_mgechev__revive-1408.exitcode`
- `eval_report_mgechev__revive-1408.json`
- `mgechev__revive-1408_log.txt`

The evaluator passed:

- evaluator exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `passed_match`: true
- instance raw `exit_code`: 0
- expected fail-to-pass tests passed: 2/2
- failed pass-to-pass tests: 0/492
- `error`: empty

The preserved container log records reset to commit `24c008d`, `go test -v
./...` across the Revive packages, many individual `=== RUN` and `--- PASS`
test lines, package-level `PASS` output, and clean patch/test-patch
application to `rule/unexported_return.go` and
`testdata/golint/unexported_return.go`. Docker residual checks found no
matching SWE-rebench, `mgechev`, or `revive` images or containers after the
run.

## Workload Shapes Reproduced

This row adds Go coverage to the selected SWE-rebench V2 workload set:

- a Go repository evaluated by `go test -v ./...`;
- both fail-to-pass and a large pass-to-pass oracle;
- package-level and test-level verbose output preserved in raw logs;
- clean evaluator and raw row exit status.

## Boundaries

Together with earlier records, selected SWE-rebench V2 coverage now includes
the README C row, all four public HF Clojure rows, one public HF JavaScript
row, one public HF Dart row, and one public HF Go row. It is still not full
20-task HF sample reproduction and not full SWE-rebench V2 corpus
reproduction.

This run uses the public prebuilt per-instance image. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

Do not claim that Go/SWE-rebench workloads require `namei_ext`. Use this row
as a source-backed W4 oracle with a clean raw exit status and large P2P set.

## Use In `namei_ext`

`mgechev__revive-1408` is a good W4 candidate when the paper needs a Go
workload with clean raw exit status and many pass-to-pass checks. A later
Make-owned KVM workload can reuse the same image identity, repository state,
patches, and Go test oracle while measuring path-view behavior and natural
baselines.
