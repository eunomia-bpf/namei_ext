# Agent Sandbox Related Work Survey

## Purpose

This note records an expanded related-work survey for a possible `namei_ext` paper story centered on agent sandbox lifecycle workloads. The existing paper related-work draft in `docs/paper/sections/06-related-work.tex` covers FUSE, OverlayFS/materialized views, Landlock/BPF LSM/fanotify, and eBPF kernel policy interfaces. It does not yet cover coding-agent benchmarks, agent sandbox products, snapshot/fork systems, terminal-command traces, or serverless checkpoint work.

The main question for related work is not "who also runs agents?" The question is:

> What existing systems, benchmarks, and interfaces either provide workload provenance, provide a competing mechanism, or explain why a narrow VFS path-resolution eBPF hook is a distinct point in the design space?

## Current positioning

The stronger paper shape should use three top-level use cases:

1. Agent sandbox lifecycle.
2. Service fixture sandbox.
3. Content-verified cache view.

For the agent sandbox lifecycle line, the workload input should be fixed command traces derived from SWE-bench-style tasks, not live random agents. The paper should not claim eval isolation, security isolation, or higher agent solve rate. It should claim only path-view setup, fork/fanout, rollback, and materialization behavior when the same deterministic command trace is replayed under `namei_ext` and baselines.

## Category 1: Coding-agent benchmarks and trajectories

### SWE-bench family

SWE-bench introduced the patch-and-test task shape: a model receives a real GitHub issue, edits the repository, and the generated patch is judged by fail-to-pass and pass-to-pass tests. SWE-bench Verified is a human-filtered 500-instance subset. SWE-bench Pro extends the direction to longer-horizon, multi-file professional tasks and publishes a public subset with fields such as `base_commit`, `patch`, `test_patch`, `fail_to_pass`, `pass_to_pass`, `before_repo_set_cmd`, `selected_test_files_to_run`, and `dockerhub_tag`.

Sources:

- SWE-bench original: https://www.swebench.com/original.html
- SWE-bench Verified: https://www.swebench.com/verified.html
- SWE-bench harness reference: https://www.swebench.com/SWE-bench/reference/harness/
- SWE-bench Pro public leaderboard: https://labs.scale.com/leaderboard/swe_bench_pro_public
- SWE-bench Pro dataset: https://huggingface.co/datasets/ScaleAI/SWE-bench_Pro
- SWE-bench Pro paper: https://arxiv.org/html/2509.16941v1

Relevance:

- Provides real task provenance: repository, base commit, issue, patch, tests, Docker/harness.
- Good source for deterministic command-replay workloads.
- SWE-bench Pro public is the best candidate for final agent sandbox lifecycle workloads if local reproduction works.

Boundary:

- SWE-bench does not provide path-level syscall traces.
- SWE-bench score is an agent capability metric; it should not be used as a `namei_ext` systems metric.
- Held-out/private subsets are not appropriate as main artifact evidence because reviewers cannot reproduce them.

Paper angle:

- Cite SWE-bench/SWE-bench Pro as the source of real coding-agent task workflows.
- State that the evaluation replays fixed command traces derived from these tasks and collects file-operation evidence locally.

### Public agent trajectory datasets

Recent datasets expose trajectories from SWE-agent, OpenHands, and related coding agents. The most useful ones for us are command/action sources, not filesystem traces.

Sources:

- Open-SWE-Traces: https://huggingface.co/datasets/nvidia/Open-SWE-Traces
- Open-SWE-Traces paper: https://arxiv.org/html/2606.16038
- Nebius SWE-agent trajectories: https://huggingface.co/datasets/nebius/SWE-agent-trajectories
- Nebius OpenHands trajectories: https://huggingface.co/datasets/nebius/SWE-rebench-openhands-trajectories
- SWE-agent trajectory documentation: https://swe-agent.com/latest/usage/trajectories/
- SWE-bench experiments: https://github.com/swe-bench/experiments
- SWE-ZERO 12M trajectories: https://huggingface.co/datasets/AlienKevin/SWE-ZERO-12M-trajectories
- LMCache agentic traces: https://huggingface.co/datasets/sammshen/lmcache-agentic-traces

Relevance:

- They provide command/action distributions and edit-test-debug loop shapes.
- Open-SWE-Traces and Nebius trajectories are useful fallbacks if SWE-bench Pro Docent trajectories are not exportable.
- SWE-agent `.traj` format demonstrates that trajectories usually contain actions, observations, and working directory state.

