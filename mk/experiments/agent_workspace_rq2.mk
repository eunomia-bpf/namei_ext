AGENT_WORKSPACE_RQ2_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq2/$(RUN_ID)
AGENT_WORKSPACE_RQ2_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/agent-workspace-rq2-preflight/$(RUN_ID)
AGENT_WORKSPACE_RQ2_AGENTFS_CACHE_DIR ?= $(CACHE_ROOT)/dependencies/agentfs
AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE ?= $(AGENT_WORKSPACE_RQ2_AGENTFS_CACHE_DIR)/agentfs-$(AGENT_WORKSPACE_AGENTFS_COMMIT).tar.gz
AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE ?= $(BUILD_ROOT)/dependencies/agentfs-$(AGENT_WORKSPACE_AGENTFS_COMMIT)
AGENT_WORKSPACE_RQ2_AGENTFS_STAMP ?= $(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/.source-ok
AGENT_WORKSPACE_RQ2_LIBFUSE_ARCHIVE ?= $(CACHE_ROOT)/dependencies/libfuse/libfuse-$(AGENT_WORKSPACE_LIBFUSE_VERSION).tar.gz
AGENT_WORKSPACE_RQ2_LIBFUSE_RUNTIME ?= /usr/lib/x86_64-linux-gnu/libfuse3.so.3.14.0
AGENT_WORKSPACE_RQ2_ANALYSIS ?= $(ROOT_DIR)/analysis/agent_workspace/analyze.py
AGENT_WORKSPACE_RQ2_REQUIRED_ORACLES ?= $(ROOT_DIR)/experiments/agent_workspace/rq2_required_oracles.txt

define AGENT_WORKSPACE_RQ2_VALIDATE_HOST_PIN
printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" | grep -Eq '^[0-9]+-[0-9]+$$'; \
pin_start=$$(printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" | cut -d- -f1); \
pin_end=$$(printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" | cut -d- -f2); \
test "$$pin_end" -ge "$$pin_start"; \
test "$$((pin_end - pin_start + 1))" = "$(KVM_CPUS)"; \
test "$$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" = "1"; \
pin_frequency=; \
for cpu in $$(seq "$$pin_start" "$$pin_end"); do \
	test -d "/sys/devices/system/cpu/cpu$$cpu"; \
	if test -f "/sys/devices/system/cpu/cpu$$cpu/online"; then \
		test "$$(cat "/sys/devices/system/cpu/cpu$$cpu/online")" = "1"; \
	fi; \
	frequency=$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/cpuinfo_max_freq"); \
	test "$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_governor")" = "performance"; \
	if test -z "$$pin_frequency"; then pin_frequency="$$frequency"; fi; \
	test "$$frequency" = "$$pin_frequency"; \
done
endef

define AGENT_WORKSPACE_RQ2_CAPTURE_ARTIFACTS
install -d "$(1)/artifacts/kernel" "$(1)/artifacts/runtime" \
	"$(1)/artifacts/source/agentfs-tests" "$(1)/artifacts/source/archives"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" "$(1)/artifacts/kernel/config"
objcopy --dump-section .BTF="$(1)/artifacts/kernel/vmlinux.btf" \
	"$(KERNEL_BUILD_DIR)/vmlinux"
objcopy --dump-section .notes="$(1)/artifacts/kernel/vmlinux.notes" \
	"$(KERNEL_BUILD_DIR)/vmlinux"
install -m 0555 "$(AGENT_WORKSPACE_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_agent_workspace"
install -m 0555 "$(AGENT_WORKSPACE_FUSE_RUNNER)" \
	"$(1)/artifacts/runtime/namei_ext_agent_workspace_fuse"
install -m 0444 "$(AGENT_WORKSPACE_POLICY)" \
	"$(1)/artifacts/runtime/agent_workspace_view.bpf.o"
install -m 0444 "$(AGENT_WORKSPACE_SOURCE_TRACE)" \
	"$(1)/artifacts/source/agentfs_lifecycle_trace.txt"
install -m 0444 "$(AGENT_WORKSPACE_RQ2_REQUIRED_ORACLES)" \
	"$(1)/artifacts/source/rq2_required_oracles.txt"
install -m 0444 "$(AGENT_WORKSPACE_RQ2_LIBFUSE_RUNTIME)" \
	"$(1)/artifacts/runtime/libfuse3.so.3"
install -m 0444 "$(AGENT_WORKSPACE_RQ2_LIBFUSE_ARCHIVE)" \
	"$(1)/artifacts/source/archives/libfuse-$(AGENT_WORKSPACE_LIBFUSE_VERSION).tar.gz"
