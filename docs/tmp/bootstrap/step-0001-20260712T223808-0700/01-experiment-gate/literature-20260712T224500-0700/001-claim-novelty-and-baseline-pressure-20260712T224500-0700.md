# Literature/Novelty Node: Claim, Baseline, And Experiment Pressure

Timestamp: 2026-07-12T22:45:00-07:00
Phase: BOOTSTRAP
Step: 0001
Gate: 01-experiment-gate
Status: complete pending independent gate audit
Parent:
`docs/tmp/bootstrap/step-0001-20260712T223808-0700/01-experiment-gate/000-gate-entry-20260712T223808-0700.md`

## Question And Entry

This node asks whether the current candidate story remains defensible for an
OSDI/SOSP-style systems paper after returning to BOOTSTRAP:

- Is there same-claim prior work?
- Are the current RQs the right paper-level questions?
- Which baselines are mandatory, and which should be citation/background only?
- Does the evaluation promise still avoid scattered weak experiments?

The node follows `research-literature-novelty`: start from claims, search
multiple source families, verify with primary sources, and preserve the larger
claim unless evidence shows it is impossible.

## Candidate Claims

Plain claims without project naming:

1. A kernel extension point at VFS name resolution can let verified policy
   choose pathname-to-existing-object and visibility actions while the kernel
   and lower filesystem keep file data, VFS object, permission, write, page
   cache, persistence, and consistency semantics.
2. Real agent/workspace and environment/cache systems provide source oracles
   where path-view selection is a load-bearing subproblem.
3. For policies that are only name-resolution selection, a verified policy hook
   can be a narrower implementation and safety boundary than FUSE/custom or
   stackable filesystem ownership.

## Search Method

Primary-source families checked:

- Linux kernel docs: `sched_ext`, BPF LSM, FUSE, FUSE passthrough, OverlayFS.
- OS/filesystem papers and official pages: ExtFUSE, FAST 2017 FUSE study,
  Bento, Wrapfs, DeltaFS, IndexFS, TableFS.
- Agent/workspace systems: AgentFS, BranchFS, YoloFS, Sandlock, Mirage,
  OpenHands, SWE-agent/SWE-ReX, SWE-MiniSandbox, AgentCgroup.
- Environment/cache systems: SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench
  V2, DockSmith, Multi-Docker-Eval.
- Service/config and materialization context: Kubernetes projected volumes,
  ConfigMaps, Secrets, mount namespaces, OverlayFS.

Representative current web queries included:

- `Linux kernel documentation sched_ext eBPF scheduler class official docs`
- `Linux kernel documentation BPF LSM official docs`
- `Linux kernel documentation FUSE filesystem official docs`
- `ExtFUSE USENIX ATC 2019 eBPF FUSE paper`
- `Bento safe in-kernel file systems FAST 2021 official`
- `Wrapfs stackable filesystem templates USENIX 1999 paper`
- `AgentFS Turso GitHub FUSE copy on write workspace`
- `YoloFS filesystem GitHub paper agent filesystem`
- `SWE-Factory Gym benchmark GitHub environment construction SWE agents`
- `MEnvAgent MEnvData-SWE GitHub Hugging Face benchmark environment construction`
- `Kubernetes projected volumes ConfigMap Secret service account token official documentation`

The node also used the local PDFs under `docs/reference/` and the source
catalog `docs/reference/CODE_SOURCES.md`.

## Results

Same-claim risk is medium, not fatal. The closest neighboring mechanisms are
very relevant but not the same claim:

- `sched_ext` supports the "BPF policy inside kernel-owned subsystem" analogy,
  but it is a scheduler interface, not a filesystem path-view interface.
- BPF LSM and fanotify mediate security or permission events; they do not define
  a bounded object-selection action at VFS name resolution.
- FUSE, FUSE passthrough, and ExtFUSE are the closest programmable filesystem
  family. They remain the required RQ2 comparison because they can implement
  equivalent policy but at a filesystem/request-path boundary.
