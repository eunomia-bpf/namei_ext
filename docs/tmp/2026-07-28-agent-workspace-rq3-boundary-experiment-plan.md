# Experiment Plan: RQ3 Agent Workspace Ownership Boundary

## Research Question

- RQ exactly as written in the paper: Does `namei_ext` provide a narrower
  verifier-bounded, fail-closed ownership boundary than building a custom or
  stackable filesystem when the needed policy is only name resolution?
- Specific uncertainty tested here: for the same AgentFS-derived
  base/upper/hidden pathname view, which VFS and lower-filesystem
  responsibilities must workload-specific `namei_ext` code and a minimal
  stackable filesystem own, and does the implemented `namei_ext` verifier and
  kernel boundary contain every writable-ABI fault class?
- Why the answer matters: RQ1 establishes that the view is expressible and RQ2
  measures its cost. Without a matched stackable implementation, ordinary
  data-path evidence, and fault containment, the claimed ownership boundary is
  still only an interface-design assertion.

## Paper-Value Admission

- Planned role: decisive.
- Largest credible paper story this experiment could unlock: a developer can
  implement an existing-object Agent workspace view as a verified
  lookup/readdir decision while the lower filesystem continues to implement
  ordinary file operations; implementing the same application-visible view
  with a minimal stackable filesystem requires a workload-specific kernel
  module to interpose and forward broader VFS operations.
- Strongest reviewer reject argument or load-bearing uncertainty addressed:
  "`namei_ext` is just another custom filesystem interface whose shared kernel
  mechanism and failure behavior have been omitted from the comparison."
- Independent evidence added beyond existing runs and published results: a
  same-oracle Wrapfs-derived baseline on the current KVM kernel, runtime
  attribution of lookup and already-open-file operations, a complete
  writable-ABI containment matrix, and an accounting that separates shared
  mechanism code from workload-specific extension code.
- Why the result is not tautological, already settled, or dominated: Wrapfs
  documents the operation surface of a stackable template, but no publication
  implements this Agent view on the current kernel or shows which operations
  execute for the matched oracle. The prototype could also fail to enforce its
  advertised verifier, action, lifetime, or lower-object boundaries.
- Paper decision if positive: report one scoped RQ3 responsibility and
  containment table for the tested existing-object view. Do not claim complete
  system security or that all custom filesystems have the same surface.
- Paper decision if contradictory, mixed, or inconclusive: retain the completed
  negative result, remove or narrow the affected fail-closed/ownership claim,
  and identify the shared mechanism or operation responsibility that escaped
  the proposed boundary.
- Best alternative experiment and why this one has higher decision value:
  DMTCP or Spindle would add RQ1 breadth, but RQ3 currently has no matched
  evidence while RQ1 and RQ2 already have valid Agent and Bazel/FxMark results.

## Expected And Alternative Outcomes

- Current expected answer: both implementations pass the same view oracle.
  The `namei_ext` workload policy executes for lookup/readdir but not operations
  on an already-open file; the matched stackable module supplies and executes
  lookup, directory, inode, file, and superblock forwarding. Invalid BPF
  programs fail to load, invalid accepted decisions fail with their declared
  errno, teardown releases target/scope state, and fault cases do not mutate
  lower objects.
- Known pre-run mechanism repair: `target_id == 0` is currently rejected with
  `EINVAL` on ref-walk but can reach `ENOENT` on RCU-walk. Before preflight,
  move the zero-ID rejection ahead of the walk-mode branch in
  `namei_ext_resolve_target()` and protect it with warm/cold lookup regression
  cases. This repairs an already source-proven inconsistency; it does not
  change the RQ or the expected ownership relation.
- Strongest competing explanation: after accounting for `namei_ext` target
  registration, cgroup scope, path references, validation, and RCU lifetime,
  its shared privileged mechanism or ordinary data-path involvement is broad
  enough that the workload-specific distinction is not meaningful.
- Result that would contradict the expectation: a policy fault loads or
  escapes its declared errno, lookup/readdir disagree, teardown leaves usable
  policy state, ordinary fd operations execute policy code, a fault mutates a
  lower object, or the matched stackable implementation avoids the broader
  operation ownership recorded by the plan.

## Published Precedent And Real Assets

