# Plan Review: RQ1 Sandboxed Application File Sharing

## Scope

One fresh read-only reviewer examined the formal plan, the old experiment and
implementation records, the policy and controller, the old Make suite, the
latest clean preflight result, and the RQ1 evaluation plan.

## Initial Verdict

The initial verdict was `NO-GO` for the implementation state, not for the
scientific admission.

The reviewer accepted that:

- the experiment adds independently recomputable evidence beyond the old
  aggregate preflight;
- the tested existing-object grant/revoke subset is accurately bounded against
  the official XDG Documents portal behavior;
- no matched baseline is necessary for this RQ1 sufficiency experiment;
- one preflight and three formal boots are adequate for deterministic
  correctness replication.

## Blocking Defects

The reviewer identified three execution blockers:

1. the old boolean directory helper could treat `opendir` failure as a hidden
   entry;
2. the child probe returned only aggregate success instead of per-state raw
   syscall, enumeration, byte, and object-identity observations;
3. the old suite lacked the formal three-boot command and did not check cgroup
   removal or preserve the lower payload for host-side comparison.

## Repairs

The formal implementation:

- records `opendir`, complete `readdir`, and `closedir` failures separately
  from the `document_listed` observation;
- sends a raw observation structure from each cgroup-scoped child and emits
  one state record for each of the five planned states;
- records lookup and payload errors, enumeration, unrelated-path bytes,
  registered-lower visibility, and visible-state device/inode identity;
- adds one-boot preflight and three-fresh-boot formal Make entrypoints;
- records detach, target clearing, and both cgroup removals as hard cases;
- records lower-object metadata before and after and saves both the host and
  unrelated payloads for direct host comparison;
- removes the legacy checksum and canonical-result path from this workload.

The same reviewer receives one follow-up review after local build and Make
parsing. No extra workload or baseline is added.

## Follow-Up Verdict

After the repairs and local build, the same reviewer returned `GO`. The
follow-up found no remaining defect that would invalidate the result. It
confirmed that the current runner distinguishes `opendir`, `readdir`, and
`closedir` errors from entry absence; emits the five planned raw state
observations; preserves visible-state lower-object identity; and hard-fails
missing cleanup. It also confirmed the one-boot preflight, three-boot formal
path, per-boot finalizer, external inventory, dmesg check, direct payload
comparison, and absence of a checksum command from the active workload path.

This verdict authorizes the real KVM preflight. It is not evidence that the
workload already passes.
