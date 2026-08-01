TARGET_LIFETIME_RUNNER ?= \
	$(BUILD_ROOT)/namei-ext-target-lifetime/namei_ext_target_lifetime
TARGET_LIFETIME_POLICY ?= $(BUILD_ROOT)/bpf/fxmark_select.bpf.o
TARGET_LIFETIME_LITMUS ?= \
	$(BUILD_ROOT)/namei-ext-target-lifetime/retirement_litmus.bpf.o
TARGET_LIFETIME_ANALYSIS ?= \
	$(ROOT_DIR)/analysis/namei_ext_target_lifetime/analyze.py
TARGET_LIFETIME_RESULT_DIR ?= \
	$(RESULT_ROOT)/experiments/namei-ext-target-lifetime/$(RUN_ID)
TARGET_LIFETIME_PREFLIGHT_RESULT_DIR ?= \
	$(RESULT_ROOT)/experiments/namei-ext-target-lifetime-preflight/$(RUN_ID)

TARGET_LIFETIME_KASAN_CONFIG ?= \
	$(ROOT_DIR)/configs/kernel/x86_64_phase1_kasan.config
TARGET_LIFETIME_KASAN_BUILD_DIR ?= $(BUILD_ROOT)/kernel-kasan
TARGET_LIFETIME_KASAN_IMAGE ?= \
	$(TARGET_LIFETIME_KASAN_BUILD_DIR)/arch/x86/boot/bzImage
TARGET_LIFETIME_KCSAN_CONFIG ?= \
	$(ROOT_DIR)/configs/kernel/x86_64_phase1_kcsan.config
TARGET_LIFETIME_KCSAN_BUILD_DIR ?= $(BUILD_ROOT)/kernel-kcsan
TARGET_LIFETIME_KCSAN_IMAGE ?= \
	$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/arch/x86/boot/bzImage

define TARGET_LIFETIME_MARK_FAILURE_IF_RUNNING
if test -f "$(1)/run.json"; then \
	status=$$(jq -r '.status' "$(1)/run.json"); \
	case "$$status" in \
	running) failed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
		$(call NAMEI_EXT_MARK_RUN_FAILED,$(1),$$failed_at,$(2));; \
	failed) :;; \
	*) exit 1;; \
	esac; \
fi
endef

define TARGET_LIFETIME_START
set +e; ( set -eu; \
	install -d "$(dir $(1))"; \
	mkdir "$(1)"; \
	$(call NAMEI_EXT_RUN_START,$(1),namei-ext-target-lifetime,linux-vfs,kvm_namei_ext_target_lifetime,$(1)/observations.jsonl,fxmark_select.bpf.c,namei_ext_target_lifetime); \
	install -d "$(1)/boots"; \
	jq \
	--arg role "$(2)" \
	--argjson repetitions "$(3)" \
	--argjson duration_seconds "$(4)" \
	--argjson readers "$(5)" \
	--argjson minimum_updates "$(6)" \
	--argjson minimum_opens_per_reader "$(7)" \
	--argjson lifecycle_cycles "$(8)" \
	'.role = $$role | .matrix = {kernel_kinds:["normal","kasan","kcsan"],repetitions_per_kernel:$$repetitions,duration_seconds_per_publication_cell:$$duration_seconds,readers:$$readers,minimum_updates:$$minimum_updates,minimum_opens_per_reader:$$minimum_opens_per_reader,lifecycle_cycles:$$lifecycle_cycles}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"; \
	mv -f "$(1)/run.json.tmp" "$(1)/run.json"; \
	printf '%s\n' "$(9)" >"$(1)/command.txt"; \
	: >"$(1)/stdout.log"; \
	: >"$(1)/stderr.log"; \
); stage_status=$$?; set -e; if test "$$stage_status" -ne 0; then \
	$(call TARGET_LIFETIME_MARK_FAILURE_IF_RUNNING,$(1),host-run-start); \
	exit 1; \
fi
endef

define TARGET_LIFETIME_RUN_BOOTS
set +e; ( set -eu; for kernel_kind in normal kasan kcsan; do \
	case "$$kernel_kind" in \
	normal) \
		image="$(KERNEL_IMAGE)"; \
		build_dir="$(KERNEL_BUILD_DIR)"; \
		config_fragment="$(KERNEL_CONFIG_FRAGMENT)";; \
	kasan) \
		image="$(TARGET_LIFETIME_KASAN_IMAGE)"; \
		build_dir="$(TARGET_LIFETIME_KASAN_BUILD_DIR)"; \
		config_fragment="$(TARGET_LIFETIME_KASAN_CONFIG)";; \
	kcsan) \
		image="$(TARGET_LIFETIME_KCSAN_IMAGE)"; \
		build_dir="$(TARGET_LIFETIME_KCSAN_BUILD_DIR)"; \
		config_fragment="$(TARGET_LIFETIME_KCSAN_CONFIG)";; \
	*) exit 1;; \
	esac; \
	test -s "$$image"; \
	test -s "$$build_dir/.config"; \
	for repetition in $$(seq 1 "$(3)"); do \
		boot="$(1)/boots/$$kernel_kind-$$(printf '%02d' "$$repetition")"; \
		mkdir "$$boot"; \
		$(MAKE) --no-print-directory -C "$(ROOT_DIR)" \
			__namei_ext_kvm_capture \
			RUN_ID="$(RUN_ID)" \
			NAMEI_EXT_KVM_CAPTURE_IMAGE="$$image" \
			NAMEI_EXT_KVM_CAPTURE_GUEST_TARGET="__namei_ext_target_lifetime_guest TARGET_LIFETIME_BOOT_DIR=$$boot TARGET_LIFETIME_RUN_ROLE=$(2) TARGET_LIFETIME_KERNEL_KIND=$$kernel_kind TARGET_LIFETIME_DURATION=$(4) TARGET_LIFETIME_READERS=$(5) TARGET_LIFETIME_MIN_UPDATES=$(6) TARGET_LIFETIME_MIN_OPENS=$(7) TARGET_LIFETIME_LIFECYCLE_CYCLES=$(8) KERNEL_BUILD_DIR=$$build_dir KERNEL_IMAGE=$$image KERNEL_CONFIG_FRAGMENT=$$config_fragment" \
				NAMEI_EXT_KVM_CAPTURE_BOOT_DIR="$$boot" \
				NAMEI_EXT_KVM_CAPTURE_RUN_DIR="$(1)" \
				NAMEI_EXT_KVM_CAPTURE_REQUIRE_EMPTY=1 \
				NAMEI_EXT_KVM_CAPTURE_TIMEOUT="$(9)"; \
	done; \