- Closest published protocol: Zadok et al., *Extending File Systems Using
  Stackable Templates* (USENIX 1999), which presents Wrapfs as a minimal
  passthrough template for implementing stackable filesystems.
- Official systems and versions:
  - latest official Wrapfs branch, based on Linux 5.18, commit
    `464802c8fd1a25413b295161c9bb9a4ce7bfa33b`;
  - YoloFS compat commit
    `f37d17583464e72793c63a31de17ca86e19262fe`;
  - AgentFS commit `0a014ebd4918615baff589ed17486e557e7c6a23`;
  - libfuse 3.14.0 and the current committed `namei_ext` kernel and policy.
- What is reused:
  - the existing Agent formal result and fixed source-derived lifecycle oracle;
  - Wrapfs' official 2,080-line null-layer implementation and operation
    forwarding structure;
  - the valid YoloFS mounted result with 593/593 upstream tests as an unmatched
    real agent stackable-filesystem exemplar;
  - the valid feature-equivalent FUSE Agent run as a supporting comparator.
- Necessary deviations or custom glue:
  - port the pinned Wrapfs code from Linux 5.18 to the current
    `7.1.0-rc7-gbdc9a83e3dfb` kernel without adding unrelated filesystem
    behavior. An unmodified-source compile probe identified concrete API work
    in idmapped mounts, the new mount API, dentry revalidation, directory
    iteration, inode timestamps, rename, mmap/writeback, and xattrs;
  - add only the matched `deleted.txt` lookup/readdir hiding rule;
  - mount the selected base or upper existing-object tree at the same logical
    workspace path, switching epochs through the baseline's mount lifecycle;
  - add a Make-owned KVM runner, raw source inventory, and tracefs kprobe
    attribution. These are adapters and instrumentation, not new policy
    configuration languages.

## Comparison

- Proposed system: `agent_workspace_view.bpf.c` through the real
  `cgroup/namei_ext` attach path.
- Main baseline: a pinned Wrapfs-derived minimal stackable filesystem adapted
  to the same application-visible base/upper/hidden workspace oracle. It
  represents the competing choice to implement the pathname view as a custom
  in-kernel filesystem.
- Why a matched baseline run is needed: the Wrapfs publication establishes the
  template but does not implement this policy, run the Agent oracle, or expose
  runtime operation attribution on the current kernel. Citation alone cannot
  determine the matched responsibility boundary.
- Supporting comparator: the existing feature-equivalent libfuse Agent
  workspace result records daemon, mount, callback, invalidation, and lifetime
  ownership. It is not the decisive RQ3 baseline and is not rerun.
- External exemplar: YoloFS source and its reproduced 593-test result show that
  a real agent stackable filesystem owns staging, snapshots, permissions,
  journaling, and a broad VFS surface. It is not feature-equivalent and its
  callback count is never compared numerically with the narrow Agent slice.
- Controls:
  - direct lower-tree operations before and after every view and fault case;
  - normal valid `namei_ext` policy, detach, target clear, and cgroup teardown;
  - source-derived operation inventories and tracefs kprobe engagement;
  - clean dmesg and complete raw manifests.
- Conclusion if the main baseline matches or wins: if the matched Wrapfs
  adapter passes the oracle without interposing broader VFS operation classes,
  or if `namei_ext` policy code participates in ordinary already-open-file
  operations, the claimed workload-specific ownership distinction is not
  supported.
- Information and fairness: both mechanisms receive the same pre-existing
  base and upper trees, logical pathname, state sequence, operations, and
  expected bytes/modes. The comparison is categorical, not a performance,
  LOC, instruction-count, or vulnerability-rate comparison. Control-plane
  differences such as cgroup state versus mount lifecycle are reported as
  responsibilities rather than normalized away.

## Workloads And Metrics

- Real workload: the fixed AgentFS-derived existing-object slice:
  1. base epoch selects the base tree;
  2. `deleted.txt` is absent from lookup and readdir;
  3. upper epoch selects the staged tree;
  4. nested paths, symlinks, permissions, access, open, stat, exec, create,
     write, fsync, rename, and final tree state match the existing oracle;
  5. teardown restores direct lower-tree behavior.
