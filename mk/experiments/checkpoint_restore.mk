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
CHECKPOINT_RESTORE_SUITE_MAKE ?= \
	$(ROOT_DIR)/mk/experiments/checkpoint_restore.mk
CHECKPOINT_RESTORE_PLAN ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-28-checkpoint-restore-experiment-plan.md
CHECKPOINT_RESTORE_PLAN_REVIEW ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-28-checkpoint-restore-plan-review.md
CHECKPOINT_RESTORE_IMPLEMENTATION_STATUS ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-28-checkpoint-restore-implementation-status.md
CHECKPOINT_RESTORE_ROOT_CAUSE ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-28-dmtcp-restart-env-root-cause.md
CHECKPOINT_RESTORE_BOOT_FILES := \
	guest.mk guest.mk.sha256 launcher.stdout.log launcher.stderr.log \
	boot.json observations.jsonl upstream-autotest.stdout.log \
	upstream-autotest.stderr.log bpf-programs-before.json \
	bpf-programs-after.json bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-after.txt \
	kernel.config kernel-commit.txt kernel-release.txt uname.txt \
	proc-version.txt kernel-cmdline.txt dmesg.log evidence.sha256

define CHECKPOINT_RESTORE_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source/dmtcp/src" \
	"$(1)/artifacts/source/dmtcp/test"
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
cp -a "$(DMTCP_INSTALL_ROOT)" "$(1)/artifacts/runtime/dmtcp"
install -m 0444 "$(DMTCP_ARCHIVE)" \
	"$(1)/artifacts/source/dmtcp/source.tar.gz"
install -m 0444 "$(DMTCP_RESTART_ENV_PATCH)" \
	"$(1)/artifacts/source/dmtcp/restart-env-scan-count.patch"
install -m 0444 "$(DMTCP_BUILD_PROVENANCE)" \
	"$(1)/artifacts/source/dmtcp/build.json"
install -m 0444 "$(DMTCP_INSTALL_MANIFEST)" \
	"$(1)/artifacts/source/dmtcp/install-tree.sha256"
install -m 0444 "$(DMTCP_CONFIGURE_LOG)" \
	"$(1)/artifacts/source/dmtcp/configure.log"
install -m 0444 "$(DMTCP_BUILD_LOG)" \
	"$(1)/artifacts/source/dmtcp/build.log"
install -m 0444 "$(DMTCP_INSTALL_LOG)" \
	"$(1)/artifacts/source/dmtcp/install.log"
install -m 0444 "$(DMTCP_SRC)/src/dmtcpplugin.cpp" \
	"$(1)/artifacts/source/dmtcp/src/dmtcpplugin.cpp"
install -m 0444 "$(DMTCP_SRC)/src/plugin_pathtranslator.cpp" \
	"$(1)/artifacts/source/dmtcp/src/plugin_pathtranslator.cpp"
install -m 0444 "$(DMTCP_SRC)/test/pathvirt1.c" \
	"$(1)/artifacts/source/dmtcp/test/pathvirt1.c"
install -m 0444 "$(DMTCP_SRC)/test/autotest.py" \
	"$(1)/artifacts/source/dmtcp/test/autotest.py"
(cd "$(1)/artifacts/runtime/dmtcp" && \
	sha256sum -c ../../source/dmtcp/install-tree.sha256)
printf '%s  %s\n' "$(DMTCP_ARCHIVE_SHA256)" \
	"$(1)/artifacts/source/dmtcp/source.tar.gz" | sha256sum -c -
printf '%s  %s\n' "$(DMTCP_RESTART_ENV_PATCH_SHA256)" \
	"$(1)/artifacts/source/dmtcp/restart-env-scan-count.patch" | \
	sha256sum -c -
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg dmtcp_commit "$(DMTCP_COMMIT)" \
	--arg dmtcp_archive_sha256 "$(DMTCP_ARCHIVE_SHA256)" \
	--arg dmtcp_patch_sha256 "$(DMTCP_RESTART_ENV_PATCH_SHA256)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_checkpoint_restore",application:"artifacts/runtime/checkpoint_restore_app",policy:"artifacts/runtime/checkpoint_restore_migration.bpf.o",bpftool:"artifacts/runtime/bpftool",dmtcp:"artifacts/runtime/dmtcp"},source:{dmtcp_commit:$$dmtcp_commit,dmtcp_archive:"artifacts/source/dmtcp/source.tar.gz",dmtcp_archive_sha256:$$dmtcp_archive_sha256,dmtcp_patch:"artifacts/source/dmtcp/restart-env-scan-count.patch",dmtcp_patch_sha256:$$dmtcp_patch_sha256,dmtcp_build:"artifacts/source/dmtcp/build.json",dmtcp_install_manifest:"artifacts/source/dmtcp/install-tree.sha256"}}' \
	>"$(1)/artifacts/manifest.json"
