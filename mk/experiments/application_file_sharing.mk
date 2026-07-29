APPLICATION_FILE_SHARING_RESULT_DIR ?= $(RESULT_ROOT)/experiments/application-file-sharing/$(RUN_ID)
APPLICATION_FILE_SHARING_JSON ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/observations.jsonl
APPLICATION_FILE_SHARING_INPUTS ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/inputs.sha256
APPLICATION_FILE_SHARING_ARTIFACTS ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/artifacts.sha256
APPLICATION_FILE_SHARING_COMMAND ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/command.txt
APPLICATION_FILE_SHARING_STDOUT ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/stdout.log
APPLICATION_FILE_SHARING_STDERR ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/stderr.log
APPLICATION_FILE_SHARING_DMESG ?= $(APPLICATION_FILE_SHARING_RESULT_DIR)/dmesg.log
APPLICATION_FILE_SHARING_POLICY ?= $(BUILD_ROOT)/bpf/application_file_sharing.bpf.o
APPLICATION_FILE_SHARING_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/application_file_sharing.bpf.c
APPLICATION_FILE_SHARING_RUNNER ?= $(BUILD_ROOT)/application-file-sharing/namei_ext_application_file_sharing
APPLICATION_FILE_SHARING_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/application_file_sharing/namei_ext_application_file_sharing.c
APPLICATION_FILE_SHARING_SUITE_MAKE ?= $(ROOT_DIR)/mk/experiments/application_file_sharing.mk
NAMEI_EXT_HARNESS_SOURCE ?= $(ROOT_DIR)/runner/src/namei_ext_harness.c
NAMEI_EXT_HARNESS_HEADER ?= $(ROOT_DIR)/runner/include/namei_ext_harness.h
NAMEI_EXT_HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a

.PHONY: kvm-application-file-sharing-preflight __experiment_application_file_sharing_preflight

kvm-application-file-sharing-preflight: $(KERNEL_IMAGE) bpf application-file-sharing
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(APPLICATION_FILE_SHARING_RESULT_DIR))
	$(call NAMEI_EXT_RUN_START,$(APPLICATION_FILE_SHARING_RESULT_DIR),application-file-sharing,xdg-document-portal,kvm_application_file_sharing_preflight,$(APPLICATION_FILE_SHARING_JSON),application_file_sharing.bpf.c,namei_ext_application_file_sharing)
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" __namei_ext_kvm_capture \
		RUN_ID="$(RUN_ID)" \
		NAMEI_EXT_KVM_CAPTURE_IMAGE="$(KERNEL_IMAGE)" \
		NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET=__experiment_application_file_sharing_preflight \
		NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)" \
		NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(APPLICATION_FILE_SHARING_RESULT_DIR),$(APPLICATION_FILE_SHARING_JSON))
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_RESULT_DIR))

__experiment_application_file_sharing_preflight: __namei_ext_guest_prepare
	install -d "$(APPLICATION_FILE_SHARING_RESULT_DIR)"
	: >"$(APPLICATION_FILE_SHARING_STDOUT)"
	: >"$(APPLICATION_FILE_SHARING_STDERR)"
	printf 'make -C %s __experiment_application_file_sharing_preflight RUN_ID=%s\n' "$(ROOT_DIR)" "$(RUN_ID)" >"$(APPLICATION_FILE_SHARING_COMMAND)"
	sha256sum "$(APPLICATION_FILE_SHARING_POLICY_SOURCE)" "$(APPLICATION_FILE_SHARING_RUNNER_SOURCE)" "$(NAMEI_EXT_HARNESS_SOURCE)" "$(NAMEI_EXT_HARNESS_HEADER)" "$(APPLICATION_FILE_SHARING_SUITE_MAKE)" "$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/docs/tmp/2026-07-25-sandboxed-application-file-sharing-experiment-plan.md" >"$(APPLICATION_FILE_SHARING_INPUTS)"
	sha256sum "$(KERNEL_IMAGE)" "$(APPLICATION_FILE_SHARING_POLICY)" "$(APPLICATION_FILE_SHARING_RUNNER)" "$(NAMEI_EXT_HARNESS_LIBRARY)" >"$(APPLICATION_FILE_SHARING_ARTIFACTS)"
	uname -a >"$(APPLICATION_FILE_SHARING_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(APPLICATION_FILE_SHARING_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(APPLICATION_FILE_SHARING_RESULT_DIR)/kernel-cmdline.txt"
	cp "$(KERNEL_BUILD_DIR)/.config" "$(APPLICATION_FILE_SHARING_RESULT_DIR)/kernel.config"
	printf '{"event":"application-file-sharing-start","run_id":"%s","result_level":"kvm_application_file_sharing_preflight","workload":"sandboxed-application-file-sharing","source_system":"xdg-document-portal"}\n' "$(RUN_ID)" >"$(APPLICATION_FILE_SHARING_JSON)"
	"$(APPLICATION_FILE_SHARING_RUNNER)" "$(APPLICATION_FILE_SHARING_POLICY)" "$(APPLICATION_FILE_SHARING_JSON)" /sys/fs/cgroup >>"$(APPLICATION_FILE_SHARING_STDOUT)" 2>>"$(APPLICATION_FILE_SHARING_STDERR)"
	! jq -e 'select(.pass == false)' "$(APPLICATION_FILE_SHARING_JSON)" >/dev/null
	dmesg >"$(APPLICATION_FILE_SHARING_DMESG)"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(APPLICATION_FILE_SHARING_DMESG))
	printf '{"event":"application-file-sharing-done","run_id":"%s","result_level":"kvm_application_file_sharing_preflight"}\n' "$(RUN_ID)" >>"$(APPLICATION_FILE_SHARING_JSON)"
