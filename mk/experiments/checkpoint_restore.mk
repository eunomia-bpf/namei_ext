CHECKPOINT_RESTORE_MIGRATION_POLICY ?= \
	$(BUILD_ROOT)/bpf/checkpoint_restore_migration.bpf.o
CHECKPOINT_RESTORE_MIGRATION_POLICY_SOURCE ?= \
	$(ROOT_DIR)/bpf/policies/checkpoint_restore_migration.bpf.c
CHECKPOINT_RESTORE_RUNNER ?= \
	$(BUILD_ROOT)/checkpoint-restore/namei_ext_checkpoint_restore
CHECKPOINT_RESTORE_APP ?= \
	$(BUILD_ROOT)/checkpoint-restore/checkpoint_restore_app
CHECKPOINT_RESTORE_RUNNER_SOURCE ?= \
	$(ROOT_DIR)/experiments/checkpoint_restore/namei_ext_checkpoint_restore.c
CHECKPOINT_RESTORE_APP_SOURCE ?= \
	$(ROOT_DIR)/experiments/checkpoint_restore/checkpoint_restore_app.c
CHECKPOINT_RESTORE_DMTCP_REPOSITORY ?= https://github.com/dmtcp/dmtcp.git
CHECKPOINT_RESTORE_DMTCP_CACHE ?= \
	$(CACHE_ROOT)/workloads/dmtcp-$(DMTCP_COMMIT_SHORT)-git
CHECKPOINT_RESTORE_DMTCP_ROOT ?= \
	$(BUILD_ROOT)/checkpoint-restore/dmtcp-$(DMTCP_COMMIT_SHORT)
CHECKPOINT_RESTORE_DMTCP_SOURCE ?= \
	$(CHECKPOINT_RESTORE_DMTCP_ROOT)/source
CHECKPOINT_RESTORE_DMTCP_INSTALL ?= \
	$(CHECKPOINT_RESTORE_DMTCP_ROOT)/install
CHECKPOINT_RESTORE_DMTCP_LOGS ?= \
	$(CHECKPOINT_RESTORE_DMTCP_ROOT)/logs
CHECKPOINT_RESTORE_DMTCP_SOURCE_STAMP ?= \
	$(CHECKPOINT_RESTORE_DMTCP_ROOT)/.source-ready
CHECKPOINT_RESTORE_DMTCP_BUILD_STAMP ?= \
	$(CHECKPOINT_RESTORE_DMTCP_ROOT)/.build-ready
CHECKPOINT_RESTORE_DMTCP_CONFIGURE_LOG ?= \
	$(CHECKPOINT_RESTORE_DMTCP_LOGS)/configure.log
CHECKPOINT_RESTORE_DMTCP_BUILD_LOG ?= \
	$(CHECKPOINT_RESTORE_DMTCP_LOGS)/build.log
CHECKPOINT_RESTORE_DMTCP_INSTALL_LOG ?= \
	$(CHECKPOINT_RESTORE_DMTCP_LOGS)/install.log
CHECKPOINT_RESTORE_BOOT_FILES := \
	guest.mk launcher.stdout.log launcher.stderr.log boot.json \
	observations.jsonl bpf-programs-before.json \
	bpf-programs-after.json bpf-cgroup-before.json bpf-cgroup-after.json \
	kernel.config kernel-commit.txt kernel-release.txt uname.txt \
	proc-version.txt kernel-cmdline.txt runtime-identity.json \
	runtime-identity-probe.txt dmesg.log

$(CHECKPOINT_RESTORE_DMTCP_SOURCE_STAMP): \
		$(ROOT_DIR)/configs/benchmarks/workload-sources.mk
	command -v git >/dev/null
	install -d "$(dir $(CHECKPOINT_RESTORE_DMTCP_CACHE))" \
		"$(CHECKPOINT_RESTORE_DMTCP_ROOT)"
	if test ! -d "$(CHECKPOINT_RESTORE_DMTCP_CACHE)/.git"; then \
		rm -rf "$(CHECKPOINT_RESTORE_DMTCP_CACHE)"; \
		git clone --no-checkout "$(CHECKPOINT_RESTORE_DMTCP_REPOSITORY)" \
			"$(CHECKPOINT_RESTORE_DMTCP_CACHE)"; \
	fi
	git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" fetch --depth=1 origin \
		"$(DMTCP_COMMIT)"
	git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" checkout --detach \
		"$(DMTCP_COMMIT)"
	test "$$(git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" rev-parse HEAD)" = \
		"$(DMTCP_COMMIT)"
	test -z "$$(git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" \
		status --porcelain=v1 --untracked-files=all)"
	test -x "$(CHECKPOINT_RESTORE_DMTCP_CACHE)/configure"
	test -f "$(CHECKPOINT_RESTORE_DMTCP_CACHE)/test/pathvirt1.c"
	touch "$@"

