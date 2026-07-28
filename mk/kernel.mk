KERNEL_BUILD_DIR ?= $(BUILD_ROOT)/kernel
KERNEL_CONFIG_FRAGMENT ?= $(ROOT_DIR)/configs/kernel/x86_64_phase1.config
KERNEL_IMAGE ?= $(KERNEL_BUILD_DIR)/arch/x86/boot/bzImage
KERNEL_COMMIT_FILE ?= $(BUILD_ROOT)/kernel-commit.txt
ifeq ($(origin KERNEL_SOURCE_COMMIT), undefined)
KERNEL_SOURCE_COMMIT := $(shell git -C "$(KERNEL_DIR)" rev-parse HEAD)
endif
KERNEL_SOURCE_COMMIT_STAMP ?= $(KERNEL_BUILD_DIR)/.source-commit
KERNEL_BUILT_COMMIT_FILE ?= $(KERNEL_BUILD_DIR)/.built-commit
KERNEL_RELEASE_HEADER ?= $(KERNEL_BUILD_DIR)/include/generated/utsrelease.h
KERNEL_MERGE_CONFIG ?= $(KERNEL_DIR)/scripts/kconfig/merge_config.sh
KERNEL_LOCK_ROOT ?= $(CACHE_ROOT)/locks
KERNEL_BUILD_LOCK ?= $(KERNEL_LOCK_ROOT)/kernel-build.lock
STOCK_KERNEL_COMMIT ?= 062871f1371b2e02a272ff5279c6479aff0a37ef
STOCK_KERNEL_SOURCE_DIR ?= $(BUILD_ROOT)/kernel-stock-src
STOCK_KERNEL_BUILD_DIR ?= $(BUILD_ROOT)/kernel-stock
STOCK_KERNEL_IMAGE ?= $(STOCK_KERNEL_BUILD_DIR)/arch/x86/boot/bzImage
STOCK_KERNEL_SOURCE_STAMP ?= $(STOCK_KERNEL_SOURCE_DIR)/.source-commit-$(STOCK_KERNEL_COMMIT)
STOCK_KERNEL_SOURCE_HASH_FILE ?= $(BUILD_ROOT)/kernel-stock-source-tree.sha256
STOCK_KERNEL_VERIFY_INDEX ?= $(BUILD_ROOT)/kernel-stock-source.index
STOCK_KERNEL_BUILT_COMMIT_FILE ?= $(STOCK_KERNEL_BUILD_DIR)/.built-commit
STOCK_KERNEL_RELEASE_HEADER ?= $(STOCK_KERNEL_BUILD_DIR)/include/generated/utsrelease.h
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

STOCK_KERNEL_SOURCE_HASH_COMMAND = git -C "$(KERNEL_DIR)" ls-tree -rz \
	--full-tree "$(STOCK_KERNEL_COMMIT)"

define STOCK_KERNEL_VERIFY_SOURCE
index="$(STOCK_KERNEL_VERIFY_INDEX)"; \
rm -f "$$index"; \
trap 'rm -f "$$index"' EXIT; \
GIT_INDEX_FILE="$$index" git -C "$(KERNEL_DIR)" \
	--work-tree="$(STOCK_KERNEL_SOURCE_DIR)" read-tree "$(STOCK_KERNEL_COMMIT)"; \
GIT_INDEX_FILE="$$index" git -C "$(KERNEL_DIR)" \
	--work-tree="$(STOCK_KERNEL_SOURCE_DIR)" update-index --refresh; \
GIT_INDEX_FILE="$$index" git -C "$(KERNEL_DIR)" \
	--work-tree="$(STOCK_KERNEL_SOURCE_DIR)" diff-files --quiet --; \
test -z "$$(GIT_INDEX_FILE="$$index" git -C "$(KERNEL_DIR)" \
	--work-tree="$(STOCK_KERNEL_SOURCE_DIR)" ls-files --others \
	--exclude='.source-commit-*')"
endef

.PHONY: kernel-lock-ready kernel-source-identity kernel-config kernel-objects kernel kernel-provenance \
	kernel-stock-source kernel-stock-config kernel-stock \
	kernel-stock-provenance kernel-clean FORCE

FORCE:

kernel-lock-ready:
	command -v flock >/dev/null
	install -d "$(KERNEL_LOCK_ROOT)" "$(BUILD_ROOT)"

kernel-source-identity: | kernel-lock-ready
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	commit="$(KERNEL_SOURCE_COMMIT)"; \
	case "$$commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
	test "$${#commit}" -eq 40; \
	current=$$(cat "$(KERNEL_SOURCE_COMMIT_STAMP)" 2>/dev/null || true); \
	if test "$$current" != "$$commit"; then \
		rm -rf "$(KERNEL_BUILD_DIR)"; \
		install -d "$(KERNEL_BUILD_DIR)"; \
		printf '%s\n' "$$commit" >"$(KERNEL_SOURCE_COMMIT_STAMP).tmp"; \
		mv -f "$(KERNEL_SOURCE_COMMIT_STAMP).tmp" "$(KERNEL_SOURCE_COMMIT_STAMP)"; \
	fi

