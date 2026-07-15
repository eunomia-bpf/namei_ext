# namei_ext Policies

A `namei_ext` policy is an eBPF program. Policy behavior belongs in
`*.bpf.c` files in this directory, not in YAML or JSON policy files.

Phase 1 policy roles:

- `pass_only.bpf.c`: attach/static-branch residual-overhead lower bound.
- `redirect_alias.bpf.c`: minimal regression policy for lookup and readdir
  REDIRECT behavior.
- `hide_secret.bpf.c`: minimal regression policy for lookup and readdir HIDE
  behavior.
- `select_portal.bpf.c`: minimal regression policy for intermediate
  SELECT_TARGET behavior through a registered lower directory.
- `agent_workspace_view.bpf.c`: Agent workspace dependency-preflight policy
  for stable logical `ws` directory selection plus whiteout-style hiding. This
  is a preflight policy, not the full Experiment A policy matrix.
- `table_redirect.bpf.c`: exact-map diagnostic policy for workloads where a
  precomputed mapping is the relevant sanity check. It must stay limited to map
  lookup plus PASS/REDIRECT.
- `build_graph_view.bpf.c`: build graph precedence policy family.
- `sandbox_fixture_view.bpf.c`: test/staging fixture substitution family.
- `checkpoint_restore_view.bpf.c`: checkpoint/restore session consistency
  family.
- `cache_locality_view.bpf.c`: content-verified cache locality family.

The four policy-family files intentionally contain different bounded decision
structures tied to workload semantics. Dynamic-policy claims should be made
from those semantics and the relevant workload baselines, not from the mere
existence of multiple policy files.
