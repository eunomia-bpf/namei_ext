ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/w1-oracle
KERNEL_DIR ?= $(ROOT_DIR)/kernel
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
LIBBPF_SOURCES := $(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] $(KERNEL_DIR)/tools/lib/bpf/Makefile)
CC ?= cc
FUSE_CFLAGS ?= -D_FILE_OFFSET_BITS=64 -I/usr/include/fuse
FUSE_LIBS ?= -lfuse -pthread

.PHONY: all clean

all: $(OUTPUT)/namei_ext_w1_oracle

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(OUTPUT)/namei_ext_w1_oracle: namei_ext_w1_oracle.c $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra $(FUSE_CFLAGS) \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(LIBBPF_A)" -lelf -lz $(FUSE_LIBS)

clean:
	rm -rf "$(OUTPUT)"
