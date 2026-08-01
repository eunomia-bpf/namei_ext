APPLICATION_FILE_SHARING_POLICY ?= \
	$(BUILD_ROOT)/bpf/application_file_sharing.bpf.o
APPLICATION_FILE_SHARING_RUNNER ?= \
	$(BUILD_ROOT)/application-file-sharing/namei_ext_application_file_sharing
APPLICATION_FILE_SHARING_SOURCE_ORACLE ?= \
	$(BUILD_ROOT)/application-file-sharing/xdg_document_portal_oracle
APPLICATION_FILE_SHARING_BPFTOOL ?= $(KERNEL_BPFTOOL)
APPLICATION_FILE_SHARING_RQ2_FUSE_COUNTER ?= \
	$(BUILD_ROOT)/bpf/application_file_sharing_fuse_counter.bpf.o
APPLICATION_FILE_SHARING_RQ2_ANALYSIS ?= \
	$(ROOT_DIR)/analysis/application_file_sharing_rq2/analyze.py
APPLICATION_FILE_SHARING_RQ2_PREFLIGHT_REVIEW ?= \
	$(ROOT_DIR)/docs/tmp/2026-08-01-rq2-official-xdg-portal-preflight-review.md
APPLICATION_FILE_SHARING_XDG_PORTAL_ARCHIVE ?= \
	$(CACHE_ROOT)/workloads/xdg-document-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT).tar.gz
APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT ?= \
	$(BUILD_ROOT)/workloads/xdg-document-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)
APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/source
APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE_READY ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/source.ready
APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build
APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD_READY ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build.ready
APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD)/document-portal/xdg-document-portal
APPLICATION_FILE_SHARING_XDG_PERMISSION_STORE_BINARY ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD)/document-portal/xdg-permission-store
APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD)/meson-logs/testlog.txt
APPLICATION_FILE_SHARING_XDG_PORTAL_METADATA ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/source-metadata.json
APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION_LOG ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-document-portal.version.txt
APPLICATION_FILE_SHARING_XDG_PORTAL_DOCKERFILE ?= \
	$(ROOT_DIR)/experiments/application_file_sharing/Dockerfile.xdg-portal
APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE ?= \
	namei-ext-xdg-document-portal:ubuntu-24.04-1.22.1
APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE_READY ?= \
	$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/image.ready

APPLICATION_FILE_SHARING_XDG_PORTAL_MESON_OPTIONS := \
	-Dflatpak-interfaces=disabled \
	-Dgeoclue=disabled \
	-Dsystemd=enabled \
	-Ddocumentation=disabled \
	-Dman-pages=disabled \
	-Dtests=enabled \
	-Dsandboxed-image-validation=disabled \
	-Dsandboxed-sound-validation=disabled

$(APPLICATION_FILE_SHARING_XDG_PORTAL_ARCHIVE):
	install -d "$(dir $@)"
	curl --fail --location --retry 3 --output "$@.tmp" \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ARCHIVE_URL)"
	mv "$@.tmp" "$@"

$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE_READY): \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_ARCHIVE)
	rm -rf "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp" \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)"
	install -d "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp"
	tar -xf "$<" -C "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp"
	test -f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)/document-portal/document-portal.c"
	test -f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)/document-portal/document-portal-fuse.c"
	test -f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)/data/org.freedesktop.portal.Documents.xml"
	test -f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)/tests/test_documents.py"
	test -f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)/tests/xdp_doc_utils.py"
	mv "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp/xdg-desktop-portal-$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)"
	rmdir "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE).tmp"
	printf '%s\n' "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" >"$@"

$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE_READY): \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_DOCKERFILE)
	install -d "$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)"
	docker build \
		-f "$(APPLICATION_FILE_SHARING_XDG_PORTAL_DOCKERFILE)" \
		-t "$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE)" \
		"$(ROOT_DIR)/experiments/application_file_sharing"
	docker image inspect "$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE)" \
		>"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/image-inspect.json"
	docker image inspect "$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE)" \
		--format '{{.Id}}' >"$@"

$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD_READY): \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE_READY) \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE_READY)
	rm -rf "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD)"
	install -d "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD)"
	docker run --rm --privileged --device /dev/fuse \
		-v "$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE):/source:rw" \
		-v "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD):/build" \
		-e HOST_UID="$$(id -u)" -e HOST_GID="$$(id -g)" \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE)" \
		bash -euc 'trap '\''chown -R "$${HOST_UID}:$${HOST_GID}" /build'\'' EXIT; if ! test -f /build/build.ninja; then meson setup /build /source $(APPLICATION_FILE_SHARING_XDG_PORTAL_MESON_OPTIONS); fi; meson compile -C /build; meson test -C /build --print-errorlogs unit/permission-db unit/xdp-utils unit/xdp-method-info integration/documents' \
		>"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build.stdout.log" \
		2>"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build.stderr.log"
	test -x "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY)"
	test -x "$(APPLICATION_FILE_SHARING_XDG_PERMISSION_STORE_BINARY)"
	test -s "$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)"
	grep -E '^Ok:[[:space:]]+4[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Fail:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Skipped:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Timeout:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	ldd "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY)" \
		>"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-document-portal.ldd.txt"
	! grep -F 'not found' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-document-portal.ldd.txt"
	ldd "$(APPLICATION_FILE_SHARING_XDG_PERMISSION_STORE_BINARY)" \
		>"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-permission-store.ldd.txt"
	! grep -F 'not found' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-permission-store.ldd.txt"
	printf '%s\n' "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" >"$@"

$(APPLICATION_FILE_SHARING_XDG_PORTAL_METADATA): \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD_READY)
	jq -n \
		--arg source_system xdg-document-portal \
		--arg version "$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)" \
		--arg commit "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
		--arg archive_url "$(APPLICATION_FILE_SHARING_XDG_PORTAL_ARCHIVE_URL)" \
		--arg image "$$(cat "$(APPLICATION_FILE_SHARING_XDG_PORTAL_IMAGE_READY)")" \
		--arg source_api data/org.freedesktop.portal.Documents.xml \
		--arg implementation document-portal/document-portal.c \
		--arg fuse_implementation document-portal/document-portal-fuse.c \
		--arg upstream_test tests/test_documents.py \
		'{source_system:$$source_system,version:$$version,commit:$$commit,archive_url:$$archive_url,builder_image_id:$$image,source_files:{api:$$source_api,implementation:$$implementation,fuse:$$fuse_implementation,upstream_test:$$upstream_test},upstream_test_gate:{meson_tests:["unit/permission-db","unit/xdp-utils","unit/xdp-method-info","integration/documents"],skips:0,failures:0,timeouts:0}}' \
		>"$@"

$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION_LOG): \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD_READY)
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY)" --version >"$@"
	grep -Fx 'xdg-desktop-portal $(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)' \
		"$@" >/dev/null

APPLICATION_FILE_SHARING_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	lower-document-payload.txt unrelated-document-payload.txt \
	stdout-controller.log stderr-controller.log \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

define APPLICATION_FILE_SHARING_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(APPLICATION_FILE_SHARING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_application_file_sharing"
install -m 0444 "$(APPLICATION_FILE_SHARING_POLICY)" \
	"$(1)/artifacts/runtime/application_file_sharing.bpf.o"
install -m 0555 "$(APPLICATION_FILE_SHARING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
printf '%s\n' \
	'https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html' \
	>"$(1)/artifacts/source/documents-portal-url.txt"
printf '%s\n' \
	'https://github.com/flatpak/xdg-desktop-portal' \
	>"$(1)/artifacts/source/implementation-url.txt"
printf 'xdg-portal-existing-object\n' \
	>"$(1)/artifacts/source/expected-document-payload.txt"
printf 'unrelated-document-object\n' \
	>"$(1)/artifacts/source/expected-unrelated-payload.txt"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{runner:"artifacts/runtime/namei_ext_application_file_sharing",policy:"artifacts/runtime/application_file_sharing.bpf.o",bpftool:"artifacts/runtime/bpftool"},source:{documents_portal:"artifacts/source/documents-portal-url.txt",implementation:"artifacts/source/implementation-url.txt",expected_document:"artifacts/source/expected-document-payload.txt",expected_unrelated:"artifacts/source/expected-unrelated-payload.txt"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define APPLICATION_FILE_SHARING_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),application-file-sharing-rq1,xdg-documents-portal,kvm_application_file_sharing_rq1,$(1)/observations.jsonl,application_file_sharing.bpf.c,namei_ext_application_file_sharing)