- Bento, Wrapfs, YoloFS, BranchFS, DeltaFS, IndexFS, and TableFS are strong
  RQ3 boundary pressure. They own filesystem or metadata-service interfaces,
  so they should be compared through ownership and containment evidence rather
  than all reimplemented as main baselines.
- AgentFS, BranchFS, YoloFS, Sandlock, Mirage, OpenHands, SWE-agent/SWE-ReX,
  Terminal-Bench, SWE-MiniSandbox, and AgentCgroup strongly support the
  workload setting, but they are source systems and oracle providers rather
  than proof that `namei_ext` is necessary.
- SWE-Factory, MEnvAgent/MEnvData-SWE, SWE-rebench V2, DockSmith, and
  Multi-Docker-Eval strongly support the environment/cache setting. The best
  experiment source should come from executable released rows and fixed
  build/test oracles; DockSmith is mainly methodology/trajectory evidence
  unless a concrete official evaluator path is selected.
- Kubernetes projected volumes, ConfigMaps, Secrets, OverlayFS, and mount
  namespaces support materialized/context comparisons. They should not drive
  the central RQ unless a selected source oracle makes them direct opponents.

## Baseline And Experiment Implications

Mandatory mainline comparisons:

- RQ2: feature-equivalent FUSE under the same oracle. This is not optional.
- RQ1: source/native oracle behavior to establish task correctness and input
  provenance.
- RQ3: custom/stackable filesystem boundary evidence after the source oracle
  passes. This evidence should account for methods owned, daemon/state surface,
  verifier or language safety, invalid-policy containment, and lower-FS data
  and write responsibility.
- Controls: no-hook/lower-FS controls only for overhead attribution.

Comparisons not admitted as mainline by default:

- table-only/static-table diagnostics;
- separate copy/symlink/bind/Overlay/projected-volume shootouts;
- DeltaFS/IndexFS/TableFS full-system reproductions;
- source-system inventory as final RQ evidence;
- many small FUSE/native/proxy rows that cannot change an RQ answer.

Candidate complete experiments:

1. Agent workspace lifecycle: source-derived AgentFS first, with BranchFS,
   YoloFS, Sandlock, Mirage, OpenHands, and SWE-agent/SWE-ReX as supporting
   context and boundary evidence. The matrix must include `namei_ext` in KVM,
   feature-equivalent FUSE, lower-FS semantic checks, operation-weighted
   lookup/readdir traces, no-hook controls where meaningful, and RQ3 boundary
   accounting.
2. Environment/cache transition: source-derived SWE-Factory, MEnvData-SWE, or
   SWE-rebench V2 suite. The matrix must include hit/miss plus stale/corrupt or
   update-state transitions, source build/test oracle, `namei_ext` KVM,
   feature-equivalent FUSE, controls, and boundary accounting.
3. Service/config: conditional only. Admit it only if a concrete source oracle
   depends on lookup-time object selection rather than projected-volume update
   mechanics or application reload behavior.

## Scientific Impact And Decision

The candidate story is strong enough to keep in BOOTSTRAP:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The story should not shrink to "tables fail", "dynamic policy exists", or "the
current prototype passes". The stronger OSDI/SOSP shape is a systems-boundary
claim plus two deep same-oracle experiment families.

However, the paper should not exit BOOTSTRAP yet. It still needs WRITE and
REVIEW gates to check that the paper expresses this current evidence program,
does not overclaim the prototype matrix, and has placeholders only where final
numbers are missing.

## State Updates

Updated `docs/background-related-work.md` into the skill template:

- Search Log
- PDF Corpus
- Claim-Oriented Novelty Map
- Closest Work
- Mandatory Baselines
- Experimental Precedents And External Assets
- Baseline Candidates
- Absorbable Ideas
- Adjacent Communities
- Venue Evaluation Patterns
- Novelty Verdict

No paper source, design, implementation, or user-instruction file was edited by
this node.

## Completion And Next Action

This literature/novelty node is complete. Next action for the gate is an
independent outer audit of whether this node followed the BOOTSTRAP user
instructions and did not shrink the claim or mistake prototype artifacts for
final evidence.
