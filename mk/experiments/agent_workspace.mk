AGENT_WORKSPACE_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-preflight/$(RUN_ID)
AGENT_WORKSPACE_PREFLIGHT_JSON ?= $(AGENT_WORKSPACE_RESULT_DIR)/agent-workspace-preflight.jsonl
AGENT_WORKSPACE_MATRIX_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace/$(RUN_ID)
AGENT_WORKSPACE_MATRIX_JSON ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/observations.jsonl
AGENT_WORKSPACE_MATRIX_INPUTS ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/inputs.sha256
AGENT_WORKSPACE_MATRIX_ARTIFACTS ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/artifacts.sha256
AGENT_WORKSPACE_MATRIX_COMMAND ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/command.txt
AGENT_WORKSPACE_MATRIX_STDOUT ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/stdout.log
AGENT_WORKSPACE_MATRIX_STDERR ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/stderr.log
AGENT_WORKSPACE_MATRIX_DMESG ?= $(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/dmesg.log
AGENT_WORKSPACE_POLICY ?= $(BUILD_ROOT)/bpf/agent_workspace_view.bpf.o
AGENT_WORKSPACE_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/agent_workspace_view.bpf.c
AGENT_WORKSPACE_RUNNER ?= $(BUILD_ROOT)/agent-workspace/namei_ext_agent_workspace
AGENT_WORKSPACE_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace.c
AGENT_WORKSPACE_FUSE_RUNNER ?= $(BUILD_ROOT)/agent-workspace/namei_ext_agent_workspace_fuse
AGENT_WORKSPACE_FUSE_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace_fuse.c
AGENT_WORKSPACE_SOURCE_TRACE ?= $(ROOT_DIR)/experiments/agent_workspace/agentfs_lifecycle_trace.txt
AGENT_WORKSPACE_SUITE_MAKE ?= $(ROOT_DIR)/mk/experiments/agent_workspace.mk

.PHONY: kvm-agent-workspace-preflight kvm-agent-workspace-matrix __experiment_agent_workspace_preflight __experiment_agent_workspace_matrix

kvm-agent-workspace-preflight: $(KERNEL_IMAGE) bpf agent-workspace
	install -d "$(AGENT_WORKSPACE_RESULT_DIR)"
	$(call NAMEI_EXT_KVM_RUN,__experiment_agent_workspace_preflight,)

__experiment_agent_workspace_preflight: __namei_ext_guest_prepare
	install -d "$(AGENT_WORKSPACE_RESULT_DIR)"
	printf '{"event":"agent-workspace-preflight-start","run_id":"%s","result_level":"kvm_agent_workspace_dependency_preflight","policy":"agent_workspace_view.bpf.c"}\n' "$(RUN_ID)" >"$(AGENT_WORKSPACE_PREFLIGHT_JSON)"
	"$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_PREFLIGHT_JSON)" /sys/fs/cgroup
	"$(AGENT_WORKSPACE_FUSE_RUNNER)" "$(AGENT_WORKSPACE_PREFLIGHT_JSON)"
	dmesg >"$(AGENT_WORKSPACE_RESULT_DIR)/dmesg-agent-workspace-preflight.log"
	printf '{"event":"agent-workspace-preflight-done","run_id":"%s","result_level":"kvm_agent_workspace_dependency_preflight"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_PREFLIGHT_JSON)"

kvm-agent-workspace-matrix: $(KERNEL_IMAGE) bpf agent-workspace
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(AGENT_WORKSPACE_MATRIX_RESULT_DIR))
	$(call NAMEI_EXT_RUN_START,$(AGENT_WORKSPACE_MATRIX_RESULT_DIR),agent-workspace,agentfs-derived,kvm_agent_workspace_lifecycle_matrix,$(AGENT_WORKSPACE_MATRIX_JSON),agent_workspace_view.bpf.c,namei_ext_agent_workspace+fuse)
	$(call NAMEI_EXT_KVM_RUN_CAPTURE,$(KERNEL_IMAGE),__experiment_agent_workspace_matrix,,$(AGENT_WORKSPACE_MATRIX_RESULT_DIR),$(AGENT_WORKSPACE_MATRIX_RESULT_DIR))
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(AGENT_WORKSPACE_MATRIX_RESULT_DIR),$(AGENT_WORKSPACE_MATRIX_JSON))
	$(call NAMEI_EXT_RUN_COMPLETE,$(AGENT_WORKSPACE_MATRIX_RESULT_DIR))

