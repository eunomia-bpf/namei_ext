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
$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(1))
install -d "$(1)/boots"
$(call NAMEI_EXT_RUN_START,$(1),agent-workspace-rq2,agentfs,kvm_agent_workspace_rq2,$(1)/observations.jsonl,agent_workspace_view.bpf.c,namei_ext_agent_workspace+libfuse3)
$(call AGENT_WORKSPACE_RQ2_CAPTURE_ARTIFACTS,$(1))
jq --slurpfile artifacts "$(1)/artifacts/manifest.json" \
	--argjson repetitions "$(2)" \
	--argjson lifecycle_samples "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" \
	'.layout = "paired-boot-matrix" | .artifacts = $$artifacts[0] | .matrix = {conditions:["namei_ext","fuse"],repetitions:$$repetitions,lifecycle_samples:$$lifecycle_samples,order:"alternating"}' \
	"$(1)/run.json" >"$(1)/run.json.tmp"
mv -f "$(1)/run.json.tmp" "$(1)/run.json"
jq -e '.kernel.commit == .artifacts.kernel.commit and .kernel_commit == .artifacts.kernel.commit' \
	"$(1)/run.json" >/dev/null
printf '%s\n' "$(3)" >"$(1)/command.txt"
lscpu >"$(1)/host-lscpu.txt"
ldd "$(1)/artifacts/runtime/namei_ext_agent_workspace_fuse" \
	>"$(1)/fuse-runner-ldd.txt"
sha256sum "$(ROOT_DIR)/configs/benchmarks/agent_workspace.mk" \
	"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
	"$(ROOT_DIR)/mk/experiments/agent_workspace_rq2.mk" \
	"$(ROOT_DIR)/mk/experiments/agent_workspace.mk" \
	"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
	"$(ROOT_DIR)/experiments/agent_workspace/Makefile" \
	"$(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace.c" \
	"$(ROOT_DIR)/experiments/agent_workspace/namei_ext_agent_workspace_fuse.c" \
	"$(ROOT_DIR)/experiments/agent_workspace/agentfs_lifecycle_trace.txt" \
	"$(ROOT_DIR)/experiments/agent_workspace/rq2_required_oracles.txt" \
	"$(ROOT_DIR)/bpf/policies/agent_workspace_view.bpf.c" \
	"$(AGENT_WORKSPACE_RQ2_ANALYSIS)" \
	"$(ROOT_DIR)/docs/tmp/2026-07-27-agent-workspace-rq2-experiment-plan.md" \
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
	kvm-agent-workspace-rq2-preflight experiment-agent-workspace-rq2 \
	kvm-agent-workspace-rq2 agent-workspace-rq2-run-matrix \
	agent-workspace-rq2-finalize agent-workspace-rq2-mark-complete \
	agent-workspace-rq2-report \
	__agent_workspace_rq2_guest

agent-workspace-rq2-source-bindings: $(AGENT_WORKSPACE_RQ2_AGENTFS_STAMP)

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
		agent-workspace agent-workspace-rq2-source-bindings
	command -v objcopy >/dev/null
	command -v readelf >/dev/null
	test "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" = "20"
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
		agent-workspace-rq2-source-bindings
	command -v objcopy >/dev/null
	command -v readelf >/dev/null
	test "$(AGENT_WORKSPACE_RQ2_REPETITIONS)" = "10"
	test "$(AGENT_WORKSPACE_RQ2_LIFECYCLE_SAMPLES)" = "20"
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
	for repetition in $$(seq 1 "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)"); do \
		if (( repetition % 2 )); then \
			conditions=(namei_ext fuse); \
		else \
			conditions=(fuse namei_ext); \
		fi; \
		for condition in "$${conditions[@]}"; do \
			printf '%s|%s\n' "$$repetition" "$$condition" \
				>>"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/expected-boots.txt"; \
			boot_dir="$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
			install -d "$$boot_dir"; \
			guest_makefile="$$boot_dir/guest.mk"; \
			$(call AGENT_WORKSPACE_RQ2_WRITE_GUEST_MAKEFILE); \
			guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
			$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __agent_workspace_rq2_guest,,$$boot_dir,$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)); \
		done; \
	done

