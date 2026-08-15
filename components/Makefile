ROOT ?= $(abspath ..)
BUILD ?= $(ROOT)/.build
CLANG ?= clang
CPPFLAGS := -I$(ROOT)/components/include
CFLAGS := -O2 -g -Wall -Wextra -Werror
SOURCES := $(wildcard */*.bpf.c)
OBJECTS := $(patsubst %.bpf.c,$(BUILD)/bpf/%.bpf.o,$(SOURCES))

.PHONY: all syntax clean check-target

syntax:
	@set -e; for source in $(SOURCES); do \
		echo "  CHECK   $$source"; \
		$(CLANG) $(CPPFLAGS) -D__EBPFOS_HOST_CHECK__ -fsyntax-only \
			-Wno-unused-parameter -Wno-unknown-attributes $$source; \
	done

check-target:
	@printf 'int x;' | $(CLANG) -target bpf -x c -c -o /dev/null - 2>/dev/null || \
		{ echo 'clang does not include the BPF backend' >&2; exit 2; }

all: check-target $(OBJECTS)

$(BUILD)/bpf/%.bpf.o: %.bpf.c include/ebpfos_bpf.h
	@mkdir -p $(@D)
	$(CLANG) -target bpf -D__TARGET_ARCH_x86 $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD)/bpf
