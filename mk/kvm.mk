PHASE1_RESULT_DIR ?= $(RESULT_ROOT)/phase1/$(RUN_ID)

.PHONY: kvm-smoke kvm-functional kvm-bench __phase1_guest_smoke __phase1_guest_functional __phase1_guest_bench

kvm-smoke: $(KERNEL_IMAGE)
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_smoke RUN_ID=$(RUN_ID)"

__phase1_guest_smoke:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"guest-smoke-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/guest-smoke.jsonl"
	uname -a >"$(PHASE1_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(PHASE1_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(PHASE1_RESULT_DIR)/kernel-cmdline.txt"
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config" >"$(PHASE1_RESULT_DIR)/config-namei-ext.txt"
	cp "$(KERNEL_BUILD_DIR)/.config" "$(PHASE1_RESULT_DIR)/kernel.config"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-smoke.log"
	printf '{"event":"guest-smoke-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/guest-smoke.jsonl"

kvm-functional: $(KERNEL_IMAGE) bpf functional
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_functional RUN_ID=$(RUN_ID)"

__phase1_guest_functional:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"functional-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/functional.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/functional/namei_ext_functional" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(PHASE1_RESULT_DIR)/functional.jsonl" /sys/fs/cgroup
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-functional.log"
	printf '{"event":"functional-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/functional.jsonl"

kvm-bench: $(KERNEL_IMAGE) bpf bench
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_bench RUN_ID=$(RUN_ID)"

__phase1_guest_bench:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"bench-start","run_id":"%s","samples":%s,"iterations":%s}\n' "$(RUN_ID)" "$(SAMPLES)" "$(BENCH_ITERS)" >"$(PHASE1_RESULT_DIR)/bench.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/bench-workloads/namei_ext_bench" "$(PHASE1_RESULT_DIR)/bench.jsonl" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(SAMPLES)" "$(BENCH_ITERS)" /sys/fs/cgroup
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-bench.log"
	printf '{"event":"bench-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/bench.jsonl"