$(call APPLICATION_FILE_SHARING_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	'.protocol_schema = "namei_ext.application_file_sharing_rq1.v1" | .layout = "fresh-boot-two-application-grant-revoke" | .matrix = {applications:["application-a","application-b"],states:["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"],repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

define APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL
jq -e 'type == "array" and length == 0' \
	"$(1)/bpf-programs-$(2).json" >/dev/null; \
jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
	"$(1)/bpf-cgroup-$(2).json" >/dev/null; \
test ! -s "$(1)/fuse-mounts-$(2).txt"; \
test "$$(cat "$(1)/fuse-open-fds-$(2).status")" = 1; \
test ! -s "$(1)/fuse-open-fds-$(2).txt"
endef

APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log \
	source-host-payload.txt lower-document-payload.txt \
	unrelated-document-payload.txt \
	source-controller.stdout.log source-controller.stderr.log \
	source-permission-store.stdout.log source-permission-store.stderr.log \
	source-portal.stdout.log source-portal.stderr.log \
	stdout-controller.log stderr-controller.log \
	source-oracle.status namei-ext-runner.status \
	xdg-document-portal.version.txt \
	xdg-document-portal.ldd.txt xdg-permission-store.ldd.txt \
	bpf-programs-before.json bpf-programs-midpoint.json \
	bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-midpoint.json \
	bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-midpoint.txt \
	fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-midpoint.txt fuse-open-fds-midpoint.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	guest-inner.status guest-midpoint-inventory.status \
	guest-inventory-after.status guest-dmesg.status \
	kernel.config kernel-commit.txt kernel-release.txt \
	uname.txt proc-version.txt kernel-cmdline.txt \
	launcher.stdout.log launcher.stderr.log

define APPLICATION_FILE_SHARING_SOURCE_ORACLE_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(APPLICATION_FILE_SHARING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_application_file_sharing"
install -m 0555 "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE)" \
	"$(1)/artifacts/runtime/xdg_document_portal_oracle"
install -m 0555 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY)" \
	"$(1)/artifacts/runtime/xdg-document-portal"
install -m 0555 "$(APPLICATION_FILE_SHARING_XDG_PERMISSION_STORE_BINARY)" \
	"$(1)/artifacts/runtime/xdg-permission-store"
install -m 0444 "$(APPLICATION_FILE_SHARING_POLICY)" \
	"$(1)/artifacts/runtime/application_file_sharing.bpf.o"
install -m 0555 "$(APPLICATION_FILE_SHARING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_METADATA)" \
	"$(1)/artifacts/source/source-metadata.json"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" \
	"$(1)/artifacts/source/test-doc-portal.log"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build.stdout.log" \
	"$(1)/artifacts/source/build.stdout.log"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/build.stderr.log" \
	"$(1)/artifacts/source/build.stderr.log"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/image-inspect.json" \
	"$(1)/artifacts/source/builder-image-inspect.json"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-document-portal.ldd.txt" \
	"$(1)/artifacts/source/xdg-document-portal-builder.ldd.txt"
	install -m 0444 \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_ROOT)/xdg-permission-store.ldd.txt" \
		"$(1)/artifacts/source/xdg-permission-store-builder.ldd.txt"
	install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION_LOG)" \
		"$(1)/artifacts/source/xdg-document-portal.version.txt"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/data/org.freedesktop.portal.Documents.xml" \
	"$(1)/artifacts/source/org.freedesktop.portal.Documents.xml"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/document-portal/document-portal.c" \
	"$(1)/artifacts/source/document-portal.c"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/document-portal/document-portal-fuse.c" \
	"$(1)/artifacts/source/document-portal-fuse.c"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/tests/test_documents.py" \
	"$(1)/artifacts/source/test_documents.py"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/tests/xdp_doc_utils.py" \
	"$(1)/artifacts/source/xdp_doc_utils.py"
install -m 0444 \
	"$(ROOT_DIR)/experiments/application_file_sharing/xdg_document_portal_oracle.c" \
	"$(1)/artifacts/source/xdg_document_portal_oracle.c"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_DOCKERFILE)" \
	"$(1)/artifacts/source/Dockerfile.xdg-portal"
printf 'xdg-portal-existing-object\n' \
	>"$(1)/artifacts/source/expected-document-payload.txt"
printf 'unrelated-document-object\n' \
	>"$(1)/artifacts/source/expected-unrelated-payload.txt"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg source_commit "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
		'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{namei_runner:"artifacts/runtime/namei_ext_application_file_sharing",source_oracle:"artifacts/runtime/xdg_document_portal_oracle",portal:"artifacts/runtime/xdg-document-portal",permission_store:"artifacts/runtime/xdg-permission-store",policy:"artifacts/runtime/application_file_sharing.bpf.o",bpftool:"artifacts/runtime/bpftool"},source:{system:"xdg-document-portal",commit:$$source_commit,metadata:"artifacts/source/source-metadata.json",upstream_test_log:"artifacts/source/test-doc-portal.log",api:"artifacts/source/org.freedesktop.portal.Documents.xml",implementation:"artifacts/source/document-portal.c",fuse_implementation:"artifacts/source/document-portal-fuse.c",upstream_test:"artifacts/source/test_documents.py",upstream_test_helper:"artifacts/source/xdp_doc_utils.py"}}' \
	>"$(1)/artifacts/manifest.json"
endef

define APPLICATION_FILE_SHARING_SOURCE_ORACLE_START
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),application-file-sharing-source-oracle-rq1,xdg-document-portal,kvm_application_file_sharing_source_oracle_rq1,$(1)/observations.jsonl,application_file_sharing.bpf.c,xdg_document_portal_oracle+namei_ext_application_file_sharing)
$(call APPLICATION_FILE_SHARING_SOURCE_ORACLE_CAPTURE_ARTIFACTS,$(1))
jq \
	--argjson repetitions "$(2)" \
	--arg source_commit "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
	'.protocol_schema = "namei_ext.application_file_sharing_source_oracle_rq1.v1" | .layout = "fresh-boot-official-source-control-then-namei-ext" | .source_system_commit = $$source_commit | .matrix = {mechanisms:["xdg-document-portal","namei_ext"],states:["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"],repetitions:$$repetitions,all_boots_must_pass:true}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(3)" >"$(1)/command.txt"
: >"$(1)/stdout.log"
: >"$(1)/stderr.log"
endef

.PHONY: kvm-application-file-sharing-preflight \
		kvm-application-file-sharing-rq1 application-file-sharing-run \
		application-file-sharing-finalize application-file-sharing-analyze \
		experiment-application-file-sharing-rq1 \
		application-file-sharing-source \
		kvm-application-file-sharing-source-oracle-preflight \
		kvm-application-file-sharing-source-oracle-rq1 \
		application-file-sharing-source-oracle-run \
		application-file-sharing-source-oracle-finalize \
		application-file-sharing-source-oracle-analyze \
		experiment-application-file-sharing-source-oracle-rq1 \
		__application_file_sharing_guest \
		__application_file_sharing_guest_inner \
		__application_file_sharing_source_oracle_guest \
		__application_file_sharing_source_oracle_guest_inner

application-file-sharing-source: \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_BUILD_READY) \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_METADATA) \
		$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION_LOG) \
		application-file-sharing

kvm-application-file-sharing-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-preflight: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf application-file-sharing
	test "$(APPLICATION_FILE_SHARING_PREFLIGHT_REPETITIONS)" = 1
	$(call APPLICATION_FILE_SHARING_START,$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR),1,make kvm-application-file-sharing-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_PREFLIGHT_RESULT_DIR)"

kvm-application-file-sharing-rq1: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-rq1: experiment-source-clean kernel \
		kernel-provenance kernel-bpftool bpf application-file-sharing
	test "$(APPLICATION_FILE_SHARING_REPETITIONS)" = 3
	$(call APPLICATION_FILE_SHARING_START,$(APPLICATION_FILE_SHARING_RESULT_DIR),3,make kvm-application-file-sharing-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RESULT_DIR)"

experiment-application-file-sharing-rq1: kvm-application-file-sharing-rq1

application-file-sharing-run:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		install -d "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__application_file_sharing_guest APPLICATION_FILE_SHARING_BOOT_DIR=$${boot#$(ROOT_DIR)/} APPLICATION_FILE_SHARING_RUN_DIR=$${APPLICATION_FILE_SHARING_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(APPLICATION_FILE_SHARING_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(APPLICATION_FILE_SHARING_KVM_TIMEOUT)"; \
	done