agent-workspace-rq2-finalize:
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"
	test -n "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)"
	jq -e '.status == "running" and (.failed_at | not)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/run.json" >/dev/null
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
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/inputs.sha256"
	sha256sum -c "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/artifacts.sha256"
	test "$$(find "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/boots" \
		-name boot.json -type f | wc -l)" = \
		"$$((2 * $(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)))"
	test "$$(jq -s '[.[] | select(.event == "agent-workspace-lifecycle-sample")] | length' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl")" = \
		"$$((2 * $(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS) * 20))"
	! jq -e 'select(.pass == false)' \
		"$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl" >/dev/null
	for boot in "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)"/boots/*; do \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		for file in guest.mk guest.mk.sha256 launcher.stdout.log \
			launcher.stderr.log boot.json raw-runner.jsonl \
			observations.jsonl stdout.log stderr.log kernel.config \
			kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 \
			kernel-btf.sha256 kernel-release.txt clocksource-before.txt \
			clocksource-after.txt uname.txt proc-version.txt \
			kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt \
			dmesg.log; do \
			test -e "$$boot/$$file"; \
		done; \
		jq -e '.status == "completed" and .clocksource == "tsc"' \
			"$$boot/boot.json" >/dev/null; \
	done
	for file in host-lscpu.txt fuse-runner-ldd.txt; do \
		test -s "$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/$$file"; \
	done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR),$(AGENT_WORKSPACE_RQ2_ACTIVE_DIR)/observations.jsonl)
	jq -e --argjson repetitions "$(AGENT_WORKSPACE_RQ2_ACTIVE_REPETITIONS)" \
		'.layout == "paired-boot-matrix" and .matrix.repetitions == $$repetitions and .matrix.conditions == ["namei_ext","fuse"] and .matrix.lifecycle_samples == 20' \
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
		--output "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/analysis" \
		--seed "$(AGENT_WORKSPACE_RQ2_ANALYSIS_SEED)"
	for file in summary.json summary.csv report.md latency-ratios.png \
		latency-ratios.pdf; do \
		test -s "$(AGENT_WORKSPACE_RQ2_RESULT_DIR)/analysis/$$file"; \
	done
	jq -e '.verdict.tested_hypothesis == "supported" or .verdict.tested_hypothesis == "contradicted" or .verdict.tested_hypothesis == "inconclusive"' \
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
	! jq -e 'select(.pass == false)' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null
	case "$(CONDITION)" in \
	namei_ext) \
		prefix=namei_ext; summary=agent_workspace_rq2_summary ;; \
	fuse) \
		prefix=fuse; summary=fuse_agent_workspace_rq2_summary ;; \
	esac; \
	test "$$(jq -s --arg metric "$${prefix}_lifecycle_ns" \
		'[.[] | select(.event == "agent-workspace-lifecycle-sample" and .metric == $$metric)] | length' \
		"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl")" = "20"; \
	for spec in stat_main_ns:100 open_main_ns:100 access_main_ns:100 \
		exec_tool_ns:20 readdir_ws_ns:50; do \
		metric="$${prefix}_$${spec%%:*}"; expected="$${spec##*:}"; \
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
		jq -e 'select(.counter == "invalidate_attempt" and .value == 5 and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null; \
		jq -e 'select(.counter == "invalidate_error" and .value == 0 and .pass == true)' \
			"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/observations.jsonl" >/dev/null; \
		jq -e 'select(.event == "agent-workspace-fuse-resource" and .requests > 0 and .pass == true)' \
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
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_build_id:$$kernel_build_id,kernel_notes_sha256:$$kernel_notes_sha256,kernel_btf_sha256:$$kernel_btf_sha256,kernel_release:$$kernel_release,clocksource:$$clocksource,status:"completed",completed_at:$$completed_at}' \
		>"$(AGENT_WORKSPACE_RQ2_BOOT_DIR)/boot.json"