install -m 0444 "$(AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE)" \
	"$(1)/artifacts/source/archives/agentfs-$(AGENT_WORKSPACE_AGENTFS_COMMIT).tar.gz"
for file in test-run-bash.sh test-run-git.sh test-overlay-delta-in-base-dir.sh \
		test-overlay-whiteout.sh test-symlinks.sh \
		test-fuse-cache-invalidation.sh; do \
	install -m 0444 \
		"$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/$$file" \
		"$(1)/artifacts/source/agentfs-tests/$$file"; \
done
jq -n \
	--arg kernel_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg kernel_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg kernel_build_id "$$(readelf -n "$(KERNEL_BUILD_DIR)/vmlinux" | awk '/Build ID:/ {print $$3; exit}')" \
	--arg kernel_notes_sha256 "$$(sha256sum "$(1)/artifacts/kernel/vmlinux.notes" | awk '{print $$1}')" \
	--arg kernel_btf_sha256 "$$(sha256sum "$(1)/artifacts/kernel/vmlinux.btf" | awk '{print $$1}')" \
	--arg agentfs_commit "$(AGENT_WORKSPACE_AGENTFS_COMMIT)" \
	--arg libfuse_version "$(AGENT_WORKSPACE_LIBFUSE_VERSION)" \
	'{kernel:{commit:$$kernel_commit,release:$$kernel_release,build_id:$$kernel_build_id,notes_sha256:$$kernel_notes_sha256,btf_sha256:$$kernel_btf_sha256,image:"artifacts/kernel/bzImage",config:"artifacts/kernel/config"},runtime:{namei_ext_runner:"artifacts/runtime/namei_ext_agent_workspace",fuse_runner:"artifacts/runtime/namei_ext_agent_workspace_fuse",policy:"artifacts/runtime/agent_workspace_view.bpf.o",libfuse:"artifacts/runtime/libfuse3.so.3"},source:{trace:"artifacts/source/agentfs_lifecycle_trace.txt",required_oracles:"artifacts/source/rq2_required_oracles.txt",agentfs_commit:$$agentfs_commit,libfuse_version:$$libfuse_version}}' \
	>"$(1)/artifacts/manifest.json"
jq -e '.kernel.commit | length == 40' "$(1)/artifacts/manifest.json" >/dev/null
jq -e '.kernel.release | length > 0' "$(1)/artifacts/manifest.json" >/dev/null
jq -e '.kernel.build_id | length > 0' "$(1)/artifacts/manifest.json" >/dev/null
find "$(1)/artifacts" -type f ! -name artifacts.sha256 -print0 | \
	LC_ALL=C sort -z | xargs -0 sha256sum >"$(1)/artifacts.sha256"
endef

define AGENT_WORKSPACE_RQ2_START
$(call AGENT_WORKSPACE_RQ2_VALIDATE_HOST_PIN)
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),agent-workspace-rq2,agentfs,kvm_agent_workspace_rq2,$(1)/observations.jsonl,agent_workspace_view.bpf.c,namei_ext_agent_workspace+libfuse3)
$(call AGENT_WORKSPACE_RQ2_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--argjson repetitions "$(2)" \
	--argjson lifecycle_samples "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" \
	--argjson stat_samples "$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES)" \
	--argjson open_samples "$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES)" \
	--argjson access_samples "$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES)" \
	--argjson readdir_samples "$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES)" \
	--argjson exec_samples "$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES)" \
	--argjson kvm_cpus "$(KVM_CPUS)" \
	--arg host_cpu_pin "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" \
	'.protocol_schema = "namei_ext.agent_workspace_rq2.protocol.v2" | .layout = "paired-boot-matrix" | .artifacts = $$artifacts[0] | .matrix = {conditions:["namei_ext","fuse"],repetitions:$$repetitions,lifecycle_samples:$$lifecycle_samples,sample_counts:{lifecycle:$$lifecycle_samples,stat:$$stat_samples,open:$$open_samples,access:$$access_samples,readdir:$$readdir_samples,exec:$$exec_samples},order:"alternating",kvm_cpus:$$kvm_cpus,host_cpu_pin:$$host_cpu_pin}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq -e '.kernel.commit == .artifacts.kernel.commit and .kernel_commit == .artifacts.kernel.commit' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(3)" >"$(1)/command.txt"
lscpu >"$(1)/host-lscpu.txt"
lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE,MAXMHZ,MINMHZ \
	>"$(1)/host-lscpu-extended.txt"
cat /proc/stat >"$(1)/host-proc-stat-before.txt"
cat /proc/interrupts >"$(1)/host-proc-interrupts-before.txt"
printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" \
	>"$(1)/host-cpu-pin.txt"
pin_start=$$(printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" | cut -d- -f1); \
pin_end=$$(printf '%s\n' "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" | cut -d- -f2); \
jq -n --argjson start "$$pin_start" --argjson end "$$pin_end" \
	'[range($$start; $$end + 1)]' >"$(1)/host-cpu-pin.json"; \
printf 'intel_pstate_no_turbo=%s\n' \
	"$$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" \
	>"$(1)/host-cpu-frequency-policy.txt"; \
for cpu in $$(seq "$$pin_start" "$$pin_end"); do \
	printf 'cpu=%s governor=%s driver=%s max_khz=%s\n' "$$cpu" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_governor")" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/scaling_driver")" \
		"$$(cat "/sys/devices/system/cpu/cpu$$cpu/cpufreq/cpuinfo_max_freq")" \
		>>"$(1)/host-cpu-frequency-policy.txt"; \
done
vng_path=$$(command -v "$(VNG)"); \
vng_module_path=$$(python3 -c 'import virtme_ng.run; print(virtme_ng.run.__file__)'); \
"$(VNG)" --version >"$(1)/vng-version.txt"; \
sha256sum "$$vng_path" >"$(1)/vng-executable.sha256"; \
sha256sum "$$vng_module_path" >"$(1)/vng-run-module.sha256"
ldd "$(1)/artifacts/runtime/namei_ext_agent_workspace_fuse" \
	>"$(1)/fuse-runner-ldd.txt"
