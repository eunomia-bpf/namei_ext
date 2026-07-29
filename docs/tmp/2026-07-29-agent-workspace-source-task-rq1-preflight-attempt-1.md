# Agent Workspace Source-Task RQ1 Preflight: Attempt 1

## Purpose

This was the first real KVM preflight for the source-derived Agent Workspace
workload. The run used the modified kernel and the real `cgroup/namei_ext`
attach workflow. Its purpose was to validate the admitted oracle before the
three-boot formal run.

## Run

- Result root:
  `results/experiments/agent-workspace-source-task-rq1-preflight/20260729T-agent-source-task-preflight01/`
- Source task: SWE-Factory-Gym `pallets__click-2622`
- Click base commit: `1787497713fa389435ed732c9b26274c3cdc458d`
- SWE-Factory source commit: `760b1758c04ba61885972fe8f635c9db3b2c3232`
- Entry point:
  `make kvm-agent-workspace-source-task-rq1-preflight RUN_ID=20260729T-agent-source-task-preflight01`

The earlier one-second host invocation ended while building the kernel and
never entered the guest. It is not a preflight attempt.

## Observations

The guest prepared the fixed Click source tree and applied the source task's
test patch and gold patch. The physical controls produced the intended task
behavior:

- base workspace: 40 tests collected, 39 passed, and only
  `tests.test_types::test_choice_get_invalid_choice_message` failed;
- completed workspace: 40 tests collected and 40 passed;
- both import probes resolved the expected `click` package;
- source-tree status, lower-file comparisons, inventory, and dmesg collection
  completed without an external mutation or kernel warning.

The controller stopped before loading or attaching the BPF policy because the
base-control JUnit parser returned failure. The JUnit record identifies the
failed case with `classname="tests.test_types"` and
`name="test_choice_get_invalid_choice_message"`, but pytest 8 omits the optional
`file` attribute. The parser had required `file="tests/test_types.py"`, so it
rejected the otherwise exact expected result.

## Decision

This attempt does not support an RQ1 result. It is retained as raw failed-run
evidence. The failure is an oracle-adapter incompatibility, not a contradiction
of the source task or the name-resolution hypothesis.

The repair removes the optional JUnit `file` requirement and instead requires
the exact structured classname and test name. It does not change the substantive
gate: base must be exactly 39 passed and one specified failure, while completed
must be exactly 40 passed and zero failures.

## Next Step

Rebuild the parser artifact and run a fresh KVM preflight. If that run reaches
the real attach path and satisfies every lifecycle, source-task, isolation,
fresh-child, lower-file, cleanup, inventory, and dmesg oracle, perform an
independent evidence review before the three-boot formal run.
