# Build Action Allowlist Policy Implementation

Date: 2026-07-28

## Motivation

The original Build Action Sandboxing preflight selected one action root and
hid only a fixed `private.txt` component. That was sufficient for the first
two-action correctness oracle, but it could not represent the matched
official-sandboxfs experiment frozen in
`2026-07-29-build-action-rq2-experiment-plan.md`. The RQ2 experiment requires
each action to expose an arbitrary declared-input set while every other child
of the selected root remains absent from lookup and directory enumeration.

This change adds the bounded policy substrate for that experiment. It does not
run or claim the sandboxfs comparison.

## Files Changed

- `bpf/policies/build_action_sandboxing.bpf.c`
  replaces the fixed hidden-component map with an action-root marker map and a
  dedicated declared-input allowlist.
- `runner/include/namei_ext_harness.h` and
  `runner/src/namei_ext_harness.c`
  add exact component-map lookup and occupancy counting for the planned
  capacity gate.
- `experiments/build_action_sandboxing/namei_ext_build_action_sandboxing.c`
  migrates the existing two-action preflight to the allowlist policy and checks
  that both allow and hide branches execute.
- `experiments/build_action_sandboxing/Makefile`
  rebuilds the harness archive when its source or public header changes.

## Policy Layout

`build_action_views` retains the existing exact mapping from an action cgroup
and logical component to a registered lower directory.

`build_action_roots` marks the selected lower directory inode for each action
cgroup. Its component name is empty because the policy uses only cgroup ID,
parent device, and parent inode when determining whether a lookup is directly
under an action root.

`build_action_declared_inputs` contains exact
`(cgroup, parent device, parent inode, component)` entries. Under a marked
action root, an entry in this map returns `PASS`; a missing entry returns
`HIDE`. The same decision function handles lookup and readdir events. Outside a
marked root, the existing registered-target selection and normal pass behavior
remain unchanged.

The allowlist has 8,192 entries. The frozen RQ2 maximum is two actions with
2,048 declared names each, or 4,096 simultaneous entries. The remaining headroom
does not weaken the planned preflight: that preflight must insert, read back,
count, delete, and recount all 4,096 entries before a formal run is admitted.

## Harness Operations

`namei_ext_component_map_lookup` reconstructs the same ABI key used by map
updates and returns the exact stored value.

`namei_ext_component_map_count` walks map keys with
`bpf_map_get_next_key`. It is intended for quiescent setup and teardown gates,
not concurrent runtime telemetry.

All component-map operations verify that the selected BPF map has the expected
component-key and 32-bit value sizes. Passing an existing map with a different
ABI therefore fails instead of returning a misleading lookup or occupancy.

## Alternatives Rejected

- A denylist remains correct only for names known during setup and cannot give
  sandboxfs the same declared-input information budget.
- One policy entry per undeclared file doubles the planned map pressure and
  allows a newly created unknown name to become visible.
- Mapping each declared file to a registered target would consume target
  registry state unnecessarily. Declared files already exist under the
  selected lower directory and should retain normal lower-filesystem lookup.
- A userspace policy file or generated policy language would violate the
  project ABI and orchestration invariants.

## Validation

The following host checks pass:

```text
make bpf
make build-action-sandboxing
git diff --check
```

The build-action binary was rebuilt through the Make dependency graph after
the harness source changed. Changes to the harness source, public header, or
Makefile all invalidate the experiment's harness prerequisite. No
modified-kernel KVM run has been performed for this change yet. Therefore this
checkpoint establishes only buildable policy and runner infrastructure. The
existing dated KVM result remains evidence for the earlier fixed-size preflight,
not for the new 4,096-entry capacity gate or the official sandboxfs comparison.

## Remaining Work

1. Pin and build official sandboxfs 0.2.0 and its generated Cargo lock through
   Make.
2. Implement the capacity gate and matched two-condition lifecycle runner.
3. Run the frozen paired KVM preflight.
4. Only after the preflight passes, run and analyze the complete formal matrix.
