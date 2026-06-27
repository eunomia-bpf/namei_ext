# OSDI evaluation policy budgets.
#
# This file is included by future Make targets. It is intentionally Makefile
# syntax, not YAML/JSON/DSL policy configuration.

OSDI_MAX_POLICY_INSTRUCTIONS ?= 10000
OSDI_MAX_POLICY_MAPS ?= 8
OSDI_MAX_POLICY_MAP_ENTRIES ?= 131072
OSDI_MAX_POLICY_MAP_MEMORY_BYTES ?= 67108864

# checkpoint_restore_view.bpf.c: maximum path classes checked in bounded logic.
OSDI_CHECKPOINT_MAX_PATH_CLASSES ?= 8
OSDI_CHECKPOINT_MAX_RESTORE_SESSIONS ?= 100
OSDI_CHECKPOINT_MIN_RESTORE_SWITCH_HIT_RATE ?= 0.80
OSDI_CHECKPOINT_MIN_POST_RESTORE_VFS_HIT_RATE ?= 0.80

# cache_locality_view.bpf.c: maximum content-hash witnesses checked per decision.
OSDI_CACHE_MAX_HASH_WITNESSES ?= 4
OSDI_CACHE_MIN_STATE_TRANSITION_HIT_RATE ?= 0.80

# table_redirect.bpf.c counterfactual budget.
OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO ?= 10
OSDI_TABLE_MAX_UPDATE_WRITES_RATIO ?= 10
OSDI_TABLE_MAX_STALE_WINDOW_MS ?= 100
OSDI_TABLE_MAX_UPDATE_LATENCY_MS ?= 1000
