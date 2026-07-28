SERVICE_CONFIG_ROTATION_POLICY ?= $(BUILD_ROOT)/bpf/service_config_rotation.bpf.o
SERVICE_CONFIG_ROTATION_POLICY_SOURCE ?= $(ROOT_DIR)/bpf/policies/service_config_rotation.bpf.c
SERVICE_CONFIG_ROTATION_RUNNER ?= $(BUILD_ROOT)/service-config-rotation/namei_ext_service_config_rotation
SERVICE_CONFIG_ROTATION_RUNNER_SOURCE ?= $(ROOT_DIR)/experiments/service_config_rotation/namei_ext_service_config_rotation.c
SERVICE_CONFIG_ROTATION_NGINX ?= $(NGINX_BUILD_SRC)/objs/nginx
SERVICE_CONFIG_ROTATION_PLAN ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-experiment-plan.md
SERVICE_CONFIG_ROTATION_PLAN_REVIEW ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-plan-review.md
SERVICE_CONFIG_ROTATION_V2_PLAN ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-preflight-recovery-plan.md
SERVICE_CONFIG_ROTATION_V2_PLAN_REVIEW ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-v2-plan-review.md
SERVICE_CONFIG_ROTATION_V2_IMPLEMENTATION ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-v2-implementation.md
SERVICE_CONFIG_ROTATION_V2_IMPLEMENTATION_REVIEW ?= $(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-v2-implementation-review.md
SERVICE_CONFIG_ROTATION_SUITE_MAKE ?= $(ROOT_DIR)/mk/experiments/service_config_rotation.mk
SERVICE_CONFIG_ROTATION_BOOT_EVIDENCE_FILES := \
	guest.mk guest.mk.sha256 launcher.stdout.log launcher.stderr.log \
	boot.json raw-runner.jsonl observations.jsonl stdout.log stderr.log \
	outputs.sha256 nginx.error.log nginx.stdout.log nginx.stderr.log \
	nginx-current-test.stdout.log nginx-current-test.stderr.log \
	nginx-canary-test.stdout.log nginx-canary-test.stderr.log \
	nginx-invalid-test.stdout.log nginx-invalid-test.stderr.log \
	nginx-rollback-test.stdout.log nginx-rollback-test.stderr.log \
	nginx-version.txt kernel.config \
	uname.txt proc-version.txt kernel-cmdline.txt dmesg.log
SERVICE_CONFIG_ROTATION_BOOT_FILES := \
	$(SERVICE_CONFIG_ROTATION_BOOT_EVIDENCE_FILES) evidence.sha256
SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS ?= \
	$(BUILD_ROOT)/report-validation/service-config-rotation/$(RUN_ID)

define SERVICE_CONFIG_ROTATION_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(SERVICE_CONFIG_ROTATION_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_service_config_rotation"
install -m 0444 "$(SERVICE_CONFIG_ROTATION_POLICY)" \
	"$(1)/artifacts/runtime/service_config_rotation.bpf.o"
install -m 0555 "$(SERVICE_CONFIG_ROTATION_NGINX)" \
	"$(1)/artifacts/runtime/nginx"
install -m 0444 "$(NGINX_ARCHIVE)" \
	"$(1)/artifacts/source/$(NGINX_ARCHIVE_NAME)"
install -m 0444 "$(NGINX_PROVENANCE)" \
	"$(1)/artifacts/source/nginx-source.json"
install -m 0444 "$(NGINX_BUILD_JSON)" \
	"$(1)/artifacts/source/nginx-build.json"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg nginx_version "$(NGINX_VERSION)" \
	--arg nginx_archive_sha256 "$(NGINX_ARCHIVE_SHA256)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_service_config_rotation",policy:"artifacts/runtime/service_config_rotation.bpf.o",nginx:"artifacts/runtime/nginx"},source:{nginx_version:$$nginx_version,nginx_archive:"artifacts/source/$(NGINX_ARCHIVE_NAME)",nginx_archive_sha256:$$nginx_archive_sha256,nginx_provenance:"artifacts/source/nginx-source.json",nginx_build:"artifacts/source/nginx-build.json"}}' \
	>"$(1)/artifacts/manifest.json"