done; ); stage_status=$$?; set -e; if test "$$stage_status" -ne 0; then \
	$(call TARGET_LIFETIME_MARK_FAILURE_IF_RUNNING,$(1),host-boot-matrix); \
	exit 1; \
fi
endef

.PHONY: namei-ext-target-lifetime \
		namei-ext-target-lifetime-control \
		namei-ext-target-lifetime-analysis-test \
	namei-ext-target-lifetime-debug-kernels \
	kvm-namei-ext-target-lifetime-preflight \
	kvm-namei-ext-target-lifetime \
	experiment-namei-ext-target-lifetime \
	__namei_ext_target_lifetime_guest

namei-ext-target-lifetime:
	$(MAKE) -C "$(ROOT_DIR)/experiments/namei_ext_target_lifetime" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" all

namei-ext-target-lifetime-control:
	$(MAKE) -C "$(ROOT_DIR)/experiments/agent_workspace" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" namei-only

namei-ext-target-lifetime-analysis-test:
	python3 -m unittest analysis.namei_ext_target_lifetime.test_analyze

namei-ext-target-lifetime-debug-kernels:
	grep '^CONFIG_KPROBES=y' "$(KERNEL_BUILD_DIR)/.config"
	grep '^CONFIG_KPROBE_EVENTS=y' "$(KERNEL_BUILD_DIR)/.config"
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel kernel-config \
		KERNEL_BUILD_DIR="$(TARGET_LIFETIME_KASAN_BUILD_DIR)" \
		KERNEL_IMAGE="$(TARGET_LIFETIME_KASAN_IMAGE)" \
		KERNEL_CONFIG_FRAGMENT="$(TARGET_LIFETIME_KASAN_CONFIG)" \
		KERNEL_COMMIT_FILE="$(TARGET_LIFETIME_KASAN_BUILD_DIR)/kernel-commit.txt"
	grep '^CONFIG_KASAN=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_KASAN_INLINE=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_PROVE_RCU=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_PROVE_RCU_LIST=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_DEBUG_ATOMIC_SLEEP=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_DETECT_HUNG_TASK=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=120' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_KPROBES=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	grep '^CONFIG_KPROBE_EVENTS=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	! grep '^CONFIG_KCSAN=y' \
		"$(TARGET_LIFETIME_KASAN_BUILD_DIR)/.config"
	$(MAKE) --no-print-directory -C "$(ROOT_DIR)" kernel kernel-config \
		KERNEL_BUILD_DIR="$(TARGET_LIFETIME_KCSAN_BUILD_DIR)" \
		KERNEL_IMAGE="$(TARGET_LIFETIME_KCSAN_IMAGE)" \
		KERNEL_CONFIG_FRAGMENT="$(TARGET_LIFETIME_KCSAN_CONFIG)" \
		KERNEL_COMMIT_FILE="$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/kernel-commit.txt"
	grep '^CONFIG_KCSAN=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_KCSAN_STRICT=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_KCSAN_WEAK_MEMORY=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_PROVE_RCU=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_PROVE_RCU_LIST=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_DEBUG_ATOMIC_SLEEP=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_DETECT_HUNG_TASK=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_DEFAULT_HUNG_TASK_TIMEOUT=120' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_KPROBES=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	grep '^CONFIG_KPROBE_EVENTS=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"
	! grep '^CONFIG_KASAN=y' \
		"$(TARGET_LIFETIME_KCSAN_BUILD_DIR)/.config"