$(CHECKPOINT_RESTORE_DMTCP_BUILD_STAMP): \
		$(CHECKPOINT_RESTORE_DMTCP_SOURCE_STAMP) \
		$(DMTCP_RESTART_ENV_PATCH)
	command -v patch >/dev/null
	rm -rf "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" \
		"$(CHECKPOINT_RESTORE_DMTCP_INSTALL)" \
		"$(CHECKPOINT_RESTORE_DMTCP_LOGS)"
	install -d "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" \
		"$(CHECKPOINT_RESTORE_DMTCP_INSTALL)" \
		"$(CHECKPOINT_RESTORE_DMTCP_LOGS)"
	git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" archive "$(DMTCP_COMMIT)" | \
		tar -x -C "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)"
	patch --batch --forward --fuzz=0 \
		-d "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" -p1 \
		<"$(DMTCP_RESTART_ENV_PATCH)"
	test "$$(grep -F -c 'while (start_ptr - env_buf < count)' \
		"$(CHECKPOINT_RESTORE_DMTCP_SOURCE)/src/dmtcpplugin.cpp")" = 1
	! grep -F 'while (start_ptr - env_buf < (int)sizeof(env_buf))' \
		"$(CHECKPOINT_RESTORE_DMTCP_SOURCE)/src/dmtcpplugin.cpp"
	(cd "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" && \
		./configure --prefix="$(CHECKPOINT_RESTORE_DMTCP_INSTALL)") \
		>"$(CHECKPOINT_RESTORE_DMTCP_CONFIGURE_LOG)" 2>&1
	$(MAKE) -C "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" -j"$(JOBS)" \
		>"$(CHECKPOINT_RESTORE_DMTCP_BUILD_LOG)" 2>&1
	$(MAKE) -C "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" install \
		>"$(CHECKPOINT_RESTORE_DMTCP_INSTALL_LOG)" 2>&1
	test -x "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/bin/dmtcp_launch"
	test -x "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/bin/dmtcp_coordinator"
	test -x "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/bin/dmtcp_command"
	test -x "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/bin/dmtcp_restart"
	test -f "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/lib/dmtcp/libdmtcp.so"
	test -s "$(CHECKPOINT_RESTORE_DMTCP_CONFIGURE_LOG)"
	test -s "$(CHECKPOINT_RESTORE_DMTCP_BUILD_LOG)"
	test -s "$(CHECKPOINT_RESTORE_DMTCP_INSTALL_LOG)"
	touch "$@"

.PHONY: checkpoint-restore-dmtcp-build
checkpoint-restore-dmtcp-build: $(CHECKPOINT_RESTORE_DMTCP_BUILD_STAMP)
	test "$$(git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" rev-parse HEAD)" = \
		"$(DMTCP_COMMIT)"
	test -z "$$(git -C "$(CHECKPOINT_RESTORE_DMTCP_CACHE)" \
		status --porcelain=v1 --untracked-files=all)"
	test -x "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)/bin/dmtcp_restart"
	test -f "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)/test/autotest.py"

define CHECKPOINT_RESTORE_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source/dmtcp"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(CHECKPOINT_RESTORE_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_checkpoint_restore"
install -m 0555 "$(CHECKPOINT_RESTORE_APP)" \
	"$(1)/artifacts/runtime/checkpoint_restore_app"
install -m 0444 "$(CHECKPOINT_RESTORE_MIGRATION_POLICY)" \
	"$(1)/artifacts/runtime/checkpoint_restore_migration.bpf.o"
install -m 0555 "$(CHECKPOINT_RESTORE_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
cp -a "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)" \
	"$(1)/artifacts/runtime/dmtcp"
cp -a "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" \
	"$(1)/artifacts/source/dmtcp/worktree"
