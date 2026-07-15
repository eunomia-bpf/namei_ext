# Evaluation Plan

Last updated: 2026-07-15
Orchestrator phase: BUILD_AND_EVALUATE after BOOTSTRAP step
`docs/tmp/bootstrap/step-0005-20260714T174151-0700/` completed full writing,
citation, meaning-preservation, build checks, and independent outer audit.
Historical KVM runs remain motivation, feasibility, or prototype evidence.
Final RQ evidence still requires BUILD_AND_EVALUATE admission, full execution,
and result review.

The frozen evaluation follows the current idea: `namei_ext` is a `sched_ext`-style
VFS policy boundary for state-dependent path views, positioned in the sequence
bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom
filesystems. The paper does not try to prove that namespace construction
mechanisms are impossible. It asks whether a name-resolution policy boundary is
expressive enough, lower overhead than feature-equivalent FUSE for policy on
the lookup path, and a narrower verifier-bounded, fail-closed ownership
boundary than custom or stackable filesystem implementation for policies that
only need name resolution.

ExtFUSE, FUSE-BPF, FUSE passthrough, and related FUSE acceleration work are
closest mechanism pressure for RQ2 and related work, not automatic new main
baselines. They force the FUSE comparison to be fair and feature-equivalent.
Materialized namespace mechanisms and table redirects remain background unless
a final admitted source oracle makes one directly load-bearing.

## Research Questions

| RQ | Question | Evidence |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Representative source-derived workloads run through the real `cgroup/namei_ext` KVM attach path, pass the source oracle, preserve lookup/readdir coherence, and preserve lower-filesystem permission/write/data-path behavior. |
| RQ2 Cost / overhead versus FUSE | What is the cost of putting programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy implementation? | Feature-equivalent FUSE policy and `namei_ext` policy over the same oracle; lookup/open/stat/access/exec/readdir latency, macro workload runtime, pass-through and action-specific overhead, and operation-weighted policy invocation traces. |
| RQ3 Safety / boundary versus custom or stackable FS | Does `namei_ext` provide a narrower verifier-bounded, fail-closed ownership boundary than building a custom or stackable filesystem when the needed policy is only name resolution? | Ownership and safety-boundary comparison: required filesystem methods, privileged code surface, verifier/kernel validation constraints, invalid-policy containment, and evidence that selected workloads need name-resolution policy rather than broader filesystem ownership. |

Source-system characterization motivates RQ1 workload selection and scope; RQ1
evidence comes from representative KVM workloads passing the source oracle
through the real attach path.
Materialized namespace mechanisms such as bind mounts, OverlayFS, projected
volumes, copies, and symlinks are related-work and background comparisons, not
the central RQ3 opponent.
RQ3 is a boundary and containment claim, not a requirement to reimplement every
custom or stackable filesystem. Its evidence is interpreted only after the
same-oracle RQ1/RQ2 runs establish that the selected behavior is genuinely
name-resolution policy; then RQ3 accounts for what broader filesystem
mechanisms would have to own for that same policy.

## RQ3 Boundary Audit Schema

RQ3 is admitted only with workload-specific comparators and an explicit evidence
table. The comparison is not "custom filesystems are bad"; it is whether the
same oracle-relevant behavior requires a broader owner than a name-resolution
policy.

For every admitted workload, the RQ3 table must record:

- source behavior and oracle;
- `namei_ext` actions used for the same behavior;
- concrete FUSE/custom/stackable/source-system comparators;
- filesystem methods the comparator owns or must intercept;
- daemon, runtime, metadata, and cache state the comparator owns;
- data-path, write-path, and persistence responsibilities;
- privileged code surface and failure surface;
- verifier/kernel validation and invalid-policy containment;
- evidence source: runnable artifact, source code, local PDF, or explanatory
  sketch.

The current comparator set is:

