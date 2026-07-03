# SWE-ReX Docker Backend Workload Reproduction

Date: 2026-07-02

## Motivation

The earlier SWE-ReX record reproduced local runtime, in-process remote server,
file transfer, command execution, shell sessions, timeout/interrupt behavior,
interactive commands, pager handling, and multi-session isolation. It explicitly
left Docker, Modal, Fargate, and Daytona backends unrun.

This record closes the local Docker backend subset because it is the closest
container-backed agent runtime workload in SWE-ReX and is directly relevant to
workspace setup, command/session behavior, and deployment lifecycle.

## Source

- Repository: `https://github.com/SWE-agent/SWE-ReX`
- Local checkout: `.cache/source-inspection/swe-rex`
- Commit: `5c995c365dfb1fd5bc56fda688be5d8538f9931f`
- Python environment: `.cache/venvs/swe-rex`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-rex-docker-backend/`

## Raw Artifacts

Important files:

- `summary.json`
- `docker-script-probe.log`
- `docker-build-swe-rex-test.log`
- `pytest-docker-collect.log`
- `pytest-docker.log`

## Setup Probe

The upstream helper script is `tests/setup_test_docker.sh`. Running it from the
repository root failed because the script refers to `swe_rex_test.Dockerfile`
without the `tests/` prefix. Running it from `tests/` would make the Docker
build context too small for `pip install -e .`.

Therefore the equivalent build command used the same Dockerfile and tag but
made the Dockerfile path explicit:

```text
docker build -t swe-rex-test:latest -f tests/swe_rex_test.Dockerfile --build-arg TARGETARCH=$(uname -m) .
```

The image built successfully:

- image: `swe-rex-test:latest`
- image ID: `sha256:23d77d3419a58e14d9b7efba1313a249bf5496fc3128e4fd91942731f8db972c`
- image size: `179475593` bytes

## Test Run

The collected Docker backend tests were:

- `test_docker_deployment`
- `test_docker_deployment_with_python_standalone`
- `test_docker_deployment_config_platform`
- `test_docker_deployment_config_container_runtime`
- `test_podman_deployment`
- `test_podman_deployment_config`

Execution command:

```text
PYTHONPATH=src .cache/venvs/swe-rex/bin/python -m pytest tests/test_docker_deployment.py -q -s
```

Result:

- collected: `6`
- passed: `6`
- failed: `0`
- duration: `15.52s`

No running or exited containers from `swe-rex-test:latest` or `ubuntu:latest`
remained after the test run. The local image remains in the Docker cache as
build evidence.

## Workload Shapes Reproduced

This run covers:

- Docker deployment lifecycle using `swe-rex-test:latest`;
- Docker deployment with `python_standalone_dir` over `ubuntu:latest`;
- container-runtime config parsing for Docker and Podman;
- `DockerDeployment.from_config` for Podman runtime settings;
- container-backed remote runtime liveness checks and stop cleanup.

Together with the earlier local/remote SWE-ReX record, this gives source-backed
coverage for local runtime, remote runtime, and local Docker deployment.

## Caveats

The Podman tests in this file validate runtime selection/configuration; they do
not start a Podman container. Modal, Fargate, and Daytona backends remain
unreproduced because they require cloud/provider-specific setup.

This is SWE-ReX runtime/workspace backend evidence. It is not SWE-agent task
solving evidence and does not claim LLM benchmark performance.

## Reuse Decision

Use SWE-ReX as an agent runtime/workspace workload seed for file transfer,
command/session execution, timeout/interrupt behavior, multi-session isolation,
and now Docker-backed deployment lifecycle. For `namei_ext`, these traces help
shape a realistic agent workspace lifecycle workload and source-system baseline
without claiming that the workload requires eBPF or replacing SWE-ReX.
