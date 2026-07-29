TOOLCHAIN_ENV_POLICY ?= $(BUILD_ROOT)/bpf/toolchain_environment.bpf.o
TOOLCHAIN_ENV_RUNNER ?= \
	$(BUILD_ROOT)/toolchain-environment/namei_ext_toolchain_environment
TOOLCHAIN_ENV_PROBE ?= \
	$(ROOT_DIR)/experiments/toolchain_environment/probe.py
TOOLCHAIN_ENV_PYTHON310 ?= /usr/bin/python3.10
TOOLCHAIN_ENV_PYTHON312 ?= /usr/bin/python3.12
TOOLCHAIN_ENV_BPFTOOL ?= $(KERNEL_BPFTOOL)

TOOLCHAIN_ENV_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	venv-310.stdout.log venv-310.stderr.log \
	venv-312.stdout.log venv-312.stderr.log \
	python-versions.txt lower-before.tsv lower-after.tsv \
	physical-310-probe.json physical-310-probe.stderr.log \
	physical-310-pip.stdout.log physical-310-pip.stderr.log \
	physical-312-probe.json physical-312-probe.stderr.log \
	physical-312-pip.stdout.log physical-312-pip.stderr.log \
	concurrent-a-310-probe.json concurrent-a-310-probe.stderr.log \
	concurrent-b-312-probe.json concurrent-b-312-probe.stderr.log \
	logical-a-310-probe.json logical-a-310-probe.stderr.log \
	logical-a-310-pip.stdout.log logical-a-310-pip.stderr.log \
	logical-b-312-probe.json logical-b-312-probe.stderr.log \
	logical-b-312-pip.stdout.log logical-b-312-pip.stderr.log \
	logical-a-switched-312-probe.json \
	logical-a-switched-312-probe.stderr.log \
	logical-a-switched-312-pip.stdout.log \
	logical-a-switched-312-pip.stderr.log \
	logical-a-rollback-310-probe.json \
	logical-a-rollback-310-probe.stderr.log \
	logical-a-rollback-310-pip.stdout.log \
	logical-a-rollback-310-pip.stderr.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-lower-after.status \
	guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

