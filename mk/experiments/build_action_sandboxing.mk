BUILD_ACTION_SANDBOXING_POLICY ?= \
	$(BUILD_ROOT)/bpf/build_action_sandboxing.bpf.o
BUILD_ACTION_SANDBOXING_RUNNER ?= \
	$(BUILD_ROOT)/build-action-sandboxing/namei_ext_build_action_sandboxing
BUILD_ACTION_SANDBOXING_BPFTOOL ?= $(KERNEL_BPFTOOL)

BUILD_ACTION_SANDBOXING_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log bazel-version.txt \
	action-a-output.txt action-b-output.txt \
	lower-action-a-input.txt lower-action-b-input.txt \
	lower-action-a-private.txt lower-action-b-private.txt \
	stdout-controller.log stderr-controller.log \
	stdout-bazel-action-a.log stderr-bazel-action-a.log \
	stdout-bazel-action-b.log stderr-bazel-action-b.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

define BUILD_ACTION_SANDBOXING_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(BUILD_ACTION_SANDBOXING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_build_action_sandboxing"
install -m 0444 "$(BUILD_ACTION_SANDBOXING_POLICY)" \
	"$(1)/artifacts/runtime/build_action_sandboxing.bpf.o"
install -m 0555 "$(BUILD_ACTION_SANDBOXING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0555 "$(BAZEL_BINARY)" "$(1)/artifacts/runtime/bazel"
"$(BAZEL_BINARY)" --version >"$(1)/artifacts/source/bazel-version.txt"
printf '%s\n' "$(BAZEL_URL)" >"$(1)/artifacts/source/bazel-url.txt"
printf 'declared-input-A\n' >"$(1)/artifacts/source/expected-action-a.txt"
printf 'declared-input-B\n' >"$(1)/artifacts/source/expected-action-b.txt"
printf 'undeclared-input-must-stay-hidden\n' \
	>"$(1)/artifacts/source/expected-private.txt"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg bazel_version "$(BAZEL_VERSION)" \
	--arg bazel_url "$(BAZEL_URL)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_build_action_sandboxing",policy:"artifacts/runtime/build_action_sandboxing.bpf.o",bpftool:"artifacts/runtime/bpftool",bazel:"artifacts/runtime/bazel"},source:{bazel_version:$$bazel_version,bazel_url:$$bazel_url,expected_action_a:"artifacts/source/expected-action-a.txt",expected_action_b:"artifacts/source/expected-action-b.txt",expected_private:"artifacts/source/expected-private.txt"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define BUILD_ACTION_SANDBOXING_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),build-action-sandboxing-rq1,Bazel-6.5.0,kvm_bazel_action_rq1,$(1)/observations.jsonl,build_action_sandboxing.bpf.c,namei_ext_build_action_sandboxing)
