FXMARK_READDIR_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-readdir/$(RUN_ID)
FXMARK_READDIR_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-readdir-preflight/$(RUN_ID)
FXMARK_READDIR_ANALYSIS ?= $(ROOT_DIR)/analysis/fxmark_readdir/analyze.py

define FXMARK_READDIR_ASSERT_SHARED_PROTOCOL
test "$(KVM_CPUS)" = 4
test "$(KVM_MEM)" = 8G
test "$(FXMARK_TMPFS_SIZE)" = 1G
test "$(FXMARK_CELL_TIMEOUT)" = 900
test "$(FXMARK_BPF_STATS)" = 0
test "$(FXMARK_READDIR_TYPES)" = "MRDL MRDM"
test "$(FXMARK_READDIR_HOST_CPUS)" = 4-7
test "$(FXMARK_READDIR_ANALYSIS_SEED)" = 20260728
test "$(FXMARK_COMMIT)" = 3f29552ce7ba6be24c4172e6e2c2c1f603209953
test "$(FXMARK_ARCHIVE_URL)" = \
	https://codeload.github.com/sslab-gatech/fxmark/tar.gz/3f29552ce7ba6be24c4172e6e2c2c1f603209953
test "$(FXMARK_ARCHIVE_SHA256)" = \
	b8887b7ef5fe9cedaeed35ab12801aa8b7534d9e16ec40124af788dfd85f46ae
test "$(FXMARK_BPFTOOL)" = "$(KERNEL_BPFTOOL)"
test "$$(cat "$(KERNEL_BPFTOOL_SOURCE_STAMP)")" = \
	"$(FXMARK_READDIR_EXPECTED_PATCHED_COMMIT)"
test "$(KVM_APPEND)" = \
	"loglevel=7 panic=30 oops=panic tsc=reliable clocksource=tsc"
test "$(VNG_MODULE_FLAGS)" = --skip-modules
test "$(FXMARK_READDIR_EXPECTED_PATCHED_COMMIT)" = \
	1e81d4793c78b7667d0798248c70c0b15a2c3877
test "$(FXMARK_READDIR_EXPECTED_STOCK_COMMIT)" = \
	062871f1371b2e02a272ff5279c6479aff0a37ef
endef

define FXMARK_READDIR_ASSERT_PREFLIGHT_PROTOCOL
$(call FXMARK_READDIR_ASSERT_SHARED_PROTOCOL)
test "$(FXMARK_READDIR_PREFLIGHT_REPETITIONS)" = 1
test "$(FXMARK_READDIR_PREFLIGHT_DURATION)" = 2
test "$(FXMARK_READDIR_PREFLIGHT_WORKERS)" = "1 4"
endef

define FXMARK_READDIR_ASSERT_FORMAL_PROTOCOL
$(call FXMARK_READDIR_ASSERT_SHARED_PROTOCOL)
test -f "$(FXMARK_READDIR_PREFLIGHT_REVIEW)"
grep -Fx 'Final verdict: GO' "$(FXMARK_READDIR_PREFLIGHT_REVIEW)"
test "$(FXMARK_READDIR_REPETITIONS)" = 10
test "$(FXMARK_READDIR_DURATION)" = 30
test "$(FXMARK_READDIR_WORKERS)" = "1 2 4"
endef

define FXMARK_READDIR_CAPTURE_SOURCE
install -d "$(1)/artifacts/source/fxmark"
install -m 0444 "$(FXMARK_ARCHIVE)" \
	"$(1)/artifacts/source/fxmark/source.tar.gz"
install -m 0444 "$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
	"$(1)/artifacts/source/fxmark/fxmark-correctness.patch"
install -m 0444 \
	"$(ROOT_DIR)/bench/fxmark/fxmark-readdir-correctness.patch" \
	"$(1)/artifacts/source/fxmark/fxmark-readdir-correctness.patch"
install -m 0444 "$(FXMARK_SOURCE_ROOT)/src/MRDL.c" \
	"$(1)/artifacts/source/fxmark/MRDL.c"
install -m 0444 "$(FXMARK_SOURCE_ROOT)/src/MRDM.c" \
	"$(1)/artifacts/source/fxmark/MRDM.c"