jq -e '.kernel.commit | length == 40' "$(1)/artifacts/manifest.json" \
	>/dev/null
jq -e '.kernel.release | length > 0' "$(1)/artifacts/manifest.json" \
	>/dev/null
(cd "$(1)" && find artifacts -type f ! -name artifacts.sha256 -print0 | \
	LC_ALL=C sort -z | xargs -0 sha256sum >artifacts.sha256)
endef

define SERVICE_CONFIG_ROTATION_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),service-config-rotation,kubernetes-atomic-writer+nginx,kvm_service_config_rotation,$(1)/observations.jsonl,service_config_rotation.bpf.c,namei_ext_service_config_rotation+nginx)
$(call SERVICE_CONFIG_ROTATION_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--argjson repetitions "$(2)" \
	--argjson timeout_seconds "$(SERVICE_CONFIG_ROTATION_TIMEOUT_SECONDS)" \
	--arg kvm_timeout "$(SERVICE_CONFIG_ROTATION_KVM_TIMEOUT_SECONDS)" \
	'.protocol_schema = "namei_ext.service_config_rotation.protocol.v2" | .layout = "fresh-boot-matrix" | .artifacts = $$artifacts[0] | .matrix = {states:["current","canary","invalid","rollback"],repetitions:$$repetitions,timeout_seconds:$$timeout_seconds,kvm_timeout:$$kvm_timeout,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq -e '.kernel.commit == .artifacts.kernel.commit and .kernel_commit == .artifacts.kernel.commit' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
ldd "$(1)/artifacts/runtime/nginx" >"$(1)/nginx-ldd.txt"
sha256sum \
	"$(ROOT_DIR)/configs/benchmarks/service_config_rotation.mk" \
	"$(ROOT_DIR)/configs/benchmarks/workload-sources.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(SERVICE_CONFIG_ROTATION_SUITE_MAKE)" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/multi_boot.mk" \
	"$(ROOT_DIR)/mk/kvm.mk" \
	"$(ROOT_DIR)/mk/workload.mk" \
	"$(ROOT_DIR)/experiments/service_config_rotation/Makefile" \
	"$(SERVICE_CONFIG_ROTATION_RUNNER_SOURCE)" \
	"$(SERVICE_CONFIG_ROTATION_POLICY_SOURCE)" \
	"$(ROOT_DIR)/runner/src/namei_ext_harness.c" \
	"$(ROOT_DIR)/runner/include/namei_ext_harness.h" \
	"$(SERVICE_CONFIG_ROTATION_ANALYSIS)" \
	"$(ROOT_DIR)/analysis/service_config_rotation/test_analyze.py" \
	"$(SERVICE_CONFIG_ROTATION_PLAN)" \
	"$(SERVICE_CONFIG_ROTATION_PLAN_REVIEW)" \
	"$(SERVICE_CONFIG_ROTATION_V2_PLAN)" \
	"$(SERVICE_CONFIG_ROTATION_V2_PLAN_REVIEW)" \
	"$(SERVICE_CONFIG_ROTATION_V2_IMPLEMENTATION)" \
	"$(SERVICE_CONFIG_ROTATION_V2_IMPLEMENTATION_REVIEW)" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-preflight-attempt-1.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-preflight-attempt-2.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-preflight-attempt-3.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-service-config-rotation-v2-preflight-attempt-1.md" \
	>"$(1)/inputs.sha256"
endef

define SERVICE_CONFIG_ROTATION_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'REPETITION' "$$repetition" \
	'SERVICE_CONFIG_ROTATION_BOOT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'SERVICE_CONFIG_ROTATION_GUEST_RUNNER' "$${runner#$(ROOT_DIR)/}" \
	'SERVICE_CONFIG_ROTATION_GUEST_POLICY' "$${policy#$(ROOT_DIR)/}" \
	'SERVICE_CONFIG_ROTATION_GUEST_NGINX' "$${nginx#$(ROOT_DIR)/}" \
	'SERVICE_CONFIG_ROTATION_GUEST_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'SERVICE_CONFIG_ROTATION_GUEST_KERNEL_COMMIT' "$$commit" \
	'SERVICE_CONFIG_ROTATION_GUEST_KERNEL_RELEASE' "$$release" \
	'SERVICE_CONFIG_ROTATION_GUEST_TIMEOUT' \
		"$(SERVICE_CONFIG_ROTATION_TIMEOUT_SECONDS)" \
	>"$$guest_makefile"; \
	$(call NAMEI_EXT_MULTI_BOOT_SEAL_GUEST_MAKEFILE,$$guest_makefile,9)
endef

.PHONY: service-config-rotation-analysis-test \
	kvm-service-config-rotation-preflight kvm-service-config-rotation \
	service-config-rotation-run-matrix service-config-rotation-finalize \
	service-config-rotation-analyze service-config-rotation-report \
	experiment-service-config-rotation \
	__service_config_rotation_guest

service-config-rotation-analysis-test:
	python3 -m unittest discover \
		-s "$(ROOT_DIR)/analysis/service_config_rotation" \
		-p 'test_*.py' -v

kvm-service-config-rotation-preflight: kernel kernel-provenance bpf \
		service-config-rotation workload-nginx-build \
		service-config-rotation-analysis-test
	test "$(SERVICE_CONFIG_ROTATION_TIMEOUT_SECONDS)" = "5"
	test "$(SERVICE_CONFIG_ROTATION_KVM_TIMEOUT_SECONDS)" = "120s"
	command -v timeout >/dev/null
	$(call SERVICE_CONFIG_ROTATION_START,$(SERVICE_CONFIG_ROTATION_PREFLIGHT_RESULT_DIR),1,make kvm-service-config-rotation-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-run-matrix \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_PREFLIGHT_RESULT_DIR)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-finalize \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_PREFLIGHT_RESULT_DIR)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-analyze \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_PREFLIGHT_RESULT_DIR)"

