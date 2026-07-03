EVAL_OSDI_PHASE1_RUN_ID ?= $(RUN_ID)
EVAL_OSDI_PHASE1_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_PHASE1_RUN_ID)
EVAL_OSDI_WORKLOAD_RUN_DIR ?= $(RESULT_ROOT)/workloads/runs/$(EVAL_OSDI_PHASE1_RUN_ID)
EVAL_OSDI_RESULT_DIR ?= $(RESULT_ROOT)/eval-osdi/paper/$(RUN_ID)
EVAL_OSDI_B12_DIR ?= $(EVAL_OSDI_RESULT_DIR)/b12-policy-family
EVAL_OSDI_MANIFEST ?= $(EVAL_OSDI_RESULT_DIR)/manifest.json
EVAL_OSDI_POLICY_FAMILY_JSON ?= $(EVAL_OSDI_B12_DIR)/policy-family.jsonl
EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256 ?= $(EVAL_OSDI_B12_DIR)/policy-family-inputs.sha256
EVAL_OSDI_POLICY_FAMILY_SUMMARY ?= $(EVAL_OSDI_B12_DIR)/summary.md
EVAL_OSDI_PERFORMANCE_DIR ?= $(EVAL_OSDI_RESULT_DIR)/b2-performance
EVAL_OSDI_PERFORMANCE_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance.jsonl
EVAL_OSDI_PERFORMANCE_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-inputs.sha256
EVAL_OSDI_PERFORMANCE_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/summary.md
EVAL_OSDI_PERFORMANCE_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/manifest.json
EVAL_OSDI_PERFORMANCE_TAIL_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/bench-latency-tail.jsonl
EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/bench-latency-tail-inputs.sha256
EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/bench-latency-tail-summary.md
EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/bench-latency-tail-manifest.json
EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON ?= $(EVAL_OSDI_PHASE1_DIR)/bench-system-metrics.jsonl
EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/external-baseline-latency-tail.jsonl
EVAL_OSDI_PERFORMANCE_COMPARISON_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-comparison.jsonl
EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-comparison-inputs.sha256
EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-comparison-summary.md
EVAL_OSDI_PERFORMANCE_COMPARISON_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-comparison-manifest.json
EVAL_OSDI_PERFORMANCE_SCOPE_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-tool-redirect-scope.jsonl
EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-tool-redirect-scope-inputs.sha256
EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-tool-redirect-scope-summary.md
EVAL_OSDI_PERFORMANCE_SCOPE_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/performance-tool-redirect-scope-manifest.json
EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID ?=
EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID)/b2-performance/performance-comparison.jsonl
EVAL_OSDI_C3_RESIDUAL_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c3-full-suite-residual-diagnostic.jsonl
EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c3-full-suite-residual-diagnostic-inputs.sha256
EVAL_OSDI_C3_RESIDUAL_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c3-full-suite-residual-diagnostic-summary.md
EVAL_OSDI_C3_RESIDUAL_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c3-full-suite-residual-diagnostic-manifest.json
EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID ?=
EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)/b2-performance/performance-comparison.jsonl
EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)/b2-performance/bench-latency-tail.jsonl
EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)/b2-performance/external-baseline-latency-tail.jsonl
EVAL_OSDI_C5_ABLATION_JSON ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c5-rusage-nohook-ablation.jsonl
EVAL_OSDI_C5_ABLATION_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c5-rusage-nohook-ablation-inputs.sha256
EVAL_OSDI_C5_ABLATION_SUMMARY ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c5-rusage-nohook-ablation-summary.md
EVAL_OSDI_C5_ABLATION_MANIFEST ?= $(EVAL_OSDI_PERFORMANCE_DIR)/c5-rusage-nohook-ablation-manifest.json
EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID ?=
EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID)/b2-performance/bench-latency-tail.jsonl
EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID ?=
EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID)/bench.jsonl
EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID ?=
EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID)/b2-performance/bench-latency-tail.jsonl
EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID ?=
EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID)/b2-performance/bench-latency-tail.jsonl
EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES ?= lookup_tool_redirect access_tool_redirect open_tool_redirect exec_tool_redirect
EVAL_OSDI_PAPER_RELEASE_DIR ?= $(EVAL_OSDI_RESULT_DIR)/paper-release
EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON ?= $(EVAL_OSDI_PAPER_RELEASE_DIR)/w2-tool-redirect-paper-release-gate.jsonl
EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256 ?= $(EVAL_OSDI_PAPER_RELEASE_DIR)/w2-tool-redirect-paper-release-gate-inputs.sha256
EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY ?= $(EVAL_OSDI_PAPER_RELEASE_DIR)/w2-tool-redirect-paper-release-gate-summary.md
EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_MANIFEST ?= $(EVAL_OSDI_PAPER_RELEASE_DIR)/w2-tool-redirect-paper-release-gate-manifest.json
EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/w2-tool-redirect-paper-release-gate.jq
EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID ?=
EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID)/w2-nginx-real-trace.jsonl
EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_INPUTS_SHA256 ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID)/w2-nginx-real-trace-inputs.sha256
EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID ?=
EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID)/b3-macrobench/w2-nginx-workload-macrobench.jsonl
EVAL_OSDI_W2_TOOL_REDIRECT_W2_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID)/b3-macrobench/w2-nginx-workload-macrobench-inputs.sha256
EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID ?=
EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID)/b2-performance/performance-tool-redirect-scope.jsonl
EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID)/b2-performance/performance-tool-redirect-scope-inputs.sha256
EVAL_OSDI_MACROBENCH_DIR ?= $(EVAL_OSDI_RESULT_DIR)/b3-macrobench
EVAL_OSDI_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/macrobench.jsonl
EVAL_OSDI_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/macrobench-inputs.sha256
EVAL_OSDI_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/summary.md
EVAL_OSDI_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/manifest.json
EVAL_OSDI_WORKLOAD_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/workload-macrobench.jsonl
EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/workload-macrobench-inputs.sha256
EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/workload-macrobench-summary.md
EVAL_OSDI_WORKLOAD_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/workload-macrobench-manifest.json
EVAL_OSDI_C4_DIR ?= $(EVAL_OSDI_RESULT_DIR)/c4-lookup-readdir
EVAL_OSDI_C4_JSON ?= $(EVAL_OSDI_C4_DIR)/c4-lookup-readdir-matrix.jsonl
EVAL_OSDI_C4_INPUTS_SHA256 ?= $(EVAL_OSDI_C4_DIR)/c4-lookup-readdir-matrix-inputs.sha256
EVAL_OSDI_C4_SUMMARY ?= $(EVAL_OSDI_C4_DIR)/c4-lookup-readdir-matrix-summary.md
EVAL_OSDI_C4_MANIFEST ?= $(EVAL_OSDI_C4_DIR)/c4-lookup-readdir-matrix-manifest.json
EVAL_OSDI_C4_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/c4-lookup-readdir-matrix.jq
EVAL_OSDI_C4_PHASE1_RUN_ID ?= $(EVAL_OSDI_PHASE1_RUN_ID)
EVAL_OSDI_C4_PHASE1_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_C4_PHASE1_RUN_ID)
EVAL_OSDI_C4_W1_JSON ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w1-oracle.jsonl
EVAL_OSDI_C4_W1_INPUTS_SHA256 ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w1-oracle-inputs.sha256
EVAL_OSDI_C4_W2_JSON ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w2-oracle.jsonl
EVAL_OSDI_C4_W2_INPUTS_SHA256 ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w2-oracle-inputs.sha256
EVAL_OSDI_C4_W3_JSON ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w3-oracle.jsonl
EVAL_OSDI_C4_W3_INPUTS_SHA256 ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w3-oracle-inputs.sha256
EVAL_OSDI_C4_W4_JSON ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w4-oracle.jsonl
EVAL_OSDI_C4_W4_INPUTS_SHA256 ?= $(EVAL_OSDI_C4_PHASE1_DIR)/w4-oracle-inputs.sha256
EVAL_OSDI_CLAIM_VERDICT_DIR ?= $(EVAL_OSDI_RESULT_DIR)/claim-verdict
EVAL_OSDI_CLAIM_VERDICT_JSON ?= $(EVAL_OSDI_CLAIM_VERDICT_DIR)/claim-verdict.jsonl
EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256 ?= $(EVAL_OSDI_CLAIM_VERDICT_DIR)/claim-verdict-inputs.sha256
EVAL_OSDI_CLAIM_VERDICT_SUMMARY ?= $(EVAL_OSDI_CLAIM_VERDICT_DIR)/claim-verdict-summary.md
EVAL_OSDI_CLAIM_VERDICT_MANIFEST ?= $(EVAL_OSDI_CLAIM_VERDICT_DIR)/claim-verdict-manifest.json
EVAL_OSDI_CLAIM_VERDICT_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/claim-verdict.jq
EVAL_OSDI_C7_AUDIT_DIR ?= $(EVAL_OSDI_RESULT_DIR)/artifact-audit
EVAL_OSDI_C7_AUDIT_JSON ?= $(EVAL_OSDI_C7_AUDIT_DIR)/c7-artifact-reproducibility-audit.jsonl
EVAL_OSDI_C7_AUDIT_INPUTS_SHA256 ?= $(EVAL_OSDI_C7_AUDIT_DIR)/c7-artifact-reproducibility-audit-inputs.sha256
EVAL_OSDI_C7_AUDIT_SUMMARY ?= $(EVAL_OSDI_C7_AUDIT_DIR)/c7-artifact-reproducibility-audit-summary.md
EVAL_OSDI_C7_AUDIT_MANIFEST ?= $(EVAL_OSDI_C7_AUDIT_DIR)/c7-artifact-reproducibility-audit-manifest.json
EVAL_OSDI_C7_AUDIT_MAIN_STATUS ?= $(EVAL_OSDI_C7_AUDIT_DIR)/main-repo-status.txt
EVAL_OSDI_C7_AUDIT_KERNEL_STATUS ?= $(EVAL_OSDI_C7_AUDIT_DIR)/kernel-repo-status.txt
EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST ?= $(EVAL_OSDI_C7_AUDIT_DIR)/artifact-package-files.txt
EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT ?= $(EVAL_OSDI_C7_AUDIT_DIR)/package-root
EVAL_OSDI_C7_AUDIT_PACKAGE_TAR ?= $(EVAL_OSDI_C7_AUDIT_DIR)/namei-ext-osdi-evidence-package.tar
EVAL_OSDI_C7_AUDIT_PACKAGE_TAR_LIST ?= $(EVAL_OSDI_C7_AUDIT_DIR)/artifact-package-tar-list.txt
EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST ?= $(EVAL_OSDI_C7_AUDIT_DIR)/artifact-package-manifest.json
EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST ?= $(EVAL_OSDI_C7_AUDIT_DIR)/artifact-anonymization-checklist.json
EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG ?= $(EVAL_OSDI_C7_AUDIT_DIR)/artifact-package-replay.log
EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_PDF ?= $(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/.build/paper/main.pdf
EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID ?=
EVAL_OSDI_C7_AUDIT_CLAIM_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)/claim-verdict/claim-verdict.jsonl
EVAL_OSDI_C7_AUDIT_CLAIM_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)/claim-verdict/claim-verdict-inputs.sha256
EVAL_OSDI_C7_AUDIT_C3_RUN_ID ?=
EVAL_OSDI_C7_AUDIT_C3_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_C3_RUN_ID)/b2-performance/c3-full-suite-residual-diagnostic.jsonl
EVAL_OSDI_C7_AUDIT_C5_RUN_ID ?=
EVAL_OSDI_C7_AUDIT_C5_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_C5_RUN_ID)/b2-performance/c5-rusage-nohook-ablation.jsonl
EVAL_OSDI_CLAIM_W1_RUN_ID ?=
EVAL_OSDI_CLAIM_W1_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W1_RUN_ID)/b3-macrobench/w1-build-workload-macrobench.jsonl
EVAL_OSDI_CLAIM_W1_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W1_RUN_ID)/b3-macrobench/w1-build-workload-macrobench-inputs.sha256
EVAL_OSDI_CLAIM_W2_RUN_ID ?=
EVAL_OSDI_CLAIM_W2_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W2_RUN_ID)/b3-macrobench/w2-nginx-workload-macrobench.jsonl
EVAL_OSDI_CLAIM_W2_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W2_RUN_ID)/b3-macrobench/w2-nginx-workload-macrobench-inputs.sha256
EVAL_OSDI_CLAIM_W3_RUN_ID ?=
EVAL_OSDI_CLAIM_W3_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W3_RUN_ID)/b3-macrobench/w3-redis-workload-macrobench.jsonl
EVAL_OSDI_CLAIM_W3_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W3_RUN_ID)/b3-macrobench/w3-redis-workload-macrobench-inputs.sha256
EVAL_OSDI_CLAIM_W4_RUN_ID ?=
EVAL_OSDI_CLAIM_W4_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W4_RUN_ID)/b3-macrobench/w4-ccache-workload-macrobench.jsonl
EVAL_OSDI_CLAIM_W4_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_W4_RUN_ID)/b3-macrobench/w4-ccache-workload-macrobench-inputs.sha256
EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID ?=
EVAL_OSDI_CLAIM_PERFORMANCE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID)/b2-performance/performance-comparison.jsonl
EVAL_OSDI_CLAIM_PERFORMANCE_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID)/b2-performance/performance-comparison-inputs.sha256
EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID ?=
EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID)/b2-performance/performance-tool-redirect-scope.jsonl
EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID)/b2-performance/performance-tool-redirect-scope-inputs.sha256
EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID ?=
EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID)/paper-release/w2-tool-redirect-paper-release-gate.jsonl
EVAL_OSDI_CLAIM_PAPER_RELEASE_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID)/paper-release/w2-tool-redirect-paper-release-gate-inputs.sha256
EVAL_OSDI_CLAIM_C4_RUN_ID ?=
EVAL_OSDI_CLAIM_C4_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_C4_RUN_ID)/c4-lookup-readdir/c4-lookup-readdir-matrix.jsonl
EVAL_OSDI_CLAIM_C4_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_C4_RUN_ID)/c4-lookup-readdir/c4-lookup-readdir-matrix-inputs.sha256
EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID ?=
EVAL_OSDI_CLAIM_W4_TRANSITION_JSON ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID)/w4-cache-transition-counterfactual.jsonl
EVAL_OSDI_CLAIM_W4_TRANSITION_INPUTS_SHA256 ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID)/w4-cache-transition-counterfactual-inputs.sha256
EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID ?=
EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID)/w4-cache-table-content.jsonl
EVAL_OSDI_CLAIM_W4_CACHE_TABLE_INPUTS_SHA256 ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID)/w4-cache-table-content-inputs.sha256
EVAL_OSDI_CLAIM_C7_AUDIT_RUN_ID ?=
EVAL_OSDI_CLAIM_C7_AUDIT_JSON ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_C7_AUDIT_RUN_ID)/artifact-audit/c7-artifact-reproducibility-audit.jsonl
EVAL_OSDI_CLAIM_C7_AUDIT_INPUTS_SHA256 ?= $(RESULT_ROOT)/eval-osdi/paper/$(EVAL_OSDI_CLAIM_C7_AUDIT_RUN_ID)/artifact-audit/c7-artifact-reproducibility-audit-inputs.sha256
EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench.jsonl
EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench-inputs.sha256
EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench-summary.md
EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench-manifest.json
EVAL_OSDI_W1_BUILD_POLICY_RUN_ID ?=
EVAL_OSDI_W1_BUILD_POLICY_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W1_BUILD_POLICY_RUN_ID)
EVAL_OSDI_W1_BUILD_POLICY_JSON ?= $(EVAL_OSDI_W1_BUILD_POLICY_DIR)/w1-build-macrobench.jsonl
EVAL_OSDI_W1_BUILD_POLICY_INPUTS_SHA256 ?= $(EVAL_OSDI_W1_BUILD_POLICY_DIR)/w1-build-macrobench-inputs.sha256
EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID ?=
EVAL_OSDI_W1_BUILD_BASELINE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID)
EVAL_OSDI_W1_BUILD_BASELINE_JSON ?= $(EVAL_OSDI_W1_BUILD_BASELINE_DIR)/w1-build-baseline-macrobench.jsonl
EVAL_OSDI_W1_BUILD_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_W1_BUILD_BASELINE_DIR)/w1-build-baseline-macrobench-inputs.sha256
EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID ?= $(EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID)
EVAL_OSDI_W1_BUILD_FUSE_TEST_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID)
EVAL_OSDI_W1_BUILD_FUSE_TEST_JSON ?= $(EVAL_OSDI_W1_BUILD_FUSE_TEST_DIR)/w1-build-baseline-macrobench.jsonl
EVAL_OSDI_W1_BUILD_FUSE_TEST_INPUTS_SHA256 ?= $(EVAL_OSDI_W1_BUILD_FUSE_TEST_DIR)/w1-build-baseline-macrobench-inputs.sha256
EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/w1-build-workload-macrobench.jq
EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/w2-nginx-workload-macrobench.jsonl
EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/w2-nginx-workload-macrobench-inputs.sha256
EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/w2-nginx-workload-macrobench-summary.md
EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/w2-nginx-workload-macrobench-manifest.json
EVAL_OSDI_W2_NGINX_POLICY_RUN_ID ?=
EVAL_OSDI_W2_NGINX_POLICY_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W2_NGINX_POLICY_RUN_ID)
EVAL_OSDI_W2_NGINX_POLICY_JSON ?= $(EVAL_OSDI_W2_NGINX_POLICY_DIR)/w2-nginx-macrobench.jsonl
EVAL_OSDI_W2_NGINX_POLICY_INPUTS_SHA256 ?= $(EVAL_OSDI_W2_NGINX_POLICY_DIR)/w2-nginx-macrobench-inputs.sha256
EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID ?=
EVAL_OSDI_W2_NGINX_BASELINE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID)
EVAL_OSDI_W2_NGINX_BASELINE_JSON ?= $(EVAL_OSDI_W2_NGINX_BASELINE_DIR)/w2-nginx-baseline-macrobench.jsonl
EVAL_OSDI_W2_NGINX_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_W2_NGINX_BASELINE_DIR)/w2-nginx-baseline-macrobench-inputs.sha256
EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/w2-nginx-workload-macrobench.jq
EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/w3-redis-workload-macrobench.jsonl
EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/w3-redis-workload-macrobench-inputs.sha256
EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/w3-redis-workload-macrobench-summary.md
EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/w3-redis-workload-macrobench-manifest.json
EVAL_OSDI_W3_REDIS_POLICY_RUN_ID ?=
EVAL_OSDI_W3_REDIS_POLICY_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W3_REDIS_POLICY_RUN_ID)
EVAL_OSDI_W3_REDIS_POLICY_JSON ?= $(EVAL_OSDI_W3_REDIS_POLICY_DIR)/w3-redis-policy-macrobench.jsonl
EVAL_OSDI_W3_REDIS_POLICY_INPUTS_SHA256 ?= $(EVAL_OSDI_W3_REDIS_POLICY_DIR)/w3-redis-policy-macrobench-inputs.sha256
EVAL_OSDI_W3_REDIS_BASELINE_RUN_ID ?=
EVAL_OSDI_W3_REDIS_BASELINE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W3_REDIS_BASELINE_RUN_ID)
EVAL_OSDI_W3_REDIS_BASELINE_JSON ?= $(EVAL_OSDI_W3_REDIS_BASELINE_DIR)/w3-redis-baseline-macrobench.jsonl
EVAL_OSDI_W3_REDIS_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_W3_REDIS_BASELINE_DIR)/w3-redis-baseline-macrobench-inputs.sha256
EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/w3-redis-workload-macrobench.jq
EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON ?= $(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench.jsonl
EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench-inputs.sha256
EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY ?= $(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench-summary.md
EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_MANIFEST ?= $(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench-manifest.json
EVAL_OSDI_W4_CCACHE_RULE_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_RULE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_RULE_RUN_ID)
EVAL_OSDI_W4_CCACHE_RULE_JSON ?= $(EVAL_OSDI_W4_CCACHE_RULE_DIR)/w4-ccache-rule-macrobench.jsonl
EVAL_OSDI_W4_CCACHE_RULE_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_RULE_DIR)/w4-ccache-rule-macrobench-inputs.sha256
EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_MATERIALIZED_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID)
EVAL_OSDI_W4_CCACHE_MATERIALIZED_JSON ?= $(EVAL_OSDI_W4_CCACHE_MATERIALIZED_DIR)/w4-ccache-materialized-baseline.jsonl
EVAL_OSDI_W4_CCACHE_MATERIALIZED_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_MATERIALIZED_DIR)/w4-ccache-materialized-baseline-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_POLICY_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_POLICY_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_DIR)/w4-ccache-bulk-policy-compile.jsonl
EVAL_OSDI_W4_CCACHE_BULK_POLICY_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_DIR)/w4-ccache-bulk-policy-compile-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_DIR)/w4-ccache-bulk-policy-macrobench.jsonl
EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_DIR)/w4-ccache-bulk-policy-macrobench-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_DIR)/w4-ccache-bulk-materialized-baseline.jsonl
EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_DIR)/w4-ccache-bulk-materialized-baseline-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_FUSE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_FUSE_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_DIR)/w4-ccache-bulk-fuse-baseline.jsonl
EVAL_OSDI_W4_CCACHE_BULK_FUSE_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_DIR)/w4-ccache-bulk-fuse-baseline-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_DIR)/w4-ccache-bulk-fuse-compile.jsonl
EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_DIR)/w4-ccache-bulk-fuse-compile-inputs.sha256
EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID ?=
EVAL_OSDI_W4_CCACHE_BULK_NATIVE_DIR ?= $(RESULT_ROOT)/phase1/$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID)
EVAL_OSDI_W4_CCACHE_BULK_NATIVE_JSON ?= $(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_DIR)/w4-ccache-bulk-native-compile.jsonl
EVAL_OSDI_W4_CCACHE_BULK_NATIVE_INPUTS_SHA256 ?= $(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_DIR)/w4-ccache-bulk-native-compile-inputs.sha256
EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_FILTER ?= $(ROOT_DIR)/configs/eval-osdi/w4-ccache-workload-macrobench.jq
EVAL_OSDI_BASELINE_DIR ?= $(RESULT_ROOT)/eval-osdi/baselines/$(RUN_ID)
EVAL_OSDI_BASELINE_JSON ?= $(EVAL_OSDI_BASELINE_DIR)/baselines.jsonl
EVAL_OSDI_BASELINE_LEDGER_JSON ?= $(EVAL_OSDI_BASELINE_DIR)/baseline-ledger.jsonl
EVAL_OSDI_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_BASELINE_DIR)/baseline-inputs.sha256
EVAL_OSDI_BASELINE_SUMMARY ?= $(EVAL_OSDI_BASELINE_DIR)/summary.md
EVAL_OSDI_BASELINE_MANIFEST ?= $(EVAL_OSDI_BASELINE_DIR)/manifest.json
EVAL_OSDI_BASELINE_GUEST_JSON ?= $(EVAL_OSDI_BASELINE_DIR)/guest.jsonl
EVAL_OSDI_BASELINE_DMESG ?= $(EVAL_OSDI_BASELINE_DIR)/dmesg-baselines.log
EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID ?=
EVAL_OSDI_PERFORMANCE_BASELINE_DIR ?= $(RESULT_ROOT)/eval-osdi/baselines/$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)
EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON ?= $(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baseline-ledger.jsonl
EVAL_OSDI_PERFORMANCE_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baseline-inputs.sha256
EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID ?= $(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)
EVAL_OSDI_MACROBENCH_BASELINE_DIR ?= $(RESULT_ROOT)/eval-osdi/baselines/$(EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID)
EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON ?= $(EVAL_OSDI_MACROBENCH_BASELINE_DIR)/baseline-ledger.jsonl
EVAL_OSDI_MACROBENCH_BASELINE_INPUTS_SHA256 ?= $(EVAL_OSDI_MACROBENCH_BASELINE_DIR)/baseline-inputs.sha256
EVAL_OSDI_REPORT ?= $(EVAL_OSDI_RESULT_DIR)/summary.md

EVAL_OSDI_REQUIRED_FAMILIES ?= 4
EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY ?= 2
EVAL_OSDI_REQUIRED_PERF_SAMPLES ?= 20
EVAL_OSDI_REQUIRED_BASELINES ?= 5
EVAL_OSDI_TAIL_CI_Z ?= 1.96
EVAL_OSDI_BASELINE_EXPECTED_BENCHES ?= lookup_native_hot lookup_tool_redirect access_tool_redirect open_tool_redirect read_tool_content exec_tool_redirect readdir_alias_view build_tree_stat_walk
EVAL_OSDI_SHARED_PERFORMANCE_BENCHES ?= lookup_native_hot lookup_tool_redirect access_tool_redirect open_tool_redirect exec_tool_redirect readdir_alias_view build_tree_stat_walk
EVAL_OSDI_PASS_ONLY_MAX_P99_NATIVE_RATIO ?= 1.10
EVAL_OSDI_POLICY_MAX_P99_NATIVE_RATIO ?= 1.50
EVAL_OSDI_POLICY_MIN_P99_FUSE_SPEEDUP ?= 2.00
EVAL_OSDI_REQUIRED_LATENCY_BATCH ?= 64

.PHONY: eval-osdi-smoke eval-osdi-policy-family-ledger eval-osdi-policy-family eval-osdi-baselines eval-osdi-macrobench-ledger eval-osdi-macrobench eval-osdi-workload-macrobench-ledger eval-osdi-workload-macrobench eval-osdi-c4-lookup-readdir-ledger eval-osdi-c4-lookup-readdir eval-osdi-claim-verdict-ledger eval-osdi-w1-build-workload-macrobench-ledger eval-osdi-w1-build-workload-macrobench eval-osdi-w2-nginx-workload-macrobench-ledger eval-osdi-w2-nginx-workload-macrobench eval-osdi-w3-redis-workload-macrobench-ledger eval-osdi-w3-redis-workload-macrobench eval-osdi-w4-ccache-workload-macrobench-ledger eval-osdi-w4-ccache-workload-macrobench eval-osdi-performance-tail eval-osdi-performance-ledger eval-osdi-performance-comparison eval-osdi-performance-tool-redirect-ledger eval-osdi-c3-residual-diagnostic-ledger eval-osdi-c5-rusage-nohook-ledger eval-osdi-c7-artifact-audit-ledger eval-osdi-performance eval-osdi-paper eval-osdi-paper-report

eval-osdi-smoke: phase1 eval-osdi-policy-family-ledger eval-osdi-performance-ledger

eval-osdi-policy-family-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_B12_DIR)"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/summary.md"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/metadata.json"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/policy-load.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/policy-semantic.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/table-conformance.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/table-budget.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w1-branch-probes.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-counterfactual.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-cache-table-content.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-build-graph-oracle-entries.tsv"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-build-output-oracle.jsonl"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/alias-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/trace.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/alias-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/trace.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-nginx-fixture/fixture-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-postgres-secret-fixture/fixture-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-sandbox-fixture-oracle-entries.tsv"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-redis-podman-criu/checkpoint-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-nginx-podman-criu/checkpoint-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-checkpoint-oracle-entries.tsv"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-ccache-redis-nginx/cache-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-buildkit-prometheus-go-cache/cache-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-cache-oracle-entries.tsv"
	test -s "$(ROOT_DIR)/workload/w1-redis-build/evidence.md"
	test -s "$(ROOT_DIR)/workload/w1-nginx-build/evidence.md"
	test -s "$(ROOT_DIR)/workload/w2-nginx-fixture/evidence.md"
	test -s "$(ROOT_DIR)/workload/w2-postgres-secret-fixture/evidence.md"
	test -s "$(ROOT_DIR)/workload/w3-redis-podman-criu/evidence.md"
	test -s "$(ROOT_DIR)/workload/w3-nginx-podman-criu/evidence.md"
	test -s "$(ROOT_DIR)/workload/w4-ccache-redis-nginx/evidence.md"
	test -s "$(ROOT_DIR)/workload/w4-buildkit-prometheus-go-cache/evidence.md"
	sha256sum \
		"$(EVAL_OSDI_PHASE1_DIR)/summary.md" \
		"$(EVAL_OSDI_PHASE1_DIR)/metadata.json" \
		"$(EVAL_OSDI_PHASE1_DIR)/policy-load.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/policy-semantic.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/table-conformance.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/table-budget.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w1-branch-probes.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w3-redis-counterfactual.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-cache-table-content.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-build-graph-oracle-entries.tsv" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-build-output-oracle.jsonl" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/alias-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/trace.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/alias-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/trace.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-nginx-fixture/fixture-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-postgres-secret-fixture/fixture-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-sandbox-fixture-oracle-entries.tsv" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-redis-podman-criu/checkpoint-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-nginx-podman-criu/checkpoint-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-checkpoint-oracle-entries.tsv" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-ccache-redis-nginx/cache-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-buildkit-prometheus-go-cache/cache-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-cache-oracle-entries.tsv" \
		"$(ROOT_DIR)/workload/w1-redis-build/evidence.md" \
		"$(ROOT_DIR)/workload/w1-nginx-build/evidence.md" \
		"$(ROOT_DIR)/workload/w2-nginx-fixture/evidence.md" \
		"$(ROOT_DIR)/workload/w2-postgres-secret-fixture/evidence.md" \
		"$(ROOT_DIR)/workload/w3-redis-podman-criu/evidence.md" \
		"$(ROOT_DIR)/workload/w3-nginx-podman-criu/evidence.md" \
		"$(ROOT_DIR)/workload/w4-ccache-redis-nginx/evidence.md" \
		"$(ROOT_DIR)/workload/w4-buildkit-prometheus-go-cache/evidence.md" \
		"$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" \
		"$(ROOT_DIR)/configs/eval-osdi/workloads.mk" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)" >/dev/null
	w1_workloads=$$(jq -s '[.[] | select(.event == "w1-release-build-replay" and .op == "output_compare" and .pass == true and .policy_executed == true and .release_binary_hash_match == true)] | length' "$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl"); \
	w1_semantic=$$(jq -s '[.[] | select(.event == "w1-branch-probe-summary" and .pass == true and .failures == 0 and .policy_executed == true and .kvm_validated == true)] | length == 1' "$(EVAL_OSDI_PHASE1_DIR)/w1-branch-probes.jsonl"); \
	w1_release_metric=$$(jq -s '[.[] | select(.event == "w1-branch-probes-hit-rate" and .operation_weighted_hit_rate_is_release == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w1-branch-probes.jsonl"); \
	w1_table_support=$$(jq -s '[.[] | select(.event == "table-budget" and .family == "build_graph" and .qualified_for_c8 == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/table-budget.jsonl"); \
	w2_workloads=$$(jq -s '[.[] | select(.event == "w2-nginx-real-summary" and .pass == true and .failures == 0)] | length' "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl"); \
	w2_semantic=$$(jq -s '[.[] | select(.event == "w2-nginx-real-summary" and .pass == true and .failures == 0)] | length == 1' "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl"); \
	w2_release_metric=$$(jq -s '[.[] | select(.operation_weighted_hit_rate_is_release == true or .release_endpoint_matrix == true or .trace_no_real_open_checker == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl"); \
	w2_table_support=$$(jq -s '[.[] | select(.event == "table-budget" and .family == "sandbox_fixture" and .qualified_for_c8 == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/table-budget.jsonl"); \
	w3_workloads=$$(jq -s '[.[] | select(.event == "w3-redis-replay-summary" and .pass == true and .failures == 0 and .policy_executed == true and .kvm_validated == true)] | length' "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl"); \
	w3_semantic=$$(jq -s '[.[] | select(.event == "w3-redis-replay-summary" and .pass == true and .failures == 0 and .policy_executed == true and .kvm_validated == true)] | length == 1' "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl"); \
	w3_release_metric=$$(jq -s '[.[] | select(.restore_trace_checker == true or .zero_mixed_epoch == true or .operation_weighted_hit_rate_is_release == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl"); \
	w3_budget_support=$$(jq -s '[.[] | select(.event == "table-budget" and .family == "checkpoint_restore" and .qualified_for_c8 == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/table-budget.jsonl"); \
	w3_counterfactual_support=$$(jq -s '[.[] | select(.event == "w3-redis-counterfactual" and .qualified_for_c8 == true and .table_baseline_current_oracle_pass == false)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-counterfactual.jsonl"); \
	w3_table_support=$$(jq -n --argjson budget "$$w3_budget_support" --argjson counterfactual "$$w3_counterfactual_support" '$$budget or $$counterfactual'); \
	w4_workloads=$$(jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual-summary" and .pass == true and .failures == 0 and .real_ccache_run == true and .parent_scoped_policy_executed == true and .table_policy_executed == true)] | if length == 1 then 2 else 0 end' "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"); \
	w4_semantic=$$(jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual-summary" and .pass == true and .failures == 0 and .real_ccache_run == true and .parent_scoped_policy_executed == true)] | length == 1' "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"); \
	w4_release_metric=$$(jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual-summary" and .operation_weighted_policy_hit_rate_is_release == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"); \
	w4_content_table_negative=$$(jq -s '[.[] | select(.event == "w4-cache-table-content-summary" and .pass == true and .failures == 0 and .table_baseline_current_oracle_pass == true and .content_equivalent_table_oracle == true and .qualified_for_c8 == false)] | length == 1' "$(EVAL_OSDI_PHASE1_DIR)/w4-cache-table-content.jsonl"); \
	w4_table_support=$$(jq -s '[.[] | select(.event == "w4-ccache-release-counterfactual-summary" and .table_baseline_current_oracle_pass == false and .qualified_for_c8 == true)] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"); \
	: >"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg family "build_graph" \
		--arg policy "build_graph_view.bpf.c" \
		--argjson observed_workload_basis '["w1-redis-build:release-output-compare","w1-nginx-build:release-output-compare"]' \
		--argjson observed_workload_rows "$$w1_workloads" \
		--argjson semantic_witness_pass "$$w1_semantic" \
		--argjson release_metric_pass "$$w1_release_metric" \
		--argjson table_counterfactual_support "$$w1_table_support" \
		--arg blocker "缺完整 trace-derived alias set、release-level poison/negative natural workload hit、operation-weighted redirected hit rate 和 table/update budget counterfactual。" \
		'{schema:"namei_ext.eval_osdi.policy_family.v1", event:"eval-osdi-policy-family", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, family:$$family, policy:$$policy, observed_workload_rows:$$observed_workload_rows, observed_workload_basis:$$observed_workload_basis, required_workload_rows:$(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY), semantic_witness_pass:$$semantic_witness_pass, release_metric_pass:$$release_metric_pass, table_counterfactual_support:$$table_counterfactual_support, qualifying_workload_rows:(if $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then $$observed_workload_rows else 0 end), qualified_for_c1_c8:($$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support), gate_state:(if $$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then "qualified" else "blocked" end), release_blocker:$$blocker}' \
		>>"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg family "sandbox_fixture" \
		--arg policy "sandbox_fixture_view.bpf.c" \
		--argjson observed_workload_basis '["w2-nginx-fixture:nginx-real-endpoint-health"]' \
		--argjson observed_workload_rows "$$w2_workloads" \
		--argjson semantic_witness_pass "$$w2_semantic" \
		--argjson release_metric_pass "$$w2_release_metric" \
		--argjson table_counterfactual_support "$$w2_table_support" \
		--arg blocker "缺 PostgreSQL real app oracle、nginx trace-level no-real-open checker、release-level endpoint matrix、startup trace、operation-weighted hit rate 和 table/update budget counterfactual。" \
		'{schema:"namei_ext.eval_osdi.policy_family.v1", event:"eval-osdi-policy-family", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, family:$$family, policy:$$policy, observed_workload_rows:$$observed_workload_rows, observed_workload_basis:$$observed_workload_basis, required_workload_rows:$(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY), semantic_witness_pass:$$semantic_witness_pass, release_metric_pass:$$release_metric_pass, table_counterfactual_support:$$table_counterfactual_support, qualifying_workload_rows:(if $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then $$observed_workload_rows else 0 end), qualified_for_c1_c8:($$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support), gate_state:(if $$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then "qualified" else "blocked" end), release_blocker:$$blocker}' \
		>>"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg family "checkpoint_restore" \
		--arg policy "checkpoint_restore_view.bpf.c" \
		--argjson observed_workload_basis '["w3-redis-podman-criu:redis-checkpoint-replay","w3-redis-podman-criu:table-only-replay-counterfactual"]' \
		--argjson observed_workload_rows "$$w3_workloads" \
		--argjson semantic_witness_pass "$$w3_semantic" \
		--argjson release_metric_pass "$$w3_release_metric" \
		--argjson table_counterfactual_support "$$w3_table_support" \
		--arg blocker "缺 nginx/Grafana/Podman 第二真实 checkpoint workload、真实 Podman/CRIU restore、restore trace、0 mixed epoch checker、operation-weighted hit rate 和能让 table-only 失败或超预算的 release counterfactual；当前 Redis table-only replay 通过，是 C8 负证据。" \
		'{schema:"namei_ext.eval_osdi.policy_family.v1", event:"eval-osdi-policy-family", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, family:$$family, policy:$$policy, observed_workload_rows:$$observed_workload_rows, observed_workload_basis:$$observed_workload_basis, required_workload_rows:$(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY), semantic_witness_pass:$$semantic_witness_pass, release_metric_pass:$$release_metric_pass, table_counterfactual_support:$$table_counterfactual_support, qualifying_workload_rows:(if $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then $$observed_workload_rows else 0 end), qualified_for_c1_c8:($$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support), gate_state:(if $$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then "qualified" else "blocked" end), release_blocker:$$blocker}' \
		>>"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg family "cache_locality" \
		--arg policy "cache_locality_view.bpf.c" \
		--argjson observed_workload_basis '["w4-ccache-redis-nginx:redis-hot-compile","w4-ccache-redis-nginx:nginx-hot-compile"]' \
		--argjson observed_workload_rows "$$w4_workloads" \
		--argjson semantic_witness_pass "$$w4_semantic" \
		--argjson release_metric_pass "$$w4_release_metric" \
		--argjson table_counterfactual_support "$$w4_table_support" \
		--argjson content_table_counterfactual_negative "$$w4_content_table_negative" \
		--arg blocker "缺 release-level operation-weighted policy cache hit rate、真实 stale/corrupt transition、BuildKit cache-path trace、compiler/go output hash 发布级 oracle、stale/update window 和 table/update budget failure；当前 W4 release comparator 与 cache-content same-workload table comparator 都通过，是 C8 负证据。" \
		'{schema:"namei_ext.eval_osdi.policy_family.v1", event:"eval-osdi-policy-family", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, family:$$family, policy:$$policy, observed_workload_rows:$$observed_workload_rows, observed_workload_basis:$$observed_workload_basis, required_workload_rows:$(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY), semantic_witness_pass:$$semantic_witness_pass, release_metric_pass:$$release_metric_pass, table_counterfactual_support:$$table_counterfactual_support, content_table_counterfactual_negative:$$content_table_counterfactual_negative, qualifying_workload_rows:(if $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then $$observed_workload_rows else 0 end), qualified_for_c1_c8:($$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support), gate_state:(if $$observed_workload_rows >= $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY) and $$semantic_witness_pass and $$release_metric_pass and $$table_counterfactual_support then "qualified" else "blocked" end), release_blocker:$$blocker}' \
		>>"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	jq -cs \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg inputs_sha256 "$(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)" \
		'{schema:"namei_ext.eval_osdi.policy_family.v1", event:"eval-osdi-policy-family-summary", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"release_eval_contract", required_qualified_families:$(EVAL_OSDI_REQUIRED_FAMILIES), required_workload_rows_per_family:$(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY), families:([.[] | select(.event == "eval-osdi-policy-family")] | length), qualified_families:([.[] | select(.event == "eval-osdi-policy-family" and .qualified_for_c1_c8 == true)] | length), qualifying_workload_rows:([.[] | select(.event == "eval-osdi-policy-family") | .qualifying_workload_rows] | add), release_gate_pass:(([.[] | select(.event == "eval-osdi-policy-family" and .qualified_for_c1_c8 == true)] | length) >= $(EVAL_OSDI_REQUIRED_FAMILIES)), c1_supported:(([.[] | select(.event == "eval-osdi-policy-family" and .qualified_for_c1_c8 == true)] | length) >= $(EVAL_OSDI_REQUIRED_FAMILIES)), c8_supported:(([.[] | select(.event == "eval-osdi-policy-family" and .qualified_for_c1_c8 == true)] | length) >= $(EVAL_OSDI_REQUIRED_FAMILIES)), inputs_sha256_file:$$inputs_sha256, detail:"当前 ledger 是 release gate contract；未满足的 family 保持 blocked，不能计入 C1 release-level programmability 或 C8。"}' \
		"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp" >>"$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp"; \
	mv "$(EVAL_OSDI_POLICY_FAMILY_JSON).tmp" "$(EVAL_OSDI_POLICY_FAMILY_JSON)"
	jq -e -s 'length == 5 and ([.[] | select(.event == "eval-osdi-policy-family")] | length) == 4 and ([.[] | select(.event == "eval-osdi-policy-family-summary")] | length) == 1' "$(EVAL_OSDI_POLICY_FAMILY_JSON)" >/dev/null
	install -d "$(EVAL_OSDI_RESULT_DIR)"
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg b12_result_dir "$(EVAL_OSDI_B12_DIR)" \
		--arg main_head "$$(jq -r '.main_repo.head' "$(EVAL_OSDI_PHASE1_DIR)/metadata.json")" \
		--arg kernel_head "$$(jq -r '.kernel_repo.head' "$(EVAL_OSDI_PHASE1_DIR)/metadata.json")" \
		--argjson main_dirty "$$(jq -r '.main_repo.dirty' "$(EVAL_OSDI_PHASE1_DIR)/metadata.json")" \
		--argjson kernel_dirty "$$(jq -r '.kernel_repo.dirty' "$(EVAL_OSDI_PHASE1_DIR)/metadata.json")" \
		--arg policy_family_json "$(EVAL_OSDI_POLICY_FAMILY_JSON)" \
		--arg policy_family_inputs_sha256 "$(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)" \
		--arg policy_family_summary "$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)" \
		--argjson qualified_families "$$(jq -s -r '.[] | select(.event == "eval-osdi-policy-family-summary") | .qualified_families' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-policy-family-summary") | .release_gate_pass' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" \
		--argjson c1_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-policy-family-summary") | .c1_supported' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" \
		--argjson c8_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-policy-family-summary") | .c8_supported' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" \
		'{schema:"namei_ext.eval_osdi.manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, generated_at:$$generated_at, phase1_result_dir:$$phase1_result_dir, b12_result_dir:$$b12_result_dir, main_repo:{head:$$main_head, dirty:$$main_dirty}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty}, artifacts:{policy_family_json:$$policy_family_json, policy_family_inputs_sha256:$$policy_family_inputs_sha256, policy_family_summary:$$policy_family_summary}, gate:{qualified_families:$$qualified_families, release_gate_pass:$$release_gate_pass, c1_supported:$$c1_supported, c8_supported:$$c8_supported}}' \
		>"$(EVAL_OSDI_MANIFEST)"
	printf '%s\n' '# OSDI B12 Policy-Family Ledger' >"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence root: $(EVAL_OSDI_PHASE1_DIR)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_POLICY_FAMILY_JSON)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Required families: $(EVAL_OSDI_REQUIRED_FAMILIES)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Required workload rows per family: $(EVAL_OSDI_REQUIRED_WORKLOAD_ROWS_PER_FAMILY)' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Qualified families: '"$$(jq -s -r '[.[] | select(.event == "eval-osdi-policy-family" and .qualified_for_c1_c8 == true)] | length' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '%s\n' '- Release gate pass: '"$$(jq -s -r '.[] | select(.event == "eval-osdi-policy-family-summary") | .release_gate_pass' "$(EVAL_OSDI_POLICY_FAMILY_JSON)")" >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '\n%s\n' '## Families' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-policy-family") | "- " + .family + ": observed=" + (.observed_workload_rows|tostring) + ", qualifying=" + (.qualifying_workload_rows|tostring) + ", semantic=" + (.semantic_witness_pass|tostring) + ", release_metric=" + (.release_metric_pass|tostring) + ", table_counterfactual=" + (.table_counterfactual_support|tostring) + ", gate=" + .gate_state' "$(EVAL_OSDI_POLICY_FAMILY_JSON)" >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	printf '\n%s\n' '## Blockers' >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-policy-family" and .gate_state != "qualified") | "- " + .family + ": " + .release_blocker' "$(EVAL_OSDI_POLICY_FAMILY_JSON)" >>"$(EVAL_OSDI_POLICY_FAMILY_SUMMARY)"

eval-osdi-policy-family: eval-osdi-policy-family-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-policy-family-summary" and .release_gate_pass == true and .qualified_families >= $(EVAL_OSDI_REQUIRED_FAMILIES))' "$(EVAL_OSDI_POLICY_FAMILY_JSON)" >/dev/null

eval-osdi-baselines: kvm-eval-osdi-baselines
	command -v jq >/dev/null
	command -v git >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_BASELINE_DIR)"
	test -s "$(EVAL_OSDI_BASELINE_JSON)"
	test -s "$(EVAL_OSDI_BASELINE_GUEST_JSON)"
	test -s "$(EVAL_OSDI_BASELINE_DMESG)"
	test -s "$(ROOT_DIR)/bench/workloads/namei_ext_baselines.c"
	test -s "$(ROOT_DIR)/bench/workloads/Makefile"
	test -s "$(ROOT_DIR)/configs/benchmarks/phase1.mk"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_BASELINE_JSON)" \
		"$(EVAL_OSDI_BASELINE_GUEST_JSON)" \
		"$(EVAL_OSDI_BASELINE_DMESG)" \
		"$(ROOT_DIR)/bench/workloads/namei_ext_baselines.c" \
		"$(ROOT_DIR)/bench/workloads/Makefile" \
		"$(ROOT_DIR)/configs/benchmarks/phase1.mk" \
		"$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_BASELINE_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_BASELINE_INPUTS_SHA256)" >/dev/null
	jq -s -c \
		--arg run_id "$(RUN_ID)" \
		--arg inputs_sha256 "$(EVAL_OSDI_BASELINE_INPUTS_SHA256)" \
		--arg expected_benches "$(EVAL_OSDI_BASELINE_EXPECTED_BENCHES)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		'($$expected_benches | split(" ") | map(select(length > 0))) as $$expected_benches | def count_rows($$b; $$event; $$bench): [.[] | select(.event == $$event and .baseline == $$b and .bench == $$bench)] | length; def min_rows($$b; $$event): ([$$expected_benches[] as $$bench | count_rows($$b; $$event; $$bench)] | min // 0); def missing_rows($$b; $$event): [$$expected_benches[] as $$bench | select(count_rows($$b; $$event; $$bench) == 0)]; def baseline_row($$b): ([.[] | select(.baseline == $$b)] | length) as $$observed | ([.[] | select(.event == "baseline-setup" and .baseline == $$b)] | first // {}) as $$setup | ([.[] | select(.event == "baseline-update" and .baseline == $$b)] | first // {}) as $$update | ([.[] | select(.event == "baseline-cleanup" and .baseline == $$b)] | first // {}) as $$cleanup | ([.[] | select(.event == "baseline" and .baseline == $$b)] | length) as $$bench_rows | ([.[] | select(.event == "baseline" and .baseline == $$b and .bench == "read_tool_content")] | length) as $$content_rows | ([.[] | select(.event == "baseline_latency" and .baseline == $$b)] | length) as $$latency_rows | ([.[] | select(.event == "baseline" and .baseline == $$b) | .bench] | unique) as $$bench_cases_observed | ([.[] | select(.event == "baseline_latency" and .baseline == $$b) | .bench] | unique) as $$latency_bench_cases_observed | missing_rows($$b; "baseline") as $$missing_bench_cases | missing_rows($$b; "baseline_latency") as $$missing_latency_bench_cases | ([.[] | select(.event == "baseline" and .baseline == $$b) | .sample] | unique | length) as $$samples_observed | ([.[] | select(.event == "baseline_latency" and .baseline == $$b) | .sample] | unique | length) as $$latency_samples_observed | min_rows($$b; "baseline") as $$min_bench_rows_per_case | min_rows($$b; "baseline_latency") as $$min_latency_rows_per_case | ([.[] | select((.event == "baseline" or .event == "baseline_latency") and .baseline == $$b) | .fail] | add // 0) as $$failing_ops | ($$missing_bench_cases | length == 0) as $$has_expected_bench_set | ($$missing_latency_bench_cases | length == 0) as $$has_expected_latency_bench_set | ($$observed > 0 and ($$setup.pass // false) and ($$update.pass // false) and ($$cleanup.pass // false) and $$bench_rows > 0 and $$content_rows > 0 and $$has_expected_bench_set and $$failing_ops == 0) as $$smoke_pass | ($$smoke_pass and $$has_expected_latency_bench_set and $$samples_observed >= $$required_samples and $$min_bench_rows_per_case >= $$required_samples and $$latency_rows > 0 and $$latency_samples_observed >= $$required_samples and $$min_latency_rows_per_case >= $$required_samples) as $$release_pass | {schema:"namei_ext.eval_osdi.baseline_ledger.v1", event:"eval-osdi-baseline", run_id:$$run_id, result_level:"kvm_external_baseline", run_environment:"kvm", baseline:$$b, selected:($$observed > 0), setup_pass:($$setup.pass // false), update_pass:($$update.pass // false), cleanup_pass:($$cleanup.pass // false), setup_ns:($$setup.setup_ns // 0), update_ns:($$update.update_ns // 0), created_dirs:($$setup.created_dirs // 0), created_files:($$setup.created_files // 0), created_symlinks:($$setup.created_symlinks // 0), bind_mounts:($$setup.bind_mounts // 0), overlay_mounts:($$setup.overlay_mounts // 0), fuse_mounts:($$setup.fuse_mounts // 0), bytes_copied:($$setup.bytes_copied // 0), source_update_writes:($$update.source_update_writes // 0), baseline_update_writes:($$update.baseline_update_writes // 0), update_bytes_copied:($$update.update_bytes_copied // 0), expected_bench_cases:$$expected_benches, expected_bench_case_count:($$expected_benches | length), bench_cases_observed:$$bench_cases_observed, latency_bench_cases_observed:$$latency_bench_cases_observed, missing_bench_cases:$$missing_bench_cases, missing_latency_bench_cases:$$missing_latency_bench_cases, has_expected_bench_set:$$has_expected_bench_set, has_expected_latency_bench_set:$$has_expected_latency_bench_set, bench_rows:$$bench_rows, content_rows:$$content_rows, has_update_content_oracle:($$content_rows > 0), latency_rows:$$latency_rows, samples_observed:$$samples_observed, latency_samples_observed:$$latency_samples_observed, min_bench_rows_per_case:$$min_bench_rows_per_case, min_latency_rows_per_case:$$min_latency_rows_per_case, required_paper_samples:$$required_samples, failing_ops:$$failing_ops, inputs_sha256_file:$$inputs_sha256, qualified_for_baseline_smoke:$$smoke_pass, has_release_sample_budget:$$release_pass, qualified_for_baseline_release:$$release_pass}; baseline_row("copy_tree"), baseline_row("symlink_forest"), baseline_row("bind_mount"), baseline_row("overlayfs"), baseline_row("fuse_redirect")' \
		"$(EVAL_OSDI_BASELINE_JSON)" >"$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"
	baselines_selected=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .selected == true)] | length' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	baselines_passed=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .selected == true and .qualified_for_baseline_smoke == true)] | length' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	baselines_release_passed=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .selected == true and .qualified_for_baseline_release == true)] | length' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	runner_failures=$$(jq -s '[.[] | select(.event == "baseline-summary")][0].failures // 1' "$(EVAL_OSDI_BASELINE_JSON)"); \
	raw_rows=$$(jq -s 'length' "$(EVAL_OSDI_BASELINE_JSON)"); \
	bench_rows=$$(jq -s '[.[] | select(.event == "baseline")] | length' "$(EVAL_OSDI_BASELINE_JSON)"); \
	latency_rows=$$(jq -s '[.[] | select(.event == "baseline_latency")] | length' "$(EVAL_OSDI_BASELINE_JSON)"); \
	has_copy_tree=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "copy_tree" and .qualified_for_baseline_smoke == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_symlink_forest=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "symlink_forest" and .qualified_for_baseline_smoke == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_bind_mount=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "bind_mount" and .qualified_for_baseline_smoke == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_overlayfs=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "overlayfs" and .qualified_for_baseline_smoke == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_fuse_redirect=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "fuse_redirect" and .qualified_for_baseline_smoke == true and .fuse_mounts > 0)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_copy_tree_release=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "copy_tree" and .qualified_for_baseline_release == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
	has_symlink_forest_release=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "symlink_forest" and .qualified_for_baseline_release == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
		has_bind_mount_release=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "bind_mount" and .qualified_for_baseline_release == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
		has_overlayfs_release=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "overlayfs" and .qualified_for_baseline_release == true)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
		has_fuse_redirect_release=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline" and .baseline == "fuse_redirect" and .qualified_for_baseline_release == true and .fuse_mounts > 0)] | length == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"); \
		baseline_min_bench_unique_samples=$$(jq -s --arg expected_benches "$(EVAL_OSDI_BASELINE_EXPECTED_BENCHES)" --arg baselines "$(EVAL_OSDI_BASELINES)" '($$expected_benches | split(" ") | map(select(length > 0))) as $$benches | ($$baselines | split(" ") | map(select(length > 0))) as $$baselines | [$$baselines[] as $$baseline | $$benches[] as $$bench | [.[] | select(.event == "baseline" and .baseline == $$baseline and .bench == $$bench) | .sample] | unique | length] | min // 0' "$(EVAL_OSDI_BASELINE_JSON)"); \
		baseline_min_latency_unique_samples=$$(jq -s --arg expected_benches "$(EVAL_OSDI_BASELINE_EXPECTED_BENCHES)" --arg baselines "$(EVAL_OSDI_BASELINES)" '($$expected_benches | split(" ") | map(select(length > 0))) as $$benches | ($$baselines | split(" ") | map(select(length > 0))) as $$baselines | [$$baselines[] as $$baseline | $$benches[] as $$bench | [.[] | select(.event == "baseline_latency" and .baseline == $$baseline and .bench == $$bench) | .sample] | unique | length] | min // 0' "$(EVAL_OSDI_BASELINE_JSON)"); \
		baseline_unique_sample_budget_pass=$$(jq -n --argjson bench_min "$$baseline_min_bench_unique_samples" --argjson latency_min "$$baseline_min_latency_unique_samples" --argjson required "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" '$$bench_min >= $$required and $$latency_min >= $$required'); \
		baseline_release_gate_pass=$$(jq -n --argjson selected "$$baselines_selected" --argjson release_passed "$$baselines_release_passed" --argjson required "$(EVAL_OSDI_REQUIRED_BASELINES)" --argjson failures "$$runner_failures" --argjson has_fuse "$$has_fuse_redirect_release" --argjson unique_budget "$$baseline_unique_sample_budget_pass" '$$selected >= $$required and $$release_passed >= $$required and $$failures == 0 and $$has_fuse and $$unique_budget'); \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg baseline_json "$(EVAL_OSDI_BASELINE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_BASELINE_INPUTS_SHA256)" \
		--argjson required "$(EVAL_OSDI_REQUIRED_BASELINES)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		--argjson raw_rows "$$raw_rows" \
		--argjson bench_rows "$$bench_rows" \
		--argjson latency_rows "$$latency_rows" \
		--argjson baselines_selected "$$baselines_selected" \
		--argjson baselines_passed "$$baselines_passed" \
		--argjson baselines_release_passed "$$baselines_release_passed" \
		--argjson runner_failures "$$runner_failures" \
		--argjson has_copy_tree "$$has_copy_tree" \
		--argjson has_symlink_forest "$$has_symlink_forest" \
		--argjson has_bind_mount "$$has_bind_mount" \
		--argjson has_overlayfs "$$has_overlayfs" \
		--argjson has_fuse_redirect "$$has_fuse_redirect" \
		--argjson has_copy_tree_release "$$has_copy_tree_release" \
		--argjson has_symlink_forest_release "$$has_symlink_forest_release" \
		--argjson has_bind_mount_release "$$has_bind_mount_release" \
			--argjson has_overlayfs_release "$$has_overlayfs_release" \
			--argjson has_fuse_redirect_release "$$has_fuse_redirect_release" \
			--argjson baseline_min_bench_unique_samples "$$baseline_min_bench_unique_samples" \
			--argjson baseline_min_latency_unique_samples "$$baseline_min_latency_unique_samples" \
			--argjson baseline_unique_sample_budget_pass "$$baseline_unique_sample_budget_pass" \
			--argjson baseline_release_gate_pass "$$baseline_release_gate_pass" \
			'{schema:"namei_ext.eval_osdi.baseline_ledger.v1", event:"eval-osdi-baseline-summary", run_id:$$run_id, result_level:"kvm_external_baseline", run_environment:"kvm", baseline_json:$$baseline_json, inputs_sha256_file:$$inputs_sha256, required_baselines:$$required, required_paper_samples:$$required_samples, raw_rows:$$raw_rows, bench_rows:$$bench_rows, latency_rows:$$latency_rows, baselines_selected:$$baselines_selected, baselines_passed:$$baselines_passed, baselines_release_passed:$$baselines_release_passed, baseline_min_bench_unique_samples_per_case:$$baseline_min_bench_unique_samples, baseline_min_latency_unique_samples_per_case:$$baseline_min_latency_unique_samples, baseline_unique_sample_budget_pass:$$baseline_unique_sample_budget_pass, runner_failures:$$runner_failures, has_copy_tree_baseline:$$has_copy_tree, has_symlink_forest_baseline:$$has_symlink_forest, has_bind_mount_baseline:$$has_bind_mount, has_overlayfs_baseline:$$has_overlayfs, has_fuse_redirect_baseline:$$has_fuse_redirect, has_copy_tree_release_baseline:$$has_copy_tree_release, has_symlink_forest_release_baseline:$$has_symlink_forest_release, has_bind_mount_release_baseline:$$has_bind_mount_release, has_overlayfs_release_baseline:$$has_overlayfs_release, has_fuse_redirect_release_baseline:$$has_fuse_redirect_release, missing_release_baselines:[(if $$has_copy_tree_release then empty else "copy_tree" end), (if $$has_symlink_forest_release then empty else "symlink_forest" end), (if $$has_bind_mount_release then empty else "bind_mount" end), (if $$has_overlayfs_release then empty else "overlayfs" end), (if $$has_fuse_redirect_release then empty else "fuse_redirect" end)], baseline_smoke_gate_pass:($$baselines_selected >= $$required and $$baselines_passed >= $$required and $$runner_failures == 0 and $$has_fuse_redirect), baseline_release_gate_pass:$$baseline_release_gate_pass, release_gate_pass:$$baseline_release_gate_pass, detail:"KVM external baseline rows exist for implemented materialization, kernel, and FUSE redirect baselines. Release baseline qualification requires per-baseline feature oracle pass plus release unique-sample budget; head-to-head C2/C3/C5 still depends on the performance ledger."}' \
		>>"$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp"
	mv "$(EVAL_OSDI_BASELINE_LEDGER_JSON).tmp" "$(EVAL_OSDI_BASELINE_LEDGER_JSON)"
	jq -e -s 'length == 6 and ([.[] | select(.event == "eval-osdi-baseline")] | length) == 5 and ([.[] | select(.event == "eval-osdi-baseline-summary" and .baseline_smoke_gate_pass == true)] | length) == 1' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg baseline_dir "$(EVAL_OSDI_BASELINE_DIR)" \
		--arg baseline_json "$(EVAL_OSDI_BASELINE_JSON)" \
		--arg baseline_ledger_json "$(EVAL_OSDI_BASELINE_LEDGER_JSON)" \
		--arg baseline_inputs_sha256 "$(EVAL_OSDI_BASELINE_INPUTS_SHA256)" \
		--arg baseline_summary "$(EVAL_OSDI_BASELINE_SUMMARY)" \
		--arg main_head "$$(git -C "$(ROOT_DIR)" rev-parse HEAD)" \
		--arg kernel_head "$$(git -C "$(KERNEL_DIR)" rev-parse HEAD)" \
		--argjson main_dirty "$$(test -n "$$(git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results')" && printf true || printf false)" \
		--argjson kernel_dirty "$$(test -n "$$(git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal)" && printf true || printf false)" \
		--argjson baseline_smoke_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | .baseline_smoke_gate_pass' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)")" \
		--argjson baseline_release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | .baseline_release_gate_pass' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)")" \
		'{schema:"namei_ext.eval_osdi.baseline_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, baseline_dir:$$baseline_dir, main_repo:{head:$$main_head, dirty:$$main_dirty}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty}, artifacts:{baseline_json:$$baseline_json, baseline_ledger_json:$$baseline_ledger_json, baseline_inputs_sha256:$$baseline_inputs_sha256, baseline_summary:$$baseline_summary}, gate:{baseline_smoke_gate_pass:$$baseline_smoke_gate_pass, baseline_release_gate_pass:$$baseline_release_gate_pass, release_gate_pass:$$baseline_release_gate_pass}}' \
		>"$(EVAL_OSDI_BASELINE_MANIFEST)"
	printf '%s\n' '# OSDI External Baseline Ledger' >"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_BASELINE_JSON)' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '%s\n' '- Ledger JSONL: $(EVAL_OSDI_BASELINE_LEDGER_JSON)' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_BASELINE_INPUTS_SHA256)' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '%s\n' '- Manifest: $(EVAL_OSDI_BASELINE_MANIFEST)' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
		printf '%s\n' '- Baseline smoke gate pass: '"$$(jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | .baseline_smoke_gate_pass' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)")" >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
		printf '%s\n' '- Baseline release gate pass: '"$$(jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | .baseline_release_gate_pass' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)")" >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
		printf '%s\n' '- Baseline unique sample budget pass: '"$$(jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | .baseline_unique_sample_budget_pass' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)")" >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
		printf '\n%s\n' '## Baselines' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-baseline") | "- " + .baseline + ": selected=" + (.selected|tostring) + ", smoke_pass=" + (.qualified_for_baseline_smoke|tostring) + ", release_pass=" + (.qualified_for_baseline_release|tostring) + ", expected_bench_set=" + (.has_expected_bench_set|tostring) + ", expected_latency_set=" + (.has_expected_latency_bench_set|tostring) + ", missing_bench_cases=" + (.missing_bench_cases|join(",")) + ", missing_latency_cases=" + (.missing_latency_bench_cases|join(",")) + ", samples=" + (.samples_observed|tostring) + ", min_bench_rows=" + (.min_bench_rows_per_case|tostring) + ", min_latency_rows=" + (.min_latency_rows_per_case|tostring) + ", setup_ns=" + (.setup_ns|tostring) + ", update_ns=" + (.update_ns|tostring) + ", files=" + (.created_files|tostring) + ", symlinks=" + (.created_symlinks|tostring) + ", bind_mounts=" + (.bind_mounts|tostring) + ", overlay_mounts=" + (.overlay_mounts|tostring) + ", fuse_mounts=" + (.fuse_mounts|tostring) + ", bytes_copied=" + (.bytes_copied|tostring) + ", bench_rows=" + (.bench_rows|tostring) + ", content_rows=" + (.content_rows|tostring) + ", failing_ops=" + (.failing_ops|tostring)' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)" >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
	printf '\n%s\n' '## Missing Release Evidence' >>"$(EVAL_OSDI_BASELINE_SUMMARY)"
		jq -s -r '.[] | select(.event == "eval-osdi-baseline-summary") | "- missing release baselines: " + (.missing_release_baselines|join(", ")) + "\n- min bench unique samples per case: " + (.baseline_min_bench_unique_samples_per_case|tostring) + "\n- min latency unique samples per case: " + (.baseline_min_latency_unique_samples_per_case|tostring) + "\n- release gate pass: " + (.release_gate_pass|tostring)' "$(EVAL_OSDI_BASELINE_LEDGER_JSON)" >>"$(EVAL_OSDI_BASELINE_SUMMARY)"