define TOOLCHAIN_ENV_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(TOOLCHAIN_ENV_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_toolchain_environment"
install -m 0444 "$(TOOLCHAIN_ENV_POLICY)" \
	"$(1)/artifacts/runtime/toolchain_environment.bpf.o"
install -m 0555 "$(TOOLCHAIN_ENV_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0555 "$(TOOLCHAIN_ENV_PROBE)" \
	"$(1)/artifacts/source/probe.py"
"$(TOOLCHAIN_ENV_PYTHON310)" --version \
	>"$(1)/artifacts/source/python310-version.txt" 2>&1
"$(TOOLCHAIN_ENV_PYTHON312)" --version \
	>"$(1)/artifacts/source/python312-version.txt" 2>&1
dpkg-query -W -f='$${Package} $${Version}\n' \
	python3.10 python3.10-venv python3.12 python3.12-venv \
	>"$(1)/artifacts/source/packages.txt"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_toolchain_environment",policy:"artifacts/runtime/toolchain_environment.bpf.o",bpftool:"artifacts/runtime/bpftool"},source:{probe:"artifacts/source/probe.py",python310:"/usr/bin/python3.10",python312:"/usr/bin/python3.12",versions:["artifacts/source/python310-version.txt","artifacts/source/python312-version.txt"],packages:"artifacts/source/packages.txt"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define TOOLCHAIN_ENV_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),toolchain-environment,CPython-venv,kvm_toolchain_environment,$(1)/observations.jsonl,toolchain_environment.bpf.c,namei_ext_toolchain_environment)
$(call TOOLCHAIN_ENV_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.protocol_schema = "namei_ext.toolchain_environment.v1" | .layout = "fresh-boot-physical-isolation-switch-rollback-withdrawn" | .matrix = {physical_environments:["CPython-3.10","CPython-3.12"],logical_states:["a-3.10","b-3.12","a-switched-3.12","a-rollback-3.10"],repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define TOOLCHAIN_ENV_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

.PHONY: toolchain-environment \
	kvm-toolchain-environment-preflight kvm-toolchain-environment \
	toolchain-environment-run toolchain-environment-finalize \
	toolchain-environment-analyze experiment-toolchain-environment \
	__toolchain_environment_guest __toolchain_environment_guest_inner

toolchain-environment:
	$(MAKE) -C "$(ROOT_DIR)/experiments/toolchain_environment" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

kvm-toolchain-environment-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-toolchain-environment-preflight: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		toolchain-environment
	test "$(TOOLCHAIN_ENV_PREFLIGHT_REPETITIONS)" = 1
	$(call TOOLCHAIN_ENV_START,$(TOOLCHAIN_ENV_PREFLIGHT_RESULT_DIR),1,make kvm-toolchain-environment-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-run \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_PREFLIGHT_RESULT_DIR)" \
		TOOLCHAIN_ENV_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-finalize \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_PREFLIGHT_RESULT_DIR)" \
		TOOLCHAIN_ENV_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(TOOLCHAIN_ENV_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-analyze \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_PREFLIGHT_RESULT_DIR)"

kvm-toolchain-environment: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-toolchain-environment: experiment-source-clean kernel kernel-provenance \
		kernel-bpftool bpf toolchain-environment
	test "$(TOOLCHAIN_ENV_REPETITIONS)" = 3
	$(call TOOLCHAIN_ENV_START,$(TOOLCHAIN_ENV_RESULT_DIR),3,make kvm-toolchain-environment RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-run \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_RESULT_DIR)" \
		TOOLCHAIN_ENV_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-finalize \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_RESULT_DIR)" \
		TOOLCHAIN_ENV_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(TOOLCHAIN_ENV_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" toolchain-environment-analyze \
		RUN_ID="$(RUN_ID)" \
		TOOLCHAIN_ENV_ACTIVE_DIR="$(TOOLCHAIN_ENV_RESULT_DIR)"

experiment-toolchain-environment: kvm-toolchain-environment

toolchain-environment-run:
	test -n "$(TOOLCHAIN_ENV_ACTIVE_DIR)"
	test -n "$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(TOOLCHAIN_ENV_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(TOOLCHAIN_ENV_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(TOOLCHAIN_ENV_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__toolchain_environment_guest TOOLCHAIN_ENV_BOOT_DIR=$${boot#$(ROOT_DIR)/} TOOLCHAIN_ENV_RUN_DIR=$${TOOLCHAIN_ENV_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(TOOLCHAIN_ENV_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(TOOLCHAIN_ENV_KVM_TIMEOUT)"; \
	done

toolchain-environment-finalize:
	test -n "$(TOOLCHAIN_ENV_ACTIVE_DIR)"
	test -n "$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(TOOLCHAIN_ENV_ACTIVE_DIR),$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS))
	! jq -e 'select(.pass != true)' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "toolchain-environment-summary" and .physical_environments == 2 and .logical_states == 4 and .failures == 0 and .pass == true)] | length' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl")" = \
		"$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	for state in physical-310 physical-312 logical-a-310 logical-b-312 \
			logical-a-switched-312 logical-a-rollback-310; do \
		test "$$(jq -s --arg state "$$state" \
			'[.[] | select(.event == "toolchain-environment-state" and .state == $$state and .probe_exit == 0 and .probe_nonempty == true and .probe_stderr_empty == true and .pip_exit == 0 and .pip_nonempty == true and .pip_stderr_empty == true and .actual_root_dev == .expected_root_dev and .actual_root_ino == .expected_root_ino and .actual_python_dev == .expected_python_dev and .actual_python_ino == .expected_python_ino and .pass == true)] | length' \
			"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl")" = \
			"$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"; \
	done
	test "$$(jq -s '[.[] | select(.event == "toolchain-environment-concurrent" and .barrier_participants == 2 and .a_exit == 0 and .b_exit == 0 and .a_output == true and .b_output == true and .a_stderr_empty == true and .b_stderr_empty == true and .pass == true)] | length' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl")" = \
		"$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "toolchain-environment-permission" and .observed_errno == 13 and .restore_errno == 0 and .pass == true)] | length' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl")" = \
		"$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "toolchain-environment-withdrawn" and .observed_errno == 2 and .pass == true)] | length' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl")" = \
		"$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(TOOLCHAIN_ENV_ACTIVE_DIR),$(TOOLCHAIN_ENV_ACTIVE_REPETITIONS),$(TOOLCHAIN_ENV_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		cmp "$$boot/lower-before.tsv" "$$boot/lower-after.tsv"; \
		for state in physical-310 physical-312 concurrent-a-310 \
				concurrent-b-312 logical-a-310 logical-b-312 \
				logical-a-switched-312 logical-a-rollback-310; do \
			jq -e '.schema == "namei_ext.toolchain_environment.probe.v1" and .pass == true and all(.checks[]; . == true)' \
				"$$boot/$$state-probe.json" >/dev/null; \
			test ! -s "$$boot/$$state-probe.stderr.log"; \
		done; \
		for state in physical-310 physical-312 logical-a-310 \
				logical-b-312 logical-a-switched-312 \
				logical-a-rollback-310; do \
			grep -Fx 'No broken requirements found.' \
				"$$boot/$$state-pip.stdout.log" >/dev/null; \
			test ! -s "$$boot/$$state-pip.stderr.log"; \
		done; \
		jq -e '.status == "completed" and .inner_status == 0 and .lower_after_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call TOOLCHAIN_ENV_VALIDATE_EXTERNAL,$$boot,before); \
		$(call TOOLCHAIN_ENV_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(TOOLCHAIN_ENV_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/run.json" >/dev/null

