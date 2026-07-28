FXMARK_CACHE_DIR ?= $(CACHE_ROOT)/benchmarks/fxmark
FXMARK_ARCHIVE ?= $(FXMARK_CACHE_DIR)/fxmark-$(FXMARK_COMMIT).tar.gz
FXMARK_SOURCE_ROOT ?= $(BUILD_ROOT)/fxmark-source
FXMARK_SOURCE_STAMP ?= $(FXMARK_SOURCE_ROOT)/.source-ok
FXMARK_OUTPUT ?= $(BUILD_ROOT)/fxmark-rq2
FXMARK_BINARY ?= $(FXMARK_OUTPUT)/fxmark
FXMARK_CELL ?= $(FXMARK_OUTPUT)/fxmark_cell
FXMARK_FUSE ?= $(FXMARK_OUTPUT)/fxmark_fuse
FXMARK_PASS_POLICY ?= $(BUILD_ROOT)/bpf/fxmark_pass.bpf.o
FXMARK_SELECT_POLICY ?= $(BUILD_ROOT)/bpf/fxmark_select.bpf.o
FXMARK_PATCHED_KERNEL_BTF ?= $(FXMARK_OUTPUT)/patched-vmlinux.btf
FXMARK_STOCK_KERNEL_BTF ?= $(FXMARK_OUTPUT)/stock-vmlinux.btf
FXMARK_PATCHED_KERNEL_NOTES ?= $(FXMARK_OUTPUT)/patched-vmlinux.notes
FXMARK_STOCK_KERNEL_NOTES ?= $(FXMARK_OUTPUT)/stock-vmlinux.notes
FXMARK_CELL_TIMEOUT ?= 900
FXMARK_ANALYSIS_SEED ?= 20260726
FXMARK_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-rq2/$(RUN_ID)
FXMARK_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-rq2-preflight/$(RUN_ID)
FXMARK_GUEST_MOUNT ?= /tmp/namei-ext-fxmark-rq2

define FXMARK_CAPTURE_RUN_ARTIFACTS
install -d "$(1)/artifacts/kernel/patched" "$(1)/artifacts/kernel/stock" "$(1)/artifacts/runtime"
install -m 0444 "$(KERNEL_IMAGE)" "$(1)/artifacts/kernel/patched/bzImage"
install -m 0444 "$(KERNEL_BUILD_DIR)/.config" "$(1)/artifacts/kernel/patched/config"
install -m 0444 "$(FXMARK_PATCHED_KERNEL_BTF)" "$(1)/artifacts/kernel/patched/vmlinux.btf"
install -m 0444 "$(FXMARK_PATCHED_KERNEL_NOTES)" "$(1)/artifacts/kernel/patched/vmlinux.notes"
install -m 0444 "$(STOCK_KERNEL_IMAGE)" "$(1)/artifacts/kernel/stock/bzImage"
install -m 0444 "$(STOCK_KERNEL_BUILD_DIR)/.config" "$(1)/artifacts/kernel/stock/config"
install -m 0444 "$(FXMARK_STOCK_KERNEL_BTF)" "$(1)/artifacts/kernel/stock/vmlinux.btf"
install -m 0444 "$(FXMARK_STOCK_KERNEL_NOTES)" "$(1)/artifacts/kernel/stock/vmlinux.notes"
install -m 0555 "$(FXMARK_BINARY)" "$(1)/artifacts/runtime/fxmark"
install -m 0555 "$(FXMARK_CELL)" "$(1)/artifacts/runtime/fxmark_cell"
install -m 0555 "$(FXMARK_FUSE)" "$(1)/artifacts/runtime/fxmark_fuse"
install -m 0444 "$(FXMARK_PASS_POLICY)" "$(1)/artifacts/runtime/fxmark_pass.bpf.o"
install -m 0444 "$(FXMARK_SELECT_POLICY)" "$(1)/artifacts/runtime/fxmark_select.bpf.o"
jq -n \
	--arg patched_commit "$$(cat "$(KERNEL_COMMIT_FILE)")" \
	--arg patched_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(KERNEL_RELEASE_HEADER)")" \
	--arg patched_build_id "$$(readelf -n "$(KERNEL_BUILD_DIR)/vmlinux" | awk '/Build ID:/ {print $$3; exit}')" \
	--arg patched_notes_sha256 "$$(sha256sum "$(1)/artifacts/kernel/patched/vmlinux.notes" | awk '{print $$1}')" \
	--arg patched_btf_sha256 "$$(sha256sum "$(1)/artifacts/kernel/patched/vmlinux.btf" | awk '{print $$1}')" \
	--arg stock_commit "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" \
	--arg stock_source_tree_sha256 "$$(cat "$(STOCK_KERNEL_SOURCE_HASH_FILE)")" \
	--arg stock_release "$$(sed -n 's/^#define UTS_RELEASE "\(.*\)"/\1/p' "$(STOCK_KERNEL_RELEASE_HEADER)")" \
	--arg stock_build_id "$$(readelf -n "$(STOCK_KERNEL_BUILD_DIR)/vmlinux" | awk '/Build ID:/ {print $$3; exit}')" \
	--arg stock_notes_sha256 "$$(sha256sum "$(1)/artifacts/kernel/stock/vmlinux.notes" | awk '{print $$1}')" \
	--arg stock_btf_sha256 "$$(sha256sum "$(1)/artifacts/kernel/stock/vmlinux.btf" | awk '{print $$1}')" \
	'{patched:{commit:$$patched_commit,release:$$patched_release,build_id:$$patched_build_id,notes_sha256:$$patched_notes_sha256,btf_sha256:$$patched_btf_sha256,image:"artifacts/kernel/patched/bzImage",config:"artifacts/kernel/patched/config"},stock:{commit:$$stock_commit,source_tree_sha256:$$stock_source_tree_sha256,release:$$stock_release,build_id:$$stock_build_id,notes_sha256:$$stock_notes_sha256,btf_sha256:$$stock_btf_sha256,image:"artifacts/kernel/stock/bzImage",config:"artifacts/kernel/stock/config"},runtime:{fxmark:"artifacts/runtime/fxmark",cell:"artifacts/runtime/fxmark_cell",fuse:"artifacts/runtime/fxmark_fuse",pass_policy:"artifacts/runtime/fxmark_pass.bpf.o",select_policy:"artifacts/runtime/fxmark_select.bpf.o"}}' \
	>"$(1)/artifacts/manifest.json.tmp"
