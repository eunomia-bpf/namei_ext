# Multi-Docker-Eval Python Manual Docker-Res Replay

Date: 2026-07-02.
Stage: W4 environment-construction workload reproduction boundary.
Source/command: current Multi-Docker-Eval paper/dataset/repository sources,
local Hugging Face parquet inspection, and upstream evaluator runs with a
manual `docker_res` entry for one public Python task.

## Motivation

The earlier Multi-Docker-Eval probe established that the public evaluator works
when a `docker_res` entry exists, but the successful row used a synthetic Go
environment. This step checks whether we can reproduce a second language using
a public task row with concrete `patch` and `test_patch`, while keeping the
artifact boundary clear: the environment result is manual, not an official
released Multi-Docker-Eval generated output.

## Primary Sources Checked

- Paper: `https://arxiv.org/abs/2512.06915`
- Hugging Face dataset: `https://huggingface.co/datasets/litble/Multi-Docker-Eval`
- Code repository: `https://github.com/Z2sJ4t/Multi-Docker-Eval`
- Local source checkout: `.cache/source-inspection/multi-docker-eval`
- Local parquet:
  `.cache/source-inspection/hf-datasets/litble__Multi-Docker-Eval/data/test-00000-of-00001.parquet`

Search strings used on 2026-07-02:

- `Multi-Docker-Eval GitHub Z2sJ4t Multi-Docker-Eval docker_res`
- `HuggingFace litble Multi-Docker-Eval docker_res`
- `Multi-Docker-Eval benchmark Docker environment construction paper code`

## Public Artifact Boundary

The public parquet still has 334 task rows and these columns:

```text
repo, pull_number, instance_id, issue_numbers, base_commit, patch,
test_patch, problem_statement, hints_text, created_at, language, label
```

It does not include official generated Dockerfiles, eval scripts,
`setup_scripts`, or `docker_res`. The evaluator requires `base.docker_res`;
the repository provides converters from SWE-Builder and RepoLaunch result
formats, but this checkout does not include generated SWE-Builder or
RepoLaunch result directories for the benchmark rows.

## Selected Task

| Field | Value |
| --- | --- |
| Instance | `pallets-eco__flask-wtf-512` |
| Repository | `pallets-eco/flask-wtf` |
| Base commit | `b86d5c6516344f85f930cdd710b14d54ac88415c` |
| Language | Python |
| Difficulty label | Easy |
| Target test | `tests/test_recaptcha.py` |
| Problem | Werkzeug 2.1 JSON handling breaks empty submitted forms. |

Raw result root:

```text
results/reproduction/2026-07-02-official-workloads/multi-docker-eval-python-manual-res/
```

## Replay Attempts

All attempts used the upstream Multi-Docker-Eval evaluator with
`test.stability_runs=1`, the public task row, the public gold patch, and a
manual `docker_res` entry.

| Attempt | Environment change | Evaluator exit | Result | Key evidence |
| --- | --- | ---: | --- | --- |
| v1 | `pip install -e '.[test]'` | 0 | F2F | `pytest: command not found`; both before and after emitted `OMNIGRIL_EXIT_CODE=127`. |
| v2 | Install package plus explicit `pytest` | 0 | F2F | Test collection failed because current Flask no longer exports `Markup`; both before and after emitted `OMNIGRIL_EXIT_CODE=2`. |
| v3 | Pin `Flask==2.1.3`, `Werkzeug==2.1.0`, `WTForms==3.0.1`, and install `pytest` | 0 | F2P | Before patch failed under Werkzeug 2.1 JSON behavior; after gold patch passed 13/13 tests with `OMNIGRIL_EXIT_CODE=0`. |

The v1/v2 failures are useful environment-construction evidence. They show why
this benchmark is not just "run pytest": missing test tooling and dependency
version drift both determine whether the public task oracle is meaningful.

## Final v3 Result

The final upstream evaluator report for
`manual-python-pallets-eco-flask-wtf-512-v3`:

```json
{
  "dataset_instances": 1,
  "provided_instances": 1,
  "provided_rate": 1.0,
  "summary": {
    "total_instances": 1,
    "failed_before_patch": 1,
    "passed_after_patch": 1,
    "details": {
      "f2p_instance": 1,
      "p2p_instance": 0,
      "f2f_instance": 0,
      "p2f_instance": 0,
      "resolved": 1,
      "stable": 1
    }
  }
}
```

Before applying the gold patch, `tests/test_recaptcha.py` failed with
Werkzeug/Flask `BadRequest` exceptions caused by JSON loading on a non-JSON
request. After applying the gold patch, the same target test passed:

```text
13 passed in 0.03s
OMNIGRIL_EXIT_CODE=0
```

The final v3 image size was 998,327,314 bytes.

## Interpretation

This is a positive Multi-Docker-Eval public-task replay with a manual
environment result. It strengthens the workload evidence beyond the earlier
single Go probe by covering a Python dependency-drift task and showing the
upstream evaluator's F2P classification on a concrete public row.

It is still not full official Multi-Docker-Eval reproduction. The critical
`docker_res` was manually constructed, not released by the benchmark authors or
generated through an official SWE-Builder/RepoLaunch output artifact. It should
be cited as:

- public task row replay;
- manual environment-construction reproduction;
- evidence of real W4 dependency/version pressure;
- evaluator-path evidence once `docker_res` is supplied.

It should not be cited as:

- official generated `docker_res` reproduction;
- full benchmark reproduction;
- proof that a workload requires `namei_ext`, eBPF, or dynamic policy logic.

## Use In `namei_ext`

For a future W4 workload, this row supplies a concrete environment/cache
transition shape:

- setup state: clone/reset `pallets-eco/flask-wtf`;
- environment state: Python package install plus Flask/Werkzeug/WTForms pins;
- correctness oracle: fail before patch, pass after patch;
- materialization/cache pressure: dependency version selection changes whether
  the target test is even runnable.

Paper-facing W4 correctness rows should still prefer sources with official
released environment outputs, such as SWE-Factory-Gym and MEnvData-SWE, unless
the paper explicitly labels Multi-Docker-Eval rows as manual `docker_res`
replays.
