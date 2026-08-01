# Semantic Continuation Preflight V1 And V2

## Purpose

This record preserves the first two real-launch attempts for the semantic
continuation experiment. Both result roots are immutable. Neither attempt ran a
semantic-continuation case, so neither supports or refutes the RQ1 mechanism
claim.

## V1: Launcher Failure

Result root:

`results/experiments/semantic-continuation-preflight/20260801T130000Z-semantic-preflight-v1`

The KVM command was launched through a PTY. QEMU entered the stopped process
state before the guest command began and the bounded launcher timed out. The
result lifecycle recorded `kvm-launch-or-guest-command`. No guest observation
stream exists and no process remained after cleanup. This was an experiment
launcher failure, not kernel or workload evidence.

## V2: Policy Configuration Failure

Result root:

`results/experiments/semantic-continuation-preflight/20260801T130000Z-semantic-preflight-v2`

The non-PTY launch booted the expected modified kernel, created and mounted the
ext4 and tmpfs fixtures, and completed guest cleanup with clean dmesg status.
The controller emitted:

```json
{"event":"semantic-continuation-setup","step":"prepare-fixture","errno":0,"pass":true}
{"event":"semantic-continuation-setup","step":"configure-policy","errno":5,"pass":false}
{"event":"semantic-continuation-setup","step":"teardown-policy","errno":0,"pass":true}
```

`runner.status` was 1; `boot.json` recorded `inner_status=2`,
`cleanup_status=0`, and `dmesg_status=0`. No S01--S16 operation, case,
engagement, or residual event exists.

## Root Cause

The controller registered targets and then called
`namei_ext_policy_parent_exact()` for the experiment child cgroup before loading
the policy. The kernel accepts an exact-parent command only when the current
cgroup owns its attached namei_ext policy. The controller also planned to attach
the policy at the cgroup-v2 root. Root attachment with inherited execution and
child cgroup map keys is supported, but it would make the root, rather than the
child, the policy owner for exact-parent registration. The shared control helper
reduced the failing child command to `EIO`, which is why the old aggregate event
did not identify the exact operation. Attaching directly to the child is the
chosen fix because it gives the program, targets, exact-parent scope, and map key
one explicit owner and keeps the direct arm outside the attachment.

## Forward Fix

The corrected dependency order is:

1. create the experiment child cgroup and read its ID;
2. register targets A, B, and X in that cgroup;
3. attach the policy directly to that cgroup;
4. register the exact logical parent for the same cgroup;
5. populate the three component-map entries.

Each operation now emits an individual setup event. A successful boot must have
exactly one passing event for every frozen setup step and exactly one matching
teardown step. This directly identifies any future dependency failure before a
new KVM attempt.

## Evidence Boundary

V1 establishes only that PTY KVM launch is unsuitable for this Make workflow.
V2 establishes only that the original control-plane ordering was invalid. The
semantic claim still requires a passing preflight followed by the unchanged
S01--S16 matrix in three fresh boots and an independent raw-result review.