| Workload | Concrete RQ3 comparators | Evidence required before freeze/result interpretation |
| --- | --- | --- |
| Agent workspace lifecycle | AgentFS FUSE/NFS workspace service; BranchFS FUSE branch/COW filesystem; YoloFS staging/snapshot/permission design; Mirage/Redis AFS only if their selected behavior enters the oracle; Bento/Wrapfs/ExtFUSE as filesystem-boundary literature. | A boundary table for the exact Agent workspace oracle listing owned operations such as lookup, readdir, create, unlink, rename, symlink, open/read/write where applicable; daemon/runtime state; COW/checkpoint/audit metadata; invalid-policy containment; lower-filesystem preservation. |
| Environment/cache transition | Feature-equivalent FUSE cache/policy view; source-native SWE-Factory/MEnv/SWE-rebench environment mechanisms; Docker/Overlay/build-cache ownership only when used by the selected source row; custom/stackable filesystem literature as explanatory boundary context. | A boundary table for the fixed cache-state oracle listing cache-validity state, epoch metadata, stale/corrupt rejection, read/write/data-path ownership, source evaluator ownership, daemon/cache-service responsibilities, and invalid-policy containment. |
| Service/config transition | Only after a concrete source oracle is admitted: feature-equivalent FUSE policy, native projected/config mechanism, and any custom service filesystem actually required by the source. | No RQ3 claim until the service/config source proves lookup-time object selection is the oracle-relevant behavior. |

## Paper-Value Admission

The main evaluation is a small set of complete experiments, not a catalog of
run IDs or mechanism checks. A candidate experiment is admitted only if it can
state a load-bearing reviewer question, a source-derived correctness oracle, the
strongest fair comparison, and the paper decision produced by positive,
contradictory, mixed, or inconclusive results.

Do not admit a standalone experiment when it is only a dependency, smoke test,
source-characterization row, artifact reproduction, weak comparison, or a
diagnostic showing that a toy mechanism is inconvenient. Those observations are
recorded as setup, background, or appendix material and may support one admitted
experiment, but they do not count as paper results.

## Make Control Plane

The current Make entrypoints are implementation artifacts for the next
BUILD_AND_EVALUATE phase. They expose feasibility and evidence gaps until
admitted full runs pass result review:

- `make experiments` is the integrated experiment-suite entrypoint.
- `make experiment-agent-workspace` currently runs an Agent workspace prototype
  matrix and preserves raw KVM/FUSE outputs; its latest reviewed run is
  supporting-only and incomplete for final paper evidence.
- `make experiment-env-cache` names the environment/cache transition matrix
  and fails with its required cells until implemented.
- `make kvm-agent-workspace-preflight` remains the implemented dependency
  preflight; it is not a paper-result cell.
- `ENABLE_LEGACY_DIAGNOSTICS=1 make phase1-legacy-diagnostics` preserves old
  W1-W4/table diagnostics as archived provenance only.

## Frozen Complete Experiment Set

The evaluation promise has two complete experiments and one conditional scope
experiment. Each experiment still requires BUILD_AND_EVALUATE admission, full
execution, and result review before it becomes final paper evidence:

| Experiment | Role | Primary RQ | Paper-value admission | Main comparison |
| --- | --- | --- | --- | --- |
| A. Agent workspace lifecycle | headline | RQ1, with RQ2/RQ3 cells | Tests the central claim on the strongest source-backed agent filesystem/workspace setting. A positive result says the VFS name-resolution boundary can satisfy a real agent workspace oracle without filesystem ownership. | Feature-equivalent FUSE policy for overhead; source/custom/stackable ownership evidence for boundary. |
| B. Environment/cache transition | decisive | RQ1 and RQ2, with RQ3 boundary evidence | Tests whether the idea extends beyond agent workspaces to build/test environment state, where cache epoch, stale, corrupt, and canonical-object choices matter. | Feature-equivalent FUSE cache/policy view; native source evaluator as correctness oracle. |
| C. Service/config transition | conditional supporting | RQ1 breadth, with RQ2/RQ3 if admitted | Included only after selecting a real service/config source whose oracle depends on lookup-time object selection. If the source only exercises projected-volume mechanics or app reload behavior, it stays related work. | Feature-equivalent FUSE policy when the source admits one; custom/stackable boundary evidence. |

### Experiment A: Agent Workspace Lifecycle

Hypothesis: a narrow `namei_ext` policy can express a source-derived agent
workspace transition while preserving lower-filesystem semantics, with lower
path-policy cost than a feature-equivalent FUSE implementation and a narrower
verifier-bounded, fail-closed ownership boundary than a custom or stackable
filesystem.

Detailed execution plan:
`docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md`.

