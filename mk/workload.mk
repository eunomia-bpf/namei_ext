include $(ROOT_DIR)/configs/eval-osdi/workloads.mk
include $(ROOT_DIR)/configs/eval-osdi/workload-sources.mk

WORKLOAD_CACHE_ROOT ?= $(CACHE_ROOT)/workloads
WORKLOAD_BUILD_ROOT ?= $(BUILD_ROOT)/workloads
WORKLOAD_PROVENANCE_ROOT ?= $(RESULT_ROOT)/workloads/provenance
WORKLOAD_RUNS_ROOT ?= $(RESULT_ROOT)/workloads/runs
WORKLOAD_RESULT_ROOT ?= $(WORKLOAD_PROVENANCE_ROOT)
WORKLOAD_RUN_ROOT ?= $(WORKLOAD_RUNS_ROOT)/$(RUN_ID)

REDIS_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(REDIS_ARCHIVE_NAME)
REDIS_SRC := $(WORKLOAD_BUILD_ROOT)/$(REDIS_SOURCE_DIR_NAME)
REDIS_STAMP := $(REDIS_SRC)/.source.ok
REDIS_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/redis-source.json

NGINX_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(NGINX_ARCHIVE_NAME)
NGINX_SRC := $(WORKLOAD_BUILD_ROOT)/$(NGINX_SOURCE_DIR_NAME)
NGINX_STAMP := $(NGINX_SRC)/.source.ok
NGINX_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/nginx-source.json

POSTGRES_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(POSTGRES_ARCHIVE_NAME)
POSTGRES_SRC := $(WORKLOAD_BUILD_ROOT)/$(POSTGRES_SOURCE_DIR_NAME)
POSTGRES_STAMP := $(POSTGRES_SRC)/.source.ok
POSTGRES_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/postgres-source.json

PROMETHEUS_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(PROMETHEUS_ARCHIVE_NAME)
PROMETHEUS_SRC := $(WORKLOAD_BUILD_ROOT)/$(PROMETHEUS_SOURCE_DIR_NAME)
PROMETHEUS_STAMP := $(PROMETHEUS_SRC)/.source.ok
PROMETHEUS_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/prometheus-source.json

REDIS_BUILD_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-redis-build
REDIS_BUILD_SRC := $(REDIS_BUILD_WORK_ROOT)/src
REDIS_BUILD_STAMP := $(REDIS_BUILD_SRC)/.workload-source.ok
REDIS_BUILD_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w1-redis-build
REDIS_BUILD_LOG := $(REDIS_BUILD_RESULT_DIR)/build.log
REDIS_BUILD_JSON := $(REDIS_BUILD_RESULT_DIR)/build.json
REDIS_TRACE_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-redis-build-trace
REDIS_TRACE_SRC := $(REDIS_TRACE_WORK_ROOT)/src
REDIS_TRACE_STAMP := $(REDIS_TRACE_SRC)/.workload-source.ok
REDIS_TRACE_LOG := $(REDIS_BUILD_RESULT_DIR)/strace.log
REDIS_TRACE_JSON := $(REDIS_BUILD_RESULT_DIR)/trace.json
REDIS_MANIFEST_JSON := $(REDIS_BUILD_RESULT_DIR)/manifest.json
REDIS_ALIAS_MANIFEST_JSON := $(REDIS_BUILD_RESULT_DIR)/alias-manifest.json

NGINX_BUILD_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-nginx-build
NGINX_BUILD_SRC := $(NGINX_BUILD_WORK_ROOT)/src
NGINX_BUILD_PREFIX := $(NGINX_BUILD_WORK_ROOT)/install
NGINX_BUILD_STAMP := $(NGINX_BUILD_SRC)/.workload-source.ok
NGINX_BUILD_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w1-nginx-build
NGINX_CONFIGURE_LOG := $(NGINX_BUILD_RESULT_DIR)/configure.log
NGINX_BUILD_LOG := $(NGINX_BUILD_RESULT_DIR)/build.log
NGINX_BUILD_JSON := $(NGINX_BUILD_RESULT_DIR)/build.json
NGINX_TRACE_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-nginx-build-trace
NGINX_TRACE_SRC := $(NGINX_TRACE_WORK_ROOT)/src
NGINX_TRACE_PREFIX := $(NGINX_TRACE_WORK_ROOT)/install
NGINX_TRACE_STAMP := $(NGINX_TRACE_SRC)/.workload-source.ok
NGINX_TRACE_LOG := $(NGINX_BUILD_RESULT_DIR)/strace.log
NGINX_TRACE_JSON := $(NGINX_BUILD_RESULT_DIR)/trace.json
NGINX_MANIFEST_JSON := $(NGINX_BUILD_RESULT_DIR)/manifest.json
NGINX_ALIAS_MANIFEST_JSON := $(NGINX_BUILD_RESULT_DIR)/alias-manifest.json
W1_ORACLE_ENTRIES_TSV := $(WORKLOAD_RUN_ROOT)/w1-build-graph-oracle-entries.tsv
W1_BUILD_OUTPUT_ORACLE_JSON := $(WORKLOAD_RUN_ROOT)/w1-build-output-oracle.jsonl

NGINX_FIXTURE_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w2-nginx-fixture
NGINX_FIXTURE_MANIFEST_JSON := $(NGINX_FIXTURE_RESULT_DIR)/fixture-manifest.json
NGINX_FIXTURE_CONFIG := $(ROOT_DIR)/workload/w2-nginx-fixture/nginx.test.conf
NGINX_FIXTURE_CERT := $(NGINX_FIXTURE_RESULT_DIR)/server.fake.crt
NGINX_FIXTURE_ENDPOINT := $(NGINX_FIXTURE_RESULT_DIR)/upstream.local
NGINX_FIXTURE_POISON := $(NGINX_FIXTURE_RESULT_DIR)/poison.secret
POSTGRES_FIXTURE_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w2-postgres-secret-fixture
POSTGRES_FIXTURE_MANIFEST_JSON := $(POSTGRES_FIXTURE_RESULT_DIR)/fixture-manifest.json
POSTGRES_FIXTURE_PASSWORD := $(POSTGRES_FIXTURE_RESULT_DIR)/db.fake.pass
W2_ORACLE_ENTRIES_TSV := $(WORKLOAD_RUN_ROOT)/w2-sandbox-fixture-oracle-entries.tsv

REDIS_CHECKPOINT_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w3-redis-podman-criu
REDIS_CHECKPOINT_MANIFEST_JSON := $(REDIS_CHECKPOINT_RESULT_DIR)/checkpoint-manifest.json
REDIS_CHECKPOINT_DUMP := $(REDIS_CHECKPOINT_RESULT_DIR)/dump.ckpt
REDIS_CHECKPOINT_AOF := $(REDIS_CHECKPOINT_RESULT_DIR)/aof.ckpt
REDIS_CHECKPOINT_SOCKET := $(REDIS_CHECKPOINT_RESULT_DIR)/redis.sock.new
REDIS_CHECKPOINT_POISON := $(REDIS_CHECKPOINT_RESULT_DIR)/poison.epoch
NGINX_CHECKPOINT_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w3-nginx-podman-criu
NGINX_CHECKPOINT_MANIFEST_JSON := $(NGINX_CHECKPOINT_RESULT_DIR)/checkpoint-manifest.json
NGINX_CHECKPOINT_CACHE := $(NGINX_CHECKPOINT_RESULT_DIR)/cache.ckpt
NGINX_CHECKPOINT_PID := $(NGINX_CHECKPOINT_RESULT_DIR)/nginx.pid.new
W3_PODMAN_CRIU_CAPABILITY_DIR := $(WORKLOAD_RUN_ROOT)/w3-podman-criu-capability
W3_PODMAN_CRIU_CAPABILITY_JSON := $(W3_PODMAN_CRIU_CAPABILITY_DIR)/capability.jsonl
W3_ORACLE_ENTRIES_TSV := $(WORKLOAD_RUN_ROOT)/w3-checkpoint-oracle-entries.tsv

CCACHE_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w4-ccache-redis-nginx
CCACHE_MANIFEST_JSON := $(CCACHE_RESULT_DIR)/cache-manifest.json
CCACHE_OBJECT_LOCAL := $(CCACHE_RESULT_DIR)/object.local
CCACHE_STALE_CANON := $(CCACHE_RESULT_DIR)/stale.canon
CCACHE_CORRUPT_REJECT := $(CCACHE_RESULT_DIR)/corrupt.reject
BUILDKIT_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w4-buildkit-prometheus-go-cache
BUILDKIT_MANIFEST_JSON := $(BUILDKIT_RESULT_DIR)/cache-manifest.json
BUILDKIT_PKG_CANON := $(BUILDKIT_RESULT_DIR)/pkg.canon
W4_ORACLE_ENTRIES_TSV := $(WORKLOAD_RUN_ROOT)/w4-cache-oracle-entries.tsv

WORKLOAD_SOURCE_STAMPS := \
	$(REDIS_STAMP) \
	$(NGINX_STAMP) \
	$(POSTGRES_STAMP) \
	$(PROMETHEUS_STAMP)

WORKLOAD_PROVENANCE_FILES := \
	$(REDIS_PROVENANCE) \
	$(NGINX_PROVENANCE) \
	$(POSTGRES_PROVENANCE) \
	$(PROMETHEUS_PROVENANCE)

.PHONY: workloads workload-fetch workload-provenance workload-clean \
	workload-redis-build-fetch workload-nginx-build-fetch \
	workload-postgres-fixture-fetch workload-prometheus-go-cache-fetch \
	workload-build-graph workload-redis-build workload-redis-build-trace \
	workload-redis-build-manifest workload-redis-build-alias-manifest \
	workload-w1-build-output-oracle \
	workload-nginx-build workload-nginx-build-trace \
	workload-nginx-build-manifest workload-nginx-build-alias-manifest \
	workload-sandbox-fixture workload-nginx-fixture-manifest \
	workload-postgres-fixture-manifest workload-w1-oracle-entries \
	workload-w2-oracle-entries workload-checkpoint-restore \
	workload-redis-checkpoint-manifest workload-nginx-checkpoint-manifest \
	workload-w3-podman-criu-capability \
	workload-w3-oracle-entries workload-cache-locality \
	workload-ccache-manifest workload-buildkit-manifest \
	workload-w4-oracle-entries \
	workload-clean-results

