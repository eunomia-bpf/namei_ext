FXMARK_FAST_PATH_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-fast-path/$(RUN_ID)
FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-fast-path-preflight/$(RUN_ID)
FXMARK_FAST_PATH_ANALYSIS ?= $(ROOT_DIR)/analysis/fxmark_fast_path/analyze.py

define FXMARK_FAST_PATH_ASSERT_SHARED_PROTOCOL
test "$(KVM_CPUS)" = 4
test "$(KVM_MEM)" = 8G
test "$(FXMARK_TMPFS_SIZE)" = 1G
test "$(FXMARK_CELL_TIMEOUT)" = 900
test "$(FXMARK_BPF_STATS)" = 0
test "$(FXMARK_FAST_PATH_HOST_CPUS)" = 4-7
test "$(FXMARK_FAST_PATH_ANALYSIS_SEED)" = 20260728
test "$(FXMARK_COMMIT)" = 3f29552ce7ba6be24c4172e6e2c2c1f603209953
test "$(FXMARK_ARCHIVE_URL)" = \
	https://codeload.github.com/sslab-gatech/fxmark/tar.gz/3f29552ce7ba6be24c4172e6e2c2c1f603209953
test "$(FXMARK_ARCHIVE_SHA256)" = \
	b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae
test "$(FXMARK_BPFTOOL)" = /usr/local/sbin/bpftool
test "$$(sha256sum "$(FXMARK_BPFTOOL)" | awk '{print $$1}')" = \
	8d90219edf52eacd3416ded92f2137f7ab87eeef2379b5d4b24e5395a79c9587
test "$(KVM_APPEND)" = \
	"loglevel=7 panic=30 oops=panic tsc=reliable clocksource=tsc"
test "$(VNG_MODULE_FLAGS)" = --skip-modules
test "$(FXMARK_FAST_PATH_EXPECTED_PATCHED_COMMIT)" = bdc9a83e3dfbef8ff2017f9188c7c86025962183
test "$(FXMARK_FAST_PATH_EXPECTED_STOCK_COMMIT)" = 062871f1371b2e02a272ff5279c6479aff0a37ef
endef

define FXMARK_FAST_PATH_ASSERT_PREFLIGHT_PROTOCOL
$(call FXMARK_FAST_PATH_ASSERT_SHARED_PROTOCOL)
test "$(FXMARK_FAST_PATH_PREFLIGHT_REPETITIONS)" = 1
test "$(FXMARK_FAST_PATH_PREFLIGHT_DURATION)" = 2
endef

define FXMARK_FAST_PATH_ASSERT_FORMAL_PROTOCOL
$(call FXMARK_FAST_PATH_ASSERT_SHARED_PROTOCOL)
test "$(FXMARK_FAST_PATH_REPETITIONS)" = 30
test "$(FXMARK_FAST_PATH_DURATION)" = 30
endef

define FXMARK_FAST_PATH_START
$(call NAMEI_EXT_VALIDATE_HOST_CPU_PIN,$(FXMARK_FAST_PATH_HOST_CPUS),$(KVM_CPUS))
test "$$(cat "$(KERNEL_COMMIT_FILE)")" = \
	"$(FXMARK_FAST_PATH_EXPECTED_PATCHED_COMMIT)"
