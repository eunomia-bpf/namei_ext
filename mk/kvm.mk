PHASE1_RESULT_DIR ?= $(RESULT_ROOT)/phase1/$(RUN_ID)
POLICY_LOAD_OBJECTS ?= $(BUILD_ROOT)/bpf/hide_secret.bpf.o $(BUILD_ROOT)/bpf/pass_only.bpf.o $(BUILD_ROOT)/bpf/redirect_alias.bpf.o $(BUILD_ROOT)/bpf/select_portal.bpf.o
AGENT_WORKSPACE_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace/$(RUN_ID)
AGENT_WORKSPACE_PREFLIGHT_JSON ?= $(AGENT_WORKSPACE_RESULT_DIR)/agent-workspace-preflight.jsonl
AGENT_WORKSPACE_MATRIX_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-matrix/$(RUN_ID)
AGENT_WORKSPACE_MATRIX_JSON ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/agent-workspace-matrix.jsonl
AGENT_WORKSPACE_MATRIX_INPUTS ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/agent-workspace-matrix-inputs.sha256
AGENT_WORKSPACE_MATRIX_COMMAND ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/agent-workspace-matrix-command.txt
AGENT_WORKSPACE_MATRIX_STDOUT ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/stdout-agent-workspace-matrix.log
AGENT_WORKSPACE_MATRIX_STDERR ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/stderr-agent-workspace-matrix.log
AGENT_WORKSPACE_POLICY ?= $(BUILD_ROOT)/bpf/agent_workspace_view.bpf.o
AGENT_WORKSPACE_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/agent_workspace_view.bpf.c
AGENT_WORKSPACE_RUNNER ?= $(BUILD_ROOT)/agent-workspace/namei_ext_agent_workspace
AGENT_WORKSPACE_RUNNER_SOURCE ?= $(ROOT_DIR)/tests/agent_workspace/namei_ext_agent_workspace.c
AGENT_WORKSPACE_FUSE_RUNNER ?= $(BUILD_ROOT)/agent-workspace/namei_ext_agent_workspace_fuse
AGENT_WORKSPACE_FUSE_RUNNER_SOURCE ?= $(ROOT_DIR)/tests/agent_workspace/namei_ext_agent_workspace_fuse.c
AGENT_WORKSPACE_SOURCE_TRACE ?= $(ROOT_DIR)/tests/agent_workspace/agentfs_lifecycle_trace.txt
BUILD_GRAPH_POLICY ?= $(BUILD_ROOT)/bpf/build_graph_view.bpf.o
SANDBOX_FIXTURE_POLICY ?= $(BUILD_ROOT)/bpf/sandbox_fixture_view.bpf.o
CHECKPOINT_RESTORE_POLICY ?= $(BUILD_ROOT)/bpf/checkpoint_restore_view.bpf.o
CACHE_LOCALITY_POLICY ?= $(BUILD_ROOT)/bpf/cache_locality_view.bpf.o
TABLE_REDIRECT_POLICY ?= $(BUILD_ROOT)/bpf/table_redirect.bpf.o
PASS_ONLY_POLICY ?= $(BUILD_ROOT)/bpf/pass_only.bpf.o
BUILD_GRAPH_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/build_graph_view.bpf.c
SANDBOX_FIXTURE_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/sandbox_fixture_view.bpf.c
CHECKPOINT_RESTORE_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/checkpoint_restore_view.bpf.c
CACHE_LOCALITY_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/cache_locality_view.bpf.c
TABLE_REDIRECT_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/table_redirect.bpf.c
PASS_ONLY_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/pass_only.bpf.c
W1_ORACLE_RUNNER ?= $(BUILD_ROOT)/w1-oracle/namei_ext_w1_oracle
W1_ORACLE_RUNNER_SOURCE ?= $(ROOT_DIR)/tests/w1_oracle/namei_ext_w1_oracle.c
W1_ORACLE_ENTRIES_TSV ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-build-graph-oracle-entries.tsv
W1_BUILD_OUTPUT_ORACLE ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-build-output-oracle.jsonl
W1_REDIS_ALIAS_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-redis-build/alias-manifest.json
W1_NGINX_ALIAS_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-nginx-build/alias-manifest.json
W1_REDIS_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-redis-build/manifest.json
W1_NGINX_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w1-nginx-build/manifest.json
W1_BUILD_REPLAY_JSON ?= $(PHASE1_RESULT_DIR)/w1-build-replay.jsonl
W1_BUILD_REPLAY_RESULT_DIR ?= $(PHASE1_RESULT_DIR)/w1-build-replay
W1_BUILD_REPLAY_WORK_DIR ?= /tmp/namei-ext-w1-build-replay-$(RUN_ID)
W1_RELEASE_REPLAY_JSON ?= $(PHASE1_RESULT_DIR)/w1-release-build-replay.jsonl
W1_RELEASE_REPLAY_RESULT_DIR ?= $(PHASE1_RESULT_DIR)/w1-release-build-replay
W1_RELEASE_REPLAY_WORK_DIR ?= /tmp/namei-ext-w1-release-build-replay-$(RUN_ID)
W1_BUILD_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w1-build-macrobench.jsonl
W1_BUILD_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w1-build-macrobench-inputs.sha256
W1_BUILD_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w1-build-macrobench-work
W1_BUILD_MACROBENCH_SAMPLES ?= 1
W1_BUILD_BASELINE_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w1-build-baseline-macrobench.jsonl
W1_BUILD_BASELINE_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w1-build-baseline-macrobench-inputs.sha256
W1_BUILD_BASELINE_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w1-build-baseline-macrobench-work
W1_BUILD_BASELINE_MACROBENCH_SAMPLES ?= $(W1_BUILD_MACROBENCH_SAMPLES)
W1_BUILD_BASELINES ?= copy_tree symlink_forest bind_mount projected_volume fuse_redirect
W1_BRANCH_PROBE_JSON ?= $(PHASE1_RESULT_DIR)/w1-branch-probes.jsonl
W1_BRANCH_PROBE_WORK_DIR ?= /tmp/namei-ext-w1-branch-probes-$(RUN_ID)
W1_BUILD_EPOCH_COUNTERFACTUAL_JSON ?= $(PHASE1_RESULT_DIR)/w1-build-epoch-counterfactual.jsonl
W1_BUILD_EPOCH_COUNTERFACTUAL_INPUTS ?= $(PHASE1_RESULT_DIR)/w1-build-epoch-counterfactual-inputs.sha256
W1_BUILD_EPOCH_COUNTERFACTUAL_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w1-build-epoch-counterfactual-work
W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES ?= 2
W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS ?= 16
W2_ORACLE_RUNNER ?= $(W1_ORACLE_RUNNER)
W2_ORACLE_RUNNER_SOURCE ?= $(W1_ORACLE_RUNNER_SOURCE)
W2_ORACLE_ENTRIES_TSV ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w2-sandbox-fixture-oracle-entries.tsv
W2_NGINX_FIXTURE_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w2-nginx-fixture/fixture-manifest.json
W2_POSTGRES_FIXTURE_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w2-postgres-secret-fixture/fixture-manifest.json
W2_NGINX_REAL_JSON ?= $(PHASE1_RESULT_DIR)/w2-nginx-real.jsonl
W2_NGINX_REAL_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w2-nginx-real-app
W2_NGINX_REAL_TRACE_JSON ?= $(PHASE1_RESULT_DIR)/w2-nginx-real-trace.jsonl
W2_NGINX_REAL_TRACE_INPUTS ?= $(PHASE1_RESULT_DIR)/w2-nginx-real-trace-inputs.sha256
W2_NGINX_REAL_TRACE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w2-nginx-real-trace-app
W2_NGINX_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w2-nginx-macrobench.jsonl
W2_NGINX_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w2-nginx-macrobench-inputs.sha256
W2_NGINX_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w2-nginx-macrobench-work
W2_NGINX_MACROBENCH_SAMPLES ?= 2
W2_NGINX_BASELINE_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w2-nginx-baseline-macrobench.jsonl
W2_NGINX_BASELINE_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w2-nginx-baseline-macrobench-inputs.sha256
W2_NGINX_BASELINE_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w2-nginx-baseline-macrobench-work
W2_NGINX_BASELINE_MACROBENCH_SAMPLES ?= $(W2_NGINX_MACROBENCH_SAMPLES)
W2_NGINX_BASELINES ?= copy_tree symlink_forest bind_mount projected_volume fuse_redirect
W2_NGINX_BIN ?= $(NGINX_BUILD_SRC)/objs/nginx
W2_NGINX_FIXTURE_CONF ?= $(NGINX_FIXTURE_CONFIG)
W2_NGINX_ENDPOINT_FIXTURE ?= $(NGINX_FIXTURE_ENDPOINT)
W2_NGINX_MIME_TYPES ?= $(NGINX_SRC)/conf/mime.types
W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON ?= $(PHASE1_RESULT_DIR)/w2-fixture-epoch-counterfactual.jsonl
W2_FIXTURE_EPOCH_COUNTERFACTUAL_INPUTS ?= $(PHASE1_RESULT_DIR)/w2-fixture-epoch-counterfactual-inputs.sha256
W2_FIXTURE_EPOCH_COUNTERFACTUAL_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w2-fixture-epoch-counterfactual-work
W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES ?= 2
W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS ?= 16
W3_ORACLE_RUNNER ?= $(W1_ORACLE_RUNNER)
W3_ORACLE_RUNNER_SOURCE ?= $(W1_ORACLE_RUNNER_SOURCE)
W3_ORACLE_ENTRIES_TSV ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w3-checkpoint-oracle-entries.tsv
W3_REDIS_CHECKPOINT_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w3-redis-podman-criu/checkpoint-manifest.json
W3_NGINX_CHECKPOINT_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w3-nginx-podman-criu/checkpoint-manifest.json
W3_REDIS_REPLAY_JSON ?= $(PHASE1_RESULT_DIR)/w3-redis-replay.jsonl
W3_REDIS_REPLAY_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w3-redis-replay-work
W3_REDIS_REPLAY_REDIS_BIN ?= $(REDIS_BUILD_SRC)/src/redis-server
W3_REDIS_TABLE_REPLAY_JSON ?= $(PHASE1_RESULT_DIR)/w3-redis-table-replay.jsonl
W3_REDIS_TABLE_REPLAY_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w3-redis-table-replay-work
W3_REDIS_COUNTERFACTUAL_JSON ?= $(PHASE1_RESULT_DIR)/w3-redis-counterfactual.jsonl
W3_REDIS_COUNTERFACTUAL_INPUTS ?= $(PHASE1_RESULT_DIR)/w3-redis-counterfactual-inputs.sha256
W3_REDIS_POLICY_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w3-redis-policy-macrobench.jsonl
W3_REDIS_POLICY_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w3-redis-policy-macrobench-inputs.sha256
W3_REDIS_POLICY_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w3-redis-policy-macrobench-work
W3_REDIS_POLICY_MACROBENCH_SAMPLES ?= 2
W3_REDIS_BASELINE_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w3-redis-baseline-macrobench.jsonl
W3_REDIS_BASELINE_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w3-redis-baseline-macrobench-inputs.sha256
W3_REDIS_BASELINE_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w3-redis-baseline-macrobench-work
W3_REDIS_BASELINE_MACROBENCH_SAMPLES ?= $(W3_REDIS_POLICY_MACROBENCH_SAMPLES)
W3_REDIS_BASELINES ?= materialized_checkpoint_view fuse_redirect
W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON ?= $(PHASE1_RESULT_DIR)/w3-checkpoint-epoch-counterfactual.jsonl
W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_INPUTS ?= $(PHASE1_RESULT_DIR)/w3-checkpoint-epoch-counterfactual-inputs.sha256
W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w3-checkpoint-epoch-counterfactual-work
W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES ?= 2
W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS ?= 16
W4_ORACLE_RUNNER ?= $(W1_ORACLE_RUNNER)
W4_ORACLE_RUNNER_SOURCE ?= $(W1_ORACLE_RUNNER_SOURCE)
W4_ORACLE_ENTRIES_TSV ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w4-cache-oracle-entries.tsv
W4_CCACHE_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w4-ccache-redis-nginx/cache-manifest.json
W4_BUILDKIT_MANIFEST ?= $(RESULT_ROOT)/workloads/runs/$(RUN_ID)/w4-buildkit-prometheus-go-cache/cache-manifest.json
W4_CACHE_CONTENT_JSON ?= $(PHASE1_RESULT_DIR)/w4-cache-content.jsonl
W4_CACHE_CONTENT_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-cache-content-work
W4_CACHE_TABLE_CONTENT_JSON ?= $(PHASE1_RESULT_DIR)/w4-cache-table-content.jsonl
W4_CACHE_TABLE_CONTENT_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-cache-table-content-work
W4_CACHE_TRANSITION_JSON ?= $(PHASE1_RESULT_DIR)/w4-cache-transition-counterfactual.jsonl
W4_CACHE_TRANSITION_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-cache-transition-counterfactual-inputs.sha256
W4_CACHE_TRANSITION_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-cache-transition-counterfactual-work
W4_CACHE_TRANSITION_SAMPLES ?= 2
W4_CACHE_EPOCH_JSON ?= $(PHASE1_RESULT_DIR)/w4-cache-epoch-counterfactual.jsonl
W4_CACHE_EPOCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-cache-epoch-counterfactual-inputs.sha256
W4_CACHE_EPOCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-cache-epoch-counterfactual-work
W4_CACHE_EPOCH_SAMPLES ?= 2
W4_CACHE_EPOCH_OBJECTS ?= 16
W4_CCACHE_BULK_CACHE_EPOCH_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-epoch-counterfactual.jsonl
W4_CCACHE_BULK_CACHE_EPOCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-epoch-counterfactual-inputs.sha256
W4_CCACHE_BULK_CACHE_EPOCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-epoch-counterfactual-work
W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES ?= $(W4_CACHE_EPOCH_SAMPLES)
W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS ?= $(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)
W4_CCACHE_REAL_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-real.jsonl
W4_CCACHE_REAL_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-real-work
W4_CCACHE_REAL_ENTRIES_TSV ?= $(PHASE1_RESULT_DIR)/w4-ccache-real-entries.tsv
W4_CCACHE_REAL_REDIS_SRC ?= $(REDIS_BUILD_SRC)/src/crc64.c
W4_CCACHE_REAL_NGINX_SRC ?= $(NGINX_BUILD_SRC)/src/core/ngx_string.c
W4_CCACHE_TRACE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-trace.jsonl
W4_CCACHE_TRACE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-trace-work
W4_CCACHE_TRACE_REDIS_LOG ?= $(PHASE1_RESULT_DIR)/w4-ccache-trace-redis.strace.log
W4_CCACHE_TRACE_NGINX_LOG ?= $(PHASE1_RESULT_DIR)/w4-ccache-trace-nginx.strace.log
W4_CCACHE_BULK_TRACE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace.jsonl
W4_CCACHE_BULK_TRACE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-work
W4_CCACHE_BULK_TRACE_REDIS_LOG ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-redis.strace.log
W4_CCACHE_BULK_TRACE_NGINX_LOG ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-nginx.strace.log
W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-source-manifest.tsv
W4_CCACHE_BULK_TRACE_ARTIFACTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-artifacts.sha256
W4_CCACHE_BULK_TRACE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-inputs.sha256
W4_CCACHE_BULK_REDIS_SRCS ?= src/adlist.c src/crc64.c src/dict.c src/intset.c src/listpack.c src/lzf_c.c src/lzf_d.c src/siphash.c src/ziplist.c src/sha1.c
W4_CCACHE_BULK_NGINX_SRCS ?= src/core/ngx_string.c src/core/ngx_palloc.c src/core/ngx_array.c src/core/ngx_hash.c src/core/ngx_list.c src/core/ngx_buf.c src/core/ngx_queue.c src/core/ngx_output_chain.c src/os/unix/ngx_alloc.c src/os/unix/ngx_files.c
W4_CCACHE_BULK_MIN_TRACE_OBJECTS ?= 16
W4_CCACHE_BULK_BRIDGE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-bridge.jsonl
W4_CCACHE_BULK_BRIDGE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-bridge-work
W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-bridge-entries.tsv
W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-bridge-trace-objects.txt
W4_CCACHE_BULK_BRIDGE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-bridge-inputs.sha256
W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-materialized-baseline.jsonl
W4_CCACHE_BULK_MATERIALIZED_BASELINE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-materialized-baseline-inputs.sha256
W4_CCACHE_BULK_MATERIALIZED_BASELINE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-materialized-baseline-work
W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES ?= 2
W4_CCACHE_BULK_FUSE_BASELINE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-baseline.jsonl
W4_CCACHE_BULK_FUSE_BASELINE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-baseline-inputs.sha256
W4_CCACHE_BULK_FUSE_BASELINE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-baseline-work
W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES ?= $(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)
W4_CCACHE_BULK_POLICY_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile.jsonl
W4_CCACHE_BULK_POLICY_COMPILE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-inputs.sha256
W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-work
W4_CCACHE_BULK_POLICY_COMPILE_STATS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-stats.txt
W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES ?= $(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)
W4_CCACHE_BULK_NATIVE_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile.jsonl
W4_CCACHE_BULK_NATIVE_COMPILE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-inputs.sha256
W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-work
W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES ?= $(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)
W4_CCACHE_BULK_FUSE_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile.jsonl
W4_CCACHE_BULK_FUSE_COMPILE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-inputs.sha256
W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-work
W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES ?= $(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)
W4_CCACHE_BULK_POLICY_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-macrobench.jsonl
W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-macrobench-inputs.sha256
W4_CCACHE_BULK_POLICY_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-macrobench-work
W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES ?= $(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)
W4_CCACHE_BRIDGE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-bridge.jsonl
W4_CCACHE_BRIDGE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-bridge-work
W4_CCACHE_BRIDGE_ENTRIES_TSV ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-bridge-entries.tsv
W4_CCACHE_BRIDGE_TRACE_OBJECTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-bridge-trace-objects.txt
W4_CCACHE_POLICY_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-compile.jsonl
W4_CCACHE_POLICY_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-work
W4_CCACHE_POLICY_COMPILE_STATS ?= $(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-stats.txt
W4_CCACHE_PARENT_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-parent-compile.jsonl
W4_CCACHE_PARENT_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-work
W4_CCACHE_PARENT_COMPILE_STATS ?= $(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-stats.txt
W4_CCACHE_TABLE_COMPILE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-table-compile.jsonl
W4_CCACHE_TABLE_COMPILE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-table-compile-work
W4_CCACHE_TABLE_COMPILE_STATS ?= $(PHASE1_RESULT_DIR)/w4-ccache-table-compile-stats.txt
W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-release-counterfactual.jsonl
W4_CCACHE_RELEASE_COUNTERFACTUAL_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-release-counterfactual-inputs.sha256
W4_CCACHE_RULE_MACROBENCH_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-rule-macrobench.jsonl
W4_CCACHE_RULE_MACROBENCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-rule-macrobench-inputs.sha256
W4_CCACHE_RULE_MACROBENCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-rule-macrobench-work
W4_CCACHE_RULE_MACROBENCH_SAMPLES ?= 2
W4_CCACHE_MATERIALIZED_BASELINE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-materialized-baseline.jsonl
W4_CCACHE_MATERIALIZED_BASELINE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-materialized-baseline-inputs.sha256
W4_CCACHE_MATERIALIZED_BASELINE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-materialized-baseline-work
W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES ?= 2

.PHONY: kvm-smoke kvm-policy-load kvm-policy-semantic kvm-w1-oracle kvm-w1-build-replay kvm-w1-release-build-replay kvm-w1-build-macrobench kvm-w1-build-baseline-macrobench kvm-w1-branch-probes kvm-w1-build-epoch-counterfactual kvm-w2-oracle kvm-w2-nginx-real kvm-w2-nginx-real-trace kvm-w2-nginx-macrobench kvm-w2-nginx-baseline-macrobench kvm-w2-fixture-epoch-counterfactual kvm-w3-oracle kvm-w3-redis-replay kvm-w3-redis-table-replay kvm-w3-redis-counterfactual kvm-w3-redis-policy-macrobench kvm-w3-redis-baseline-macrobench kvm-w3-checkpoint-epoch-counterfactual kvm-w4-oracle kvm-w4-cache-content kvm-w4-cache-table-content kvm-w4-cache-transition-counterfactual kvm-w4-cache-epoch-counterfactual kvm-w4-ccache-real kvm-w4-ccache-trace kvm-w4-ccache-policy-bridge kvm-w4-ccache-bulk-trace kvm-w4-ccache-bulk-policy-bridge kvm-w4-ccache-bulk-materialized-baseline-macrobench kvm-w4-ccache-bulk-fuse-baseline-macrobench kvm-w4-ccache-bulk-policy-compile kvm-w4-ccache-bulk-native-compile kvm-w4-ccache-bulk-fuse-compile kvm-w4-ccache-bulk-policy-macrobench kvm-w4-ccache-policy-compile kvm-w4-ccache-parent-compile kvm-w4-ccache-table-compile kvm-w4-ccache-release-counterfactual kvm-w4-ccache-rule-macrobench kvm-w4-ccache-materialized-baseline-macrobench kvm-agent-workspace-preflight kvm-agent-workspace-matrix kvm-functional kvm-bench kvm-eval-osdi-baselines __phase1_guest_smoke __phase1_guest_policy_load __phase1_guest_policy_semantic __phase1_guest_w1_oracle __phase1_guest_w1_build_replay __phase1_guest_w1_release_build_replay __phase1_guest_w1_build_macrobench __phase1_guest_w1_build_baseline_macrobench __phase1_guest_w1_branch_probes __phase1_guest_w1_build_epoch_counterfactual __phase1_guest_w2_oracle __phase1_guest_w2_nginx_real __phase1_guest_w2_nginx_real_trace __phase1_guest_w2_nginx_macrobench __phase1_guest_w2_nginx_baseline_macrobench __phase1_guest_w2_fixture_epoch_counterfactual __phase1_guest_w3_oracle __phase1_guest_w3_redis_replay __phase1_guest_w3_redis_table_replay __phase1_guest_w3_redis_counterfactual __phase1_guest_w3_redis_policy_macrobench __phase1_guest_w3_redis_baseline_macrobench __phase1_guest_w3_checkpoint_epoch_counterfactual __phase1_guest_w4_oracle __phase1_guest_w4_cache_content __phase1_guest_w4_cache_table_content __phase1_guest_w4_cache_transition_counterfactual __phase1_guest_w4_cache_epoch_counterfactual __phase1_guest_w4_ccache_real __phase1_guest_w4_ccache_trace __phase1_guest_w4_ccache_policy_bridge __phase1_guest_w4_ccache_bulk_trace __phase1_guest_w4_ccache_bulk_policy_bridge __phase1_guest_w4_ccache_bulk_materialized_baseline_macrobench __phase1_guest_w4_ccache_bulk_fuse_baseline_macrobench __phase1_guest_w4_ccache_bulk_policy_compile __phase1_guest_w4_ccache_bulk_native_compile __phase1_guest_w4_ccache_bulk_fuse_compile __phase1_guest_w4_ccache_bulk_policy_macrobench __phase1_guest_w4_ccache_policy_compile __phase1_guest_w4_ccache_parent_compile __phase1_guest_w4_ccache_table_compile __phase1_guest_w4_ccache_release_counterfactual __phase1_guest_w4_ccache_rule_macrobench __phase1_guest_w4_ccache_materialized_baseline_macrobench __experiment_agent_workspace_preflight __experiment_agent_workspace_matrix __phase1_guest_functional __phase1_guest_bench __eval_osdi_guest_baselines

kvm-smoke: $(KERNEL_IMAGE)
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_smoke RUN_ID=$(RUN_ID)"

__phase1_guest_smoke:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"guest-smoke-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/guest-smoke.jsonl"
	uname -a >"$(PHASE1_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(PHASE1_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(PHASE1_RESULT_DIR)/kernel-cmdline.txt"
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config" >"$(PHASE1_RESULT_DIR)/config-namei-ext.txt"
	cp "$(KERNEL_BUILD_DIR)/.config" "$(PHASE1_RESULT_DIR)/kernel.config"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-smoke.log"
	printf '{"event":"guest-smoke-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/guest-smoke.jsonl"

kvm-policy-load: $(KERNEL_IMAGE) bpf policy-load
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_policy_load RUN_ID=$(RUN_ID)"

__phase1_guest_policy_load:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"policy-load-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/policy-load.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -n "$(POLICY_LOAD_OBJECTS)"
	"$(BUILD_ROOT)/policy-load/namei_ext_policy_load" "$(PHASE1_RESULT_DIR)/policy-load.jsonl" /sys/fs/cgroup $(POLICY_LOAD_OBJECTS)
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-policy-load.log"
	printf '{"event":"policy-load-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/policy-load.jsonl"

kvm-policy-semantic: $(KERNEL_IMAGE) bpf policy-semantic
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_policy_semantic RUN_ID=$(RUN_ID)"

__phase1_guest_policy_semantic:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"policy-semantic-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/policy-semantic.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/policy-semantic/namei_ext_policy_semantic" "$(PHASE1_RESULT_DIR)/policy-semantic.jsonl" /sys/fs/cgroup "$(BUILD_GRAPH_POLICY)" "$(SANDBOX_FIXTURE_POLICY)" "$(CHECKPOINT_RESTORE_POLICY)" "$(CACHE_LOCALITY_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-policy-semantic.log"
	printf '{"event":"policy-semantic-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/policy-semantic.jsonl"

kvm-agent-workspace-preflight: $(KERNEL_IMAGE) bpf agent-workspace
	install -d "$(AGENT_WORKSPACE_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __experiment_agent_workspace_preflight RUN_ID=$(RUN_ID)"

__experiment_agent_workspace_preflight:
	install -d "$(AGENT_WORKSPACE_RESULT_DIR)"
	printf '{"event":"agent-workspace-preflight-start","run_id":"%s","result_level":"kvm_agent_workspace_dependency_preflight","policy":"agent_workspace_view.bpf.c"}\n' "$(RUN_ID)" >"$(AGENT_WORKSPACE_PREFLIGHT_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_PREFLIGHT_JSON)" /sys/fs/cgroup
	"$(AGENT_WORKSPACE_FUSE_RUNNER)" "$(AGENT_WORKSPACE_PREFLIGHT_JSON)"
	dmesg >"$(AGENT_WORKSPACE_RESULT_DIR)/dmesg-agent-workspace-preflight.log"
	printf '{"event":"agent-workspace-preflight-done","run_id":"%s","result_level":"kvm_agent_workspace_dependency_preflight"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_PREFLIGHT_JSON)"

kvm-agent-workspace-matrix: $(KERNEL_IMAGE) bpf agent-workspace
	install -d "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __experiment_agent_workspace_matrix RUN_ID=$(RUN_ID)"

__experiment_agent_workspace_matrix:
	install -d "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)"
	: >"$(AGENT_WORKSPACE_MATRIX_STDOUT)"
	: >"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	printf 'make -C %s __experiment_agent_workspace_matrix RUN_ID=%s\n' "$(ROOT_DIR)" "$(RUN_ID)" >"$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	printf 'AGENT_WORKSPACE_POLICY=%s\nAGENT_WORKSPACE_RUNNER=%s\nAGENT_WORKSPACE_FUSE_RUNNER=%s\nAGENT_WORKSPACE_SOURCE_TRACE=%s\nKERNEL_IMAGE=%s\nKERNEL_BUILD_DIR=%s\n' "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_FUSE_RUNNER)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" "$(KERNEL_IMAGE)" "$(KERNEL_BUILD_DIR)" >>"$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	printf '{"event":"agent-workspace-matrix-start","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix","policy":"agent_workspace_view.bpf.c"}\n' "$(RUN_ID)" >"$(AGENT_WORKSPACE_MATRIX_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	cp "$(KERNEL_BUILD_DIR)/.config" "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/kernel.config"
	uname -a >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/kernel-cmdline.txt"
	sha256sum "$(KERNEL_IMAGE)" "$(KERNEL_BUILD_DIR)/.config" "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_POLICY_SOURCE)" "$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_RUNNER_SOURCE)" "$(AGENT_WORKSPACE_FUSE_RUNNER)" "$(AGENT_WORKSPACE_FUSE_RUNNER_SOURCE)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" "$(ROOT_DIR)/Makefile" "$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md" >"$(AGENT_WORKSPACE_MATRIX_INPUTS)"
	printf '{"event":"agent-workspace-provenance","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix","command_file":"agent-workspace-matrix-command.txt","input_sha256_file":"agent-workspace-matrix-inputs.sha256","kernel_config":"kernel.config","stdout_file":"stdout-agent-workspace-matrix.log","stderr_file":"stderr-agent-workspace-matrix.log"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	"$(AGENT_WORKSPACE_RUNNER)" --matrix "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_MATRIX_JSON)" /sys/fs/cgroup "$(AGENT_WORKSPACE_SOURCE_TRACE)" >>"$(AGENT_WORKSPACE_MATRIX_STDOUT)" 2>>"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	"$(AGENT_WORKSPACE_FUSE_RUNNER)" --matrix "$(AGENT_WORKSPACE_MATRIX_JSON)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" >>"$(AGENT_WORKSPACE_MATRIX_STDOUT)" 2>>"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"namei_ext","source_oracle":"AgentFS-derived bash/git workspace lifecycle","owned_methods":"lookup_policy,readdir_policy","daemon_state":"none","metadata_state":"target registry only","data_write_path_owner":"lower_filesystem","privileged_code_surface":"verified eBPF policy plus kernel validation","invalid_policy_containment":"unregistered target fails closed to ENOENT in this matrix","owns_filesystem_methods":false,"requires_daemon":false,"policy_verified":true,"lower_fs_owns_data_path":true,"detail":"bounded eBPF name-resolution policy; kernel and lower filesystem own VFS objects, methods, writes, and data path"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"feature_equivalent_fuse","source_oracle":"AgentFS-derived bash/git workspace lifecycle","owned_methods":"getattr,readdir,open,create,read,write,readlink,unlink,rename,truncate","daemon_state":"FUSE policy daemon and shared epoch state","metadata_state":"daemon-managed path translation and hidden-name state","data_write_path_owner":"FUSE request path over lower files","privileged_code_surface":"userspace filesystem daemon plus kernel FUSE interface","invalid_policy_containment":"daemon must implement path validation and failure behavior","owns_filesystem_methods":true,"requires_daemon":true,"policy_verified":false,"lower_fs_owns_data_path":false,"detail":"feature-equivalent FUSE policy filesystem implements filesystem operations for the same oracle"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"custom_or_stackable_fs","source_oracle":"AgentFS/BranchFS/YoloFS-style workspace lifecycle","owned_methods":"lookup,readdir,create,unlink,rename,open_read_write_or_stackable_forwarding","daemon_state":"none for in-kernel stackable FS, runtime state for source services","metadata_state":"COW,checkpoint,whiteout,audit,cache-invalidation metadata","data_write_path_owner":"custom or stackable filesystem boundary when it owns COW/write semantics","privileged_code_surface":"kernel filesystem or stackable filesystem implementation","invalid_policy_containment":"implementation-specific validation across owned methods","owns_filesystem_methods":true,"requires_daemon":false,"policy_verified":false,"lower_fs_owns_data_path":false,"detail":"source-backed boundary evidence: broader filesystem designs own method, metadata, and failure surface beyond name-resolution policy"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	if jq -e 'select(.pass == false)' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null; then exit 1; fi
	dmesg >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/dmesg-agent-workspace-matrix.log"
	test -s "$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	test -s "$(AGENT_WORKSPACE_MATRIX_INPUTS)"
	test -s "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/kernel.config"
	test -e "$(AGENT_WORKSPACE_MATRIX_STDOUT)"
	test -e "$(AGENT_WORKSPACE_MATRIX_STDERR)"
	jq -e 'select(.event == "agent-workspace-provenance")' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null
	for case in setup_source_dirs setup_executable_tools agentfs_source_trace_artifact agentfs_source_trace_replayed nohook_base_main nohook_upper_main nohook_base_deleted_visible nohook_base_readdir nohook_parent_lists_ws policy_parent_lists_ws base_epoch_main base_epoch_src_app base_epoch_git_head upper_epoch_main upper_epoch_src_app upper_epoch_git_head upper_generated_negative_before_write upper_epoch_write upper_generated_visible base_not_materialized agentfs_cached_negative_before_create agentfs_cached_negative_create agentfs_cached_negative_visible agentfs_rename_generated_to_renamed agentfs_rename_generated_old_absent agentfs_rename_generated_new_visible agentfs_rename_restored_generated agentfs_unlink_cached_created agentfs_unlink_cached_absent final_tree_manifest invalid_unregistered_target_contained agent_workspace_matrix_summary fuse_setup_source_dirs fuse_setup_executable_tools fuse_agentfs_source_trace_artifact fuse_agentfs_source_trace_replayed fuse_nohook_base_main fuse_nohook_upper_main fuse_nohook_base_deleted_visible fuse_nohook_base_readdir fuse_options_recorded fuse_parent_lists_ws fuse_base_epoch_main fuse_base_epoch_src_app fuse_base_epoch_git_head fuse_upper_epoch_main fuse_upper_epoch_src_app fuse_upper_epoch_git_head fuse_upper_generated_negative_before_write fuse_upper_epoch_write fuse_upper_generated_visible fuse_base_not_materialized fuse_agentfs_cached_negative_before_create fuse_agentfs_cached_negative_create fuse_agentfs_cached_negative_visible fuse_agentfs_rename_generated_to_renamed fuse_agentfs_rename_generated_old_absent fuse_agentfs_rename_generated_new_visible fuse_agentfs_rename_restored_generated fuse_agentfs_unlink_cached_created fuse_agentfs_unlink_cached_absent fuse_final_tree_manifest fuse_agent_workspace_matrix_summary; do \
		jq -e --arg case "$$case" 'select((.case == $$case or .manifest == $$case) and .pass == true)' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null; \
	done
	for metric in nohook_stat_base_main_ns nohook_readdir_base_ns namei_ext_stat_main_ns namei_ext_open_main_ns namei_ext_access_main_ns namei_ext_exec_tool_ns namei_ext_readdir_ws_ns namei_ext_macro_lifecycle_ns fuse_nohook_stat_base_main_ns fuse_nohook_readdir_base_ns fuse_stat_main_ns fuse_open_main_ns fuse_access_main_ns fuse_exec_tool_ns fuse_readdir_ws_ns fuse_macro_lifecycle_ns; do \
		jq -e --arg metric "$$metric" 'select(.event == "agent-workspace-metric" and .metric == $$metric and .pass == true and .value >= 0)' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null; \
	done
	for mechanism in namei_ext feature_equivalent_fuse custom_or_stackable_fs; do \
		jq -e --arg mechanism "$$mechanism" 'select(.event == "agent-workspace-boundary" and .mechanism == $$mechanism)' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null; \
	done
	! grep -E 'BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN' "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/dmesg-agent-workspace-matrix.log" >/dev/null
	printf '{"event":"agent-workspace-matrix-done","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"

kvm-w1-oracle: $(KERNEL_IMAGE) bpf w1-oracle workload-w1-oracle-entries workload-w1-build-output-oracle
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_oracle RUN_ID=$(RUN_ID)"

__phase1_guest_w1_oracle:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w1-oracle-start","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/w1-oracle.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_BUILD_OUTPUT_ORACLE)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W1_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_BUILD_OUTPUT_ORACLE)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(BUILD_GRAPH_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w1-oracle-inputs.sha256"
	printf '{"event":"w1-oracle-input","run_id":"%s","result_level":"kvm_policy_path_oracle","input_sha256_file":"w1-oracle-inputs.sha256","entries_tsv":"%s","build_output_oracle":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_BUILD_OUTPUT_ORACLE)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" >>"$(PHASE1_RESULT_DIR)/w1-oracle.jsonl"
	"$(W1_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w1-oracle.jsonl" /sys/fs/cgroup "$(W1_ORACLE_ENTRIES_TSV)" "$(BUILD_GRAPH_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-oracle.log"
	printf '{"event":"w1-oracle-done","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/w1-oracle.jsonl"

kvm-w1-build-replay: $(KERNEL_IMAGE) bpf w1-oracle workload-w1-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_build_replay RUN_ID=$(RUN_ID)"

__phase1_guest_w1_build_replay:
	install -d "$(PHASE1_RESULT_DIR)" "$(W1_BUILD_REPLAY_RESULT_DIR)"
	printf '{"event":"w1-build-replay-start","run_id":"%s","result_level":"kvm_policy_build_replay_witness"}\n' "$(RUN_ID)" >"$(W1_BUILD_REPLAY_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_REDIS_MANIFEST)"
	test -s "$(W1_NGINX_MANIFEST)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -d "$(REDIS_TRACE_SRC)"
	test -d "$(NGINX_TRACE_SRC)"
	rm -rf "$(W1_BUILD_REPLAY_WORK_DIR)"
	install -d "$(W1_BUILD_REPLAY_WORK_DIR)"
	cp -a "$(REDIS_TRACE_SRC)" "$(W1_BUILD_REPLAY_WORK_DIR)/redis-src"
	cp -a "$(NGINX_TRACE_SRC)" "$(W1_BUILD_REPLAY_WORK_DIR)/nginx-src"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(BUILD_GRAPH_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w1-build-replay-inputs.sha256"
	printf '{"event":"w1-build-replay-input","run_id":"%s","result_level":"kvm_policy_build_replay_witness","input_sha256_file":"w1-build-replay-inputs.sha256","entries_tsv":"%s","redis_manifest":"%s","nginx_manifest":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" >>"$(W1_BUILD_REPLAY_JSON)"
	"$(W1_ORACLE_RUNNER)" --build-replay "$(W1_BUILD_REPLAY_JSON)" /sys/fs/cgroup "$(W1_ORACLE_ENTRIES_TSV)" "$(BUILD_GRAPH_POLICY)" "$(W1_BUILD_REPLAY_WORK_DIR)/redis-src" "$(W1_BUILD_REPLAY_WORK_DIR)/nginx-src" "$(W1_BUILD_REPLAY_RESULT_DIR)"
	test -s "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.baseline.i"
	test -s "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.policy.i"
	test -s "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.baseline.i"
	test -s "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.policy.i"
	sha256sum "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.baseline.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.policy.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.baseline.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.policy.i" >"$(PHASE1_RESULT_DIR)/w1-build-replay-outputs.sha256"
	printf '{"event":"w1-build-replay-output","run_id":"%s","result_level":"kvm_policy_build_replay_witness","run_environment":"kvm","policy_executed":true,"kvm_validated":true,"output_hash_oracle":false,"policy_replay_output_hash_oracle":true,"release_output_hash_oracle":false,"output_hash_oracle_scope":"kvm_policy_preprocess","output_sha256_file":"w1-build-replay-outputs.sha256","redis_baseline":"%s","redis_policy":"%s","nginx_baseline":"%s","nginx_policy":"%s","qualified_for_c8":false}\n' "$(RUN_ID)" "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.baseline.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/redis.policy.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.baseline.i" "$(W1_BUILD_REPLAY_RESULT_DIR)/nginx.policy.i" >>"$(W1_BUILD_REPLAY_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-build-replay.log"
	rm -rf "$(W1_BUILD_REPLAY_WORK_DIR)"
	printf '{"event":"w1-build-replay-done","run_id":"%s","result_level":"kvm_policy_build_replay_witness"}\n' "$(RUN_ID)" >>"$(W1_BUILD_REPLAY_JSON)"

kvm-w1-release-build-replay: $(KERNEL_IMAGE) bpf w1-oracle workload-w1-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_release_build_replay RUN_ID=$(RUN_ID)"

__phase1_guest_w1_release_build_replay:
	install -d "$(PHASE1_RESULT_DIR)" "$(W1_RELEASE_REPLAY_RESULT_DIR)"
	printf '{"event":"w1-release-build-replay-start","run_id":"%s","result_level":"kvm_policy_release_build_replay_witness"}\n' "$(RUN_ID)" >"$(W1_RELEASE_REPLAY_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_REDIS_MANIFEST)"
	test -s "$(W1_NGINX_MANIFEST)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -d "$(REDIS_TRACE_SRC)"
	test -d "$(NGINX_TRACE_SRC)"
	rm -rf "$(W1_RELEASE_REPLAY_WORK_DIR)"
	install -d "$(W1_RELEASE_REPLAY_WORK_DIR)"
	cp -a "$(REDIS_TRACE_SRC)" "$(W1_RELEASE_REPLAY_WORK_DIR)/redis-baseline-src"
	cp -a "$(REDIS_TRACE_SRC)" "$(W1_RELEASE_REPLAY_WORK_DIR)/redis-policy-src"
	cp -a "$(NGINX_TRACE_SRC)" "$(W1_RELEASE_REPLAY_WORK_DIR)/nginx-baseline-src"
	cp -a "$(NGINX_TRACE_SRC)" "$(W1_RELEASE_REPLAY_WORK_DIR)/nginx-policy-src"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(BUILD_GRAPH_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w1-release-build-replay-inputs.sha256"
	printf '{"event":"w1-release-build-replay-input","run_id":"%s","result_level":"kvm_policy_release_build_replay_witness","input_sha256_file":"w1-release-build-replay-inputs.sha256","entries_tsv":"%s","redis_manifest":"%s","nginx_manifest":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" >>"$(W1_RELEASE_REPLAY_JSON)"
	"$(W1_ORACLE_RUNNER)" --release-build-replay "$(W1_RELEASE_REPLAY_JSON)" /sys/fs/cgroup "$(W1_ORACLE_ENTRIES_TSV)" "$(BUILD_GRAPH_POLICY)" "$(W1_RELEASE_REPLAY_WORK_DIR)/redis-baseline-src" "$(W1_RELEASE_REPLAY_WORK_DIR)/redis-policy-src" "$(W1_RELEASE_REPLAY_WORK_DIR)/nginx-baseline-src" "$(W1_RELEASE_REPLAY_WORK_DIR)/nginx-policy-src" "$(W1_RELEASE_REPLAY_RESULT_DIR)"
	test -s "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.baseline.bin"
	test -s "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.policy.bin"
	test -s "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.baseline.bin"
	test -s "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.policy.bin"
	sha256sum "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.baseline.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.policy.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.baseline.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.policy.bin" >"$(PHASE1_RESULT_DIR)/w1-release-build-replay-outputs.sha256"
	test "$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w1-release-build-replay-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w1-release-build-replay-outputs.sha256" | awk '{print $$1}')"
	test "$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w1-release-build-replay-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w1-release-build-replay-outputs.sha256" | awk '{print $$1}')"
	printf '{"event":"w1-release-build-replay-output","run_id":"%s","result_level":"kvm_policy_release_build_replay_witness","run_environment":"kvm","policy_executed":true,"kvm_validated":true,"release_binary_hash_match":true,"release_output_hash_oracle":false,"output_sha256_file":"w1-release-build-replay-outputs.sha256","redis_baseline":"%s","redis_policy":"%s","nginx_baseline":"%s","nginx_policy":"%s","qualified_for_c8":false}\n' "$(RUN_ID)" "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.baseline.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/redis.policy.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.baseline.bin" "$(W1_RELEASE_REPLAY_RESULT_DIR)/nginx.policy.bin" >>"$(W1_RELEASE_REPLAY_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-release-build-replay.log"
	rm -rf "$(W1_RELEASE_REPLAY_WORK_DIR)"
	printf '{"event":"w1-release-build-replay-done","run_id":"%s","result_level":"kvm_policy_release_build_replay_witness"}\n' "$(RUN_ID)" >>"$(W1_RELEASE_REPLAY_JSON)"

kvm-w1-build-macrobench: $(KERNEL_IMAGE) bpf w1-oracle workload-w1-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_build_macrobench RUN_ID=$(RUN_ID) W1_BUILD_MACROBENCH_SAMPLES=$(W1_BUILD_MACROBENCH_SAMPLES)"

__phase1_guest_w1_build_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w1-build-macrobench-start","run_id":"%s","result_level":"kvm_workload_setup_update_poc","samples":%s}\n' "$(RUN_ID)" "$(W1_BUILD_MACROBENCH_SAMPLES)" >"$(W1_BUILD_MACROBENCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_REDIS_MANIFEST)"
	test -s "$(W1_NGINX_MANIFEST)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-macrobench-design.md"
	test -d "$(REDIS_TRACE_SRC)"
	test -d "$(NGINX_TRACE_SRC)"
	rm -rf "$(W1_BUILD_MACROBENCH_WORK_DIR)"
	install -d "$(W1_BUILD_MACROBENCH_WORK_DIR)"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(BUILD_GRAPH_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-macrobench-design.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W1_BUILD_MACROBENCH_INPUTS)"
	printf '{"event":"w1-build-macrobench-input","run_id":"%s","result_level":"kvm_workload_setup_update_poc","input_sha256_file":"w1-build-macrobench-inputs.sha256","entries_tsv":"%s","redis_manifest":"%s","nginx_manifest":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s","samples":%s}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_BUILD_MACROBENCH_SAMPLES)" >>"$(W1_BUILD_MACROBENCH_JSON)"
	"$(W1_ORACLE_RUNNER)" --w1-build-macrobench "$(W1_BUILD_MACROBENCH_JSON)" /sys/fs/cgroup "$(W1_BUILD_MACROBENCH_WORK_DIR)" "$(W1_BUILD_MACROBENCH_SAMPLES)" "$(W1_ORACLE_ENTRIES_TSV)" "$(BUILD_GRAPH_POLICY)" "$(REDIS_TRACE_SRC)" "$(NGINX_TRACE_SRC)"
	test "$$(jq -s '[.[] | select(.event == "w1-build-macrobench-setup" and .pass == true)] | length' "$(W1_BUILD_MACROBENCH_JSON)")" = "$(W1_BUILD_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w1-build-macrobench-update" and .pass == true)] | length' "$(W1_BUILD_MACROBENCH_JSON)")" = "$(W1_BUILD_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w1-build-macrobench-correctness" and .pass == true)] | length' "$(W1_BUILD_MACROBENCH_JSON)")" = "$(W1_BUILD_MACROBENCH_SAMPLES)"
	jq -e --argjson samples "$(W1_BUILD_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w1-build-macrobench-summary")][0]) as $$s | $$s.samples == $$samples and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W1_BUILD_MACROBENCH_JSON)" >/dev/null
	sha256sum -c "$(W1_BUILD_MACROBENCH_INPUTS)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-build-macrobench.log"
	printf '{"event":"w1-build-macrobench-done","run_id":"%s","result_level":"kvm_workload_setup_update_poc","samples":%s}\n' "$(RUN_ID)" "$(W1_BUILD_MACROBENCH_SAMPLES)" >>"$(W1_BUILD_MACROBENCH_JSON)"