eval-osdi-macrobench-ledger:
	command -v jq >/dev/null
	command -v git >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID)"
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/summary.md"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/metadata.json"
	test -s "$(EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON)"
	test -s "$(EVAL_OSDI_MACROBENCH_BASELINE_INPUTS_SHA256)"
	test -s "$(ROOT_DIR)/bench/workloads/namei_ext_bench.c"
	test -s "$(ROOT_DIR)/bench/workloads/namei_ext_baselines.c"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/summary.md" \
		"$(EVAL_OSDI_PHASE1_DIR)/metadata.json" \
		"$(EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON)" \
		"$(EVAL_OSDI_MACROBENCH_BASELINE_INPUTS_SHA256)" \
		"$(ROOT_DIR)/bench/workloads/namei_ext_bench.c" \
		"$(ROOT_DIR)/bench/workloads/namei_ext_baselines.c" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -cn \
		--slurpfile bench "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		--slurpfile baseline "$(EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg baseline_run_id "$(EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID)" \
		--arg baseline_ledger_json "$(EVAL_OSDI_MACROBENCH_BASELINE_LEDGER_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_MACROBENCH_INPUTS_SHA256)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		--argjson required_baselines "$(EVAL_OSDI_REQUIRED_BASELINES)" \
		'($$bench | map(select(.event == "namei_ext-setup" and .variant == "backing_tree"))) as $$setups | ($$bench | map(select(.event == "namei_ext-update" and .variant == "backing_tree"))) as $$source_updates | ($$bench | map(select(.event == "namei_ext-update" and .variant == "table_redirect_hit"))) as $$policy_updates | ($$setups[0] // {}) as $$setup | ($$source_updates[0] // {}) as $$source_update | ($$policy_updates[0] // {}) as $$policy_update | ($$setups | length) as $$setup_rows | ($$source_updates | length) as $$source_update_rows | ($$policy_updates | length) as $$policy_update_rows | ($$setups | map(.sample // 0) | unique | length) as $$setup_samples | ($$source_updates | map(.sample // 0) | unique | length) as $$source_update_samples | ($$policy_updates | map(.sample // 0) | unique | length) as $$policy_update_samples | (($$setup.pass // false) and ($$source_update.pass // false) and ($$policy_update.pass // false) and (($$setup.created_dirs // 0) > 0) and (($$setup.created_files // 0) > 0) and (($$source_update.source_update_writes // 0) > 0) and (($$policy_update.policy_update_writes // 0) > 0)) as $$namei_raw_gate_pass | ($$setup_samples >= $$required_samples and $$source_update_samples >= $$required_samples and $$policy_update_samples >= $$required_samples) as $$namei_release_sample_budget_pass | ($$baseline | map(select(.event == "eval-osdi-baseline"))) as $$baseline_rows | ($$baseline | map(select(.event == "eval-osdi-baseline-summary")) | first // {}) as $$baseline_summary | ($$baseline_rows | map(select(.qualified_for_baseline_release == true)) | length) as $$baseline_release_rows | ($$baseline_summary.baseline_release_gate_pass // false) as $$baseline_release_gate_pass | ($$baseline_summary.baseline_unique_sample_budget_pass // false) as $$baseline_unique_sample_budget_pass | ($$namei_raw_gate_pass and $$namei_release_sample_budget_pass and $$baseline_release_gate_pass and $$baseline_release_rows >= $$required_baselines) as $$macrobench_input_gate_pass | {schema:"namei_ext.eval_osdi.macrobench.v1", event:"eval-osdi-macrobench-namei-ext", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"c2_setup_update_contract", run_environment:"kvm", subject:"namei_ext", setup_rows:$$setup_rows, source_update_rows:$$source_update_rows, policy_update_rows:$$policy_update_rows, setup_samples:$$setup_samples, source_update_samples:$$source_update_samples, policy_update_samples:$$policy_update_samples, required_paper_samples:$$required_samples, raw_gate_pass:$$namei_raw_gate_pass, release_sample_budget_pass:$$namei_release_sample_budget_pass, setup_pass:($$setup.pass // false), source_update_pass:($$source_update.pass // false), policy_update_pass:($$policy_update.pass // false), setup_ns:($$setup.setup_ns // 0), source_update_ns:($$source_update.update_ns // 0), policy_update_ns:($$policy_update.update_ns // 0), created_dirs:($$setup.created_dirs // 0), created_files:($$setup.created_files // 0), created_symlinks:($$setup.created_symlinks // 0), bind_mounts:($$setup.bind_mounts // 0), overlay_mounts:($$setup.overlay_mounts // 0), fuse_mounts:($$setup.fuse_mounts // 0), bytes_copied:($$setup.bytes_copied // 0), bytes_written:($$setup.bytes_written // 0), source_update_writes:($$source_update.source_update_writes // 0), policy_update_writes:($$policy_update.policy_update_writes // 0), source_update_bytes_written:($$source_update.update_bytes_written // 0), policy_update_bytes_written:($$policy_update.update_bytes_written // 0), c2_supported:false, detail:"namei_ext setup/update raw rows exist, but workload-equivalent macrobench comparison and thresholds are not satisfied"} , ($$baseline_rows[] | {schema:"namei_ext.eval_osdi.macrobench.v1", event:"eval-osdi-macrobench-baseline", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, baseline_ledger_json:$$baseline_ledger_json, result_level:"c2_setup_update_contract", run_environment:"kvm", baseline:.baseline, selected:.selected, setup_pass:.setup_pass, update_pass:.update_pass, qualified_for_baseline_release:.qualified_for_baseline_release, setup_ns:.setup_ns, update_ns:.update_ns, created_dirs:.created_dirs, created_files:.created_files, created_symlinks:.created_symlinks, bind_mounts:.bind_mounts, overlay_mounts:.overlay_mounts, fuse_mounts:.fuse_mounts, bytes_copied:.bytes_copied, source_update_writes:.source_update_writes, baseline_update_writes:.baseline_update_writes, update_bytes_copied:.update_bytes_copied, namei_setup_ns:($$setup.setup_ns // 0), namei_source_update_ns:($$source_update.update_ns // 0), namei_policy_update_ns:($$policy_update.update_ns // 0), setup_ns_over_namei:(if (($$setup.setup_ns // 0) > 0) then (.setup_ns / $$setup.setup_ns) else null end), update_ns_over_namei_source:(if (($$source_update.update_ns // 0) > 0) then (.update_ns / $$source_update.update_ns) else null end), c2_supported:false}) , {schema:"namei_ext.eval_osdi.macrobench.v1", event:"eval-osdi-macrobench-summary", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, phase1_result_dir:$$phase1_result_dir, baseline_ledger_json:$$baseline_ledger_json, result_level:"c2_release_contract", required_paper_samples:$$required_samples, required_baselines:$$required_baselines, namei_ext_raw_gate_pass:$$namei_raw_gate_pass, namei_ext_setup_rows:$$setup_rows, namei_ext_source_update_rows:$$source_update_rows, namei_ext_policy_update_rows:$$policy_update_rows, namei_ext_setup_samples:$$setup_samples, namei_ext_source_update_samples:$$source_update_samples, namei_ext_policy_update_samples:$$policy_update_samples, namei_ext_release_sample_budget_pass:$$namei_release_sample_budget_pass, baseline_release_gate_pass:$$baseline_release_gate_pass, baseline_unique_sample_budget_pass:$$baseline_unique_sample_budget_pass, baselines_release_passed:$$baseline_release_rows, macrobench_input_gate_pass:$$macrobench_input_gate_pass, release_gate_pass:false, c2_supported:false, missing_evidence:[(if $$namei_raw_gate_pass then empty else "namei_ext setup/update raw rows" end), (if $$namei_release_sample_budget_pass then empty else "namei_ext release setup/update sample budget" end), (if $$baseline_release_gate_pass then empty else "external baseline release gate" end), (if $$baseline_release_rows >= $$required_baselines then empty else "five release external baselines" end), "W1-W4 workload-equivalent setup/storage/update macrobench", "C2 setup/update success thresholds"], verdict:(if $$macrobench_input_gate_pass then "blocked_by_missing_thresholds" else "blocked_by_missing_inputs" end), detail:"C2 remains unsupported until namei_ext setup/update rows are compared against feature-equivalent external baselines under explicit thresholds."}' \
		>"$(EVAL_OSDI_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-macrobench-namei-ext")] | length) == 1 and ([.[] | select(.event == "eval-osdi-macrobench-baseline")] | length) >= 5 and ([.[] | select(.event == "eval-osdi-macrobench-summary")] | length) == 1' "$(EVAL_OSDI_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg macrobench_json "$(EVAL_OSDI_MACROBENCH_JSON)" \
		--arg macrobench_inputs_sha256 "$(EVAL_OSDI_MACROBENCH_INPUTS_SHA256)" \
		--arg macrobench_summary "$(EVAL_OSDI_MACROBENCH_SUMMARY)" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_MACROBENCH_JSON)")" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.macrobench_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, generated_at:$$generated_at, artifacts:{macrobench_json:$$macrobench_json, macrobench_inputs_sha256:$$macrobench_inputs_sha256, macrobench_summary:$$macrobench_summary}, gate:{release_gate_pass:$$release_gate_pass, c2_supported:$$c2_supported}}' \
		>"$(EVAL_OSDI_MACROBENCH_MANIFEST)"
	printf '%s\n' '# OSDI B3-B6 C2 Macrobench Ledger' >"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '%s\n' '- External baseline run: $(EVAL_OSDI_MACROBENCH_BASELINE_RUN_ID)' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_MACROBENCH_JSON)' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-macrobench-summary") | "- namei_ext_raw_gate_pass=" + (.namei_ext_raw_gate_pass|tostring) + "\n- namei_ext_release_sample_budget_pass=" + (.namei_ext_release_sample_budget_pass|tostring) + "\n- baseline_release_gate_pass=" + (.baseline_release_gate_pass|tostring) + "\n- macrobench_input_gate_pass=" + (.macrobench_input_gate_pass|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- verdict=" + .verdict + "\n- missing_evidence=" + (.missing_evidence|join(", "))' "$(EVAL_OSDI_MACROBENCH_JSON)" >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '## Baseline Rows' >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-macrobench-baseline") | "- " + .baseline + ": release=" + (.qualified_for_baseline_release|tostring) + ", setup_ns=" + (.setup_ns|tostring) + ", update_ns=" + (.update_ns|tostring) + ", setup/namei=" + (.setup_ns_over_namei|tostring) + ", update/namei_source=" + (.update_ns_over_namei_source|tostring) + ", files=" + (.created_files|tostring) + ", symlinks=" + (.created_symlinks|tostring) + ", bind_mounts=" + (.bind_mounts|tostring) + ", overlay_mounts=" + (.overlay_mounts|tostring) + ", fuse_mounts=" + (.fuse_mounts|tostring)' "$(EVAL_OSDI_MACROBENCH_JSON)" >>"$(EVAL_OSDI_MACROBENCH_SUMMARY)"