.PHONY: FORCE
FORCE:

workloads: workload-provenance workload-build-graph workload-sandbox-fixture workload-checkpoint-restore workload-cache-locality

workload-fetch: $(WORKLOAD_SOURCE_STAMPS)

workload-provenance: $(WORKLOAD_PROVENANCE_FILES)

workload-redis-build-fetch: $(REDIS_PROVENANCE)

workload-nginx-build-fetch: $(NGINX_PROVENANCE)

workload-postgres-fixture-fetch: $(POSTGRES_PROVENANCE)

workload-prometheus-go-cache-fetch: $(PROMETHEUS_PROVENANCE)

workload-build-graph: workload-redis-build-alias-manifest workload-nginx-build-alias-manifest workload-w1-build-output-oracle

workload-sandbox-fixture: workload-nginx-fixture-manifest workload-postgres-fixture-manifest

workload-checkpoint-restore: workload-redis-checkpoint-manifest workload-nginx-checkpoint-manifest

workload-cache-locality: workload-ccache-manifest workload-buildkit-manifest

workload-w1-oracle-entries: $(W1_ORACLE_ENTRIES_TSV)

workload-w1-build-output-oracle: $(W1_BUILD_OUTPUT_ORACLE_JSON)

workload-w2-oracle-entries: $(W2_ORACLE_ENTRIES_TSV)

workload-w3-oracle-entries: $(W3_ORACLE_ENTRIES_TSV)

workload-w4-oracle-entries: $(W4_ORACLE_ENTRIES_TSV)

workload-redis-build: $(REDIS_BUILD_JSON)

workload-redis-build-trace: $(REDIS_TRACE_JSON)

workload-redis-build-manifest: $(REDIS_MANIFEST_JSON)

workload-redis-build-alias-manifest: $(REDIS_ALIAS_MANIFEST_JSON)

workload-nginx-build: $(NGINX_BUILD_JSON)

workload-nginx-build-trace: $(NGINX_TRACE_JSON)

workload-nginx-build-manifest: $(NGINX_MANIFEST_JSON)

workload-nginx-build-alias-manifest: $(NGINX_ALIAS_MANIFEST_JSON)

workload-nginx-fixture-manifest: $(NGINX_FIXTURE_MANIFEST_JSON)

workload-postgres-fixture-manifest: $(POSTGRES_FIXTURE_MANIFEST_JSON)

workload-redis-checkpoint-manifest: $(REDIS_CHECKPOINT_MANIFEST_JSON)

workload-nginx-checkpoint-manifest: $(NGINX_CHECKPOINT_MANIFEST_JSON)

workload-w3-podman-criu-capability: $(W3_PODMAN_CRIU_CAPABILITY_JSON)

workload-ccache-manifest: $(CCACHE_MANIFEST_JSON)

workload-buildkit-manifest: $(BUILDKIT_MANIFEST_JSON)

$(WORKLOAD_CACHE_ROOT) $(WORKLOAD_BUILD_ROOT) $(WORKLOAD_RESULT_ROOT):
	install -d "$@"

$(WORKLOAD_RUN_ROOT) $(REDIS_BUILD_RESULT_DIR) $(NGINX_BUILD_RESULT_DIR) $(NGINX_FIXTURE_RESULT_DIR) $(POSTGRES_FIXTURE_RESULT_DIR) $(REDIS_CHECKPOINT_RESULT_DIR) $(NGINX_CHECKPOINT_RESULT_DIR) $(W3_PODMAN_CRIU_CAPABILITY_DIR) $(CCACHE_RESULT_DIR) $(BUILDKIT_RESULT_DIR):
	install -d "$@"

$(W3_PODMAN_CRIU_CAPABILITY_JSON): FORCE $(ROOT_DIR)/mk/workload.mk | $(W3_PODMAN_CRIU_CAPABILITY_DIR)
	rm -f "$@.tmp" "$@"
	printf '{"event":"w3-podman-criu-capability-start","run_id":"%s","result_level":"host_capability_audit"}\n' "$(RUN_ID)" >"$@.tmp"
	podman_path=$$(command -v podman 2>/dev/null || true); \
	criu_path=$$(command -v criu 2>/dev/null || true); \
	podman_present=false; \
	criu_present=false; \
	podman_version_ok=false; \
	criu_version_ok=false; \
	podman_checkpoint_help_ok=false; \
	podman_checkpoint_listed=false; \
	if test -n "$$podman_path"; then \
		podman_present=true; \
		if podman --version >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-version.stdout" 2>"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-version.stderr"; then \
			podman_version_ok=true; \
		fi; \
		if podman checkpoint --help >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-checkpoint-help.stdout" 2>"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-checkpoint-help.stderr"; then \
			podman_checkpoint_help_ok=true; \
		fi; \
		if grep -Eq '(^|[[:space:]])checkpoint([[:space:]]|$$)' "$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-checkpoint-help.stdout"; then \
			podman_checkpoint_listed=true; \
		fi; \
	else \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-version.stdout"; \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-version.stderr"; \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-checkpoint-help.stdout"; \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/podman-checkpoint-help.stderr"; \
	fi; \
	if test -n "$$criu_path"; then \
		criu_present=true; \
		if criu --version >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/criu-version.stdout" 2>"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/criu-version.stderr"; then \
			criu_version_ok=true; \
		fi; \
	else \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/criu-version.stdout"; \
		: >"$(W3_PODMAN_CRIU_CAPABILITY_DIR)/criu-version.stderr"; \
	fi; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--arg podman_path "$$podman_path" \
		--arg criu_path "$$criu_path" \
		--argjson podman_present "$$podman_present" \
		--argjson criu_present "$$criu_present" \
		--argjson podman_version_ok "$$podman_version_ok" \
		--argjson criu_version_ok "$$criu_version_ok" \
		--argjson podman_checkpoint_help_ok "$$podman_checkpoint_help_ok" \
		--argjson podman_checkpoint_listed "$$podman_checkpoint_listed" \
		'{schema:"namei_ext.w3_podman_criu_capability.v1", event:"w3-podman-criu-capability", run_id:$$run_id, result_level:"host_capability_audit", run_environment:"host", policy_executed:false, kvm_validated:false, podman_present:$$podman_present, podman_path:$$podman_path, podman_version_ok:$$podman_version_ok, podman_checkpoint_help_ok:$$podman_checkpoint_help_ok, podman_checkpoint_listed:$$podman_checkpoint_listed, criu_present:$$criu_present, criu_path:$$criu_path, criu_version_ok:$$criu_version_ok, podman_version_stdout:"podman-version.stdout", podman_version_stderr:"podman-version.stderr", podman_checkpoint_help_stdout:"podman-checkpoint-help.stdout", podman_checkpoint_help_stderr:"podman-checkpoint-help.stderr", criu_version_stdout:"criu-version.stdout", criu_version_stderr:"criu-version.stderr", pass:($$podman_present and $$podman_version_ok and $$podman_checkpoint_help_ok and $$podman_checkpoint_listed and $$criu_present and $$criu_version_ok), qualified_for_c8:false, detail:(if $$podman_present and $$podman_version_ok and $$podman_checkpoint_help_ok and $$podman_checkpoint_listed and $$criu_present and $$criu_version_ok then "Podman checkpoint and CRIU capability available for future W3 real restore run" else "Podman/CRIU capability missing or checkpoint command unavailable; W3 real restore cannot be claimed from this host audit" end)}' >>"$@.tmp"; \
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--slurpfile rows "$@.tmp" \
		'{schema:"namei_ext.w3_podman_criu_capability.v1", event:"w3-podman-criu-capability-summary", run_id:$$run_id, result_level:"host_capability_audit", run_environment:"host", policy_executed:false, kvm_validated:false, pass:($$rows | map(select(.event == "w3-podman-criu-capability" and .pass == true)) | length == 1), failures:(if ($$rows | map(select(.event == "w3-podman-criu-capability" and .pass == true)) | length == 1) then 0 else 1 end), qualified_for_c8:false, detail:(if ($$rows | map(select(.event == "w3-podman-criu-capability" and .pass == true)) | length == 1) then "host capability audit is ready for a future KVM real restore target" else "host capability audit failed; preserve raw stdout/stderr and keep W3 real restore blocked" end)}' >>"$@.tmp"
	mv -f "$@.tmp" "$@"
	jq -e -s '.[] | select(.event == "w3-podman-criu-capability-summary" and .pass == true and .failures == 0)' "$@" >/dev/null

$(W1_ORACLE_ENTRIES_TSV): $(REDIS_ALIAS_MANIFEST_JSON) $(NGINX_ALIAS_MANIFEST_JSON) | $(WORKLOAD_RUN_ROOT)
	rm -f "$@.tmp" "$@"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(REDIS_ALIAS_MANIFEST_JSON)" >"$@.tmp"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(NGINX_ALIAS_MANIFEST_JSON)" >>"$@.tmp"
	test "$$(wc -l <"$@.tmp")" -ge 8
	awk -F '\t' 'NF != 8 { exit 1 } $$5 == "" || $$6 == "" || $$7 == "" || $$8 == "" { exit 1 }' "$@.tmp"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$@.tmp"
	mv -f "$@.tmp" "$@"

