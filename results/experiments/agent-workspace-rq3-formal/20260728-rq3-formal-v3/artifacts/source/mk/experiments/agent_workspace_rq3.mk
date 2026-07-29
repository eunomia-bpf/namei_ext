AGENT_WORKSPACE_RQ3_BUILD_DIR ?= $(BUILD_ROOT)/agent-workspace-rq3
AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE ?= $(ROOT_DIR)/thirdparty/wrapfs
AGENT_WORKSPACE_RQ3_WRAPFS_BUILD ?= $(AGENT_WORKSPACE_RQ3_BUILD_DIR)/wrapfs
AGENT_WORKSPACE_RQ3_WRAPFS_MODULE ?= $(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)/wrapfs.ko
AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR ?= $(ROOT_DIR)/experiments/agent_workspace_rq3
AGENT_WORKSPACE_RQ3_FAULT_RUNNER ?= $(AGENT_WORKSPACE_RQ3_BUILD_DIR)/namei_ext_rq3_faults
AGENT_WORKSPACE_RQ3_FAULT_SOURCE ?= $(AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR)/namei_ext_rq3_faults.c
AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER ?= $(AGENT_WORKSPACE_RQ3_BUILD_DIR)/wrapfs_agent_workspace_rq3
AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER_SOURCE ?= $(AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR)/wrapfs_agent_workspace_rq3.c
AGENT_WORKSPACE_RQ3_LIBBPF_A ?= $(BUILD_ROOT)/libbpf/libbpf.a
AGENT_WORKSPACE_RQ3_SUITE_MAKE ?= $(ROOT_DIR)/mk/experiments/agent_workspace_rq3.mk
AGENT_WORKSPACE_RQ3_INVALID_CTX_POLICY ?= $(BUILD_ROOT)/bpf/rq3_invalid_ctx_write.bpf.o
AGENT_WORKSPACE_RQ3_INVALID_ACTION_POLICY ?= $(BUILD_ROOT)/bpf/rq3_invalid_action.bpf.o
AGENT_WORKSPACE_RQ3_FAULT_POLICY ?= $(BUILD_ROOT)/bpf/rq3_fault_injection.bpf.o
AGENT_WORKSPACE_RQ3_FAULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq3-faults/$(RUN_ID)
AGENT_WORKSPACE_RQ3_FAULT_JSON ?= $(AGENT_WORKSPACE_RQ3_FAULT_DIR)/observations.jsonl
AGENT_WORKSPACE_RQ3_FAULT_DMESG ?= $(AGENT_WORKSPACE_RQ3_FAULT_DIR)/dmesg.log
AGENT_WORKSPACE_RQ3_FAULT_ROOT ?= /dev/shm/namei-ext-rq3-faults-$(RUN_ID)
AGENT_WORKSPACE_RQ3_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq3/$(RUN_ID)
AGENT_WORKSPACE_RQ3_FORMAL_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq3-formal/$(RUN_ID)
AGENT_WORKSPACE_RQ3_FORMAL_BOOTS ?= 3
AGENT_WORKSPACE_RQ3_RUN_ROLE ?= preflight
AGENT_WORKSPACE_RQ3_ANALYSIS ?= $(ROOT_DIR)/analysis/agent_workspace_rq3/analyze.py
AGENT_WORKSPACE_RQ3_SEMANTIC_ORACLES ?= \
	$(AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR)/semantic_oracles.h
