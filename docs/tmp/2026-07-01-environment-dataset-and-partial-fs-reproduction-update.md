# Environment Dataset And Partial FS Reproduction Update

Date: 2026-07-01

## Motivation

This record extends the official workload reproduction audit after downloading
full Hugging Face artifacts for environment-construction sources and after
checking whether any remaining full-filesystem sources have additional
reproducible upstream tests. The purpose remains workload selection and oracle
identification for `namei_ext`, not mechanism exclusivity.

Raw logs and derived artifacts are under:

- `results/reproduction/2026-07-01-official-workloads/`

Downloaded dataset caches are under:

- `.cache/source-inspection/hf-datasets/`

## New Results

| Source | Additional artifact attempted | Result | Reuse decision |
| --- | --- | --- | --- |
| MEnvAgent / MEnvData | Full `MEnvData-SWE` JSONL, full trajectory JSONL, Docker Hub registry probes, official image/eval rows | Downloaded 3,005 environment rows across 10 languages and 3,918 trajectory rows over 3,000 unique image names. The trajectories expose `execute_bash`, `str_replace_editor`, and `submit` tool schemas. Passing image/eval rows now include `python-attrs__attrs-586` and `go-task__task-1814`; a Rust row, `eyre-rs__color-eyre-114`, pulled but failed applying the official test patch because the new test file already existed. | Strong executable W4 environment/cache seed plus dataset and trajectory source. Do not claim full MEnvAgent system reproduction because the public repo still does not expose the core runtime as a complete runnable system; do not assume every released row replays without per-row evidence. |
| Multi-Docker-Eval | Full HF parquet and evaluator schema | Downloaded the 334-row test parquet. Rows contain task metadata, patches, test patches, language, and label, but not Dockerfile/eval-script outputs. | Use as benchmark/task corpus and environment-construction selection criteria. Full evaluator run still needs `docker_res` artifacts or generated Docker results. |
| SWE-Factory | Correct HF datasets plus `SWE-Factory-Gym` one-task evaluator run | Downloaded `Deep-Software-Analytics/SweSetupBench-lite` with 671 rows, `SWE-Factory-Gym` with 430 rows including Dockerfile and eval script, and `DeepSWE-Agent-Kimi-K2-Trajectories-2.8K` with 2,809 trajectory rows. A one-task `pallets__click-2622` gold-patch run through the upstream evaluator completed and resolved: 40 pytest tests passed and `OMNIGRIL_EXIT_CODE=0`. | Strong W4 executable workload source. Still do not claim full SWE-Builder generation because the LLM-driven builder stage was not run. |
| DockSmith | Full file list, all index shards, and one full training shard structure | The model is public and not gated. The training dataset has nine JSON shards plus indexes. All nine index shards were downloaded: 39,719 conversation metadata rows. Shard 1 contains 4,033 conversation lists, aligned with 4,033 metadata rows, spanning context retrieval, test analysis, Dockerfile writing, and eval-script writing agents. | Strong trajectory and Docker/eval-script generation workload source. Do not claim an official DockSmith evaluator or primary code reproduction because no primary public code repo or direct eval harness was identified. |
| IndexFS original | Non-RPC unit tests from the partially built original tree | Nine built tests ran successfully: `bitmap_test`, `dirctrl_test`, `didxcache_test`, `network_test`, `fstat_test`, `dbtypes_test`, `metadb_test`, `leveldb_test`, and `monitor_test`. The RPC/server build remains blocked by old Boost pointer APIs versus modern Thrift `std::shared_ptr` APIs. | Related-work/appendix metadata-source evidence is stronger than before, but original full IndexFS workload remains unclosed until the RPC layer is ported or built against an old Thrift stack. |

## Logs And Artifacts

New raw or derived files:

- `hf-full-file-downloads.log`
- `hf-full-dataset-summaries.log`
- `hf-dataset-derived-counts.json`
- `menvdata-image-registry-probe.log`
- `menvdata-mcatwj-registry-probe.log`
- `menvdata-python-attrs-586/extract-summary.json`
- `menvdata-python-attrs-586/docker-pull.log`
- `menvdata-python-attrs-586/eval.log`
- `menvdata-python-attrs-586/run-summary.json`
- `menvdata-go-task-1814/run-summary.json`
- `menvdata-rust-color-eyre-114/run-summary.json`
- `docksmith-shard-structure-probe.log`
- `docksmith-index-download-and-summary.log`
- `docksmith-index-summary.json`
- `hf-swe-factory-dataset-search.log`
- `swe-factory-hf-download-summary.log`
- `swe-factory-eval-venv-install.log`
- `swe-factory-gym-click2622-prepare.log`
- `swe-factory-gym-click2622-eval-after-venv.log`
- `swe-factory-gym-click2622/`
- `indexfs-partial-unit-tests.log`

The SWE-Factory-Gym run wrote:

- `swe-factory-gym-click2622/reports/gold.namei_ext_click2622.json`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/report.json`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/test_output_after_apply.txt`
- `swe-factory-gym-click2622/run_instances/namei_ext_click2622/gold/pallets__click-2622/build_image.log`

Key outcome:

- report: `completed_instances=1`, `resolved_instances=1`, `error_instances=0`;
- instance report: `patch_successfully_applied=true`, `resolved=true`;
- pytest oracle: `40 passed in 0.02s`;
- eval marker: `OMNIGRIL_EXIT_CODE=0`;
- image left intentionally for cache inspection: `setup.pallets__click-2622:latest`.

## Source Details

### MEnvAgent / MEnvData

The public MEnvAgent repository still states that the core code is being
organized for release. The full released datasets are nevertheless useful:

- `MEnvData-SWE`: 3,005 rows.
- Languages: C 16, C++ 31, Go 502, Java 33, JavaScript 578, PHP 159,
  Python 477, Ruby 283, Rust 769, TypeScript 157.
- Each sampled row has `env_setup_script`, `original_env_setup_script`,
  `eval_script`, and `image_name`.
- `MEnvData-SWE-Trajectory`: 3,918 rows over 3,000 unique image names.
- Trajectory tool names: `str_replace_editor`, `execute_bash`, `submit`.

The first environment image was `swe-images-c:systemd-systemd-pr-24645`.
Initial manifest probes against the bare tag and several plausible registry
prefixes failed. A later source check of the HF README found the official
Docker Hub namespace convention: `mcatwj/<image_name>`. Under that convention,
both `mcatwj/swe-images-c:systemd-systemd-pr-24645` and
`mcatwj/swe-images-python:python-attrs-attrs-pr-586` have public manifests.

The selected executable task was `python-attrs__attrs-586` from
`python-attrs/attrs`. It used:

- image: `mcatwj/swe-images-python:python-attrs-attrs-pr-586`;
- base commit: `3432df571117386cd7f58db3222ed1dd7fa35d7b`;
- official eval script from `MEnvData-SWE`;
- official test patch adding `test_non_comparable_defaults`.

The Docker pull succeeded. Running the official eval script inside the image
completed with:

- Docker run exit: 0;
- pytest oracle: `21 passed, 1 warning in 0.08s`;
- eval marker: `OMNIGRIL_EXIT_CODE=0`;
- completion marker: `COMMAND_EXECUTION_COMPLETE`.

This closes one concrete executable MEnvData-SWE workload slice. The later
polyglot extension in
`docs/tmp/2026-07-01-menvdata-polyglot-eval-extension.md` adds a passing Go row
and a negative Rust row. Together, the safe conclusion is that MEnvData-SWE has
real executable image/eval rows, but selected rows need per-row verification.
This still does not reproduce the full MEnvAgent system because the public
MEnvAgent repository still states that core code is being organized for
release.

### Multi-Docker-Eval

The full HF test parquet has 334 rows. It covers C, Go, JavaScript, Ruby, and
Rust with 40 rows each; Python has 39 rows, Java has 35 rows, C++ has 30 rows,
and PHP has 30 rows. Labels are 267 hard and 67 easy.

The rows do not include Dockerfile or eval-script fields. The upstream
evaluator still needs a separate `docker_res` object containing Dockerfile,
eval script, and optional setup scripts. Therefore this is a strong task and
benchmark source, but not a complete executable workload without generated or
released environment artifacts.

### SWE-Factory

The correct SetupBench-lite HF dataset is
`Deep-Software-Analytics/SweSetupBench-lite`, not `SWE-Factory/SetupBench-Lite`.
It contains 671 rows.

`SWE-Factory/SWE-Factory-Gym` is more directly reusable because it has 430 rows
with Dockerfile and eval script. The selected smoke task was
`pallets__click-2622` from `pallets/click`. Running the upstream evaluator with
the gold patch succeeded and produced a resolved report.

This closes a real executable SWE-Factory-derived workload slice. It does not
reproduce the LLM-driven SWE-Builder generation stage; that stage still
requires API configuration and would generate Docker/eval artifacts.

### DockSmith

The HF model `8sj7df9k8m5x8/DockSmith` is public and not gated. The training
dataset `8sj7df9k8m5x8/docker_building_training` has JSON shards `1.json`
through `9.json` plus matching index files. All index shards were downloaded.

Shard 1's structure was inspected in full: `1.json` is a list of 4,033
conversation lists, and `1.index.json` has 4,033 matching metadata rows. The
conversation roles are system/user/assistant, and the metadata names
agent-specific stages such as context retrieval, test analysis, Dockerfile
writing, and eval-script writing.

This is enough to reuse DockSmith as an environment-construction trajectory
source. It is not enough to claim DockSmith system reproduction because no
primary code repository or official evaluator entry point was identified.

### IndexFS

The original IndexFS build is no longer simply "nothing ran." The non-RPC
pieces built earlier produced runnable tests, and these passed:

- `common/bitmap_test`: 18 tests passed.
- `common/dirctrl_test`: 4 tests passed.
- `common/didxcache_test`: 4 tests passed.
- `common/network_test`: exit status 0.
- `metadb/fstat_test`: 7 tests passed.
- `metadb/dbtypes_test`: 27 tests passed.
- `metadb/metadb_test`: 16 tests passed, including extraction, bulk insertion,
  local bulk insertion, and restart.
- `util/leveldb_test`: 2 tests passed.
- `util/monitor_test`: 3 tests passed.

The full server/RPC path remains blocked by Thrift API drift. The build fails
because generated/current Thrift APIs use `std::shared_ptr` and changed
`TThreadedServer` constructor signatures, while the original IndexFS code uses
old `boost::shared_ptr` call sites.

## Implication For `namei_ext`

The environment/cache workload family now has two additional executable seeds:
SWE-Factory-Gym and MEnvData-SWE. Together with SWE-rebench V2, they can drive
real Docker-backed build/test/cache traces. MEnvAgent is not reproduced as a
full system, but its dataset now has at least one verified executable image
row. DockSmith remains stronger than metadata because it provides
environment-construction conversations, but public evaluator access is not
closed.

IndexFS should remain related work or appendix evidence. Its metadata-layer
tests are reproducible, but the full distributed metadata service and tree
workload are not reproduced on the current toolchain.
