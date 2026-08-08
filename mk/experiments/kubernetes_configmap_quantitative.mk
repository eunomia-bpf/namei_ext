KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD ?= \
	$(BUILD_ROOT)/kubernetes-configmap-quantitative
KUBERNETES_CONFIGMAP_QUANTITATIVE_CONSUMER ?= \
	$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/configmap-consumer
KUBERNETES_CONFIGMAP_QUANTITATIVE_RUNNER ?= \
	$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/namei-ext-configmap-quantitative
KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE ?= \
	$(ROOT_DIR)/experiments/kubernetes_configmap_quantitative/atomic_writer_quantitative_driver.go
KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/atomic-writer-quantitative-driver
KUBERNETES_CONFIGMAP_QUANTITATIVE_POLICY ?= \
	$(BUILD_ROOT)/bpf/kubernetes_configmap_publication.bpf.o
KUBERNETES_CONFIGMAP_QUANTITATIVE_ANALYZER ?= \
	$(ROOT_DIR)/analysis/kubernetes_configmap_quantitative/analyze.py
KUBERNETES_CONFIGMAP_QUANTITATIVE_VALIDATOR ?= \
	$(ROOT_DIR)/analysis/kubernetes_configmap_quantitative/validate.py
KUBERNETES_CONFIGMAP_QUANTITATIVE_SOURCE_METADATA ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/quantitative-source-metadata.json

KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER): \
		$(KUBERNETES_CONFIGMAP_SOURCE_READY) \
		$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE)
	cd "$(KUBERNETES_CONFIGMAP_SOURCE)" && \
		CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor \
		go build -o "$@" \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE)"

$(KUBERNETES_CONFIGMAP_QUANTITATIVE_SOURCE_METADATA): \
		$(KUBERNETES_CONFIGMAP_SOURCE_METADATA) \
		$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER) \
		$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE)
	jq \
		--arg adapter experiments/kubernetes_configmap_quantitative/atomic_writer_quantitative_driver.go \
		--arg adapter_command 'cd $(KUBERNETES_CONFIGMAP_SOURCE) && CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor go build -o $(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER) $(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE)' \
		'.suite = "kubernetes-configmap-quantitative" | .adapter = $$adapter | .build.adapter_command = $$adapter_command' \
		"$<" >"$@.tmp"
	mv -f "$@.tmp" "$@"

define KUBERNETES_CONFIGMAP_QUANTITATIVE_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_CONSUMER)" \
	"$(1)/artifacts/runtime/configmap-consumer"
install -m 0555 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUNNER)" \
	"$(1)/artifacts/runtime/namei-ext-configmap-quantitative"
install -m 0555 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER)" \
	"$(1)/artifacts/runtime/atomic-writer-quantitative-driver"
install -m 0444 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_POLICY)" \
	"$(1)/artifacts/runtime/kubernetes_configmap_publication.bpf.o"
install -m 0555 "$(KUBERNETES_CONFIGMAP_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0444 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_SOURCE_METADATA)" \
	"$(1)/artifacts/source/source-metadata.json"
install -m 0444 "$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG)" \
	"$(1)/artifacts/source/atomic-writer-tests.log"
install -m 0444 \
	"$(KUBERNETES_CONFIGMAP_SOURCE)/pkg/volume/util/atomic_writer.go" \
	"$(1)/artifacts/source/atomic_writer.go"
install -m 0444 \
	"$(KUBERNETES_CONFIGMAP_SOURCE)/pkg/volume/util/atomic_writer_test.go" \
	"$(1)/artifacts/source/atomic_writer_test.go"
install -m 0444 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER_SOURCE)" \
	"$(1)/artifacts/source/atomic_writer_quantitative_driver.go"
install -m 0444 \
	"$(ROOT_DIR)/experiments/kubernetes_configmap_quantitative/configmap_consumer.c" \
	"$(1)/artifacts/source/configmap_consumer.c"
install -m 0444 \
	"$(ROOT_DIR)/experiments/kubernetes_configmap_quantitative/namei_ext_configmap_quantitative.c" \
	"$(1)/artifacts/source/namei_ext_configmap_quantitative.c"
install -m 0444 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ANALYZER)" \
	"$(1)/artifacts/source/analyze.py"
install -m 0444 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_VALIDATOR)" \
	"$(1)/artifacts/source/validate.py"