jq -e \
	--arg commit "$(DMTCP_COMMIT)" \
	--arg patch "$(DMTCP_RESTART_ENV_PATCH_SHA256)" \
	'.kernel.commit | length == 40' \
	"$(1)/artifacts/manifest.json" >/dev/null
jq -e \
	--arg commit "$(DMTCP_COMMIT)" \
	--arg patch "$(DMTCP_RESTART_ENV_PATCH_SHA256)" \
	'.source.dmtcp_commit == $$commit and .source.dmtcp_patch_sha256 == $$patch' \
	"$(1)/artifacts/manifest.json" >/dev/null
(cd "$(1)" && find artifacts -type f -print0 | LC_ALL=C sort -z | \
	xargs -0 sha256sum >artifacts.sha256)
endef

define CHECKPOINT_RESTORE_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),checkpoint-restore,dmtcp-pathtranslator,kvm_checkpoint_restore_preflight,$(1)/observations.jsonl,checkpoint_restore_migration.bpf.c,namei_ext_checkpoint_restore+dmtcp)
$(call CHECKPOINT_RESTORE_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--argjson timeout_seconds "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
	--argjson upstream_timeout_seconds \
		"$(CHECKPOINT_RESTORE_UPSTREAM_TIMEOUT_SECONDS)" \
	--arg kvm_timeout "$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)" \
	'.protocol_schema = "namei_ext.checkpoint_restore.protocol.v1" | .layout = "single-modified-kernel-boot" | .artifacts = $$artifacts[0] | .matrix = {conditions:["pathvirt","namei_ext","withdrawn"],baseline:"patched DMTCP PathTranslator at commit 068559d9b14c with a disclosed one-line restart-environment scan-bound fix",control:"withdrawn",timeout_seconds:$$timeout_seconds,upstream_timeout_seconds:$$upstream_timeout_seconds,kvm_timeout:$$kvm_timeout,all_conditions_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq -e '.kernel.commit == .artifacts.kernel.commit and .kernel_commit == .artifacts.kernel.commit' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(2)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
sha256sum \
	"$(ROOT_DIR)/configs/benchmarks/checkpoint_restore.mk" \
	"$(ROOT_DIR)/configs/benchmarks/workload-sources.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(CHECKPOINT_RESTORE_SUITE_MAKE)" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/multi_boot.mk" \
	"$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/mk/workload.mk" \
	"$(ROOT_DIR)/experiments/checkpoint_restore/Makefile" \
	"$(CHECKPOINT_RESTORE_RUNNER_SOURCE)" \
	"$(CHECKPOINT_RESTORE_APP_SOURCE)" \
	"$(CHECKPOINT_RESTORE_MIGRATION_POLICY_SOURCE)" \
	"$(ROOT_DIR)/runner/src/namei_ext_harness.c" \
	"$(ROOT_DIR)/runner/include/namei_ext_harness.h" \
	"$(CHECKPOINT_RESTORE_ANALYSIS)" \
	"$(ROOT_DIR)/analysis/checkpoint_restore/test_analyze.py" \
	"$(CHECKPOINT_RESTORE_PLAN)" \
	"$(CHECKPOINT_RESTORE_PLAN_REVIEW)" \
	"$(CHECKPOINT_RESTORE_IMPLEMENTATION_STATUS)" \
	"$(CHECKPOINT_RESTORE_ROOT_CAUSE)" \
	>"$(1)/inputs.sha256"
endef

define CHECKPOINT_RESTORE_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'CHECKPOINT_RESTORE_BOOT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_RUNNER' "$${runner#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_APP' "$${app#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_POLICY' "$${policy#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_BPFTOOL' "$${bpftool#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_DMTCP' "$${dmtcp#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_DMTCP_SOURCE' "$${dmtcp_source#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_BUILD_JSON' "$${dmtcp_build#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_INSTALL_MANIFEST' "$${dmtcp_install_manifest#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT' "$$commit" \
	'CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE' "$$release" \
	'CHECKPOINT_RESTORE_GUEST_TIMEOUT' \
		"$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
	'CHECKPOINT_RESTORE_GUEST_UPSTREAM_TIMEOUT' \
		"$(CHECKPOINT_RESTORE_UPSTREAM_TIMEOUT_SECONDS)" \
	>"$$guest_makefile"; \
$(call NAMEI_EXT_MULTI_BOOT_SEAL_GUEST_MAKEFILE,$$guest_makefile,14)
endef

.PHONY: checkpoint-restore-analysis-test \
	kvm-checkpoint-restore-preflight checkpoint-restore-finalize \
	checkpoint-restore-analyze __checkpoint_restore_guest

checkpoint-restore-analysis-test:
	python3 -m unittest discover \
		-s "$(ROOT_DIR)/analysis/checkpoint_restore" \
		-p 'test_*.py' -v

kvm-checkpoint-restore-preflight: kernel kernel-provenance bpf \
		checkpoint-restore workload-dmtcp-build \
		checkpoint-restore-analysis-test
	test "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" = "120"
	test "$(CHECKPOINT_RESTORE_UPSTREAM_TIMEOUT_SECONDS)" = "120"
	test "$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)" = "600s"
	command -v timeout >/dev/null
	command -v findmnt >/dev/null
	command -v lsof >/dev/null
	test -x "$(CHECKPOINT_RESTORE_BPFTOOL)"
	$(call CHECKPOINT_RESTORE_START,$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR),make kvm-checkpoint-restore-preflight RUN_ID=$(RUN_ID))
	manifest="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/artifacts/manifest.json"; \
	image="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.kernel.image' "$$manifest")"; \
	config="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.kernel.config' "$$manifest")"; \
	commit=$$(jq -r '.kernel.commit' "$$manifest"); \
	release=$$(jq -r '.kernel.release' "$$manifest"); \
	runner="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.runner' "$$manifest")"; \
	app="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.application' "$$manifest")"; \
	policy="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.policy' "$$manifest")"; \
	bpftool="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.bpftool' "$$manifest")"; \
	dmtcp="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.dmtcp' "$$manifest")"; \
	dmtcp_build="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.source.dmtcp_build' "$$manifest")"; \
	dmtcp_install_manifest="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/$$(jq -r '.source.dmtcp_install_manifest' "$$manifest")"; \
	dmtcp_source="$(DMTCP_SRC)"; \
	boot_dir="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/boots/preflight"; \
	install -d "$$boot_dir"; \
	printf '%s\n' preflight \
		>>"$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)/expected-boots.txt"; \
	guest_makefile="$$boot_dir/guest.mk"; \
	$(call CHECKPOINT_RESTORE_WRITE_GUEST_MAKEFILE); \
	guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
	host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
	$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __checkpoint_restore_guest,,$$boot_dir,$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR),,$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)); \
	host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
	jq --arg started_at "$$host_started_at" \
		--arg completed_at "$$host_completed_at" \
		'.host_launch = {started_at:$$started_at,completed_at:$$completed_at}' \
		"$$boot_dir/boot.json" >"$$boot_dir/boot.json.tmp"; \
	mv -f "$$boot_dir/boot.json.tmp" "$$boot_dir/boot.json"; \
	(cd "$$boot_dir" && find . -type f ! -name evidence.sha256 \
		-print0 | LC_ALL=C sort -z | xargs -0 sha256sum \
		>evidence.sha256)
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-finalize \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" checkpoint-restore-analyze \
		RUN_ID="$(RUN_ID)" \
		CHECKPOINT_RESTORE_ACTIVE_DIR="$(CHECKPOINT_RESTORE_PREFLIGHT_RESULT_DIR)"

