# OpenHands SDK Workload Reproduction

Date: 2026-07-02

## Motivation

OpenHands SDK is a direct workload seed because it exposes agent workspaces,
file tools, terminal tools, and local or ephemeral execution environments.
For `namei_ext`, the relevant workload shape is not LLM solve accuracy; it is
agent-visible workspace and tool lifecycle behavior: remote workspace command
execution, file upload/download/read/write, file-editor path validation, and
terminal session behavior.

## Source

- Official repository: <https://github.com/OpenHands/software-agent-sdk>
- Local checkout: `.cache/source-inspection/software-agent-sdk`
- Commit: `feca62017e2d33519c953b83f3747ded6b96329d`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/openhands-sdk/`

The checkout had a modified `uv.lock` before this run. It was not cleaned or
reverted.

## Commands

Environment and source inspection:

```sh
git -C .cache/source-inspection/software-agent-sdk rev-parse HEAD
git -C .cache/source-inspection/software-agent-sdk status --short
python3 --version
uv --version
node --version
npm --version
tmux -V
```

Targeted collection and execution:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/openhands-sdk \
uv run --frozen pytest \
  tests/sdk/workspace/remote \
  tests/tools/file_editor/test_workspace_root.py \
  tests/tools/terminal/test_terminal_session.py \
  --collect-only -q

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
UV_PROJECT_ENVIRONMENT=/home/yunwei37/workspace/namei_ext/.cache/venvs/openhands-sdk \
uv run --frozen pytest \
  tests/sdk/workspace/remote \
  tests/tools/file_editor/test_workspace_root.py \
  tests/tools/terminal/test_terminal_session.py \
  -q
```

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/openhands-sdk/summary.json`.

The targeted subset collected 195 tests and passed all 195 tests in
191.10 seconds.

Covered paths:

- `tests/sdk/workspace/remote`
- `tests/tools/file_editor/test_workspace_root.py`
- `tests/tools/terminal/test_terminal_session.py`

Covered workload/oracle shapes:

- remote workspace command execution and polling;
- multiple command isolation;
- duplicate output suppression during polling;
- remote workspace upload/download/read/write behavior;
- file-editor workspace-root path validation;
- terminal session behavior over tmux and subprocess backends;
- terminal cwd, multiline commands, failed commands, long output, pager
  behavior, and session cleanup.

## Warnings And Boundaries

`uv run --frozen` warned that `pyproject.toml` setting
`exclude-newer = "7 days"` failed date parsing during settings discovery. The
warning did not prevent pytest from collecting and passing the targeted tests.

This is not a full OpenHands Cloud/platform reproduction. It does not run live
LLM conversations, cloud workspaces, Docker/Kubernetes workspace backends,
browser tasks, or the remote agent server deployment. It is a local
SDK/workspace/tool lifecycle reproduction.

Follow-up: `docs/tmp/2026-07-02-openhands-docker-workspace-reproduction.md`
closes the local DockerWorkspace backend slice with the official prebuilt
agent-server image. OpenHands Cloud, Kubernetes, browser, and live LLM paths
remain unreproduced.

## Use In `namei_ext`

Use OpenHands SDK as a strong source-backed agent workspace and tool lifecycle
workload seed. The natural adaptation is to replay or synthesize the same
workspace/tool lifecycle behaviors under a Make-owned KVM `namei_ext` workload:
workspace setup, remote-command or terminal-command phases, file-tool path
validation, file upload/download/read/write views, and command-output/session
cleanup oracles.

Do not claim that OpenHands SDK requires eBPF path-resolution policy, and do
not treat this targeted subset as full OpenHands platform reproduction.