jq -n \
	--arg kernel_image artifacts/kernel/bzImage \
	--arg kernel_config artifacts/kernel/config \
	--arg consumer artifacts/runtime/configmap-consumer \
	--arg runner artifacts/runtime/namei-ext-configmap-quantitative \
	--arg source_driver artifacts/runtime/atomic-writer-quantitative-driver \
	--arg policy artifacts/runtime/kubernetes_configmap_publication.bpf.o \
	--arg bpftool artifacts/runtime/bpftool \
	--arg source_metadata artifacts/source/source-metadata.json \
	'{kernel:{image:$$kernel_image,config:$$kernel_config},runtime:{consumer:$$consumer,runner:$$runner,source_driver:$$source_driver,policy:$$policy,bpftool:$$bpftool},source:{metadata:$$source_metadata,atomic_writer:"artifacts/source/atomic_writer.go",atomic_writer_test:"artifacts/source/atomic_writer_test.go",upstream_test_log:"artifacts/source/atomic-writer-tests.log",analyzer:"artifacts/source/analyze.py",validator:"artifacts/source/validate.py"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define KUBERNETES_CONFIGMAP_QUANTITATIVE_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),kubernetes-configmap-quantitative,Kubernetes-AtomicWriter-vs-namei_ext,kvm_kubernetes_configmap_quantitative,$(1)/observations.jsonl,kubernetes_configmap_publication.bpf.c,configmap-consumer+atomic-writer-quantitative-driver+namei-ext-configmap-quantitative)
$(call KUBERNETES_CONFIGMAP_QUANTITATIVE_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson boots "$(2)" \
	--argjson pairs "$(3)" \
	--arg scales "$(4)" \
	'.layout = "paired-two-known-generation-configmap-lifecycle" | .matrix = {baseline:"Kubernetes-v1.30.0-AtomicWriter",proposed:"namei_ext",states:["initial","update","no-op","rollback"],boots:$$boots,pairs_per_scale_per_boot:$$pairs,scales:($$scales | split(" ") | map(select(length > 0) | tonumber)),all_rows_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(5)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

.PHONY: kubernetes-configmap-quantitative \
	kubernetes-configmap-quantitative-source \
	kubernetes-configmap-quantitative-analysis-test \
	kubernetes-configmap-quantitative-host-test \
	kubernetes-configmap-quantitative-host-failure-test \
	kvm-kubernetes-configmap-quantitative-preflight \
	kvm-kubernetes-configmap-quantitative \
	kubernetes-configmap-quantitative-run \
	kubernetes-configmap-quantitative-finalize \
	kubernetes-configmap-quantitative-analyze \
	experiment-kubernetes-configmap-quantitative \
	__kubernetes_configmap_quantitative_guest \
	__kubernetes_configmap_quantitative_guest_inner

kubernetes-configmap-quantitative:
	$(MAKE) -C "$(ROOT_DIR)/experiments/kubernetes_configmap_quantitative" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

kubernetes-configmap-quantitative-source: \
	$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER) \
	$(KUBERNETES_CONFIGMAP_QUANTITATIVE_SOURCE_METADATA)
	jq -e --arg commit "$(KUBERNETES_CONFIGMAP_COMMIT)" \
		'.suite == "kubernetes-configmap-quantitative" and .commit == $$commit and .adapter == "experiments/kubernetes_configmap_quantitative/atomic_writer_quantitative_driver.go" and .upstream_tests == ["TestWriteOnce","TestUpdate","TestMultipleUpdates"]' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_SOURCE_METADATA)" >/dev/null

kubernetes-configmap-quantitative-analysis-test:
	cd "$(ROOT_DIR)/analysis/kubernetes_configmap_quantitative" && \
		python3 -m unittest -v

kubernetes-configmap-quantitative-host-test: \
		kubernetes-configmap-quantitative \
		kubernetes-configmap-quantitative-source
	rm -rf "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test"
	install -d "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/sample"
	"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER)" \
		timed \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/observations.jsonl" \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_CONSUMER)" \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/sample" \
		16 1 1 1
	"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER)" \
		audit \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/observations.jsonl" \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/sample" \
		16 1 1
	rmdir "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/sample"
	PYTHONPATH="$(ROOT_DIR)/analysis/kubernetes_configmap_quantitative" \
		python3 -c 'import json,sys,validate; rows=[json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]; validate.validate_lifecycle(rows[0]); validate.validate_atomicwriter(rows[0], rows[1:])' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-test/observations.jsonl"