$(W1_BUILD_OUTPUT_ORACLE_JSON): $(REDIS_BUILD_JSON) $(REDIS_TRACE_JSON) $(REDIS_MANIFEST_JSON) $(NGINX_BUILD_JSON) $(NGINX_TRACE_JSON) $(NGINX_MANIFEST_JSON) $(ROOT_DIR)/mk/workload.mk | $(WORKLOAD_RUN_ROOT)
	rm -f "$@.tmp" "$@.summary" "$@"
	for json in "$(REDIS_BUILD_JSON)" "$(REDIS_TRACE_JSON)" "$(NGINX_BUILD_JSON)" "$(NGINX_TRACE_JSON)"; do \
		binary=$$(jq -r '.artifacts.binary' "$$json"); \
		sha=$$(jq -r '.artifacts.binary_sha256' "$$json"); \
		test -x "$$binary"; \
		printf '%s  %s\n' "$$sha" "$$binary" | sha256sum -c - >/dev/null; \
	done
	jq -cn \
		--slurpfile build "$(REDIS_BUILD_JSON)" \
		--slurpfile trace "$(REDIS_TRACE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-redis-build" \
		--arg manifest "$(REDIS_MANIFEST_JSON)" \
		--arg manifest_sha256 "$$(sha256sum "$(REDIS_MANIFEST_JSON)" | awk '{print $$1}')" \
		'{schema:"namei_ext.w1_build_output_oracle.v1", event:"w1-build-output", run_id:$$run_id, workload_id:$$workload_id, policy_family:"build_graph_view.bpf.c", result_level:"host_real_build_output_oracle", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, host_output_hash_oracle:true, release_output_hash_oracle:false, output_hash_oracle_scope:"host", qualified_for_c8:false, pass:(($$build[0].schema == "namei_ext.real_workload_build.v1") and ($$trace[0].schema == "namei_ext.real_workload_trace.v1") and (($$build[0].artifacts.binary_sha256 // "") | test("^[0-9a-f]{64}$$")) and (($$trace[0].artifacts.binary_sha256 // "") | test("^[0-9a-f]{64}$$")) and (($$build[0].duration_ns // 0) > 0) and (($$trace[0].duration_ns // 0) > 0) and (($$trace[0].file_op_lines // 0) > 1000)), build:{binary:$$build[0].artifacts.binary, binary_sha256:$$build[0].artifacts.binary_sha256, duration_ns:$$build[0].duration_ns, log_sha256:$$build[0].artifacts.log_sha256}, trace:{binary:$$trace[0].artifacts.binary, binary_sha256:$$trace[0].artifacts.binary_sha256, duration_ns:$$trace[0].duration_ns, file_op_lines:$$trace[0].file_op_lines, strace_sha256:$$trace[0].artifacts.strace_sha256}, source_manifest:{path:$$manifest, sha256:$$manifest_sha256}, c1_c8_gate:"not_validated_until_kvm_policy_build_replay_trace_level_poison_oracle_and_table_counterfactual_pass", detail:"host real Redis source build produced auditable binary hashes; this is not KVM policy replay"}' \
		>"$@.tmp"
	jq -cn \
		--slurpfile build "$(NGINX_BUILD_JSON)" \
		--slurpfile trace "$(NGINX_TRACE_JSON)" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-nginx-build" \
		--arg manifest "$(NGINX_MANIFEST_JSON)" \
		--arg manifest_sha256 "$$(sha256sum "$(NGINX_MANIFEST_JSON)" | awk '{print $$1}')" \
		'{schema:"namei_ext.w1_build_output_oracle.v1", event:"w1-build-output", run_id:$$run_id, workload_id:$$workload_id, policy_family:"build_graph_view.bpf.c", result_level:"host_real_build_output_oracle", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, host_output_hash_oracle:true, release_output_hash_oracle:false, output_hash_oracle_scope:"host", qualified_for_c8:false, pass:(($$build[0].schema == "namei_ext.real_workload_build.v1") and ($$trace[0].schema == "namei_ext.real_workload_trace.v1") and (($$build[0].artifacts.binary_sha256 // "") | test("^[0-9a-f]{64}$$")) and (($$trace[0].artifacts.binary_sha256 // "") | test("^[0-9a-f]{64}$$")) and (($$build[0].duration_ns // 0) > 0) and (($$trace[0].duration_ns // 0) > 0) and (($$trace[0].file_op_lines // 0) > 1000)), build:{binary:$$build[0].artifacts.binary, binary_sha256:$$build[0].artifacts.binary_sha256, duration_ns:$$build[0].duration_ns, configure_log_sha256:$$build[0].artifacts.configure_log_sha256, build_log_sha256:$$build[0].artifacts.build_log_sha256}, trace:{binary:$$trace[0].artifacts.binary, binary_sha256:$$trace[0].artifacts.binary_sha256, duration_ns:$$trace[0].duration_ns, file_op_lines:$$trace[0].file_op_lines, strace_sha256:$$trace[0].artifacts.strace_sha256}, source_manifest:{path:$$manifest, sha256:$$manifest_sha256}, c1_c8_gate:"not_validated_until_kvm_policy_build_replay_trace_level_poison_oracle_and_table_counterfactual_pass", detail:"host real nginx source build produced auditable binary hashes; this is not KVM policy replay"}' \
		>>"$@.tmp"
	jq -cs \
		--arg run_id "$(RUN_ID)" \
		'{schema:"namei_ext.w1_build_output_oracle.v1", event:"w1-build-output-summary", run_id:$$run_id, result_level:"host_real_build_output_oracle", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, host_output_hash_oracle:true, release_output_hash_oracle:false, output_hash_oracle_scope:"host", qualified_for_c8:false, pass:((length == 2) and all(.[]; .event == "w1-build-output" and .pass == true)), workloads:(map(.workload_id) | sort), failures:(map(select(.pass != true)) | length), detail:"host Redis/nginx real source builds produced auditable output hashes; still not C1/C8 without KVM policy build replay and table/update counterfactual"}' \
		"$@.tmp" >"$@.summary"
	cat "$@.summary" >>"$@.tmp"
	jq -e -s 'length == 3 and ([.[] | select(.event == "w1-build-output" and .pass == true)] | length) == 2 and ([.[] | select(.event == "w1-build-output-summary" and .pass == true and .qualified_for_c8 == false)] | length) == 1 and all(.[]; .schema == "namei_ext.w1_build_output_oracle.v1" and .run_id == "$(RUN_ID)" and (.event == "w1-build-output" or .event == "w1-build-output-summary") and .result_level == "host_real_build_output_oracle" and .run_environment == "host" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .host_output_hash_oracle == true and .release_output_hash_oracle == false and .output_hash_oracle_scope == "host" and .qualified_for_c8 == false and .pass == true)' "$@.tmp" >/dev/null || { rm -f "$@.tmp" "$@.summary"; exit 1; }
	mv -f "$@.tmp" "$@"
	rm -f "$@.summary"

$(NGINX_FIXTURE_MANIFEST_JSON): $(NGINX_PROVENANCE) $(ROOT_DIR)/mk/workload.mk $(NGINX_FIXTURE_CONFIG) | $(NGINX_FIXTURE_RESULT_DIR)
	test -f "$(NGINX_SRC)/conf/nginx.conf"
	test -f "$(NGINX_FIXTURE_CONFIG)"
	printf '%s\n' 'namei-ext fake certificate for nginx fixture' >"$(NGINX_FIXTURE_CERT)"
	printf '%s\n' 'proxy_pass http://127.0.0.1:18080;' >"$(NGINX_FIXTURE_ENDPOINT)"
	printf '%s\n' 'NAMEI_EXT_POISON_SENTINEL' >"$(NGINX_FIXTURE_POISON)"
	jq -n \
		--slurpfile provenance "$(NGINX_PROVENANCE)" \
		--arg schema "namei_ext.fixture_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w2-nginx-fixture" \
		--arg policy_family "sandbox_fixture_view.bpf.c" \
		--arg make_target "workload-nginx-fixture-manifest" \
		--arg upstream_sample_config "$(NGINX_SRC)/conf/nginx.conf" \
		--arg upstream_sample_config_sha256 "$$(sha256sum "$(NGINX_SRC)/conf/nginx.conf" | awk '{print $$1}')" \
		--arg fixture_config "$(NGINX_FIXTURE_CONFIG)" \
		--arg fixture_config_sha256 "$$(sha256sum "$(NGINX_FIXTURE_CONFIG)" | awk '{print $$1}')" \
		--arg fixture_cert "$(NGINX_FIXTURE_CERT)" \
		--arg fixture_cert_sha256 "$$(sha256sum "$(NGINX_FIXTURE_CERT)" | awk '{print $$1}')" \
		--arg endpoint_fixture "$(NGINX_FIXTURE_ENDPOINT)" \
		--arg endpoint_fixture_sha256 "$$(sha256sum "$(NGINX_FIXTURE_ENDPOINT)" | awk '{print $$1}')" \
		--arg poison_fixture "$(NGINX_FIXTURE_POISON)" \
		--arg poison_fixture_sha256 "$$(sha256sum "$(NGINX_FIXTURE_POISON)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"fixture_witness", result_level:"host_fixture_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:$$provenance[0], real_source_inputs:{upstream_sample_config:$$upstream_sample_config, upstream_sample_config_sha256:$$upstream_sample_config_sha256}, generator:{make_target:$$make_target}, candidate_entries:[{branch:"config", parent_relative:"conf", visible_component:"nginx.conf", shadow_backing_component:"nginx.test.conf", original_backing_path:$$fixture_config, original_backing_sha256:$$fixture_config_sha256, source:"workload/w2-nginx-fixture nginx test config derived from nginx docs and pinned upstream source provenance", events:["lookup","readdir"]}, {branch:"certificate", parent_relative:"conf", visible_component:"server.crt", shadow_backing_component:"server.fake.crt", original_backing_path:$$fixture_cert, original_backing_sha256:$$fixture_cert_sha256, source:"make-owned fake certificate fixture", events:["lookup","readdir"]}, {branch:"endpoint", parent_relative:"conf", visible_component:"upstream.sock", shadow_backing_component:"upstream.local", original_backing_path:$$endpoint_fixture, original_backing_sha256:$$endpoint_fixture_sha256, source:"make-owned local endpoint fixture", events:["lookup","readdir"]}, {branch:"poison", parent_relative:"conf", visible_component:"prod.token", shadow_backing_component:"poison.secret", original_backing_path:$$poison_fixture, original_backing_sha256:$$poison_fixture_sha256, source:"make-owned poison sentinel", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{config:true, certificate:true, endpoint:true, poison:true, secret:false, pass_through:false}, missing_branches:["secret","pass_through"], missing_branch_reason:"nginx fixture witness does not cover PostgreSQL secret or generic pass-through"}, c1_c8_gate:"not_validated_until_kvm_policy_oracle_service_health_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.fixture_witness_manifest.v1" and .status == "fixture_witness" and .result_level == "host_fixture_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 4 and .semantic_witness.branch_coverage.config == true and .semantic_witness.branch_coverage.certificate == true and .semantic_witness.branch_coverage.endpoint == true and .semantic_witness.branch_coverage.poison == true and (.candidate_entries[] | select(.branch == "config") | .original_backing_path == "$(NGINX_FIXTURE_CONFIG)") and (.real_source_inputs.upstream_sample_config_sha256 | length) == 64 and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(POSTGRES_FIXTURE_MANIFEST_JSON): $(POSTGRES_PROVENANCE) $(ROOT_DIR)/mk/workload.mk | $(POSTGRES_FIXTURE_RESULT_DIR)
	test -f "$(POSTGRES_SRC)/src/backend/utils/misc/postgresql.conf.sample"
	printf '%s\n' 'namei_ext_fake_password' >"$(POSTGRES_FIXTURE_PASSWORD)"
	jq -n \
		--slurpfile provenance "$(POSTGRES_PROVENANCE)" \
		--arg schema "namei_ext.fixture_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w2-postgres-secret-fixture" \
		--arg policy_family "sandbox_fixture_view.bpf.c" \
		--arg make_target "workload-postgres-fixture-manifest" \
		--arg sample_config "$(POSTGRES_SRC)/src/backend/utils/misc/postgresql.conf.sample" \
		--arg sample_config_sha256 "$$(sha256sum "$(POSTGRES_SRC)/src/backend/utils/misc/postgresql.conf.sample" | awk '{print $$1}')" \
		--arg fake_password "$(POSTGRES_FIXTURE_PASSWORD)" \
		--arg fake_password_sha256 "$$(sha256sum "$(POSTGRES_FIXTURE_PASSWORD)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"fixture_witness", result_level:"host_fixture_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:$$provenance[0], generator:{make_target:$$make_target}, candidate_entries:[{branch:"service_config", parent_relative:"conf", visible_component:"postgresql.conf", shadow_backing_component:"postgres.test.conf", original_backing_path:$$sample_config, original_backing_sha256:$$sample_config_sha256, source:"PostgreSQL upstream sample config", events:["lookup","readdir"]}, {branch:"secret", parent_relative:"conf", visible_component:"db.password", shadow_backing_component:"db.fake.pass", original_backing_path:$$fake_password, original_backing_sha256:$$fake_password_sha256, source:"make-owned fake password fixture", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{service_config:true, secret:true, config:false, certificate:false, endpoint:false, poison:false, pass_through:false}, missing_branches:["config","certificate","endpoint","poison","pass_through"], missing_branch_reason:"PostgreSQL fixture witness contributes service_config and secret branches; nginx fixture contributes config/certificate/endpoint/poison"}, c1_c8_gate:"not_validated_until_kvm_policy_oracle_service_health_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.fixture_witness_manifest.v1" and .status == "fixture_witness" and .result_level == "host_fixture_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 2 and .semantic_witness.branch_coverage.service_config == true and .semantic_witness.branch_coverage.secret == true and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(W2_ORACLE_ENTRIES_TSV): $(NGINX_FIXTURE_MANIFEST_JSON) $(POSTGRES_FIXTURE_MANIFEST_JSON) | $(WORKLOAD_RUN_ROOT)
	rm -f "$@.tmp" "$@"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(NGINX_FIXTURE_MANIFEST_JSON)" >"$@.tmp"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(POSTGRES_FIXTURE_MANIFEST_JSON)" >>"$@.tmp"
	test "$$(wc -l <"$@.tmp")" = "6"
	awk -F '\t' 'NF != 8 { exit 1 } $$5 == "" || $$6 == "" || $$7 == "" || $$8 == "" { exit 1 }' "$@.tmp"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$@.tmp"
	mv -f "$@.tmp" "$@"