application-file-sharing-finalize:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(APPLICATION_FILE_SHARING_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS))
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl" \
		>/dev/null
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .failures == 0 and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((5 * $(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-lower-object" and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(APPLICATION_FILE_SHARING_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_ACTIVE_REPETITIONS),$(APPLICATION_FILE_SHARING_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .failures == 0 and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		for state in application-a-before-grant \
				application-b-without-grant \
				application-b-during-a-grant \
				application-a-after-revoke; do \
			test "$$(jq -s --arg state "$$state" \
				'[.[] | select(.event == "application-file-sharing-state" and .state == $$state and .expected_visible == false and .observation_errno == 0 and .move_errno == 0 and .document_errno == 2 and .payload_stat_errno == 2 and .payload_read_errno == 2 and .opendir_errno == 0 and .readdir_errno == 0 and .closedir_errno == 0 and .document_listed == false and .unrelated_errno == 0 and .unrelated_bytes_expected == true and .lower_document_errno == 0 and .lower_payload_errno == 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-state" and .state == "application-a-after-grant" and .expected_visible == true and .observation_errno == 0 and .move_errno == 0 and .document_errno == 0 and .payload_stat_errno == 0 and .payload_read_errno == 0 and .opendir_errno == 0 and .readdir_errno == 0 and .closedir_errno == 0 and .document_listed == true and .payload_bytes_expected == true and .unrelated_errno == 0 and .unrelated_bytes_expected == true and .lower_document_errno == 0 and .lower_payload_errno == 0 and .logical_document_dev == .lower_document_dev and .logical_document_ino == .lower_document_ino and .logical_payload_dev == .lower_payload_dev and .logical_payload_ino == .lower_payload_ino and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s \
			'[.[] | select(.event == "application-file-sharing-lower-object" and .object == "host-document-payload" and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_size == .after_size and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' \
			"$$boot/observations.jsonl")" = 1; \
		for case_name in fixture_paths application_identities \
				application_a_identity register_existing_document \
				attach_policy register_portal_scope \
				grant_application_a revoke_application_a \
				preserve_raw_objects detach_policy \
				clear_registered_document \
				remove_application_a_cgroup \
				remove_application_b_cgroup; do \
			test "$$(jq -s --arg case_name "$$case_name" \
				'[.[] | select(.event == "application-file-sharing-case" and .case == $$case_name and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		for counter in lookup readdir select hide_lookup hide_readdir; do \
			test "$$(jq -s --arg counter "$$counter" \
				'[.[] | select(.event == "application-file-sharing-policy-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' \
				"$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/lower-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/source/expected-document-payload.txt"; \
		cmp "$$boot/unrelated-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/artifacts/source/expected-unrelated-payload.txt"; \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,before); \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/run.json" >/dev/null

application-file-sharing-analyze:
	test -n "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(APPLICATION_FILE_SHARING_ACTIVE_DIR))
	install -d "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.application_file_sharing_rq1.summary.v1",boots:([.[] | select(.event == "application-file-sharing-summary" and .pass == true)] | length),states:([.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length),visible_states:([.[] | select(.event == "application-file-sharing-state" and .expected_visible == true and .pass == true)] | length),hidden_states:([.[] | select(.event == "application-file-sharing-state" and .expected_visible == false and .pass == true)] | length),lower_objects:([.[] | select(.event == "application-file-sharing-lower-object" and .pass == true)] | length),cgroup_removals:([.[] | select(.event == "application-file-sharing-case" and (.case == "remove_application_a_cgroup" or .case == "remove_application_b_cgroup") and .pass == true)] | length)}' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/observations.jsonl" \
		>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json"
	jq -e \
		'.boots > 0 and .states == (5 * .boots) and .visible_states == .boots and .hidden_states == (4 * .boots) and .lower_objects == .boots and .cgroup_removals == (2 * .boots)' \
		"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json" \
		>/dev/null
	printf '%s\n' \
		'# Sandboxed Application File Sharing RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing lifecycle states: $$(jq -r .states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Visible states: $$(jq -r .visible_states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Hidden states: $$(jq -r .hidden_states "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Preserved lower objects: $$(jq -r .lower_objects "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		"Removed application cgroups: $$(jq -r .cgroup_removals "$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/summary.json")" \
		'Scope: tested XDG Documents portal existing-object grant/revoke subset.' \
		>"$(APPLICATION_FILE_SHARING_ACTIVE_DIR)/analysis/report.md"

__application_file_sharing_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__application_file_sharing_guest_inner \
		APPLICATION_FILE_SHARING_BOOT_DIR="$(APPLICATION_FILE_SHARING_BOOT_DIR)" \
		APPLICATION_FILE_SHARING_RUN_DIR="$(APPLICATION_FILE_SHARING_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(APPLICATION_FILE_SHARING_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(APPLICATION_FILE_SHARING_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/guest-dmesg.status"; \
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
		'{schema:"namei_ext.application_file_sharing_rq1.boot.v1",status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__application_file_sharing_guest_inner:
	test -n "$(APPLICATION_FILE_SHARING_BOOT_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_RUN_DIR)"
	test -x "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing"
	test -r "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o"
	test -x "$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_BOOT_DIR),$(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$(APPLICATION_FILE_SHARING_BOOT_DIR),before)
	: >"$(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl"
	"$(abspath $(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing)" \
		"$(abspath $(APPLICATION_FILE_SHARING_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o)" \
		"$(abspath $(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(APPLICATION_FILE_SHARING_BOOT_DIR))" /sys/fs/cgroup \
		>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/stdout-controller.log" \
		2>"$(APPLICATION_FILE_SHARING_BOOT_DIR)/stderr-controller.log"
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_BOOT_DIR)/observations.jsonl" \
		>/dev/null

kvm-application-file-sharing-source-oracle-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-source-oracle-preflight: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		application-file-sharing-source
	test "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_REPETITIONS)" = 1
	$(call APPLICATION_FILE_SHARING_SOURCE_ORACLE_START,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_RESULT_DIR),1,make kvm-application-file-sharing-source-oracle-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS=1
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_PREFLIGHT_RESULT_DIR)"

kvm-application-file-sharing-source-oracle-rq1: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-source-oracle-rq1: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool bpf \
		application-file-sharing-source
	test "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_REPETITIONS)" = 3
	$(call APPLICATION_FILE_SHARING_SOURCE_ORACLE_START,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RESULT_DIR),3,make kvm-application-file-sharing-source-oracle-rq1 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS=3
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS=3
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RESULT_DIR))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-source-oracle-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RESULT_DIR)"

experiment-application-file-sharing-source-oracle-rq1: \
	kvm-application-file-sharing-source-oracle-rq1

application-file-sharing-source-oracle-run:
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)"
	for repetition in $$(seq 1 "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)"); do \
		printf '%s\n' "$$repetition" \
			>>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/expected-boots.txt"; \
		boot="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/boots/repetition-$$(printf '%02d' "$$repetition")"; \
		install -d "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__application_file_sharing_source_oracle_guest APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR=$${boot#$(ROOT_DIR)/} APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR=$${APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR#$(ROOT_DIR)/}" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_KVM_TIMEOUT)"; \
	done

application-file-sharing-source-oracle-finalize:
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS))
	grep -E '^Ok:[[:space:]]+4[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/test-doc-portal.log" >/dev/null
	grep -E '^Skipped:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/test-doc-portal.log" >/dev/null
	grep -E '^Fail:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/test-doc-portal.log" >/dev/null
	grep -E '^Timeout:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/test-doc-portal.log" >/dev/null
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-source-summary" and .mechanism == "xdg-document-portal" and .states == 5 and .expected_states == 5 and .failures == 0 and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .failures == 0 and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-source-state" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((5 * $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((5 * $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS)))"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_REPETITIONS),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_FILES))
	while IFS= read -r -d '' boot; do \
		jq -s -e \
			'def states: ["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"]; def visible($$state): $$state == "application-a-after-grant"; def valid($$row; $$visible): ($$row.expected_visible == $$visible) and (if $$visible then $$row.document_errno == 0 and $$row.payload_stat_errno == 0 and $$row.payload_read_errno == 0 and $$row.opendir_errno == 0 and $$row.readdir_errno == 0 and $$row.closedir_errno == 0 and $$row.document_listed == true and $$row.payload_bytes_expected == true else $$row.document_errno == 2 and $$row.payload_stat_errno == 2 and $$row.payload_read_errno == 2 and $$row.opendir_errno == 0 and $$row.readdir_errno == 0 and $$row.closedir_errno == 0 and $$row.document_listed == false and $$row.payload_bytes_expected == false end); . as $$events | all(states[]; . as $$state | [$$events[] | select(.event == "application-file-sharing-source-state" and .state == $$state)] as $$source | [$$events[] | select(.event == "application-file-sharing-state" and .state == $$state)] as $$namei | ($$source | length) == 1 and ($$namei | length) == 1 and valid($$source[0]; visible($$state)) and valid($$namei[0]; visible($$state)) and ($$source[0] | {expected_visible,document_errno,payload_stat_errno,payload_read_errno,opendir_errno,readdir_errno,closedir_errno,document_listed,payload_bytes_expected}) == ($$namei[0] | {expected_visible,document_errno,payload_stat_errno,payload_read_errno,opendir_errno,readdir_errno,closedir_errno,document_listed,payload_bytes_expected}) and $$source[0].pass == true and $$namei[0].pass == true)' \
			"$$boot/observations.jsonl" >/dev/null; \
		test "$$(jq -s '[.[] | select(.event == "application-file-sharing-state" and .state == "application-a-after-grant" and .observation_errno == 0 and .move_errno == 0 and .unrelated_errno == 0 and .unrelated_bytes_expected == true and .lower_document_errno == 0 and .lower_payload_errno == 0 and .logical_document_dev == .lower_document_dev and .logical_document_ino == .lower_document_ino and .logical_payload_dev == .lower_payload_dev and .logical_payload_ino == .lower_payload_ino)] | length' "$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s '[.[] | select(.event == "application-file-sharing-source-process" and .started == true and .stop_errno == 0 and .status_valid == true and ((.exited == true and .exit_code == 0) or (.signaled == true and .term_signal == 15)))] | length' "$$boot/observations.jsonl")" = 2; \
		test "$$(jq -s '[.[] | select(.event == "application-file-sharing-source-lower" and .after_errno == 0 and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_uid == .after_uid and .before_gid == .after_gid and .before_size == .after_size and .before_mtime_sec == .after_mtime_sec and .before_mtime_nsec == .after_mtime_nsec and .before_ctime_sec == .after_ctime_sec and .before_ctime_nsec == .after_ctime_nsec and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s '[.[] | select(.event == "application-file-sharing-lower-object" and .after_errno == 0 and .before_dev == .after_dev and .before_ino == .after_ino and .before_mode == .after_mode and .before_uid == .after_uid and .before_gid == .after_gid and .before_size == .after_size and .before_mtime_sec == .after_mtime_sec and .before_mtime_nsec == .after_mtime_nsec and .before_ctime_sec == .after_ctime_sec and .before_ctime_nsec == .after_ctime_nsec and .metadata_unchanged == true and .bytes_expected == true and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		for counter in lookup readdir select hide_lookup hide_readdir; do \
			test "$$(jq -s --arg counter "$$counter" '[.[] | select(.event == "application-file-sharing-policy-counter" and .counter == $$counter and .value > 0 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		done; \
		cmp "$$boot/source-host-payload.txt" \
			"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/expected-document-payload.txt"; \
		cmp "$$boot/lower-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/expected-document-payload.txt"; \
		cmp "$$boot/unrelated-document-payload.txt" \
			"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/artifacts/source/expected-unrelated-payload.txt"; \
		test "$$(cat "$$boot/source-oracle.status")" = 0; \
		test "$$(cat "$$boot/namei-ext-runner.status")" = 0; \
		test "$$(cat "$$boot/guest-midpoint-inventory.status")" = 0; \
		grep -Fx 'xdg-desktop-portal $(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)' \
			"$$boot/xdg-document-portal.version.txt" >/dev/null; \
		! grep -F 'not found' "$$boot/xdg-document-portal.ldd.txt"; \
		! grep -F 'not found' "$$boot/xdg-permission-store.ldd.txt"; \
		jq -e '.status == "completed" and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0' \
			"$$boot/boot.json" >/dev/null; \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,before); \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,midpoint); \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,after); \
	done < <(find "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/boots" \
		-mindepth 1 -maxdepth 1 -type d -print0 | LC_ALL=C sort -z)
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false and .source_system_commit == "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)"' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/run.json" >/dev/null

application-file-sharing-source-oracle-analyze:
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)"
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR))
	install -d "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis"
	jq -s \
		'{schema:"namei_ext.application_file_sharing_source_oracle_rq1.summary.v1",boots:([.[] | select(.event == "application-file-sharing-source-summary" and .pass == true)] | length),source_states:([.[] | select(.event == "application-file-sharing-source-state" and .pass == true)] | length),namei_ext_states:([.[] | select(.event == "application-file-sharing-state" and .pass == true)] | length),source_lower_preservation:([.[] | select(.event == "application-file-sharing-source-lower" and .pass == true)] | length),namei_ext_lower_preservation:([.[] | select(.event == "application-file-sharing-lower-object" and .pass == true)] | length)}' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/observations.jsonl" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json"
	jq -e \
		'.boots > 0 and .source_states == (5 * .boots) and .namei_ext_states == (5 * .boots) and .source_lower_preservation == .boots and .namei_ext_lower_preservation == .boots' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json" >/dev/null
	printf '%s\n' \
		'# Application File Sharing Source-Oracle RQ1 Result' \
		'' \
		"Boots: $$(jq -r .boots "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing official portal states: $$(jq -r .source_states "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json")" \
		"Passing namei_ext states: $$(jq -r .namei_ext_states "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json")" \
		"Official portal lower-object checks: $$(jq -r .source_lower_preservation "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json")" \
		"namei_ext lower-object checks: $$(jq -r .namei_ext_lower_preservation "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/summary.json")" \
		'Scope: official xdg-document-portal grant/revoke lifecycle and namei_ext execute the same five-state existing-object visibility oracle.' \
		'This RQ1 experiment makes no latency or FUSE-performance claim.' \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_ACTIVE_DIR)/analysis/report.md"

__application_file_sharing_source_oracle_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__application_file_sharing_source_oracle_guest_inner \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)" \
		APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR="$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/guest-inventory-after.status"; \
	dmesg_status=0; \
	dmesg >"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/guest-dmesg.status"; \
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
		'{schema:"namei_ext.application_file_sharing_source_oracle_rq1.boot.v1",status:$$status,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,completed_at:$$completed_at}' \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__application_file_sharing_source_oracle_guest_inner:
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg_document_portal_oracle"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-document-portal"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-permission-store"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing"
	test -r "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/bpftool"
	command -v dbus-daemon >/dev/null
	command -v fusermount3 >/dev/null
	test -c /dev/fuse
	"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-document-portal" \
		--version \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-document-portal.version.txt"
	grep -Fx 'xdg-desktop-portal $(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-document-portal.version.txt" >/dev/null
	ldd "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-document-portal" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-document-portal.ldd.txt"
	! grep -F 'not found' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-document-portal.ldd.txt"
	ldd "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-permission-store" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-permission-store.ldd.txt"
	! grep -F 'not found' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/xdg-permission-store.ldd.txt"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),before)
	: >"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/observations.jsonl"
	source_status=0; \
	"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg_document_portal_oracle)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-document-portal)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/xdg-permission-store)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR))" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/source-controller.stdout.log" \
		2>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/source-controller.stderr.log" || \
		source_status=$$?; \
	printf '%s\n' "$$source_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/source-oracle.status"; \
	test "$$source_status" -eq 0
	midpoint_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/bpftool,midpoint) || \
		midpoint_status=$$?; \
	if test "$$midpoint_status" -eq 0; then \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR),midpoint) || \
			midpoint_status=$$?; \
	fi; \
	printf '%s\n' "$$midpoint_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/guest-midpoint-inventory.status"; \
	test "$$midpoint_status" -eq 0
	namei_status=0; \
	"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/observations.jsonl)" \
		"$(abspath $(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR))" \
		/sys/fs/cgroup \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/stdout-controller.log" \
		2>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/stderr-controller.log" || \
		namei_status=$$?; \
	printf '%s\n' "$$namei_status" \
		>"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/namei-ext-runner.status"; \
	test "$$namei_status" -eq 0
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_SOURCE_ORACLE_BOOT_DIR)/observations.jsonl" >/dev/null

