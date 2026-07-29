# Agent Workspace RQ3 Oracle and Accounting Repair

## Motivation

The first independent implementation audit rejected the RQ3 preflight for two
reasons. The two mechanisms passed related tests, but the analyzer did not
prove feature-equivalent operations and outcomes. The source accounting also
omitted deployed sources and inferred operation ownership with a regex that was
not restricted to registered VFS tables.

This repair changes the experiment evidence rather than weakening RQ3.

## Semantic Oracle Repair

- Added `experiments/agent_workspace_rq3/semantic_oracles.h` as the one shared
  contract for 37 AgentFS-derived semantic checks.
- Both the `namei_ext` and Wrapfs-derived runners emit one
  `rq3-semantic-oracle` row per contract with the same oracle ID, operation, and
  expected application-visible outcome.
- The analyzer requires exactly 37 unique rows per mechanism, equal contract
  fields, the planned case-name mapping, and a passing observed predicate.
- The two directory implementations now require the same `main.txt`,
  `link.txt`, `src`, and `.git` entries and the same hidden/generated/cached
  entry states.
- Both cached-negative create paths now use
  `O_CREAT|O_EXCL|O_WRONLY|O_CLOEXEC`.
- Both mechanisms emit the same 19-field lower/visible-tree manifest, and the
  analyzer compares every field exactly.

The `namei_ext` runner records the four policy-visible fields while the policy
is attached. It records the fifteen direct lower-tree fields only after
detaching the policy and removing its child cgroup. This ordering avoids
mistaking an intentionally hidden lower pathname for a mutated lower object.

## Deployed Source Accounting Repair

- The analyzer parses `thirdparty/wrapfs/Makefile` and records all six sources
  compiled into `wrapfs.ko`.
- Registered operation slots are extracted only from explicit VFS operation
  table definitions. The current module exposes 34 unique slots.
- The `namei_ext` shared mechanism inventory covers all nine modified kernel
  integration files in name lookup, readdir, cgroup BPF, verifier, internal
  headers, and UAPI.
- The analyzer parses `kernel/fs/fuse/Makefile` against the captured guest
  kernel configuration. The current configuration selects 15 FUSE client
  sources and 83 unique registered VFS slots.
- The feature-equivalent userspace FUSE comparator records 12 callbacks.
- The input hash manifest includes the shared semantic contract, both runner
  Makefiles, every `namei_ext` integration file, FUSE sources, Wrapfs sources,
  policies, analyzer, and source trace.

These counts are descriptive ownership evidence. They are not LOC, safety, or
performance scores.

## Validation

- `make agent-workspace-rq3-analysis-test`: eight tests passed, including
  contract mismatch and 19-field manifest mismatch rejection.
- `make kvm-agent-workspace-rq3-preflight
  RUN_ID=20260728-rq3-full-preflight14`: passed on the modified kernel.
- Preflight 14 contains 37/37 paired semantic checks, 19 runtime fault cells
  with eight object and two directory manifests each, 18 independent policy
  lifecycles, all 13 declared Wrapfs kprobes, zero `pass=false` observations,
  and a clean dmesg gate.
- `make kvm-agent-workspace-preflight
  RUN_ID=20260728-agent-workspace-regression-rq3-contract`: passed for the
  existing `namei_ext` and FUSE Agent paths.
- The independent re-review returned GO with no blocking findings and stated
  that both original blockers were resolved.

## Failed Development Attempts

- Preflights 10 and 11 exposed that attached policy scope hid direct
  `deleted.txt` lower-path checks.
- Preflights 12 and 13 completed the workload but failed strict harness gates:
  the first used an incorrect slurped-jq expression; the second emitted the
  final Wrapfs semantic row twice.
- These roots are development evidence only. Preflight 14 is the passing
  pre-commit validation root.

## Remaining Work

Formal evidence must be generated from a clean project commit. The authoritative
next step is three independent boots through
`make experiment-agent-workspace-rq3 RUN_ID=<fresh-id>`, followed by generated
analysis and a result review.