Boundary:

- These are not VFS or syscall traces.
- Some trajectories are not executed or not verified; SWE-ZERO explicitly should be treated only as command-distribution evidence.
- The trajectory format is not stable enough to be the paper artifact without normalization.

Paper angle:

- Use them to justify command-trace replay as a realistic agent-sandbox workload shape.
- Normalize all selected trajectories into a project-owned command-trace schema before benchmarking.

### Terminal benchmarks

Terminal-Bench and TerminalWorld are adjacent rather than primary. They evaluate command-line agents in realistic terminal tasks. TerminalWorld is especially relevant because it reverse-engineers tasks from public terminal recordings and releases deterministic task artifacts such as reference solutions and Docker/test environments.

Sources:

- Terminal-Bench paper: https://arxiv.org/html/2601.11868v1
- Terminal-Bench trajectories: https://huggingface.co/datasets/yoonholee/terminalbench-trajectories
- Terminal-Bench site: https://www.tbench.ai/about
- TerminalWorld paper: https://arxiv.org/html/2605.22535v1
- TerminalWorld repository: https://github.com/EuniAI/TerminalWorld
- TerminalWorld dataset: https://huggingface.co/datasets/EuniAI/TerminalWorld

Relevance:

- Good command-heavy control workload.
- Demonstrates that deterministic Docker/test-based terminal tasks are now a standard evaluation object.
- TerminalWorld's `solve.sh` style artifacts can be useful for rollback/fork/control experiments.

Boundary:

- These are not patch-and-test coding-agent tasks in the SWE-bench sense.
- They should not replace SWE-bench Pro as the main agent sandbox workload.

Paper angle:

- Use as appendix/control if the agent sandbox lifecycle story needs a non-SWE terminal workload.

## Category 2: Agent sandbox products and platforms

### E2B, Modal, Daytona, and Codex sandboxing

Agent sandbox products show that isolated, reproducible execution environments, snapshots, forks, and filesystem persistence are central primitives for modern coding agents.

Sources:

- E2B sandboxes: https://e2b.dev/docs
- E2B snapshots: https://e2b.dev/docs/sandbox/snapshots
- Modal sandboxes: https://modal.com/docs/guide/sandboxes
- Modal sandbox snapshots: https://modal.com/docs/guide/sandbox-snapshots
- Modal directory snapshots: https://modal.com/blog/directory-snapshots-resumable-project-state-for-sandboxes
- Daytona snapshots: https://www.daytona.io/docs/en/snapshots/
- Daytona docs: https://www.daytona.io/docs/en/
- OpenAI Codex sandboxing: https://developers.openai.com/codex/concepts/sandboxing
- Codex approvals and security: https://developers.openai.com/codex/agent-approvals-security

Relevance:

- They motivate the agent sandbox lifecycle use case: create sandbox, run commands, preserve state, snapshot, restore, fork.
- They show that snapshots may include filesystem state, memory state, or directory-specific state depending on platform.
- They justify measuring setup, fork/fanout, rollback, and workspace state reuse.

Boundary:

- Product docs are motivation and design-space evidence, not peer-reviewed systems papers.
- Most product platforms provide whole-sandbox or directory snapshots; `namei_ext` is narrower and does not claim to be a full sandbox platform.
- We should avoid security-isolation claims. `namei_ext` changes path resolution; it does not replace sandbox enforcement.

Paper angle:

- State that agent sandboxes increasingly rely on filesystem snapshots and reproducible execution state.
- Position `namei_ext` as a low-level VFS path-view mechanism that can reduce materialization for selected read-mostly path views, not as a complete sandbox runtime.

## Category 3: Snapshot, fork, and restore systems

### Serverless snapshot systems

FaaSnap, REAP/vHive, Pronghorn, SEUSS, Sabre, and related serverless work study snapshot/restore performance for cold starts and hot starts. They typically benchmark fixed functions, compare against cold/warm/snapshot baselines, and decompose restore latency, page faults, working set, and checkpoint timing.

Sources:

- FaaSnap paper: https://www.sysnet.ucsd.edu/~voelker/pubs/faasnap-eurosys22.pdf
- FaaSnap artifact: https://github.com/ucsdsysnet/faasnap
- REAP/vHive paper: https://marioskogias.github.io/docs/reap.pdf
- REAP arXiv summary: https://arxiv.org/abs/2101.09355
- Pronghorn paper: https://www.cs.purdue.edu/homes/pfonseca/papers/eurosys24-pronghorn.pdf
- Pronghorn artifact: https://github.com/rssys/pronghorn-artifact
- SEUSS paper: https://open.bu.edu/bitstreams/cd53f261-0c9a-48a5-b885-4982022e60e6/download
- Sabre OSDI 2024 paper: https://www.csl.cornell.edu/~zhiruz/pdfs/sabre-osdi2024.pdf
- No Provisioned Concurrency / remote fork: https://www.usenix.org/system/files/osdi23-wei-rdma.pdf

Relevance:

- Provides evaluation patterns for fork/restore systems: fixed workload suite, explicit restore-to-ready metric, page-fault/resource attribution, and feature-equivalent baselines.
- Supports our decision to separate correctness gates from performance metrics.
- Shows reviewers will expect real restore/fork operations if the paper claims restore.

Boundary:

- These systems restore processes, VMs, memory, or containers. `namei_ext` only changes path resolution and lower-filesystem object selection.
- Current W3 Redis RDB replay is not comparable to these restore systems and should not be written as real checkpoint/restore evidence.

Paper angle:

- Use this related work to justify benchmark structure for agent checkpoint rollback: restore/fork must have health, state hash, post-restore VFS operation evidence, and no mixed-generation oracle.
- Do not claim to replace CRIU, VM snapshotting, or memory snapshots.

### Fork optimization

On-demand-fork optimizes process creation by reducing fork latency for memory-intensive workloads. It reports end-to-end gains on applications such as SQLite, Redis, and AFL.

Source:

- On-demand-fork paper: https://sishuaigong.github.io/pdf/eurosys21-odf.pdf

Relevance:

- Shows that systems papers can make fork a first-class metric when fork latency is central to the workload.
- Provides a comparison point for "fork/fanout" terminology.

Boundary:

- It optimizes process address-space fork; `namei_ext` targets workspace/path-view fork.
- It is not a direct baseline unless the benchmark includes process forking cost.

Paper angle:

- Mention only if using "fork" terminology heavily; otherwise avoid confusion by saying workspace fork/fanout.

## Category 4: File-system trace replay and benchmark methodology

### Replayfs and TBBT

Replayfs and TBBT are classic trace replay systems. Replayfs argues that VFS-level replay is appropriate for file-system evaluation. TBBT shows that file-system traces are stateful: replay may require repairing missing operations and reconstructing a filesystem image.

Sources:

- Replayfs / Accurate and Efficient Replaying of File System Traces: https://www.usenix.org/conference/fast-05/accurate-and-efficient-replaying-file-system-traces
- Replayfs project page: https://www.filesystems.org/docs/replayfs/index.html
- TBBT: https://www.usenix.org/conference/fast-05/tbbt-scalable-and-accurate-trace-replay-file-server-evaluation
- TBBT HTML: https://www.usenix.org/legacy/events/fast05/tech/full_papers/zhu/zhu_html/tbbt_fast05_html.html

Relevance:

- Provides method justification for collecting file-operation evidence.
- Explains why raw syscall trace replay should not be our main workload driver.

Boundary:

- Historical traces are not coding-agent workloads.
- The replay mechanisms are full trace replay systems; `namei_ext` should not inherit that burden.

Paper angle:

- Cite these papers to justify the split: command trace drives workload; file-op trace validates path behavior.

### Filebench

Filebench is a flexible filesystem workload generator with macro workload personalities.

Sources:

- Filebench repository: https://github.com/filebench/filebench
- Filebench discussion in USENIX login: https://www.usenix.org/system/files/login/articles/login_spring16_02_tarasov.pdf

Relevance:

- Useful as background for filesystem benchmarking.
- Could be an appendix stress generator.

Boundary:

- Synthetic workload generator, not real agent sandbox behavior.
- Should not be a main OSDI workload for the agent use case.

Paper angle:

- Mention only if reviewers ask why not use synthetic filesystem benchmarks; answer: we use real command traces and retain synthetic stress only for appendix.

## Category 5: User-space filesystem and materialized-view baselines

### FUSE and optimized FUSE variants

