# Agent Workspace RQ2 Preflight v1

Date: 2026-07-27

## Motivation

The first formal two-boot preflight was intended to validate the independent
KVM matrix before launching the 20-boot Agent workspace RQ2 experiment. The
preflight failed in the first `namei_ext` boot. This record preserves the
failure, diagnosis, and forward fix.

## Execution

The preflight was started through:

```text
make kvm-agent-workspace-rq2-preflight \
  RUN_ID=20260727T-agent-workspace-rq2-preflight-v1
```

The preserved result root is:

```text
results/experiments/agent-workspace-rq2-preflight/
  20260727T-agent-workspace-rq2-preflight-v1/
```

`run.json` records `status=failed` and
`failure=kvm-launch-or-guest-command`. The first boot verified the expected
kernel commit, release, build ID, notes, BTF, `namei_ext_lookup` symbol, and TSC
clocksource. The real `cgroup/namei_ext` policy loaded and executed. It emitted
615 raw JSONL rows before returning failure.

## Failure

All measured lifecycle and path-operation samples passed. The only failed
correctness row before the summary was:

```json
{"case":"base_deleted_preserved","pass":false,"errno":2}
```

The policy hid every component named `deleted.txt` while attached. The runner
then attempted to read `base/deleted.txt` directly from the same cgroup before
detaching the policy. That operation was therefore subject to the same hide
decision.

## Diagnosis

Two issues were exposed:

1. The runner attached `agent_workspace_view.bpf.c` with global parent scope,
   even though the kernel already provides exact parent dispatch through
   `/sys/kernel/debug/namei_ext/policy_parent`.
2. The lower-object preservation oracle conflated two properties. Reading a
   lower pathname from the attached cgroup tests policy bypass, not whether the
   lower object was modified. Lower-object preservation must be checked after
   detaching the policy or from outside its cgroup.

The failure is not evidence about the comparative cost hypothesis. It occurred
before the FUSE boot and before paired analysis.

## Forward Fix

The `namei_ext` runner now configures exact policy-parent scope for:

- the logical `view` parent that contains `ws`;
- the `base` directory that may be selected as the workspace root;
- the `upper` directory that may be selected as the workspace root.

It also checks that a same-named `deleted.txt` under an unscoped parent remains
visible. The lower-object preservation checks run after detach. Before final
teardown, the runner restores global scope so the scoped path references are
released when the policy is detached.

The fixed required-oracle manifest includes every scope transition and the
unscoped visibility row. A new run ID is required for the next preflight; the
v1 evidence is not overwritten.

## Validation And Follow-Up

The next steps are:

1. compile both runners and run result-contract tests;
2. commit and push the fix so the KVM manifest has a clean source identity;
3. run a fresh two-boot preflight;
4. launch the 20-boot formal matrix only if both preflight conditions and all
   required oracles pass.