kvm-w1-build-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle workload-w1-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_build_baseline_macrobench RUN_ID=$(RUN_ID) W1_BUILD_BASELINE_MACROBENCH_SAMPLES=$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES) W1_BUILD_BASELINES='$(W1_BUILD_BASELINES)'"

__phase1_guest_w1_build_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w1-build-baseline-macrobench-start","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES)" "$(W1_BUILD_BASELINES)" >"$(W1_BUILD_BASELINE_MACROBENCH_JSON)"
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_REDIS_MANIFEST)"
	test -s "$(W1_NGINX_MANIFEST)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-design.md"
	test -d "$(REDIS_TRACE_SRC)"
	test -d "$(NGINX_TRACE_SRC)"
	rm -rf "$(W1_BUILD_BASELINE_MACROBENCH_WORK_DIR)"
	install -d "$(W1_BUILD_BASELINE_MACROBENCH_WORK_DIR)"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-design.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W1_BUILD_BASELINE_MACROBENCH_INPUTS)"
	printf '{"event":"w1-build-baseline-macrobench-input","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","input_sha256_file":"w1-build-baseline-macrobench-inputs.sha256","entries_tsv":"%s","redis_manifest":"%s","nginx_manifest":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES)" "$(W1_BUILD_BASELINES)" >>"$(W1_BUILD_BASELINE_MACROBENCH_JSON)"
	"$(W1_ORACLE_RUNNER)" --w1-build-baseline-macrobench "$(W1_BUILD_BASELINE_MACROBENCH_JSON)" "$(W1_BUILD_BASELINE_MACROBENCH_WORK_DIR)" "$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES)" "$(W1_ORACLE_ENTRIES_TSV)" "$(REDIS_TRACE_SRC)" "$(NGINX_TRACE_SRC)" "$(W1_BUILD_BASELINES)"
	jq -e --argjson samples "$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w1-build-baseline-summary")][0]) as $$s | (($$s.selected_baselines == "all") or (($$s.selected_baselines // "") | contains("fuse_redirect"))) as $$needs_fuse | ([.[] | select(.event == "w1-build-baseline-correctness" and .baseline == "fuse_redirect" and .pass == true and (.visible_aliases // 0) > 0 and (.alias_parent_dirs // 0) > 0 and (.fuse_mounts // 0) == (.alias_parent_dirs // -1) and (.materialized_output_hash_match // false) == true and (.post_update_output_hash_match // false) == true)] | length) as $$fuse_correct_rows | $$s.samples == $$samples and $$s.baseline_count > 0 and $$s.setup_rows == ($$samples * $$s.baseline_count) and $$s.update_rows == ($$samples * $$s.baseline_count) and $$s.correctness_rows == ($$samples * $$s.baseline_count) and $$s.pass == true and $$s.c2_supported == false and $$s.release_gate_pass == false and (($$needs_fuse | not) or $$fuse_correct_rows == $$samples)' "$(W1_BUILD_BASELINE_MACROBENCH_JSON)" >/dev/null
	sha256sum -c "$(W1_BUILD_BASELINE_MACROBENCH_INPUTS)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-build-baseline-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w1-build-baseline-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w1-build-baseline-macrobench-done","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W1_BUILD_BASELINE_MACROBENCH_SAMPLES)" "$(W1_BUILD_BASELINES)" >>"$(W1_BUILD_BASELINE_MACROBENCH_JSON)"

kvm-w1-branch-probes: $(KERNEL_IMAGE) bpf w1-oracle workload-w1-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_branch_probes RUN_ID=$(RUN_ID)"

__phase1_guest_w1_branch_probes:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w1-branch-probes-start","run_id":"%s","result_level":"kvm_policy_branch_probe_witness"}\n' "$(RUN_ID)" >"$(W1_BRANCH_PROBE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W1_REDIS_MANIFEST)"
	test -s "$(W1_NGINX_MANIFEST)"
	test -s "$(W1_REDIS_ALIAS_MANIFEST)"
	test -s "$(W1_NGINX_ALIAS_MANIFEST)"
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -d "$(REDIS_TRACE_SRC)"
	test -d "$(NGINX_TRACE_SRC)"
	rm -rf "$(W1_BRANCH_PROBE_WORK_DIR)"
	install -d "$(W1_BRANCH_PROBE_WORK_DIR)"
	cp -a "$(REDIS_TRACE_SRC)" "$(W1_BRANCH_PROBE_WORK_DIR)/redis-src"
	cp -a "$(NGINX_TRACE_SRC)" "$(W1_BRANCH_PROBE_WORK_DIR)/nginx-src"
	sha256sum "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(BUILD_GRAPH_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w1-branch-probes-inputs.sha256"
	printf '{"event":"w1-branch-probes-input","run_id":"%s","result_level":"kvm_policy_branch_probe_witness","input_sha256_file":"w1-branch-probes-inputs.sha256","entries_tsv":"%s","redis_manifest":"%s","nginx_manifest":"%s","redis_alias_manifest":"%s","nginx_alias_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W1_ORACLE_ENTRIES_TSV)" "$(W1_REDIS_MANIFEST)" "$(W1_NGINX_MANIFEST)" "$(W1_REDIS_ALIAS_MANIFEST)" "$(W1_NGINX_ALIAS_MANIFEST)" "$(W1_ORACLE_RUNNER_SOURCE)" >>"$(W1_BRANCH_PROBE_JSON)"
	jq -cn --slurpfile redis "$(W1_REDIS_ALIAS_MANIFEST)" --slurpfile nginx "$(W1_NGINX_ALIAS_MANIFEST)" --arg run_id "$(RUN_ID)" '($$redis[0].hit_rate.numerator_candidate_trace_hits // 0) as $$redis_hits | ($$nginx[0].hit_rate.numerator_candidate_trace_hits // 0) as $$nginx_hits | ($$redis[0].hit_rate.denominator_file_op_lines // 0) as $$redis_ops | ($$nginx[0].hit_rate.denominator_file_op_lines // 0) as $$nginx_ops | {event:"w1-branch-probes-hit-rate", run_id:$$run_id, result_level:"kvm_policy_branch_probe_witness", artifact_environment:"kvm", metric_basis_environment:"host", trace_basis:"host_trace_witness_manifest", policy_executed:false, kvm_validated:true, numerator_candidate_trace_hits:($$redis_hits + $$nginx_hits), denominator_file_op_lines:($$redis_ops + $$nginx_ops), candidate_witness_hit_rate:(($$redis_hits + $$nginx_hits) / ($$redis_ops + $$nginx_ops)), operation_weighted_hit_rate_is_release:false, qualified_for_c8:false, detail:"host trace candidate hit rate recorded in a KVM branch-probe artifact; release-level redirected operation hit rate remains a blocker"}' >>"$(W1_BRANCH_PROBE_JSON)"
	"$(W1_ORACLE_RUNNER)" --build-branch-probes "$(W1_BRANCH_PROBE_JSON)" /sys/fs/cgroup "$(BUILD_GRAPH_POLICY)" "$(W1_BRANCH_PROBE_WORK_DIR)/redis-src" "$(W1_BRANCH_PROBE_WORK_DIR)/nginx-src"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-branch-probes.log"
	rm -rf "$(W1_BRANCH_PROBE_WORK_DIR)"
	printf '{"event":"w1-branch-probes-done","run_id":"%s","result_level":"kvm_policy_branch_probe_witness"}\n' "$(RUN_ID)" >>"$(W1_BRANCH_PROBE_JSON)"

kvm-w1-build-epoch-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w1_build_epoch_counterfactual RUN_ID=$(RUN_ID) W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES=$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES) W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS=$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)"

__phase1_guest_w1_build_epoch_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)"
	rm -rf "$(W1_BUILD_EPOCH_COUNTERFACTUAL_WORK_DIR)"
	install -d "$(W1_BUILD_EPOCH_COUNTERFACTUAL_WORK_DIR)"
	printf '{"event":"w1-build-epoch-start","run_id":"%s","result_level":"kvm_build_graph_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)" >"$(W1_BUILD_EPOCH_COUNTERFACTUAL_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(BUILD_GRAPH_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(BUILD_GRAPH_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W1_ORACLE_RUNNER)"
	test -s "$(W1_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(BUILD_GRAPH_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(BUILD_GRAPH_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_ORACLE_RUNNER)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W1_BUILD_EPOCH_COUNTERFACTUAL_INPUTS)"
	sha256sum -c "$(W1_BUILD_EPOCH_COUNTERFACTUAL_INPUTS)" >/dev/null
	printf '{"event":"w1-build-epoch-input","run_id":"%s","result_level":"kvm_build_graph_epoch_counterfactual","input_sha256_file":"w1-build-epoch-counterfactual-inputs.sha256","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"build_policy":"build_graph_view.bpf.c","table_policy":"table_redirect.bpf.c","max_table_update_write_ratio":%s}\n' "$(RUN_ID)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W1_ORACLE_RUNNER_SOURCE)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" >>"$(W1_BUILD_EPOCH_COUNTERFACTUAL_JSON)"
	"$(W1_ORACLE_RUNNER)" --build-epoch-counterfactual "$(W1_BUILD_EPOCH_COUNTERFACTUAL_JSON)" /sys/fs/cgroup "$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(BUILD_GRAPH_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES)" --argjson objects "$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)" --argjson max_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" -s '([.[] | select(.event == "w1-build-epoch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_static_expected_failure_observed == true and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == true and $$s.targeted_c8_budget_failure == true and $$s.state_dependent_branch_not_static_table_expressible == true and $$s.table_update_write_ratio > $$max_ratio and $$s.max_table_update_write_ratio == $$max_ratio and $$s.materialized_current_oracle_pass == true and $$s.materialized_feature_equivalent_baseline == true and $$s.materialized_update_budget_failure == true and $$s.materialized_update_write_ratio > $$max_ratio and $$s.fuse_current_oracle_pass == true and $$s.fuse_feature_equivalent_baseline == true and $$s.fuse_update_budget_failure == true and $$s.fuse_update_write_ratio > $$max_ratio and $$s.fuse_mounts == $$samples and $$s.real_redis_nginx_trace == false and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false' "$(W1_BUILD_EPOCH_COUNTERFACTUAL_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w1-build-epoch-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w1-build-epoch-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w1-build-epoch-done","run_id":"%s","result_level":"kvm_build_graph_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W1_BUILD_EPOCH_COUNTERFACTUAL_OBJECTS)" >>"$(W1_BUILD_EPOCH_COUNTERFACTUAL_JSON)"

