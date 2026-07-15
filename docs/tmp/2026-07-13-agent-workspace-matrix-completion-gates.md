# Agent Workspace Matrix Completion Gates

Date: 2026-07-13

## Motivation

BUILD_AND_EVALUATE step 0002 admitted Experiment A as the headline Agent
workspace matrix. Independent plan review found that the existing
`make experiment-agent-workspace` target was still preflight-sized: it could
pass when important planned rows were absent. That would repeat the user's
rejected pattern of scattered or incomplete experiments.

## Changes

The Experiment A runner and Make target were strengthened without changing the
frozen scientific contract or adding a new baseline family.

`tests/agent_workspace/namei_ext_agent_workspace.c` now emits and checks:

- lower-FS/no-hook control rows over the base and upper trees;
- generated-file negative-before-write evidence;
- final logical-tree manifest evidence;
- fixed stat and readdir latency rows;
- unregistered-target containment after target-registry clear.

`tests/agent_workspace/namei_ext_agent_workspace_fuse.c` now emits the matching
FUSE-side controls, negative-before-write evidence, final manifest, and stat
and readdir latency rows.

`mk/kvm.mk` now fails `kvm-agent-workspace-matrix` when required case,
manifest, metric, or boundary rows are absent. It also fails the target if the
matrix dmesg contains kernel failure patterns such as `BUG:`, `WARNING:`,
`Oops:`, `Call Trace:`, hung task, general-protection fault, NULL pointer,
KASAN, or UBSAN.

## Boundary

These repairs do not make the existing raw matrix roots final paper evidence.
They only make the next Make-owned run a credible full-matrix attempt. The run
still requires result review before interpretation, and result review may still
classify the experiment as incomplete if the workload remains too small or if
FUSE parity, lower-FS preservation, or RQ3 boundary accounting is insufficient.

## Validation To Run

The next validation commands are:

```text
make agent-workspace
make experiment-agent-workspace
```

The second command must run in KVM through the real `cgroup/namei_ext` attach
path and preserve raw outputs under
`results/experiments/agent-workspace-matrix/<RUN_ID>/`.