kvm-namei-ext-target-lifetime-preflight: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-namei-ext-target-lifetime-preflight: experiment-source-clean \
		kernel kernel-provenance bpf namei-ext-target-lifetime-control \
		namei-ext-target-lifetime \
		namei-ext-target-lifetime-analysis-test \
		namei-ext-target-lifetime-debug-kernels
	test "$(TARGET_LIFETIME_PREFLIGHT_DURATION)" = 5
	test "$(TARGET_LIFETIME_PREFLIGHT_READERS)" = 2
	test "$(TARGET_LIFETIME_PREFLIGHT_MIN_UPDATES)" = 8
	test "$(TARGET_LIFETIME_PREFLIGHT_MIN_OPENS)" = 64
	test "$(TARGET_LIFETIME_PREFLIGHT_LIFECYCLE_CYCLES)" = 4
	test "$(TARGET_LIFETIME_PREFLIGHT_REPETITIONS)" = 1
	test "$(TARGET_LIFETIME_PREFLIGHT_KVM_TIMEOUT)" = 180
	$(call TARGET_LIFETIME_START,$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR),preflight,1,$(TARGET_LIFETIME_PREFLIGHT_DURATION),$(TARGET_LIFETIME_PREFLIGHT_READERS),$(TARGET_LIFETIME_PREFLIGHT_MIN_UPDATES),$(TARGET_LIFETIME_PREFLIGHT_MIN_OPENS),$(TARGET_LIFETIME_PREFLIGHT_LIFECYCLE_CYCLES),make kvm-namei-ext-target-lifetime-preflight RUN_ID=$(RUN_ID))
	$(call TARGET_LIFETIME_RUN_BOOTS,$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR),preflight,1,$(TARGET_LIFETIME_PREFLIGHT_DURATION),$(TARGET_LIFETIME_PREFLIGHT_READERS),$(TARGET_LIFETIME_PREFLIGHT_MIN_UPDATES),$(TARGET_LIFETIME_PREFLIGHT_MIN_OPENS),$(TARGET_LIFETIME_PREFLIGHT_LIFECYCLE_CYCLES),$(TARGET_LIFETIME_PREFLIGHT_KVM_TIMEOUT))
	set +e; ( set -eu; find "$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR)/boots" \
		-name observations.jsonl -print0 | sort -z | xargs -0 cat \
		>"$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR)/observations.jsonl"; \
	test "$$(find "$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR)/boots" \
		-name analysis.json | wc -l)" = 3; \
	$(call NAMEI_EXT_RUN_COMPLETE,$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR)); \
	); stage_status=$$?; set -e; if test "$$stage_status" -ne 0; then \
		$(call TARGET_LIFETIME_MARK_FAILURE_IF_RUNNING,$(TARGET_LIFETIME_PREFLIGHT_RESULT_DIR),host-preflight-finalize); \
		exit 1; \
	fi

