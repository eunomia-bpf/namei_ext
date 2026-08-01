ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
CACHE_ROOT ?= $(ROOT_DIR)/.cache
OUTPUT ?= $(BUILD_ROOT)/agent-workspace
KERNEL_DIR ?= $(ROOT_DIR)/kernel
include $(ROOT_DIR)/configs/benchmarks/agent_workspace.mk
LIBFUSE_CACHE_DIR ?= $(CACHE_ROOT)/dependencies/libfuse
LIBFUSE_ARCHIVE ?= $(LIBFUSE_CACHE_DIR)/libfuse-$(AGENT_WORKSPACE_LIBFUSE_VERSION).tar.gz
LIBFUSE_SOURCE ?= $(BUILD_ROOT)/dependencies/libfuse-$(AGENT_WORKSPACE_LIBFUSE_VERSION)
LIBFUSE_CONFIG_BUILD ?= $(BUILD_ROOT)/dependencies/libfuse-$(AGENT_WORKSPACE_LIBFUSE_VERSION)-config
LIBFUSE_SOURCE_STAMP ?= $(LIBFUSE_SOURCE)/.source-ok
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
LIBBPF_SOURCES := $(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] $(KERNEL_DIR)/tools/lib/bpf/Makefile)
CC ?= cc
FUSE_CFLAGS ?= -D_FILE_OFFSET_BITS=64 -I$(LIBFUSE_CONFIG_BUILD) -I$(LIBFUSE_SOURCE)/include
FUSE_LIBS ?= -l:libfuse3.so.3 -pthread

.PHONY: all namei-only clean

all: $(OUTPUT)/namei_ext_agent_workspace $(OUTPUT)/namei_ext_agent_workspace_fuse

namei-only: $(OUTPUT)/namei_ext_agent_workspace

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(LIBFUSE_CACHE_DIR):
	install -d "$@"

$(LIBFUSE_ARCHIVE): | $(LIBFUSE_CACHE_DIR)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" \
		"$(AGENT_WORKSPACE_LIBFUSE_ARCHIVE_URL)"
	printf '%s  %s\n' "$(AGENT_WORKSPACE_LIBFUSE_ARCHIVE_SHA256)" "$@.tmp" | \
		sha256sum -c -
	mv -f "$@.tmp" "$@"

$(LIBFUSE_SOURCE_STAMP): $(LIBFUSE_ARCHIVE) Makefile
	rm -rf "$(LIBFUSE_SOURCE)"
	rm -rf "$(LIBFUSE_CONFIG_BUILD)"
	install -d "$(LIBFUSE_SOURCE)"
	printf '%s  %s\n' "$(AGENT_WORKSPACE_LIBFUSE_ARCHIVE_SHA256)" \
		"$(LIBFUSE_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(LIBFUSE_ARCHIVE)" -C "$(LIBFUSE_SOURCE)" --strip-components=1
	test -f "$(LIBFUSE_SOURCE)/include/fuse.h"
	test -f "$(LIBFUSE_SOURCE)/include/fuse_common.h"
	command -v meson >/dev/null
	meson setup "$(LIBFUSE_CONFIG_BUILD)" "$(LIBFUSE_SOURCE)" \
		-Dutils=false -Dexamples=false -Dtests=false -Duseroot=false
	test -f "$(LIBFUSE_CONFIG_BUILD)/libfuse_config.h"
	printf '%s\n' "$(AGENT_WORKSPACE_LIBFUSE_VERSION)" >"$@"

$(OUTPUT)/namei_ext_agent_workspace: namei_ext_agent_workspace.c \
		../agent_workspace_rq3/semantic_oracles.h $(LIBBPF_A) \
		$(ROOT_DIR)/configs/benchmarks/agent_workspace.mk | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-DAGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES=$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_STAT_SAMPLES=$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_OPEN_SAMPLES=$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_ACCESS_SAMPLES=$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_READDIR_SAMPLES=$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_EXEC_SAMPLES=$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES) \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/namei_ext_agent_workspace_fuse: namei_ext_agent_workspace_fuse.c \
		$(LIBFUSE_SOURCE_STAMP) \
		$(ROOT_DIR)/configs/benchmarks/agent_workspace.mk | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-DAGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES=$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_STAT_SAMPLES=$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_OPEN_SAMPLES=$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_ACCESS_SAMPLES=$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_READDIR_SAMPLES=$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES) \
		-DAGENT_WORKSPACE_RQ2_EXEC_SAMPLES=$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES) \
		$(FUSE_CFLAGS) \
		-o "$@" "$<" $(FUSE_LIBS)

clean:
	rm -rf "$(OUTPUT)"