Real assets: AgentFS is the first-choice source because its official SDK,
CLI, integration, examples, FUSE mount, COW sandbox, bash/git overlay, whiteout,
cache-invalidation, and symlink behavior have reproduced evidence. BranchFS,
Sandlock, YoloFS, Mirage, OpenHands, SWE-agent/SWE-ReX, and Redis AFS provide
supporting source context and boundary evidence, not a list of independent
comparison cells.

Implementation gate: the full paper-result run requires the implemented
`HIDE` and `SELECT_TARGET` mechanisms plus any additional registered-target
parent-directory aliasing or final-file semantics required by the admitted
Agent workspace oracle. A redirect-only or redirect/hide/select functional run
may be a useful preflight, but it is not the headline experiment and must not
shrink the hypothesis.

Current dependency preflight: `make kvm-agent-workspace-preflight` validates a
small Agent workspace path-view slice through KVM and the real
`cgroup/namei_ext` attach path. The latest passing root is
`results/experiments/agent-workspace/20260713T032434Z-8cbbac1b/`. It exercises
stable logical directory selection across base and upper registered targets,
whiteout-style hide, symlink metadata preservation, selected-root final
directory lookup and readdir in both epochs, stale-target cleanup, and lower-filesystem
write placement. The same target now also runs a FUSE policy preflight cell for
the same base/upper, whiteout, symlink, selected-root readdir, and
write-placement oracle shape. The latest root also records nonzero
operation-weighted preflight counters for `namei_ext` lookup/readdir/action
branches and FUSE getattr/readdir/open/create/read/write/readlink/hidden
branches. Full feature-equivalent FUSE parity remains a requirement for the
complete lifecycle run. This is not a paper-result cell because it does not
include the full source oracle, full-lifecycle RQ2 measurements, complete
lifecycle, or result review.

Current unreviewed prototype matrix: after the now-superseded
BUILD_AND_EVALUATE routing, `make experiment-agent-workspace` produced raw
matrix roots:

- `results/experiments/agent-workspace-matrix/20260713T053547Z-77bb2b4d/`
- `results/experiments/agent-workspace-matrix/20260713T053556Z-e2d462d9/`

Both JSONL files contain no `pass == false` rows in a quick raw check. This is
useful implementation evidence, but it is not admitted final RQ evidence: the
project re-entered BOOTSTRAP before independent result review and
source-oracle admission, and any step-0005 review-accepted route requires a
fresh admitted full run.

Historical BUILD_AND_EVALUATE Loop 001 result: after the now-superseded
freeze, the runner and Make target were repaired and
`make experiment-agent-workspace` produced raw root
`results/experiments/agent-workspace-matrix/20260713T073438Z-5be906d9/`.
Independent result review classified the run as incomplete, hypothesis
inconclusive, research value supporting, and paper impact no paper change. The
run passed its self-contained KVM/FUSE path-view oracle, but it remains too
synthetic for headline Experiment A and lacks source-derived AgentFS lifecycle
strength, raw per-operation samples, uncertainty, macro runtime, source-tied
RQ3 boundary accounting, and broader invalid-policy containment. It must not be
used as final paper evidence.

The current BUILD_AND_EVALUATE step has repaired protocol-level defects and
rerun the matrix under
`results/experiments/agent-workspace-matrix/20260714T231148Z-7e0cc0e8/`. The
new root adds matrix-specific summary labels, input hashes, command record,
kernel config snapshot, stdout/stderr logs, explicit FUSE options, no-hook
latency controls, and hard gates for those artifacts. This is supporting
protocol evidence only. It does not close the source-oracle gap; final
Experiment A still requires AgentFS-derived rename, unlink, cached-negative
creation, bash/git command-sequence or trace evidence, source-tied RQ3 boundary
rows, and broader invalid-policy containment.

Minimum complete matrix:

| Run group | Role | Workload | System/method | Decision consequence |
| --- | --- | --- | --- | --- |
| preflight | dependency | one fixed workspace transition with the real source oracle | `namei_ext` in KVM, real `cgroup/namei_ext` attach | Establishes that the real path runs; not a paper result. |
| main | proposed | full fixed workspace lifecycle: branch/fork or checkpoint, COW state, whiteout, symlink/cache invalidation where supported by implemented actions | `namei_ext` policy in KVM | Supports RQ1 only if the source oracle passes and lower-filesystem semantics are preserved. |
| main | FUSE comparison | same lifecycle and oracle | feature-equivalent FUSE policy | Supports RQ2 only if the policy and oracle are feature-equivalent. |
| control | lower-bound/control | same workload without policy actions where meaningful | no-hook or lower-filesystem path | Interprets hook overhead; not a competing mechanism. |
| ablation/control | safety control | malformed or unsupported policy decisions | `namei_ext` validation path | Supports RQ3 containment claims; not a baseline. |
| boundary evidence | RQ3 comparison | same policy requirements | source-backed custom/stackable FS boundary evidence for the same policy, with explanatory sketches only as support | Shows what filesystem methods, privileged code, daemon state, or storage semantics the broader mechanism owns. |

