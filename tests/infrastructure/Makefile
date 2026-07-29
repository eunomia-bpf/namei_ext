SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
RUN_ID ?= result-contract-test
OUTPUT_ROOT ?= $(BUILD_ROOT)/tests/result-contract
OUTPUT ?= $(OUTPUT_ROOT)/$(RUN_ID)
RESULT_JSON ?= $(OUTPUT)/observations.jsonl
SOURCE_FIXTURE_ROOT ?= $(OUTPUT_ROOT)/source-state-fixture
KERNEL_IDENTITY_ROOT ?= $(OUTPUT_ROOT)/kernel-identity
MULTI_BOOT_ROOT ?= $(OUTPUT_ROOT)/multi-boot

include $(ROOT_DIR)/mk/results.mk
include $(ROOT_DIR)/mk/multi_boot.mk

.PHONY: test validate-only create-only multi-boot-collect-only \
	multi-boot-collect-nested-only multi-boot-validate-only \
	multi-boot-validate-nested-only analysis-publish-only \
	published-result-contract clean

analysis-publish-only:
	test -n "$(ANALYSIS_PATH)"
	$(call NAMEI_EXT_ANALYSIS_PUBLISH,$(ANALYSIS_PATH))

published-result-contract:
	PYTHONPATH="$(ROOT_DIR)/tests/infrastructure" \
		python3 -m unittest discover \
		-s "$(ROOT_DIR)/tests/infrastructure" -p 'test_*.py' -v
	python3 "$(ROOT_DIR)/tests/infrastructure/validate_published_results.py" \
		--repo "$(ROOT_DIR)" \
		--index "$(ROOT_DIR)/configs/publication/published-formal.json"

