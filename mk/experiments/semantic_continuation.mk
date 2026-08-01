SEMANTIC_CONTINUATION_POLICY ?= \
	$(BUILD_ROOT)/bpf/semantic_continuation.bpf.o
SEMANTIC_CONTINUATION_RUNNER ?= \
	$(BUILD_ROOT)/semantic-continuation/namei_ext_semantic_continuation
SEMANTIC_CONTINUATION_GUEST_SCRATCH ?= \
	/tmp/namei-ext-semantic-continuation
SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT ?= \
	$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/ext4
SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT ?= \
	$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/tmpfs
SEMANTIC_CONTINUATION_GUEST_LOGICAL_ROOT ?= \
	$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/logical

define SEMANTIC_CONTINUATION_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(SEMANTIC_CONTINUATION_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_semantic_continuation"
install -m 0444 "$(SEMANTIC_CONTINUATION_POLICY)" \
	"$(1)/artifacts/runtime/semantic_continuation.bpf.o"
endef

define SEMANTIC_CONTINUATION_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),semantic-continuation,Linux-VFS-operation-matrix,kvm_semantic_continuation_rq1,$(1)/observations.jsonl,semantic_continuation.bpf.c,namei_ext_semantic_continuation)
$(call SEMANTIC_CONTINUATION_CAPTURE_ARTIFACTS,$(1))
jq \
	--arg profile "$(2)" \
	--argjson repetitions "$(3)" \
	'.protocol_schema = "namei_ext.semantic_continuation.v1" | .layout = "fresh-boot-paired-direct-selected" | .operation_inventory = {source:"pjd/pjdfstest",commit:"ededbeb2b44929972898afb87474b0937f78a877",reuse:"operation-families-not-unmodified-suite"} | .matrix = {profile:$$profile,repetitions:$$repetitions,arms:["direct","selected"],order:["direct-selected","selected-direct"],filesystems:["ext4","tmpfs"],all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(4)" >"$(1)/command.txt"
endef

define SEMANTIC_CONTINUATION_MARK_FAILURE_IF_RUNNING
if jq -e '.status == "running" and (.completed_at | not)' \
	"$(1)/run.json" >/dev/null 2>&1; then \
	failed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
	$(call NAMEI_EXT_MARK_RUN_FAILED,$(1),$$failed_at,$(2)); \
fi
endef

define SEMANTIC_CONTINUATION_RUN_STAGE
set +e; $(1); stage_status=$$?; set -e; \
if test "$$stage_status" -ne 0; then \
	$(call SEMANTIC_CONTINUATION_MARK_FAILURE_IF_RUNNING,$(2),$(3)); \
	exit "$$stage_status"; \
fi
endef

.PHONY: semantic-continuation \
	kvm-semantic-continuation-preflight kvm-semantic-continuation \
	semantic-continuation-run semantic-continuation-finalize \
	semantic-continuation-analyze experiment-semantic-continuation \
	__semantic_continuation_guest __semantic_continuation_guest_inner

semantic-continuation:
	$(MAKE) -C "$(ROOT_DIR)/experiments/semantic_continuation" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

kvm-semantic-continuation-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-semantic-continuation-preflight: experiment-source-clean kernel \
		kernel-provenance bpf semantic-continuation
	test "$(SEMANTIC_CONTINUATION_PREFLIGHT_REPETITIONS)" = 1
	$(call SEMANTIC_CONTINUATION_START,$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR),preflight,1,make kvm-semantic-continuation-preflight RUN_ID=$(RUN_ID))
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-run RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=1 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=preflight,$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR),kvm-preflight)
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-finalize RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=1 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=preflight,$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR),host-finalize)
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-analyze RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=1 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=preflight,$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR),host-analyze)
	$(call NAMEI_EXT_RUN_COMPLETE,$(SEMANTIC_CONTINUATION_PREFLIGHT_RESULT_DIR))

kvm-semantic-continuation: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-semantic-continuation: experiment-source-clean kernel kernel-provenance \
		bpf semantic-continuation
	test "$(SEMANTIC_CONTINUATION_REPETITIONS)" = 3
	$(call SEMANTIC_CONTINUATION_START,$(SEMANTIC_CONTINUATION_RESULT_DIR),formal,3,make kvm-semantic-continuation RUN_ID=$(RUN_ID))
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-run RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=3 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=formal,$(SEMANTIC_CONTINUATION_RESULT_DIR),kvm-formal)
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-finalize RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=3 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=formal,$(SEMANTIC_CONTINUATION_RESULT_DIR),host-finalize)
	$(call SEMANTIC_CONTINUATION_RUN_STAGE,$(MAKE) --no-print-directory -C "$(ROOT_DIR)" semantic-continuation-analyze RUN_ID="$(RUN_ID)" SEMANTIC_CONTINUATION_ACTIVE_DIR="$(SEMANTIC_CONTINUATION_RESULT_DIR)" SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS=3 SEMANTIC_CONTINUATION_ACTIVE_PROFILE=formal,$(SEMANTIC_CONTINUATION_RESULT_DIR),host-analyze)
	$(call NAMEI_EXT_RUN_COMPLETE,$(SEMANTIC_CONTINUATION_RESULT_DIR))

