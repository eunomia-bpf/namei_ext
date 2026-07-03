# SWE-Factory-Gym Workload Reproduction

Date: 2026-07-02

## Motivation

SWE-Factory-Gym is a useful W4 environment/cache workload seed because it
contains released Dockerfile and evaluation-script artifacts for real
repository tasks. For `namei_ext`, the relevant shape is a reproducible
repository environment with a correctness oracle, not the LLM-based
SWE-Builder generation process.

This record separates the `pallets__click-2622` SWE-Factory-Gym row from the
earlier combined environment-source record and reruns the upstream evaluator in
a new result root.

## Source

- Official repository: <https://github.com/DeepSoftwareAnalytics/swe-factory>
- Local checkout: `.cache/source-inspection/swe-factory`
- Commit: `760b1758c04ba61885972fe8f635c9db3b2c3232`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/`

The selected released Gym row was preserved from the 2026-07-01 Hugging Face
dataset extraction:

- dataset input:
  `results/reproduction/2026-07-01-official-workloads/swe-factory-gym-click2622/dataset.json`
- prediction input:
  `results/reproduction/2026-07-01-official-workloads/swe-factory-gym-click2622/predictions.json`
- instance: `pallets__click-2622`
- repository: `pallets/click`
- version: `8.1`
- base commit: `1787497713fa389435ed732c9b26274c3cdc458d`
- Dockerfile length: 1261 bytes
- eval script length: 931 bytes
- patch length: 1199 bytes
- test patch length: 497 bytes
- prediction: `gold`

## Commands

Environment and source inspection:

```sh
install -d results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622
python3 --version
docker --version
.cache/venvs/swe-factory-eval/bin/python --version
git -C .cache/source-inspection/swe-factory remote -v
git -C .cache/source-inspection/swe-factory rev-parse HEAD
git -C .cache/source-inspection/swe-factory status --short
```

Evaluator rerun:

```sh
cd .cache/source-inspection/swe-factory/evaluation
/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-factory-eval/bin/python run_evaluation.py \
  --dataset_name /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/swe-factory-gym-click2622/dataset.json \
  --predictions_path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-01-official-workloads/swe-factory-gym-click2622/predictions.json \
  --max_workers 1 \
  --run_id namei_ext_click2622_rerun \
  --output_path /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances \
  --timeout 3600 \
  --rm_image false
```

The evaluator writes its top-level report to a relative `reports/` directory
under its current working directory. That generated report was copied back into
the result root at:
`results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/reports/gold.namei_ext_click2622_rerun.json`.

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/summary.json`.

Raw artifacts:

- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/source-inspection.log`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/eval.log`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/reports/gold.namei_ext_click2622_rerun.json`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/Dockerfile`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/build_image.log`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/eval.sh`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/patch.diff`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/report.json`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/run_instance_after_apply.log`
- `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-click2622/run_instances/namei_ext_click2622_rerun/gold/pallets__click-2622/test_output_after_apply.txt`

The rerun passed:

- evaluator exit status: 0
- total instances: 1
- completed instances: 1
- resolved instances: 1
- unresolved instances: 0
- empty patch instances: 0
- error instances: 0
- unstopped containers: 0
- per-instance `patch_successfully_applied`: true
- per-instance `resolved`: true
- pytest oracle: 40 passed
- eval marker: `OMNIGRIL_EXIT_CODE=0`

The generated image was left for cache inspection:

- tag: `setup.pallets__click-2622:latest`
- image ID:
  `sha256:d7408979fc91eb2fb520ffb5b05901264424a18cde5edc93c42d0efcffacbd9f`
- size: 784063675 bytes

## Workload Shapes Reproduced

This is useful W4 workload evidence because it covers:

- generated Dockerfile-backed environment construction;
- real repository checkout and base-commit reset;
- gold patch application;
- test-patch/eval-script application;
- pytest execution over `tests/test_types.py`;
- `OMNIGRIL_EXIT_CODE`-based resolved classification;
- preserved Dockerfile, eval script, patch, build log, test output, and report
  artifacts.

## Boundaries

This rerun covers one SWE-Factory-Gym row, not the full 430-row Gym dataset.

This is not a reproduction of the full SWE-Factory SWE-Builder pipeline. The
LLM-driven Repository Explorer, Environment Manager, Test Manager, Test Analyst,
and environment-memory stages still require API configuration and are not run
here.

The dataset and predictions inputs were reused from the 2026-07-01 Hugging Face
dataset extraction artifacts. This is appropriate for a workload replay, but it
should not be described as regenerating the dataset row.

Do not claim that SWE-Factory-Gym requires eBPF or `namei_ext`; use it as a real
source-backed environment/cache workload seed.

## Use In `namei_ext`

Use this row as a W4 environment/cache seed with a small, fast correctness
oracle. A later Make-owned KVM workload can reuse the generated Dockerfile,
repo checkout, patch, eval script, and pytest oracle while testing whether a
path-view policy can select among canonical, cached, stale, or regenerated
environment state.

Correctness should gate any performance interpretation: the evaluator report
must show `resolved_instances=1`, the per-instance report must show
`patch_successfully_applied=true` and `resolved=true`, and the raw test output
must show `OMNIGRIL_EXIT_CODE=0`.