Completion rule: all admitted cells run to terminal status through Make-owned
KVM targets, preserve raw per-operation lookup/readdir traces, stdout/stderr,
dmesg, kernel and policy identity, and pass/fail oracle outputs under
`results/`. A result-review record must audit correctness, mechanism
engagement, FUSE fairness, lower-filesystem preservation, and boundary evidence before
any paper claim is made.

### Experiment B: Environment/Cache Transition

Hypothesis: `namei_ext` can express environment/cache object selection for
build/test workloads, including hit, miss, stale, corrupt, and update-epoch
states, without changing the source evaluator or owning the data path.

Detailed execution plan:
`docs/tmp/2026-07-13-environment-cache-complete-experiment-plan.md`.

Real assets: SWE-Factory-Gym, MEnvData-SWE, and SWE-rebench V2 provide source
oracles with released Docker/eval suites and clean reproductions.
DockSmith and Multi-Docker-Eval provide workload-shape evidence when their
artifacts are incomplete, but they are not headline comparisons unless a concrete
official evaluator path is available.

Step 0002 selected the intended suite for later BUILD_AND_EVALUATE admission,
subject only to documented KVM/Docker compatibility failures before policy
results are observed:

| Source family | Candidate row | Role |
| --- | --- | --- |
| MEnvData-SWE | `python-attrs__attrs-586` | Python preflight and small clean oracle. |
| MEnvData-SWE | `go-task__task-1814` | Go build/test oracle. |
| MEnvData-SWE | `sindresorhus__type-fest-818` | TypeScript row that closed a prior artifact gap. |
| MEnvData-SWE | `CLIUtils__CLI11-926` | C++ row that closed a prior artifact gap. |
| MEnvData-SWE | `cobalt-org__liquid-rust-403` | Rust row that closed a prior artifact gap. |
| SWE-Factory-Gym | `pallets__click-2622` | Released Docker/eval row with resolved report. |

Each admitted row must expose the same fixed state machine: hit, miss, stale,
corrupt, and epoch update. If a row cannot produce a path-view manifest with
source-evaluator path operations and stale/corrupt non-use evidence, it is
dependency-only source reproduction, not an Experiment B paper-result row.

This is one integrated environment/cache experiment. Individual ccache,
BuildKit, Docker image, source-row, or trace replays are dependencies unless
they are admitted into the same source-oracle matrix with `namei_ext`, a
feature-equivalent FUSE policy, controls, boundary evidence, raw results, and a
result review.

Minimum complete matrix:

| Run group | Role | Workload | System/method | Decision consequence |
| --- | --- | --- | --- | --- |
| preflight | dependency | one fixed clean source task with build/test oracle | `namei_ext` in KVM | Establishes runner, image, and trace path. |
| main | proposed | pre-registered environment/cache workload suite selected before the run, covering at least hit/miss plus stale or corrupt rejection | `namei_ext` cache/path policy in KVM | Supports RQ1 only if the whole suite passes source oracles and state transitions are observed. |
| main | FUSE comparison | same suite, same cache state machine, same oracle | feature-equivalent FUSE cache/policy view | Supports RQ2 if FUSE engages the same policy and receives equal information. |
| control | source evaluator | same suite without path-view policy | native source evaluator / lower-filesystem setup | Confirms the oracle and task are valid; not used as a weak proposed-method win. |
| boundary evidence | RQ3 comparison | required cache/path policy responsibilities | source-backed custom/stackable FS boundary evidence for the same policy | Shows whether a broader filesystem would own data path, metadata persistence, or cache semantics beyond object selection. |

