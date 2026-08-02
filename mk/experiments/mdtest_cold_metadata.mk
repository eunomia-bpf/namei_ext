MDTEST_CACHE_DIR ?= $(CACHE_ROOT)/benchmarks/mdtest-cold-metadata
MDTEST_IOR_SOURCE ?= $(MDTEST_CACHE_DIR)/ior-4.0.0
MDTEST_IOR_SOURCE_STAMP ?= $(MDTEST_IOR_SOURCE)/.namei-ext-source
MDTEST_IOR_BUILD_SOURCE ?= $(BUILD_ROOT)/mdtest-cold-metadata/ior-source
MDTEST_IOR_BUILD ?= $(BUILD_ROOT)/mdtest-cold-metadata/ior-build
MDTEST_IOR_BUILD_LOG ?= $(BUILD_ROOT)/mdtest-cold-metadata/ior-build.log
MDTEST_BINARY ?= $(BUILD_ROOT)/mdtest-cold-metadata/runtime/mdtest

MDTEST_LIBFUSE_SOURCE ?= $(MDTEST_CACHE_DIR)/libfuse-3.18.2
MDTEST_LIBFUSE_SOURCE_STAMP ?= $(MDTEST_LIBFUSE_SOURCE)/.namei-ext-source
MDTEST_LIBFUSE_BUILD ?= $(BUILD_ROOT)/mdtest-cold-metadata/libfuse-build
MDTEST_LIBFUSE_BUILD_LOG ?= $(BUILD_ROOT)/mdtest-cold-metadata/libfuse-build.log
MDTEST_FUSE_BINARY ?= $(BUILD_ROOT)/mdtest-cold-metadata/runtime/passthrough_ll

MDTEST_VIRTME_NG_SOURCE ?= $(MDTEST_CACHE_DIR)/virtme-ng-$(MDTEST_VIRTME_NG_COMMIT)
MDTEST_VIRTME_NG_SOURCE_STAMP ?= $(MDTEST_VIRTME_NG_SOURCE)/.namei-ext-source
MDTEST_VNG ?= $(MDTEST_VIRTME_NG_SOURCE)/vng

MDTEST_CELL ?= $(BUILD_ROOT)/mdtest-cold-metadata/mdtest_cell
MDTEST_BPFTOOL ?= $(KERNEL_BPFTOOL)
MDTEST_PASS_POLICY ?= $(BUILD_ROOT)/bpf/fxmark_pass.bpf.o
MDTEST_SELECT_POLICY ?= $(BUILD_ROOT)/bpf/fxmark_select.bpf.o
MDTEST_ANALYSIS ?= $(ROOT_DIR)/analysis/mdtest_cold_metadata/analyze.py
MDTEST_RESULT_DIR ?= $(RESULT_ROOT)/experiments/mdtest-cold-metadata-rq2/$(RUN_ID)
MDTEST_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/mdtest-cold-metadata-rq2-preflight/$(RUN_ID)
MDTEST_GUEST_WORK_ROOT ?= /run/namei-ext-mdtest

ifneq ($(strip $(MDTEST_RUN_ROOT)),)
MDTEST_RUN_BINARY ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/mdtest
MDTEST_RUN_FUSE ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/passthrough_ll
MDTEST_RUN_CELL ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/mdtest_cell
MDTEST_RUN_BPFTOOL ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/bpftool
MDTEST_RUN_PASS_POLICY ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/fxmark_pass.bpf.o
MDTEST_RUN_SELECT_POLICY ?= $(MDTEST_RUN_ROOT)/artifacts/runtime/fxmark_select.bpf.o
MDTEST_BOOT_RESULT_DIR ?= $(MDTEST_RUN_ROOT)/boots/block-$(shell printf '%02d' "$(REPETITION)")-$(CONDITION)
MDTEST_BOOT_KERNEL_CONFIG ?= $(MDTEST_RUN_ROOT)/artifacts/kernel/$(MDTEST_BOOT_KERNEL_FLAVOR)/config
endif

define MDTEST_ASSERT_SHARED_PROTOCOL
test "$(MDTEST_IOR_COMMIT)" = 967a9f65109760db8a3ac14a7fdd007f337d2960
test "$(MDTEST_IOR_TAG)" = 4.0.0
test "$(MDTEST_LIBFUSE_COMMIT)" = 033844748010a3b8265bf1c90b9ae8ffe4cd9ca7
test "$(MDTEST_LIBFUSE_TAG)" = fuse-3.18.2
test "$(MDTEST_RANKS)" = "1 4"
test "$(MDTEST_HOST_CPUS)" = 8-15
test "$(MDTEST_KVM_CPUS)" = 8
test "$(MDTEST_KVM_MEMORY)" = 8G
test "$(MDTEST_BOOT_TIMEOUT)" = 7200
test "$(MDTEST_PHASE_TIMEOUT)" = 900
test "$(MDTEST_FUSE_TIMEOUT)" = 30
test "$(MDTEST_TMPFS_SIZE)" = 4G
test "$(MDTEST_EXT4_IMAGE_SIZE)" = 2G
test "$(MDTEST_EXT4_INODES)" = 262144
test "$(MDTEST_ANALYSIS_SEED)" = 20260729
test "$(MDTEST_VIRTME_NG_COMMIT)" = 8f74cceecb163a5d5b08e70c101de85920eb624c
test "$(MDTEST_QMP_LISTENER_TIMEOUT)" = 30
test "$(MDTEST_VCPU_VERIFY_INITIAL_DELAY)" = 6
test "$(MDTEST_AFFINITY_BARRIER_TIMEOUT)" = 60
test "$(NAMEI_EXT_QMP_HOST)" = 127.0.0.1
test "$(NAMEI_EXT_QMP_PORT)" = 3636
test "$(KVM_APPEND)" = \
	"loglevel=7 panic=30 oops=panic tsc=reliable clocksource=tsc"
test "$(VNG_MODULE_FLAGS)" = --skip-modules
grep -Fx 'Final verdict: GO' "$(MDTEST_PLAN_REVIEW)"
command -v ss >/dev/null
endef

