# Evaluation

Last updated: 2026-07-27

This file holds the scientific evaluation state: use cases, experiment
matrices, result pointers, and open questions. Research process rules and
gates belong to the orchestrator skill, not to this repository. The previous
process-heavy version is archived at
`docs/tmp/2026-07-25-archived-process-docs/evaluation.md`.

## Research Questions

| RQ | Question | Main comparison |
| --- | --- | --- |
| RQ1 Expressiveness / sufficiency | Can a narrow VFS name-resolution extension express real state-dependent path-view policies without taking over filesystem semantics? | Source-system behavior as correctness oracle |
| RQ2 Cost / overhead versus FUSE | What is the cost of programmable policy on the VFS name-resolution path compared with a feature-equivalent FUSE policy? | Feature-equivalent FUSE over the same oracle |
| RQ3 Safety / boundary | Is the verifier-bounded, fail-closed ownership boundary narrower than custom or stackable filesystem ownership when only name resolution is needed? | Workload-specific ownership accounting |

## Use Cases

The evaluation separates three kinds of evidence:

1. **Case studies** replay behavior from a real source system and check its
   correctness oracle.
2. **Standard filesystem benchmarks** measure the cost of adding the hook to
   the VFS path.
3. **Mechanism-specific tests** isolate `PASS`, `HIDE`, target selection,
   policy updates, and failure behavior that standard benchmarks do not know
   about.

A case study is admitted only when an unmodified POSIX application consumes
paths, the source system changes which existing object a path denotes or
whether the object is visible, and the behavior has a reproducible oracle.
The experiment does **not** need to prove that a static table, mount, symlink,
or another mechanism is impossible. It tests whether the source behavior fits
the narrow `namei_ext` boundary and compares its cost with a
feature-equivalent FUSE implementation.

The unit of classification is an industrial workflow, identified by its user,
production objective, triggering event, source system, and correctness oracle.
It is not a policy action such as `HIDE`, `SELECT`, an epoch switch, or pathname
remapping. Multiple systems that solve the same production problem are grouped
inside one case; systems that happen to use similar path actions but solve
different production problems remain separate.

### Industrial case-study portfolio

