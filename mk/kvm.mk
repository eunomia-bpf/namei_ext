PHASE1_RESULT_DIR ?= $(RESULT_ROOT)/phase1/$(RUN_ID)
POLICY_LOAD_OBJECTS ?= $(BUILD_ROOT)/bpf/hide_secret.bpf.o $(BUILD_ROOT)/bpf/pass_only.bpf.o $(BUILD_ROOT)/bpf/redirect_alias.bpf.o $(BUILD_ROOT)/bpf/select_portal.bpf.o
BUILD_GRAPH_POLICY ?= $(BUILD_ROOT)/bpf/build_graph_view.bpf.o
SANDBOX_FIXTURE_POLICY ?= $(BUILD_ROOT)/bpf/sandbox_fixture_view.bpf.o
CHECKPOINT_RESTORE_POLICY ?= $(BUILD_ROOT)/bpf/checkpoint_restore_view.bpf.o
CACHE_LOCALITY_POLICY ?= $(BUILD_ROOT)/bpf/cache_locality_view.bpf.o
TABLE_REDIRECT_POLICY ?= $(BUILD_ROOT)/bpf/table_redirect.bpf.o
PASS_ONLY_POLICY ?= $(BUILD_ROOT)/bpf/pass_only.bpf.o
NAMEI_EXT_EMPTY :=
NAMEI_EXT_SPACE := $(NAMEI_EXT_EMPTY) $(NAMEI_EXT_EMPTY)
NAMEI_EXT_COMMA := ,
NAMEI_EXT_BENCH_VARIANTS_NORMALIZED := $(subst :,$(NAMEI_EXT_SPACE),$(subst $(NAMEI_EXT_COMMA),$(NAMEI_EXT_SPACE),$(BENCH_VARIANTS)))
TABLE_REDIRECT_BENCH_VARIANTS := $(filter table_redirect_empty table_redirect_hit,$(NAMEI_EXT_BENCH_VARIANTS_NORMALIZED))
TABLE_REDIRECT_BENCH_ARG := $(if $(TABLE_REDIRECT_BENCH_VARIANTS),$(TABLE_REDIRECT_POLICY),-)
NAMEI_EXT_DMESG_FAILURE_PATTERN := BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN|clocksource: Watchdog .*read timed out|Marking clocksource .* unstable
NAMEI_EXT_VCPU_AFFINITY_VERIFY ?= $(ROOT_DIR)/tools/kvm/verify_vcpu_affinity.py

define NAMEI_EXT_KVM_RUN_IMAGE
$(VNG) $(if $(4),--pin "$(4)") --run "$(1)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) $(2) RUN_ID=$(RUN_ID) $(3)"
endef

define NAMEI_EXT_KVM_RUN
$(call NAMEI_EXT_KVM_RUN_IMAGE,$(KERNEL_IMAGE),$(1),$(2))
endef

define NAMEI_EXT_KVM_RUN_CAPTURE
if test -n "$(6)"; then launcher_status=0; affinity_status=0; $(call NAMEI_EXT_KVM_RUN_IMAGE,$(1),$(2),$(3),$(6)) >"$(4)/launcher.stdout.log" 2>"$(4)/launcher.stderr.log" & launcher_pid=$$!; python3 "$(NAMEI_EXT_VCPU_AFFINITY_VERIFY)" --expected "$(6)" --output "$(4)/vcpu-affinity.json" || affinity_status=$$?; wait "$$launcher_pid" || launcher_status=$$?; if test "$$launcher_status" -ne 0 || test "$$affinity_status" -ne 0; then failure=kvm-launch-or-guest-command; if test "$$affinity_status" -ne 0; then failure=vcpu-affinity-verification; fi; failed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); jq --arg failed_at "$$failed_at" --arg failure "$$failure" '.status = "failed" | .failed_at = $$failed_at | .failure = $$failure' "$(5)/run.json" >"$(5)/run.json.tmp"; mv -f "$(5)/run.json.tmp" "$(5)/run.json"; exit 1; fi; else if ! $(call NAMEI_EXT_KVM_RUN_IMAGE,$(1),$(2),$(3)) >"$(4)/launcher.stdout.log" 2>"$(4)/launcher.stderr.log"; then failed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); jq --arg failed_at "$$failed_at" '.status = "failed" | .failed_at = $$failed_at | .failure = "kvm-launch-or-guest-command"' "$(5)/run.json" >"$(5)/run.json.tmp"; mv -f "$(5)/run.json.tmp" "$(5)/run.json"; exit 1; fi; fi
endef

define NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN
! grep -E '$(NAMEI_EXT_DMESG_FAILURE_PATTERN)' "$(1)" >/dev/null
endef

.PHONY: kvm-smoke kvm-policy-load kvm-policy-semantic kvm-functional kvm-bench \
	__namei_ext_guest_prepare __phase1_guest_smoke __phase1_guest_policy_load \
	__phase1_guest_policy_semantic __phase1_guest_functional \
	__phase1_guest_bench

KVM_CORE_ENTRYPOINTS := \
	kvm-smoke \
	kvm-policy-load \
	kvm-policy-semantic \
	kvm-functional \
	kvm-bench \
	kvm-agent-workspace-preflight \
	$(CURRENT_EXPERIMENT_TARGETS)

$(KVM_CORE_ENTRYPOINTS): kernel-provenance

__namei_ext_guest_prepare:
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi

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

kvm-policy-load: $(KERNEL_IMAGE) bpf policy-load
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_policy_load RUN_ID=$(RUN_ID)"

__phase1_guest_policy_load:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"policy-load-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/policy-load.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -n "$(POLICY_LOAD_OBJECTS)"
	"$(BUILD_ROOT)/policy-load/namei_ext_policy_load" "$(PHASE1_RESULT_DIR)/policy-load.jsonl" /sys/fs/cgroup $(POLICY_LOAD_OBJECTS)
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-policy-load.log"
	printf '{"event":"policy-load-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/policy-load.jsonl"

kvm-policy-semantic: $(KERNEL_IMAGE) bpf policy-semantic
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_policy_semantic RUN_ID=$(RUN_ID)"

__phase1_guest_policy_semantic:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"policy-semantic-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/policy-semantic.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/policy-semantic/namei_ext_policy_semantic" "$(PHASE1_RESULT_DIR)/policy-semantic.jsonl" /sys/fs/cgroup "$(BUILD_GRAPH_POLICY)" "$(SANDBOX_FIXTURE_POLICY)" "$(CHECKPOINT_RESTORE_POLICY)" "$(CACHE_LOCALITY_POLICY)"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-policy-semantic.log"
	printf '{"event":"policy-semantic-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/policy-semantic.jsonl"

kvm-functional: $(KERNEL_IMAGE) bpf functional
	install -d "$(PHASE1_RESULT_DIR)"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_functional RUN_ID=$(RUN_ID)"

__phase1_guest_functional:
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"functional-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/functional.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	"$(BUILD_ROOT)/functional/namei_ext_functional" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(PHASE1_RESULT_DIR)/functional.jsonl" /sys/fs/cgroup "$(BUILD_ROOT)/bpf/hide_secret.bpf.o" "$(BUILD_ROOT)/bpf/select_portal.bpf.o"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-functional.log"
	printf '{"event":"functional-done","run_id":"%s"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/functional.jsonl"