$(REDIS_CHECKPOINT_MANIFEST_JSON): $(REDIS_PROVENANCE) $(ROOT_DIR)/mk/workload.mk | $(REDIS_CHECKPOINT_RESULT_DIR)
	test -f "$(REDIS_SRC)/redis.conf"
	printf '%s\n' 'namei_ext redis checkpoint RDB fixture' >"$(REDIS_CHECKPOINT_DUMP)"
	printf '%s\n' 'namei_ext redis checkpoint AOF fixture' >"$(REDIS_CHECKPOINT_AOF)"
	printf '%s\n' 'namei_ext redis restored socket fixture' >"$(REDIS_CHECKPOINT_SOCKET)"
	printf '%s\n' 'NAMEI_EXT_MIXED_EPOCH_POISON' >"$(REDIS_CHECKPOINT_POISON)"
	jq -n \
		--slurpfile provenance "$(REDIS_PROVENANCE)" \
		--arg schema "namei_ext.checkpoint_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w3-redis-podman-criu" \
		--arg policy_family "checkpoint_restore_view.bpf.c" \
		--arg make_target "workload-redis-checkpoint-manifest" \
		--arg redis_conf "$(REDIS_SRC)/redis.conf" \
		--arg redis_conf_sha256 "$$(sha256sum "$(REDIS_SRC)/redis.conf" | awk '{print $$1}')" \
		--arg dump "$(REDIS_CHECKPOINT_DUMP)" \
		--arg dump_sha256 "$$(sha256sum "$(REDIS_CHECKPOINT_DUMP)" | awk '{print $$1}')" \
		--arg aof "$(REDIS_CHECKPOINT_AOF)" \
		--arg aof_sha256 "$$(sha256sum "$(REDIS_CHECKPOINT_AOF)" | awk '{print $$1}')" \
		--arg socket "$(REDIS_CHECKPOINT_SOCKET)" \
		--arg socket_sha256 "$$(sha256sum "$(REDIS_CHECKPOINT_SOCKET)" | awk '{print $$1}')" \
		--arg poison "$(REDIS_CHECKPOINT_POISON)" \
		--arg poison_sha256 "$$(sha256sum "$(REDIS_CHECKPOINT_POISON)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"checkpoint_witness", result_level:"host_checkpoint_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:$$provenance[0], generator:{make_target:$$make_target}, real_source_inputs:{redis_conf:$$redis_conf, redis_conf_sha256:$$redis_conf_sha256}, candidate_entries:[{branch:"state_rdb", parent_relative:"checkpoint", visible_component:"dump.rdb", shadow_backing_component:"dump.ckpt", original_backing_path:$$dump, original_backing_sha256:$$dump_sha256, source:"make-owned Redis checkpoint state fixture derived from fixed Redis source provenance", events:["lookup","readdir"]}, {branch:"state_aof", parent_relative:"checkpoint", visible_component:"appendonly.aof", shadow_backing_component:"aof.ckpt", original_backing_path:$$aof, original_backing_sha256:$$aof_sha256, source:"make-owned Redis checkpoint AOF fixture derived from fixed Redis source provenance", events:["lookup","readdir"]}, {branch:"runtime_socket", parent_relative:"runtime", visible_component:"redis.sock", shadow_backing_component:"redis.sock.new", original_backing_path:$$socket, original_backing_sha256:$$socket_sha256, source:"make-owned restored runtime socket fixture", events:["lookup","readdir"]}, {branch:"mixed_epoch_poison", parent_relative:"checkpoint", visible_component:"epoch.bad", shadow_backing_component:"poison.epoch", original_backing_path:$$poison, original_backing_sha256:$$poison_sha256, source:"make-owned mixed-epoch poison fixture", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{state:true, runtime:true, mixed_epoch:true, config:false, cache:false}, missing_branches:["config","cache","post_restore_trace"], missing_branch_reason:"current W3 path oracle does not run CRIU/Podman restore or post-restore service trace"}, c1_c8_gate:"not_validated_until_real_restore_health_trace_epoch_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.checkpoint_witness_manifest.v1" and .status == "checkpoint_witness" and .result_level == "host_checkpoint_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 4 and .semantic_witness.branch_coverage.state == true and .semantic_witness.branch_coverage.runtime == true and .semantic_witness.branch_coverage.mixed_epoch == true and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(NGINX_CHECKPOINT_MANIFEST_JSON): $(NGINX_PROVENANCE) $(ROOT_DIR)/mk/workload.mk | $(NGINX_CHECKPOINT_RESULT_DIR)
	test -f "$(NGINX_SRC)/conf/nginx.conf"
	printf '%s\n' 'namei_ext nginx checkpoint cache fixture' >"$(NGINX_CHECKPOINT_CACHE)"
	printf '%s\n' 'namei_ext nginx restored pid fixture' >"$(NGINX_CHECKPOINT_PID)"
	jq -n \
		--slurpfile provenance "$(NGINX_PROVENANCE)" \
		--arg schema "namei_ext.checkpoint_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w3-nginx-podman-criu" \
		--arg policy_family "checkpoint_restore_view.bpf.c" \
		--arg make_target "workload-nginx-checkpoint-manifest" \
		--arg nginx_conf "$(NGINX_SRC)/conf/nginx.conf" \
		--arg nginx_conf_sha256 "$$(sha256sum "$(NGINX_SRC)/conf/nginx.conf" | awk '{print $$1}')" \
		--arg cache "$(NGINX_CHECKPOINT_CACHE)" \
		--arg cache_sha256 "$$(sha256sum "$(NGINX_CHECKPOINT_CACHE)" | awk '{print $$1}')" \
		--arg pid "$(NGINX_CHECKPOINT_PID)" \
		--arg pid_sha256 "$$(sha256sum "$(NGINX_CHECKPOINT_PID)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"checkpoint_witness", result_level:"host_checkpoint_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:$$provenance[0], generator:{make_target:$$make_target}, candidate_entries:[{branch:"config", parent_relative:"conf", visible_component:"nginx.conf", shadow_backing_component:"nginx.ckpt", original_backing_path:$$nginx_conf, original_backing_sha256:$$nginx_conf_sha256, source:"nginx upstream sample config as checkpoint config witness", events:["lookup","readdir"]}, {branch:"cache", parent_relative:"cache", visible_component:"cache.db", shadow_backing_component:"cache.ckpt", original_backing_path:$$cache, original_backing_sha256:$$cache_sha256, source:"make-owned nginx checkpoint cache fixture", events:["lookup","readdir"]}, {branch:"runtime_pid", parent_relative:"runtime", visible_component:"nginx.pid", shadow_backing_component:"nginx.pid.new", original_backing_path:$$pid, original_backing_sha256:$$pid_sha256, source:"make-owned restored runtime pid fixture", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{config:true, cache:true, runtime:true, state:false, mixed_epoch:false}, missing_branches:["state","mixed_epoch","post_restore_trace"], missing_branch_reason:"nginx checkpoint witness contributes config/cache/runtime; Redis witness contributes state/mixed-epoch"}, c1_c8_gate:"not_validated_until_real_restore_health_trace_epoch_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.checkpoint_witness_manifest.v1" and .status == "checkpoint_witness" and .result_level == "host_checkpoint_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 3 and .semantic_witness.branch_coverage.config == true and .semantic_witness.branch_coverage.cache == true and .semantic_witness.branch_coverage.runtime == true and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(W3_ORACLE_ENTRIES_TSV): $(REDIS_CHECKPOINT_MANIFEST_JSON) $(NGINX_CHECKPOINT_MANIFEST_JSON) | $(WORKLOAD_RUN_ROOT)
	rm -f "$@.tmp" "$@"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(REDIS_CHECKPOINT_MANIFEST_JSON)" >"$@.tmp"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(NGINX_CHECKPOINT_MANIFEST_JSON)" >>"$@.tmp"
	test "$$(wc -l <"$@.tmp")" = "7"
	awk -F '\t' 'NF != 8 { exit 1 } $$5 == "" || $$6 == "" || $$7 == "" || $$8 == "" { exit 1 }' "$@.tmp"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$@.tmp"
	mv -f "$@.tmp" "$@"