test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = \
	"$(FXMARK_FAST_PATH_EXPECTED_STOCK_COMMIT)"
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),fxmark-fast-path,fxmark-atc2016,kvm_fxmark_fast_path,$(1)/observations.jsonl,none,fxmark_cell)
$(call FXMARK_CAPTURE_RUN_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--argjson repetitions "$(2)" \
	--argjson duration_seconds "$(3)" \
	--argjson kvm_cpus "$(KVM_CPUS)" \
	--arg host_cpu_pin "$(FXMARK_FAST_PATH_HOST_CPUS)" \
	--arg fxmark_commit "$(FXMARK_COMMIT)" \
	--arg fxmark_archive_url "$(FXMARK_ARCHIVE_URL)" \
	--arg fxmark_archive_sha256 "$(FXMARK_ARCHIVE_SHA256)" \
	--arg kvm_append "$(KVM_APPEND)" \
	--arg vng_module_flags "$(VNG_MODULE_FLAGS)" \
	'.layout = "paired-boot-matrix" | .kernel_artifacts = $$artifacts[0] | .kernel_commits = {patched:$$artifacts[0].patched.commit,stock:$$artifacts[0].stock.commit} | .benchmark_source = {commit:$$fxmark_commit,archive_url:$$fxmark_archive_url,archive_sha256:$$fxmark_archive_sha256} | .guest_launch = {kvm_append:$$kvm_append,vng_module_flags:$$vng_module_flags} | .matrix = {conditions:["stock","unattached"],types:["MRPL"],workers:[1,2,4],repetitions:$$repetitions,duration_seconds:$$duration_seconds,bpf_stats:0,order:"alternating",kvm_cpus:$$kvm_cpus,host_cpu_pin:$$host_cpu_pin,affinity:"exact-vcpu-index-mapping",external_inventory_gate:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" -e \
	--arg patched "$(FXMARK_FAST_PATH_EXPECTED_PATCHED_COMMIT)" \
	--arg stock "$(FXMARK_FAST_PATH_EXPECTED_STOCK_COMMIT)" \
	'.layout == "paired-boot-matrix" and .kernel_artifacts == $$artifacts[0] and .kernel.commit == $$patched and .kernel_artifacts.patched.commit == $$patched and .kernel_commit == $$patched and .kernel_commits.patched == $$patched and .kernel_artifacts.stock.commit == $$stock and .kernel_commits.stock == $$stock' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(4)" >"$(1)/command.txt"
$(call NAMEI_EXT_MULTI_BOOT_CAPTURE_PINNED_HOST,$(1),$(FXMARK_FAST_PATH_HOST_CPUS))
: >"$(1)/launch-order.jsonl"
sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
	"$(ROOT_DIR)/configs/benchmarks/fxmark_fast_path.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(ROOT_DIR)/Makefile" \
	"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
	"$(ROOT_DIR)/mk/experiments/fxmark_fast_path.mk" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/multi_boot.mk" \
	"$(ROOT_DIR)/mk/kvm.mk" \
	"$(ROOT_DIR)/mk/kernel.mk" \
	"$(ROOT_DIR)/tools/kvm/verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
	"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
	"$(FXMARK_FAST_PATH_ANALYSIS)" \
	"$(ROOT_DIR)/analysis/fxmark_fast_path/test_analyze.py" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-fast-path-confirmatory-plan.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-fast-path-plan-review.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-fxmark-fast-path-confirmatory-implementation.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-fxmark-fast-path-preflight-v1-failure.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-fxmark-fast-path-preflight-v2.md" \
	>"$(1)/inputs.sha256"
: >"$(1)/expected-boots.txt"
: >"$(1)/expected-cells.txt"
endef

define FXMARK_FAST_PATH_RUN_MATRIX
manifest="$(1)/artifacts/manifest.json"; \
fxmark_binary="$(1)/$$(jq -r '.runtime.fxmark' "$$manifest")"; \
fxmark_cell="$(1)/$$(jq -r '.runtime.cell' "$$manifest")"; \
fxmark_fuse="$(1)/$$(jq -r '.runtime.fuse' "$$manifest")"; \
bpftool_binary="$(1)/$$(jq -r '.runtime.bpftool' "$$manifest")"; \
pass_policy="$(1)/$$(jq -r '.runtime.pass_policy' "$$manifest")"; \
select_policy="$(1)/$$(jq -r '.runtime.select_policy' "$$manifest")"; \
order_index=0; \
for repetition in $$(seq 1 "$(2)"); do \
	if test "$$((repetition % 2))" = 1; then \
		conditions=(stock unattached); \
	else \
		conditions=(unattached stock); \
	fi; \
	for condition in "$${conditions[@]}"; do \
		order_index=$$((order_index + 1)); \
		case "$$condition" in \
		stock) flavor=stock ;; \
		unattached) flavor=patched ;; \
		*) exit 1 ;; \
		esac; \
		image="$(1)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].image' "$$manifest")"; \
		config="$(1)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].config' "$$manifest")"; \
		commit=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].commit' "$$manifest"); \
		build_id=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].build_id' "$$manifest"); \
		notes_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].notes_sha256' "$$manifest"); \
		btf_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].btf_sha256' "$$manifest"); \
		release=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].release' "$$manifest"); \
		printf '%s|%s|%s|%s|%s|%s|%s\n' "$$repetition" "$$condition" "$$commit" "$$build_id" "$$notes_sha" "$$btf_sha" "$$release" >>"$(1)/expected-boots.txt"; \
		for workers in 1 2 4; do \
			printf '%s|%s|MRPL|%s\n' "$$repetition" "$$condition" "$$workers" >>"$(1)/expected-cells.txt"; \
		done; \
		boot_dir="$(1)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
		install -d "$$boot_dir"; \
		guest_makefile="$$boot_dir/guest.mk"; \
		$(call FXMARK_WRITE_GUEST_MAKEFILE,$(3),MRPL,1 2 4,1); \
		guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
		host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		test -n "$$host_started_at"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$$image" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="-f Makefile -f $$guest_makefile_rel __fxmark_rq2_guest" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot_dir" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(1)" \
			NAMEI_EXT_KVM_CAPTURE_HOST_CPUS="$(FXMARK_FAST_PATH_HOST_CPUS)"; \
		host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		test -n "$$host_completed_at"; \
		jq -cn \
			--arg schema "namei_ext.fxmark_fast_path.launch_order.v1" \
			--argjson order_index "$$order_index" \
			--argjson repetition "$$repetition" \
			--arg condition "$$condition" \
			--arg started_at "$$host_started_at" \
			--arg completed_at "$$host_completed_at" \
			--arg boot_dir "$${boot_dir#$(1)/}" \
			'{schema:$$schema,order_index:$$order_index,repetition:$$repetition,condition:$$condition,host_started_at:$$started_at,host_completed_at:$$completed_at,boot_dir:$$boot_dir}' \
			>>"$(1)/launch-order.jsonl"; \
		jq --argjson order_index "$$order_index" \
			--arg started_at "$$host_started_at" \
			--arg completed_at "$$host_completed_at" \
			'.host_launch = {order_index:$$order_index,started_at:$$started_at,completed_at:$$completed_at}' \
			"$$boot_dir/boot.json" >"$$boot_dir/boot.json.tmp"; \
		mv -f "$$boot_dir/boot.json.tmp" "$$boot_dir/boot.json"; \
	done; \
done
$(call NAMEI_EXT_MULTI_BOOT_CAPTURE_PINNED_HOST_AFTER,$(1))
endef

define FXMARK_FAST_PATH_FINALIZE
jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' \
	"$(1)/run.json" >/dev/null
LC_ALL=C sort -o "$(1)/expected-boots.txt" "$(1)/expected-boots.txt"
LC_ALL=C sort -o "$(1)/expected-cells.txt" "$(1)/expected-cells.txt"
find "$(1)/boots" -name observations.jsonl -print0 | sort -z | \
	xargs -0 cat >"$(1)/observations.jsonl"
jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' \
	"$(1)/observations.jsonl" | LC_ALL=C sort >"$(1)/observed-cells.txt"
find "$(1)/boots" -name boot.json -print0 | sort -z | \
	xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)|\(.kernel_release)"' | \
	LC_ALL=C sort >"$(1)/observed-boots.txt"