kvm-bench: $(KERNEL_IMAGE) bpf bench
	command -v jq >/dev/null
	install -d "$(PHASE1_RESULT_DIR)"
	git -C "$(ROOT_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/main-repo-head.txt"
	git -C "$(KERNEL_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/kernel-repo-head.txt"
	git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results' >"$(PHASE1_RESULT_DIR)/main-repo-status.txt"
	git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal >"$(PHASE1_RESULT_DIR)/kernel-repo-status.txt"
	sha256sum "$(KERNEL_IMAGE)" >"$(PHASE1_RESULT_DIR)/kernel-image.sha256"
	sha256sum "$(KERNEL_BUILD_DIR)/.config" >"$(PHASE1_RESULT_DIR)/kernel-config.sha256"
	sha256sum "$(KERNEL_CONFIG_FRAGMENT)" >"$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/phase1.mk" >"$(PHASE1_RESULT_DIR)/benchmark-config.sha256"
	sha256sum "$(ROOT_DIR)/configs/kvm/x86_64.mk" >"$(PHASE1_RESULT_DIR)/kvm-config.sha256"
	main_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/main-repo-status.txt" && printf true || printf false); \
	kernel_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/kernel-repo-status.txt" && printf true || printf false); \
	jq -n \
		--arg schema "namei_ext.phase1.kvm_bench_metadata.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg main_head "$$(cat "$(PHASE1_RESULT_DIR)/main-repo-head.txt")" \
		--arg kernel_head "$$(cat "$(PHASE1_RESULT_DIR)/kernel-repo-head.txt")" \
		--argjson main_dirty "$$main_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
		--arg kernel_image_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-image.sha256")" \
		--arg kernel_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config.sha256")" \
		--arg kernel_config_fragment_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256")" \
		--arg benchmark_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/benchmark-config.sha256")" \
		--arg kvm_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kvm-config.sha256")" \
		--arg samples "$(SAMPLES)" \
		--arg bench_iters "$(BENCH_ITERS)" \
		--arg bench_latency_samples "$(BENCH_LATENCY_SAMPLES)" \
		--arg bench_latency_batch "$(BENCH_LATENCY_BATCH)" \
		--arg bench_randomize_order "$(BENCH_RANDOMIZE_ORDER)" \
		--arg bench_variants "$(BENCH_VARIANTS)" \
		--arg kvm_cpus "$(KVM_CPUS)" \
		--arg kvm_mem "$(KVM_MEM)" \
		--arg kvm_append "$(KVM_APPEND)" \
		'{schema:$$schema, run_id:$$run_id, generated_at:$$generated_at, main_repo:{head:$$main_head, dirty:$$main_dirty, status_file:"main-repo-status.txt"}, kernel_repo:{head:$$kernel_head, dirty:$$kernel_dirty, status_file:"kernel-repo-status.txt"}, artifacts:{kernel_image_sha256:$$kernel_image_sha256, kernel_config_sha256:$$kernel_config_sha256, kernel_config_fragment_sha256:$$kernel_config_fragment_sha256, benchmark_config_sha256:$$benchmark_config_sha256, kvm_config_sha256:$$kvm_config_sha256}, config:{samples:$$samples, bench_iters:$$bench_iters, bench_latency_samples:$$bench_latency_samples, bench_latency_batch:$$bench_latency_batch, bench_randomize_order:$$bench_randomize_order, bench_variants:$$bench_variants, kvm_cpus:$$kvm_cpus, kvm_mem:$$kvm_mem, kvm_append:$$kvm_append}}' \
		>"$(PHASE1_RESULT_DIR)/metadata.json"
	$(VNG) --run "$(KERNEL_IMAGE)" $(VNG_MODULE_FLAGS) --user root --cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" --memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp --append "$(KVM_APPEND)" --exec "$(MAKE) -C $(ROOT_DIR) __phase1_guest_bench RUN_ID=$(RUN_ID) SAMPLES=$(SAMPLES) BENCH_ITERS=$(BENCH_ITERS) BENCH_LATENCY_SAMPLES=$(BENCH_LATENCY_SAMPLES) BENCH_LATENCY_BATCH=$(BENCH_LATENCY_BATCH) BENCH_RANDOMIZE_ORDER=$(BENCH_RANDOMIZE_ORDER) BENCH_VARIANTS='$(BENCH_VARIANTS)'"