- Primary result: a categorical responsibility matrix with separate rows for:
  execution domain and verifier; lookup/readdir; inode/dentry/super/file/data
  operations; target and scope state; persistent state; daemon and mount
  lifetime; cache/coherency; failure behavior; and lower-filesystem ownership.
- Shared-versus-workload accounting:
  - `namei_ext` shared mechanism includes target registration, path references,
    per-cgroup scope state, action validation, RCU lifetime, cgroup release,
    and debugfs controls in `kernel/fs/namei_ext.c` plus the cgroup BPF hooks;
  - the workload-specific part is the Agent BPF decision and its maps;
  - Wrapfs shared template and Linux VFS are separated from the added hide/view
    policy;
  - FUSE framework/daemon runtime is separated from the Agent callbacks.
- Complete deployed accounting is reported alongside that decomposition:
  - `namei_ext` includes the complete shared kernel mechanism plus the loaded
    verified Agent policy;
  - the stackable baseline includes the complete ported and loaded Wrapfs
    module plus the added policy, even when code originated in a reusable
    template;
  - FUSE includes the in-tree FUSE client path plus the userspace daemon and
    Agent callbacks.
  The reusable/workload-specific view explains where new policy code lives;
  the complete deployed-union view prevents either system from hiding
  privileged or runtime responsibilities behind the word "shared."
- Runtime operation attribution:
  - BPF policy counters cover lookup and readdir;
  - tracefs kprobe events cover the matched Wrapfs lookup, iterate, open,
    read/write, fsync, getattr/setattr, and teardown methods;
  - after opening a selected file, perform read, write, `fsync`, `fstat`, and
    `fchmod` on that fd and compare policy counters before/after.
- Lower-object evidence: `statx` device/inode/mode/uid/gid/size/mtime, symlink
  target, and SHA-256 manifests. Fault cases must preserve them; the normal
  write case must change only the selected lower object exactly as declared.
- Source slot names, source lines, and compiled BPF instructions are secondary
  descriptive data with explicit counting boundaries. No ratio or safety score
  is derived from them.
- Repetitions and uncertainty: source accounting is deterministic. After one
  real end-to-end preflight, run the complete matrix in three independent
  modified-kernel KVM boots and report three-of-three outcomes. No confidence
  interval is constructed for deterministic errno and ownership checks.
- Cost estimate: one dependency build, one preflight boot, and three formal
  boots; existing YoloFS, FUSE, and Agent formal runs are reused.

## Fault And Containment Matrix

Every runtime case exercises lookup and/or readdir as applicable, records lower
manifests, performs teardown, and scans dmesg. Load failures preserve the full
verifier log.

| Fault class | Injection | Expected boundary evidence |
| --- | --- | --- |
| Read-only context write | Write `ctx->event` | `BPF_PROG_LOAD` fails with `EACCES`; verifier log contains `invalid bpf_context access off=0 size=4` |
| Unknown action | Return constant action `4` | `BPF_PROG_LOAD` fails with `EINVAL`; verifier log identifies `R0` outside `[0, 3]`; the defensive kernel `-EINVAL` branch is source-audited because valid BPF cannot reach it |
| Redirect length | Return `REDIRECT` with length `0` and `65` | lookup/readdir fail with `EINVAL` |
| Redirect component | Return `.`, `..`, a slash-containing name, and an embedded-NUL name | lookup/readdir fail with `EINVAL` |
| Invalid or missing target | Return `SELECT_TARGET` with target `0`, then an unregistered nonzero ID | after the pre-run consistency repair, zero ID fails with `EINVAL` in warm and cold lookup; an unregistered nonzero ID fails with `ENOENT` |
| Unsupported readdir action | Return `SELECT_TARGET` for a directory entry | `getdents64` fails with `EOPNOTSUPP` |
| Unsupported create | Return `REDIRECT` and `SELECT_TARGET` for `open(O_CREAT)` | operation fails with `EOPNOTSUPP`; no file is created |
| Unsupported final open | Return `SELECT_TARGET` for the final regular-file component | `open` fails with `EOPNOTSUPP` |
| Teardown and lifetime | Open selected file, detach, clear target, remove cgroup, then use old fd and issue fresh lookup | old fd remains a valid lower-FS fd; fresh lookup uses the unmodified lower namespace; target/scope state is no longer reachable |
| Normal data path | Open selected file, snapshot counters, then read/write/fsync/fstat/fchmod | BPF counter is unchanged after open; selected lower object receives exactly the declared mutation |

