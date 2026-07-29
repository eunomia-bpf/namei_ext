AGENT_SOURCE_TASK_POLICY ?= \
	$(BUILD_ROOT)/bpf/agent_workspace_source_task.bpf.o
AGENT_SOURCE_TASK_RUNNER ?= \
	$(BUILD_ROOT)/agent-workspace-source-task/namei_ext_agent_workspace_source_task
AGENT_SOURCE_TASK_PROBE ?= \
	$(ROOT_DIR)/experiments/agent_workspace_source_task/import_probe.py
AGENT_SOURCE_TASK_PARSER ?= \
	$(ROOT_DIR)/experiments/agent_workspace_source_task/parse_pytest_junit.py
AGENT_SOURCE_TASK_GOLD_PATCH ?= \
	$(ROOT_DIR)/experiments/agent_workspace_source_task/fixtures/click-2622-gold.patch
AGENT_SOURCE_TASK_TEST_PATCH ?= \
	$(ROOT_DIR)/experiments/agent_workspace_source_task/fixtures/click-2622-test.patch
AGENT_SOURCE_TASK_BPFTOOL ?= $(KERNEL_BPFTOOL)

AGENT_SOURCE_TASK_STATES := \
	physical-base physical-completed \
	concurrent-a-completed concurrent-b-base \
	logical-b-switched-completed logical-b-rollback-base
AGENT_SOURCE_TASK_STATE_FILES := \
	$(foreach state,$(AGENT_SOURCE_TASK_STATES),\
		$(state)-import.json \
		$(state)-junit.xml \
		$(state)-pytest.json \
		$(state)-probe.stdout.log \
		$(state)-probe.stderr.log \
		$(state)-pytest.stdout.log \
		$(state)-pytest.stderr.log \
		$(state)-parser.stdout.log \
		$(state)-parser.stderr.log)
AGENT_SOURCE_TASK_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	source-prepare.stdout.log source-prepare.stderr.log \
	lower-before.tsv lower-after.tsv \
	expected-base-types.py expected-base-test.py \
	expected-completed-types.py expected-completed-test.py \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-lower-after.status \
	guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log \
	$(AGENT_SOURCE_TASK_STATE_FILES)