test: published-result-contract
	PYTHONPATH="$(ROOT_DIR)/analysis/fxmark" \
		python3 "$(ROOT_DIR)/analysis/fxmark/test_analyze.py"
	PYTHONPATH="$(ROOT_DIR)/analysis/agent_workspace" \
		python3 "$(ROOT_DIR)/analysis/agent_workspace/test_analyze.py"
	PYTHONPATH="$(ROOT_DIR)/analysis/build_action_rq2" \
		python3 "$(ROOT_DIR)/analysis/build_action_rq2/test_analyze.py"
	rm -rf "$(OUTPUT)"
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(OUTPUT))
	printf '%s\n' 'make result-contract' >"$(OUTPUT)/command.txt"
	sha256sum "$(ROOT_DIR)/mk/results.mk" >"$(OUTPUT)/inputs.sha256"
	sha256sum "$(ROOT_DIR)/Makefile" >"$(OUTPUT)/artifacts.sha256"
	: >"$(OUTPUT)/stdout.log"
	: >"$(OUTPUT)/stderr.log"
	: >"$(OUTPUT)/launcher.stdout.log"
	: >"$(OUTPUT)/launcher.stderr.log"
	printf '%s\n' 'CONFIG_NAMEI_EXT=y' >"$(OUTPUT)/kernel.config"
	uname -a >"$(OUTPUT)/uname.txt"
	cat /proc/version >"$(OUTPUT)/proc-version.txt"
	cat /proc/cmdline >"$(OUTPUT)/kernel-cmdline.txt"
	printf '%s\n' 'result-contract dmesg fixture' >"$(OUTPUT)/dmesg.log"
	$(call NAMEI_EXT_RUN_START,$(OUTPUT),result-contract,self-test,host_result_contract,$(RESULT_JSON),none,make)
	printf '%s\n' '{"event":"result-contract","pass":true}' >"$(RESULT_JSON)"
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(OUTPUT),$(RESULT_JSON))
	jq -e '.schema == "namei_ext.run.v2" and (.source.dirty | type == "boolean") and (.kernel.dirty | type == "boolean")' "$(OUTPUT)/run.json" >/dev/null
	test "$$(cat "$(OUTPUT)/source-commit.txt")" = "$$(git -C "$(ROOT_DIR)" rev-parse HEAD)"
	test "$$(cat "$(OUTPUT)/kernel-commit.txt")" = "$$(git -C "$(ROOT_DIR)/kernel" rev-parse HEAD)"
	rm -rf "$(SOURCE_FIXTURE_ROOT)"
	for repo in source kernel; do \
		git init -q "$(SOURCE_FIXTURE_ROOT)/$$repo"; \
		git -C "$(SOURCE_FIXTURE_ROOT)/$$repo" config user.name namei-ext-test; \
		git -C "$(SOURCE_FIXTURE_ROOT)/$$repo" config user.email namei-ext-test@example.invalid; \
		git -C "$(SOURCE_FIXTURE_ROOT)/$$repo" config commit.gpgsign false; \
		printf '%s\n' tracked >"$(SOURCE_FIXTURE_ROOT)/$$repo/tracked"; \
		git -C "$(SOURCE_FIXTURE_ROOT)/$$repo" add tracked; \
		git -C "$(SOURCE_FIXTURE_ROOT)/$$repo" commit -qm fixture; \
	done
	$(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"
	printf '%s\n' dirty >"$(SOURCE_FIXTURE_ROOT)/source/untracked"
	if $(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"; then \
		printf '%s\n' 'dirty source tree unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm -f "$(SOURCE_FIXTURE_ROOT)/source/untracked"
	printf '%s\n' unstaged >>"$(SOURCE_FIXTURE_ROOT)/source/tracked"
	if $(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"; then \
		printf '%s\n' 'unstaged source change unexpectedly passed' >&2; \
		exit 1; \
	fi
	git -C "$(SOURCE_FIXTURE_ROOT)/source" add tracked
	if $(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"; then \
		printf '%s\n' 'staged source change unexpectedly passed' >&2; \
		exit 1; \
	fi
	git -C "$(SOURCE_FIXTURE_ROOT)/source" commit -qm staged-fixture
	printf '%s\n' unstaged >>"$(SOURCE_FIXTURE_ROOT)/kernel/tracked"
	if $(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"; then \
		printf '%s\n' 'unstaged kernel change unexpectedly passed' >&2; \
		exit 1; \
	fi
	git -C "$(SOURCE_FIXTURE_ROOT)/kernel" add tracked
	if $(MAKE) --no-print-directory experiment-source-clean \
		NAMEI_EXT_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/source" \
		NAMEI_EXT_KERNEL_SOURCE_DIR="$(SOURCE_FIXTURE_ROOT)/kernel"; then \
		printf '%s\n' 'staged kernel change unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm -rf "$(SOURCE_FIXTURE_ROOT)"
	rm -rf "$(KERNEL_IDENTITY_ROOT)"
	install -d "$(KERNEL_IDENTITY_ROOT)/build/kernel"
	printf '%s\n' "$$(printf '1%.0s' {1..40})" \
		>"$(KERNEL_IDENTITY_ROOT)/build/kernel/.source-commit"
	printf '%s\n' stale >"$(KERNEL_IDENTITY_ROOT)/build/kernel/stale-object"
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel-source-identity \
		BUILD_ROOT="$(KERNEL_IDENTITY_ROOT)/build" \
		CACHE_ROOT="$(KERNEL_IDENTITY_ROOT)/cache" \
		KERNEL_SOURCE_COMMIT="$$(printf '2%.0s' {1..40})"
	test ! -e "$(KERNEL_IDENTITY_ROOT)/build/kernel/stale-object"
	test "$$(cat "$(KERNEL_IDENTITY_ROOT)/build/kernel/.source-commit")" = \
		"$$(printf '2%.0s' {1..40})"
	printf '%s\n' current >"$(KERNEL_IDENTITY_ROOT)/build/kernel/current-object"
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel-source-identity \
		BUILD_ROOT="$(KERNEL_IDENTITY_ROOT)/build" \
		CACHE_ROOT="$(KERNEL_IDENTITY_ROOT)/cache" \
		KERNEL_SOURCE_COMMIT="$$(printf '2%.0s' {1..40})"
	test -e "$(KERNEL_IDENTITY_ROOT)/build/kernel/current-object"
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel-source-identity \
		BUILD_ROOT="$(KERNEL_IDENTITY_ROOT)/build" \
		CACHE_ROOT="$(KERNEL_IDENTITY_ROOT)/cache" \
		KERNEL_SOURCE_COMMIT="$$(printf '3%.0s' {1..40})"
	test ! -e "$(KERNEL_IDENTITY_ROOT)/build/kernel/current-object"
	test "$$(cat "$(KERNEL_IDENTITY_ROOT)/build/kernel/.source-commit")" = \
		"$$(printf '3%.0s' {1..40})"
	install -d "$(ROOT_DIR)/.cache/locks"
	rm -rf "$(KERNEL_IDENTITY_ROOT)/locked-build" \
		"$(KERNEL_IDENTITY_ROOT)/alternate-cache"
	exec 8>"$(ROOT_DIR)/.cache/locks/kernel-build.lock"; \
	flock 8; \
	(exec 8>&-; $(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel-source-identity \
		BUILD_ROOT="$(KERNEL_IDENTITY_ROOT)/locked-build" \
		CACHE_ROOT="$(KERNEL_IDENTITY_ROOT)/alternate-cache" \
		KERNEL_SOURCE_COMMIT="$$(printf '4%.0s' {1..40})" \
		>"$(KERNEL_IDENTITY_ROOT)/locked-identity.log" 2>&1) & \
	pid=$$!; \
	sleep 0.2; \
	kill -0 "$$pid"; \
	test ! -e "$(KERNEL_IDENTITY_ROOT)/locked-build/kernel/.source-commit"; \
	flock -u 8; \
	wait "$$pid"
	test "$$(cat "$(KERNEL_IDENTITY_ROOT)/locked-build/kernel/.source-commit")" = \
		"$$(printf '4%.0s' {1..40})"
	rm -rf "$(KERNEL_IDENTITY_ROOT)/clean-build" \
		"$(KERNEL_IDENTITY_ROOT)/clean-cache"
	install -d "$(KERNEL_IDENTITY_ROOT)/clean-build"
	printf '%s\n' sentinel >"$(KERNEL_IDENTITY_ROOT)/clean-build/sentinel"
	exec 8>"$(ROOT_DIR)/.cache/locks/kernel-build.lock"; \
	flock 8; \
	(exec 8>&-; $(MAKE) --no-print-directory -C "$(ROOT_DIR)" clean \
		BUILD_ROOT="$(KERNEL_IDENTITY_ROOT)/clean-build" \
		CACHE_ROOT="$(KERNEL_IDENTITY_ROOT)/clean-cache" \
		>"$(KERNEL_IDENTITY_ROOT)/locked-clean.log" 2>&1) & \
	pid=$$!; \
	sleep 0.2; \
	kill -0 "$$pid"; \
	test -e "$(KERNEL_IDENTITY_ROOT)/clean-build/sentinel"; \
	flock -u 8; \
	wait "$$pid"
	test ! -e "$(KERNEL_IDENTITY_ROOT)/clean-build"
	mv "$(OUTPUT)/dmesg.log" "$(OUTPUT)/dmesg.log.saved"
	if $(MAKE) --no-print-directory validate-only \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(OUTPUT)" RUN_ID="$(RUN_ID)"; then \
		printf '%s\n' 'missing dmesg.log unexpectedly passed' >&2; \
		exit 1; \
	fi
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(OUTPUT)/run.json" >/dev/null
	mv "$(OUTPUT)/dmesg.log.saved" "$(OUTPUT)/dmesg.log"
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(OUTPUT),$(RESULT_JSON))
	$(call NAMEI_EXT_RUN_COMPLETE,$(OUTPUT))
	$(call NAMEI_EXT_RUN_VALIDATE_COMPLETE,$(OUTPUT))
	if $(MAKE) --no-print-directory create-only \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(OUTPUT)" RUN_ID="$(RUN_ID)"; then \
		printf '%s\n' 'existing result root unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm -rf "$(MULTI_BOOT_ROOT)"
	install -d "$(MULTI_BOOT_ROOT)"
	$(call NAMEI_EXT_MULTI_BOOT_INIT,$(MULTI_BOOT_ROOT))
	for boot in two one; do \
		install -d "$(MULTI_BOOT_ROOT)/boots/$$boot"; \
		printf '{"boot":"%s"}\n' "$$boot" \
			>"$(MULTI_BOOT_ROOT)/boots/$$boot/observations.jsonl"; \
		printf '{}\n' >"$(MULTI_BOOT_ROOT)/boots/$$boot/boot.json"; \
		printf 'required\n' >"$(MULTI_BOOT_ROOT)/boots/$$boot/required.txt"; \
	done
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(MULTI_BOOT_ROOT),2)
	test "$$(wc -l <"$(MULTI_BOOT_ROOT)/observations.jsonl")" = "2"
	test "$$(jq -s -c '[.[].boot]' "$(MULTI_BOOT_ROOT)/observations.jsonl")" = \
		'["one","two"]'
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(MULTI_BOOT_ROOT),2,boot.json observations.jsonl required.txt)
	printf '%s\n' 'FIRST := one' 'SECOND := two' \
		>"$(MULTI_BOOT_ROOT)/boots/one/guest.mk"
	$(call NAMEI_EXT_MULTI_BOOT_SEAL_GUEST_MAKEFILE,$(MULTI_BOOT_ROOT)/boots/one/guest.mk,2)
	(cd "$(MULTI_BOOT_ROOT)/boots/one" && sha256sum -c guest.mk.sha256)
	install -d "$(MULTI_BOOT_ROOT)/boots/one/nested"
	printf '{}\n' >"$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json"
	printf '{"boot":"extra"}\n' \
		>"$(MULTI_BOOT_ROOT)/boots/one/nested/observations.jsonl"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'extra nested boot evidence unexpectedly passed' >&2; \
		exit 1; \
	fi
	if $(MAKE) --no-print-directory multi-boot-collect-only; then \
		printf '%s\n' 'extra nested observations unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm "$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json"
	$(MAKE) --no-print-directory multi-boot-collect-nested-only
	$(MAKE) --no-print-directory multi-boot-validate-nested-only
	test "$$(wc -l <"$(MULTI_BOOT_ROOT)/observations.jsonl")" = "2"
	install -d "$(MULTI_BOOT_ROOT)/boots/two/nested"
	printf '{"boot":"second-extra"}\n' \
		>"$(MULTI_BOOT_ROOT)/boots/two/nested/observations.jsonl"
	if $(MAKE) --no-print-directory multi-boot-collect-nested-only; then \
		printf '%s\n' 'wrong nested observation count unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm "$(MULTI_BOOT_ROOT)/boots/two/nested/observations.jsonl" \
		"$(MULTI_BOOT_ROOT)/boots/one/nested/observations.jsonl"
	ln -s ../../two/observations.jsonl \
		"$(MULTI_BOOT_ROOT)/boots/one/nested/observations.jsonl"
	if $(MAKE) --no-print-directory multi-boot-collect-nested-only; then \
		printf '%s\n' 'nested observation symlink unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm "$(MULTI_BOOT_ROOT)/boots/one/nested/observations.jsonl"
	rm "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'missing multi-boot artifact unexpectedly passed' >&2; \
		exit 1; \
	fi
	printf 'required\n' >"$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	rm "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	install -d "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'directory multi-boot artifact unexpectedly passed' >&2; \
		exit 1; \
	fi
	rmdir "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	ln -s /etc/passwd "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'symlink multi-boot artifact unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm "$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	printf 'required\n' >"$(MULTI_BOOT_ROOT)/boots/two/required.txt"
	ln -s ../../two/boot.json \
		"$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'nested symlink boot artifact unexpectedly passed' >&2; \
		exit 1; \
	fi
	rm "$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json"
	mv "$(MULTI_BOOT_ROOT)/boots/two/boot.json" \
		"$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json"
	if $(MAKE) --no-print-directory multi-boot-validate-only; then \
		printf '%s\n' 'nested boot artifact unexpectedly passed' >&2; \
		exit 1; \
	fi
	mv "$(MULTI_BOOT_ROOT)/boots/one/nested/boot.json" \
		"$(MULTI_BOOT_ROOT)/boots/two/boot.json"
	mv "$(MULTI_BOOT_ROOT)/boots/two/observations.jsonl" \
		"$(MULTI_BOOT_ROOT)/boots/one/nested/observations.jsonl"
	if $(MAKE) --no-print-directory multi-boot-collect-only; then \
		printf '%s\n' 'nested observations unexpectedly passed' >&2; \
		exit 1; \
	fi

validate-only:
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(OUTPUT),$(RESULT_JSON))

create-only:
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(OUTPUT))

multi-boot-collect-only:
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(MULTI_BOOT_ROOT),2)

multi-boot-collect-nested-only:
	$(call NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS,$(MULTI_BOOT_ROOT),2,1)

multi-boot-validate-only:
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(MULTI_BOOT_ROOT),2,boot.json observations.jsonl required.txt)

multi-boot-validate-nested-only:
	$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES,$(MULTI_BOOT_ROOT),2,boot.json observations.jsonl required.txt,1)

clean:
	rm -rf "$(OUTPUT_ROOT)"