APPLICATION_FILE_SHARING_RQ2_BOOT_FILES := \
	boot.json observations.jsonl dmesg.log stdout-controller.log \
	stderr-controller.log mechanism.status guest-inner.status \
	guest-inventory-after.status guest-dmesg.status \
	bpf-programs-before.json bpf-programs-after.json \
	bpf-cgroup-before.json bpf-cgroup-after.json \
	fuse-mounts-before.txt fuse-mounts-after.txt \
	fuse-open-fds-before.txt fuse-open-fds-before.status \
	fuse-open-fds-after.txt fuse-open-fds-after.status \
	kernel.config kernel-commit.txt kernel-release.txt uname.txt \
	proc-version.txt kernel-cmdline.txt clocksource-before.txt \
	clocksource-after.txt launcher.stdout.log launcher.stderr.log \
	vcpu-affinity-pin.json vcpu-affinity.json ext4-filesystem.txt \
	ext4-statfs.txt mkfs-ext4.log ext4-cleanup.status

define APPLICATION_FILE_SHARING_RQ2_ASSERT_SHARED_PROTOCOL
test "$(KVM_CPUS)" = 4
test "$(KVM_MEM)" = 8G
test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_HOST_CPUS)" = 4-7
test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_ANALYSIS_SEED)" = 20260801
test "$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)" = 1.22.1
test "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" = \
	1d20fadc304f6601452b5db65ed91197dba77041