kernel-config: $(KERNEL_BUILD_DIR)/include/config/auto.conf
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_SYSCALL=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_BPF_JIT=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_CGROUP_BPF=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_FUSE_FS=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_DEBUG_INFO_BTF=y' "$(KERNEL_BUILD_DIR)/.config"

$(KERNEL_BUILD_DIR): | kernel-source-identity
	install -d "$@"

$(KERNEL_BUILD_DIR)/.config: $(KERNEL_CONFIG_FRAGMENT) | kernel-source-identity $(KERNEL_BUILD_DIR)
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" x86_64_defconfig; \
	cd "$(KERNEL_DIR)" && "$(KERNEL_MERGE_CONFIG)" -O "$(KERNEL_BUILD_DIR)" "$(KERNEL_BUILD_DIR)/.config" "$(KERNEL_CONFIG_FRAGMENT)"; \
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

$(KERNEL_BUILD_DIR)/include/config/auto.conf: $(KERNEL_BUILD_DIR)/.config
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" olddefconfig

kernel-objects: $(KERNEL_BUILD_DIR)/include/config/auto.conf $(KERNEL_BUILD_DIR)/.config
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
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

kernel-provenance: $(KERNEL_IMAGE)
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	install -d "$(BUILD_ROOT)"; \
	commit=$$(git -C "$(KERNEL_DIR)" rev-parse HEAD); \
	case "$$commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
	test "$${#commit}" -eq 40; \
	test "$$(cat "$(KERNEL_SOURCE_COMMIT_STAMP)")" = "$$commit"; \
	test "$$(cat "$(KERNEL_BUILT_COMMIT_FILE)")" = "$$commit"; \
	short=$$(printf '%.12s' "$$commit"); \
	release=$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)"); \
	test -n "$$release"; \
	case "$$release" in (*-dirty*) exit 1;; (*-g$$short) ;; (*) exit 1;; esac; \
	grep -aF "Linux version $$release " "$(KERNEL_BUILD_DIR)/vmlinux" >/dev/null; \
	printf '%s\n' "$$commit" >"$(KERNEL_COMMIT_FILE).tmp"; \
	if test -r "$(KERNEL_COMMIT_FILE)" && cmp -s "$(KERNEL_COMMIT_FILE).tmp" "$(KERNEL_COMMIT_FILE)"; then \
		rm -f "$(KERNEL_COMMIT_FILE).tmp"; \
	else \
		mv -f "$(KERNEL_COMMIT_FILE).tmp" "$(KERNEL_COMMIT_FILE)"; \
	fi

kernel-stock-provenance: $(STOCK_KERNEL_IMAGE)
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	install -d "$(BUILD_ROOT)"; \
	commit="$(STOCK_KERNEL_COMMIT)"; \
	case "$$commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
	test "$${#commit}" -eq 40; \
	test "$$(cat "$(STOCK_KERNEL_SOURCE_STAMP)")" = "$$commit"; \
	test "$$($(STOCK_KERNEL_SOURCE_HASH_COMMAND) | sha256sum | awk '{print $$1}')" = "$$(cat "$(STOCK_KERNEL_SOURCE_HASH_FILE)")"; \
	test "$$(cat "$(STOCK_KERNEL_BUILT_COMMIT_FILE)")" = "$$commit"; \
	release=$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(STOCK_KERNEL_RELEASE_HEADER)"); \
	test -n "$$release"; \
	case "$$release" in (*-dirty*) exit 1;; esac; \
	grep -aF "Linux version $$release " "$(STOCK_KERNEL_BUILD_DIR)/vmlinux" >/dev/null; \
	printf '%s\n' "$$commit" >"$(STOCK_KERNEL_COMMIT_FILE).tmp"
	$(call STOCK_KERNEL_VERIFY_SOURCE)
	if test -r "$(STOCK_KERNEL_COMMIT_FILE)" && cmp -s "$(STOCK_KERNEL_COMMIT_FILE).tmp" "$(STOCK_KERNEL_COMMIT_FILE)"; then \
		rm -f "$(STOCK_KERNEL_COMMIT_FILE).tmp"; \
	else \
		mv -f "$(STOCK_KERNEL_COMMIT_FILE).tmp" "$(STOCK_KERNEL_COMMIT_FILE)"; \
	fi

