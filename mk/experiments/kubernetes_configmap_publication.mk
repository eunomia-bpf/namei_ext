KUBERNETES_CONFIGMAP_POLICY ?= \
	$(BUILD_ROOT)/bpf/kubernetes_configmap_publication.bpf.o
KUBERNETES_CONFIGMAP_RUNNER ?= \
	$(BUILD_ROOT)/kubernetes-configmap-publication/namei_ext_kubernetes_configmap_publication
KUBERNETES_CONFIGMAP_DRIVER_SOURCE ?= \
	$(ROOT_DIR)/experiments/kubernetes_configmap_publication/atomic_writer_driver.go
KUBERNETES_CONFIGMAP_WORKLOAD_ROOT ?= \
	$(BUILD_ROOT)/workloads/kubernetes-configmap-publication
KUBERNETES_CONFIGMAP_ARCHIVE ?= \
	$(CACHE_ROOT)/workloads/kubernetes-$(KUBERNETES_CONFIGMAP_COMMIT).tar.gz
KUBERNETES_CONFIGMAP_SOURCE ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/source
KUBERNETES_CONFIGMAP_SOURCE_READY ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/source.ready
KUBERNETES_CONFIGMAP_UPSTREAM_TEST ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/volume-util.test
KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/atomic-writer-tests.log
KUBERNETES_CONFIGMAP_DRIVER ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/atomic-writer-driver
KUBERNETES_CONFIGMAP_SOURCE_METADATA ?= \
	$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/source-metadata.json
KUBERNETES_CONFIGMAP_BPFTOOL ?= $(KERNEL_BPFTOOL)
KUBERNETES_CONFIGMAP_SUITE_MAKE ?= \
	$(ROOT_DIR)/mk/experiments/kubernetes_configmap_publication.mk

KUBERNETES_CONFIGMAP_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	source-tree-initial.tsv source-tree-update.tsv \
	source-tree-no-op.tsv source-tree-rollback.tsv \
	lower-before.tsv lower-after.tsv \
	cat-physical-v0.stdout.log cat-physical-v0.stderr.log \
	cat-physical-v1.stdout.log cat-physical-v1.stderr.log \
	cat-initial.stdout.log cat-initial.stderr.log \
	cat-update.stdout.log cat-update.stderr.log \
	cat-no-op.stdout.log cat-no-op.stderr.log \
	cat-rollback.stdout.log cat-rollback.stderr.log \
	source-driver.stdout.log source-driver.stderr.log \
	namei-runner.stdout.log namei-runner.stderr.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

$(KUBERNETES_CONFIGMAP_ARCHIVE):
	install -d "$(dir $@)"
	rm -f "$@.tmp"
	curl --fail --location --retry 3 --output "$@.tmp" \
		"$(KUBERNETES_CONFIGMAP_ARCHIVE_URL)"
	test -s "$@.tmp"
	mv -f "$@.tmp" "$@"

$(KUBERNETES_CONFIGMAP_SOURCE_READY): $(KUBERNETES_CONFIGMAP_ARCHIVE)
	rm -rf "$(KUBERNETES_CONFIGMAP_SOURCE).tmp" \
		"$(KUBERNETES_CONFIGMAP_SOURCE)"
	install -d "$(KUBERNETES_CONFIGMAP_SOURCE).tmp"
	tar -xf "$<" -C "$(KUBERNETES_CONFIGMAP_SOURCE).tmp"
	test -f "$(KUBERNETES_CONFIGMAP_SOURCE).tmp/kubernetes-$(KUBERNETES_CONFIGMAP_COMMIT)/pkg/volume/util/atomic_writer.go"
	test -f "$(KUBERNETES_CONFIGMAP_SOURCE).tmp/kubernetes-$(KUBERNETES_CONFIGMAP_COMMIT)/pkg/volume/util/atomic_writer_test.go"
	test -d "$(KUBERNETES_CONFIGMAP_SOURCE).tmp/kubernetes-$(KUBERNETES_CONFIGMAP_COMMIT)/vendor"
	mv "$(KUBERNETES_CONFIGMAP_SOURCE).tmp/kubernetes-$(KUBERNETES_CONFIGMAP_COMMIT)" \
		"$(KUBERNETES_CONFIGMAP_SOURCE)"
	rmdir "$(KUBERNETES_CONFIGMAP_SOURCE).tmp"
	touch "$@"