cmp "$(1)/expected-cells.txt" "$(1)/observed-cells.txt"
cmp "$(1)/expected-boots.txt" "$(1)/observed-boots.txt"
sha256sum -c "$(1)/inputs.sha256"
sha256sum -c "$(1)/artifacts.sha256"
test "$$(jq -s 'length' "$(1)/observations.jsonl")" = "$$((6 * $(2)))"
test "$$(jq -s '[.[] | select(.pass == true)] | length' \
	"$(1)/observations.jsonl")" = "$$((6 * $(2)))"
test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' \
	"$(1)/observations.jsonl")" = "$$((6 * $(2)))"
test "$$(find "$(1)/boots" -name boot.json -type f | wc -l)" = "$$((2 * $(2)))"
jq -s -e --argjson repetitions "$(2)" \
	'length == (2 * $$repetitions) and ([.[].order_index] == [range(1; (2 * $$repetitions) + 1)]) and ([.[] | [.repetition,.condition]] == [range(1; $$repetitions + 1) as $$rep | (if ($$rep % 2) == 1 then ["stock","unattached"] else ["unattached","stock"] end)[] as $$condition | [$$rep,$$condition]]) and all(.[]; .schema == "namei_ext.fxmark_fast_path.launch_order.v1" and (.host_started_at | type == "string" and length > 0) and (.host_completed_at | type == "string" and length > 0))' \
	"$(1)/launch-order.jsonl" >/dev/null