install -m 0444 "$(DMTCP_RESTART_ENV_PATCH)" \
	"$(1)/artifacts/source/dmtcp/restart-env-scan-count.patch"
install -m 0444 "$(CHECKPOINT_RESTORE_DMTCP_CONFIGURE_LOG)" \
	"$(1)/artifacts/source/dmtcp/configure.log"
install -m 0444 "$(CHECKPOINT_RESTORE_DMTCP_BUILD_LOG)" \
	"$(1)/artifacts/source/dmtcp/build.log"
install -m 0444 "$(CHECKPOINT_RESTORE_DMTCP_INSTALL_LOG)" \
	"$(1)/artifacts/source/dmtcp/install.log"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg dmtcp_commit "$(DMTCP_COMMIT)" \
	--arg dmtcp_repository "$(CHECKPOINT_RESTORE_DMTCP_REPOSITORY)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_checkpoint_restore",application:"artifacts/runtime/checkpoint_restore_app",policy:"artifacts/runtime/checkpoint_restore_migration.bpf.o",bpftool:"artifacts/runtime/bpftool",dmtcp:"artifacts/runtime/dmtcp"},source:{dmtcp_commit:$$dmtcp_commit,dmtcp_repository:$$dmtcp_repository,dmtcp_worktree:"artifacts/source/dmtcp/worktree",patch:"artifacts/source/dmtcp/restart-env-scan-count.patch",patch_purpose:"repair dmtcp_get_restart_env scan bound; pathname translation is unchanged",configure_log:"artifacts/source/dmtcp/configure.log",build_log:"artifacts/source/dmtcp/build.log",install_log:"artifacts/source/dmtcp/install.log"}}' \
	>"$(1)/artifacts/manifest.json"
jq -e --arg commit "$(DMTCP_COMMIT)" \
	'.source.dmtcp_commit == $$commit and (.kernel.commit | length) == 40' \
	"$(1)/artifacts/manifest.json" >/dev/null
endef