define AGENT_SOURCE_TASK_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(AGENT_SOURCE_TASK_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_agent_workspace_source_task"
install -m 0444 "$(AGENT_SOURCE_TASK_POLICY)" \
	"$(1)/artifacts/runtime/agent_workspace_source_task.bpf.o"
install -m 0555 "$(AGENT_SOURCE_TASK_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0555 "$(AGENT_SOURCE_TASK_PROBE)" \
	"$(1)/artifacts/source/import_probe.py"
install -m 0555 "$(AGENT_SOURCE_TASK_PARSER)" \
	"$(1)/artifacts/source/parse_pytest_junit.py"
install -m 0444 "$(AGENT_SOURCE_TASK_GOLD_PATCH)" \
	"$(1)/artifacts/source/click-2622-gold.patch"
install -m 0444 "$(AGENT_SOURCE_TASK_TEST_PATCH)" \
	"$(1)/artifacts/source/click-2622-test.patch"
git -C "$(AGENT_SOURCE_TASK_CACHE)" archive \
	"$(AGENT_SOURCE_TASK_CLICK_COMMIT)" \
	>"$(1)/artifacts/source/click-source.tar"
printf '%s\n' "$(AGENT_SOURCE_TASK_CLICK_URL)" \
	>"$(1)/artifacts/source/click-url.txt"
printf '%s\n' "$(AGENT_SOURCE_TASK_CLICK_COMMIT)" \
	>"$(1)/artifacts/source/click-commit.txt"
printf '%s\n' "$(AGENT_SOURCE_TASK_SWE_FACTORY_URL)" \
	>"$(1)/artifacts/source/swe-factory-url.txt"
printf '%s\n' "$(AGENT_SOURCE_TASK_SWE_FACTORY_COMMIT)" \
	>"$(1)/artifacts/source/swe-factory-commit.txt"
printf '%s\n' "$(AGENT_SOURCE_TASK_INSTANCE)" \
	>"$(1)/artifacts/source/instance.txt"
"$(AGENT_SOURCE_TASK_PYTHON)" --version \
	>"$(1)/artifacts/source/python-version.txt" 2>&1
"$(AGENT_SOURCE_TASK_PYTHON)" -m "$(AGENT_SOURCE_TASK_PYTEST)" --version \
	>"$(1)/artifacts/source/pytest-version.txt" 2>&1
endef

define AGENT_SOURCE_TASK_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),agent-workspace-source-task-rq1,SWE-Factory-Gym-pallets-click-2622,kvm_agent_workspace_source_task_rq1,$(1)/observations.jsonl,agent_workspace_source_task.bpf.c,namei_ext_agent_workspace_source_task)
$(call AGENT_SOURCE_TASK_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.protocol_schema = "namei_ext.agent_workspace_source_task_rq1.v1" | .layout = "fresh-boot-physical-controls-concurrent-views-switch-rollback-withdrawal" | .matrix = {instance:"pallets__click-2622",pytest_runs_per_boot:6,repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define AGENT_SOURCE_TASK_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

.PHONY: agent-workspace-source-task-source \
	agent-workspace-source-task \
	kvm-agent-workspace-source-task-rq1-preflight \
	kvm-agent-workspace-source-task-rq1 \
	agent-workspace-source-task-run \
	agent-workspace-source-task-finalize \
	agent-workspace-source-task-analyze \
	experiment-agent-workspace-source-task-rq1 \
	__agent_workspace_source_task_guest \
	__agent_workspace_source_task_guest_inner

agent-workspace-source-task-source: \
		$(AGENT_SOURCE_TASK_CACHE)/.git/HEAD
	test "$$(git -C "$(AGENT_SOURCE_TASK_CACHE)" rev-parse HEAD)" = \
		"$(AGENT_SOURCE_TASK_CLICK_COMMIT)"
	test -z "$$(git -C "$(AGENT_SOURCE_TASK_CACHE)" status --porcelain)"
	git -C "$(AGENT_SOURCE_TASK_CACHE)" cat-file -e \
		"$(AGENT_SOURCE_TASK_CLICK_COMMIT)^{commit}"

$(AGENT_SOURCE_TASK_CACHE)/.git/HEAD:
	install -d "$(AGENT_SOURCE_TASK_CACHE)"
	git -C "$(AGENT_SOURCE_TASK_CACHE)" init
	git -C "$(AGENT_SOURCE_TASK_CACHE)" remote add origin \
		"$(AGENT_SOURCE_TASK_CLICK_URL)"
	git -C "$(AGENT_SOURCE_TASK_CACHE)" fetch --depth=1 origin \
		"$(AGENT_SOURCE_TASK_CLICK_COMMIT)"
	git -C "$(AGENT_SOURCE_TASK_CACHE)" checkout --detach FETCH_HEAD

agent-workspace-source-task:
	$(MAKE) -C "$(ROOT_DIR)/experiments/agent_workspace_source_task" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

kvm-agent-workspace-source-task-rq1-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-agent-workspace-source-task-rq1-preflight: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		agent-workspace-source-task-source \
		agent-workspace-source-task
	test "$(AGENT_SOURCE_TASK_PREFLIGHT_REPETITIONS)" = 1
	$(call AGENT_SOURCE_TASK_START,$(AGENT_SOURCE_TASK_PREFLIGHT_RESULT_DIR),1,make kvm-agent-workspace-source-task-rq1-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-run \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_PREFLIGHT_RESULT_DIR)" \
		AGENT_SOURCE_TASK_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-finalize \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_PREFLIGHT_RESULT_DIR)" \
		AGENT_SOURCE_TASK_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(AGENT_SOURCE_TASK_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-analyze \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_PREFLIGHT_RESULT_DIR)"

kvm-agent-workspace-source-task-rq1: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-agent-workspace-source-task-rq1: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf \
		agent-workspace-source-task-source \
		agent-workspace-source-task
	test "$(AGENT_SOURCE_TASK_REPETITIONS)" = 3
	$(call AGENT_SOURCE_TASK_START,$(AGENT_SOURCE_TASK_RESULT_DIR),3,make kvm-agent-workspace-source-task-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-run \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_RESULT_DIR)" \
		AGENT_SOURCE_TASK_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-finalize \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_RESULT_DIR)" \
		AGENT_SOURCE_TASK_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(AGENT_SOURCE_TASK_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-source-task-analyze \
		RUN_ID="$(RUN_ID)" \
		AGENT_SOURCE_TASK_ACTIVE_DIR="$(AGENT_SOURCE_TASK_RESULT_DIR)"

experiment-agent-workspace-source-task-rq1: \
	kvm-agent-workspace-source-task-rq1

agent-workspace-source-task-run:
	test -n "$(AGENT_SOURCE_TASK_ACTIVE_DIR)"
	test -n "$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(AGENT_SOURCE_TASK_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(AGENT_SOURCE_TASK_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__agent_workspace_source_task_guest AGENT_SOURCE_TASK_BOOT_DIR=$${boot#$(ROOT_DIR)/} AGENT_SOURCE_TASK_RUN_DIR=$${AGENT_SOURCE_TASK_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(AGENT_SOURCE_TASK_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(AGENT_SOURCE_TASK_KVM_TIMEOUT)"; \
	done

agent-workspace-source-task-finalize:
	test -n "$(AGENT_SOURCE_TASK_ACTIVE_DIR)"
	test -n "$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(AGENT_SOURCE_TASK_ACTIVE_DIR),$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS))
	! jq -e 'select(.pass != true)' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "agent-source-task-summary" and .pytest_runs == 6 and .concurrent_pairs == 1 and .failures == 0 and .pass == true)] | length' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl")" = \
		"$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "agent-source-task-state" and .pass == true)] | length' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((6 * $(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "agent-source-task-concurrent" and .participants == 2 and .overlap == true and .pass == true)] | length' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl")" = \
		"$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "agent-source-task-visibility" and .pass == true)] | length' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((4 * $(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS)))"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(AGENT_SOURCE_TASK_ACTIVE_DIR),$(AGENT_SOURCE_TASK_ACTIVE_REPETITIONS),$(AGENT_SOURCE_TASK_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		for state in physical-base concurrent-b-base \
				logical-b-rollback-base; do \
			jq -e '.expected == "base" and .tests == 40 and .passed == 39 and .failures == 1 and .errors == 0 and .skipped == 0 and .failed == [{classname:"tests.test_types",file:"",name:"test_choice_get_invalid_choice_message"}] and .pass == true' \
				"$$boot/$$state-pytest.json" >/dev/null; \
		done; \
		for state in physical-completed concurrent-a-completed \
				logical-b-switched-completed; do \
			jq -e '.expected == "completed" and .tests == 40 and .passed == 40 and .failures == 0 and .errors == 0 and .skipped == 0 and .failed == [] and .pass == true' \
				"$$boot/$$state-pytest.json" >/dev/null; \
		done; \
		for state in $(AGENT_SOURCE_TASK_STATES); do \
			jq -e '.pass == true and .checks.cwd_is_logical_root == true and .checks.sys_path_has_exact_logical_src == true and .checks.click_file_is_logical == true and .checks.click_types_file_is_logical == true and .checks.types_identity_matches == true and .checks.test_identity_matches == true' \
				"$$boot/$$state-import.json" >/dev/null; \
			test ! -s "$$boot/$$state-probe.stderr.log"; \
			test ! -s "$$boot/$$state-parser.stderr.log"; \
		done; \
		for state in before-assignment assigned-a assigned-b \
				after-withdrawal; do \
			test "$$(jq -s --arg state "$$state" \
				'[.[] | select(.event == "agent-source-task-visibility" and .state == $$state and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for case_name in fixture_paths configure_policy \
				assign_concurrent_views switch_b_to_completed \
				rollback_b_to_base withdraw_b_view detach_policy \
				clear_targets_a clear_targets_b remove_cgroup_a \
				remove_cgroup_b; do \
			test "$$(jq -s --arg case_name "$$case_name" \
				'[.[] | select(.event == "agent-source-task-case" and .case == $$case_name and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for counter in lookup readdir select hide-lookup hide-readdir \
				target-a-completed target-b-base \
				target-b-completed; do \
			test "$$(jq -s --arg counter "$$counter" \
				'[.[] | select(.event == "agent-source-task-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/expected-base-types.py" \
			"$$boot/lower/base/src/click/types.py"; \
		cmp "$$boot/expected-base-test.py" \
			"$$boot/lower/base/tests/test_types.py"; \
		cmp "$$boot/expected-completed-types.py" \
			"$$boot/lower/completed/src/click/types.py"; \
		cmp "$$boot/expected-completed-test.py" \
			"$$boot/lower/completed/tests/test_types.py"; \
		cmp "$$boot/lower-before.tsv" "$$boot/lower-after.tsv"; \
		jq -e '.status == "completed" and .inner_status == 0 and .lower_after_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call AGENT_SOURCE_TASK_VALIDATE_EXTERNAL,$$boot,before); \
		$(call AGENT_SOURCE_TASK_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/run.json" >/dev/null

agent-workspace-source-task-analyze:
	test -n "$(AGENT_SOURCE_TASK_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(AGENT_SOURCE_TASK_ACTIVE_DIR))
	install -d "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.agent_workspace_source_task_rq1.summary.v1",boots:([.[] | select(.event == "agent-source-task-summary" and .pass == true)] | length),pytest_runs:([.[] | select(.event == "agent-source-task-state" and .pass == true)] | length),concurrent_pairs:([.[] | select(.event == "agent-source-task-concurrent" and .pass == true)] | length),visibility_states:([.[] | select(.event == "agent-source-task-visibility" and .pass == true)] | length)}' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/observations.jsonl" \
		>"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json"
	jq -e '.boots > 0 and .pytest_runs == (6 * .boots) and .concurrent_pairs == .boots and .visibility_states == (4 * .boots)' \
		"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	printf '%s\n' \
		'# Agent Workspace Source Task RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing pytest states: $$(jq -r .pytest_runs "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json")" \
		"Overlapping concurrent pairs: $$(jq -r .concurrent_pairs "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing visibility states: $$(jq -r .visibility_states "$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/summary.json")" \
		>"$(AGENT_SOURCE_TASK_ACTIVE_DIR)/analysis/report.md"

__agent_workspace_source_task_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__agent_workspace_source_task_guest_inner \
		AGENT_SOURCE_TASK_BOOT_DIR="$(AGENT_SOURCE_TASK_BOOT_DIR)" \
		AGENT_SOURCE_TASK_RUN_DIR="$(AGENT_SOURCE_TASK_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/guest-inner.status"; \
	lower_after_status=0; \
	if test -d "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower"; then \
		stat -c '%n\t%F\t%a\t%u\t%g\t%s\t%D\t%i' \
			"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/src/click/types.py" \
			"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/tests/test_types.py" \
			"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/src/click/types.py" \
			"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/tests/test_types.py" \
			>"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower-after.tsv" || \
			lower_after_status=$$?; \
		if test "$$lower_after_status" -eq 0; then \
			cmp "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower-before.tsv" \
				"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower-after.tsv" || \
				lower_after_status=$$?; \
			cmp "$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-base-types.py" \
				"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/src/click/types.py" || \
				lower_after_status=$$?; \
			cmp "$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-base-test.py" \
				"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/tests/test_types.py" || \
				lower_after_status=$$?; \
			cmp "$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-completed-types.py" \
				"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/src/click/types.py" || \
				lower_after_status=$$?; \
			cmp "$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-completed-test.py" \
				"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/tests/test_types.py" || \
				lower_after_status=$$?; \
		fi; \
	else \
		lower_after_status=1; \
	fi; \
	printf '%s\n' "$$lower_after_status" \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/guest-lower-after.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(AGENT_SOURCE_TASK_BOOT_DIR),$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(AGENT_SOURCE_TASK_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_SOURCE_TASK_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/guest-dmesg.status"; \
	status=completed; \
	if test "$$inner_status" -ne 0 || \
	   test "$$lower_after_status" -ne 0 || \
	   test "$$inventory_after_status" -ne 0 || \
	   test "$$dmesg_status" -ne 0; then status=failed; fi; \
	jq -n \
		--arg status "$$status" \
		--argjson inner_status "$$inner_status" \
		--argjson lower_after_status "$$lower_after_status" \
		--argjson inventory_after_status "$$inventory_after_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.agent_workspace_source_task_rq1.boot.v1",status:$$status,inner_status:$$inner_status,lower_after_status:$$lower_after_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__agent_workspace_source_task_guest_inner:
	test -n "$(AGENT_SOURCE_TASK_BOOT_DIR)"
	test -n "$(AGENT_SOURCE_TASK_RUN_DIR)"
	test -x "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/namei_ext_agent_workspace_source_task"
	test -r "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/agent_workspace_source_task.bpf.o"
	test -x "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/bpftool"
	test -x "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/import_probe.py"
	test -x "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/parse_pytest_junit.py"
	test -r "$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-source.tar"
	test -x "$(AGENT_SOURCE_TASK_PYTHON)"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(AGENT_SOURCE_TASK_BOOT_DIR),$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(AGENT_SOURCE_TASK_BOOT_DIR),$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/bpftool,before)
	owner_uid=$$(stat -c %u "$(AGENT_SOURCE_TASK_BOOT_DIR)"); \
	owner_gid=$$(stat -c %g "$(AGENT_SOURCE_TASK_BOOT_DIR)"); \
	install -d -o "$$owner_uid" -g "$$owner_gid" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed"; \
	prepare_status=0; \
	{ \
		tar --no-same-owner -xf \
			"$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-source.tar" \
			-C "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base"; \
		tar --no-same-owner -xf \
			"$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-source.tar" \
			-C "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed"; \
		patch -s -p1 -d "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base" \
			<"$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-2622-test.patch"; \
		patch -s -p1 -d "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed" \
			<"$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-2622-test.patch"; \
		patch -s -p1 -d "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed" \
			<"$(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/click-2622-gold.patch"; \
	} >"$(AGENT_SOURCE_TASK_BOOT_DIR)/source-prepare.stdout.log" \
	  2>"$(AGENT_SOURCE_TASK_BOOT_DIR)/source-prepare.stderr.log" || \
		prepare_status=$$?; \
	test "$$prepare_status" -eq 0; \
	cp "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/src/click/types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-base-types.py"; \
	cp "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/tests/test_types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-base-test.py"; \
	cp "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/src/click/types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-completed-types.py"; \
	cp "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/tests/test_types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/expected-completed-test.py"; \
	chown -R "$$owner_uid:$$owner_gid" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower"; \
	chmod -R a-w "$(AGENT_SOURCE_TASK_BOOT_DIR)/lower"; \
	stat -c '%n\t%F\t%a\t%u\t%g\t%s\t%D\t%i' \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/src/click/types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base/tests/test_types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/src/click/types.py" \
		"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed/tests/test_types.py" \
		>"$(AGENT_SOURCE_TASK_BOOT_DIR)/lower-before.tsv"; \
	: >"$(AGENT_SOURCE_TASK_BOOT_DIR)/observations.jsonl"; \
	"$(abspath $(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/namei_ext_agent_workspace_source_task)" \
		"$(abspath $(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/runtime/agent_workspace_source_task.bpf.o)" \
		"$(abspath $(AGENT_SOURCE_TASK_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(AGENT_SOURCE_TASK_BOOT_DIR))" \
		"$(AGENT_SOURCE_TASK_PYTHON)" \
		"$(abspath $(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/import_probe.py)" \
		"$(abspath $(AGENT_SOURCE_TASK_RUN_DIR)/artifacts/source/parse_pytest_junit.py)" \
		"$(abspath $(AGENT_SOURCE_TASK_BOOT_DIR)/lower/base)" \
		"$(abspath $(AGENT_SOURCE_TASK_BOOT_DIR)/lower/completed)" \
		/sys/fs/cgroup
