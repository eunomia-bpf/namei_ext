# OpenHands Docker Workspace Reproduction

Date: 2026-07-02

## Motivation

The earlier OpenHands SDK reproduction covered targeted remote-workspace,
file-editor workspace-root, and terminal-session tests, but it did not exercise
the public Docker workspace backend. OpenHands explicitly describes ephemeral
workspaces, including Docker and Kubernetes-style workspaces, as part of the SDK
surface. This run closes the local Docker backend slice without relying on a
live LLM or OpenHands Cloud account.

## Source

- Repository: `.cache/source-inspection/software-agent-sdk`
- Commit: `feca62017e2d33519c953b83f3747ded6b96329d`
- Python environment: `.cache/venvs/openhands-sdk`
- Docker image: `ghcr.io/openhands/agent-server:latest-python`
- Image digest: `ghcr.io/openhands/agent-server@sha256:25bc9f1433a4e5d1739bd782dead90b78ced10fc57066de631896eeddf78d9ec`
- Image id: `sha256:1f489728c1a86fecba4b141c8652fdc2c8a88d21aaab528b1e53f7280306b46a`
- Docker engine: recorded in `docker-workspace-run-v4.log`

## Workload

The reproduction used the upstream `DockerWorkspace` class from
`openhands.workspace` against the official prebuilt agent-server image. The run:

1. Pulled and inspected the official agent-server Docker image.
2. Started a real Docker container through `DockerWorkspace`.
3. Mounted a host workspace directory at `/workspace`.
4. Waited for the agent server health endpoint.
5. Queried `get_server_info()`.
6. Executed a command in `/workspace` that read a host-created file and wrote a
   container-created file.
7. Uploaded a file through the remote workspace API and verified it through a
   shell command.
8. Downloaded a container-created file through the remote workspace API.
9. Paused and resumed the Docker container, then verified command execution
   after resume.
10. Exited the context manager and verified that the `--rm` container was gone.

## Raw Artifacts

Result root:

```text
results/reproduction/2026-07-02-official-workloads/openhands-docker-workspace/
```

Important files:

- `summary.json`: final machine-readable v4 result.
- `docker-pull.log`: official image pull log.
- `docker-image-inspect.json`: image metadata.
- `docker-workspace-run-v4.log`: final clean run log.
- `host-workspace-v4/`: mounted host workspace evidence.
- `downloads-v4/container-created.downloaded.txt`: downloaded remote file.
- `summary-v1-api-name-error.json` and
  `docker-workspace-run-v1-api-name-error.log`: preserved script error from
  using the old `server_info()` method name.
- `summary-v2-host-input-permission.json` and
  `docker-workspace-run-v2-host-input-permission.log`: preserved host input
  permission boundary.
- `summary-v3-pass-stale-cleanup-warnings.json` and
  `docker-workspace-run-v3-pass-stale-cleanup-warnings.log`: passing run with
  stale cleanup warnings from the previous host-workspace directory.

## Final Result

The final v4 run passed. `summary.json` records:

- `status=pass`
- image inspect passed
- container startup and health passed
- `get_server_info()` passed with OpenHands agent-server `version=1.31.0`
- mounted workspace command passed
- API file upload passed
- uploaded file visible to shell command
- API file download passed
- Docker pause passed
- Docker resume plus command execution passed
- container cleanup passed with no remaining `agent-server-*` container

## Caveats

- This is a DockerWorkspace backend reproduction, not OpenHands Cloud,
  Kubernetes, browser, live LLM, or full platform reproduction.
- The source checkout is `feca62017e2d`, while the official prebuilt image
  reports server build git sha `31f71fe172f1104b856a2fa4d873b85ed901098a` and
  version `1.31.0`. This is acceptable for backend workload evidence because the
  tested surface is the published `DockerWorkspace` client API plus official
  prebuilt agent-server image, but it should not be described as a same-commit
  source-image build.
- The v2 failure shows that host-mounted input permissions matter: a `0600`
  host file is not readable by the container user `openhands` uid `10001`.
  The final run uses `0644` input files and a writable mount directory.

## Source-Use Verdict

OpenHands can now be used as a source-backed agent workspace workload seed in
two ways:

- in-process and remote workspace API tests from the earlier targeted test
  reproduction;
- a real Docker-backed ephemeral workspace lifecycle from this run.

Do not claim full OpenHands Cloud, Kubernetes backend, browser, or live-LLM
coverage from this evidence.
