#
# Historical Redis/nginx ccache experiment matrix.
# New formal case studies must not add modes to this suite.
#

BUILD_CACHE_SAMPLES ?= 20
BUILD_CACHE_RESULT_DIR ?= $(RESULT_ROOT)/experiments/build-cache/$(RUN_ID)
BUILD_CACHE_JSON ?= $(BUILD_CACHE_RESULT_DIR)/build-cache-matrix.jsonl
BUILD_CACHE_INPUTS ?= $(BUILD_CACHE_RESULT_DIR)/build-cache-matrix-inputs.sha256
BUILD_CACHE_COMMAND ?= $(BUILD_CACHE_RESULT_DIR)/build-cache-matrix-command.txt
BUILD_CACHE_STDOUT ?= $(BUILD_CACHE_RESULT_DIR)/stdout-build-cache-matrix.log
BUILD_CACHE_STDERR ?= $(BUILD_CACHE_RESULT_DIR)/stderr-build-cache-matrix.log
BUILD_CACHE_PLAN ?= $(ROOT_DIR)/docs/tmp/2026-07-23-build-cache-experiment-b-plan.md
CACHE_LOCALITY_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/cache_locality_view.bpf.c
W1_ORACLE_RUNNER ?= $(BUILD_ROOT)/w1-oracle/namei_ext_w1_oracle
W1_ORACLE_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/legacy_oracle/namei_ext_w1_oracle.c
W4_ORACLE_RUNNER ?= $(W1_ORACLE_RUNNER)
W4_ORACLE_RUNNER_SOURCE ?= $(W1_ORACLE_RUNNER_SOURCE)
W4_CACHE_EPOCH_SAMPLES ?= 2
W4_CCACHE_BULK_CACHE_STATE_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-state-policy-fuse.jsonl
W4_CCACHE_BULK_CACHE_STATE_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-state-policy-fuse-inputs.sha256
W4_CCACHE_BULK_CACHE_STATE_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-cache-state-policy-fuse-work
W4_CCACHE_BULK_CACHE_STATE_SAMPLES ?= $(W4_CACHE_EPOCH_SAMPLES)
W4_CCACHE_BULK_CACHE_STATE_OBJECTS ?= $(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)
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
W4_CCACHE_BULK_MATERIALIZED_BASELINE_SAMPLES ?= 2
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
W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch.jsonl
W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-inputs.sha256
W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_OUTPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-outputs.sha256
W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-work
W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES ?= $(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE).jsonl
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_INPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-inputs.sha256
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_OUTPUTS ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-outputs.sha256
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR ?= $(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-work
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES ?= 1
W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE ?= stale

.PHONY: kvm-build-cache-matrix kvm-w4-ccache-bulk-trace \
	kvm-w4-ccache-bulk-policy-bridge \
	kvm-w4-ccache-bulk-cache-state-policy-fuse \
	kvm-w4-ccache-bulk-policy-compile kvm-w4-ccache-bulk-native-compile \
	kvm-w4-ccache-bulk-fuse-compile \
	kvm-w4-ccache-bulk-compile-epoch-switch \
	kvm-w4-ccache-bulk-bad-local-fallback \
	__experiment_build_cache_matrix __phase1_guest_w4_ccache_bulk_trace \
	__phase1_guest_w4_ccache_bulk_policy_bridge \
	__phase1_guest_w4_ccache_bulk_cache_state_policy_fuse \
	__phase1_guest_w4_ccache_bulk_policy_compile \
	__phase1_guest_w4_ccache_bulk_native_compile \
	__phase1_guest_w4_ccache_bulk_fuse_compile \
	__phase1_guest_w4_ccache_bulk_compile_epoch_switch \
	__phase1_guest_w4_ccache_bulk_bad_local_fallback

LEGACY_BUILD_CACHE_KVM_ENTRYPOINTS := \
	kvm-build-cache-matrix \
	kvm-w4-ccache-bulk-trace \
	kvm-w4-ccache-bulk-policy-bridge \
	kvm-w4-ccache-bulk-cache-state-policy-fuse \
	kvm-w4-ccache-bulk-policy-compile \
	kvm-w4-ccache-bulk-native-compile \
	kvm-w4-ccache-bulk-fuse-compile \
	kvm-w4-ccache-bulk-compile-epoch-switch \
	kvm-w4-ccache-bulk-bad-local-fallback

$(LEGACY_BUILD_CACHE_KVM_ENTRYPOINTS): kernel-provenance

kvm-build-cache-matrix: $(KERNEL_IMAGE) bpf w1-oracle workload-redis-build workload-nginx-build
	install -d "$(BUILD_CACHE_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __experiment_build_cache_matrix RUN_ID=$(RUN_ID) BUILD_CACHE_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_CACHE_STATE_SAMPLES=$(BUILD_CACHE_SAMPLES) W4_CCACHE_BULK_CACHE_STATE_OBJECTS=$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)"

__experiment_build_cache_matrix:
	install -d "$(PHASE1_RESULT_DIR)" "$(BUILD_CACHE_RESULT_DIR)"
	: >"$(BUILD_CACHE_STDOUT)"
	: >"$(BUILD_CACHE_STDERR)"
	printf 'make -C %s __experiment_build_cache_matrix RUN_ID=%s BUILD_CACHE_SAMPLES=%s W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=%s\n' "$(ROOT_DIR)" "$(RUN_ID)" "$(BUILD_CACHE_SAMPLES)" "$(BUILD_CACHE_SAMPLES)" >"$(BUILD_CACHE_COMMAND)"
	printf 'CACHE_LOCALITY_POLICY=%s\nW4_ORACLE_RUNNER=%s\nREDIS_BUILD_SRC=%s\nNGINX_BUILD_SRC=%s\nKERNEL_IMAGE=%s\nKERNEL_BUILD_DIR=%s\n' "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(KERNEL_IMAGE)" "$(KERNEL_BUILD_DIR)" >>"$(BUILD_CACHE_COMMAND)"
	printf '{"event":"build-cache-matrix-start","run_id":"%s","result_level":"kvm_build_cache_matrix","workload":"redis-nginx-ccache","samples":%s,"policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(BUILD_CACHE_SAMPLES)" >"$(BUILD_CACHE_JSON)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	cp "$(KERNEL_BUILD_DIR)/.config" "$(BUILD_CACHE_RESULT_DIR)/kernel.config"
	uname -a >"$(BUILD_CACHE_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(BUILD_CACHE_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(BUILD_CACHE_RESULT_DIR)/kernel-cmdline.txt"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_trace RUN_ID="$(RUN_ID)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_policy_bridge RUN_ID="$(RUN_ID)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_cache_state_policy_fuse RUN_ID="$(RUN_ID)" W4_CCACHE_BULK_CACHE_STATE_SAMPLES="$(BUILD_CACHE_SAMPLES)" W4_CCACHE_BULK_CACHE_STATE_OBJECTS="$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_policy_compile RUN_ID="$(RUN_ID)" W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES="$(BUILD_CACHE_SAMPLES)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_native_compile RUN_ID="$(RUN_ID)" W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES="$(BUILD_CACHE_SAMPLES)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_fuse_compile RUN_ID="$(RUN_ID)" W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES="$(BUILD_CACHE_SAMPLES)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	$(MAKE) -C "$(ROOT_DIR)" __phase1_guest_w4_ccache_bulk_compile_epoch_switch RUN_ID="$(RUN_ID)" W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES="$(BUILD_CACHE_SAMPLES)" >>"$(BUILD_CACHE_STDOUT)" 2>>"$(BUILD_CACHE_STDERR)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_CACHE_STATE_JSON)"
	test -s "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	test -s "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"
	test -s "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"
	test -s "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"
	cp "$(W4_CCACHE_BULK_TRACE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-trace.jsonl"
	cp "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-policy-bridge.jsonl"
	cp "$(W4_CCACHE_BULK_CACHE_STATE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-cache-state-policy-fuse.jsonl"
	cp "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-policy-compile.jsonl"
	cp "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-native-compile.jsonl"
	cp "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-fuse-compile.jsonl"
	cp "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch.jsonl"
	for f in w4-ccache-bulk-trace-inputs.sha256 w4-ccache-bulk-trace-artifacts.sha256 w4-ccache-bulk-policy-bridge-inputs.sha256 w4-ccache-bulk-cache-state-policy-fuse-inputs.sha256 w4-ccache-bulk-policy-compile-inputs.sha256 w4-ccache-bulk-policy-compile-outputs.sha256 w4-ccache-bulk-native-compile-inputs.sha256 w4-ccache-bulk-native-compile-outputs.sha256 w4-ccache-bulk-fuse-compile-inputs.sha256 w4-ccache-bulk-fuse-compile-outputs.sha256 w4-ccache-bulk-compile-epoch-switch-inputs.sha256 w4-ccache-bulk-compile-epoch-switch-outputs.sha256; do test -s "$(PHASE1_RESULT_DIR)/$$f"; cp "$(PHASE1_RESULT_DIR)/$$f" "$(BUILD_CACHE_RESULT_DIR)/$$f"; done
	for f in dmesg-w4-ccache-bulk-trace.log dmesg-w4-ccache-bulk-policy-bridge.log dmesg-w4-ccache-bulk-cache-state-policy-fuse.log dmesg-w4-ccache-bulk-policy-compile.log dmesg-w4-ccache-bulk-native-compile.log dmesg-w4-ccache-bulk-fuse-compile.log dmesg-w4-ccache-bulk-compile-epoch-switch.log; do test -s "$(PHASE1_RESULT_DIR)/$$f"; cp "$(PHASE1_RESULT_DIR)/$$f" "$(BUILD_CACHE_RESULT_DIR)/$$f"; done
	sha256sum "$(KERNEL_IMAGE)" "$(KERNEL_BUILD_DIR)/.config" "$(CACHE_LOCALITY_POLICY)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(BUILD_CACHE_PLAN)" "$(ROOT_DIR)/Makefile" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-trace.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-policy-bridge.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-cache-state-policy-fuse.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-policy-compile.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-native-compile.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-fuse-compile.jsonl" "$(BUILD_CACHE_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch.jsonl" >"$(BUILD_CACHE_INPUTS)"
	printf '{"event":"build-cache-provenance","run_id":"%s","result_level":"kvm_build_cache_matrix","command_file":"build-cache-matrix-command.txt","input_sha256_file":"build-cache-matrix-inputs.sha256","phase1_result_dir":"%s","stdout_file":"stdout-build-cache-matrix.log","stderr_file":"stderr-build-cache-matrix.log","kernel_config":"kernel.config"}\n' "$(RUN_ID)" "$(PHASE1_RESULT_DIR)" >>"$(BUILD_CACHE_JSON)"
	jq -e --argjson samples "$(BUILD_CACHE_SAMPLES)" --argjson min_trace_objects "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)" -s '([.[] | select(.event == "w4-ccache-bulk-policy-compile-release-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.policy_executed == true and $$s.ccache_compile_policy_executed == true and $$s.output_hash_match == true and $$s.policy_redirected_cache_objects >= ($$samples * $$min_trace_objects) and $$s.attached_cache_path_file_ops > 0 and $$s.attached_policy_cache_object_ops > 0' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" >/dev/null
	jq -e --argjson samples "$(BUILD_CACHE_SAMPLES)" --argjson objects "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)" -s '([.[] | select(.event == "w4-ccache-bulk-cache-state-policy-fuse-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.trace_entries >= $$objects and $$s.pass == true and $$s.namei_ext.pass == true and $$s.namei_ext.policy_epoch_switch_pass == true and $$s.fuse_baseline.pass == true and $$s.fuse_baseline.feature_equivalent_baseline == true and $$s.fuse_baseline.fuse_mounts == $$samples and $$s.real_ccache_trace_basis == true and $$s.trace_derived_state_oracle == true and $$s.policy_executed == true and $$s.feature_equivalent_fuse == true and $$s.kvm_validated == true' "$(W4_CCACHE_BULK_CACHE_STATE_JSON)" >/dev/null
	jq -e --argjson samples "$(BUILD_CACHE_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-bulk-native-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.total_compile_jobs == $$s.total_compile_output_matches and $$s.direct_cache_hit >= $$s.source_manifest_count' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" >/dev/null
	jq -e --argjson samples "$(BUILD_CACHE_SAMPLES)" -s '([.[] | select(.event == "w4-ccache-bulk-fuse-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.complete_ccache_compile_through_fuse == true and $$s.fuse_mounts == $$samples and $$s.total_compile_jobs == $$s.total_compile_output_matches and $$s.direct_cache_hit >= $$s.source_manifest_count' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" >/dev/null
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	jq -e --argjson samples "$(BUILD_CACHE_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-compile-epoch-switch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.failures == 0 and $$s.source_manifest_count == $$source_count and $$s.namei_ext.pass == true and $$s.namei_ext.rows == $$samples and $$s.namei_ext.epoch1_compile_jobs == ($$samples * $$source_count) and $$s.namei_ext.epoch1_output_matches == $$s.namei_ext.epoch1_compile_jobs and $$s.namei_ext.epoch2_compile_jobs == ($$samples * $$source_count) and $$s.namei_ext.epoch2_output_matches == $$s.namei_ext.epoch2_compile_jobs and $$s.namei_ext.policy_session_updates == $$samples and $$s.fuse_baseline.pass == true and $$s.fuse_baseline.rows == $$samples and $$s.fuse_baseline.epoch1_compile_jobs == ($$samples * $$source_count) and $$s.fuse_baseline.epoch1_output_matches == $$s.fuse_baseline.epoch1_compile_jobs and $$s.fuse_baseline.epoch2_compile_jobs == ($$samples * $$source_count) and $$s.fuse_baseline.epoch2_output_matches == $$s.fuse_baseline.epoch2_compile_jobs and $$s.fuse_baseline.fuse_mounts == $$samples and $$s.real_compile_epoch_switch == true and $$s.miss_stale_corrupt_compile_cells_closed == false and $$s.feature_equivalent_fuse == true and $$s.kvm_validated == true' "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)" >/dev/null
	for raw in "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_CACHE_STATE_JSON)" "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"; do jq -c 'select(.event | test("summary$$|release-summary$$"))' "$$raw" >>"$(BUILD_CACHE_JSON)"; done
	printf '{"event":"build-cache-boundary","run_id":"%s","result_level":"kvm_build_cache_boundary","mechanism":"namei_ext","workload":"redis-nginx-ccache","owned_methods":"lookup_policy,readdir_policy","daemon_state":"none","data_path_owner":"lower_filesystem","write_path_owner":"lower_filesystem_and_ccache","privileged_code_surface":"verified eBPF policy plus kernel validation","requires_daemon":false,"owns_filesystem_methods":false,"policy_verified":true,"lower_fs_owns_data_path":true,"detail":"cache object selection is a bounded VFS name-resolution policy; ccache and lower filesystems keep data/write semantics"}\n' "$(RUN_ID)" >>"$(BUILD_CACHE_JSON)"
	printf '{"event":"build-cache-boundary","run_id":"%s","result_level":"kvm_build_cache_boundary","mechanism":"feature_equivalent_fuse","workload":"redis-nginx-ccache","owned_methods":"getattr,readdir,open,read,release","daemon_state":"FUSE cache-view daemon and mount lifecycle","data_path_owner":"FUSE request path over backing cache objects","write_path_owner":"ccache read-only mode with tempdir outside FUSE mount","privileged_code_surface":"userspace filesystem daemon plus kernel FUSE interface","requires_daemon":true,"owns_filesystem_methods":true,"policy_verified":false,"lower_fs_owns_data_path":false,"detail":"same ccache output oracle passes through a FUSE filesystem-service boundary"}\n' "$(RUN_ID)" >>"$(BUILD_CACHE_JSON)"
	policy_rows=$$(jq -sr '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")]' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"); \
	policy_samples=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | length'); \
	policy_jobs=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.attached_compile_jobs // 0) | add // 0'); \
	policy_matches=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.attached_compile_output_matches // 0) | add // 0'); \
	policy_compile_ns=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.compile_ns // 0) | add // 0'); \
	policy_cache_ops=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.attached_cache_path_file_ops // 0) | add // 0'); \
	policy_object_ops=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.attached_policy_cache_object_ops // 0) | add // 0'); \
	policy_redirects=$$(jq -nr --argjson rows "$$policy_rows" '$$rows | map(.policy_redirected_cache_objects // 0) | add // 0'); \
	native_summary=$$(jq -csr '[.[] | select(.event == "w4-ccache-bulk-native-compile-summary")][0]' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"); \
	fuse_summary=$$(jq -csr '[.[] | select(.event == "w4-ccache-bulk-fuse-compile-summary")][0]' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"); \
	state_summary=$$(jq -csr '[.[] | select(.event == "w4-ccache-bulk-cache-state-policy-fuse-summary")][0]' "$(W4_CCACHE_BULK_CACHE_STATE_JSON)"); \
	epoch_summary=$$(jq -csr '[.[] | select(.event == "w4-ccache-bulk-compile-epoch-switch-summary")][0]' "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"); \
	jq -cn --arg run_id "$(RUN_ID)" --argjson samples "$(BUILD_CACHE_SAMPLES)" --argjson policy_samples "$$policy_samples" --argjson policy_jobs "$$policy_jobs" --argjson policy_matches "$$policy_matches" --argjson policy_compile_ns "$$policy_compile_ns" --argjson policy_cache_ops "$$policy_cache_ops" --argjson policy_object_ops "$$policy_object_ops" --argjson policy_redirects "$$policy_redirects" --argjson native "$$native_summary" --argjson fuse "$$fuse_summary" --argjson state "$$state_summary" --argjson epoch "$$epoch_summary" '{event:"build-cache-matrix-summary", run_id:$$run_id, result_level:"kvm_build_cache_matrix", workload:"redis-nginx-ccache", run_environment:"kvm", samples:$$samples, source_manifest_count:$$native.source_manifest_count, namei_ext:{policy:"cache_locality_view.bpf.c", pass:true, compile_rows:$$policy_samples, compile_jobs:$$policy_jobs, output_matches:$$policy_matches, compile_ns_total:$$policy_compile_ns, compile_ns_per_job_avg:(if $$policy_jobs > 0 then ($$policy_compile_ns / $$policy_jobs) else 0 end), compile_ns_per_sample_avg:(if $$policy_samples > 0 then ($$policy_compile_ns / $$policy_samples) else 0 end), cache_path_file_ops:$$policy_cache_ops, cache_object_ops:$$policy_object_ops, redirected_cache_objects:$$policy_redirects, sampled_operation_hit_rate:(if $$policy_cache_ops > 0 then ($$policy_object_ops / $$policy_cache_ops) else 0 end)}, trace_derived_state_row:{pass:$$state.pass, oracle:$$state.oracle, samples:$$state.samples, objects:$$state.objects, trace_entries:$$state.trace_entries, state_coverage:$$state.state_coverage, namei_ext:$$state.namei_ext, fuse_baseline:$$state.fuse_baseline, real_ccache_trace_basis:$$state.real_ccache_trace_basis, trace_derived_state_oracle:$$state.trace_derived_state_oracle}, real_compile_epoch_switch_row:{pass:$$epoch.pass, samples:$$epoch.samples, source_manifest_count:$$epoch.source_manifest_count, namei_ext:$$epoch.namei_ext, fuse_baseline:$$epoch.fuse_baseline, real_ccache_run:$$epoch.real_ccache_run, real_compile_epoch_switch:$$epoch.real_compile_epoch_switch, complete_ccache_compile_epoch_switch:$$epoch.complete_ccache_compile_epoch_switch, miss_stale_corrupt_compile_cells_closed:$$epoch.miss_stale_corrupt_compile_cells_closed}, native_control:{pass:$$native.pass, compile_jobs:$$native.total_compile_jobs, output_matches:$$native.total_compile_output_matches, compile_ns_total:$$native.compile_ns_total, compile_ns_per_job_avg:(if $$native.total_compile_jobs > 0 then ($$native.compile_ns_total / $$native.total_compile_jobs) else 0 end), compile_ns_per_sample_avg:$$native.compile_ns_avg, direct_cache_hit:$$native.direct_cache_hit}, fuse_baseline:{pass:$$fuse.pass, compile_jobs:$$fuse.total_compile_jobs, output_matches:$$fuse.total_compile_output_matches, compile_ns_total:$$fuse.compile_ns_total, compile_ns_per_job_avg:(if $$fuse.total_compile_jobs > 0 then ($$fuse.compile_ns_total / $$fuse.total_compile_jobs) else 0 end), compile_ns_per_sample_avg:$$fuse.compile_ns_avg, direct_cache_hit:$$fuse.direct_cache_hit, fuse_mounts:$$fuse.fuse_mounts, ccache_read_only:$$fuse.ccache_read_only, complete_ccache_compile_through_fuse:$$fuse.complete_ccache_compile_through_fuse}, fuse_over_namei_ext_compile_ns_ratio:(if $$policy_compile_ns > 0 then ($$fuse.compile_ns_total / $$policy_compile_ns) else 0 end), native_over_namei_ext_compile_ns_ratio:(if $$policy_compile_ns > 0 then ($$native.compile_ns_total / $$policy_compile_ns) else 0 end), real_compile_epoch_switch:true, miss_stale_corrupt_compile_cells_closed:false, table_baseline_used:false, materialized_baseline_used:false, policy_executed:true, feature_equivalent_fuse:true, output_hash_match:true, operation_weighted_policy_hit_rate:true, kvm_validated:true, pass:true, failures:0, detail:"Redis/nginx ccache build-cache matrix passed for verified-hot-cache compiles, trace-derived policy/FUSE state transition, and real compiler-output epoch-switch row"}' >>"$(BUILD_CACHE_JSON)"
	dmesg >"$(BUILD_CACHE_RESULT_DIR)/dmesg-build-cache-matrix.log"
	! grep -E 'BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN' "$(BUILD_CACHE_RESULT_DIR)/dmesg-build-cache-matrix.log" >/dev/null
	printf '{"event":"build-cache-matrix-done","run_id":"%s","result_level":"kvm_build_cache_matrix","samples":%s}\n' "$(RUN_ID)" "$(BUILD_CACHE_SAMPLES)" >>"$(BUILD_CACHE_JSON)"

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
	sha256sum "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-ccache.version" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-trace-strace.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-ccache-workload-design.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_TRACE_INPUTS)"
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
	jq -cn --arg run_id "$(RUN_ID)" --arg source_manifest "w4-ccache-bulk-source-manifest.tsv" --arg cache_dir "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" --arg redis_trace "w4-ccache-bulk-trace-redis.strace.log" --arg nginx_trace "w4-ccache-bulk-trace-nginx.strace.log" --arg artifacts_sha256 "w4-ccache-bulk-trace-artifacts.sha256" --arg stats_file "w4-ccache-bulk-trace-stats.txt" --argjson source_count "$$source_count" --argjson redis_trace_lines "$$redis_trace_lines" --argjson nginx_trace_lines "$$nginx_trace_lines" --argjson redis_cache_path_lines "$$redis_cache_path_lines" --argjson nginx_cache_path_lines "$$nginx_cache_path_lines" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" '{event:"w4-ccache-bulk-cache-path-trace", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_cache_path_trace_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, output_hash_match:true, source_manifest:$$source_manifest, source_count:$$source_count, ccache_cache_dir:$$cache_dir, redis_trace_file_ops:$$redis_trace_lines, nginx_trace_file_ops:$$nginx_trace_lines, redis_cache_path_file_ops:$$redis_cache_path_lines, nginx_cache_path_file_ops:$$nginx_cache_path_lines, cache_path_file_ops:($$redis_cache_path_lines + $$nginx_cache_path_lines), cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, redis_trace_file:$$redis_trace, nginx_trace_file:$$nginx_trace, stats_file:$$stats_file, artifacts_sha256_file:$$artifacts_sha256, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, detail:"multi-source real Redis/nginx ccache hot compiles touched CCACHE_DIR paths under KVM"}' >>"$(W4_CCACHE_BULK_TRACE_JSON)"; \
	jq -cn --arg run_id "$(RUN_ID)" --argjson source_count "$$source_count" '{event:"w4-ccache-bulk-trace-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_cache_path_trace_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", pass:true, failures:0, real_ccache_run:true, ccache_cache_path_trace:true, policy_executed:false, kvm_validated:true, source_count:$$source_count, detail:"bulk real ccache cache-path trace witness passed; policy bridge and baselines are separate gates"}' >>"$(W4_CCACHE_BULK_TRACE_JSON)"
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
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_REDIS_LOG)" "$(W4_CCACHE_BULK_TRACE_NGINX_LOG)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-ccache-workload-design.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_BRIDGE_INPUTS)"
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
	jq -cn --arg run_id "$(RUN_ID)" --argjson policy_failures "$$policy_failures" --argjson redis_entries "$$redis_entries" --argjson nginx_entries "$$nginx_entries" --argjson total_entries "$$total_entries" '{event:"w4-ccache-bulk-policy-bridge-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_bridge_witness", workload:"w4-ccache-bulk-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_trace_basis:true, ccache_cache_path_trace:true, trace_derived_policy_oracle_executed:true, ccache_compile_policy_executed:false, policy_executed:true, kvm_validated:true, trace_objects:$$total_entries, entries:$$total_entries, redis_trace_objects:$$redis_entries, nginx_trace_objects:$$nginx_entries, policy_content_oracle_failures:$$policy_failures, pass:true, failures:0, detail:"bulk trace-derived ccache cache object components executed cache_locality policy content oracle"}' >>"$(W4_CCACHE_BULK_BRIDGE_JSON)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-policy-bridge.log"
	printf '{"event":"w4-ccache-bulk-policy-bridge-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_policy_bridge_witness"}\n' "$(RUN_ID)" >>"$(W4_CCACHE_BULK_BRIDGE_JSON)"