Completion rule: the whole suite, all policy states, the FUSE comparison,
controls, and result review run to terminal status. The report must include
output/test oracle status, stale/corrupt rejection evidence, cache-state transitions,
operation-weighted lookup/readdir traces, macro runtime, and per-operation
latency/overhead. Partial row replay, image setup, or trace inspection alone is
dependency work, not an experiment result.

### Experiment C: Service/Config Transition

This experiment is not admitted merely to add breadth. It is admitted only if a
concrete service source provides a correctness oracle where lookup-time object
selection affects service-visible behavior. Examples may include real
config/secret/certificate rotation or PostgreSQL/nginx-style reload traces, but
projected-volume behavior by itself is background context.

Admission criteria:

- the source oracle must fail or change behavior when the wrong config object is
  selected at the service path;
- the policy must be implementable as bounded lookup/readdir selection rather
  than application reload logic, synthetic contents, or data-path mediation;
- a feature-equivalent FUSE policy path must be feasible for RQ2, or the row
  stays as RQ1/RQ3 supporting evidence only;
- the run must use the same completion, raw-result, and result-review discipline
  as Experiments A and B.

## Measurements

Correctness gates every evaluation row. A `namei_ext` run or comparison run is
interpreted only after it passes the same source-derived oracle. Same-oracle
means that the mechanism is judged against the same source behavior, not a
weaker mechanism-specific test.

For RQ1, report:

- source oracle pass/fail;
- lookup/readdir coherence;
- lower-filesystem permission, write, data-path, page-cache, persistence, and
  consistency preservation;
- workload-selection evidence that the chosen oracle depends on name-resolution
  policy rather than broader filesystem ownership.

For RQ2, report:

- pass-through overhead;
- action-specific overhead for redirect, hide, and select actions;
- lookup/open/stat/access/exec/readdir latency;
- cache-hot and cache-cold behavior;
- macro workload runtime;
- operation-weighted policy invocation rate;
- FUSE daemon and request-path cost for the feature-equivalent policy.

For RQ3, report:

- whether the alternative requires a filesystem daemon, a kernel filesystem, or
  a stackable filesystem layer;
- filesystem methods and storage semantics the developer must own;
- privileged code surface and policy code size;
- verifier and kernel validation guarantees;
- containment behavior for malformed or unsupported policy decisions;
- evidence that the selected policy does not require custom file operations,
  metadata persistence, data-path mediation, or runtime orchestration.

## Comparison Discipline

The evaluation deliberately avoids a long list of weak or shifting comparisons.
Each main experiment has one strong role-specific comparison:

- FUSE is the central RQ2 comparison whenever a feature-equivalent policy can be
  implemented. Fairness requires the protocol to justify FUSE caching,
  passthrough, and related acceleration context rather than relying on a weak
  generic FUSE configuration.
- Custom or stackable filesystem mechanisms are the central RQ3
  safety/boundary comparisons, using source systems and prior work where a full
  implementation is not appropriate.
- Materialized namespace mechanisms are cited and may appear as background
  comparisons, but they should not drive the central RQ structure.
- Native build/cache or service mechanisms remain production-context
  comparisons when they are the mechanism operators would normally deploy.

The experiments should be selected and engineered to support the hypothesis:
`namei_ext` should pass the same oracle, preserve lower-filesystem semantics,
show acceptable overhead versus FUSE, and demonstrate a narrower
safety/implementation boundary than custom or stackable filesystem ownership.
Candidate workloads that mainly exercise a different mechanism should be kept
out of the main evaluation so the paper tests the strongest form of its
hypothesis.

A planned comparison is valid only if it changes the answer to one RQ. A
comparison that merely repeats a fact established by prior work, is too small to
change reviewer belief, or cannot be completed under the same oracle belongs in
related work or a dated artifact note, not the main experiment matrix.

## Result Review

Each admitted experiment must end with a result-review report, separate from raw
collection. The review reports:

- run status: valid, invalid, or incomplete;
- tested hypothesis: supported, contradicted, or inconclusive;
- research value: headline, decisive, supporting, dependency-only, or redundant;
- paper impact: mechanism/workload boundary, additional RQ evidence, direct
  thesis challenge, or no paper change;
- next paper decision: what changes in the paper, or why nothing changes.

Invalid or incomplete comparisons do not count as wins for `namei_ext`.
Contradictory results trigger a stronger experiment redesign only when the
redesign has higher paper-level decision value than the other admitted
experiments. The hypothesis is not weakened just because the first experiment
was under-designed.