| ID | Industrial workflow | Source systems and current mechanism | State and path-view effect | Correctness oracle | `namei_ext` boundary and natural comparison |
| --- | --- | --- | --- | --- | --- |
| W1 | Sandboxed Application File Sharing | The official [Documents portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html) exposes host files to sandboxed applications through a FUSE filesystem, gives each application a restricted view, and supports grant/revoke. The portal API can derive host-application identity from a standardized [cgroup path](https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html). | `(application identity, grant state, document ID)` selects an existing host file or hides it; revocation changes subsequent lookup/readdir results. | The granted application opens/stats/enumerates the document; another application and the revoked application receive the portal's expected `ENOENT`/visibility result; bytes and inode-backed behavior match the registered host object. | Implement the existing-object grant/revoke subset and compare with the portal-style FUSE view. Synthetic document contents, mode synthesis, persistent grant storage, and portal UI stay out of scope. |
| W2 | Agent Workspaces | [AgentFS](https://github.com/tursodatabase/agentfs), [BranchFS](https://arxiv.org/abs/2602.08199), and [YoloFS](https://arxiv.org/abs/2604.13536) provide workspace branch, snapshot, hide/whiteout, and staged/base views through FUSE or a stackable filesystem. | `(workspace, branch state, pathname)` selects a staged object, base object, or hidden result; fork, staging, and rollback change the visible workspace. | Source-derived lifecycle trace, final file-tree oracle, expected lookup/readdir/open/stat results, concurrent branch isolation, and unchanged lower-object data/metadata outside the policy decision. | Compare the same view/visibility subset with feature-equivalent FUSE. Write isolation, copy-up, commit, conflict resolution, and audit storage remain with the workspace manager or filesystem. |
| W3 | Build Action Sandboxing | Bazel's [sandboxfs](https://blog.bazel.build/2017/08/25/introducing-sandboxfs.html) was built because an action may require hundreds or thousands of mappings; symlink-forest construction was costly and error-prone, while FUSE could expose an arbitrary view. Its [official repository](https://github.com/bazelbuild/sandboxfs) is archived but reproducible. | `(action identity, declared-input set, configuration)` maps action paths to existing source or generated objects and hides undeclared paths. | A real Bazel build/test succeeds with the declared inputs, output hashes match, an undeclared-input probe fails, and two concurrent actions observe their own mappings. | Reuse an action trace and local existing targets. Compare `namei_ext` with the source symlink-forest behavior and feature-equivalent FUSE; remote execution, CAS download, output upload, and sandbox process isolation are out of scope. |
| W4 | Service Configuration and Secret Rotation | Kubernetes [AtomicWriter](https://github.com/kubernetes/kubernetes/blob/master/pkg/volume/util/atomic_writer.go) materializes timestamped versions and atomically retargets a symlink; [ConfigMap documentation](https://kubernetes.io/docs/concepts/configuration/configmap/) records delayed propagation and non-updating `subPath` mounts. ingress-nginx embeds Lua to avoid reloads for some runtime selections. | `(service identity, validated release)` selects current, canary, or rollback config/certificate/secret; an invalid candidate remains hidden and lookup falls back to the current object. | `nginx -t` or the service's native validator, service-visible behavior after reopen/reload, rejection of a bad release, and successful rollback. | Compare with a feature-equivalent FUSE view and retain AtomicWriter as the source-system behavior. Applications that keep old file descriptors, secret generation, validation, and reload orchestration remain out of scope. |
| W5 | Checkpoint/Restore and Migration | [DMTCP path virtualization](https://dmtcp.sourceforge.io/papers/cluster16.pdf) translates paths remembered before checkpoint to paths valid after migration; the implementation interposes pathname operations in user space. | `(restart image, restored root/mount state, remembered pathname)` selects the restored existing object or fails closed when the mapping is absent. | The source application checkpoints, moves to a different root, restarts, and reopens the expected object with matching bytes/metadata; an unmapped stale path fails. | Compare the same remapping with DMTCP's source plugin behavior and feature-equivalent FUSE. Process checkpointing, descriptor restoration, distributed coordination, and file-content transfer remain DMTCP/CRIU responsibilities. |
| W6 | HPC File Staging | LLNL [Spindle](https://computing.llnl.gov/projects/spindle) intercepts library, executable, Python, and selected data-file operations, distributes one shared-filesystem read to node-local storage, and redirects applications to the local object. It is [enabled automatically on El Capitan](https://hpc.llnl.gov/documentation/user-guides/using-el-capitan-systems/using-el-capitan-systems-spindle-and-library). Its public [source](https://github.com/LLNL/Spindle) interposes `open`, `stat`, `exec`, and dynamic-loader operations. | `(job/session, local-stage readiness, pathname)` selects the prepared local copy or the shared canonical object; a negative or invalid entry hides the local candidate. | Pynamic or an LLNL-style MPI/Python launch completes with identical loaded object hashes and output; file-operation and shared-filesystem request counts fall; stale/wrong local objects are not loaded. | Reuse Spindle's distribution/cache control plane and replace only its pathname redirection decision. `namei_ext` does not distribute bytes, populate caches, or recognize libraries. Compare with source Spindle behavior and feature-equivalent FUSE over the same pre-populated objects. |
| W7 | Toolchain and Dependency Environments | [Nix profiles](https://nix.dev/manual/nix/2.34/command-ref/files/profiles.html) and [Guix profiles](https://guix.gnu.org/manual/en/guix.pdf) are versioned symlink trees into immutable stores; [Spack environment views](https://spack.readthedocs.io/en/v0.23.1/environments.html) link installed packages into `bin/lib/include` trees; Python [venv](https://docs.python.org/3/library/venv.html), [Conda](https://docs.conda.io/en/latest/user-guide/tasks/manage-environments.html), [nvm](https://github.com/nvm-sh/nvm), [rbenv](https://github.com/rbenv/rbenv), [Lmod](https://lmod.readthedocs.io/en/6.6/), and Debian [update-alternatives](https://manpages.debian.org/bookworm/dpkg/update-alternatives.1.en.html) select versions through environment, shims, profiles, or symlink groups. CernVM-FS even implements [variant symlinks](https://cvmfs.readthedocs.io/en/2.14/cpt-repo/#variant-symlinks) in FUSE so one software or certificate path resolves according to client configuration. | `(project/job/process group, selected environment, pathname)` selects one installed executable, library tree, dependency profile, or site-specific target; switching the environment changes later exec/open/readdir results without changing the application's path. | Run source-native version and build/import checks in two real environments; verify executable/library identity and output, concurrent isolation, switch, and rollback. | Reuse installed objects from Spack/Nix/Guix or two Python/Node environments. The natural source behavior remains the oracle; feature-equivalent FUSE is the RQ2 comparison. Package solving, installation, builds, activation scripts, and ABI compatibility stay with the source package manager. |

The cases remain distinct even when their policies use the same bounded action:

| Potential confusion | Non-overlap boundary |
| --- | --- |
| W2 Agent Workspaces vs W5 Checkpoint/Restore and Migration | W2 creates concurrent, isolated workspace branches for agents; W5 resumes one traditional application after restart or migration and preserves its pathname continuity. |
| W3 Build Action Sandboxing vs W7 Toolchain and Dependency Environments | W3 restricts each action to declared build inputs and tests undeclared-input failure; W7 selects an installed compiler/runtime/dependency environment and tests version, linkage, import, and program output. |
| W6 HPC File Staging vs W7 Toolchain and Dependency Environments | W6 moves the same object from shared storage to node-local storage to reduce launch and shared-filesystem load; W7 chooses among semantically different installed software variants. |
| W4 Service Configuration and Secret Rotation vs W7 Toolchain and Dependency Environments | W4 publishes validated configuration, certificate, or secret releases to a running service; W7 selects a user, project, or job software environment. |

W1--W7 are seven industrial workflow cases, not seven unrelated performance
benchmarks. Multiple source systems are consolidated within the workflow they
serve. Each case gets a correctness cell for RQ1 and an ownership/scope row for
RQ3. RQ2 uses standard benchmarks plus feature-equivalent FUSE on
representative macro cases; it does not require seven bespoke FUSE performance
stories.

### Related evidence, not case studies

| Candidate | Citation | Disposition |
| --- | --- | --- |
| SELinux polyinstantiation / `pam_namespace` | [`namespace.conf(5)`](https://man7.org/linux/man-pages/man5/namespace.conf.5.html); Red Hat SELinux guide | Closest shipping precedent for per-context path views. Cite and account for it in RQ3; no separate workload is needed. |
| Plan 9 per-process namespaces and union directories | Pike et al., *The Use of Name Spaces in Plan 9*, 1993 | Intellectual ancestor and related work, not a Linux evaluation workload. |
| lakeFS and DVC | Git-like branches over object storage | Demand is real, but normal consumption is through S3 APIs/SDKs rather than VFS pathname lookup; related work only. |

The paper claims that these source behaviors can share one bounded
name-resolution decision boundary. It does not claim that the workloads
intrinsically require eBPF or that their existing mechanisms cannot implement
the behavior.

## Performance Evaluation

### Standard benchmarks

| Benchmark | Role and operations | Conditions | Primary metrics and figure |
| --- | --- | --- | --- |
| [FxMark](https://github.com/sslab-gatech/fxmark) ([ATC'16 paper](https://www.usenix.org/conference/atc16/technical-sessions/presentation/min)) | Primary VFS microbenchmark: component/path lookup (`MRPL`, `MRPM`, `MRPH`), directory enumeration (`MRDL`, `MRDM`), and create control (`MWCL`). | Stock kernel; patched kernel unattached; attached `PASS`; attached same-filesystem `SELECT`; feature-equivalent FUSE. Run cache-hot and cache-cold variants where supported and scale threads/vCPUs. | Operations/s and normalized overhead versus stock across core count; median and confidence interval across independent runs. Main figure: throughput curves or a compact operation-by-condition heatmap. |
| [mdtest/IOR](https://github.com/hpc/ior) | Standard metadata breadth: file/directory create, stat, open/read, rename, and remove. It checks that the conclusion is not unique to FxMark's operation mix. | Stock, patched-unattached, attached `PASS`, and FUSE; selected operations only, with fixed tree and process counts. | Metadata operations/s and scaling efficiency. Appendix or secondary figure. |
| [Filebench](https://github.com/filebench/filebench) | Mixed macro control using fileserver and webserver profiles. It is not evidence for RQ1. | Stock, patched-unattached, attached `PASS`, representative `SELECT`, and FUSE with identical lower storage and cache warmup. | Runtime/throughput, CPU utilization, context switches, and FUSE daemon CPU. Secondary macro figure. |

### Mechanism-specific measurements

The repository's custom VFS benchmark remains necessary for operations that
standard suites do not expose:

| Measurement | Conditions | Metrics |
| --- | --- | --- |
| Hook fast path | Stock kernel versus patched-unattached, then attached `PASS`, for `stat`, `open`, `access`, `exec`, multi-component walk, and `readdir` | ns/op, p50/p95/p99, cycles, instructions, branch misses |
| Policy actions | `PASS`, `HIDE`, same-filesystem `SELECT`, cross-filesystem `SELECT`, and invalid/fail-closed decision | ns/op and tail latency per operation; returned errno/object identity |
| State update | Policy/object registration update followed by concurrent lookup | update calls/s, update-to-visible latency, stale observations after acknowledged update |
| FUSE comparison | Same policy inputs, targets, operation stream, cache state, daemon count, and justified caching/passthrough mode | client latency/throughput, daemon CPU, context switches, request count, correctness oracle |

The critical kernel-maintainer result is the patched-but-unattached cost.
Macro compile time cannot establish that fast path because compiler work
dilutes pathname lookup overhead.

## Experiment Matrix Status

### Case-study implementation status

| Case | Source/oracle fixed | `namei_ext` correctness in KVM | Feature-equivalent FUSE | RQ3 boundary record |
| --- | --- | --- | --- | --- |
| W1 Sandboxed Application File Sharing | Existing-object, two-application grant/revoke subset frozen from the XDG Documents portal API | Preflight passed: grant, revoke, cross-application isolation, lookup/readdir/open/stat, and unchanged lower object | Source system is FUSE; matched project implementation not run | Preflight records lower-object preservation; full ownership table open |
| W2 Agent Workspaces | AgentFS-derived lifecycle trace fixed | Passed, three terminal runs | Correctness passed; macro timing open | Open |
| W3 Build Action Sandboxing | Bazel 6.5.0 two-genrule oracle fixed: same logical path, distinct declared roots, undeclared-input lookup/readdir probe, concurrent overlap | Preflight passed: two concurrent real Bazel actions, distinct expected outputs, undeclared input hidden, lower objects unchanged | Not run | Preflight records lower-object preservation; full ownership table open |
| W4 Service Configuration and Secret Rotation | AtomicWriter and nginx validation oracle identified | Not run | Not run | Not written |
| W5 Checkpoint/Restore and Migration | DMTCP plugin behavior identified | Not run | Not run | Not written |
| W6 HPC File Staging | Spindle source and production behavior identified; exact Pynamic/MPI/Python trace not yet frozen | Not run; blocked on cross-filesystem `SELECT` preflight | Not run | Not written |
| W7 Toolchain and Dependency Environments | Industrial workflow and source set fixed; exact Spack/Nix/Python workflow not yet selected | Not run | Not run | Not written |

### A. Sandboxed Application File Sharing (supporting RQ1 breadth)

| Cell | Status | Raw root |
| --- | --- | --- |
| XDG-derived two-application grant/revoke preflight | Passed in KVM; application A hidden before grant, visible after grant, and hidden after revoke; application B always hidden; unrelated same-named path and lower object unchanged; zero failures | `results/experiments/application-file-sharing/20260725T-sandboxed-file-sharing-preflight-v3/` |
| Policy engagement | Passed: 123 lookup, 30 readdir, 2 `SELECT`, 8 lookup `HIDE`, and 4 readdir `HIDE` events | Same raw root |
| Matched FUSE performance comparison | Open; the source system establishes FUSE behavior, but no matched timing result exists | — |

Make entrypoint: `make kvm-application-file-sharing-preflight`.

### B. Agent Workspaces (headline)

| Cell | Status | Raw root |
| --- | --- | --- |
| RQ1 correctness: AgentFS-derived trace oracle for `namei_ext` and feature-equivalent FUSE | Passed, independently reviewed; 3 terminal KVM runs, 1,176 records each, zero failures, clean dmesg | `results/experiments/agent-workspace-matrix/20260722T020120Z-rq1run1/`, `-rq1run2/`, `-rq1run3/` |
| RQ2 timing versus FUSE | Open: no macro runtime or per-operation latency claim yet | — |
| RQ3 boundary table | Open: source-tied ownership rows not yet written | — |

### C. Build Action Sandboxing (supporting RQ1 breadth)

| Cell | Status | Raw root |
| --- | --- | --- |
| Two concurrent Bazel 6.5.0 genrules in separate action cgroups | Passed in KVM; both actions reached the barrier concurrently and completed successfully | `results/experiments/build-action-sandboxing/20260726T-build-action-sandboxing-preflight-v3/` |
| Same logical path, distinct declared-input roots | Passed; action A and B produced their expected distinct 17-byte outputs | Same raw root |
| Undeclared existing input hidden from lookup and readdir | Passed; policy recorded 4 `SELECT`, 2 lookup `HIDE`, and 2 readdir `HIDE` decisions | Same raw root |
| Lower-filesystem preservation and kernel health | Passed; declared and undeclared lower objects remained unchanged; zero false records and no declared dmesg failure signature | Same raw root |
| Matched sandboxfs/symlink-forest/FUSE comparison | Open; this correctness preflight is not a performance result | — |

Make entrypoint: `make kvm-build-action-sandboxing-preflight`.

### D. ccache compile macrobenchmark (existing performance evidence)

| Cell | Status | Raw root |
| --- | --- | --- |
| Verified hot-cache compile, 20 samples, `namei_ext` / native / FUSE | Passed in KVM; 400/400 output hashes per mechanism; observed FUSE/namei_ext compile-time ratio 2.18x, native/namei_ext 0.945x | `results/experiments/build-cache/20260723T-build-cache-release-v1/` |
| Trace-derived state row (verified-hit→local, epoch→canonical) | Passed in KVM for `namei_ext` and FUSE | `results/experiments/build-cache/20260723T-build-cache-state-release-v1/` |
| Real compiler-output epoch switch, 20 samples, 2 epochs | Passed in KVM; 800/800 output matches; observed FUSE/namei_ext ratio 2.10x; policy session updates 20 vs 800 backing invalidations | `results/phase1/20260724T-epoch-switch-release-v2/` |
| Stale-local and corrupt-hidden fallback | One-sample probes passed in KVM for both mechanisms | `results/phase1/20260724T-bad-local-stale-smoke-v1/`, `-corrupt-hidden-smoke-v1/` |
| Real-compile miss cell | Open | — |
| Release-scale stale/corrupt compile cells | Open (probes only) | — |
| Timing uncertainty (median/dispersion across samples) | Open: ratios are release-run observations, not modeled statistics | — |
| RQ3 boundary table | Open | — |

Formal case-study entrypoints: `make experiments`,
`make kvm-agent-workspace-matrix`,
`make kvm-application-file-sharing-preflight`, and
`make kvm-build-action-sandboxing-preflight`.

Historical ccache reproduction entrypoints: `make legacy-build-cache`,
`make kvm-w4-ccache-bulk-compile-epoch-switch`,
`make kvm-w4-ccache-bulk-bad-local-fallback`.

The ccache matrix is useful RQ2 macro evidence and validates state changes in
the prototype. It is not, by itself, a headline case-study motivation:
ccache already implements cache lookup and validation in user space. W3 Bazel
action views and W6 Spindle file relocation provide the source-derived
build/cache cases whose pathname view is the behavior under study.

### E. FxMark path-resolution cost (decisive RQ2 mechanism result)

| Cell | Status | Raw root |
| --- | --- | --- |
| Complete matched matrix | Valid: 50 KVM boots, 450/450 unique passing observations, no exclusions, exact boot/cell sets | `results/experiments/fxmark-rq2/20260726T-rq2-fxmark-full-v2/` |
| Patched-unattached versus stock | Hypothesis contradicted: median ratio `0.867--0.942`; all nine CI upper bounds below `0.98` | Same raw root and `analysis/summary.csv` |
| Attached `SELECT` versus optimized FUSE | Hypothesis contradicted for the stable cache-hot view: median ratio `0.314--0.570`; all nine CIs below `1` | Same raw root and `analysis/report.md` |
| Attached-path ablation | `PASS` accounts for most active cost: paired `PASS`/unattached medians `0.298--0.547`; `SELECT`/`PASS` is `0.980--1.004` | Same raw root; independently recomputed |
| Baseline engagement | FUSE setup median requests `28--195,433`, measured-phase median requests `1--18`; valid for stable cache-hot policy, not update/invalidation behavior | Same raw root |
| Result review | Run valid; hypothesis contradicted; decisive mechanism/workload boundary; implementation redesign and fresh rerun required | `docs/tmp/2026-07-27-rq2-fxmark-result-review.md` |

The current result is retained as internal negative evidence and is not a
paper performance claim. It does not change RQ2 or the hypothesis. The next
step is to isolate attached-only state from the inactive path, diagnose RCU
fallback and cgroup/BPF dispatch, and rerun the same approved matrix under a
new run ID. A dynamic update/invalidation comparison may add RQ2 evidence, but
it does not replace the strong cached-FUSE row.

## Open Questions

1. Can an out-of-line attached slow path restore the predeclared
   patched-unattached FxMark threshold without changing semantics?
2. How much of the attached `PASS`/`SELECT` cost comes from RCU fallback,
   context initialization, cgroup dispatch, and BPF execution, and which
   mechanism repair can meet the unchanged cached-FUSE comparison?
3. What are the setup and steady-state costs of the W3 action view relative to
   Bazel's symlink-forest behavior and a matched FUSE view after the real Bazel
   correctness preflight?
4. Does cross-filesystem target selection preserve lower-filesystem behavior
   well enough to replay Spindle's shared-to-local redirection without turning
   `namei_ext` into a cache or remote filesystem?
5. Which concrete Spack/Nix/Python workflow gives W7 the strongest unmodified
   application oracle while staying within existing-object selection?
6. What do the per-workload RQ3 ownership tables show for FUSE and the
   relevant custom/stackable source system?
7. Does the existing ccache macro ratio survive independent-run
   median/dispersion reporting and a hardened FUSE configuration with caching
   and passthrough explicitly accounted for?