kvm-w2-oracle: $(KERNEL_IMAGE) bpf w1-oracle workload-w2-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_oracle RUN_ID=$(RUN_ID)"

__phase1_guest_w2_oracle:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w2-oracle-start","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/w2-oracle.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W2_ORACLE_ENTRIES_TSV)"
	test -s "$(W2_NGINX_FIXTURE_MANIFEST)"
	test -s "$(W2_POSTGRES_FIXTURE_MANIFEST)"
	test -s "$(SANDBOX_FIXTURE_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W2_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W2_ORACLE_ENTRIES_TSV)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_POSTGRES_FIXTURE_MANIFEST)" "$(SANDBOX_FIXTURE_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(SANDBOX_FIXTURE_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w2-oracle-inputs.sha256"
	printf '{"event":"w2-oracle-input","run_id":"%s","result_level":"kvm_policy_path_oracle","input_sha256_file":"w2-oracle-inputs.sha256","entries_tsv":"%s","nginx_fixture_manifest":"%s","postgres_fixture_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W2_ORACLE_ENTRIES_TSV)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_POSTGRES_FIXTURE_MANIFEST)" "$(W2_ORACLE_RUNNER_SOURCE)" >>"$(PHASE1_RESULT_DIR)/w2-oracle.jsonl"
	"$(W2_ORACLE_RUNNER)" --sandbox-fixture "$(PHASE1_RESULT_DIR)/w2-oracle.jsonl" /sys/fs/cgroup "$(W2_ORACLE_ENTRIES_TSV)" "$(SANDBOX_FIXTURE_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-oracle.log"
	printf '{"event":"w2-oracle-done","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/w2-oracle.jsonl"

kvm-w2-nginx-real: $(KERNEL_IMAGE) bpf w1-oracle workload-nginx-build workload-nginx-fixture-manifest
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_nginx_real RUN_ID=$(RUN_ID)"

__phase1_guest_w2_nginx_real:
	install -d "$(PHASE1_RESULT_DIR)" "$(W2_NGINX_REAL_WORK_DIR)"
	printf '{"event":"w2-nginx-real-start","run_id":"%s","result_level":"kvm_real_app_health_oracle"}\n' "$(RUN_ID)" >"$(W2_NGINX_REAL_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -x "$(W2_NGINX_BIN)"
	test -s "$(W2_NGINX_FIXTURE_CONF)"
	test -s "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(W2_NGINX_MIME_TYPES)"
	test -s "$(W2_NGINX_FIXTURE_MANIFEST)"
	grep -Eq '^[[:space:]]*include[[:space:]]+upstream[.]sock[[:space:]]*;' "$(W2_NGINX_FIXTURE_CONF)"
	grep -Fxq 'proxy_pass http://127.0.0.1:18080;' "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(SANDBOX_FIXTURE_POLICY_SOURCE)"
	test -s "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	sha256sum "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY_SOURCE)" "$(SANDBOX_FIXTURE_POLICY)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w2-nginx-real-inputs.sha256"
	sha256sum -c "$(PHASE1_RESULT_DIR)/w2-nginx-real-inputs.sha256" >/dev/null
	printf '{"event":"w2-nginx-real-input","run_id":"%s","result_level":"kvm_real_app_health_oracle","input_sha256_file":"w2-nginx-real-inputs.sha256","nginx_binary":"%s","fixture_config":"%s","endpoint_fixture":"%s","mime_types":"%s","fixture_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_ORACLE_RUNNER_SOURCE)" >>"$(W2_NGINX_REAL_JSON)"
	"$(W2_ORACLE_RUNNER)" --sandbox-nginx-smoke "$(W2_NGINX_REAL_JSON)" /sys/fs/cgroup "$(W2_NGINX_REAL_WORK_DIR)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-real.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-real.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w2-nginx-real-done","run_id":"%s","result_level":"kvm_real_app_health_oracle"}\n' "$(RUN_ID)" >>"$(W2_NGINX_REAL_JSON)"

kvm-w2-nginx-real-trace: $(KERNEL_IMAGE) bpf w1-oracle workload-nginx-build workload-nginx-fixture-manifest
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_nginx_real_trace RUN_ID=$(RUN_ID)"

__phase1_guest_w2_nginx_real_trace:
	install -d "$(PHASE1_RESULT_DIR)" "$(W2_NGINX_REAL_TRACE_WORK_DIR)"
	printf '{"event":"w2-nginx-real-trace-start","run_id":"%s","result_level":"kvm_real_app_no_production_trace_oracle"}\n' "$(RUN_ID)" >"$(W2_NGINX_REAL_TRACE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	command -v strace >"$(PHASE1_RESULT_DIR)/w2-nginx-real-trace-strace.path"
	strace -V >"$(PHASE1_RESULT_DIR)/w2-nginx-real-trace-strace.version"
	test -x "$(W2_NGINX_BIN)"
	test -s "$(W2_NGINX_FIXTURE_CONF)"
	test -s "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(W2_NGINX_MIME_TYPES)"
	test -s "$(W2_NGINX_FIXTURE_MANIFEST)"
	grep -Eq '^[[:space:]]*include[[:space:]]+upstream[.]sock[[:space:]]*;' "$(W2_NGINX_FIXTURE_CONF)"
	grep -Fxq 'proxy_pass http://127.0.0.1:18080;' "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(SANDBOX_FIXTURE_POLICY_SOURCE)"
	test -s "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w2-nginx-real-trace-gate.md"
	sha256sum "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY_SOURCE)" "$(SANDBOX_FIXTURE_POLICY)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w2-nginx-real-trace-strace.version" "$(ROOT_DIR)/docs/tmp/2026-06-17-w2-nginx-real-trace-gate.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W2_NGINX_REAL_TRACE_INPUTS)"
	sha256sum -c "$(W2_NGINX_REAL_TRACE_INPUTS)" >/dev/null
	printf '{"event":"w2-nginx-real-trace-input","run_id":"%s","result_level":"kvm_real_app_no_production_trace_oracle","input_sha256_file":"w2-nginx-real-trace-inputs.sha256","nginx_binary":"%s","fixture_config":"%s","endpoint_fixture":"%s","mime_types":"%s","fixture_manifest":"%s","runner_source":"%s","strace_version_file":"w2-nginx-real-trace-strace.version"}\n' "$(RUN_ID)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_ORACLE_RUNNER_SOURCE)" >>"$(W2_NGINX_REAL_TRACE_JSON)"
	"$(W2_ORACLE_RUNNER)" --sandbox-nginx-trace "$(W2_NGINX_REAL_TRACE_JSON)" /sys/fs/cgroup "$(W2_NGINX_REAL_TRACE_WORK_DIR)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-test.strace.log"
	test -s "$(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-start.strace.log"
	test -s "$(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-quit.strace.log"
	prod_pattern='nginx[.]prod[.]conf|upstream[.]prod|server[.]prod[.]crt|db[.]prod[.]pass|prod[.]real[.]token'; \
	fixture_pattern='nginx[.]conf|upstream[.]sock'; \
	attached_logs="$(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-test.strace.log $(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-start.strace.log $(W2_NGINX_REAL_TRACE_WORK_DIR)/attached-nginx-quit.strace.log"; \
	attached_prod_open_count=$$({ grep -Eh "$$prod_pattern" $$attached_logs || true; } | wc -l); \
	attached_fixture_open_count=$$({ grep -Eh "$$fixture_pattern" $$attached_logs || true; } | wc -l); \
	attached_config_fixture_open_count=$$({ grep -Eh 'nginx[.]conf' $$attached_logs || true; } | wc -l); \
	attached_endpoint_fixture_open_count=$$({ grep -Eh 'upstream[.]sock' $$attached_logs || true; } | wc -l); \
	jq -cn --arg run_id "$(RUN_ID)" --arg path_class "production_decoy" --argjson opened_count "$$attached_prod_open_count" '{event:"w2-nginx-real-trace-open", run_id:$$run_id, result_level:"kvm_real_app_no_production_trace_oracle", path_class:$$path_class, opened_real_production:($$opened_count > 0), opened_expected_fixture:false, opened_count:$$opened_count, trace_scope:"attached_nginx_commands"}' >>"$(W2_NGINX_REAL_TRACE_JSON)"; \
	jq -cn --arg run_id "$(RUN_ID)" --arg path_class "fixture_alias" --argjson opened_count "$$attached_fixture_open_count" --argjson config_count "$$attached_config_fixture_open_count" --argjson endpoint_count "$$attached_endpoint_fixture_open_count" '{event:"w2-nginx-real-trace-open", run_id:$$run_id, result_level:"kvm_real_app_no_production_trace_oracle", path_class:$$path_class, opened_real_production:false, opened_expected_fixture:($$opened_count > 0), opened_count:$$opened_count, config_fixture_open_count:$$config_count, endpoint_fixture_open_count:$$endpoint_count, trace_scope:"attached_nginx_commands"}' >>"$(W2_NGINX_REAL_TRACE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-real-trace.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-real-trace.log"); \
	jq -n -c \
		--slurpfile rows "$(W2_NGINX_REAL_TRACE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg inputs "$(W2_NGINX_REAL_TRACE_INPUTS)" \
		--argjson dmesg_issues "$$dmesg_issues" \
		'([$$rows[] | select(.event == "w2-nginx-real-summary")][0] // {}) as $$s | ([ $$rows[] | select(.event == "w2-nginx-real" and .op == "pre_attach_nginx_test" and .pass == true) ] | length == 1) as $$pre | ([ $$rows[] | select(.event == "w2-nginx-real" and .op == "post_detach_nginx_test" and .pass == true) ] | length == 1) as $$post | ([ $$rows[] | select(.event == "w2-nginx-real" and .op == "attached_http_health" and .pass == true) ] | length == 1) as $$health | ([ $$rows[] | select(.event == "w2-nginx-real" and .op == "attached_endpoint_upstream" and .pass == true) ] | length == 1) as $$upstream | (([ $$rows[] | select(.event == "w2-nginx-real" and .op == "load" and .pass == true) ] | length == 1) and ([ $$rows[] | select(.event == "w2-nginx-real" and .op == "attach" and .pass == true) ] | length == 1)) as $$policy | ([ $$rows[] | select(.event == "w2-nginx-real-trace-open" and .path_class == "production_decoy") ][0] // {opened_count:1}) as $$prod | ([ $$rows[] | select(.event == "w2-nginx-real-trace-open" and .path_class == "fixture_alias") ][0] // {opened_count:0, config_fixture_open_count:0, endpoint_fixture_open_count:0}) as $$fixture | ($$prod.opened_count == 0) as $$no_prod | (($$fixture.config_fixture_open_count // 0) > 0 and ($$fixture.endpoint_fixture_open_count // 0) > 0) as $$fixture_seen | ($$s.pass == true and $$pre and $$post and $$health and $$upstream and $$policy and $$no_prod and $$fixture_seen and $$dmesg_issues == 0) as $$pass | {event:"w2-nginx-real-trace-summary", schema:"namei_ext.eval_osdi.w2_nginx_real_trace.v1", run_id:$$run_id, result_level:"kvm_real_app_no_production_trace_oracle", workload:"w2-nginx-fixture", app:"nginx", pass:$$pass, w2_real_trace_gate_pass:$$pass, real_app_health_pass:($$s.pass == true), endpoint_health_pass:$$health, upstream_seen:$$upstream, pre_attach_rejected:$$pre, post_detach_rejected:$$post, policy_executed:$$policy, kvm_validated:true, no_real_production_open_pass:$$no_prod, opened_real_production:($$prod.opened_count > 0), opened_expected_fixture:$$fixture_seen, attached_production_decoy_opens:$$prod.opened_count, attached_fixture_alias_opens:$$fixture.opened_count, attached_config_fixture_alias_opens:$$fixture.config_fixture_open_count, attached_endpoint_fixture_alias_opens:$$fixture.endpoint_fixture_open_count, dmesg_clean:($$dmesg_issues == 0), dmesg_issues:$$dmesg_issues, input_sha256_file:$$inputs, release_gate_pass:false, paper_release_gate_candidate:true, scope:"w2_nginx_fixture_real_trace"}' >>"$(W2_NGINX_REAL_TRACE_JSON)"
	jq -e -s '([.[] | select(.event == "w2-nginx-real-trace-summary" and .pass == true and .w2_real_trace_gate_pass == true and .no_real_production_open_pass == true and .opened_expected_fixture == true and .endpoint_health_pass == true and .upstream_seen == true and .pre_attach_rejected == true and .post_detach_rejected == true and .policy_executed == true and .kvm_validated == true and .dmesg_clean == true)] | length) == 1' "$(W2_NGINX_REAL_TRACE_JSON)" >/dev/null
	printf '{"event":"w2-nginx-real-trace-done","run_id":"%s","result_level":"kvm_real_app_no_production_trace_oracle"}\n' "$(RUN_ID)" >>"$(W2_NGINX_REAL_TRACE_JSON)"

kvm-w2-nginx-macrobench: $(KERNEL_IMAGE) bpf w1-oracle workload-nginx-build workload-nginx-fixture-manifest
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_nginx_macrobench RUN_ID=$(RUN_ID) W2_NGINX_MACROBENCH_SAMPLES=$(W2_NGINX_MACROBENCH_SAMPLES)"

__phase1_guest_w2_nginx_macrobench:
	install -d "$(PHASE1_RESULT_DIR)" "$(W2_NGINX_MACROBENCH_WORK_DIR)"
	printf '{"event":"w2-nginx-macrobench-start","run_id":"%s","result_level":"kvm_workload_setup_update_poc","samples":%s}\n' "$(RUN_ID)" "$(W2_NGINX_MACROBENCH_SAMPLES)" >"$(W2_NGINX_MACROBENCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -x "$(W2_NGINX_BIN)"
	test -s "$(W2_NGINX_FIXTURE_CONF)"
	test -s "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(W2_NGINX_MIME_TYPES)"
	test -s "$(W2_NGINX_FIXTURE_MANIFEST)"
	grep -Eq '^[[:space:]]*include[[:space:]]+upstream[.]sock[[:space:]]*;' "$(W2_NGINX_FIXTURE_CONF)"
	grep -Fxq 'proxy_pass http://127.0.0.1:18080;' "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(SANDBOX_FIXTURE_POLICY_SOURCE)"
	test -s "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	sha256sum "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY_SOURCE)" "$(SANDBOX_FIXTURE_POLICY)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" "$(ROOT_DIR)/mk/kvm.mk" >"$(W2_NGINX_MACROBENCH_INPUTS)"
	sha256sum -c "$(W2_NGINX_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w2-nginx-macrobench-input","run_id":"%s","result_level":"kvm_workload_setup_update_poc","input_sha256_file":"w2-nginx-macrobench-inputs.sha256","nginx_binary":"%s","fixture_config":"%s","endpoint_fixture":"%s","mime_types":"%s","fixture_manifest":"%s","runner_source":"%s","samples":%s}\n' "$(RUN_ID)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_NGINX_MACROBENCH_SAMPLES)" >>"$(W2_NGINX_MACROBENCH_JSON)"
	"$(W2_ORACLE_RUNNER)" --sandbox-nginx-macrobench "$(W2_NGINX_MACROBENCH_JSON)" /sys/fs/cgroup "$(W2_NGINX_MACROBENCH_WORK_DIR)" "$(W2_NGINX_MACROBENCH_SAMPLES)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(SANDBOX_FIXTURE_POLICY)"
	test "$$(jq -s '[.[] | select(.event == "w2-nginx-macrobench-setup" and .pass == true)] | length' "$(W2_NGINX_MACROBENCH_JSON)")" = "$(W2_NGINX_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w2-nginx-macrobench-update" and .pass == true)] | length' "$(W2_NGINX_MACROBENCH_JSON)")" = "$(W2_NGINX_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w2-nginx-macrobench-correctness" and .pass == true)] | length' "$(W2_NGINX_MACROBENCH_JSON)")" = "$(W2_NGINX_MACROBENCH_SAMPLES)"
	jq -e --argjson samples "$(W2_NGINX_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w2-nginx-macrobench-summary")][0]) as $$s | $$s.samples == $$samples and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W2_NGINX_MACROBENCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w2-nginx-macrobench-done","run_id":"%s","result_level":"kvm_workload_setup_update_poc","samples":%s}\n' "$(RUN_ID)" "$(W2_NGINX_MACROBENCH_SAMPLES)" >>"$(W2_NGINX_MACROBENCH_JSON)"

kvm-w2-nginx-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle workload-nginx-build workload-nginx-fixture-manifest
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_nginx_baseline_macrobench RUN_ID=$(RUN_ID) W2_NGINX_BASELINE_MACROBENCH_SAMPLES=$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES) W2_NGINX_BASELINES='$(W2_NGINX_BASELINES)'"

