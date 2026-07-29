BUILD_ACTION_SANDBOXING_RESULT_DIR ?= $(RESULT_ROOT)/experiments/build-action-sandboxing/$(RUN_ID)
BUILD_ACTION_SANDBOXING_JSON ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/observations.jsonl
BUILD_ACTION_SANDBOXING_INPUTS ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/inputs.sha256
BUILD_ACTION_SANDBOXING_ARTIFACTS ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/artifacts.sha256
BUILD_ACTION_SANDBOXING_OUTPUTS ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/outputs.sha256
BUILD_ACTION_SANDBOXING_COMMAND ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/command.txt
BUILD_ACTION_SANDBOXING_STDOUT ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/stdout.log
BUILD_ACTION_SANDBOXING_STDERR ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/stderr.log
BUILD_ACTION_SANDBOXING_DMESG ?= $(BUILD_ACTION_SANDBOXING_RESULT_DIR)/dmesg.log
BUILD_ACTION_SANDBOXING_POLICY ?= $(BUILD_ROOT)/bpf/build_action_sandboxing.bpf.o
BUILD_ACTION_SANDBOXING_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/build_action_sandboxing.bpf.c
BUILD_ACTION_SANDBOXING_RUNNER ?= $(BUILD_ROOT)/build-action-sandboxing/namei_ext_build_action_sandboxing
BUILD_ACTION_SANDBOXING_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/build_action_sandboxing/namei_ext_build_action_sandboxing.c
BUILD_ACTION_SANDBOXING_PLAN ?= $(ROOT_DIR)/docs/tmp/2026-07-26-build-action-sandboxing-experiment-plan.md
BUILD_ACTION_SANDBOXING_SUITE_MAKE ?= $(ROOT_DIR)/mk/experiments/build_action_sandboxing.mk
NAMEI_EXT_HARNESS_SOURCE ?= $(ROOT_DIR)/runner/src/namei_ext_harness.c
NAMEI_EXT_HARNESS_HEADER ?= $(ROOT_DIR)/runner/include/namei_ext_harness.h
NAMEI_EXT_HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a

.PHONY: kvm-build-action-sandboxing-preflight __experiment_build_action_sandboxing_preflight

kvm-build-action-sandboxing-preflight: $(KERNEL_IMAGE) bpf build-action-sandboxing workload-bazel
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(BUILD_ACTION_SANDBOXING_RESULT_DIR))
	$(call NAMEI_EXT_RUN_START,$(BUILD_ACTION_SANDBOXING_RESULT_DIR),build-action-sandboxing,bazel-action-sandboxing,kvm_bazel_action_preflight,$(BUILD_ACTION_SANDBOXING_JSON),build_action_sandboxing.bpf.c,namei_ext_build_action_sandboxing)
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" __namei_ext_kvm_capture \
		RUN_ID="$(RUN_ID)" \
		NAMEI_EXT_KVM_CAPTURE_IMAGE="$(KERNEL_IMAGE)" \
		NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET=__experiment_build_action_sandboxing_preflight \
		NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$(BUILD_ACTION_SANDBOXING_RESULT_DIR)" \
		NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(BUILD_ACTION_SANDBOXING_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(BUILD_ACTION_SANDBOXING_RESULT_DIR),$(BUILD_ACTION_SANDBOXING_JSON))
	$(call NAMEI_EXT_RUN_COMPLETE,$(BUILD_ACTION_SANDBOXING_RESULT_DIR))

__experiment_build_action_sandboxing_preflight: __namei_ext_guest_prepare
	install -d "$(BUILD_ACTION_SANDBOXING_RESULT_DIR)"
	: >"$(BUILD_ACTION_SANDBOXING_STDOUT)"
	: >"$(BUILD_ACTION_SANDBOXING_STDERR)"
	printf 'make -C %s __experiment_build_action_sandboxing_preflight RUN_ID=%s\n' "$(ROOT_DIR)" "$(RUN_ID)" >"$(BUILD_ACTION_SANDBOXING_COMMAND)"
	printf 'BAZEL_VERSION=%s\nBAZEL_URL=%s\nBAZEL_BINARY=%s\nBAZEL_BINARY_SHA256=%s\n' "$(BAZEL_VERSION)" "$(BAZEL_URL)" "$(BAZEL_BINARY)" "$(BAZEL_BINARY_SHA256)" >>"$(BUILD_ACTION_SANDBOXING_COMMAND)"
	sha256sum "$(BUILD_ACTION_SANDBOXING_POLICY_SOURCE)" "$(BUILD_ACTION_SANDBOXING_RUNNER_SOURCE)" "$(NAMEI_EXT_HARNESS_SOURCE)" "$(NAMEI_EXT_HARNESS_HEADER)" "$(BUILD_ACTION_SANDBOXING_SUITE_MAKE)" "$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" "$(BUILD_ACTION_SANDBOXING_PLAN)" "$(ROOT_DIR)/configs/benchmarks/workload-sources.mk" >"$(BUILD_ACTION_SANDBOXING_INPUTS)"
	sha256sum "$(KERNEL_IMAGE)" "$(BUILD_ACTION_SANDBOXING_POLICY)" "$(BUILD_ACTION_SANDBOXING_RUNNER)" "$(NAMEI_EXT_HARNESS_LIBRARY)" "$(BAZEL_BINARY)" >"$(BUILD_ACTION_SANDBOXING_ARTIFACTS)"
	printf '%s  %s\n' "$(BAZEL_BINARY_SHA256)" "$(BAZEL_BINARY)" | sha256sum -c -
	"$(BAZEL_BINARY)" --version >"$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/bazel-version.txt"
	uname -a >"$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/kernel-cmdline.txt"
	cp "$(KERNEL_BUILD_DIR)/.config" "$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/kernel.config"
	printf '{"event":"build-action-sandboxing-start","run_id":"%s","result_level":"kvm_bazel_action_preflight","workload":"build-action-sandboxing","source_system":"bazel-action-sandboxing","bazel_version":"%s"}\n' "$(RUN_ID)" "$(BAZEL_VERSION)" >"$(BUILD_ACTION_SANDBOXING_JSON)"
	"$(BUILD_ACTION_SANDBOXING_RUNNER)" "$(BUILD_ACTION_SANDBOXING_POLICY)" "$(BUILD_ACTION_SANDBOXING_JSON)" "$(BAZEL_BINARY)" "$(BUILD_ACTION_SANDBOXING_RESULT_DIR)" /sys/fs/cgroup >>"$(BUILD_ACTION_SANDBOXING_STDOUT)" 2>>"$(BUILD_ACTION_SANDBOXING_STDERR)"
	sha256sum "$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/action-a-output.txt" "$(BUILD_ACTION_SANDBOXING_RESULT_DIR)/action-b-output.txt" >"$(BUILD_ACTION_SANDBOXING_OUTPUTS)"
	jq -e 'select(.event == "build-action-sandboxing-summary" and .pass == true and .bazel_actions == 2 and .concurrent == true)' "$(BUILD_ACTION_SANDBOXING_JSON)" >/dev/null
	! jq -e 'select(.pass == false)' "$(BUILD_ACTION_SANDBOXING_JSON)" >/dev/null
	dmesg >"$(BUILD_ACTION_SANDBOXING_DMESG)"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(BUILD_ACTION_SANDBOXING_DMESG))
	printf '{"event":"build-action-sandboxing-done","run_id":"%s","result_level":"kvm_bazel_action_preflight"}\n' "$(RUN_ID)" >>"$(BUILD_ACTION_SANDBOXING_JSON)"
	test -s "$(BUILD_ACTION_SANDBOXING_OUTPUTS)"