define MDTEST_ASSERT_PREFLIGHT_PROTOCOL
$(call MDTEST_ASSERT_SHARED_PROTOCOL)
test "$(MDTEST_PREFLIGHT_REPETITIONS)" = 1
test "$(MDTEST_PREFLIGHT_ITEMS_PER_RANK)" = 4096
endef

define MDTEST_ASSERT_FORMAL_PROTOCOL
$(call MDTEST_ASSERT_SHARED_PROTOCOL)
test "$(MDTEST_FORMAL_REPETITIONS)" = 10
test "$(MDTEST_FORMAL_ITEMS_PER_RANK)" = 32768
test -f "$(MDTEST_PREFLIGHT_REVIEW)"
grep -Fx 'Final verdict: GO' "$(MDTEST_PREFLIGHT_REVIEW)"
endef

define MDTEST_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel/patched" "$(1)/artifacts/kernel/stock" \
	"$(1)/artifacts/runtime" "$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" \
	"$(1)/artifacts/kernel/patched/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/patched/config"
install -m 0444 "$(STOCK_KERNEL_IMAGE)" \
	"$(1)/artifacts/kernel/stock/bzImage"
install -m 0444 "$(STOCK_KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/stock/config"
install -m 0555 "$(MDTEST_BINARY)" "$(1)/artifacts/runtime/mdtest"
install -m 0555 "$(MDTEST_FUSE_BINARY)" \
	"$(1)/artifacts/runtime/passthrough_ll"
install -m 0555 "$(MDTEST_CELL)" "$(1)/artifacts/runtime/mdtest_cell"
install -m 0555 "$(MDTEST_BPFTOOL)" "$(1)/artifacts/runtime/bpftool"
install -m 0444 "$(MDTEST_PASS_POLICY)" \
	"$(1)/artifacts/runtime/fxmark_pass.bpf.o"
install -m 0444 "$(MDTEST_SELECT_POLICY)" \
	"$(1)/artifacts/runtime/fxmark_select.bpf.o"
install -m 0444 "$(MDTEST_IOR_BUILD_LOG)" \
	"$(1)/artifacts/source/ior-build.log"
install -m 0444 "$(MDTEST_LIBFUSE_BUILD_LOG)" \
	"$(1)/artifacts/source/libfuse-build.log"
readelf -d "$(1)/artifacts/runtime/passthrough_ll" \
	>"$(1)/artifacts/source/passthrough-elf-dynamic.txt"
! grep -F 'libfuse.so' \
	"$(1)/artifacts/source/passthrough-elf-dynamic.txt"
	"$(1)/artifacts/runtime/passthrough_ll" --version \
		>"$(1)/artifacts/source/passthrough-version.txt"
	git -C "$(MDTEST_IOR_SOURCE)" show -s \
		--format='%H%n%D%n%s' "$(MDTEST_IOR_COMMIT)" \
		>"$(1)/artifacts/source/ior-source-version.txt"
	grep -Fx "$(MDTEST_IOR_COMMIT)" \
		"$(1)/artifacts/source/ior-source-version.txt"
	git -C "$(MDTEST_VIRTME_NG_SOURCE)" show -s \
		--format='%H%n%s' HEAD \
		>"$(1)/artifacts/source/virtme-ng-source-version.txt"
	grep -Fx "$(MDTEST_VIRTME_NG_COMMIT)" \
		"$(1)/artifacts/source/virtme-ng-source-version.txt"
jq -n \
	--arg ior_repository "$(MDTEST_IOR_REPOSITORY)" \
	--arg ior_tag "$(MDTEST_IOR_TAG)" \
	--arg ior_commit "$(MDTEST_IOR_COMMIT)" \
	--arg ior_build "CC=mpicc CFLAGS=-O2" \
	--arg libfuse_repository "$(MDTEST_LIBFUSE_REPOSITORY)" \
	--arg libfuse_tag "$(MDTEST_LIBFUSE_TAG)" \
	--arg libfuse_commit "$(MDTEST_LIBFUSE_COMMIT)" \
	--arg libfuse_build "Meson release; default_library=static; examples=true; tests=false; utils=false; enable-io-uring=false" \
	--arg virtme_ng_repository "$(MDTEST_VIRTME_NG_REPOSITORY)" \
	--arg virtme_ng_commit "$(MDTEST_VIRTME_NG_COMMIT)" \
	'{ior:{repository:$$ior_repository,tag:$$ior_tag,commit:$$ior_commit,build:$$ior_build,source_unmodified:true},libfuse:{repository:$$libfuse_repository,tag:$$libfuse_tag,commit:$$libfuse_commit,build:$$libfuse_build,example:"example/passthrough_ll.c",source_unmodified:true},virtme_ng:{repository:$$virtme_ng_repository,commit:$$virtme_ng_commit,source_unmodified:true,native_pin:true}}' \
	>"$(1)/artifacts/source/manifest.json"
jq -n \
	--arg patched_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg patched_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg stock_commit "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" \
	--arg stock_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(STOCK_KERNEL_RELEASE_HEADER)")" \
	'{patched:{commit:$$patched_commit,release:$$patched_release,image:"artifacts/kernel/patched/bzImage",config:"artifacts/kernel/patched/config"},stock:{commit:$$stock_commit,release:$$stock_release,image:"artifacts/kernel/stock/bzImage",config:"artifacts/kernel/stock/config"},runtime:{mdtest:"artifacts/runtime/mdtest",fuse:"artifacts/runtime/passthrough_ll",cell:"artifacts/runtime/mdtest_cell",bpftool:"artifacts/runtime/bpftool",pass_policy:"artifacts/runtime/fxmark_pass.bpf.o",select_policy:"artifacts/runtime/fxmark_select.bpf.o"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define MDTEST_CAPTURE_HOST_BEFORE
lscpu >"$(1)/host-lscpu.txt"
lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE,MAXMHZ,MINMHZ \
	>"$(1)/host-lscpu-extended.txt"
