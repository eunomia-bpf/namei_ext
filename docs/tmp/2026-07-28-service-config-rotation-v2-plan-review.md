# Service Configuration Rotation V2 Plan Review

## Review Scope

This review covers
`2026-07-28-service-config-rotation-preflight-recovery-plan.md`. It evaluates
whether a new preflight is methodologically admissible after the original
protocol's three dependency failures and whether the proposed nginx runtime
boundary preserves the experiment's hypothesis and evidence.

## Round 1

Verdict: blocked.

Two issues had to be resolved before implementation:

1. The plan described the next run as a recovery attempt without closing the
   original three-attempt protocol. Reusing that protocol would reset its
   attempt budget after the declared stopping rule.
2. The plan did not freeze cleanup order or require the copied nginx error log
   and guest-local runtime removal as correctness-gated observations.

## Revision

The plan now defines a separately admitted V2 protocol. The original protocol
remains closed with no hypothesis evidence. V2 preserves the hypothesis,
workload states, oracle, targets, timeouts, repetitions, and interpretation;
only the guest/runtime filesystem boundary changes.

The cleanup sequence is fixed: stop and reap nginx, copy and verify a non-empty
error log, remove the guest-local runtime tree, then detach policy state, clear
targets, and remove the cgroup. Copy, verification, and removal are mandatory
structured cases and Make-level result gates.

## Round 2

Verdict: go.

The proposed boundary is technically valid for this harness. The KVM path
provides guest-local writable `/tmp`, while the result tree remains a shared
host path for immutable inputs and captured evidence. Moving nginx's pid,
error log, and prefix to `/tmp` removes the UID-changing operation that caused
all three original dependency failures. Keeping the four configuration
generations, content roots, observations, and copied log in the result tree
preserves the state-transition and lower-object oracles.

V2 may proceed to implementation and one fresh-boot dependency preflight. It
does not authorize a formal claim until the later ten-boot protocol passes.