test "$(KVM_APPEND)" = \
	"loglevel=7 panic=30 oops=panic tsc=reliable clocksource=tsc"
$(call NAMEI_EXT_VALIDATE_HOST_CPU_PIN,$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_HOST_CPUS),$(KVM_CPUS))
endef

define APPLICATION_FILE_SHARING_RQ2_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source" "$(1)/artifacts/analysis"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" \
	"$(1)/artifacts/kernel/config"
install -m 0555 "$(APPLICATION_FILE_SHARING_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_application_file_sharing"
install -m 0555 "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE)" \
	"$(1)/artifacts/runtime/xdg_document_portal_oracle"
install -m 0555 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_BINARY)" \
	"$(1)/artifacts/runtime/xdg-document-portal"
install -m 0555 "$(APPLICATION_FILE_SHARING_XDG_PERMISSION_STORE_BINARY)" \
	"$(1)/artifacts/runtime/xdg-permission-store"
install -m 0444 "$(APPLICATION_FILE_SHARING_POLICY)" \
	"$(1)/artifacts/runtime/application_file_sharing.bpf.o"
install -m 0444 "$(APPLICATION_FILE_SHARING_RQ2_FUSE_COUNTER)" \
	"$(1)/artifacts/runtime/application_file_sharing_fuse_counter.bpf.o"
install -m 0555 "$(APPLICATION_FILE_SHARING_BPFTOOL)" \
	"$(1)/artifacts/runtime/bpftool"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_METADATA)" \
	"$(1)/artifacts/source/xdg-document-portal-metadata.json"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" \
	"$(1)/artifacts/source/xdg-document-portal-testlog.txt"
install -m 0444 "$(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION_LOG)" \
	"$(1)/artifacts/source/xdg-document-portal.version.txt"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/document-portal/document-portal-fuse.c" \
	"$(1)/artifacts/source/document-portal-fuse.c"
install -m 0444 \
	"$(APPLICATION_FILE_SHARING_XDG_PORTAL_SOURCE)/tests/test_documents.py" \
	"$(1)/artifacts/source/test_documents.py"
install -m 0444 \
	"$(ROOT_DIR)/experiments/application_file_sharing/rq2_measurement.c" \
	"$(1)/artifacts/source/rq2_measurement.c"
install -m 0444 \
	"$(ROOT_DIR)/experiments/application_file_sharing/rq2_measurement.h" \
	"$(1)/artifacts/source/rq2_measurement.h"
install -m 0444 \
	"$(ROOT_DIR)/bpf/tracing/application_file_sharing_fuse_counter.bpf.c" \
	"$(1)/artifacts/source/application_file_sharing_fuse_counter.bpf.c"
install -m 0444 "$(APPLICATION_FILE_SHARING_RQ2_ANALYSIS)" \
	"$(1)/artifacts/analysis/analyze.py"
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg portal_commit "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{namei_runner:"artifacts/runtime/namei_ext_application_file_sharing",portal_runner:"artifacts/runtime/xdg_document_portal_oracle",portal:"artifacts/runtime/xdg-document-portal",permission_store:"artifacts/runtime/xdg-permission-store",namei_policy:"artifacts/runtime/application_file_sharing.bpf.o",fuse_counter:"artifacts/runtime/application_file_sharing_fuse_counter.bpf.o",bpftool:"artifacts/runtime/bpftool"},source:{system:"xdg-document-portal",commit:$$portal_commit,metadata:"artifacts/source/xdg-document-portal-metadata.json",upstream_testlog:"artifacts/source/xdg-document-portal-testlog.txt",fuse_implementation:"artifacts/source/document-portal-fuse.c"},analysis:"artifacts/analysis/analyze.py"}' \
	>"$(1)/artifacts/manifest.json"
endef

define APPLICATION_FILE_SHARING_RQ2_START
$(call APPLICATION_FILE_SHARING_RQ2_ASSERT_SHARED_PROTOCOL)
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
$(call NAMEI_EXT_MULTI_BOOT_INIT,$(1))
$(call NAMEI_EXT_RUN_START,$(1),application-file-sharing-rq2-official,xdg-document-portal,kvm_application_file_sharing_rq2_official,$(1)/observations.jsonl,application_file_sharing.bpf.c+application_file_sharing_fuse_counter.bpf.c,xdg_document_portal_oracle+namei_ext_application_file_sharing)
$(call APPLICATION_FILE_SHARING_RQ2_CAPTURE_ARTIFACTS,$(1))
lscpu >"$(1)/host-lscpu.txt"
lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE,MAXMHZ,MINMHZ \
	>"$(1)/host-lscpu-extended.txt"
printf '%s\n' "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_HOST_CPUS)" \
	>"$(1)/host-cpu-pin.txt"
for cpu in $$(seq 4 7); do \
	printf 'cpu=%s governor=%s driver=%s max_khz=%s\n' "$$cpu" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_governor")" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_driver")" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/cpuinfo_max_freq")"; \
done >"$(1)/host-cpu-frequency-policy.txt"
jq \
	--argjson pairs "$(2)" \
	--argjson warmup "$(3)" \
	--argjson samples "$(4)" \
	--argjson seed "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_ANALYSIS_SEED)" \
	--arg host_cpu_pin "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_HOST_CPUS)" \
	--arg source_commit "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)" \
	'.protocol_schema = "namei_ext.application_file_sharing_rq2_official.v1" | .layout = "paired-fresh-boots-alternating-arm-order" | .source_system_commit = $$source_commit | .matrix = {mechanisms:["xdg-document-portal","namei_ext"],pairs:$$pairs,warmup:$$warmup,samples:$$samples,direct_samples:$$samples,order:"alternating",kvm_cpus:4,kvm_memory:"8G",host_cpu_pin:$$host_cpu_pin,analysis_seed:$$seed,bootstrap_repetitions:10000}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
printf '%s\n' "$(5)" >"$(1)/command.txt"
: >"$(1)/launch-order.jsonl"
endef