kvm-service-config-rotation: kernel kernel-provenance bpf \
		service-config-rotation workload-nginx-build \
		service-config-rotation-analysis-test
	test "$(SERVICE_CONFIG_ROTATION_REPETITIONS)" = "10"
	test "$(SERVICE_CONFIG_ROTATION_TIMEOUT_SECONDS)" = "5"
	test "$(SERVICE_CONFIG_ROTATION_KVM_TIMEOUT_SECONDS)" = "120s"
	command -v timeout >/dev/null
	$(call SERVICE_CONFIG_ROTATION_START,$(SERVICE_CONFIG_ROTATION_RESULT_DIR),$(SERVICE_CONFIG_ROTATION_REPETITIONS),make kvm-service-config-rotation RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-run-matrix \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_RESULT_DIR)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS="$(SERVICE_CONFIG_ROTATION_REPETITIONS)"
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-finalize \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_RESULT_DIR)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS="$(SERVICE_CONFIG_ROTATION_REPETITIONS)"
	$(MAKE) -C "$(ROOT_DIR)" service-config-rotation-analyze \
		RUN_ID="$(RUN_ID)" \
		SERVICE_CONFIG_ROTATION_ACTIVE_DIR="$(SERVICE_CONFIG_ROTATION_RESULT_DIR)"