printf '%s\n' "$(MDTEST_HOST_CPUS)" >"$(1)/host-cpu-pin.txt"
	cat /proc/stat >"$(1)/host-proc-stat-before.txt"
	cat /proc/interrupts >"$(1)/host-proc-interrupts-before.txt"
	: >"$(1)/host-cpu-frequency-policy.txt"
	cpu_range="$(MDTEST_HOST_CPUS)"; \
	first_cpu="$${cpu_range%-*}"; \
	last_cpu="$${cpu_range#*-}"; \
	for cpu in $$(seq "$$first_cpu" "$$last_cpu"); do \
		printf 'cpu=%s governor=%s driver=%s max_khz=%s\n' "$$cpu" \
			"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_governor")" \
			"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_driver")" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/cpuinfo_max_freq")" \
		>>"$(1)/host-cpu-frequency-policy.txt"; \
done
"$(MDTEST_VNG)" --version >"$(1)/vng-version.txt"
endef

define MDTEST_START_RUN
$(call NAMEI_EXT_VALIDATE_HOST_CPU_PIN,$(MDTEST_HOST_CPUS),$(MDTEST_KVM_CPUS))
test -z "$$(ss -H -ltn "sport = :$(NAMEI_EXT_QMP_PORT)")"
test "$(MDTEST_VNG)" = "$(MDTEST_VIRTME_NG_SOURCE)/vng"
test -x "$(MDTEST_VNG)"
test ! -L "$(MDTEST_VNG)"
test "$$(cat "$(MDTEST_VIRTME_NG_SOURCE_STAMP)")" = \
	"$(MDTEST_VIRTME_NG_COMMIT)"
test "$$(git -C "$(MDTEST_VIRTME_NG_SOURCE)" rev-parse HEAD)" = \
	"$(MDTEST_VIRTME_NG_COMMIT)"
test -z "$$(git -C "$(MDTEST_VIRTME_NG_SOURCE)" status \
	--porcelain=v1 --untracked-files=no)"
test "$$(cat "$(KERNEL_COMMIT_FILE)")" = \
	"$(MDTEST_EXPECTED_PATCHED_KERNEL_COMMIT)"
test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = \
	"$(MDTEST_EXPECTED_STOCK_KERNEL_COMMIT)"
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),mdtest-cold-metadata,ior-mdtest-4.0.0,kvm_mdtest_cold_metadata_rq2,$(1)/observations.jsonl,fxmark_pass.bpf.c+fxmark_select.bpf.c,mdtest_cell+official_passthrough_ll)
$(call MDTEST_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--slurpfile source "$(1)/artifacts/source/manifest.json" \
	--arg mode "$(2)" \
	--argjson repetitions "$(3)" \
	--argjson items_per_rank "$(4)" \
	--argjson kvm_cpus "$(MDTEST_KVM_CPUS)" \
	--arg host_cpu_pin "$(MDTEST_HOST_CPUS)" \
	--arg kvm_append "$(KVM_APPEND)" \
	--arg virtme_ng_commit "$(MDTEST_VIRTME_NG_COMMIT)" \
	--argjson verifier_initial_delay_seconds "$(MDTEST_VCPU_VERIFY_INITIAL_DELAY)" \
	--argjson affinity_barrier_timeout_seconds "$(MDTEST_AFFINITY_BARRIER_TIMEOUT)" \
	'.layout = "rotating-condition-boot-matrix" | .kernel_artifacts = $$artifacts[0] | .benchmark_source = $$source[0] | .kernel_commits = {patched:$$artifacts[0].patched.commit,stock:$$artifacts[0].stock.commit} | .guest_launch = {kvm_cpus:$$kvm_cpus,host_cpu_pin:$$host_cpu_pin,kvm_append:$$kvm_append,affinity:"official-virtme-ng-native-pin-plus-independent-verification",virtme_ng_commit:$$virtme_ng_commit,verifier_initial_delay_seconds:$$verifier_initial_delay_seconds,affinity_barrier_timeout_seconds:$$affinity_barrier_timeout_seconds} | .matrix = {event:"mdtest-cold-metadata-phase",mode:$$mode,conditions:["stock","unattached","pass","select","fuse"],ranks:[1,4],operations:["create","stat","remove"],repetitions:$$repetitions,items_per_rank:$$items_per_rank,order:"rotating-condition-order-and-alternating-rank-order",fresh_ext4_per_rank_cell:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(5)" >"$(1)/command.txt"
$(call MDTEST_CAPTURE_HOST_BEFORE,$(1))
: >"$(1)/launch-order.jsonl"
endef

define MDTEST_RUN_MATRIX
manifest="$(1)/artifacts/manifest.json"; \
base=(stock unattached pass select fuse); \
order_index=0; \
for repetition in $$(seq 1 "$(2)"); do \
	offset=$$(((repetition - 1) % 5)); \
	for step in 0 1 2 3 4; do \
		condition="$${base[$$(((offset + step) % 5))]}"; \
		order_index=$$((order_index + 1)); \
		case "$$condition" in \
		stock) flavor=stock ;; \
		unattached|pass|select|fuse) flavor=patched ;; \
		*) exit 1 ;; \
		esac; \
		image="$(1)/$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].image' "$$manifest")"; \
		config="$(1)/$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].config' "$$manifest")"; \
		commit=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].commit' "$$manifest"); \
		release=$$(jq -r --arg flavor "$$flavor" \
			'.[$$flavor].release' "$$manifest"); \
		boot_dir="$(1)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
		install -d "$$boot_dir"; \
		host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" KVM_CPUS="$(MDTEST_KVM_CPUS)" \
			KVM_MEM="$(MDTEST_KVM_MEMORY)" \
			VNG="$(MDTEST_VNG)" \
			NAMEI_EXT_VNG_RUN_FLAGS="--verbose --pin $(MDTEST_HOST_CPUS)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$$image" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__mdtest_cold_metadata_guest" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_VARS="CONDITION=$$condition REPETITION=$$repetition MDTEST_RUN_ITEMS=$(3) MDTEST_RUN_ROOT=$(1) MDTEST_BOOT_KERNEL_COMMIT=$$commit MDTEST_BOOT_KERNEL_RELEASE=$$release MDTEST_BOOT_KERNEL_FLAVOR=$$flavor" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot_dir" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(1)" \
			NAMEI_EXT_KVM_CAPTURE_HOST_CPUS="$(MDTEST_HOST_CPUS)" \
			NAMEI_EXT_KVM_CAPTURE_NATIVE_PIN=1 \
			NAMEI_EXT_KVM_CAPTURE_QMP_LISTENER_TIMEOUT="$(MDTEST_QMP_LISTENER_TIMEOUT)" \
			NAMEI_EXT_KVM_CAPTURE_VERIFY_INITIAL_DELAY="$(MDTEST_VCPU_VERIFY_INITIAL_DELAY)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(MDTEST_BOOT_TIMEOUT)"; \
		host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		jq -cn \
			--argjson order_index "$$order_index" \
			--argjson repetition "$$repetition" \
			--arg condition "$$condition" \
			--arg flavor "$$flavor" \
			--arg started_at "$$host_started_at" \
			--arg completed_at "$$host_completed_at" \
			'{order_index:$$order_index,repetition:$$repetition,condition:$$condition,kernel_flavor:$$flavor,host_started_at:$$started_at,host_completed_at:$$completed_at}' \
			>>"$(1)/launch-order.jsonl"; \
	done; \