sha256sum "$(ROOT_DIR)/configs/benchmarks/agent_workspace.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(ROOT_DIR)/mk/experiments/agent_workspace_rq2.mk" \
	"$(ROOT_DIR)/mk/experiments/agent_workspace.mk" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
	"$(ROOT_DIR)/tools/kvm/verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/tools/kvm/test_verify_vcpu_affinity.py" \
	"$(ROOT_DIR)/experiments/agent_workspace/Makefile" \
	"$(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace.c" \
	"$(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace_fuse.c" \
	"$(ROOT_DIR)/experiments/agent_workspace/agentfs_lifecycle_trace.txt" \
	"$(ROOT_DIR)/experiments/agent_workspace/rq2_required_oracles.txt" \
	"$(ROOT_DIR)/bpf/policies/agent_workspace_view.bpf.c" \
	"$(AGENT_WORKSPACE_RQ2_ANALYSIS)" \
	"$(ROOT_DIR)/analysis/agent_workspace/test_analyze.py" \
	"$(ROOT_DIR)/docs/tmp/2026-07-27-agent-workspace-rq2-experiment-plan.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-27-agent-workspace-rq2-formal-v1-review.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-27-agent-workspace-rq2-publication-control-repair.md" \
	"$(ROOT_DIR)/docs/tmp/2026-07-27-agent-workspace-rq2-control-preflight.md" \
	>"$(1)/inputs.sha256"
endef

