ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/fxmark-rq2
FXMARK_SOURCE_ROOT ?=
KERNEL_DIR ?= $(ROOT_DIR)/kernel
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a
CC ?= cc

FXMARK_BINARY := $(OUTPUT)/fxmark
FXMARK_CELL := $(OUTPUT)/fxmark_cell
FXMARK_FUSE := $(OUTPUT)/fxmark_fuse

FXMARK_LIBS := \
	$(FXMARK_SOURCE_ROOT)/src/bench.c \
	$(FXMARK_SOURCE_ROOT)/src/util.c
FXMARK_TESTS := \
	$(FXMARK_SOURCE_ROOT)/src/MWCM.c \
	$(FXMARK_SOURCE_ROOT)/src/MWCL.c \
	$(FXMARK_SOURCE_ROOT)/src/DWAL.c \
	$(FXMARK_SOURCE_ROOT)/src/DWOL.c \
	$(FXMARK_SOURCE_ROOT)/src/DWSL.c \
	$(FXMARK_SOURCE_ROOT)/src/MWRM.c \
	$(FXMARK_SOURCE_ROOT)/src/DWOM.c \
	$(FXMARK_SOURCE_ROOT)/src/MWRL.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBL.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBM.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBH.c \
	$(FXMARK_SOURCE_ROOT)/src/MRDL.c \
	$(FXMARK_SOURCE_ROOT)/src/MRDM.c \
	$(FXMARK_SOURCE_ROOT)/src/MRPM.c \
	$(FXMARK_SOURCE_ROOT)/src/MRDL_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBL_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBH_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/MRDM_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/DRBM_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/MRPM_bg.c \
	$(FXMARK_SOURCE_ROOT)/src/MWUM.c \
	$(FXMARK_SOURCE_ROOT)/src/MWUL.c \
	$(FXMARK_SOURCE_ROOT)/src/DWTL.c \
	$(FXMARK_SOURCE_ROOT)/src/MRPH.c \
	$(FXMARK_SOURCE_ROOT)/src/MRPL.c
FXMARK_HEADERS := $(wildcard $(FXMARK_SOURCE_ROOT)/src/*.h)
LIBBPF_SOURCES := $(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] $(KERNEL_DIR)/tools/lib/bpf/Makefile)

.PHONY: all clean

all: $(FXMARK_BINARY) $(FXMARK_CELL) $(FXMARK_FUSE)

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(HARNESS_LIBRARY):
	$(MAKE) -C "$(ROOT_DIR)/runner" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

$(FXMARK_BINARY): $(FXMARK_SOURCE_ROOT)/src/fxmark.c $(FXMARK_LIBS) $(FXMARK_TESTS) $(FXMARK_HEADERS) cpupol.h | $(OUTPUT)
	test -n "$(FXMARK_SOURCE_ROOT)"
	$(CC) -Wall -Wextra -g -O3 -D_GNU_SOURCE \
		-I"$(ROOT_DIR)/bench/fxmark" \
		-I"$(FXMARK_SOURCE_ROOT)/src" \
		-o "$@" "$(FXMARK_SOURCE_ROOT)/src/fxmark.c" \
		$(FXMARK_LIBS) $(FXMARK_TESTS)

$(FXMARK_CELL): fxmark_cell.c $(HARNESS_LIBRARY) $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(HARNESS_LIBRARY)" "$(LIBBPF_A)" \
		-lelf -lz -lm

$(FXMARK_FUSE): fxmark_fuse.c | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra $$(pkg-config --cflags fuse) \
		-o "$@" "$<" $$(pkg-config --libs fuse)

clean:
	rm -rf "$(OUTPUT)"
