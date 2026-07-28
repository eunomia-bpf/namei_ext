ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
CACHE_ROOT ?= $(ROOT_DIR)/.cache
RESULT_ROOT ?= $(ROOT_DIR)/results
OUTPUT ?= $(BUILD_ROOT)/checkpoint-restore
KERNEL_DIR ?= $(ROOT_DIR)/kernel
include $(ROOT_DIR)/configs/benchmarks/workload-sources.mk
include $(ROOT_DIR)/mk/results.mk
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
LIBBPF_SOURCES := $(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] $(KERNEL_DIR)/tools/lib/bpf/Makefile)
HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a
HARNESS_SOURCES := $(ROOT_DIR)/runner/src/namei_ext_harness.c \
	$(ROOT_DIR)/runner/include/namei_ext_harness.h
DMTCP_INSTALL ?= $(BUILD_ROOT)/workloads/dmtcp-$(DMTCP_COMMIT_SHORT)/install
DMTCP_INCLUDE ?= $(DMTCP_INSTALL)/include
DMTCP_SOURCE ?= $(BUILD_ROOT)/workloads/dmtcp-$(DMTCP_COMMIT_SHORT)/$(DMTCP_SOURCE_DIR_NAME)
DMTCP_ARCHIVE ?= $(CACHE_ROOT)/workloads/$(DMTCP_ARCHIVE_NAME)
DMTCP_BUILD_PROVENANCE ?= $(RESULT_ROOT)/workloads/provenance/build/dmtcp-$(DMTCP_COMMIT_SHORT)/build.json
DMTCP_INSTALL_MANIFEST ?= $(RESULT_ROOT)/workloads/provenance/build/dmtcp-$(DMTCP_COMMIT_SHORT)/install-tree.sha256
RUN_ID ?= $(shell date -u +%Y%m%dT%H%M%SZ)-$(shell od -An -N4 -tx4 /dev/urandom 2>/dev/null | tr -d ' \n')
PATHVIRT_HOST_RESULT_DIR ?= $(RESULT_ROOT)/workloads/preflight/checkpoint-restore-pathvirt/$(RUN_ID)
PATHVIRT_HOST_TIMEOUT ?= 120
CC ?= cc

.PHONY: all pathvirt-host-preflight clean

all: $(OUTPUT)/namei_ext_checkpoint_restore \
	$(OUTPUT)/checkpoint_restore_app

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(HARNESS_LIBRARY): $(HARNESS_SOURCES)
	$(MAKE) -C "$(ROOT_DIR)/runner" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

$(OUTPUT)/namei_ext_checkpoint_restore: namei_ext_checkpoint_restore.c $(HARNESS_LIBRARY) $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(HARNESS_LIBRARY)" "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/checkpoint_restore_app: checkpoint_restore_app.c $(DMTCP_INCLUDE)/dmtcp.h | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra -I"$(DMTCP_INCLUDE)" -o "$@" "$<" -ldl