__phase1_guest_w2_nginx_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)" "$(W2_NGINX_BASELINE_MACROBENCH_WORK_DIR)"
	printf '{"event":"w2-nginx-baseline-macrobench-start","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES)" "$(W2_NGINX_BASELINES)" >"$(W2_NGINX_BASELINE_MACROBENCH_JSON)"
	test -x "$(W2_NGINX_BIN)"
	test -s "$(W2_NGINX_FIXTURE_CONF)"
	test -s "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(W2_NGINX_MIME_TYPES)"
	test -s "$(W2_NGINX_FIXTURE_MANIFEST)"
	grep -Eq '^[[:space:]]*include[[:space:]]+upstream[.]sock[[:space:]]*;' "$(W2_NGINX_FIXTURE_CONF)"
	grep -Fxq 'proxy_pass http://127.0.0.1:18080;' "$(W2_NGINX_ENDPOINT_FIXTURE)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	sha256sum "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" "$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-feature-baseline-design.md" >"$(W2_NGINX_BASELINE_MACROBENCH_INPUTS)"
	sha256sum -c "$(W2_NGINX_BASELINE_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w2-nginx-baseline-macrobench-input","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","input_sha256_file":"w2-nginx-baseline-macrobench-inputs.sha256","nginx_binary":"%s","fixture_config":"%s","endpoint_fixture":"%s","mime_types":"%s","fixture_manifest":"%s","runner_source":"%s","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_NGINX_FIXTURE_MANIFEST)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES)" "$(W2_NGINX_BASELINES)" >>"$(W2_NGINX_BASELINE_MACROBENCH_JSON)"
	"$(W2_ORACLE_RUNNER)" --sandbox-nginx-baseline-macrobench "$(W2_NGINX_BASELINE_MACROBENCH_JSON)" "$(W2_NGINX_BASELINE_MACROBENCH_WORK_DIR)" "$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES)" "$(W2_NGINX_BIN)" "$(W2_NGINX_FIXTURE_CONF)" "$(W2_NGINX_ENDPOINT_FIXTURE)" "$(W2_NGINX_MIME_TYPES)" "$(W2_NGINX_BASELINES)"
	jq -e --argjson samples "$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w2-nginx-baseline-summary")][0]) as $$s | $$s.samples == $$samples and $$s.baseline_count > 0 and $$s.setup_rows == ($$samples * $$s.baseline_count) and $$s.update_rows == ($$samples * $$s.baseline_count) and $$s.correctness_rows == ($$samples * $$s.baseline_count) and $$s.pass == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W2_NGINX_BASELINE_MACROBENCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-baseline-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w2-nginx-baseline-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w2-nginx-baseline-macrobench-done","run_id":"%s","result_level":"kvm_workload_feature_baseline_input","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W2_NGINX_BASELINE_MACROBENCH_SAMPLES)" "$(W2_NGINX_BASELINES)" >>"$(W2_NGINX_BASELINE_MACROBENCH_JSON)"

kvm-w2-fixture-epoch-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w2_fixture_epoch_counterfactual RUN_ID=$(RUN_ID) W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES=$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES) W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS=$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)"

__phase1_guest_w2_fixture_epoch_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_WORK_DIR)"
	printf '{"event":"w2-fixture-epoch-start","run_id":"%s","result_level":"kvm_sandbox_fixture_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)" >"$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(SANDBOX_FIXTURE_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(SANDBOX_FIXTURE_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W2_ORACLE_RUNNER)"
	test -s "$(W2_ORACLE_RUNNER_SOURCE)"
	sha256sum "$(SANDBOX_FIXTURE_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(SANDBOX_FIXTURE_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_ORACLE_RUNNER)" "$(ROOT_DIR)/mk/kvm.mk" >"$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_INPUTS)"
	sha256sum -c "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_INPUTS)" >/dev/null
	printf '{"event":"w2-fixture-epoch-input","run_id":"%s","result_level":"kvm_sandbox_fixture_epoch_counterfactual","input_sha256_file":"w2-fixture-epoch-counterfactual-inputs.sha256","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"fixture_policy":"sandbox_fixture_view.bpf.c","table_policy":"table_redirect.bpf.c","max_table_update_write_ratio":%s}\n' "$(RUN_ID)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W2_ORACLE_RUNNER_SOURCE)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" >>"$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON)"
	"$(W2_ORACLE_RUNNER)" --sandbox-fixture-epoch-counterfactual "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON)" /sys/fs/cgroup "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(SANDBOX_FIXTURE_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES)" --argjson objects "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)" --argjson max_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" -s '([.[] | select(.event == "w2-fixture-epoch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_static_expected_failure_observed == true and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == true and $$s.targeted_c8_budget_failure == true and $$s.state_dependent_branch_not_static_table_expressible == true and $$s.table_update_write_ratio > $$max_ratio and $$s.max_table_update_write_ratio == $$max_ratio and $$s.materialized_current_oracle_pass == true and $$s.materialized_feature_equivalent_baseline == true and $$s.materialized_update_budget_failure == true and $$s.materialized_update_write_ratio > $$max_ratio and $$s.fuse_current_oracle_pass == true and $$s.fuse_feature_equivalent_baseline == true and $$s.fuse_update_budget_failure == true and $$s.fuse_update_write_ratio > $$max_ratio and $$s.fuse_mounts == $$samples and $$s.real_nginx_trace == false and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false' "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w2-fixture-epoch-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w2-fixture-epoch-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w2-fixture-epoch-done","run_id":"%s","result_level":"kvm_sandbox_fixture_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_OBJECTS)" >>"$(W2_FIXTURE_EPOCH_COUNTERFACTUAL_JSON)"

kvm-w3-oracle: $(KERNEL_IMAGE) bpf w1-oracle workload-w3-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_oracle RUN_ID=$(RUN_ID)"

__phase1_guest_w3_oracle:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-oracle-start","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/w3-oracle.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_REDIS_CHECKPOINT_MANIFEST)"
	test -s "$(W3_NGINX_CHECKPOINT_MANIFEST)"
	test -s "$(CHECKPOINT_RESTORE_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CHECKPOINT_RESTORE_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W3_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_NGINX_CHECKPOINT_MANIFEST)" "$(CHECKPOINT_RESTORE_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CHECKPOINT_RESTORE_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w3-oracle-inputs.sha256"
	printf '{"event":"w3-oracle-input","run_id":"%s","result_level":"kvm_policy_path_oracle","input_sha256_file":"w3-oracle-inputs.sha256","entries_tsv":"%s","redis_checkpoint_manifest":"%s","nginx_checkpoint_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_NGINX_CHECKPOINT_MANIFEST)" "$(W3_ORACLE_RUNNER_SOURCE)" >>"$(PHASE1_RESULT_DIR)/w3-oracle.jsonl"
	"$(W3_ORACLE_RUNNER)" --checkpoint-restore "$(PHASE1_RESULT_DIR)/w3-oracle.jsonl" /sys/fs/cgroup "$(W3_ORACLE_ENTRIES_TSV)" "$(CHECKPOINT_RESTORE_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-oracle.log"
	printf '{"event":"w3-oracle-done","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/w3-oracle.jsonl"

kvm-w3-redis-replay: $(KERNEL_IMAGE) bpf w1-oracle workload-redis-build workload-w3-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_redis_replay RUN_ID=$(RUN_ID)"

__phase1_guest_w3_redis_replay:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-redis-replay-start","run_id":"%s","result_level":"kvm_checkpoint_restore_replay_witness"}\n' "$(RUN_ID)" >"$(W3_REDIS_REPLAY_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_REDIS_CHECKPOINT_MANIFEST)"
	test -s "$(CHECKPOINT_RESTORE_POLICY_SOURCE)"
	test -s "$(CHECKPOINT_RESTORE_POLICY)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	test -x "$(W3_REDIS_REPLAY_REDIS_BIN)"
	rm -rf "$(W3_REDIS_REPLAY_WORK_DIR)"
	install -d "$(W3_REDIS_REPLAY_WORK_DIR)"
	sha256sum "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(CHECKPOINT_RESTORE_POLICY_SOURCE)" "$(CHECKPOINT_RESTORE_POLICY)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" "$(W3_REDIS_REPLAY_REDIS_BIN)" >"$(PHASE1_RESULT_DIR)/w3-redis-replay-inputs.sha256"
	printf '{"event":"w3-redis-replay-input","run_id":"%s","result_level":"kvm_checkpoint_restore_replay_witness","input_sha256_file":"w3-redis-replay-inputs.sha256","entries_tsv":"%s","redis_checkpoint_manifest":"%s","redis_binary":"%s","work_dir":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(W3_REDIS_REPLAY_WORK_DIR)" "$(W3_ORACLE_RUNNER_SOURCE)" >>"$(W3_REDIS_REPLAY_JSON)"
	"$(W3_ORACLE_RUNNER)" --checkpoint-redis-replay "$(W3_REDIS_REPLAY_JSON)" /sys/fs/cgroup "$(W3_REDIS_REPLAY_WORK_DIR)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(CHECKPOINT_RESTORE_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-redis-replay.log"
	printf '{"event":"w3-redis-replay-done","run_id":"%s","result_level":"kvm_checkpoint_restore_replay_witness"}\n' "$(RUN_ID)" >>"$(W3_REDIS_REPLAY_JSON)"

kvm-w3-redis-table-replay: $(KERNEL_IMAGE) bpf w1-oracle workload-redis-build workload-w3-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_redis_table_replay RUN_ID=$(RUN_ID)"

__phase1_guest_w3_redis_table_replay:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-redis-replay-start","run_id":"%s","result_level":"kvm_checkpoint_restore_table_replay_witness"}\n' "$(RUN_ID)" >"$(W3_REDIS_TABLE_REPLAY_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_REDIS_CHECKPOINT_MANIFEST)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	test -x "$(W3_REDIS_REPLAY_REDIS_BIN)"
	rm -rf "$(W3_REDIS_TABLE_REPLAY_WORK_DIR)"
	install -d "$(W3_REDIS_TABLE_REPLAY_WORK_DIR)"
	sha256sum "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" "$(W3_REDIS_REPLAY_REDIS_BIN)" >"$(PHASE1_RESULT_DIR)/w3-redis-table-replay-inputs.sha256"
	printf '{"event":"w3-redis-replay-input","run_id":"%s","result_level":"kvm_checkpoint_restore_table_replay_witness","input_sha256_file":"w3-redis-table-replay-inputs.sha256","entries_tsv":"%s","redis_checkpoint_manifest":"%s","redis_binary":"%s","work_dir":"%s","runner_source":"%s","policy":"table_redirect.bpf.c"}\n' "$(RUN_ID)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(W3_REDIS_TABLE_REPLAY_WORK_DIR)" "$(W3_ORACLE_RUNNER_SOURCE)" >>"$(W3_REDIS_TABLE_REPLAY_JSON)"
	"$(W3_ORACLE_RUNNER)" --checkpoint-redis-table-replay "$(W3_REDIS_TABLE_REPLAY_JSON)" /sys/fs/cgroup "$(W3_REDIS_TABLE_REPLAY_WORK_DIR)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-redis-table-replay.log"
	printf '{"event":"w3-redis-replay-done","run_id":"%s","result_level":"kvm_checkpoint_restore_table_replay_witness"}\n' "$(RUN_ID)" >>"$(W3_REDIS_TABLE_REPLAY_JSON)"

kvm-w3-redis-counterfactual: $(KERNEL_IMAGE) kvm-w3-redis-replay kvm-w3-redis-table-replay
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_redis_counterfactual RUN_ID=$(RUN_ID)"

__phase1_guest_w3_redis_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-redis-counterfactual-start","run_id":"%s","result_level":"kvm_checkpoint_restore_counterfactual_accounting"}\n' "$(RUN_ID)" >"$(W3_REDIS_COUNTERFACTUAL_JSON)"
	test -s "$(W3_REDIS_REPLAY_JSON)"
	test -s "$(W3_REDIS_TABLE_REPLAY_JSON)"
	test -s "$(PHASE1_RESULT_DIR)/w3-redis-replay-inputs.sha256"
	test -s "$(PHASE1_RESULT_DIR)/w3-redis-table-replay-inputs.sha256"
	sha256sum "$(W3_REDIS_REPLAY_JSON)" "$(W3_REDIS_TABLE_REPLAY_JSON)" "$(PHASE1_RESULT_DIR)/w3-redis-replay-inputs.sha256" "$(PHASE1_RESULT_DIR)/w3-redis-table-replay-inputs.sha256" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W3_REDIS_COUNTERFACTUAL_INPUTS)"
	printf '{"event":"w3-redis-counterfactual-input","run_id":"%s","result_level":"kvm_checkpoint_restore_counterfactual_accounting","input_sha256_file":"w3-redis-counterfactual-inputs.sha256","policy_replay_json":"%s","table_replay_json":"%s"}\n' "$(RUN_ID)" "$(W3_REDIS_REPLAY_JSON)" "$(W3_REDIS_TABLE_REPLAY_JSON)" >>"$(W3_REDIS_COUNTERFACTUAL_JSON)"
	policy_pass=$$(jq -sr '[.[] | select(.event == "w3-redis-replay-summary")][0].pass // false' "$(W3_REDIS_REPLAY_JSON)"); \
	policy_failures=$$(jq -sr '[.[] | select(.event == "w3-redis-replay-summary")][0].failures // 1' "$(W3_REDIS_REPLAY_JSON)"); \
	table_pass=$$(jq -sr '[.[] | select(.event == "w3-redis-replay-summary")][0].pass // false' "$(W3_REDIS_TABLE_REPLAY_JSON)"); \
	table_failures=$$(jq -sr '[.[] | select(.event == "w3-redis-replay-summary")][0].failures // 1' "$(W3_REDIS_TABLE_REPLAY_JSON)"); \
	table_loaded=$$(jq -sr '[.[] | select(.event == "w3-redis-replay-summary")][0].redis_checkpoint_loaded_via_policy // false' "$(W3_REDIS_TABLE_REPLAY_JSON)"); \
	table_rules=$$(jq -s '[.[] | select(.event == "w3-redis-replay" and .op == "populate_table_rules" and .pass == true)] | if length == 1 then .[0].actual | tonumber else 0 end' "$(W3_REDIS_TABLE_REPLAY_JSON)"); \
	test "$$policy_pass" = "true"; \
	test "$$policy_failures" = "0"; \
	test "$$table_failures" = "0"; \
	test "$$table_loaded" = "true"; \
	test "$$table_rules" = "2"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson table_rules "$$table_rules" --argjson policy_pass "$$policy_pass" --argjson table_pass "$$table_pass" '{event:"w3-redis-counterfactual", run_id:$$run_id, result_level:"kvm_checkpoint_restore_counterfactual_accounting", workload:"w3-redis-podman-criu", run_environment:"kvm", real_redis_replay:true, policy_family:"checkpoint_restore_view.bpf.c", table_policy:"table_redirect.bpf.c", checkpoint_policy_executed:true, table_policy_executed:true, kvm_validated:true, policy_replay_pass:$$policy_pass, table_replay_pass:$$table_pass, table_baseline_current_oracle_pass:$$table_pass, table_rule_writes:$$table_rules, table_update_writes_accounted:$$table_rules, table_budget_failure:false, podman_criu_restore_executed:false, post_restore_vfs_replay:true, zero_mixed_epoch_checker:false, restore_trace_checker:false, qualified_for_c8:false, pass:true, failures:0, detail:"same Redis checkpoint replay passed with checkpoint_restore and table_redirect; this is negative C8 evidence until a release restore/update/stale oracle makes table-only fail or exceed budget"}' >>"$(W3_REDIS_COUNTERFACTUAL_JSON)"
	jq -cn --arg run_id "$(RUN_ID)" '{event:"w3-redis-counterfactual-summary", run_id:$$run_id, result_level:"kvm_checkpoint_restore_counterfactual_accounting", workload:"w3-redis-podman-criu", run_environment:"kvm", pass:true, failures:0, real_redis_replay:true, table_baseline_current_oracle_pass:true, table_budget_failure:false, zero_mixed_epoch_checker:false, restore_trace_checker:false, qualified_for_c8:false, detail:"counterfactual accounting preserves W3 negative C8 evidence: table-only exact redirects pass the current Redis replay"}' >>"$(W3_REDIS_COUNTERFACTUAL_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-redis-counterfactual.log"
	printf '{"event":"w3-redis-counterfactual-done","run_id":"%s","result_level":"kvm_checkpoint_restore_counterfactual_accounting"}\n' "$(RUN_ID)" >>"$(W3_REDIS_COUNTERFACTUAL_JSON)"

kvm-w3-checkpoint-epoch-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_checkpoint_epoch_counterfactual RUN_ID=$(RUN_ID) W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES=$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES) W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS=$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)"

__phase1_guest_w3_checkpoint_epoch_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_WORK_DIR)"
	printf '{"event":"w3-checkpoint-epoch-start","run_id":"%s","result_level":"kvm_checkpoint_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)" >"$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(CHECKPOINT_RESTORE_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CHECKPOINT_RESTORE_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(CHECKPOINT_RESTORE_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CHECKPOINT_RESTORE_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_INPUTS)"
	sha256sum -c "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_INPUTS)" >/dev/null
	printf '{"event":"w3-checkpoint-epoch-input","run_id":"%s","result_level":"kvm_checkpoint_epoch_counterfactual","input_sha256_file":"w3-checkpoint-epoch-counterfactual-inputs.sha256","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"checkpoint_policy":"checkpoint_restore_view.bpf.c","table_policy":"table_redirect.bpf.c","max_table_update_write_ratio":%s}\n' "$(RUN_ID)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" >>"$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON)"
	"$(W3_ORACLE_RUNNER)" --checkpoint-epoch-counterfactual "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON)" /sys/fs/cgroup "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_WORK_DIR)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)" "$(CHECKPOINT_RESTORE_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES)" --argjson objects "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)" --argjson max_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" -s '([.[] | select(.event == "w3-checkpoint-epoch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_static_expected_failure_observed == true and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == true and $$s.targeted_c8_budget_failure == true and $$s.table_update_write_ratio > $$max_ratio and $$s.max_table_update_write_ratio == $$max_ratio and $$s.materialized_current_oracle_pass == true and $$s.materialized_feature_equivalent_baseline == true and $$s.materialized_update_budget_failure == true and $$s.materialized_update_write_ratio > $$max_ratio and $$s.fuse_current_oracle_pass == true and $$s.fuse_feature_equivalent_baseline == true and $$s.fuse_update_budget_failure == true and $$s.fuse_update_write_ratio > $$max_ratio and $$s.fuse_mounts == $$samples and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false' "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-checkpoint-epoch-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w3-checkpoint-epoch-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w3-checkpoint-epoch-done","run_id":"%s","result_level":"kvm_checkpoint_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_SAMPLES)" "$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_OBJECTS)" >>"$(W3_CHECKPOINT_EPOCH_COUNTERFACTUAL_JSON)"

kvm-w3-redis-policy-macrobench: $(KERNEL_IMAGE) bpf w1-oracle workload-redis-build workload-w3-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_redis_policy_macrobench RUN_ID=$(RUN_ID) W3_REDIS_POLICY_MACROBENCH_SAMPLES=$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)"

__phase1_guest_w3_redis_policy_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-redis-policy-macrobench-start","run_id":"%s","result_level":"kvm_workload_checkpoint_policy_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)" >"$(W3_REDIS_POLICY_MACROBENCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_REDIS_CHECKPOINT_MANIFEST)"
	test -s "$(CHECKPOINT_RESTORE_POLICY_SOURCE)"
	test -s "$(CHECKPOINT_RESTORE_POLICY)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	test -x "$(W3_REDIS_REPLAY_REDIS_BIN)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md"
	rm -rf "$(W3_REDIS_POLICY_MACROBENCH_WORK_DIR)"
	install -d "$(W3_REDIS_POLICY_MACROBENCH_WORK_DIR)"
	sha256sum "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(CHECKPOINT_RESTORE_POLICY_SOURCE)" "$(CHECKPOINT_RESTORE_POLICY)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W3_REDIS_POLICY_MACROBENCH_INPUTS)"
	sha256sum -c "$(W3_REDIS_POLICY_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w3-redis-policy-macrobench-input","run_id":"%s","result_level":"kvm_workload_checkpoint_policy_setup_update_input","input_sha256_file":"w3-redis-policy-macrobench-inputs.sha256","entries_tsv":"%s","redis_checkpoint_manifest":"%s","redis_binary":"%s","work_dir":"%s","runner_source":"%s","samples":%s}\n' "$(RUN_ID)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(W3_REDIS_POLICY_MACROBENCH_WORK_DIR)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)" >>"$(W3_REDIS_POLICY_MACROBENCH_JSON)"
	"$(W3_ORACLE_RUNNER)" --checkpoint-redis-policy-macrobench "$(W3_REDIS_POLICY_MACROBENCH_JSON)" /sys/fs/cgroup "$(W3_REDIS_POLICY_MACROBENCH_WORK_DIR)" "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(CHECKPOINT_RESTORE_POLICY)"
	test "$$(jq -s '[.[] | select(.event == "w3-redis-policy-macrobench-setup" and .pass == true and .policy_executed == true)] | length' "$(W3_REDIS_POLICY_MACROBENCH_JSON)")" = "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w3-redis-policy-macrobench-update" and .pass == true and .policy_executed == true)] | length' "$(W3_REDIS_POLICY_MACROBENCH_JSON)")" = "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w3-redis-policy-macrobench-correctness" and .pass == true and .pre_attach_absent == true and .attached_get_pass == true and .readdir_pass == true and .post_update_get_pass == true and .post_detach_absent == true)] | length' "$(W3_REDIS_POLICY_MACROBENCH_JSON)")" = "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)"
	jq -e --argjson samples "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w3-redis-policy-macrobench-summary")][0]) as $$s | $$s.samples == $$samples and $$s.systems == 1 and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.policy_executed == true and $$s.feature_equivalent_baseline == false and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W3_REDIS_POLICY_MACROBENCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-redis-policy-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w3-redis-policy-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w3-redis-policy-macrobench-done","run_id":"%s","result_level":"kvm_workload_checkpoint_policy_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W3_REDIS_POLICY_MACROBENCH_SAMPLES)" >>"$(W3_REDIS_POLICY_MACROBENCH_JSON)"

kvm-w3-redis-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle workload-redis-build workload-w3-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w3_redis_baseline_macrobench RUN_ID=$(RUN_ID) W3_REDIS_BASELINE_MACROBENCH_SAMPLES=$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES) W3_REDIS_BASELINES='$(W3_REDIS_BASELINES)'"

__phase1_guest_w3_redis_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w3-redis-baseline-macrobench-start","run_id":"%s","result_level":"kvm_external_checkpoint_baseline","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)" "$(W3_REDIS_BASELINES)" >"$(W3_REDIS_BASELINE_MACROBENCH_JSON)"
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_REDIS_CHECKPOINT_MANIFEST)"
	test -s "$(W3_ORACLE_RUNNER)"
	test -s "$(W3_ORACLE_RUNNER_SOURCE)"
	test -x "$(W3_REDIS_REPLAY_REDIS_BIN)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md"
	rm -rf "$(W3_REDIS_BASELINE_MACROBENCH_WORK_DIR)"
	install -d "$(W3_REDIS_BASELINE_MACROBENCH_WORK_DIR)"
	sha256sum "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_ORACLE_RUNNER)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W3_REDIS_BASELINE_MACROBENCH_INPUTS)"
	sha256sum -c "$(W3_REDIS_BASELINE_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w3-redis-baseline-macrobench-input","run_id":"%s","result_level":"kvm_external_checkpoint_baseline","input_sha256_file":"w3-redis-baseline-macrobench-inputs.sha256","entries_tsv":"%s","redis_checkpoint_manifest":"%s","redis_binary":"%s","work_dir":"%s","runner_source":"%s","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W3_REDIS_CHECKPOINT_MANIFEST)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(W3_REDIS_BASELINE_MACROBENCH_WORK_DIR)" "$(W3_ORACLE_RUNNER_SOURCE)" "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)" "$(W3_REDIS_BASELINES)" >>"$(W3_REDIS_BASELINE_MACROBENCH_JSON)"
	"$(W3_ORACLE_RUNNER)" --checkpoint-redis-baseline-macrobench "$(W3_REDIS_BASELINE_MACROBENCH_JSON)" "$(W3_REDIS_BASELINE_MACROBENCH_WORK_DIR)" "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)" "$(W3_REDIS_REPLAY_REDIS_BIN)" "$(W3_REDIS_BASELINES)"
	jq -e --argjson samples "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w3-redis-baseline-macrobench-summary")][0]) as $$s | $$s.samples == $$samples and $$s.baseline_count > 0 and $$s.setup_rows == ($$samples * $$s.baseline_count) and $$s.update_rows == ($$samples * $$s.baseline_count) and $$s.correctness_rows == ($$samples * $$s.baseline_count) and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W3_REDIS_BASELINE_MACROBENCH_JSON)" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "w3-redis-baseline-macrobench-setup" and .baseline == "fuse_redirect" and .pass == true and .fuse_mounts == 1)] | length' "$(W3_REDIS_BASELINE_MACROBENCH_JSON)")" = "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)"
	test "$$(jq -s '[.[] | select(.event == "w3-redis-baseline-macrobench-correctness" and .baseline == "fuse_redirect" and .pass == true and .initial_get_pass == true and .readdir_pass == true and .hidden_backing_absent == true and .post_update_get_pass == true)] | length' "$(W3_REDIS_BASELINE_MACROBENCH_JSON)")" = "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w3-redis-baseline-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w3-redis-baseline-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w3-redis-baseline-macrobench-done","run_id":"%s","result_level":"kvm_external_checkpoint_baseline","samples":%s,"selected_baselines":"%s"}\n' "$(RUN_ID)" "$(W3_REDIS_BASELINE_MACROBENCH_SAMPLES)" "$(W3_REDIS_BASELINES)" >>"$(W3_REDIS_BASELINE_MACROBENCH_JSON)"

