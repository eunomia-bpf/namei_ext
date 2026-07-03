# Terminal-Bench ACL Workload Reproduction

Date: 2026-07-01

## Motivation

Earlier Terminal-Bench evidence covered unit tests, installed-agent runtime
tests, and Docker-backed run/resume/status tests. That showed the harness works,
but it was still weaker than reproducing a real benchmark task with its task
input, Docker sandbox, reference solution, and pytest oracle.

This record runs one official Terminal-Bench task that is directly useful for
the `namei_ext` agent-workspace workload family: POSIX ACL inheritance and
protected path behavior.

## Source And Result Root

Source checkout:

- `.cache/source-inspection/terminal-bench`

Revision:

- `1a6ffa9674b571da0ed040c470cb40c4d85f9b9b`

Task:

- `original-tasks/acl-permissions-inheritance`

Raw result root:

- `results/reproduction/2026-07-01-official-workloads/terminal-bench-acl-permissions-oracle/`

Key raw artifacts:

- `summary.json`
- `tb-run.log`
- `2026-07-01__terminal-bench-acl-permissions-oracle/run_metadata.json`
- `2026-07-01__terminal-bench-acl-permissions-oracle/results.json`
- `2026-07-01__terminal-bench-acl-permissions-oracle/run.log`
- per-trial `results.json`
- per-trial `commands.txt`
- per-trial `sessions/agent.log`
- per-trial `sessions/tests.log`

## Command Shape

The run used the upstream Terminal-Bench CLI and built-in oracle agent:

```text
uv run tb run \
  --dataset-path original-tasks \
  --task-id acl-permissions-inheritance \
  --agent oracle \
  --n-concurrent 1 \
  --n-attempts 1 \
  --run-id 2026-07-01__terminal-bench-acl-permissions-oracle \
  --output-path results/reproduction/2026-07-01-official-workloads/terminal-bench-acl-permissions-oracle \
  --no-upload-results \
  --cleanup
```

The `oracle` agent copies the task's `solution.sh` into the task container and
runs it. This is a reference-solution reproduction, not an LLM-agent run.

## Workload Shape

The task asks the agent to create and configure `/srv/shared` with:

- group ownership by `research`;
- setgid directory mode `2770`;
- current ACLs for `research`, `alice`, `bob`, and `others`;
- default inheritable ACLs for future files and directories;
- denial for a user outside the research group.

The Docker task creates users and group state before the agent runs. The pytest
oracle then creates files and subdirectories as `alice`, `bob`, and `mallory`
to validate inheritance and denial behavior.

This is a concrete filesystem-permission workload, not a synthetic metadata
loop.

## Result

The run reproduced cleanly:

- `n_resolved=1`
- `n_unresolved=0`
- `accuracy=1.0`
- resolved task: `acl-permissions-inheritance`
- per-trial `is_resolved=true`
- pytest: `9 passed in 0.41s`

Passed parser checks:

- `test_directory_exists_and_basic_permissions`
- `test_current_acl_settings`
- `test_default_acl_inheritance`
- `test_alice_can_create_and_bob_can_access`
- `test_bob_can_create_and_alice_can_access`
- `test_subdirectory_inheritance`
- `test_outside_users_denied_access`
- `test_file_permissions_inheritance`
- `test_execute_permissions_on_scripts`

The run log also shows the full Terminal-Bench lifecycle:

1. build the task Docker image through `docker compose`;
2. start the task container;
3. record the agent session;
4. run `/oracle/solution.sh`;
5. record the test session;
6. run `/tests/run-tests.sh`;
7. tear down the compose project and remove task images/volumes.

## Interpretation

This strengthens Terminal-Bench from harness/test evidence to a real
source-backed workload seed for `namei_ext`:

- task setup through a Docker sandbox;
- file and directory creation;
- POSIX ACL and permission state;
- multiple users with different path-access outcomes;
- executable pytest correctness oracle.

Use this task family as input for the Make-owned KVM agent workspace lifecycle
workload, especially the protected-path and permission-inheritance sub-oracles.

Do not claim full Terminal-Bench-Core reproduction from this single task. The
claim is narrower: one official Terminal-Bench filesystem-permission task
reproduced cleanly through the upstream harness and oracle agent.