kvm-w4-ccache-bulk-cache-state-policy-fuse: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_cache_state_policy_fuse RUN_ID=$(RUN_ID) W4_CCACHE_BULK_CACHE_STATE_SAMPLES=$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES) W4_CCACHE_BULK_CACHE_STATE_OBJECTS=$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)"

__phase1_guest_w4_ccache_bulk_cache_state_policy_fuse:
	install -d "$(PHASE1_RESULT_DIR)" "$(W4_CCACHE_BULK_CACHE_STATE_WORK_DIR)"
	printf '{"event":"w4-ccache-bulk-cache-state-policy-fuse-start","run_id":"%s","result_level":"kvm_real_ccache_trace_cache_state_policy_fuse","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)" >"$(W4_CCACHE_BULK_CACHE_STATE_JSON)"
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
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(W4_ORACLE_RUNNER)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -s "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk"
	trace_entries=$$(wc -l <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"); test "$$trace_entries" -ge "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)"
	while IFS="	" read -r workload branch parent_relative parent_absolute visible shadow original sha; do test -e "$$original"; printf '%s  %s\n' "$$sha" "$$original" | sha256sum -c - >/dev/null; done <"$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_INPUTS)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(BUILD_CACHE_PLAN)" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_CACHE_STATE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_CACHE_STATE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-cache-state-policy-fuse-input","run_id":"%s","result_level":"kvm_real_ccache_trace_cache_state_policy_fuse","input_sha256_file":"w4-ccache-bulk-cache-state-policy-fuse-inputs.sha256","trace_json":"%s","bridge_json":"%s","entries_tsv":"%s","work_dir":"%s","runner_source":"%s","samples":%s,"objects":%s,"cache_policy":"cache_locality_view.bpf.c"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_CACHE_STATE_WORK_DIR)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)" >>"$(W4_CCACHE_BULK_CACHE_STATE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-cache-state-policy-fuse "$(W4_CCACHE_BULK_CACHE_STATE_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_STATE_WORK_DIR)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)" "$(CACHE_LOCALITY_POLICY)"
	jq -e --argjson samples "$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES)" --argjson objects "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)" -s '([.[] | select(.event == "w4-ccache-bulk-cache-state-policy-fuse-summary")][0]) as $$s | $$s.samples == $$samples and $$s.objects == $$objects and $$s.trace_entries >= $$objects and $$s.pass == true and $$s.namei_ext.pass == true and $$s.namei_ext.policy_epoch_switch_pass == true and $$s.fuse_baseline.pass == true and $$s.fuse_baseline.feature_equivalent_baseline == true and $$s.fuse_baseline.fuse_mounts == $$samples and $$s.real_ccache_trace_basis == true and $$s.trace_derived_state_oracle == true and $$s.policy_executed == true and $$s.feature_equivalent_fuse == true and $$s.kvm_validated == true' "$(W4_CCACHE_BULK_CACHE_STATE_JSON)" >/dev/null
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-cache-state-policy-fuse.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-cache-state-policy-fuse.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-cache-state-policy-fuse-done","run_id":"%s","result_level":"kvm_real_ccache_trace_cache_state_policy_fuse","samples":%s,"objects":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_CACHE_STATE_SAMPLES)" "$(W4_CCACHE_BULK_CACHE_STATE_OBJECTS)" >>"$(W4_CCACHE_BULK_CACHE_STATE_JSON)"

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
	sha256sum "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(CACHE_LOCALITY_POLICY)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-policy-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-policy-compile-implementation.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_POLICY_COMPILE_INPUTS)"
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
	jq -cn --arg run_id "$(RUN_ID)" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" --argjson source_count "$$source_count" --argjson compile_jobs "$$compile_jobs" --argjson output_matches "$$output_matches" --argjson redirected "$$redirected" --argjson cache_path_ops "$$cache_path_ops" --argjson object_ops "$$object_ops" '{event:"w4-ccache-bulk-policy-compile-stats", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_compile_witness", workload:"w4-ccache-bulk-redis-nginx", run_environment:"kvm", policy_family:"cache_locality_view.bpf.c", real_ccache_run:true, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, source_count:$$source_count, attached_compile_jobs:$$compile_jobs, attached_compile_output_matches:$$output_matches, policy_redirected_cache_objects:$$redirected, attached_cache_path_file_ops:$$cache_path_ops, attached_policy_cache_object_ops:$$object_ops, cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, operation_weighted_policy_cache_hit_rate:false, operation_weighted_policy_hit_rate_is_release:false, detail:"bulk Redis/nginx ccache hot compiles ran under attached cache_locality policy"}' >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
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
	jq -c -s --arg run_id "$(RUN_ID)" --argjson samples "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" --argjson source_count "$$source_count" --argjson cache_miss "$$cache_miss" --argjson direct_cache_hit "$$direct_hit" --argjson local_storage_hit "$$local_hit" --argjson local_storage_write "$$local_write" '[.[] | select(.event == "w4-ccache-bulk-policy-compile-summary")] as $$rows | ($$rows | map(.failures // 0) | add // 0) as $$failures | ($$rows | map(.attached_compile_jobs // 0) | add // 0) as $$jobs | ($$rows | map(.attached_compile_output_matches // 0) | add // 0) as $$matches | ($$rows | map(.policy_redirected_cache_objects // 0) | add // 0) as $$redirected | ($$rows | map(.attached_cache_path_file_ops // 0) | add // 0) as $$cache_path_ops | ($$rows | map(.attached_policy_cache_object_ops // 0) | add // 0) as $$object_ops | ($$rows | all(.output_hash_match == true)) as $$hash_ok | {event:"w4-ccache-bulk-policy-compile-release-summary", run_id:$$run_id, result_level:"kvm_real_ccache_bulk_policy_compile_release_input", workload:"w4-ccache-bulk-redis-nginx", policy_family:"cache_locality_view.bpf.c", run_environment:"kvm", real_ccache_run:true, bulk_policy_compile:true, samples:$$samples, compile_rows:($$rows | length), source_manifest_count:$$source_count, attached_compile_jobs:$$jobs, attached_compile_output_matches:$$matches, policy_executed:true, ccache_compile_policy_executed:true, kvm_validated:true, output_hash_match:$$hash_ok, policy_redirected_cache_objects:$$redirected, attached_cache_path_file_ops:$$cache_path_ops, attached_policy_cache_object_ops:$$object_ops, attached_sampled_operation_hit_rate:(if $$cache_path_ops > 0 then ($$object_ops / $$cache_path_ops) else 0 end), cache_miss:$$cache_miss, direct_cache_hit:$$direct_cache_hit, local_storage_hit:$$local_storage_hit, local_storage_write:$$local_storage_write, pass:(($$rows | length) == $$samples and $$failures == 0 and $$hash_ok and $$jobs == ($$samples * $$source_count) and $$matches == $$jobs and $$cache_path_ops > 0 and $$object_ops > 0), failures:$$failures, operation_weighted_policy_cache_hit_rate:true, operation_weighted_policy_hit_rate_is_release:true, detail:"bulk Redis/nginx ccache hot compiles ran repeatedly under attached cache_locality policy"}' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" >"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON).release-summary"
	cat "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON).release-summary" >>"$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	jq -e --argjson samples "$(W4_CCACHE_BULK_POLICY_COMPILE_SAMPLES)" --argjson source_count "$$source_count" --argjson min_trace_objects "$(W4_CCACHE_BULK_MIN_TRACE_OBJECTS)" -s '([.[] | select(.event == "w4-ccache-bulk-policy-compile-release-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == true and $$s.ccache_compile_policy_executed == true and $$s.output_hash_match == true and $$s.attached_compile_jobs == ($$samples * $$source_count) and $$s.attached_compile_output_matches == $$s.attached_compile_jobs and $$s.policy_redirected_cache_objects >= ($$samples * $$min_trace_objects) and $$s.attached_cache_path_file_ops > 0 and $$s.attached_policy_cache_object_ops > 0 and $$s.operation_weighted_policy_hit_rate_is_release == true' "$(W4_CCACHE_BULK_POLICY_COMPILE_JSON)" >/dev/null
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
	test -s "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-native-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-native-ccache-baseline-implementation.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_NATIVE_COMPILE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_NATIVE_COMPILE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-native-compile-input","run_id":"%s","result_level":"kvm_external_native_ccache_compile_baseline","input_sha256_file":"w4-ccache-bulk-native-compile-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"baseline":"native_ccache_hot_compile"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-native-compile "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" "$(W4_CCACHE_BULK_NATIVE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	expected_rows="$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)"; \
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-native-compile-sample" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false and .direct_cache_hit >= .source_manifest_count and .compile_output_matches == .source_manifest_count)] | length' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_NATIVE_COMPILE_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-native-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.total_compile_jobs == ($$samples * $$source_count) and $$s.total_compile_output_matches == ($$samples * $$source_count) and $$s.direct_cache_hit >= ($$samples * $$source_count) and $$s.operation_weighted_native_hit_rate_is_release == true' "$(W4_CCACHE_BULK_NATIVE_COMPILE_JSON)" >/dev/null
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
	test -s "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-06-16-w4-bulk-fuse-compile-baseline-implementation.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_FUSE_COMPILE_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_FUSE_COMPILE_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-fuse-compile-input","run_id":"%s","result_level":"kvm_external_fuse_ccache_compile_baseline","input_sha256_file":"w4-ccache-bulk-fuse-compile-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"baseline":"fuse_redirect_compile","complete_ccache_compile_through_fuse":true}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-fuse-compile "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	expected_rows="$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)"; \
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-fuse-compile-sample" and .workload == "w4-ccache-bulk-redis-nginx" and .pass == true and .policy_executed == false and .complete_ccache_compile_through_fuse == true and .fuse_mounts == 1 and .direct_cache_hit >= .source_manifest_count and .compile_output_matches == .source_manifest_count)] | length' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)")" = "$$expected_rows"; \
	jq -e --argjson samples "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-fuse-compile-summary")][0]) as $$s | $$s.samples == $$samples and $$s.compile_rows == $$samples and $$s.pass == true and $$s.policy_executed == false and $$s.feature_equivalent_baseline == true and $$s.complete_ccache_compile_through_fuse == true and $$s.read_oriented_cache_view_only == false and $$s.total_compile_jobs == ($$samples * $$source_count) and $$s.total_compile_output_matches == ($$samples * $$source_count) and $$s.direct_cache_hit >= ($$samples * $$source_count) and $$s.fuse_mounts == $$samples and $$s.operation_weighted_fuse_hit_rate_is_release == true' "$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)" >/dev/null
	find "$(W4_CCACHE_BULK_FUSE_COMPILE_WORK_DIR)" -type f \( -name '*.fuse.o' -o -name '*.fuse.strace.log' -o -name 'ccache-fuse.log' \) -print | sort | xargs sha256sum >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-fuse-compile-outputs.sha256"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-compile.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-fuse-compile.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-fuse-compile-done","run_id":"%s","result_level":"kvm_external_fuse_ccache_compile_baseline","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_FUSE_COMPILE_SAMPLES)" >>"$(W4_CCACHE_BULK_FUSE_COMPILE_JSON)"

