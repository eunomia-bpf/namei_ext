ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/abi
RESULT_DIR ?= $(ROOT_DIR)/results/phase1/abi-dev
KERNEL_DIR ?= $(ROOT_DIR)/kernel
CC ?= cc

UAPI_KERNEL_BLOCK := $(OUTPUT)/namei-ext-uapi.kernel
UAPI_TOOLS_BLOCK := $(OUTPUT)/namei-ext-uapi.tools
UAPI_SYNC_STAMP := $(OUTPUT)/uapi-sync.ok

.PHONY: all run clean

all: $(OUTPUT)/namei_ext_abi_uapi $(OUTPUT)/namei_ext_abi_bpf $(UAPI_SYNC_STAMP)

run: all
	install -d "$(RESULT_DIR)"
	: >"$(RESULT_DIR)/abi.jsonl"
	"$(OUTPUT)/namei_ext_abi_uapi" >>"$(RESULT_DIR)/abi.jsonl"
	"$(OUTPUT)/namei_ext_abi_bpf" >>"$(RESULT_DIR)/abi.jsonl"
	printf '%s\n' '{"event":"abi","name":"uapi_header_sync","pass":true,"detail":"kernel and tools namei_ext UAPI blocks match"}' >>"$(RESULT_DIR)/abi.jsonl"

$(OUTPUT):
	install -d "$@"

$(OUTPUT)/namei_ext_abi_uapi: namei_ext_abi.c $(KERNEL_DIR)/tools/include/uapi/linux/bpf.h | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra -DNAMEI_EXT_ABI_UAPI \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-o "$@" "$<"

$(OUTPUT)/namei_ext_abi_bpf: namei_ext_abi.c $(ROOT_DIR)/bpf/include/namei_ext.h | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra -DNAMEI_EXT_ABI_BPF \
		-I"$(ROOT_DIR)/bpf/include" \
		-o "$@" "$<"

$(UAPI_KERNEL_BLOCK): $(KERNEL_DIR)/include/uapi/linux/bpf.h | $(OUTPUT)
	sed -n '/#define BPF_NAMEI_EXT_NAME_MAX/,/struct bpf_raw_tracepoint_args/p' "$<" >"$@"

$(UAPI_TOOLS_BLOCK): $(KERNEL_DIR)/tools/include/uapi/linux/bpf.h | $(OUTPUT)
	sed -n '/#define BPF_NAMEI_EXT_NAME_MAX/,/struct bpf_raw_tracepoint_args/p' "$<" >"$@"

$(UAPI_SYNC_STAMP): $(UAPI_KERNEL_BLOCK) $(UAPI_TOOLS_BLOCK)
	diff -u "$(UAPI_KERNEL_BLOCK)" "$(UAPI_TOOLS_BLOCK)"
	touch "$@"

clean:
	rm -rf "$(OUTPUT)"