FUSE is the strongest feature-equivalent programmable path-remapping baseline. "To FUSE or Not to FUSE" analyzes FUSE overhead, CPU cost, and workload sensitivity. DEFUSE, Direct-FUSE, and related work optimize user-space filesystem access, but still sit in the user-space filesystem design space.

Sources:

- FUSE kernel docs: https://docs.kernel.org/filesystems/fuse.html
- To FUSE or Not to FUSE: https://www.usenix.org/system/files/conference/fast17/fast17-vangoor.pdf
- DEFUSE: https://dl.acm.org/doi/10.1145/3494556
- Direct-FUSE: https://www.osti.gov/servlets/purl/1458703

Relevance:

- FUSE is the direct programmable user-space path-view competitor.
- Our evaluation already treats FUSE as the primary programmable baseline; this is correct.

Boundary:

- `namei_ext` is not a filesystem and does not own file data operations.
- We cannot claim broad superiority over FUSE unless every relevant row passes the declared FUSE speedup threshold. Current evidence only supports the tool-redirect slice and W2 setup/materialization slice.

Paper angle:

- Position `namei_ext` as narrower than FUSE: it adds programmable name-resolution decisions while leaving VFS/lower filesystem ownership intact.

### OverlayFS, copy, bind, symlink, and projected volumes

OverlayFS, copy trees, bind mounts, symlink forests, and projected volumes are important materialized or kernel-provided baselines.

Sources:

- Linux OverlayFS docs: https://docs.kernel.org/filesystems/overlayfs.html
- Docker overlay2 docs: https://docs.docker.com/engine/storage/drivers/overlayfs-driver/
- Kubernetes projected volumes: https://kubernetes.io/docs/concepts/storage/projected-volumes/
- Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Docker Compose secrets: https://docs.docker.com/compose/how-tos/use-secrets/

Relevance:

- They are strong baselines because they are common, mature, and often fast.
- Projected volumes/secrets directly motivate the W2 service fixture sandbox.
- OverlayFS/copy-up behavior is relevant to workspace fork/rollback baselines.

Boundary:

- These mechanisms can beat `namei_ext` for some workloads; current W1/W3/W4 negative results confirm that.
- We should not claim "materialization is always worse."

Paper angle:

- Keep them as first-class baselines, not strawmen.
- Use current negative results to show the paper is scoped honestly.

## Category 6: Access-control, event, and kernel-observability interfaces

### Landlock, BPF LSM, fanotify, and fsnotify

Landlock is an unprivileged sandboxing/access-control mechanism. BPF LSM lets privileged users attach eBPF programs to LSM hooks for MAC/audit policies. fanotify/fsnotify provide notification or interception of filesystem events.

Sources:

- Landlock kernel docs: https://docs.kernel.org/userspace-api/landlock.html
- BPF LSM kernel docs: https://docs.kernel.org/bpf/prog_lsm.html
- fanotify man page: https://man7.org/linux/man-pages/man7/fanotify.7.html
- Linux pathname lookup docs: https://www.kernel.org/doc/html/latest/filesystems/path-lookup.html

Relevance:

- Important to explain what `namei_ext` is not.
- These interfaces can observe, allow, deny, or notify, but they do not provide a narrow policy hook that redirects lookup/readdir path resolution while leaving lower filesystems in control.

Boundary:

- Do not describe `namei_ext` as a security sandbox or access-control replacement.
- BPF LSM is related as a BPF-in-kernel policy interface, not as a path-view mechanism.

Paper angle:

- "Unlike access-control and notification mechanisms, `namei_ext` changes which backing component a path resolves to under a restricted decision API."

## Category 7: Build and cache systems

### BuildKit, ccache, Bazel, and build caches

Build systems and compiler/package caches motivate content-verified cache views. BuildKit cache mounts provide persistent caches during image builds; ccache supports local and remote storage; Bazel remote caching uses action graphs and cache hits to reuse build outputs.

Sources:

- Docker BuildKit cache docs: https://docs.docker.com/build/cache/optimize/
- ccache manual: https://ccache.dev/manual/4.13.6.html
- Bazel remote caching: https://bazel.build/remote/caching
- Bazel remote cache overview: https://queue.acm.org/detail.cfm?id=3287302

Relevance:

- Provides real cache-path workloads for W4.
- Shows path-class/stateful cache semantics are real: cache hits, misses, local/remote storage, package caches, action outputs.

Boundary:

- Current W4 is not yet a positive result. Existing W4 ccache bulk setup wins in one dimension but update loses; table-only and materialized baselines remain strong.
- We should not claim cache view necessity until operation-weighted stale/corrupt/update-window and table-budget evidence exists.

Paper angle:

- Use W4 as either a mixed/negative case or redesign it around a stronger BuildKit/cache workload with native/cache-remap baselines.

## Category 8: Programmable kernel extension points

### sched_ext and eBPF policy interfaces

sched_ext shows a Linux pattern where eBPF can express constrained kernel policy while the kernel owns safety and object lifetime. BPF LSM shows another policy hook family, but it is security-focused.

Sources:

- sched_ext docs: https://docs.kernel.org/scheduler/sched-ext.html
- BPF LSM docs: https://docs.kernel.org/bpf/prog_lsm.html

Relevance:

- Helps explain the `namei_ext` design philosophy: one narrow decision hook, verifier-constrained policies, kernel-owned objects.

Boundary:

- sched_ext is a scheduler, not filesystem/path-resolution work.
- We need workload-specific VFS evidence, not just analogy.

Paper angle:

- Use sched_ext as architectural precedent, not as a baseline.

## Missing related-work coverage in current paper draft

The existing `docs/paper/sections/06-related-work.tex` covers:

- FUSE and optimized filesystem extension frameworks.
- OverlayFS/materialized kernel view mechanisms.
- Landlock/BPF LSM/fanotify.
- sched_ext-style eBPF policy extension.

It does not yet cover:

- SWE-bench/SWE-bench Pro and command-trace workload provenance.
- SWE-agent/OpenHands/Open-SWE-Traces/TerminalWorld trajectory datasets.
- Agent sandbox products: E2B, Modal, Daytona, Codex.
- Serverless snapshot/fork systems: FaaSnap, REAP/vHive, Pronghorn, SEUSS, Sabre, remote fork.
- File-system trace replay methodology: Replayfs, TBBT, Filebench.
- Build/cache systems: BuildKit, ccache, Bazel remote caching.

These gaps matter only if the paper story pivots to agent sandbox lifecycle. If the paper stays as the current scoped W2/tool-redirect paper, the related-work section can remain narrower.

## Recommended related-work structure for a revised paper

1. Agent execution benchmarks and traces.
   - SWE-bench/SWE-bench Pro, trajectories, Terminal-Bench/TerminalWorld.
   - Distinguish task provenance from systems trace evidence.

2. Agent sandbox runtimes and snapshot products.
   - E2B, Modal, Daytona, Codex.
   - Motivate sandbox lifecycle; distinguish from security/runtime platform claims.

3. Snapshot/fork/restore systems.
   - FaaSnap, REAP/vHive, Pronghorn, SEUSS, Sabre, remote fork.
   - Explain why real restore claims need restore health and post-restore operations.

4. File-system trace replay and benchmarking.
   - Replayfs, TBBT, Filebench.
   - Justify command replay plus file-operation evidence.

5. Filesystem view and user-space filesystem baselines.
   - FUSE, OverlayFS, copy/bind/symlink/projected volumes.
   - Explain why these are strong baselines.

6. Access-control/event interfaces and eBPF policy hooks.
   - Landlock, BPF LSM, fanotify, sched_ext.
   - Distinguish allow/deny/notify from path-resolution redirect.

7. Build/cache systems.
   - BuildKit, ccache, Bazel remote caching.
   - Include only if W4 remains in the main story.

## Consequences for claims

The related work pushes the paper toward conservative claims:

- Agent sandbox lifecycle should be evaluated with fixed command traces and self-collected file-operation evidence.
- FUSE must remain the main programmable baseline.
- OverlayFS/copy/git-worktree/materialized views must remain first-class baselines for workspace fork/rollback.
- Current W3 Redis replay should not be called restore related work evidence.
- Current W4 should remain mixed/negative unless rebuilt against stronger cache baselines.
- C8 table-only insufficiency remains a future claim unless table/update/stale-window evidence becomes positive.

## Immediate follow-up

If the paper pivots to this story, update `docs/paper/sections/06-related-work.tex` only after the evaluation scope is frozen. The safer next step is to implement the agent command-trace pilot first, because the final related-work wording depends on whether SWE-bench Pro Docent trajectories are exportable and whether the KVM command replay produces positive evidence.