kubernetes-configmap-quantitative-host-failure-test: \
		kubernetes-configmap-quantitative-source
	rm -rf "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test"
	install -d "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test/sample"
	if "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_DRIVER)" \
		timed \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test/observations.jsonl" \
		/bin/false \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test/sample" \
		16 1 1 1; then exit 1; fi
	test "$$(find "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test/sample" -mindepth 1 -print -quit | wc -l)" = 0
	jq -s -e 'length == 1 and .[0] as $$row | $$row.pass == false and $$row.cleanup_pass == true and ($$row.error | length) > 0 and $$row.consumer_exit_status != 0 and $$row.cleanup_root_absent == true and $$row.cleanup_root_remove_error == 0 and $$row.cleanup_root_stat_error == 2 and $$row.cleanup_parent_read_error == 0 and $$row.cleanup_parent_entries == []' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BUILD)/host-failure-test/observations.jsonl" >/dev/null

kvm-kubernetes-configmap-quantitative-preflight: \
		experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		kubernetes-configmap-quantitative \
		kubernetes-configmap-quantitative-source
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_BOOTS)" = 1
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_PAIRS)" = 2
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_SCALES)" = 16
	$(call KUBERNETES_CONFIGMAP_QUANTITATIVE_START,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_RESULT_DIR),1,2,16,make kvm-kubernetes-configmap-quantitative-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-run \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS=1 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS=2 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES="16"
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-finalize \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS=1 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS=2 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES="16"
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-analyze \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PREFLIGHT_RESULT_DIR))

kvm-kubernetes-configmap-quantitative: \
		experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		kubernetes-configmap-quantitative \
		kubernetes-configmap-quantitative-source
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOTS)" = 20
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_PAIRS)" = 5
	test "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_SCALES)" = "4 16 64 256"
	$(call KUBERNETES_CONFIGMAP_QUANTITATIVE_START,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RESULT_DIR),20,5,4 16 64 256,make experiment-kubernetes-configmap-quantitative RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-run \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS=20 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS=5 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES="4 16 64 256"
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-finalize \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS=20 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS=5 \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES="4 16 64 256"
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-quantitative-analyze \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RESULT_DIR))

experiment-kubernetes-configmap-quantitative: \
	kvm-kubernetes-configmap-quantitative

kubernetes-configmap-quantitative-run:
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS)"
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/run.json" >/dev/null
	test ! -e "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/execution-started"; \
		test ! -s "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/expected-boots.txt"; \
		test "$$(find "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/boots" -mindepth 1 -print -quit | wc -l)" = 0; \
		: >"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/execution-started"
	for boot_index in $$(seq 1 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS)"); do \
		printf '%s\n' "$$boot_index" \
			>>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$boot_index")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__kubernetes_configmap_quantitative_guest KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_INDEX=$$boot_index KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR=$${boot#$(ROOT_DIR)/} KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR=$${KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR#$(ROOT_DIR)/} KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS=$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS) KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES='$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES)'" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_KVM_TIMEOUT)"; \
	done

kubernetes-configmap-quantitative-finalize:
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES)"
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/run.json" >/dev/null
	test -f "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/execution-started"; \
		test ! -e "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/finalization-started"; \
		: >"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/finalization-started"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS))
	! jq -e 'select(.pass != true)' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/observations.jsonl" >/dev/null
	python3 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/artifacts/source/validate.py" \
		--run-dir "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_BOOTS),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' "$$boot/boot.json" >/dev/null; \
		$(call KUBERNETES_CONFIGMAP_VALIDATE_EXTERNAL,$$boot,before); \
		$(call KUBERNETES_CONFIGMAP_VALIDATE_EXTERNAL,$$boot,after); \
		test "$$(find "$$boot/logs" -type f -name '*.stderr.log' -size +0c -print -quit | wc -l)" = 0; \
		test ! -s "$$boot/launcher.stderr.log"; \
	done < <(find "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)