eval-osdi-macrobench: eval-osdi-macrobench-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_MACROBENCH_JSON)" >/dev/null

eval-osdi-workload-macrobench-ledger:
	command -v jq >/dev/null
	command -v git >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/metadata.json"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w1-build-replay.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-real.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-policy-compile.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-parent-compile.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-table-compile.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-nginx-fixture/fixture-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-postgres-secret-fixture/fixture-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-redis-podman-criu/checkpoint-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-nginx-podman-criu/checkpoint-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-ccache-redis-nginx/cache-manifest.json"
	test -s "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-buildkit-prometheus-go-cache/cache-manifest.json"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-15-c2-workload-macrobench-design.md"
	sha256sum \
		"$(EVAL_OSDI_PHASE1_DIR)/metadata.json" \
		"$(EVAL_OSDI_PHASE1_DIR)/w1-build-replay.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-real.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-policy-compile.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-parent-compile.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-table-compile.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-nginx-fixture/fixture-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-postgres-secret-fixture/fixture-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-redis-podman-criu/checkpoint-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-nginx-podman-criu/checkpoint-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-ccache-redis-nginx/cache-manifest.json" \
		"$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-buildkit-prometheus-go-cache/cache-manifest.json" \
		"$(ROOT_DIR)/docs/tmp/2026-06-15-c2-workload-macrobench-design.md" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -cn \
		--slurpfile w1_redis "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-redis-build/manifest.json" \
		--slurpfile w1_nginx "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w1-nginx-build/manifest.json" \
		--slurpfile w2_nginx "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-nginx-fixture/fixture-manifest.json" \
		--slurpfile w2_postgres "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w2-postgres-secret-fixture/fixture-manifest.json" \
		--slurpfile w3_redis "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-redis-podman-criu/checkpoint-manifest.json" \
		--slurpfile w3_nginx "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w3-nginx-podman-criu/checkpoint-manifest.json" \
		--slurpfile w4_ccache "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-ccache-redis-nginx/cache-manifest.json" \
		--slurpfile w4_buildkit "$(EVAL_OSDI_WORKLOAD_RUN_DIR)/w4-buildkit-prometheus-go-cache/cache-manifest.json" \
		--slurpfile w1_build "$(EVAL_OSDI_PHASE1_DIR)/w1-build-replay.jsonl" \
		--slurpfile w1_release "$(EVAL_OSDI_PHASE1_DIR)/w1-release-build-replay.jsonl" \
		--slurpfile w2_real "$(EVAL_OSDI_PHASE1_DIR)/w2-nginx-real.jsonl" \
		--slurpfile w3_replay "$(EVAL_OSDI_PHASE1_DIR)/w3-redis-replay.jsonl" \
		--slurpfile w4_real "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-real.jsonl" \
		--slurpfile w4_policy "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-policy-compile.jsonl" \
		--slurpfile w4_parent "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-parent-compile.jsonl" \
		--slurpfile w4_table "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-table-compile.jsonl" \
		--slurpfile w4_counter "$(EVAL_OSDI_PHASE1_DIR)/w4-ccache-release-counterfactual.jsonl" \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg inputs_sha256 "$(EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		'def first_event($$rows; $$name): ($$rows | map(select(.event == $$name)) | first // {}); def row($$workload_id; $$family; $$source_kind; $$correct; $$policy_kvm; $$kvm; $$setup; $$storage; $$update; $$baseline; $$threshold; $$reason): {schema:"namei_ext.eval_osdi.workload_macrobench.v1", event:"eval-osdi-workload-macrobench", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"c2_workload_derived_contract", run_environment:"mixed_host_kvm_derived", workload_id:$$workload_id, policy_family:$$family, source_kind:$$source_kind, correctness_oracle_pass:$$correct, policy_executed_in_kvm:$$policy_kvm, kvm_validated:$$kvm, setup_proxy_available:$$setup, storage_proxy_available:$$storage, update_proxy_available:$$update, release_sample_budget_pass:false, feature_equivalent_baseline_pass:$$baseline, threshold_pass:$$threshold, c2_eligible:false, blocking_reason:$$reason}; first_event($$w1_build; "w1-build-replay-summary") as $$w1_build_summary | first_event($$w1_release; "w1-release-build-replay-summary") as $$w1_release_summary | first_event($$w2_real; "w2-nginx-real-summary") as $$w2_summary | first_event($$w3_replay; "w3-redis-replay-summary") as $$w3_summary | first_event($$w4_real; "w4-ccache-real-summary") as $$w4_real_summary | first_event($$w4_policy; "w4-ccache-policy-compile-summary") as $$w4_policy_summary | first_event($$w4_parent; "w4-ccache-parent-compile-summary") as $$w4_parent_summary | first_event($$w4_table; "w4-ccache-table-compile-summary") as $$w4_table_summary | first_event($$w4_counter; "w4-ccache-release-counterfactual-summary") as $$w4_counter_summary | [ row("w1-redis-build"; "build_graph_view.bpf.c"; "real_source_build_trace"; (($$w1_build_summary.pass // false) and ($$w1_release_summary.pass // false)); true; true; true; true; false; false; false; "derived from host build trace plus KVM replay; missing KVM per-sample build-graph setup/update macrobench") + {build_duration_ns:($$w1_redis[0].build.duration_ns // 0), trace_duration_ns:($$w1_redis[0].trace.duration_ns // 0), file_op_lines:($$w1_redis[0].trace.file_op_lines // 0), binary_sha256:($$w1_redis[0].build.artifacts.binary_sha256 // ""), kvm_build_replay_pass:($$w1_build_summary.pass // false), kvm_release_replay_pass:($$w1_release_summary.pass // false)} , row("w1-nginx-build"; "build_graph_view.bpf.c"; "real_source_build_trace"; (($$w1_build_summary.pass // false) and ($$w1_release_summary.pass // false)); true; true; true; true; false; false; false; "derived from host configure/build trace plus KVM replay; missing KVM per-sample build-graph setup/update macrobench") + {build_duration_ns:($$w1_nginx[0].build.duration_ns // 0), trace_duration_ns:($$w1_nginx[0].trace.duration_ns // 0), file_op_lines:($$w1_nginx[0].trace.file_op_lines // 0), binary_sha256:($$w1_nginx[0].build.artifacts.binary_sha256 // ""), kvm_build_replay_pass:($$w1_build_summary.pass // false), kvm_release_replay_pass:($$w1_release_summary.pass // false)} , row("w2-nginx-fixture"; "sandbox_fixture_view.bpf.c"; "real_nginx_fixture"; ($$w2_summary.pass // false); true; true; true; true; false; false; false; "nginx KVM health oracle exists; missing per-sample config/secret rotation and feature-equivalent baseline comparison") + {fixture_entries:(($$w2_nginx[0].candidate_entries // []) | length), app:"nginx", app_health_pass:($$w2_summary.pass // false)} , row("w2-postgres-secret-fixture"; "sandbox_fixture_view.bpf.c"; "postgres_secret_fixture_planned"; false; false; false; true; true; false; false; false; "PostgreSQL real app oracle is not implemented") + {fixture_entries:(($$w2_postgres[0].candidate_entries // []) | length), app:"postgres"} , row("w3-redis-podman-criu"; "checkpoint_restore_view.bpf.c"; "redis_checkpoint_replay"; ($$w3_summary.pass // false); true; true; true; true; false; false; false; "Redis replay KVM oracle exists, but real Podman/CRIU restore and epoch/update macrobench are missing") + {checkpoint_entries:(($$w3_redis[0].candidate_entries // []) | length), real_restore:($$w3_summary.podman_criu_restore_executed // false), redis_checkpoint_loaded_via_policy:($$w3_summary.redis_checkpoint_loaded_via_policy // false)} , row("w3-nginx-podman-criu"; "checkpoint_restore_view.bpf.c"; "nginx_checkpoint_restore_planned"; false; false; false; true; true; false; false; false; "nginx real Podman/CRIU restore oracle is not implemented") + {checkpoint_entries:(($$w3_nginx[0].candidate_entries // []) | length), real_restore:false} , row("w4-ccache-redis-nginx"; "cache_locality_view.bpf.c"; "real_ccache_compile"; (($$w4_real_summary.pass // false) and ($$w4_policy_summary.pass // false) and ($$w4_parent_summary.pass // false)); true; true; true; true; false; false; false; "real ccache KVM witnesses exist, but operation-weighted release hit rate and stale/update macrobench are missing") + {cache_entries:(($$w4_ccache[0].candidate_entries // []) | length), real_ccache_run:($$w4_real_summary.real_ccache_run // false), attached_cache_path_file_ops:($$w4_policy_summary.attached_cache_path_file_ops // 0), attached_sampled_operation_hit_rate:($$w4_policy_summary.attached_sampled_operation_hit_rate // 0), table_baseline_current_oracle_pass:($$w4_table_summary.table_baseline_current_oracle_pass // false), release_counterfactual_pass:($$w4_counter_summary.pass // false)} , row("w4-buildkit-prometheus-go-cache"; "cache_locality_view.bpf.c"; "buildkit_prometheus_go_cache_planned"; false; false; false; true; true; false; false; false; "BuildKit/Prometheus real cache run is not implemented") + {cache_entries:(($$w4_buildkit[0].candidate_entries // []) | length), real_buildkit_run:false} ] as $$rows | $$rows[], {schema:"namei_ext.eval_osdi.workload_macrobench.v1", event:"eval-osdi-workload-macrobench-summary", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"c2_workload_derived_contract", run_environment:"mixed_host_kvm_derived", workload_rows:($$rows | length), correctness_oracle_passed:([$$rows[] | select(.correctness_oracle_pass == true)] | length), policy_kvm_rows:([$$rows[] | select(.policy_executed_in_kvm == true and .kvm_validated == true)] | length), c2_eligible_rows:([$$rows[] | select(.c2_eligible == true)] | length), release_gate_pass:false, c2_supported:false, missing_evidence:["KVM per-sample workload setup/update macrobench", "feature-equivalent workload baselines", "C2 setup/storage/update success thresholds"], verdict:"derived_contract_only", inputs_sha256_file:$$inputs_sha256, detail:"Derived workload inventory only; it records current W1-W4 evidence and blockers but cannot support C2."}' \
		>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-workload-macrobench")] | length) == 8 and ([.[] | select(.event == "eval-osdi-workload-macrobench-summary")] | length) == 1' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg workload_macrobench_json "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)" \
		--arg workload_macrobench_inputs_sha256 "$(EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--arg workload_macrobench_summary "$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-workload-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)")" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-workload-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.workload_macrobench_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, generated_at:$$generated_at, artifacts:{workload_macrobench_json:$$workload_macrobench_json, workload_macrobench_inputs_sha256:$$workload_macrobench_inputs_sha256, workload_macrobench_summary:$$workload_macrobench_summary}, gate:{release_gate_pass:$$release_gate_pass, c2_supported:$$c2_supported}}' \
		>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_MANIFEST)"
	printf '%s\n' '# OSDI B3-B6 C2 Workload Macrobench Derived Ledger' >"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)' >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_WORKLOAD_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-workload-macrobench-summary") | "- workload_rows=" + (.workload_rows|tostring) + "\n- correctness_oracle_passed=" + (.correctness_oracle_passed|tostring) + "\n- policy_kvm_rows=" + (.policy_kvm_rows|tostring) + "\n- c2_eligible_rows=" + (.c2_eligible_rows|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- verdict=" + .verdict + "\n- missing_evidence=" + (.missing_evidence|join(", "))' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '## Workload Rows' >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-workload-macrobench") | "- " + .workload_id + ": correctness=" + (.correctness_oracle_pass|tostring) + ", policy_kvm=" + (.policy_executed_in_kvm|tostring) + ", setup_proxy=" + (.setup_proxy_available|tostring) + ", update_proxy=" + (.update_proxy_available|tostring) + ", c2_eligible=" + (.c2_eligible|tostring) + ", blocker=" + .blocking_reason' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_WORKLOAD_MACROBENCH_SUMMARY)"

eval-osdi-workload-macrobench: eval-osdi-workload-macrobench-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-workload-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_WORKLOAD_MACROBENCH_JSON)" >/dev/null