define APPLICATION_FILE_SHARING_RQ2_RUN_PAIRS
global_order=0; \
for pair in $$(seq 1 "$(2)"); do \
	if test "$$((pair % 2))" = 1; then \
		arms="xdg-document-portal namei_ext"; \
	else \
		arms="namei_ext xdg-document-portal"; \
	fi; \
	pair_order=0; \
	for arm in $$arms; do \
		pair_order=$$((pair_order + 1)); \
		global_order=$$((global_order + 1)); \
		printf '%s|%s|%s\n' "$$pair" "$$pair_order" "$$arm" \
			>>"$(1)/expected-boots.txt"; \
		boot="$(1)/boots/pair-$$(printf '%02d' "$$pair")-order-$$(printf '%02d' "$$pair_order")-$$arm"; \
		install -d "$$boot"; \
		host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$(1)/artifacts/kernel/bzImage" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__application_file_sharing_rq2_official_guest APPLICATION_FILE_SHARING_RQ2_BOOT_DIR=$${boot#$(ROOT_DIR)/} APPLICATION_FILE_SHARING_RQ2_RUN_DIR=$(1) APPLICATION_FILE_SHARING_RQ2_ARM=$$arm APPLICATION_FILE_SHARING_RQ2_PAIR=$$pair APPLICATION_FILE_SHARING_RQ2_ORDER=$$pair_order APPLICATION_FILE_SHARING_RQ2_WARMUP=$(3) APPLICATION_FILE_SHARING_RQ2_SAMPLES=$(4)" \
			NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
			NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(1)" \
			NAMEI_EXT_KVM_CAPTURE_HOST_CPUS="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_HOST_CPUS)" \
			NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_KVM_TIMEOUT)"; \
		host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		jq -cn \
			--argjson global_order "$$global_order" \
			--argjson pair "$$pair" \
			--argjson pair_order "$$pair_order" \
			--arg mechanism "$$arm" \
			--arg started_at "$$host_started_at" \
			--arg completed_at "$$host_completed_at" \
			--arg boot_dir "$${boot#$(1)/}" \
			'{global_order:$$global_order,pair:$$pair,pair_order:$$pair_order,mechanism:$$mechanism,host_started_at:$$started_at,host_completed_at:$$completed_at,boot_dir:$$boot_dir}' \
			>>"$(1)/launch-order.jsonl"; \
	done; \
done
endef

.PHONY: application-file-sharing-rq2-analysis-test \
	application-file-sharing-rq2-official-host-gate \
	kvm-application-file-sharing-rq2-official-preflight \
	kvm-application-file-sharing-rq2-official \
	application-file-sharing-rq2-official-run \
	application-file-sharing-rq2-official-finalize \
	application-file-sharing-rq2-official-analyze \
	experiment-application-file-sharing-rq2-official \
	__application_file_sharing_rq2_official_guest \
	__application_file_sharing_rq2_official_guest_inner \
	__application_file_sharing_rq2_official_guest_mechanism

application-file-sharing-rq2-analysis-test:
	python3 -m unittest discover \
		-s "$(ROOT_DIR)/analysis/application_file_sharing_rq2" \
		-p 'test_*.py'

application-file-sharing-rq2-official-host-gate: bpf \
		application-file-sharing-source \
		application-file-sharing-rq2-analysis-test
	$(call APPLICATION_FILE_SHARING_RQ2_ASSERT_SHARED_PROTOCOL)
	$(MAKE) -C "$(ROOT_DIR)/experiments/application_file_sharing" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" rq2-host-smoke
	test -s "$(APPLICATION_FILE_SHARING_POLICY)"
	test -s "$(APPLICATION_FILE_SHARING_RQ2_FUSE_COUNTER)"
	test -x "$(APPLICATION_FILE_SHARING_RUNNER)"
	test -x "$(APPLICATION_FILE_SHARING_SOURCE_ORACLE)"
	grep -E '^Ok:[[:space:]]+4[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Fail:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Skipped:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null
	grep -E '^Timeout:[[:space:]]+0[[:space:]]*$$' \
		"$(APPLICATION_FILE_SHARING_XDG_PORTAL_TEST_LOG)" >/dev/null

kvm-application-file-sharing-rq2-official-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-rq2-official-preflight: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool \
		application-file-sharing-rq2-official-host-gate
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_PAIRS)" = 1
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_WARMUP)" = 10
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_SAMPLES)" = 100
	$(call APPLICATION_FILE_SHARING_RQ2_START,$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_RESULT_DIR),1,10,100,make kvm-application-file-sharing-rq2-official-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS=1 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_WARMUP=10 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES=100
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS=1 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES=100
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PREFLIGHT_RESULT_DIR))

kvm-application-file-sharing-rq2-official: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-application-file-sharing-rq2-official: experiment-source-clean \
		kernel kernel-provenance kernel-bpftool \
		application-file-sharing-rq2-official-host-gate
	test -f "$(APPLICATION_FILE_SHARING_RQ2_PREFLIGHT_REVIEW)"
	grep -Fx 'Final verdict: GO' \
		"$(APPLICATION_FILE_SHARING_RQ2_PREFLIGHT_REVIEW)"
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_PAIRS)" = 10
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_WARMUP)" = 1000
	test "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_SAMPLES)" = 10000
	$(call APPLICATION_FILE_SHARING_RQ2_START,$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_RESULT_DIR),10,1000,10000,make kvm-application-file-sharing-rq2-official RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-run \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS=10 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_WARMUP=1000 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES=10000
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-finalize \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_RESULT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS=10 \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES=10000
	$(MAKE) -C "$(ROOT_DIR)" application-file-sharing-rq2-official-analyze \
		RUN_ID="$(RUN_ID)" \
		APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR="$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_RESULT_DIR)"
	$(call NAMEI_EXT_RUN_COMPLETE,$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_RESULT_DIR))

experiment-application-file-sharing-rq2-official: \
	kvm-application-file-sharing-rq2-official

application-file-sharing-rq2-official-run:
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_WARMUP)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES)"
	$(call APPLICATION_FILE_SHARING_RQ2_RUN_PAIRS,$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR),$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS),$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_WARMUP),$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES))

