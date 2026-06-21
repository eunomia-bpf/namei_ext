# Agent Command Trace Workload Survey

## Motivation

This note records the search for public agent traces and command traces that could support an OSDI-grade `namei_ext` agent sandbox lifecycle benchmark. The design goal is to avoid live LLM variance: the workload input should be fixed commands or fixed harness actions, while `namei_ext` evidence should come from the file-system behavior observed when those commands run.

## Short answer

There are usable public command/agent trajectory sources, but they are not the same as path-level VFS traces.

- SWE-bench and SWE-bench Pro provide reproducible issue-resolution tasks, base commits, patches, tests, and Docker/harness metadata. They do not provide the path-level syscall trace needed to prove `namei_ext` path-view behavior.
- SWE-bench Pro also publishes public trajectory views through Docent from the public leaderboard. These are useful for inspecting and potentially mining agent command traces, but they should not be considered a reproducible local artifact until export/API access is confirmed.
- SWE-agent, OpenHands, and SWE-bench experiment submissions provide agent trajectories with actions, observations, patches, and logs. These can seed command traces, but formats vary and should not be treated as canonical syscall evidence.
- TerminalWorld is the closest public command-trace-like source outside SWE-bench: it derives terminal tasks from public terminal recordings and releases deterministic task artifacts, Docker environments, reference solutions, and tests. It is useful as a command-workload control, but it is not a SWE-bench patch-and-test workload.

The recommended paper design is therefore: fixed command trace as workload input, plus self-collected file-operation trace as evidence.

## Directly usable trace candidates

Current ranking after the search:

1. SWE-bench Pro public tasks plus Docent trajectories, if export is available.
2. Open-SWE-Traces or Nebius SWE-agent trajectories, if a public SWE-bench Pro-specific export is not available.
3. Terminal-Bench/TerminalWorld command traces as a terminal-control workload.
4. SWE-ZERO-style execution-free trajectories only for command distribution analysis, not correctness.

The first usable artifact should still be normalized into our own command-trace schema before benchmarking.

### SWE-bench Pro trajectories via Docent

The Scale Labs public SWE-bench Pro page has a `View trajectories` link to Docent. The page also describes the benchmark construction, public/private/held-out split, Docker-based environment creation, fail-to-pass and pass-to-pass tests, and standardized evaluation. Docent documentation says transcripts and agent-run metadata can be exported locally with DQL.