$(CCACHE_MANIFEST_JSON): $(REDIS_PROVENANCE) $(NGINX_PROVENANCE) $(ROOT_DIR)/mk/workload.mk | $(CCACHE_RESULT_DIR)
	test -f "$(REDIS_SRC)/src/server.c"
	test -f "$(NGINX_SRC)/src/core/nginx.c"
	printf 'redis server.c sha256 %s\n' "$$(sha256sum "$(REDIS_SRC)/src/server.c" | awk '{print $$1}')" >"$(CCACHE_OBJECT_LOCAL)"
	printf 'nginx canonical object sha256 %s\n' "$$(sha256sum "$(NGINX_SRC)/src/core/nginx.c" | awk '{print $$1}')" >"$(CCACHE_STALE_CANON)"
	printf '%s\n' 'NAMEI_EXT_CORRUPT_CACHE_REJECT' >"$(CCACHE_CORRUPT_REJECT)"
	jq -n \
		--slurpfile redis_provenance "$(REDIS_PROVENANCE)" \
		--slurpfile nginx_provenance "$(NGINX_PROVENANCE)" \
		--arg schema "namei_ext.cache_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w4-ccache-redis-nginx" \
		--arg policy_family "cache_locality_view.bpf.c" \
		--arg make_target "workload-ccache-manifest" \
		--arg object "$(CCACHE_OBJECT_LOCAL)" \
		--arg object_sha256 "$$(sha256sum "$(CCACHE_OBJECT_LOCAL)" | awk '{print $$1}')" \
		--arg stale "$(CCACHE_STALE_CANON)" \
		--arg stale_sha256 "$$(sha256sum "$(CCACHE_STALE_CANON)" | awk '{print $$1}')" \
		--arg reject "$(CCACHE_CORRUPT_REJECT)" \
		--arg reject_sha256 "$$(sha256sum "$(CCACHE_CORRUPT_REJECT)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"cache_witness", result_level:"host_cache_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:{redis:$$redis_provenance[0], nginx:$$nginx_provenance[0]}, generator:{make_target:$$make_target}, candidate_entries:[{branch:"verified_hit", parent_relative:"cache", visible_component:"object.o", shadow_backing_component:"object.local", original_backing_path:$$object, original_backing_sha256:$$object_sha256, source:"make-owned ccache local-hit fixture derived from Redis source hash", events:["lookup","readdir"]}, {branch:"stale_fallback", parent_relative:"cache", visible_component:"stale.o", shadow_backing_component:"stale.canon", original_backing_path:$$stale, original_backing_sha256:$$stale_sha256, source:"make-owned canonical fallback fixture derived from nginx source hash", events:["lookup","readdir"]}, {branch:"corrupt_reject", parent_relative:"cache", visible_component:"corrupt.o", shadow_backing_component:"corrupt.reject", original_backing_path:$$reject, original_backing_sha256:$$reject_sha256, source:"make-owned corrupt cache reject fixture", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{verified_hit:true, stale:true, corrupt:true, miss:false, pass_through:false}, missing_branches:["miss","pass_through","real_ccache_trace"], missing_branch_reason:"current W4 path oracle does not run ccache or measure hit/miss/stale transitions"}, c1_c8_gate:"not_validated_until_real_cache_trace_content_hash_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.cache_witness_manifest.v1" and .status == "cache_witness" and .result_level == "host_cache_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 3 and .semantic_witness.branch_coverage.verified_hit == true and .semantic_witness.branch_coverage.stale == true and .semantic_witness.branch_coverage.corrupt == true and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(BUILDKIT_MANIFEST_JSON): $(PROMETHEUS_PROVENANCE) $(ROOT_DIR)/mk/workload.mk | $(BUILDKIT_RESULT_DIR)
	test -f "$(PROMETHEUS_SRC)/go.mod"
	install -m 0644 "$(PROMETHEUS_SRC)/go.mod" "$(BUILDKIT_PKG_CANON)"
	jq -n \
		--slurpfile provenance "$(PROMETHEUS_PROVENANCE)" \
		--arg schema "namei_ext.cache_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w4-buildkit-prometheus-go-cache" \
		--arg policy_family "cache_locality_view.bpf.c" \
		--arg make_target "workload-buildkit-manifest" \
		--arg pkg "$(BUILDKIT_PKG_CANON)" \
		--arg pkg_sha256 "$$(sha256sum "$(BUILDKIT_PKG_CANON)" | awk '{print $$1}')" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"cache_witness", result_level:"host_cache_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, source_provenance:$$provenance[0], generator:{make_target:$$make_target}, candidate_entries:[{branch:"miss_canonical", parent_relative:"gomod", visible_component:"pkg.mod", shadow_backing_component:"pkg.canon", original_backing_path:$$pkg, original_backing_sha256:$$pkg_sha256, source:"Prometheus go.mod as BuildKit/Go module canonical cache witness", events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{miss:true, verified_hit:false, stale:false, corrupt:false, pass_through:false}, missing_branches:["verified_hit","stale","corrupt","pass_through","real_buildkit_trace"], missing_branch_reason:"BuildKit witness contributes miss/canonical path only; ccache witness contributes hit/stale/corrupt"}, c1_c8_gate:"not_validated_until_real_cache_trace_content_hash_oracle_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.cache_witness_manifest.v1" and .status == "cache_witness" and .result_level == "host_cache_witness_manifest" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and (.candidate_entries | length) == 1 and .semantic_witness.branch_coverage.miss == true and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(W4_ORACLE_ENTRIES_TSV): $(CCACHE_MANIFEST_JSON) $(BUILDKIT_MANIFEST_JSON) | $(WORKLOAD_RUN_ROOT)
	rm -f "$@.tmp" "$@"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(CCACHE_MANIFEST_JSON)" >"$@.tmp"
	jq -r '.workload_id as $$wid | .candidate_entries[] | [$$wid, .branch, (.parent_relative // "."), (.parent_absolute // "."), .visible_component, .shadow_backing_component, .original_backing_path, .original_backing_sha256] | @tsv' "$(BUILDKIT_MANIFEST_JSON)" >>"$@.tmp"
	test "$$(wc -l <"$@.tmp")" = "4"
	awk -F '\t' 'NF != 8 { exit 1 } $$5 == "" || $$6 == "" || $$7 == "" || $$8 == "" { exit 1 }' "$@.tmp"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$@.tmp"
	mv -f "$@.tmp" "$@"