kvm-namei-ext-target-lifetime: NAMEI_EXT_REQUIRE_CLEAN = 1
kvm-namei-ext-target-lifetime: experiment-source-clean \
		kernel kernel-provenance bpf namei-ext-target-lifetime-control \
		namei-ext-target-lifetime \
		namei-ext-target-lifetime-analysis-test \
		namei-ext-target-lifetime-debug-kernels
	test "$(TARGET_LIFETIME_FORMAL_DURATION)" = 60
	test "$(TARGET_LIFETIME_FORMAL_READERS)" = 4
	test "$(TARGET_LIFETIME_FORMAL_MIN_UPDATES)" = 256
	test "$(TARGET_LIFETIME_FORMAL_MIN_OPENS)" = 2000
	test "$(TARGET_LIFETIME_FORMAL_LIFECYCLE_CYCLES)" = 64
	test "$(TARGET_LIFETIME_FORMAL_REPETITIONS)" = 3
	test "$(TARGET_LIFETIME_FORMAL_KVM_TIMEOUT)" = 480
	$(call TARGET_LIFETIME_START,$(TARGET_LIFETIME_RESULT_DIR),formal,3,$(TARGET_LIFETIME_FORMAL_DURATION),$(TARGET_LIFETIME_FORMAL_READERS),$(TARGET_LIFETIME_FORMAL_MIN_UPDATES),$(TARGET_LIFETIME_FORMAL_MIN_OPENS),$(TARGET_LIFETIME_FORMAL_LIFECYCLE_CYCLES),make experiment-namei-ext-target-lifetime RUN_ID=$(RUN_ID))
	$(call TARGET_LIFETIME_RUN_BOOTS,$(TARGET_LIFETIME_RESULT_DIR),formal,3,$(TARGET_LIFETIME_FORMAL_DURATION),$(TARGET_LIFETIME_FORMAL_READERS),$(TARGET_LIFETIME_FORMAL_MIN_UPDATES),$(TARGET_LIFETIME_FORMAL_MIN_OPENS),$(TARGET_LIFETIME_FORMAL_LIFECYCLE_CYCLES),$(TARGET_LIFETIME_FORMAL_KVM_TIMEOUT))
	set +e; ( set -eu; find "$(TARGET_LIFETIME_RESULT_DIR)/boots" \
		-name observations.jsonl -print0 | sort -z | xargs -0 cat \
		>"$(TARGET_LIFETIME_RESULT_DIR)/observations.jsonl"; \
	python3 "$(TARGET_LIFETIME_ANALYSIS)" formal \
		--root "$(TARGET_LIFETIME_RESULT_DIR)" \
		--repetitions 3 \
		--output "$(TARGET_LIFETIME_RESULT_DIR)/analysis.json"; \
	$(call NAMEI_EXT_RUN_COMPLETE,$(TARGET_LIFETIME_RESULT_DIR)); \
	); stage_status=$$?; set -e; if test "$$stage_status" -ne 0; then \
		$(call TARGET_LIFETIME_MARK_FAILURE_IF_RUNNING,$(TARGET_LIFETIME_RESULT_DIR),host-formal-finalize); \
		exit 1; \
	fi

experiment-namei-ext-target-lifetime: kvm-namei-ext-target-lifetime