checkpoint-restore-finalize:
	test -n "$(CHECKPOINT_RESTORE_ACTIVE_DIR)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(CHECKPOINT_RESTORE_ACTIVE_DIR),1)
	jq -s -e \
		'. as $$rows | ([$$rows[] | select(.event == "checkpoint-restore-summary") | .condition] | sort) == ["namei_ext","pathvirt","withdrawn"] and all($$rows[]; .pass == true)' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/observations.jsonl" >/dev/null
	! jq -e 'select(.pass != true)' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/observations.jsonl" >/dev/null
	sha256sum -c "$(CHECKPOINT_RESTORE_ACTIVE_DIR)/inputs.sha256"
	(cd "$(CHECKPOINT_RESTORE_ACTIVE_DIR)" && sha256sum -c artifacts.sha256)
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(CHECKPOINT_RESTORE_ACTIVE_DIR),1,$(CHECKPOINT_RESTORE_BOOT_FILES))
	boot="$(CHECKPOINT_RESTORE_ACTIVE_DIR)/boots/preflight"; \
	(cd "$$boot" && sha256sum -c guest.mk.sha256); \
	(cd "$$boot" && sha256sum -c evidence.sha256); \
	grep -F 'test groups: pass=1 fail=0 skipped=0 total=1' \
		"$$boot/upstream-autotest.stdout.log" >/dev/null; \
	jq -e '.schema == "namei_ext.checkpoint_restore.boot.v1" and .status == "completed" and .conditions == ["pathvirt","namei_ext","withdrawn"] and (.host_launch.started_at | type == "string" and length > 0) and (.host_launch.completed_at | type == "string" and length > 0)' \
		"$$boot/boot.json" >/dev/null; \
	for condition in pathvirt namei_ext withdrawn; do \
		result="$$boot/conditions/$$condition"; \
		test -d "$$result"; \
		jq -s -e --arg condition "$$condition" \
			'all(.[]; .pass == true) and ([.[] | select(.event == "checkpoint-restore-summary" and .condition == $$condition and .failures == 0)] | length) == 1' \
			"$$result/observations.jsonl" >/dev/null; \
		(cd "$$result" && sha256sum -c checkpoint-images.sha256); \
	done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(CHECKPOINT_RESTORE_ACTIVE_DIR),$(CHECKPOINT_RESTORE_ACTIVE_DIR)/observations.jsonl)
	jq -e \
		--argjson timeout "$(CHECKPOINT_RESTORE_TIMEOUT_SECONDS)" \
		--argjson upstream_timeout \
			"$(CHECKPOINT_RESTORE_UPSTREAM_TIMEOUT_SECONDS)" \
		--arg kvm_timeout "$(CHECKPOINT_RESTORE_KVM_TIMEOUT_SECONDS)" \
		'.protocol_schema == "namei_ext.checkpoint_restore.protocol.v1" and .layout == "single-modified-kernel-boot" and .matrix.conditions == ["pathvirt","namei_ext","withdrawn"] and .matrix.timeout_seconds == $$timeout and .matrix.upstream_timeout_seconds == $$upstream_timeout and .matrix.kvm_timeout == $$kvm_timeout and .matrix.all_conditions_must_pass == true' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/run.json" >/dev/null

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
	jq -e '.schema == "namei_ext.checkpoint_restore.summary.v1" and .correctness.all_conditions_passed == true and .verdict.tested_hypothesis == "not_tested" and .verdict.evidence_role == "dependency_preflight"' \
		"$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis.tmp/summary.json" \
		>/dev/null
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$(CHECKPOINT_RESTORE_ACTIVE_DIR)/analysis)