$(KERNEL_IMAGE): FORCE $(KERNEL_BUILD_DIR)/include/config/auto.conf $(KERNEL_BUILD_DIR)/.config $(KERNEL_SOURCE_DEPS) | kernel-lock-ready
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	commit=$$(git -C "$(KERNEL_DIR)" rev-parse HEAD); \
	case "$$commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
	test "$${#commit}" -eq 40; \
	test "$$(cat "$(KERNEL_SOURCE_COMMIT_STAMP)")" = "$$commit"; \
	short=$$(printf '%.12s' "$$commit"); \
	release=$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)" 2>/dev/null || true); \
	case "$$release" in (*-g$$short) ;; (*) \
		rm -f "$(KERNEL_BUILD_DIR)/include/config/kernel.release" \
			"$(KERNEL_RELEASE_HEADER)" \
			"$(KERNEL_BUILD_DIR)/init/version.o" \
			"$(KERNEL_BUILD_DIR)/init/version-timestamp.o";; \
	esac; \
	$(MAKE) -C "$(KERNEL_DIR)" O="$(KERNEL_BUILD_DIR)" bzImage -j"$(JOBS)"; \
	commit=$$(cat "$(KERNEL_SOURCE_COMMIT_STAMP)"); \
	short=$$(printf '%.12s' "$$commit"); \
	release=$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)"); \
	test -n "$$release"; \
	case "$$release" in (*-dirty*) exit 1;; (*-g$$short) ;; (*) exit 1;; esac; \
	grep -aF "Linux version $$release " "$(KERNEL_BUILD_DIR)/vmlinux" >/dev/null; \
	printf '%s\n' "$$commit" >"$(KERNEL_BUILT_COMMIT_FILE)"

$(STOCK_KERNEL_SOURCE_STAMP): | kernel-lock-ready
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	if test "$$(cat "$@" 2>/dev/null || true)" != "$(STOCK_KERNEL_COMMIT)"; then \
		git -C "$(KERNEL_DIR)" cat-file -e "$(STOCK_KERNEL_COMMIT)^{commit}"; \
		rm -rf "$(STOCK_KERNEL_SOURCE_DIR)" "$(STOCK_KERNEL_BUILD_DIR)"; \
		install -d "$(STOCK_KERNEL_SOURCE_DIR)"; \
		git -C "$(KERNEL_DIR)" archive "$(STOCK_KERNEL_COMMIT)" | tar -x -C "$(STOCK_KERNEL_SOURCE_DIR)"; \
		printf '%s\n' "$(STOCK_KERNEL_COMMIT)" >"$@"; \
	fi

$(STOCK_KERNEL_SOURCE_HASH_FILE): $(STOCK_KERNEL_SOURCE_STAMP)
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	$(STOCK_KERNEL_SOURCE_HASH_COMMAND) | sha256sum | awk '{print $$1}' >"$@.tmp"; \
	mv -f "$@.tmp" "$@"

$(STOCK_KERNEL_BUILD_DIR): | $(STOCK_KERNEL_SOURCE_STAMP)
	install -d "$@"

$(STOCK_KERNEL_BUILD_DIR)/.config: $(KERNEL_CONFIG_FRAGMENT) $(STOCK_KERNEL_SOURCE_STAMP) | $(STOCK_KERNEL_BUILD_DIR)
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" x86_64_defconfig; \
	cd "$(STOCK_KERNEL_SOURCE_DIR)" && scripts/kconfig/merge_config.sh -O "$(STOCK_KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_BUILD_DIR)/.config" "$(KERNEL_CONFIG_FRAGMENT)"; \
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" olddefconfig

$(STOCK_KERNEL_BUILD_DIR)/include/config/auto.conf: $(STOCK_KERNEL_BUILD_DIR)/.config
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" olddefconfig

$(STOCK_KERNEL_IMAGE): FORCE $(STOCK_KERNEL_BUILD_DIR)/include/config/auto.conf $(STOCK_KERNEL_BUILD_DIR)/.config $(STOCK_KERNEL_SOURCE_HASH_FILE) | kernel-lock-ready
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	test "$$(cat "$(STOCK_KERNEL_SOURCE_STAMP)")" = "$(STOCK_KERNEL_COMMIT)"; \
	test "$$($(STOCK_KERNEL_SOURCE_HASH_COMMAND) | sha256sum | awk '{print $$1}')" = "$$(cat "$(STOCK_KERNEL_SOURCE_HASH_FILE)")"; \
	$(call STOCK_KERNEL_VERIFY_SOURCE); \
	$(MAKE) -C "$(STOCK_KERNEL_SOURCE_DIR)" O="$(STOCK_KERNEL_BUILD_DIR)" bzImage -j"$(JOBS)"; \
	release=$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(STOCK_KERNEL_RELEASE_HEADER)"); \
	test -n "$$release"; \
	case "$$release" in (*-dirty*) exit 1;; esac; \
	grep -aF "Linux version $$release " "$(STOCK_KERNEL_BUILD_DIR)/vmlinux" >/dev/null; \
	printf '%s\n' "$(STOCK_KERNEL_COMMIT)" >"$(STOCK_KERNEL_BUILT_COMMIT_FILE)"

kernel-clean: | kernel-lock-ready
	exec 9>"$(KERNEL_BUILD_LOCK)"; \
	flock 9; \
	rm -rf "$(KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_BUILD_DIR)" "$(STOCK_KERNEL_SOURCE_DIR)"; \
	rm -f "$(STOCK_KERNEL_SOURCE_HASH_FILE)"