kvm-w4-oracle: $(KERNEL_IMAGE) bpf w1-oracle workload-w4-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_oracle RUN_ID=$(RUN_ID)"

__phase1_guest_w4_oracle:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-oracle-start","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/w4-oracle.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_ORACLE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_MANIFEST)"
	test -s "$(W4_BUILDKIT_MANIFEST)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w4-oracle-inputs.sha256"
	printf '{"event":"w4-oracle-input","run_id":"%s","result_level":"kvm_policy_path_oracle","input_sha256_file":"w4-oracle-inputs.sha256","entries_tsv":"%s","ccache_manifest":"%s","buildkit_manifest":"%s","runner_source":"%s"}\n' "$(RUN_ID)" "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(W4_ORACLE_RUNNER_SOURCE)" >>"$(PHASE1_RESULT_DIR)/w4-oracle.jsonl"
	"$(W4_ORACLE_RUNNER)" --cache-locality "$(PHASE1_RESULT_DIR)/w4-oracle.jsonl" /sys/fs/cgroup "$(W4_ORACLE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-oracle.log"
	printf '{"event":"w4-oracle-done","run_id":"%s","result_level":"kvm_policy_path_oracle"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/w4-oracle.jsonl"

kvm-w4-cache-content: $(KERNEL_IMAGE) bpf w1-oracle workload-w4-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_cache_content RUN_ID=$(RUN_ID)"

__phase1_guest_w4_cache_content:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CACHE_CONTENT_WORK_DIR)"
	printf '{"event":"w4-cache-content-start","run_id":"%s","result_level":"kvm_cache_content_oracle"}\n' "$(RUN_ID)" >"$(W4_CACHE_CONTENT_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_ORACLE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_MANIFEST)"
	test -s "$(W4_BUILDKIT_MANIFEST)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w4-cache-content-inputs.sha256"
	sha256sum -c "$(PHASE1_RESULT_DIR)/w4-cache-content-inputs.sha256" >/dev/null
	printf '{"event":"w4-cache-content-input","run_id":"%s","result_level":"kvm_cache_content_oracle","input_sha256_file":"w4-cache-content-inputs.sha256","entries_tsv":"%s","ccache_manifest":"%s","buildkit_manifest":"%s","runner_source":"%s","work_dir":"%s"}\n' "$(RUN_ID)" "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CACHE_CONTENT_WORK_DIR)" >>"$(W4_CACHE_CONTENT_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-content "$(W4_CACHE_CONTENT_JSON)" /sys/fs/cgroup "$(W4_CACHE_CONTENT_WORK_DIR)" "$(W4_ORACLE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-cache-content.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-cache-content.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-cache-content-done","run_id":"%s","result_level":"kvm_cache_content_oracle"}\n' "$(RUN_ID)" >>"$(W4_CACHE_CONTENT_JSON)"

kvm-w4-cache-table-content: $(KERNEL_IMAGE) bpf w1-oracle workload-w4-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_cache_table_content RUN_ID=$(RUN_ID)"

__phase1_guest_w4_cache_table_content:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CACHE_TABLE_CONTENT_WORK_DIR)"
	printf '{"event":"w4-cache-table-content-start","run_id":"%s","result_level":"kvm_cache_table_content_oracle"}\n' "$(RUN_ID)" >"$(W4_CACHE_TABLE_CONTENT_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_ORACLE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_MANIFEST)"
	test -s "$(W4_BUILDKIT_MANIFEST)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w4-cache-table-content-inputs.sha256"
	sha256sum -c "$(PHASE1_RESULT_DIR)/w4-cache-table-content-inputs.sha256" >/dev/null
	printf '{"event":"w4-cache-table-content-input","run_id":"%s","result_level":"kvm_cache_table_content_oracle","input_sha256_file":"w4-cache-table-content-inputs.sha256","entries_tsv":"%s","ccache_manifest":"%s","buildkit_manifest":"%s","runner_source":"%s","work_dir":"%s"}\n' "$(RUN_ID)" "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CACHE_TABLE_CONTENT_WORK_DIR)" >>"$(W4_CACHE_TABLE_CONTENT_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-table-content "$(W4_CACHE_TABLE_CONTENT_JSON)" /sys/fs/cgroup "$(W4_CACHE_TABLE_CONTENT_WORK_DIR)" "$(W4_ORACLE_ENTRIES_TSV)" "$(TABLE_REDIRECT_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-cache-table-content.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-cache-table-content.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-cache-table-content-done","run_id":"%s","result_level":"kvm_cache_table_content_oracle"}\n' "$(RUN_ID)" >>"$(W4_CACHE_TABLE_CONTENT_JSON)"

kvm-w4-cache-transition-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle workload-w4-oracle-entries
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_cache_transition_counterfactual RUN_ID=$(RUN_ID) W4_CACHE_TRANSITION_SAMPLES=$(W4_CACHE_TRANSITION_SAMPLES)"

__phase1_guest_w4_cache_transition_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CACHE_TRANSITION_WORK_DIR)"
	printf '{"event":"w4-cache-transition-start","run_id":"%s","result_level":"kvm_cache_state_transition_counterfactual","samples":%s}\n' "$(RUN_ID)" "$(W4_CACHE_TRANSITION_SAMPLES)" >"$(W4_CACHE_TRANSITION_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_ORACLE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_MANIFEST)"
	test -s "$(W4_BUILDKIT_MANIFEST)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_ORACLE_ENTRIES_TSV)"
	sha256sum "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CACHE_TRANSITION_INPUTS)"
	sha256sum -c "$(W4_CACHE_TRANSITION_INPUTS)" >/dev/null
	printf '{"event":"w4-cache-transition-input","run_id":"%s","result_level":"kvm_cache_state_transition_counterfactual","input_sha256_file":"w4-cache-transition-counterfactual-inputs.sha256","entries_tsv":"%s","ccache_manifest":"%s","buildkit_manifest":"%s","runner_source":"%s","work_dir":"%s","samples":%s}\n' "$(RUN_ID)" "$(W4_ORACLE_ENTRIES_TSV)" "$(W4_CCACHE_MANIFEST)" "$(W4_BUILDKIT_MANIFEST)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CACHE_TRANSITION_WORK_DIR)" "$(W4_CACHE_TRANSITION_SAMPLES)" >>"$(W4_CACHE_TRANSITION_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-transition-counterfactual "$(W4_CACHE_TRANSITION_JSON)" /sys/fs/cgroup "$(W4_CACHE_TRANSITION_SAMPLES)" "$(W4_CACHE_TRANSITION_WORK_DIR)" "$(W4_ORACLE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W4_CACHE_TRANSITION_SAMPLES)" -s '([.[] | select(.event == "w4-cache-transition-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == false and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false and $$s.static_wrong_local_hits > 0 and $$s.policy_transition_rows > 0 and $$s.table_transition_rows > 0 and $$s.state_transition_hit_rate >= 1' "$(W4_CACHE_TRANSITION_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-cache-transition-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-cache-transition-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-cache-transition-done","run_id":"%s","result_level":"kvm_cache_state_transition_counterfactual","samples":%s}\n' "$(RUN_ID)" "$(W4_CACHE_TRANSITION_SAMPLES)" >>"$(W4_CACHE_TRANSITION_JSON)"

kvm-w4-cache-epoch-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_cache_epoch_counterfactual RUN_ID=$(RUN_ID) W4_CACHE_EPOCH_SAMPLES=$(W4_CACHE_EPOCH_SAMPLES) W4_CACHE_EPOCH_OBJECTS=$(W4_CACHE_EPOCH_OBJECTS)"

__phase1_guest_w4_cache_epoch_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CACHE_EPOCH_WORK_DIR)"
	printf '{"event":"w4-cache-epoch-start","run_id":"%s","result_level":"kvm_cache_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CACHE_EPOCH_SAMPLES)" "$(W4_CACHE_EPOCH_OBJECTS)" >"$(W4_CACHE_EPOCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CACHE_EPOCH_INPUTS)"
	sha256sum -c "$(W4_CACHE_EPOCH_INPUTS)" >/dev/null
	printf '{"event":"w4-cache-epoch-input","run_id":"%s","result_level":"kvm_cache_epoch_counterfactual","input_sha256_file":"w4-cache-epoch-counterfactual-inputs.sha256","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"cache_policy":"cache_locality_view.bpf.c","table_policy":"table_redirect.bpf.c","max_table_update_write_ratio":%s}\n' "$(RUN_ID)" "$(W4_CACHE_EPOCH_WORK_DIR)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CACHE_EPOCH_SAMPLES)" "$(W4_CACHE_EPOCH_OBJECTS)" "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" >>"$(W4_CACHE_EPOCH_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-epoch-counterfactual "$(W4_CACHE_EPOCH_JSON)" /sys/fs/cgroup "$(W4_CACHE_EPOCH_SAMPLES)" "$(W4_CACHE_EPOCH_WORK_DIR)" "$(W4_CACHE_EPOCH_OBJECTS)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W4_CACHE_EPOCH_SAMPLES)" --argjson objects "$(W4_CACHE_EPOCH_OBJECTS)" --argjson max_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" -s '([.[] | select(.event == "w4-cache-epoch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_static_expected_failure_observed == true and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == true and $$s.targeted_c8_budget_failure == true and $$s.table_update_write_ratio > $$max_ratio and $$s.max_table_update_write_ratio == $$max_ratio and $$s.materialized_current_oracle_pass == true and $$s.materialized_feature_equivalent_baseline == true and $$s.materialized_update_budget_failure == true and $$s.materialized_update_write_ratio > $$max_ratio and $$s.fuse_current_oracle_pass == true and $$s.fuse_feature_equivalent_baseline == true and $$s.fuse_update_budget_failure == true and $$s.fuse_update_write_ratio > $$max_ratio and $$s.fuse_mounts == $$samples and $$s.real_ccache_trace == false and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false' "$(W4_CACHE_EPOCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-cache-epoch-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-cache-epoch-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-cache-epoch-done","run_id":"%s","result_level":"kvm_cache_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CACHE_EPOCH_SAMPLES)" "$(W4_CACHE_EPOCH_OBJECTS)" >>"$(W4_CACHE_EPOCH_JSON)"

