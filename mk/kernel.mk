KERNEL_BUILD_DIR ?= $(BUILD_ROOT)/kernel
KERNEL_CONFIG_FRAGMENT ?= $(ROOT_DIR)/configs/kernel/x86_64_phase1.config
KERNEL_IMAGE ?= $(KERNEL_BUILD_DIR)/arch/x86/boot/bzImage
KERNEL_MERGE_CONFIG ?= $(KERNEL_DIR)/scripts/kconfig/merge_config.sh
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

.PHONY: kernel-config kernel-objects kernel kernel-clean

kernel-config: $(KERNEL_BUILD_DIR)/include/config/auto.conf
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_SYSCALL=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_JIT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_CGROUP_BPF=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_DEBUG_INFO_BTF=y' "$(KERNEL_BUILD_DIR)/.config"

$(KERNEL_BUILD_DIR):
	install -d "$@"

$(KERNEL_BUILD_DIR)/.config: $(KERNEL_CONFIG_FRAGMENT) | $(KERNEL_BUILD_DIR)
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" x86_64_defconfig
	cd "$(KERNEL_DIR)" && "$(KERNEL_MERGE_CONFIG)" -O "$(KERNEL_BUILD_DIR)" "$(KERNEL_BUILD_DIR)/.config" "$(KERNEL_CONFIG_FRAGMENT)"
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

$(KERNEL_BUILD_DIR)/include/config/auto.conf: $(KERNEL_BUILD_DIR)/.config
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

kernel-objects: $(KERNEL_BUILD_DIR)/include/config/auto.conf
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" $(KERNEL_TOUCHED_OBJECTS) -j"$(JOBS)"

kernel: $(KERNEL_IMAGE)

$(KERNEL_IMAGE): $(KERNEL_BUILD_DIR)/include/config/auto.conf $(KERNEL_SOURCE_DEPS)
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" bzImage -j"$(JOBS)"

kernel-clean:
	rm -rf "$(KERNEL_BUILD_DIR)"