jq -n \
	--arg commit "$(FXMARK_COMMIT)" \
	--arg archive_url "$(FXMARK_ARCHIVE_URL)" \
	--arg archive_sha256 "$(FXMARK_ARCHIVE_SHA256)" \
	--arg correctness_patch_sha256 "$$(sha256sum "$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" | awk '{print $$1}')" \
	--arg readdir_patch_sha256 "$$(sha256sum "$(ROOT_DIR)/bench/fxmark/fxmark-readdir-correctness.patch" | awk '{print $$1}')" \
	'{commit:$$commit,archive_url:$$archive_url,archive_sha256:$$archive_sha256,corrections:{common_patch_sha256:$$correctness_patch_sha256,readdir_patch_sha256:$$readdir_patch_sha256,files_per_worker:8192}}' \
	>"$(1)/artifacts/source/fxmark/manifest.json"
(cd "$(1)" && sha256sum \
	artifacts/source/fxmark/source.tar.gz \
	artifacts/source/fxmark/fxmark-correctness.patch \
	artifacts/source/fxmark/fxmark-readdir-correctness.patch \
	artifacts/source/fxmark/MRDL.c \
	artifacts/source/fxmark/MRDM.c \
	artifacts/source/fxmark/manifest.json >source.sha256)
endef

define FXMARK_READDIR_START
$(call NAMEI_EXT_VALIDATE_HOST_CPU_PIN,$(FXMARK_READDIR_HOST_CPUS),$(KVM_CPUS))
test "$$(cat "$(KERNEL_COMMIT_FILE)")" = \
	"$(FXMARK_READDIR_EXPECTED_PATCHED_COMMIT)"
test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = \
	"$(FXMARK_READDIR_EXPECTED_STOCK_COMMIT)"
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),fxmark-readdir,fxmark-atc2016,kvm_fxmark_readdir,$(1)/observations.jsonl,fxmark_pass.bpf.c+fxmark_select.bpf.c,fxmark_cell+fxmark_fuse)
$(call FXMARK_CAPTURE_RUN_ARTIFACTS,$(1))
$(call FXMARK_READDIR_CAPTURE_SOURCE,$(1))
test "$$(sha256sum "$(1)/artifacts/runtime/bpftool" | awk '{print $$1}')" = \
	"$$(sha256sum "$(KERNEL_BPFTOOL)" | awk '{print $$1}')"
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--slurpfile source "$(1)/artifacts/source/fxmark/manifest.json" \
	--argjson repetitions "$(2)" \
	--argjson duration_seconds "$(3)" \
	--arg workers "$(4)" \
	--argjson kvm_cpus "$(KVM_CPUS)" \
	--arg host_cpu_pin "$(FXMARK_READDIR_HOST_CPUS)" \
	--arg kvm_append "$(KVM_APPEND)" \
	--arg vng_module_flags "$(VNG_MODULE_FLAGS)" \
	--arg bpftool_source_commit "$$(cat "$(KERNEL_BPFTOOL_SOURCE_STAMP)")" \
	--arg bpftool_sha256 "$$(sha256sum "$(1)/artifacts/runtime/bpftool" | awk '{print $$1}')" \
	'.layout = "latin-square-boot-matrix" | .kernel_artifacts = $$artifacts[0] | .kernel_commits = {patched:$$artifacts[0].patched.commit,stock:$$artifacts[0].stock.commit} | .benchmark_source = $$source[0] | .guest_launch = {kvm_append:$$kvm_append,vng_module_flags:$$vng_module_flags} | .runtime_provenance = {bpftool_source_commit:$$bpftool_source_commit,bpftool_sha256:$$bpftool_sha256} | .matrix = {conditions:["stock","unattached","pass","select","fuse"],types:["MRDL","MRDM"],workers:($$workers|split(" ")|map(tonumber)),repetitions:$$repetitions,duration_seconds:$$duration_seconds,bpf_stats:0,order:"rotating-latin-square",kvm_cpus:$$kvm_cpus,host_cpu_pin:$$host_cpu_pin,affinity:"exact-vcpu-index-mapping",external_inventory_gate:true,files_per_worker:8192}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" -e \
	--arg patched "$(FXMARK_READDIR_EXPECTED_PATCHED_COMMIT)" \
	--arg stock "$(FXMARK_READDIR_EXPECTED_STOCK_COMMIT)" \
	'.layout == "latin-square-boot-matrix" and .kernel_artifacts == $$artifacts[0] and .kernel.commit == $$patched and .kernel_artifacts.patched.commit == $$patched and .kernel_commits.patched == $$patched and .kernel_artifacts.stock.commit == $$stock and .kernel_commits.stock == $$stock and .runtime_provenance.bpftool_source_commit == $$patched' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(5)" >"$(1)/command.txt"