kvm-w4-ccache-real: $(KERNEL_IMAGE) bpf w1-oracle workload-redis-build workload-nginx-build
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_real RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_real:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-real-start","run_id":"%s","result_level":"kvm_real_ccache_workload_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_REAL_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_REAL_REDIS_SRC)"
	test -s "$(W4_CCACHE_REAL_NGINX_SRC)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-real-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-real-ccache.version"
	rm -rf "$(W4_CCACHE_REAL_WORK_DIR)"
	install -d "$(W4_CCACHE_REAL_WORK_DIR)" "$(W4_CCACHE_REAL_WORK_DIR)/policy-work"
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache --clear >/dev/null
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache --zero-stats >/dev/null
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache gcc -I"$(REDIS_BUILD_SRC)/src" -c "$(W4_CCACHE_REAL_REDIS_SRC)" -o "$(W4_CCACHE_REAL_WORK_DIR)/redis.cold.o"
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache gcc -I"$(REDIS_BUILD_SRC)/src" -c "$(W4_CCACHE_REAL_REDIS_SRC)" -o "$(W4_CCACHE_REAL_WORK_DIR)/redis.hot.o"
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache gcc -I"$(NGINX_BUILD_SRC)/objs" -I"$(NGINX_BUILD_SRC)/src/core" -I"$(NGINX_BUILD_SRC)/src/event" -I"$(NGINX_BUILD_SRC)/src/event/modules" -I"$(NGINX_BUILD_SRC)/src/os/unix" -c "$(W4_CCACHE_REAL_NGINX_SRC)" -o "$(W4_CCACHE_REAL_WORK_DIR)/nginx.cold.o"
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache gcc -I"$(NGINX_BUILD_SRC)/objs" -I"$(NGINX_BUILD_SRC)/src/core" -I"$(NGINX_BUILD_SRC)/src/event" -I"$(NGINX_BUILD_SRC)/src/event/modules" -I"$(NGINX_BUILD_SRC)/src/os/unix" -c "$(W4_CCACHE_REAL_NGINX_SRC)" -o "$(W4_CCACHE_REAL_WORK_DIR)/nginx.hot.o"
	CCACHE_DIR="$(W4_CCACHE_REAL_WORK_DIR)/ccache" ccache --print-stats >"$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"
	sha256sum "$(W4_CCACHE_REAL_WORK_DIR)/redis.cold.o" "$(W4_CCACHE_REAL_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_REAL_WORK_DIR)/nginx.cold.o" "$(W4_CCACHE_REAL_WORK_DIR)/nginx.hot.o" >"$(PHASE1_RESULT_DIR)/w4-ccache-real-outputs.sha256"
	redis_cold_sha=$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w4-ccache-real-outputs.sha256" | awk '{print $$1}'); \
	redis_hot_sha=$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w4-ccache-real-outputs.sha256" | awk '{print $$1}'); \
	nginx_cold_sha=$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w4-ccache-real-outputs.sha256" | awk '{print $$1}'); \
	nginx_hot_sha=$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w4-ccache-real-outputs.sha256" | awk '{print $$1}'); \
	cache_miss=$$(awk '$$1 == "cache_miss" { print $$2 }' "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { print $$2 }' "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { print $$2 }' "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"); \
	local_write=$$(awk '$$1 == "local_storage_write" { print $$2 }' "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"); \
	files_in_cache=$$(awk '$$1 == "files_in_cache" { print $$2 }' "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt"); \
	test "$$redis_cold_sha" = "$$redis_hot_sha"; \
	test "$$nginx_cold_sha" = "$$nginx_hot_sha"; \
	test "$$cache_miss" -ge 2; \
	test "$$direct_hit" -ge 2; \
	printf 'w4-ccache-redis-nginx\tverified_hit\treal-cache\t.\tredis.object.o\tredis.object.local\t%s\t%s\n' "$(W4_CCACHE_REAL_WORK_DIR)/redis.hot.o" "$$redis_hot_sha" >"$(W4_CCACHE_REAL_ENTRIES_TSV)"; \
	printf 'w4-ccache-redis-nginx\tverified_hit\treal-cache\t.\tnginx.object.o\tnginx.object.local\t%s\t%s\n' "$(W4_CCACHE_REAL_WORK_DIR)/nginx.hot.o" "$$nginx_hot_sha" >>"$(W4_CCACHE_REAL_ENTRIES_TSV)"; \
	jq -cn --arg run_id "$(RUN_ID)" --arg redis_source "$(W4_CCACHE_REAL_REDIS_SRC)" --arg nginx_source "$(W4_CCACHE_REAL_NGINX_SRC)" --arg redis_sha "$$redis_hot_sha" --arg nginx_sha "$$nginx_hot_sha" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson files_in_cache "$$files_in_cache" '{event:"w4-ccache-real", run_id:$$run_id, result_level:"kvm_real_ccache_workload_witness", workload:"w4-ccache-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_run:true, policy_executed:false, kvm_validated:true, output_hash_match:true, redis_source:$$redis_source, nginx_source:$$nginx_source, redis_object_sha256:$$redis_sha, nginx_object_sha256:$$nginx_sha, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, files_in_cache:$$files_in_cache, qualified_for_c8:false, detail:"real ccache cold/hot compiles over Redis and nginx source produced matching object hashes and cache hits"}' >>"$(W4_CCACHE_REAL_JSON)"
	sha256sum "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(W4_CCACHE_REAL_ENTRIES_TSV)" "$(PHASE1_RESULT_DIR)/w4-ccache-real-stats.txt" "$(PHASE1_RESULT_DIR)/w4-ccache-real-ccache.version" >"$(PHASE1_RESULT_DIR)/w4-ccache-real-inputs.sha256"
	printf '{"event":"w4-ccache-real-input","run_id":"%s","result_level":"kvm_real_ccache_workload_witness","input_sha256_file":"w4-ccache-real-inputs.sha256","entries_tsv":"%s","stats_file":"w4-ccache-real-stats.txt","output_sha256_file":"w4-ccache-real-outputs.sha256"}\n' "$(RUN_ID)" "$(W4_CCACHE_REAL_ENTRIES_TSV)" >>"$(W4_CCACHE_REAL_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-content "$(W4_CCACHE_REAL_JSON)" /sys/fs/cgroup "$(W4_CCACHE_REAL_WORK_DIR)/policy-work" "$(W4_CCACHE_REAL_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)"
	policy_failures=$$(jq -s '[.[] | select(.event == "w4-cache-content-summary") | .failures] | add // 0' "$(W4_CCACHE_REAL_JSON)"); \
	test "$$policy_failures" = "0"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson policy_failures "$$policy_failures" '{event:"w4-ccache-real-summary", run_id:$$run_id, result_level:"kvm_real_ccache_workload_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", real_ccache_run:true, policy_executed:true, kvm_validated:true, output_hash_match:true, policy_content_oracle_failures:$$policy_failures, pass:true, failures:0, qualified_for_c8:false, detail:"real ccache transition witness and cache_locality policy content oracle passed; release-level C8 remains blocked by operation-weighted policy cache hit rate and table/update counterfactual"}' >>"$(W4_CCACHE_REAL_JSON)"
	printf '{"event":"w4-ccache-real-policy-scope","run_id":"%s","result_level":"kvm_real_ccache_workload_witness","workload":"w4-ccache-redis-nginx","ccache_compile_policy_executed":false,"policy_content_oracle_executed":true,"qualified_for_c8":false,"detail":"ccache cold/hot compile did not execute namei_ext policy; only the subsequent cache_locality content oracle executed policy over ccache-derived objects"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_REAL_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-real.log"
	printf '{"event":"w4-ccache-real-done","run_id":"%s","result_level":"kvm_real_ccache_workload_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_REAL_JSON)"

kvm-w4-ccache-trace: $(KERNEL_IMAGE) workload-redis-build workload-nginx-build
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_trace RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_trace:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-trace-start","run_id":"%s","result_level":"kvm_real_ccache_cache_path_trace_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_TRACE_JSON)"
	test -s "$(W4_CCACHE_REAL_REDIS_SRC)"
	test -s "$(W4_CCACHE_REAL_NGINX_SRC)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-ccache.path"
	command -v strace >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-strace.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-ccache.version"
	strace -V >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-strace.version"
	sha256sum "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-ccache.version" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-strace.version" >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256"
	printf '{"event":"w4-ccache-trace-input","run_id":"%s","result_level":"kvm_real_ccache_cache_path_trace_witness","input_sha256_file":"w4-ccache-trace-inputs.sha256","redis_source":"%s","nginx_source":"%s","ccache_version_file":"w4-ccache-trace-ccache.version","strace_version_file":"w4-ccache-trace-strace.version"}\n' "$(RUN_ID)" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" >>"$(W4_CCACHE_TRACE_JSON)"
	rm -rf "$(W4_CCACHE_TRACE_WORK_DIR)"
	install -d "$(W4_CCACHE_TRACE_WORK_DIR)"
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" ccache --clear >/dev/null
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" ccache --zero-stats >/dev/null
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" ccache gcc -I"$(REDIS_BUILD_SRC)/src" -c "$(W4_CCACHE_REAL_REDIS_SRC)" -o "$(W4_CCACHE_TRACE_WORK_DIR)/redis.cold.o"
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" strace -f -e trace=%file -o "$(W4_CCACHE_TRACE_REDIS_LOG)" ccache gcc -I"$(REDIS_BUILD_SRC)/src" -c "$(W4_CCACHE_REAL_REDIS_SRC)" -o "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o"
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" ccache gcc -I"$(NGINX_BUILD_SRC)/objs" -I"$(NGINX_BUILD_SRC)/src/core" -I"$(NGINX_BUILD_SRC)/src/event" -I"$(NGINX_BUILD_SRC)/src/event/modules" -I"$(NGINX_BUILD_SRC)/src/os/unix" -c "$(W4_CCACHE_REAL_NGINX_SRC)" -o "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.cold.o"
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" strace -f -e trace=%file -o "$(W4_CCACHE_TRACE_NGINX_LOG)" ccache gcc -I"$(NGINX_BUILD_SRC)/objs" -I"$(NGINX_BUILD_SRC)/src/core" -I"$(NGINX_BUILD_SRC)/src/event" -I"$(NGINX_BUILD_SRC)/src/event/modules" -I"$(NGINX_BUILD_SRC)/src/os/unix" -c "$(W4_CCACHE_REAL_NGINX_SRC)" -o "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o"
	CCACHE_DIR="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" ccache --print-stats >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt"
	sha256sum "$(W4_CCACHE_TRACE_WORK_DIR)/redis.cold.o" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.cold.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(W4_CCACHE_TRACE_REDIS_LOG)" "$(W4_CCACHE_TRACE_NGINX_LOG)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt" >"$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256"
	redis_cold_sha=$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" | awk '{print $$1}'); \
	redis_hot_sha=$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" | awk '{print $$1}'); \
	nginx_cold_sha=$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" | awk '{print $$1}'); \
	nginx_hot_sha=$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" | awk '{print $$1}'); \
	redis_trace_lines=$$(wc -l <"$(W4_CCACHE_TRACE_REDIS_LOG)"); \
	nginx_trace_lines=$$(wc -l <"$(W4_CCACHE_TRACE_NGINX_LOG)"); \
	redis_cache_path_lines=$$(awk -v p="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 { n++ } END { print n + 0 }' "$(W4_CCACHE_TRACE_REDIS_LOG)"); \
	nginx_cache_path_lines=$$(awk -v p="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 { n++ } END { print n + 0 }' "$(W4_CCACHE_TRACE_NGINX_LOG)"); \
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-trace-stats.txt"); \
	test "$$redis_cold_sha" = "$$redis_hot_sha"; \
	test "$$nginx_cold_sha" = "$$nginx_hot_sha"; \
	test "$$redis_trace_lines" -gt 0; \
	test "$$nginx_trace_lines" -gt 0; \
	test "$$redis_cache_path_lines" -gt 0; \
	test "$$nginx_cache_path_lines" -gt 0; \
	test "$$cache_miss" -ge 2; \
	test "$$direct_hit" -ge 2; \
	jq -cn --arg run_id "$(RUN_ID)" --arg redis_source "$(W4_CCACHE_REAL_REDIS_SRC)" --arg nginx_source "$(W4_CCACHE_REAL_NGINX_SRC)" --arg cache_dir "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" --arg redis_trace "w4-ccache-trace-redis.strace.log" --arg nginx_trace "w4-ccache-trace-nginx.strace.log" --arg artifacts_sha256 "w4-ccache-trace-artifacts.sha256" --arg stats_file "w4-ccache-trace-stats.txt" --argjson redis_trace_lines "$$redis_trace_lines" --argjson nginx_trace_lines "$$nginx_trace_lines" --argjson redis_cache_path_lines "$$redis_cache_path_lines" --argjson nginx_cache_path_lines "$$nginx_cache_path_lines" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" '{event:"w4-ccache-cache-path-trace", run_id:$$run_id, result_level:"kvm_real_ccache_cache_path_trace_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, output_hash_match:true, redis_source:$$redis_source, nginx_source:$$nginx_source, ccache_cache_dir:$$cache_dir, redis_trace_file_ops:$$redis_trace_lines, nginx_trace_file_ops:$$nginx_trace_lines, redis_cache_path_file_ops:$$redis_cache_path_lines, nginx_cache_path_file_ops:$$nginx_cache_path_lines, cache_path_file_ops:($$redis_cache_path_lines + $$nginx_cache_path_lines), cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, redis_trace_file:$$redis_trace, nginx_trace_file:$$nginx_trace, stats_file:$$stats_file, artifacts_sha256_file:$$artifacts_sha256, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, qualified_for_c8:false, detail:"real ccache hot compiles touched CCACHE_DIR paths under KVM; this is workload cache-path evidence, not namei_ext policy execution"}' >>"$(W4_CCACHE_TRACE_JSON)"; \
	jq -cn --arg run_id "$(RUN_ID)" '{event:"w4-ccache-trace-summary", run_id:$$run_id, result_level:"kvm_real_ccache_cache_path_trace_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", pass:true, failures:0, real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, qualified_for_c8:false, detail:"real ccache cache-path trace witness passed; release-level policy hit rate and stale/corrupt transitions remain blockers"}' >>"$(W4_CCACHE_TRACE_JSON)"
	printf '{"event":"w4-ccache-trace-policy-scope","run_id":"%s","result_level":"kvm_real_ccache_cache_path_trace_witness","workload":"w4-ccache-redis-nginx","ccache_compile_policy_executed":false,"policy_content_oracle_executed":false,"qualified_for_c8":false,"detail":"this target traces real ccache file operations only; it does not attach or execute namei_ext policy"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_TRACE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-trace.log"
	printf '{"event":"w4-ccache-trace-done","run_id":"%s","result_level":"kvm_real_ccache_cache_path_trace_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_TRACE_JSON)"

kvm-w4-ccache-policy-bridge: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-trace
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_policy_bridge RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_policy_bridge:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CCACHE_BRIDGE_WORK_DIR)"
	printf '{"event":"w4-ccache-policy-bridge-start","run_id":"%s","result_level":"kvm_real_ccache_policy_bridge_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_BRIDGE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_TRACE_JSON)"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256"
	test -s "$(W4_CCACHE_TRACE_REDIS_LOG)"
	test -s "$(W4_CCACHE_TRACE_NGINX_LOG)"
	test -d "$(W4_CCACHE_TRACE_WORK_DIR)/ccache"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	awk -v p="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 && /openat[(]/ && /O_RDONLY/ && / = [0-9]+$$/ && $$0 !~ /ccache[.]conf|stats|stats[.]alive|stats[.]lock|stats[.]tmp/ { line = $$0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); print line }' "$(W4_CCACHE_TRACE_REDIS_LOG)" | sort -u | awk '{ printf "redis\t%s\n", $$0 }' >"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	awk -v p="$(W4_CCACHE_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 && /openat[(]/ && /O_RDONLY/ && / = [0-9]+$$/ && $$0 !~ /ccache[.]conf|stats|stats[.]alive|stats[.]lock|stats[.]tmp/ { line = $$0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); print line }' "$(W4_CCACHE_TRACE_NGINX_LOG)" | sort -u | awk '{ printf "nginx\t%s\n", $$0 }' >>"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	redis_entries=$$(awk -F '	' '$$1 == "redis" { n++ } END { print n + 0 }' "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	nginx_entries=$$(awk -F '	' '$$1 == "nginx" { n++ } END { print n + 0 }' "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	total_entries=$$(wc -l <"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	test "$$redis_entries" -gt 0; \
	test "$$nginx_entries" -gt 0; \
	test "$$total_entries" -le 128
	: >"$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	while IFS="	" read -r source original; do \
		test -s "$$original"; \
		case "$$source" in redis|nginx) ;; *) exit 1 ;; esac; \
		case "$$original" in "$(W4_CCACHE_TRACE_WORK_DIR)/ccache/"*) ;; *) exit 1 ;; esac; \
		rel="$${original#$(W4_CCACHE_TRACE_WORK_DIR)/ccache/}"; \
		case "$$rel" in ""|"."|".."|../*|*/../*|*/..) exit 1 ;; esac; \
		parent_rel=$$(dirname "$$rel"); \
		base=$$(basename "$$rel"); \
		case "$$base" in ""|*/*|.|..) exit 1 ;; esac; \
		test "$${#base}" -le 249; \
		sha=$$(sha256sum "$$original" | awk '{ print $$1 }'); \
		printf 'w4-ccache-redis-nginx\tverified_hit\ttrace-derived/%s/%s\t.\t%s\t%s.local\t%s\t%s\n' "$$source" "$$parent_rel" "$$base" "$$base" "$$original" "$$sha" >>"$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"; \
	done <"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test "$$(wc -l <"$(W4_CCACHE_BRIDGE_ENTRIES_TSV)")" = "$$(wc -l <"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)")"
	awk -F '	' 'NF == 8 && $$1 == "w4-ccache-redis-nginx" && $$2 == "verified_hit" && $$3 ~ /^trace-derived\/(redis|nginx)\// && $$4 == "." && $$5 != "" && $$6 == ($$5 ".local") && $$7 != "" && length($$8) == 64 { n++ } END { exit !(n > 1) }' "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	sha256sum "$(W4_CCACHE_TRACE_JSON)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" "$(W4_CCACHE_TRACE_REDIS_LOG)" "$(W4_CCACHE_TRACE_NGINX_LOG)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" >"$(PHASE1_RESULT_DIR)/w4-ccache-policy-bridge-inputs.sha256"
	printf '{"event":"w4-ccache-policy-bridge-input","run_id":"%s","result_level":"kvm_real_ccache_policy_bridge_witness","input_sha256_file":"w4-ccache-policy-bridge-inputs.sha256","trace_json":"%s","trace_objects":"%s","entries_tsv":"%s","work_dir":"%s","policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_TRACE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_WORK_DIR)" >>"$(W4_CCACHE_BRIDGE_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-content "$(W4_CCACHE_BRIDGE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BRIDGE_WORK_DIR)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)"
	policy_failures=$$(jq -s '[.[] | select(.event == "w4-cache-content-summary") | .failures] | add // 0' "$(W4_CCACHE_BRIDGE_JSON)"); \
	redis_entries=$$(awk -F '	' '$$1 == "redis" { n++ } END { print n + 0 }' "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	nginx_entries=$$(awk -F '	' '$$1 == "nginx" { n++ } END { print n + 0 }' "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	total_entries=$$(wc -l <"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	attached_matches=$$(jq -s '[.[] | select(.event == "w4-cache-content" and .op == "attached_expected_match" and .pass == true)] | length' "$(W4_CCACHE_BRIDGE_JSON)"); \
	readdir_aliases=$$(jq -s '[.[] | select(.event == "w4-cache-content" and .op == "readdir_alias" and .pass == true)] | length' "$(W4_CCACHE_BRIDGE_JSON)"); \
	test "$$policy_failures" = "0"; \
	test "$$attached_matches" = "$$total_entries"; \
	test "$$readdir_aliases" = "$$total_entries"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson policy_failures "$$policy_failures" --argjson redis_entries "$$redis_entries" --argjson nginx_entries "$$nginx_entries" --argjson total_entries "$$total_entries" '{event:"w4-ccache-policy-bridge-summary", run_id:$$run_id, result_level:"kvm_real_ccache_policy_bridge_witness", workload:"w4-ccache-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_trace_basis:true, ccache_cache_path_trace:true, trace_derived_policy_oracle_executed:true, ccache_compile_policy_executed:false, policy_executed:true, kvm_validated:true, trace_objects:$$total_entries, entries:$$total_entries, redis_trace_objects:$$redis_entries, nginx_trace_objects:$$nginx_entries, policy_content_oracle_failures:$$policy_failures, pass:true, failures:0, qualified_for_c8:false, detail:"trace-derived ccache cache object components executed cache_locality policy content oracle; real ccache compile still did not execute namei_ext policy"}' >>"$(W4_CCACHE_BRIDGE_JSON)"
	printf '{"event":"w4-ccache-policy-bridge-policy-scope","run_id":"%s","result_level":"kvm_real_ccache_policy_bridge_witness","workload":"w4-ccache-redis-nginx","ccache_compile_policy_executed":false,"trace_derived_policy_oracle_executed":true,"operation_weighted_policy_cache_hit_rate":false,"operation_weighted_policy_hit_rate_is_release":false,"qualified_for_c8":false,"detail":"policy executed only in the trace-derived cache object oracle, not during the real ccache compile"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_BRIDGE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-policy-bridge.log"
	printf '{"event":"w4-ccache-policy-bridge-done","run_id":"%s","result_level":"kvm_real_ccache_policy_bridge_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_BRIDGE_JSON)"

kvm-w4-ccache-bulk-trace: $(KERNEL_IMAGE) workload-redis-build workload-nginx-build
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_trace RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_bulk_trace:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-trace-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_path_trace_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_BULK_TRACE_JSON)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-ccache.path"
	command -v strace >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-strace.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-ccache.version"
	strace -V >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-strace.version"
	: >"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	for f in $(W4_CCACHE_BULK_REDIS_SRCS); do test -s "$(REDIS_BUILD_SRC)/$$f"; sha=$$(sha256sum "$(REDIS_BUILD_SRC)/$$f" | awk '{ print $$1 }'); printf 'redis\t%s\t%s\t%s\n' "$$f" "$(REDIS_BUILD_SRC)/$$f" "$$sha" >>"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"; done
	for f in $(W4_CCACHE_BULK_NGINX_SRCS); do test -s "$(NGINX_BUILD_SRC)/$$f"; sha=$$(sha256sum "$(NGINX_BUILD_SRC)/$$f" | awk '{ print $$1 }'); printf 'nginx\t%s\t%s\t%s\n' "$$f" "$(NGINX_BUILD_SRC)/$$f" "$$sha" >>"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"; done
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); test "$$source_count" -gt 1
	sha256sum "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-ccache.version" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-strace.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-ccache-workload-design.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_TRACE_INPUTS)"
	printf '{"event":"w4-ccache-bulk-trace-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_path_trace_witness","input_sha256_file":"w4-ccache-bulk-trace-inputs.sha256","source_manifest":"w4-ccache-bulk-source-manifest.tsv","redis_sources":%s,"nginx_sources":%s}\n' "$(RUN_ID)" "$$(awk -F '	' '$$1 == "redis" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)")" "$$(awk -F '	' '$$1 == "nginx" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)")" >>"$(W4_CCACHE_BULK_TRACE_JSON)"
	rm -rf "$(W4_CCACHE_BULK_TRACE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" ccache --clear >/dev/null
	CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" ccache --zero-stats >/dev/null
	for f in $(W4_CCACHE_BULK_REDIS_SRCS); do name=$${f//\//_}; name=$${name%.c}; CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" ccache gcc -I"$(REDIS_BUILD_SRC)/src" -c "$(REDIS_BUILD_SRC)/$$f" -o "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold/redis-$$name.o"; done
	for f in $(W4_CCACHE_BULK_NGINX_SRCS); do name=$${f//\//_}; name=$${name%.c}; CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" ccache gcc -I"$(NGINX_BUILD_SRC)/objs" -I"$(NGINX_BUILD_SRC)/src/core" -I"$(NGINX_BUILD_SRC)/src/event" -I"$(NGINX_BUILD_SRC)/src/event/modules" -I"$(NGINX_BUILD_SRC)/src/os/unix" -c "$(NGINX_BUILD_SRC)/$$f" -o "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold/nginx-$$name.o"; done
	CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" strace -f -e trace=%file -o "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)" bash -c 'set -e; redis_src="$(REDIS_BUILD_SRC)"; out="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"; for f in $(W4_CCACHE_BULK_REDIS_SRCS); do name=$${f//\//_}; name=$${name%.c}; ccache gcc -I"$$redis_src/src" -c "$$redis_src/$$f" -o "$$out/redis-$$name.o"; done'
	CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" strace -f -e trace=%file -o "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)" bash -c 'set -e; nginx_src="$(NGINX_BUILD_SRC)"; out="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"; for f in $(W4_CCACHE_BULK_NGINX_SRCS); do name=$${f//\//_}; name=$${name%.c}; ccache gcc -I"$$nginx_src/objs" -I"$$nginx_src/src/core" -I"$$nginx_src/src/event" -I"$$nginx_src/src/event/modules" -I"$$nginx_src/src/os/unix" -c "$$nginx_src/$$f" -o "$$out/nginx-$$name.o"; done'
	CCACHE_DIR="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" ccache --print-stats >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-stats.txt"
	for f in $(W4_CCACHE_BULK_REDIS_SRCS); do name=$${f//\//_}; name=$${name%.c}; cold_sha=$$(sha256sum "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold/redis-$$name.o" | awk '{ print $$1 }'); hot_sha=$$(sha256sum "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot/redis-$$name.o" | awk '{ print $$1 }'); test "$$cold_sha" = "$$hot_sha"; done
	for f in $(W4_CCACHE_BULK_NGINX_SRCS); do name=$${f//\//_}; name=$${name%.c}; cold_sha=$$(sha256sum "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold/nginx-$$name.o" | awk '{ print $$1 }'); hot_sha=$$(sha256sum "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot/nginx-$$name.o" | awk '{ print $$1 }'); test "$$cold_sha" = "$$hot_sha"; done
	find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/cold" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -type f -name '*.o' -print | sort | xargs sha256sum >"$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	redis_trace_lines=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_REDIS_LOG)"); \
	nginx_trace_lines=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_NGINX_LOG)"); \
	redis_cache_path_lines=$$(awk -v p="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)"); \
	nginx_cache_path_lines=$$(awk -v p="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)"); \
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-stats.txt"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-stats.txt"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-stats.txt"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-stats.txt"); \
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	test "$$redis_trace_lines" -gt 0; \
	test "$$nginx_trace_lines" -gt 0; \
	test "$$redis_cache_path_lines" -gt 0; \
	test "$$nginx_cache_path_lines" -gt 0; \
	test "$$cache_miss" -ge "$$source_count"; \
	test "$$direct_hit" -ge "$$source_count"; \
	jq -cn --arg run_id "$(RUN_ID)" --arg source_manifest "w4-ccache-bulk-source-manifest.tsv" --arg cache_dir "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" --arg redis_trace "w4-ccache-bulk-trace-redis.strace.log" --arg nginx_trace "w4-ccache-bulk-trace-nginx.strace.log" --arg artifacts_sha256 "w4-ccache-bulk-trace-artifacts.sha256" --arg stats_file "w4-ccache-bulk-trace-stats.txt" --argjson source_count "$$source_count" --argjson redis_trace_lines "$$redis_trace_lines" --argjson nginx_trace_lines "$$nginx_trace_lines" --argjson redis_cache_path_lines "$$redis_cache_path_lines" --argjson nginx_cache_path_lines "$$nginx_cache_path_lines" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" '{event:"w4-ccache-bulk-cache-path-trace", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_cache_path_trace_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, output_hash_match:true, source_manifest:$$source_manifest, source_count:$$source_count, ccache_cache_dir:$$cache_dir, redis_trace_file_ops:$$redis_trace_lines, nginx_trace_file_ops:$$nginx_trace_lines, redis_cache_path_file_ops:$$redis_cache_path_lines, nginx_cache_path_file_ops:$$nginx_cache_path_lines, cache_path_file_ops:($$redis_cache_path_lines + $$nginx_cache_path_lines), cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, redis_trace_file:$$redis_trace, nginx_trace_file:$$nginx_trace, stats_file:$$stats_file, artifacts_sha256_file:$$artifacts_sha256, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, qualified_for_c8:false, detail:"multi-source real Redis/nginx ccache hot compiles touched CCACHE_DIR paths under KVM"}' >>"$(W4_CCACHE_BULK_TRACE_JSON)"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson source_count "$$source_count" '{event:"w4-ccache-bulk-trace-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_cache_path_trace_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", pass:true, failures:0, real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, source_count:$$source_count, qualified_for_c8:false, detail:"bulk real ccache cache-path trace witness passed; policy bridge and baselines are separate gates"}' >>"$(W4_CCACHE_BULK_TRACE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-trace.log"
	printf '{"event":"w4-ccache-bulk-trace-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_path_trace_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_BULK_TRACE_JSON)"

kvm-w4-ccache-bulk-policy-bridge: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-trace
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_policy_bridge RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_bulk_policy_bridge:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CCACHE_BULK_BRIDGE_WORK_DIR)"
	printf '{"event":"w4-ccache-bulk-policy-bridge-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_bridge_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_BULK_BRIDGE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)"
	test -s "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	awk -v p="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 && /openat[(]/ && /O_RDONLY/ && / = [0-9]+$$/ && $$0 !~ /ccache[.]conf|stats|stats[.]alive|stats[.]lock|stats[.]tmp/ { line = $$0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); print line }' "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)" | sort -u | awk '{ printf "redis\t%s\n", $$0 }' >"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	awk -v p="$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" 'index($$0, p) > 0 && /openat[(]/ && /O_RDONLY/ && / = [0-9]+$$/ && $$0 !~ /ccache[.]conf|stats|stats[.]alive|stats[.]lock|stats[.]tmp/ { line = $$0; sub(/^[^"]*"/, "", line); sub(/".*/, "", line); print line }' "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)" | sort -u | awk '{ printf "nginx\t%s\n", $$0 }' >>"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	redis_entries=$$(awk -F '	' '$$1 == "redis" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	nginx_entries=$$(awk -F '	' '$$1 == "nginx" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	total_entries=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	test "$$redis_entries" -gt 0; \
	test "$$nginx_entries" -gt 0; \
	test "$$total_entries" -ge "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)"; \
	test "$$total_entries" -le 128
	: >"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	while IFS="	" read -r source original; do \
		test -s "$$original"; \
		case "$$source" in redis|nginx) ;; *) exit 1 ;; esac; \
		case "$$original" in "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache/"*) ;; *) exit 1 ;; esac; \
		rel="$${original#$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache/}"; \
		case "$$rel" in ""|"."|".."|../*|*/../*|*/..) exit 1 ;; esac; \
		parent_rel=$$(dirname "$$rel"); \
		base=$$(basename "$$rel"); \
		case "$$base" in ""|*/*|.|..) exit 1 ;; esac; \
		test "$${#base}" -le 249; \
		sha=$$(sha256sum "$$original" | awk '{ print $$1 }'); \
		printf 'w4-ccache-bulk-redis-nginx\tverified_hit\ttrace-derived-bulk/%s/%s\t.\t%s\t%s.local\t%s\t%s\n' "$$source" "$$parent_rel" "$$base" "$$base" "$$original" "$$sha" >>"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"; \
	done <"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test "$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)")" = "$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)")"
	awk -F '	' 'NF == 8 && $$1 == "w4-ccache-bulk-redis-nginx" && $$2 == "verified_hit" && $$3 ~ /^trace-derived-bulk\/(redis|nginx)\// && $$4 == "." && $$5 != "" && $$6 == ($$5 ".local") && $$7 != "" && length($$8) == 64 { n++ } END { exit !(n >= '"$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)"') }' "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)" "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-ccache-workload-design.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_BRIDGE_INPUTS)"
	printf '{"event":"w4-ccache-bulk-policy-bridge-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_bridge_witness","input_sha256_file":"w4-ccache-bulk-policy-bridge-inputs.sha256","trace_json":"%s","trace_objects":"%s","entries_tsv":"%s","work_dir":"%s","policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_BRIDGE_WORK_DIR)" >>"$(W4_CCACHE_BULK_BRIDGE_JSON)"
	"$(W4_ORACLE_RUNNER)" --cache-content "$(W4_CCACHE_BULK_BRIDGE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_BRIDGE_WORK_DIR)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)"
	policy_failures=$$(jq -s '[.[] | select(.event == "w4-cache-content-summary") | .failures] | add // 0' "$(W4_CCACHE_BULK_BRIDGE_JSON)"); \
	redis_entries=$$(awk -F '	' '$$1 == "redis" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	nginx_entries=$$(awk -F '	' '$$1 == "nginx" { n++ } END { print n + 0 }' "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	total_entries=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	attached_matches=$$(jq -s '[.[] | select(.event == "w4-cache-content" and .op == "attached_expected_match" and .pass == true)] | length' "$(W4_CCACHE_BULK_BRIDGE_JSON)"); \
	readdir_aliases=$$(jq -s '[.[] | select(.event == "w4-cache-content" and .op == "readdir_alias" and .pass == true)] | length' "$(W4_CCACHE_BULK_BRIDGE_JSON)"); \
	test "$$policy_failures" = "0"; \
	test "$$attached_matches" = "$$total_entries"; \
	test "$$readdir_aliases" = "$$total_entries"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson policy_failures "$$policy_failures" --argjson redis_entries "$$redis_entries" --argjson nginx_entries "$$nginx_entries" --argjson total_entries "$$total_entries" '{event:"w4-ccache-bulk-policy-bridge-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_bridge_witness", workload:"w4-ccache-bulk-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_trace_basis:true, ccache_cache_path_trace:true, trace_derived_policy_oracle_executed:true, ccache_compile_policy_executed:false, policy_executed:true, kvm_validated:true, trace_objects:$$total_entries, entries:$$total_entries, redis_trace_objects:$$redis_entries, nginx_trace_objects:$$nginx_entries, policy_content_oracle_failures:$$policy_failures, pass:true, failures:0, qualified_for_c8:false, detail:"bulk trace-derived ccache cache object components executed cache_locality policy content oracle"}' >>"$(W4_CCACHE_BULK_BRIDGE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-bridge.log"
	printf '{"event":"w4-ccache-bulk-policy-bridge-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_bridge_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_BULK_BRIDGE_JSON)"

kvm-w4-ccache-bulk-cache-epoch-counterfactual: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_cache_epoch_counterfactual RUN_ID=$(RUN_ID) W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES=$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES) W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS=$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)"

__phase1_guest_w4_ccache_bulk_cache_epoch_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CCACHE_BULK_CACHE_EPOCH_WORK_DIR)"
	printf '{"event":"w4-ccache-bulk-cache-epoch-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)" >"$(W4_CCACHE_BULK_CACHE_EPOCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	trace_entries=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"); test "$$trace_entries" -ge "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_INPUTS)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_CACHE_EPOCH_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_CACHE_EPOCH_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-cache-epoch-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_epoch_counterfactual","input_sha256_file":"w4-ccache-bulk-cache-epoch-counterfactual-inputs.sha256","trace_json":"%s","bridge_json":"%s","entries_tsv":"%s","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"cache_policy":"cache_locality_view.bpf.c","table_policy":"table_redirect.bpf.c","max_table_update_write_ratio":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_CACHE_EPOCH_WORK_DIR)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)" "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" >>"$(W4_CCACHE_BULK_CACHE_EPOCH_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-cache-epoch-counterfactual "$(W4_CCACHE_BULK_CACHE_EPOCH_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_EPOCH_WORK_DIR)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	jq -e --argjson samples "$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES)" --argjson objects "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)" --argjson max_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" -s '([.[] | select(.event == "w4-cache-epoch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.trace_entries >= $$objects and $$s.pass == true and $$s.failures == 0 and $$s.policy_executed == true and $$s.kvm_validated == true and $$s.table_static_current_oracle_pass == false and $$s.table_static_expected_failure_observed == true and $$s.table_updated_current_oracle_pass == true and $$s.table_requires_external_state_updates == true and $$s.table_update_budget_failure == true and $$s.targeted_c8_budget_failure == true and $$s.trace_derived_targeted_c8_pass == true and $$s.table_update_write_ratio > $$max_ratio and $$s.max_table_update_write_ratio == $$max_ratio and $$s.materialized_current_oracle_pass == true and $$s.materialized_feature_equivalent_baseline == true and $$s.materialized_update_budget_failure == true and $$s.materialized_update_write_ratio > $$max_ratio and $$s.fuse_current_oracle_pass == true and $$s.fuse_feature_equivalent_baseline == true and $$s.fuse_update_budget_failure == true and $$s.fuse_update_write_ratio > $$max_ratio and $$s.fuse_mounts == $$samples and $$s.real_ccache_trace == true and $$s.trace_derived_counterfactual == true and $$s.qualified_for_c8 == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_CACHE_EPOCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-cache-epoch-counterfactual.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-cache-epoch-counterfactual.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-cache-epoch-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_cache_epoch_counterfactual","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_CACHE_EPOCH_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_EPOCH_OBJECTS)" >>"$(W4_CCACHE_BULK_CACHE_EPOCH_JSON)"

kvm-w4-ccache-bulk-policy-compile: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_policy_compile RUN_ID=$(RUN_ID) W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES=$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)"

__phase1_guest_w4_ccache_bulk_policy_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-policy-compile-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_compile_witness","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" >"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)"
	cp -a "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)/ccache"
	sha256sum "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_POLICY_COMPILE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_POLICY_COMPILE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-policy-compile-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_compile_witness","input_sha256_file":"w4-ccache-bulk-policy-compile-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","ccache_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","stats_file":"w4-ccache-bulk-policy-compile-stats.txt","samples":%s,"policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-policy-compile "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(CACHE_LOCALITY_POLICY)" "$(W4_CCACHE_BULK_POLICY_COMPILE_STATS)"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	output_count=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -maxdepth 1 -type f -name '*.policy.o' | wc -l); \
	trace_count=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -maxdepth 1 -type f -name '*.policy.strace.log' | wc -l); \
	test "$$output_count" = "$$source_count"; \
	test "$$trace_count" = "$$source_count"
	find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -maxdepth 1 -type f \( -name '*.policy.o' -o -name '*.policy.strace.log' \) -print | sort | xargs sha256sum >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-outputs.sha256"
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_BULK_POLICY_COMPILE_STATS)"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_BULK_POLICY_COMPILE_STATS)"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_BULK_POLICY_COMPILE_STATS)"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_BULK_POLICY_COMPILE_STATS)"); \
	source_count=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].source_manifest_count // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	compile_jobs=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].attached_compile_jobs // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	output_matches=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].attached_compile_output_matches // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	redirected=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].policy_redirected_cache_objects // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	cache_path_ops=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].attached_cache_path_file_ops // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	object_ops=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].attached_policy_cache_object_ops // 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	failures=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].failures // 1' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	output_hash_match=$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")][0].output_hash_match // false' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	test "$$failures" = "0"; \
	test "$$compile_jobs" = "$$source_count"; \
	test "$$output_matches" = "$$source_count"; \
	test "$$output_hash_match" = "true"; \
	test "$$redirected" -ge "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)"; \
	test "$$cache_path_ops" -gt 0; \
	test "$$object_ops" -gt 0; \
	test "$$direct_hit" -ge "$$source_count"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson source_count "$$source_count" --argjson compile_jobs "$$compile_jobs" --argjson output_matches "$$output_matches" --argjson redirected "$$redirected" --argjson cache_path_ops "$$cache_path_ops" --argjson object_ops "$$object_ops" '{event:"w4-ccache-bulk-policy-compile-stats", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_compile_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", policy_family:"cache_locality_view.bpf.c", real_ccache_run:true, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, source_count:$$source_count, attached_compile_jobs:$$compile_jobs, attached_compile_output_matches:$$output_matches, policy_redirected_cache_objects:$$redirected, attached_cache_path_file_ops:$$cache_path_ops, attached_policy_cache_object_ops:$$object_ops, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, qualified_for_c8:false, detail:"bulk Redis/nginx ccache hot compiles ran under attached cache_locality policy"}' >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	set -e; \
	test "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" -ge 1; \
	sample=1; \
	while test "$$sample" -lt "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)"; do \
		sample_label=$$(printf '%03d' "$$sample"); \
		sample_dir="$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)/sample-$$sample_label"; \
		sample_cache="$$sample_dir/ccache"; \
		sample_stats="$$sample_dir/w4-ccache-bulk-policy-compile-stats.txt"; \
		install -d "$$sample_dir"; \
		cp -a "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$$sample_cache"; \
		"$(W4_ORACLE_RUNNER)" --ccache-bulk-policy-compile "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" /sys/fs/cgroup "$$sample_dir" "$$sample_cache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(CACHE_LOCALITY_POLICY)" "$$sample_stats"; \
		sample=$$((sample + 1)); \
	done
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	expected_outputs=$$((source_count * $(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES))); \
	output_count=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name '*.policy.o' | wc -l); \
	trace_count=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name '*.policy.strace.log' | wc -l); \
	test "$$output_count" = "$$expected_outputs"; \
	test "$$trace_count" = "$$expected_outputs"
	find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f \( -name '*.policy.o' -o -name '*.policy.strace.log' -o -name 'w4-ccache-bulk-policy-compile-stats.txt' \) -print | sort | xargs sha256sum >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-outputs.sha256"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	cache_miss=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name 'w4-ccache-bulk-policy-compile-stats.txt' -print | sort | xargs awk '$$1 == "cache_miss" { v += $$2 } END { print v + 0 }'); \
	direct_hit=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name 'w4-ccache-bulk-policy-compile-stats.txt' -print | sort | xargs awk '$$1 == "direct_cache_hit" { v += $$2 } END { print v + 0 }'); \
	local_hit=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name 'w4-ccache-bulk-policy-compile-stats.txt' -print | sort | xargs awk '$$1 == "local_storage_hit" { v += $$2 } END { print v + 0 }'); \
	local_write=$$(find "$(W4_CCACHE_BULK_POLICY_COMPILE_WORK_DIR)" -type f -name 'w4-ccache-bulk-policy-compile-stats.txt' -print | sort | xargs awk '$$1 == "local_storage_write" { v += $$2 } END { print v + 0 }'); \
	jq -c -s --arg run_id "$(RUN_ID)" --argjson samples "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" --argjson source_count "$$source_count" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")] as $$rows | ($$rows | map(.failures // 0) | add // 0) as $$failures | ($$rows | map(.attached_compile_jobs // 0) | add // 0) as $$jobs | ($$rows | map(.attached_compile_output_matches // 0) | add // 0) as $$matches | ($$rows | map(.policy_redirected_cache_objects // 0) | add // 0) as $$redirected | ($$rows | map(.attached_cache_path_file_ops // 0) | add // 0) as $$cache_path_ops | ($$rows | map(.attached_policy_cache_object_ops // 0) | add // 0) as $$object_ops | ($$rows | all(.output_hash_match == true)) as $$hash_ok | {event:"w4-ccache-bulk-policy-compile-release-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_compile_release_input", workload:"w4-ccache-bulk-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_run:true, bulk_policy_compile:true, samples:$$samples, compile_rows:($$rows | length), source_manifest_count:$$source_count, attached_compile_jobs:$$jobs, attached_compile_output_matches:$$matches, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, output_hash_match:$$hash_ok, policy_redirected_cache_objects:$$redirected, attached_cache_path_file_ops:$$cache_path_ops, attached_policy_cache_object_ops:$$object_ops, attached_sampled_operation_hit_rate:(if $$cache_path_ops > 0 then ($$object_ops / $$cache_path_ops) else 0 end), cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, pass:(($$rows | length) == $$samples and $$failures == 0 and $$hash_ok and $$jobs == ($$samples * $$source_count) and $$matches == $$jobs and $$cache_path_ops > 0 and $$object_ops > 0), failures:$$failures, operation_weighted_policy_cache_hit_rate:true, operation_weighted_policy_hit_rate_is_release:true, qualified_for_c8:false, release_gate_pass:false, detail:"bulk Redis/nginx ccache hot compiles ran repeatedly under attached cache_locality policy; this is a release compile input, not a stale-window/table-budget C8 proof"}' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" >"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON).release-summary"
	cat "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON).release-summary" >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	jq -e --argjson samples "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" --argjson source_count "$$source_count" --argjson min_trace_objects "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)" -s '([.[] | select(.event == "w4-ccache-bulk-policy-compile-release-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == true and $$s.ccache_compile_policy_executed == true and $$s.output_hash_match == true and $$s.attached_compile_jobs == ($$samples * $$source_count) and $$s.attached_compile_output_matches == $$s.attached_compile_jobs and $$s.policy_redirected_cache_objects >= ($$samples * $$min_trace_objects) and $$s.attached_cache_path_file_ops > 0 and $$s.attached_policy_cache_object_ops > 0 and $$s.operation_weighted_policy_hit_rate_is_release == true and $$s.qualified_for_c8 == false' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-compile.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-compile.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-policy-compile-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_compile_witness","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"

kvm-w4-ccache-bulk-native-compile: $(KERNEL_IMAGE) w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_native_compile RUN_ID=$(RUN_ID) W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)"

__phase1_guest_w4_ccache_bulk_native_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-native-compile-start","run_id":"%s","result_level":"kvm_external_native_ccache_compile_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" >"$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-native-ccache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-native-ccache-baseline-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_NATIVE_COMPILE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_NATIVE_COMPILE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-native-compile-input","run_id":"%s","result_level":"kvm_external_native_ccache_compile_baseline","input_sha256_file":"w4-ccache-bulk-native-compile-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"baseline":"native_ccache_hot_compile"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-native-compile "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	expected_rows="$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)"; \
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-native-compile-sample" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false and .direct_cache_hit >= .source_manifest_count and .compile_output_matches == .source_manifest_count)] | length' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-native-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.total_compile_jobs == ($$samples * $$source_count) and $$s.total_compile_output_matches == ($$samples * $$source_count) and $$s.direct_cache_hit >= ($$samples * $$source_count) and $$s.operation_weighted_native_hit_rate_is_release == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" >/dev/null
	find "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)" -type f \( -name '*.native.o' -o -name '*.native.strace.log' -o -name 'ccache-native-stats.txt' \) -print | sort | xargs sha256sum >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-outputs.sha256"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-native-compile.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-native-compile.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-native-compile-done","run_id":"%s","result_level":"kvm_external_native_ccache_compile_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"

kvm-w4-ccache-bulk-fuse-compile: $(KERNEL_IMAGE) w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_fuse_compile RUN_ID=$(RUN_ID) W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)"

__phase1_guest_w4_ccache_bulk_fuse_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-fuse-compile-start","run_id":"%s","result_level":"kvm_external_fuse_ccache_compile_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" >"$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_FUSE_COMPILE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_FUSE_COMPILE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-fuse-compile-input","run_id":"%s","result_level":"kvm_external_fuse_ccache_compile_baseline","input_sha256_file":"w4-ccache-bulk-fuse-compile-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"baseline":"fuse_redirect_compile","complete_ccache_compile_through_fuse":true}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-fuse-compile "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	expected_rows="$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)"; \
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-fuse-compile-sample" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false and .complete_ccache_compile_through_fuse == true and .fuse_mounts == 1 and .direct_cache_hit >= .source_manifest_count and .compile_output_matches == .source_manifest_count)] | length' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-fuse-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.complete_ccache_compile_through_fuse == true and $$s.read_oriented_cache_view_only == false and $$s.total_compile_jobs == ($$samples * $$source_count) and $$s.total_compile_output_matches == ($$samples * $$source_count) and $$s.direct_cache_hit >= ($$samples * $$source_count) and $$s.fuse_mounts == $$samples and $$s.operation_weighted_fuse_hit_rate_is_release == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" >/dev/null
	find "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" -type f \( -name '*.fuse.o' -o -name '*.fuse.strace.log' -o -name 'ccache-fuse.log' \) -print | sort | xargs sha256sum >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-outputs.sha256"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-compile.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-compile.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-fuse-compile-done","run_id":"%s","result_level":"kvm_external_fuse_ccache_compile_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"

kvm-w4-ccache-bulk-policy-macrobench: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_policy_macrobench RUN_ID=$(RUN_ID) W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES=$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)"

__phase1_guest_w4_ccache_bulk_policy_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-policy-macrobench-start","run_id":"%s","result_level":"kvm_workload_bulk_policy_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)" >"$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-macrobench-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	entry_count=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"); \
	trace_object_count=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"); \
	test "$$source_count" -gt 1; \
	test "$$entry_count" -ge "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)"; \
	test "$$entry_count" = "$$trace_object_count"
	rm -rf "$(W4_CCACHE_BULK_POLICY_MACROBENCH_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_POLICY_MACROBENCH_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-macrobench-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-policy-macrobench-input","run_id":"%s","result_level":"kvm_workload_bulk_policy_setup_update_input","input_sha256_file":"w4-ccache-bulk-policy-macrobench-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","samples":%s,"policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_POLICY_MACROBENCH_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)" >>"$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-policy-macrobench "$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)" "$(W4_CCACHE_BULK_POLICY_MACROBENCH_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(CACHE_LOCALITY_POLICY)"
	expected_rows="$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-macrobench-setup" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == true)] | length' "$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-macrobench-update" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == true)] | length' "$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-policy-macrobench-correctness" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == true and .attached_lookup_pass == true and .attached_readdir_pass == true and .post_update_lookup_pass == true and .post_update_readdir_pass == true and .post_detach_absent == true)] | length' "$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-bulk-policy-macrobench-summary")][0]) as $$s | $$s.workload == "w4-ccache-bulk-redis-nginx" and $$s.samples == $$samples and $$s.systems == 1 and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.policy_executed == true and $$s.compile_smoke_required == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-macrobench.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-macrobench.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-policy-macrobench-done","run_id":"%s","result_level":"kvm_workload_bulk_policy_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_POLICY_MACROBENCH_SAMPLES)" >>"$(W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)"

kvm-w4-ccache-policy-compile: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_policy_compile RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_policy_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-policy-compile-start","run_id":"%s","result_level":"kvm_real_ccache_policy_compile_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_POLICY_COMPILE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -d "$(W4_CCACHE_TRACE_WORK_DIR)/ccache"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o"
	test -s "$(W4_CCACHE_REAL_REDIS_SRC)"
	test -s "$(W4_CCACHE_REAL_NGINX_SRC)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-ccache.version"
	rm -rf "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)"
	cp -a "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)/ccache"
	sha256sum "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-ccache.version" >"$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-inputs.sha256"
	printf '{"event":"w4-ccache-policy-compile-input","run_id":"%s","result_level":"kvm_real_ccache_policy_compile_witness","input_sha256_file":"w4-ccache-policy-compile-inputs.sha256","entries_tsv":"%s","trace_objects":"%s","work_dir":"%s","ccache_dir":"%s","trace_cache_dir":"%s","stats_file":"w4-ccache-policy-compile-stats.txt","policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" >>"$(W4_CCACHE_POLICY_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-policy-compile "$(W4_CCACHE_POLICY_COMPILE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(REDIS_BUILD_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(CACHE_LOCALITY_POLICY)" "$(W4_CCACHE_POLICY_COMPILE_STATS)"
	sha256sum "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)/redis.policy.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(W4_CCACHE_POLICY_COMPILE_WORK_DIR)/nginx.policy.o" >"$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-outputs.sha256"
	test "$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-outputs.sha256" | awk '{print $$1}')"
	test "$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w4-ccache-policy-compile-outputs.sha256" | awk '{print $$1}')"
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_POLICY_COMPILE_STATS)"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_POLICY_COMPILE_STATS)"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_POLICY_COMPILE_STATS)"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_POLICY_COMPILE_STATS)"); \
	redirected=$$(jq -s '[.[] | select(.event == "w4-ccache-policy-compile-summary") | .policy_redirected_cache_objects] | add // 0' "$(W4_CCACHE_POLICY_COMPILE_JSON)"); \
	failures=$$(jq -s '[.[] | select(.event == "w4-ccache-policy-compile-summary") | .failures] | add // 0' "$(W4_CCACHE_POLICY_COMPILE_JSON)"); \
	test "$$failures" = "0"; \
	test "$$redirected" -gt 1; \
	test "$$direct_hit" -ge 2; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson redirected "$$redirected" '{event:"w4-ccache-policy-compile-stats", run_id:$$run_id, result_level:"kvm_real_ccache_policy_compile_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", policy_family:"cache_locality_view.bpf.c", real_ccache_run:true, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, policy_redirected_cache_objects:$$redirected, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, qualified_for_c8:false, detail:"ccache stats after policy-attached hot compiles"}' >>"$(W4_CCACHE_POLICY_COMPILE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-policy-compile.log"
	printf '{"event":"w4-ccache-policy-compile-done","run_id":"%s","result_level":"kvm_real_ccache_policy_compile_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_POLICY_COMPILE_JSON)"

kvm-w4-ccache-parent-compile: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_parent_compile RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_parent_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-parent-compile-start","run_id":"%s","result_level":"kvm_real_ccache_parent_rule_compile_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_PARENT_COMPILE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -d "$(W4_CCACHE_TRACE_WORK_DIR)/ccache"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o"
	test -s "$(W4_CCACHE_REAL_REDIS_SRC)"
	test -s "$(W4_CCACHE_REAL_NGINX_SRC)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-ccache.version"
	rm -rf "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)"
	cp -a "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/ccache"
	sha256sum "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-ccache.version" >"$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-inputs.sha256"
	printf '{"event":"w4-ccache-parent-compile-input","run_id":"%s","result_level":"kvm_real_ccache_parent_rule_compile_witness","input_sha256_file":"w4-ccache-parent-compile-inputs.sha256","entries_tsv":"%s","trace_objects":"%s","work_dir":"%s","ccache_dir":"%s","trace_cache_dir":"%s","stats_file":"w4-ccache-parent-compile-stats.txt","policy":"cache_locality_view.bpf.c","parent_rule_policy":true}\n' "$(RUN_ID)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" >>"$(W4_CCACHE_PARENT_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-parent-compile "$(W4_CCACHE_PARENT_COMPILE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(REDIS_BUILD_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(CACHE_LOCALITY_POLICY)" "$(W4_CCACHE_PARENT_COMPILE_STATS)"
	sha256sum "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/redis.policy.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/nginx.policy.o" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/redis-policy-compile.strace.log" "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/nginx-policy-compile.strace.log" >"$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256"
	test "$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256" | awk '{print $$1}')"
	test "$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256" | awk '{print $$1}')"
	test -s "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/redis-policy-compile.strace.log"
	test -s "$(W4_CCACHE_PARENT_COMPILE_WORK_DIR)/nginx-policy-compile.strace.log"
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_PARENT_COMPILE_STATS)"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_PARENT_COMPILE_STATS)"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_PARENT_COMPILE_STATS)"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_PARENT_COMPILE_STATS)"); \
	redirected=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile-summary") | .policy_redirected_cache_objects] | add // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	failures=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile-summary") | .failures] | add // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	parents=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile-summary") | .cache_leaf_parents] | add // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	parent_updates=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile-summary") | .parent_rule_updates] | add // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	table_updates=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile-summary") | .table_equivalent_rule_updates] | add // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	sibling_pass=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile" and .op == "attached_parent_sibling_pass" and .pass == true)] | length' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	valid_sibling_prepare=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile" and .op == "parent_valid_sibling_prepare" and .pass == true)] | length' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	valid_sibling_backing_absent=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile" and .op == "parent_valid_sibling_backing_absent" and .pass == true)] | length' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	valid_sibling_pass=$$(jq -s '[.[] | select(.event == "w4-ccache-parent-compile" and .op == "attached_parent_valid_sibling_pass" and .pass == true and .policy_executed == true and .ccache_compile_policy_executed == true and .qualified_for_c8 == false and .content_oracle == true and .content_oracle_kind == "exact-text" and .expected_content_len > 0 and .expected_content_len == .observed_content_len and .expected_content_fnv1a64 == .observed_content_fnv1a64)] | length' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	test "$$failures" = "0"; \
	test "$$redirected" -gt 1; \
	test "$$direct_hit" -ge 2; \
	test "$$parents" -gt 0; \
	test "$$parent_updates" -gt 0; \
	test "$$sibling_pass" -gt 0; \
	test "$$valid_sibling_prepare" -gt 0; \
	test "$$valid_sibling_backing_absent" -gt 0; \
	test "$$valid_sibling_pass" -gt 0; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson redirected "$$redirected" --argjson cache_leaf_parents "$$parents" --argjson parent_rule_updates "$$parent_updates" --argjson table_equivalent_rule_updates "$$table_updates" --argjson parent_sibling_pass_count "$$sibling_pass" --argjson valid_shape_sibling_prepare_count "$$valid_sibling_prepare" --argjson valid_shape_sibling_backing_absent_count "$$valid_sibling_backing_absent" --argjson valid_shape_sibling_content_pass_count "$$valid_sibling_pass" '{event:"w4-ccache-parent-compile-stats", run_id:$$run_id, result_level:"kvm_real_ccache_parent_rule_compile_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", policy_family:"cache_locality_view.bpf.c", real_ccache_run:true, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, parent_rule_policy:true, parent_sibling_pass:($$parent_sibling_pass_count > 0), parent_sibling_pass_count:$$parent_sibling_pass_count, valid_shape_sibling_prepare_count:$$valid_shape_sibling_prepare_count, valid_shape_sibling_backing_absent_count:$$valid_shape_sibling_backing_absent_count, valid_shape_sibling_content_oracle:($$valid_shape_sibling_content_pass_count > 0), valid_shape_sibling_content_pass_count:$$valid_shape_sibling_content_pass_count, policy_redirected_cache_objects:$$redirected, cache_leaf_parents:$$cache_leaf_parents, parent_rule_updates:$$parent_rule_updates, table_equivalent_rule_updates:$$table_equivalent_rule_updates, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, qualified_for_c8:false, detail:"ccache stats after parent-rule policy-attached hot compiles"}' >>"$(W4_CCACHE_PARENT_COMPILE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-parent-compile.log"
	printf '{"event":"w4-ccache-parent-compile-done","run_id":"%s","result_level":"kvm_real_ccache_parent_rule_compile_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_PARENT_COMPILE_JSON)"

kvm-w4-ccache-table-compile: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_table_compile RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_table_compile:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-table-compile-start","run_id":"%s","result_level":"kvm_real_ccache_table_compile_witness"}\n' "$(RUN_ID)" >"$(W4_CCACHE_TABLE_COMPILE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -d "$(W4_CCACHE_TRACE_WORK_DIR)/ccache"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o"
	test -s "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o"
	test -s "$(W4_CCACHE_REAL_REDIS_SRC)"
	test -s "$(W4_CCACHE_REAL_NGINX_SRC)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-ccache.version"
	rm -rf "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)"
	cp -a "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/ccache"
	sha256sum "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-trace-artifacts.sha256" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-ccache.version" >"$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-inputs.sha256"
	printf '{"event":"w4-ccache-table-compile-input","run_id":"%s","result_level":"kvm_real_ccache_table_compile_witness","input_sha256_file":"w4-ccache-table-compile-inputs.sha256","entries_tsv":"%s","trace_objects":"%s","work_dir":"%s","ccache_dir":"%s","trace_cache_dir":"%s","stats_file":"w4-ccache-table-compile-stats.txt","policy":"table_redirect.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" >>"$(W4_CCACHE_TABLE_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-table-compile "$(W4_CCACHE_TABLE_COMPILE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/ccache" "$(W4_CCACHE_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_REAL_REDIS_SRC)" "$(REDIS_BUILD_SRC)" "$(W4_CCACHE_REAL_NGINX_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(TABLE_REDIRECT_POLICY)" "$(W4_CCACHE_TABLE_COMPILE_STATS)"
	sha256sum "$(W4_CCACHE_TRACE_WORK_DIR)/redis.hot.o" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/redis.policy.o" "$(W4_CCACHE_TRACE_WORK_DIR)/nginx.hot.o" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/nginx.policy.o" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/redis-policy-compile.strace.log" "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/nginx-policy-compile.strace.log" >"$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256"
	test "$$(sed -n '1p' "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '2p' "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256" | awk '{print $$1}')"
	test "$$(sed -n '3p' "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256" | awk '{print $$1}')" = "$$(sed -n '4p' "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256" | awk '{print $$1}')"
	test -s "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/redis-policy-compile.strace.log"
	test -s "$(W4_CCACHE_TABLE_COMPILE_WORK_DIR)/nginx-policy-compile.strace.log"
	cache_miss=$$(awk '$$1 == "cache_miss" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_TABLE_COMPILE_STATS)"); \
	direct_hit=$$(awk '$$1 == "direct_cache_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_TABLE_COMPILE_STATS)"); \
	local_hit=$$(awk '$$1 == "local_storage_hit" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_TABLE_COMPILE_STATS)"); \
	local_write=$$(awk '$$1 == "local_storage_write" { v = $$2 } END { if (v == "") v = 0; print v }' "$(W4_CCACHE_TABLE_COMPILE_STATS)"); \
	redirected=$$(jq -s '[.[] | select(.event == "w4-ccache-table-compile-summary") | .policy_redirected_cache_objects] | add // 0' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	failures=$$(jq -s '[.[] | select(.event == "w4-ccache-table-compile-summary") | .failures] | add // 0' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	test "$$failures" = "0"; \
	test "$$redirected" -gt 1; \
	test "$$direct_hit" -ge 2; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson redirected "$$redirected" '{event:"w4-ccache-table-compile-stats", run_id:$$run_id, result_level:"kvm_real_ccache_table_compile_witness", workload:"w4-ccache-redis-nginx", run_environment:"kvm", policy_family:"table_redirect.bpf.c", real_ccache_run:true, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, table_baseline_current_oracle_pass:true, content_equivalent_table_oracle:true, policy_redirected_cache_objects:$$redirected, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, qualified_for_c8:false, detail:"table-only exact redirects after sampled ccache hot compiles"}' >>"$(W4_CCACHE_TABLE_COMPILE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-table-compile.log"
	printf '{"event":"w4-ccache-table-compile-done","run_id":"%s","result_level":"kvm_real_ccache_table_compile_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_TABLE_COMPILE_JSON)"

kvm-w4-ccache-release-counterfactual: $(KERNEL_IMAGE) kvm-w4-ccache-parent-compile kvm-w4-ccache-table-compile
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_release_counterfactual RUN_ID=$(RUN_ID)"

__phase1_guest_w4_ccache_release_counterfactual:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-release-counterfactual-start","run_id":"%s","result_level":"kvm_release_counterfactual_accounting"}\n' "$(RUN_ID)" >"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON)"
	test -s "$(W4_CCACHE_TRACE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_CCACHE_PARENT_COMPILE_JSON)"
	test -s "$(W4_CCACHE_TABLE_COMPILE_JSON)"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-inputs.sha256"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-inputs.sha256"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256"
	test -s "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256"
	sha256sum "$(W4_CCACHE_TRACE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_PARENT_COMPILE_JSON)" "$(W4_CCACHE_TABLE_COMPILE_JSON)" "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-inputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-parent-compile-outputs.sha256" "$(PHASE1_RESULT_DIR)/w4-ccache-table-compile-outputs.sha256" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_INPUTS)"
	printf '{"event":"w4-ccache-release-counterfactual-input","run_id":"%s","result_level":"kvm_release_counterfactual_accounting","input_sha256_file":"w4-ccache-release-counterfactual-inputs.sha256","trace_json":"%s","parent_compile_json":"%s","table_compile_json":"%s","trace_objects":"%s","entries_tsv":"%s"}\n' "$(RUN_ID)" "$(W4_CCACHE_TRACE_JSON)" "$(W4_CCACHE_PARENT_COMPILE_JSON)" "$(W4_CCACHE_TABLE_COMPILE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" >>"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON)"
	cache_path_ops=$$(jq -sr '[.[] | select(.event == "w4-ccache-cache-path-trace")][0].cache_path_file_ops // 0' "$(W4_CCACHE_TRACE_JSON)"); \
	trace_objects=$$(wc -l <"$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"); \
	entries=$$(wc -l <"$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"); \
	parent_redirected=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].policy_redirected_cache_objects // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	table_redirected=$$(jq -sr '[.[] | select(.event == "w4-ccache-table-compile-summary")][0].policy_redirected_cache_objects // 0' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	parent_rules=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].parent_rule_updates // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	readdir_rules=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].exact_readdir_updates // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	table_rules=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].table_equivalent_rule_updates // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	attached_ops=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].attached_cache_path_file_ops // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	attached_object_ops=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].attached_policy_cache_object_ops // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	attached_hit_rate=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].attached_sampled_operation_hit_rate // 0' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	attached_optrace=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].attached_optrace_collected // false' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	parent_failures=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].failures // 1' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	table_failures=$$(jq -sr '[.[] | select(.event == "w4-ccache-table-compile-summary")][0].failures // 1' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	parent_output_match=$$(jq -sr '[.[] | select(.event == "w4-ccache-parent-compile-summary")][0].output_hash_match // false' "$(W4_CCACHE_PARENT_COMPILE_JSON)"); \
	table_output_match=$$(jq -sr '[.[] | select(.event == "w4-ccache-table-compile-summary")][0].output_hash_match // false' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	table_pass=$$(jq -sr '[.[] | select(.event == "w4-ccache-table-compile-summary")][0].table_baseline_current_oracle_pass // false' "$(W4_CCACHE_TABLE_COMPILE_JSON)"); \
	test "$$cache_path_ops" -gt 0; \
	test "$$trace_objects" -gt 0; \
	test "$$entries" = "$$trace_objects"; \
	test "$$parent_redirected" = "$$trace_objects"; \
	test "$$table_redirected" = "$$trace_objects"; \
	test "$$parent_rules" -gt 0; \
	test "$$table_rules" -ge "$$parent_rules"; \
	test "$$attached_optrace" = "true"; \
	test "$$attached_ops" -gt 0; \
	test "$$attached_object_ops" -gt 0; \
	test "$$parent_failures" = "0"; \
	test "$$table_failures" = "0"; \
	test "$$parent_output_match" = "true"; \
	test "$$table_output_match" = "true"; \
	test "$$table_pass" = "true"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_path_ops "$$cache_path_ops" --argjson trace_objects "$$trace_objects" --argjson entries "$$entries" --argjson parent_redirected "$$parent_redirected" --argjson table_redirected "$$table_redirected" --argjson parent_rules "$$parent_rules" --argjson readdir_rules "$$readdir_rules" --argjson table_rules "$$table_rules" --argjson attached_ops "$$attached_ops" --argjson attached_object_ops "$$attached_object_ops" --argjson attached_hit_rate "$$attached_hit_rate" --argjson max_ratio "$(OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO)" '{event:"w4-ccache-release-counterfactual", run_id:$$run_id, result_level:"kvm_release_counterfactual_accounting", workload:"w4-ccache-redis-nginx", run_environment:"kvm", real_ccache_run:true, policy_family:"cache_locality_view.bpf.c", table_policy:"table_redirect.bpf.c", parent_scoped_policy_executed:true, table_policy_executed:true, kvm_validated:true, trace_cache_path_file_ops:$$cache_path_ops, trace_cache_objects:$$trace_objects, trace_entries:$$entries, parent_policy_redirected_objects:$$parent_redirected, table_policy_redirected_objects:$$table_redirected, parent_rule_writes:$$parent_rules, exact_readdir_rule_writes:$$readdir_rules, table_rule_writes:$$table_rules, table_over_parent_rule_ratio:(if $$parent_rules == 0 then 0 else ($$table_rules / $$parent_rules) end), max_over_materialization_ratio:$$max_ratio, eligible_object_policy_hit_rate:(if $$trace_objects == 0 then 0 else ($$parent_redirected / $$trace_objects) end), cache_path_policy_coverage:(if $$cache_path_ops == 0 then 0 else ($$parent_redirected / $$cache_path_ops) end), attached_optrace_collected:true, attached_optrace_scope:"sampled_ccache_compile_strace", attached_cache_path_file_ops:$$attached_ops, attached_policy_cache_object_ops:$$attached_object_ops, attached_sampled_operation_hit_rate:$$attached_hit_rate, attached_sampled_operation_hit_rate_is_release:false, table_baseline_current_oracle_pass:true, table_budget_failure:false, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, qualified_for_c8:false, pass:true, failures:0, detail:"sampled ccache parent-rule accounting passed with attach-window optrace, but table-only also passed and release-level operation-weighted policy hit rate is not established"}' >>"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON)"
	jq -cn --arg run_id "$(RUN_ID)" '{event:"w4-ccache-release-counterfactual-summary", run_id:$$run_id, result_level:"kvm_release_counterfactual_accounting", workload:"w4-ccache-redis-nginx", run_environment:"kvm", pass:true, failures:0, real_ccache_run:true, parent_scoped_policy_executed:true, table_policy_executed:true, table_baseline_current_oracle_pass:true, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, qualified_for_c8:false, detail:"counterfactual accounting is preserved as negative C8 evidence until release-level hit rate, stale/update window, or table budget failure is measured"}' >>"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-release-counterfactual.log"
	printf '{"event":"w4-ccache-release-counterfactual-done","run_id":"%s","result_level":"kvm_release_counterfactual_accounting"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_RELEASE_COUNTERFACTUAL_JSON)"

kvm-w4-ccache-rule-macrobench: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_rule_macrobench RUN_ID=$(RUN_ID) W4_CCACHE_RULE_MACROBENCH_SAMPLES=$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)"

__phase1_guest_w4_ccache_rule_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-rule-macrobench-start","run_id":"%s","result_level":"kvm_workload_rule_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)" >"$(W4_CCACHE_RULE_MACROBENCH_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(W4_CCACHE_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(TABLE_REDIRECT_POLICY_SOURCE)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(TABLE_REDIRECT_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-design.md" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_RULE_MACROBENCH_INPUTS)"
	sha256sum -c "$(W4_CCACHE_RULE_MACROBENCH_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-rule-macrobench-input","run_id":"%s","result_level":"kvm_workload_rule_setup_update_input","input_sha256_file":"w4-ccache-rule-macrobench-inputs.sha256","entries_tsv":"%s","trace_objects":"%s","bridge_json":"%s","runner_source":"%s","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)" >>"$(W4_CCACHE_RULE_MACROBENCH_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-rule-macrobench "$(W4_CCACHE_RULE_MACROBENCH_JSON)" /sys/fs/cgroup "$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)" "$(W4_CCACHE_RULE_MACROBENCH_WORK_DIR)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)" "$(TABLE_REDIRECT_POLICY)"
	expected_rows=$$(( $(W4_CCACHE_RULE_MACROBENCH_SAMPLES) * 2 )); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-rule-macrobench-setup" and .pass == true)] | length' "$(W4_CCACHE_RULE_MACROBENCH_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-rule-macrobench-update" and .pass == true)] | length' "$(W4_CCACHE_RULE_MACROBENCH_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-rule-macrobench-correctness" and .pass == true)] | length' "$(W4_CCACHE_RULE_MACROBENCH_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)" --argjson expected_rows "$$expected_rows" -s '([.[] | select(.event == "w4-ccache-rule-macrobench-summary")][0]) as $$s | $$s.samples == $$samples and $$s.systems == 2 and $$s.setup_rows == $$expected_rows and $$s.update_rows == $$expected_rows and $$s.correctness_rows == $$expected_rows and $$s.pass == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_RULE_MACROBENCH_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-rule-macrobench.log"
	printf '{"event":"w4-ccache-rule-macrobench-done","run_id":"%s","result_level":"kvm_workload_rule_setup_update_input","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_RULE_MACROBENCH_SAMPLES)" >>"$(W4_CCACHE_RULE_MACROBENCH_JSON)"

kvm-w4-ccache-materialized-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle kvm-w4-ccache-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_materialized_baseline_macrobench RUN_ID=$(RUN_ID) W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES=$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)"

__phase1_guest_w4_ccache_materialized_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-materialized-baseline-start","run_id":"%s","result_level":"kvm_external_materialized_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)" >"$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-design.md" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_MATERIALIZED_BASELINE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_MATERIALIZED_BASELINE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-materialized-baseline-input","run_id":"%s","result_level":"kvm_external_materialized_cache_baseline","input_sha256_file":"w4-ccache-materialized-baseline-inputs.sha256","entries_tsv":"%s","trace_objects":"%s","bridge_json":"%s","runner_source":"%s","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BRIDGE_JSON)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)" >>"$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-materialized-baseline-macrobench "$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)" "$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)" "$(W4_CCACHE_MATERIALIZED_BASELINE_WORK_DIR)" "$(W4_CCACHE_BRIDGE_ENTRIES_TSV)"
	expected_rows="$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-setup" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-update" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-correctness" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-materialized-baseline-summary")][0]) as $$s | $$s.samples == $$samples and $$s.systems == 1 and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-materialized-baseline.log"
	printf '{"event":"w4-ccache-materialized-baseline-done","run_id":"%s","result_level":"kvm_external_materialized_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_MATERIALIZED_BASELINE_SAMPLES)" >>"$(W4_CCACHE_MATERIALIZED_BASELINE_JSON)"

kvm-w4-ccache-bulk-materialized-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_materialized_baseline_macrobench RUN_ID=$(RUN_ID) W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES=$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)"

__phase1_guest_w4_ccache_bulk_materialized_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-materialized-baseline-start","run_id":"%s","result_level":"kvm_external_bulk_materialized_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)" >"$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-design.md" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-materialized-baseline-input","run_id":"%s","result_level":"kvm_external_bulk_materialized_cache_baseline","input_sha256_file":"w4-ccache-bulk-materialized-baseline-inputs.sha256","trace_json":"%s","bridge_json":"%s","entries_tsv":"%s","trace_objects":"%s","runner_source":"%s","samples":%s,"workload":"w4-ccache-bulk-redis-nginx"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)" >>"$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-materialized-baseline-macrobench "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)" "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)" "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_WORK_DIR)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "w4-ccache-bulk-redis-nginx"
	expected_rows="$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-setup" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-update" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-materialized-baseline-correctness" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false)] | length' "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-materialized-baseline-summary")][0]) as $$s | $$s.workload == "w4-ccache-bulk-redis-nginx" and $$s.samples == $$samples and $$s.systems == 1 and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-materialized-baseline.log"
	printf '{"event":"w4-ccache-bulk-materialized-baseline-done","run_id":"%s","result_level":"kvm_external_bulk_materialized_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES)" >>"$(W4_CCACHE_BULK_MATERIALIZED_BASELINE_JSON)"

kvm-w4-ccache-bulk-fuse-baseline-macrobench: $(KERNEL_IMAGE) w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_fuse_baseline_macrobench RUN_ID=$(RUN_ID) W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES=$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)"

__phase1_guest_w4_ccache_bulk_fuse_baseline_macrobench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-fuse-baseline-start","run_id":"%s","result_level":"kvm_external_fuse_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)" >"$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-cache-baseline-implementation.md" "$(ROOT_DIR)/mk/kvm.mk" >"$(W4_CCACHE_BULK_FUSE_BASELINE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_FUSE_BASELINE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-fuse-baseline-input","run_id":"%s","result_level":"kvm_external_fuse_cache_baseline","input_sha256_file":"w4-ccache-bulk-fuse-baseline-inputs.sha256","trace_json":"%s","bridge_json":"%s","entries_tsv":"%s","trace_objects":"%s","runner_source":"%s","samples":%s,"workload":"w4-ccache-bulk-redis-nginx"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-fuse-baseline-macrobench "$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)" "$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)" "$(W4_CCACHE_BULK_FUSE_BASELINE_WORK_DIR)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "w4-ccache-bulk-redis-nginx"
	expected_rows="$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-fuse-baseline-setup" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .fuse_mounts == 1)] | length' "$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-fuse-baseline-update" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true)] | length' "$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)")" = "$$expected_rows"; \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-fuse-baseline-correctness" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .visible_content_pass == true and .readdir_pass == true and .hidden_backing_absent == true and .post_update_content_pass == true)] | length' "$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-fuse-baseline-summary")][0]) as $$s | $$s.workload == "w4-ccache-bulk-redis-nginx" and $$s.samples == $$samples and $$s.systems == 1 and $$s.setup_rows == $$samples and $$s.update_rows == $$samples and $$s.correctness_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.c2_supported == false and $$s.release_gate_pass == false' "$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-baseline.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-baseline.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-fuse-baseline-done","run_id":"%s","result_level":"kvm_external_fuse_cache_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_FUSE_BASELINE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_BASELINE_JSON)"

kvm-functional: $(KERNEL_IMAGE) bpf functional
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_functional RUN_ID=$(RUN_ID)"

__phase1_guest_functional:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"functional-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/functional.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/functional/namei_ext_functional" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(PHASE1_RESULT_DIR)/functional.jsonl" /sys/fs/cgroup "$(BUILD_ROOT)/bpf/hide_secret.bpf.o" "$(BUILD_ROOT)/bpf/select_portal.bpf.o"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-functional.log"
	printf '{"event":"functional-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/functional.jsonl"

kvm-bench: $(KERNEL_IMAGE) bpf bench
	command -v jq >/dev/null
	install -d "$(PHASE1_RESULT_DIR)"
	git -C "$(ROOT_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/main-repo-head.txt"
	git -C "$(KERNEL_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/kernel-repo-head.txt"
	git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results' >"$(PHASE1_RESULT_DIR)/main-repo-status.txt"
	git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal >"$(PHASE1_RESULT_DIR)/kernel-repo-status.txt"
	sha256sum "$(KERNEL_IMAGE)" >"$(PHASE1_RESULT_DIR)/kernel-image.sha256"
	sha256sum "$(KERNEL_BUILD_DIR)/.config" >"$(PHASE1_RESULT_DIR)/kernel-config.sha256"
	sha256sum "$(KERNEL_CONFIG_FRAGMENT)" >"$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/phase1.mk" >"$(PHASE1_RESULT_DIR)/benchmark-config.sha256"
	sha256sum "$(ROOT_DIR)/configs/kvm/x86_64.mk" >"$(PHASE1_RESULT_DIR)/kvm-config.sha256"
	main_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/main-repo-status.txt" && printf true || printf false); \
	kernel_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/kernel-repo-status.txt" && printf true || printf false); \
	jq -n \
		--arg schema "namei_ext.phase1.kvm_bench_metadata.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg main_head "$$(cat "$(PHASE1_RESULT_DIR)/main-repo-head.txt")" \
		--arg kernel_head "$$(cat "$(PHASE1_RESULT_DIR)/kernel-repo-head.txt")" \
		--argjson main_dirty "$$main_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
		--arg kernel_image_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-image.sha256")" \
		--arg kernel_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config.sha256")" \
		--arg kernel_config_fragment_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256")" \
		--arg benchmark_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/benchmark-config.sha256")" \
		--arg kvm_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kvm-config.sha256")" \
		--arg samples "$(SAMPLES)" \
		--arg bench_iters "$(BENCH_ITERS)" \
		--arg bench_latency_samples "$(BENCH_LATENCY_SAMPLES)" \
		--arg bench_latency_batch "$(BENCH_LATENCY_BATCH)" \
		--arg bench_randomize_order "$(BENCH_RANDOMIZE_ORDER)" \
		--arg bench_variants "$(BENCH_VARIANTS)" \
		--arg kvm_cpus "$(KVM_CPUS)" \
		--arg kvm_mem "$(KVM_MEM)" \
		--arg kvm_append "$(KVM_APPEND)" \
		'{schema:$$schema, run_id:$$run_id, generated_at:$$generated_at, main_repo:{head:$$main_head, dirty:$$main_dirty, status_file:"main-repo-status.txt"}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty, status_file:"kernel-repo-status.txt"}, artifacts:{kernel_image_sha256:$$kernel_image_sha256, kernel_config_sha256:$$kernel_config_sha256, kernel_config_fragment_sha256:$$kernel_config_fragment_sha256, benchmark_config_sha256:$$benchmark_config_sha256, kvm_config_sha256:$$kvm_config_sha256}, config:{samples:$$samples, bench_iters:$$bench_iters, bench_latency_samples:$$bench_latency_samples, bench_latency_batch:$$bench_latency_batch, bench_randomize_order:$$bench_randomize_order, bench_variants:$$bench_variants, kvm_cpus:$$kvm_cpus, kvm_mem:$$kvm_mem, kvm_append:$$kvm_append}}' \
		>"$(PHASE1_RESULT_DIR)/metadata.json"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_bench RUN_ID=$(RUN_ID) SAMPLES=$(SAMPLES) BENCH_ITERS=$(BENCH_ITERS) BENCH_LATENCY_SAMPLES=$(BENCH_LATENCY_SAMPLES) BENCH_LATENCY_BATCH=$(BENCH_LATENCY_BATCH) BENCH_RANDOMIZE_ORDER=$(BENCH_RANDOMIZE_ORDER) BENCH_VARIANTS='$(BENCH_VARIANTS)'"

__phase1_guest_bench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"bench-start","run_id":"%s","samples":%s,"iterations":%s,"latency_samples":%s,"latency_batch":%s,"randomize_order":"%s","bench_variants":"%s","policy_variants":["pass_only","table_redirect_empty","table_redirect_hit","policy"]}\n' "$(RUN_ID)" "$(SAMPLES)" "$(BENCH_ITERS)" "$(BENCH_LATENCY_SAMPLES)" "$(BENCH_LATENCY_BATCH)" "$(BENCH_RANDOMIZE_ORDER)" "$(BENCH_VARIANTS)" >"$(PHASE1_RESULT_DIR)/bench.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o"
	test -s "$(PASS_ONLY_POLICY)"
	test -s "$(TABLE_REDIRECT_POLICY)"
	printf '{"event":"bench-system-metrics-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	cat /proc/stat >"$(PHASE1_RESULT_DIR)/bench-proc-stat-before.txt"
	cat /proc/meminfo >"$(PHASE1_RESULT_DIR)/bench-meminfo-before.txt"
	cat /proc/vmstat >"$(PHASE1_RESULT_DIR)/bench-vmstat-before.txt"
	cat /proc/diskstats >"$(PHASE1_RESULT_DIR)/bench-diskstats-before.txt"
	printf '{"event":"bench-system-metrics","run_id":"%s","phase":"before","proc_stat":"bench-proc-stat-before.txt","meminfo":"bench-meminfo-before.txt","vmstat":"bench-vmstat-before.txt","diskstats":"bench-diskstats-before.txt"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	status=0; NAMEI_EXT_RUN_ID="$(RUN_ID)" NAMEI_EXT_BENCH_ORDER_SEED="$(RUN_ID)" NAMEI_EXT_BENCH_RANDOMIZE="$(BENCH_RANDOMIZE_ORDER)" NAMEI_EXT_BENCH_VARIANTS="$(BENCH_VARIANTS)" "$(BUILD_ROOT)/bench-workloads/namei_ext_bench" "$(PHASE1_RESULT_DIR)/bench.jsonl" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(SAMPLES)" "$(BENCH_ITERS)" /sys/fs/cgroup "$(PASS_ONLY_POLICY)" "$(TABLE_REDIRECT_POLICY)" "$(BENCH_LATENCY_SAMPLES)" "$(BENCH_LATENCY_BATCH)" || status=$$?; printf '%s\n' "$$status" >"$(PHASE1_RESULT_DIR)/bench-status.txt"
	cat /proc/stat >"$(PHASE1_RESULT_DIR)/bench-proc-stat-after.txt"
	cat /proc/meminfo >"$(PHASE1_RESULT_DIR)/bench-meminfo-after.txt"
	cat /proc/vmstat >"$(PHASE1_RESULT_DIR)/bench-vmstat-after.txt"
	cat /proc/diskstats >"$(PHASE1_RESULT_DIR)/bench-diskstats-after.txt"
	printf '{"event":"bench-system-metrics","run_id":"%s","phase":"after","proc_stat":"bench-proc-stat-after.txt","meminfo":"bench-meminfo-after.txt","vmstat":"bench-vmstat-after.txt","diskstats":"bench-diskstats-after.txt"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-bench.log"
	status=$$(cat "$(PHASE1_RESULT_DIR)/bench-status.txt"); printf '{"event":"bench-done","run_id":"%s","status":%s}\n' "$(RUN_ID)" "$$status" >>"$(PHASE1_RESULT_DIR)/bench.jsonl"
	test "$$(cat "$(PHASE1_RESULT_DIR)/bench-status.txt")" = "0"

kvm-eval-osdi-baselines: $(KERNEL_IMAGE) bench
	install -d "$(EVAL_OSDI_BASELINE_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __eval_osdi_guest_baselines RUN_ID=$(RUN_ID) BASELINE_SAMPLES=$(BASELINE_SAMPLES) BASELINE_ITERS=$(BASELINE_ITERS) BASELINE_LATENCY_SAMPLES=$(BASELINE_LATENCY_SAMPLES) BASELINE_LATENCY_BATCH=$(BASELINE_LATENCY_BATCH) EVAL_OSDI_BASELINES='$(EVAL_OSDI_BASELINES)'"

__eval_osdi_guest_baselines:
	install -d "$(EVAL_OSDI_BASELINE_DIR)"
	printf '{"event":"baseline-guest-start","run_id":"%s","result_level":"kvm_external_baseline_raw"}\n' "$(RUN_ID)" >"$(EVAL_OSDI_BASELINE_GUEST_JSON)"
	test -x "$(BUILD_ROOT)/bench-workloads/namei_ext_baselines"
	install -d /run/namei-ext-baselines
	if ! mountpoint -q /run/namei-ext-baselines; then mount -t tmpfs -o mode=0700,size=256m tmpfs /run/namei-ext-baselines; fi
	: >"$(EVAL_OSDI_BASELINE_JSON)"
	status=0; NAMEI_EXT_BASELINE_TMPDIR=/run/namei-ext-baselines "$(BUILD_ROOT)/bench-workloads/namei_ext_baselines" "$(EVAL_OSDI_BASELINE_JSON)" "$(RUN_ID)" "$(BASELINE_SAMPLES)" "$(BASELINE_ITERS)" "$(BASELINE_LATENCY_SAMPLES)" "$(BASELINE_LATENCY_BATCH)" "$(EVAL_OSDI_BASELINES)" || status=$$?; dmesg >"$(EVAL_OSDI_BASELINE_DMESG)"; dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(EVAL_OSDI_BASELINE_DMESG)"); test "$$dmesg_issues" = "0"; test "$$status" = "0"
	printf '{"event":"baseline-guest-done","run_id":"%s","result_level":"kvm_external_baseline_raw"}\n' "$(RUN_ID)" >>"$(EVAL_OSDI_BASELINE_GUEST_JSON)"
