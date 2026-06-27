ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/table-conformance
RESULT_DIR ?= $(ROOT_DIR)/results/phase1/table-conformance-dev
TABLE_SOURCE ?= $(ROOT_DIR)/bpf/policies/table_redirect.bpf.c
TABLE_OBJECT ?= $(BUILD_ROOT)/bpf/table_redirect.bpf.o
CC ?= cc

.PHONY: all run clean

all: $(OUTPUT)/namei_ext_table_conformance

$(OUTPUT):
	install -d "$@"

$(OUTPUT)/namei_ext_table_conformance: namei_ext_table_conformance.c | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra -o "$@" "$<"

run: all $(TABLE_SOURCE) $(TABLE_OBJECT)
	install -d "$(RESULT_DIR)"
	"$(OUTPUT)/namei_ext_table_conformance" "$(RESULT_DIR)/table-conformance.jsonl" "$(TABLE_SOURCE)" "$(TABLE_OBJECT)"

clean:
	rm -rf "$(OUTPUT)"
