# SWE-Factory-Gym Diverse Extension Reproduction

Date: 2026-07-02

## Motivation

The earlier SWE-Factory-Gym evidence covered four selected resolved rows:
`pallets__click-2622`, `python-attrs__attrs-556`,
`mochajs__mocha-1965`, and `iamkun__dayjs-337`. This run extends the official
Gym replay to three more repositories and adds Node.js frontend/runtime and
Python imaging packages.

For `namei_ext`, these rows are useful W4 environment/cache workload seeds
because each row ships a released Dockerfile, repository base commit, gold
patch, evaluation script, test output, and resolved/not-resolved oracle.

## Source

- Official repository: <https://github.com/DeepSoftwareAnalytics/swe-factory>
- Local checkout: `.cache/source-inspection/swe-factory`
- Commit: `760b1758c04ba61885972fe8f635c9db3b2c3232`
- Dataset: `SWE-Factory/SWE-Factory-Gym`
- Local dataset file:
  `.cache/source-inspection/hf-datasets/SWE-Factory__SWE-Factory-Gym/SWE-Factory-Gym.json`
- Dataset rows in local file: 430
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-diverse-extension/`
- Machine-readable summary:
  `results/reproduction/2026-07-02-official-workloads/swe-factory-gym-diverse-extension/summary.json`

## Method

The selected rows were extracted from the released Gym JSON into:

- `dataset.json`
- `predictions.json`, using the released row patch as the `gold` prediction
- `run-manifest.tsv`
- per-row snapshots of the released `Dockerfile`, `eval.sh`, patch, and test
  patch

The upstream evaluator was run with the existing SWE-Factory evaluation virtual
environment:

```sh
.cache/venvs/swe-factory-eval/bin/python run_evaluation.py \
  --dataset_name <result-root>/dataset.json \
  --predictions_path <result-root>/predictions.json \
  --max_workers 1 \
  --run_id namei_ext_gym_diverse_extension \
  --output_path <result-root>/run_instances \
  --timeout 1800 \
  --rm_image true \
  --reports_dir <result-root>/reports
```

## Result

| Row | Repository | Version | Oracle result |
| --- | --- | --- | --- |
| `nodejs__undici-3566` | `nodejs/undici` | `6.19` | resolved; patch applied; `npx borp -p "test/websocket/issue-3546.js"` passed; `OMNIGRIL_EXIT_CODE=0` |
| `tailwindlabs__tailwindcss-12404` | `tailwindlabs/tailwindcss` | `3.3` | resolved; patch applied; Jest reports 1 suite passed, 1 test passed, and 1 snapshot passed; `OMNIGRIL_EXIT_CODE=0` |
| `python-pillow__Pillow-5425` | `python-pillow/Pillow` | `8.2` | resolved; patch applied; pytest reports 18 passed; `OMNIGRIL_EXIT_CODE=0` |

Top-level evaluator report:

- evaluator exit code: 0
- total instances: 3
- submitted instances: 3
- completed instances: 3
- resolved instances: 3
- unresolved instances: 0
- error instances: 0
- unstopped containers: 0
- unremoved images: 0

Per-row logs report clean patch application for all three rows:

- `nodejs__undici-3566`: `Applied patch lib/web/websocket/websocket.js cleanly.`
- `tailwindlabs__tailwindcss-12404`: `Applied patch src/corePlugins.js cleanly.`
- `python-pillow__Pillow-5425`: `Applied patch src/PIL/TiffTags.py cleanly.`

A post-run Docker check found no running containers or remaining setup images
matching the three row image names or `namei_ext_gym_diverse_extension`.

## Caveats

This is selected row replay, not full 430-row SWE-Factory-Gym reproduction.

This is not full SWE-Factory SWE-Builder reproduction. The LLM-driven
Repository Explorer, Environment Manager, Test Manager, Test Analyst, and
environment-memory stages are not run here.

## Use In `namei_ext`

Together with the earlier `pallets`, `attrs`, `mocha`, and `dayjs` rows,
SWE-Factory-Gym now contributes seven selected resolved rows across seven
repositories:

- `pallets/click`
- `python-attrs/attrs`
- `mochajs/mocha`
- `iamkun/dayjs`
- `nodejs/undici`
- `tailwindlabs/tailwindcss`
- `python-pillow/Pillow`

Use these rows as W4 environment/cache workload candidates with released
Dockerfiles, eval scripts, gold patches, build logs, test outputs, and
resolved/not-resolved oracles. A later Make-owned KVM workload should select a
small stable subset and add path lookup/readdir tracing around cache,
regeneration, stale, or corrupt environment-state transitions.