service-config-rotation-run-matrix:
	test -n "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)"
	test -n "$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and .layout == "fresh-boot-matrix"' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/run.json" >/dev/null
	: >"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-boots.txt"
	: >"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-states.txt"
	manifest="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/artifacts/manifest.json"; \
	image="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/$$(jq -r '.kernel.image' "$$manifest")"; \
	config="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/$$(jq -r '.kernel.config' "$$manifest")"; \
	commit=$$(jq -r '.kernel.commit' "$$manifest"); \
	release=$$(jq -r '.kernel.release' "$$manifest"); \
	runner="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/$$(jq -r '.runtime.runner' "$$manifest")"; \
	policy="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/$$(jq -r '.runtime.policy' "$$manifest")"; \
	nginx="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/$$(jq -r '.runtime.nginx' "$$manifest")"; \
	for repetition in $$(seq 1 "$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-boots.txt"; \
		for state in current canary invalid rollback; do \
			printf '%s|%s\n' "$$repetition" "$$state" \
				>>"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-states.txt"; \
		done; \
		boot_dir="$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		install -d "$$boot_dir"; \
		guest_makefile="$$boot_dir/guest.mk"; \
		$(call SERVICE_CONFIG_ROTATION_WRITE_GUEST_MAKEFILE); \
		guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
		host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __service_config_rotation_guest,,$$boot_dir,$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR),,$(SERVICE_CONFIG_ROTATION_KVM_TIMEOUT_SECONDS)); \
		host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
			jq --arg started_at "$$host_started_at" \
				--arg completed_at "$$host_completed_at" \
				'.host_launch = {started_at:$$started_at,completed_at:$$completed_at}' \
				"$$boot_dir/boot.json" >"$$boot_dir/boot.json.tmp"; \
			mv -f "$$boot_dir/boot.json.tmp" "$$boot_dir/boot.json"; \
			(cd "$$boot_dir" && \
				for file in $(SERVICE_CONFIG_ROTATION_BOOT_EVIDENCE_FILES); do \
					test -f "$$file"; \
					test ! -L "$$file"; \
				done && \
				sha256sum $(SERVICE_CONFIG_ROTATION_BOOT_EVIDENCE_FILES) \
					>evidence.sha256); \
		done