__namei_ext_target_lifetime_guest: __namei_ext_guest_prepare
	test -n "$(TARGET_LIFETIME_BOOT_DIR)"
	test -n "$(TARGET_LIFETIME_RUN_ROLE)"
	test -n "$(TARGET_LIFETIME_KERNEL_KIND)"
	test "$(TARGET_LIFETIME_RUN_ROLE)" = preflight -o \
		"$(TARGET_LIFETIME_RUN_ROLE)" = formal
	test "$(TARGET_LIFETIME_KERNEL_KIND)" = normal -o \
		"$(TARGET_LIFETIME_KERNEL_KIND)" = kasan -o \
		"$(TARGET_LIFETIME_KERNEL_KIND)" = kcsan
	command -v mkfs.ext4 >/dev/null
	install -d "$(TARGET_LIFETIME_BOOT_DIR)" \
		"$(TARGET_LIFETIME_BOOT_DIR)/lower"
	$(call NAMEI_EXT_GUEST_CAPTURE_KERNEL_EVIDENCE,\
		$(TARGET_LIFETIME_BOOT_DIR),\
		$(KERNEL_BUILD_DIR)/.config,\
		$(shell cat $(KERNEL_BUILD_DIR)/.built-commit),\
		$(shell sed -n 's/^\#define UTS_RELEASE "\(.*\)"/\1/p' \
			$(KERNEL_BUILD_DIR)/include/generated/utsrelease.h))
	rm -f "$(TARGET_LIFETIME_BOOT_DIR)/lower.img"
	truncate -s 512M "$(TARGET_LIFETIME_BOOT_DIR)/lower.img"
	mkfs.ext4 -q -F "$(TARGET_LIFETIME_BOOT_DIR)/lower.img" \
		>"$(TARGET_LIFETIME_BOOT_DIR)/mkfs.stdout.log" \
		2>"$(TARGET_LIFETIME_BOOT_DIR)/mkfs.stderr.log"
	mount -t ext4 -o loop "$(TARGET_LIFETIME_BOOT_DIR)/lower.img" \
		"$(TARGET_LIFETIME_BOOT_DIR)/lower"
	test "$$(findmnt -n -o FSTYPE \
		"$(TARGET_LIFETIME_BOOT_DIR)/lower")" = ext4
	findmnt "$(TARGET_LIFETIME_BOOT_DIR)/lower" \
		>"$(TARGET_LIFETIME_BOOT_DIR)/lower-filesystem.txt"
	if test "$(TARGET_LIFETIME_KERNEL_KIND)" = kcsan; then \
		cat /sys/kernel/debug/kcsan \
			>"$(TARGET_LIFETIME_BOOT_DIR)/kcsan-before.txt"; \
	fi
	status=0; \
	"$(TARGET_LIFETIME_RUNNER)" "$(TARGET_LIFETIME_POLICY)" \
		"$(TARGET_LIFETIME_LITMUS)" \
		"$(TARGET_LIFETIME_BOOT_DIR)/observations.jsonl" \
		/sys/fs/cgroup "$(TARGET_LIFETIME_BOOT_DIR)/lower" \
		"$(TARGET_LIFETIME_DURATION)" "$(TARGET_LIFETIME_READERS)" \
		"$(TARGET_LIFETIME_MIN_UPDATES)" \
		"$(TARGET_LIFETIME_MIN_OPENS)" \
		"$(TARGET_LIFETIME_LIFECYCLE_CYCLES)" \
		>"$(TARGET_LIFETIME_BOOT_DIR)/runner.stdout.log" \
		2>"$(TARGET_LIFETIME_BOOT_DIR)/runner.stderr.log" || status=$$?; \
	printf '%s\n' "$$status" \
		>"$(TARGET_LIFETIME_BOOT_DIR)/runner.status"; \
	if test "$(TARGET_LIFETIME_RUN_ROLE)" = formal; then \
		control_cgroup=/sys/fs/cgroup/namei-ext-life-control; \
		test ! -e "$$control_cgroup"; \
		mkdir "$$control_cgroup"; \
		control_status=0; \
		NAMEI_EXT_AGENT_WORKSPACE_WORK_ROOT="$(TARGET_LIFETIME_BOOT_DIR)/lower" \
			"$(AGENT_WORKSPACE_RUNNER)" --rq3 \
			"$(AGENT_WORKSPACE_POLICY)" \
			"$(TARGET_LIFETIME_BOOT_DIR)/current-namei-control.jsonl" \
			"$$control_cgroup" "$(AGENT_WORKSPACE_SOURCE_TRACE)" \
			>"$(TARGET_LIFETIME_BOOT_DIR)/control.stdout.log" \
			2>"$(TARGET_LIFETIME_BOOT_DIR)/control.stderr.log" || \
			control_status=$$?; \
		printf '%s\n' "$$control_status" \
			>"$(TARGET_LIFETIME_BOOT_DIR)/control.status"; \
		test ! -e "$$control_cgroup"; \
	else \
		control_status=0; \
	fi; \
	if test "$(TARGET_LIFETIME_KERNEL_KIND)" = kcsan; then \
		cat /sys/kernel/debug/kcsan \
			>"$(TARGET_LIFETIME_BOOT_DIR)/kcsan-after.txt"; \
	fi; \
	dmesg >"$(TARGET_LIFETIME_BOOT_DIR)/dmesg.log"; \
	test "$$status" = 0; \
	test "$$control_status" = 0
	if test "$(TARGET_LIFETIME_KERNEL_KIND)" = kcsan; then \
		kcsan_args="--kcsan-before $(TARGET_LIFETIME_BOOT_DIR)/kcsan-before.txt --kcsan-after $(TARGET_LIFETIME_BOOT_DIR)/kcsan-after.txt"; \
	else \
		kcsan_args=; \
	fi; \
	if test "$(TARGET_LIFETIME_RUN_ROLE)" = formal; then \
		control_args="--control $(TARGET_LIFETIME_BOOT_DIR)/current-namei-control.jsonl --require-control"; \
	else \
		control_args=; \
	fi; \
	python3 "$(TARGET_LIFETIME_ANALYSIS)" boot \
		--history "$(TARGET_LIFETIME_BOOT_DIR)/observations.jsonl" \
		--dmesg "$(TARGET_LIFETIME_BOOT_DIR)/dmesg.log" \
		--kernel-config "$(TARGET_LIFETIME_BOOT_DIR)/kernel.config" \
		--kernel-kind "$(TARGET_LIFETIME_KERNEL_KIND)" \
		$$kcsan_args $$control_args \
		--output "$(TARGET_LIFETIME_BOOT_DIR)/analysis.json"
	umount "$(TARGET_LIFETIME_BOOT_DIR)/lower"
	rm -rf "$(TARGET_LIFETIME_BOOT_DIR)/lower"
	rm -f "$(TARGET_LIFETIME_BOOT_DIR)/lower.img"