$(call BUILD_ACTION_SANDBOXING_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.protocol_schema = "namei_ext.build_action_sandboxing_rq1.v1" | .layout = "fresh-boot-two-concurrent-bazel-actions" | .matrix = {actions:["action-a","action-b"],logical_path:"view/action/input.txt",declared_child:"input.txt",hidden_child:"private.txt",repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define BUILD_ACTION_SANDBOXING_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

.PHONY: kvm-build-action-sandboxing-preflight \
	kvm-build-action-sandboxing-rq1 build-action-sandboxing-run \
	build-action-sandboxing-finalize build-action-sandboxing-analyze \
	experiment-build-action-sandboxing-rq1 \
	__build_action_sandboxing_guest \
	__build_action_sandboxing_guest_inner

kvm-build-action-sandboxing-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-build-action-sandboxing-preflight: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf build-action-sandboxing \
		workload-bazel
	test "$(BUILD_ACTION_SANDBOXING_PREFLIGHT_REPETITIONS)" = 1
	$(call BUILD_ACTION_SANDBOXING_START,$(BUILD_ACTION_SANDBOXING_PREFLIGHT_RESULT_DIR),1,make kvm-build-action-sandboxing-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-run \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_PREFLIGHT_RESULT_DIR)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-finalize \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_PREFLIGHT_RESULT_DIR)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(BUILD_ACTION_SANDBOXING_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-analyze \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_PREFLIGHT_RESULT_DIR)"

kvm-build-action-sandboxing-rq1: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-build-action-sandboxing-rq1: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf build-action-sandboxing \
		workload-bazel
	test "$(BUILD_ACTION_SANDBOXING_REPETITIONS)" = 3
	$(call BUILD_ACTION_SANDBOXING_START,$(BUILD_ACTION_SANDBOXING_RESULT_DIR),3,make kvm-build-action-sandboxing-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-run \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_RESULT_DIR)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-finalize \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_RESULT_DIR)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(BUILD_ACTION_SANDBOXING_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" build-action-sandboxing-analyze \
		RUN_ID="$(RUN_ID)" \
		BUILD_ACTION_SANDBOXING_ACTIVE_DIR="$(BUILD_ACTION_SANDBOXING_RESULT_DIR)"

experiment-build-action-sandboxing-rq1: kvm-build-action-sandboxing-rq1

build-action-sandboxing-run:
	test -n "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)"
	test -n "$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__build_action_sandboxing_guest BUILD_ACTION_SANDBOXING_BOOT_DIR=$${boot#$(ROOT_DIR)/} BUILD_ACTION_SANDBOXING_RUN_DIR=$${BUILD_ACTION_SANDBOXING_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(BUILD_ACTION_SANDBOXING_KVM_TIMEOUT)"; \
	done

build-action-sandboxing-finalize:
	test -n "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)"
	test -n "$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR),$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS))
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/observations.jsonl" \
		>/dev/null
	test "$$(jq -s '[.[] | select(.event == "build-action-sandboxing-summary" and .bazel_actions == 2 and .concurrent == true and .failures == 0 and .pass == true)] | length' \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"
	for action in action-a action-b; do \
		test "$$(jq -s --arg action "$$action" \
			'[.[] | select(.event == "build-action-sandboxing-view" and .action == $$action and .private_errno == 2 and .logical_dev == .lower_dev and .logical_ino == .lower_ino and .pass == true)] | length' \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/observations.jsonl")" = \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"; \
	done
	for object in action-a-input action-b-input action-a-private \
			action-b-private; do \
		test "$$(jq -s --arg object "$$object" \
			'[.[] | select(.event == "build-action-sandboxing-lower-object" and .object == $$object and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/observations.jsonl")" = \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS)"; \
	done
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR),$(BUILD_ACTION_SANDBOXING_ACTIVE_REPETITIONS),$(BUILD_ACTION_SANDBOXING_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		test "$$(jq -s \
			'[.[] | select(.event == "build-action-sandboxing-summary" and .bazel_actions == 2 and .concurrent == true and .failures == 0 and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		for action in action-a action-b; do \
			test "$$(jq -s --arg action "$$action" \
				'[.[] | select(.event == "build-action-sandboxing-view" and .action == $$action and .private_errno == 2 and .logical_dev == .lower_dev and .logical_ino == .lower_ino and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for object in action-a-input action-b-input action-a-private \
				action-b-private; do \
			test "$$(jq -s --arg object "$$object" \
				'[.[] | select(.event == "build-action-sandboxing-lower-object" and .object == $$object and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for case_name in bazel_workspaces action_identities \
				register_declared_input_roots attach_policy \
				install_action_views start_concurrent_bazel_actions \
				concurrent_action_overlap bazel_action_a \
				bazel_action_b action_a_output_oracle \
				action_b_output_oracle preserve_raw_objects \
				lower_inputs_unchanged detach_policy \
				clear_action_a_target clear_action_b_target \
				remove_action_a_cgroup \
				remove_action_b_cgroup; do \
			test "$$(jq -s --arg case_name "$$case_name" \
				'[.[] | select(.event == "build-action-sandboxing-case" and .case == $$case_name and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for counter in lookup readdir select allow_lookup allow_readdir \
				hide_lookup hide_readdir; do \
			test "$$(jq -s --arg counter "$$counter" \
				'[.[] | select(.event == "build-action-sandboxing-policy-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/action-a-output.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-action-a.txt"; \
		cmp "$$boot/action-b-output.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-action-b.txt"; \
		cmp "$$boot/lower-action-a-input.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-action-a.txt"; \
		cmp "$$boot/lower-action-b-input.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-action-b.txt"; \
		cmp "$$boot/lower-action-a-private.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-private.txt"; \
		cmp "$$boot/lower-action-b-private.txt" \
			"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/artifacts/source/expected-private.txt"; \
		grep -Fx "bazel $(BAZEL_VERSION)" "$$boot/bazel-version.txt" \
			>/dev/null; \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call BUILD_ACTION_SANDBOXING_VALIDATE_EXTERNAL,$$boot,before); \
		$(call BUILD_ACTION_SANDBOXING_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false' \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/run.json" >/dev/null

build-action-sandboxing-analyze:
	test -n "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR))
	mkdir "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.build_action_sandboxing_rq1.summary.v1",boots:([.[] | select(.event == "build-action-sandboxing-summary" and .pass == true)] | length),bazel_actions:([.[] | select(.event == "build-action-sandboxing-case" and (.case == "bazel_action_a" or .case == "bazel_action_b") and .pass == true)] | length),action_views:([.[] | select(.event == "build-action-sandboxing-view" and .pass == true)] | length),lower_objects:([.[] | select(.event == "build-action-sandboxing-lower-object" and .pass == true)] | length),cgroup_removals:([.[] | select(.event == "build-action-sandboxing-case" and (.case == "remove_action_a_cgroup" or .case == "remove_action_b_cgroup") and .pass == true)] | length)}' \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/observations.jsonl" \
		>"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json"
	jq -e \
		'.boots > 0 and .bazel_actions == (2 * .boots) and .action_views == (2 * .boots) and .lower_objects == (4 * .boots) and .cgroup_removals == (2 * .boots)' \
		"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json" \
		>/dev/null
	printf '%s\n' \
		'# Build Action Sandboxing RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing Bazel actions: $$(jq -r .bazel_actions "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing action views: $$(jq -r .action_views "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json")" \
		"Preserved lower objects: $$(jq -r .lower_objects "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json")" \
		"Removed action cgroups: $$(jq -r .cgroup_removals "$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/summary.json")" \
		'Scope: tested Bazel existing-object action-view subset.' \
		>"$(BUILD_ACTION_SANDBOXING_ACTIVE_DIR)/analysis/report.md"

__build_action_sandboxing_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__build_action_sandboxing_guest_inner \
		BUILD_ACTION_SANDBOXING_BOOT_DIR="$(BUILD_ACTION_SANDBOXING_BOOT_DIR)" \
		BUILD_ACTION_SANDBOXING_RUN_DIR="$(BUILD_ACTION_SANDBOXING_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(BUILD_ACTION_SANDBOXING_BOOT_DIR),$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/guest-dmesg.status"; \
	status=completed; \
	if test "$$inner_status" -ne 0 || \
	   test "$$inventory_after_status" -ne 0 || \
	   test "$$dmesg_status" -ne 0; then status=failed; fi; \
	jq -n \
		--arg status "$$status" \
		--argjson inner_status "$$inner_status" \
		--argjson inventory_after_status "$$inventory_after_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.build_action_sandboxing_rq1.boot.v1",status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__build_action_sandboxing_guest_inner:
	test -n "$(BUILD_ACTION_SANDBOXING_BOOT_DIR)"
	test -n "$(BUILD_ACTION_SANDBOXING_RUN_DIR)"
	test -x "$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/namei_ext_build_action_sandboxing"
	test -r "$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/build_action_sandboxing.bpf.o"
	test -x "$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bpftool"
	test -x "$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bazel"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(BUILD_ACTION_SANDBOXING_BOOT_DIR),$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(BUILD_ACTION_SANDBOXING_BOOT_DIR),$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call BUILD_ACTION_SANDBOXING_VALIDATE_EXTERNAL,$(BUILD_ACTION_SANDBOXING_BOOT_DIR),before)
	"$(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bazel" \
		--version >"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/bazel-version.txt"
	: >"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/observations.jsonl"
	"$(abspath $(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/namei_ext_build_action_sandboxing)" \
		"$(abspath $(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/build_action_sandboxing.bpf.o)" \
		"$(abspath $(BUILD_ACTION_SANDBOXING_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(BUILD_ACTION_SANDBOXING_RUN_DIR)/artifacts/runtime/bazel)" \
		"$(abspath $(BUILD_ACTION_SANDBOXING_BOOT_DIR))" /sys/fs/cgroup \
		>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/stdout-controller.log" \
		2>"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/stderr-controller.log"
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(BUILD_ACTION_SANDBOXING_BOOT_DIR)/observations.jsonl" \
		>/dev/null
