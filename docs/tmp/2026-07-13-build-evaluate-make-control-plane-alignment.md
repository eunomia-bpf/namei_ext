# Implementation Record: BUILD_AND_EVALUATE Make Control-Plane Alignment

Date: 2026-07-13

## Motivation

BOOTSTRAP cycle 0 froze the paper around integrated same-oracle experiments:

- Agent workspace lifecycle;
- environment/cache transition;
- conditional service/config transition only with a lookup-time source oracle.

The top-level Makefile still loaded legacy `eval-osdi`, W1-W4, workload, and
table-budget machinery as ordinary control-plane state. Even when the default
`phase1` target no longer ran those diagnostics, the top-level `.PHONY` list,
unconditional includes, and help structure made the executable workflow look
like the paper still centered scattered W1-W4/table experiments.

## Change

This implementation step keeps historical targets available but separates them
from the current experiment path:

- added current lifecycle targets:
  - `experiments`;
  - `experiment-agent-workspace`;
  - `experiment-env-cache`;
- made those final experiment targets fail visibly until their integrated
  matrices are implemented;
- kept `kvm-agent-workspace-preflight` as the implemented Agent workspace
  dependency preflight;
- made legacy `eval-osdi`, `table_budget`, `report`, and workload helper
  includes conditional on legacy use;
- simplified top-level `.PHONY` declarations so old W1-W4/table/eval-osdi
  targets are not advertised as the current paper control plane;
- rewrote `make help` into current validation, current experiment lifecycle,
  build/component checks, archived legacy diagnostics, and cleanup sections;
- changed top-level `clean` to remove legacy workload build/cache roots
  directly instead of depending on the legacy workload Make include.

## Boundary

This does not implement the final Agent workspace or environment/cache
matrices. It is a dependency repair before final experiment execution.

The old diagnostic targets are preserved for provenance and debugging. They are
not paper-result targets and should not be used to answer the frozen RQs.

## Validation Performed

Current help:

```sh
make help
```

Result: passed. Help now shows current validation and experiment lifecycle
first, and lists W1-W4/table diagnostics only under archived legacy diagnostics.

Current final matrix dry-runs:

```sh
make -n experiments
make -n experiment-agent-workspace
make -n experiment-env-cache
```

Result: passed. The dry-runs show fail-fast recipes that describe missing
complete matrices and required cells.

Current final matrix actual fail-fast:

```sh
make experiment-agent-workspace
```

Result: failed as intended with:

- full Agent workspace lifecycle matrix is not implemented yet;
- required cells are `namei_ext` KVM, feature-equivalent FUSE, lower-FS checks,
  boundary evidence, and raw result review;
- current dependency preflight is `make kvm-agent-workspace-preflight`.

Implemented dependency preflight dry-run:

```sh
make -n kvm-agent-workspace-preflight
```

Result: passed. The dry-run uses the Make-owned KVM target and records raw
outputs under `results/experiments/agent-workspace/$(RUN_ID)/`.

Legacy include isolation:

```sh
make -pn help
make -pn ENABLE_LEGACY_DIAGNOSTICS=1 help
```

Result: without legacy enabled, `eval-osdi` and workload recipes are not loaded
for `help`; with `ENABLE_LEGACY_DIAGNOSTICS=1`, legacy recipes such as
`workloads`, `table-budget`, and `eval-osdi-smoke` are loaded.

## Validation Caveat

`make -n phase1-legacy-diagnostics` is not a safe parse-only check because GNU
Make executes recursive `$(MAKE)` recipe lines even under `-n`. A dry-run
attempt reached a recursive workload target and failed on an absent generated
directory. That failure is preserved as a validation-method caveat, not as a
current-control-plane failure.

## Remaining Work

The next implementation step should build the actual
`experiment-agent-workspace` matrix target instead of leaving it as fail-fast:

- source-derived AgentFS lifecycle oracle;
- `namei_ext` KVM cell through real `cgroup/namei_ext` attach;
- feature-equivalent FUSE cell under the same oracle;
- lower-FS permission/write/data-path preservation checks;
- boundary evidence for custom/stackable filesystem ownership;
- raw result directory and result-review report.