jq -e '.patched.commit | length == 40' "$(1)/artifacts/manifest.json.tmp" >/dev/null
	jq -e '.stock.commit | length == 40' "$(1)/artifacts/manifest.json.tmp" >/dev/null
	jq -e '.stock.source_tree_sha256 | length == 64' "$(1)/artifacts/manifest.json.tmp" >/dev/null
jq -e '.patched.release | length > 0' "$(1)/artifacts/manifest.json.tmp" >/dev/null
jq -e '.stock.release | length > 0' "$(1)/artifacts/manifest.json.tmp" >/dev/null
jq -e '.patched.build_id | length > 0' "$(1)/artifacts/manifest.json.tmp" >/dev/null
jq -e '.stock.build_id | length > 0' "$(1)/artifacts/manifest.json.tmp" >/dev/null
mv -f "$(1)/artifacts/manifest.json.tmp" "$(1)/artifacts/manifest.json"
sha256sum \
	"$(1)/artifacts/kernel/patched/bzImage" \
	"$(1)/artifacts/kernel/patched/config" \
	"$(1)/artifacts/kernel/patched/vmlinux.btf" \
	"$(1)/artifacts/kernel/patched/vmlinux.notes" \
	"$(1)/artifacts/kernel/stock/bzImage" \
	"$(1)/artifacts/kernel/stock/config" \
	"$(1)/artifacts/kernel/stock/vmlinux.btf" \
	"$(1)/artifacts/kernel/stock/vmlinux.notes" \
	"$(1)/artifacts/runtime/fxmark" \
	"$(1)/artifacts/runtime/fxmark_cell" \
	"$(1)/artifacts/runtime/fxmark_fuse" \
	"$(1)/artifacts/runtime/fxmark_pass.bpf.o" \
	"$(1)/artifacts/runtime/fxmark_select.bpf.o" \
	"$(1)/artifacts/manifest.json" \
	>"$(1)/artifacts.sha256"
endef

define FXMARK_WRITE_GUEST_MAKEFILE
printf '%s := %s\n' \
	'CONDITION' "$$condition" \
	'REPETITION' "$$repetition" \
	'FXMARK_RUN_DURATION' "$(1)" \
	'FXMARK_RUN_TYPES' "$(2)" \
	'FXMARK_RUN_CORES' "$(3)" \
	'FXMARK_RUN_BINARY' "$${fxmark_binary#$(ROOT_DIR)/}" \
	'FXMARK_RUN_CELL' "$${fxmark_cell#$(ROOT_DIR)/}" \
	'FXMARK_RUN_FUSE' "$${fxmark_fuse#$(ROOT_DIR)/}" \
	'FXMARK_RUN_PASS_POLICY' "$${pass_policy#$(ROOT_DIR)/}" \
	'FXMARK_RUN_SELECT_POLICY' "$${select_policy#$(ROOT_DIR)/}" \
	'FXMARK_BOOT_RESULT_DIR' "$${boot_dir#$(ROOT_DIR)/}" \
	'FXMARK_BOOT_KERNEL_CONFIG' "$${config#$(ROOT_DIR)/}" \
	'FXMARK_BOOT_KERNEL_COMMIT' "$$commit" \
	'FXMARK_BOOT_KERNEL_BUILD_ID' "$$build_id" \
	'FXMARK_BOOT_KERNEL_NOTES_SHA256' "$$notes_sha" \
	'FXMARK_BOOT_KERNEL_BTF_SHA256' "$$btf_sha" \
	'FXMARK_BOOT_KERNEL_RELEASE' "$$release" \
	'FXMARK_BOOT_KERNEL_FLAVOR' "$$flavor" \
	'FXMARK_BPF_STATS' "$(FXMARK_BPF_STATS)" \
	'FXMARK_REQUIRE_AFFINITY' "$(if $(strip $(4)),$(4),0)" \
	>"$$guest_makefile"; \
test "$$(wc -l <"$$guest_makefile")" = "20"; \
! grep -F "$(ROOT_DIR)/" "$$guest_makefile" >/dev/null; \
(cd "$$boot_dir" && sha256sum guest.mk >guest.mk.sha256)
endef

.PHONY: fxmark-source fxmark-rq2-build fxmark-kernel-pair \
	kvm-fxmark-rq2-preflight kvm-fxmark-rq2 \
	fxmark-rq2-finalize fxmark-rq2-report experiment-fxmark-rq2 \
	__fxmark_rq2_guest fxmark-rq2-clean

fxmark-source: $(FXMARK_SOURCE_STAMP)

fxmark-rq2-build: $(FXMARK_SOURCE_STAMP) runner
	$(MAKE) -C "$(ROOT_DIR)/bench/fxmark" \
		ROOT_DIR="$(ROOT_DIR)" \
		BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(FXMARK_OUTPUT)" \
		FXMARK_SOURCE_ROOT="$(FXMARK_SOURCE_ROOT)" all

fxmark-kernel-pair: kernel kernel-stock kernel-provenance \
		kernel-stock-provenance $(FXMARK_PATCHED_KERNEL_BTF) \
		$(FXMARK_STOCK_KERNEL_BTF) $(FXMARK_PATCHED_KERNEL_NOTES) \
		$(FXMARK_STOCK_KERNEL_NOTES)
	git -C "$(KERNEL_DIR)" merge-base --is-ancestor "$(STOCK_KERNEL_COMMIT)" "$$(cat "$(KERNEL_COMMIT_FILE)")"
	test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = "$(STOCK_KERNEL_COMMIT)"
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	! grep '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	diff -u \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(KERNEL_BUILD_DIR)/.config") \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config")