define AGENT_WORKSPACE_RQ2_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'CONDITION' "$$condition" \
	'REPETITION' "$$repetition" \
	'AGENT_WORKSPACE_RQ2_BOOT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_RUNNER' "$${runner#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_FUSE_RUNNER' "$${fuse_runner#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_POLICY' "$${policy#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_TRACE' "$${trace#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_REQUIRED_ORACLES' "$${required_oracles#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_LIBFUSE' "$${libfuse#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'AGENT_WORKSPACE_RQ2_KERNEL_COMMIT' "$$commit" \
	'AGENT_WORKSPACE_RQ2_KERNEL_BUILD_ID' "$$build_id" \
	'AGENT_WORKSPACE_RQ2_KERNEL_NOTES_SHA256' "$$notes_sha" \
	'AGENT_WORKSPACE_RQ2_KERNEL_BTF_SHA256' "$$btf_sha" \
	'AGENT_WORKSPACE_RQ2_KERNEL_RELEASE' "$$release" \
	>"$$guest_makefile"; \
	test "$$(wc -l <"$$guest_makefile")" = "15"; \
! grep -F "$(ROOT_DIR)/" "$$guest_makefile" >/dev/null; \
(cd "$$boot_dir" && sha256sum guest.mk >guest.mk.sha256)
endef

.PHONY: agent-workspace-rq2-source-bindings \
	agent-workspace-rq2-analysis-test \
	agent-workspace-rq2-affinity-test \
	kvm-agent-workspace-rq2-preflight experiment-agent-workspace-rq2 \
	kvm-agent-workspace-rq2 agent-workspace-rq2-run-matrix \
	agent-workspace-rq2-finalize agent-workspace-rq2-mark-complete \
	agent-workspace-rq2-report \
	__agent_workspace_rq2_guest

agent-workspace-rq2-source-bindings: $(AGENT_WORKSPACE_RQ2_AGENTFS_STAMP)

agent-workspace-rq2-analysis-test:
	python3 -m unittest discover -s "$(ROOT_DIR)/analysis/agent_workspace" \
		-p 'test_*.py' -v

agent-workspace-rq2-affinity-test:
	python3 -m unittest discover -s "$(ROOT_DIR)/tools/kvm" \
		-p 'test_*.py' -v

$(AGENT_WORKSPACE_RQ2_AGENTFS_CACHE_DIR):
	install -d "$@"

$(AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE): | $(AGENT_WORKSPACE_RQ2_AGENTFS_CACHE_DIR)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" \
		"$(AGENT_WORKSPACE_AGENTFS_ARCHIVE_URL)"
	printf '%s  %s\n' "$(AGENT_WORKSPACE_AGENTFS_ARCHIVE_SHA256)" "$@.tmp" | \
		sha256sum -c -
	mv -f "$@.tmp" "$@"

$(AGENT_WORKSPACE_RQ2_AGENTFS_STAMP): $(AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE) \
		$(ROOT_DIR)/configs/benchmarks/agent_workspace.mk
	rm -rf "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)"
	install -d "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)"
	printf '%s  %s\n' "$(AGENT_WORKSPACE_AGENTFS_ARCHIVE_SHA256)" \
		"$(AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(AGENT_WORKSPACE_RQ2_AGENTFS_ARCHIVE)" \
		-C "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)" --strip-components=1
	test -f "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-run-bash.sh"
	test -f "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-run-git.sh"
	test -f "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-overlay-whiteout.sh"
	test -f "$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-fuse-cache-invalidation.sh"
	rg -F 'caches ENOENT' \
		"$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-fuse-cache-invalidation.sh"
	rg -F 'base file still exists' \
		"$(AGENT_WORKSPACE_RQ2_AGENTFS_SOURCE)/cli/tests/test-overlay-whiteout.sh"
	printf '%s\n' "$(AGENT_WORKSPACE_AGENTFS_COMMIT)" >"$@"

kvm-agent-workspace-rq2-preflight: kernel kernel-provenance bpf \
		agent-workspace agent-workspace-rq2-source-bindings \
		agent-workspace-rq2-analysis-test \
		agent-workspace-rq2-affinity-test
	command -v objcopy >/dev/null
	command -v readelf >/dev/null
	for samples in "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES)"; do \
		test "$$samples" = "1000"; \
	done
	test -f "$(AGENT_WORKSPACE_RQ2_LIBFUSE_RUNTIME)"
	$(call AGENT_WORKSPACE_RQ2_START,$(AGENT_WORKSPACE_RQ2_PREFLIGHT_RESULT_DIR),1,make kvm-agent-workspace-rq2-preflight RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-run-matrix \
		RUN_ID="$(RUN_ID)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_DIR="$(AGENT_WORKSPACE_RQ2_PREFLIGHT_RESULT_DIR)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-finalize \
		RUN_ID="$(RUN_ID)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_DIR="$(AGENT_WORKSPACE_RQ2_PREFLIGHT_RESULT_DIR)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS=1
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-mark-complete \
		RUN_ID="$(RUN_ID)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_DIR="$(AGENT_WORKSPACE_RQ2_PREFLIGHT_RESULT_DIR)"

kvm-agent-workspace-rq2: kernel kernel-provenance bpf agent-workspace \
		agent-workspace-rq2-source-bindings \
		agent-workspace-rq2-analysis-test \
		agent-workspace-rq2-affinity-test
	command -v objcopy >/dev/null
	command -v readelf >/dev/null
	test "$(AGENT_WORKSPACE_RQ2_REPETITIONS)" = "10"
	for samples in "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES)" \
			"$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES)"; do \
		test "$$samples" = "1000"; \
	done
	test -f "$(AGENT_WORKSPACE_RQ2_LIBFUSE_RUNTIME)"
	$(call AGENT_WORKSPACE_RQ2_START,$(AGENT_WORKSPACE_RQ2_RESULT_DIR),$(AGENT_WORKSPACE_RQ2_REPETITIONS),make kvm-agent-workspace-rq2 RUN_ID=$(RUN_ID))
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-run-matrix \
		RUN_ID="$(RUN_ID)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_DIR="$(AGENT_WORKSPACE_RQ2_RESULT_DIR)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS="$(AGENT_WORKSPACE_RQ2_REPETITIONS)"
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-finalize \
		RUN_ID="$(RUN_ID)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_DIR="$(AGENT_WORKSPACE_RQ2_RESULT_DIR)" \
		AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS="$(AGENT_WORKSPACE_RQ2_REPETITIONS)"
	$(MAKE) -C "$(ROOT_DIR)" agent-workspace-rq2-report RUN_ID="$(RUN_ID)"

agent-workspace-rq2-run-matrix:
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and .layout == "paired-boot-matrix"' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null
	: >"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt"
	: >"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/launch-order.jsonl"
	manifest="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/artifacts/manifest.json"; \
	image="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.kernel.image' "$$manifest")"; \
	config="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.kernel.config' "$$manifest")"; \
	commit=$$(jq -r '.kernel.commit' "$$manifest"); \
	build_id=$$(jq -r '.kernel.build_id' "$$manifest"); \
	notes_sha=$$(jq -r '.kernel.notes_sha256' "$$manifest"); \
	btf_sha=$$(jq -r '.kernel.btf_sha256' "$$manifest"); \
	release=$$(jq -r '.kernel.release' "$$manifest"); \
	runner="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.runtime.namei_ext_runner' "$$manifest")"; \
	fuse_runner="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.runtime.fuse_runner' "$$manifest")"; \
	policy="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.runtime.policy' "$$manifest")"; \
	libfuse="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.runtime.libfuse' "$$manifest")"; \
	trace="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.source.trace' "$$manifest")"; \
	required_oracles="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$(jq -r '.source.required_oracles' "$$manifest")"; \
	order_index=0; \
	for repetition in $$(seq 1 "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)"); do \
		if (( repetition % 2 )); then \
			conditions=(namei_ext fuse); \
		else \
			conditions=(fuse namei_ext); \
		fi; \
		for condition in "$${conditions[@]}"; do \
			order_index=$$((order_index + 1)); \
			printf '%s|%s\n' "$$repetition" "$$condition" \
				>>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt"; \
			boot_dir="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
			install -d "$$boot_dir"; \
			guest_makefile="$$boot_dir/guest.mk"; \
			$(call AGENT_WORKSPACE_RQ2_WRITE_GUEST_MAKEFILE); \
			guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
			host_started_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
			$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __agent_workspace_rq2_guest,,$$boot_dir,$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR),$(AGENT_WORKSPACE_RQ2_HOST_CPUS)); \
			host_completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
			jq -n --argjson order_index "$$order_index" \
				--argjson repetition "$$repetition" \
				--arg condition "$$condition" \
				--arg started_at "$$host_started_at" \
				--arg completed_at "$$host_completed_at" \
				'{schema:"namei_ext.agent_workspace_rq2.launch_order.v1",order_index:$$order_index,repetition:$$repetition,condition:$$condition,host_started_at:$$started_at,host_completed_at:$$completed_at}' \
				>>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/launch-order.jsonl"; \
			jq --argjson order_index "$$order_index" \
				--arg started_at "$$host_started_at" \
				--arg completed_at "$$host_completed_at" \
				'.host_launch = {order_index:$$order_index,started_at:$$started_at,completed_at:$$completed_at}' \
				"$$boot_dir/boot.json" >"$$boot_dir/boot.json.tmp"; \
			mv -f "$$boot_dir/boot.json.tmp" "$$boot_dir/boot.json"; \
		done; \
	done

