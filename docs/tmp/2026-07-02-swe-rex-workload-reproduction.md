# SWE-ReX Workload Reproduction

Date: 2026-07-02

## Motivation

SWE-ReX is a direct workload seed because it is the execution runtime used by
SWE-agent-style software-engineering agents. For `namei_ext`, the useful
evidence is not model solve accuracy. The useful workload shape is agent-visible
runtime behavior: workspace file transfer, command execution, shell sessions,
timeouts, interrupts, and multiple isolated sessions.

This record separates SWE-ReX from the earlier combined agent-runtime evidence
and records a focused, reproducible local/remote-runtime subset.

## Source

- Official repository: <https://github.com/SWE-agent/SWE-ReX>
- Local checkout: `.cache/source-inspection/swe-rex`
- Commit: `5c995c365dfb1fd5bc56fda688be5d8538f9931f`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rex/`

The checkout was clean before this run.

## Commands

Environment and source inspection:

```sh
install -d results/reproduction/2026-07-02-official-workloads/swe-rex
python3 --version
uv --version
git -C .cache/source-inspection/swe-rex remote -v
git -C .cache/source-inspection/swe-rex rev-parse HEAD
git -C .cache/source-inspection/swe-rex status --short
```

Targeted collection:

```sh
cd .cache/source-inspection/swe-rex
PYTHONPATH=src /home/yunwei37/workspace/namei_ext/.cache/venvs/swe-rex/bin/python -m pytest \
  tests/test_runtime.py \
  tests/test_local_runtime.py \
  tests/test_dummy_deployment.py \
  tests/test_local_deployment.py \
  tests/test_remote_deployment.py \
  tests/test_execution.py \
  tests/test_server.py \
  --collect-only -q
```

Raw selected run, preserving the auth-status drift:

```sh
PYTHONPATH=src /home/yunwei37/workspace/namei_ext/.cache/venvs/swe-rex/bin/python -m pytest \
  tests/test_runtime.py \
  tests/test_local_runtime.py \
  tests/test_dummy_deployment.py \
  tests/test_local_deployment.py \
  tests/test_remote_deployment.py \
  tests/test_execution.py \
  tests/test_server.py \
  -q
```

Passing runtime/workspace subset:

```sh
PYTHONPATH=src /home/yunwei37/workspace/namei_ext/.cache/venvs/swe-rex/bin/python -m pytest \
  tests/test_runtime.py \
  tests/test_local_runtime.py \
  tests/test_dummy_deployment.py \
  tests/test_local_deployment.py \
  tests/test_remote_deployment.py \
  tests/test_execution.py \
  tests/test_server.py \
  -q -k 'not test_unauthenticated_request'
```

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/swe-rex/summary.json`.

Raw logs:

- `results/reproduction/2026-07-02-official-workloads/swe-rex/source-inspection.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rex/collect-local-remote.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rex/pytest-local-remote-with-auth-drift.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rex/pytest-local-remote-exclude-auth-drift.log`
- `results/reproduction/2026-07-02-official-workloads/swe-rex/python-package-versions.log`

The targeted collection reported 70 tests.

The raw selected run produced:

- 68 passed
- 1 failed
- 1 xfailed
- failed test: `tests/test_server.py::test_unauthenticated_request`

The failure is an auth status-code drift: the test expects unauthenticated
requests to return 403, while the current FastAPI/API-key path returns 401.
This is useful negative evidence for API compatibility, but it is not a
workspace/runtime workload failure.

After excluding only that status-code drift, the same selected set produced:

- 68 passed
- 1 deselected
- 1 xfailed
- 0 failed
- 34 warnings
- duration: 24.51 seconds

## Workload Shapes Reproduced

The passing subset covers:

- local runtime file upload and readback;
- dummy and local deployment lifecycle;
- remote deployment lifecycle against an in-process FastAPI server;
- remote read/write file behavior;
- shell command execution with stdout, stderr, and exit-code checks;
- session create/close and missing-session errors;
- command timeouts, interrupt handling, pager interruption, and interactive
  Python sessions;
- multiple isolated shell sessions;
- multi-line commands, heredocs, blank lines, comments, and bash syntax
  handling;
- remote upload of files and directories.

These are strong source-backed runtime/workspace oracles for a `namei_ext`
agent workload. They expose concrete filesystem and path-facing state:
temporary files, uploaded directories, working directories, session-local shell
state, stdout/stderr files or streams, and cleanup/close behavior.

## Boundaries

This pass does not run SWE-ReX Docker deployment tests. It also does not run
Modal, Fargate, or Daytona cloud/backend tests. Those are broader runtime
backend tests and should not be counted as reproduced here.

This pass is not a full SWE-agent benchmark run and not an LLM solve run. It is
a runtime/workspace harness reproduction.

## Use In `namei_ext`

Use SWE-ReX as a source-backed runtime harness seed for the AI agent workspace
workload. The most reusable pieces are:

- command execution over local and remote runtime APIs;
- file read/write/upload oracles;
- shell session create/close, timeout, interrupt, and multi-session isolation;
- interactive command and pager behavior;
- deterministic local test inputs that do not require API credentials.

The `namei_ext` adaptation should run through a Make-owned KVM workload, replay
the file/session/command lifecycle, and compare its correctness against native
SWE-ReX behavior and materialized or source-system baselines. Do not claim that
SWE-ReX requires eBPF or that this subset proves full SWE-ReX backend coverage.

## Follow-Up

`docs/tmp/2026-07-02-swe-rex-docker-backend-reproduction.md` closes the local
Docker backend subset left open in this record. That follow-up built
`swe-rex-test:latest` and passed `6/6` Docker deployment tests. Modal, Fargate,
Daytona, and live/cloud backends remain outside the reproduced subset.
