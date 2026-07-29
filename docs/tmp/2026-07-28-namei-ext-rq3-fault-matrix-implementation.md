# RQ3 Fault Matrix Implementation Record

## Motivation

RQ3 claims a verifier-bounded and fail-closed policy boundary. The existing
normal Agent workspace run establishes valid behavior but does not test
malformed programs, malformed accepted decisions, unsupported operation
contexts, or teardown. This implementation adds executable KVM fixtures for
those boundaries.

This record covers implementation and preflight evidence. It does not replace
the planned three-boot formal RQ3 matrix.

## Implemented Assets

- `bpf/policies/rq3_invalid_ctx_write.bpf.c`
  attempts to write the read-only BPF context.
- `bpf/policies/rq3_invalid_action.bpf.c`
  returns action `4`, outside the declared `[0, 3]` range.
- `bpf/policies/rq3_fault_injection.bpf.c`
  is one loadable decision function controlled by a one-element BPF array map.
- `experiments/agent_workspace_rq3/namei_ext_rq3_faults.c`
  loads fixtures, preserves verifier logs, attaches through
  `cgroup/namei_ext`, triggers runtime faults, and records raw JSONL.
- `mk/experiments/agent_workspace_rq3.mk`
  owns the build and KVM entrypoint.

The runtime fixture includes malformed redirect lengths, `.`, `..`, slash and
embedded-NUL components, target ID zero, an unregistered nonzero target,
`SELECT_TARGET` during readdir, redirect and select during create, and select
for a final regular-file open.

## Design Choices

1. Invalid-load programs are separate BPF objects so each verifier outcome and
   log is unambiguous.
2. Runtime faults use one valid BPF source and an array-map mode, but every
   fault cell independently loads, attaches, registers its target, detaches,
   clears targets, and closes the object. This keeps the kernel-facing ABI to
   one decision function while isolating lifecycle failures.
3. Every operation asserts an exact errno. Merely observing a failure does not
   satisfy the oracle.
4. Redirect validation is exercised independently through lookup and directory
   iteration.
5. Full verifier logs are written as raw artifacts. JSONL records only the
   observation and expected relation.
6. Every runtime fault records eight lower objects before and after the fault:
   `statx` identity and metadata, SHA-256 for regular files, the symlink target,
   and explicit absence for all possible create destinations. It also records
   sorted complete directory-entry manifests for the fixture root and nested
   readdir directory.
7. The runner enters a dedicated child cgroup. It detaches and clears every
   cell, leaves and removes the child cgroup, and verifies ordinary lower-file
   access afterward.

## Validation

Host build checks:

```text
make bpf
make /home/yunwei37/workspace/namei_ext/.build/agent-workspace-rq3/namei_ext_rq3_faults
```

Modified-kernel KVM preflight:

```text
make kvm-agent-workspace-rq3-faults \
  RUN_ID=20260728-rq3-faults-preflight2
```

Raw results:

```text
results/experiments/agent-workspace-rq3-faults/
  20260728-rq3-faults-preflight2/
```

Preserved artifacts include:

- `observations.jsonl`;
- `invalid-ctx-verifier.log`;
- `invalid-action-verifier.log`;
- `kernel.config`;
- `uname.txt`;
- `dmesg.log`.

All declared preflight cells passed:

| Boundary | Observed errno |
| --- | ---: |
| verifier rejects context write | `EACCES` (13) |
| verifier rejects action 4 | `EINVAL` (22) |
| redirect length 0 or 65, lookup and readdir | `EINVAL` (22) |
| redirect `.`, `..`, slash, or embedded NUL, lookup and readdir | `EINVAL` (22) |
| target ID 0 | `EINVAL` (22) |
| unregistered target ID | `ENOENT` (2) |
| select during readdir | `EOPNOTSUPP` (95) |
| redirect or select during create | `EOPNOTSUPP` (95) |
| select for final regular-file open | `EOPNOTSUPP` (95) |

The context-write log contains the expected invalid BPF-context access
diagnostic at `off=0 size=4`. The action log identifies `R0=4` outside
`[0, 3]`.

The integrated preflight
`results/experiments/agent-workspace-rq3/20260728-rq3-full-preflight7/`
supersedes the earlier fault-only preflight for the complete protocol. It
passed 19 runtime fault oracles, 19 before/after containment checks over eight
objects each, 18 independent policy lifecycles (the cold and warm target-zero
checks intentionally share one lifecycle), child-cgroup removal, exact
verifier evidence, post-teardown lower access, and the dmesg scan.

## Kernel Repair Covered

Before the preflight, `namei_ext_resolve_target()` rejected target ID zero
after selecting the RCU/ref-walk path. That allowed the two walk modes to
return different errors. Kernel commit
`1e81d4793c78b7667d0798248c70c0b15a2c3877` moves the zero-ID check before
the walk-mode branch. The KVM runtime cell now observes `EINVAL`.

## Remaining Risks And Follow-Up

- Freeze the implementation in a clean project commit and run three
  independent formal KVM boots from that exact commit.
- Generate the responsibility table only after the analyzer verifies source
  and binary hashes, project/kernel provenance, all pairwise workload rows,
  every containment manifest, and exact Wrapfs symbol attribution.