application-file-sharing-rq2-official-finalize:
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES)"
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR),$$(($(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS) * 2)))
	test "$$(wc -l <"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/expected-boots.txt")" = \
		"$$((2 * $(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)))"
	test "$$(sort -u "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/expected-boots.txt" | wc -l)" = \
		"$$((2 * $(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)))"
	test "$$(wc -l <"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/launch-order.jsonl")" = \
		"$$((2 * $(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)))"
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/observations.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-summary" and .mechanism == "xdg-document-portal" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)"
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-summary" and .mechanism == "namei_ext" and .pass == true)] | length' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/observations.jsonl")" = \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)"
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR),$$(($(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS) * 2)),$(APPLICATION_FILE_SHARING_RQ2_BOOT_FILES))
	while IFS='|' read -r pair order mechanism; do \
		boot="$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/boots/pair-$$(printf '%02d' "$$pair")-order-$$(printf '%02d' "$$order")-$$mechanism"; \
		test -d "$$boot"; \
		test "$$(cat "$$boot/mechanism.status")" = 0; \
		test "$$(cat "$$boot/guest-inner.status")" = 0; \
		test "$$(cat "$$boot/guest-inventory-after.status")" = 0; \
		test "$$(cat "$$boot/guest-dmesg.status")" = 0; \
		test "$$(cat "$$boot/ext4-cleanup.status")" = 0; \
		awk '$$2 == "ext4" { found = 1 } END { exit !found }' \
			"$$boot/ext4-filesystem.txt"; \
		grep -E 'type=ext2/ext3 magic=ef53|type=ext4 magic=ef53' \
			"$$boot/ext4-statfs.txt" >/dev/null; \
		jq -e --arg mechanism "$$mechanism" --argjson pair "$$pair" --argjson order "$$order" \
			'.status == "completed" and .mechanism == $$mechanism and .pair == $$pair and .pair_order == $$order and .inner_status == 0 and .inventory_after_status == 0 and .dmesg_status == 0 and .clocksource == "tsc"' \
			"$$boot/boot.json" >/dev/null; \
		jq -e '.status == "verified" and .expected_host_cpus == [4,5,6,7] and [.vcpus[].cpus_allowed] == [[4],[5],[6],[7]]' \
			"$$boot/vcpu-affinity.json" >/dev/null; \
		grep -Fx tsc "$$boot/clocksource-before.txt" >/dev/null; \
		grep -Fx tsc "$$boot/clocksource-after.txt" >/dev/null; \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,before); \
		$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$$boot,after); \
		for stream in policy-view direct-ext4; do \
			jq -s -e --arg mechanism "$$mechanism" --arg stream "$$stream" --argjson samples "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES)" '[.[] | select(.event == "application-file-sharing-rq2-sample" and .mechanism == $$mechanism and .stream == $$stream and .phase == "measured" and .pass == true) | .sample] as $$indices | ($$indices | length) == $$samples and ($$indices | sort) == [range(0; $$samples)]' "$$boot/observations.jsonl" >/dev/null; \
		done; \
		jq -s -e --arg mechanism "$$mechanism" --argjson samples "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES)" --argjson warmup "$$(jq -r '.matrix.warmup' "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/run.json")" '([.[] | select(.event == "application-file-sharing-rq2-summary" and .mechanism == $$mechanism and .document_id_bytes == 22 and .payload_bytes == 27 and .warmup_transactions == $$warmup and .measured_transactions == $$samples and .direct_transactions == $$samples and .pass == true)] | length) == 1' "$$boot/observations.jsonl" >/dev/null; \
		test "$$(jq -s --arg mechanism "$$mechanism" '[.[] | select(.event == "application-file-sharing-rq2-control" and .mechanism == $$mechanism and (.operation == "grant" or .operation == "revoke") and .pass == true)] | length' "$$boot/observations.jsonl")" = 2; \
		test "$$(jq -s --arg mechanism "$$mechanism" '[.[] | select(.event == "application-file-sharing-rq2-filesystem" and .mechanism == $$mechanism and .filesystem == "ext4" and .f_type == 61267 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s --arg mechanism "$$mechanism" '[.[] | select(.event == "application-file-sharing-rq2-oracle" and .mechanism == $$mechanism and .phase == "first-after-grant" and .directory_entries == 3 and .payload_bytes == 27 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		test "$$(jq -s --arg mechanism "$$mechanism" '[.[] | select(.event == "application-file-sharing-rq2-hidden-oracle" and .mechanism == $$mechanism and .phase == "first-after-revoke" and .document_stat_errno == 2 and .directory_entries == 2 and .document_listed == false and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
		if test "$$mechanism" = xdg-document-portal; then \
			for file in fuse-request-send.format xdg-document-portal.version.txt xdg-document-portal.ldd.txt xdg-permission-store.ldd.txt source-permission-store.stdout.log source-permission-store.stderr.log source-portal.stdout.log source-portal.stderr.log; do test -f "$$boot/$$file"; done; \
			grep -E 'field:dev_t connection;[[:space:]]+offset:8;[[:space:]]+size:4;' "$$boot/fuse-request-send.format" >/dev/null; \
			grep -E 'field:uint64_t unique;[[:space:]]+offset:16;[[:space:]]+size:8;' "$$boot/fuse-request-send.format" >/dev/null; \
			grep -E 'field:enum fuse_opcode opcode;[[:space:]]+offset:24;[[:space:]]+size:4;' "$$boot/fuse-request-send.format" >/dev/null; \
			grep -E 'field:uint32_t len;[[:space:]]+offset:28;[[:space:]]+size:4;' "$$boot/fuse-request-send.format" >/dev/null; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-source-summary" and .states == 5 and .expected_states == 5 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
			jq -s -e '[.[] | select(.event == "application-file-sharing-source-state" and .pass == true) | .state] | sort == (["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"] | sort)' "$$boot/observations.jsonl" >/dev/null; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-fuse-counter")] | length' "$$boot/observations.jsonl")" = 128; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-fuse-engagement" and .delta > 0 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
			jq -s -e '(([.[] | select(.event == "application-file-sharing-rq2-fuse-counter" and .phase == "after")] | map(select(.opcode as $$opcode | [14,15] | index($$opcode))) | map(.value) | add // 0) - ([.[] | select(.event == "application-file-sharing-rq2-fuse-counter" and .phase == "before")] | map(select(.opcode as $$opcode | [14,15] | index($$opcode))) | map(.value) | add // 0)) > 0 and (([.[] | select(.event == "application-file-sharing-rq2-fuse-counter" and .phase == "after")] | map(select(.opcode as $$opcode | [27,28,44] | index($$opcode))) | map(.value) | add // 0) - ([.[] | select(.event == "application-file-sharing-rq2-fuse-counter" and .phase == "before")] | map(select(.opcode as $$opcode | [27,28,44] | index($$opcode))) | map(.value) | add // 0)) > 0' "$$boot/observations.jsonl" >/dev/null; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-process-snapshot" and (.role == "client" or .role == "portal-daemon") and (.phase == "before" or .phase == "after") and .pass == true)] | length' "$$boot/observations.jsonl")" = 4; \
			grep -Fx 'xdg-desktop-portal $(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)' "$$boot/xdg-document-portal.version.txt" >/dev/null; \
			! grep -F 'not found' "$$boot/xdg-document-portal.ldd.txt"; \
			! grep -F 'not found' "$$boot/xdg-permission-store.ldd.txt"; \
		else \
			for file in lower-document-payload.txt unrelated-document-payload.txt; do test -f "$$boot/$$file"; done; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-summary" and .applications == 2 and .states == 5 and .pass == true)] | length' "$$boot/observations.jsonl")" = 1; \
			jq -s -e '[.[] | select(.event == "application-file-sharing-state" and .pass == true) | .state] | sort == (["application-a-before-grant","application-b-without-grant","application-a-after-grant","application-b-during-a-grant","application-a-after-revoke"] | sort)' "$$boot/observations.jsonl" >/dev/null; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-bpf-counter")] | length' "$$boot/observations.jsonl")" = 16; \
			for counter in select visible_readdir; do \
				jq -s -e --arg counter "$$counter" '([.[] | select(.event == "application-file-sharing-rq2-bpf-counter" and .phase == "before" and .counter == $$counter)] | length) == 1 and ([.[] | select(.event == "application-file-sharing-rq2-bpf-counter" and .phase == "after" and .counter == $$counter)] | length) == 1 and ([.[] | select(.event == "application-file-sharing-rq2-bpf-counter" and .phase == "after" and .counter == $$counter)][0].value > [.[] | select(.event == "application-file-sharing-rq2-bpf-counter" and .phase == "before" and .counter == $$counter)][0].value)' "$$boot/observations.jsonl" >/dev/null; \
			done; \
			test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-process-snapshot" and .role == "client" and (.phase == "before" or .phase == "after") and .pass == true)] | length' "$$boot/observations.jsonl")" = 2; \
		fi; \
	done <"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/expected-boots.txt"
	jq -e --arg run_id "$(RUN_ID)" --argjson pairs "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_PAIRS)" --argjson samples "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_SAMPLES)" \
		'.run_id == $$run_id and .status == "running" and .source.dirty == false and .kernel.dirty == false and .matrix.pairs == $$pairs and .matrix.samples == $$samples and .source_system_commit == "$(APPLICATION_FILE_SHARING_XDG_PORTAL_COMMIT)"' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/run.json" >/dev/null

application-file-sharing-rq2-official-analyze: \
		application-file-sharing-rq2-analysis-test
	test -n "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)"
	jq -e --arg run_id "$(RUN_ID)" \
		'.run_id == $$run_id and .status == "running" and (.completed_at | not) and (.failed_at | not)' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/run.json" >/dev/null
	python3 "$(APPLICATION_FILE_SHARING_RQ2_ANALYSIS)" \
		--run-dir "$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)" \
		--seed "$(APPLICATION_FILE_SHARING_RQ2_OFFICIAL_ANALYSIS_SEED)" \
		--bootstrap 10000
	jq -e '.pairs > 0 and .samples_per_boot > 0 and .primary.portal_over_namei_ext_geomean > 0 and .primary.bootstrap_95_lower > 0 and .primary.bootstrap_95_upper > 0' \
		"$(APPLICATION_FILE_SHARING_RQ2_ACTIVE_DIR)/analysis/summary.json" >/dev/null

__application_file_sharing_rq2_official_guest: __namei_ext_guest_prepare
	inner_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__application_file_sharing_rq2_official_guest_inner \
		APPLICATION_FILE_SHARING_RQ2_BOOT_DIR="$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_RUN_DIR="$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ARM="$(APPLICATION_FILE_SHARING_RQ2_ARM)" \
		APPLICATION_FILE_SHARING_RQ2_PAIR="$(APPLICATION_FILE_SHARING_RQ2_PAIR)" \
		APPLICATION_FILE_SHARING_RQ2_ORDER="$(APPLICATION_FILE_SHARING_RQ2_ORDER)" \
		APPLICATION_FILE_SHARING_RQ2_WARMUP="$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" \
		APPLICATION_FILE_SHARING_RQ2_SAMPLES="$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" || \
		inner_status=$$?; \
	printf '%s\n' "$$inner_status" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/guest-inner.status"; \
	inventory_after_status=0; \
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR),$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/bpftool,after) || \
		inventory_after_status=$$?; \
	printf '%s\n' "$$inventory_after_status" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/guest-inventory-after.status"; \
	cat /sys/devices/system/clocksource/clocksource0/current_clocksource \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/clocksource-after.txt"; \
	dmesg_status=0; \
	dmesg >"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/dmesg.log" || \
		dmesg_status=$$?; \
	if test "$$dmesg_status" -eq 0; then \
		$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/dmesg.log) || \
			dmesg_status=$$?; \
	fi; \
	printf '%s\n' "$$dmesg_status" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/guest-dmesg.status"; \
	clocksource=$$(cat "$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/clocksource-after.txt"); \
	status=completed; \
	if test "$$inner_status" -ne 0 || \
	   test "$$inventory_after_status" -ne 0 || \
	   test "$$dmesg_status" -ne 0 || test "$$clocksource" != tsc; then \
		status=failed; \
	fi; \
	jq -n \
		--arg status "$$status" \
		--arg mechanism "$(APPLICATION_FILE_SHARING_RQ2_ARM)" \
		--argjson pair "$(APPLICATION_FILE_SHARING_RQ2_PAIR)" \
		--argjson pair_order "$(APPLICATION_FILE_SHARING_RQ2_ORDER)" \
		--argjson warmup "$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" \
		--argjson samples "$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" \
		--argjson inner_status "$$inner_status" \
		--argjson inventory_after_status "$$inventory_after_status" \
		--argjson dmesg_status "$$dmesg_status" \
		--arg clocksource "$$clocksource" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.application_file_sharing_rq2_official.boot.v1",status:$$status,mechanism:$$mechanism,pair:$$pair,pair_order:$$pair_order,warmup:$$warmup,samples:$$samples,inner_status:$$inner_status,inventory_after_status:$$inventory_after_status,dmesg_status:$$dmesg_status,clocksource:$$clocksource,completed_at:$$completed_at}' \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/boot.json"; \
	test "$$status" = completed

__application_file_sharing_rq2_official_guest_inner:
	test -n "$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)"
	case "$(APPLICATION_FILE_SHARING_RQ2_ARM)" in \
		xdg-document-portal|namei_ext) ;; \
		*) exit 2 ;; \
	esac
	test "$(APPLICATION_FILE_SHARING_RQ2_PAIR)" -ge 1
	test "$(APPLICATION_FILE_SHARING_RQ2_ORDER)" -ge 1
	test "$(APPLICATION_FILE_SHARING_RQ2_ORDER)" -le 2
	test "$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" -ge 1
	test "$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" -ge 1
	test -x "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing"
	test -x "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg_document_portal_oracle"
	test -x "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-document-portal"
	test -x "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-permission-store"
	test -r "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o"
	test -r "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/application_file_sharing_fuse_counter.bpf.o"
	test -x "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/bpftool"
	command -v dbus-daemon >/dev/null
	command -v fusermount3 >/dev/null
	test -c /dev/fuse
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR),$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/kernel/config,$(shell cat $(KERNEL_COMMIT_FILE)),$(shell sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' $(KERNEL_RELEASE_HEADER)))
	cat /sys/devices/system/clocksource/clocksource0/current_clocksource \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/clocksource-before.txt"
	grep -Fx tsc "$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/clocksource-before.txt" >/dev/null
	$(call NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY,$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR),$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/bpftool,before)
	$(call APPLICATION_FILE_SHARING_VALIDATE_EXTERNAL,$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR),before)
	: >"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/observations.jsonl"
	ext4_image=/tmp/namei-ext-rq2-$$(printf '%02d' "$(APPLICATION_FILE_SHARING_RQ2_PAIR)")-$$(printf '%02d' "$(APPLICATION_FILE_SHARING_RQ2_ORDER)").img; \
	ext4_mount=/mnt/namei-ext-rq2; \
	mechanism_status=0; \
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
		__application_file_sharing_rq2_official_guest_mechanism \
		APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE="$$ext4_image" \
		APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT="$$ext4_mount" \
		APPLICATION_FILE_SHARING_RQ2_BOOT_DIR="$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_RUN_DIR="$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)" \
		APPLICATION_FILE_SHARING_RQ2_ARM="$(APPLICATION_FILE_SHARING_RQ2_ARM)" \
		APPLICATION_FILE_SHARING_RQ2_WARMUP="$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" \
		APPLICATION_FILE_SHARING_RQ2_SAMPLES="$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" || \
		mechanism_status=$$?; \
	ext4_cleanup_status=0; \
	if mountpoint -q "$$ext4_mount"; then \
		sync; \
		umount "$$ext4_mount" || ext4_cleanup_status=$$?; \
	fi; \
	if test -d "$$ext4_mount"; then \
		rmdir "$$ext4_mount" || ext4_cleanup_status=$$?; \
	fi; \
	if test -e "$$ext4_image"; then \
		rm -f "$$ext4_image" || ext4_cleanup_status=$$?; \
	fi; \
	printf '%s\n' "$$ext4_cleanup_status" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/ext4-cleanup.status"; \
	if test "$$ext4_cleanup_status" -ne 0 && \
	   test "$$mechanism_status" -eq 0; then \
		mechanism_status=$$ext4_cleanup_status; \
	fi; \
	printf '%s\n' "$$mechanism_status" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/mechanism.status"; \
	test "$$mechanism_status" -eq 0
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null