kubernetes-configmap-quantitative-analyze:
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)"
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/run.json" >/dev/null
	test -f "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/finalization-started"; \
		test ! -e "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/analysis-started"; \
		test ! -e "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/analysis"; \
		: >"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/analysis-started"
	python3 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)/artifacts/source/analyze.py" \
		--run-dir "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_DIR)"

__kubernetes_configmap_quantitative_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__kubernetes_configmap_quantitative_guest_inner \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_INDEX="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_INDEX)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS)" \
		KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/dmesg.log" || dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/dmesg.log) || dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/guest-dmesg.status"; \
	status=completed; \
	if test "$$inner_status" -ne 0 || test "$$inventory_after_status" -ne 0 || test "$$dmesg_status" -ne 0; then status=failed; fi; \
	jq -n --arg status "$$status" --argjson inner_status "$$inner_status" \
		--argjson inventory_after_status "$$inventory_after_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__kubernetes_configmap_quantitative_guest_inner:
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_INDEX)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS)"
	test -n "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES)"
	test -x "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/configmap-consumer"
	test -x "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/atomic-writer-quantitative-driver"
	test -x "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/namei-ext-configmap-quantitative"
	test -r "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/kubernetes_configmap_publication.bpf.o"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR),$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/bpftool,before)
	: >"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/observations.jsonl"
	install -d "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs" \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/samples"
	boot_index="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_INDEX)"; \
	runtime_uid="$$(stat -c %u "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)")"; \
	runtime_gid="$$(stat -c %g "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)")"; \
	test "$$runtime_uid" -gt 0; test "$$runtime_gid" -gt 0; \
	scales=( $(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_SCALES) ); \
	scale_count="$${#scales[@]}"; \
	start_index=$$(( (boot_index - 1) % scale_count )); \
	run_condition() { \
		mechanism="$$1"; scale="$$2"; pair="$$3"; order="$$4"; \
		label="w$${scale}-p$${pair}-o$${order}-$${mechanism}"; \
		parent="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/samples/$$label"; \
		install -d "$$parent"; \
		chown "$$runtime_uid:$$runtime_gid" "$$parent"; \
		if test "$$mechanism" = atomicwriter; then \
			"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/atomic-writer-quantitative-driver" \
				timed \
				"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/observations.jsonl" \
				"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/configmap-consumer" \
				"$$parent" "$$scale" "$$boot_index" "$$pair" "$$order" \
				>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stdout.log" \
				2>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stderr.log"; \
		else \
			"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/namei-ext-configmap-quantitative" \
				"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/kubernetes_configmap_publication.bpf.o" \
				"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/configmap-consumer" \
				"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/observations.jsonl" \
				"$$parent" /sys/fs/cgroup "$$scale" "$$boot_index" "$$pair" "$$order" \
				>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stdout.log" \
				2>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stderr.log"; \
		fi; \
		rmdir "$$parent"; \
	}; \
	run_audit() { \
		scale="$$1"; pair="$$2"; label="w$${scale}-p$${pair}-atomicwriter-audit"; \
		parent="$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/samples/$$label"; \
		install -d "$$parent"; chown "$$runtime_uid:$$runtime_gid" "$$parent"; \
		"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_RUN_DIR)/artifacts/runtime/atomic-writer-quantitative-driver" \
			audit "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/observations.jsonl" \
			"$$parent" "$$scale" "$$boot_index" "$$pair" \
			>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stdout.log" \
			2>"$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/logs/$$label.stderr.log"; \
		rmdir "$$parent"; \
	}; \
	for ((offset=0; offset<scale_count; offset++)); do \
		scale="$${scales[$$(( (start_index + offset) % scale_count ))]}"; \
		for pair in $$(seq 1 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS)"); do \
			if test $$(( (boot_index + pair) % 2 )) -eq 0; then first=atomicwriter; second=namei_ext; else first=namei_ext; second=atomicwriter; fi; \
			run_condition "$$first" "$$scale" "$$pair" 1; \
			run_condition "$$second" "$$scale" "$$pair" 2; \
			done; \
		done; \
	for scale in "$${scales[@]}"; do \
		for pair in $$(seq 1 "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_ACTIVE_PAIRS)"); do \
			run_audit "$$scale" "$$pair"; \
		done; \
	done
	test "$$(find "$(KUBERNETES_CONFIGMAP_QUANTITATIVE_BOOT_DIR)/samples" -mindepth 1 -print -quit | wc -l)" = 0