AGENT_WORKSPACE_RQ3_REPORT_JSON ?= $(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/report.json
AGENT_WORKSPACE_RQ3_REPORT_MD ?= $(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/report.md
AGENT_WORKSPACE_RQ3_JSON ?= $(AGENT_WORKSPACE_RQ3_RESULT_DIR)/observations.jsonl
AGENT_WORKSPACE_RQ3_DMESG ?= $(AGENT_WORKSPACE_RQ3_RESULT_DIR)/dmesg.log
AGENT_WORKSPACE_RQ3_WRAPFS_TRACE ?= $(AGENT_WORKSPACE_RQ3_RESULT_DIR)/wrapfs-kprobe.trace
AGENT_WORKSPACE_RQ3_EXT4_IMAGE ?= /dev/shm/namei-ext-rq3-$(RUN_ID).ext4
AGENT_WORKSPACE_RQ3_EXT4_ROOT ?= /dev/shm/namei-ext-rq3-root-$(RUN_ID)
AGENT_WORKSPACE_RQ3_AGENT_CGROUP ?= /sys/fs/cgroup/namei-ext-rq3-agent-$(RUN_ID)
AGENT_WORKSPACE_RQ3_FAULT_CGROUP ?= /sys/fs/cgroup/namei-ext-rq3-fault-$(RUN_ID)
AGENT_WORKSPACE_RQ3_TRACE_GROUP ?= namei_ext_rq3
AGENT_WORKSPACE_RQ3_KPROBES := \
	fill_super:wrapfs_fill_super \
	put_super:wrapfs_put_super \
	lookup:wrapfs_lookup \
	readdir:wrapfs_readdir \
	open:wrapfs_open \
	read_iter:wrapfs_read_iter \
	write_iter:wrapfs_write_iter \
	fsync:wrapfs_fsync \
	getattr:wrapfs_getattr \
	setattr:wrapfs_setattr \
	create:wrapfs_create \
	rename:wrapfs_rename \
	unlink:wrapfs_unlink
AGENT_WORKSPACE_RQ3_SMOKE_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq3-module-smoke/$(RUN_ID)
AGENT_WORKSPACE_RQ3_SMOKE_JSON ?= $(AGENT_WORKSPACE_RQ3_SMOKE_DIR)/observations.jsonl
AGENT_WORKSPACE_RQ3_SMOKE_DMESG ?= $(AGENT_WORKSPACE_RQ3_SMOKE_DIR)/dmesg.log
AGENT_WORKSPACE_RQ3_SMOKE_ROOT ?= /dev/shm/namei-ext-rq3-wrapfs-smoke
AGENT_WORKSPACE_RQ3_WRAPFS_SOURCES := \
	$(wildcard $(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/*.[ch]) \
	$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/Makefile \
	$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/UPSTREAM.md
AGENT_WORKSPACE_RQ3_KERNEL_INTEGRATION_SOURCES := \
	$(KERNEL_DIR)/fs/namei.c \
	$(KERNEL_DIR)/fs/namei_ext.c \
	$(KERNEL_DIR)/fs/readdir.c \
	$(KERNEL_DIR)/include/linux/bpf-cgroup-defs.h \
	$(KERNEL_DIR)/include/linux/bpf-cgroup.h \
	$(KERNEL_DIR)/include/linux/namei_ext.h \
	$(KERNEL_DIR)/include/uapi/linux/bpf.h \
	$(KERNEL_DIR)/kernel/bpf/cgroup.c \
	$(KERNEL_DIR)/kernel/bpf/verifier.c
AGENT_WORKSPACE_RQ3_FUSE_KERNEL_SOURCES := \
	$(KERNEL_DIR)/fs/fuse/Makefile \
	$(wildcard $(KERNEL_DIR)/fs/fuse/*.c)

.PHONY: agent-workspace-rq3-wrapfs \
	kvm-agent-workspace-rq3-module-smoke \
	kvm-agent-workspace-rq3-faults \
	kvm-agent-workspace-rq3-preflight \
	kvm-agent-workspace-rq3 \
	experiment-agent-workspace-rq3 \
	agent-workspace-rq3-analysis-test \
	agent-workspace-rq3-report \
	__experiment_agent_workspace_rq3_module_smoke \
	__experiment_agent_workspace_rq3_faults \
	__experiment_agent_workspace_rq3_preflight

agent-workspace-rq3-wrapfs: $(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE)

kvm-agent-workspace-rq3-module-smoke: $(KERNEL_IMAGE) agent-workspace-rq3-wrapfs
	install -d "$(AGENT_WORKSPACE_RQ3_SMOKE_DIR)"
	$(call NAMEI_EXT_KVM_RUN,__experiment_agent_workspace_rq3_module_smoke,)

kvm-agent-workspace-rq3-faults: $(KERNEL_IMAGE) bpf $(AGENT_WORKSPACE_RQ3_FAULT_RUNNER)
	install -d "$(AGENT_WORKSPACE_RQ3_FAULT_DIR)"
	$(call NAMEI_EXT_KVM_RUN,__experiment_agent_workspace_rq3_faults,)

kvm-agent-workspace-rq3-preflight kvm-agent-workspace-rq3: \
			kernel-provenance $(KERNEL_IMAGE) bpf \
			agent-workspace agent-workspace-rq3-wrapfs \
			$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER) \
			$(AGENT_WORKSPACE_RQ3_FAULT_RUNNER)
	install -d "$(AGENT_WORKSPACE_RQ3_RESULT_DIR)"
	project_commit=$$(git -C "$(ROOT_DIR)" rev-parse HEAD); \
	kernel_commit=$$(git -C "$(KERNEL_DIR)" rev-parse HEAD); \
	kernel_submodule_commit=$$(git -C "$(ROOT_DIR)" ls-tree HEAD kernel | \
		awk '{print $$3}'); \
	wrapfs_upstream_commit=$$(sed -n \
		's/^- commit: `\([0-9a-f]\{40\}\)`/\1/p' \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/UPSTREAM.md"); \
	project_dirty=false; \
	kernel_dirty=false; \
	test -z "$$(git -C "$(ROOT_DIR)" status --porcelain --untracked-files=all)" || \
		project_dirty=true; \
	test -z "$$(git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=all)" || \
		kernel_dirty=true; \
	test -n "$$project_commit"; \
	test -n "$$kernel_commit"; \
	test -n "$$kernel_submodule_commit"; \
	test -n "$$wrapfs_upstream_commit"; \
	jq -n --arg project_commit "$$project_commit" \
		--arg kernel_commit "$$kernel_commit" \
		--arg kernel_submodule_commit "$$kernel_submodule_commit" \
		--arg wrapfs_upstream_commit "$$wrapfs_upstream_commit" \
		--argjson project_dirty "$$project_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
		'{project_commit:$$project_commit,project_dirty:$$project_dirty,kernel_commit:$$kernel_commit,kernel_dirty:$$kernel_dirty,kernel_submodule_commit:$$kernel_submodule_commit,wrapfs_upstream_commit:$$wrapfs_upstream_commit}' \
		>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/provenance.json"
	$(call NAMEI_EXT_KVM_RUN,__experiment_agent_workspace_rq3_preflight,AGENT_WORKSPACE_RQ3_RESULT_DIR=$(AGENT_WORKSPACE_RQ3_RESULT_DIR) AGENT_WORKSPACE_RQ3_RUN_ROLE=$(AGENT_WORKSPACE_RQ3_RUN_ROLE))

experiment-agent-workspace-rq3:
	test "$(AGENT_WORKSPACE_RQ3_FORMAL_BOOTS)" -eq 3
	test ! -e "$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)"
	install -d "$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)"
	printf 'make experiment-agent-workspace-rq3 RUN_ID=%s\n' "$(RUN_ID)" \
		>"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/command.txt"
	for boot in $$(seq -w 1 "$(AGENT_WORKSPACE_RQ3_FORMAL_BOOTS)"); do \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			kvm-agent-workspace-rq3 \
			RUN_ID="$(RUN_ID)-boot-$$boot" \
			AGENT_WORKSPACE_RQ3_RUN_ROLE=formal \
			AGENT_WORKSPACE_RQ3_RESULT_DIR="$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot"; \
	done
	for boot in $$(seq -w 1 "$(AGENT_WORKSPACE_RQ3_FORMAL_BOOTS)"); do \
		jq -e 'select(.event == "rq3-preflight-done" and .pass == true and .run_role == "formal")' \
			"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot/observations.jsonl" >/dev/null; \
		sha256sum \
			"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot/observations.jsonl" \
			"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot/wrapfs-kprobe.trace" \
			"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot/invalid-ctx-verifier.log" \
			"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/boot-$$boot/invalid-action-verifier.log"; \
	done >"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/formal-artifacts.sha256"
	jq -n \
		--arg schema "namei_ext.agent_workspace_rq3.formal.v2" \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--argjson boots "$(AGENT_WORKSPACE_RQ3_FORMAL_BOOTS)" \
		'{schema:$$schema,run_id:$$run_id,generated_at:$$generated_at,boots:$$boots,completed_boots:$$boots,pass:true,lower_fs:"ext4",mechanisms:["namei_ext","wrapfs-derived"],fault_matrix:true,kprobe_attribution:true}' \
		>"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/formal-summary.json"
	jq -e '.pass == true and .boots == 3 and .completed_boots == 3' \
		"$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/formal-summary.json" >/dev/null
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		agent-workspace-rq3-report RUN_ID="$(RUN_ID)"

agent-workspace-rq3-analysis-test:
	python3 -m unittest discover \
		-s "$(ROOT_DIR)/analysis/agent_workspace_rq3" \
		-p 'test_*.py' -v

agent-workspace-rq3-report: agent-workspace-rq3-analysis-test
	test -f "$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)/formal-summary.json"
	python3 "$(AGENT_WORKSPACE_RQ3_ANALYSIS)" \
		--formal-dir "$(AGENT_WORKSPACE_RQ3_FORMAL_DIR)" \
		--root "$(ROOT_DIR)" \
		--json "$(AGENT_WORKSPACE_RQ3_REPORT_JSON)" \
		--markdown "$(AGENT_WORKSPACE_RQ3_REPORT_MD)"
	jq -e '.all_oracles_passed == true and .completed_boots == 3 and .namei_fd_policy_counter_unchanged_boots == 3' \
		"$(AGENT_WORKSPACE_RQ3_REPORT_JSON)" >/dev/null

__experiment_agent_workspace_rq3_preflight: __namei_ext_guest_prepare
	command -v mkfs.ext4 >/dev/null
	command -v losetup >/dev/null
	command -v sha256sum >/dev/null
	install -d "$(AGENT_WORKSPACE_RQ3_RESULT_DIR)" \
		"$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)"
	rm -f "$(AGENT_WORKSPACE_RQ3_EXT4_IMAGE)"
	truncate -s 512M "$(AGENT_WORKSPACE_RQ3_EXT4_IMAGE)"
	mkfs.ext4 -q -F "$(AGENT_WORKSPACE_RQ3_EXT4_IMAGE)" \
		>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/mkfs.stdout.log" \
		2>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/mkfs.stderr.log"
	mount -t ext4 -o loop "$(AGENT_WORKSPACE_RQ3_EXT4_IMAGE)" \
		"$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)"
	test "$$(findmnt -n -o FSTYPE "$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)")" = ext4
	findmnt "$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)" \
		>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/lower-filesystem.txt"
	cp "$(KERNEL_BUILD_DIR)/.config" \
		"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/kernel.config"
	uname -a >"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/proc-version.txt"
	test -s "$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/provenance.json"
	sha256sum "$(KERNEL_IMAGE)" "$(AGENT_WORKSPACE_POLICY)" \
		"$(AGENT_WORKSPACE_RUNNER)" "$(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE)" \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_RUNNER)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_CTX_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_ACTION_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_POLICY)" \
		>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/artifacts.sha256"
	sha256sum "$(AGENT_WORKSPACE_RUNNER_SOURCE)" \
		"$(AGENT_WORKSPACE_FUSE_RUNNER_SOURCE)" \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER_SOURCE)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_SOURCE)" \
		"$(AGENT_WORKSPACE_RQ3_ANALYSIS)" \
		"$(AGENT_WORKSPACE_RQ3_SEMANTIC_ORACLES)" \
		"$(ROOT_DIR)/experiments/agent_workspace/Makefile" \
		"$(ROOT_DIR)/bpf/policies/agent_workspace_view.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/rq3_invalid_ctx_write.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/rq3_invalid_action.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/rq3_fault_injection.bpf.c" \
		"$(AGENT_WORKSPACE_SOURCE_TRACE)" \
		"$(AGENT_WORKSPACE_RQ3_SUITE_MAKE)" \
		$(AGENT_WORKSPACE_RQ3_KERNEL_INTEGRATION_SOURCES) \
		$(AGENT_WORKSPACE_RQ3_FUSE_KERNEL_SOURCES) \
		$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCES) \
		>"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/inputs.sha256"
	printf '{"event":"rq3-preflight-start","run_id":"%s","run_role":"%s","lower_fs":"ext4"}\n' \
		"$(RUN_ID)" "$(AGENT_WORKSPACE_RQ3_RUN_ROLE)" \
		>"$(AGENT_WORKSPACE_RQ3_JSON)"
	test ! -e "$(AGENT_WORKSPACE_RQ3_AGENT_CGROUP)"
	mkdir "$(AGENT_WORKSPACE_RQ3_AGENT_CGROUP)"
	namei_status=0; \
	NAMEI_EXT_AGENT_WORKSPACE_WORK_ROOT="$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)" \
		"$(AGENT_WORKSPACE_RUNNER)" --rq3 "$(AGENT_WORKSPACE_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_JSON)" "$(AGENT_WORKSPACE_RQ3_AGENT_CGROUP)" \
		"$(AGENT_WORKSPACE_SOURCE_TRACE)" || namei_status=$$?; \
	dmesg >"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/dmesg-namei-ext.log"; \
	test "$$namei_status" -eq 0; \
	test ! -e "$(AGENT_WORKSPACE_RQ3_AGENT_CGROUP)"
	insmod "$(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE)"
	grep -F wrapfs /proc/filesystems >/dev/null
	trace_root=/sys/kernel/debug/tracing; \
	test -w "$$trace_root/kprobe_events"; \
	: >"$$trace_root/trace"; \
	for spec in $(AGENT_WORKSPACE_RQ3_KPROBES); do \
		event=$${spec%%:*}; symbol=$${spec#*:}; \
		printf 'p:%s/%s %s\n' "$(AGENT_WORKSPACE_RQ3_TRACE_GROUP)" \
			"$$event" "$$symbol" >>"$$trace_root/kprobe_events"; \
	done; \
	printf 1 >"$$trace_root/events/$(AGENT_WORKSPACE_RQ3_TRACE_GROUP)/enable"; \
	wrapfs_status=0; \
	NAMEI_EXT_RQ3_WRAPFS_PRELOADED=1 \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER)" \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE)" \
		"$(AGENT_WORKSPACE_RQ3_JSON)" \
		"$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)" \
		"$(AGENT_WORKSPACE_SOURCE_TRACE)" || wrapfs_status=$$?; \
	printf 0 >"$$trace_root/events/$(AGENT_WORKSPACE_RQ3_TRACE_GROUP)/enable"; \
	cat "$$trace_root/trace" >"$(AGENT_WORKSPACE_RQ3_WRAPFS_TRACE)"; \
	for spec in $(AGENT_WORKSPACE_RQ3_KPROBES); do \
		event=$${spec%%:*}; \
		printf -- '-:%s/%s\n' "$(AGENT_WORKSPACE_RQ3_TRACE_GROUP)" \
			"$$event" >>"$$trace_root/kprobe_events"; \
	done; \
	rmmod wrapfs; \
	dmesg >"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/dmesg-wrapfs.log"; \
	test "$$wrapfs_status" -eq 0
	for spec in $(AGENT_WORKSPACE_RQ3_KPROBES); do \
		event=$${spec%%:*}; \
		grep -F ": $$event:" \
			"$(AGENT_WORKSPACE_RQ3_WRAPFS_TRACE)" >/dev/null; \
	done
	rm -rf "$(AGENT_WORKSPACE_RQ3_FAULT_ROOT)"
	test ! -e "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	mkdir "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	"$(AGENT_WORKSPACE_RQ3_FAULT_RUNNER)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_CTX_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_ACTION_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_JSON)" \
		"$(AGENT_WORKSPACE_RQ3_RESULT_DIR)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)" \
		"$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)/rq3-faults"
	test ! -e "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	dmesg >"$(AGENT_WORKSPACE_RQ3_DMESG)"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_WORKSPACE_RQ3_DMESG))
	for case in agent_workspace_rq3_summary rq3_selected_fd_open \
		rq3_fd_read rq3_fd_write rq3_fd_fsync rq3_fd_fstat \
		rq3_fd_fchmod rq3_fd_policy_not_reentered \
		rq3_fd_lower_mutation rq3_old_fd_read rq3_old_fd_write \
		rq3_old_fd_lower_mutation rq3_old_fd_close \
		rq3_child_cgroup_entered rq3_child_cgroup_removed \
		logical_after_detach \
		base_epoch_exec_tool upper_epoch_exec_tool \
		upper_epoch_create_write_fsync_fchmod_fstat \
		agentfs_cached_negative_readdir_visible; do \
		jq -e --arg case "$$case" \
			'select(.case == $$case and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ3_JSON)" >/dev/null; \
	done
	for case in agentfs_source_trace setup_workspace_fixtures \
		base_lookup_main base_lookup_deleted_hidden \
		base_readdir_deleted_hidden base_main_mode base_exec_tool \
		base_unprivileged_access_denied upper_lookup_main upper_main_mode \
		base_denied_mode \
		upper_lookup_deleted_hidden upper_readdir_deleted_hidden \
		upper_exec_tool upper_unprivileged_access_denied upper_denied_mode \
		generated_create_write_fsync_fchmod_fstat \
		cached_negative_create rename_generated_to_renamed \
		unlink_cached_negative final_lower_tree_manifest \
		rq3_wrapfs_complete; do \
		jq -e --arg case "$$case" \
			'select(.case == $$case and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ3_JSON)" >/dev/null; \
	done
	for case in verifier_reject_ctx_write verifier_reject_action_4 \
		redirect_len_zero redirect_len_zero_readdir redirect_len_65 \
		redirect_len_65_readdir redirect_dot redirect_dot_readdir \
		redirect_dot_dot redirect_dot_dot_readdir redirect_slash \
		redirect_slash_readdir redirect_embedded_nul \
		redirect_embedded_nul_readdir target_cache_drop target_zero \
		target_zero_warm target_unregistered \
		select_readdir select_create redirect_create select_final_open \
		target_teardown policy_teardown fault_child_cgroup_entered \
		fault_child_cgroup_removed \
		post_teardown_lower_access; do \
		jq -e --arg case "$$case" \
			'select(.case == $$case and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ3_JSON)" >/dev/null; \
	done
	for condition in namei_ext wrapfs; do \
		jq -e --arg condition "$$condition" \
			'select(.event == "rq3-lower-tree-manifest" and .condition == $$condition and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ3_JSON)" >/dev/null; \
		test "$$(jq -sr --arg condition "$$condition" \
			'[.[] | select(.event == "rq3-semantic-oracle" and .condition == $$condition)] | length' \
			"$(AGENT_WORKSPACE_RQ3_JSON)")" -eq 37; \
	done
	jq -e 'select(.event == "rq3-fault-summary" and .pass == true)' \
		"$(AGENT_WORKSPACE_RQ3_JSON)" >/dev/null
	test -s "$(AGENT_WORKSPACE_RQ3_WRAPFS_TRACE)"
	test -s "$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/invalid-ctx-verifier.log"
	test -s "$(AGENT_WORKSPACE_RQ3_RESULT_DIR)/invalid-action-verifier.log"
	printf '{"event":"rq3-preflight-done","run_id":"%s","run_role":"%s","pass":true}\n' \
		"$(RUN_ID)" "$(AGENT_WORKSPACE_RQ3_RUN_ROLE)" \
		>>"$(AGENT_WORKSPACE_RQ3_JSON)"
	umount "$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)"
	rm -rf "$(AGENT_WORKSPACE_RQ3_EXT4_ROOT)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_ROOT)"
	rm -f "$(AGENT_WORKSPACE_RQ3_EXT4_IMAGE)"

__experiment_agent_workspace_rq3_faults: __namei_ext_guest_prepare
	command -v sha256sum >/dev/null
	install -d "$(AGENT_WORKSPACE_RQ3_FAULT_DIR)"
	rm -rf "$(AGENT_WORKSPACE_RQ3_FAULT_ROOT)"
	cp "$(KERNEL_BUILD_DIR)/.config" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_DIR)/kernel.config"
	uname -a >"$(AGENT_WORKSPACE_RQ3_FAULT_DIR)/uname.txt"
	printf '{"event":"rq3-fault-run-start","run_id":"%s"}\n' \
		"$(RUN_ID)" >"$(AGENT_WORKSPACE_RQ3_FAULT_JSON)"
	test ! -e "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	mkdir "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	"$(AGENT_WORKSPACE_RQ3_FAULT_RUNNER)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_CTX_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_INVALID_ACTION_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_POLICY)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_JSON)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_DIR)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)" \
		"$(AGENT_WORKSPACE_RQ3_FAULT_ROOT)"
	test ! -e "$(AGENT_WORKSPACE_RQ3_FAULT_CGROUP)"
	dmesg >"$(AGENT_WORKSPACE_RQ3_FAULT_DMESG)"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_WORKSPACE_RQ3_FAULT_DMESG))
	for case in verifier_reject_ctx_write verifier_reject_action_4 \
		fixture_setup fault_policy_attach register_target \
		redirect_len_zero redirect_len_65 redirect_dot redirect_dot_dot \
		redirect_slash redirect_embedded_nul \
		redirect_len_zero_readdir redirect_len_65_readdir \
		redirect_dot_readdir redirect_dot_dot_readdir \
		redirect_slash_readdir redirect_embedded_nul_readdir \
		target_cache_drop target_zero target_zero_warm \
		target_unregistered select_readdir select_create redirect_create \
		select_final_open target_teardown policy_teardown \
		fault_child_cgroup_entered fault_child_cgroup_removed \
		post_teardown_lower_access; do \
		jq -e --arg case "$$case" \
			'select(.case == $$case and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ3_FAULT_JSON)" >/dev/null; \
	done
	jq -e 'select(.event == "rq3-fault-summary" and .pass == true)' \
		"$(AGENT_WORKSPACE_RQ3_FAULT_JSON)" >/dev/null
	test -s "$(AGENT_WORKSPACE_RQ3_FAULT_DIR)/invalid-ctx-verifier.log"
	test -s "$(AGENT_WORKSPACE_RQ3_FAULT_DIR)/invalid-action-verifier.log"
	printf '{"event":"rq3-fault-run-done","run_id":"%s","pass":true}\n' \
		"$(RUN_ID)" >>"$(AGENT_WORKSPACE_RQ3_FAULT_JSON)"
	rm -rf "$(AGENT_WORKSPACE_RQ3_FAULT_ROOT)"

__experiment_agent_workspace_rq3_module_smoke:
	install -d "$(AGENT_WORKSPACE_RQ3_SMOKE_DIR)"
	rm -rf "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)"
	install -d "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower" \
		"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount"
	printf 'base-main\n' >"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/main.txt"
	printf 'must-be-hidden\n' >"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/deleted.txt"
	printf '{"event":"rq3-wrapfs-module-smoke-start","run_id":"%s"}\n' \
		"$(RUN_ID)" >"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	insmod "$(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE)"
	grep -F wrapfs /proc/filesystems >/dev/null
	mount -t wrapfs "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower" \
		"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount" || \
		{ dmesg >"$(AGENT_WORKSPACE_RQ3_SMOKE_DMESG)"; \
		tail -n 80 "$(AGENT_WORKSPACE_RQ3_SMOKE_DMESG)" >&2; exit 1; }
	test "$$(cat "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/main.txt")" = base-main
	printf '{"event":"oracle","case":"lookup_visible","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	test ! -e "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/deleted.txt"
	printf '{"event":"oracle","case":"lookup_hidden","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	find "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount" -maxdepth 1 \
		-printf '%f\n' >"$(AGENT_WORKSPACE_RQ3_SMOKE_DIR)/readdir.txt"
	grep -Fx main.txt "$(AGENT_WORKSPACE_RQ3_SMOKE_DIR)/readdir.txt" >/dev/null
	! grep -Fx deleted.txt "$(AGENT_WORKSPACE_RQ3_SMOKE_DIR)/readdir.txt" >/dev/null
	printf '{"event":"oracle","case":"readdir_hidden","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	printf 'created\n' >"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/created.txt"
	sync "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/created.txt"
	test "$$(cat "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/created.txt")" = created
	printf '{"event":"oracle","case":"write_through","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	mv "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/created.txt" \
		"$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/renamed.txt"
	test -f "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/renamed.txt"
	test ! -e "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/created.txt"
	printf '{"event":"oracle","case":"rename_through","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	rm "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount/renamed.txt"
	test ! -e "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/lower/renamed.txt"
	printf '{"event":"oracle","case":"unlink_through","pass":true}\n' \
		>>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	umount "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)/mount"
	rmmod wrapfs
	dmesg >"$(AGENT_WORKSPACE_RQ3_SMOKE_DMESG)"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_WORKSPACE_RQ3_SMOKE_DMESG))
	printf '{"event":"rq3-wrapfs-module-smoke-done","run_id":"%s","pass":true}\n' \
		"$(RUN_ID)" >>"$(AGENT_WORKSPACE_RQ3_SMOKE_JSON)"
	rm -rf "$(AGENT_WORKSPACE_RQ3_SMOKE_ROOT)"

$(AGENT_WORKSPACE_RQ3_WRAPFS_MODULE): $(KERNEL_IMAGE) \
		$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCES)
	rm -rf "$(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)"
	install -d "$(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)"
	install -m 0444 $(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/*.[ch] \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)/"
	install -m 0444 "$(AGENT_WORKSPACE_RQ3_WRAPFS_SOURCE)/Makefile" \
		"$(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)/Makefile"
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" \
		modules_prepare -j"$(JOBS)"
	cp "$(KERNEL_BUILD_DIR)/vmlinux.symvers" \
		"$(KERNEL_BUILD_DIR)/Module.symvers"
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" \
		M="$(AGENT_WORKSPACE_RQ3_WRAPFS_BUILD)" modules -j"$(JOBS)"
	test -f "$@"

$(AGENT_WORKSPACE_RQ3_FAULT_RUNNER): $(AGENT_WORKSPACE_RQ3_FAULT_SOURCE) \
		$(AGENT_WORKSPACE_RQ3_LIBBPF_A) | $(AGENT_WORKSPACE_RQ3_BUILD_DIR)
	$(CC) -g -O2 -Wall -Wextra -Werror \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(BUILD_ROOT)/libbpf" \
		-o "$@" "$<" "$(AGENT_WORKSPACE_RQ3_LIBBPF_A)" -lelf -lz

$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER): \
		$(AGENT_WORKSPACE_RQ3_WRAPFS_RUNNER_SOURCE) \
		$(AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR)/Makefile
	$(MAKE) -C "$(AGENT_WORKSPACE_RQ3_EXPERIMENT_DIR)" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(AGENT_WORKSPACE_RQ3_BUILD_DIR)" "$@"

$(AGENT_WORKSPACE_RQ3_LIBBPF_A):
	$(MAKE) -C "$(ROOT_DIR)/experiments/agent_workspace" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" "$@"

$(AGENT_WORKSPACE_RQ3_BUILD_DIR):
	install -d "$@"
