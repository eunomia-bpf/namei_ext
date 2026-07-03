# SWE-rebench V2 Workload Reproduction

Date: 2026-07-02

## Motivation

SWE-rebench V2 is a direct W4 environment/cache workload seed because it
packages real repository state, prebuilt Docker images, gold patches,
test patches, test commands, and fail-to-pass/pass-to-pass oracles. For
`namei_ext`, this is useful as a source-backed build/test environment workload:
the system can later evaluate whether a path-view cache or environment selection
policy preserves the same correctness oracle.

This record separates SWE-rebench V2 from the earlier combined
agent-runtime/environment evidence and reruns the official README local sample.

## Source

- Official repository: <https://github.com/SWE-rebench/SWE-rebench-V2>
- Local checkout: `.cache/source-inspection/swe-rebench-v2`
- Commit: `c71902a8cf8d2b725f63d51f199f4d3e56f68d2d`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/`

The selected workload is the repository's `sample.json` task:

- instance: `unidata__netcdf-c-1925`
- repository: `Unidata/netcdf-c`
- base commit: `ad6bff35c39a0600fb8f2e176be4269e768e4e22`
- language: C
- image: `docker.io/swerebenchv2/unidata-netcdf-c:1925-ad6bff3`
- image ID:
  `sha256:7a9ef595f93471c219640a34c22b3e8a1cc894476c57adefa3a5405e7a49c35e`
- test command: `make check`
- log parser: `parse_log_jq`
- expected fail-to-pass tests: 12
- expected pass-to-pass tests: 177

## Commands

Environment and source inspection:

```sh
install -d results/reproduction/2026-07-02-official-workloads/swe-rebench-v2
python3 --version
docker --version
.cache/venvs/swe-rebench-v2/bin/python --version
git -C .cache/source-inspection/swe-rebench-v2 remote -v
git -C .cache/source-inspection/swe-rebench-v2 rev-parse HEAD
git -C .cache/source-inspection/swe-rebench-v2 status --short
docker image inspect swerebenchv2/unidata-netcdf-c:1925-ad6bff3
```

README sample evaluation:

```sh
cd /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2
/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-rebench-v2/bin/python \
  /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2/scripts/eval.py \
  --json /home/yunwei37/workspace/namei_ext/.cache/source-inspection/swe-rebench-v2/sample.json \
  --max-workers 1 \
  --golden-eval \
  --report-json /home/yunwei37/workspace/namei_ext/results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/eval-report.json
```

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/summary.json`.

Raw logs:

- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/source-inspection.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/sample-eval.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/eval-report.json`
- `results/reproduction/2026-07-02-official-workloads/swe-rebench-v2/logs/unidata__netcdf-c-1925_log.txt`

The README sample eval passed:

- evaluator process exit status: 0
- report `total`: 1
- report `all_ok`: true
- instance `exit_code`: 0
- `passed_match`: true
- `failed_from_pass_to_pass`: empty
- `error`: empty

The following 12 fail-to-pass tests were reported as passed:

- `do_comps.sh`
- `format`
- `run_examples.sh`
- `run_examples4.sh`
- `run_filter.sh`
- `sfc_pres_temp_more`
- `simple`
- `t_dap3a`
- `test_cvt3`
- `test_vara`
- `tst_filter.sh`
- `tst_ncdap3.sh`

The preserved container log shows patch and test-patch application followed by
the netcdf-c `make check` test execution.

## Workload Shapes Reproduced

This is useful W4 workload evidence because it covers:

- a real repository checkout inside a prebuilt Docker image;
- deterministic reset before evaluation;
- gold patch and test patch application;
- build/test execution through `make check`;
- fail-to-pass and pass-to-pass oracle parsing from raw logs;
- an explicit Docker image identity that can be reused for cache and
  environment-reuse experiments.

## Boundaries

This pass covers only the official README local sample in `sample.json`. It is
not a full SWE-rebench V2 corpus reproduction and not a Hugging Face 20-task
sample run.

This pass does not rerun the base-image builder or per-instance image builder.
It uses the cached prebuilt `swerebenchv2/unidata-netcdf-c:1925-ad6bff3`
image.

This is an evaluator/workload replay, not LLM-based task construction or
environment generation. Do not claim that SWE-rebench V2 requires eBPF or
`namei_ext`.

## Use In `namei_ext`

Use this sample as a source-backed W4 environment/cache seed. A later
Make-owned KVM `namei_ext` workload can reuse the same repository state, image
identity, patch/test-patch, and `make check` oracle while varying how the
environment or cache path view is selected.

The natural correctness gate is the SWE-rebench V2 evaluator report:
`all_ok=true`, `passed_match=true`, no pass-to-pass failures, and all
fail-to-pass tests present in the passed set. Performance or path-resolution
measurements should be interpreted only after this oracle passes.