toolchain-environment-analyze:
	test -n "$(TOOLCHAIN_ENV_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(TOOLCHAIN_ENV_ACTIVE_DIR))
	mkdir "$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.toolchain_environment.summary.v1",boots:([.[] | select(.event == "toolchain-environment-summary" and .pass == true)] | length),states:([.[] | select(.event == "toolchain-environment-state" and .pass == true)] | length),concurrent_pairs:([.[] | select(.event == "toolchain-environment-concurrent" and .pass == true)] | length),permission_controls:([.[] | select(.event == "toolchain-environment-permission" and .pass == true)] | length),withdrawn_controls:([.[] | select(.event == "toolchain-environment-withdrawn" and .pass == true)] | length),verdict:"supported"}' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/observations.jsonl" \
		>"$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis/summary.json"
	jq -e \
		'.boots > 0 and .states == (6 * .boots) and .concurrent_pairs == .boots and .permission_controls == .boots and .withdrawn_controls == .boots and .verdict == "supported"' \
		"$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	printf '%s\n' \
		'# Toolchain Environment RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing environment states: $$(jq -r .states "$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis/summary.json")" \
		'Verdict: supported for CPython 3.10/3.12 virtual-environment selection.' \
		>"$(TOOLCHAIN_ENV_ACTIVE_DIR)/analysis/report.md"