$(REDIS_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(REDIS_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(NGINX_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(NGINX_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(POSTGRES_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(POSTGRES_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(POSTGRES_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(PROMETHEUS_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(PROMETHEUS_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(PROMETHEUS_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(REDIS_STAMP): $(REDIS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(REDIS_SRC)"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$(REDIS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(REDIS_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(REDIS_SRC)/Makefile"
	test -f "$(REDIS_SRC)/src/Makefile"
	test -f "$(REDIS_SRC)/$(REDIS_LICENSE_PATH)"
	touch "$@"

$(NGINX_STAMP): $(NGINX_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(NGINX_SRC)"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$(NGINX_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(NGINX_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(NGINX_SRC)/configure"
	test -f "$(NGINX_SRC)/conf/nginx.conf"
	test -f "$(NGINX_SRC)/$(NGINX_LICENSE_PATH)"
	touch "$@"

$(POSTGRES_STAMP): $(POSTGRES_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(POSTGRES_SRC)"
	printf '%s  %s\n' "$(POSTGRES_ARCHIVE_SHA256)" "$(POSTGRES_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(POSTGRES_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(POSTGRES_SRC)/configure"
	test -f "$(POSTGRES_SRC)/src/backend/utils/misc/postgresql.conf.sample"
	test -f "$(POSTGRES_SRC)/$(POSTGRES_LICENSE_PATH)"
	touch "$@"

$(PROMETHEUS_STAMP): $(PROMETHEUS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(PROMETHEUS_SRC)"
	printf '%s  %s\n' "$(PROMETHEUS_ARCHIVE_SHA256)" "$(PROMETHEUS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(PROMETHEUS_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(PROMETHEUS_SRC)/go.mod"
	test -f "$(PROMETHEUS_SRC)/go.sum"
	test -f "$(PROMETHEUS_SRC)/$(PROMETHEUS_LICENSE_PATH)"
	touch "$@"

$(REDIS_BUILD_STAMP): $(REDIS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(REDIS_BUILD_WORK_ROOT)"
	install -d "$(REDIS_BUILD_SRC)"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$(REDIS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(REDIS_ARCHIVE)" -C "$(REDIS_BUILD_SRC)" --strip-components=1
	test -f "$(REDIS_BUILD_SRC)/Makefile"
	test -f "$(REDIS_BUILD_SRC)/src/Makefile"
	touch "$@"

$(REDIS_TRACE_STAMP): $(REDIS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(REDIS_TRACE_WORK_ROOT)"
	install -d "$(REDIS_TRACE_SRC)"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$(REDIS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(REDIS_ARCHIVE)" -C "$(REDIS_TRACE_SRC)" --strip-components=1
	test -f "$(REDIS_TRACE_SRC)/Makefile"
	test -f "$(REDIS_TRACE_SRC)/src/Makefile"
	touch "$@"

$(NGINX_BUILD_STAMP): $(NGINX_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(NGINX_BUILD_WORK_ROOT)"
	install -d "$(NGINX_BUILD_SRC)" "$(NGINX_BUILD_PREFIX)"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$(NGINX_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(NGINX_ARCHIVE)" -C "$(NGINX_BUILD_SRC)" --strip-components=1
	test -f "$(NGINX_BUILD_SRC)/configure"
	test -f "$(NGINX_BUILD_SRC)/conf/nginx.conf"
	touch "$@"

$(NGINX_TRACE_STAMP): $(NGINX_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(NGINX_TRACE_WORK_ROOT)"
	install -d "$(NGINX_TRACE_SRC)" "$(NGINX_TRACE_PREFIX)"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$(NGINX_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(NGINX_ARCHIVE)" -C "$(NGINX_TRACE_SRC)" --strip-components=1
	test -f "$(NGINX_TRACE_SRC)/configure"
	test -f "$(NGINX_TRACE_SRC)/conf/nginx.conf"
	touch "$@"

$(REDIS_PROVENANCE): $(REDIS_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w1-redis-build,w3-redis-podman-criu,w4-ccache-redis-nginx" \
		--arg project "redis" \
		--arg version "$(REDIS_VERSION)" \
		--arg commit "$(REDIS_COMMIT)" \
		--arg url "$(REDIS_URL)" \
		--arg archive "$(REDIS_ARCHIVE)" \
		--arg expected_archive_sha256 "$(REDIS_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(REDIS_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(REDIS_SRC)" \
		--arg license "$(REDIS_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(REDIS_SRC)/$(REDIS_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg makefile_sha256 "$$(sha256sum "$(REDIS_SRC)/Makefile" | awk '{print $$1}')" \
		--arg src_makefile_sha256 "$$(sha256sum "$(REDIS_SRC)/src/Makefile" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, commit:$$commit, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{makefile_sha256:$$makefile_sha256, src_makefile_sha256:$$src_makefile_sha256}}' \
		>"$@"

$(NGINX_PROVENANCE): $(NGINX_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w1-nginx-build,w2-nginx-fixture,w3-nginx-podman-criu,w4-ccache-redis-nginx" \
		--arg project "nginx" \
		--arg version "$(NGINX_VERSION)" \
		--arg url "$(NGINX_URL)" \
		--arg archive "$(NGINX_ARCHIVE)" \
		--arg expected_archive_sha256 "$(NGINX_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(NGINX_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(NGINX_SRC)" \
		--arg license "$(NGINX_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(NGINX_SRC)/$(NGINX_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg configure_sha256 "$$(sha256sum "$(NGINX_SRC)/configure" | awk '{print $$1}')" \
		--arg conf_sha256 "$$(sha256sum "$(NGINX_SRC)/conf/nginx.conf" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{configure_sha256:$$configure_sha256, sample_config_sha256:$$conf_sha256}}' \
		>"$@"

$(POSTGRES_PROVENANCE): $(POSTGRES_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w2-postgres-secret-fixture" \
		--arg project "postgresql" \
		--arg version "$(POSTGRES_VERSION)" \
		--arg url "$(POSTGRES_URL)" \
		--arg archive "$(POSTGRES_ARCHIVE)" \
		--arg expected_archive_sha256 "$(POSTGRES_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(POSTGRES_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(POSTGRES_SRC)" \
		--arg license "$(POSTGRES_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(POSTGRES_SRC)/$(POSTGRES_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg configure_sha256 "$$(sha256sum "$(POSTGRES_SRC)/configure" | awk '{print $$1}')" \
		--arg config_sha256 "$$(sha256sum "$(POSTGRES_SRC)/src/backend/utils/misc/postgresql.conf.sample" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{configure_sha256:$$configure_sha256, sample_config_sha256:$$config_sha256}}' \
		>"$@"

$(PROMETHEUS_PROVENANCE): $(PROMETHEUS_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w4-buildkit-prometheus-go-cache" \
		--arg project "prometheus" \
		--arg version "$(PROMETHEUS_VERSION)" \
		--arg commit "$(PROMETHEUS_COMMIT)" \
		--arg url "$(PROMETHEUS_URL)" \
		--arg archive "$(PROMETHEUS_ARCHIVE)" \
		--arg expected_archive_sha256 "$(PROMETHEUS_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(PROMETHEUS_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(PROMETHEUS_SRC)" \
		--arg license "$(PROMETHEUS_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(PROMETHEUS_SRC)/$(PROMETHEUS_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg gomod_sha256 "$$(sha256sum "$(PROMETHEUS_SRC)/go.mod" | awk '{print $$1}')" \
		--arg gosum_sha256 "$$(sha256sum "$(PROMETHEUS_SRC)/go.sum" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, commit:$$commit, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{go_mod_sha256:$$gomod_sha256, go_sum_sha256:$$gosum_sha256, cache_mount_paths:["/go/pkg/mod","/root/.cache/go-build"]}}' \
		>"$@"

$(REDIS_BUILD_JSON): $(REDIS_BUILD_STAMP) $(REDIS_PROVENANCE) | $(REDIS_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	start_ns=$$(date +%s%N); \
	GIT_CEILING_DIRECTORIES="$(REDIS_BUILD_SRC)" \
		$(MAKE) -C "$(REDIS_BUILD_SRC)" -j"$(JOBS)" BUILD_TLS=no MALLOC=libc redis-server >"$(REDIS_BUILD_LOG)" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(REDIS_BUILD_SRC)/src/redis-server"; \
	jq -n \
		--arg schema "namei_ext.real_workload_build.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-redis-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "redis" \
		--arg version "$(REDIS_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg git_ceiling_directories "$(REDIS_BUILD_SRC)" \
		--arg cc_version "$$(cc --version | sed -n '1p')" \
		--arg source_dir "$(REDIS_BUILD_SRC)" \
		--arg log "$(REDIS_BUILD_LOG)" \
		--arg binary "$(REDIS_BUILD_SRC)/src/redis-server" \
		--arg binary_sha256 "$$(sha256sum "$(REDIS_BUILD_SRC)/src/redis-server" | awk '{print $$1}')" \
		--arg stdout_sha256 "$$(sha256sum "$(REDIS_BUILD_LOG)" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["make","redis-server"], make_variables:{BUILD_TLS:"no", MALLOC:"libc", JOBS:$$jobs}, environment:{GIT_CEILING_DIRECTORIES:$$git_ceiling_directories}, toolchain:{cc_version:$$cc_version}, duration_ns:$$duration_ns, artifacts:{log:$$log, log_sha256:$$stdout_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"

$(REDIS_TRACE_JSON): $(REDIS_TRACE_STAMP) $(REDIS_PROVENANCE) | $(REDIS_BUILD_RESULT_DIR)
	command -v strace >/dev/null
	rm -f "$(REDIS_TRACE_LOG)"
	start_ns=$$(date +%s%N); \
	GIT_CEILING_DIRECTORIES="$(REDIS_TRACE_SRC)" \
		strace -f -e trace=%file -o "$(REDIS_TRACE_LOG)" \
		$(MAKE) -C "$(REDIS_TRACE_SRC)" -j"$(JOBS)" BUILD_TLS=no MALLOC=libc redis-server \
		>"$(REDIS_BUILD_RESULT_DIR)/trace-build.log" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(REDIS_TRACE_SRC)/src/redis-server"; \
	jq -n \
		--arg schema "namei_ext.real_workload_trace.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-redis-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "redis" \
		--arg version "$(REDIS_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg git_ceiling_directories "$(REDIS_TRACE_SRC)" \
		--arg strace_version "$$(strace -V | sed -n '1p')" \
		--arg source_dir "$(REDIS_TRACE_SRC)" \
		--arg strace "$(REDIS_TRACE_LOG)" \
		--arg strace_sha256 "$$(sha256sum "$(REDIS_TRACE_LOG)" | awk '{print $$1}')" \
		--arg trace_build_log "$(REDIS_BUILD_RESULT_DIR)/trace-build.log" \
		--arg trace_build_log_sha256 "$$(sha256sum "$(REDIS_BUILD_RESULT_DIR)/trace-build.log" | awk '{print $$1}')" \
		--arg binary "$(REDIS_TRACE_SRC)/src/redis-server" \
		--arg binary_sha256 "$$(sha256sum "$(REDIS_TRACE_SRC)/src/redis-server" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		--argjson file_op_lines "$$(wc -l <"$(REDIS_TRACE_LOG)")" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["strace","make","redis-server"], make_variables:{BUILD_TLS:"no", MALLOC:"libc", JOBS:$$jobs}, environment:{GIT_CEILING_DIRECTORIES:$$git_ceiling_directories}, toolchain:{strace_version:$$strace_version}, duration_ns:$$duration_ns, file_op_lines:$$file_op_lines, artifacts:{strace:$$strace, strace_sha256:$$strace_sha256, build_log:$$trace_build_log, build_log_sha256:$$trace_build_log_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"

$(REDIS_MANIFEST_JSON): $(REDIS_BUILD_JSON) $(REDIS_TRACE_JSON) $(REDIS_PROVENANCE) | $(REDIS_BUILD_RESULT_DIR)
	jq -n \
		--slurpfile provenance "$(REDIS_PROVENANCE)" \
		--slurpfile build "$(REDIS_BUILD_JSON)" \
		--slurpfile trace "$(REDIS_TRACE_JSON)" \
		'{schema:"namei_ext.real_workload_manifest.v1", run_id:"$(RUN_ID)", workload_id:"w1-redis-build", policy_family:"build_graph_view.bpf.c", status:"source-build-trace", result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, provenance:$$provenance[0], build:$$build[0], trace:$$trace[0], c1_c8_gate:"not_validated_until_kvm_policy_oracle_and_table_counterfactual_pass"}' \
		>"$@"

$(REDIS_ALIAS_MANIFEST_JSON): $(REDIS_MANIFEST_JSON) $(ROOT_DIR)/mk/workload.mk | $(REDIS_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	command -v gcc >/dev/null
	test "$$(dirname "$$(command -v cc)")" = "/usr/bin"
	test "$$(dirname "$$(command -v gcc)")" = "/usr/bin"
	test -f "$(REDIS_TRACE_LOG)"
	test -f "$(REDIS_TRACE_SRC)/src/release.h"
	test -f "$(REDIS_TRACE_SRC)/src/server.c"
	test -f /usr/include/stdio.h
	rm -f "$@.tmp" "$@"
	jq -n \
		--slurpfile source_manifest "$(REDIS_MANIFEST_JSON)" \
		--arg schema "namei_ext.trace_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-redis-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg make_target "workload-redis-build-alias-manifest" \
		--arg trace_path "$(REDIS_TRACE_LOG)" \
		--arg trace_sha256 "$$(sha256sum "$(REDIS_TRACE_LOG)" | awk '{print $$1}')" \
		--arg source_manifest_path "$(REDIS_MANIFEST_JSON)" \
		--arg source_manifest_sha256 "$$(sha256sum "$(REDIS_MANIFEST_JSON)" | awk '{print $$1}')" \
		--arg release_h "$(REDIS_TRACE_SRC)/src/release.h" \
		--arg release_h_sha256 "$$(sha256sum "$(REDIS_TRACE_SRC)/src/release.h" | awk '{print $$1}')" \
		--arg server_c "$(REDIS_TRACE_SRC)/src/server.c" \
		--arg server_c_sha256 "$$(sha256sum "$(REDIS_TRACE_SRC)/src/server.c" | awk '{print $$1}')" \
		--arg cc_path "$$(command -v cc)" \
		--arg cc_sha256 "$$(sha256sum "$$(command -v cc)" | awk '{print $$1}')" \
		--arg gcc_path "$$(command -v gcc)" \
		--arg gcc_sha256 "$$(sha256sum "$$(command -v gcc)" | awk '{print $$1}')" \
		--arg stdio_h "/usr/include/stdio.h" \
		--arg stdio_h_sha256 "$$(sha256sum /usr/include/stdio.h | awk '{print $$1}')" \
		--argjson release_h_hits "$$(awk -v pat="release.h" 'index($$0, pat){n++} END{print n+0}' "$(REDIS_TRACE_LOG)")" \
		--argjson server_c_hits "$$(awk -v pat="src/server.c" 'index($$0, pat){n++} END{print n+0}' "$(REDIS_TRACE_LOG)")" \
		--argjson cc_hits "$$(awk -v pat="$$(command -v cc)" 'index($$0, pat){n++} END{print n+0}' "$(REDIS_TRACE_LOG)")" \
		--argjson stdio_h_hits "$$(awk -v pat="stdio.h" 'index($$0, pat){n++} END{print n+0}' "$(REDIS_TRACE_LOG)")" \
		--argjson file_op_lines "$$(jq '.trace.file_op_lines' "$(REDIS_MANIFEST_JSON)")" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"trace_witness", result_level:"host_trace_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, policy_execution_basis:"host_trace_only", source_manifest:$$source_manifest[0], generator:{make_target:$$make_target, input_trace:$$trace_path, input_trace_sha256:$$trace_sha256, input_manifest:$$source_manifest_path, input_manifest_sha256:$$source_manifest_sha256}, candidate_entries:[{branch:"generated_output", parent_relative:"src", visible_component:"release.h", shadow_backing_component:".namei_ext.generated.release.h", original_backing_path:$$release_h, original_backing_sha256:$$release_h_sha256, trace_hits:$$release_h_hits, events:["lookup","readdir"]}, {branch:"declared_source_fallback", parent_relative:"src", visible_component:"server.c", shadow_backing_component:".namei_ext.source.server.c", original_backing_path:$$server_c, original_backing_sha256:$$server_c_sha256, trace_hits:$$server_c_hits, events:["lookup","readdir"]}, {branch:"toolchain_selection", parent_absolute:"/usr/bin", visible_component:"cc", shadow_backing_component:"gcc", original_backing_path:$$gcc_path, original_backing_sha256:$$gcc_sha256, observed_frontend_path:$$cc_path, observed_frontend_sha256:$$cc_sha256, trace_hits:$$cc_hits, events:["lookup","readdir"]}, {branch:"external_dependency", parent_absolute:"/usr/include", visible_component:"stdio.h", shadow_backing_component:".namei_ext.external.stdio.h", original_backing_path:$$stdio_h, original_backing_sha256:$$stdio_h_sha256, trace_hits:$$stdio_h_hits, events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{generated_output:($$release_h_hits > 0), declared_source_fallback:($$server_c_hits > 0), toolchain_selection:($$cc_hits > 0), external_dependency:($$stdio_h_hits > 0), undeclared_dependency_poison:false, negative_fallback:false}, missing_branches:["undeclared_dependency_poison","negative_fallback"], missing_branch_reason:"clean host build trace does not exercise poison or negative probes; those require KVM policy oracle tests"}, hit_rate:{candidate_witness_hit_rate:(($$release_h_hits + $$server_c_hits + $$cc_hits + $$stdio_h_hits) / $$file_op_lines), numerator_candidate_trace_hits:($$release_h_hits + $$server_c_hits + $$cc_hits + $$stdio_h_hits), denominator_file_op_lines:$$file_op_lines, basis:"host trace candidate entry hits over all strace %file operations; policy_executed is false", release_gate_eligible:false}, materialization_status:"shadow backing files not created by this target", c1_c8_gate:"not_validated_until_kvm_policy_oracle_materializer_loader_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.trace_witness_manifest.v1" and .status == "trace_witness" and .result_level == "host_trace_witness_manifest" and .run_environment == "host" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and .policy_execution_basis == "host_trace_only" and (.candidate_entries | length) >= 4 and .semantic_witness.branch_coverage.generated_output == true and .semantic_witness.branch_coverage.declared_source_fallback == true and .semantic_witness.branch_coverage.toolchain_selection == true and .semantic_witness.branch_coverage.external_dependency == true and .semantic_witness.branch_coverage.undeclared_dependency_poison == false and .semantic_witness.branch_coverage.negative_fallback == false and (.hit_rate.candidate_witness_hit_rate >= 0) and (.hit_rate.numerator_candidate_trace_hits > 0) and (.hit_rate.denominator_file_op_lines > 1000) and .hit_rate.release_gate_eligible == false and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

$(NGINX_BUILD_JSON): $(NGINX_BUILD_STAMP) $(NGINX_PROVENANCE) | $(NGINX_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	start_ns=$$(date +%s%N); \
	cd "$(NGINX_BUILD_SRC)" && ./configure --prefix="$(NGINX_BUILD_PREFIX)" --with-cc=cc --without-http_rewrite_module --without-http_gzip_module >"$(NGINX_CONFIGURE_LOG)" 2>&1; \
	$(MAKE) -C "$(NGINX_BUILD_SRC)" -j"$(JOBS)" >"$(NGINX_BUILD_LOG)" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(NGINX_BUILD_SRC)/objs/nginx"; \
	jq -n \
		--arg schema "namei_ext.real_workload_build.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-nginx-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "nginx" \
		--arg version "$(NGINX_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg cc_version "$$(cc --version | sed -n '1p')" \
		--arg source_dir "$(NGINX_BUILD_SRC)" \
		--arg configure_log "$(NGINX_CONFIGURE_LOG)" \
		--arg configure_log_sha256 "$$(sha256sum "$(NGINX_CONFIGURE_LOG)" | awk '{print $$1}')" \
		--arg build_log "$(NGINX_BUILD_LOG)" \
		--arg build_log_sha256 "$$(sha256sum "$(NGINX_BUILD_LOG)" | awk '{print $$1}')" \
		--arg binary "$(NGINX_BUILD_SRC)/objs/nginx" \
		--arg binary_sha256 "$$(sha256sum "$(NGINX_BUILD_SRC)/objs/nginx" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["./configure","make"], configure_flags:["--without-http_rewrite_module","--without-http_gzip_module"], make_variables:{JOBS:$$jobs}, toolchain:{cc_version:$$cc_version}, duration_ns:$$duration_ns, artifacts:{configure_log:$$configure_log, configure_log_sha256:$$configure_log_sha256, build_log:$$build_log, build_log_sha256:$$build_log_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"

$(NGINX_TRACE_JSON): $(NGINX_TRACE_STAMP) $(NGINX_PROVENANCE) | $(NGINX_BUILD_RESULT_DIR)
	command -v strace >/dev/null
	rm -f "$(NGINX_TRACE_LOG)" "$(NGINX_TRACE_LOG).configure" "$(NGINX_TRACE_LOG).make"
	start_ns=$$(date +%s%N); \
	cd "$(NGINX_TRACE_SRC)" && strace -f -e trace=%file -o "$(NGINX_TRACE_LOG).configure" \
		./configure --prefix="$(NGINX_TRACE_PREFIX)" --with-cc=cc --without-http_rewrite_module --without-http_gzip_module \
		>"$(NGINX_BUILD_RESULT_DIR)/trace-configure.log" 2>&1; \
	strace -f -e trace=%file -o "$(NGINX_TRACE_LOG).make" \
		$(MAKE) -C "$(NGINX_TRACE_SRC)" -j"$(JOBS)" \
		>"$(NGINX_BUILD_RESULT_DIR)/trace-build.log" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(NGINX_TRACE_SRC)/objs/nginx"; \
	cat "$(NGINX_TRACE_LOG).configure" "$(NGINX_TRACE_LOG).make" >"$(NGINX_TRACE_LOG)"; \
	jq -n \
		--arg schema "namei_ext.real_workload_trace.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-nginx-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "nginx" \
		--arg version "$(NGINX_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg strace_version "$$(strace -V | sed -n '1p')" \
		--arg source_dir "$(NGINX_TRACE_SRC)" \
		--arg strace "$(NGINX_TRACE_LOG)" \
		--arg strace_sha256 "$$(sha256sum "$(NGINX_TRACE_LOG)" | awk '{print $$1}')" \
		--arg trace_configure_log "$(NGINX_BUILD_RESULT_DIR)/trace-configure.log" \
		--arg trace_configure_log_sha256 "$$(sha256sum "$(NGINX_BUILD_RESULT_DIR)/trace-configure.log" | awk '{print $$1}')" \
		--arg trace_build_log "$(NGINX_BUILD_RESULT_DIR)/trace-build.log" \
		--arg trace_build_log_sha256 "$$(sha256sum "$(NGINX_BUILD_RESULT_DIR)/trace-build.log" | awk '{print $$1}')" \
		--arg binary "$(NGINX_TRACE_SRC)/objs/nginx" \
		--arg binary_sha256 "$$(sha256sum "$(NGINX_TRACE_SRC)/objs/nginx" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		--argjson file_op_lines "$$(wc -l <"$(NGINX_TRACE_LOG)")" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["strace","./configure","make"], configure_flags:["--without-http_rewrite_module","--without-http_gzip_module"], make_variables:{JOBS:$$jobs}, toolchain:{strace_version:$$strace_version}, duration_ns:$$duration_ns, file_op_lines:$$file_op_lines, artifacts:{strace:$$strace, strace_sha256:$$strace_sha256, configure_log:$$trace_configure_log, configure_log_sha256:$$trace_configure_log_sha256, build_log:$$trace_build_log, build_log_sha256:$$trace_build_log_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"

$(NGINX_MANIFEST_JSON): $(NGINX_BUILD_JSON) $(NGINX_TRACE_JSON) $(NGINX_PROVENANCE) | $(NGINX_BUILD_RESULT_DIR)
	jq -n \
		--slurpfile provenance "$(NGINX_PROVENANCE)" \
		--slurpfile build "$(NGINX_BUILD_JSON)" \
		--slurpfile trace "$(NGINX_TRACE_JSON)" \
		'{schema:"namei_ext.real_workload_manifest.v1", run_id:"$(RUN_ID)", workload_id:"w1-nginx-build", policy_family:"build_graph_view.bpf.c", status:"source-build-trace", result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, provenance:$$provenance[0], build:$$build[0], trace:$$trace[0], c1_c8_gate:"not_validated_until_kvm_policy_oracle_and_table_counterfactual_pass"}' \
		>"$@"

$(NGINX_ALIAS_MANIFEST_JSON): $(NGINX_MANIFEST_JSON) $(ROOT_DIR)/mk/workload.mk | $(NGINX_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	command -v gcc >/dev/null
	test "$$(dirname "$$(command -v cc)")" = "/usr/bin"
	test "$$(dirname "$$(command -v gcc)")" = "/usr/bin"
	test -f "$(NGINX_TRACE_LOG)"
	test -f "$(NGINX_TRACE_SRC)/objs/ngx_auto_config.h"
	test -f "$(NGINX_TRACE_SRC)/objs/ngx_auto_headers.h"
	test -f "$(NGINX_TRACE_SRC)/src/core/nginx.c"
	test -f /usr/include/stdio.h
	rm -f "$@.tmp" "$@"
	jq -n \
		--slurpfile source_manifest "$(NGINX_MANIFEST_JSON)" \
		--arg schema "namei_ext.trace_witness_manifest.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-nginx-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg make_target "workload-nginx-build-alias-manifest" \
		--arg trace_path "$(NGINX_TRACE_LOG)" \
		--arg trace_sha256 "$$(sha256sum "$(NGINX_TRACE_LOG)" | awk '{print $$1}')" \
		--arg source_manifest_path "$(NGINX_MANIFEST_JSON)" \
		--arg source_manifest_sha256 "$$(sha256sum "$(NGINX_MANIFEST_JSON)" | awk '{print $$1}')" \
		--arg auto_config_h "$(NGINX_TRACE_SRC)/objs/ngx_auto_config.h" \
		--arg auto_config_h_sha256 "$$(sha256sum "$(NGINX_TRACE_SRC)/objs/ngx_auto_config.h" | awk '{print $$1}')" \
		--arg auto_headers_h "$(NGINX_TRACE_SRC)/objs/ngx_auto_headers.h" \
		--arg auto_headers_h_sha256 "$$(sha256sum "$(NGINX_TRACE_SRC)/objs/ngx_auto_headers.h" | awk '{print $$1}')" \
		--arg nginx_c "$(NGINX_TRACE_SRC)/src/core/nginx.c" \
		--arg nginx_c_sha256 "$$(sha256sum "$(NGINX_TRACE_SRC)/src/core/nginx.c" | awk '{print $$1}')" \
		--arg cc_path "$$(command -v cc)" \
		--arg cc_sha256 "$$(sha256sum "$$(command -v cc)" | awk '{print $$1}')" \
		--arg gcc_path "$$(command -v gcc)" \
		--arg gcc_sha256 "$$(sha256sum "$$(command -v gcc)" | awk '{print $$1}')" \
		--arg stdio_h "/usr/include/stdio.h" \
		--arg stdio_h_sha256 "$$(sha256sum /usr/include/stdio.h | awk '{print $$1}')" \
		--argjson auto_config_h_hits "$$(awk -v pat="objs/ngx_auto_config.h" 'index($$0, pat){n++} END{print n+0}' "$(NGINX_TRACE_LOG)")" \
		--argjson auto_headers_h_hits "$$(awk -v pat="objs/ngx_auto_headers.h" 'index($$0, pat){n++} END{print n+0}' "$(NGINX_TRACE_LOG)")" \
		--argjson nginx_c_hits "$$(awk -v pat="src/core/nginx.c" 'index($$0, pat){n++} END{print n+0}' "$(NGINX_TRACE_LOG)")" \
		--argjson cc_hits "$$(awk -v pat="$$(command -v cc)" 'index($$0, pat){n++} END{print n+0}' "$(NGINX_TRACE_LOG)")" \
		--argjson stdio_h_hits "$$(awk -v pat="stdio.h" 'index($$0, pat){n++} END{print n+0}' "$(NGINX_TRACE_LOG)")" \
		--argjson file_op_lines "$$(jq '.trace.file_op_lines' "$(NGINX_MANIFEST_JSON)")" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, status:"trace_witness", result_level:"host_trace_witness_manifest", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, release_gate_eligible:false, policy_execution_basis:"host_trace_only", source_manifest:$$source_manifest[0], generator:{make_target:$$make_target, input_trace:$$trace_path, input_trace_sha256:$$trace_sha256, input_manifest:$$source_manifest_path, input_manifest_sha256:$$source_manifest_sha256}, candidate_entries:[{branch:"generated_output", parent_relative:"objs", visible_component:"ngx_auto_config.h", shadow_backing_component:".namei_ext.generated.ngx_auto_config.h", original_backing_path:$$auto_config_h, original_backing_sha256:$$auto_config_h_sha256, trace_hits:$$auto_config_h_hits, events:["lookup","readdir"]}, {branch:"generated_output", parent_relative:"objs", visible_component:"ngx_auto_headers.h", shadow_backing_component:".namei_ext.generated.ngx_auto_headers.h", original_backing_path:$$auto_headers_h, original_backing_sha256:$$auto_headers_h_sha256, trace_hits:$$auto_headers_h_hits, events:["lookup","readdir"]}, {branch:"declared_source_fallback", parent_relative:"src/core", visible_component:"nginx.c", shadow_backing_component:".namei_ext.source.nginx.c", original_backing_path:$$nginx_c, original_backing_sha256:$$nginx_c_sha256, trace_hits:$$nginx_c_hits, events:["lookup","readdir"]}, {branch:"toolchain_selection", parent_absolute:"/usr/bin", visible_component:"cc", shadow_backing_component:"gcc", original_backing_path:$$gcc_path, original_backing_sha256:$$gcc_sha256, observed_frontend_path:$$cc_path, observed_frontend_sha256:$$cc_sha256, trace_hits:$$cc_hits, events:["lookup","readdir"]}, {branch:"external_dependency", parent_absolute:"/usr/include", visible_component:"stdio.h", shadow_backing_component:".namei_ext.external.stdio.h", original_backing_path:$$stdio_h, original_backing_sha256:$$stdio_h_sha256, trace_hits:$$stdio_h_hits, events:["lookup","readdir"]}], semantic_witness:{branch_coverage:{generated_output:(($$auto_config_h_hits + $$auto_headers_h_hits) > 0), declared_source_fallback:($$nginx_c_hits > 0), toolchain_selection:($$cc_hits > 0), external_dependency:($$stdio_h_hits > 0), undeclared_dependency_poison:false, negative_fallback:false}, missing_branches:["undeclared_dependency_poison","negative_fallback"], missing_branch_reason:"clean host configure/build trace does not exercise poison or negative probes; those require KVM policy oracle tests"}, hit_rate:{candidate_witness_hit_rate:(($$auto_config_h_hits + $$auto_headers_h_hits + $$nginx_c_hits + $$cc_hits + $$stdio_h_hits) / $$file_op_lines), numerator_candidate_trace_hits:($$auto_config_h_hits + $$auto_headers_h_hits + $$nginx_c_hits + $$cc_hits + $$stdio_h_hits), denominator_file_op_lines:$$file_op_lines, basis:"host trace candidate entry hits over all strace %file operations; policy_executed is false", release_gate_eligible:false}, materialization_status:"shadow backing files not created by this target", c1_c8_gate:"not_validated_until_kvm_policy_oracle_materializer_loader_and_table_counterfactual_pass"}' \
		>"$@.tmp"
	jq -e '.schema == "namei_ext.trace_witness_manifest.v1" and .status == "trace_witness" and .result_level == "host_trace_witness_manifest" and .run_environment == "host" and .policy_executed == false and .kvm_validated == false and .output_hash_oracle == false and .release_gate_eligible == false and .policy_execution_basis == "host_trace_only" and (.candidate_entries | length) >= 4 and .semantic_witness.branch_coverage.generated_output == true and .semantic_witness.branch_coverage.declared_source_fallback == true and .semantic_witness.branch_coverage.toolchain_selection == true and .semantic_witness.branch_coverage.external_dependency == true and .semantic_witness.branch_coverage.undeclared_dependency_poison == false and .semantic_witness.branch_coverage.negative_fallback == false and (.hit_rate.candidate_witness_hit_rate >= 0) and (.hit_rate.numerator_candidate_trace_hits > 0) and (.hit_rate.denominator_file_op_lines > 1000) and .hit_rate.release_gate_eligible == false and (.c1_c8_gate | contains("not_validated"))' "$@.tmp" >/dev/null || { rm -f "$@.tmp"; exit 1; }
	mv -f "$@.tmp" "$@"

workload-clean:
	rm -rf "$(WORKLOAD_BUILD_ROOT)" "$(WORKLOAD_CACHE_ROOT)"

workload-clean-results:
	rm -rf "$(WORKLOAD_PROVENANCE_ROOT)" "$(WORKLOAD_RUNS_ROOT)"
