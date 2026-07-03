# SWE-MiniSandbox Workload Reproduction

Date: 2026-07-02

## Motivation

SWE-MiniSandbox is a direct workload seed for the AI agent workspace lifecycle
because it targets container-free, many-agent software-engineering sandboxes.
For `namei_ext`, the useful workload shape is per-agent workspace setup and
private path-state isolation, especially private `/tmp` behavior under
concurrent sandboxes.

This record is intentionally scoped to the core MiniSandbox `sandboxdev`
workload. The repository vendors or modifies several larger systems
(`SWE-agent`, `SWE-ReX`, `SWE-bench`, `SWE-smith`, `SkyRL`, `R2E-Gym`), but
passing this record does not mean those full nested pipelines were reproduced.

## Source

- Official repository: <https://github.com/lblankl/SWE-MiniSandbox>
- Local checkout: `.cache/source-inspection/swe-minisandbox`
- Commit: `381ada53ab35dadb342add33ff006f3157c22fb7`
- Raw result root:
  `results/reproduction/2026-07-02-official-workloads/swe-minisandbox/`

The checkout was already dirty before this run from earlier editable install
metadata and Python bytecode. Those files were not cleaned or reverted.

## Commands

Environment and source inspection:

```sh
git -C .cache/source-inspection/swe-minisandbox rev-parse HEAD
git -C .cache/source-inspection/swe-minisandbox status --short
python3 --version
uv --version
```

Dependency setup:

```sh
UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
uv venv /home/yunwei37/workspace/namei_ext/.cache/venvs/swe-minisandbox

UV_CACHE_DIR=/home/yunwei37/workspace/namei_ext/.cache/uv-cache \
uv pip install --python /home/yunwei37/workspace/namei_ext/.cache/venvs/swe-minisandbox/bin/python \
  -e sandboxdev pytest pydantic typing_extensions
```

Test and smoke commands:

```sh
/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-minisandbox/bin/python \
  -m pytest tests/test_tmpfs_tmp_isolation.py --collect-only -q

/home/yunwei37/workspace/namei_ext/.cache/venvs/swe-minisandbox/bin/python \
  -m pytest tests/test_tmpfs_tmp_isolation.py -q -s
```

An additional API smoke instantiated `SandboxDeployment` with minimal state and
inspected the generated `startup_old()` command.

## Result

Machine-readable summary:
`results/reproduction/2026-07-02-official-workloads/swe-minisandbox/summary.json`.

Positive evidence:

- pytest collected four tests from `tests/test_tmpfs_tmp_isolation.py`.
- all four tests passed.
- the covered oracles are:
  - `startup_old()` must not bind-mount host `/tmp`;
  - `startup_old()` must mount a private tmpfs on sandbox `/tmp`;
  - the private tmpfs mount must be generated before `chroot`;
  - concurrent sandboxes must not see each other's `/tmp` contents.
- the API smoke confirmed `has_private_tmpfs=true` and `binds_host_tmp=false`.

## Boundaries

This run does not reproduce full RL training, full modified SWE-agent rollout,
full R2E-Gym, full SWE-bench/SWE-smith dataset generation, or live agent
evaluation. Those are broader nested systems in the repository. The reproduced
workload here is the core MiniSandbox sandbox setup/isolation behavior.

## Workload Shapes Reproduced

SWE-MiniSandbox contributes:

- per-sandbox root directory setup;
- mount namespace plus chroot startup command generation;
- private `/tmp` tmpfs per sandbox rather than shared host `/tmp`;
- concurrent sandbox isolation oracle for many-agent workspace setup.

## Use In `namei_ext`

Use SWE-MiniSandbox as a many-agent sandbox setup and private-workspace
isolation workload seed. The natural `namei_ext` adaptation is not to reproduce
its full RL stack, but to model agent-visible workspace/session path views and
concurrent private-path behavior, then compare against source-system behavior,
materialized views, FUSE/source-system filesystems, or native namespace setup
where appropriate.

Do not claim that SWE-MiniSandbox's workload requires eBPF path-resolution
policy, and do not describe the four-test subset as full SWE-MiniSandbox
pipeline reproduction.