__experiment_agent_workspace_matrix: __namei_ext_guest_prepare
	install -d "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)"
	: >"$(AGENT_WORKSPACE_MATRIX_STDOUT)"
	: >"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	printf 'make -C %s __experiment_agent_workspace_matrix RUN_ID=%s\n' "$(ROOT_DIR)" "$(RUN_ID)" >"$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	printf 'AGENT_WORKSPACE_POLICY=%s\nAGENT_WORKSPACE_RUNNER=%s\nAGENT_WORKSPACE_FUSE_RUNNER=%s\nAGENT_WORKSPACE_SOURCE_TRACE=%s\nKERNEL_IMAGE=%s\nKERNEL_BUILD_DIR=%s\n' "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_FUSE_RUNNER)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" "$(KERNEL_IMAGE)" "$(KERNEL_BUILD_DIR)" >>"$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	cp "$(KERNEL_BUILD_DIR)/.config" "$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/kernel.config"
	uname -a >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(AGENT_WORKSPACE_MATRIX_RESULT_DIR)/kernel-cmdline.txt"
	sha256sum "$(AGENT_WORKSPACE_POLICY_SOURCE)" "$(AGENT_WORKSPACE_RUNNER_SOURCE)" "$(AGENT_WORKSPACE_FUSE_RUNNER_SOURCE)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" "$(AGENT_WORKSPACE_SUITE_MAKE)" "$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/docs/tmp/2026-07-13-agent-workspace-complete-experiment-plan.md" >"$(AGENT_WORKSPACE_MATRIX_INPUTS)"
	sha256sum "$(KERNEL_IMAGE)" "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_FUSE_RUNNER)" >"$(AGENT_WORKSPACE_MATRIX_ARTIFACTS)"
	printf '{"event":"agent-workspace-matrix-start","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix","policy":"agent_workspace_view.bpf.c"}\n' "$(RUN_ID)" >"$(AGENT_WORKSPACE_MATRIX_JSON)"
	printf '{"event":"agent-workspace-provenance","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix","command_file":"command.txt","input_sha256_file":"inputs.sha256","artifact_sha256_file":"artifacts.sha256","kernel_config":"kernel.config","stdout_file":"stdout.log","stderr_file":"stderr.log"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	"$(AGENT_WORKSPACE_RUNNER)" --matrix "$(AGENT_WORKSPACE_POLICY)" "$(AGENT_WORKSPACE_MATRIX_JSON)" /sys/fs/cgroup "$(AGENT_WORKSPACE_SOURCE_TRACE)" >>"$(AGENT_WORKSPACE_MATRIX_STDOUT)" 2>>"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	"$(AGENT_WORKSPACE_FUSE_RUNNER)" --matrix "$(AGENT_WORKSPACE_MATRIX_JSON)" "$(AGENT_WORKSPACE_SOURCE_TRACE)" >>"$(AGENT_WORKSPACE_MATRIX_STDOUT)" 2>>"$(AGENT_WORKSPACE_MATRIX_STDERR)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"namei_ext","source_oracle":"AgentFS-derived bash/git workspace lifecycle","owned_methods":"lookup_policy,readdir_policy","daemon_state":"none","metadata_state":"target registry only","data_write_path_owner":"lower_filesystem","privileged_code_surface":"verified eBPF policy plus kernel validation","invalid_policy_containment":"unregistered target fails closed to ENOENT in this matrix","owns_filesystem_methods":false,"requires_daemon":false,"policy_verified":true,"lower_fs_owns_data_path":true,"detail":"bounded eBPF name-resolution policy; kernel and lower filesystem own VFS objects, methods, writes, and data path"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"feature_equivalent_fuse","source_oracle":"AgentFS-derived bash/git workspace lifecycle","owned_methods":"getattr,readdir,open,create,read,write,readlink,unlink,rename,truncate","daemon_state":"FUSE policy daemon and shared epoch state","metadata_state":"daemon-managed path translation and hidden-name state","data_write_path_owner":"FUSE request path over lower files","privileged_code_surface":"userspace filesystem daemon plus kernel FUSE interface","invalid_policy_containment":"daemon must implement path validation and failure behavior","owns_filesystem_methods":true,"requires_daemon":true,"policy_verified":false,"lower_fs_owns_data_path":false,"detail":"feature-equivalent FUSE policy filesystem implements filesystem operations for the same oracle"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	printf '{"event":"agent-workspace-boundary","run_id":"%s","result_level":"kvm_agent_workspace_boundary_evidence","mechanism":"custom_or_stackable_fs","source_oracle":"AgentFS/BranchFS/YoloFS-style workspace lifecycle","owned_methods":"lookup,readdir,create,unlink,rename,open_read_write_or_stackable_forwarding","daemon_state":"none for in-kernel stackable FS, runtime state for source services","metadata_state":"COW,checkpoint,whiteout,audit,cache-invalidation metadata","data_write_path_owner":"custom or stackable filesystem boundary when it owns COW/write semantics","privileged_code_surface":"kernel filesystem or stackable filesystem implementation","invalid_policy_containment":"implementation-specific validation across owned methods","owns_filesystem_methods":true,"requires_daemon":false,"policy_verified":false,"lower_fs_owns_data_path":false,"detail":"source-backed boundary evidence: broader filesystem designs own method, metadata, and failure surface beyond name-resolution policy"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
	if jq -e 'select(.pass == false)' "$(AGENT_WORKSPACE_MATRIX_JSON)" >/dev/null; then exit 1; fi
	dmesg >"$(AGENT_WORKSPACE_MATRIX_DMESG)"
	test -s "$(AGENT_WORKSPACE_MATRIX_COMMAND)"
	test -s "$(AGENT_WORKSPACE_MATRIX_INPUTS)"
	test -s "$(AGENT_WORKSPACE_MATRIX_ARTIFACTS)"
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
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_WORKSPACE_MATRIX_DMESG))
	printf '{"event":"agent-workspace-matrix-done","run_id":"%s","result_level":"kvm_agent_workspace_lifecycle_matrix"}\n' "$(RUN_ID)" >>"$(AGENT_WORKSPACE_MATRIX_JSON)"