service-config-rotation-finalize:
	test -n "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)"
	test -n "$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR),$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS))
	find "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/boots" \
		-mindepth 2 -maxdepth 2 -name boot.json -type f \
		-print0 | sort -z | xargs -0 jq -r '.repetition' | \
		LC_ALL=C sort -n \
		>"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observed-boots.txt"
	jq -r 'select(.event == "service-config-rotation-state") | "\(.repetition)|\(.state)"' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observations.jsonl" | \
		LC_ALL=C sort \
		>"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observed-states.txt"
	LC_ALL=C sort -n -o \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-boots.txt" \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-boots.txt"
	LC_ALL=C sort -o \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-states.txt" \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-states.txt"
	cmp "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-boots.txt" \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observed-boots.txt"
	cmp "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/expected-states.txt" \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observed-states.txt"
	test "$$(jq -s '[.[] | select(.event == "service-config-rotation-state")] | length' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((4 * $(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS)))"
	! jq -e 'select(.pass != true)' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observations.jsonl" >/dev/null
	sha256sum -c "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/inputs.sha256"
	(cd "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)" && \
		sha256sum -c artifacts.sha256)
	test -s "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/nginx-ldd.txt"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR),$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS),$(SERVICE_CONFIG_ROTATION_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		(cd "$$boot" && sha256sum -c evidence.sha256); \
		test -s "$$boot/nginx.error.log"; \
		(cd "$(ROOT_DIR)" && \
			sha256sum -c "$${boot#$(ROOT_DIR)/}/outputs.sha256"); \
		jq -e '.schema == "namei_ext.service_config_rotation.boot.v1" and .status == "completed" and (.host_launch.started_at | type == "string" and length > 0) and (.host_launch.completed_at | type == "string" and length > 0)' \
			"$$boot/boot.json" >/dev/null; \
	done < <(find "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR),$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observations.jsonl)
	jq -e --argjson repetitions "$(SERVICE_CONFIG_ROTATION_ACTIVE_REPETITIONS)" \
		--argjson timeout "$(SERVICE_CONFIG_ROTATION_TIMEOUT_SECONDS)" \
		--arg kvm_timeout "$(SERVICE_CONFIG_ROTATION_KVM_TIMEOUT_SECONDS)" \
		'.protocol_schema == "namei_ext.service_config_rotation.protocol.v2" and .layout == "fresh-boot-matrix" and .matrix.states == ["current","canary","invalid","rollback"] and .matrix.repetitions == $$repetitions and .matrix.timeout_seconds == $$timeout and .matrix.kvm_timeout == $$kvm_timeout and .matrix.all_boots_must_pass == true' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/run.json" >/dev/null

service-config-rotation-analyze:
	test -n "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/run.json" >/dev/null
	python3 "$(SERVICE_CONFIG_ROTATION_ANALYSIS)" \
		--input "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/observations.jsonl" \
		--run "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/run.json" \
		--output "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/analysis"
	for file in summary.json summary.csv report.md; do \
		test -s "$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/analysis/$$file"; \
	done
	jq -e '.schema == "namei_ext.service_config_rotation.summary.v2" and .correctness.all_boots_passed == true and (if .correctness.boots_expected == 10 then .verdict.tested_hypothesis == "supported" and .verdict.evidence_role == "formal" else .correctness.boots_expected == 1 and .verdict.tested_hypothesis == "not_tested" and .verdict.evidence_role == "dependency_preflight" end)' \
		"$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(SERVICE_CONFIG_ROTATION_ACTIVE_DIR))

service-config-rotation-report:
	jq -e '.status == "completed" and .protocol_schema == "namei_ext.service_config_rotation.protocol.v2" and .matrix.repetitions == 10' \
		"$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/run.json" >/dev/null
	test ! -s "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/source-status.txt"
	test ! -s "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/kernel-status.txt"
	test "$$(cat "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/source-commit.txt")" = \
		"$$(jq -r '.source.commit' "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/run.json")"
	test "$$(cat "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/kernel-commit.txt")" = \
		"$$(jq -r '.kernel.commit' "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/run.json")"
	sha256sum -c "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/inputs.sha256"
	(cd "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)" && \
		sha256sum -c artifacts.sha256)
	test -s "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/nginx-ldd.txt"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(SERVICE_CONFIG_ROTATION_RESULT_DIR),$(SERVICE_CONFIG_ROTATION_REPETITIONS),$(SERVICE_CONFIG_ROTATION_BOOT_FILES))
	rm -rf "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)"
	install -d "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)"
	: >"$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/observations.jsonl"
	while IFS= read -r -d '' boot; do \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		(cd "$$boot" && sha256sum -c evidence.sha256); \
		test -s "$$boot/nginx.error.log"; \
		(cd "$(ROOT_DIR)" && \
			sha256sum -c "$${boot#$(ROOT_DIR)/}/outputs.sha256"); \
		jq -e '.schema == "namei_ext.service_config_rotation.boot.v1" and .status == "completed" and (.host_launch.started_at | type == "string" and length > 0) and (.host_launch.completed_at | type == "string" and length > 0)' \
			"$$boot/boot.json" >/dev/null; \
		cat "$$boot/observations.jsonl" \
			>>"$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/observations.jsonl"; \
	done < <(find "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	cmp "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/observations.jsonl" \
		"$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/observations.jsonl"
	python3 "$(SERVICE_CONFIG_ROTATION_ANALYSIS)" \
		--input "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/observations.jsonl" \
		--run "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/run.json" \
		--output "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/analysis"
	for file in summary.json summary.csv report.md; do \
		test -f "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/analysis/$$file"; \
		test ! -L "$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/analysis/$$file"; \
		cmp "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)/analysis/$$file" \
			"$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/analysis/$$file"; \
	done
	jq -e '.schema == "namei_ext.service_config_rotation.summary.v2" and .verdict.tested_hypothesis == "supported"' \
		"$(SERVICE_CONFIG_ROTATION_RESULT_DIR)/analysis/summary.json" \
		>/dev/null
	rm -rf "$(SERVICE_CONFIG_ROTATION_REPORT_REANALYSIS)"

experiment-service-config-rotation: kvm-service-config-rotation

__service_config_rotation_guest: __namei_ext_guest_prepare
	test "$(notdir $(lastword $(MAKEFILE_LIST)))" = guest.mk
	(cd "$(dir $(lastword $(MAKEFILE_LIST)))" && \
		sha256sum -c guest.mk.sha256)
	test -n "$(REPETITION)"
	test "$(SERVICE_CONFIG_ROTATION_GUEST_TIMEOUT)" = "5"
	test -x "$(SERVICE_CONFIG_ROTATION_GUEST_RUNNER)"
	test -r "$(SERVICE_CONFIG_ROTATION_GUEST_POLICY)"
	test -x "$(SERVICE_CONFIG_ROTATION_GUEST_NGINX)"
	install -d "$(SERVICE_CONFIG_ROTATION_BOOT_DIR)"
	: >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/stdout.log"
	: >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/stderr.log"
	printf '{"event":"service-config-rotation-start","result_level":"kvm_service_config_rotation","repetition":%s,"pass":true}\n' \
		"$(REPETITION)" \
		>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/raw-runner.jsonl"
	cp "$(SERVICE_CONFIG_ROTATION_GUEST_KERNEL_CONFIG)" \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/kernel.config"
	actual_release=$$(uname -r); \
	test "$$actual_release" = "$(SERVICE_CONFIG_ROTATION_GUEST_KERNEL_RELEASE)"
	grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms
	uname -a >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/uname.txt"
	cat /proc/version >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/kernel-cmdline.txt"
	"$(SERVICE_CONFIG_ROTATION_GUEST_NGINX)" -V \
		>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/nginx-version.txt" 2>&1
	grep -F 'nginx/$(NGINX_VERSION)' \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/nginx-version.txt"
	"$(SERVICE_CONFIG_ROTATION_GUEST_RUNNER)" \
		"$(SERVICE_CONFIG_ROTATION_GUEST_POLICY)" \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/raw-runner.jsonl" \
		"$(SERVICE_CONFIG_ROTATION_GUEST_NGINX)" \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)" \
		"$(REPETITION)" "$(SERVICE_CONFIG_ROTATION_GUEST_TIMEOUT)" \
		/sys/fs/cgroup \
		>>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/stdout.log" \
		2>>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/stderr.log"
	test -s "$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/nginx.error.log"
	cp "$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/raw-runner.jsonl" \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/observations.jsonl"
	test "$$(jq -s '[.[] | select(.event == "service-config-rotation-state")] | length' \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/observations.jsonl")" = "4"
	for state in current canary invalid rollback; do \
		test "$$(jq -s --arg state "$$state" \
			'[.[] | select(.event == "service-config-rotation-state" and .state == $$state and .pass == true)] | length' \
			"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/observations.jsonl")" = "1"; \
	done
	jq -e 'select(.event == "service-config-rotation-summary" and .states == 4 and .failures == 0 and .pass == true)' \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/observations.jsonl" >/dev/null
	! jq -e 'select(.pass != true)' \
		"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/observations.jsonl" >/dev/null
	find "$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/fixture" \
		-type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum \
		>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/outputs.sha256"
	sha256sum "$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/nginx.error.log" \
		>>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/outputs.sha256"
	dmesg >"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/dmesg.log)
	jq -n --argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(SERVICE_CONFIG_ROTATION_GUEST_KERNEL_COMMIT)" \
		--arg kernel_release "$(SERVICE_CONFIG_ROTATION_GUEST_KERNEL_RELEASE)" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.service_config_rotation.boot.v1",repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_release:$$kernel_release,status:"completed",completed_at:$$completed_at}' \
		>"$(SERVICE_CONFIG_ROTATION_BOOT_DIR)/boot.json"
