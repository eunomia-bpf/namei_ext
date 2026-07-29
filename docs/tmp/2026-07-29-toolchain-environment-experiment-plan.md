# Experiment Plan: RQ1 Toolchain Environments

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty tested here: Can two process groups concurrently use
  the same executable pathname while `namei_ext` selects different complete
  Python virtual environments, then switch and roll back one group without
  changing the lower environments?
- Why the answer matters: This tests a traditional installed-toolchain view,
  rather than an Agent workspace, sandbox input tree, or staged HPC object.

## Paper-Value Admission

- Planned role: supporting RQ1 breadth.
- Largest credible paper story this experiment could unlock: `namei_ext` can
  select a complete existing software environment at lookup time while the
  source environment manager retains installation and package ownership.
- Strongest reviewer reject argument addressed: Existing positive cases may be
  special-purpose file views and may not preserve a real interpreter's
  environment discovery, imports, ABI identity, and concurrent isolation.
- Independent evidence added: Two distribution CPython installations create
  real `venv` trees; the same pathname executes different interpreter,
  `sys.prefix`, SOABI, stdlib-extension, and package-consistency behavior.
- Why the result is not tautological: Success requires an unmodified CPython
  executable to discover the selected `pyvenv.cfg`, import its runtime
  modules, pass `pip check`, preserve exact lower inode identity, and remain
  isolated during concurrent execution.
- Paper decision if positive: Add one traditional toolchain-environment row to
  the RQ1 sufficiency table.
- Paper decision if contradictory or inconclusive: Keep W7 as motivation and
  bound directory-target selection for executable environment discovery.
- Best alternative experiment: DMTCP and Spindle are closed after three setup
  attempts, and service rotation exhausted its dependency preflight. W7 is the
  strongest remaining runnable and non-overlapping RQ1 case.

## Expected And Alternative Outcomes

- Current expected answer: Selecting an existing `venv` directory for the
  logical component `current` preserves normal CPython environment discovery.
- Strongest competing explanation: CPython may canonicalize the executable or
  environment root in a way that bypasses the selected directory, or target
  replacement may not remain isolated across concurrent cgroups.
- Contradictory result: Direct physical environments pass, but the logical
  path observes the wrong version/prefix/SOABI, crosses cgroup state, bypasses
  lower permissions, or changes lower objects.

## Published Precedent And Real Assets

- Official behavior: Python documents `venv` as a directory tree containing a
  particular Python installation and packages, with `sys.prefix` identifying
  the active environment:
  <https://docs.python.org/3.12/tutorial/venv.html> and
  <https://docs.python.org/3.12/library/sys_path_init.html>.
- Real tools: Ubuntu CPython 3.10.19 and 3.12.3, `venv`, and the `pip check`
  command installed into each environment.
- Reused behavior: `/usr/bin/python3.10 -m venv` and
  `/usr/bin/python3.12 -m venv` create both lower trees.
- Custom glue: One BPF policy, one C controller, and one Python observation
  program. They select and observe existing environments; they do not install
  Python, resolve packages, or implement environment activation.

## Comparison

- Proposed method: A `cgroup/namei_ext` policy maps the same `view/current`
  component to a registered Python 3.10 or 3.12 `venv` directory.
- Main baseline: None for this RQ1 sufficiency experiment. RQ2 owns the matched
  FUSE comparison.
- Positive control: Execute the same observation and `pip check` commands
  through each physical `venv` path before BPF attachment.
- Causal control: Remove one component rule and require the unchanged logical
  executable pathname to fail with `ENOENT`.
- Permission control: Remove execute permission from the selected lower
  interpreter, require logical execution to fail with `EACCES`, then restore
  it.

## Workloads And Metrics

- Workload: Create two real virtual environments; execute the same Python
  observation program and `python -m pip check`.
- Primary metrics: Expected interpreter major/minor version, logical
  `sys.executable`, logical `sys.prefix`, physical target inode identity,
  expected SOABI, successful imports of `ssl`, `sqlite3`, `venv`, and `pip`,
  and zero `pip check` failures.
- Correctness: Physical positive controls, concurrent cgroup A/B isolation,
  A switch from 3.10 to 3.12, rollback to 3.10, withdrawn `ENOENT`, lower
  permission `EACCES`, positive per-cgroup selection counters, and identical
  before/after lower metadata inventories.
- Repetitions: One real KVM preflight, followed by three fresh KVM boots under
  the unchanged plan.
- Cost: Under two minutes per boot.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| physical | positive control | observation + `pip check` | direct `venv` paths | 1 per boot | validates both source environments |
| isolation | proposed | concurrent 3.10 and 3.12 execution | `namei_ext` | 1 pair per boot | tests per-cgroup views |
| transition | proposed | switch and rollback | `namei_ext` | 1 lifecycle per boot | tests runtime state update |
| withdrawn | causal control | unchanged logical executable | no component rule | 1 per boot | attributes success to policy |
| permission | lower-FS control | logical exec of mode-000 target | `namei_ext` | 1 per boot | checks lower permission ownership |

## Execution

- Authoritative workflow:
  `make kvm-toolchain-environment-preflight RUN_ID=<fresh-id>`.
- Real preflight: One modified-kernel boot executes every row above.
- Full completion: Three fresh boots; every physical and logical command passes
  its oracle; both concurrent children overlap; switch and rollback observe
  the expected versions; withdrawn and permission controls fail for the
  expected errno; lower inventories and external BPF/FUSE state are unchanged.
- Raw results:
  `results/experiments/toolchain-environment[-preflight]/<RUN_ID>/`.
- Recovery: Failed roots are preserved and never counted as completed boots.

## Interpretation

- Positive: `namei_ext` expresses this existing-environment selection and
  update lifecycle without owning Python installation, package state, or file
  operations.
- Negative: Bound the mechanism to workloads that do not require this form of
  interpreter environment discovery or concurrent directory-target switch.
- Mixed: Treat any failed environment, transition, isolation, or lower-FS
  control as inconclusive for W7.
- Target paper artifact: One RQ1 case-study row, not a standalone performance
  figure.

## Reproducibility Notes

- Software: Ubuntu packages `python3.10` 3.10.19-1+noble1 and `python3.12`
  3.12.3-1ubuntu0.15.
- No random seed is used.
- No downloaded package, synthetic dependency version, FUSE baseline, or
  materialized-view comparison is part of this RQ1 experiment.