__checkpoint_restore_guest: __namei_ext_guest_prepare
	test "$(notdir $(lastword $(MAKEFILE_LIST)))" = guest.mk
	(cd "$(dir $(lastword $(MAKEFILE_LIST)))" && \
		sha256sum -c guest.mk.sha256)
	test "$(CHECKPOINT_RESTORE_GUEST_TIMEOUT)" = "120"
	test "$(CHECKPOINT_RESTORE_GUEST_UPSTREAM_TIMEOUT)" = "120"
	test -x "$(CHECKPOINT_RESTORE_GUEST_RUNNER)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_APP)"
	test -r "$(CHECKPOINT_RESTORE_GUEST_POLICY)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)"
	test -x "$(CHECKPOINT_RESTORE_GUEST_DMTCP)/bin/dmtcp_launch"
	test -f "$(CHECKPOINT_RESTORE_GUEST_DMTCP_SOURCE)/Makefile"
	command -v findmnt >/dev/null
	command -v lsof >/dev/null
	test -c /dev/fuse
	install -d "$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions"
	cp "$(CHECKPOINT_RESTORE_GUEST_KERNEL_CONFIG)" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/kernel.config"
	printf '%s\n' "$(CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT)" \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/kernel-commit.txt"
	actual_release=$$(uname -r); \
	test "$$actual_release" = "$(CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE)"; \
	printf '%s\n' "$$actual_release" \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/kernel-release.txt"
	grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms
	uname -a >"$(CHECKPOINT_RESTORE_BOOT_DIR)/uname.txt"
	cat /proc/version >"$(CHECKPOINT_RESTORE_BOOT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(CHECKPOINT_RESTORE_BOOT_DIR)/kernel-cmdline.txt"
	(cd "$(CHECKPOINT_RESTORE_GUEST_DMTCP)" && \
		sha256sum -c \
			"$(ROOT_DIR)/$(CHECKPOINT_RESTORE_GUEST_INSTALL_MANIFEST)")
	for file in src/dmtcpplugin.cpp src/plugin_pathtranslator.cpp \
			test/pathvirt1.c test/autotest.py; do \
		expected=$$(jq -r --arg file "$$file" \
			'.source.pinned_files[$$file]' \
			"$(CHECKPOINT_RESTORE_GUEST_BUILD_JSON)"); \
		test "$$(sha256sum \
			"$(CHECKPOINT_RESTORE_GUEST_DMTCP_SOURCE)/$$file" | \
			awk '{print $$1}')" = "$$expected"; \
	done
	for file in dmtcp_launch dmtcp_coordinator dmtcp_command \
			dmtcp_restart mtcp_restart; do \
		test "$$(sha256sum \
			"$(CHECKPOINT_RESTORE_GUEST_DMTCP_SOURCE)/bin/$$file" | \
			awk '{print $$1}')" = "$$(sha256sum \
			"$(CHECKPOINT_RESTORE_GUEST_DMTCP)/bin/$$file" | \
			awk '{print $$1}')"; \
	done
	timeout --signal=TERM --kill-after=10s \
		"$(CHECKPOINT_RESTORE_GUEST_UPSTREAM_TIMEOUT)" \
		$(MAKE) -C "$(CHECKPOINT_RESTORE_GUEST_DMTCP_SOURCE)" \
		check-autotest AUTOTEST=pathvirt \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/upstream-autotest.stdout.log" \
		2>"$(CHECKPOINT_RESTORE_BOOT_DIR)/upstream-autotest.stderr.log"
	grep -F 'test groups: pass=1 fail=0 skipped=0 total=1' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/upstream-autotest.stdout.log"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j prog show \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json"
	"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j cgroup tree \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json"
	jq -e 'type == "array" and length == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json" \
		>/dev/null
	jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json" \
		>/dev/null
	findmnt -rn -o FSTYPE,TARGET | \
		awk '$$1 == "fuse" || $$1 == "fuseblk" || index($$1, "fuse.") == 1' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-before.txt"
	test ! -s "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-before.txt"
	lsof_status=0; \
	lsof -Fpc /dev/fuse \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-before.txt" || \
		lsof_status=$$?; \
	test "$$lsof_status" = 1; \
	test ! -s "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-before.txt"
	for condition in pathvirt namei_ext withdrawn; do \
		result="$(CHECKPOINT_RESTORE_BOOT_DIR)/conditions/$$condition"; \
		mkdir "$$result"; \
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
		(cd "$$result" && sha256sum -c checkpoint-images.sha256); \
		if test "$$condition" = pathvirt; then \
			"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j prog show \
				>"$$result/bpf-programs-after.json"; \
			"$(CHECKPOINT_RESTORE_GUEST_BPFTOOL)" -j cgroup tree \
				>"$$result/bpf-cgroup-after.json"; \
			cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json" \
				"$$result/bpf-programs-after.json"; \
			cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json" \
				"$$result/bpf-cgroup-after.json"; \
		fi; \
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
	cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-before.json" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-programs-after.json"
	cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-before.json" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/bpf-cgroup-after.json"
	findmnt -rn -o FSTYPE,TARGET | \
		awk '$$1 == "fuse" || $$1 == "fuseblk" || index($$1, "fuse.") == 1' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-after.txt"
	test ! -s "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-after.txt"
	lsof_status=0; \
	lsof -Fpc /dev/fuse \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-after.txt" || \
		lsof_status=$$?; \
	test "$$lsof_status" = 1; \
	test ! -s "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-after.txt"
	cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-before.txt" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-mounts-after.txt"
	cmp "$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-before.txt" \
		"$(CHECKPOINT_RESTORE_BOOT_DIR)/fuse-open-fds-after.txt"
	dmesg >"$(CHECKPOINT_RESTORE_BOOT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(CHECKPOINT_RESTORE_BOOT_DIR)/dmesg.log)
	jq -n \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)" \
		--arg kernel_commit "$(CHECKPOINT_RESTORE_GUEST_KERNEL_COMMIT)" \
		--arg kernel_release "$(CHECKPOINT_RESTORE_GUEST_KERNEL_RELEASE)" \
		'{schema:"namei_ext.checkpoint_restore.boot.v1",status:"completed",conditions:["pathvirt","namei_ext","withdrawn"],kernel:{commit:$$kernel_commit,release:$$kernel_release},upstream_pathvirt_test:"passed",completed_at:$$completed_at}' \
		>"$(CHECKPOINT_RESTORE_BOOT_DIR)/boot.json"