pkg-config --modversion fuse >"$(1)/fuse-version.txt"
ldd "$(1)/artifacts/runtime/fxmark_fuse" >"$(1)/fxmark-fuse-ldd.txt"
$(call NAMEI_EXT_MULTI_BOOT_CAPTURE_PINNED_HOST,$(1),$(FXMARK_READDIR_HOST_CPUS))
: >"$(1)/launch-order.jsonl"
sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
	"$(ROOT_DIR)/configs/benchmarks/fxmark_readdir.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(ROOT_DIR)/Makefile" \
	"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
	"$(ROOT_DIR)/mk/experiments/fxmark_readdir.mk" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/multi_boot.mk" \
	"$(ROOT_DIR)/mk/kvm.mk" "$(ROOT_DIR)/mk/kernel.mk" \
	"$(ROOT_DIR)/tools/kvm/verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
	"$(ROOT_DIR)/bench/fxmark/fxmark-readdir-correctness.patch" \
	"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
	"$(ROOT_DIR)/bench/fxmark/fxmark_fuse.c" \
	"$(ROOT_DIR)/bpf/policies/fxmark_pass.bpf.c" \
	"$(ROOT_DIR)/bpf/policies/fxmark_select.bpf.c" \
	"$(FXMARK_READDIR_ANALYSIS)" \
	"$(ROOT_DIR)/analysis/fxmark_readdir/test_analyze.py" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-readdir-experiment-plan.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-readdir-plan-review.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-readdir-implementation.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-28-rq2-fxmark-readdir-implementation-review.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-29-rq2-fxmark-readdir-kvm-preflight-attempt-1.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-29-rq2-fxmark-readdir-kvm-preflight-attempt-2.md" \
	>"$(1)/inputs.sha256"
if test -n "$(6)"; then \
	test -f "$(6)"; \
	sha256sum "$(6)" >>"$(1)/inputs.sha256"; \
fi
: >"$(1)/expected-boots.txt"
: >"$(1)/expected-cells.txt"
endef

define FXMARK_READDIR_RUN_MATRIX
manifest="$(1)/artifacts/manifest.json"; \
fxmark_binary="$(1)/$$(jq -r '.runtime.fxmark' "$$manifest")"; \
fxmark_cell="$(1)/$$(jq -r '.runtime.cell' "$$manifest")"; \
fxmark_fuse="$(1)/$$(jq -r '.runtime.fuse' "$$manifest")"; \
bpftool_binary="$(1)/$$(jq -r '.runtime.bpftool' "$$manifest")"; \
pass_policy="$(1)/$$(jq -r '.runtime.pass_policy' "$$manifest")"; \
select_policy="$(1)/$$(jq -r '.runtime.select_policy' "$$manifest")"; \
base=(stock unattached pass select fuse); \
order_index=0; \
for repetition in $$(seq 1 "$(2)"); do \
	offset=$$(((repetition - 1) % 5)); \
	for step in 0 1 2 3 4; do \
		condition="$${base[$$(((offset + step) % 5))]}"; \
		order_index=$$((order_index + 1)); \
		case "$$condition" in \
		stock|fuse) flavor=stock ;; \
		unattached|pass|select) flavor=patched ;; \
		*) exit 1 ;; \
		esac; \
		image="$(1)/$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].image' "$$manifest")"; \
		config="$(1)/$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].config' "$$manifest")"; \
		commit=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].commit' "$$manifest"); \
		build_id=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].build_id' "$$manifest"); \
		notes_sha=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].notes_sha256' "$$manifest"); \
		btf_sha=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].btf_sha256' "$$manifest"); \
		release=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].release' "$$manifest"); \
		printf '%s|%s|%s|%s|%s|%s|%s\n' "$$repetition" \
			"$$condition" "$$commit" "$$build_id" "$$notes_sha" \
			"$$btf_sha" "$$release" >>"$(1)/expected-boots.txt"; \
		for type in MRDL MRDM; do \
			for workers in $(4); do \
				printf '%s|%s|%s|%s\n' "$$repetition" \
					"$$condition" "$$type" "$$workers" \
					>>"$(1)/expected-cells.txt"; \
			done; \
		done; \
		boot_dir="$(1)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
		install -d "$$boot_dir"; \
		guest_makefile="$$boot_dir/guest.mk"; \
		$(call FXMARK_WRITE_GUEST_MAKEFILE,$(3),MRDL MRDM,$(4),1); \
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
			NAMEI_EXT_KVM_CAPTURE_HOST_CPUS="$(FXMARK_READDIR_HOST_CPUS)"; \
		host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		test -n "$$host_completed_at"; \
		jq -cn \
			--arg schema "namei_ext.fxmark_readdir.launch_order.v1" \
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

