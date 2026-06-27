ROOT_DIR ?= $(abspath ..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/bpf
CLANG ?= clang
ARCH ?= x86

POLICIES := $(wildcard policies/*.bpf.c)
BPF_OBJECTS := $(patsubst policies/%.bpf.c,$(OUTPUT)/%.bpf.o,$(POLICIES))

.PHONY: all clean

all: $(OUTPUT) $(BPF_OBJECTS)

$(OUTPUT):
	install -d "$@"

$(OUTPUT)/%.bpf.o: policies/%.bpf.c include/*.h | $(OUTPUT)
	$(CLANG) -g -O2 -target bpf -D__TARGET_ARCH_$(ARCH) -Iinclude -c "$<" -o "$@"

clean:
	rm -rf "$(OUTPUT)"