agent-workspace-rq2-finalize:
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null
	cat /proc/stat \
		>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/host-proc-stat-after.txt"
	cat /proc/interrupts \
		>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/host-proc-interrupts-after.txt"
	LC_ALL=C sort -o "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt" \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt"
	find "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots" -name observations.jsonl \
		-print0 | sort -z | xargs -0 cat \
		>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl"
	find "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots" -name boot.json -print0 | \
		sort -z | xargs -0 jq -r '"\(.repetition)|\(.condition)"' | \
		LC_ALL=C sort >"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observed-boots.txt"
	cmp "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt" \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observed-boots.txt"
	jq -e -s --argjson repetitions "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)" \
		'. as $$rows | length == (2 * $$repetitions) and all(range(0; length); . as $$i | $$rows[$$i].schema == "namei_ext.agent_workspace_rq2.launch_order.v1" and $$rows[$$i].order_index == ($$i + 1) and $$rows[$$i].repetition == ((($$i / 2) | floor) + 1) and $$rows[$$i].condition == (if (((($$i / 2) | floor) + 1) % 2) == 1 then (if ($$i % 2) == 0 then "namei_ext" else "fuse" end) else (if ($$i % 2) == 0 then "fuse" else "namei_ext" end) end) and ($$rows[$$i].host_started_at | type == "string" and length > 0) and ($$rows[$$i].host_completed_at | type == "string" and length > 0))' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/launch-order.jsonl" >/dev/null
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/inputs.sha256"
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/artifacts.sha256"
	test "$$(find "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots" \
		-name boot.json -type f | wc -l)" = \
		"$$((2 * $(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "agent-workspace-lifecycle-sample")] | length' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((2 * $(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS) * $(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)))"
	! jq -e 'select(.pass != true)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl" >/dev/null
	for boot in "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"/boots/*; do \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		for file in guest.mk guest.mk.sha256 launcher.stdout.log \
			launcher.stderr.log vcpu-affinity.json affinity-barrier.txt \
			boot.json raw-runner.jsonl \
			observations.jsonl stdout.log stderr.log kernel.config \
			kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 \
			kernel-btf.sha256 kernel-release.txt clocksource-before.txt \
			clocksource-after.txt uname.txt proc-version.txt \
			kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt \
			dmesg.log; do \
			test -e "$$boot/$$file"; \
		done; \
		jq -e '.schema == "namei_ext.agent_workspace_rq2.boot.v2" and .status == "completed" and .clocksource == "tsc" and (.affinity_verified_at | type == "string" and length > 0)' \
			"$$boot/boot.json" >/dev/null; \
		test "$$(cat "$$boot/affinity-barrier.txt")" = \
			"$$(jq -r '.affinity_verified_at' "$$boot/boot.json")"; \
		jq -e '.host_launch.order_index > 0 and (.host_launch.started_at | type == "string" and length > 0) and (.host_launch.completed_at | type == "string" and length > 0)' \
			"$$boot/boot.json" >/dev/null; \
		jq -e --slurpfile expected "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/host-cpu-pin.json" \
			--argjson kvm_cpus "$(KVM_CPUS)" \
			'.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified" and .expected_host_cpus == $$expected[0] and (.expected_host_cpus | length) == $$kvm_cpus and (.vcpus | length) == (.expected_host_cpus | length) and ([.vcpus[].cpus_allowed | length] | all(. == 1)) and ([.vcpus[].cpus_allowed[0]] | sort) == (.expected_host_cpus | sort)' \
			"$$boot/vcpu-affinity.json" >/dev/null; \
		! grep -E 'WARNING: Failed to pin vCPUs|Permission denied: cannot set affinity|not enough host CPUs|QMP .*failed|No vCPU threads found|TID .* does not exist' \
			"$$boot/launcher.stderr.log" >/dev/null; \
	done
	for file in host-lscpu.txt host-lscpu-extended.txt host-cpu-pin.txt \
			host-cpu-pin.json \
			host-cpu-frequency-policy.txt vng-version.txt \
			vng-executable.sha256 vng-run-module.sha256 \
			host-proc-stat-before.txt \
			host-proc-stat-after.txt host-proc-interrupts-before.txt \
			host-proc-interrupts-after.txt launch-order.jsonl \
			fuse-runner-ldd.txt; do \
		test -s "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$file"; \
	done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR),$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl)
	jq -e --argjson repetitions "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)" \
		--arg host_cpu_pin "$(AGENT_WORKSPACE_RQ2_HOST_CPUS)" \
		--argjson kvm_cpus "$(KVM_CPUS)" \
		'.protocol_schema == "namei_ext.agent_workspace_rq2.protocol.v2" and .layout == "paired-boot-matrix" and .matrix.repetitions == $$repetitions and .matrix.conditions == ["namei_ext","fuse"] and .matrix.lifecycle_samples == 1000 and .matrix.sample_counts == {lifecycle:1000,stat:1000,open:1000,access:1000,readdir:1000,exec:1000} and .matrix.host_cpu_pin == $$host_cpu_pin and .matrix.kvm_cpus == $$kvm_cpus' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null
	jq -e '.status == "running" and (.completed_at | not)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null

agent-workspace-rq2-mark-complete:
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR))

agent-workspace-rq2-report:
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/run.json" >/dev/null
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/artifacts.sha256"
	python3 "$(AGENT_WORKSPACE_RQ2_ANALYSIS)" \
		--input "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/observations.jsonl" \
		--run "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/run.json" \
		--launch-order \
			"$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/launch-order.jsonl" \
		--required-oracles \
			"$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/artifacts/source/rq2_required_oracles.txt" \
		--output "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/analysis" \
		--seed "$(AGENT_WORKSPACE_RQ2_ANALYSIS_SEED)"
	for file in summary.json summary.csv report.md latency-ratios.png \
		latency-ratios.pdf; do \
		test -s "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/analysis/$$file"; \
	done
	jq -e '.schema == "namei_ext.agent_workspace_rq2.summary.v2" and (.verdict.tested_hypothesis == "supported" or .verdict.tested_hypothesis == "contradicted" or .verdict.tested_hypothesis == "inconclusive")' \
		"$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/analysis/summary.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(AGENT_WORKSPACE_RQ2_RESULT_DIR))

experiment-agent-workspace-rq2: kvm-agent-workspace-rq2

__agent_workspace_rq2_guest: __namei_ext_guest_prepare
	test "$(notdir $(lastword $(MAKEFILE_LIST)))" = guest.mk
	(cd "$(dir $(lastword $(MAKEFILE_LIST)))" && sha256sum -c guest.mk.sha256)
	case "$(CONDITION)" in namei_ext|fuse) ;; *) exit 1;; esac
	test -n "$(REPETITION)"
	test -x "$(AGENT_WORKSPACE_RQ2_RUNNER)"
	test -x "$(AGENT_WORKSPACE_RQ2_FUSE_RUNNER)"
	test -r "$(AGENT_WORKSPACE_RQ2_POLICY)"
	test -r "$(AGENT_WORKSPACE_RQ2_TRACE)"
	test -r "$(AGENT_WORKSPACE_RQ2_REQUIRED_ORACLES)"
	test -r "$(AGENT_WORKSPACE_RQ2_LIBFUSE)"
	affinity_status=waiting; \
	for attempt in $$(seq 1 500); do \
		if test -s "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/vcpu-affinity.json"; then \
			if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified"' \
					"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
				affinity_status=verified; \
				break; \
			fi; \
			if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "failed"' \
					"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
				cat "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/vcpu-affinity.json" >&2; \
				exit 1; \
			fi; \
		fi; \
		sleep 0.05; \
	done; \
	test "$$affinity_status" = verified; \
	jq -r '.verified_at' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/vcpu-affinity.json" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/affinity-barrier.txt"
	install -d "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)"
	: >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stdout.log"
	: >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stderr.log"
	: >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/raw-runner.jsonl"
	cp "$(AGENT_WORKSPACE_RQ2_KERNEL_CONFIG)" \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel.config"
	printf '%s\n' "$(AGENT_WORKSPACE_RQ2_KERNEL_COMMIT)" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-commit.txt"
	actual_notes_sha=$$(sha256sum /sys/kernel/notes | awk '{print $$1}'); \
	test "$$actual_notes_sha" = "$(AGENT_WORKSPACE_RQ2_KERNEL_NOTES_SHA256)"; \
	printf '%s  %s\n' "$$actual_notes_sha" /sys/kernel/notes \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-notes.sha256"
	printf '%s\n' "$(AGENT_WORKSPACE_RQ2_KERNEL_BUILD_ID)" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-build-id.txt"
	actual_btf_sha=$$(sha256sum /sys/kernel/btf/vmlinux | awk '{print $$1}'); \
	test "$$actual_btf_sha" = "$(AGENT_WORKSPACE_RQ2_KERNEL_BTF_SHA256)"; \
	printf '%s  %s\n' "$$actual_btf_sha" /sys/kernel/btf/vmlinux \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-btf.sha256"
	grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms
	actual_release=$$(uname -r); \
	test "$$actual_release" = "$(AGENT_WORKSPACE_RQ2_KERNEL_RELEASE)"; \
	printf '%s\n' "$$actual_release" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-release.txt"
	uname -a >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/uname.txt"
	cat /proc/version >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/kernel-cmdline.txt"
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = tsc; \
	printf '%s\n' "$$clocksource" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/clocksource-before.txt"
	cat /proc/stat >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/proc-stat-before.txt"
	case "$(CONDITION)" in \
	namei_ext) \
		"$(AGENT_WORKSPACE_RQ2_RUNNER)" --rq2 \
			"$(AGENT_WORKSPACE_RQ2_POLICY)" \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/raw-runner.jsonl" \
			/sys/fs/cgroup "$(AGENT_WORKSPACE_RQ2_TRACE)" \
			>>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stdout.log" \
			2>>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stderr.log" ;; \
	fuse) \
		LD_LIBRARY_PATH="$(dir $(AGENT_WORKSPACE_RQ2_LIBFUSE))" \
			"$(AGENT_WORKSPACE_RQ2_FUSE_RUNNER)" --rq2 \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/raw-runner.jsonl" \
			"$(AGENT_WORKSPACE_RQ2_TRACE)" \
			>>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stdout.log" \
			2>>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/stderr.log" ;; \
	esac
	jq -c --arg condition "$(CONDITION)" \
		--argjson repetition "$(REPETITION)" \
		'. + {condition:$$condition,repetition:$$repetition}' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/raw-runner.jsonl" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl"
	! jq -e 'select(.pass != true)' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null
	case "$(CONDITION)" in \
	namei_ext) \
		prefix=namei_ext; summary=agent_workspace_rq2_summary ;; \
	fuse) \
		prefix=fuse; summary=fuse_agent_workspace_rq2_summary ;; \
	esac; \
	test "$$(jq -s --arg metric "$${prefix}_lifecycle_ns" \
		'[.[] | select(.event == "agent-workspace-lifecycle-sample" and .metric == $$metric)] | length' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl")" = \
		"$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)"; \
	for spec in stat_main_ns:$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES) \
		open_main_ns:$(AGENT_WORKSPACE_RQ2_OPEN_SAMPLES) \
		access_main_ns:$(AGENT_WORKSPACE_RQ2_ACCESS_SAMPLES) \
		exec_tool_ns:$(AGENT_WORKSPACE_RQ2_EXEC_SAMPLES) \
		readdir_ws_ns:$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES); do \
		metric="$${prefix}_$${spec%%:*}"; expected="$${spec##*:}"; \
		test "$$(jq -s --arg metric "$$metric" \
			'[.[] | select(.event == "agent-workspace-sample" and .metric == $$metric)] | length' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl")" = "$$expected"; \
	done; \
	case "$(CONDITION)" in \
	namei_ext) control_prefix=nohook ;; \
	fuse) control_prefix=fuse_nohook ;; \
	esac; \
	for spec in stat_base_main_ns:$(AGENT_WORKSPACE_RQ2_STAT_SAMPLES) \
		readdir_base_ns:$(AGENT_WORKSPACE_RQ2_READDIR_SAMPLES); do \
		metric="$${control_prefix}_$${spec%%:*}"; expected="$${spec##*:}"; \
		test "$$(jq -s --arg metric "$$metric" \
			'[.[] | select(.event == "agent-workspace-sample" and .metric == $$metric)] | length' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl")" = "$$expected"; \
	done; \
	jq -e --arg summary "$$summary" \
		'select(.case == $$summary and .pass == true)' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null
	jq -e 'select(.case | strings | contains("source_trace_artifact")) | select(.pass == true)' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null
	awk -v condition="$(CONDITION)" '$$1 == condition {print $$2, $$3}' \
		"$(AGENT_WORKSPACE_RQ2_REQUIRED_ORACLES)" | \
	while read -r kind name; do \
		test -n "$$kind"; \
		test -n "$$name"; \
		case "$$kind" in \
		case) field=case ;; \
		manifest) field=manifest ;; \
		*) exit 1 ;; \
		esac; \
		test "$$(jq -s --arg field "$$field" --arg name "$$name" \
			'[.[] | select(.[$$field] == $$name and .pass == true)] | length' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl")" = "1"; \
	done
	case "$(CONDITION)" in \
	namei_ext) \
		jq -e 'select(.counter == "select_ws_lookup" and .value > 0 and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null ;; \
	fuse) \
		jq -e 'select(.case == "fuse_epoch_switch_invalidated" and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null; \
		jq -e 'select(.counter == "invalidate_attempt" and .value == 6 and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null; \
		jq -e 'select(.counter == "invalidate_error" and .value == 0 and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null; \
		jq -e 'select(.event == "agent-workspace-fuse-resource" and .callback_requests > 0 and .cpu_runtime_ns > 0 and .threads_before >= 2 and .threads_before == .threads_after and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null ;; \
	esac
	cat /proc/stat >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/proc-stat-after.txt"
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = "$$(cat "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/clocksource-before.txt")"; \
	printf '%s\n' "$$clocksource" \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/clocksource-after.txt"
	dmesg >"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/dmesg.log)
	jq -n --arg condition "$(CONDITION)" \
		--argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(AGENT_WORKSPACE_RQ2_KERNEL_COMMIT)" \
		--arg kernel_build_id "$(AGENT_WORKSPACE_RQ2_KERNEL_BUILD_ID)" \
		--arg kernel_notes_sha256 "$(AGENT_WORKSPACE_RQ2_KERNEL_NOTES_SHA256)" \
		--arg kernel_btf_sha256 "$(AGENT_WORKSPACE_RQ2_KERNEL_BTF_SHA256)" \
		--arg kernel_release "$(AGENT_WORKSPACE_RQ2_KERNEL_RELEASE)" \
		--arg clocksource "$$(cat "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/clocksource-after.txt")" \
		--arg affinity_verified_at "$$(cat "$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/affinity-barrier.txt")" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{schema:"namei_ext.agent_workspace_rq2.boot.v2",condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_build_id:$$kernel_build_id,kernel_notes_sha256:$$kernel_notes_sha256,kernel_btf_sha256:$$kernel_btf_sha256,kernel_release:$$kernel_release,clocksource:$$clocksource,affinity_verified_at:$$affinity_verified_at,status:"completed",completed_at:$$completed_at}' \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/boot.json"
