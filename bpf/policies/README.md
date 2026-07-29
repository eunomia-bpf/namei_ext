# namei_ext Policies

A `namei_ext` policy is an eBPF program. Policy behavior belongs in
`*.bpf.c` files in this directory, not in YAML or JSON policy files.

Phase 1 policy roles:

- `pass_only.bpf.c`: attach/static-branch residual-overhead lower bound.
- `redirect_alias.bpf.c`: minimal regression policy for lookup and readdir
  REDIRECT behavior.
- `hide_secret.bpf.c`: minimal regression policy for lookup and readdir HIDE
  behavior.
- `select_portal.bpf.c`: minimal regression policy for intermediate and final
  SELECT_TARGET behavior through registered lower directories and files.
- `application_file_sharing.bpf.c`: XDG-derived Sandboxed Application File
  Sharing preflight policy. It scopes a managed document by parent and name,
  then uses application cgroup identity for grant/revoke `SELECT` and `HIDE`
  decisions.
- `build_action_sandboxing.bpf.c`: Bazel-derived Build Action Sandboxing
  preflight policy. It selects an existing declared-input root for each action
  identity and hides undeclared paths during lookup and directory enumeration.
- `spindle_staging.bpf.c`: Spindle-derived HPC File Staging policy. It maps
  exact source components to registered Spindle cache files and records
  aggregate and per-target selection hits.
- `agent_workspace_view.bpf.c`: Agent workspace dependency-preflight policy
  for stable logical `ws` directory selection plus whiteout-style hiding. This
  is a preflight policy, not the full Experiment A policy matrix.
- `table_redirect.bpf.c`: retained legacy exact-map diagnostic. It is excluded
  from the default current benchmark and runs only when explicitly selected
  through `BENCH_VARIANTS`. It must stay limited to map lookup plus
  PASS/REDIRECT.
- `build_graph_view.bpf.c`: build graph precedence policy family.
- `sandbox_fixture_view.bpf.c`: test/staging fixture substitution family.
- `checkpoint_restore_view.bpf.c`: checkpoint/restore session consistency
  family.
- `cache_locality_view.bpf.c`: content-verified cache locality family.

The four policy-family files intentionally contain different bounded decision
structures tied to workload semantics. Dynamic-policy claims should be made
from those semantics and the relevant workload baselines, not from the mere
existence of multiple policy files.
