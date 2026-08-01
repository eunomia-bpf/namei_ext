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
	$(OUTPUT)/xdg_document_portal_oracle \
	$(OUTPUT)/rq2_transaction_smoke

$(OUTPUT):
	install -d "$@"

$(LIBBPF_OUTPUT):
	install -d "$@"

$(LIBBPF_A): $(LIBBPF_SOURCES) | $(LIBBPF_OUTPUT)
	$(MAKE) -C "$(KERNEL_DIR)/tools/lib/bpf" OUTPUT="$(LIBBPF_OUTPUT)/" "$(LIBBPF_A)"

$(HARNESS_LIBRARY):
	$(MAKE) -C "$(ROOT_DIR)/runner" ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

$(OUTPUT)/namei_ext_application_file_sharing: \
		namei_ext_application_file_sharing.c rq2_measurement.c \
		rq2_measurement.h $(HARNESS_LIBRARY) $(LIBBPF_A) | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" namei_ext_application_file_sharing.c rq2_measurement.c \
		"$(HARNESS_LIBRARY)" "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/xdg_document_portal_oracle: \
		xdg_document_portal_oracle.c rq2_measurement.c rq2_measurement.h \
		rq2_fuse_counter.c rq2_fuse_counter.h $(LIBBPF_A) | $(OUTPUT)
	pkg-config --exists gio-2.0 gio-unix-2.0 glib-2.0
	$(CC) -g -O2 -Wall -Wextra $(GIO_CFLAGS) \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-o "$@" xdg_document_portal_oracle.c rq2_measurement.c \
		rq2_fuse_counter.c $(GIO_LIBS) "$(LIBBPF_A)" -lelf -lz

$(OUTPUT)/rq2_transaction_smoke: rq2_transaction_smoke.c \
		rq2_measurement.c rq2_measurement.h | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-o "$@" rq2_transaction_smoke.c rq2_measurement.c

.PHONY: rq2-host-smoke

rq2-host-smoke: $(OUTPUT)/rq2_transaction_smoke
	"$(OUTPUT)/rq2_transaction_smoke" \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl"
	! jq -e 'select(has("pass") and .pass != true)' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl" >/dev/null
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-sample" and .pass == true)] | length' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl")" = 3
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-oracle" and .stream == "host-filesystem-smoke" and .phase == "initial" and .pass == true)] | length' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl")" = 1
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-process-snapshot" and .role == "client" and .pass == true)] | length' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl")" = 2
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-hidden-oracle" and .document_stat_errno == 2 and .directory_entries == 2 and .pass == true)] | length' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl")" = 1
	test "$$(jq -s '[.[] | select(.event == "application-file-sharing-rq2-smoke" and .pass == true)] | length' \
		"$(OUTPUT)/rq2-transaction-smoke.jsonl")" = 1

clean:
	rm -rf "$(OUTPUT)"