pathvirt-host-preflight: all
	test "$(PATHVIRT_HOST_TIMEOUT)" = 120
	command -v timeout >/dev/null
	test -s "$(DMTCP_BUILD_PROVENANCE)"
	test -s "$(DMTCP_INSTALL_MANIFEST)"
	test -s "$(DMTCP_ARCHIVE)"
	test ! -e "$(PATHVIRT_HOST_RESULT_DIR)"
	test -f "$(DMTCP_SOURCE)/Makefile"
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(PATHVIRT_HOST_RESULT_DIR))
	$(call NAMEI_EXT_RUN_START,$(PATHVIRT_HOST_RESULT_DIR),checkpoint-restore,dmtcp-pathvirt,host_dependency_preflight,$(PATHVIRT_HOST_RESULT_DIR)/observations.jsonl,none,namei_ext_checkpoint_restore+checkpoint_restore_app)
	install -m 0444 "$(DMTCP_BUILD_PROVENANCE)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-build.json"
	install -m 0444 "$(DMTCP_RESTART_ENV_PATCH)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/restart-env-scan-count.patch"
	install -m 0444 "$(DMTCP_ARCHIVE)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source.tar.gz"
	install -m 0444 "$(DMTCP_INSTALL_MANIFEST)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-install-tree.sha256"
	install -d \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/src" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/test" \
		"$(PATHVIRT_HOST_RESULT_DIR)/runtime"
	install -m 0444 "$(DMTCP_SOURCE)/src/dmtcpplugin.cpp" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/src/dmtcpplugin.cpp"
	install -m 0444 "$(DMTCP_SOURCE)/src/plugin_pathtranslator.cpp" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/src/plugin_pathtranslator.cpp"
	install -m 0444 "$(DMTCP_SOURCE)/test/pathvirt1.c" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/test/pathvirt1.c"
	install -m 0444 "$(DMTCP_SOURCE)/test/autotest.py" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/test/autotest.py"
	cp -a "$(DMTCP_INSTALL)" "$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-install"
	install -m 0555 "$(OUTPUT)/namei_ext_checkpoint_restore" \
		"$(PATHVIRT_HOST_RESULT_DIR)/runtime/namei_ext_checkpoint_restore"
	install -m 0555 "$(OUTPUT)/checkpoint_restore_app" \
		"$(PATHVIRT_HOST_RESULT_DIR)/runtime/checkpoint_restore_app"
	printf '%s  %s\n' "$(DMTCP_ARCHIVE_SHA256)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source.tar.gz" | sha256sum -c -
	printf '%s  %s\n' "$(DMTCP_RESTART_ENV_PATCH_SHA256)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/restart-env-scan-count.patch" | sha256sum -c -
	printf '%s\n' \
		'make checkpoint-restore-pathvirt-host-preflight RUN_ID=$(RUN_ID) PATHVIRT_HOST_TIMEOUT=$(PATHVIRT_HOST_TIMEOUT)' \
		>"$(PATHVIRT_HOST_RESULT_DIR)/command.txt"
	sha256sum \
		"$(ROOT_DIR)/configs/benchmarks/workload-sources.mk" \
		"$(ROOT_DIR)/mk/workload.mk" \
		"$(ROOT_DIR)/mk/results.mk" \
		"$(ROOT_DIR)/experiments/checkpoint_restore/Makefile" \
		"$(ROOT_DIR)/experiments/checkpoint_restore/namei_ext_checkpoint_restore.c" \
		"$(ROOT_DIR)/experiments/checkpoint_restore/checkpoint_restore_app.c" \
		"$(DMTCP_RESTART_ENV_PATCH)" \
		"$(DMTCP_SOURCE)/src/dmtcpplugin.cpp" \
		"$(DMTCP_SOURCE)/src/plugin_pathtranslator.cpp" \
		"$(DMTCP_SOURCE)/test/pathvirt1.c" \
		"$(DMTCP_SOURCE)/test/autotest.py" \
		>"$(PATHVIRT_HOST_RESULT_DIR)/inputs.sha256"
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && \
		sha256sum \
			dmtcp-install/bin/dmtcp_launch \
			dmtcp-install/bin/dmtcp_coordinator \
			dmtcp-install/bin/dmtcp_command \
			dmtcp-install/bin/dmtcp_restart \
			dmtcp-install/bin/mtcp_restart \
			dmtcp-install/lib/dmtcp/libdmtcp.so \
			runtime/namei_ext_checkpoint_restore \
			runtime/checkpoint_restore_app \
			>artifacts.sha256)
	for file in src/dmtcpplugin.cpp src/plugin_pathtranslator.cpp \
			test/pathvirt1.c test/autotest.py; do \
		expected=$$(jq -r --arg file "$$file" '.source.pinned_files[$$file]' \
			"$(DMTCP_BUILD_PROVENANCE)"); \
		test "$$(sha256sum "$(DMTCP_SOURCE)/$$file" | awk '{print $$1}')" = "$$expected"; \
		test "$$(sha256sum "$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-source/$$file" | \
			awk '{print $$1}')" = "$$expected"; \
	done
	for file in dmtcp_launch dmtcp_coordinator dmtcp_command dmtcp_restart; do \
		test "$$(sha256sum "$(DMTCP_SOURCE)/bin/$$file" | awk '{print $$1}')" = \
			"$$(sha256sum "$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-install/bin/$$file" | awk '{print $$1}')"; \
	done
	(cd "$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-install" && \
		sha256sum -c ../dmtcp-install-tree.sha256)
	uname -a >"$(PATHVIRT_HOST_RESULT_DIR)/host-uname.txt"
	cat /proc/version >"$(PATHVIRT_HOST_RESULT_DIR)/host-proc-version.txt"
	timeout --signal=TERM --kill-after=10s "$(PATHVIRT_HOST_TIMEOUT)" \
		$(MAKE) -C "$(DMTCP_SOURCE)" check-autotest AUTOTEST=pathvirt \
		>"$(PATHVIRT_HOST_RESULT_DIR)/upstream-autotest.stdout.log" \
		2>"$(PATHVIRT_HOST_RESULT_DIR)/upstream-autotest.stderr.log"
	grep -F 'test groups: pass=1 fail=0 skipped=0 total=1' \
		"$(PATHVIRT_HOST_RESULT_DIR)/upstream-autotest.stdout.log"
	"$(PATHVIRT_HOST_RESULT_DIR)/runtime/namei_ext_checkpoint_restore" \
		pathvirt "$(PATHVIRT_HOST_RESULT_DIR)/observations.jsonl" \
		"$(PATHVIRT_HOST_RESULT_DIR)" \
		"$(PATHVIRT_HOST_RESULT_DIR)/dmtcp-install" /dev/null \
		"$(PATHVIRT_HOST_RESULT_DIR)/runtime/checkpoint_restore_app" \
		/sys/fs/cgroup/namei-ext-checkpoint-restore-host \
		"$(PATHVIRT_HOST_TIMEOUT)" \
		>"$(PATHVIRT_HOST_RESULT_DIR)/stdout.log" \
		2>"$(PATHVIRT_HOST_RESULT_DIR)/stderr.log"
	jq -s -e \
		'length > 0 and all(.[]; .pass == true) and any(.[]; .event == "checkpoint-restore-summary" and .condition == "pathvirt" and .failures == 0)' \
		"$(PATHVIRT_HOST_RESULT_DIR)/observations.jsonl" >/dev/null
	jq -s -e \
		'length == 2 and ([.[] | select(.stage == "pre-checkpoint" and .generation == "a" and .restarts == 0 and .saw_stale == true and .saw_new == false and .pass == true)] | length) == 1 and ([.[] | select(.stage == "post-restart" and .generation == "b" and .restarts > 0 and .saw_stale == false and .saw_new == true and .restart_env_status == 0 and (.restart_mapping | contains("generation-b/workspace")) and (.checkpoint_mapping | contains("generation-a/workspace")) and .pass == true)] | length) == 1' \
		"$(PATHVIRT_HOST_RESULT_DIR)/application-observations.jsonl" >/dev/null
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && \
		sha256sum dmtcp-build.json dmtcp-source.tar.gz \
			restart-env-scan-count.patch dmtcp-install-tree.sha256 \
			command.txt inputs.sha256 artifacts.sha256 \
			dmtcp-source/src/dmtcpplugin.cpp \
			dmtcp-source/src/plugin_pathtranslator.cpp \
			dmtcp-source/test/pathvirt1.c dmtcp-source/test/autotest.py \
			observations.jsonl application-observations.jsonl \
			lower-before.jsonl lower-after.jsonl \
			checkpoint-images.txt checkpoint-images.sha256 \
			stdout.log stderr.log \
			host-uname.txt host-proc-version.txt \
			upstream-autotest.stdout.log upstream-autotest.stderr.log \
			dmtcp-coordinator.stdout.log dmtcp-coordinator.stderr.log \
			dmtcp-launch.stdout.log dmtcp-launch.stderr.log \
			dmtcp-command.stdout.log dmtcp-command.stderr.log \
			dmtcp-restart.stdout.log dmtcp-restart.stderr.log \
			>evidence.sha256)
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && sha256sum -c evidence.sha256)
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && sha256sum -c checkpoint-images.sha256)
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && sha256sum -c inputs.sha256)
	(cd "$(PATHVIRT_HOST_RESULT_DIR)" && sha256sum -c artifacts.sha256)
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(PATHVIRT_HOST_RESULT_DIR),$(PATHVIRT_HOST_RESULT_DIR)/observations.jsonl)
	$(call NAMEI_EXT_RUN_COMPLETE,$(PATHVIRT_HOST_RESULT_DIR))
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(PATHVIRT_HOST_RESULT_DIR))

clean:
	rm -rf "$(OUTPUT)"
