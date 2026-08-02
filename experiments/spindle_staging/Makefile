ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/spindle-staging
KERNEL_DIR ?= $(ROOT_DIR)/kernel
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
LIBBPF_SOURCES := \
	$(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] \
		$(KERNEL_DIR)/tools/lib/bpf/Makefile)
HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a
HARNESS_SOURCES := \
	$(ROOT_DIR)/runner/Makefile \
	$(ROOT_DIR)/runner/include/namei_ext_harness.h \
	$(ROOT_DIR)/runner/src/namei_ext_harness.c
LIBFUSE_SOURCE ?= $(ROOT_DIR)/.cache/benchmarks/mdtest-cold-metadata/libfuse-3.18.2
LIBFUSE_BUILD ?= $(BUILD_ROOT)/mdtest-cold-metadata/libfuse-build
LIBFUSE_A ?= $(LIBFUSE_BUILD)/lib/libfuse3.a
CC ?= cc

.PHONY: all rq2 clean

all: $(OUTPUT)/namei_ext_spindle_staging

rq2: $(OUTPUT)/namei_ext_spindle_staging_rq2

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" \
		OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(HARNESS_LIBRARY): $(HARNESS_SOURCES)
	$(MAKE) -C "$(ROOT_DIR)/runner" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

$(OUTPUT)/namei_ext_spindle_staging: namei_ext_spindle_staging.c \
		$(HARNESS_LIBRARY) $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(HARNESS_LIBRARY)" "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/namei_ext_spindle_staging_rq2: \
		namei_ext_spindle_staging_rq2.c namei_ext_spindle_staging.c \
		$(HARNESS_LIBRARY) $(LIBBPF_A) $(LIBFUSE_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra -Werror -Wno-unused-function \
		-D_FILE_OFFSET_BITS=64 \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-I"$(LIBFUSE_BUILD)" \
		-I"$(LIBFUSE_BUILD)/include" \
		-I"$(LIBFUSE_SOURCE)/include" \
		-o "$@" "$<" "$(HARNESS_LIBRARY)" "$(LIBBPF_A)" \
		"$(LIBFUSE_A)" -lelf -lz -lpthread -ldl -lrt

clean:
	rm -rf "$(OUTPUT)"