Sources: [SWE-bench Pro public leaderboard](https://labs.scale.com/leaderboard/swe_bench_pro_public), [SWE-bench Pro Docent trajectory collection](https://docent.transluce.org/dashboard/032fb63d-4992-4bfc-911d-3b7dafcb931f/), and [Docent export documentation](https://docs.transluce.org/analysis/exporting).

Assessment:

- This is the most attractive source because it is tied to SWE-bench Pro public tasks.
- It likely contains real agent transcripts, tool calls, commands, observations, and submitted patches.
- The web UI is not by itself enough for an artifact. We need an export path that does not require private credentials or manual browser work.
- Even if exported, these are agent trajectories, not path-level VFS traces.

Use in our benchmark:

- First check whether the Docent collection can be exported with public access.
- If yes, mine command sequences, submitted patches, and test commands for the same 731 public tasks.
- If no, cite these only as motivation and use other public trajectory datasets for command distribution.

### Open-SWE-Traces

NVIDIA's Open-SWE-Traces dataset contains 207,489 agent trajectories collected with SWE-agent and OpenHands, synthesized using Minimax-M2.5 and Qwen3.5-122B-A10B. The dataset covers SWE-bench-style tasks sourced from SWE-rebench-V2 and reports language distributions for Python, Go, TypeScript, JavaScript, and Rust.

Source: [nvidia/Open-SWE-Traces](https://huggingface.co/datasets/nvidia/Open-SWE-Traces).

Assessment:

- Strong candidate for direct command/action trajectory mining.
- More language-diverse than classic SWE-bench Verified.
- It is not specifically SWE-bench Pro public, so task identity and harness parity must be checked.
- It is still not syscall evidence.

Use in our benchmark:

- Mine command patterns and edit/test loop shapes.
- Prefer trajectories with resolved status and available repository/task metadata.
- Rerun a selected subset under our KVM harness before using it for paper evidence.

### Nebius SWE-agent trajectories

The Nebius SWE-agent trajectory dataset contains 80,036 trajectories generated with SWE-agent. The dataset structure includes a JSON trajectory, exit status, generated patch, and eval logs. The card reports issue resolution statistics and step counts.

Source: [nebius/SWE-agent-trajectories](https://huggingface.co/datasets/nebius/SWE-agent-trajectories).

Assessment:

- Good source for SWE-agent-style commands and observations.
- Has generated patches and eval logs, which makes filtering easier.
- Task source is SWE-bench Extra and SWE-bench dev, not SWE-bench Pro.

Use in our benchmark:

- Use as a direct command trace source if SWE-bench Pro trajectories are not exportable.
- Filter to resolved rows and commands that replay under our pinned Docker/KVM setup.

### SWE-ZERO 12M trajectories

SWE-ZERO 12M trajectories follow a mini-swe-agent v1 format where the assistant issues one bash command per turn and the harness returns command output. The dataset card explicitly says generation is execution-free: no container is built, no test is executed, and no verifier is consulted.

Source: [AlienKevin/SWE-ZERO-12M-trajectories](https://huggingface.co/datasets/AlienKevin/SWE-ZERO-12M-trajectories).

Assessment:

- Very large command-style corpus.
- Bad fit for correctness because commands were not executed or verified.
- Useful only for command distribution, not as a paper workload source.

Use in our benchmark:

- Do not use as main evidence.
- Use only to shape command-mix stress tests if needed.

### Terminal-Bench trajectories

Terminal-Bench 2.0 trajectories contain complete step-by-step traces of messages, tool calls, and observations. The dataset has 52,104 trajectories over 89 tasks, with per-row `steps` JSON.

Source: [yoonholee/terminalbench-trajectories](https://huggingface.co/datasets/yoonholee/terminalbench-trajectories).

Assessment:

- Directly usable as command/tool-call trajectories.
- Not SWE-bench-style patch-and-test tasks.
- Good for a terminal-control workload or appendix.

Use in our benchmark:

- Use only as a control if we want a command-heavy non-SWE benchmark.
- Do not use to replace SWE-bench Pro in the main agent sandbox lifecycle result.

### LMCache agentic traces

The LMCache agentic traces dataset provides sessions from SWE-bench Verified, GAIA, and WildClaw, designed for inference/KV-cache benchmarking. It describes SWE-bench sessions as read-code, write-patches, run-tests, and debug-failure loops, with 5-50 turns.

Source: [sammshen/lmcache-agentic-traces](https://huggingface.co/datasets/sammshen/lmcache-agentic-traces).

Assessment:

- Useful evidence that fixed agent traces are already used to avoid rerunning agents for systems benchmarking.
- Small for our filesystem workload needs.
- Format is optimized for inference benchmarking, not filesystem command replay.

Use in our benchmark:

- Cite as related benchmark methodology.
- Do not use as the main command source.

## Sources checked

### SWE-bench harness

The SWE-bench harness is Docker-based and explicitly sets up environments, applies patches, runs tests, and grades results. The harness documentation describes layered Docker images, `run_evaluation`, patch application, test execution, and logs under `logs/run_evaluation`.

Source: [SWE-bench harness reference](https://www.swebench.com/SWE-bench/reference/harness/).

Assessment:

- Good source for reproducible task execution.
- Good source for fixed command phases: setup, apply patch, run tests, report.
- Not a source of agent command traces by itself.
- Not a source of path-level syscall traces.

Use in our benchmark:

- Use the harness as the canonical way to materialize a fixed task and run tests.
- Add our own command logging and file-operation tracing around harness phases.
- Treat harness output as the correctness oracle, not as the performance metric.

### SWE-bench Verified

SWE-bench Verified is a human-filtered subset of 500 instances. The public page says annotators reviewed clarity, test patches, and solvability.

Source: [SWE-bench Verified](https://www.swebench.com/verified.html).

Assessment:

- Best pilot source because the tasks are smaller and human-vetted.
- Good for validating the trace collector and replay pipeline before scaling.
- Less representative of large multi-file professional tasks than SWE-bench Pro.

Use in our benchmark:

- Use 10-30 Verified tasks for first end-to-end command replay.
- Gate the pilot on reproducible harness pass/fail and path classification coverage.

### SWE-bench Pro

SWE-bench Pro contains 1,865 tasks, with a public subset of 731 rows on Hugging Face. The public dataset exposes fields such as `repo`, `instance_id`, `base_commit`, `patch`, `test_patch`, `fail_to_pass`, `pass_to_pass`, `before_repo_set_cmd`, `selected_test_files_to_run`, and `dockerhub_tag`. The paper describes long-horizon, multi-file, professional tasks and released pre-built Docker images.

Sources: [SWE-bench Pro dataset](https://huggingface.co/datasets/ScaleAI/SWE-bench_Pro) and [SWE-bench Pro paper](https://arxiv.org/pdf/2509.16941).

Assessment:

- Best candidate for the final agent sandbox lifecycle workload source.
- Stronger path/dependency/cache diversity than SWE-bench Verified.
- Public subset is reproducible enough for an artifact; held-out/commercial subsets should not be main evidence.
- It still does not provide path-level syscall traces.

Use in our benchmark:

- Use public tasks only.
- Filter tasks by reproducibility, runtime budget, repo/language diversity, and path activity.
- Use `before_repo_set_cmd`, selected test files, Docker image tag, base commit, patch, and test patch as workload provenance.

### SWE-bench experiments repository

The SWE-bench experiments repository stores public submissions. Its README says a submission can contain predictions, results, execution logs, and trajectories. It also says trajectories are intentionally not strictly formatted; they are human-readable reasoning traces reflecting intermediate steps.

Source: [SWE-bench experiments](https://github.com/swe-bench/experiments).

Assessment:

- Useful as evidence that the community values trajectories and logs for reproducibility.
- Useful for mining example agent command sequences when a submission includes structured `.traj` files.
- Weak as canonical input because trajectory format is non-specific and may mix reasoning, tool calls, observations, and post-hoc text.
- Download flow can depend on public S3/AWS tooling.

Use in our benchmark:

- Optional source for seed command traces.
- Do not make it the only source of workload provenance.
- Normalize mined traces into our own command-trace schema before use.

### SWE-agent trajectories

SWE-agent documents `<instance_id>.traj` JSON files containing turns with `thought`, `action`, `observation`, and state such as `working_dir`. The example includes shell-like actions such as `ls -F`, `open setup.py`, and `pip install -e .[dev]`.

Source: [SWE-agent trajectory documentation](https://swe-agent.com/latest/usage/trajectories/).

Assessment:

- Good command/action trace source when actions are shell commands or tool invocations.
- Contains enough information to reconstruct high-level command phases in many cases.
- Not guaranteed to be deterministic across model/framework versions.
- Not sufficient for file-system correctness because observations are text, not VFS-level outcomes.

Use in our benchmark:

- Mine successful trajectories for realistic command sequences.
- Canonicalize into shell commands, cwd, environment, timeout, expected exit status, and phase.
- Rerun commands under our harness and collect fresh file-operation evidence.

### OpenHands/Nebius trajectories

The Nebius OpenHands dataset has 67,074 rows. The dataset schema includes `trajectory_id`, `instance_id`, `repo`, `trajectory`, `tools`, `model_patch`, `exit_status`, and `resolved`. The card describes complete multi-turn agent trajectories with actions and environmental observations for real GitHub issues.

Source: [nebius/SWE-rebench-openhands-trajectories](https://huggingface.co/datasets/nebius/SWE-rebench-openhands-trajectories).

Assessment:

- Large public source of structured tool-call trajectories.
- Better scale than single leaderboard submissions.
- Useful for mining command/action distributions and realistic repeated edit/test loops.
- It is not SWE-bench Pro, and it does not release path-level VFS traces.

Use in our benchmark:

- Use as a secondary source for command-pattern selection, not as primary correctness evidence.
- Extract shell tool calls, cwd if available, and submit/exit status.
- Rerun a filtered subset in our controlled environment before using any command trace in the paper.

### TerminalWorld

TerminalWorld reverse-engineers benchmark tasks from public terminal recordings. Its README says it processed 80,870 asciinema recordings, synthesized `instruction.md` and `solve.sh`, reproduced Docker environments, and validated 1,530 tasks with tests. The Hugging Face dataset exposes task IDs, instructions, artifact paths, terminal domains, and source type `public_terminal_recording`.

Sources: [TerminalWorld repository](https://github.com/EuniAI/TerminalWorld) and [TerminalWorld dataset](https://huggingface.co/datasets/EuniAI/TerminalWorld).

Assessment:

- Closest available public command-trace-like corpus.
- The reference solution `solve.sh` is a deterministic command script derived from an in-the-wild terminal recording.
- Docker/test artifacts are designed for reproducibility.
- Not specifically a coding-agent patch-and-test workload.
- License and task domains must be checked before inclusion in artifact.

Use in our benchmark:

- Use as an optional control workload for command-heavy sandbox lifecycle operations.
- Good for testing workspace materialization, dependency/cache path handling, and rollback across terminal tasks.
- Do not substitute it for SWE-bench Pro if the paper claim is about coding-agent sandbox lifecycle.

### File-system trace replay literature

FAST file-system trace replay work is useful methodologically. Replayfs argues that VFS-level replay provides a reproducible way to apply real workloads to file systems. TBBT shows that file-system replay is stateful and needs an initial filesystem image plus repair of missing operations.

Sources: [Replayfs / Accurate and Efficient Replaying of File System Traces](https://www.filesystems.org/docs/replayfs/index.html), [USENIX abstract](https://www.usenix.org/conference/fast-05/accurate-and-efficient-replaying-file-system-traces), and [TBBT](https://www.usenix.org/conference/fast-05/tbbt-scalable-and-accurate-trace-replay-file-server-evaluation).

Assessment:

- Important caution: replaying raw syscalls as workload input is hard because filesystem state and missing dependencies matter.
- This supports using command traces as workload input and collecting path traces as evidence, rather than trying to make syscall replay the main benchmark.

Use in our benchmark:

- Cite this literature to justify command-level replay plus file-op evidence.
- Keep path-level trace replay as a diagnostic or appendix, not the main workload driver.

## Suitability matrix

| Source | Has fixed task? | Has command/action trace? | Has Docker/harness? | Has path-level syscall trace? | Good for main workload? |
|---|---:|---:|---:|---:|---|
| SWE-bench Verified | yes | no | yes | no | pilot |
| SWE-bench Pro public | yes | harness commands + Docent trajectories if exportable | yes | no | yes |
| Open-SWE-Traces | yes | yes | depends on source task | no | secondary/main fallback |
| Nebius SWE-agent trajectories | yes | yes | eval logs present | no | secondary |
| SWE-ZERO 12M trajectories | yes | yes, one bash command per turn | no executed harness | no | command-distribution only |
| SWE-bench experiments | yes | sometimes | logs only | no | secondary |
| SWE-agent trajectories | yes | yes | depends on run | no | secondary |
| Nebius OpenHands trajectories | yes | yes | join via source dataset | no | secondary |
| Terminal-Bench trajectories | yes | yes | benchmark-dependent | no | control |
| TerminalWorld | yes | reference `solve.sh` | yes | no | control |
| Replayfs/TBBT traces | yes, historical traces | N/A | N/A | yes, but not agent/SWE | methodology only |

## Recommended benchmark design

### Thesis

`namei_ext` reduces path-view setup, fork, rollback, and workspace materialization cost for deterministic coding-agent sandbox lifecycle command traces, while preserving command-level correctness and observed path-view behavior.

This is not a claim that agents solve more tasks. It is a systems claim about the sandbox filesystem operations around agent workflows.

### Workload input

The workload input should be a normalized command trace:

```json
{
  "task_id": "instance_qutebrowser__qutebrowser-...",
  "source": "swe_bench_pro_public",
  "repo": "qutebrowser/qutebrowser",
  "base_commit": "...",
  "docker_image": "...",
  "patch_sha256": "...",
  "test_patch_sha256": "...",
  "commands": [
    {
      "phase": "reset",
      "cwd": "/workspace/repo",
      "argv": ["git", "reset", "--hard", "<base_commit>"],
      "env": {},
      "stdin_sha256": null,
      "timeout_s": 60,
      "expected_exit": 0
    },
    {
      "phase": "apply_patch",
      "cwd": "/workspace/repo",
      "argv": ["git", "apply", "/inputs/model.patch"],
      "env": {},
      "stdin_sha256": null,
      "timeout_s": 60,
      "expected_exit": 0
    },
    {
      "phase": "test",
      "cwd": "/workspace/repo",
      "argv": ["pytest", "..."],
      "env": {},
      "stdin_sha256": null,
      "timeout_s": 1800,
      "expected_exit": 0
    }
  ]
}
```

The source of commands can be:

1. Harness-derived commands from SWE-bench Pro/Verified.
2. Successful SWE-agent/OpenHands trajectories after normalization.
3. TerminalWorld `solve.sh` only as a control.

### Evidence collected during command replay

During replay, collect file-operation evidence. This is not the workload input; it is the raw evidence and oracle input.

Required fields:

- command phase and command ID;
- pid/tid/process tree;
- cwd and exec path;
- path operation type: lookup/open/stat/access/exec/readdir/rename/unlink/mkdir/symlink/link;
- normalized absolute path;
- return value and errno;
- optional content/hash sample for declared oracle paths;
- path class: workspace, patch, test, deps, cache, build output, temp, runtime state, hidden checkpoint, unknown.

### Path classes

The paper should define path classes before running the benchmark:

| Class | Meaning | Example |
|---|---|---|
| workspace | repository source and checked-out task files | `src/...`, `tests/...` |
| patch | generated or candidate patch input | `/inputs/model.patch` |
| test | selected fail/pass tests and test data | `tests/unit/...` |
| deps | language package environment | `.venv`, `node_modules`, Go module cache |
| cache | build/test/tool caches | `.pytest_cache`, `__pycache__`, `ccache`, npm cache |
| output | build/test outputs | `build/`, `dist/`, `.tox/` |
| state | rollback/checkpoint generation state | `.namei-gen-*` or hidden backing |
| temp | short-lived temp files | `/tmp/...` |

### `namei_ext` operations to test

The agent sandbox lifecycle use case should have three sub-experiments:

1. Workspace fork/fanout: create many task sandboxes from the same base repository state.
2. Checkpoint rollback/restore: run edit/test commands, roll back to a prior generation, and rerun a fixed suffix of the command trace.
3. Dependency/cache path view: redirect selected deps/cache/output paths to generation-specific or shared backing while keeping workspace-visible paths stable.

Eval isolation is not included.

### Baselines

Feature-equivalent baselines:

- copy-tree workspace clone;
- git worktree or checkout/reset;
- OverlayFS if it can express the same visible workspace semantics;
- bind/symlink/projection only for the subcases they faithfully express;
- FUSE redirect for programmable user-space path remapping;
- native direct execution only as a lower-bound reference, not a feature-equivalent fork/rollback baseline.

### Correctness oracles

Each command trace replay must satisfy:

- command exit statuses match the expected phase outcome;
- final test result matches the source task expectation;
- workspace-visible file hashes match the expected generation after fork or rollback;
- no mixed-generation path events after rollback;
- lookup/readdir consistency holds for declared redirected directories;
- dmesg has no warning/oops/panic/hung-task signature;
- `namei_ext` policy hit counters show the relevant path classes were exercised.

### Metrics

Primary:

- setup latency for N sandboxes;
- created files, symlinks, mounts, bytes written, and storage footprint;
- rollback latency;
- update latency for generation switch or path-view change;
- command-trace execution time split by phase;
- metadata p50/p95/p99 for lookup/open/stat/access/readdir during replay;
- FUSE process/mount overhead when applicable.

Secondary:

- operation-weighted redirected hit rate;
- path-class distribution;
- cache/deps path reuse rate;
- CPU time, context switches, and page faults if C3/C5 performance claims are made.

## Run plan

### Pilot

Use SWE-bench Verified:

- choose 10 tasks across at least 3 repositories;
- use gold patches first to avoid candidate-patch ambiguity;
- run each task under native direct, copy-tree, git worktree, FUSE redirect, and `namei_ext`;
- collect command logs and file-op evidence;
- validate path classification coverage.

Success criterion:

- all tasks reproduce under the harness;
- command trace schema is stable;
- at least workspace, deps/cache, test, and output path classes appear;
- `namei_ext` policy hits occur during command replay, not only setup.

### Main

Use SWE-bench Pro public:

- choose 30-50 tasks, or enough to cover Python, JavaScript/TypeScript, and Go if local KVM resources allow;
- require public Docker image availability and runtime under the benchmark budget;
- prefer tasks with multi-file patches and non-trivial tests;
- include at least one successful candidate patch path and one gold patch path if candidate patches are used.

Success criterion:

- correctness passes for every included task and baseline;
- `namei_ext` setup or rollback cost is lower than feature-equivalent baselines by the declared threshold;
- FUSE remains the primary programmable user-space baseline;
- negative rows are preserved, not filtered out.

### Control

Use TerminalWorld verified subset:

- choose 10-20 terminal tasks with strong workspace/deps/cache behavior;
- use `solve.sh` as the command trace;
- treat this as a command-heavy control, not the main coding-agent sandbox result.

Success criterion:

- shows whether the mechanism generalizes beyond patch/test SWE workloads;
- does not replace SWE-bench Pro as the primary agent sandbox source.

## Why command trace is the right workload input

Path-level syscall replay would make fidelity harder, not easier. Filesystem traces are stateful; a syscall stream depends on cwd, fds, process timing, initial filesystem image, temp files, caches, and missing operations. Prior file-system replay work exists, but it is a separate system problem.

For this paper, the better split is:

- command trace drives the workload;
- file-op trace proves what the workload did and what `namei_ext` affected.

That design avoids LLM nondeterminism while preserving real command behavior.

## Claim boundaries

Allowed claim if experiments pass:

> For deterministic coding-agent sandbox lifecycle command traces derived from SWE-bench-style tasks, `namei_ext` reduces fork/rollback/path-view materialization cost while preserving command-level correctness and observed path-view consistency.

Not allowed:

- agents solve more tasks;
- hidden/eval isolation is provided;
- SWE-bench Pro trajectories already provide VFS traces;
- path-level syscall replay is the main benchmark input;
- all SWE-bench workloads benefit.

## Immediate next steps

1. Build a Make-owned command trace collector target for SWE-bench Verified gold-patch runs.
2. Normalize command phases into a JSONL schema under `results/`.
3. Collect path-operation evidence during command replay.
4. Implement a path-class classifier with fail-fast unknown-path budget.
5. Run a 3-task smoke across native/copy/git-worktree/FUSE/`namei_ext`.
6. Only after the smoke passes, select the SWE-bench Pro public main subset.

## References

- SWE-bench harness reference: https://www.swebench.com/SWE-bench/reference/harness/
- SWE-bench Verified: https://www.swebench.com/verified.html
- SWE-bench Pro dataset: https://huggingface.co/datasets/ScaleAI/SWE-bench_Pro
- SWE-bench Pro public leaderboard and trajectories: https://labs.scale.com/leaderboard/swe_bench_pro_public
- Docent export documentation: https://docs.transluce.org/analysis/exporting
- Open-SWE-Traces: https://huggingface.co/datasets/nvidia/Open-SWE-Traces
- Nebius SWE-agent trajectories: https://huggingface.co/datasets/nebius/SWE-agent-trajectories
- SWE-ZERO 12M trajectories: https://huggingface.co/datasets/AlienKevin/SWE-ZERO-12M-trajectories
- Terminal-Bench trajectories: https://huggingface.co/datasets/yoonholee/terminalbench-trajectories
- LMCache agentic traces: https://huggingface.co/datasets/sammshen/lmcache-agentic-traces
- SWE-bench Pro paper: https://arxiv.org/pdf/2509.16941
- SWE-bench experiments: https://github.com/swe-bench/experiments
- SWE-agent trajectories: https://swe-agent.com/latest/usage/trajectories/
- Nebius OpenHands trajectories: https://huggingface.co/datasets/nebius/SWE-rebench-openhands-trajectories
- TerminalWorld repository: https://github.com/EuniAI/TerminalWorld
- TerminalWorld dataset: https://huggingface.co/datasets/EuniAI/TerminalWorld
- Replayfs: https://www.filesystems.org/docs/replayfs/index.html
- TBBT: https://www.usenix.org/conference/fast-05/tbbt-scalable-and-accurate-trace-replay-file-server-evaluation