$(FXMARK_PATCHED_KERNEL_BTF): $(KERNEL_IMAGE)
	command -v objcopy >/dev/null
	install -d "$(dir $@)"
	objcopy --dump-section .BTF="$@.tmp" "$(KERNEL_BUILD_DIR)/vmlinux"
	test -s "$@.tmp"
	mv -f "$@.tmp" "$@"

$(FXMARK_STOCK_KERNEL_BTF): $(STOCK_KERNEL_IMAGE)
	command -v objcopy >/dev/null
	install -d "$(dir $@)"
	objcopy --dump-section .BTF="$@.tmp" "$(STOCK_KERNEL_BUILD_DIR)/vmlinux"
	test -s "$@.tmp"
	mv -f "$@.tmp" "$@"

$(FXMARK_PATCHED_KERNEL_NOTES): $(KERNEL_IMAGE)
	command -v objcopy >/dev/null
	install -d "$(dir $@)"
	objcopy --dump-section .notes="$@.tmp" "$(KERNEL_BUILD_DIR)/vmlinux"
	test -s "$@.tmp"
	mv -f "$@.tmp" "$@"

$(FXMARK_STOCK_KERNEL_NOTES): $(STOCK_KERNEL_IMAGE)
	command -v objcopy >/dev/null
	install -d "$(dir $@)"
	objcopy --dump-section .notes="$@.tmp" "$(STOCK_KERNEL_BUILD_DIR)/vmlinux"
	test -s "$@.tmp"
	mv -f "$@.tmp" "$@"

$(FXMARK_CACHE_DIR):
	install -d "$@"

$(FXMARK_ARCHIVE): | $(FXMARK_CACHE_DIR)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(FXMARK_ARCHIVE_URL)"
	printf '%s  %s\n' "$(FXMARK_ARCHIVE_SHA256)" "$@.tmp" | sha256sum -c -
	mv -f "$@.tmp" "$@"

$(FXMARK_SOURCE_STAMP): $(FXMARK_ARCHIVE) \
		$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch
	rm -rf "$(FXMARK_SOURCE_ROOT)"
	install -d "$(FXMARK_SOURCE_ROOT)"
	printf '%s  %s\n' "$(FXMARK_ARCHIVE_SHA256)" "$(FXMARK_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(FXMARK_ARCHIVE)" -C "$(FXMARK_SOURCE_ROOT)" --strip-components=1
	test -f "$(FXMARK_SOURCE_ROOT)/src/fxmark.c"
	test -f "$(FXMARK_SOURCE_ROOT)/src/MRPL.c"
	test -f "$(FXMARK_SOURCE_ROOT)/src/MRPM.c"
	test -f "$(FXMARK_SOURCE_ROOT)/src/MRPH.c"
	patch --fuzz=0 -d "$(FXMARK_SOURCE_ROOT)" -p1 <"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch"
	printf '%s\n' "$(FXMARK_COMMIT)" >"$@"

