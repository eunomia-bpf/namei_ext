# AgentCgroup Workload Reproduction

Date: 2026-07-02

## Motivation

AgentCgroup is listed as a direct workload seed because it studies
tool-call-granularity resource behavior for AI coding agents over SWE-rebench
tasks. For `namei_ext`, it is useful as trace and operation-boundary evidence:
tool calls, command phases, resource hints, and per-tool-call lifecycle events
can shape an agent workspace workload. It is not a filesystem baseline and
should not be cited as proof that a workload requires eBPF or `namei_ext`.

## Source

- Official repository: <https://github.com/eunomia-bpf/agentcgroup>
- Local checkout: `.cache/source-inspection/agentcgroup`
- Commit: `5af9e7b8f37a93513206c331c7ec0ff149e89f27`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/agentcgroup/`

The checkout was already dirty before this run from generated analysis figures.
Those files were not cleaned or reverted. This run records new raw logs under
the result root above.

## Commands

Environment and source inspection:

```sh
git -C .cache/source-inspection/agentcgroup rev-parse HEAD
git -C .cache/source-inspection/agentcgroup status --short
python3 --version
uv --version
clang --version
gcc --version
bpftool version
```

Dependency setup:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
uv venv /home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
uv pip install --python /home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup/bin/python \
  -r requirements.txt
```

The first characterization attempt failed with latest Matplotlib because the
upstream script uses `Axes.boxplot(labels=...)`, which newer Matplotlib no
longer accepts. The failure is preserved in `characterization-fast.log`. The
compatibility rerun installed `matplotlib<3.10`, resolving to Matplotlib 3.9.4:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
uv pip install --python /home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup/bin/python \
  'matplotlib<3.10'
```

Reproduction commands:

```sh
cd .cache/source-inspection/agentcgroup/agentcg
/home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup/bin/python \
  -m unittest test_agentcgroupd -v
bash test_bash_wrapper.sh
/home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup/bin/python \
  test_integration.py -v
make
make memcg

cd .cache/source-inspection/agentcgroup
/home/yunwei37/workspace/namei_ext/.cache/venvs/agentcgroup/bin/python \
  analysis/characterization.py --skip-extended --skip-rq
```

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/agentcgroup/summary.json`.

Positive evidence:

- `test_agentcgroupd`: 43 tests passed, 0 failed.
- `test_bash_wrapper.sh`: 14 tests passed, 0 failed.
- `test_integration.py`: 4 tests passed, 0 failed. The integration test drives
  a trace-derived memory-pressure timeline, activates high-session protection,
  throttles low cgroups, and restores defaults in a tmpdir cgroup simulation.
- `analysis/characterization.py --skip-extended --skip-rq`: passed after the
  explicit Matplotlib compatibility pin. It loaded 33 Haiku tasks and 111 local
  tasks, and reported 43 Haiku figures, 42 Qwen/local figures, and 34
  comparison figures.
- `make` under `agentcg/`: passed for the scheduler and process monitor
  components.

Negative or boundary evidence:

- `make memcg` failed. `memcg_priority.bpf.c` cannot instantiate
  `struct memcg_bpf_ops` because the running kernel BTF exposes it only as an
  incomplete type. This is a host kernel capability boundary, not a missing
  Python dependency.
- `test_live_agent.sh` was not run because it depends on live Claude Code/API
  behavior and is not a deterministic no-credential reproduction.
- `test_e2e_cgroup.sh` was not run because it requires root and writes under
  `/sys/fs/cgroup`; this pass kept to non-root local reproduction plus BPF
  builds.

## Workload Shapes Reproduced

AgentCgroup contributes:

- per-tool-call bash wrapper boundaries with JSONL command, duration, memory,
  resource hint, exit status, and ephemeral cgroup path;
- trace-derived pressure timelines over SWE-rebench-style coding-agent tasks;
- operation-weighted tool-call/resource phases that can guide agent workspace
  workload selection;
- process/scheduler BPF build evidence for OS-level agent-resource
  instrumentation.

## Use In `namei_ext`

Use AgentCgroup as an operation-boundary and trace source for the first
Make-owned KVM AI agent workspace lifecycle workload. The useful adaptation is
not its resource controller itself; it is the workload shape: agent tool calls
with command boundaries, workspace state, resource phase changes, and
operation-weighted behavior.

Do not use AgentCgroup as a filesystem baseline. Do not claim full
`memcg_bpf_ops` reproduction on this host. Do not claim that AgentCgroup's
workloads require eBPF path-resolution policy.