__application_file_sharing_rq2_official_guest_mechanism:
	test -n "$(APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE)"
	test -n "$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)"
	test ! -e "$(APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE)"
	test ! -e "$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)"
	truncate -s 512M "$(APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE)"
	mkfs.ext4 -q -F -m 0 "$(APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE)" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/mkfs-ext4.log" 2>&1
	install -d "$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)"
	mount -t ext4 -o loop,noatime,nosuid,nodev \
		"$(APPLICATION_FILE_SHARING_RQ2_EXT4_IMAGE)" \
		"$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)"
	test "$$(findmnt -rn -T "$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)" -o FSTYPE)" = ext4
	findmnt -rn -T "$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)" \
		-o SOURCE,FSTYPE,OPTIONS,TARGET \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/ext4-filesystem.txt"
	stat -f -c 'type=%T magic=%t block_size=%S blocks=%b available=%a' \
		"$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)" \
		>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/ext4-statfs.txt"
	if test "$(APPLICATION_FILE_SHARING_RQ2_ARM)" = xdg-document-portal; then \
		trace_format=/sys/kernel/debug/tracing/events/fuse/fuse_request_send/format; \
		test -r "$$trace_format"; \
		cat "$$trace_format" \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/fuse-request-send.format"; \
		grep -E 'field:dev_t connection;[[:space:]]+offset:8;[[:space:]]+size:4;' "$$trace_format" >/dev/null; \
		grep -E 'field:uint64_t unique;[[:space:]]+offset:16;[[:space:]]+size:8;' "$$trace_format" >/dev/null; \
		grep -E 'field:enum fuse_opcode opcode;[[:space:]]+offset:24;[[:space:]]+size:4;' "$$trace_format" >/dev/null; \
		grep -E 'field:uint32_t len;[[:space:]]+offset:28;[[:space:]]+size:4;' "$$trace_format" >/dev/null; \
		"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-document-portal" --version \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-document-portal.version.txt"; \
		grep -Fx 'xdg-desktop-portal $(APPLICATION_FILE_SHARING_XDG_PORTAL_VERSION)' \
			"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-document-portal.version.txt" >/dev/null; \
		ldd "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-document-portal" \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-document-portal.ldd.txt"; \
		! grep -F 'not found' "$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-document-portal.ldd.txt"; \
		ldd "$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-permission-store" \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-permission-store.ldd.txt"; \
		! grep -F 'not found' "$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/xdg-permission-store.ldd.txt"; \
		"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg_document_portal_oracle" \
			"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-document-portal" \
			"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/xdg-permission-store" \
			"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/observations.jsonl" \
			"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)" \
			"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/application_file_sharing_fuse_counter.bpf.o" \
			"$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" \
			"$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" \
			"$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)" \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/stdout-controller.log" \
			2>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/stderr-controller.log"; \
	else \
		"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/namei_ext_application_file_sharing" \
			"$(APPLICATION_FILE_SHARING_RQ2_RUN_DIR)/artifacts/runtime/application_file_sharing.bpf.o" \
			"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/observations.jsonl" \
			"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)" \
			/sys/fs/cgroup \
			"$(APPLICATION_FILE_SHARING_RQ2_WARMUP)" \
			"$(APPLICATION_FILE_SHARING_RQ2_SAMPLES)" \
			"$(APPLICATION_FILE_SHARING_RQ2_EXT4_ROOT)" \
			>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/stdout-controller.log" \
			2>"$(APPLICATION_FILE_SHARING_RQ2_BOOT_DIR)/stderr-controller.log"; \
	fi