done
cat /proc/stat >"$(1)/host-proc-stat-after.txt"
cat /proc/interrupts >"$(1)/host-proc-interrupts-after.txt"
endef

define MDTEST_FINALIZE
jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' \
	"$(1)/run.json" >/dev/null
test "$$(find "$(1)/boots" -mindepth 1 -maxdepth 1 -type d | wc -l)" = \
	"$$((5 * $(2)))"
find "$(1)/boots" -mindepth 2 -maxdepth 2 -name observations.jsonl \
	-print0 | LC_ALL=C sort -z | xargs -0 cat >"$(1)/observations.jsonl"
test "$$(jq -s 'length' "$(1)/observations.jsonl")" = \
	"$$((30 * $(2)))"
test "$$(jq -s '[.[] | select(.pass == true)] | length' \
	"$(1)/observations.jsonl")" = "$$((30 * $(2)))"
test "$$(jq -s '[.[] | [.repetition,.condition,.ranks,.operation]] | unique | length' \
	"$(1)/observations.jsonl")" = "$$((30 * $(2)))"
	for boot in "$(1)"/boots/*; do \
		jq -e '.schema == "namei_ext.mdtest_cold_metadata.boot.v1" and .status == "completed" and .clocksource == "tsc" and .observation_count == 6' \
			"$$boot/boot.json" >/dev/null; \
		condition=$$(jq -r '.condition' "$$boot/boot.json"); \
		case "$$condition" in \
		stock) expected_flavor=stock; expected_commit="$(MDTEST_EXPECTED_STOCK_KERNEL_COMMIT)" ;; \
		unattached|pass|select|fuse) expected_flavor=patched; expected_commit="$(MDTEST_EXPECTED_PATCHED_KERNEL_COMMIT)" ;; \
		*) exit 1 ;; \
		esac; \
		jq -e --arg condition "$$condition" \
			--arg flavor "$$expected_flavor" \
			--arg commit "$$expected_commit" \
			'.condition == $$condition and .kernel_flavor == $$flavor and .kernel_commit == $$commit' \
			"$$boot/boot.json" >/dev/null; \
		test "$$(cat "$$boot/kernel-flavor.txt")" = "$$expected_flavor"; \
		test "$$(cat "$$boot/kernel-commit.txt")" = "$$expected_commit"; \
		jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified" and .qmp == {host:"127.0.0.1",port:3636} and .initial_delay_seconds == 6 and (.verified_at | type == "string" and length > 0) and .expected_host_cpus == [8,9,10,11,12,13,14,15] and .expected_vcpu_mapping == [range(0; 8) as $$index | {vcpu_index:$$index,host_cpu:(8 + $$index)}] and [.vcpus[] | [.vcpu_index,.cpus_allowed]] == [range(0; 8) as $$index | [$$index,[8 + $$index]]]' \
			"$$boot/vcpu-affinity.json" >/dev/null; \
		test ! -e "$$boot/vcpu-affinity-pin.json"; \
		test "$$(cat "$$boot/qmp-listener-status.txt")" = 0; \
		test -s "$$boot/qmp-listener.txt"; \
		test -s "$$boot/qmp-listener-wait-started-at.txt"; \
		test -s "$$boot/qmp-listener-observed-at.txt"; \
		test "$$(cat "$$boot/vcpu-affinity.status")" = 0; \
		test "$$(cat "$$boot/launcher.status")" = 0; \
		for file in bpf-programs-before.json bpf-programs-after.json; do \
			jq -e 'type == "array" and length == 0' "$$boot/$$file" >/dev/null; \
		done; \
		for file in bpf-cgroup-before.json bpf-cgroup-after.json; do \
			jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
				"$$boot/$$file" >/dev/null; \
		done; \
		cmp "$$boot/bpf-programs-before.json" "$$boot/bpf-programs-after.json"; \
		cmp "$$boot/bpf-cgroup-before.json" "$$boot/bpf-cgroup-after.json"; \
		for ranks in 1 4; do \
			test ! -e "$$boot/raw/ranks-$$ranks.create.drop-caches.json"; \
			for phase in stat remove; do \
				event="$$boot/raw/ranks-$$ranks.$$phase.drop-caches.json"; \
				jq -e --arg phase "$$phase" \
					'.schema == "namei_ext.mdtest_cold_metadata.drop_caches.v1" and .phase == $$phase and .requested_value == 3 and .bytes_requested == 2 and .bytes_written == 2 and .error == 0' \
					"$$event" >/dev/null; \
				for when in before after; do \
					test -s "$$boot/raw/ranks-$$ranks.$$phase.meminfo.$$when"; \
				done; \
			done; \
		done; \
		for file in fuse-mounts-before.txt fuse-mounts-after.txt \
				fuse-open-fds-before.txt fuse-open-fds-after.txt; do \
			test ! -s "$$boot/$$file"; \
	done; \
	test "$$(cat "$$boot/fuse-open-fds-before.status")" = 1; \
	test "$$(cat "$$boot/fuse-open-fds-after.status")" = 1; \
done
jq -s -e --argjson repetitions "$(2)" \
	'length == (5 * $$repetitions) and ([.[].order_index] == [range(1; (5 * $$repetitions) + 1)])' \
	"$(1)/launch-order.jsonl" >/dev/null
jq -e --arg mode "$(3)" --argjson repetitions "$(2)" \
	--argjson items "$(4)" \
	'.layout == "rotating-condition-boot-matrix" and .guest_launch.affinity == "official-virtme-ng-native-pin-plus-independent-verification" and .guest_launch.virtme_ng_commit == "$(MDTEST_VIRTME_NG_COMMIT)" and .guest_launch.verifier_initial_delay_seconds == 6 and .guest_launch.affinity_barrier_timeout_seconds == 60 and .matrix.mode == $$mode and .matrix.conditions == ["stock","unattached","pass","select","fuse"] and .matrix.ranks == [1,4] and .matrix.operations == ["create","stat","remove"] and .matrix.repetitions == $$repetitions and .matrix.items_per_rank == $$items and .matrix.fresh_ext4_per_rank_cell == true and .kernel_commits.patched == "$(MDTEST_EXPECTED_PATCHED_KERNEL_COMMIT)" and .kernel_commits.stock == "$(MDTEST_EXPECTED_STOCK_KERNEL_COMMIT)"' \
	"$(1)/run.json" >/dev/null
endef

.PHONY: mdtest-cold-metadata-source mdtest-cold-metadata-build \
		mdtest-cold-metadata-source-feasibility mdtest-cold-metadata-kernel-pair \
		mdtest-cold-metadata-analysis-test \
		kvm-mdtest-cold-metadata-preflight kvm-mdtest-cold-metadata-rq2 \
		mdtest-cold-metadata-analyze \
		experiment-mdtest-cold-metadata-rq2 __mdtest_cold_metadata_guest

mdtest-cold-metadata-source: $(MDTEST_IOR_SOURCE_STAMP) \
	$(MDTEST_LIBFUSE_SOURCE_STAMP) $(MDTEST_VIRTME_NG_SOURCE_STAMP)

$(MDTEST_IOR_SOURCE_STAMP):
	rm -rf "$(MDTEST_IOR_SOURCE)"
	install -d "$(MDTEST_CACHE_DIR)"
	git clone --no-checkout "$(MDTEST_IOR_REPOSITORY)" "$(MDTEST_IOR_SOURCE)"
	git -C "$(MDTEST_IOR_SOURCE)" checkout --detach "$(MDTEST_IOR_COMMIT)"
	test "$$(git -C "$(MDTEST_IOR_SOURCE)" rev-parse HEAD)" = \
		"$(MDTEST_IOR_COMMIT)"
	test "$$(git -C "$(MDTEST_IOR_SOURCE)" describe --tags --exact-match)" = \
		"$(MDTEST_IOR_TAG)"
	test -z "$$(git -C "$(MDTEST_IOR_SOURCE)" status --porcelain=v1)"
	printf '%s\n' "$(MDTEST_IOR_COMMIT)" >"$@"

$(MDTEST_LIBFUSE_SOURCE_STAMP):
	rm -rf "$(MDTEST_LIBFUSE_SOURCE)"
	install -d "$(MDTEST_CACHE_DIR)"
	git clone --no-checkout "$(MDTEST_LIBFUSE_REPOSITORY)" \
		"$(MDTEST_LIBFUSE_SOURCE)"
	git -C "$(MDTEST_LIBFUSE_SOURCE)" checkout --detach \
		"$(MDTEST_LIBFUSE_COMMIT)"
	test "$$(git -C "$(MDTEST_LIBFUSE_SOURCE)" rev-parse HEAD)" = \
		"$(MDTEST_LIBFUSE_COMMIT)"
	test "$$(git -C "$(MDTEST_LIBFUSE_SOURCE)" describe --tags --exact-match)" = \
		"$(MDTEST_LIBFUSE_TAG)"
	test -z "$$(git -C "$(MDTEST_LIBFUSE_SOURCE)" status --porcelain=v1)"
	printf '%s\n' "$(MDTEST_LIBFUSE_COMMIT)" >"$@"

$(MDTEST_VIRTME_NG_SOURCE_STAMP):
	rm -rf "$(MDTEST_VIRTME_NG_SOURCE)"
	install -d "$(MDTEST_CACHE_DIR)"
	git clone --no-checkout "$(MDTEST_VIRTME_NG_REPOSITORY)" \
		"$(MDTEST_VIRTME_NG_SOURCE)"
	git -C "$(MDTEST_VIRTME_NG_SOURCE)" checkout --detach \
		"$(MDTEST_VIRTME_NG_COMMIT)"
	test "$$(git -C "$(MDTEST_VIRTME_NG_SOURCE)" rev-parse HEAD)" = \
		"$(MDTEST_VIRTME_NG_COMMIT)"
	test -z "$$(git -C "$(MDTEST_VIRTME_NG_SOURCE)" status --porcelain=v1)"
	test -x "$(MDTEST_VNG)"
	"$(MDTEST_VNG)" --version
	printf '%s\n' "$(MDTEST_VIRTME_NG_COMMIT)" >"$@"

$(MDTEST_BINARY): $(MDTEST_IOR_SOURCE_STAMP)
	rm -rf "$(MDTEST_IOR_BUILD_SOURCE)" "$(MDTEST_IOR_BUILD)"
	install -d "$(MDTEST_IOR_BUILD_SOURCE)" "$(MDTEST_IOR_BUILD)" \
		"$(dir $(MDTEST_BINARY))"
	git -C "$(MDTEST_IOR_SOURCE)" archive "$(MDTEST_IOR_COMMIT)" | \
		tar -x -C "$(MDTEST_IOR_BUILD_SOURCE)"
	(cd "$(MDTEST_IOR_BUILD_SOURCE)" && ./bootstrap) \
		>"$(MDTEST_IOR_BUILD_LOG)" 2>&1
	(cd "$(MDTEST_IOR_BUILD)" && \
		CC=mpicc CFLAGS=-O2 "$(MDTEST_IOR_BUILD_SOURCE)/configure") \
		>>"$(MDTEST_IOR_BUILD_LOG)" 2>&1
	$(MAKE) -C "$(MDTEST_IOR_BUILD)" -j"$(JOBS)" \
		>>"$(MDTEST_IOR_BUILD_LOG)" 2>&1
	install -m 0555 "$(MDTEST_IOR_BUILD)/src/mdtest" "$@"

$(MDTEST_FUSE_BINARY): $(MDTEST_LIBFUSE_SOURCE_STAMP)
	rm -rf "$(MDTEST_LIBFUSE_BUILD)"
	install -d "$(dir $(MDTEST_FUSE_BINARY))"
	meson setup "$(MDTEST_LIBFUSE_BUILD)" "$(MDTEST_LIBFUSE_SOURCE)" \
		--buildtype=release -Ddefault_library=static -Dexamples=true \
		-Dtests=false -Dutils=false -Denable-io-uring=false \
		>"$(MDTEST_LIBFUSE_BUILD_LOG)" 2>&1
	ninja -C "$(MDTEST_LIBFUSE_BUILD)" example/passthrough_ll \
		>>"$(MDTEST_LIBFUSE_BUILD_LOG)" 2>&1
	install -m 0555 "$(MDTEST_LIBFUSE_BUILD)/example/passthrough_ll" "$@"
	readelf -d "$@" >"$(MDTEST_LIBFUSE_BUILD)/passthrough-elf-dynamic.txt"
	! grep -F 'libfuse.so' \
		"$(MDTEST_LIBFUSE_BUILD)/passthrough-elf-dynamic.txt"
	"$@" --version

$(MDTEST_CELL): bench/mdtest/mdtest_cell.c
	$(MAKE) -C "$(ROOT_DIR)/bench/mdtest" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

mdtest-cold-metadata-build: $(MDTEST_BINARY) $(MDTEST_FUSE_BINARY) \
	$(MDTEST_CELL) $(MDTEST_VIRTME_NG_SOURCE_STAMP) kernel-bpftool bpf
	test -x "$(MDTEST_BINARY)"
	test -x "$(MDTEST_FUSE_BINARY)"
	test -x "$(MDTEST_VNG)"
	test -x "$(MDTEST_CELL)"
	test -x "$(MDTEST_BPFTOOL)"
	test -r "$(MDTEST_PASS_POLICY)"
	test -r "$(MDTEST_SELECT_POLICY)"

mdtest-cold-metadata-source-feasibility: mdtest-cold-metadata-build
	rm -rf "$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility"
	install -d "$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility"
	root="$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility"; \
	for ranks in 1 4; do \
		bench="$$root/ranks-$$ranks/bench"; \
		install -d "$$bench"; \
		for phase in create stat remove; do \
			case "$$phase" in create) flag=-C ;; stat) flag=-T ;; remove) flag=-r ;; esac; \
			timeout --signal=TERM --kill-after=10s 120s \
				taskset -c 0-3 mpirun --allow-run-as-root \
				--bind-to core --map-by core --report-bindings \
				-np "$$ranks" "$(MDTEST_BINARY)" -a POSIX -F -u \
				-i 1 -n 64 --warningAsErrors -d "$$bench" "$$flag" \
				>"$$root/ranks-$$ranks/$$phase.stdout" \
				2>"$$root/ranks-$$ranks/$$phase.stderr"; \
			"$(MDTEST_CELL)" --parse-only "$$phase" \
				"$$root/ranks-$$ranks/$$phase.stdout" \
				"$$root/ranks-$$ranks/$$phase.stderr" \
				>"$$root/ranks-$$ranks/$$phase.summary.json"; \
			if test "$$phase" != remove; then \
				test "$$(find "$$bench" -type f | wc -l)" = \
					"$$((ranks * 64))"; \
				test "$$(find "$$bench" -type d | wc -l)" = \
					"$$((ranks + 2))"; \
			else \
				test "$$(find "$$bench" -mindepth 1 | wc -l)" = 0; \
			fi; \
		done; \
	done
	"$(MDTEST_FUSE_BINARY)" --help \
		>"$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility/fuse-help.txt"
	grep -F -- '-o source=/home/dir' \
		"$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility/fuse-help.txt"
	grep -F -- '-o cache=always' \
		"$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility/fuse-help.txt"
	grep -F -- '-o clone_fd' \
		"$(BUILD_ROOT)/mdtest-cold-metadata/source-feasibility/fuse-help.txt"

mdtest-cold-metadata-kernel-pair: kernel kernel-stock kernel-provenance \
	kernel-stock-provenance
	test "$$(cat "$(KERNEL_COMMIT_FILE)")" = \
		"$(MDTEST_EXPECTED_PATCHED_KERNEL_COMMIT)"
	test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = \
		"$(MDTEST_EXPECTED_STOCK_KERNEL_COMMIT)"
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	! grep '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	diff -u \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(KERNEL_BUILD_DIR)/.config") \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config")

mdtest-cold-metadata-analysis-test:
	(cd "$(ROOT_DIR)/analysis/mdtest_cold_metadata" && \
		python3 -m unittest -v)
	python3 "$(ROOT_DIR)/tools/kvm/test_pin_vcpu_affinity.py"
	python3 "$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py"

kvm-mdtest-cold-metadata-preflight kvm-mdtest-cold-metadata-rq2: \
	NAMEI_EXT_REQUIRE_CLEAN = 1

kvm-mdtest-cold-metadata-preflight: experiment-source-clean \
	mdtest-cold-metadata-kernel-pair mdtest-cold-metadata-build \
	mdtest-cold-metadata-source-feasibility \
	mdtest-cold-metadata-analysis-test
	$(call MDTEST_ASSERT_PREFLIGHT_PROTOCOL)
	$(call MDTEST_START_RUN,$(MDTEST_PREFLIGHT_RESULT_DIR),preflight,$(MDTEST_PREFLIGHT_REPETITIONS),$(MDTEST_PREFLIGHT_ITEMS_PER_RANK),make kvm-mdtest-cold-metadata-preflight RUN_ID=$(RUN_ID))
	$(call MDTEST_RUN_MATRIX,$(MDTEST_PREFLIGHT_RESULT_DIR),$(MDTEST_PREFLIGHT_REPETITIONS),$(MDTEST_PREFLIGHT_ITEMS_PER_RANK))
	$(call MDTEST_FINALIZE,$(MDTEST_PREFLIGHT_RESULT_DIR),$(MDTEST_PREFLIGHT_REPETITIONS),preflight,$(MDTEST_PREFLIGHT_ITEMS_PER_RANK))
	$(MAKE) -C "$(ROOT_DIR)" mdtest-cold-metadata-analyze \
		RUN_ID="$(RUN_ID)" \
		MDTEST_ACTIVE_RESULT_DIR="$(MDTEST_PREFLIGHT_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(MDTEST_PREFLIGHT_RESULT_DIR))
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(MDTEST_PREFLIGHT_RESULT_DIR))
	test -s "$(MDTEST_PREFLIGHT_RESULT_DIR)/analysis/summary.json"

kvm-mdtest-cold-metadata-rq2: experiment-source-clean \
	mdtest-cold-metadata-kernel-pair mdtest-cold-metadata-build \
	mdtest-cold-metadata-source-feasibility \
	mdtest-cold-metadata-analysis-test
	$(call MDTEST_ASSERT_FORMAL_PROTOCOL)
	$(call MDTEST_START_RUN,$(MDTEST_RESULT_DIR),formal,$(MDTEST_FORMAL_REPETITIONS),$(MDTEST_FORMAL_ITEMS_PER_RANK),make experiment-mdtest-cold-metadata-rq2 RUN_ID=$(RUN_ID))
	$(call MDTEST_RUN_MATRIX,$(MDTEST_RESULT_DIR),$(MDTEST_FORMAL_REPETITIONS),$(MDTEST_FORMAL_ITEMS_PER_RANK))
	$(call MDTEST_FINALIZE,$(MDTEST_RESULT_DIR),$(MDTEST_FORMAL_REPETITIONS),formal,$(MDTEST_FORMAL_ITEMS_PER_RANK))
	$(MAKE) -C "$(ROOT_DIR)" mdtest-cold-metadata-analyze \
		RUN_ID="$(RUN_ID)" MDTEST_ACTIVE_RESULT_DIR="$(MDTEST_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(MDTEST_RESULT_DIR))
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(MDTEST_RESULT_DIR))
	test -s "$(MDTEST_RESULT_DIR)/analysis/summary.json"

mdtest-cold-metadata-analyze:
	result="$(MDTEST_ACTIVE_RESULT_DIR)"; \
	test -n "$$result"; \
	jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' \
		"$$result/run.json" >/dev/null; \
	analysis="$$result/analysis"; \
	test ! -e "$$analysis"; \
	rm -rf "$$analysis.tmp"; \
	python3 "$(MDTEST_ANALYSIS)" \
		--input "$$result/observations.jsonl" \
		--run "$$result/run.json" \
		--output "$$analysis.tmp" \
		--seed "$(MDTEST_ANALYSIS_SEED)"; \
	for file in summary.json summary.csv report.md normalized-throughput.png \
			normalized-throughput.pdf; do \
		test -s "$$analysis.tmp/$$file"; \
	done; \
	jq -e '.schema == "namei_ext.mdtest_cold_metadata.analysis.v1" and (.verdict.verdict == "diagnostic-only" or .verdict.verdict == "positive" or .verdict.verdict == "contradicted" or .verdict.verdict == "mixed")' \
		"$$analysis.tmp/summary.json" >/dev/null; \
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$$analysis)

experiment-mdtest-cold-metadata-rq2: kvm-mdtest-cold-metadata-rq2
	jq -e '.status == "completed"' "$(MDTEST_RESULT_DIR)/run.json" >/dev/null
	jq -e '.schema == "namei_ext.mdtest_cold_metadata.analysis.v1" and (.verdict.verdict == "positive" or .verdict.verdict == "contradicted" or .verdict.verdict == "mixed")' \
		"$(MDTEST_RESULT_DIR)/analysis/summary.json" >/dev/null

__mdtest_cold_metadata_guest:
	test -n "$(CONDITION)"
	test -n "$(REPETITION)"
	test -n "$(MDTEST_RUN_ITEMS)"
	test -x "$(MDTEST_RUN_BINARY)"
	test -x "$(MDTEST_RUN_FUSE)"
	test -x "$(MDTEST_RUN_CELL)"
	test -x "$(MDTEST_RUN_BPFTOOL)"
	test -r "$(MDTEST_RUN_PASS_POLICY)"
	test -r "$(MDTEST_RUN_SELECT_POLICY)"
	test -d "$(MDTEST_BOOT_RESULT_DIR)"
	affinity_status=waiting; \
	for attempt in $$(seq 1 "$$(( $(MDTEST_AFFINITY_BARRIER_TIMEOUT) * 20 ))"); do \
		if test -s "$(MDTEST_BOOT_RESULT_DIR)/vcpu-affinity.json"; then \
			if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified"' \
					"$(MDTEST_BOOT_RESULT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
				affinity_status=verified; \
				break; \
			fi; \
			if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "failed"' \
					"$(MDTEST_BOOT_RESULT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
				cat "$(MDTEST_BOOT_RESULT_DIR)/vcpu-affinity.json" >&2; \
				exit 1; \
			fi; \
		fi; \
		sleep 0.05; \
	done; \
	test "$$affinity_status" = verified; \
	affinity_verified_at=$$(jq -r '.verified_at' \
		"$(MDTEST_BOOT_RESULT_DIR)/vcpu-affinity.json"); \
	printf '%s\n' "$$affinity_verified_at" \
		>"$(MDTEST_BOOT_RESULT_DIR)/affinity-verified-at.txt"; \
	date -u +%Y-%m-%dT%H:%M:%S.%NZ \
		>"$(MDTEST_BOOT_RESULT_DIR)/affinity-barrier.txt"
	install -d "$(MDTEST_BOOT_RESULT_DIR)/raw"
		if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
		if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
		if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
		test ! -e "$(MDTEST_GUEST_WORK_ROOT)"
		$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,\
			$(MDTEST_BOOT_RESULT_DIR),$(MDTEST_RUN_BPFTOOL),before)
		jq -e 'type == "array" and length == 0' \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-programs-before.json" >/dev/null
		jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-cgroup-before.json" >/dev/null
		test ! -s "$(MDTEST_BOOT_RESULT_DIR)/fuse-mounts-before.txt"
	test ! -s "$(MDTEST_BOOT_RESULT_DIR)/fuse-open-fds-before.txt"
	printf '0\n' >/proc/sys/kernel/bpf_stats_enabled
	: >"$(MDTEST_BOOT_RESULT_DIR)/observations.jsonl"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,\
		$(MDTEST_BOOT_RESULT_DIR),$(MDTEST_BOOT_KERNEL_CONFIG),\
		$(MDTEST_BOOT_KERNEL_COMMIT),$(MDTEST_BOOT_KERNEL_RELEASE))
	if grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms; then \
		actual_flavor=patched; \
	else \
		actual_flavor=stock; \
	fi; \
	test "$$actual_flavor" = "$(MDTEST_BOOT_KERNEL_FLAVOR)"; \
	printf '%s\n' "$$actual_flavor" \
		>"$(MDTEST_BOOT_RESULT_DIR)/kernel-flavor.txt"
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = tsc; \
	printf '%s\n' "$$clocksource" \
		>"$(MDTEST_BOOT_RESULT_DIR)/clocksource-before.txt"
	cat /proc/stat >"$(MDTEST_BOOT_RESULT_DIR)/proc-stat-before.txt"
	cat /proc/meminfo >"$(MDTEST_BOOT_RESULT_DIR)/meminfo-before.txt"
	policy=-; \
	case "$(CONDITION)" in \
	pass) policy="$(MDTEST_RUN_PASS_POLICY)" ;; \
	select) policy="$(MDTEST_RUN_SELECT_POLICY)" ;; \
	stock|unattached|fuse) ;; \
	*) exit 1 ;; \
	esac; \
	if test "$$(( $(REPETITION) % 2 ))" = 1; then ranks_order="1 4"; else ranks_order="4 1"; fi; \
	for ranks in $$ranks_order; do \
		"$(MDTEST_RUN_CELL)" "$(CONDITION)" "$(MDTEST_RUN_BINARY)" \
			"$(MDTEST_RUN_FUSE)" "$$policy" \
			"$(MDTEST_BOOT_RESULT_DIR)/observations.jsonl" \
			"$(MDTEST_BOOT_RESULT_DIR)/raw/ranks-$$ranks" \
			"$(MDTEST_GUEST_WORK_ROOT)" /sys/fs/cgroup "$$ranks" \
			"$(MDTEST_RUN_ITEMS)" "$(REPETITION)" \
			"$(MDTEST_PHASE_TIMEOUT)" "$(MDTEST_FUSE_TIMEOUT)" \
				"$(MDTEST_TMPFS_SIZE)" "$(MDTEST_EXT4_IMAGE_SIZE)" \
				"$(MDTEST_EXT4_INODES)"; \
		done
		rmdir "$(MDTEST_GUEST_WORK_ROOT)"
		test "$$(jq -s 'length' "$(MDTEST_BOOT_RESULT_DIR)/observations.jsonl")" = 6
	jq -s -e 'all(.[]; .pass == true and .cleanup_complete == true)' \
		"$(MDTEST_BOOT_RESULT_DIR)/observations.jsonl" >/dev/null
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,\
		$(MDTEST_BOOT_RESULT_DIR),$(MDTEST_RUN_BPFTOOL),after)
		jq -e 'type == "array" and length == 0' \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-programs-after.json" >/dev/null
		jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-cgroup-after.json" >/dev/null
		cmp "$(MDTEST_BOOT_RESULT_DIR)/bpf-programs-before.json" \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-programs-after.json"
		cmp "$(MDTEST_BOOT_RESULT_DIR)/bpf-cgroup-before.json" \
			"$(MDTEST_BOOT_RESULT_DIR)/bpf-cgroup-after.json"
	test ! -s "$(MDTEST_BOOT_RESULT_DIR)/fuse-mounts-after.txt"
	test ! -s "$(MDTEST_BOOT_RESULT_DIR)/fuse-open-fds-after.txt"
	test "$$(cat "$(MDTEST_BOOT_RESULT_DIR)/fuse-open-fds-before.status")" = 1
	test "$$(cat "$(MDTEST_BOOT_RESULT_DIR)/fuse-open-fds-after.status")" = 1
	printf '0\n' >/proc/sys/kernel/bpf_stats_enabled
	cat /proc/stat >"$(MDTEST_BOOT_RESULT_DIR)/proc-stat-after.txt"
	cat /proc/meminfo >"$(MDTEST_BOOT_RESULT_DIR)/meminfo-after.txt"
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = "$$(cat "$(MDTEST_BOOT_RESULT_DIR)/clocksource-before.txt")"; \
	printf '%s\n' "$$clocksource" \
		>"$(MDTEST_BOOT_RESULT_DIR)/clocksource-after.txt"
	dmesg >"$(MDTEST_BOOT_RESULT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(MDTEST_BOOT_RESULT_DIR)/dmesg.log)
	completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
	jq -n \
		--arg schema "namei_ext.mdtest_cold_metadata.boot.v1" \
		--arg condition "$(CONDITION)" \
		--argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(MDTEST_BOOT_KERNEL_COMMIT)" \
		--arg kernel_flavor "$(MDTEST_BOOT_KERNEL_FLAVOR)" \
		--arg kernel_release "$$(cat "$(MDTEST_BOOT_RESULT_DIR)/kernel-release.txt")" \
		--arg clocksource "$$(cat "$(MDTEST_BOOT_RESULT_DIR)/clocksource-after.txt")" \
		--arg completed_at "$$completed_at" \
		'{schema:$$schema,status:"completed",condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_flavor:$$kernel_flavor,kernel_release:$$kernel_release,clocksource:$$clocksource,observation_count:6,completed_at:$$completed_at}' \
		>"$(MDTEST_BOOT_RESULT_DIR)/boot.json"