for boot in "$(1)"/boots/*; do \
	for file in guest.mk guest.mk.sha256 launcher.stdout.log \
		launcher.stderr.log vcpu-affinity.json affinity-verified-at.txt \
		affinity-barrier.txt bpf-programs-before.json \
		bpf-programs-after.json bpf-cgroup-before.json \
		bpf-cgroup-after.json fuse-mounts-before.txt \
		fuse-mounts-after.txt fuse-open-fds-before.txt \
		fuse-open-fds-after.txt \
		boot.json observations.jsonl kernel.config kernel-commit.txt \
		kernel-build-id.txt kernel-notes.sha256 kernel-btf.sha256 \
		kernel-flavor.txt kernel-release.txt clocksource-before.txt \
		clocksource-after.txt uname.txt proc-version.txt kernel-cmdline.txt \
		proc-stat-before.txt proc-stat-after.txt dmesg.log; do \
		test -e "$$boot/$$file"; \
	done; \
	(cd "$$boot" && sha256sum -c guest.mk.sha256); \
	jq -e '.schema == "namei_ext.fxmark.boot.v2" and .status == "completed" and .clocksource == "tsc" and (.completed_at | type == "string" and length > 0) and (.affinity_verified_at | type == "string" and length > 0) and (.guest_barrier_at | type == "string" and length > 0) and .host_launch.order_index > 0 and (.host_launch.started_at | type == "string" and length > 0) and (.host_launch.completed_at | type == "string" and length > 0)' \
		"$$boot/boot.json" >/dev/null; \
	test "$$(cat "$$boot/affinity-verified-at.txt")" = \
		"$$(jq -r '.affinity_verified_at' "$$boot/boot.json")"; \
	test "$$(cat "$$boot/affinity-verified-at.txt")" = \
		"$$(jq -r '.verified_at' "$$boot/vcpu-affinity.json")"; \
	test "$$(cat "$$boot/affinity-barrier.txt")" = \
		"$$(jq -r '.guest_barrier_at' "$$boot/boot.json")"; \
	jq -e 'type == "array" and length == 0' \
		"$$boot/bpf-programs-before.json" >/dev/null; \
	jq -e 'type == "array" and length == 0' \
		"$$boot/bpf-programs-after.json" >/dev/null; \
	jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
		"$$boot/bpf-cgroup-before.json" >/dev/null; \
	jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
		"$$boot/bpf-cgroup-after.json" >/dev/null; \
	cmp "$$boot/bpf-programs-before.json" \
		"$$boot/bpf-programs-after.json"; \
	cmp "$$boot/bpf-cgroup-before.json" \
		"$$boot/bpf-cgroup-after.json"; \
	for file in fuse-mounts-before.txt fuse-mounts-after.txt \
			fuse-open-fds-before.txt fuse-open-fds-after.txt; do \
		test ! -s "$$boot/$$file"; \
	done; \
	cmp "$$boot/fuse-mounts-before.txt" \
		"$$boot/fuse-mounts-after.txt"; \
	cmp "$$boot/fuse-open-fds-before.txt" \
		"$$boot/fuse-open-fds-after.txt"; \
	jq -e --slurpfile expected "$(1)/host-cpu-pin.json" \
		--argjson kvm_cpus "$(KVM_CPUS)" \
		'.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified" and .expected_host_cpus == $$expected[0] and (.expected_host_cpus | length) == $$kvm_cpus and .expected_vcpu_mapping == [range(0; ($$expected[0] | length)) as $$index | {vcpu_index:$$index,host_cpu:$$expected[0][$$index]}] and [.vcpus[] | [.vcpu_index,.cpus_allowed]] == [range(0; ($$expected[0] | length)) as $$index | [$$index,[$$expected[0][$$index]]]]' \
		"$$boot/vcpu-affinity.json" >/dev/null; \
	jq -e --slurpfile launches "$(1)/launch-order.jsonl" \
		'. as $$boot | [$$launches[] | select(.repetition == $$boot.repetition and .condition == $$boot.condition)] as $$matched | ($$matched | length) == 1 and .host_launch == {order_index:$$matched[0].order_index,started_at:$$matched[0].host_started_at,completed_at:$$matched[0].host_completed_at}' \
		"$$boot/boot.json" >/dev/null; \
	host_started_ns=$$(date -u -d "$$(jq -r '.host_launch.started_at' "$$boot/boot.json")" +%s%N); \
	affinity_verified_ns=$$(date -u -d "$$(jq -r '.affinity_verified_at' "$$boot/boot.json")" +%s%N); \
	guest_barrier_ns=$$(date -u -d "$$(jq -r '.guest_barrier_at' "$$boot/boot.json")" +%s%N); \
	guest_completed_ns=$$(date -u -d "$$(jq -r '.completed_at' "$$boot/boot.json")" +%s%N); \
	host_completed_ns=$$(date -u -d "$$(jq -r '.host_launch.completed_at' "$$boot/boot.json")" +%s%N); \
	test "$$host_started_ns" -le "$$affinity_verified_ns"; \
	test "$$affinity_verified_ns" -le "$$guest_barrier_ns"; \
	test "$$guest_barrier_ns" -le "$$guest_completed_ns"; \
	test "$$guest_completed_ns" -le "$$host_completed_ns"; \
	! grep -E 'WARNING: Failed to pin vCPUs|Permission denied: cannot set affinity|not enough host CPUs|QMP .*failed|No vCPU threads found|TID .* does not exist' \
		"$$boot/launcher.stderr.log" >/dev/null; \
done
find "$(1)/boots" -name boot.json -print0 | sort -z | \
	xargs -0 jq -s -e 'group_by(.kernel_flavor) | length == 2 and all(.[]; ([.[] | [.kernel_commit,.kernel_build_id,.kernel_notes_sha256,.kernel_btf_sha256,.kernel_release]] | unique | length) == 1)' >/dev/null
for file in host-lscpu.txt host-lscpu-extended.txt host-cpu-pin.txt \
		host-cpu-pin.json host-cpu-frequency-policy.txt vng-version.txt \
		vng-executable.sha256 vng-run-module.sha256 \
		host-proc-stat-before.txt host-proc-stat-after.txt \
		host-proc-interrupts-before.txt host-proc-interrupts-after.txt \
		launch-order.jsonl; do \
	test -s "$(1)/$$file"; \
done
$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(1),$(1)/observations.jsonl)
jq --slurpfile manifest "$(1)/artifacts/manifest.json" -e \
	--argjson repetitions "$(2)" \
	--argjson duration_seconds "$(3)" \
	--arg patched "$(FXMARK_FAST_PATH_EXPECTED_PATCHED_COMMIT)" \
	--arg stock "$(FXMARK_FAST_PATH_EXPECTED_STOCK_COMMIT)" \
	--arg fxmark_commit "3f29552ce7ba6be24c4172e6e2c2c1f603209953" \
	--arg fxmark_archive_url "https://codeload.github.com/sslab-gatech/fxmark/tar.gz/3f29552ce7ba6be24c4172e6e2c2c1f603209953" \
	--arg fxmark_archive_sha256 "b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae" \
	--arg kvm_append "loglevel=7 panic=30 oops=panic tsc=reliable clocksource=tsc" \
	--arg vng_module_flags "--skip-modules" \
	'.layout == "paired-boot-matrix" and .benchmark_source == {commit:$$fxmark_commit,archive_url:$$fxmark_archive_url,archive_sha256:$$fxmark_archive_sha256} and .guest_launch == {kvm_append:$$kvm_append,vng_module_flags:$$vng_module_flags} and .matrix.conditions == ["stock","unattached"] and .matrix.types == ["MRPL"] and .matrix.workers == [1,2,4] and .matrix.repetitions == $$repetitions and .matrix.duration_seconds == $$duration_seconds and .matrix.bpf_stats == 0 and .matrix.order == "alternating" and .matrix.affinity == "exact-vcpu-index-mapping" and .matrix.external_inventory_gate == true and .kernel_artifacts == $$manifest[0] and .kernel_artifacts.patched.commit == $$patched and .kernel_commits.patched == $$patched and .kernel_artifacts.stock.commit == $$stock and .kernel_commits.stock == $$stock' \
	"$(1)/run.json" >/dev/null
endef

.PHONY: fxmark-fast-path-analysis-test \
	kvm-fxmark-fast-path-preflight kvm-fxmark-fast-path \
	fxmark-fast-path-analyze fxmark-fast-path-report \
	experiment-fxmark-fast-path

fxmark-fast-path-analysis-test:
	python3 "$(ROOT_DIR)/analysis/fxmark_fast_path/test_analyze.py"
	python3 "$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py"

kvm-fxmark-fast-path-preflight: fxmark-kernel-pair fxmark-rq2-build bpf \
		fxmark-fast-path-analysis-test
	$(call FXMARK_FAST_PATH_ASSERT_PREFLIGHT_PROTOCOL)
	$(call FXMARK_FAST_PATH_START,$(FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR),$(FXMARK_FAST_PATH_PREFLIGHT_REPETITIONS),$(FXMARK_FAST_PATH_PREFLIGHT_DURATION),make kvm-fxmark-fast-path-preflight RUN_ID=$(RUN_ID))
	$(call FXMARK_FAST_PATH_RUN_MATRIX,$(FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR),$(FXMARK_FAST_PATH_PREFLIGHT_REPETITIONS),$(FXMARK_FAST_PATH_PREFLIGHT_DURATION))
	$(call FXMARK_FAST_PATH_FINALIZE,$(FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR),$(FXMARK_FAST_PATH_PREFLIGHT_REPETITIONS),$(FXMARK_FAST_PATH_PREFLIGHT_DURATION))
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" fxmark-fast-path-analyze \
		RUN_ID="$(RUN_ID)" \
		FXMARK_FAST_PATH_ACTIVE_DIR="$(FXMARK_FAST_PATH_PREFLIGHT_RESULT_DIR)"

kvm-fxmark-fast-path: fxmark-kernel-pair fxmark-rq2-build bpf \
		fxmark-fast-path-analysis-test
	$(call FXMARK_FAST_PATH_ASSERT_FORMAL_PROTOCOL)
	$(call FXMARK_FAST_PATH_START,$(FXMARK_FAST_PATH_RESULT_DIR),$(FXMARK_FAST_PATH_REPETITIONS),$(FXMARK_FAST_PATH_DURATION),make experiment-fxmark-fast-path RUN_ID=$(RUN_ID))
	$(call FXMARK_FAST_PATH_RUN_MATRIX,$(FXMARK_FAST_PATH_RESULT_DIR),$(FXMARK_FAST_PATH_REPETITIONS),$(FXMARK_FAST_PATH_DURATION))
	$(call FXMARK_FAST_PATH_FINALIZE,$(FXMARK_FAST_PATH_RESULT_DIR),$(FXMARK_FAST_PATH_REPETITIONS),$(FXMARK_FAST_PATH_DURATION))
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_FAST_PATH_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" fxmark-fast-path-analyze \
		RUN_ID="$(RUN_ID)" \
		FXMARK_FAST_PATH_ACTIVE_DIR="$(FXMARK_FAST_PATH_RESULT_DIR)"

fxmark-fast-path-analyze:
	result="$(FXMARK_FAST_PATH_ACTIVE_DIR)"; \
	test -n "$$result"; \
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$$result); \
	sha256sum -c "$$result/inputs.sha256"; \
	sha256sum -c "$$result/artifacts.sha256"; \
	analysis="$$result/analysis"; \
	$(call NAMEI_EXT_ANALYSIS_PREPARE,$$analysis); \
	python3 "$(FXMARK_FAST_PATH_ANALYSIS)" \
		--input "$$result/observations.jsonl" \
		--launch-order "$$result/launch-order.jsonl" \
		--run "$$result/run.json" \
		--output "$$analysis.tmp" \
		--seed "$(FXMARK_FAST_PATH_ANALYSIS_SEED)"; \
	for file in summary.json summary.csv report.md fast-path.png \
			fast-path.pdf; do \
		test -s "$$analysis.tmp/$$file"; \
	done; \
	jq -e '.schema == "namei_ext.fxmark-fast-path.analysis.v1" and (.verdict == "supported" or .verdict == "contradicted" or .verdict == "inconclusive")' \
		"$$analysis.tmp/summary.json" >/dev/null; \
	(cd "$$analysis.tmp" && \
		sha256sum summary.json summary.csv report.md fast-path.png \
			fast-path.pdf >analysis.sha256.tmp && \
		mv -f analysis.sha256.tmp analysis.sha256 && \
		sha256sum -c analysis.sha256); \
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$$analysis)

fxmark-fast-path-report:
	jq -e '.status == "completed" and (.completed_at | type == "string" and length > 0)' \
		"$(FXMARK_FAST_PATH_RESULT_DIR)/run.json" >/dev/null
	sha256sum -c "$(FXMARK_FAST_PATH_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(FXMARK_FAST_PATH_RESULT_DIR)/artifacts.sha256"
	(cd "$(FXMARK_FAST_PATH_RESULT_DIR)/analysis" && \
		sha256sum -c analysis.sha256)
	jq -e '.schema == "namei_ext.fxmark-fast-path.analysis.v1" and (.verdict == "supported" or .verdict == "contradicted" or .verdict == "inconclusive")' \
		"$(FXMARK_FAST_PATH_RESULT_DIR)/analysis/summary.json" >/dev/null

experiment-fxmark-fast-path: kvm-fxmark-fast-path
	$(MAKE) -C "$(ROOT_DIR)" fxmark-fast-path-report RUN_ID="$(RUN_ID)"