__phase1_guest_bench:
	install -d "$(PHASE1_RESULT_DIR)"
	jq -cn \
		--arg run_id "$(RUN_ID)" \
		--argjson samples "$(SAMPLES)" \
		--argjson iterations "$(BENCH_ITERS)" \
		--argjson latency_samples "$(BENCH_LATENCY_SAMPLES)" \
		--argjson latency_batch "$(BENCH_LATENCY_BATCH)" \
		--arg randomize_order "$(BENCH_RANDOMIZE_ORDER)" \
		--arg bench_variants "$(BENCH_VARIANTS)" \
		'{event:"bench-start",run_id:$$run_id,samples:$$samples,iterations:$$iterations,latency_samples:$$latency_samples,latency_batch:$$latency_batch,randomize_order:$$randomize_order,bench_variants:$$bench_variants,policy_variants:($$bench_variants | gsub("[,:]+"; " ") | split(" ") | map(select(length > 0 and . != "baseline")))}' \
		>"$(PHASE1_RESULT_DIR)/bench.jsonl"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	test -s "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o"
	test -s "$(PASS_ONLY_POLICY)"
	$(if $(TABLE_REDIRECT_BENCH_VARIANTS),test -s "$(TABLE_REDIRECT_POLICY)",test "$(TABLE_REDIRECT_BENCH_ARG)" = "-")
	printf '{"event":"bench-system-metrics-start","run_id":"%s"}\n' "$(RUN_ID)" >"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	cat /proc/stat >"$(PHASE1_RESULT_DIR)/bench-proc-stat-before.txt"
	cat /proc/meminfo >"$(PHASE1_RESULT_DIR)/bench-meminfo-before.txt"
	cat /proc/vmstat >"$(PHASE1_RESULT_DIR)/bench-vmstat-before.txt"
	cat /proc/diskstats >"$(PHASE1_RESULT_DIR)/bench-diskstats-before.txt"
	printf '{"event":"bench-system-metrics","run_id":"%s","phase":"before","proc_stat":"bench-proc-stat-before.txt","meminfo":"bench-meminfo-before.txt","vmstat":"bench-vmstat-before.txt","diskstats":"bench-diskstats-before.txt"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	status=0; NAMEI_EXT_RUN_ID="$(RUN_ID)" NAMEI_EXT_BENCH_ORDER_SEED="$(RUN_ID)" NAMEI_EXT_BENCH_RANDOMIZE="$(BENCH_RANDOMIZE_ORDER)" NAMEI_EXT_BENCH_VARIANTS="$(BENCH_VARIANTS)" "$(BUILD_ROOT)/bench-workloads/namei_ext_bench" "$(PHASE1_RESULT_DIR)/bench.jsonl" "$(BUILD_ROOT)/bpf/redirect_alias.bpf.o" "$(SAMPLES)" "$(BENCH_ITERS)" /sys/fs/cgroup "$(PASS_ONLY_POLICY)" "$(TABLE_REDIRECT_BENCH_ARG)" "$(BENCH_LATENCY_SAMPLES)" "$(BENCH_LATENCY_BATCH)" || status=$$?; printf '%s\n' "$$status" >"$(PHASE1_RESULT_DIR)/bench-status.txt"
	cat /proc/stat >"$(PHASE1_RESULT_DIR)/bench-proc-stat-after.txt"
	cat /proc/meminfo >"$(PHASE1_RESULT_DIR)/bench-meminfo-after.txt"
	cat /proc/vmstat >"$(PHASE1_RESULT_DIR)/bench-vmstat-after.txt"
	cat /proc/diskstats >"$(PHASE1_RESULT_DIR)/bench-diskstats-after.txt"
	printf '{"event":"bench-system-metrics","run_id":"%s","phase":"after","proc_stat":"bench-proc-stat-after.txt","meminfo":"bench-meminfo-after.txt","vmstat":"bench-vmstat-after.txt","diskstats":"bench-diskstats-after.txt"}\n' "$(RUN_ID)" >>"$(PHASE1_RESULT_DIR)/bench-system-metrics.jsonl"
	dmesg >"$(PHASE1_RESULT_DIR)/dmesg-bench.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(PHASE1_RESULT_DIR)/dmesg-bench.log)
	status=$$(cat "$(PHASE1_RESULT_DIR)/bench-status.txt"); printf '{"event":"bench-done","run_id":"%s","status":%s}\n' "$(RUN_ID)" "$$status" >>"$(PHASE1_RESULT_DIR)/bench.jsonl"
	test "$$(cat "$(PHASE1_RESULT_DIR)/bench-status.txt")" = "0"
