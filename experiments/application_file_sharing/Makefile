ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/application-file-sharing
KERNEL_DIR ?= $(ROOT_DIR)/kernel
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
LIBBPF_A ?= $(LIBBPF_OUTPUT)/libbpf.a
LIBBPF_SOURCES := $(wildcard $(KERNEL_DIR)/tools/lib/bpf/*.[ch] $(KERNEL_DIR)/tools/lib/bpf/Makefile)
HARNESS_LIBRARY ?= $(BUILD_ROOT)/runner/libnamei_ext_harness.a
CC ?= cc
GIO_CFLAGS ?= $(shell pkg-config --cflags gio-2.0 gio-unix-2.0 glib-2.0)
GIO_LIBS ?= $(shell pkg-config --libs gio-2.0 gio-unix-2.0 glib-2.0)

.PHONY: all clean

all: \
	$(OUTPUT)/namei_ext_application_file_sharing \
	$(OUTPUT)/xdg_document_portal_oracle

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(HARNESS_LIBRARY):
	$(MAKE) -C "$(ROOT_DIR)/runner" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

$(OUTPUT)/namei_ext_application_file_sharing: namei_ext_application_file_sharing.c $(HARNESS_LIBRARY) $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" "$<" "$(HARNESS_LIBRARY)" "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/xdg_document_portal_oracle: xdg_document_portal_oracle.c | $(OUTPUT)
	pkg-config --exists gio-2.0 gio-unix-2.0 glib-2.0
	$(CC) -g -O2 -Wall -Wextra $(GIO_CFLAGS) \
		-o "$@" "$<" $(GIO_LIBS)

clean:
	rm -rf "$(OUTPUT)"
