KERNEL_BUILD_DIR ?= $(BUILD_ROOT)/kernel
KERNEL_CONFIG_FRAGMENT ?= $(ROOT_DIR)/configs/kernel/x86_64_phase1.config
KERNEL_IMAGE ?= $(KERNEL_BUILD_DIR)/arch/x86/boot/bzImage
KERNEL_COMMIT_FILE ?= $(BUILD_ROOT)/kernel-commit.txt
KERNEL_MERGE_CONFIG ?= $(KERNEL_DIR)/scripts/kconfig/merge_config.sh
STOCK_KERNEL_COMMIT ?= 062871f1371b2e02a272ff5279c6479aff0a37ef
STOCK_KERNEL_SOURCE_DIR ?= $(BUILD_ROOT)/kernel-stock-src
STOCK_KERNEL_BUILD_DIR ?= $(BUILD_ROOT)/kernel-stock
STOCK_KERNEL_IMAGE ?= $(STOCK_KERNEL_BUILD_DIR)/arch/x86/boot/bzImage
STOCK_KERNEL_SOURCE_STAMP ?= $(STOCK_KERNEL_SOURCE_DIR)/.source-commit
STOCK_KERNEL_COMMIT_FILE ?= $(BUILD_ROOT)/kernel-stock-commit.txt
KERNEL_TOUCHED_OBJECTS := \
	fs/namei.o \
	fs/readdir.o \
	fs/namei_ext.o \
	kernel/bpf/btf.o \
	kernel/bpf/cgroup.o \
	kernel/bpf/syscall.o \
	kernel/bpf/verifier.o

KERNEL_SOURCE_DEPS := \
	$(KERNEL_DIR)/fs/Kconfig \
	$(KERNEL_DIR)/fs/Makefile \
	$(KERNEL_DIR)/fs/namei.c \
	$(KERNEL_DIR)/fs/namei_ext.c \
	$(KERNEL_DIR)/fs/readdir.c \
	$(KERNEL_DIR)/include/linux/bpf-cgroup-defs.h \
	$(KERNEL_DIR)/include/linux/bpf-cgroup.h \
	$(KERNEL_DIR)/include/linux/bpf_types.h \
	$(KERNEL_DIR)/include/linux/namei_ext.h \
	$(KERNEL_DIR)/include/uapi/linux/bpf.h \
	$(KERNEL_DIR)/kernel/bpf/btf.c \
	$(KERNEL_DIR)/kernel/bpf/cgroup.c \
	$(KERNEL_DIR)/kernel/bpf/syscall.c \
	$(KERNEL_DIR)/kernel/bpf/verifier.c \
	$(KERNEL_DIR)/tools/bpf/bpftool/prog.c \
	$(KERNEL_DIR)/tools/include/uapi/linux/bpf.h \
	$(KERNEL_DIR)/tools/lib/bpf/libbpf.c \
	$(KERNEL_DIR)/tools/lib/bpf/libbpf_probes.c

.PHONY: kernel-config kernel-objects kernel kernel-provenance \
	kernel-stock-source kernel-stock-config kernel-stock \
	kernel-stock-provenance kernel-clean

kernel-config: $(KERNEL_BUILD_DIR)/include/config/auto.conf
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_SYSCALL=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_JIT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_CGROUP_BPF=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_FUSE_FS=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_DEBUG_INFO_BTF=y' "$(KERNEL_BUILD_DIR)/.config"

$(KERNEL_BUILD_DIR):
	install -d "$@"

$(KERNEL_BUILD_DIR)/.config: $(KERNEL_CONFIG_FRAGMENT) | $(KERNEL_BUILD_DIR)
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" x86_64_defconfig
	cd "$(KERNEL_DIR)" && "$(KERNEL_MERGE_CONFIG)" -O "$(KERNEL_BUILD_DIR)" "$(KERNEL_BUILD_DIR)/.config" "$(KERNEL_CONFIG_FRAGMENT)"
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

$(KERNEL_BUILD_DIR)/include/config/auto.conf: $(KERNEL_BUILD_DIR)/.config
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