No kernel warning, Oops, BUG, KASAN/UBSAN report, RCU stall, or lockdep failure
is allowed in any cell.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
| --- | --- | --- | --- | ---: | --- |
| source audit | main baseline | Matched operation ownership | Wrapfs-derived stackable FS | Once at pinned source | Defines registered and policy-added operation responsibilities |
| reused | supporting | AgentFS-derived lifecycle | `namei_ext` and libfuse formal-v3 | Existing 10+10 boots | Supplies prior normal correctness and FUSE daemon evidence |
| reused | external exemplar | Full agent filesystem | YoloFS compat | Existing 1 VM, 593 tests | Confirms broader source-system responsibilities without a matched comparison |
| preflight | proposed and baseline | Complete matched oracle plus one load and one runtime fault | `namei_ext` and Wrapfs-derived baseline | 1 boot | Establishes both real system paths and raw evidence flow |
| formal | proposed and baseline | Matched oracle, data-path attribution, and complete fault matrix | `namei_ext` and Wrapfs-derived baseline | 3 boots | Supplies the decisive responsibility and containment evidence |

## Execution

- Planned authoritative entrypoints, which do not exist until implementation:
  - `make kvm-agent-workspace-rq3-preflight RUN_ID=<fresh-id>`;
  - `make experiment-agent-workspace-rq3 RUN_ID=<fresh-id>`.
- Real preflight: one modified-kernel KVM boot must load and mount the actual
  Wrapfs-derived module, pass the matched base/upper/hidden oracle with both
  mechanisms, reject the read-only-context program, execute one malformed
  redirect case, attribute normal fd operations, preserve raw manifests, and
  tear down both paths cleanly.
- Execution completeness is independent of the hypothesis outcome. A formal
  boot is complete when every declared cell emits an observation, all
  inventories and logs are retained, and analysis can classify each expected
  relation. Any unexpected result makes the owning Make target fail after
  preserving the complete matrix; it remains a completed negative scientific
  result rather than disappearing as infrastructure failure.
- Full completion rule: all three formal boots terminate with every declared
  cell present; source identities match; reports regenerate from raw
  observations; no partial boot prefix is interpreted as the experiment.
- Raw-result path:
  `results/experiments/agent-workspace-rq3/<RUN_ID>/`.
- Recovery: failed boot roots remain immutable. Host-only source inspection or
  unit tests cannot substitute for the modified-kernel KVM preflight.

## Interpretation

- Positive result: both mechanisms pass the same oracle; the responsibility
  matrix and runtime traces show that the workload-specific `namei_ext` policy
  is confined to lookup/readdir while the matched stackable module interposes
  broader file/inode/super operations; every fault remains inside its declared
  load/errno/lifetime boundary.
- Negative or contradictory result: a complete run shows an escaping fault,
  lower-object corruption, policy execution on the ordinary data path, leaked
  target/scope state, or a matched stackable implementation that does not own
  the predicted operation classes.
- Mixed or inconclusive result: both systems run but one primary responsibility
  relation cannot be attributed, or evidence is insufficient to distinguish
  shared mechanism from workload-specific code. Missing a declared mechanism
  arm or raw cell makes the run incomplete, not mixed.
- Target paper output: one categorical ownership-and-containment table,
  supported by a small operation-engagement panel. No LOC ratio, callback
  ratio, or generic filesystem-security ranking.

## Reproducibility Notes

- Pin and record Wrapfs, YoloFS, AgentFS, libfuse, project, and modified-kernel
  commits in raw metadata.
- Preserve the exact Wrapfs 5.18-to-7.1 port as vendored third-party source plus
  a focused patch or clearly separated adapter changes.
- Use the kernel-source bpftool for the `cgroup/namei_ext` programs.
- Preserve verifier logs, errno observations, operation inventories, kprobe
  traces, BPF counters, lower manifests, cgroup/mount teardown, and dmesg as
  raw artifacts. Generate the paper table only in an analysis target.
- The stackable baseline is matched only for the existing-object Agent view.
  YoloFS staging, snapshots, journaling, conflict handling, and progressive
  permissions remain out of the matched conclusion.
