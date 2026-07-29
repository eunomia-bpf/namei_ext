APPLICATION_FILE_SHARING_POLICY ?= \
	$(BUILD_ROOT)/bpf/application_file_sharing.bpf.o
APPLICATION_FILE_SHARING_RUNNER ?= \
	$(BUILD_ROOT)/application-file-sharing/namei_ext_application_file_sharing
APPLICATION_FILE_SHARING_BPFTOOL ?= $(KERNEL_BPFTOOL)

APPLICATION_FILE_SHARING_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	lower-document-payload.txt unrelated-document-payload.txt \
	stdout-controller.log stderr-controller.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

define APPLICATION_FILE_SHARING_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(APPLICATION_FILE_SHARING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_application_file_sharing"
install -m 0444 "$(APPLICATION_FILE_SHARING_POLICY)" \
	"$(1)/artifacts/runtime/application_file_sharing.bpf.o"
install -m 0555 "$(APPLICATION_FILE_SHARING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
printf '%s\n' \
	'https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html' \
	>"$(1)/artifacts/source/documents-portal-url.txt"
printf '%s\n' \
	'https://github.com/flatpak/xdg-desktop-portal' \
	>"$(1)/artifacts/source/implementation-url.txt"
printf 'xdg-portal-existing-object\n' \
	>"$(1)/artifacts/source/expected-document-payload.txt"
printf 'unrelated-document-object\n' \
	>"$(1)/artifacts/source/expected-unrelated-payload.txt"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_application_file_sharing",policy:"artifacts/runtime/application_file_sharing.bpf.o",bpftool:"artifacts/runtime/bpftool"},source:{documents_portal:"artifacts/source/documents-portal-url.txt",implementation:"artifacts/source/implementation-url.txt",expected_document:"artifacts/source/expected-document-payload.txt",expected_unrelated:"artifacts/source/expected-unrelated-payload.txt"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define APPLICATION_FILE_SHARING_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),application-file-sharing-rq1,xdg-documents-portal,kvm_application_file_sharing_rq1,$(1)/observations.jsonl,application_file_sharing.bpf.c,namei_ext_application_file_sharing)
$(call APPLICATION_FILE_SHARING_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.protocol_schema = "namei_ext.application_file_sharing_rq1.v1" | .layout = "fresh-boot-two-application-grant-revoke" | .matrix = {applications:["application-a","application-b"],states:["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"],repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

.PHONY: kvm-application-file-sharing-preflight \
	kvm-application-file-sharing-rq1 application-file-sharing-run \
	application-file-sharing-finalize application-file-sharing-analyze \
	experiment-application-file-sharing-rq1 \
	__application_file_sharing_guest \
	__application_file_sharing_guest_inner

kvm-application-file-sharing-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-preflight: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf application-file-sharing
	test "$(APPLICATION_FILE_SHARING_PREFLIGHT_REPETITIONS)" = 1
	$(call APPLICATION_FILE_SHARING_START,$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR),1,make kvm-application-file-sharing-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)"

kvm-application-file-sharing-rq1: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-rq1: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf application-file-sharing
	test "$(APPLICATION_FILE_SHARING_REPETITIONS)" = 3
	$(call APPLICATION_FILE_SHARING_START,$(APPLICATION_FILE_SHARING_RESULT_DIR),3,make kvm-application-file-sharing-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)"

experiment-application-file-sharing-rq1: kvm-application-file-sharing-rq1

application-file-sharing-run:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		install -d "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__application_file_sharing_guest APPLICATION_FILE_SHARING_BOOT_DIR=$${boot#$(ROOT_DIR)/} APPLICATION_FILE_SHARING_RUN_DIR=$${APPLICATION_FILE_SHARING_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(APPLICATION_FILE_SHARING_KVM_TIMEOUT)"; \
	done

application-file-sharing-finalize:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(APPLICATION_FILE_SHARING_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS))
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl" \
		>/dev/null
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .failures == 0 and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((5 * $(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-lower-object" and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(APPLICATION_FILE_SHARING_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS),$(APPLICATION_FILE_SHARING_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .failures == 0 and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		for state in application-a-before-grant \
				application-b-without-grant \
				application-b-during-a-grant \
				application-a-after-revoke; do \
			test "$$(jq -s --arg state "$$state" \
				'[.[] | select(.event == "application-file-sharing-state" and .state == $$state and .expected_visible == false and .observation_errno == 0 and .move_errno == 0 and .document_errno == 2 and .payload_stat_errno == 2 and .payload_read_errno == 2 and .opendir_errno == 0 and .readdir_errno == 0 and .closedir_errno == 0 and .document_listed == false and .unrelated_errno == 0 and .unrelated_bytes_expected == true and .lower_document_errno == 0 and .lower_payload_errno == 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-state" and .state == "application-a-after-grant" and .expected_visible == true and .observation_errno == 0 and .move_errno == 0 and .document_errno == 0 and .payload_stat_errno == 0 and .payload_read_errno == 0 and .opendir_errno == 0 and .readdir_errno == 0 and .closedir_errno == 0 and .document_listed == true and .payload_bytes_expected == true and .unrelated_errno == 0 and .unrelated_bytes_expected == true and .lower_document_errno == 0 and .lower_payload_errno == 0 and .logical_document_dev == .lower_document_dev and .logical_document_ino == .lower_document_ino and .logical_payload_dev == .lower_payload_dev and .logical_payload_ino == .lower_payload_ino and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-lower-object" and .object == "host-document-payload" and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		for case_name in fixture_paths application_identities \
				application_a_identity register_existing_document \
				attach_policy register_portal_scope \
				grant_application_a revoke_application_a \
				preserve_raw_objects detach_policy \
				clear_registered_document \
				remove_application_a_cgroup \
				remove_application_b_cgroup; do \
			test "$$(jq -s --arg case_name "$$case_name" \
				'[.[] | select(.event == "application-file-sharing-case" and .case == $$case_name and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for counter in lookup readdir select hide_lookup hide_readdir; do \
			test "$$(jq -s --arg counter "$$counter" \
				'[.[] | select(.event == "application-file-sharing-policy-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/lower-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/source/expected-document-payload.txt"; \
		cmp "$$boot/unrelated-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/source/expected-unrelated-payload.txt"; \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,before); \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/run.json" >/dev/null

application-file-sharing-analyze:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(APPLICATION_FILE_SHARING_ACTIVE_DIR))
	install -d "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.application_file_sharing_rq1.summary.v1",boots:([.[] | select(.event == "application-file-sharing-summary" and .pass == true)] | length),states:([.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length),visible_states:([.[] | select(.event == "application-file-sharing-state" and .expected_visible == true and .pass == true)] | length),hidden_states:([.[] | select(.event == "application-file-sharing-state" and .expected_visible == false and .pass == true)] | length),lower_objects:([.[] | select(.event == "application-file-sharing-lower-object" and .pass == true)] | length),cgroup_removals:([.[] | select(.event == "application-file-sharing-case" and (.case == "remove_application_a_cgroup" or .case == "remove_application_b_cgroup") and .pass == true)] | length)}' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl" \
		>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json"
	jq -e \
		'.boots > 0 and .states == (5 * .boots) and .visible_states == .boots and .hidden_states == (4 * .boots) and .lower_objects == .boots and .cgroup_removals == (2 * .boots)' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json" \
		>/dev/null
	printf '%s\n' \
		'# Sandboxed Application File Sharing RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing lifecycle states: $$(jq -r .states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Visible states: $$(jq -r .visible_states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Hidden states: $$(jq -r .hidden_states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Preserved lower objects: $$(jq -r .lower_objects "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Removed application cgroups: $$(jq -r .cgroup_removals "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		'Scope: tested XDG Documents portal existing-object grant/revoke subset.' \
		>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/report.md"

__application_file_sharing_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__application_file_sharing_guest_inner \
		APPLICATION_FILE_SHARING_BOOT_DIR="$(APPLICATION_FILE_SHARING_BOOT_DIR)" \
		APPLICATION_FILE_SHARING_RUN_DIR="$(APPLICATION_FILE_SHARING_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(APPLICATION_FILE_SHARING_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(APPLICATION_FILE_SHARING_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-dmesg.status"; \
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
		'{schema:"namei_ext.application_file_sharing_rq1.boot.v1",status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__application_file_sharing_guest_inner:
	test -n "$(APPLICATION_FILE_SHARING_BOOT_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_RUN_DIR)"
	test -x "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing"
	test -r "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o"
	test -x "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$(APPLICATION_FILE_SHARING_BOOT_DIR),before)
	: >"$(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl"
	"$(abspath $(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing)" \
		"$(abspath $(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o)" \
		"$(abspath $(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(APPLICATION_FILE_SHARING_BOOT_DIR))" /sys/fs/cgroup \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/stdout-controller.log" \
		2>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/stderr-controller.log"
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl" \
		>/dev/null