kernel-objects: $(KERNEL_BUILD_DIR)/include/config/auto.conf $(KERNEL_BUILD_DIR)/.config
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" $(KERNEL_TOUCHED_OBJECTS) -j"$(JOBS)"

kernel: $(KERNEL_IMAGE)

kernel-stock-source: $(STOCK_KERNEL_SOURCE_STAMP)

kernel-stock-config: $(STOCK_KERNEL_BUILD_DIR)/include/config/auto.conf
	grep '^CONFIG_BPF_SYSCALL=y' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_JIT=y' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_CGROUP_BPF=y' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_FUSE_FS=y' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	! grep '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config"

kernel-stock: $(STOCK_KERNEL_IMAGE)

kernel-provenance:
	install -d "$(BUILD_ROOT)"
	commit=$$(git -C "$(KERNEL_DIR)" rev-parse HEAD); \
	case "$$commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
	test "$${#commit}" -eq 40; \
	printf '%s\n' "$$commit" >"$(KERNEL_COMMIT_FILE).tmp"; \
	if test -r "$(KERNEL_COMMIT_FILE)" && cmp -s "$(KERNEL_COMMIT_FILE).tmp" "$(KERNEL_COMMIT_FILE)"; then \
		rm -f "$(KERNEL_COMMIT_FILE).tmp"; \
	else \
		mv -f "$(KERNEL_COMMIT_FILE).tmp" "$(KERNEL_COMMIT_FILE)"; \
	fi

kernel-stock-provenance: $(STOCK_KERNEL_SOURCE_STAMP)
	install -d "$(BUILD_ROOT)"
	printf '%s\n' "$(STOCK_KERNEL_COMMIT)" >"$(STOCK_KERNEL_COMMIT_FILE).tmp"
	if test -r "$(STOCK_KERNEL_COMMIT_FILE)" && cmp -s "$(STOCK_KERNEL_COMMIT_FILE).tmp" "$(STOCK_KERNEL_COMMIT_FILE)"; then \
		rm -f "$(STOCK_KERNEL_COMMIT_FILE).tmp"; \
	else \
		mv -f "$(STOCK_KERNEL_COMMIT_FILE).tmp" "$(STOCK_KERNEL_COMMIT_FILE)"; \
	fi

$(KERNEL_IMAGE): $(KERNEL_BUILD_DIR)/include/config/auto.conf $(KERNEL_BUILD_DIR)/.config $(KERNEL_SOURCE_DEPS)
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" bzImage -j"$(JOBS)"

$(STOCK_KERNEL_SOURCE_STAMP):
	git -C "$(KERNEL_DIR)" cat-file -e "$(STOCK_KERNEL_COMMIT)^{commit}"
	rm -rf "$(STOCK_KERNEL_SOURCE_DIR)"
	install -d "$(STOCK_KERNEL_SOURCE_DIR)"
	git -C "$(KERNEL_DIR)" archive "$(STOCK_KERNEL_COMMIT)" | tar -x -C "$(STOCK_KERNEL_SOURCE_DIR)"
	printf '%s\n' "$(STOCK_KERNEL_COMMIT)" >"$@"

$(STOCK_KERNEL_BUILD_DIR):
	install -d "$@"

$(STOCK_KERNEL_BUILD_DIR)/.config: $(KERNEL_CONFIG_FRAGMENT) $(STOCK_KERNEL_SOURCE_STAMP) | $(STOCK_KERNEL_BUILD_DIR)
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" x86_64_defconfig
	cd "$(STOCK_KERNEL_SOURCE_DIR)" && scripts/kconfig/merge_config.sh -O "$(STOCK_KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_BUILD_DIR)/.config" "$(KERNEL_CONFIG_FRAGMENT)"
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" olddefconfig

$(STOCK_KERNEL_BUILD_DIR)/include/config/auto.conf: $(STOCK_KERNEL_BUILD_DIR)/.config
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" olddefconfig

$(STOCK_KERNEL_IMAGE): $(STOCK_KERNEL_BUILD_DIR)/include/config/auto.conf $(STOCK_KERNEL_BUILD_DIR)/.config
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" bzImage -j"$(JOBS)"

kernel-clean:
	rm -rf "$(KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_SOURCE_DIR)"
