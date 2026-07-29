# RQ3 Agent Workspace Boundary Plan Review

## Round 1

The independent reviewer returned `NO-GO` on the first plan. The blocking
findings were:

1. YoloFS implements staging, copy-on-write, snapshots, journaling,
   permissions, and commit/abort, so its complete operation-table surface is
   not a feature-equivalent baseline for the narrow Agent pathname-view slice.
2. The plan counted only the BPF policy and omitted the shared privileged
   `namei_ext` mechanism: target registration, cgroup scope state, path
   references, validation, RCU lifetime, and debugfs controls.
3. The proposed fault matrix omitted malformed redirect fields, unsupported
   action/event combinations, create/final-open behavior, and exact verifier
   evidence.
4. Lower manifests alone did not show that ordinary operations on an already
   open file bypass policy code.
5. Experiment completion was incorrectly defined as obtaining the expected
   positive outcome.
6. Callback counts, source lines, and BPF instructions were treated as if they
   were comparable safety metrics.
7. The matched FUSE implementation is useful supporting evidence but cannot
   substitute for the paper's custom/stackable-FS RQ3 baseline.

The revised plan responds by using the latest official Wrapfs branch (Linux
5.18) passthrough
template as a matched minimal stackable baseline; demoting YoloFS to an
unmatched real-system exemplar; separating shared mechanisms from
workload-specific code; making a categorical responsibility matrix primary;
adding full verifier, action, field, event, lifetime, and data-path cases; and
defining execution completeness independently from hypothesis support. A
compile feasibility probe also corrected the target-kernel description: the
current prototype is Linux 7.1-rc7, and the plan now explicitly includes the
observed 5.18-to-7.1 VFS API port rather than assuming 6.8 compatibility.

Round 2 will review the revised plan before implementation or KVM execution.

## Round 2

The reviewer accepted the matched Wrapfs baseline, the mount-lifecycle versus
cgroup-control-plane treatment, the ordinary data-path attribution, and
outcome-independent completion. Two blockers remained:

1. The verifier errno oracle contradicted the implementation. A write to the
   read-only context propagates `EACCES`, while an out-of-range return value
   propagates `EINVAL`. The plan incorrectly expected `EPERM` for both.
2. Target ID zero was already source-proven to differ by walk mode:
   `namei_ext_get_target()` returns `EINVAL` in ref-walk, while the RCU path
   reaches a missing-target `ENOENT`. A formal oracle cannot accept this
   inconsistency silently.
3. Separating a reusable Wrapfs template from the added policy was not enough;
   the primary table must also count the complete ported and loaded module as
   the baseline's deployed privileged mechanism.

The plan now uses the implementation's exact verifier errno, separates zero ID
from an unregistered nonzero target, and declares a preflight prerequisite that
rejects zero before the RCU/ref-walk split. It also requires two simultaneous
accounting views: reusable mechanism versus workload-specific delta, and the
complete deployed mechanism/runtime union for each system.

Round 3 is the final permitted plan review.

## Round 3

The final reviewer found no remaining scientific or executability blocker.
The Wrapfs port remains a preflight engineering risk, but its source and
required API work are fixed and a failed port cannot be interpreted as an RQ3
result. Baseline fairness, exact fault oracles, complete deployed-union
accounting, ordinary data-path attribution, and outcome-independent completion
were accepted.

Final verdict: `PLAN GO`.