define CHECKPOINT_RESTORE_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),checkpoint-restore,dmtcp-pathtranslator,$(2),$(1)/observations.jsonl,checkpoint_restore_migration.bpf.c,namei_ext_checkpoint_restore+dmtcp)
$(call CHECKPOINT_RESTORE_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--arg protocol "namei_ext.checkpoint_restore.protocol.v3" \
	--arg layout "$(3)" \
	--argjson repetitions "$(4)" \
	--argjson timeout_seconds "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
	--arg kvm_timeout "$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)" \
	'.protocol_schema = $$protocol | .layout = $$layout | .attempt = 5 | .artifacts = $$artifacts[0] | .matrix = {conditions:["pathvirt","namei_ext","withdrawn"],repetitions:$$repetitions,baseline:"DMTCP PathTranslator at commit 068559d9b14c with a disclosed restart-environment scan-bound fix",control:"withdrawn",pathtranslator_activation:"DMTCP_PATHVIRT_PLUGIN=1; DMTCP_PATH_MAPPING generation A to B",timeout_seconds:$$timeout_seconds,kvm_timeout:$$kvm_timeout,all_conditions_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(5)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define CHECKPOINT_RESTORE_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'CHECKPOINT_RESTORE_BOOT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_RUNNER' "$${runner#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_APP' "$${app#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_POLICY' "$${policy#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_BPFTOOL' "$${bpftool#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_DMTCP' "$${dmtcp#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT' "$$commit" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE' "$$release" \
	'CHECKPOINT_RESTORE_GUEST_TIMEOUT' "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
	>"$$guest_makefile"
endef

.PHONY: checkpoint-restore-analysis-test checkpoint-restore-source-feasibility \
	kvm-checkpoint-restore-preflight kvm-checkpoint-restore-rq1 \
	checkpoint-restore-run checkpoint-restore-finalize \
	checkpoint-restore-analyze __checkpoint_restore_guest

checkpoint-restore-analysis-test:
	python3 -m unittest discover \
		-s "$(ROOT_DIR)/analysis/checkpoint_restore" \
		-p 'test_*.py' -v

checkpoint-restore-source-feasibility: checkpoint-restore
	test ! -e "$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)"
	install -d "$(dir $(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR))"
	mkdir "$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)"
	cp -a "$(CHECKPOINT_RESTORE_DMTCP_SOURCE)" \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/dmtcp-source"
	cp -a "$(CHECKPOINT_RESTORE_DMTCP_INSTALL)" \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/dmtcp-install"
	printf '%s\n' \
		'make checkpoint-restore-source-feasibility RUN_ID=$(RUN_ID)' \
		>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/command.txt"
	printf '%s\n' "$(DMTCP_COMMIT)" \
		>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/dmtcp-commit.txt"
	timeout --signal=TERM --kill-after=10s \
		"$(CHECKPOINT_RESTORE_UPSTREAM_TIMEOUT_SECONDS)" \
		$(MAKE) -C "$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/dmtcp-source" \
		check-autotest AUTOTEST='--verbose pathvirt' \
		>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/upstream-autotest.stdout.log" \
		2>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/upstream-autotest.stderr.log"
	grep -F 'test groups: pass=1 fail=0 skipped=0 total=1' \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/upstream-autotest.stdout.log"
	"$(CHECKPOINT_RESTORE_RUNNER)" pathvirt \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/observations.jsonl" \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)" \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/dmtcp-install" /dev/null \
		"$(CHECKPOINT_RESTORE_APP)" /sys/fs/cgroup \
		"$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
		>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/controller.stdout.log" \
		2>"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/controller.stderr.log"
	jq -s -e \
		'all(.[]; .pass == true) and ([.[] | select(.event == "checkpoint-restore-summary" and .condition == "pathvirt" and .failures == 0)] | length) == 1' \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/observations.jsonl" >/dev/null
	jq -s -e \
		'length == 2 and ([.[] | select(.stage == "pre-checkpoint" and .generation == "a" and .saw_stale == true and .saw_new == false and .pass == true)] | length) == 1 and ([.[] | select(.stage == "post-restart" and .generation == "b" and .saw_stale == false and .saw_new == true and .restart_env_status == 0 and (.restart_mapping | contains("generation-b/workspace")) and .pass == true)] | length) == 1' \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/application-observations.jsonl" \
		>/dev/null
	jq -s -e \
		'length == 6 and all(.[]; .phase == "before" and .final_newline == true and (.content | type == "string" and length > 0))' \
		"$(CHECKPOINT_RESTORE_SOURCE_RESULT_DIR)/lower-before.jsonl" >/dev/null


kvm-checkpoint-restore-preflight: kernel kernel-provenance kernel-bpftool bpf \
		checkpoint-restore checkpoint-restore-analysis-test \
		experiment-source-clean
	test "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" = "120"
	test "$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)" = "600s"
	$(call CHECKPOINT_RESTORE_START,$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR),kvm_checkpoint_restore_preflight,single-modified-kernel-boot,1,make kvm-checkpoint-restore-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-run \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)" \
		CHECKPOINT_RESTORE_BOOT_LABEL=preflight
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-finalize \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)" \
		CHECKPOINT_RESTORE_EXPECTED_BOOTS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-analyze \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)"

kvm-checkpoint-restore-rq1: kernel kernel-provenance kernel-bpftool bpf \
		checkpoint-restore checkpoint-restore-analysis-test \
		experiment-source-clean
	$(call CHECKPOINT_RESTORE_START,$(CHECKPOINT_RESTORE_RQ1_RESULT_DIR),kvm_checkpoint_restore_rq1,three-modified-kernel-boots,3,make kvm-checkpoint-restore-rq1 RUN_ID=$(RUN_ID))
	for index in 1 2 3; do \
		$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-run \
			RUN_ID="$(RUN_ID)" \
			CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_RQ1_RESULT_DIR)" \
			CHECKPOINT_RESTORE_BOOT_LABEL="$$(printf 'block-%02d' "$$index")"; \
	done
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-finalize \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_RQ1_RESULT_DIR)" \
		CHECKPOINT_RESTORE_EXPECTED_BOOTS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(CHECKPOINT_RESTORE_RQ1_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-analyze \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_RQ1_RESULT_DIR)"