experiment-semantic-continuation: kvm-semantic-continuation

semantic-continuation-run:
	test -n "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)"
	test -n "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)"
	test "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = preflight -o \
		"$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = formal
	for repetition in $$(seq 1 "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)"); do \
		boot="$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		if test "$$((repetition % 2))" = 1; then \
			order=direct-selected; \
		else \
			order=selected-direct; \
		fi; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__semantic_continuation_guest SEMANTIC_CONTINUATION_BOOT_DIR=$${boot#$(ROOT_DIR)/} SEMANTIC_CONTINUATION_RUN_DIR=$${SEMANTIC_CONTINUATION_ACTIVE_DIR#$(ROOT_DIR)/} SEMANTIC_CONTINUATION_PROFILE=$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE) SEMANTIC_CONTINUATION_ORDER=$$order" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(SEMANTIC_CONTINUATION_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(SEMANTIC_CONTINUATION_KVM_TIMEOUT)"; \
	done

semantic-continuation-finalize:
	test -n "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)"
	test -n "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)"
	test "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = preflight -o \
		"$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = formal
	test "$$(find "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d | wc -l)" = \
		"$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)"
	: >"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl"
	for repetition in $$(seq 1 "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)"); do \
		boot="$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		test -s "$$boot/observations.jsonl"; \
		cat "$$boot/observations.jsonl" \
			>>"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl"; \
		if test "$$((repetition % 2))" = 1; then \
			order=direct-selected; \
		else \
			order=selected-direct; \
		fi; \
		if test "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = preflight; then \
			expected_cases=2; \
			case_specs='S02:8 S11:5'; \
			engagement_specs='S02:2 S11:6'; \
		else \
			expected_cases=16; \
			case_specs='S01:1 S02:8 S03:5 S04:6 S05:6 S06:5 S07:3 S08:8 S09:6 S10:5 S11:5 S12:5 S13:5 S14:5 S15:1 S16:6'; \
			engagement_specs='S01:2 S02:2 S03:2 S04:2 S05:2 S06:2 S07:2 S08:2 S09:2 S10:2 S11:6 S12:6 S13:10 S14:10 S15:0 S16:2'; \
		fi; \
		test "$$(jq -s --arg profile "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" \
			--arg order "$$order" --argjson cases "$$expected_cases" \
			'[.[] | select(.event == "semantic-continuation-summary" and .profile == $$profile and .order == $$order and .expected_cases_per_arm == $$cases and .failures == 0 and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		! jq -e 'select(has("pass") and .pass != true)' \
			"$$boot/observations.jsonl" >/dev/null; \
		for arm in direct selected; do \
			for case_spec in $$case_specs; do \
				IFS=: read -r case_id operation_count <<<"$$case_spec"; \
				test "$$(jq -s --arg arm "$$arm" --arg case_id "$$case_id" --argjson operation_count "$$operation_count" \
					'[.[] | select(.event == "semantic-continuation-case" and .arm == $$arm and .case == $$case_id and .operations == $$operation_count and .failures == 0 and .pass == true)] | length' \
					"$$boot/observations.jsonl")" = 1; \
			done; \
			test "$$(jq -s --arg arm "$$arm" \
				'[.[] | select(.event == "semantic-continuation-residual" and .arm == $$arm and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = "$$expected_cases"; \
		done; \
		for engagement_spec in $$engagement_specs; do \
			IFS=: read -r case_id target_mask <<<"$$engagement_spec"; \
			test "$$(jq -s --arg case_id "$$case_id" --argjson target_mask "$$target_mask" \
				'[.[] | select(.event == "semantic-continuation-engagement" and .arm == "selected" and .case == $$case_id and .expected_target_mask == $$target_mask and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		jq -s -e '([.[] | select(.event == "semantic-continuation-operation" and .arm == "direct") | {case,operation,errno,detail,pass,outcome:(if .return < 0 then "error" else "success" end)}] | sort_by(.case,.operation)) == ([.[] | select(.event == "semantic-continuation-operation" and .arm == "selected") | {case,operation,errno,detail,pass,outcome:(if .return < 0 then "error" else "success" end)}] | sort_by(.case,.operation))' \
			"$$boot/observations.jsonl" >/dev/null; \
		jq -e '.status == "completed" and .inner_status == 0 and .cleanup_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		test "$$(cat "$$boot/runner.status")" = 0; \
		test "$$(cat "$$boot/cleanup.status")" = 0; \
		grep -Eq 'FSTYPE[[:space:]]+ext4' "$$boot/ext4-filesystem.txt"; \
		grep -Eq 'FSTYPE[[:space:]]+tmpfs' "$$boot/tmpfs-filesystem.txt"; \
	done
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl" >/dev/null
	if test "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" = formal; then \
		test "$$(jq -s '[.[] | select(.event == "semantic-continuation-operation" and .case == "S04" and .operation == "unprivileged-read-denied" and .errno == 13 and .pass == true)] | length' "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl")" = 6; \
		test "$$(jq -s '[.[] | select(.event == "semantic-continuation-operation" and (.case == "S13" or .case == "S14") and .errno == 18 and .pass == true)] | length' "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl")" = 12; \
		test "$$(jq -s '[.[] | select(.event == "semantic-continuation-setup" and .step == "teardown-policy-before-dirfd" and .pass == true)] | length' "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl")" = 3; \
	fi
	jq -e --arg profile "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" \
		--argjson repetitions "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)" \
		'.status == "running" and .source.dirty == false and .kernel.dirty == false and .matrix.profile == $$profile and .matrix.repetitions == $$repetitions' \
		"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/run.json" >/dev/null

semantic-continuation-analyze:
	test -n "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)"
	test ! -e "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis"
	install -d "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis"
	jq -s \
		--arg profile "$(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" \
		'{schema:"namei_ext.semantic_continuation.summary.v1",profile:$$profile,boots:([.[] | select(.event == "semantic-continuation-summary" and .pass == true)] | length),direct_cases:([.[] | select(.event == "semantic-continuation-case" and .arm == "direct" and .pass == true)] | length),selected_cases:([.[] | select(.event == "semantic-continuation-case" and .arm == "selected" and .pass == true)] | length),selected_engagements:([.[] | select(.event == "semantic-continuation-engagement" and .pass == true)] | length),residual_checks:([.[] | select(.event == "semantic-continuation-residual" and .pass == true)] | length),failed_observations:([.[] | select(has("pass") and .pass != true)] | length),verdict:"supported-for-frozen-matrix"}' \
		"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/observations.jsonl" \
		>"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json"
	jq -e --argjson boots "$(SEMANTIC_CONTINUATION_ACTIVE_REPETITIONS)" \
		'.boots == $$boots and .direct_cases == .selected_cases and .selected_engagements == .selected_cases and .residual_checks == (2 * .selected_cases) and .failed_observations == 0 and .verdict == "supported-for-frozen-matrix"' \
		"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	printf '%s\n' \
		'# Semantic Continuation Result' \
		'' \
		"Profile: $(SEMANTIC_CONTINUATION_ACTIVE_PROFILE)" \
		"Fresh KVM boots: $$(jq -r .boots "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing direct cases: $$(jq -r .direct_cases "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing selected cases: $$(jq -r .selected_cases "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing selected-path engagement checks: $$(jq -r .selected_engagements "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing lower-object residual checks: $$(jq -r .residual_checks "$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/summary.json")" \
		'Verdict: direct and selected paths agree for the frozen operation matrix.' \
		>"$(SEMANTIC_CONTINUATION_ACTIVE_DIR)/analysis/report.md"

__semantic_continuation_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__semantic_continuation_guest_inner \
		SEMANTIC_CONTINUATION_BOOT_DIR="$(SEMANTIC_CONTINUATION_BOOT_DIR)" \
		SEMANTIC_CONTINUATION_RUN_DIR="$(SEMANTIC_CONTINUATION_RUN_DIR)" \
		SEMANTIC_CONTINUATION_PROFILE="$(SEMANTIC_CONTINUATION_PROFILE)" \
		SEMANTIC_CONTINUATION_ORDER="$(SEMANTIC_CONTINUATION_ORDER)" || \
		inner_status=$$?; \
	cleanup_status=0; \
	if mountpoint -q "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)"; then \
		umount "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)" || cleanup_status=$$?; \
	fi; \
	if mountpoint -q "$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)"; then \
		sync; umount "$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)" || cleanup_status=$$?; \
	fi; \
	for path in "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)" \
			"$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)"; do \
		if test -d "$$path"; then rmdir "$$path" || cleanup_status=$$?; fi; \
	done; \
	if test -e "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/lower.img"; then \
		rm -f "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/lower.img" || cleanup_status=$$?; \
	fi; \
	if mountpoint -q "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)"; then \
		umount "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)" || cleanup_status=$$?; \
	fi; \
	if test -d "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)"; then \
		rmdir "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)" || cleanup_status=$$?; \
	fi; \
	printf '%s\n' "$$cleanup_status" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/cleanup.status"; \
	dmesg_status=0; \
	dmesg >"$(SEMANTIC_CONTINUATION_BOOT_DIR)/dmesg.log" || dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(SEMANTIC_CONTINUATION_BOOT_DIR)/dmesg.log) || dmesg_status=$$?; \
	fi; \
	if test "$$dmesg_status" -eq 0; then \
		! grep -Ei 'rcu[^:]*:[^[:cntrl:]]*stall|namei_ext[^[:cntrl:]]*(failed|failure|error)' \
			"$(SEMANTIC_CONTINUATION_BOOT_DIR)/dmesg.log" >/dev/null || dmesg_status=$$?; \
	fi; \
	status=completed; \
	if test "$$inner_status" -ne 0 || test "$$cleanup_status" -ne 0 || \
	   test "$$dmesg_status" -ne 0; then status=failed; fi; \
	jq -n --arg status "$$status" --argjson inner_status "$$inner_status" \
		--argjson cleanup_status "$$cleanup_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.semantic_continuation.boot.v1",status:$$status,inner_status:$$inner_status,cleanup_status:$$cleanup_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__semantic_continuation_guest_inner:
	test -n "$(SEMANTIC_CONTINUATION_BOOT_DIR)"
	test -n "$(SEMANTIC_CONTINUATION_RUN_DIR)"
	test "$(SEMANTIC_CONTINUATION_PROFILE)" = preflight -o \
		"$(SEMANTIC_CONTINUATION_PROFILE)" = formal
	test "$(SEMANTIC_CONTINUATION_ORDER)" = direct-selected -o \
		"$(SEMANTIC_CONTINUATION_ORDER)" = selected-direct
	test -x "$(SEMANTIC_CONTINUATION_RUN_DIR)/artifacts/runtime/namei_ext_semantic_continuation"
	test -r "$(SEMANTIC_CONTINUATION_RUN_DIR)/artifacts/runtime/semantic_continuation.bpf.o"
	command -v mkfs.ext4 >/dev/null
	test ! -e "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)"
	install -d "$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)"
	mount -t tmpfs -o size=768m namei-ext-semantic-scratch \
		"$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)"
	truncate -s "$(SEMANTIC_CONTINUATION_EXT4_BYTES)" \
		"$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/lower.img"
	mkfs.ext4 -q -F -m 0 \
		"$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/lower.img" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/mkfs-ext4.log" 2>&1
	install -d "$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)" \
		"$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)"
	mount -t ext4 -o loop,noatime,nosuid,nodev \
		"$(SEMANTIC_CONTINUATION_GUEST_SCRATCH)/lower.img" \
		"$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)"
	mount -t tmpfs -o size="$(SEMANTIC_CONTINUATION_TMPFS_SIZE)",nosuid,nodev \
		namei-ext-semantic-tmpfs "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)"
	test "$$(findmnt -rn -T "$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)" -o FSTYPE)" = ext4
	test "$$(findmnt -rn -T "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)" -o FSTYPE)" = tmpfs
	findmnt "$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/ext4-filesystem.txt"
	findmnt "$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/tmpfs-filesystem.txt"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(SEMANTIC_CONTINUATION_BOOT_DIR),$(SEMANTIC_CONTINUATION_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	runner_status=0; \
	"$(SEMANTIC_CONTINUATION_RUN_DIR)/artifacts/runtime/namei_ext_semantic_continuation" \
		"$(SEMANTIC_CONTINUATION_RUN_DIR)/artifacts/runtime/semantic_continuation.bpf.o" \
		"$(SEMANTIC_CONTINUATION_BOOT_DIR)/observations.jsonl" \
		/sys/fs/cgroup \
		"$(SEMANTIC_CONTINUATION_GUEST_EXT4_ROOT)" \
		"$(SEMANTIC_CONTINUATION_GUEST_TMPFS_ROOT)" \
		"$(SEMANTIC_CONTINUATION_GUEST_LOGICAL_ROOT)" \
		"$(SEMANTIC_CONTINUATION_PROFILE)" \
		"$(SEMANTIC_CONTINUATION_ORDER)" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/runner.stdout.log" \
		2>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/runner.stderr.log" || \
		runner_status=$$?; \
	printf '%s\n' "$$runner_status" \
		>"$(SEMANTIC_CONTINUATION_BOOT_DIR)/runner.status"; \
	test "$$runner_status" -eq 0
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(SEMANTIC_CONTINUATION_BOOT_DIR)/observations.jsonl" >/dev/null
