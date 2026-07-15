# Implementation Record: Phase 1 Make Routing Cleanup

Date: 2026-07-13

## Motivation

The current paper story uses complete integrated experiments:

- AgentFS-derived workspace lifecycle;
- environment/cache transition;
- conditional service/config transition.

The old `make phase1` target still ran W1-W4/table/C8 diagnostic targets and
the old release report. That contradicted the current documentation and made
the executable entrypoint look like the project was still pursuing scattered
diagnostic rows.

## Change

This implementation step keeps historical targets available but removes them
from the default Phase 1 path:

- `phase1` now runs current prototype validation only:
  `phase1-smoke`, `kvm-policy-load`, and `kvm-functional`;
- `phase1-smoke` no longer depends on `table-conformance` or `w1-oracle`;
- default `POLICY_LOAD_OBJECTS` now lists the current validation policies
  explicitly (`hide_secret`, `pass_only`, `redirect_alias`, and
  `select_portal`) instead of globbing every BPF object, which pulled
  `table_redirect` into the current validation path;
- the old W1-W4/table/policy-family/report chain is preserved as
  `phase1-legacy-diagnostics`, including the host-side `table-conformance` and
  `w1-oracle` prerequisites that the archived report path expects;
- `make help` lists the current validation path and marks the legacy diagnostic
  flow as archived, instead of advertising every old W1-W4/table/C8 target as
  the active evaluation.

## Boundary

This does not implement the complete Agent workspace or environment/cache
experiments. It only aligns the default project-owned control plane with the
current research direction so `make phase1` is no longer misleading.

The legacy targets remain callable for provenance and debugging, but they are
not the paper's current experiment route.

## Validation Plan

The owning checks are:

```text
make help
make -qp
make phase1
```

`make phase1` must boot the modified kernel in KVM for smoke, policy load, and
functional validation. It must not run W1-W4/table diagnostic targets unless
`phase1-legacy-diagnostics` is explicitly requested.

## Validation Performed

Completed on 2026-07-13:

```text
make help
make -qp
make phase1
```

`make -qp` shows the current default route as:

```text
phase1: phase1-smoke kvm-policy-load kvm-functional
phase1-smoke: check-prereqs abi bpf functional bench policy-load policy-semantic kernel-objects kvm-smoke
phase1-legacy-diagnostics: phase1-smoke table-conformance w1-oracle kvm-policy-load kvm-policy-semantic ...
```

`make phase1` passed and wrote raw artifacts under
`results/phase1/20260713T022917Z-d2fd7174/`. After adding the Agent workspace
preflight target, `make phase1` was rerun and passed again under
`results/phase1/20260713T024221Z-8d9cb9a5/`, confirming the new experiment
target did not change the default Phase 1 route.

Observed result summary:

- ABI: 3 JSONL rows, all pass;
- KVM smoke: start/done rows present;
- KVM policy load: `hide_secret`, `pass_only`, `redirect_alias`, and
  `select_portal` loaded, attached, and detached successfully;
- KVM functional: 46 JSONL rows, including `HIDE`, intermediate
  `SELECT_TARGET`, same-parent `REDIRECT`, attach-rejection, and detach cases;
  all pass;
- no failed JSONL rows were found;
- dmesg scan found no `BUG:`, `WARNING:`, `Oops:`, `Call Trace:`, hung task,
  general-protection fault, NULL-pointer, KASAN, or UBSAN signal. The only
  broad "failed" grep hits were the expected virtme/cfg80211 regulatory
  database messages, unrelated to `namei_ext`.