kvm-w4-ccache-bulk-compile-epoch-switch: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_compile_epoch_switch RUN_ID=$(RUN_ID) W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES=$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)"

__phase1_guest_w4_ccache_bulk_compile_epoch_switch:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-compile-epoch-switch-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_compile_epoch_switch","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)" >"$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md"
	test -s "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-compile-epoch-switch-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-07-24-build-cache-real-compile-epoch-plan.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-compile-epoch-switch-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_compile_epoch_switch","input_sha256_file":"w4-ccache-bulk-compile-epoch-switch-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"policy":"cache_locality_view.bpf.c","baseline":"feature_equivalent_fuse"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)" >>"$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-compile-epoch-switch "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(CACHE_LOCALITY_POLICY)"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	jq -e --argjson samples "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-compile-epoch-switch-summary")][0]) as $$s | $$s.samples == $$samples and $$s.pass == true and $$s.failures == 0 and $$s.source_manifest_count == $$source_count and $$s.namei_ext.pass == true and $$s.namei_ext.rows == $$samples and $$s.namei_ext.epoch1_compile_jobs == ($$samples * $$source_count) and $$s.namei_ext.epoch1_output_matches == $$s.namei_ext.epoch1_compile_jobs and $$s.namei_ext.epoch2_compile_jobs == ($$samples * $$source_count) and $$s.namei_ext.epoch2_output_matches == $$s.namei_ext.epoch2_compile_jobs and $$s.namei_ext.epoch1_direct_cache_hit >= ($$samples * $$source_count) and $$s.namei_ext.epoch2_direct_cache_hit >= ($$samples * $$source_count) and $$s.namei_ext.policy_session_updates == $$samples and $$s.fuse_baseline.pass == true and $$s.fuse_baseline.rows == $$samples and $$s.fuse_baseline.epoch1_compile_jobs == ($$samples * $$source_count) and $$s.fuse_baseline.epoch1_output_matches == $$s.fuse_baseline.epoch1_compile_jobs and $$s.fuse_baseline.epoch2_compile_jobs == ($$samples * $$source_count) and $$s.fuse_baseline.epoch2_output_matches == $$s.fuse_baseline.epoch2_compile_jobs and $$s.fuse_baseline.epoch1_direct_cache_hit >= ($$samples * $$source_count) and $$s.fuse_baseline.epoch2_direct_cache_hit >= ($$samples * $$source_count) and $$s.fuse_baseline.fuse_mounts == $$samples and $$s.real_compile_epoch_switch == true and $$s.miss_stale_corrupt_compile_cells_closed == false and $$s.feature_equivalent_fuse == true and $$s.kvm_validated == true' "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)" >/dev/null
	expected_rows=$$((2 * $(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES))); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-compile-epoch-switch-sample" and .pass == true and .real_compile_epoch_switch == true)] | length' "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)")" = "$$expected_rows"
	find "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_WORK_DIR)" -type f \( -name '*.policy-e1.o' -o -name '*.policy-e2.o' -o -name '*.fuse-e1.o' -o -name '*.fuse-e2.o' -o -name '*.policy-e1.strace.log' -o -name '*.policy-e2.strace.log' -o -name '*.fuse-e1.strace.log' -o -name '*.fuse-e2.strace.log' -o -name 'ccache-policy-epoch1-stats.txt' -o -name 'ccache-policy-epoch2-stats.txt' -o -name 'ccache-fuse-epoch1.log' -o -name 'ccache-fuse-epoch2.log' \) -print | sort | xargs sha256sum >"$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_OUTPUTS)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-compile-epoch-switch.log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-compile-epoch-switch.log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-compile-epoch-switch-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_compile_epoch_switch","samples":%s}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_SAMPLES)" >>"$(W4_CCACHE_BULK_COMPILE_EPOCH_SWITCH_JSON)"