eval-osdi-c4-lookup-readdir-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_C4_DIR)"
	test -n "$(EVAL_OSDI_C4_PHASE1_RUN_ID)"
	test -s "$(EVAL_OSDI_C4_W1_JSON)"
	test -s "$(EVAL_OSDI_C4_W1_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_C4_W2_JSON)"
	test -s "$(EVAL_OSDI_C4_W2_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_C4_W3_JSON)"
	test -s "$(EVAL_OSDI_C4_W3_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_C4_W4_JSON)"
	test -s "$(EVAL_OSDI_C4_W4_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_C4_FILTER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-c4-lookup-readdir-matrix-ledger.md"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum -c "$(EVAL_OSDI_C4_W1_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_C4_W2_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_C4_W3_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_C4_W4_INPUTS_SHA256)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_C4_W1_JSON)" \
		"$(EVAL_OSDI_C4_W1_INPUTS_SHA256)" \
		"$(EVAL_OSDI_C4_W2_JSON)" \
		"$(EVAL_OSDI_C4_W2_INPUTS_SHA256)" \
		"$(EVAL_OSDI_C4_W3_JSON)" \
		"$(EVAL_OSDI_C4_W3_INPUTS_SHA256)" \
		"$(EVAL_OSDI_C4_W4_JSON)" \
		"$(EVAL_OSDI_C4_W4_INPUTS_SHA256)" \
		"$(EVAL_OSDI_C4_FILTER)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-c4-lookup-readdir-matrix-ledger.md" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_C4_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_C4_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile w1 "$(EVAL_OSDI_C4_W1_JSON)" \
		--slurpfile w2 "$(EVAL_OSDI_C4_W2_JSON)" \
		--slurpfile w3 "$(EVAL_OSDI_C4_W3_JSON)" \
		--slurpfile w4 "$(EVAL_OSDI_C4_W4_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_C4_PHASE1_RUN_ID)" \
		--arg inputs_sha256 "$(EVAL_OSDI_C4_INPUTS_SHA256)" \
		--arg w1_json "$(EVAL_OSDI_C4_W1_JSON)" \
		--arg w2_json "$(EVAL_OSDI_C4_W2_JSON)" \
		--arg w3_json "$(EVAL_OSDI_C4_W3_JSON)" \
		--arg w4_json "$(EVAL_OSDI_C4_W4_JSON)" \
		-f "$(EVAL_OSDI_C4_FILTER)" \
		>"$(EVAL_OSDI_C4_JSON).tmp"
	mv "$(EVAL_OSDI_C4_JSON).tmp" "$(EVAL_OSDI_C4_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix")] | length) == 4 and ([.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary" and .c4_supported == true and .release_gate_pass == true and .families == 4 and .passing_families == 4 and .lookup_rows == .entries and .readdir_rows == .entries)] | length) == 1' "$(EVAL_OSDI_C4_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_C4_PHASE1_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_C4_JSON)" \
		--arg inputs "$(EVAL_OSDI_C4_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_C4_SUMMARY)" \
		--argjson c4_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary") | .c4_supported' "$(EVAL_OSDI_C4_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary") | .release_gate_pass' "$(EVAL_OSDI_C4_JSON)")" \
		'{schema:"namei_ext.eval_osdi.c4_lookup_readdir_matrix_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c4_supported:$$c4_supported, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_C4_MANIFEST)"
	printf '%s\n' '# C4 Lookup/Readdir Matrix Ledger' >"$(EVAL_OSDI_C4_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_C4_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_C4_JSON)' >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_C4_INPUTS_SHA256)' >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '%s\n' '- Manifest: $(EVAL_OSDI_C4_MANIFEST)' >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '\n%s\n' '## Summary' >>"$(EVAL_OSDI_C4_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary") | "- families=" + (.families|tostring) + "\n- passing_families=" + (.passing_families|tostring) + "\n- entries=" + (.entries|tostring) + "\n- lookup_rows=" + (.lookup_rows|tostring) + "\n- readdir_rows=" + (.readdir_rows|tostring) + "\n- c4_supported=" + (.c4_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- scope=" + .scope + "\n- scope_boundaries=" + (.scope_boundaries|join("; "))' "$(EVAL_OSDI_C4_JSON)" >>"$(EVAL_OSDI_C4_SUMMARY)"
	printf '\n%s\n' '## Families' >>"$(EVAL_OSDI_C4_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix") | "- " + .family + ": entries=" + (.entries|tostring) + ", lookup_rows=" + (.lookup_rows|tostring) + ", readdir_rows=" + (.readdir_rows|tostring) + ", failed_rows=" + (.failed_rows|tostring) + ", pass=" + (.lookup_readdir_matrix_pass|tostring) + ", workloads=" + (.workloads|join(","))' "$(EVAL_OSDI_C4_JSON)" >>"$(EVAL_OSDI_C4_SUMMARY)"

eval-osdi-c4-lookup-readdir: eval-osdi-c4-lookup-readdir-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary" and .release_gate_pass == true and .c4_supported == true)' "$(EVAL_OSDI_C4_JSON)" >/dev/null

eval-osdi-claim-verdict-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_CLAIM_VERDICT_DIR)"
	test -n "$(EVAL_OSDI_CLAIM_W1_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_W2_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_W3_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_W4_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_PERFORMANCE_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_C4_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_W4_TRANSITION_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_RUN_ID)"
	test -n "$(EVAL_OSDI_CLAIM_C7_AUDIT_RUN_ID)"
	test -s "$(EVAL_OSDI_CLAIM_W1_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W1_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_W2_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W2_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_W3_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W3_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_W4_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W4_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_PERFORMANCE_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_PERFORMANCE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_C4_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_C4_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_W4_TRANSITION_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W4_TRANSITION_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_C7_AUDIT_JSON)"
	test -s "$(EVAL_OSDI_CLAIM_C7_AUDIT_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_CLAIM_VERDICT_FILTER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-claim-verdict-ledger-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-tool-redirect-performance-scope-ledger.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w1-fuse-baseline-test-integration.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-c4-lookup-readdir-matrix-ledger.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w4-cache-content-hardgate-provenance.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	jq -e -s '([.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary" and .schema == "namei_ext.eval_osdi.w1_build_workload_macrobench.v1")] | length) == 1' "$(EVAL_OSDI_CLAIM_W1_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary" and .schema == "namei_ext.eval_osdi.w2_nginx_workload_macrobench.v1")] | length) == 1' "$(EVAL_OSDI_CLAIM_W2_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary" and .schema == "namei_ext.eval_osdi.w3_redis_workload_macrobench.v1")] | length) == 1' "$(EVAL_OSDI_CLAIM_W3_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary" and .schema == "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1")] | length) == 1' "$(EVAL_OSDI_CLAIM_W4_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-comparison-summary" and .schema == "namei_ext.eval_osdi.performance_comparison.v1")] | length) == 1' "$(EVAL_OSDI_CLAIM_PERFORMANCE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-tool-redirect-scope-summary" and .schema == "namei_ext.eval_osdi.performance_scope.v1" and .scoped_c3_supported == true and .release_gate_pass == false)] | length) == 1' "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-w2-tool-redirect-paper-release-summary" and .schema == "namei_ext.eval_osdi.w2_tool_redirect_paper_release.v1" and .paper_release_gate_pass == true and .scope == "w2_nginx_fixture_plus_tool_redirect_metadata")] | length) == 1' "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c4-lookup-readdir-matrix-summary" and .schema == "namei_ext.eval_osdi.c4_lookup_readdir_matrix.v1" and .c4_supported == true and .release_gate_pass == true)] | length) == 1' "$(EVAL_OSDI_CLAIM_C4_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "w4-cache-transition-summary" and .schema == "namei_ext.eval_osdi.w4_cache_transition.v1" and (.qualified_for_c8 | type) == "boolean")] | length) == 1' "$(EVAL_OSDI_CLAIM_W4_TRANSITION_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "w4-cache-table-content-summary" and .result_level == "kvm_cache_table_content_oracle" and (.qualified_for_c8 | type) == "boolean")] | length) == 1' "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c7-artifact-reproducibility-audit-summary" and .schema == "namei_ext.eval_osdi.c7_artifact_reproducibility_audit.v1" and .artifact_package_gate_pass == true and .artifact_package_replay_pass == true and .anonymization_checklist_gate_pass == true and .c7_supported == false and .release_gate_pass == false and (.missing_evidence | length) == 1 and (.missing_evidence | index("clean checkout reproduction")))] | length) == 1' "$(EVAL_OSDI_CLAIM_C7_AUDIT_JSON)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W1_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W2_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W3_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W4_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_PERFORMANCE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_C4_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W4_TRANSITION_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_CLAIM_C7_AUDIT_INPUTS_SHA256)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_CLAIM_W1_JSON)" \
		"$(EVAL_OSDI_CLAIM_W1_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_W2_JSON)" \
		"$(EVAL_OSDI_CLAIM_W2_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_W3_JSON)" \
		"$(EVAL_OSDI_CLAIM_W3_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_W4_JSON)" \
		"$(EVAL_OSDI_CLAIM_W4_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_PERFORMANCE_JSON)" \
		"$(EVAL_OSDI_CLAIM_PERFORMANCE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON)" \
		"$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON)" \
		"$(EVAL_OSDI_CLAIM_PAPER_RELEASE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_C4_JSON)" \
		"$(EVAL_OSDI_CLAIM_C4_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_W4_TRANSITION_JSON)" \
		"$(EVAL_OSDI_CLAIM_W4_TRANSITION_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON)" \
		"$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_C7_AUDIT_JSON)" \
		"$(EVAL_OSDI_CLAIM_C7_AUDIT_INPUTS_SHA256)" \
		"$(EVAL_OSDI_CLAIM_VERDICT_FILTER)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-claim-verdict-ledger-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-tool-redirect-performance-scope-ledger.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-w1-fuse-baseline-test-integration.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-c4-lookup-readdir-matrix-ledger.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-w4-cache-content-hardgate-provenance.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-w4-cache-transition-counterfactual.md" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile w1 "$(EVAL_OSDI_CLAIM_W1_JSON)" \
		--slurpfile w2 "$(EVAL_OSDI_CLAIM_W2_JSON)" \
		--slurpfile w3 "$(EVAL_OSDI_CLAIM_W3_JSON)" \
		--slurpfile w4 "$(EVAL_OSDI_CLAIM_W4_JSON)" \
		--slurpfile perf "$(EVAL_OSDI_CLAIM_PERFORMANCE_JSON)" \
		--slurpfile perf_scope "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON)" \
		--slurpfile paper_release "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON)" \
		--slurpfile c4 "$(EVAL_OSDI_CLAIM_C4_JSON)" \
		--slurpfile w4_transition "$(EVAL_OSDI_CLAIM_W4_TRANSITION_JSON)" \
		--slurpfile w4_cache_table "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON)" \
		--slurpfile c7_audit "$(EVAL_OSDI_CLAIM_C7_AUDIT_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg inputs_sha256 "$(EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256)" \
		--arg w1_json "$(EVAL_OSDI_CLAIM_W1_JSON)" \
		--arg w2_json "$(EVAL_OSDI_CLAIM_W2_JSON)" \
		--arg w3_json "$(EVAL_OSDI_CLAIM_W3_JSON)" \
		--arg w4_json "$(EVAL_OSDI_CLAIM_W4_JSON)" \
		--arg performance_json "$(EVAL_OSDI_CLAIM_PERFORMANCE_JSON)" \
		--arg performance_scope_json "$(EVAL_OSDI_CLAIM_PERFORMANCE_SCOPE_JSON)" \
		--arg paper_release_json "$(EVAL_OSDI_CLAIM_PAPER_RELEASE_JSON)" \
		--arg c4_json "$(EVAL_OSDI_CLAIM_C4_JSON)" \
		--arg w4_transition_json "$(EVAL_OSDI_CLAIM_W4_TRANSITION_JSON)" \
		--arg w4_cache_table_json "$(EVAL_OSDI_CLAIM_W4_CACHE_TABLE_JSON)" \
		--arg c7_audit_json "$(EVAL_OSDI_CLAIM_C7_AUDIT_JSON)" \
		-f "$(EVAL_OSDI_CLAIM_VERDICT_FILTER)" \
		>"$(EVAL_OSDI_CLAIM_VERDICT_JSON).tmp"
	mv "$(EVAL_OSDI_CLAIM_VERDICT_JSON).tmp" "$(EVAL_OSDI_CLAIM_VERDICT_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-claim-verdict-summary")] | length) == 1 and ([.[] | select(.event == "eval-osdi-claim-verdict-summary" and .weak_accept_ready == true and .paper_release_gate_pass == true and .release_gate_pass == false and .active_main_claims == 4 and .scoped_out_claims == 4 and .supported_claims == 4 and .partial_claims == 0 and .unsupported_claims == 0 and (.highest_risk_claims | index("C7")) and (.scoped_out_rationale | index("C7 lacks clean-checkout reproduction")))] | length) == 1 and ([.[] | select((.claim_id == "C2" or .claim_id == "C3") and .slice_gate_pass == true and .paper_release_gate_pass == true and .release_gate_pass == false)] | length) == 2 and ([.[] | select(.claim_id == "C4" and .slice_gate_pass == true and .verdict == "supported")] | length) == 1 and ([.[] | select(.claim_id == "C7" and .active_main_claim == false and .verdict == "scoped_out" and (.evidence | index("C7 artifact audit package, anonymization, and package-root paper replay gates passed")) and (.missing_evidence | length) == 1 and (.missing_evidence | index("clean checkout reproduction")))] | length) == 1 and ([.[] | select((.claim_id == "C5" or .claim_id == "C6" or .claim_id == "C7" or .claim_id == "C8") and .active_main_claim == false and .verdict == "scoped_out")] | length) == 4' "$(EVAL_OSDI_CLAIM_VERDICT_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_CLAIM_VERDICT_JSON)" \
		--arg inputs "$(EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)" \
		--argjson weak_accept_ready "$$(jq -s -r '.[] | select(.event == "eval-osdi-claim-verdict-summary") | .weak_accept_ready' "$(EVAL_OSDI_CLAIM_VERDICT_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-claim-verdict-summary") | .release_gate_pass' "$(EVAL_OSDI_CLAIM_VERDICT_JSON)")" \
		'{schema:"namei_ext.eval_osdi.claim_verdict_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{weak_accept_ready:$$weak_accept_ready, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_CLAIM_VERDICT_MANIFEST)"
	printf '%s\n' '# OSDI Claim Verdict Ledger' >"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_CLAIM_VERDICT_JSON)' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_CLAIM_VERDICT_INPUTS_SHA256)' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '%s\n' '- Manifest: $(EVAL_OSDI_CLAIM_VERDICT_MANIFEST)' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '\n%s\n' '## Summary' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-claim-verdict-summary") | "- weak_accept_ready=" + (.weak_accept_ready|tostring) + "\n- paper_release_gate_pass=" + (.paper_release_gate_pass|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- claims=" + (.claims|tostring) + "\n- active_main_claims=" + (.active_main_claims|tostring) + "\n- scoped_out_claims=" + (.scoped_out_claims|tostring) + "\n- supported_claims=" + (.supported_claims|tostring) + "\n- partial_claims=" + (.partial_claims|tostring) + "\n- unsupported_claims=" + (.unsupported_claims|tostring) + "\n- highest_risk_claims=" + (.highest_risk_claims|join(", ")) + "\n- scoped_out_rationale=" + (.scoped_out_rationale|join("; ")) + "\n- required_next_actions=" + (.required_next_actions|join("; "))' "$(EVAL_OSDI_CLAIM_VERDICT_JSON)" >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	printf '\n%s\n' '## Per-Claim Verdicts' >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"
	jq -s -r '.[] | select(.claim_id != null) | "- " + .claim_id + ": verdict=" + .verdict + ", slice_gate_pass=" + (.slice_gate_pass|tostring) + ", paper_release_gate_pass=" + (.paper_release_gate_pass|tostring) + ", release_gate_pass=" + (.release_gate_pass|tostring) + ", wording=" + .supported_wording + ", scope=" + ((.scope_boundaries // [])|join("; ")) + ", missing=" + (.missing_evidence|join("; "))' "$(EVAL_OSDI_CLAIM_VERDICT_JSON)" >>"$(EVAL_OSDI_CLAIM_VERDICT_SUMMARY)"

eval-osdi-w1-build-workload-macrobench-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -n "$(EVAL_OSDI_W1_BUILD_POLICY_RUN_ID)"
	test -n "$(EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID)"
	test -n "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID)"
	test -s "$(EVAL_OSDI_W1_BUILD_POLICY_JSON)"
	test -s "$(EVAL_OSDI_W1_BUILD_POLICY_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W1_BUILD_BASELINE_JSON)"
	test -s "$(EVAL_OSDI_W1_BUILD_BASELINE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_JSON)"
	test -s "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_INPUTS_SHA256)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-workload-ledger-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w1-fuse-baseline-test-integration.md"
	test -s "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_FILTER)"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum -c "$(EVAL_OSDI_W1_BUILD_POLICY_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_W1_BUILD_BASELINE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_INPUTS_SHA256)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_W1_BUILD_POLICY_JSON)" \
		"$(EVAL_OSDI_W1_BUILD_POLICY_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W1_BUILD_BASELINE_JSON)" \
		"$(EVAL_OSDI_W1_BUILD_BASELINE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W1_BUILD_FUSE_TEST_JSON)" \
		"$(EVAL_OSDI_W1_BUILD_FUSE_TEST_INPUTS_SHA256)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-feature-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w1-build-workload-ledger-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-w1-fuse-baseline-test-integration.md" \
		"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_FILTER)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -n \
		--slurpfile policy "$(EVAL_OSDI_W1_BUILD_POLICY_JSON)" \
		--slurpfile baseline "$(EVAL_OSDI_W1_BUILD_BASELINE_JSON)" \
		--slurpfile fuse_test "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg policy_run_id "$(EVAL_OSDI_W1_BUILD_POLICY_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID)" \
		--arg fuse_test_run_id "$(EVAL_OSDI_W1_BUILD_FUSE_TEST_RUN_ID)" \
		--arg policy_json "$(EVAL_OSDI_W1_BUILD_POLICY_JSON)" \
		--arg baseline_json "$(EVAL_OSDI_W1_BUILD_BASELINE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		-f "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_FILTER)" \
		>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w1-build-workload-macrobench" and .row_kind == "proposed_system")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w1-build-workload-macrobench" and .row_kind == "feature_baseline")] | length) >= 1' "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)" \
		--arg inputs "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.w1_build_workload_macrobench_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c2_supported:$$c2_supported, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_MANIFEST)"
	printf '%s\n' '# W1 build workload macrobench ledger' >"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Policy run: $(EVAL_OSDI_W1_BUILD_POLICY_RUN_ID)' >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Baseline run: $(EVAL_OSDI_W1_BUILD_BASELINE_RUN_ID)' >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)' >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary") | "- policy_release_input_pass=" + (.policy_release_input_pass|tostring) + "\n- baseline_release_input_pass=" + (.baseline_release_input_pass|tostring) + "\n- copy_tree_baseline_pass=" + (.copy_tree_baseline_pass|tostring) + "\n- symlink_forest_baseline_pass=" + (.symlink_forest_baseline_pass|tostring) + "\n- bind_mount_baseline_pass=" + (.bind_mount_baseline_pass|tostring) + "\n- projected_volume_baseline_pass=" + (.projected_volume_baseline_pass|tostring) + "\n- fuse_test_release_input_pass=" + (.fuse_test_release_input_pass|tostring) + "\n- fuse_correctness_test_rows=" + (.fuse_correctness_test_rows|tostring) + "\n- fuse_correctness_test_pass=" + (.fuse_correctness_test_pass|tostring) + "\n- fuse_visible_aliases_avg=" + (.fuse_visible_aliases_avg|tostring) + "\n- fuse_alias_parent_dirs_avg=" + (.fuse_alias_parent_dirs_avg|tostring) + "\n- fuse_correctness_mounts_avg=" + (.fuse_correctness_mounts_avg|tostring) + "\n- fuse_baseline_pass=" + (.fuse_baseline_pass|tostring) + "\n- implemented_feature_baselines_pass=" + (.implemented_feature_baselines_pass|tostring) + "\n- full_feature_equivalent_baseline_pass=" + (.full_feature_equivalent_baseline_pass|tostring) + "\n- storage_footprint_pass=" + (.storage_footprint_pass|tostring) + "\n- setup_latency_threshold_pass=" + (.setup_latency_threshold_pass|tostring) + "\n- update_latency_threshold_pass=" + (.update_latency_threshold_pass|tostring) + "\n- update_materialization_threshold_pass=" + (.update_materialization_threshold_pass|tostring) + "\n- threshold_pass=" + (.threshold_pass|tostring) + "\n- w1_c2_slice_supported=" + (.w1_c2_slice_supported|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- policy_setup_ns_avg=" + (.policy_setup_ns_avg|tostring) + "\n- best_baseline_setup_ns_avg=" + (.best_baseline_setup_ns_avg|tostring) + "\n- policy_update_ns_avg=" + (.policy_update_ns_avg|tostring) + "\n- best_baseline_update_ns_avg=" + (.best_baseline_update_ns_avg|tostring) + "\n- policy_setup_objects_avg=" + (.policy_setup_objects_avg|tostring) + "\n- min_baseline_setup_objects_avg=" + (.min_baseline_setup_objects_avg|tostring) + "\n- policy_setup_bytes_avg=" + (.policy_setup_bytes_avg|tostring) + "\n- min_baseline_setup_bytes_avg=" + (.min_baseline_setup_bytes_avg|tostring) + "\n- missing_inputs=" + (.missing_inputs|join(", ")) + "\n- failed_gates=" + (.failed_gates|join(", "))' "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_SUMMARY)"

eval-osdi-w1-build-workload-macrobench: eval-osdi-w1-build-workload-macrobench-ledger
	@if jq -e -s '.[] | select(.event == "eval-osdi-w1-build-workload-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_W1_BUILD_WORKLOAD_MACROBENCH_JSON)" >/dev/null; then \
		jq -n --arg run_id "$(RUN_ID)" --arg target "$@" --arg status "0" \
			'{schema:"namei_ext.eval_osdi.hardgate_status.v1", run_id:$$run_id, target:$$target, status:($$status|tonumber), pass:true}' \
			>"$(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench-hardgate-status.json"; \
	else \
		status=$$?; \
		jq -n --arg run_id "$(RUN_ID)" --arg target "$@" --arg status "$$status" \
			'{schema:"namei_ext.eval_osdi.hardgate_status.v1", run_id:$$run_id, target:$$target, status:($$status|tonumber), pass:false}' \
			>"$(EVAL_OSDI_MACROBENCH_DIR)/w1-build-workload-macrobench-hardgate-status.json"; \
		exit $$status; \
	fi

eval-osdi-w2-nginx-workload-macrobench-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -n "$(EVAL_OSDI_W2_NGINX_POLICY_RUN_ID)"
	test -n "$(EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID)"
	test -s "$(EVAL_OSDI_W2_NGINX_POLICY_JSON)"
	test -s "$(EVAL_OSDI_W2_NGINX_POLICY_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W2_NGINX_BASELINE_JSON)"
	test -s "$(EVAL_OSDI_W2_NGINX_BASELINE_INPUTS_SHA256)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-feature-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-feature-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-bind-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-fuse-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-workload-ledger-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-storage-threshold-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md"
	test -s "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_FILTER)"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_W2_NGINX_POLICY_JSON)" \
		"$(EVAL_OSDI_W2_NGINX_POLICY_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W2_NGINX_BASELINE_JSON)" \
		"$(EVAL_OSDI_W2_NGINX_BASELINE_INPUTS_SHA256)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-feature-baseline-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-feature-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-bind-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-projected-volume-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-fuse-baseline-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-fuse-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-workload-ledger-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-storage-threshold-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w2-nginx-storage-threshold-implementation.md" \
		"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_FILTER)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -n \
		--slurpfile policy "$(EVAL_OSDI_W2_NGINX_POLICY_JSON)" \
		--slurpfile baseline "$(EVAL_OSDI_W2_NGINX_BASELINE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg policy_run_id "$(EVAL_OSDI_W2_NGINX_POLICY_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID)" \
		--arg policy_json "$(EVAL_OSDI_W2_NGINX_POLICY_JSON)" \
		--arg baseline_json "$(EVAL_OSDI_W2_NGINX_BASELINE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		-f "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_FILTER)" \
		>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench" and .row_kind == "proposed_system")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench" and .row_kind == "feature_baseline")] | length) >= 2' "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)" \
		--arg inputs "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.w2_nginx_workload_macrobench_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c2_supported:$$c2_supported, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_MANIFEST)"
	printf '%s\n' '# W2 nginx workload macrobench ledger' >"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Policy run: $(EVAL_OSDI_W2_NGINX_POLICY_RUN_ID)' >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Baseline run: $(EVAL_OSDI_W2_NGINX_BASELINE_RUN_ID)' >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)' >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary") | "- policy_release_input_pass=" + (.policy_release_input_pass|tostring) + "\n- baseline_release_input_pass=" + (.baseline_release_input_pass|tostring) + "\n- copy_symlink_baselines_pass=" + (.copy_symlink_baselines_pass|tostring) + "\n- bind_baseline_pass=" + (.bind_baseline_pass|tostring) + "\n- projected_volume_baseline_pass=" + (.projected_volume_baseline_pass|tostring) + "\n- fuse_baseline_pass=" + (.fuse_baseline_pass|tostring) + "\n- all_feature_baselines_pass=" + (.all_feature_baselines_pass|tostring) + "\n- full_feature_equivalent_baseline_pass=" + (.full_feature_equivalent_baseline_pass|tostring) + "\n- storage_footprint_pass=" + (.storage_footprint_pass|tostring) + "\n- setup_latency_threshold_pass=" + (.setup_latency_threshold_pass|tostring) + "\n- update_latency_threshold_pass=" + (.update_latency_threshold_pass|tostring) + "\n- update_materialization_threshold_pass=" + (.update_materialization_threshold_pass|tostring) + "\n- threshold_pass=" + (.threshold_pass|tostring) + "\n- w2_c2_slice_supported=" + (.w2_c2_slice_supported|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- policy_setup_ns_avg=" + (.policy_setup_ns_avg|tostring) + "\n- best_baseline_setup_ns_avg=" + (.best_baseline_setup_ns_avg|tostring) + "\n- policy_update_ns_avg=" + (.policy_update_ns_avg|tostring) + "\n- best_baseline_update_ns_avg=" + (.best_baseline_update_ns_avg|tostring) + "\n- policy_setup_objects_avg=" + (.policy_setup_objects_avg|tostring) + "\n- min_baseline_setup_objects_avg=" + (.min_baseline_setup_objects_avg|tostring) + "\n- policy_setup_bytes_avg=" + (.policy_setup_bytes_avg|tostring) + "\n- min_baseline_setup_bytes_avg=" + (.min_baseline_setup_bytes_avg|tostring) + "\n- missing_evidence=" + (.missing_evidence|join(", "))' "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_SUMMARY)"

eval-osdi-w2-nginx-workload-macrobench: eval-osdi-w2-nginx-workload-macrobench-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_W2_NGINX_WORKLOAD_MACROBENCH_JSON)" >/dev/null

eval-osdi-w3-redis-workload-macrobench-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -n "$(EVAL_OSDI_W3_REDIS_POLICY_RUN_ID)"
	test -n "$(EVAL_OSDI_W3_REDIS_BASELINE_RUN_ID)"
	test -s "$(EVAL_OSDI_W3_REDIS_POLICY_JSON)"
	test -s "$(EVAL_OSDI_W3_REDIS_POLICY_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W3_REDIS_BASELINE_JSON)"
	test -s "$(EVAL_OSDI_W3_REDIS_BASELINE_INPUTS_SHA256)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md"
	test -s "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_FILTER)"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_W3_REDIS_POLICY_JSON)" \
		"$(EVAL_OSDI_W3_REDIS_POLICY_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W3_REDIS_BASELINE_JSON)" \
		"$(EVAL_OSDI_W3_REDIS_BASELINE_INPUTS_SHA256)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w3-redis-policy-fuse-macrobench-implementation.md" \
		"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_FILTER)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -n \
		--slurpfile policy "$(EVAL_OSDI_W3_REDIS_POLICY_JSON)" \
		--slurpfile baseline "$(EVAL_OSDI_W3_REDIS_BASELINE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg policy_run_id "$(EVAL_OSDI_W3_REDIS_POLICY_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_W3_REDIS_BASELINE_RUN_ID)" \
		--arg policy_json "$(EVAL_OSDI_W3_REDIS_POLICY_JSON)" \
		--arg baseline_json "$(EVAL_OSDI_W3_REDIS_BASELINE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		-f "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_FILTER)" \
		>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench" and .row_kind == "proposed_system")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench" and .row_kind == "external_baseline")] | length) == 2 and ([.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench" and .row_kind == "external_baseline" and .baseline == "fuse_redirect" and .fuse_mounts_avg == 1)] | length) == 1' "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)" \
		--arg inputs "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.w3_redis_workload_macrobench_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c2_supported:$$c2_supported, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_MANIFEST)"
	printf '%s\n' '# W3 Redis workload macrobench ledger' >"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Policy run: $(EVAL_OSDI_W3_REDIS_POLICY_RUN_ID)' >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Baseline run: $(EVAL_OSDI_W3_REDIS_BASELINE_RUN_ID)' >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)' >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary") | "- policy_release_input_pass=" + (.policy_release_input_pass|tostring) + "\n- baseline_release_input_pass=" + (.baseline_release_input_pass|tostring) + "\n- materialized_baseline_pass=" + (.materialized_baseline_pass|tostring) + "\n- fuse_baseline_pass=" + (.fuse_baseline_pass|tostring) + "\n- implemented_external_baselines_pass=" + (.implemented_external_baselines_pass|tostring) + "\n- storage_footprint_pass=" + (.storage_footprint_pass|tostring) + "\n- setup_latency_threshold_pass=" + (.setup_latency_threshold_pass|tostring) + "\n- update_latency_threshold_pass=" + (.update_latency_threshold_pass|tostring) + "\n- update_materialization_threshold_pass=" + (.update_materialization_threshold_pass|tostring) + "\n- threshold_pass=" + (.threshold_pass|tostring) + "\n- w3_c2_slice_supported=" + (.w3_c2_slice_supported|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- policy_setup_ns_avg=" + (.policy_setup_ns_avg|tostring) + "\n- best_baseline_setup_ns_avg=" + (.best_baseline_setup_ns_avg|tostring) + "\n- policy_update_ns_avg=" + (.policy_update_ns_avg|tostring) + "\n- best_baseline_update_ns_avg=" + (.best_baseline_update_ns_avg|tostring) + "\n- policy_setup_objects_avg=" + (.policy_setup_objects_avg|tostring) + "\n- min_baseline_setup_objects_avg=" + (.min_baseline_setup_objects_avg|tostring) + "\n- policy_setup_bytes_avg=" + (.policy_setup_bytes_avg|tostring) + "\n- min_baseline_setup_bytes_avg=" + (.min_baseline_setup_bytes_avg|tostring) + "\n- policy_update_writes_avg=" + (.policy_update_writes_avg|tostring) + "\n- min_baseline_update_writes_avg=" + (.min_baseline_update_writes_avg|tostring) + "\n- missing_evidence=" + (.missing_evidence|join(", ")) + "\n- failed_gates=" + (.failed_gates|join(", "))' "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_SUMMARY)"

