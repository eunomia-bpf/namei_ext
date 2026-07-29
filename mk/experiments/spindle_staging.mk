SPINDLE_STAGING_POLICY ?= $(BUILD_ROOT)/bpf/spindle_staging.bpf.o
SPINDLE_STAGING_POLICY_SOURCE ?= \
	$(ROOT_DIR)/bpf/policies/spindle_staging.bpf.c
SPINDLE_STAGING_RUNNER ?= \
	$(BUILD_ROOT)/spindle-staging/namei_ext_spindle_staging
SPINDLE_STAGING_RUNNER_SOURCE ?= \
	$(ROOT_DIR)/experiments/spindle_staging/namei_ext_spindle_staging.c
SPINDLE_STAGING_EXPERIMENT_MAKE ?= \
	$(ROOT_DIR)/experiments/spindle_staging/Makefile
SPINDLE_STAGING_SUITE_MAKE ?= \
	$(ROOT_DIR)/mk/experiments/spindle_staging.mk
SPINDLE_STAGING_PLAN ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-29-spindle-hpc-staging-experiment-plan.md
SPINDLE_STAGING_PLAN_REVIEW ?= \
	$(ROOT_DIR)/docs/tmp/2026-07-29-spindle-hpc-staging-plan-review.md
SPINDLE_STAGING_BPFTOOL ?= $(KERNEL_BPFTOOL)
SPINDLE_STAGING_HOST_PREFLIGHT_DIR ?= \
	$(BUILD_ROOT)/spindle-staging/host-preflight
SPINDLE_STAGING_GUEST_COMPILED_ABS = \
	$(ROOT_DIR)/$(SPINDLE_STAGING_GUEST_COMPILED_ROOT)
SPINDLE_STAGING_GUEST_SPINDLE_ABS = \
	$(ROOT_DIR)/$(SPINDLE_STAGING_GUEST_SPINDLE)
SPINDLE_STAGING_GUEST_TEST_DIR_ABS = \
	$(ROOT_DIR)/$(SPINDLE_STAGING_GUEST_TEST_DIR)
SPINDLE_STAGING_GUEST_HELLO_SOURCE_ABS = \
	$(ROOT_DIR)/$(SPINDLE_STAGING_GUEST_RUN_DIR)/artifacts/source/hello.py
SPINDLE_STAGING_BOOT_FILES := \
	guest.mk launcher.stdout.log launcher.stderr.log \
	boot.json raw-runner.jsonl observations.jsonl \
	source.stdout.log source.stderr.log \
	namei_ext.stdout.log namei_ext.stderr.log \
	withdrawn.stdout.log withdrawn.stderr.log \
	cache-tree.txt focal-manifest-before.jsonl \
	focal-manifest-after.jsonl runtime-identity.json \
	runtime-metadata.json runtime-symlinks.txt \
	readlink-fixtures-active.tsv readlink-fixtures-after.tsv \
	readlink-fixtures-restored.tsv \
	runtime-mount-active.txt runtime-mount-before.status \
	runtime-mount-after.status \
	guest-prepare.status guest-inner.status guest-cleanup.status \
	guest-inventory-after.status guest-dmesg.status \
	test-driver-ldd.txt spindle-ldd.txt \
	test-driver-file.txt test-driver-readelf-program.txt \
	test-driver-readelf-dynamic.txt spindle-compiled-paths.txt \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	kernel.config kernel-commit.txt kernel-release.txt uname.txt \
	proc-version.txt kernel-cmdline.txt dmesg.log