kvm-w4-ccache-bulk-bad-local-fallback: $(KERNEL_IMAGE) bpf w1-oracle kvm-w4-ccache-bulk-policy-bridge
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_w4_ccache_bulk_bad_local_fallback RUN_ID=$(RUN_ID) W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES=$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES) W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE=$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)"

__phase1_guest_w4_ccache_bulk_bad_local_fallback:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"w4-ccache-bulk-bad-local-fallback-start","run_id":"%s","result_level":"kvm_real_ccache_bulk_bad_local_fallback","samples":%s,"mode":"%s"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)" >"$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_JSON)"
	test -s "$(W4_CCACHE_BULK_TRACE_INPUTS)"
	test -s "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache"
	test -d "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot"
	test -s "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_JSON)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)"
	test -s "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)"
	test -s "$(CACHE_LOCALITY_POLICY)"
	test -s "$(CACHE_LOCALITY_POLICY_SOURCE)"
	test -s "$(W4_ORACLE_RUNNER_SOURCE)"
	test -x "$(W4_ORACLE_RUNNER)"
	test -s "$(ROOT_DIR)/docs/tmp/2026-07-24-stale-corrupt-fallback-probe-design.md"
	test -s "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk"
	command -v ccache >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-ccache.path"
	ccache --version >"$(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-ccache.version"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	hot_objects=$$(find "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" -maxdepth 1 -type f -name '*.o' | wc -l); \
	test "$$source_count" -gt 1; \
	test "$$hot_objects" = "$$source_count"
	rm -rf "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR)"
	install -d "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR)"
	sha256sum "$(W4_CCACHE_BULK_TRACE_JSON)" "$(W4_CCACHE_BULK_TRACE_INPUTS)" "$(W4_CCACHE_BULK_TRACE_ARTIFACTS)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BRIDGE_JSON)" "$(W4_CCACHE_BULK_BRIDGE_TRACE_OBJECTS)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(CACHE_LOCALITY_POLICY)" "$(CACHE_LOCALITY_POLICY_SOURCE)" "$(W4_ORACLE_RUNNER_SOURCE)" "$(W4_ORACLE_RUNNER)" "$(PHASE1_RESULT_DIR)/w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)-ccache.version" "$(ROOT_DIR)/docs/tmp/2026-07-24-stale-corrupt-fallback-probe-design.md" "$(ROOT_DIR)/mk/experiments/legacy_build_cache.mk" >"$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_INPUTS)"
	sha256sum -c "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_INPUTS)" >/dev/null
	printf '{"event":"w4-ccache-bulk-bad-local-fallback-input","run_id":"%s","result_level":"kvm_real_ccache_bulk_bad_local_fallback","input_sha256_file":"w4-ccache-bulk-bad-local-fallback-%s-inputs.sha256","entries_tsv":"%s","source_manifest":"%s","work_dir":"%s","trace_cache_dir":"%s","baseline_hot_dir":"%s","samples":%s,"mode":"%s","policy":"cache_locality_view.bpf.c","baseline":"feature_equivalent_fuse"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)" >>"$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)"
	"$(W4_ORACLE_RUNNER)" --ccache-bulk-bad-local-fallback "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)" /sys/fs/cgroup "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/ccache" "$(W4_CCACHE_BULK_BRIDGE_ENTRIES_TSV)" "$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)" "$(REDIS_BUILD_SRC)" "$(NGINX_BUILD_SRC)" "$(W4_CCACHE_BULK_TRACE_WORK_DIR)/hot" "$(CACHE_LOCALITY_POLICY)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)"
	source_count=$$(wc -l <"$(W4_CCACHE_BULK_TRACE_SOURCE_MANIFEST)"); \
	jq -e --arg mode "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)" --argjson samples "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES)" --argjson source_count "$$source_count" -s '([.[] | select(.event == "w4-ccache-bulk-bad-local-fallback-summary")][0]) as $$s | $$s.mode == $$mode and $$s.samples == $$samples and $$s.pass == true and $$s.failures == 0 and $$s.source_manifest_count == $$source_count and $$s.namei_ext.pass == true and $$s.namei_ext.rows == $$samples and $$s.namei_ext.compile_jobs == ($$samples * $$source_count) and $$s.namei_ext.compile_output_matches == $$s.namei_ext.compile_jobs and $$s.namei_ext.direct_cache_hit >= ($$samples * $$source_count) and $$s.namei_ext.bad_local_objects >= $$s.cache_objects and $$s.namei_ext.bad_local_nonuse_checks == $$s.namei_ext.bad_local_nonuse_passes and $$s.fuse_baseline.pass == true and $$s.fuse_baseline.rows == $$samples and $$s.fuse_baseline.compile_jobs == ($$samples * $$source_count) and $$s.fuse_baseline.compile_output_matches == $$s.fuse_baseline.compile_jobs and $$s.fuse_baseline.direct_cache_hit >= ($$samples * $$source_count) and $$s.fuse_baseline.fuse_mounts == $$samples and $$s.fuse_baseline.bad_local_objects >= $$s.cache_objects and $$s.fuse_baseline.bad_local_nonuse_checks == $$s.fuse_baseline.bad_local_nonuse_passes and $$s.lookup_time_fallback == true and $$s.real_ccache_run == true and $$s.bfs_probe == true and $$s.feature_equivalent_fuse == true and $$s.kvm_validated == true and $$s.complete_miss_stale_corrupt_compile_state_machine == false' "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)" >/dev/null
	expected_rows=$$((2 * $(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES))); \
	test "$$(jq -s '[.[] | select(.event == "w4-ccache-bulk-bad-local-fallback-sample" and .pass == true and .bfs_probe == true)] | length' "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)")" = "$$expected_rows"
	find "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_WORK_DIR)" -type f \( -name '*.policy-bad-local.o' -o -name '*.fuse-bad-local.o' -o -name '*.policy-bad-local.strace.log' -o -name '*.fuse-bad-local.strace.log' -o -name 'ccache-policy-bad-local-stats.txt' -o -name 'ccache-fuse-bad-local.log' \) -print | sort | xargs sha256sum >"$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_OUTPUTS)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE).log"
	dmesg_issues=$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at|INFO: task .* blocked for more than/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)/dmesg-w4-ccache-bulk-bad-local-fallback-$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE).log"); test "$$dmesg_issues" = "0"
	printf '{"event":"w4-ccache-bulk-bad-local-fallback-done","run_id":"%s","result_level":"kvm_real_ccache_bulk_bad_local_fallback","samples":%s,"mode":"%s"}\n' "$(RUN_ID)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_SAMPLES)" "$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_MODE)" >>"$(W4_CCACHE_BULK_BAD_LOCAL_FALLBACK_JSON)"