eval-osdi-w3-redis-workload-macrobench: eval-osdi-w3-redis-workload-macrobench-ledger
	jq -e -s '.[] | select(.event == "eval-osdi-w3-redis-workload-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_W3_REDIS_WORKLOAD_MACROBENCH_JSON)" >/dev/null

eval-osdi-w4-ccache-workload-macrobench-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_MACROBENCH_DIR)"
	test -n "$(EVAL_OSDI_W4_CCACHE_RULE_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID)"
	test -n "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID)"
	test -s "$(EVAL_OSDI_W4_CCACHE_RULE_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_RULE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_JSON)"
	test -s "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_INPUTS_SHA256)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-design.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-macrobench-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-cache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-native-ccache-baseline-implementation.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-workload-ledger-integration.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-fuse-compile-ledger-integration.md"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-native-compile-ledger-integration.md"
	test -s "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_FILTER)"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_W4_CCACHE_RULE_JSON)" \
		"$(EVAL_OSDI_W4_CCACHE_RULE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_JSON)" \
		"$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_JSON)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_JSON)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_JSON)" \
			"$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_INPUTS_SHA256)" \
			"$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_JSON)" \
			"$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_INPUTS_SHA256)" \
			"$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_JSON)" \
			"$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_INPUTS_SHA256)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-ccache-rule-macrobench-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-design.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-materialized-cache-baseline-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-macrobench-implementation.md" \
		"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-materialized-cache-baseline-implementation.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-cache-baseline-implementation.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-native-ccache-baseline-implementation.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-workload-ledger-integration.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-fuse-compile-ledger-integration.md" \
			"$(ROOT_DIR)/docs/tmp/2026-06-16-w4-native-compile-ledger-integration.md" \
		"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_FILTER)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256)" >/dev/null
	jq -n \
		--slurpfile w4 "$(EVAL_OSDI_W4_CCACHE_RULE_JSON)" \
		--slurpfile w4_materialized "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_JSON)" \
		--slurpfile w4_bulk_policy "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_JSON)" \
		--slurpfile w4_bulk_policy_macro "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)" \
			--slurpfile w4_bulk_materialized "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_JSON)" \
			--slurpfile w4_bulk_fuse "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_JSON)" \
			--slurpfile w4_bulk_fuse_compile "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_JSON)" \
			--slurpfile w4_bulk_native "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg w4_rule_run_id "$(EVAL_OSDI_W4_CCACHE_RULE_RUN_ID)" \
		--arg w4_materialized_run_id "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID)" \
		--arg w4_bulk_policy_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID)" \
		--arg w4_bulk_policy_macrobench_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID)" \
		--arg w4_bulk_materialized_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID)" \
			--arg w4_bulk_fuse_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID)" \
			--arg w4_bulk_fuse_compile_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID)" \
			--arg w4_bulk_native_run_id "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID)" \
		--arg w4_json "$(EVAL_OSDI_W4_CCACHE_RULE_JSON)" \
		--arg w4_materialized_json "$(EVAL_OSDI_W4_CCACHE_MATERIALIZED_JSON)" \
		--arg w4_bulk_policy_json "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_JSON)" \
		--arg w4_bulk_policy_macro_json "$(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_JSON)" \
		--arg w4_bulk_materialized_json "$(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_JSON)" \
			--arg w4_bulk_fuse_json "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_JSON)" \
			--arg w4_bulk_fuse_compile_json "$(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_JSON)" \
			--arg w4_bulk_native_json "$(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--argjson required_samples "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
		-f "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_FILTER)" \
		>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON).tmp"
	mv "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON).tmp" "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "proposed_system")] | length) == 2 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "feature_baseline")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "external_baseline" and .baseline == "materialized_cache_view")] | length) == 2 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "external_baseline" and .baseline == "fuse_redirect")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "external_baseline" and .baseline == "fuse_redirect_compile")] | length) == 1 and ([.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench" and .row_kind == "external_baseline" and .baseline == "native_ccache_hot_compile")] | length) == 1' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" \
		--arg inputs "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary") | .c2_supported' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)")" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary") | .release_gate_pass' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)")" \
		'{schema:"namei_ext.eval_osdi.w4_ccache_workload_macrobench_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c2_supported:$$c2_supported, release_gate_pass:$$release_gate_pass}}' \
		>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_MANIFEST)"
	printf '%s\n' '# W4 ccache workload macrobench ledger' >"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Rule macrobench run: $(EVAL_OSDI_W4_CCACHE_RULE_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Materialized external baseline run: $(EVAL_OSDI_W4_CCACHE_MATERIALIZED_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk policy compile run: $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk policy macrobench run: $(EVAL_OSDI_W4_CCACHE_BULK_POLICY_MACROBENCH_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk materialized external baseline run: $(EVAL_OSDI_W4_CCACHE_BULK_MATERIALIZED_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk FUSE cache-view baseline run: $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk FUSE compile baseline run: $(EVAL_OSDI_W4_CCACHE_BULK_FUSE_COMPILE_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Bulk native ccache compile baseline run: $(EVAL_OSDI_W4_CCACHE_BULK_NATIVE_RUN_ID)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_INPUTS_SHA256)' >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
		jq -s -r '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary") | "- policy_release_input_pass=" + (.policy_release_input_pass|tostring) + "\n- baseline_release_input_pass=" + (.baseline_release_input_pass|tostring) + "\n- table_release_input_pass=" + (.table_release_input_pass|tostring) + "\n- table_baseline_pass=" + (.table_baseline_pass|tostring) + "\n- materialized_baseline_pass=" + (.materialized_baseline_pass|tostring) + "\n- full_feature_equivalent_baseline_pass=" + (.full_feature_equivalent_baseline_pass|tostring) + "\n- bulk_policy_compile_smoke_pass=" + (.bulk_policy_compile_smoke_pass|tostring) + "\n- bulk_policy_release_input_pass=" + (.bulk_policy_release_input_pass|tostring) + "\n- bulk_materialized_baseline_pass=" + (.bulk_materialized_baseline_pass|tostring) + "\n- bulk_fuse_baseline_pass=" + (.bulk_fuse_baseline_pass|tostring) + "\n- bulk_fuse_compile_baseline_pass=" + (.bulk_fuse_compile_baseline_pass|tostring) + "\n- bulk_external_baseline_release_input_pass=" + (.bulk_external_baseline_release_input_pass|tostring) + "\n- bulk_release_comparison_pass=" + (.bulk_release_comparison_pass|tostring) + "\n- storage_footprint_pass=" + (.storage_footprint_pass|tostring) + "\n- setup_latency_threshold_pass=" + (.setup_latency_threshold_pass|tostring) + "\n- update_latency_threshold_pass=" + (.update_latency_threshold_pass|tostring) + "\n- rule_materialization_threshold_pass=" + (.rule_materialization_threshold_pass|tostring) + "\n- threshold_pass=" + (.threshold_pass|tostring) + "\n- w4_c2_slice_supported=" + (.w4_c2_slice_supported|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- policy_setup_ns_avg=" + (.policy_setup_ns_avg|tostring) + "\n- materialized_setup_ns_avg=" + (.materialized_setup_ns_avg|tostring) + "\n- table_setup_ns_avg=" + (.table_setup_ns_avg|tostring) + "\n- policy_update_ns_avg=" + (.policy_update_ns_avg|tostring) + "\n- materialized_update_ns_avg=" + (.materialized_update_ns_avg|tostring) + "\n- table_update_ns_avg=" + (.table_update_ns_avg|tostring) + "\n- bulk_policy_attached_compile_jobs=" + (.bulk_policy_attached_compile_jobs|tostring) + "\n- bulk_policy_redirected_cache_objects=" + (.bulk_policy_redirected_cache_objects|tostring) + "\n- bulk_policy_attached_cache_path_file_ops=" + (.bulk_policy_attached_cache_path_file_ops|tostring) + "\n- bulk_policy_attached_policy_cache_object_ops=" + (.bulk_policy_attached_policy_cache_object_ops|tostring) + "\n- bulk_policy_attached_sampled_operation_hit_rate=" + (.bulk_policy_attached_sampled_operation_hit_rate|tostring) + "\n- bulk_materialized_setup_ns_avg=" + (.bulk_materialized_setup_ns_avg|tostring) + "\n- bulk_materialized_update_ns_avg=" + (.bulk_materialized_update_ns_avg|tostring) + "\n- bulk_fuse_setup_ns_avg=" + (.bulk_fuse_setup_ns_avg|tostring) + "\n- bulk_fuse_update_ns_avg=" + (.bulk_fuse_update_ns_avg|tostring) + "\n- bulk_fuse_mounts_avg=" + (.bulk_fuse_mounts_avg|tostring) + "\n- bulk_fuse_compile_ns_avg=" + (.bulk_fuse_compile_ns_avg|tostring) + "\n- bulk_fuse_compile_direct_cache_hit=" + (.bulk_fuse_compile_direct_cache_hit|tostring) + "\n- bulk_fuse_compile_cache_object_ops=" + (.bulk_fuse_compile_cache_object_ops|tostring) + "\n- bulk_best_external_setup_ns_avg=" + (.bulk_best_external_setup_ns_avg|tostring) + "\n- bulk_best_external_update_ns_avg=" + (.bulk_best_external_update_ns_avg|tostring) + "\n- policy_setup_rule_writes_avg=" + (.policy_setup_rule_writes_avg|tostring) + "\n- baseline_setup_rule_writes_avg=" + (.baseline_setup_rule_writes_avg|tostring) + "\n- policy_update_rule_writes_avg=" + (.policy_update_rule_writes_avg|tostring) + "\n- baseline_update_rule_writes_avg=" + (.baseline_update_rule_writes_avg|tostring) + "\n- missing_inputs=" + (.missing_inputs|join(", ")) + "\n- failed_gates=" + (.failed_gates|join(", "))' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary") | "- bulk_policy_compile_release_input_pass=" + (.bulk_policy_compile_release_input_pass|tostring)' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary") | "- bulk_native_compile_baseline_pass=" + (.bulk_native_compile_baseline_pass|tostring) + "\n- bulk_native_compile_ns_avg=" + (.bulk_native_compile_ns_avg|tostring) + "\n- bulk_native_compile_direct_cache_hit=" + (.bulk_native_compile_direct_cache_hit|tostring) + "\n- bulk_native_compile_cache_path_file_ops=" + (.bulk_native_compile_cache_path_file_ops|tostring) + "\n- bulk_native_compile_cache_object_ops=" + (.bulk_native_compile_cache_object_ops|tostring) + "\n- bulk_native_compile_sampled_operation_hit_rate=" + (.bulk_native_compile_sampled_operation_hit_rate|tostring)' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" >>"$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_SUMMARY)"

eval-osdi-w4-ccache-workload-macrobench: eval-osdi-w4-ccache-workload-macrobench-ledger
	@if jq -e -s '.[] | select(.event == "eval-osdi-w4-ccache-workload-macrobench-summary" and .release_gate_pass == true and .c2_supported == true)' "$(EVAL_OSDI_W4_CCACHE_WORKLOAD_MACROBENCH_JSON)" >/dev/null; then \
		jq -n --arg run_id "$(RUN_ID)" --arg target "$@" --arg status "0" \
			'{schema:"namei_ext.eval_osdi.hardgate_status.v1", run_id:$$run_id, target:$$target, status:($$status|tonumber), pass:true}' \
			>"$(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench-hardgate-status.json"; \
	else \
		status=$$?; \
		jq -n --arg run_id "$(RUN_ID)" --arg target "$@" --arg status "$$status" \
			'{schema:"namei_ext.eval_osdi.hardgate_status.v1", run_id:$$run_id, target:$$target, status:($$status|tonumber), pass:false}' \
			>"$(EVAL_OSDI_MACROBENCH_DIR)/w4-ccache-workload-macrobench-hardgate-status.json"; \
		exit $$status; \
	fi

eval-osdi-performance-tail:
	command -v jq >/dev/null
	command -v awk >/dev/null
	command -v git >/dev/null
	command -v sort >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_PERFORMANCE_DIR)"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	sha256sum \
		"$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" >/dev/null
	expected_groups=$$(jq -s '[.[] | select(.event == "bench") | [.bench,.variant] | @tsv] | unique | length' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	expected_rows=$$(jq -s '([.[] | select(.event == "bench")] | length) as $$bench_rows | ([.[] | select(.event == "bench-start")][0].latency_samples // 0) as $$latency_samples | ($$bench_rows * $$latency_samples)' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	jq -r 'select(.event == "bench_latency") | [.bench,.variant,.sample,.latency_sample,.ops,.elapsed_ns,(if .ops == 0 then 0 else (.elapsed_ns / .ops) end),.fail] | @tsv' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		| sort -t "$$(printf '\t')" -k1,1 -k2,2 -k7,7n \
		| awk -F '\t' \
			-v run_id="$(RUN_ID)" \
			-v phase1_run_id="$(EVAL_OSDI_PHASE1_RUN_ID)" \
			-v phase1_result_dir="$(EVAL_OSDI_PHASE1_DIR)" \
			-v expected_groups="$$expected_groups" \
				-v expected_rows="$$expected_rows" \
				-v required_samples="$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
				-v required_latency_batch="$(EVAL_OSDI_REQUIRED_LATENCY_BATCH)" \
				-v ci_z="$(EVAL_OSDI_TAIL_CI_Z)" \
				-v inputs_sha256_file="$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" \
			'function js(s) { gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s } \
			function pidx(count,p,idx) { idx = int((count * p) + 0.999999); if (idx < 1) idx = 1; if (idx > count) idx = count; return idx } \
			function flush(    i,sample_count,latency_sample_count,mean,var,sd,ci,low,high,p50,p95,p99,minv,maxv,complete) { \
				if (n == 0) return; \
				groups++; \
				if (min_group_rows == 0 || n < min_group_rows) min_group_rows = n; \
				if (n > max_group_rows) max_group_rows = n; \
					for (i in sample_seen) sample_count++; \
					for (i in latency_seen) latency_sample_count++; \
					if (min_group_samples == 0 || sample_count < min_group_samples) min_group_samples = sample_count; \
					if (sample_count > max_group_samples) max_group_samples = sample_count; \
					mean = sum / n; \
				var = 0; \
				if (n > 1) { var = (sumsq - ((sum * sum) / n)) / (n - 1); if (var < 0) var = 0; } \
				sd = sqrt(var); \
				ci = (n > 0 ? ci_z * sd / sqrt(n) : 0); \
				low = mean - ci; if (low < 0) low = 0; high = mean + ci; \
				p50 = values[pidx(n, 0.50)]; p95 = values[pidx(n, 0.95)]; p99 = values[pidx(n, 0.99)]; \
				minv = values[1]; maxv = values[n]; complete = (group_fail == 0 ? "true" : "false"); \
				printf("{\"schema\":\"namei_ext.eval_osdi.bench_latency_tail.v1\",\"event\":\"bench-latency-tail\",\"run_id\":\"%s\",\"phase1_run_id\":\"%s\",\"phase1_result_dir\":\"%s\",\"bench\":\"%s\",\"variant\":\"%s\",\"rows\":%d,\"samples_observed\":%d,\"latency_samples_observed\":%d,\"mean_ns_per_op\":%.6f,\"stdev_ns_per_op\":%.6f,\"ci95_low_ns_per_op\":%.6f,\"ci95_high_ns_per_op\":%.6f,\"p50_ns_per_op\":%.6f,\"p95_ns_per_op\":%.6f,\"p99_ns_per_op\":%.6f,\"min_ns_per_op\":%.6f,\"max_ns_per_op\":%.6f,\"failures\":%d,\"complete\":%s}\n", run_id, phase1_run_id, phase1_result_dir, js(bench), js(variant), n, sample_count, latency_sample_count, mean, sd, low, high, p50, p95, p99, minv, maxv, group_fail, complete); \
				delete values; delete sample_seen; delete latency_seen; n = 0; sum = 0; sumsq = 0; group_fail = 0; \
			} \
			{ \
				key = $$1 "\t" $$2; \
				if (current_key != "" && key != current_key) { flush(); current_key = key; bench = $$1; variant = $$2; } \
				if (current_key == "") { current_key = key; bench = $$1; variant = $$2; } \
					ops = $$5 + 0; if (min_ops_per_row == 0 || ops < min_ops_per_row) min_ops_per_row = ops; if (ops > max_ops_per_row) max_ops_per_row = ops; \
					value = $$7 + 0; values[++n] = value; sum += value; sumsq += value * value; \
					sample_seen[$$3] = 1; latency_seen[$$4] = 1; total_rows++; total_fail += $$8; group_fail += $$8; \
				} \
				END { \
					flush(); \
					has_artifact = (total_rows > 0 && total_fail == 0 && groups == expected_groups && total_rows == expected_rows ? "true" : "false"); \
					has_ci = (has_artifact == "true" && min_group_rows >= 2 ? "true" : "false"); \
					has_release_sample_budget = (has_artifact == "true" && min_group_samples >= required_samples ? "true" : "false"); \
					has_release_latency_batch_budget = (has_artifact == "true" && min_ops_per_row >= required_latency_batch ? "true" : "false"); \
					printf("{\"schema\":\"namei_ext.eval_osdi.bench_latency_tail.v1\",\"event\":\"bench-latency-tail-summary\",\"run_id\":\"%s\",\"phase1_run_id\":\"%s\",\"phase1_result_dir\":\"%s\",\"rows\":%d,\"expected_rows\":%d,\"groups\":%d,\"expected_groups\":%d,\"min_group_rows\":%d,\"max_group_rows\":%d,\"min_group_samples\":%d,\"max_group_samples\":%d,\"min_ops_per_latency_row\":%d,\"max_ops_per_latency_row\":%d,\"failures\":%d,\"required_paper_samples\":%d,\"required_latency_batch\":%d,\"has_tail_latency_artifact\":%s,\"has_confidence_interval\":%s,\"has_release_sample_budget\":%s,\"has_release_latency_batch_budget\":%s,\"inputs_sha256_file\":\"%s\",\"detail\":\"Percentile and CI artifact computed from raw KVM bench_latency rows; release claims still require release repetitions, sufficient latency batch size, randomized order, system metrics, and external baselines.\"}\n", run_id, phase1_run_id, phase1_result_dir, total_rows, expected_rows, groups, expected_groups, min_group_rows, max_group_rows, min_group_samples, max_group_samples, min_ops_per_row, max_ops_per_row, total_fail, required_samples, required_latency_batch, has_artifact, has_ci, has_release_sample_budget, has_release_latency_batch_budget, inputs_sha256_file); \
				}' \
		>"$(EVAL_OSDI_PERFORMANCE_TAIL_JSON).tmp"
	mv "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON).tmp" "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"
	jq -e -s '([.[] | select(.event == "bench-latency-tail-summary")] | length) == 1' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" >/dev/null
	latency_samples_declared=$$(jq -s '[.[] | select(.event == "bench-start")][0].latency_samples // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	if test "$$latency_samples_declared" -gt "0"; then \
		jq -e -s '.[] | select(.event == "bench-latency-tail-summary" and .has_tail_latency_artifact == true and .failures == 0 and .rows == .expected_rows and .groups == .expected_groups)' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" >/dev/null; \
	fi
	main_dirty=$$(test -n "$$(git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results')" && printf true || printf false); \
	kernel_dirty=$$(test -n "$$(git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal)" && printf true || printf false); \
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg bench_json "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		--arg tail_latency_json "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		--arg tail_latency_inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" \
		--arg tail_latency_summary "$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)" \
		--arg main_head "$$(git -C "$(ROOT_DIR)" rev-parse HEAD)" \
		--arg kernel_head "$$(git -C "$(KERNEL_DIR)" rev-parse HEAD)" \
		--argjson main_dirty "$$main_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
			--argjson rows "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].rows' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			--argjson groups "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].groups' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			--argjson has_tail_latency_artifact "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_tail_latency_artifact' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			--argjson has_confidence_interval "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_confidence_interval' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			--argjson has_release_sample_budget "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_release_sample_budget' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			--argjson has_release_latency_batch_budget "$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_release_latency_batch_budget' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)")" \
			'{schema:"namei_ext.eval_osdi.bench_latency_tail_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, generated_at:$$generated_at, phase1_result_dir:$$phase1_result_dir, main_repo:{head:$$main_head, dirty:$$main_dirty}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty}, artifacts:{bench_json:$$bench_json, tail_latency_json:$$tail_latency_json, tail_latency_inputs_sha256:$$tail_latency_inputs_sha256, tail_latency_summary:$$tail_latency_summary}, summary:{rows:$$rows, groups:$$groups, has_tail_latency_artifact:$$has_tail_latency_artifact, has_confidence_interval:$$has_confidence_interval, has_release_sample_budget:$$has_release_sample_budget, has_release_latency_batch_budget:$$has_release_latency_batch_budget}}' \
		>"$(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)"
	printf '%s\n' '# Bench Latency Tail Artifact' >"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_PERFORMANCE_TAIL_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)' >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	printf '%s\n' '- Manifest: $(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)' >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
		jq -s -r '.[] | select(.event == "bench-latency-tail-summary") | "- rows=" + (.rows|tostring) + ", expected=" + (.expected_rows|tostring) + ", groups=" + (.groups|tostring) + ", expected_groups=" + (.expected_groups|tostring) + ", min_group_rows=" + (.min_group_rows|tostring) + ", min_group_samples=" + (.min_group_samples|tostring) + ", min_ops_per_latency_row=" + (.min_ops_per_latency_row|tostring) + ", required_latency_batch=" + (.required_latency_batch|tostring) + ", has_tail_latency_artifact=" + (.has_tail_latency_artifact|tostring) + ", has_confidence_interval=" + (.has_confidence_interval|tostring) + ", has_release_sample_budget=" + (.has_release_sample_budget|tostring) + ", has_release_latency_batch_budget=" + (.has_release_latency_batch_budget|tostring)' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"