define SPINDLE_STAGING_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(SPINDLE_STAGING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_spindle_staging"
install -m 0444 "$(SPINDLE_STAGING_POLICY)" \
	"$(1)/artifacts/runtime/spindle_staging.bpf.o"
install -m 0555 "$(SPINDLE_STAGING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0444 "$(SPINDLE_BUILD_PROVENANCE)" \
	"$(1)/artifacts/source/build.json"
install -m 0444 "$(SPINDLE_CONFIGURE_LOG)" \
	"$(1)/artifacts/source/configure.log"
install -m 0444 "$(SPINDLE_BUILD_LOG)" \
	"$(1)/artifacts/source/build.log"
install -m 0444 "$(SPINDLE_INSTALL_LOG)" \
	"$(1)/artifacts/source/install.log"
install -m 0444 "$(SPINDLE_SRC)/testsuite/test_driver.c" \
	"$(1)/artifacts/source/test_driver.c"
install -m 0444 "$(SPINDLE_SRC)/testsuite/Makefile.am" \
	"$(1)/artifacts/source/testsuite-Makefile.am"
install -m 0444 "$(SPINDLE_SRC)/src/server/cache/global_name.c" \
	"$(1)/artifacts/source/global_name.c"
install -m 0444 "$(SPINDLE_SRC)/testsuite/hello.py" \
	"$(1)/artifacts/source/hello.py"
stat -c '%n	%a	%u	%g	%s	%d	%i' \
	"$(SPINDLE_TEST_DIR)/retzero_" \
	"$(SPINDLE_TEST_DIR)/retzero_x" \
	>"$(1)/artifacts/source/excluded-permission-fixtures.tsv"
printf '%s\t%s\t%s\t%s\n' \
	'source' 'target' 'transport_mode' 'active_mode' \
	'hello.py' 'hello_.py' '0600' '0200' \
	'hello.py' 'hello_x.py' '0700' '0300' \
	>"$(1)/artifacts/source/reconstructed-readlink-fixtures.tsv"
runtime_tar="$(1)/artifacts/source/spindle-runtime-tree.tar.tmp"; \
runtime_gz="$(1)/artifacts/source/spindle-runtime-tree.tar.gz.tmp"; \
rm -f "$$runtime_tar" "$$runtime_gz"; \
cleanup_runtime_archive() { rm -f "$$runtime_tar" "$$runtime_gz"; }; \
trap cleanup_runtime_archive EXIT; \
tar --exclude='build/testsuite/spindle_output.*' \
	--exclude='build/testsuite/spindle_test*' \
	--exclude='build/testsuite/retzero_' \
	--exclude='build/testsuite/retzero_x' \
	--exclude='build/testsuite/hello_.py' \
	--exclude='build/testsuite/hello_x.py' \
	-cf "$$runtime_tar" -C "$(SPINDLE_WORK_ROOT)" build prefix; \
tar --append --file="$$runtime_tar" \
	--transform='s|^hello.py$$|build/testsuite/hello_.py|' \
	--mode=0600 -C "$(SPINDLE_SRC)/testsuite" hello.py; \
tar --append --file="$$runtime_tar" \
	--transform='s|^hello.py$$|build/testsuite/hello_x.py|' \
	--mode=0700 -C "$(SPINDLE_SRC)/testsuite" hello.py; \
gzip -n -c "$$runtime_tar" >"$$runtime_gz"; \
mv -f "$$runtime_gz" \
	"$(1)/artifacts/source/spindle-runtime-tree.tar.gz"; \
rm -f "$$runtime_tar"; \
trap - EXIT
test "$$(tar -tzf "$(1)/artifacts/source/spindle-runtime-tree.tar.gz" | \
	grep -Fxc 'build/testsuite/hello_.py')" = 1
test "$$(tar -tzf "$(1)/artifacts/source/spindle-runtime-tree.tar.gz" | \
	grep -Fxc 'build/testsuite/hello_x.py')" = 1
tar -xOf "$(1)/artifacts/source/spindle-runtime-tree.tar.gz" \
	build/testsuite/hello_.py | \
	cmp - "$(1)/artifacts/source/hello.py"
tar -xOf "$(1)/artifacts/source/spindle-runtime-tree.tar.gz" \
	build/testsuite/hello_x.py | \
	cmp - "$(1)/artifacts/source/hello.py"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg spindle_commit "$(SPINDLE_COMMIT)" \
	--arg compiled_root "$(SPINDLE_WORK_ROOT)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:{path:"artifacts/runtime/namei_ext_spindle_staging"},policy:{path:"artifacts/runtime/spindle_staging.bpf.o"},bpftool:{path:"artifacts/runtime/bpftool"}},source:{spindle_commit:$$spindle_commit,build:"artifacts/source/build.json",runtime_tree:{path:"artifacts/source/spindle-runtime-tree.tar.gz"},excluded_permission_fixtures:{path:"artifacts/source/excluded-permission-fixtures.tsv",count:2},reconstructed_readlink_fixtures:{path:"artifacts/source/reconstructed-readlink-fixtures.tsv",count:2,source:{path:"artifacts/source/hello.py"}}},execution:{compiled_root:$$compiled_root}}' \
	>"$(1)/artifacts/manifest.json"
jq -e \
	--arg commit "$(SPINDLE_COMMIT)" \
	'.source.spindle_commit == $$commit and (.kernel.commit | length) == 40 and .source.excluded_permission_fixtures.count == 2 and .source.reconstructed_readlink_fixtures.count == 2 and (.execution.compiled_root | length) > 1' \
	"$(1)/artifacts/manifest.json" >/dev/null
endef

define SPINDLE_STAGING_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),spindle-staging,LLNL-Spindle,kvm_spindle_staging,$(1)/observations.jsonl,spindle_staging.bpf.c,namei_ext_spindle_staging)
$(call SPINDLE_STAGING_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	--arg kvm_timeout "$(SPINDLE_STAGING_KVM_TIMEOUT_SECONDS)" \
	--arg spindle_commit "$(SPINDLE_COMMIT)" \
	'.protocol_schema = "namei_ext.spindle_staging.protocol.v1" | .layout = "fresh-boot-source-namei-withdrawn" | .source_commit = $$spindle_commit | .matrix = {conditions:["source_spindle","namei_ext","withdrawn"],focal_objects:47,repetitions:$$repetitions,source_timeout_seconds:180,namei_timeout_seconds:120,withdrawn_timeout_seconds:120,kvm_timeout:$$kvm_timeout,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define SPINDLE_STAGING_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'REPETITION' "$$repetition" \
	'SPINDLE_STAGING_BOOT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_RUN_DIR' "$${run_dir#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_RUNNER' "$${runner#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_POLICY' "$${policy#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_SPINDLE' "$${spindle#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_TEST_DIR' "$${test_dir#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_RUNTIME_ROOT' "$${runtime_root#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_COMPILED_ROOT' "$${compiled_root#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'SPINDLE_STAGING_GUEST_KERNEL_COMMIT' "$$commit" \
	'SPINDLE_STAGING_GUEST_KERNEL_RELEASE' "$$release" \
	'SPINDLE_STAGING_GUEST_BPFTOOL' "$${bpftool#$(ROOT_DIR)/}" \
	>"$$guest_makefile"
endef

.PHONY: spindle-staging \
		spindle-staging-host-preflight \
		kvm-spindle-staging-preflight kvm-spindle-staging \
	spindle-staging-run-matrix spindle-staging-finalize \
	spindle-staging-analyze experiment-spindle-staging \
	__spindle_staging_guest __spindle_staging_guest_inner \
	__spindle_staging_guest_inventory_after

spindle-staging:
	$(MAKE) -C "$(ROOT_DIR)/experiments/spindle_staging" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

spindle-staging-host-preflight: kernel-bpftool kernel kernel-provenance bpf \
		spindle-staging workload-spindle-build
	rm -rf "$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)"
	install -d "$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)"
	$(call SPINDLE_STAGING_CAPTURE_ARTIFACTS,$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR))
	test -x "$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)/artifacts/runtime/namei_ext_spindle_staging"
	test -r "$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)/artifacts/runtime/spindle_staging.bpf.o"
	test -x "$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)/artifacts/runtime/bpftool"
	jq -e --arg commit "$(SPINDLE_COMMIT)" \
		'.source.spindle_commit == $$commit and .source.reconstructed_readlink_fixtures.count == 2' \
		"$(SPINDLE_STAGING_HOST_PREFLIGHT_DIR)/artifacts/manifest.json" >/dev/null

kvm-spindle-staging-preflight: experiment-source-clean kernel-bpftool \
		kernel kernel-provenance bpf spindle-staging \
		workload-spindle-build
	test "$(SPINDLE_STAGING_PREFLIGHT_REPETITIONS)" = "1"
	test "$(SPINDLE_STAGING_KVM_TIMEOUT_SECONDS)" = "600s"
	$(call SPINDLE_STAGING_START,$(SPINDLE_STAGING_PREFLIGHT_RESULT_DIR),1,make kvm-spindle-staging-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-run-matrix \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_PREFLIGHT_RESULT_DIR)" \
		SPINDLE_STAGING_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-finalize \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_PREFLIGHT_RESULT_DIR)" \
		SPINDLE_STAGING_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(SPINDLE_STAGING_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-analyze \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_PREFLIGHT_RESULT_DIR)"

kvm-spindle-staging: experiment-source-clean kernel-bpftool \
		kernel kernel-provenance bpf spindle-staging \
		workload-spindle-build
	test "$(SPINDLE_STAGING_REPETITIONS)" = "3"
	test "$(SPINDLE_STAGING_KVM_TIMEOUT_SECONDS)" = "600s"
	$(call SPINDLE_STAGING_START,$(SPINDLE_STAGING_RESULT_DIR),3,make kvm-spindle-staging RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-run-matrix \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_RESULT_DIR)" \
		SPINDLE_STAGING_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-finalize \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_RESULT_DIR)" \
		SPINDLE_STAGING_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(SPINDLE_STAGING_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" spindle-staging-analyze \
		RUN_ID="$(RUN_ID)" \
		SPINDLE_STAGING_ACTIVE_DIR="$(SPINDLE_STAGING_RESULT_DIR)"

spindle-staging-run-matrix:
	test -n "$(SPINDLE_STAGING_ACTIVE_DIR)"
	test -n "$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and .layout == "fresh-boot-source-namei-withdrawn"' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/run.json" >/dev/null
	manifest="$(SPINDLE_STAGING_ACTIVE_DIR)/artifacts/manifest.json"; \
	image="$(SPINDLE_STAGING_ACTIVE_DIR)/$$(jq -r '.kernel.image' "$$manifest")"; \
	config="$(SPINDLE_STAGING_ACTIVE_DIR)/$$(jq -r '.kernel.config' "$$manifest")"; \
	commit=$$(jq -r '.kernel.commit' "$$manifest"); \
	release=$$(jq -r '.kernel.release' "$$manifest"); \
	run_dir="$(SPINDLE_STAGING_ACTIVE_DIR)"; \
	runner="$$run_dir/$$(jq -r '.runtime.runner.path' "$$manifest")"; \
	policy="$$run_dir/$$(jq -r '.runtime.policy.path' "$$manifest")"; \
	bpftool="$$run_dir/$$(jq -r '.runtime.bpftool.path' "$$manifest")"; \
	runtime_archive="$$run_dir/$$(jq -r '.source.runtime_tree.path' "$$manifest")"; \
	compiled_root=$$(jq -r '.execution.compiled_root' "$$manifest"); \
	for repetition in $$(seq 1 "$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(SPINDLE_STAGING_ACTIVE_DIR)/expected-boots.txt"; \
		boot_dir="$(SPINDLE_STAGING_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot_dir"; \
		runtime_root="$$boot_dir/runtime/worktree"; \
		install -d "$$runtime_root"; \
		tar -xzf "$$runtime_archive" -C "$$runtime_root"; \
		spindle="$$compiled_root/prefix/bin/spindle"; \
		test_dir="$$compiled_root/build/testsuite"; \
		(cd "$$runtime_root" && \
			find build prefix -type l -printf '%p\t%l\n' | \
			LC_ALL=C sort) >"$$boot_dir/runtime-symlinks.txt"; \
		test -x "$$runtime_root/prefix/bin/spindle"; \
		test -x "$$runtime_root/build/testsuite/test_driver"; \
		cmp "$$runtime_root/build/testsuite/hello_.py" \
			"$$run_dir/artifacts/source/hello.py"; \
		cmp "$$runtime_root/build/testsuite/hello_x.py" \
			"$$run_dir/artifacts/source/hello.py"; \
		guest_makefile="$$boot_dir/guest.mk"; \
		$(call SPINDLE_STAGING_WRITE_GUEST_MAKEFILE); \
		guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
		capture_status=0; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$$image" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="-f Makefile -f $$guest_makefile_rel __spindle_staging_guest" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot_dir" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(SPINDLE_STAGING_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(SPINDLE_STAGING_KVM_TIMEOUT_SECONDS)" || \
			capture_status=$$?; \
		if test -f "$$boot_dir/boot.json"; then \
			jq --arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
				'.host_capture_completed_at = $$completed_at' \
				"$$boot_dir/boot.json" >"$$boot_dir/boot.json.tmp"; \
			mv -f "$$boot_dir/boot.json.tmp" "$$boot_dir/boot.json"; \
		fi; \
		if test "$$capture_status" -ne 0; then \
			exit "$$capture_status"; \
		fi; \
	done

spindle-staging-finalize:
	test -n "$(SPINDLE_STAGING_ACTIVE_DIR)"
	test -n "$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(SPINDLE_STAGING_ACTIVE_DIR),$(SPINDLE_STAGING_ACTIVE_REPETITIONS))
	while IFS= read -r -d '' boot; do \
		cmp "$$boot/readlink-fixtures-active.tsv" \
			"$$boot/readlink-fixtures-after.tsv"; \
		diff -u \
			<(jq -cS 'del(.phase)' \
				"$$boot/focal-manifest-before.jsonl") \
			<(jq -cS 'del(.phase)' \
				"$$boot/focal-manifest-after.jsonl"); \
		awk 'NR == 1 { ok = ($$2 == "200") } \
		     NR == 2 { ok = ok && ($$2 == "300") } \
		     END { exit !(NR == 2 && ok) }' \
			"$$boot/readlink-fixtures-active.tsv"; \
		awk 'NR == 1 { ok = ($$2 == "600") } \
		     NR == 2 { ok = ok && ($$2 == "700") } \
		     END { exit !(NR == 2 && ok) }' \
			"$$boot/readlink-fixtures-restored.tsv"; \
		for fixture in hello_.py hello_x.py; do \
			cmp "$$boot/runtime/worktree/build/testsuite/$$fixture" \
				"$(SPINDLE_STAGING_ACTIVE_DIR)/artifacts/source/hello.py"; \
		done; \
	done < <(find "$(SPINDLE_STAGING_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-condition" and .runner_errno == 0 and .diagnostic_ok == true)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((3 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"
	for event in mapping selection identity preservation; do \
		test "$$(jq -s --arg event "spindle-staging-$$event" \
			'[.[] | select(.event == $$event)] | length' \
			"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
			"$$((47 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"; \
	done
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-mapping" and .pass == true and .bytes_equal == true and .source_dev != .cache_dev and .source_size == .cache_size)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((47 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-runtime" and .pass == true and .env_i == true and .uid > 0 and .source_argv[6] == .namei_argv[0] and .namei_argv == .withdrawn_argv and .namei_env == .withdrawn_env and (all(.source_env[]; ((startswith("LD_AUDIT=") or startswith("LD_PRELOAD=") or startswith("LDCS_")) | not))) and (all(.namei_env[]; ((startswith("LD_AUDIT=") or startswith("LD_PRELOAD=")) | not))) and ([.namei_env[] | select(startswith("LDCS_"))] == ["LDCS_CHOSEN_PARSED_CACHEPATH=/__namei_ext_no_spindle_cache__"]))] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-counter-window" and .pass == true and .select_after >= .select_before and .select_delta == (.select_after - .select_before) and .select_delta == .per_target_delta_sum and .select_delta >= 47)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-selection" and .pass == true and .hits_after >= .hits_before and .hits_delta == (.hits_after - .hits_before) and .hits_delta > 0)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((47 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-identity" and .pass == true and .probe_errno == 0 and .actual_dev == .expected_dev and .actual_ino == .expected_ino and .actual_mode == .expected_mode and .actual_size == .expected_size)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((47 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-preservation" and .pass == true and .source_metadata_equal == true and .cache_metadata_equal == true and .bytes_equal == true)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((47 * $(SPINDLE_STAGING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-permission" and .pass == true and .temporary_mode == 0 and .observed_errno == 13 and .probe_errno == 0 and .restore_errno == 0)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-withdrawal" and .pass == true and .target_id == 1 and .hits_after == .hits_before and .hits_delta == 0 and .nonzero_exit == true and .expected_diagnostic == true)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "spindle-staging-summary" and .pass == true and .focal_objects == 47 and .failures == 0)] | length' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(SPINDLE_STAGING_ACTIVE_REPETITIONS)"
	! jq -e 'select(.pass != true)' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl" >/dev/null
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(SPINDLE_STAGING_ACTIVE_DIR),$(SPINDLE_STAGING_ACTIVE_REPETITIONS),$(SPINDLE_STAGING_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		jq -e '.status == "completed" and .prepare_status == 0 and .inner_status == 0 and .cleanup_status == 0 and .inventory_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		for status_file in guest-prepare.status guest-inner.status guest-cleanup.status \
			guest-inventory-after.status guest-dmesg.status; do \
			test "$$(cat "$$boot/$$status_file")" = 0; \
		done; \
		test "$$(cat "$$boot/runtime-mount-before.status")" -ne 0; \
		test "$$(cat "$$boot/runtime-mount-after.status")" -ne 0; \
		test "$$(find "$$boot" -maxdepth 1 -type f \
			-name 'source-spindle_output.*' | wc -l)" -ge 1; \
	done < <(find "$(SPINDLE_STAGING_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and (.completed_at | not) and .source.dirty == false and .kernel.dirty == false' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/run.json" >/dev/null
	test -s "$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl"
	test "$$(cat "$(SPINDLE_STAGING_ACTIVE_DIR)/source-commit.txt")" = \
		"$$(jq -r '.source.commit' "$(SPINDLE_STAGING_ACTIVE_DIR)/run.json")"
	test "$$(cat "$(SPINDLE_STAGING_ACTIVE_DIR)/kernel-commit.txt")" = \
		"$$(jq -r '.kernel.commit' "$(SPINDLE_STAGING_ACTIVE_DIR)/run.json")"

spindle-staging-analyze:
	test -n "$(SPINDLE_STAGING_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(SPINDLE_STAGING_ACTIVE_DIR))
	$(call NAMEI_EXT_ANALYSIS_PREPARE,$(SPINDLE_STAGING_ACTIVE_DIR)/analysis)
	install -d "$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp"
	jq -s \
		'{schema:"namei_ext.spindle_staging.summary.v1",boots:([.[] | select(.event == "spindle-staging-summary")] | length),source_passes:([.[] | select(.event == "spindle-staging-condition" and .condition == "source_spindle" and .pass == true)] | length),namei_ext_passes:([.[] | select(.event == "spindle-staging-condition" and .condition == "namei_ext" and .pass == true)] | length),withdrawn_passes:([.[] | select(.event == "spindle-staging-condition" and .condition == "withdrawn" and .pass == true)] | length),mappings:([.[] | select(.event == "spindle-staging-mapping" and .pass == true)] | length),selections:([.[] | select(.event == "spindle-staging-selection" and .pass == true)] | length),selection_hits:([.[] | select(.event == "spindle-staging-selection") | .hits_delta] | add // 0),identities:([.[] | select(.event == "spindle-staging-identity" and .pass == true)] | length),preserved:([.[] | select(.event == "spindle-staging-preservation" and .pass == true)] | length),permission_probes:([.[] | select(.event == "spindle-staging-permission" and .pass == true)] | length),withdrawal_controls:([.[] | select(.event == "spindle-staging-withdrawal" and .pass == true)] | length),verdict:"supported"}' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/observations.jsonl" \
		>"$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json"
	jq -e \
		'.schema == "namei_ext.spindle_staging.summary.v1" and .boots > 0 and .source_passes == .boots and .namei_ext_passes == .boots and .withdrawn_passes == .boots and .mappings == (47 * .boots) and .selections == (47 * .boots) and .selection_hits >= (47 * .boots) and .identities == (47 * .boots) and .preserved == (47 * .boots) and .permission_probes == .boots and .withdrawal_controls == .boots and .verdict == "supported"' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json" \
		>/dev/null
	jq -r \
		'["metric","value"],["boots",.boots],["source_passes",.source_passes],["namei_ext_passes",.namei_ext_passes],["withdrawn_passes",.withdrawn_passes],["mappings",.mappings],["selections",.selections],["selection_hits",.selection_hits],["identities",.identities],["preserved",.preserved],["permission_probes",.permission_probes],["withdrawal_controls",.withdrawal_controls] | @csv' \
		"$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json" \
		>"$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.csv"
	printf '%s\n' \
		'# Spindle HPC Staging Result' \
		'' \
		"Boots: $$(jq -r .boots "$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json")" \
		"Source/namei_ext/withdrawn: $$(jq -r '[.source_passes,.namei_ext_passes,.withdrawn_passes] | join(\"/\")' "$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json")" \
		"Focal mappings/selections/identities/preserved: $$(jq -r '[.mappings,.selections,.identities,.preserved] | join(\"/\")' "$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/summary.json")" \
		'' \
		'Verdict: supported for the frozen source-derived loader slice.' \
		>"$(SPINDLE_STAGING_ACTIVE_DIR)/analysis.tmp/report.md"
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$(SPINDLE_STAGING_ACTIVE_DIR)/analysis)

experiment-spindle-staging: kvm-spindle-staging

__spindle_staging_guest:
	install -d "$(SPINDLE_STAGING_BOOT_DIR)"
	prepare_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__namei_ext_guest_prepare || prepare_status=$$?; \
	printf '%s\n' "$$prepare_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/guest-prepare.status"; \
	inner_status=125; \
	if test "$$prepare_status" -eq 0; then \
		inner_status=0; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			-f Makefile -f "$(lastword $(MAKEFILE_LIST))" \
			__spindle_staging_guest_inner || inner_status=$$?; \
	fi; \
	printf '%s\n' "$$inner_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/guest-inner.status"; \
	if test -s "$(SPINDLE_STAGING_BOOT_DIR)/raw-runner.jsonl" && \
	   test ! -e "$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl"; then \
		cp "$(SPINDLE_STAGING_BOOT_DIR)/raw-runner.jsonl" \
			"$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl"; \
	fi; \
	cleanup_status=0; \
	for spec in hello_.py:600 hello_x.py:700; do \
		fixture="$${spec%%:*}"; mode="$${spec##*:}"; \
		path="$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)/build/testsuite/$$fixture"; \
		if test -e "$$path"; then \
			chmod "$$mode" "$$path" || cleanup_status=$$?; \
		else \
			cleanup_status=1; \
		fi; \
	done; \
	if test "$$cleanup_status" -eq 0; then \
		stat -c '%n	%a	%u	%g	%s	%d	%i' \
			"$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)/build/testsuite/hello_.py" \
			"$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)/build/testsuite/hello_x.py" \
			>"$(SPINDLE_STAGING_BOOT_DIR)/readlink-fixtures-restored.tsv" || \
			cleanup_status=$$?; \
	fi; \
	if mountpoint -q "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)"; then \
		umount -R "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)" || \
			cleanup_status=$$?; \
	fi; \
	mount_status=0; \
	mountpoint -q "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)" || \
		mount_status=$$?; \
	if test "$$mount_status" -eq 0; then cleanup_status=1; fi; \
	printf '%s\n' "$$mount_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/runtime-mount-after.status"; \
	printf '%s\n' "$$cleanup_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/guest-cleanup.status"; \
	inventory_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		-f Makefile -f "$(lastword $(MAKEFILE_LIST))" \
		__spindle_staging_guest_inventory_after || inventory_status=$$?; \
	printf '%s\n' "$$inventory_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(SPINDLE_STAGING_BOOT_DIR)/dmesg.log" || dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(SPINDLE_STAGING_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/guest-dmesg.status"; \
	boot_status=completed; \
	if test "$$prepare_status" -ne 0 || test "$$inner_status" -ne 0 || \
	   test "$$cleanup_status" -ne 0 || \
	   test "$$inventory_status" -ne 0 || test "$$dmesg_status" -ne 0; then \
		boot_status=failed; \
	fi; \
	jq -n \
		--argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(SPINDLE_STAGING_GUEST_KERNEL_COMMIT)" \
		--arg kernel_release "$(SPINDLE_STAGING_GUEST_KERNEL_RELEASE)" \
		--arg status "$$boot_status" \
		--argjson prepare_status "$$prepare_status" \
		--argjson inner_status "$$inner_status" \
		--argjson cleanup_status "$$cleanup_status" \
		--argjson inventory_status "$$inventory_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.spindle_staging.boot.v1",repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_release:$$kernel_release,status:$$status,prepare_status:$$prepare_status,inner_status:$$inner_status,cleanup_status:$$cleanup_status,inventory_status:$$inventory_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(SPINDLE_STAGING_BOOT_DIR)/boot.json"; \
	test "$$boot_status" = completed

__spindle_staging_guest_inventory_after:
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,\
		$(SPINDLE_STAGING_BOOT_DIR),\
		$(SPINDLE_STAGING_GUEST_BPFTOOL),after)
	jq -e 'type == "array" and length == 0' \
		"$(SPINDLE_STAGING_BOOT_DIR)/bpf-programs-after.json" \
		>/dev/null
	jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
		"$(SPINDLE_STAGING_BOOT_DIR)/bpf-cgroup-after.json" \
		>/dev/null
	test ! -s "$(SPINDLE_STAGING_BOOT_DIR)/fuse-mounts-after.txt"
	test "$$(cat "$(SPINDLE_STAGING_BOOT_DIR)/fuse-open-fds-after.status")" = 1
	test ! -s "$(SPINDLE_STAGING_BOOT_DIR)/fuse-open-fds-after.txt"

__spindle_staging_guest_inner:
	test -n "$(REPETITION)"
	test -x "$(SPINDLE_STAGING_GUEST_RUNNER)"
	test -r "$(SPINDLE_STAGING_GUEST_POLICY)"
	test -x "$(SPINDLE_STAGING_GUEST_BPFTOOL)"
	test -d "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)"
	test -d "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)"
	command -v file >/dev/null
	command -v readelf >/dev/null
	command -v strings >/dev/null
	(cd "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)" && \
		find build prefix -type l -printf '%p\t%l\n' | \
		LC_ALL=C sort) | cmp - \
			"$(SPINDLE_STAGING_BOOT_DIR)/runtime-symlinks.txt"
	runtime_mount_status=0; \
	mountpoint -q "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)" || \
		runtime_mount_status=$$?; \
	printf '%s\n' "$$runtime_mount_status" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/runtime-mount-before.status"; \
	test "$$runtime_mount_status" -ne 0
	mount --bind "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)" \
		"$(SPINDLE_STAGING_GUEST_COMPILED_ABS)"
	mountpoint -q "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)"
	test "$$(stat -c '%d:%i' "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)")" = \
		"$$(stat -c '%d:%i' "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)")"
	findmnt -rn --mountpoint "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)" \
		-o SOURCE,TARGET,FSTYPE,OPTIONS \
		>"$(SPINDLE_STAGING_BOOT_DIR)/runtime-mount-active.txt"
	test -s "$(SPINDLE_STAGING_BOOT_DIR)/runtime-mount-active.txt"
	test -x "$(SPINDLE_STAGING_GUEST_SPINDLE_ABS)"
	test -x "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver"
	for fixture in retzero_ retzero_x; do \
		test ! -e "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/$$fixture"; \
	done
	test "$$(stat -c %a "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_.py")" = 600
	test "$$(stat -c %a "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_x.py")" = 700
	for fixture in hello_.py hello_x.py; do \
		cmp "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/$$fixture" \
			"$(SPINDLE_STAGING_GUEST_HELLO_SOURCE_ABS)"; \
	done
	install -d "$(SPINDLE_STAGING_BOOT_DIR)"
	: >"$(SPINDLE_STAGING_BOOT_DIR)/raw-runner.jsonl"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,\
		$(SPINDLE_STAGING_BOOT_DIR),\
		$(SPINDLE_STAGING_GUEST_KERNEL_CONFIG),\
		$(SPINDLE_STAGING_GUEST_KERNEL_COMMIT),\
		$(SPINDLE_STAGING_GUEST_KERNEL_RELEASE))
	grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms
	runtime_uid=$$(stat -c %u "$(SPINDLE_STAGING_BOOT_DIR)"); \
	runtime_gid=$$(stat -c %g "$(SPINDLE_STAGING_BOOT_DIR)"); \
	test "$$runtime_uid" -ne 0; \
	jq -n --argjson uid "$$runtime_uid" --argjson gid "$$runtime_gid" \
		'{uid:$$uid,gid:$$gid}' \
		>"$(SPINDLE_STAGING_BOOT_DIR)/runtime-identity.json"
	LD_LIBRARY_PATH="$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)" \
		ldd "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-ldd.txt"
	! grep -F 'not found' \
		"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-ldd.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/build/testsuite/libtestoutput.so" \
		"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-ldd.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/build/testsuite/libfuncdict.so" \
		"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-ldd.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/build/src/client/spindle_api/.libs/libspindle.so.0" \
		"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-ldd.txt"
	ldd "$(SPINDLE_STAGING_GUEST_SPINDLE_ABS)" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/spindle-ldd.txt"
	! grep -F 'not found' "$(SPINDLE_STAGING_BOOT_DIR)/spindle-ldd.txt"
	file "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-file.txt"
	readelf -lW "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-readelf-program.txt"
	readelf -dW "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-readelf-dynamic.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/build/src/client/spindle_api/.libs" \
		"$(SPINDLE_STAGING_BOOT_DIR)/test-driver-readelf-dynamic.txt"
	strings "$(SPINDLE_STAGING_GUEST_SPINDLE_ABS)" | \
		grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/" | \
		LC_ALL=C sort -u \
		>"$(SPINDLE_STAGING_BOOT_DIR)/spindle-compiled-paths.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/prefix/libexec/spindle/spindle_be" \
		"$(SPINDLE_STAGING_BOOT_DIR)/spindle-compiled-paths.txt"
	grep -F "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/prefix/libexec/spindle/spindle_bootstrap" \
		"$(SPINDLE_STAGING_BOOT_DIR)/spindle-compiled-paths.txt"
	test -x "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/prefix/libexec/spindle/spindle_be"
	test -x "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)/prefix/libexec/spindle/spindle_bootstrap"
	jq -n \
		--arg runner "$$(readlink -f "$(SPINDLE_STAGING_GUEST_RUNNER)")" \
		--arg policy "$$(readlink -f "$(SPINDLE_STAGING_GUEST_POLICY)")" \
		--arg bpftool "$$(readlink -f "$(SPINDLE_STAGING_GUEST_BPFTOOL)")" \
		--arg spindle "$$(readlink -f "$(SPINDLE_STAGING_GUEST_SPINDLE_ABS)")" \
		--arg test_driver "$$(readlink -f "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/test_driver")" \
		--arg runtime_root "$$(readlink -f "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)")" \
		--arg compiled_root "$$(readlink -f "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)")" \
		--arg runtime_root_identity "$$(stat -c '%d:%i' "$(SPINDLE_STAGING_GUEST_RUNTIME_ROOT)")" \
		--arg compiled_root_identity "$$(stat -c '%d:%i' "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)")" \
		'{runner:{path:$$runner},policy:{path:$$policy},bpftool:{path:$$bpftool},spindle:{path:$$spindle},test_driver:{path:$$test_driver},runtime:{source:$$runtime_root,compiled_mount:$$compiled_root,source_identity:$$runtime_root_identity,mount_identity:$$compiled_root_identity}}' \
		>"$(SPINDLE_STAGING_BOOT_DIR)/runtime-metadata.json"
	jq -e '.runtime.source_identity == .runtime.mount_identity' \
		"$(SPINDLE_STAGING_BOOT_DIR)/runtime-metadata.json" >/dev/null
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,\
		$(SPINDLE_STAGING_BOOT_DIR),\
		$(SPINDLE_STAGING_GUEST_BPFTOOL),before)
	jq -e 'type == "array" and length == 0' \
		"$(SPINDLE_STAGING_BOOT_DIR)/bpf-programs-before.json" \
		>/dev/null
	jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
		"$(SPINDLE_STAGING_BOOT_DIR)/bpf-cgroup-before.json" \
		>/dev/null
	test ! -s "$(SPINDLE_STAGING_BOOT_DIR)/fuse-mounts-before.txt"
	test "$$(cat "$(SPINDLE_STAGING_BOOT_DIR)/fuse-open-fds-before.status")" = 1
	test ! -s "$(SPINDLE_STAGING_BOOT_DIR)/fuse-open-fds-before.txt"
	chmod 0200 "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_.py"
	chmod 0300 "$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_x.py"
	stat -c '%n	%a	%u	%g	%s	%d	%i' \
		"$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_.py" \
		"$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_x.py" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/readlink-fixtures-active.tsv"
	"$(SPINDLE_STAGING_GUEST_RUNNER)" \
		"$(SPINDLE_STAGING_GUEST_POLICY)" \
		"$(SPINDLE_STAGING_BOOT_DIR)/raw-runner.jsonl" \
		"$(SPINDLE_STAGING_GUEST_SPINDLE_ABS)" \
		"$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)" \
		"$(SPINDLE_STAGING_BOOT_DIR)" /sys/fs/cgroup
	stat -c '%n	%a	%u	%g	%s	%d	%i' \
		"$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_.py" \
		"$(SPINDLE_STAGING_GUEST_TEST_DIR_ABS)/hello_x.py" \
		>"$(SPINDLE_STAGING_BOOT_DIR)/readlink-fixtures-after.tsv"
	cmp "$(SPINDLE_STAGING_BOOT_DIR)/readlink-fixtures-active.tsv" \
		"$(SPINDLE_STAGING_BOOT_DIR)/readlink-fixtures-after.tsv"
	cp "$(SPINDLE_STAGING_BOOT_DIR)/raw-runner.jsonl" \
		"$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl"
	jq -e 'select(.event == "spindle-staging-summary" and .focal_objects == 47 and .failures == 0 and .pass == true)' \
		"$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl" >/dev/null
	! jq -e 'select(.pass != true)' \
		"$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl" >/dev/null
	for event in mapping selection identity preservation; do \
		test "$$(jq -s --arg event "spindle-staging-$$event" \
			'[.[] | select(.event == $$event)] | length' \
			"$(SPINDLE_STAGING_BOOT_DIR)/observations.jsonl")" = 47; \
	done
	test "$$(find "$(SPINDLE_STAGING_BOOT_DIR)" -maxdepth 1 -type f \
		-name 'source-spindle_output.*' | wc -l)" -ge 1
	test ! -e /tmp/namei-ext-spindle-cache
	test ! -e /tmp/namei-ext-spindle-comm
	test ! -e /tmp/namei-ext-spindle-tmp
	test "$$(find /sys/fs/cgroup -maxdepth 1 -type d \
		-name 'namei-ext-spindle-*' | wc -l)" = 0
	(cd "$(SPINDLE_STAGING_GUEST_COMPILED_ABS)" && \
		find build prefix -type l -printf '%p\t%l\n' | \
		LC_ALL=C sort) | cmp - \
			"$(SPINDLE_STAGING_BOOT_DIR)/runtime-symlinks.txt"