define FXMARK_READDIR_VALIDATE_BOOT
for boot in "$(1)"/boots/*; do \
	for file in guest.mk guest.mk.sha256 launcher.stdout.log \
		launcher.stderr.log vcpu-affinity.json affinity-verified-at.txt \
		affinity-barrier.txt bpf-programs-before.json \
		bpf-programs-after.json bpf-cgroup-before.json \
		bpf-cgroup-after.json fuse-mounts-before.txt \
		fuse-mounts-after.txt fuse-open-fds-before.txt \
		fuse-open-fds-before.status fuse-open-fds-after.txt \
		fuse-open-fds-after.status boot.json observations.jsonl \
		kernel.config kernel-commit.txt kernel-build-id.txt \
		kernel-notes.sha256 kernel-btf.sha256 kernel-flavor.txt \
		kernel-release.txt clocksource-before.txt \
		clocksource-after.txt uname.txt proc-version.txt \
		kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt \
		dmesg.log; do \
		test -e "$$boot/$$file"; \
	done; \
	(cd "$$boot" && sha256sum -c guest.mk.sha256); \
	jq -e '.schema == "namei_ext.fxmark.boot.v2" and .status == "completed" and .clocksource == "tsc" and (.completed_at | type == "string" and length > 0) and (.affinity_verified_at | type == "string" and length > 0) and (.guest_barrier_at | type == "string" and length > 0) and .host_launch.order_index > 0' \
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
	test "$$(cat "$$boot/fuse-open-fds-before.status")" = 1; \
	test "$$(cat "$$boot/fuse-open-fds-after.status")" = 1; \
	cmp "$$boot/fuse-mounts-before.txt" \
		"$$boot/fuse-mounts-after.txt"; \
	cmp "$$boot/fuse-open-fds-before.txt" \
		"$$boot/fuse-open-fds-after.txt"; \
	cmp "$$boot/fuse-open-fds-before.status" \
		"$$boot/fuse-open-fds-after.status"; \
	jq -e --slurpfile expected "$(1)/host-cpu-pin.json" \
		--argjson kvm_cpus "$(KVM_CPUS)" \
		'.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified" and .expected_host_cpus == $$expected[0] and (.expected_host_cpus | length) == $$kvm_cpus and [.vcpus[] | [.vcpu_index,.cpus_allowed]] == [range(0; ($$expected[0] | length)) as $$index | [$$index,[$$expected[0][$$index]]]]' \
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
endef

define FXMARK_READDIR_FINALIZE
jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' \
	"$(1)/run.json" >/dev/null
LC_ALL=C sort -o "$(1)/expected-boots.txt" "$(1)/expected-boots.txt"
LC_ALL=C sort -o "$(1)/expected-cells.txt" "$(1)/expected-cells.txt"
$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(1),$$((5 * $(2))))
jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' \
	"$(1)/observations.jsonl" | LC_ALL=C sort \
	>"$(1)/observed-cells.txt"
find "$(1)/boots" -name boot.json -print0 | sort -z | \
	xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)|\(.kernel_release)"' | \
	LC_ALL=C sort >"$(1)/observed-boots.txt"
cmp "$(1)/expected-cells.txt" "$(1)/observed-cells.txt"
cmp "$(1)/expected-boots.txt" "$(1)/observed-boots.txt"
test "$$(jq -s 'length' "$(1)/observations.jsonl")" = \
	"$$((5 * 2 * $(words $(4)) * $(2)))"
test "$$(jq -s '[.[] | select(.pass == true)] | length' \
	"$(1)/observations.jsonl")" = \
	"$$((5 * 2 * $(words $(4)) * $(2)))"
test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' \
	"$(1)/observations.jsonl")" = \
	"$$((5 * 2 * $(words $(4)) * $(2)))"
sha256sum -c "$(1)/inputs.sha256"
sha256sum -c "$(1)/artifacts.sha256"
(cd "$(1)" && sha256sum -c source.sha256)
jq -s -e --argjson repetitions "$(2)" \
	'length == (5 * $$repetitions) and ([.[].order_index] == [range(1; (5 * $$repetitions) + 1)]) and ([.[] | [.repetition,.condition]] == [range(1; $$repetitions + 1) as $$rep | ["stock","unattached","pass","select","fuse"] as $$base | range(0;5) as $$step | [$$rep,$$base[((($$rep - 1) % 5) + $$step) % 5]]]) and all(.[]; .schema == "namei_ext.fxmark_readdir.launch_order.v1" and (.host_started_at | type == "string" and length > 0) and (.host_completed_at | type == "string" and length > 0))' \
	"$(1)/launch-order.jsonl" >/dev/null
jq -s -e \
	'all(.[]; .event == "fxmark-cell" and .pass == true and .readdir_validation_required == true and .bpf_stats_post_timing_only == true and .fxmark_status == 0 and .seconds > 0 and .works > 0 and .works_per_second > 0 and .leader_cgroup_verified == true and .actual_files == .expected_files and .actual_directories == .expected_directories and .logical_names_complete == true and .logical_directory_entries == .expected_directory_entries and (if .type == "MRDL" then .expected_files == (8192 * .workers) and .expected_directories == (1 + .workers) and .expected_directory_entries == ((8192 + 2) * .workers) and .validation_getdents_nonempty_calls >= .workers and .validation_readdir_retry_runs == (.validation_getdents_nonempty_calls - .workers) elif .type == "MRDM" then .expected_files == (8192 * .workers) and .expected_directories == 1 and .expected_directory_entries == ((8192 * .workers) + 2) and .validation_getdents_nonempty_calls >= 1 and .validation_readdir_retry_runs == (.validation_getdents_nonempty_calls - 1) else false end) and (if (.condition == "stock" or .condition == "unattached") then .selected_directory_identity == true and .attached_program_id_before == 0 and .attached_program_id_after == 0 and .fuse_phase_measured_acks == 0 and .fuse_phase_after_acks == 0 and .fuse_phase_invalid_commands == 0 elif (.condition == "pass" or .condition == "select") then .selected_directory_identity == true and .attachment_stable == true and .attached_program_id_before > 0 and .attached_program_id_after == .attached_program_id_before and .validation_lookup_runs > 0 and .validation_readdir_runs == (.logical_directory_entries + .validation_readdir_retry_runs) and (.policy_run_count_after - .policy_run_count_before) == (.validation_lookup_runs + .validation_readdir_runs) and .fuse_phase_measured_acks == 0 and .fuse_phase_after_acks == 0 and .fuse_phase_invalid_commands == 0 elif .condition == "fuse" then .fuse_status == 0 and .fuse_setup_requests > 0 and .fuse_measured_requests > 0 and .fuse_measured_opendir > 0 and .fuse_measured_readdir > 0 and .fuse_measured_releasedir > 0 and .fuse_phase_measured_acks == 1 and .fuse_phase_after_acks == 1 and .fuse_phase_invalid_commands == 0 and .fuse_f_type_before > 0 and .fuse_f_type_after == .fuse_f_type_before else false end) and (.select_required_for_logical_path == (.condition == "select")))' \
	"$(1)/observations.jsonl" >/dev/null
$(call FXMARK_READDIR_VALIDATE_BOOT,$(1))
find "$(1)/boots" -name boot.json -print0 | sort -z | \
	xargs -0 jq -s -e 'group_by(.kernel_flavor) | length == 2 and all(.[]; ([.[] | [.kernel_commit,.kernel_build_id,.kernel_notes_sha256,.kernel_btf_sha256,.kernel_release]] | unique | length) == 1)' >/dev/null
$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_PINNED_HOST_FILES,$(1))
for file in fuse-version.txt fxmark-fuse-ldd.txt launch-order.jsonl \
		source.sha256; do \
	test -s "$(1)/$$file"; \
done
$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(1),$(1)/observations.jsonl)
jq --slurpfile manifest "$(1)/artifacts/manifest.json" -e \
	--argjson repetitions "$(2)" \
	--argjson duration_seconds "$(3)" \
	--arg workers "$(4)" \
	--arg patched "$(FXMARK_READDIR_EXPECTED_PATCHED_COMMIT)" \
	--arg stock "$(FXMARK_READDIR_EXPECTED_STOCK_COMMIT)" \
	'.layout == "latin-square-boot-matrix" and .matrix.conditions == ["stock","unattached","pass","select","fuse"] and .matrix.types == ["MRDL","MRDM"] and .matrix.workers == ($$workers|split(" ")|map(tonumber)) and .matrix.repetitions == $$repetitions and .matrix.duration_seconds == $$duration_seconds and .matrix.bpf_stats == 0 and .matrix.order == "rotating-latin-square" and .matrix.affinity == "exact-vcpu-index-mapping" and .matrix.external_inventory_gate == true and .matrix.files_per_worker == 8192 and .kernel_artifacts == $$manifest[0] and .kernel_commits.patched == $$patched and .kernel_commits.stock == $$stock and .runtime_provenance.bpftool_source_commit == $$patched' \
	"$(1)/run.json" >/dev/null
endef

.PHONY: fxmark-readdir-analysis-test \
	kvm-fxmark-readdir-preflight kvm-fxmark-readdir \
	fxmark-readdir-analyze fxmark-readdir-report \
	experiment-fxmark-readdir

fxmark-readdir-analysis-test: fxmark-readdir-source-contract \
		fxmark-fuse-readdir-contract
	python3 "$(ROOT_DIR)/analysis/fxmark_readdir/test_analyze.py"
	python3 "$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py"

kvm-fxmark-readdir-preflight kvm-fxmark-readdir: \
	FXMARK_BPFTOOL = $(KERNEL_BPFTOOL)
kvm-fxmark-readdir-preflight kvm-fxmark-readdir: \
	NAMEI_EXT_REQUIRE_CLEAN = 1

kvm-fxmark-readdir-preflight: experiment-source-clean kernel-bpftool \
		fxmark-kernel-pair fxmark-rq2-build bpf \
		fxmark-readdir-analysis-test
	$(call FXMARK_READDIR_ASSERT_PREFLIGHT_PROTOCOL)
	$(call FXMARK_READDIR_START,$(FXMARK_READDIR_PREFLIGHT_RESULT_DIR),$(FXMARK_READDIR_PREFLIGHT_REPETITIONS),$(FXMARK_READDIR_PREFLIGHT_DURATION),$(FXMARK_READDIR_PREFLIGHT_WORKERS),make kvm-fxmark-readdir-preflight RUN_ID=$(RUN_ID))
	$(call FXMARK_READDIR_RUN_MATRIX,$(FXMARK_READDIR_PREFLIGHT_RESULT_DIR),$(FXMARK_READDIR_PREFLIGHT_REPETITIONS),$(FXMARK_READDIR_PREFLIGHT_DURATION),$(FXMARK_READDIR_PREFLIGHT_WORKERS))
	$(call FXMARK_READDIR_FINALIZE,$(FXMARK_READDIR_PREFLIGHT_RESULT_DIR),$(FXMARK_READDIR_PREFLIGHT_REPETITIONS),$(FXMARK_READDIR_PREFLIGHT_DURATION),$(FXMARK_READDIR_PREFLIGHT_WORKERS))
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_READDIR_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" fxmark-readdir-analyze \
		RUN_ID="$(RUN_ID)" \
		FXMARK_READDIR_ACTIVE_DIR="$(FXMARK_READDIR_PREFLIGHT_RESULT_DIR)"

kvm-fxmark-readdir: experiment-source-clean kernel-bpftool \
		fxmark-kernel-pair fxmark-rq2-build bpf \
		fxmark-readdir-analysis-test
	$(call FXMARK_READDIR_ASSERT_FORMAL_PROTOCOL)
	$(call FXMARK_READDIR_START,$(FXMARK_READDIR_RESULT_DIR),$(FXMARK_READDIR_REPETITIONS),$(FXMARK_READDIR_DURATION),$(FXMARK_READDIR_WORKERS),make experiment-fxmark-readdir RUN_ID=$(RUN_ID),$(FXMARK_READDIR_PREFLIGHT_REVIEW))
	$(call FXMARK_READDIR_RUN_MATRIX,$(FXMARK_READDIR_RESULT_DIR),$(FXMARK_READDIR_REPETITIONS),$(FXMARK_READDIR_DURATION),$(FXMARK_READDIR_WORKERS))
	$(call FXMARK_READDIR_FINALIZE,$(FXMARK_READDIR_RESULT_DIR),$(FXMARK_READDIR_REPETITIONS),$(FXMARK_READDIR_DURATION),$(FXMARK_READDIR_WORKERS))
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_READDIR_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" fxmark-readdir-analyze \
		RUN_ID="$(RUN_ID)" \
		FXMARK_READDIR_ACTIVE_DIR="$(FXMARK_READDIR_RESULT_DIR)"

fxmark-readdir-analyze:
	result="$(FXMARK_READDIR_ACTIVE_DIR)"; \
	test -n "$$result"; \
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$$result); \
	sha256sum -c "$$result/inputs.sha256"; \
	sha256sum -c "$$result/artifacts.sha256"; \
	(cd "$$result" && sha256sum -c source.sha256); \
	analysis="$$result/analysis"; \
	$(call NAMEI_EXT_ANALYSIS_PREPARE,$$analysis); \
	python3 "$(FXMARK_READDIR_ANALYSIS)" \
		--input "$$result/observations.jsonl" \
		--run "$$result/run.json" \
		--output "$$analysis.tmp" \
		--seed "$(FXMARK_READDIR_ANALYSIS_SEED)"; \
	(cd "$$result" && sha256sum run.json observations.jsonl \
		>analysis.tmp/raw-inputs.sha256); \
	(cd "$$result" && sha256sum -c analysis.tmp/raw-inputs.sha256); \
	for file in summary.json summary.csv report.md throughput.png \
			throughput.pdf raw-inputs.sha256; do \
		test -s "$$analysis.tmp/$$file"; \
	done; \
	jq -e '.schema == "namei_ext.fxmark_readdir.analysis.v1" and (.verdict.verdict == "supported" or .verdict.verdict == "contradicted" or .verdict.verdict == "mixed")' \
		"$$analysis.tmp/summary.json" >/dev/null; \
	(cd "$$analysis.tmp" && \
		sha256sum summary.json summary.csv report.md throughput.png \
			throughput.pdf raw-inputs.sha256 >analysis.sha256.tmp && \
		mv -f analysis.sha256.tmp analysis.sha256 && \
		sha256sum -c analysis.sha256); \
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$$analysis)

fxmark-readdir-report:
	jq -e '.status == "completed" and (.completed_at | type == "string" and length > 0)' \
		"$(FXMARK_READDIR_RESULT_DIR)/run.json" >/dev/null
	sha256sum -c "$(FXMARK_READDIR_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(FXMARK_READDIR_RESULT_DIR)/artifacts.sha256"
	(cd "$(FXMARK_READDIR_RESULT_DIR)" && sha256sum -c source.sha256)
	(cd "$(FXMARK_READDIR_RESULT_DIR)" && \
		sha256sum -c analysis/raw-inputs.sha256)
	(cd "$(FXMARK_READDIR_RESULT_DIR)/analysis" && \
		sha256sum -c analysis.sha256)
	jq -e '.schema == "namei_ext.fxmark_readdir.analysis.v1" and (.verdict.verdict == "supported" or .verdict.verdict == "contradicted" or .verdict.verdict == "mixed")' \
		"$(FXMARK_READDIR_RESULT_DIR)/analysis/summary.json" >/dev/null

experiment-fxmark-readdir: kvm-fxmark-readdir
	$(MAKE) -C "$(ROOT_DIR)" fxmark-readdir-report RUN_ID="$(RUN_ID)"