__toolchain_environment_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__toolchain_environment_guest_inner \
		TOOLCHAIN_ENV_BOOT_DIR="$(TOOLCHAIN_ENV_BOOT_DIR)" \
		TOOLCHAIN_ENV_RUN_DIR="$(TOOLCHAIN_ENV_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/guest-inner.status"; \
	lower_after_status=0; \
	if test -d "$(TOOLCHAIN_ENV_BOOT_DIR)/lower"; then \
		find "$(TOOLCHAIN_ENV_BOOT_DIR)/lower" -xdev \
			-printf '%y\t%m\t%U\t%G\t%s\t%D\t%i\t%T@\t%p\n' | \
			LC_ALL=C sort \
			>"$(TOOLCHAIN_ENV_BOOT_DIR)/lower-after.tsv" || \
			lower_after_status=$$?; \
		if test "$$lower_after_status" -eq 0 && \
		   test -f "$(TOOLCHAIN_ENV_BOOT_DIR)/lower-before.tsv"; then \
			cmp "$(TOOLCHAIN_ENV_BOOT_DIR)/lower-before.tsv" \
				"$(TOOLCHAIN_ENV_BOOT_DIR)/lower-after.tsv" || \
				lower_after_status=$$?; \
		else \
			lower_after_status=1; \
		fi; \
	else \
		lower_after_status=1; \
	fi; \
	printf '%s\n' "$$lower_after_status" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/guest-lower-after.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(TOOLCHAIN_ENV_BOOT_DIR),$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(TOOLCHAIN_ENV_BOOT_DIR)/dmesg.log" || dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(TOOLCHAIN_ENV_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/guest-dmesg.status"; \
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
		'{schema:"namei_ext.toolchain_environment.boot.v1",status:$$status,inner_status:$$inner_status,lower_after_status:$$lower_after_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__toolchain_environment_guest_inner:
	test -n "$(TOOLCHAIN_ENV_BOOT_DIR)"
	test -n "$(TOOLCHAIN_ENV_RUN_DIR)"
	test -x "$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/namei_ext_toolchain_environment"
	test -r "$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/toolchain_environment.bpf.o"
	test -x "$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/bpftool"
	test -x "$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/source/probe.py"
	test -x "$(TOOLCHAIN_ENV_PYTHON310)"
	test -x "$(TOOLCHAIN_ENV_PYTHON312)"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(TOOLCHAIN_ENV_BOOT_DIR),$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	owner_uid=$$(stat -c %u "$(TOOLCHAIN_ENV_BOOT_DIR)"); \
	owner_gid=$$(stat -c %g "$(TOOLCHAIN_ENV_BOOT_DIR)"); \
	install -d -o "$$owner_uid" -g "$$owner_gid" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/lower" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/home"; \
	setpriv --reuid="$$owner_uid" --regid="$$owner_gid" --clear-groups \
		"$(TOOLCHAIN_ENV_PYTHON310)" -m venv --copies \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python310" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/venv-310.stdout.log" \
		2>"$(TOOLCHAIN_ENV_BOOT_DIR)/venv-310.stderr.log"; \
	setpriv --reuid="$$owner_uid" --regid="$$owner_gid" --clear-groups \
		"$(TOOLCHAIN_ENV_PYTHON312)" -m venv --copies \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python312" \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/venv-312.stdout.log" \
		2>"$(TOOLCHAIN_ENV_BOOT_DIR)/venv-312.stderr.log"
	test ! -s "$(TOOLCHAIN_ENV_BOOT_DIR)/venv-310.stderr.log"
	test ! -s "$(TOOLCHAIN_ENV_BOOT_DIR)/venv-312.stderr.log"
	"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python310/bin/python" --version \
		>"$(TOOLCHAIN_ENV_BOOT_DIR)/python-versions.txt" 2>&1
	"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python312/bin/python" --version \
		>>"$(TOOLCHAIN_ENV_BOOT_DIR)/python-versions.txt" 2>&1
	grep -Fx 'Python 3.10.19' \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/python-versions.txt" >/dev/null
	grep -Fx 'Python 3.12.3' \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/python-versions.txt" >/dev/null
	find "$(TOOLCHAIN_ENV_BOOT_DIR)/lower" -xdev \
		-printf '%y\t%m\t%U\t%G\t%s\t%D\t%i\t%T@\t%p\n' | \
		LC_ALL=C sort >"$(TOOLCHAIN_ENV_BOOT_DIR)/lower-before.tsv"
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(TOOLCHAIN_ENV_BOOT_DIR),$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call TOOLCHAIN_ENV_VALIDATE_EXTERNAL,$(TOOLCHAIN_ENV_BOOT_DIR),before)
	: >"$(TOOLCHAIN_ENV_BOOT_DIR)/observations.jsonl"
	"$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/namei_ext_toolchain_environment" \
		"$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/runtime/toolchain_environment.bpf.o" \
		"$(TOOLCHAIN_ENV_RUN_DIR)/artifacts/source/probe.py" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/observations.jsonl" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python310" \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/lower/python312" \
		/sys/fs/cgroup
	! jq -e 'select(.pass != true)' \
		"$(TOOLCHAIN_ENV_BOOT_DIR)/observations.jsonl" >/dev/null
