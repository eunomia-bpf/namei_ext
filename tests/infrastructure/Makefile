SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
RUN_ID ?= result-contract-test
OUTPUT_ROOT ?= $(BUILD_ROOT)/tests/result-contract
OUTPUT ?= $(OUTPUT_ROOT)/$(RUN_ID)
RESULT_JSON ?= $(OUTPUT)/observations.jsonl
KERNEL_COMMIT_FILE ?= $(BUILD_ROOT)/kernel-commit.txt

include $(ROOT_DIR)/mk/results.mk

.PHONY: test validate-only create-only clean

test:
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
	jq -e '.status == "completed" and (.completed_at | type == "string" and length > 0)' "$(OUTPUT)/run.json" >/dev/null
	if $(MAKE) --no-print-directory create-only \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(OUTPUT)" RUN_ID="$(RUN_ID)"; then \
		printf '%s\n' 'existing result root unexpectedly passed' >&2; \
		exit 1; \
	fi

validate-only:
	$(call NAMEI_EXT_RUN_VALIDATE_CANONICAL,$(OUTPUT),$(RESULT_JSON))

create-only:
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(OUTPUT))

clean:
	rm -rf "$(OUTPUT_ROOT)"
