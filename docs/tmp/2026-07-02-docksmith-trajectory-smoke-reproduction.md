# DockSmith Trajectory Smoke Reproduction

Date: 2026-07-02.
Stage: workload-source reproduction boundary for W4 environment construction.
Source/command: current web search over DockSmith primary artifacts, local
inspection of the Hugging Face `8sj7df9k8m5x8/docker_building_training`
dataset cache, and Docker smoke replay of one extracted trajectory-derived
environment.

## Motivation

DockSmith is relevant because it frames Docker environment construction as a
first-class agentic workload. For `namei_ext`, its useful signal is the W4
shape: repository checkout, dependency/toolchain inference, Dockerfile
generation, eval-script generation, test-analysis feedback, and environment
repair.

The open question was whether the public artifact can be treated as an
executable workload source, or only as a trajectory/methodology source.

## Primary Sources Checked

- DockSmith paper: `https://arxiv.org/abs/2602.00592`
- DockSmith Hugging Face collection:
  `https://huggingface.co/collections/8sj7df9k8m5x8/docksmith`
- Docker-building trajectory dataset:
  `https://huggingface.co/datasets/8sj7df9k8m5x8/docker_building_training/viewer`
- Target repository used for the smoke replay:
  `https://github.com/00imvj00/mqttrs`

Search strings used on 2026-07-02:

- `DockSmith environment construction benchmark Docker building training dataset code repository`
- `DockSmith arxiv 2602.00592 GitHub Docker building training 8sj7df9k8m5x8`
- `site:huggingface.co DockSmith Docker-building trajectory dataset 8sj7df9k8m5x8`
- `"8sj7df9k8m5x8" "docker_building_training"`
- `"docker_building_training" "DockSmith" Hugging Face`

## Local Artifacts Inspected

Local dataset cache:

```text
.cache/source-inspection/hf-datasets/8sj7df9k8m5x8__docker_building_training/
```

Content present locally:

| File | Role |
| --- | --- |
| `1.json` | Complete conversation content for shard 1. |
| `1.index.json` | Index metadata for shard 1. |
| `2.index.json` through `9.index.json` | Index metadata only in this checkout. |

Shard 1 summary:

| Metric | Value |
| --- | ---: |
| Conversation rows | 4033 |
| Distinct instances | 298 |
| Dockerfile-agent rows | 791 |
| Eval-script-agent rows | 646 |
| Instances with tagged Dockerfile and script | 298 |
| Tagged eval scripts with placeholder test patch | 646 |

The dataset is useful: each shard-1 instance has generated Dockerfile and
eval-script text. The replay boundary is that the eval scripts contain a
`[CONTENT OF TEST PATCH]` placeholder rather than the concrete patch needed for
a full fail-to-pass oracle.

## Smoke Replay

Raw result root:

```text
results/reproduction/2026-07-02-official-workloads/docksmith-trajectory-smoke/
```

Selected instance:

| Field | Value |
| --- | --- |
| Instance | `00imvj00__mqttrs-7` |
| Repository | `00imvj00/mqttrs` |
| Commit | `77d51fb5449394e450b3565205d989433511082b` |
| Target tests | `src/decoder_test.rs`, `src/encoder_test.rs` |
| Language/build | Rust/Cargo |

Files preserved under the raw result root:

| File | Purpose |
| --- | --- |
| `metadata.json` | Extracted trajectory metadata and source conversation rows. |
| `shard1_replayability_stats.json` | Shard-level replayability counts. |
| `extracted.Dockerfile` | Final extracted Dockerfile from the trajectory. |
| `extracted_eval_script_with_placeholder.sh` | Original extracted eval script with the missing test-patch placeholder. |
| `smoke_eval_no_test_patch.sh` | Explicit smoke script that removes the unavailable patch step and runs the target tests at the base commit. |
| `docker_build.log` | Raw Docker build log. |
| `docker_run_smoke.log` | Raw smoke test log. |
| `docker_image_inspect.json` | Image metadata before cleanup. |
| `docker_rmi.log` | Image cleanup log. |
| `summary.json` | Machine-readable summary. |

Replay result:

| Check | Result |
| --- | --- |
| Docker build exit code | 0 |
| Smoke run exit code | 0 |
| `decoder_test` | 15 passed, 0 failed |
| `encoder_test` | 14 passed, 0 failed |
| `OMNIGRIL_EXIT_CODE` | 0 |
| Docker image | `sha256:f88ea348fcf84a56430eedd8050fb286bc4f85905a0f4f7257e198302eb2e550` |
| Image cleanup | image removed after run |

## Interpretation

This is a positive DockSmith trajectory-derived environment smoke replay. It
shows that the public trajectory data can yield a concrete Dockerfile and
test-running script for a real repository/commit, and that the extracted final
Dockerfile for `00imvj00__mqttrs-7` builds and runs the target tests.

It is not a full DockSmith benchmark reproduction. The official fail-to-pass
oracle is unavailable for this replay because the public eval script in the
trajectory contains a placeholder instead of the concrete test patch. No
standalone DockSmith pipeline/code repository was found in this pass.

## Use In `namei_ext`

Use DockSmith as:

- a W4 environment-construction trajectory source;
- a source of Dockerfile/eval-script generation and repair phases;
- a source of environment setup/cache pressure and operation-weighted trace
  shape;
- a smoke workload source when a trajectory-derived Dockerfile is sufficient.

Do not use DockSmith as:

- a full official evaluator baseline;
- proof of official fail-to-pass correctness;
- evidence that a workload requires `namei_ext`, eBPF, or dynamic policy logic.

For paper-facing W4 correctness oracles, prefer the already executable sources:
SWE-Factory-Gym selected rows, MEnvData-SWE selected image/eval rows, and the
SWE-rebench V2 README sample.

## Remaining Work

- Download or inspect full content for shards 2 through 9 if broader DockSmith
  trajectory diversity is needed.
- Run additional trajectory-derived smokes for non-Rust rows only if the paper
  needs broader DockSmith examples.
- Keep DockSmith trajectory smokes separate from full W4 correctness rows
  unless concrete test patches and an official evaluator path become available.