eval-osdi-performance-ledger: eval-osdi-performance-tail
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(EVAL_OSDI_PERFORMANCE_DIR)"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/dmesg-bench.log"
	test -s "$(EVAL_OSDI_PHASE1_DIR)/metadata.json"
	test -s "$(ROOT_DIR)/configs/benchmarks/phase1.mk"
	test -s "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk"
	test -s "$(ROOT_DIR)/bench/workloads/namei_ext_bench.c"
	test -s "$(ROOT_DIR)/mk/kvm.mk"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	test -s "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"
	test -s "$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)"
	test -s "$(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)"
	if test -n "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)"; then test -s "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"; fi
	if test -n "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)"; then test -s "$(EVAL_OSDI_PERFORMANCE_BASELINE_INPUTS_SHA256)"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-proc-stat-before.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-proc-stat-after.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-meminfo-before.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-meminfo-after.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-vmstat-before.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-vmstat-after.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-diskstats-before.txt"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then test -s "$(EVAL_OSDI_PHASE1_DIR)/bench-diskstats-after.txt"; fi
	sha256sum \
		"$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl" \
		"$(EVAL_OSDI_PHASE1_DIR)/dmesg-bench.log" \
		"$(EVAL_OSDI_PHASE1_DIR)/metadata.json" \
		"$(ROOT_DIR)/configs/benchmarks/phase1.mk" \
		"$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" \
		"$(ROOT_DIR)/bench/workloads/namei_ext_bench.c" \
		"$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		"$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		"$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" \
		"$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)" \
		"$(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)" \
		>"$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)"
	if test -n "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)"; then sha256sum "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)" "$(EVAL_OSDI_PERFORMANCE_BASELINE_INPUTS_SHA256)" >>"$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)"; fi
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then sha256sum "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)" "$(EVAL_OSDI_PHASE1_DIR)/bench-proc-stat-before.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-proc-stat-after.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-meminfo-before.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-meminfo-after.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-vmstat-before.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-vmstat-after.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-diskstats-before.txt" "$(EVAL_OSDI_PHASE1_DIR)/bench-diskstats-after.txt" >>"$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)"; fi
	sha256sum -c "$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)" >/dev/null
	samples=$$(jq -s '[.[] | select(.event == "bench-start")][0].samples // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	iterations=$$(jq -s '[.[] | select(.event == "bench-start")][0].iterations // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	latency_samples=$$(jq -s '[.[] | select(.event == "bench-start")][0].latency_samples // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	latency_batch=$$(jq -s '[.[] | select(.event == "bench-start")][0].latency_batch // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	bench_rows=$$(jq -s '[.[] | select(.event == "bench")] | length' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	bench_latency_rows=$$(jq -s '[.[] | select(.event == "bench_latency")] | length' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	bench_names=$$(jq -s -r '[.[] | select(.event == "bench") | .bench] | unique | join(",")' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	variants=$$(jq -s -r '[.[] | select(.event == "bench") | .variant] | unique | join(",")' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	failing_ops=$$(jq -s '[.[] | select(.event == "bench") | .fail] | add // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	latency_failing_ops=$$(jq -s '[.[] | select(.event == "bench_latency") | .fail] | add // 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_native=$$(jq -s '[.[] | select(.event == "bench" and .variant == "baseline")] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_policy=$$(jq -s '[.[] | select(.event == "bench" and (.variant == "policy" or .variant == "redirect_alias"))] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_pass_only=$$(jq -s '[.[] | select(.event == "bench" and .variant == "pass_only")] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_table_redirect_empty=$$(jq -s '[.[] | select(.event == "bench" and .variant == "table_redirect_empty")] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_table_redirect_hit=$$(jq -s '[.[] | select(.event == "bench" and (.variant == "table_redirect" or .variant == "table_redirect_hit"))] | length > 0' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	if test -n "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)"; then \
		has_copy_tree_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_copy_tree_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_symlink_forest_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_symlink_forest_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_bind_mount_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_bind_mount_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_overlayfs_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_overlayfs_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_fuse_redirect_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_fuse_redirect_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_copy_tree_release_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_copy_tree_release_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_symlink_forest_release_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_symlink_forest_release_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_bind_mount_release_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_bind_mount_release_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_overlayfs_release_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_overlayfs_release_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		has_fuse_redirect_release_baseline=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].has_fuse_redirect_release_baseline // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
		baseline_release_gate_pass=$$(jq -s '[.[] | select(.event == "eval-osdi-baseline-summary")][0].baseline_release_gate_pass // false' "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"); \
	else \
		has_copy_tree_baseline=false; \
		has_symlink_forest_baseline=false; \
		has_bind_mount_baseline=false; \
		has_overlayfs_baseline=false; \
		has_fuse_redirect_baseline=false; \
		has_copy_tree_release_baseline=false; \
		has_symlink_forest_release_baseline=false; \
		has_bind_mount_release_baseline=false; \
		has_overlayfs_release_baseline=false; \
		has_fuse_redirect_release_baseline=false; \
		baseline_release_gate_pass=false; \
	fi; \
	has_latency_raw_rows=$$(jq -n --argjson rows "$$bench_latency_rows" --argjson fail "$$latency_failing_ops" '$$rows > 0 and $$fail == 0'); \
	tail_latency_groups=$$(jq -s '[.[] | select(.event == "bench-latency-tail")] | length' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		tail_latency_min_group_rows=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].min_group_rows // 0' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		tail_latency_min_group_samples=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].min_group_samples // 0' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		tail_latency_min_ops_per_row=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].min_ops_per_latency_row // 0' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		has_tail_latency_artifact=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_tail_latency_artifact // false' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		has_confidence_interval=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_confidence_interval // false' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		has_release_tail_sample_budget=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_release_sample_budget // false' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
		has_release_latency_batch_budget=$$(jq -s '[.[] | select(.event == "bench-latency-tail-summary")][0].has_release_latency_batch_budget // false' "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"); \
	has_repetition_budget=$$(jq -n --argjson samples "$$samples" --argjson required "$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" '$$samples >= $$required'); \
	run_order_rows=$$(jq -s '[.[] | select(.event == "bench_order")] | length' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	variant_order_rows=$$(jq -s '[.[] | select(.event == "bench_variant_order")] | length' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	has_randomized_order=$$(jq -s '([.[] | select(.event == "bench_order_start" and .randomized_order == true)] | length == 1) and ([.[] | select(.event == "bench_order" and .randomized_order == true)] | length > 0) and ([.[] | select(.event == "bench_variant_order" and .randomized_order == true)] | length > 0)' "$(EVAL_OSDI_PHASE1_DIR)/bench.jsonl"); \
	if test -s "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"; then \
		system_metric_rows=$$(jq -s '[.[] | select(.event == "bench-system-metrics")] | length' "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"); \
		has_system_metrics=$$(jq -s '([.[] | select(.event == "bench-system-metrics" and .phase == "before")] | length == 1) and ([.[] | select(.event == "bench-system-metrics" and .phase == "after")] | length == 1)' "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)"); \
	else \
		system_metric_rows=0; \
		has_system_metrics=false; \
	fi; \
	missing_baselines=$$(jq -cn --argjson has_pass_only "$$has_pass_only" --argjson has_table_redirect_hit "$$has_table_redirect_hit" --argjson has_copy_tree_release_baseline "$$has_copy_tree_release_baseline" --argjson has_symlink_forest_release_baseline "$$has_symlink_forest_release_baseline" --argjson has_bind_mount_release_baseline "$$has_bind_mount_release_baseline" --argjson has_overlayfs_release_baseline "$$has_overlayfs_release_baseline" --argjson has_fuse_redirect_release_baseline "$$has_fuse_redirect_release_baseline" '[(if $$has_pass_only then empty else "pass_only" end), (if $$has_table_redirect_hit then empty else "table_redirect_hit" end), (if $$has_fuse_redirect_release_baseline then empty else "fuse_redirect" end), (if $$has_copy_tree_release_baseline then empty else "copy_tree" end), (if $$has_symlink_forest_release_baseline then empty else "symlink_forest" end), (if $$has_bind_mount_release_baseline then empty else "bind_mount" end), (if $$has_overlayfs_release_baseline then empty else "overlayfs" end)]'); \
	: >"$(EVAL_OSDI_PERFORMANCE_JSON).tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg bench_names "$$bench_names" \
		--arg variants "$$variants" \
		--argjson samples "$$samples" \
		--argjson iterations "$$iterations" \
		--argjson latency_samples "$$latency_samples" \
		--argjson latency_batch "$$latency_batch" \
		--argjson bench_rows "$$bench_rows" \
		--argjson bench_latency_rows "$$bench_latency_rows" \
		--argjson failing_ops "$$failing_ops" \
		--argjson latency_failing_ops "$$latency_failing_ops" \
		--argjson has_native_baseline "$$has_native" \
		--argjson has_namei_policy "$$has_policy" \
		--argjson has_pass_only "$$has_pass_only" \
		--argjson has_table_redirect_empty "$$has_table_redirect_empty" \
		--argjson has_table_redirect_hit "$$has_table_redirect_hit" \
		--arg baseline_run_id "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)" \
		--arg baseline_ledger_json "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)" \
		--argjson has_copy_tree_baseline "$$has_copy_tree_baseline" \
		--argjson has_symlink_forest_baseline "$$has_symlink_forest_baseline" \
		--argjson has_bind_mount_baseline "$$has_bind_mount_baseline" \
		--argjson has_overlayfs_baseline "$$has_overlayfs_baseline" \
		--argjson has_fuse_redirect_baseline "$$has_fuse_redirect_baseline" \
		--argjson has_copy_tree_release_baseline "$$has_copy_tree_release_baseline" \
		--argjson has_symlink_forest_release_baseline "$$has_symlink_forest_release_baseline" \
		--argjson has_bind_mount_release_baseline "$$has_bind_mount_release_baseline" \
		--argjson has_overlayfs_release_baseline "$$has_overlayfs_release_baseline" \
		--argjson has_fuse_redirect_release_baseline "$$has_fuse_redirect_release_baseline" \
		--argjson baseline_release_gate_pass "$$baseline_release_gate_pass" \
		--argjson has_latency_raw_rows "$$has_latency_raw_rows" \
		--arg tail_latency_json "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		--arg tail_latency_inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" \
			--argjson tail_latency_groups "$$tail_latency_groups" \
			--argjson tail_latency_min_group_rows "$$tail_latency_min_group_rows" \
			--argjson tail_latency_min_group_samples "$$tail_latency_min_group_samples" \
			--argjson tail_latency_min_ops_per_row "$$tail_latency_min_ops_per_row" \
			--argjson has_tail_latency_artifact "$$has_tail_latency_artifact" \
			--argjson has_confidence_interval "$$has_confidence_interval" \
			--argjson has_release_tail_sample_budget "$$has_release_tail_sample_budget" \
			--argjson has_release_latency_batch_budget "$$has_release_latency_batch_budget" \
		--argjson has_repetition_budget "$$has_repetition_budget" \
		--argjson run_order_rows "$$run_order_rows" \
		--argjson variant_order_rows "$$variant_order_rows" \
		--argjson has_randomized_order "$$has_randomized_order" \
		--arg system_metrics_json "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)" \
		--argjson system_metric_rows "$$system_metric_rows" \
		--argjson has_system_metrics "$$has_system_metrics" \
		--argjson missing_baselines "$$missing_baselines" \
			'{schema:"namei_ext.eval_osdi.performance.v1", event:"eval-osdi-performance", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"release_input_evidence_no_claim_verdict", run_environment:"kvm", samples:$$samples, required_paper_samples:$(EVAL_OSDI_REQUIRED_PERF_SAMPLES), required_latency_batch:$(EVAL_OSDI_REQUIRED_LATENCY_BATCH), iterations:$$iterations, latency_samples:$$latency_samples, latency_batch:$$latency_batch, bench_rows:$$bench_rows, bench_latency_rows:$$bench_latency_rows, bench_names:($$bench_names | split(",") | map(select(length > 0))), variants_observed:($$variants | split(",") | map(select(length > 0))), has_native_baseline:$$has_native_baseline, has_namei_policy_variant:$$has_namei_policy, has_pass_only_baseline:$$has_pass_only, has_table_redirect_empty_baseline:$$has_table_redirect_empty, has_table_redirect_hit_baseline:$$has_table_redirect_hit, has_table_redirect_baseline:$$has_table_redirect_hit, baseline_run_id:$$baseline_run_id, baseline_ledger_json:$$baseline_ledger_json, has_copy_tree_baseline:$$has_copy_tree_baseline, has_symlink_forest_baseline:$$has_symlink_forest_baseline, has_bind_mount_baseline:$$has_bind_mount_baseline, has_overlayfs_baseline:$$has_overlayfs_baseline, has_fuse_redirect_baseline:$$has_fuse_redirect_baseline, has_copy_tree_release_baseline:$$has_copy_tree_release_baseline, has_symlink_forest_release_baseline:$$has_symlink_forest_release_baseline, has_bind_mount_release_baseline:$$has_bind_mount_release_baseline, has_overlayfs_release_baseline:$$has_overlayfs_release_baseline, has_fuse_redirect_release_baseline:$$has_fuse_redirect_release_baseline, baseline_release_gate_pass:$$baseline_release_gate_pass, has_latency_raw_rows:$$has_latency_raw_rows, tail_latency_json:$$tail_latency_json, tail_latency_inputs_sha256:$$tail_latency_inputs_sha256, tail_latency_groups:$$tail_latency_groups, tail_latency_min_group_rows:$$tail_latency_min_group_rows, tail_latency_min_group_samples:$$tail_latency_min_group_samples, tail_latency_min_ops_per_latency_row:$$tail_latency_min_ops_per_row, has_tail_latency:$$has_tail_latency_artifact, has_tail_latency_artifact:$$has_tail_latency_artifact, has_repetition_budget:$$has_repetition_budget, has_release_tail_sample_budget:$$has_release_tail_sample_budget, has_release_latency_batch_budget:$$has_release_latency_batch_budget, has_ci_artifact:$$has_confidence_interval, has_confidence_interval:$$has_confidence_interval, run_order_rows:$$run_order_rows, variant_order_rows:$$variant_order_rows, has_randomized_order:$$has_randomized_order, system_metrics_json:$$system_metrics_json, system_metric_rows:$$system_metric_rows, has_system_metrics:$$has_system_metrics, failing_ops:$$failing_ops, latency_failing_ops:$$latency_failing_ops, missing_release_baselines:$$missing_baselines, release_gate_pass:false, qualified_for_c2_c3_c5:false, detail:"This row records release-scale input evidence for B2/B8, not a supported performance claim. External baseline release rows may be linked through EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID, but C2/C3/C5 still require comparison thresholds and claim verdict before paper use."}' \
		>>"$(EVAL_OSDI_PERFORMANCE_JSON).tmp"; \
	jq -cs \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg phase1_result_dir "$(EVAL_OSDI_PHASE1_DIR)" \
		--arg inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)" \
			'{schema:"namei_ext.eval_osdi.performance.v1", event:"eval-osdi-performance-summary", run_id:$$run_id, phase1_run_id:$$phase1_run_id, phase1_result_dir:$$phase1_result_dir, result_level:"release_performance_contract", rows:([.[] | select(.event == "eval-osdi-performance")] | length), has_tail_latency_artifact:([.[] | select(.event == "eval-osdi-performance")][0].has_tail_latency_artifact // false), has_confidence_interval:([.[] | select(.event == "eval-osdi-performance")][0].has_confidence_interval // false), has_release_tail_sample_budget:([.[] | select(.event == "eval-osdi-performance")][0].has_release_tail_sample_budget // false), has_release_latency_batch_budget:([.[] | select(.event == "eval-osdi-performance")][0].has_release_latency_batch_budget // false), has_randomized_order:([.[] | select(.event == "eval-osdi-performance")][0].has_randomized_order // false), has_system_metrics:([.[] | select(.event == "eval-osdi-performance")][0].has_system_metrics // false), baseline_release_gate_pass:([.[] | select(.event == "eval-osdi-performance")][0].baseline_release_gate_pass // false), release_gate_pass:false, c2_supported:false, c3_supported:false, c5_supported:false, inputs_sha256_file:$$inputs_sha256, detail:"Current raw bench evidence is preserved as gate evidence but cannot support OSDI performance claims until the final release gate and claim verdict pass."}' \
		"$(EVAL_OSDI_PERFORMANCE_JSON).tmp" >>"$(EVAL_OSDI_PERFORMANCE_JSON).tmp"; \
	mv "$(EVAL_OSDI_PERFORMANCE_JSON).tmp" "$(EVAL_OSDI_PERFORMANCE_JSON)"
	jq -e -s 'length == 2 and ([.[] | select(.event == "eval-osdi-performance")] | length) == 1 and ([.[] | select(.event == "eval-osdi-performance-summary")] | length) == 1' "$(EVAL_OSDI_PERFORMANCE_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg performance_json "$(EVAL_OSDI_PERFORMANCE_JSON)" \
		--arg performance_inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)" \
		--arg performance_summary "$(EVAL_OSDI_PERFORMANCE_SUMMARY)" \
		--arg tail_latency_json "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		--arg tail_latency_inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)" \
		--arg tail_latency_summary "$(EVAL_OSDI_PERFORMANCE_TAIL_SUMMARY)" \
		--arg tail_latency_manifest "$(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)" \
		--arg system_metrics_json "$(EVAL_OSDI_PERFORMANCE_SYSTEM_METRICS_JSON)" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-summary") | .release_gate_pass' "$(EVAL_OSDI_PERFORMANCE_JSON)")" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-summary") | .c2_supported' "$(EVAL_OSDI_PERFORMANCE_JSON)")" \
		--argjson c3_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-summary") | .c3_supported' "$(EVAL_OSDI_PERFORMANCE_JSON)")" \
		--argjson c5_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-summary") | .c5_supported' "$(EVAL_OSDI_PERFORMANCE_JSON)")" \
		'{schema:"namei_ext.eval_osdi.performance_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, generated_at:$$generated_at, artifacts:{performance_json:$$performance_json, performance_inputs_sha256:$$performance_inputs_sha256, performance_summary:$$performance_summary, tail_latency_json:$$tail_latency_json, tail_latency_inputs_sha256:$$tail_latency_inputs_sha256, tail_latency_summary:$$tail_latency_summary, tail_latency_manifest:$$tail_latency_manifest, system_metrics_json:$$system_metrics_json}, gate:{release_gate_pass:$$release_gate_pass, c2_supported:$$c2_supported, c3_supported:$$c3_supported, c5_supported:$$c5_supported}}' \
		>"$(EVAL_OSDI_PERFORMANCE_MANIFEST)"
	printf '%s\n' '# OSDI B2/B8 Performance Ledger' >"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_PERFORMANCE_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Tail latency JSONL: $(EVAL_OSDI_PERFORMANCE_TAIL_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Tail latency input sha256: $(EVAL_OSDI_PERFORMANCE_TAIL_INPUTS_SHA256)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Tail latency manifest: $(EVAL_OSDI_PERFORMANCE_TAIL_MANIFEST)' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '%s\n' '- Release gate pass: '"$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-summary") | .release_gate_pass' "$(EVAL_OSDI_PERFORMANCE_JSON)")" >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '\n%s\n' '## Current Evidence' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
		jq -s -r '.[] | select(.event == "eval-osdi-performance") | "- samples=" + (.samples|tostring) + ", required=" + (.required_paper_samples|tostring) + ", repetition_budget=" + (.has_repetition_budget|tostring) + ", variants=" + (.variants_observed|join(",")) + ", pass_only=" + (.has_pass_only_baseline|tostring) + ", table_redirect_empty=" + (.has_table_redirect_empty_baseline|tostring) + ", table_redirect_hit=" + (.has_table_redirect_hit_baseline|tostring) + ", copy_tree_smoke=" + (.has_copy_tree_baseline|tostring) + ", symlink_smoke=" + (.has_symlink_forest_baseline|tostring) + ", bind_smoke=" + (.has_bind_mount_baseline|tostring) + ", overlay_smoke=" + (.has_overlayfs_baseline|tostring) + ", fuse_smoke=" + (.has_fuse_redirect_baseline|tostring) + ", copy_tree_release=" + (.has_copy_tree_release_baseline|tostring) + ", symlink_release=" + (.has_symlink_forest_release_baseline|tostring) + ", bind_release=" + (.has_bind_mount_release_baseline|tostring) + ", overlay_release=" + (.has_overlayfs_release_baseline|tostring) + ", fuse_release=" + (.has_fuse_redirect_release_baseline|tostring) + ", baseline_release_gate=" + (.baseline_release_gate_pass|tostring) + ", bench_latency_rows=" + (.bench_latency_rows|tostring) + ", latency_raw_rows=" + (.has_latency_raw_rows|tostring) + ", tail_latency_artifact=" + (.has_tail_latency_artifact|tostring) + ", ci_artifact=" + (.has_confidence_interval|tostring) + ", tail_min_group_rows=" + (.tail_latency_min_group_rows|tostring) + ", tail_min_group_samples=" + (.tail_latency_min_group_samples|tostring) + ", tail_min_ops_per_latency_row=" + (.tail_latency_min_ops_per_latency_row|tostring) + ", required_latency_batch=" + (.required_latency_batch|tostring) + ", release_tail_sample_budget=" + (.has_release_tail_sample_budget|tostring) + ", release_latency_batch_budget=" + (.has_release_latency_batch_budget|tostring) + ", run_order_rows=" + (.run_order_rows|tostring) + ", variant_order_rows=" + (.variant_order_rows|tostring) + ", randomized_order=" + (.has_randomized_order|tostring) + ", system_metric_rows=" + (.system_metric_rows|tostring) + ", system_metrics=" + (.has_system_metrics|tostring) + ", failing_ops=" + (.failing_ops|tostring) + ", latency_failing_ops=" + (.latency_failing_ops|tostring) + ", release_gate=" + (.release_gate_pass|tostring)' "$(EVAL_OSDI_PERFORMANCE_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
	printf '\n%s\n' '## Missing Release Evidence' >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"
		jq -s -r '.[] | select(.event == "eval-osdi-performance") | "- missing baselines: " + (.missing_release_baselines|join(", ")) + "\n- missing tail-latency artifact: " + ((.has_tail_latency_artifact|not)|tostring) + "\n- missing release tail sample budget: " + ((.has_release_tail_sample_budget|not)|tostring) + "\n- missing release latency batch budget: " + ((.has_release_latency_batch_budget|not)|tostring) + "\n- missing CI artifact: " + ((.has_confidence_interval|not)|tostring) + "\n- missing randomized order: " + ((.has_randomized_order|not)|tostring) + "\n- missing system metrics: " + ((.has_system_metrics|not)|tostring)' "$(EVAL_OSDI_PERFORMANCE_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_SUMMARY)"

eval-osdi-performance-comparison: eval-osdi-performance-ledger
	command -v jq >/dev/null
	command -v awk >/dev/null
	command -v sort >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)"
	test -s "$(EVAL_OSDI_PERFORMANCE_JSON)"
	test -s "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)"
	test -s "$(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baselines.jsonl"
	test -s "$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)"
	test -s "$(EVAL_OSDI_PERFORMANCE_BASELINE_INPUTS_SHA256)"
	sha256sum \
		"$(EVAL_OSDI_PERFORMANCE_JSON)" \
		"$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		"$(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baselines.jsonl" \
		"$(EVAL_OSDI_PERFORMANCE_BASELINE_LEDGER_JSON)" \
		"$(EVAL_OSDI_PERFORMANCE_BASELINE_INPUTS_SHA256)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256)" >/dev/null
	expected_groups=$$(jq -n --arg expected_benches "$(EVAL_OSDI_BASELINE_EXPECTED_BENCHES)" --argjson required "$(EVAL_OSDI_REQUIRED_BASELINES)" '($$expected_benches | split(" ") | map(select(length > 0)) | length) * $$required'); \
	expected_rows=$$(jq -s '[.[] | select(.event == "baseline_latency")] | length' "$(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baselines.jsonl"); \
	jq -r 'select(.event == "baseline_latency") | [.baseline,.bench,.sample,(.latency_sample // 0),.ops,.elapsed_ns,(if .ops == 0 then 0 else (.elapsed_ns / .ops) end),.fail] | @tsv' "$(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)/baselines.jsonl" \
		| sort -t "$$(printf '\t')" -k1,1 -k2,2 -k7,7n \
		| awk -F '\t' \
			-v run_id="$(RUN_ID)" \
			-v baseline_run_id="$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)" \
			-v baseline_result_dir="$(EVAL_OSDI_PERFORMANCE_BASELINE_DIR)" \
			-v expected_groups="$$expected_groups" \
				-v expected_rows="$$expected_rows" \
				-v required_samples="$(EVAL_OSDI_REQUIRED_PERF_SAMPLES)" \
				-v required_latency_batch="$(EVAL_OSDI_REQUIRED_LATENCY_BATCH)" \
				-v ci_z="$(EVAL_OSDI_TAIL_CI_Z)" \
				-v inputs_sha256_file="$(EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256)" \
			'function js(s) { gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s } \
			function pidx(count,p,idx) { idx = int((count * p) + 0.999999); if (idx < 1) idx = 1; if (idx > count) idx = count; return idx } \
			function flush(    i,sample_count,latency_sample_count,mean,var,sd,ci,low,high,p50,p95,p99,minv,maxv,complete) { \
				if (n == 0) return; \
				groups++; \
				if (min_group_rows == 0 || n < min_group_rows) min_group_rows = n; \
				if (n > max_group_rows) max_group_rows = n; \
					for (i in sample_seen) sample_count++; \
					for (i in latency_seen) latency_sample_count++; \
					if (min_group_samples == 0 || sample_count < min_group_samples) min_group_samples = sample_count; \
					if (sample_count > max_group_samples) max_group_samples = sample_count; \
					mean = sum / n; \
				var = 0; \
				if (n > 1) { var = (sumsq - ((sum * sum) / n)) / (n - 1); if (var < 0) var = 0; } \
				sd = sqrt(var); \
				ci = (n > 0 ? ci_z * sd / sqrt(n) : 0); \
				low = mean - ci; if (low < 0) low = 0; high = mean + ci; \
				p50 = values[pidx(n, 0.50)]; p95 = values[pidx(n, 0.95)]; p99 = values[pidx(n, 0.99)]; \
				minv = values[1]; maxv = values[n]; complete = (group_fail == 0 ? "true" : "false"); \
				printf("{\"schema\":\"namei_ext.eval_osdi.external_baseline_latency_tail.v1\",\"event\":\"external-baseline-latency-tail\",\"run_id\":\"%s\",\"baseline_run_id\":\"%s\",\"baseline_result_dir\":\"%s\",\"baseline\":\"%s\",\"bench\":\"%s\",\"rows\":%d,\"samples_observed\":%d,\"latency_samples_observed\":%d,\"mean_ns_per_op\":%.6f,\"stdev_ns_per_op\":%.6f,\"ci95_low_ns_per_op\":%.6f,\"ci95_high_ns_per_op\":%.6f,\"p50_ns_per_op\":%.6f,\"p95_ns_per_op\":%.6f,\"p99_ns_per_op\":%.6f,\"min_ns_per_op\":%.6f,\"max_ns_per_op\":%.6f,\"failures\":%d,\"complete\":%s}\n", run_id, baseline_run_id, baseline_result_dir, js(baseline), js(bench), n, sample_count, latency_sample_count, mean, sd, low, high, p50, p95, p99, minv, maxv, group_fail, complete); \
				delete values; delete sample_seen; delete latency_seen; n = 0; sum = 0; sumsq = 0; group_fail = 0; \
			} \
			{ \
				key = $$1 "\t" $$2; \
				if (current_key != "" && key != current_key) { flush(); current_key = key; baseline = $$1; bench = $$2; } \
				if (current_key == "") { current_key = key; baseline = $$1; bench = $$2; } \
					ops = $$5 + 0; if (min_ops_per_row == 0 || ops < min_ops_per_row) min_ops_per_row = ops; if (ops > max_ops_per_row) max_ops_per_row = ops; \
					value = $$7 + 0; values[++n] = value; sum += value; sumsq += value * value; \
					sample_seen[$$3] = 1; latency_seen[$$4] = 1; total_rows++; total_fail += $$8; group_fail += $$8; \
				} \
				END { \
					flush(); \
					has_artifact = (total_rows > 0 && total_fail == 0 && groups == expected_groups && total_rows == expected_rows ? "true" : "false"); \
					has_ci = (has_artifact == "true" && min_group_rows >= 2 ? "true" : "false"); \
					has_release_sample_budget = (has_artifact == "true" && min_group_samples >= required_samples ? "true" : "false"); \
					has_release_latency_batch_budget = (has_artifact == "true" && min_ops_per_row >= required_latency_batch ? "true" : "false"); \
					printf("{\"schema\":\"namei_ext.eval_osdi.external_baseline_latency_tail.v1\",\"event\":\"external-baseline-latency-tail-summary\",\"run_id\":\"%s\",\"baseline_run_id\":\"%s\",\"baseline_result_dir\":\"%s\",\"rows\":%d,\"expected_rows\":%d,\"groups\":%d,\"expected_groups\":%d,\"min_group_rows\":%d,\"max_group_rows\":%d,\"min_group_samples\":%d,\"max_group_samples\":%d,\"min_ops_per_latency_row\":%d,\"max_ops_per_latency_row\":%d,\"failures\":%d,\"required_paper_samples\":%d,\"required_latency_batch\":%d,\"has_external_baseline_tail_artifact\":%s,\"has_confidence_interval\":%s,\"has_release_sample_budget\":%s,\"has_release_latency_batch_budget\":%s,\"inputs_sha256_file\":\"%s\"}\n", run_id, baseline_run_id, baseline_result_dir, total_rows, expected_rows, groups, expected_groups, min_group_rows, max_group_rows, min_group_samples, max_group_samples, min_ops_per_row, max_ops_per_row, total_fail, required_samples, required_latency_batch, has_artifact, has_ci, has_release_sample_budget, has_release_latency_batch_budget, inputs_sha256_file); \
				}' \
		>"$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON).tmp"
	mv "$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON).tmp" "$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON)"
		jq -e -s '.[] | select(.event == "external-baseline-latency-tail-summary" and .has_external_baseline_tail_artifact == true)' "$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON)" >/dev/null
	jq -n -c \
		--slurpfile perf "$(EVAL_OSDI_PERFORMANCE_JSON)" \
		--slurpfile internal "$(EVAL_OSDI_PERFORMANCE_TAIL_JSON)" \
		--slurpfile external "$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)" \
		--arg shared_benches "$(EVAL_OSDI_SHARED_PERFORMANCE_BENCHES)" \
		--argjson kernel_p99_ratio_max "$(EVAL_OSDI_POLICY_MAX_P99_NATIVE_RATIO)" \
		--argjson fuse_speedup_min "$(EVAL_OSDI_POLICY_MIN_P99_FUSE_SPEEDUP)" \
		--argjson pass_only_p99_ratio_max "$(EVAL_OSDI_PASS_ONLY_MAX_P99_NATIVE_RATIO)" \
		'($$shared_benches | split(" ") | map(select(length > 0))) as $$benches | def internal_row($$variant; $$bench): ([ $$internal[] | select(.event == "bench-latency-tail" and .variant == $$variant and .bench == $$bench) ] | first // {}); def external_row($$baseline; $$bench): ([ $$external[] | select(.event == "external-baseline-latency-tail" and .baseline == $$baseline and .bench == $$bench) ] | first // {}); def ratio($$num; $$den): if (($$den // 0) > 0) then ($$num / $$den) else null end; def leq($$value; $$limit): (($$value // 1e309) <= $$limit); def geq($$value; $$limit): (($$value // 0) >= $$limit); [$$benches[] as $$bench | internal_row("baseline"; $$bench) as $$native | internal_row("pass_only"; $$bench) as $$pass_only | internal_row("policy"; $$bench) as $$policy | internal_row("table_redirect_hit"; $$bench) as $$table_hit | external_row("fuse_redirect"; $$bench) as $$fuse | ($$native.p99_ns_per_op // 0) as $$native_p99 | ($$pass_only.p99_ns_per_op // 0) as $$pass_only_p99 | ($$policy.p99_ns_per_op // 0) as $$policy_p99 | ($$table_hit.p99_ns_per_op // 0) as $$table_hit_p99 | ($$fuse.p99_ns_per_op // 0) as $$fuse_p99 | ratio($$policy_p99; $$native_p99) as $$policy_native_ratio | ratio($$fuse_p99; $$policy_p99) as $$policy_fuse_speedup | ratio($$pass_only_p99; $$native_p99) as $$pass_native_ratio | ratio($$policy_p99; $$pass_only_p99) as $$policy_pass_ratio | ratio($$policy_p99; $$table_hit_p99) as $$policy_table_ratio | {schema:"namei_ext.eval_osdi.performance_comparison.v1", event:"eval-osdi-performance-comparison", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, bench:$$bench, native_p99_ns_per_op:$$native_p99, pass_only_p99_ns_per_op:$$pass_only_p99, policy_p99_ns_per_op:$$policy_p99, table_hit_p99_ns_per_op:$$table_hit_p99, fuse_p99_ns_per_op:$$fuse_p99, policy_to_native_p99_ratio:$$policy_native_ratio, policy_to_fuse_p99_speedup:$$policy_fuse_speedup, pass_only_to_native_p99_ratio:$$pass_native_ratio, policy_to_pass_only_p99_ratio:$$policy_pass_ratio, policy_to_table_hit_p99_ratio:$$policy_table_ratio, kernel_p99_ratio_threshold:$$kernel_p99_ratio_max, fuse_speedup_threshold:$$fuse_speedup_min, pass_only_p99_ratio_threshold:$$pass_only_p99_ratio_max, kernel_p99_threshold_pass:leq($$policy_native_ratio; $$kernel_p99_ratio_max), fuse_speedup_threshold_pass:geq($$policy_fuse_speedup; $$fuse_speedup_min), pass_only_threshold_pass:leq($$pass_native_ratio; $$pass_only_p99_ratio_max), complete:(($$native.complete // false) and ($$pass_only.complete // false) and ($$policy.complete // false) and ($$table_hit.complete // false) and ($$fuse.complete // false))}] as $$rows | ([$$perf[] | select(.event == "eval-osdi-performance-summary")] | first // {}) as $$perf_summary | ([$$external[] | select(.event == "external-baseline-latency-tail-summary")] | first // {}) as $$external_summary | ($$perf_summary.has_release_tail_sample_budget // false) as $$has_internal_release_samples | ($$perf_summary.has_release_latency_batch_budget // false) as $$has_internal_latency_batch | ($$perf_summary.has_confidence_interval // false) as $$has_internal_ci | ($$perf_summary.has_randomized_order // false) as $$has_randomized_order | ($$perf_summary.has_system_metrics // false) as $$has_system_metrics | ($$perf_summary.baseline_release_gate_pass // false) as $$baseline_release_gate_pass | ($$external_summary.has_external_baseline_tail_artifact // false) as $$has_external_tail | ($$external_summary.has_confidence_interval // false) as $$has_external_ci | ($$external_summary.has_release_sample_budget // false) as $$has_external_release_samples | ($$external_summary.has_release_latency_batch_budget // false) as $$has_external_latency_batch | ($$rows | length == ($$benches | length) and ([ $$rows[] | select(.complete != true) ] | length == 0)) as $$comparison_rows_complete | ([ $$rows[] | select(.kernel_p99_threshold_pass != true) ] | length == 0) as $$kernel_p99_threshold_pass | ([ $$rows[] | select(.fuse_speedup_threshold_pass != true) ] | length == 0) as $$fuse_speedup_threshold_pass | ([ $$rows[] | select(.pass_only_threshold_pass != true) ] | length == 0) as $$pass_only_threshold_pass | ($$has_internal_release_samples and $$has_internal_latency_batch and $$has_internal_ci and $$has_randomized_order and $$has_system_metrics and $$baseline_release_gate_pass and $$has_external_tail and $$has_external_ci and $$has_external_release_samples and $$has_external_latency_batch and $$comparison_rows_complete) as $$input_gate_pass | ($$input_gate_pass and $$kernel_p99_threshold_pass and $$fuse_speedup_threshold_pass) as $$c3_supported | ($$input_gate_pass and $$pass_only_threshold_pass and $$kernel_p99_threshold_pass) as $$c5_supported | false as $$c2_supported | $$rows[], {schema:"namei_ext.eval_osdi.performance_comparison.v1", event:"eval-osdi-performance-comparison-summary", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, result_level:"release_threshold_verdict", rows:($$rows | length), shared_benches:$$benches, input_gate_pass:$$input_gate_pass, comparison_rows_complete:$$comparison_rows_complete, has_internal_release_samples:$$has_internal_release_samples, has_internal_latency_batch:$$has_internal_latency_batch, has_internal_ci:$$has_internal_ci, has_randomized_order:$$has_randomized_order, has_system_metrics:$$has_system_metrics, baseline_release_gate_pass:$$baseline_release_gate_pass, has_external_tail:$$has_external_tail, has_external_ci:$$has_external_ci, has_external_release_samples:$$has_external_release_samples, has_external_latency_batch:$$has_external_latency_batch, kernel_p99_threshold_pass:$$kernel_p99_threshold_pass, fuse_speedup_threshold_pass:$$fuse_speedup_threshold_pass, pass_only_threshold_pass:$$pass_only_threshold_pass, max_policy_to_native_p99_ratio:([$$rows[].policy_to_native_p99_ratio // 0] | max // 0), min_policy_to_fuse_p99_speedup:([$$rows[].policy_to_fuse_p99_speedup // 0] | min // 0), max_pass_only_to_native_p99_ratio:([$$rows[].pass_only_to_native_p99_ratio // 0] | max // 0), c2_supported:$$c2_supported, c3_supported:$$c3_supported, c5_supported:$$c5_supported, release_gate_pass:($$c2_supported and $$c3_supported and $$c5_supported), verdict:(if ($$c2_supported and $$c3_supported and $$c5_supported) then "supported" elif $$input_gate_pass then "unsupported_by_thresholds_or_missing_macrobench" else "blocked_by_missing_inputs" end), missing_evidence:[(if $$has_internal_release_samples then empty else "internal release latency sample budget" end), (if $$has_internal_latency_batch then empty else "internal release latency batch budget" end), (if $$has_internal_ci then empty else "internal latency CI artifact" end), (if $$has_randomized_order then empty else "internal randomized order" end), (if $$has_system_metrics then empty else "internal system metrics" end), (if $$baseline_release_gate_pass then empty else "external baseline release gate" end), (if $$has_external_tail then empty else "external baseline tail artifact" end), (if $$has_external_ci then empty else "external baseline CI artifact" end), (if $$has_external_release_samples then empty else "external release latency sample budget" end), (if $$has_external_latency_batch then empty else "external release latency batch budget" end), (if $$c2_supported then empty else "C2 setup/storage/update macrobench comparison" end), (if $$kernel_p99_threshold_pass then empty else "C3 policy/native p99 threshold" end), (if $$fuse_speedup_threshold_pass then empty else "C3 policy/FUSE 2x speedup threshold" end), (if $$pass_only_threshold_pass then empty else "C5 pass-only residual overhead threshold" end)], detail:"Comparison verdict is derived from release input evidence and fixed thresholds; it may support, block, or reject C2/C3/C5 without changing raw collectors."}' \
		>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON).tmp"
	mv "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON).tmp" "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-comparison-summary")] | length) == 1' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg phase1_run_id "$(EVAL_OSDI_PHASE1_RUN_ID)" \
		--arg baseline_run_id "$(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg comparison_json "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)" \
		--arg external_baseline_tail_json "$(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON)" \
		--arg comparison_inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256)" \
		--arg comparison_summary "$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)" \
		--argjson release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison-summary") | .release_gate_pass' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)")" \
		--argjson c2_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison-summary") | .c2_supported' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)")" \
		--argjson c3_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison-summary") | .c3_supported' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)")" \
		--argjson c5_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison-summary") | .c5_supported' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)")" \
		'{schema:"namei_ext.eval_osdi.performance_comparison_manifest.v1", run_id:$$run_id, phase1_run_id:$$phase1_run_id, baseline_run_id:$$baseline_run_id, generated_at:$$generated_at, artifacts:{comparison_json:$$comparison_json, external_baseline_tail_json:$$external_baseline_tail_json, comparison_inputs_sha256:$$comparison_inputs_sha256, comparison_summary:$$comparison_summary}, gate:{release_gate_pass:$$release_gate_pass, c2_supported:$$c2_supported, c3_supported:$$c3_supported, c5_supported:$$c5_supported}}' \
		>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_MANIFEST)"
	printf '%s\n' '# OSDI B2/B8 Performance Comparison Verdict' >"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- External baseline run: $(EVAL_OSDI_PERFORMANCE_BASELINE_RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- Comparison JSONL: $(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- External baseline tail JSONL: $(EVAL_OSDI_PERFORMANCE_BASELINE_TAIL_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_PERFORMANCE_COMPARISON_INPUTS_SHA256)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '%s\n' '- Manifest: $(EVAL_OSDI_PERFORMANCE_COMPARISON_MANIFEST)' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '\n%s\n' '## Verdict' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison-summary") | "- input_gate_pass=" + (.input_gate_pass|tostring) + "\n- internal_latency_batch=" + (.has_internal_latency_batch|tostring) + "\n- external_latency_batch=" + (.has_external_latency_batch|tostring) + "\n- c2_supported=" + (.c2_supported|tostring) + "\n- c3_supported=" + (.c3_supported|tostring) + "\n- c5_supported=" + (.c5_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- verdict=" + .verdict + "\n- max_policy_to_native_p99_ratio=" + (.max_policy_to_native_p99_ratio|tostring) + "\n- min_policy_to_fuse_p99_speedup=" + (.min_policy_to_fuse_p99_speedup|tostring) + "\n- max_pass_only_to_native_p99_ratio=" + (.max_pass_only_to_native_p99_ratio|tostring) + "\n- missing_evidence=" + (.missing_evidence|join(", "))' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	printf '\n%s\n' '## Per-Bench Rows' >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-performance-comparison") | "- " + .bench + ": policy/native_p99=" + (.policy_to_native_p99_ratio|tostring) + ", policy/fuse_speedup=" + (.policy_to_fuse_p99_speedup|tostring) + ", pass_only/native_p99=" + (.pass_only_to_native_p99_ratio|tostring) + ", kernel_pass=" + (.kernel_p99_threshold_pass|tostring) + ", fuse_pass=" + (.fuse_speedup_threshold_pass|tostring) + ", pass_only_pass=" + (.pass_only_threshold_pass|tostring)' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_COMPARISON_SUMMARY)"