kvm-fxmark-rq2-preflight: fxmark-kernel-pair fxmark-rq2-build bpf
	command -v readelf >/dev/null
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(FXMARK_PREFLIGHT_RESULT_DIR))
	install -d "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots"
	$(call NAMEI_EXT_RUN_START,$(FXMARK_PREFLIGHT_RESULT_DIR),fxmark-rq2,fxmark-atc2016,kvm_fxmark_rq2_preflight,$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl,fxmark_pass.bpf.c+fxmark_select.bpf.c,fxmark_cell+fxmark_fuse)
	$(call FXMARK_CAPTURE_RUN_ARTIFACTS,$(FXMARK_PREFLIGHT_RESULT_DIR))
	jq --slurpfile kernel_artifacts "$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts/manifest.json" \
		--argjson duration_seconds "$(FXMARK_PREFLIGHT_DURATION)" \
		--argjson bpf_stats "$(FXMARK_BPF_STATS)" \
		'.layout = "boot-matrix" | .kernel_artifacts = $$kernel_artifacts[0] | .kernel_commits = {patched:$$kernel_artifacts[0].patched.commit,stock:$$kernel_artifacts[0].stock.commit} | .matrix = {conditions:["stock","unattached","empty","pass","select","fuse"],types:["MRPL"],workers:[1],repetitions:1,duration_seconds:$$duration_seconds,bpf_stats:$$bpf_stats}' \
		"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json.tmp"
	mv -f "$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json.tmp" \
		"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json"
	jq --slurpfile manifest "$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts/manifest.json" -e '.kernel_artifacts == $$manifest[0] and .kernel.commit == .kernel_artifacts.patched.commit and .kernel_commit == .kernel_artifacts.patched.commit and .kernel_commits.patched == .kernel_artifacts.patched.commit and .kernel_commits.stock == .kernel_artifacts.stock.commit' "$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json" >/dev/null
	printf '%s\n' \
		'make kvm-fxmark-rq2-preflight RUN_ID=$(RUN_ID) FXMARK_BPF_STATS=$(FXMARK_BPF_STATS)' \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/command.txt"
	pkg-config --modversion fuse >"$(FXMARK_PREFLIGHT_RESULT_DIR)/fuse-version.txt"
	ldd "$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts/runtime/fxmark_fuse" >"$(FXMARK_PREFLIGHT_RESULT_DIR)/fxmark-fuse-ldd.txt"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
		"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/mk/kernel.mk" \
		"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_fuse.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_pass.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_select.bpf.c" \
		"$(ROOT_DIR)/docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/inputs.sha256"
	: >"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"
	: >"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"
	manifest="$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts/manifest.json"; \
	fxmark_binary="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.fxmark' "$$manifest")"; \
	fxmark_cell="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.cell' "$$manifest")"; \
	fxmark_fuse="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.fuse' "$$manifest")"; \
	pass_policy="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.pass_policy' "$$manifest")"; \
	select_policy="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r '.runtime.select_policy' "$$manifest")"; \
	conditions=(stock unattached empty pass select fuse); \
	for condition in "$${conditions[@]}"; do \
		case "$$condition" in \
		stock|fuse) flavor=stock ;; \
		unattached|empty|pass|select) flavor=patched ;; \
		*) exit 1 ;; \
		esac; \
		image="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].image' "$$manifest")"; \
		config="$(FXMARK_PREFLIGHT_RESULT_DIR)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].config' "$$manifest")"; \
		commit=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].commit' "$$manifest"); \
		build_id=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].build_id' "$$manifest"); \
		notes_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].notes_sha256' "$$manifest"); \
		btf_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].btf_sha256' "$$manifest"); \
		release=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].release' "$$manifest"); \
		printf '1|%s|%s|%s|%s|%s|%s\n' "$$condition" "$$commit" "$$build_id" "$$notes_sha" "$$btf_sha" "$$release" >>"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"; \
		printf '1|%s|MRPL|1\n' "$$condition" >>"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"; \
		boot_dir="$(FXMARK_PREFLIGHT_RESULT_DIR)/boots/block-01-$$condition"; \
		install -d "$$boot_dir"; \
		repetition=1; \
		guest_makefile="$$boot_dir/guest.mk"; \
		$(call FXMARK_WRITE_GUEST_MAKEFILE,$(FXMARK_PREFLIGHT_DURATION),MRPL,1); \
		guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
		$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __fxmark_rq2_guest,,$$boot_dir,$(FXMARK_PREFLIGHT_RESULT_DIR)); \
	done
	LC_ALL=C sort -o "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"
	LC_ALL=C sort -o "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl"
	jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl" | LC_ALL=C sort >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-cells.txt"
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)|\(.kernel_release)"' | LC_ALL=C sort >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-boots.txt"
	cmp "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-cells.txt"
	cmp "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-boots.txt"
	sha256sum -c "$(FXMARK_PREFLIGHT_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts.sha256"
	test "$$(jq -s 'length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "6"
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "6"
	test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "6"
	test "$$(find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name boot.json -type f | wc -l)" = "6"
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | \
		xargs -0 jq -s -e 'group_by(.kernel_flavor) | length == 2 and all(.[]; ([.[] | [.kernel_commit,.kernel_build_id,.kernel_notes_sha256,.kernel_btf_sha256,.kernel_release]] | unique | length) == 1)' >/dev/null
	for boot in "$(FXMARK_PREFLIGHT_RESULT_DIR)"/boots/*; do \
		for file in guest.mk guest.mk.sha256 launcher.stdout.log launcher.stderr.log; do \
			test -e "$$boot/$$file"; \
		done; \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		for file in boot.json observations.jsonl kernel.config kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 kernel-btf.sha256 kernel-flavor.txt kernel-release.txt clocksource-before.txt clocksource-after.txt uname.txt proc-version.txt kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt dmesg.log; do \
			test -s "$$boot/$$file"; \
		done; \
		jq -e '.status == "completed" and .clocksource == "tsc" and (.completed_at | type == "string" and length > 0)' "$$boot/boot.json" >/dev/null; \
	done
	for file in fuse-version.txt fxmark-fuse-ldd.txt; do test -s "$(FXMARK_PREFLIGHT_RESULT_DIR)/$$file"; done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(FXMARK_PREFLIGHT_RESULT_DIR),$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl)
	jq --slurpfile manifest "$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts/manifest.json" -e '.layout == "boot-matrix" and (.kernel_commits | keys | sort) == ["patched","stock"] and .kernel_artifacts == $$manifest[0] and .kernel.commit == .kernel_artifacts.patched.commit and .kernel_commit == .kernel_artifacts.patched.commit and .kernel_commits.patched == .kernel_artifacts.patched.commit and .kernel_commits.stock == .kernel_artifacts.stock.commit' "$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_PREFLIGHT_RESULT_DIR))

kvm-fxmark-rq2: fxmark-kernel-pair fxmark-rq2-build bpf
	command -v readelf >/dev/null
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(FXMARK_RESULT_DIR))
	install -d "$(FXMARK_RESULT_DIR)/boots"
	$(call NAMEI_EXT_RUN_START,$(FXMARK_RESULT_DIR),fxmark-rq2,fxmark-atc2016,kvm_fxmark_rq2_matrix,$(FXMARK_RESULT_DIR)/observations.jsonl,fxmark_pass.bpf.c+fxmark_select.bpf.c,fxmark_cell+fxmark_fuse)
	$(call FXMARK_CAPTURE_RUN_ARTIFACTS,$(FXMARK_RESULT_DIR))
	jq --slurpfile kernel_artifacts "$(FXMARK_RESULT_DIR)/artifacts/manifest.json" \
		--argjson repetitions "$(FXMARK_REPETITIONS)" \
		--arg types "$(FXMARK_TYPES)" \
		--arg cores "$(FXMARK_CORES)" \
		--argjson duration_seconds "$(FXMARK_DURATION)" \
		--argjson bpf_stats "$(FXMARK_BPF_STATS)" \
		'.layout = "boot-matrix" | .kernel_artifacts = $$kernel_artifacts[0] | .kernel_commits = {patched:$$kernel_artifacts[0].patched.commit,stock:$$kernel_artifacts[0].stock.commit} | .matrix = {conditions:["stock","unattached","pass","select","fuse"],types:($$types|split(" ")),workers:($$cores|split(" ")|map(tonumber)),repetitions:$$repetitions,duration_seconds:$$duration_seconds,bpf_stats:$$bpf_stats}' \
		"$(FXMARK_RESULT_DIR)/run.json" \
		>"$(FXMARK_RESULT_DIR)/run.json.tmp"
	mv -f "$(FXMARK_RESULT_DIR)/run.json.tmp" "$(FXMARK_RESULT_DIR)/run.json"
	jq --slurpfile manifest "$(FXMARK_RESULT_DIR)/artifacts/manifest.json" -e '.kernel_artifacts == $$manifest[0] and .kernel.commit == .kernel_artifacts.patched.commit and .kernel_commit == .kernel_artifacts.patched.commit and .kernel_commits.patched == .kernel_artifacts.patched.commit and .kernel_commits.stock == .kernel_artifacts.stock.commit' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	printf '%s\n' 'make kvm-fxmark-rq2 RUN_ID=$(RUN_ID) FXMARK_BPF_STATS=$(FXMARK_BPF_STATS)' \
		>"$(FXMARK_RESULT_DIR)/command.txt"
	lscpu >"$(FXMARK_RESULT_DIR)/host-lscpu.txt"
	found=false; \
	for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do \
		test -f "$$file" || continue; \
		found=true; \
		printf '%s ' "$$file"; \
		sed -n '1p' "$$file"; \
	done >"$(FXMARK_RESULT_DIR)/host-governors.txt"; \
	if ! $$found; then printf '%s\n' 'cpufreq-sysfs-unavailable' >"$(FXMARK_RESULT_DIR)/host-governors.txt"; fi
	pkg-config --modversion fuse >"$(FXMARK_RESULT_DIR)/fuse-version.txt"
	ldd "$(FXMARK_RESULT_DIR)/artifacts/runtime/fxmark_fuse" >"$(FXMARK_RESULT_DIR)/fxmark-fuse-ldd.txt"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/configs/kvm/x86_64.mk" \
		"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/mk/kernel.mk" \
		"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_fuse.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_pass.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_select.bpf.c" \
		"$(ROOT_DIR)/analysis/fxmark/analyze.py" \
		"$(ROOT_DIR)/docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md" \
		>"$(FXMARK_RESULT_DIR)/inputs.sha256"
	: >"$(FXMARK_RESULT_DIR)/expected-boots.txt"
	: >"$(FXMARK_RESULT_DIR)/expected-cells.txt"
	manifest="$(FXMARK_RESULT_DIR)/artifacts/manifest.json"; \
	fxmark_binary="$(FXMARK_RESULT_DIR)/$$(jq -r '.runtime.fxmark' "$$manifest")"; \
	fxmark_cell="$(FXMARK_RESULT_DIR)/$$(jq -r '.runtime.cell' "$$manifest")"; \
	fxmark_fuse="$(FXMARK_RESULT_DIR)/$$(jq -r '.runtime.fuse' "$$manifest")"; \
	pass_policy="$(FXMARK_RESULT_DIR)/$$(jq -r '.runtime.pass_policy' "$$manifest")"; \
	select_policy="$(FXMARK_RESULT_DIR)/$$(jq -r '.runtime.select_policy' "$$manifest")"; \
	base=(stock unattached pass select fuse); \
	for repetition in $$(seq 1 "$(FXMARK_REPETITIONS)"); do \
		offset=$$(((repetition - 1) % 5)); \
		for step in 0 1 2 3 4; do \
			condition="$${base[$$(((offset + step) % 5))]}"; \
			case "$$condition" in \
			stock|fuse) flavor=stock ;; \
			unattached|pass|select) flavor=patched ;; \
			*) exit 1 ;; \
			esac; \
			image="$(FXMARK_RESULT_DIR)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].image' "$$manifest")"; \
			config="$(FXMARK_RESULT_DIR)/$$(jq -r --arg flavor "$$flavor" '.[$$flavor].config' "$$manifest")"; \
			commit=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].commit' "$$manifest"); \
			build_id=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].build_id' "$$manifest"); \
			notes_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].notes_sha256' "$$manifest"); \
			btf_sha=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].btf_sha256' "$$manifest"); \
			release=$$(jq -r --arg flavor "$$flavor" '.[$$flavor].release' "$$manifest"); \
			printf '%s|%s|%s|%s|%s|%s|%s\n' "$$repetition" "$$condition" "$$commit" "$$build_id" "$$notes_sha" "$$btf_sha" "$$release" >>"$(FXMARK_RESULT_DIR)/expected-boots.txt"; \
			for type in $(FXMARK_TYPES); do for workers in $(FXMARK_CORES); do printf '%s|%s|%s|%s\n' "$$repetition" "$$condition" "$$type" "$$workers" >>"$(FXMARK_RESULT_DIR)/expected-cells.txt"; done; done; \
			boot_dir="$(FXMARK_RESULT_DIR)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
			install -d "$$boot_dir"; \
			guest_makefile="$$boot_dir/guest.mk"; \
			$(call FXMARK_WRITE_GUEST_MAKEFILE,$(FXMARK_DURATION),$(FXMARK_TYPES),$(FXMARK_CORES)); \
			guest_makefile_rel="$${guest_makefile#$(ROOT_DIR)/}"; \
			$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,-f Makefile -f $$guest_makefile_rel __fxmark_rq2_guest,,$$boot_dir,$(FXMARK_RESULT_DIR)); \
		done; \
	done
	$(MAKE) -C "$(ROOT_DIR)" fxmark-rq2-finalize \
		RUN_ID="$(RUN_ID)"

fxmark-rq2-finalize:
	jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	LC_ALL=C sort -o "$(FXMARK_RESULT_DIR)/expected-boots.txt" "$(FXMARK_RESULT_DIR)/expected-boots.txt"
	LC_ALL=C sort -o "$(FXMARK_RESULT_DIR)/expected-cells.txt" "$(FXMARK_RESULT_DIR)/expected-cells.txt"
	find "$(FXMARK_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_RESULT_DIR)/observations.jsonl"
	jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' "$(FXMARK_RESULT_DIR)/observations.jsonl" | LC_ALL=C sort >"$(FXMARK_RESULT_DIR)/observed-cells.txt"
	find "$(FXMARK_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)|\(.kernel_release)"' | LC_ALL=C sort >"$(FXMARK_RESULT_DIR)/observed-boots.txt"
	cmp "$(FXMARK_RESULT_DIR)/expected-cells.txt" "$(FXMARK_RESULT_DIR)/observed-cells.txt"
	cmp "$(FXMARK_RESULT_DIR)/expected-boots.txt" "$(FXMARK_RESULT_DIR)/observed-boots.txt"
	sha256sum -c "$(FXMARK_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(FXMARK_RESULT_DIR)/artifacts.sha256"
	expected=$$(jq '.matrix | (.conditions | length) * (.types | length) * (.workers | length) * .repetitions' "$(FXMARK_RESULT_DIR)/run.json"); \
	test "$$(jq -s 'length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"; \
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"; \
	test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"
	expected_boots=$$(jq '.matrix | (.conditions | length) * .repetitions' "$(FXMARK_RESULT_DIR)/run.json"); \
	test "$$(find "$(FXMARK_RESULT_DIR)/boots" -name boot.json -type f | wc -l)" = "$$expected_boots"
	find "$(FXMARK_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | \
		xargs -0 jq -s -e 'group_by(.kernel_flavor) | length == 2 and all(.[]; ([.[] | [.kernel_commit,.kernel_build_id,.kernel_notes_sha256,.kernel_btf_sha256,.kernel_release]] | unique | length) == 1)' >/dev/null
	for boot in "$(FXMARK_RESULT_DIR)"/boots/*; do \
		for file in guest.mk guest.mk.sha256 launcher.stdout.log launcher.stderr.log; do \
			test -e "$$boot/$$file"; \
		done; \
		(cd "$$boot" && sha256sum -c guest.mk.sha256); \
		for file in boot.json observations.jsonl kernel.config kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 kernel-btf.sha256 kernel-flavor.txt kernel-release.txt clocksource-before.txt clocksource-after.txt uname.txt proc-version.txt kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt dmesg.log; do \
			test -s "$$boot/$$file"; \
		done; \
		jq -e '.status == "completed" and .clocksource == "tsc" and (.completed_at | type == "string" and length > 0)' "$$boot/boot.json" >/dev/null; \
	done
	for file in host-lscpu.txt host-governors.txt fuse-version.txt fxmark-fuse-ldd.txt; do test -s "$(FXMARK_RESULT_DIR)/$$file"; done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(FXMARK_RESULT_DIR),$(FXMARK_RESULT_DIR)/observations.jsonl)
	jq --slurpfile manifest "$(FXMARK_RESULT_DIR)/artifacts/manifest.json" -e '.layout == "boot-matrix" and (.kernel_commits | keys | sort) == ["patched","stock"] and .kernel_artifacts == $$manifest[0] and .kernel.commit == .kernel_artifacts.patched.commit and .kernel_commit == .kernel_artifacts.patched.commit and .kernel_commits.patched == .kernel_artifacts.patched.commit and .kernel_commits.stock == .kernel_artifacts.stock.commit' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_RESULT_DIR))

fxmark-rq2-report:
	jq -e '.status == "completed"' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	sha256sum -c "$(FXMARK_RESULT_DIR)/inputs.sha256"
	sha256sum -c "$(FXMARK_RESULT_DIR)/artifacts.sha256"
	python3 "$(ROOT_DIR)/analysis/fxmark/analyze.py" \
		--input "$(FXMARK_RESULT_DIR)/observations.jsonl" \
		--output "$(FXMARK_RESULT_DIR)/analysis" \
		--run "$(FXMARK_RESULT_DIR)/run.json" \
		--seed "$(FXMARK_ANALYSIS_SEED)"
	for file in summary.json summary.csv report.md throughput.png throughput.pdf; do \
		test -s "$(FXMARK_RESULT_DIR)/analysis/$$file"; \
	done

experiment-fxmark-rq2: kvm-fxmark-rq2
	$(MAKE) -C "$(ROOT_DIR)" fxmark-rq2-report \
		RUN_ID="$(RUN_ID)"

__fxmark_rq2_guest:
	test "$(notdir $(lastword $(MAKEFILE_LIST)))" = guest.mk
	(cd "$(dir $(lastword $(MAKEFILE_LIST)))" && sha256sum -c guest.mk.sha256)
	test -n "$(CONDITION)"
	test -n "$(REPETITION)"
	test -n "$(FXMARK_RUN_DURATION)"
	test -n "$(FXMARK_RUN_TYPES)"
	test -n "$(FXMARK_RUN_CORES)"
	test -x "$(FXMARK_RUN_BINARY)"
	test -x "$(FXMARK_RUN_CELL)"
	test -x "$(FXMARK_RUN_FUSE)"
	test -r "$(FXMARK_RUN_PASS_POLICY)"
	test -r "$(FXMARK_RUN_SELECT_POLICY)"
	test -n "$(FXMARK_BOOT_RESULT_DIR)"
	test -n "$(FXMARK_BOOT_KERNEL_CONFIG)"
	test -n "$(FXMARK_BOOT_KERNEL_COMMIT)"
	test -n "$(FXMARK_BOOT_KERNEL_BUILD_ID)"
	test -n "$(FXMARK_BOOT_KERNEL_NOTES_SHA256)"
	test -n "$(FXMARK_BOOT_KERNEL_BTF_SHA256)"
	test -n "$(FXMARK_BOOT_KERNEL_RELEASE)"
	test -n "$(FXMARK_BOOT_KERNEL_FLAVOR)"
	case "$(FXMARK_BPF_STATS)" in 0|1) ;; *) exit 1 ;; esac
	case "$(FXMARK_REQUIRE_AFFINITY)" in 0|1) ;; *) exit 1 ;; esac
	affinity_verified_at=; \
	if test "$(FXMARK_REQUIRE_AFFINITY)" = 1; then \
		affinity_status=waiting; \
		for attempt in $$(seq 1 500); do \
			if test -s "$(FXMARK_BOOT_RESULT_DIR)/vcpu-affinity.json"; then \
				if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "verified"' \
						"$(FXMARK_BOOT_RESULT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
					affinity_status=verified; \
					break; \
				fi; \
				if jq -e '.schema == "namei_ext.vcpu_affinity.v1" and .status == "failed"' \
						"$(FXMARK_BOOT_RESULT_DIR)/vcpu-affinity.json" >/dev/null 2>&1; then \
					cat "$(FXMARK_BOOT_RESULT_DIR)/vcpu-affinity.json" >&2; \
					exit 1; \
				fi; \
			fi; \
			sleep 0.05; \
		done; \
		test "$$affinity_status" = verified; \
		affinity_verified_at=$$(jq -r '.verified_at' \
			"$(FXMARK_BOOT_RESULT_DIR)/vcpu-affinity.json"); \
		test -n "$$affinity_verified_at"; \
		guest_barrier_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
		test -n "$$guest_barrier_at"; \
		printf '%s\n' "$$affinity_verified_at" \
			>"$(FXMARK_BOOT_RESULT_DIR)/affinity-verified-at.txt"; \
		printf '%s\n' "$$guest_barrier_at" \
			>"$(FXMARK_BOOT_RESULT_DIR)/affinity-barrier.txt"; \
	fi
	install -d "$(FXMARK_BOOT_RESULT_DIR)/raw" "$(FXMARK_GUEST_MOUNT)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	if test "$(FXMARK_REQUIRE_AFFINITY)" = 1; then \
		command -v bpftool >/dev/null; \
		command -v findmnt >/dev/null; \
		command -v lsof >/dev/null; \
		test -c /dev/fuse; \
		bpftool -j prog show \
			>"$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-before.json"; \
		bpftool -j cgroup tree \
			>"$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-before.json"; \
		jq -e 'type == "array" and length == 0' \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-before.json" >/dev/null; \
		jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-before.json" >/dev/null; \
		findmnt -rn -o FSTYPE,TARGET | \
			awk '$$1 == "fuse" || $$1 == "fuseblk" || index($$1, "fuse.") == 1' \
			>"$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-before.txt"; \
		test ! -s "$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-before.txt"; \
		lsof_status=0; \
		lsof -Fpc /dev/fuse \
			>"$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-before.txt" || \
			lsof_status=$$?; \
		test "$$lsof_status" = 1; \
		test ! -s "$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-before.txt"; \
	fi
	printf '%s\n' "$(FXMARK_BPF_STATS)" >/proc/sys/kernel/bpf_stats_enabled
	mount -t tmpfs -o "size=$(FXMARK_TMPFS_SIZE),noatime" tmpfs "$(FXMARK_GUEST_MOUNT)"
	: >"$(FXMARK_BOOT_RESULT_DIR)/observations.jsonl"
	cp "$(FXMARK_BOOT_KERNEL_CONFIG)" "$(FXMARK_BOOT_RESULT_DIR)/kernel.config"
	printf '%s\n' "$(FXMARK_BOOT_KERNEL_COMMIT)" >"$(FXMARK_BOOT_RESULT_DIR)/kernel-commit.txt"
	actual_notes_sha=$$(sha256sum /sys/kernel/notes | awk '{print $$1}'); \
	test "$$actual_notes_sha" = "$(FXMARK_BOOT_KERNEL_NOTES_SHA256)"; \
	printf '%s  %s\n' "$$actual_notes_sha" /sys/kernel/notes >"$(FXMARK_BOOT_RESULT_DIR)/kernel-notes.sha256"; \
	printf '%s\n' "$(FXMARK_BOOT_KERNEL_BUILD_ID)" >"$(FXMARK_BOOT_RESULT_DIR)/kernel-build-id.txt"
	actual_btf_sha=$$(sha256sum /sys/kernel/btf/vmlinux | awk '{print $$1}'); \
	test "$$actual_btf_sha" = "$(FXMARK_BOOT_KERNEL_BTF_SHA256)"; \
	printf '%s  %s\n' "$$actual_btf_sha" /sys/kernel/btf/vmlinux >"$(FXMARK_BOOT_RESULT_DIR)/kernel-btf.sha256"
	if grep -q ' [Tt] namei_ext_lookup$$' /proc/kallsyms; then actual_flavor=patched; else actual_flavor=stock; fi; \
	test "$$actual_flavor" = "$(FXMARK_BOOT_KERNEL_FLAVOR)"; \
	printf '%s\n' "$$actual_flavor" >"$(FXMARK_BOOT_RESULT_DIR)/kernel-flavor.txt"
	actual_release=$$(uname -r); \
	test "$$actual_release" = "$(FXMARK_BOOT_KERNEL_RELEASE)"; \
	printf '%s\n' "$$actual_release" >"$(FXMARK_BOOT_RESULT_DIR)/kernel-release.txt"
	uname -a >"$(FXMARK_BOOT_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(FXMARK_BOOT_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(FXMARK_BOOT_RESULT_DIR)/kernel-cmdline.txt"
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = tsc; \
	printf '%s\n' "$$clocksource" >"$(FXMARK_BOOT_RESULT_DIR)/clocksource-before.txt"
	cat /proc/stat >"$(FXMARK_BOOT_RESULT_DIR)/proc-stat-before.txt"
	policy="-"; \
	case "$(CONDITION)" in \
	empty|pass) policy="$(FXMARK_RUN_PASS_POLICY)" ;; \
	select) policy="$(FXMARK_RUN_SELECT_POLICY)" ;; \
	stock|unattached|fuse) ;; \
	*) exit 1 ;; \
	esac; \
	for type in $(FXMARK_RUN_TYPES); do \
		for cores in $(FXMARK_RUN_CORES); do \
			cell="$${type}-$${cores}"; \
			work="$(FXMARK_GUEST_MOUNT)/cell-$${cell}"; \
			raw="$(FXMARK_BOOT_RESULT_DIR)/raw/$${cell}"; \
			"$(FXMARK_RUN_CELL)" "$(CONDITION)" "$(FXMARK_RUN_BINARY)" \
			"$(FXMARK_RUN_FUSE)" "$$policy" \
				"$(FXMARK_BOOT_RESULT_DIR)/observations.jsonl" "$$raw" \
				"$$work" /sys/fs/cgroup "$$type" "$$cores" \
				"$(FXMARK_RUN_DURATION)" "$(FXMARK_CELL_TIMEOUT)" \
				"$(REPETITION)"; \
		done; \
	done
	cat /proc/stat >"$(FXMARK_BOOT_RESULT_DIR)/proc-stat-after.txt"
	if test "$(FXMARK_REQUIRE_AFFINITY)" = 1; then \
		bpftool -j prog show \
			>"$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-after.json"; \
		bpftool -j cgroup tree \
			>"$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-after.json"; \
		jq -e 'type == "array" and length == 0' \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-after.json" >/dev/null; \
		jq -e 'type == "array" and all(.[]; has("error") | not) and ([.. | objects | select(has("id"))] | length) == 0' \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-after.json" >/dev/null; \
		cmp "$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-before.json" \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-programs-after.json"; \
		cmp "$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-before.json" \
			"$(FXMARK_BOOT_RESULT_DIR)/bpf-cgroup-after.json"; \
		findmnt -rn -o FSTYPE,TARGET | \
			awk '$$1 == "fuse" || $$1 == "fuseblk" || index($$1, "fuse.") == 1' \
			>"$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-after.txt"; \
		test ! -s "$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-after.txt"; \
		lsof_status=0; \
		lsof -Fpc /dev/fuse \
			>"$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-after.txt" || \
			lsof_status=$$?; \
		test "$$lsof_status" = 1; \
		test ! -s "$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-after.txt"; \
		cmp "$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-before.txt" \
			"$(FXMARK_BOOT_RESULT_DIR)/fuse-mounts-after.txt"; \
		cmp "$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-before.txt" \
			"$(FXMARK_BOOT_RESULT_DIR)/fuse-open-fds-after.txt"; \
	fi
	clocksource=$$(cat /sys/devices/system/clocksource/clocksource0/current_clocksource); \
	test "$$clocksource" = "$$(cat "$(FXMARK_BOOT_RESULT_DIR)/clocksource-before.txt")"; \
	printf '%s\n' "$$clocksource" >"$(FXMARK_BOOT_RESULT_DIR)/clocksource-after.txt"
	dmesg >"$(FXMARK_BOOT_RESULT_DIR)/dmesg.log"
	$(call NAMEI_EXT_GUEST_ASSERT_DMESG_CLEAN,$(FXMARK_BOOT_RESULT_DIR)/dmesg.log)
	umount "$(FXMARK_GUEST_MOUNT)"
	completed_at=$$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); \
	test -n "$$completed_at"; \
	affinity_verified_at=; \
	guest_barrier_at=; \
	if test "$(FXMARK_REQUIRE_AFFINITY)" = 1; then \
		affinity_verified_at=$$(cat \
			"$(FXMARK_BOOT_RESULT_DIR)/affinity-verified-at.txt"); \
		test -n "$$affinity_verified_at"; \
		guest_barrier_at=$$(cat \
			"$(FXMARK_BOOT_RESULT_DIR)/affinity-barrier.txt"); \
		test -n "$$guest_barrier_at"; \
	fi; \
	jq -n \
		--arg schema "namei_ext.fxmark.boot.v2" \
		--arg condition "$(CONDITION)" \
		--argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(FXMARK_BOOT_KERNEL_COMMIT)" \
		--arg kernel_build_id "$(FXMARK_BOOT_KERNEL_BUILD_ID)" \
		--arg kernel_notes_sha256 "$(FXMARK_BOOT_KERNEL_NOTES_SHA256)" \
		--arg kernel_btf_sha256 "$(FXMARK_BOOT_KERNEL_BTF_SHA256)" \
		--arg kernel_flavor "$(FXMARK_BOOT_KERNEL_FLAVOR)" \
		--arg kernel_release "$$(cat "$(FXMARK_BOOT_RESULT_DIR)/kernel-release.txt")" \
		--arg clocksource "$$(cat "$(FXMARK_BOOT_RESULT_DIR)/clocksource-after.txt")" \
		--arg affinity_verified_at "$$affinity_verified_at" \
		--arg guest_barrier_at "$$guest_barrier_at" \
		--arg completed_at "$$completed_at" \
		'{schema:$$schema,condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_build_id:$$kernel_build_id,kernel_notes_sha256:$$kernel_notes_sha256,kernel_btf_sha256:$$kernel_btf_sha256,kernel_flavor:$$kernel_flavor,kernel_release:$$kernel_release,clocksource:$$clocksource,affinity_verified_at:$$affinity_verified_at,guest_barrier_at:$$guest_barrier_at,status:"completed",completed_at:$$completed_at}' \
		>"$(FXMARK_BOOT_RESULT_DIR)/boot.json.tmp"; \
	mv -f "$(FXMARK_BOOT_RESULT_DIR)/boot.json.tmp" \
		"$(FXMARK_BOOT_RESULT_DIR)/boot.json"; \
	jq -e '.schema == "namei_ext.fxmark.boot.v2" and .status == "completed" and (.completed_at | type == "string" and length > 0)' \
		"$(FXMARK_BOOT_RESULT_DIR)/boot.json" >/dev/null

fxmark-rq2-clean:
	$(MAKE) -C "$(ROOT_DIR)/bench/fxmark" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(FXMARK_OUTPUT)" clean
	rm -rf "$(FXMARK_SOURCE_ROOT)"
