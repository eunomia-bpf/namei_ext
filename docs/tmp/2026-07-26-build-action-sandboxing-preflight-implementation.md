# Build Action Sandboxing Preflight Implementation

Date: 2026-07-26

## Motivation

The W3 evaluation row previously named Bazel and sandboxfs but had no real
Bazel action on the modified-kernel path. The old `build_graph_view.bpf.c`
component aliases and synthetic W1 oracle cannot establish per-action
declared-input isolation. This implementation adds a dedicated source-derived
preflight instead of reinterpreting those older artifacts.

## Files

- `configs/benchmarks/workload-sources.mk`
  pins Bazel 8.7.0 and its official release SHA-256.
- `mk/workload.mk`
  downloads, verifies, and installs the Bazel binary through Make.
- `bpf/policies/build_action_sandboxing.bpf.c`
  implements two exact bounded decisions:
  per-action selection of a registered existing directory and per-action
  hiding of an undeclared component.
- `tests/build_action_sandboxing/Makefile`
  builds the userspace runner against the repository's static libbpf.
- `tests/build_action_sandboxing/namei_ext_build_action_sandboxing.c`
  builds the fixture, creates action cgroups, configures maps and target
  registries, starts two real Bazel genrules, checks the oracle, and preserves
  raw logs and outputs.
- `Makefile` and `mk/kvm.mk`
  expose the build and canonical KVM preflight targets.

## Policy Boundary

`build_action_views` maps an exact
`(cgroup, parent device, parent inode, component)` key to a registered target
ID. `build_action_hidden_inputs` uses the same exact key shape to hide an
undeclared component in the selected lower directory. Both lookup and readdir
events use the one `cgroup/namei_ext` decision program.

The policy does not parse BUILD files, enumerate dependency graphs, transfer
objects, create Bazel outputs, or mediate reads and writes. Bazel remains the
action orchestrator; the lower filesystem owns all existing input objects and
the data path.

## Concurrency Control

Each generated genrule writes a distinct ready marker and waits for a shared
release marker. The runner releases the actions only after both ready markers
exist. This makes concurrent action isolation an observed precondition rather
than an inference from two quickly launched Bazel processes.

## Failure Handling

The runner and Make target fail on:

- target-registration or cgroup failures;
- BPF open, load, attach, map-update, or detach failures;
- Bazel startup/action failure;
- failure of the concurrency barrier;
- wrong or missing output;
- visible undeclared input by lookup or readdir;
- missing policy counters;
- changed lower objects;
- cleanup failure;
- malformed or false JSON records;
- guest kernel failure signatures.

## Validation Status

The policy and runner pass host compilation. The canonical terminal KVM run is:

```text
results/experiments/build-action-sandboxing/20260726T-build-action-sandboxing-preflight-v3/
```

It contains 23 JSONL records with zero false records. The policy counters are
57,737 lookup events, 8,082 readdir events, 4 target selections, 2 lookup
hides, and 2 readdir hides. Both Bazel actions overlapped, exited successfully,
and produced their distinct expected 17-byte outputs. Lower declared and
undeclared inputs remained unchanged. The Make target verified output hashes
and found no declared dmesg failure signature.

The two preceding terminal failures were retained. V1 showed that Bazel 8.7
tries to download external `rules_cc` in the offline guest. V2 reached both
actions and exercised all expected policy decisions, but exposed a runner bug:
the generated command used Bazel's relative output path after changing
directory. The runner now records the absolute execroot output path before
entering the logical action directory.

This closes the W3 RQ1 preflight only. It does not close the matched
symlink-forest/FUSE cost comparison, process-sandbox coverage, or standard VFS
fast-path evaluation.
