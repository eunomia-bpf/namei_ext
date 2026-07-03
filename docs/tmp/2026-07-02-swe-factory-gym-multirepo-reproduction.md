# SWE-Factory-Gym Multirepo Workload Reproduction

Date: 2026-07-02

## Motivation

The earlier SWE-Factory-Gym reproduction reran one released row,
`pallets__click-2622`. That was enough to prove the evaluator path worked, but
it was still a single-repository replay. This run extends the evidence to
three additional released Gym rows across Python and JavaScript repositories.

For `namei_ext`, these rows are useful W4 environment/cache workload seeds
because each row ships a Dockerfile, repository base commit, gold patch,
evaluation script, test output, and resolved/not-resolved oracle.

## Source

- Official repository: <https://github.com/DeepSoftwareAnalytics/swe-factory>
- Local checkout: `.cache/source-inspection/swe-factory`
- Commit: `760b1758c04ba61885972fe8f635c9db3b2c3232`
- Dataset: `SWE-Factory/SWE-Factory-Gym`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/SWE-Factory__SWE-Factory-Gym/SWE-Factory-Gym.json`
- Dataset rows in local file: 430
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-multirepo/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-multirepo/summary.json`

## Method

The selected rows were extracted from the released Gym JSON into:

- `dataset.json`
- `predictions.json` using the released row patch as the `gold` prediction
- `run-manifest.tsv`
- per-row released `Dockerfile`, `eval.sh`, patch, and test patch snapshots

The upstream evaluator was run with the existing SWE-Factory evaluation virtual
environment:

```sh
.cache/venvs/swe-factory-eval/bin/python run_evaluation.py \
  --dataset_name <result-root>/dataset.json \
  --predictions_path <result-root>/predictions.json \
  --max_workers 1 \
  --run_id namei_ext_gym_multirepo \
  --output_path <result-root>/run_instances \
  --timeout 1800 \
  --rm_image true \
  --reports_dir <result-root>/reports
```

The first evaluator attempt was interrupted after progress reached 1/3. At
that point `python-attrs__attrs-556` had a complete report,
`mochajs__mocha-1965` had partial build/run logs, and `iamkun__dayjs-337` had
not started. The continuation reused the same output root, preserved the
initial `eval.log`, wrote `eval-continuation.log`, and produced the final
top-level report.

## Result

| Row | Repository | Version | Oracle result |
| --- | --- | --- | --- |
| `python-attrs__attrs-556` | `python-attrs/attrs` | `19.1` | resolved; patch applied; 20 pytest tests passed; `OMNIGRIL_EXIT_CODE=0` |
| `mochajs__mocha-1965` | `mochajs/mocha` | `2.3` | resolved; patch applied; Mocha JSON reports 1 test / 1 pass / 0 failures; `OMNIGRIL_EXIT_CODE=0` |
| `iamkun__dayjs-337` | `iamkun/dayjs` | `1.7` | resolved; patch applied; Jest reports 1 suite passed and 2 tests passed; `OMNIGRIL_EXIT_CODE=0` |

Top-level evaluator report:

- total instances: 3
- submitted instances: 3
- completed instances: 3
- resolved instances: 3
- unresolved instances: 0
- error instances: 0
- unstopped containers: 0
- unremoved images: 0

The evaluator removed the `setup.*` images for these rows. A post-run Docker
check found no running `namei_ext_gym_multirepo` containers and no remaining
`setup.python-attrs__attrs-556`, `setup.mochajs__mocha-1965`, or
`setup.iamkun__dayjs-337` images.

## Caveats

This is selected row replay, not full 430-row SWE-Factory-Gym reproduction.

This is not full SWE-Factory SWE-Builder reproduction. The LLM-driven
Repository Explorer, Environment Manager, Test Manager, Test Analyst, and
environment-memory stages are not run here.

The `iamkun/dayjs` eval output includes a post-oracle cleanup warning after
`OMNIGRIL_EXIT_CODE=0`: `git checkout` could not find
`test/constructor.test.js`. The upstream evaluator still reports
`patch_successfully_applied=true` and `resolved=true`; the warning is preserved
as an artifact caveat.

## Use In `namei_ext`

Together with `pallets__click-2622`, SWE-Factory-Gym now contributes four
selected resolved rows across four repositories:

- `pallets/click`
- `python-attrs/attrs`
- `mochajs/mocha`
- `iamkun/dayjs`

Use these rows as W4 environment/cache workload candidates with released
Dockerfiles, eval scripts, gold patches, build logs, test outputs, and
resolved/not-resolved oracles. A later Make-owned KVM workload should select a
small stable subset and add path lookup/readdir tracing around cache,
regeneration, stale, or corrupt environment-state transitions.