checkpoint-restore-run:
	test -n "$(CHECKPOINT_RESTORE_ACTIVE_DIR)"
	test -n "$(CHECKPOINT_RESTORE_BOOT_LABEL)"
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running"' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/run.json" >/dev/null
	manifest="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/artifacts/manifest.json"; \
	image="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.kernel.image' "$$manifest")"; \
	config="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.kernel.config' "$$manifest")"; \
	commit=$$(jq -r '.kernel.commit' "$$manifest"); \
	release=$$(jq -r '.kernel.release' "$$manifest"); \
	runner="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.runtime.runner' "$$manifest")"; \
	app="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.runtime.application' "$$manifest")"; \
	policy="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.runtime.policy' "$$manifest")"; \
	bpftool="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.runtime.bpftool' "$$manifest")"; \
	dmtcp="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/$$(jq -r '.runtime.dmtcp' "$$manifest")"; \
	boot_dir="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/boots/$(CHECKPOINT_RESTORE_BOOT_LABEL)"; \
	mkdir "$$boot_dir"; \
	install -d "$$boot_dir/conditions"; \
	for condition in pathvirt namei_ext withdrawn; do \
		mkdir "$$boot_dir/conditions/$$condition"; \
	done; \
	printf '%s\n' "$(CHECKPOINT_RESTORE_BOOT_LABEL)" \
		>>"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/expected-boots.txt"; \
	guest_makefile="$$boot_dir/guest.mk"; \
	$(call CHECKPOINT_RESTORE_WRITE_GUEST_MAKEFILE); \
	guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__namei_ext_kvm_capture \
		RUN_ID="$(RUN_ID)" \
		NAMEI_EXT_KVM_CAPTURE_IMAGE="$$image" \
		NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="-f Makefile -f $$guest_makefile_rel __checkpoint_restore_guest" \
		NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot_dir" \
		NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(CHECKPOINT_RESTORE_ACTIVE_DIR)" \
		NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)"

checkpoint-restore-finalize:
	test -n "$(CHECKPOINT_RESTORE_ACTIVE_DIR)"
	test -n "$(CHECKPOINT_RESTORE_EXPECTED_BOOTS)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(CHECKPOINT_RESTORE_ACTIVE_DIR),$(CHECKPOINT_RESTORE_EXPECTED_BOOTS),$$(($(CHECKPOINT_RESTORE_EXPECTED_BOOTS) * 3)))
	jq -s -e --argjson boots "$(CHECKPOINT_RESTORE_EXPECTED_BOOTS)" \
		'length > 0 and all(.[]; .pass == true) and ([.[] | select(.event == "checkpoint-restore-summary" and .failures == 0)] | length) == ($$boots * 3)' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/observations.jsonl" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(CHECKPOINT_RESTORE_ACTIVE_DIR),$(CHECKPOINT_RESTORE_EXPECTED_BOOTS),$(CHECKPOINT_RESTORE_BOOT_FILES),$$(($(CHECKPOINT_RESTORE_EXPECTED_BOOTS) * 3)))
	while IFS= read -r boot; do \
		boot_dir="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/boots/$$boot"; \
		jq -e '.schema == "namei_ext.checkpoint_restore.boot.v3" and .status == "completed" and .conditions == ["pathvirt","namei_ext","withdrawn"] and .pathtranslator_activation == "DMTCP_PATHVIRT_PLUGIN=1"' \
			"$$boot_dir/boot.json" >/dev/null; \
		for condition in pathvirt namei_ext withdrawn; do \
			result="$$boot_dir/conditions/$$condition"; \
			jq -s -e --arg condition "$$condition" \
				'all(.[]; .pass == true) and ([.[] | select(.event == "checkpoint-restore-summary" and .condition == $$condition and .failures == 0)] | length) == 1' \
				"$$result/observations.jsonl" >/dev/null; \
		done; \
	done <"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/expected-boots.txt"

checkpoint-restore-analyze:
	test -n "$(CHECKPOINT_RESTORE_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(CHECKPOINT_RESTORE_ACTIVE_DIR))
	$(call NAMEI_EXT_ANALYSIS_PREPARE,$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis)
	python3 "$(CHECKPOINT_RESTORE_ANALYSIS)" \
		--result "$(CHECKPOINT_RESTORE_ACTIVE_DIR)" \
		--output "$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis.tmp"
	for file in summary.json summary.csv report.md; do \
		test -s "$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis.tmp/$$file"; \
	done
	jq -e '.schema == "namei_ext.checkpoint_restore.summary.v3" and .correctness.all_boots_passed == true' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis.tmp/summary.json" >/dev/null
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis)