$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST): $(KUBERNETES_CONFIGMAP_SOURCE_READY)
	cd "$(KUBERNETES_CONFIGMAP_SOURCE)" && \
		CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor \
		go test -c -o "$@" ./pkg/volume/util

$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG): $(KUBERNETES_CONFIGMAP_UPSTREAM_TEST)
	"$<" -test.v \
		-test.run '^(TestWriteOnce|TestUpdate|TestMultipleUpdates)$$' \
		>"$@" 2>&1
	grep -F -- '--- PASS: TestWriteOnce' "$@" >/dev/null
	grep -F -- '--- PASS: TestUpdate' "$@" >/dev/null
	grep -F -- '--- PASS: TestMultipleUpdates' "$@" >/dev/null
	grep -F -- 'PASS' "$@" >/dev/null

$(KUBERNETES_CONFIGMAP_DRIVER): \
		$(KUBERNETES_CONFIGMAP_SOURCE_READY) \
		$(KUBERNETES_CONFIGMAP_DRIVER_SOURCE)
	cd "$(KUBERNETES_CONFIGMAP_SOURCE)" && \
		CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor \
		go build -o "$@" "$(KUBERNETES_CONFIGMAP_DRIVER_SOURCE)"

$(KUBERNETES_CONFIGMAP_SOURCE_METADATA): \
		$(KUBERNETES_CONFIGMAP_SOURCE_READY) \
		$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG) \
		$(KUBERNETES_CONFIGMAP_DRIVER) \
		$(KUBERNETES_CONFIGMAP_SUITE_MAKE)
	go version >"$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/go-version.txt"
	jq -n \
		--arg source_system kubernetes \
		--arg version "$(KUBERNETES_CONFIGMAP_VERSION)" \
		--arg commit "$(KUBERNETES_CONFIGMAP_COMMIT)" \
		--arg archive_url "$(KUBERNETES_CONFIGMAP_ARCHIVE_URL)" \
		--arg go_version "$$(cat "$(KUBERNETES_CONFIGMAP_WORKLOAD_ROOT)/go-version.txt")" \
		--arg package k8s.io/kubernetes/pkg/volume/util \
		--arg source_file pkg/volume/util/atomic_writer.go \
		--arg test_file pkg/volume/util/atomic_writer_test.go \
		--arg tests TestWriteOnce,TestUpdate,TestMultipleUpdates \
		--arg adapter_build 'cd $(KUBERNETES_CONFIGMAP_SOURCE) && CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor go build -o $(KUBERNETES_CONFIGMAP_DRIVER) $(KUBERNETES_CONFIGMAP_DRIVER_SOURCE)' \
		--arg test_build 'cd $(KUBERNETES_CONFIGMAP_SOURCE) && CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=vendor go test -c -o $(KUBERNETES_CONFIGMAP_UPSTREAM_TEST) ./pkg/volume/util' \
		--arg test_run "$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST) -test.v -test.run '^(TestWriteOnce|TestUpdate|TestMultipleUpdates)$$'" \
		'{source_system:$$source_system,version:$$version,commit:$$commit,archive_url:$$archive_url,go_version:$$go_version,package:$$package,source_file:$$source_file,test_file:$$test_file,upstream_tests:($$tests | split(",")),adapter:"experiments/kubernetes_configmap_publication/atomic_writer_driver.go",build:{module_mode:"vendor",cgo:false,adapter_command:$$adapter_build,upstream_test_build_command:$$test_build,upstream_test_run_command:$$test_run}}' \
		>"$@"

