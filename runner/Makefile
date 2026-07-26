ROOT_DIR ?= $(abspath ..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/runner
KERNEL_DIR ?= $(ROOT_DIR)/kernel
LIBBPF_OUTPUT ?= $(BUILD_ROOT)/libbpf
CC ?= cc
AR ?= ar

HARNESS_OBJECT := $(OUTPUT)/namei_ext_harness.o
HARNESS_LIBRARY := $(OUTPUT)/libnamei_ext_harness.a

.PHONY: all clean

all: $(HARNESS_LIBRARY)

$(OUTPUT):
	install -d "$@"

$(HARNESS_OBJECT): src/namei_ext_harness.c include/namei_ext_harness.h | $(OUTPUT)
	$(CC) -g -O2 -Wall -Wextra \
		-I"$(ROOT_DIR)/runner/include" \
		-I"$(KERNEL_DIR)/tools/lib" \
		-I"$(KERNEL_DIR)/tools/include" \
		-I"$(KERNEL_DIR)/tools/include/uapi" \
		-I"$(LIBBPF_OUTPUT)" \
		-c -o "$@" "$<"

$(HARNESS_LIBRARY): $(HARNESS_OBJECT)
	$(AR) rcs "$@" "$<"

clean:
	rm -rf "$(OUTPUT)"