__checkpoint_restore_guest: __namei_ext_guest_prepare
	test "$(CHECKPOINT_RESTORE_GUEST_TIMEOUT)" = "120"
	test -x "$(CHECKPOINT_RESTORE_GUEST_RUNNER)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_APP)"
	test -r "$(CHECKPOINT_RESTORE_GUEST_POLICY)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_DMTCP)/bin/dmtcp_launch"
	command -v setpriv >/dev/null
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,\
		$(CHECKPOINT_RESTORE_BOOT_DIR),\
		$(CHECKPOINT_RESTORE_GUEST_KERNEL_CONFIG),\
		$(CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT),\
		$(CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE))
	grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms
	runtime_uid=$$(stat -c %u "$(CHECKPOINT_RESTORE_BOOT_DIR)"); \
	runtime_gid=$$(stat -c %g "$(CHECKPOINT_RESTORE_BOOT_DIR)"); \
	setpriv --reuid="$$runtime_uid" --regid="$$runtime_gid" --clear-groups \
		sh -c 'id -u; id -g' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/runtime-identity-probe.txt"; \
	test "$$(sed -n '1p' "$(CHECKPOINT_RESTORE_BOOT_DIR)/runtime-identity-probe.txt")" = "$$runtime_uid"; \
	test "$$(sed -n '2p' "$(CHECKPOINT_RESTORE_BOOT_DIR)/runtime-identity-probe.txt")" = "$$runtime_gid"; \
	jq -n --argjson uid "$$runtime_uid" --argjson gid "$$runtime_gid" \
		'{uid:$$uid,gid:$$gid}' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/runtime-identity.json"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j prog show \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j cgroup tree \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json"
	jq -e 'type == "array" and length == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json" >/dev/null
	jq -e 'type == "array" and ([.. | objects | select(has("id"))] | length) == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json" >/dev/null
	for condition in pathvirt namei_ext withdrawn; do \
		result="$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions/$$condition"; \
		test -d "$$result"; \
		policy=/dev/null; \
		if test "$$condition" != pathvirt; then \
			policy="$(CHECKPOINT_RESTORE_GUEST_POLICY)"; \
		fi; \
		"$(CHECKPOINT_RESTORE_GUEST_RUNNER)" "$$condition" \
			"$$result/observations.jsonl" "$$result" \
			"$(CHECKPOINT_RESTORE_GUEST_DMTCP)" "$$policy" \
			"$(CHECKPOINT_RESTORE_GUEST_APP)" /sys/fs/cgroup \
			"$(CHECKPOINT_RESTORE_GUEST_TIMEOUT)" \
			>"$$result/controller.stdout.log" \
			2>"$$result/controller.stderr.log"; \
		jq -s -e --arg condition "$$condition" \
			'all(.[]; .pass == true) and ([.[] | select(.event == "checkpoint-restore-summary" and .condition == $$condition and .failures == 0)] | length) == 1' \
			"$$result/observations.jsonl" >/dev/null; \
		"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j prog show \
			>"$$result/bpf-programs-after.json"; \
		"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j cgroup tree \
			>"$$result/bpf-cgroup-after.json"; \
		jq -e 'type == "array" and length == 0' \
			"$$result/bpf-programs-after.json" >/dev/null; \
		jq -e 'type == "array" and ([.. | objects | select(has("id"))] | length) == 0' \
			"$$result/bpf-cgroup-after.json" >/dev/null; \
	done
	cat \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions/pathvirt/observations.jsonl" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions/namei_ext/observations.jsonl" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions/withdrawn/observations.jsonl" \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/observations.jsonl"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j prog show \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-after.json"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j cgroup tree \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-after.json"
	jq -e 'type == "array" and length == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-after.json" >/dev/null
	jq -e 'type == "array" and ([.. | objects | select(has("id"))] | length) == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-after.json" >/dev/null
	dmesg >"$(CHECKPOINT_RESTORE_BOOT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(CHECKPOINT_RESTORE_BOOT_DIR)/dmesg.log)
	jq -n \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)" \
		--arg kernel_commit "$(CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT)" \
		--arg kernel_release "$(CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE)" \
		'{schema:"namei_ext.checkpoint_restore.boot.v3",status:"completed",conditions:["pathvirt","namei_ext","withdrawn"],kernel:{commit:$$kernel_commit,release:$$kernel_release},pathtranslator_activation:"DMTCP_PATHVIRT_PLUGIN=1",completed_at:$$completed_at}' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/boot.json"