define KUBERNETES_CONFIGMAP_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(KUBERNETES_CONFIGMAP_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_kubernetes_configmap_publication"
install -m 0444 "$(KUBERNETES_CONFIGMAP_POLICY)" \
	"$(1)/artifacts/runtime/kubernetes_configmap_publication.bpf.o"
install -m 0555 "$(KUBERNETES_CONFIGMAP_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0555 "$(KUBERNETES_CONFIGMAP_DRIVER)" \
	"$(1)/artifacts/runtime/atomic-writer-driver"
install -m 0444 "$(KUBERNETES_CONFIGMAP_SOURCE_METADATA)" \
	"$(1)/artifacts/source/source-metadata.json"
install -m 0444 "$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG)" \
	"$(1)/artifacts/source/atomic-writer-tests.log"
install -m 0444 \
	"$(KUBERNETES_CONFIGMAP_SOURCE)/pkg/volume/util/atomic_writer.go" \
	"$(1)/artifacts/source/atomic_writer.go"
install -m 0444 \
	"$(KUBERNETES_CONFIGMAP_SOURCE)/pkg/volume/util/atomic_writer_test.go" \
	"$(1)/artifacts/source/atomic_writer_test.go"
install -m 0444 "$(KUBERNETES_CONFIGMAP_DRIVER_SOURCE)" \
	"$(1)/artifacts/source/atomic_writer_driver.go"
jq -n \
	--arg kernel_image artifacts/kernel/bzImage \
	--arg kernel_config artifacts/kernel/config \
	--arg runner artifacts/runtime/namei_ext_kubernetes_configmap_publication \
	--arg policy artifacts/runtime/kubernetes_configmap_publication.bpf.o \
	--arg bpftool artifacts/runtime/bpftool \
	--arg source_driver artifacts/runtime/atomic-writer-driver \
	--arg source_metadata artifacts/source/source-metadata.json \
	--arg source_tests artifacts/source/atomic-writer-tests.log \
	'{kernel:{image:$$kernel_image,config:$$kernel_config},runtime:{runner:$$runner,policy:$$policy,bpftool:$$bpftool,source_driver:$$source_driver},source:{metadata:$$source_metadata,upstream_tests:$$source_tests}}' \
	>"$(1)/artifacts/manifest.json"
endef

define KUBERNETES_CONFIGMAP_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),kubernetes-configmap-publication,Kubernetes-AtomicWriter,kvm_kubernetes_configmap_publication_rq1,$(1)/observations.jsonl,kubernetes_configmap_publication.bpf.c,namei_ext_kubernetes_configmap_publication+atomic_writer_driver)
$(call KUBERNETES_CONFIGMAP_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.layout = "fresh-boot-source-control-stable-root-select-hide-update-no-op-rollback" | .matrix = {source_control:"Kubernetes-v1.30.0-AtomicWriter",states:["initial","update","no-op","rollback"],repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define KUBERNETES_CONFIGMAP_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

.PHONY: kubernetes-configmap-publication \
	kubernetes-configmap-publication-source \
	kvm-kubernetes-configmap-publication-rq1-preflight \
	kvm-kubernetes-configmap-publication-rq1 \
	kubernetes-configmap-publication-run \
	kubernetes-configmap-publication-finalize \
	kubernetes-configmap-publication-analyze \
	experiment-kubernetes-configmap-publication-rq1 \
	__kubernetes_configmap_publication_guest \
	__kubernetes_configmap_publication_guest_inner

kubernetes-configmap-publication:
	$(MAKE) -C "$(ROOT_DIR)/experiments/kubernetes_configmap_publication" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

kubernetes-configmap-publication-source: \
		$(KUBERNETES_CONFIGMAP_DRIVER) \
		$(KUBERNETES_CONFIGMAP_UPSTREAM_TEST_LOG) \
		$(KUBERNETES_CONFIGMAP_SOURCE_METADATA)

kvm-kubernetes-configmap-publication-rq1-preflight: \
		kernel kernel-provenance kernel-bpftool bpf \
		kubernetes-configmap-publication \
		kubernetes-configmap-publication-source
	test "$(KUBERNETES_CONFIGMAP_PREFLIGHT_REPETITIONS)" = 1
	$(call KUBERNETES_CONFIGMAP_START,$(KUBERNETES_CONFIGMAP_PREFLIGHT_RESULT_DIR),1,make kvm-kubernetes-configmap-publication-rq1-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-run \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_PREFLIGHT_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-finalize \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_PREFLIGHT_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-analyze \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_PREFLIGHT_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(KUBERNETES_CONFIGMAP_PREFLIGHT_RESULT_DIR))

kvm-kubernetes-configmap-publication-rq1: \
		kernel kernel-provenance kernel-bpftool bpf \
		kubernetes-configmap-publication \
		kubernetes-configmap-publication-source
	test "$(KUBERNETES_CONFIGMAP_REPETITIONS)" = 3
	$(call KUBERNETES_CONFIGMAP_START,$(KUBERNETES_CONFIGMAP_RESULT_DIR),3,make kvm-kubernetes-configmap-publication-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-run \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-finalize \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_RESULT_DIR)" \
		KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" kubernetes-configmap-publication-analyze \
		RUN_ID="$(RUN_ID)" \
		KUBERNETES_CONFIGMAP_ACTIVE_DIR="$(KUBERNETES_CONFIGMAP_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(KUBERNETES_CONFIGMAP_RESULT_DIR))

experiment-kubernetes-configmap-publication-rq1: \
	kvm-kubernetes-configmap-publication-rq1

kubernetes-configmap-publication-run:
	test -n "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__kubernetes_configmap_publication_guest KUBERNETES_CONFIGMAP_BOOT_DIR=$${boot#$(ROOT_DIR)/} KUBERNETES_CONFIGMAP_RUN_DIR=$${KUBERNETES_CONFIGMAP_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(KUBERNETES_CONFIGMAP_KVM_TIMEOUT)"; \
	done

kubernetes-configmap-publication-finalize:
	test -n "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(KUBERNETES_CONFIGMAP_ACTIVE_DIR),$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS))
	! jq -e 'select(.pass != true)' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/observations.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "kubernetes-atomicwriter-summary" and .states == 4 and .pass == true)] | length' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/observations.jsonl")" = \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "kubernetes-configmap-namei-summary" and .states == 4 and .direct_controls == 2 and .failures == 0 and .pass == true)] | length' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/observations.jsonl")" = \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(KUBERNETES_CONFIGMAP_ACTIVE_DIR),$(KUBERNETES_CONFIGMAP_ACTIVE_REPETITIONS),$(KUBERNETES_CONFIGMAP_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		for state_spec in initial:0 update:1 no-op:1 rollback:0; do \
			IFS=: read -r state generation <<<"$$state_spec"; \
			jq -s -e --arg state "$$state" --argjson generation "$$generation" \
				'([.[] | select(.event == "kubernetes-atomicwriter-state" and .mechanism == "kubernetes-atomicwriter" and .state == $$state)][0]) as $$s | def f($$p): [$$s.files[] | select(.path == $$p)][0]; ($$s.files | length) == 4 and ($$s.data_target | length) > 0 and $$s.config_entries == ["app.conf"] and $$s.tls_entries == ["cert.pem"] and $$s.root_entries == (if $$generation == 0 then ["config","retired.conf","tls"] else ["added.conf","config","tls"] end) and $$s.consumer_exit == 0 and $$s.consumer_stdout == (if $$generation == 0 then "version=0\ncertificate-v0\n" else "version=1\ncertificate-v1\n" end) and $$s.runtime_uid > 0 and $$s.runtime_gid > 0 and all($$s.files[]; if .errno == 0 then .uid == $$s.runtime_uid and .gid == $$s.runtime_gid else true end) and f("config/app.conf").errno == 0 and f("config/app.conf").bytes == (if $$generation == 0 then "version=0\n" else "version=1\n" end) and f("config/app.conf").mode == (if $$generation == 0 then 420 else 384 end) and f("config/app.conf").size == 10 and f("tls/cert.pem").errno == 0 and f("tls/cert.pem").bytes == (if $$generation == 0 then "certificate-v0\n" else "certificate-v1\n" end) and f("tls/cert.pem").mode == 256 and f("tls/cert.pem").size == 15 and (if $$generation == 0 then f("retired.conf").errno == 0 and f("retired.conf").bytes == "retired\n" and f("retired.conf").mode == 420 and f("added.conf").errno == 2 else f("retired.conf").errno == 2 and f("added.conf").errno == 0 and f("added.conf").bytes == "added\n" and f("added.conf").mode == 420 end) and $$s.pass == true' \
				"$$boot/observations.jsonl" >/dev/null; \
			jq -s -e --arg state "$$state" --argjson generation "$$generation" \
				'([.[] | select(.event == "kubernetes-atomicwriter-state" and .state == $$state)][0]) as $$s | ([.[] | select(.event == "kubernetes-atomicwriter-dirfd" and .state == $$state)][0]) as $$d | ([$$s.files[] | select(.path == "config/app.conf")][0]) as $$app | $$d.bytes == (if $$generation == 0 then "version=0\n" else "version=1\n" end) and $$d.mode == (if $$generation == 0 then 420 else 384 end) and $$d.root_initial_dev == $$d.root_current_dev and $$d.root_initial_ino == $$d.root_current_ino and $$d.file_dev == $$app.dev and $$d.file_ino == $$app.ino and $$d.pass == true' \
				"$$boot/observations.jsonl" >/dev/null; \
		done; \
		jq -e 'select(.event == "kubernetes-atomicwriter-no-op" and .data_before == .data_after and .dev_before == .dev_after and .ino_before == .ino_after and .pass == true)' \
			"$$boot/observations.jsonl" >/dev/null; \
		test "$$(jq -s '[.[] | select(.event == "kubernetes-atomicwriter-old-fd" and .bytes == "version=0\n" and .initial_dev == .current_dev and .initial_ino == .current_ino and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 2; \
		jq -s -e '([.[] | select(.event == "kubernetes-atomicwriter-state" and .state == "initial") | .files[] | select(.path == "config/app.conf")][0]) as $$initial | ([.[] | select(.event == "kubernetes-atomicwriter-state" and .state == "rollback") | .files[] | select(.path == "config/app.conf")][0]) as $$rollback | $$initial.errno == 0 and $$rollback.errno == 0 and (($$initial.dev != $$rollback.dev) or ($$initial.ino != $$rollback.ino))' \
			"$$boot/observations.jsonl" >/dev/null; \
		for state_spec in namei_ext:initial:0 namei_ext:update:1 namei_ext:no-op:1 namei_ext:rollback:0 direct:physical-v0:0 direct:physical-v1:1; do \
			IFS=: read -r mechanism state generation <<<"$$state_spec"; \
			jq -s -e --arg mechanism "$$mechanism" --arg state "$$state" --argjson generation "$$generation" \
				'([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == $$mechanism and .state == $$state)][0]) as $$s | def f($$p): [$$s.files[] | select(.path == $$p)][0]; ($$s.files | length) == 4 and $$s.generation == $$generation and $$s.root_mask == (if $$generation == 0 then 7 else 11 end) and $$s.root_unexpected == 0 and $$s.config_mask == 1 and $$s.config_unexpected == 0 and $$s.tls_mask == 1 and $$s.tls_unexpected == 0 and $$s.consumer_exit == 0 and $$s.consumer_stdout == (if $$generation == 0 then "version=0\ncertificate-v0\n" else "version=1\ncertificate-v1\n" end) and $$s.runtime_uid > 0 and $$s.runtime_gid > 0 and all($$s.files[]; if .errno == 0 then .uid == $$s.runtime_uid and .gid == $$s.runtime_gid else true end) and f("config/app.conf").errno == 0 and f("config/app.conf").bytes == (if $$generation == 0 then "version=0\n" else "version=1\n" end) and f("config/app.conf").mode == (if $$generation == 0 then 420 else 384 end) and f("config/app.conf").size == 10 and f("config/app.conf").dev == f("config/app.conf").expected_dev and f("config/app.conf").ino == f("config/app.conf").expected_ino and f("tls/cert.pem").errno == 0 and f("tls/cert.pem").bytes == (if $$generation == 0 then "certificate-v0\n" else "certificate-v1\n" end) and f("tls/cert.pem").mode == 256 and f("tls/cert.pem").size == 15 and f("tls/cert.pem").dev == f("tls/cert.pem").expected_dev and f("tls/cert.pem").ino == f("tls/cert.pem").expected_ino and (if $$generation == 0 then f("retired.conf").errno == 0 and f("retired.conf").bytes == "retired\n" and f("retired.conf").mode == 420 and f("retired.conf").dev == f("retired.conf").expected_dev and f("retired.conf").ino == f("retired.conf").expected_ino and f("added.conf").errno == 2 and f("added.conf").expected_errno == 2 else f("retired.conf").errno == 2 and f("retired.conf").expected_errno == 2 and f("added.conf").errno == 0 and f("added.conf").bytes == "added\n" and f("added.conf").mode == 420 and f("added.conf").dev == f("added.conf").expected_dev and f("added.conf").ino == f("added.conf").expected_ino end) and $$s.pass == true' \
					"$$boot/observations.jsonl" >/dev/null; \
			done; \
			jq -s -e '([.[] | select(.event == "kubernetes-atomicwriter-state" and .state == "initial")][0]) as $$identity | ([.[] | select(.event == "kubernetes-atomicwriter-state" or .event == "kubernetes-configmap-state")] | length) == 10 and $$identity.runtime_uid > 0 and $$identity.runtime_gid > 0 and all(.[] | select(.event == "kubernetes-atomicwriter-state" or .event == "kubernetes-configmap-state"); .runtime_uid == $$identity.runtime_uid and .runtime_gid == $$identity.runtime_gid)' \
				"$$boot/observations.jsonl" >/dev/null; \
			for state_spec in initial:physical-v0:0 update:physical-v1:1 no-op:physical-v1:1 rollback:physical-v0:0; do \
			IFS=: read -r state physical generation <<<"$$state_spec"; \
			jq -s -e --arg state "$$state" --arg physical "$$physical" --argjson generation "$$generation" \
				'([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == "namei_ext" and .state == $$state)][0]) as $$logical | ([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == "direct" and .state == $$physical)][0]) as $$direct | def lf($$p): [$$logical.files[] | select(.path == $$p)][0]; def df($$p): [$$direct.files[] | select(.path == $$p)][0]; lf("config/app.conf").dev == df("config/app.conf").dev and lf("config/app.conf").ino == df("config/app.conf").ino and lf("tls/cert.pem").dev == df("tls/cert.pem").dev and lf("tls/cert.pem").ino == df("tls/cert.pem").ino and (if $$generation == 0 then lf("retired.conf").dev == df("retired.conf").dev and lf("retired.conf").ino == df("retired.conf").ino else lf("added.conf").dev == df("added.conf").dev and lf("added.conf").ino == df("added.conf").ino end)' \
				"$$boot/observations.jsonl" >/dev/null; \
		done; \
		for state_spec in initial:0 update:1 no-op:1 rollback:0; do \
			IFS=: read -r state generation <<<"$$state_spec"; \
			jq -s -e --arg state "$$state" --argjson generation "$$generation" \
				'([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == "namei_ext" and .state == $$state)][0]) as $$s | ([.[] | select(.event == "kubernetes-configmap-dirfd" and .state == $$state)][0]) as $$d | ([$$s.files[] | select(.path == "config/app.conf")][0]) as $$app | $$d.bytes == (if $$generation == 0 then "version=0\n" else "version=1\n" end) and $$d.mode == (if $$generation == 0 then 420 else 384 end) and $$d.root_initial_dev == $$d.root_current_dev and $$d.root_initial_ino == $$d.root_current_ino and $$d.file_dev == $$app.dev and $$d.file_ino == $$app.ino and $$d.file_dev == $$d.expected_file_dev and $$d.file_ino == $$d.expected_file_ino and $$d.pass == true' \
				"$$boot/observations.jsonl" >/dev/null; \
		done; \
		test "$$(jq -s '[.[] | select(.event == "kubernetes-configmap-old-fd" and .bytes == "version=0\n" and .initial_dev == .current_dev and .initial_ino == .current_ino and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 2; \
		jq -e 'select(.event == "kubernetes-configmap-no-op" and .before_dev == .after_dev and .before_ino == .after_ino and .pass == true)' \
			"$$boot/observations.jsonl" >/dev/null; \
		test "$$(jq -s '[.[] | select(.event == "kubernetes-configmap-lower" and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 12; \
		for case_name in setup_fixture capture_lower_before \
				validate_expected_generations unmanaged_before create_cgroup \
				cgroup_identity register_generations attach_policy \
				configure_payload_entries scope_cgroup enter_managed_cgroup \
				open_stable_root_dirfd open_old_v0_fd \
				rollback_original_v0_identity close_stable_root_dirfd \
				close_old_fd leave_managed_cgroup delete_cgroup_scope \
				delete_payload_entries \
				detach_policy clear_targets remove_cgroup \
				preserve_lower_generations unmanaged_after; do \
			test "$$(jq -s --arg case_name "$$case_name" \
				'[.[] | select(.event == "kubernetes-configmap-case" and .case == $$case_name and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for counter in total lookup readdir select pass hide; do \
			test "$$(jq -s --arg counter "$$counter" \
				'[.[] | select(.event == "kubernetes-configmap-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/lower-before.tsv" "$$boot/lower-after.tsv"; \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call KUBERNETES_CONFIGMAP_VALIDATE_EXTERNAL,$$boot,before); \
		$(call KUBERNETES_CONFIGMAP_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)

kubernetes-configmap-publication-analyze:
	test -n "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)"
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/run.json" >/dev/null
	install -d "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis"
	jq -s \
		'{boots:([.[] | select(.event == "kubernetes-configmap-namei-summary" and .pass == true)] | length),source_states:([.[] | select(.event == "kubernetes-atomicwriter-state" and .pass == true)] | length),namei_ext_states:([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == "namei_ext" and .pass == true)] | length),direct_controls:([.[] | select(.event == "kubernetes-configmap-state" and .mechanism == "direct" and .pass == true)] | length),directory_descriptor_checks:([.[] | select((.event == "kubernetes-atomicwriter-dirfd" or .event == "kubernetes-configmap-dirfd") and .pass == true)] | length),old_descriptor_checks:([.[] | select((.event == "kubernetes-atomicwriter-old-fd" or .event == "kubernetes-configmap-old-fd") and .pass == true)] | length),lower_preservation_checks:([.[] | select(.event == "kubernetes-configmap-lower" and .pass == true)] | length),verdict:"supported"}' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/observations.jsonl" \
		>"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json"
	jq -e '.boots > 0 and .source_states == (4 * .boots) and .namei_ext_states == (4 * .boots) and .direct_controls == (2 * .boots) and .directory_descriptor_checks == (8 * .boots) and .old_descriptor_checks == (4 * .boots) and .lower_preservation_checks == (12 * .boots) and .verdict == "supported"' \
		"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	printf '%s\n' \
		'# Kubernetes ConfigMap Publication RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing source-control states: $$(jq -r .source_states "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing namei_ext states: $$(jq -r .namei_ext_states "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing direct controls: $$(jq -r .direct_controls "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Stable directory-descriptor checks: $$(jq -r .directory_descriptor_checks "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Old-descriptor checks: $$(jq -r .old_descriptor_checks "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		"Lower-object preservation checks: $$(jq -r .lower_preservation_checks "$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/summary.json")" \
		'Verdict: supported for the Kubernetes AtomicWriter payload-view subset.' \
		>"$(KUBERNETES_CONFIGMAP_ACTIVE_DIR)/analysis/report.md"

__kubernetes_configmap_publication_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__kubernetes_configmap_publication_guest_inner \
		KUBERNETES_CONFIGMAP_BOOT_DIR="$(KUBERNETES_CONFIGMAP_BOOT_DIR)" \
		KUBERNETES_CONFIGMAP_RUN_DIR="$(KUBERNETES_CONFIGMAP_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(KUBERNETES_CONFIGMAP_BOOT_DIR),$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(KUBERNETES_CONFIGMAP_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/guest-dmesg.status"; \
	status=completed; \
	if test "$$inner_status" -ne 0 || \
	   test "$$inventory_after_status" -ne 0 || \
	   test "$$dmesg_status" -ne 0; then status=failed; fi; \
	jq -n \
		--arg status "$$status" \
		--argjson inner_status "$$inner_status" \
		--argjson inventory_after_status "$$inventory_after_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__kubernetes_configmap_publication_guest_inner:
	test -n "$(KUBERNETES_CONFIGMAP_BOOT_DIR)"
	test -n "$(KUBERNETES_CONFIGMAP_RUN_DIR)"
	test -x "$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/atomic-writer-driver"
	test -x "$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/namei_ext_kubernetes_configmap_publication"
	test -r "$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/kubernetes_configmap_publication.bpf.o"
	test -x "$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/bpftool"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(KUBERNETES_CONFIGMAP_BOOT_DIR),$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(KUBERNETES_CONFIGMAP_BOOT_DIR),$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/bpftool,before)
	: >"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/observations.jsonl"
	"$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/atomic-writer-driver" \
		"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/observations.jsonl" \
		"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/source-volume" \
		"$(KUBERNETES_CONFIGMAP_BOOT_DIR)" \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/source-driver.stdout.log" \
		2>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/source-driver.stderr.log"
	"$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/namei_ext_kubernetes_configmap_publication" \
		"$(KUBERNETES_CONFIGMAP_RUN_DIR)/artifacts/runtime/kubernetes_configmap_publication.bpf.o" \
		"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/observations.jsonl" \
		"$(KUBERNETES_CONFIGMAP_BOOT_DIR)" /sys/fs/cgroup \
		>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/namei-runner.stdout.log" \
		2>"$(KUBERNETES_CONFIGMAP_BOOT_DIR)/namei-runner.stderr.log"
