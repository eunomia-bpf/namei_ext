# SWE-agent Workload Reproduction

Date: 2026-07-02

## Motivation

SWE-agent was listed as a direct workload seed in
`docs/reference/CODE_SOURCES.md`, but before this run the repository had
reproduction evidence for SWE-ReX and SWE-agent-derived trajectories rather
than the official SWE-agent implementation itself. This run checks whether the
official public repository has executable workload/test paths that can be used
as source-backed agent workspace and build/action evidence.

## Source

- Official repository: <https://github.com/SWE-agent/SWE-agent>
- Local checkout: `.cache/source-inspection/swe-agent`
- Commit: `5f40e63360d654adcd91e30ed11473389bc4909b`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-agent/`

The earlier cached path
`.cache/source-inspection/swe-minisandbox/SWE-agent` was not used as the
authoritative source because its remote points to
`https://github.com/lblankl/SWE-MiniSandbox`, not the official SWE-agent
repository.

## Commands

Source and environment record:

```sh
install -d results/reproduction/2026-07-02-official-workloads/swe-agent
python3 --version
uv --version
docker --version
git -C .cache/source-inspection/swe-agent rev-parse HEAD
```

Official test collection:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-agent \
uv run --extra dev pytest --collect-only -q
```

Partitioned official pytest run:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-agent \
uv run --extra dev pytest -m 'not slow' -q

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-agent \
uv run --extra dev pytest -m 'slow' -q
```

## Result

The official pytest collection reported 125 tests.

The `not slow` partition passed:

- 103 passed
- 2 xfailed
- 20 deselected
- 0 failed
- duration: 51.06 seconds

The `slow` partition passed:

- 19 passed
- 1 xfailed
- 105 deselected
- 0 failed
- duration: 311.00 seconds

Combined partition coverage is therefore:

- 125 collected tests
- 122 passed
- 3 expected failures
- 0 failures

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/swe-agent/summary.json`.

Raw logs:

- `results/reproduction/2026-07-02-official-workloads/swe-agent/source-inspection.log`
- `results/reproduction/2026-07-02-official-workloads/swe-agent/pytest-collect.log`
- `results/reproduction/2026-07-02-official-workloads/swe-agent/pytest-not-slow.log`
- `results/reproduction/2026-07-02-official-workloads/swe-agent/pytest-slow.log`
- `results/reproduction/2026-07-02-official-workloads/swe-agent/leftover-container-before-cleanup.log`

One generated `python3.11-*` container remained after the slow partition. Its
identity was recorded and the container was removed.

## Workload Shapes Reproduced

This is useful source-backed workload evidence because the official tests
exercise:

- agent loop execution with `DummyRuntime`, predetermined model actions, command
  observations, exit statuses, and history/trajectory construction;
- tool parsing and command schema generation;
- `run-replay` over an upstream trajectory with Docker `python:3.11` deployment
  and a cloned `swe-agent/test-repo`;
- `run-single` instant-empty-submit workflows over local and GitHub
  repository/problem-statement combinations;
- `run-batch` simple and expert instance handling with trajectory-output
  oracles.

These paths are directly relevant to an AI agent workspace lifecycle workload:
they create repository workspaces, run command actions, materialize trajectory
and patch outputs, and exercise local/GitHub problem-statement and repository
selection logic.

## Boundaries

This is not a full SWE-bench submission and not an LLM API solve run. The
official tests use deterministic model modes such as `instant_empty_submit`,
`PredeterminedTestModel`, or replay. That is a strength for deterministic
workload reproduction, but it should not be cited as agent problem-solving
accuracy.

The result proves that the official SWE-agent implementation has a clean
reproducible test/workload subset on this host, including Docker-backed replay
and run-single paths. It does not prove that arbitrary SWE-agent benchmark
configs or API-backed runs are reproducible without credentials, images, and
benchmark-specific setup.

## Use In `namei_ext`

SWE-agent should remain a direct workload seed. For the first Make-owned KVM
agent workload, the most reusable pieces are:

- deterministic replay trajectory actions;
- local/GitHub repository and problem-statement setup;
- run-single output artifacts: trajectory, prediction, and patch files;
- command-action and working-directory state from agent history;
- Docker-backed repository workspace setup as a natural source-system behavior.

The `namei_ext` workload should not try to reproduce SWE-agent's full LLM
evaluation loop. It should replay or deterministically drive the workspace and
command-action path behavior, then compare the same oracle against source-system
or materialized/FUSE views.