eval-osdi-performance-tool-redirect-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID)"
	test -s "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)"
	test "$(EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES)" = "lookup_tool_redirect access_tool_redirect open_tool_redirect exec_tool_redirect"
	install -d "$(EVAL_OSDI_PERFORMANCE_DIR)"
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-comparison-summary" and .schema == "namei_ext.eval_osdi.performance_comparison.v1" and .input_gate_pass == true)] | length) == 1' "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)" >/dev/null
	jq -e -s --arg benches "$(EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES)" '($$benches | split(" ") | map(select(length > 0))) as $$expected | ([.[] | select(.event == "eval-osdi-performance-comparison" and (.bench as $$b | $$expected | index($$b))) | .bench] | sort) == ($$expected | sort)' "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile comparison "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg source_run_id "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID)" \
		--arg source_json "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256)" \
		--arg scoped_benches "$(EVAL_OSDI_TOOL_REDIRECT_PERFORMANCE_BENCHES)" \
		'($$scoped_benches | split(" ") | map(select(length > 0))) as $$benches | ([ $$comparison[] | select(.event == "eval-osdi-performance-comparison-summary") ][0] // {}) as $$summary | [$$benches[] as $$bench | ([ $$comparison[] | select(.event == "eval-osdi-performance-comparison" and .bench == $$bench) ][0] // {}) + {scope:"tool_redirect_metadata"}] as $$rows | ($$rows | length == ($$benches | length) and ([ $$rows[] | select(.complete != true) ] | length) == 0) as $$rows_complete | ([ $$rows[] | select(.kernel_p99_threshold_pass != true) ] | length == 0) as $$kernel_pass | ([ $$rows[] | select(.fuse_speedup_threshold_pass != true) ] | length == 0) as $$fuse_pass | ($$summary.input_gate_pass == true) as $$input_pass | ($$input_pass and $$rows_complete and $$kernel_pass and $$fuse_pass) as $$scoped_c3 | ($$rows[] | . + {schema:"namei_ext.eval_osdi.performance_scope.v1", event:"eval-osdi-performance-tool-redirect-scope", run_id:$$run_id, source_run_id:$$source_run_id, source_json:$$source_json}), {schema:"namei_ext.eval_osdi.performance_scope.v1", event:"eval-osdi-performance-tool-redirect-scope-summary", run_id:$$run_id, source_run_id:$$source_run_id, source_json:$$source_json, result_level:"scoped_c3_tool_redirect_verdict", scope:"tool_redirect_metadata", scoped_benches:$$benches, rows:($$rows | length), source_input_gate_pass:$$input_pass, scoped_rows_complete:$$rows_complete, scoped_kernel_p99_threshold_pass:$$kernel_pass, scoped_fuse_speedup_threshold_pass:$$fuse_pass, scoped_c3_supported:$$scoped_c3, full_suite_c3_supported:($$summary.c3_supported // false), release_gate_pass:false, max_scoped_policy_to_native_p99_ratio:([$$rows[].policy_to_native_p99_ratio // 0] | max // 0), min_scoped_policy_to_fuse_p99_speedup:([$$rows[].policy_to_fuse_p99_speedup // 0] | min // 0), failed_full_suite_benches:([$$comparison[] | select(.event == "eval-osdi-performance-comparison" and .kernel_p99_threshold_pass != true) | .bench]), inputs_sha256_file:$$inputs_sha256, supported_wording:"The tool-redirect lookup/access/open/exec slice satisfies the configured native and FUSE p99 thresholds; full-suite C3 remains unsupported."}' \
		>"$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON).tmp"
	mv "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON).tmp" "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-tool-redirect-scope-summary" and .scoped_c3_supported == true and .full_suite_c3_supported == false and .release_gate_pass == false)] | length) == 1' "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg source_run_id "$(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg scope_json "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)" \
		--arg inputs "$(EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)" \
		--argjson scoped_c3_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-performance-tool-redirect-scope-summary") | .scoped_c3_supported' "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)")" \
		'{schema:"namei_ext.eval_osdi.performance_scope_manifest.v1", run_id:$$run_id, source_run_id:$$source_run_id, generated_at:$$generated_at, artifacts:{scope_json:$$scope_json, inputs_sha256:$$inputs, summary:$$summary}, gate:{scoped_c3_supported:$$scoped_c3_supported, release_gate_pass:false}}' \
		>"$(EVAL_OSDI_PERFORMANCE_SCOPE_MANIFEST)"
	printf '%s\n' '# OSDI Tool-Redirect Performance Scope Ledger' >"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '%s\n' '- Source performance comparison run: $(EVAL_OSDI_PERFORMANCE_SCOPE_SOURCE_RUN_ID)' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_PERFORMANCE_SCOPE_INPUTS_SHA256)' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '\n%s\n' '## Verdict' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-performance-tool-redirect-scope-summary") | "- scoped_c3_supported=" + (.scoped_c3_supported|tostring) + "\n- full_suite_c3_supported=" + (.full_suite_c3_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- max_scoped_policy_to_native_p99_ratio=" + (.max_scoped_policy_to_native_p99_ratio|tostring) + "\n- min_scoped_policy_to_fuse_p99_speedup=" + (.min_scoped_policy_to_fuse_p99_speedup|tostring) + "\n- failed_full_suite_benches=" + (.failed_full_suite_benches|join(", "))' "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	printf '\n%s\n' '## Scoped Rows' >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-performance-tool-redirect-scope") | "- " + .bench + ": policy/native_p99=" + (.policy_to_native_p99_ratio|tostring) + ", policy/fuse_speedup=" + (.policy_to_fuse_p99_speedup|tostring) + ", kernel_pass=" + (.kernel_p99_threshold_pass|tostring) + ", fuse_pass=" + (.fuse_speedup_threshold_pass|tostring)' "$(EVAL_OSDI_PERFORMANCE_SCOPE_JSON)" >>"$(EVAL_OSDI_PERFORMANCE_SCOPE_SUMMARY)"

eval-osdi-c3-residual-diagnostic-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)"
	test -s "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON)"
	test -s "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON)"
	test -s "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON)"
	install -d "$(EVAL_OSDI_PERFORMANCE_DIR)"
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-comparison-summary" and .schema == "namei_ext.eval_osdi.performance_comparison.v1" and .input_gate_pass == true and .fuse_speedup_threshold_pass == true and .c3_supported == false)] | length) == 1' "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "bench-latency-tail-summary" and .has_tail_latency_artifact == true and .has_release_sample_budget == true and .has_release_latency_batch_budget == true)] | length) == 1' "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "external-baseline-latency-tail-summary" and .has_external_baseline_tail_artifact == true)] | length) == 1' "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON)" \
		"$(EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON)" \
		"$(EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile comparison "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON)" \
		--slurpfile tail "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON)" \
		--slurpfile external "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg source_run_id "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)" \
		--arg source_json "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_JSON)" \
		--arg source_tail_json "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_TAIL_JSON)" \
		--arg source_baseline_tail_json "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_BASELINE_TAIL_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256)" \
		'def row($$variant; $$bench): ([ $$tail[] | select(.event == "bench-latency-tail" and .variant == $$variant and .bench == $$bench) ] | first // {}); def erow($$baseline; $$bench): ([ $$external[] | select(.event == "external-baseline-latency-tail" and .baseline == $$baseline and .bench == $$bench) ] | first // {}); def ratio($$num; $$den): if (($$den // 0) > 0) then ($$num / $$den) else null end; def cls($$r; $$policy; $$native): if $$r.kernel_p99_threshold_pass == true then "passes_full_suite_c3" elif (($$r.policy_to_native_p99_ratio // 0) <= (($$r.kernel_p99_ratio_threshold // 1.5) * 1.05)) then "near_native_p99_threshold" elif ((ratio($$policy.p99_ns_per_op; $$policy.p95_ns_per_op) // 0) >= 2.0) then "policy_p99_tail_outlier" elif (($$r.pass_only_threshold_pass != true) and (($$r.policy_to_pass_only_p99_ratio // 99) <= 1.0)) then "common_hook_residual_dominates" else "policy_specific_native_p99_gap" end; ([ $$comparison[] | select(.event == "eval-osdi-performance-comparison-summary") ][0] // {}) as $$summary | [$$comparison[] | select(.event == "eval-osdi-performance-comparison")] as $$rows | [$$rows[] as $$r | row("baseline"; $$r.bench) as $$native | row("pass_only"; $$r.bench) as $$pass | row("policy"; $$r.bench) as $$policy | row("table_redirect_hit"; $$r.bench) as $$table | erow("fuse_redirect"; $$r.bench) as $$fuse | {schema:"namei_ext.eval_osdi.c3_residual_diagnostic.v1", event:"eval-osdi-c3-residual-diagnostic", run_id:$$run_id, source_run_id:$$source_run_id, source_json:$$source_json, bench:$$r.bench, diagnostic_class:cls($$r; $$policy; $$native), kernel_p99_threshold_pass:$$r.kernel_p99_threshold_pass, fuse_speedup_threshold_pass:$$r.fuse_speedup_threshold_pass, pass_only_threshold_pass:$$r.pass_only_threshold_pass, policy_to_native_p99_ratio:$$r.policy_to_native_p99_ratio, policy_to_fuse_p99_speedup:$$r.policy_to_fuse_p99_speedup, pass_only_to_native_p99_ratio:$$r.pass_only_to_native_p99_ratio, policy_to_pass_only_p99_ratio:$$r.policy_to_pass_only_p99_ratio, native_p50_ns_per_op:$$native.p50_ns_per_op, native_p95_ns_per_op:$$native.p95_ns_per_op, native_p99_ns_per_op:$$native.p99_ns_per_op, pass_only_p50_ns_per_op:$$pass.p50_ns_per_op, pass_only_p95_ns_per_op:$$pass.p95_ns_per_op, pass_only_p99_ns_per_op:$$pass.p99_ns_per_op, policy_p50_ns_per_op:$$policy.p50_ns_per_op, policy_p95_ns_per_op:$$policy.p95_ns_per_op, policy_p99_ns_per_op:$$policy.p99_ns_per_op, policy_p99_to_p95_ratio:ratio($$policy.p99_ns_per_op; $$policy.p95_ns_per_op), table_hit_p99_ns_per_op:$$table.p99_ns_per_op, fuse_p50_ns_per_op:$$fuse.p50_ns_per_op, fuse_p95_ns_per_op:$$fuse.p95_ns_per_op, fuse_p99_ns_per_op:$$fuse.p99_ns_per_op, complete:(($$r.complete // false) and ($$native.complete // false) and ($$pass.complete // false) and ($$policy.complete // false) and ($$table.complete // false) and ($$fuse.complete // false))}] as $$diag | $$diag[], {schema:"namei_ext.eval_osdi.c3_residual_diagnostic.v1", event:"eval-osdi-c3-residual-diagnostic-summary", run_id:$$run_id, source_run_id:$$source_run_id, source_json:$$source_json, source_tail_json:$$source_tail_json, source_baseline_tail_json:$$source_baseline_tail_json, result_level:"diagnostic_only_not_release_gate", rows:($$diag | length), complete_rows:([$$diag[] | select(.complete == true)] | length), source_input_gate_pass:($$summary.input_gate_pass // false), full_suite_c3_supported:($$summary.c3_supported // false), full_suite_c5_supported:($$summary.c5_supported // false), fuse_baseline_threshold_pass:($$summary.fuse_speedup_threshold_pass // false), failed_kernel_benches:([$$diag[] | select(.kernel_p99_threshold_pass != true) | .bench]), failed_pass_only_benches:([$$diag[] | select(.pass_only_threshold_pass != true) | .bench]), diagnostic_classes:([$$diag[].diagnostic_class] | unique | sort), near_threshold_benches:([$$diag[] | select(.diagnostic_class == "near_native_p99_threshold") | .bench]), p99_tail_outlier_benches:([$$diag[] | select(.diagnostic_class == "policy_p99_tail_outlier") | .bench]), common_hook_residual_benches:([$$diag[] | select(.diagnostic_class == "common_hook_residual_dominates") | .bench]), policy_specific_gap_benches:([$$diag[] | select(.diagnostic_class == "policy_specific_native_p99_gap") | .bench]), min_policy_to_fuse_p99_speedup:([$$diag[].policy_to_fuse_p99_speedup // 0] | min // 0), max_policy_to_native_p99_ratio:([$$diag[].policy_to_native_p99_ratio // 0] | max // 0), max_pass_only_to_native_p99_ratio:([$$diag[].pass_only_to_native_p99_ratio // 0] | max // 0), release_gate_pass:false, inputs_sha256_file:$$inputs_sha256, detail:"Diagnostic ledger preserves negative full-suite C3/C5 evidence. FUSE p99 speedup passes for all shared benches; native p99 and pass-only residual rows remain blockers."}' \
		>"$(EVAL_OSDI_C3_RESIDUAL_JSON).tmp"
	mv "$(EVAL_OSDI_C3_RESIDUAL_JSON).tmp" "$(EVAL_OSDI_C3_RESIDUAL_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-c3-residual-diagnostic-summary" and .source_input_gate_pass == true and .fuse_baseline_threshold_pass == true and .full_suite_c3_supported == false and .release_gate_pass == false)] | length) == 1' "$(EVAL_OSDI_C3_RESIDUAL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c3-residual-diagnostic" and .kernel_p99_threshold_pass != true)] | length) >= 1' "$(EVAL_OSDI_C3_RESIDUAL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c3-residual-diagnostic" and .fuse_speedup_threshold_pass != true)] | length) == 0' "$(EVAL_OSDI_C3_RESIDUAL_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg source_run_id "$(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg diagnostic_json "$(EVAL_OSDI_C3_RESIDUAL_JSON)" \
		--arg inputs "$(EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)" \
		--argjson fuse_baseline_threshold_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-c3-residual-diagnostic-summary") | .fuse_baseline_threshold_pass' "$(EVAL_OSDI_C3_RESIDUAL_JSON)")" \
		--argjson full_suite_c3_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-c3-residual-diagnostic-summary") | .full_suite_c3_supported' "$(EVAL_OSDI_C3_RESIDUAL_JSON)")" \
		'{schema:"namei_ext.eval_osdi.c3_residual_diagnostic_manifest.v1", run_id:$$run_id, source_run_id:$$source_run_id, generated_at:$$generated_at, artifacts:{diagnostic_json:$$diagnostic_json, inputs_sha256:$$inputs, summary:$$summary}, gate:{fuse_baseline_threshold_pass:$$fuse_baseline_threshold_pass, full_suite_c3_supported:$$full_suite_c3_supported, release_gate_pass:false}}' \
		>"$(EVAL_OSDI_C3_RESIDUAL_MANIFEST)"
	printf '%s\n' '# OSDI C3 Full-Suite Residual Diagnostic' >"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '%s\n' '- Source performance comparison run: $(EVAL_OSDI_C3_RESIDUAL_SOURCE_RUN_ID)' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_C3_RESIDUAL_JSON)' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_C3_RESIDUAL_INPUTS_SHA256)' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '\n%s\n' '## Verdict' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c3-residual-diagnostic-summary") | "- source_input_gate_pass=" + (.source_input_gate_pass|tostring) + "\n- fuse_baseline_threshold_pass=" + (.fuse_baseline_threshold_pass|tostring) + "\n- full_suite_c3_supported=" + (.full_suite_c3_supported|tostring) + "\n- full_suite_c5_supported=" + (.full_suite_c5_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- failed_kernel_benches=" + (.failed_kernel_benches|join(", ")) + "\n- failed_pass_only_benches=" + (.failed_pass_only_benches|join(", ")) + "\n- diagnostic_classes=" + (.diagnostic_classes|join(", "))' "$(EVAL_OSDI_C3_RESIDUAL_JSON)" >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	printf '\n%s\n' '## Per-Bench Rows' >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c3-residual-diagnostic") | "- " + .bench + ": class=" + .diagnostic_class + ", policy/native_p99=" + (.policy_to_native_p99_ratio|tostring) + ", policy/fuse_speedup=" + (.policy_to_fuse_p99_speedup|tostring) + ", pass_only/native_p99=" + (.pass_only_to_native_p99_ratio|tostring) + ", policy_p99/p95=" + (.policy_p99_to_p95_ratio|tostring)' "$(EVAL_OSDI_C3_RESIDUAL_JSON)" >>"$(EVAL_OSDI_C3_RESIDUAL_SUMMARY)"

eval-osdi-c5-rusage-nohook-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID)"
	test -n "$(EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID)"
	test -n "$(EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID)"
	test -n "$(EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID)"
	test -s "$(EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON)"
	test -s "$(EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON)"
	test -s "$(EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON)"
	test -s "$(EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON)"
	install -d "$(EVAL_OSDI_PERFORMANCE_DIR)"
	jq -e -s '([.[] | select(.event == "bench-latency-tail-summary" and .has_tail_latency_artifact == true and .has_release_sample_budget == true and .has_release_latency_batch_budget == true)] | length) == 1' "$(EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "bench-latency-tail-summary" and .has_tail_latency_artifact == true and .has_release_sample_budget == true and .has_release_latency_batch_budget == true)] | length) == 1' "$(EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "bench-latency-tail-summary" and .has_tail_latency_artifact == true and .has_release_sample_budget == true and .has_release_latency_batch_budget == true)] | length) == 1' "$(EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "bench_latency" and (.user_usec? != null) and (.sys_usec? != null))] | length) > 0' "$(EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON)" \
		"$(EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON)" \
		"$(EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON)" \
		"$(EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON)" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_C5_ABLATION_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_C5_ABLATION_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile rtail "$(EVAL_OSDI_C5_ABLATION_RUSAGE_TAIL_JSON)" \
		--slurpfile raw "$(EVAL_OSDI_C5_ABLATION_RUSAGE_RAW_JSON)" \
		--slurpfile nohook "$(EVAL_OSDI_C5_ABLATION_NOHOOK_TAIL_JSON)" \
		--slurpfile matched "$(EVAL_OSDI_C5_ABLATION_MATCHED_TAIL_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg rusage_run_id "$(EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID)" \
		--arg rusage_phase1_run_id "$(EVAL_OSDI_C5_ABLATION_RUSAGE_PHASE1_RUN_ID)" \
		--arg nohook_run_id "$(EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID)" \
		--arg matched_run_id "$(EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID)" \
		--arg inputs_sha256 "$(EVAL_OSDI_C5_ABLATION_INPUTS_SHA256)" \
		--argjson pass_only_p99_ratio_max "$(EVAL_OSDI_PASS_ONLY_MAX_P99_NATIVE_RATIO)" \
		'def row($$src; $$variant; $$bench): ([ $$src[] | select(.event == "bench-latency-tail" and .variant == $$variant and .bench == $$bench) ] | first // {}); def rrows($$variant; $$bench): [ $$raw[] | select(.event == "bench_latency" and .variant == $$variant and .bench == $$bench) ]; def ratio($$num; $$den): if (($$den // 0) > 0) then ($$num / $$den) else null end; def avg($$xs): if ($$xs | length) > 0 then (($$xs | add) / ($$xs | length)) else null end; def maxv($$xs): if ($$xs | length) > 0 then ($$xs | max) else null end; def cpu_ns_avg($$rows): avg([$$rows[] | (((.user_usec // 0) + (.sys_usec // 0)) * 1000 / (.ops // 1))]); def cpu_ns_max($$rows): maxv([$$rows[] | (((.user_usec // 0) + (.sys_usec // 0)) * 1000 / (.ops // 1))]); def res_avg($$rows; $$field): avg([$$rows[] | ((.[$$field] // 0) / (.ops // 1))]); def res_max($$rows; $$field): maxv([$$rows[] | ((.[$$field] // 0) / (.ops // 1))]); ([ $$rtail[] | select(.event == "bench-latency-tail" and .variant == "baseline") | .bench ] | unique | sort) as $$benches | [$$benches[] as $$bench | row($$rtail; "baseline"; $$bench) as $$full_base | row($$rtail; "pass_only"; $$bench) as $$full_pass | row($$rtail; "policy"; $$bench) as $$full_policy | row($$nohook; "baseline"; $$bench) as $$nohook_base | row($$matched; "baseline"; $$bench) as $$matched_base | row($$matched; "pass_only"; $$bench) as $$matched_pass | rrows("baseline"; $$bench) as $$raw_base | rrows("pass_only"; $$bench) as $$raw_pass | rrows("policy"; $$bench) as $$raw_policy | ratio($$matched_pass.p99_ns_per_op; $$matched_base.p99_ns_per_op) as $$matched_ratio | ratio($$full_pass.p99_ns_per_op; $$full_base.p99_ns_per_op) as $$full_pass_ratio | ratio($$full_policy.p99_ns_per_op; $$full_base.p99_ns_per_op) as $$full_policy_ratio | ratio($$full_pass.p99_ns_per_op; $$nohook_base.p99_ns_per_op) as $$pass_nohook_ratio | ratio($$full_policy.p99_ns_per_op; $$nohook_base.p99_ns_per_op) as $$policy_nohook_ratio | {schema:"namei_ext.eval_osdi.c5_rusage_nohook_ablation.v1", event:"eval-osdi-c5-rusage-nohook-ablation", run_id:$$run_id, rusage_run_id:$$rusage_run_id, rusage_phase1_run_id:$$rusage_phase1_run_id, nohook_run_id:$$nohook_run_id, matched_run_id:$$matched_run_id, bench:$$bench, full_baseline_p99_ns_per_op:$$full_base.p99_ns_per_op, full_pass_only_p99_ns_per_op:$$full_pass.p99_ns_per_op, full_policy_p99_ns_per_op:$$full_policy.p99_ns_per_op, nohook_baseline_p99_ns_per_op:$$nohook_base.p99_ns_per_op, matched_baseline_p99_ns_per_op:$$matched_base.p99_ns_per_op, matched_pass_only_p99_ns_per_op:$$matched_pass.p99_ns_per_op, full_pass_only_to_native_p99_ratio:$$full_pass_ratio, full_policy_to_native_p99_ratio:$$full_policy_ratio, full_pass_only_to_nohook_p99_ratio:$$pass_nohook_ratio, full_policy_to_nohook_p99_ratio:$$policy_nohook_ratio, matched_pass_only_to_native_p99_ratio:$$matched_ratio, pass_only_p99_ratio_threshold:$$pass_only_p99_ratio_max, matched_pass_only_threshold_pass:(($$matched_ratio // 1e309) <= $$pass_only_p99_ratio_max), full_pass_only_threshold_pass:(($$full_pass_ratio // 1e309) <= $$pass_only_p99_ratio_max), baseline_self_cpu_mean_ns_per_op:cpu_ns_avg($$raw_base), pass_only_self_cpu_mean_ns_per_op:cpu_ns_avg($$raw_pass), policy_self_cpu_mean_ns_per_op:cpu_ns_avg($$raw_policy), baseline_self_cpu_max_ns_per_op:cpu_ns_max($$raw_base), pass_only_self_cpu_max_ns_per_op:cpu_ns_max($$raw_pass), policy_self_cpu_max_ns_per_op:cpu_ns_max($$raw_policy), pass_only_minor_faults_mean_per_op:res_avg($$raw_pass; "minor_faults"), pass_only_major_faults_mean_per_op:res_avg($$raw_pass; "major_faults"), pass_only_voluntary_ctxt_switches_mean_per_op:res_avg($$raw_pass; "voluntary_ctxt_switches"), pass_only_involuntary_ctxt_switches_mean_per_op:res_avg($$raw_pass; "involuntary_ctxt_switches"), pass_only_involuntary_ctxt_switches_max_per_op:res_max($$raw_pass; "involuntary_ctxt_switches"), complete:(($$full_base.complete // false) and ($$full_pass.complete // false) and ($$full_policy.complete // false) and ($$nohook_base.complete // false) and ($$matched_base.complete // false) and ($$matched_pass.complete // false) and (($$raw_base|length) > 0) and (($$raw_pass|length) > 0) and (($$raw_policy|length) > 0))}] as $$rows | $$rows[], {schema:"namei_ext.eval_osdi.c5_rusage_nohook_ablation.v1", event:"eval-osdi-c5-rusage-nohook-ablation-summary", run_id:$$run_id, result_level:"diagnostic_only_not_release_gate", rusage_run_id:$$rusage_run_id, rusage_phase1_run_id:$$rusage_phase1_run_id, nohook_run_id:$$nohook_run_id, matched_run_id:$$matched_run_id, rows:($$rows | length), complete_rows:([$$rows[] | select(.complete == true)] | length), pass_only_p99_ratio_threshold:$$pass_only_p99_ratio_max, c5_supported:(([$$rows[] | select(.matched_pass_only_threshold_pass != true)] | length) == 0), full_run_pass_only_threshold_pass:(([$$rows[] | select(.full_pass_only_threshold_pass != true)] | length) == 0), matched_pass_only_threshold_pass:(([$$rows[] | select(.matched_pass_only_threshold_pass != true)] | length) == 0), max_matched_pass_only_to_native_p99_ratio:([$$rows[].matched_pass_only_to_native_p99_ratio // 0] | max // 0), max_full_pass_only_to_native_p99_ratio:([$$rows[].full_pass_only_to_native_p99_ratio // 0] | max // 0), max_full_pass_only_to_nohook_p99_ratio:([$$rows[].full_pass_only_to_nohook_p99_ratio // 0] | max // 0), max_policy_to_nohook_p99_ratio:([$$rows[].full_policy_to_nohook_p99_ratio // 0] | max // 0), failed_matched_benches:([$$rows[] | select(.matched_pass_only_threshold_pass != true) | .bench]), failed_full_run_benches:([$$rows[] | select(.full_pass_only_threshold_pass != true) | .bench]), max_pass_only_major_faults_mean_per_op:([$$rows[].pass_only_major_faults_mean_per_op // 0] | max // 0), max_pass_only_minor_faults_mean_per_op:([$$rows[].pass_only_minor_faults_mean_per_op // 0] | max // 0), max_pass_only_ctxt_switches_mean_per_op:([$$rows[] | ((.pass_only_voluntary_ctxt_switches_mean_per_op // 0) + (.pass_only_involuntary_ctxt_switches_mean_per_op // 0))] | max // 0), release_gate_pass:false, inputs_sha256_file:$$inputs_sha256, detail:"Diagnostic ledger preserves C5 negative evidence: no-hook and matched baseline/pass-only rows reduce denominator ambiguity but pass-only residual remains above threshold."}' \
		>"$(EVAL_OSDI_C5_ABLATION_JSON).tmp"
	mv "$(EVAL_OSDI_C5_ABLATION_JSON).tmp" "$(EVAL_OSDI_C5_ABLATION_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation-summary" and .c5_supported == false and .release_gate_pass == false)] | length) == 1' "$(EVAL_OSDI_C5_ABLATION_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation" and .matched_pass_only_threshold_pass != true)] | length) >= 1' "$(EVAL_OSDI_C5_ABLATION_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation" and .complete != true)] | length) == 0' "$(EVAL_OSDI_C5_ABLATION_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg c5_json "$(EVAL_OSDI_C5_ABLATION_JSON)" \
		--arg inputs "$(EVAL_OSDI_C5_ABLATION_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_C5_ABLATION_SUMMARY)" \
		--argjson c5_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation-summary") | .c5_supported' "$(EVAL_OSDI_C5_ABLATION_JSON)")" \
		'{schema:"namei_ext.eval_osdi.c5_rusage_nohook_ablation_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{c5_json:$$c5_json, inputs_sha256:$$inputs, summary:$$summary}, gate:{c5_supported:$$c5_supported, release_gate_pass:false}}' \
		>"$(EVAL_OSDI_C5_ABLATION_MANIFEST)"
	printf '%s\n' '# OSDI C5 Rusage/No-Hook Ablation Ledger' >"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '%s\n' '- Rusage tail run: $(EVAL_OSDI_C5_ABLATION_RUSAGE_RUN_ID)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '%s\n' '- No-hook baseline run: $(EVAL_OSDI_C5_ABLATION_NOHOOK_RUN_ID)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '%s\n' '- Matched baseline/pass-only run: $(EVAL_OSDI_C5_ABLATION_MATCHED_RUN_ID)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_C5_ABLATION_JSON)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_C5_ABLATION_INPUTS_SHA256)' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '\n%s\n' '## Verdict' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation-summary") | "- c5_supported=" + (.c5_supported|tostring) + "\n- release_gate_pass=" + (.release_gate_pass|tostring) + "\n- max_matched_pass_only_to_native_p99_ratio=" + (.max_matched_pass_only_to_native_p99_ratio|tostring) + "\n- max_full_pass_only_to_native_p99_ratio=" + (.max_full_pass_only_to_native_p99_ratio|tostring) + "\n- max_full_pass_only_to_nohook_p99_ratio=" + (.max_full_pass_only_to_nohook_p99_ratio|tostring) + "\n- failed_matched_benches=" + (.failed_matched_benches|join(", ")) + "\n- failed_full_run_benches=" + (.failed_full_run_benches|join(", ")) + "\n- max_pass_only_ctxt_switches_mean_per_op=" + (.max_pass_only_ctxt_switches_mean_per_op|tostring)' "$(EVAL_OSDI_C5_ABLATION_JSON)" >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	printf '\n%s\n' '## Per-Bench Rows' >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation") | "- " + .bench + ": matched_pass/native_p99=" + (.matched_pass_only_to_native_p99_ratio|tostring) + ", full_pass/native_p99=" + (.full_pass_only_to_native_p99_ratio|tostring) + ", full_pass/nohook_p99=" + (.full_pass_only_to_nohook_p99_ratio|tostring) + ", pass_cpu_mean_ns=" + (.pass_only_self_cpu_mean_ns_per_op|tostring) + ", pass_ctxt_switch_mean_per_op=" + (((.pass_only_voluntary_ctxt_switches_mean_per_op // 0) + (.pass_only_involuntary_ctxt_switches_mean_per_op // 0))|tostring)' "$(EVAL_OSDI_C5_ABLATION_JSON)" >>"$(EVAL_OSDI_C5_ABLATION_SUMMARY)"

