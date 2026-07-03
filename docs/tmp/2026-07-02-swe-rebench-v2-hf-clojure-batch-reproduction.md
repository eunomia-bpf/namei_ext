# SWE-rebench V2 HF Clojure Batch Reproduction

Date: 2026-07-02

## Motivation

The prior SWE-rebench V2 HF record reproduced one public sample row. This
record expands that coverage by replaying the remaining Clojure rows in the
public 20-task Hugging Face sample through the official SWE-rebench V2
evaluator.

For `namei_ext`, these rows are useful W4 environment/cache workload seeds:
they provide real repositories, base commits, per-instance Docker images, gold
patches, test patches, `lein test` commands, and fail-to-pass/pass-to-pass
oracles. They remain evaluator/workload evidence only; they do not prove that
SWE-rebench V2 or Clojure build/test workloads require eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Public HF sample dataset: `ibragim-bad/SWE-rebench-V2-sample`
- Local evaluator command: `scripts/eval.py`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-clojure-batch/`

Selected rows:

| Instance | Repository | Base commit | Image | Test command | F2P | P2P |
| --- | --- | --- | --- | --- | --- | --- |
| `chrovis__cljam-268` | `chrovis/cljam` | `2cfa13e197df782ee3245e780d3a2b720d1f8e1b` | `docker.io/swerebenchv2/chrovis-cljam:268-2cfa13e` | `lein test` | 1 | 50 |
| `yogthos__migratus-223` | `yogthos/migratus` | `a141234b6c43f81f767197f867fec5ab7b5d0082` | `docker.io/swerebenchv2/yogthos-migratus:223-a141234` | `lein test` | 1 | 5 |
| `pilosus__pip-license-checker-49` | `pilosus/pip-license-checker` | `5952454d8e3b347db33115bd857ea5e116c9102d` | `docker.io/swerebenchv2/pilosus-pip-license-checker:49-5952454` | `lein test` | 7 | 0 |

The selected task specs are saved in:

```text
results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-clojure-batch/selected_specs.json
```

## Commands

The first attempt used multiple positional values after `--instance-ids` and
failed at argument parsing:

```sh
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids chrovis__cljam-268 yogthos__migratus-223 pilosus__pip-license-checker-49 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_clojure_batch.json"
```

The script expects comma-separated IDs, so the official replay used:

```sh
OUT="/home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2-hf-clojure-batch"
cd /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2
../../venvs/swe-rebench-v2/bin/python scripts/eval.py \
  --hf-dataset ibragim-bad/SWE-rebench-V2-sample \
  --hf-config default \
  --hf-split train \
  --hf-offset 0 \
  --hf-length 20 \
  --instance-ids chrovis__cljam-268,yogthos__migratus-223,pilosus__pip-license-checker-49 \
  --max-workers 1 \
  --golden-eval \
  --report-json "$OUT/eval_report_clojure_batch_v2.json"
```

Cleanup checks:

```sh
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | rg 'chrovis|migratus|pilosus|swerebenchv2|<none>' || true
docker ps -a --format '{{.Names}} {{.Image}}' | rg 'chrovis|migratus|pilosus|swerebench' || true
```

## Result

Raw files:

- `selected_specs.json`
- `eval_clojure_batch.log`
- `eval_clojure_batch.exitcode`
- `eval_clojure_batch_v2.log`
- `eval_clojure_batch_v2.exitcode`
- `eval_report_clojure_batch_v2.json`
- `chrovis__cljam-268_log.txt`
- `yogthos__migratus-223_log.txt`
- `pilosus__pip-license-checker-49_log.txt`

The v2 evaluator passed:

- evaluator exit status: 0
- report `total`: 3
- report `all_ok`: true
- all three rows reported `passed_match=true`
- all expected fail-to-pass tests appeared in the passed set
- all expected pass-to-pass tests remained passing
- `error` was empty for all three rows

Per-row oracle summary:

| Instance | Reported F2P passed | Failed P2P | `passed_match` | Row `exit_code` | Notes |
| --- | --- | --- | --- | --- | --- |
| `chrovis__cljam-268` | 1/1 | 0/50 | true | 0 | Container log records 284 tests, 3,221 assertions, 0 failures, 0 errors before patching and clean patch/test-patch application. |
| `yogthos__migratus-223` | 1/1 | 0/5 | true | 1 | Evaluator oracle passed, but the raw row exit code is 1 because the log records a testcontainers Docker-socket error for `/var/run/docker.sock`; keep this as a caveat when choosing a paper-facing row. |
| `pilosus__pip-license-checker-49` | 7/7 | 0/0 | true | 0 | Container log records 43 tests, 12,163 assertions, 0 failures, 0 errors before patching and clean patch/test-patch application. |

The Docker residual checks found no matching SWE-rebench, Clojure-row,
`pilosus`, `chrovis`, or `migratus` images or containers after the run.

## Workload Shapes Reproduced

This batch adds three additional public HF sample rows beyond the prior
`pilosus__pip-license-checker-119` row:

- multiple repositories in the same language family;
- multiple per-instance Docker images;
- `lein test` as a common language-specific build/test command;
- rows with both nonzero pass-to-pass sets and fail-to-pass sets;
- one row with evaluator-level correctness but nonzero raw command exit, which
  should guide row selection for later release workloads.

## Boundaries

Together with the previous HF selected-row record, this reproduces four public
HF Clojure sample rows, not the full 20-task public HF sample and not the full
SWE-rebench V2 corpus.

This run uses public prebuilt per-instance images. It does not reproduce the
base-image builder, per-instance image builder, task collection pipeline, or
environment-generation process.

The first command failed at argument parsing because `--instance-ids` requires
a comma-separated string. The v2 command is the valid official replay.

`yogthos__migratus-223` should be treated carefully: the official evaluator
reported `all_ok=true`, but the raw command exit code was 1 due the nested
testcontainers Docker-socket environment. For a paper-facing W4 row, prefer
rows with both evaluator correctness and row exit code 0 unless this caveat is
part of the experiment design.

## Use In `namei_ext`

Use `chrovis__cljam-268` or `pilosus__pip-license-checker-49` as additional
candidate W4 environment/cache rows if the paper needs Clojure coverage.

The next `namei_ext` implementation step is still to select one source-backed
W4 row and build a Make-owned KVM workload that preserves the source oracle
while recording lookup/readdir behavior and natural baseline behavior.