eval-osdi-c7-artifact-audit-ledger:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	command -v git >/dev/null
	command -v tar >/dev/null
	test -n "$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)"
	test -n "$(EVAL_OSDI_C7_AUDIT_C3_RUN_ID)"
	test -n "$(EVAL_OSDI_C7_AUDIT_C5_RUN_ID)"
	test -s "$(EVAL_OSDI_C7_AUDIT_CLAIM_JSON)"
	test -s "$(EVAL_OSDI_C7_AUDIT_CLAIM_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_C7_AUDIT_C3_JSON)"
	test -s "$(EVAL_OSDI_C7_AUDIT_C5_JSON)"
	$(MAKE) -C "$(ROOT_DIR)/docs/paper" check
	$(MAKE) -C "$(ROOT_DIR)/docs/paper" paper
	test -s "$(BUILD_ROOT)/paper/main.pdf"
	test -s "$(BUILD_ROOT)/paper/main.log"
	install -d "$(EVAL_OSDI_C7_AUDIT_DIR)"
	git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results' >"$(EVAL_OSDI_C7_AUDIT_MAIN_STATUS)"
	git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal >"$(EVAL_OSDI_C7_AUDIT_KERNEL_STATUS)"
	printf '%s\n' \
		"results/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)/claim-verdict/claim-verdict.jsonl" \
		"results/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)/claim-verdict/claim-verdict-inputs.sha256" \
		"results/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_C3_RUN_ID)/b2-performance/c3-full-suite-residual-diagnostic.jsonl" \
		"results/eval-osdi/paper/$(EVAL_OSDI_C7_AUDIT_C5_RUN_ID)/b2-performance/c5-rusage-nohook-ablation.jsonl" \
		"docs/paper/main.tex" \
		"docs/paper/Makefile" \
		"docs/paper/refs.bib" \
		"docs/paper/sections/01-introduction.tex" \
		"docs/paper/sections/02-motivation.tex" \
		"docs/paper/sections/03-design.tex" \
		"docs/paper/sections/04-implementation.tex" \
		"docs/paper/sections/05-evaluation.tex" \
		"docs/paper/sections/06-related-work.tex" \
		"docs/paper/sections/07-limitations.tex" \
		".build/paper/main.pdf" \
		"mk/eval_osdi.mk" \
		"configs/eval-osdi/claim-verdict.jq" \
		>"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)"
	while IFS= read -r rel; do test -s "$(ROOT_DIR)/$$rel"; done <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)"
	rm -rf "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)"
	install -d "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)"
	while IFS= read -r rel; do \
		install -d "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$(dirname "$$rel")"; \
		case "$$rel" in \
			*.pdf) cp "$(ROOT_DIR)/$$rel" "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$rel" ;; \
			*) sed -e 's#$(ROOT_DIR)#<NAMEI_EXT_ROOT>#g' -e 's#/home/[^/}"[:space:]]*#<HOME>#g' "$(ROOT_DIR)/$$rel" >"$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$rel" ;; \
		esac; \
	done <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)"
	while IFS= read -r rel; do test -s "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$rel"; done <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)"
	tar -C "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)" -cf "$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR)" -T "$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)"
	tar -tf "$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR)" >"$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR_LIST)"
	package_file_count=$$(wc -l <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" | tr -d ' '); \
	package_tar_entry_count=$$(wc -l <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR_LIST)" | tr -d ' '); \
	package_tar_sha256=$$(sha256sum "$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR)" | awk '{print $$1}'); \
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg package_file_list "$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" \
		--arg package_root "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)" \
		--arg package_tar "$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR)" \
		--arg package_tar_list "$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR_LIST)" \
		--arg package_tar_sha256 "$$package_tar_sha256" \
		--argjson package_file_count "$$package_file_count" \
		--argjson package_tar_entry_count "$$package_tar_entry_count" \
		'{schema:"namei_ext.eval_osdi.c7_artifact_package_manifest.v1", run_id:$$run_id, package_file_list:$$package_file_list, package_root:$$package_root, package_tar:$$package_tar, package_tar_sha256:$$package_tar_sha256, package_tar_list:$$package_tar_list, declared_file_count:$$package_file_count, tar_entry_count:$$package_tar_entry_count, package_manifest_gate_pass:($$package_file_count > 0 and $$package_file_count == $$package_tar_entry_count), detail:"Make-owned diagnostic artifact package containing sanitized scoped paper evidence, paper sources, generated PDF, and owning evaluation Make/JQ files. Raw result files remain unchanged outside the package root."}' \
		>"$(EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST)"
	absolute_path_occurrences=$$(while IFS= read -r rel; do grep -Ih -o '/home/[^}"[:space:]]*' "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$rel" || true; done <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" | wc -l | tr -d ' '); \
	user_path_occurrences=$$(while IFS= read -r rel; do grep -Ih -o '/home/yunwei37[^}"[:space:]]*' "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/$$rel" || true; done <"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" | wc -l | tr -d ' '); \
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg package_file_list "$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" \
		--argjson absolute_path_occurrences "$$absolute_path_occurrences" \
		--argjson user_path_occurrences "$$user_path_occurrences" \
		'{schema:"namei_ext.eval_osdi.c7_artifact_anonymization_checklist.v1", run_id:$$run_id, package_file_list:$$package_file_list, checked_absolute_home_paths:true, absolute_path_occurrences:$$absolute_path_occurrences, user_path_occurrences:$$user_path_occurrences, anonymization_checklist_gate_pass:($$absolute_path_occurrences == 0 and $$user_path_occurrences == 0), remaining_work:[(if $$absolute_path_occurrences == 0 then empty else "scrub absolute /home paths from packaged result files or document non-anonymous artifact policy" end)], detail:"Diagnostic anonymization checklist over the sanitized package root. Raw results outside the package root may retain host-specific provenance."}' \
		>"$(EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST)"
	rm -rf "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/.build/paper"
	$(MAKE) -C "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/docs/paper" check >"$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG)" 2>&1
	$(MAKE) -C "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/docs/paper" paper >>"$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG)" 2>&1
	test -s "$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_PDF)"
	test -s "$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/.build/paper/main.log"
	sha256sum \
		"$(EVAL_OSDI_C7_AUDIT_CLAIM_JSON)" \
		"$(EVAL_OSDI_C7_AUDIT_CLAIM_INPUTS_SHA256)" \
		"$(EVAL_OSDI_C7_AUDIT_C3_JSON)" \
		"$(EVAL_OSDI_C7_AUDIT_C5_JSON)" \
		"$(ROOT_DIR)/docs/paper/main.tex" \
		"$(ROOT_DIR)/docs/paper/sections/01-introduction.tex" \
		"$(ROOT_DIR)/docs/paper/sections/02-motivation.tex" \
		"$(ROOT_DIR)/docs/paper/sections/03-design.tex" \
		"$(ROOT_DIR)/docs/paper/sections/04-implementation.tex" \
		"$(ROOT_DIR)/docs/paper/sections/05-evaluation.tex" \
		"$(ROOT_DIR)/docs/paper/sections/06-related-work.tex" \
		"$(ROOT_DIR)/docs/paper/sections/07-limitations.tex" \
		"$(BUILD_ROOT)/paper/main.pdf" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_FILE_LIST)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_TAR_LIST)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST)" \
		"$(EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_PDF)" \
		"$(EVAL_OSDI_C7_AUDIT_PACKAGE_ROOT)/.build/paper/main.log" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_C7_AUDIT_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_C7_AUDIT_INPUTS_SHA256)" >/dev/null
	main_dirty=$$(test -s "$(EVAL_OSDI_C7_AUDIT_MAIN_STATUS)" && printf true || printf false); \
	kernel_dirty=$$(test -s "$(EVAL_OSDI_C7_AUDIT_KERNEL_STATUS)" && printf true || printf false); \
	main_dirty_count=$$(wc -l <"$(EVAL_OSDI_C7_AUDIT_MAIN_STATUS)" | tr -d ' '); \
	kernel_dirty_count=$$(wc -l <"$(EVAL_OSDI_C7_AUDIT_KERNEL_STATUS)" | tr -d ' '); \
	overfull_hbox_count=$$(grep -c 'Overfull \\hbox' "$(BUILD_ROOT)/paper/main.log" || true); \
	float_too_large_count=$$(grep -c 'Float too large' "$(BUILD_ROOT)/paper/main.log" || true); \
	jq -n -c \
		--slurpfile claim "$(EVAL_OSDI_C7_AUDIT_CLAIM_JSON)" \
		--slurpfile c3 "$(EVAL_OSDI_C7_AUDIT_C3_JSON)" \
		--slurpfile c5 "$(EVAL_OSDI_C7_AUDIT_C5_JSON)" \
		--slurpfile package "$(EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST)" \
		--slurpfile anonymization "$(EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST)" \
		--arg run_id "$(RUN_ID)" \
		--arg claim_run_id "$(EVAL_OSDI_C7_AUDIT_CLAIM_RUN_ID)" \
		--arg c3_run_id "$(EVAL_OSDI_C7_AUDIT_C3_RUN_ID)" \
		--arg c5_run_id "$(EVAL_OSDI_C7_AUDIT_C5_RUN_ID)" \
		--arg main_head "$$(git -C "$(ROOT_DIR)" rev-parse HEAD)" \
		--arg kernel_head "$$(git -C "$(KERNEL_DIR)" rev-parse HEAD)" \
		--arg paper_pdf "$(BUILD_ROOT)/paper/main.pdf" \
		--arg inputs_sha256 "$(EVAL_OSDI_C7_AUDIT_INPUTS_SHA256)" \
		--arg main_status "$(EVAL_OSDI_C7_AUDIT_MAIN_STATUS)" \
		--arg kernel_status "$(EVAL_OSDI_C7_AUDIT_KERNEL_STATUS)" \
		--arg package_manifest "$(EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST)" \
		--arg anonymization_checklist "$(EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST)" \
		--arg package_replay_log "$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG)" \
		--arg package_replay_pdf "$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_PDF)" \
		--argjson main_dirty "$$main_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
		--argjson main_dirty_count "$$main_dirty_count" \
		--argjson kernel_dirty_count "$$kernel_dirty_count" \
		--argjson overfull_hbox_count "$$overfull_hbox_count" \
		--argjson float_too_large_count "$$float_too_large_count" \
		'([$$claim[] | select(.event == "eval-osdi-claim-verdict-summary")][0] // {}) as $$cs | ([ $$c3[] | select(.event == "eval-osdi-c3-residual-diagnostic-summary") ][0] // {}) as $$c3s | ([ $$c5[] | select(.event == "eval-osdi-c5-rusage-nohook-ablation-summary") ][0] // {}) as $$c5s | ($$package[0] // {}) as $$pkg | ($$anonymization[0] // {}) as $$anon | ($$main_dirty == false and $$kernel_dirty == false) as $$clean_checkout | ($$float_too_large_count == 0) as $$paper_build_artifact_pass | ($$cs.weak_accept_ready == true and $$c3s.fuse_baseline_threshold_pass == true and $$c5s.c5_supported == false) as $$evidence_paths_pass | ($$pkg.package_manifest_gate_pass == true) as $$artifact_package_gate_pass | ($$anon.anonymization_checklist_gate_pass == true) as $$anonymization_checklist_gate_pass | true as $$artifact_package_replay_pass | {schema:"namei_ext.eval_osdi.c7_artifact_reproducibility_audit.v1", event:"eval-osdi-c7-artifact-reproducibility-audit-summary", run_id:$$run_id, result_level:"diagnostic_only_not_release_gate", claim_run_id:$$claim_run_id, c3_run_id:$$c3_run_id, c5_run_id:$$c5_run_id, main_repo:{head:$$main_head, dirty:$$main_dirty, dirty_entries:$$main_dirty_count, status_file:$$main_status}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty, dirty_entries:$$kernel_dirty_count, status_file:$$kernel_status}, paper:{pdf:$$paper_pdf, build_pass:true, check_pass:true, float_too_large_count:$$float_too_large_count, overfull_hbox_count:$$overfull_hbox_count}, evidence:{claim_weak_accept_ready:($$cs.weak_accept_ready // false), c3_fuse_baseline_threshold_pass:($$c3s.fuse_baseline_threshold_pass // false), c3_full_suite_supported:($$c3s.full_suite_c3_supported // false), c5_supported:($$c5s.c5_supported // false)}, artifact_package:{manifest:$$package_manifest, tar:($$pkg.package_tar // null), tar_sha256:($$pkg.package_tar_sha256 // null), declared_file_count:($$pkg.declared_file_count // 0), tar_entry_count:($$pkg.tar_entry_count // 0), replay_log:$$package_replay_log, replay_pdf:$$package_replay_pdf, replay_check_pass:true, replay_paper_pass:true}, anonymization:{checklist:$$anonymization_checklist, absolute_path_occurrences:($$anon.absolute_path_occurrences // 0), user_path_occurrences:($$anon.user_path_occurrences // 0)}, clean_checkout_gate_pass:$$clean_checkout, paper_build_artifact_pass:$$paper_build_artifact_pass, evidence_paths_pass:$$evidence_paths_pass, artifact_package_gate_pass:$$artifact_package_gate_pass, artifact_package_replay_pass:$$artifact_package_replay_pass, anonymization_checklist_gate_pass:$$anonymization_checklist_gate_pass, c7_supported:($$clean_checkout and $$paper_build_artifact_pass and $$evidence_paths_pass and $$artifact_package_gate_pass and $$artifact_package_replay_pass and $$anonymization_checklist_gate_pass), release_gate_pass:false, inputs_sha256_file:$$inputs_sha256, missing_evidence:[(if $$clean_checkout then empty else "clean checkout reproduction" end), (if $$artifact_package_gate_pass then empty else "artifact package manifest" end), (if $$artifact_package_replay_pass then empty else "artifact package paper replay" end), (if $$anonymization_checklist_gate_pass then empty else "artifact anonymization scrub" end), (if $$evidence_paths_pass then empty else "paper evidence path audit" end), (if $$paper_build_artifact_pass then empty else "paper build artifact without float errors" end)], detail:"C7 audit is diagnostic: current paper builds, evidence paths exist, and a declared sanitized artifact package can replay the paper build, but dirty worktrees keep reproducibility scoped out."}' \
		>"$(EVAL_OSDI_C7_AUDIT_JSON).tmp"
	mv "$(EVAL_OSDI_C7_AUDIT_JSON).tmp" "$(EVAL_OSDI_C7_AUDIT_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-c7-artifact-reproducibility-audit-summary" and .c7_supported == false and .release_gate_pass == false and .paper.build_pass == true and .evidence_paths_pass == true and .artifact_package_gate_pass == true and .artifact_package_replay_pass == true and .anonymization_checklist_gate_pass == true and .artifact_package.declared_file_count == 17 and .artifact_package.tar_entry_count == 17 and .artifact_package.replay_check_pass == true and .artifact_package.replay_paper_pass == true and .anonymization.absolute_path_occurrences == 0 and .anonymization.user_path_occurrences == 0 and (.missing_evidence | length) == 1 and (.missing_evidence | index("clean checkout reproduction")))] | length) == 1' "$(EVAL_OSDI_C7_AUDIT_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_C7_AUDIT_JSON)" \
		--arg inputs "$(EVAL_OSDI_C7_AUDIT_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_C7_AUDIT_SUMMARY)" \
		--arg package_manifest "$(EVAL_OSDI_C7_AUDIT_PACKAGE_MANIFEST)" \
		--arg anonymization_checklist "$(EVAL_OSDI_C7_AUDIT_ANONYMIZATION_CHECKLIST)" \
		--arg package_replay_log "$(EVAL_OSDI_C7_AUDIT_PACKAGE_REPLAY_LOG)" \
		--argjson c7_supported "$$(jq -s -r '.[] | select(.event == "eval-osdi-c7-artifact-reproducibility-audit-summary") | .c7_supported' "$(EVAL_OSDI_C7_AUDIT_JSON)")" \
		'{schema:"namei_ext.eval_osdi.c7_artifact_reproducibility_audit_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary, package_manifest:$$package_manifest, anonymization_checklist:$$anonymization_checklist, package_replay_log:$$package_replay_log}, gate:{c7_supported:$$c7_supported, release_gate_pass:false}}' \
		>"$(EVAL_OSDI_C7_AUDIT_MANIFEST)"
	printf '%s\n' '# OSDI C7 Artifact/Reproducibility Audit' >"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_C7_AUDIT_JSON)' >>"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_C7_AUDIT_INPUTS_SHA256)' >>"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"
	printf '\n%s\n' '## Verdict' >>"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-c7-artifact-reproducibility-audit-summary") | "- c7_supported=" + (.c7_supported|tostring) + "\n- clean_checkout_gate_pass=" + (.clean_checkout_gate_pass|tostring) + "\n- artifact_package_gate_pass=" + (.artifact_package_gate_pass|tostring) + "\n- artifact_package_replay_pass=" + (.artifact_package_replay_pass|tostring) + "\n- anonymization_checklist_gate_pass=" + (.anonymization_checklist_gate_pass|tostring) + "\n- evidence_paths_pass=" + (.evidence_paths_pass|tostring) + "\n- paper_build_artifact_pass=" + (.paper_build_artifact_pass|tostring) + "\n- main_dirty_entries=" + (.main_repo.dirty_entries|tostring) + "\n- kernel_dirty_entries=" + (.kernel_repo.dirty_entries|tostring) + "\n- package_declared_file_count=" + (.artifact_package.declared_file_count|tostring) + "\n- package_tar_entry_count=" + (.artifact_package.tar_entry_count|tostring) + "\n- anonymization_absolute_path_occurrences=" + (.anonymization.absolute_path_occurrences|tostring) + "\n- missing_evidence=" + (.missing_evidence|join(", "))' "$(EVAL_OSDI_C7_AUDIT_JSON)" >>"$(EVAL_OSDI_C7_AUDIT_SUMMARY)"

eval-osdi-w2-tool-redirect-paper-release-gate:
	command -v jq >/dev/null
	command -v sha256sum >/dev/null
	test -n "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID)"
	test -n "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID)"
	test -n "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_INPUTS_SHA256)"
	test -s "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_FILTER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-06-17-w2-nginx-real-trace-gate.md"
	test -s "$(ROOT_DIR)/mk/eval_osdi.mk"
	install -d "$(EVAL_OSDI_PAPER_RELEASE_DIR)"
	jq -e -s '([.[] | select(.event == "w2-nginx-real-trace-summary" and .schema == "namei_ext.eval_osdi.w2_nginx_real_trace.v1" and .w2_real_trace_gate_pass == true and .no_real_production_open_pass == true)] | length) == 1' "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-w2-nginx-workload-macrobench-summary" and .schema == "namei_ext.eval_osdi.w2_nginx_workload_macrobench.v1" and .w2_c2_slice_supported == true)] | length) == 1' "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON)" >/dev/null
	jq -e -s '([.[] | select(.event == "eval-osdi-performance-tool-redirect-scope-summary" and .schema == "namei_ext.eval_osdi.performance_scope.v1" and .scoped_c3_supported == true)] | length) == 1' "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_INPUTS_SHA256)" >/dev/null
	sha256sum -c "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_INPUTS_SHA256)" >/dev/null
	sha256sum \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_INPUTS_SHA256)" \
		"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_FILTER)" \
		"$(ROOT_DIR)/docs/tmp/2026-06-17-w2-nginx-real-trace-gate.md" \
		"$(ROOT_DIR)/mk/eval_osdi.mk" \
		>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256)"
	sha256sum -c "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256)" >/dev/null
	jq -n -c \
		--slurpfile trace "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON)" \
		--slurpfile w2 "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON)" \
		--slurpfile scope "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg trace_run_id "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID)" \
		--arg w2_run_id "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID)" \
		--arg scope_run_id "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID)" \
		--arg trace_json "$(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_JSON)" \
		--arg w2_json "$(EVAL_OSDI_W2_TOOL_REDIRECT_W2_JSON)" \
		--arg scope_json "$(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_JSON)" \
		--arg inputs_sha256 "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256)" \
		-f "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_FILTER)" \
		>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON).tmp"
	mv "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON).tmp" "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)"
	jq -e -s '([.[] | select(.event == "eval-osdi-w2-tool-redirect-paper-release-summary" and .paper_release_gate_pass == true and .release_gate_pass == true and .scope == "w2_nginx_fixture_plus_tool_redirect_metadata")] | length) == 1' "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)" >/dev/null
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg json "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)" \
		--arg inputs "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256)" \
		--arg summary "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)" \
		--argjson paper_release_gate_pass "$$(jq -s -r '.[] | select(.event == "eval-osdi-w2-tool-redirect-paper-release-summary") | .paper_release_gate_pass' "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)")" \
		'{schema:"namei_ext.eval_osdi.w2_tool_redirect_paper_release_manifest.v1", run_id:$$run_id, generated_at:$$generated_at, artifacts:{json:$$json, inputs_sha256:$$inputs, summary:$$summary}, gate:{paper_release_gate_pass:$$paper_release_gate_pass, release_gate_pass:$$paper_release_gate_pass}}' \
		>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_MANIFEST)"
	printf '%s\n' '# W2 Tool-Redirect Paper Release Gate' >"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '%s\n' '- W2 trace run: $(EVAL_OSDI_W2_TOOL_REDIRECT_TRACE_RUN_ID)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '%s\n' '- W2 macrobench ledger run: $(EVAL_OSDI_W2_TOOL_REDIRECT_W2_RUN_ID)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '%s\n' '- Tool-redirect scope run: $(EVAL_OSDI_W2_TOOL_REDIRECT_SCOPE_RUN_ID)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '%s\n' '- Raw JSONL: $(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	printf '%s\n' '- Input sha256: $(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_INPUTS_SHA256)' >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"
	jq -s -r '.[] | select(.event == "eval-osdi-w2-tool-redirect-paper-release-summary") | "- paper_release_gate_pass=" + (.paper_release_gate_pass|tostring) + "\n- scope=" + .scope + "\n- w2_real_trace_gate_pass=" + (.w2_real_trace_gate_pass|tostring) + "\n- w2_c2_slice_supported=" + (.w2_c2_slice_supported|tostring) + "\n- tool_redirect_c3_supported=" + (.tool_redirect_c3_supported|tostring) + "\n- no_real_production_open_pass=" + (.no_real_production_open_pass|tostring) + "\n- endpoint_health_pass=" + (.endpoint_health_pass|tostring) + "\n- setup_latency_threshold_pass=" + (.setup_latency_threshold_pass|tostring) + "\n- update_latency_threshold_pass=" + (.update_latency_threshold_pass|tostring) + "\n- storage_footprint_pass=" + (.storage_footprint_pass|tostring) + "\n- update_materialization_threshold_pass=" + (.update_materialization_threshold_pass|tostring) + "\n- scoped_kernel_p99_threshold_pass=" + (.scoped_kernel_p99_threshold_pass|tostring) + "\n- scoped_fuse_speedup_threshold_pass=" + (.scoped_fuse_speedup_threshold_pass|tostring) + "\n- release_scope_boundaries=" + (.release_scope_boundaries|join("; "))' "$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_JSON)" >>"$(EVAL_OSDI_W2_TOOL_REDIRECT_RELEASE_SUMMARY)"

eval-osdi-performance: eval-osdi-performance-comparison
	jq -e -s '.[] | select(.event == "eval-osdi-performance-comparison-summary" and .release_gate_pass == true and .c2_supported == true and .c3_supported == true and .c5_supported == true)' "$(EVAL_OSDI_PERFORMANCE_COMPARISON_JSON)" >/dev/null

eval-osdi-paper: phase1 eval-osdi-policy-family eval-osdi-macrobench eval-osdi-workload-macrobench eval-osdi-performance

eval-osdi-paper-report: eval-osdi-paper
	printf '%s\n' '# OSDI Paper Evaluation Report' >"$(EVAL_OSDI_REPORT)"
	printf '\n%s\n' '- Run ID: $(RUN_ID)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- Phase 1 evidence run: $(EVAL_OSDI_PHASE1_RUN_ID)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- B12 policy-family ledger: $(EVAL_OSDI_POLICY_FAMILY_JSON)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- B12 policy-family input sha256: $(EVAL_OSDI_POLICY_FAMILY_INPUTS_SHA256)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- B2/B8 performance ledger: $(EVAL_OSDI_PERFORMANCE_JSON)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- B2/B8 performance input sha256: $(EVAL_OSDI_PERFORMANCE_INPUTS_SHA256)' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- Performance release gate pass: true' >>"$(EVAL_OSDI_REPORT)"
	printf '%s\n' '- Release gate pass: true' >>"$(EVAL_OSDI_REPORT)"
