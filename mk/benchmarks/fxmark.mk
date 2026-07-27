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
	jq --arg stock_kernel_commit "$(STOCK_KERNEL_COMMIT)" \
		--argjson duration_seconds "$(FXMARK_PREFLIGHT_DURATION)" \
		'.layout = "boot-matrix" | .kernel_commits = {patched:.kernel_commit,stock:$$stock_kernel_commit} | .matrix = {conditions:["stock","unattached","pass","select","fuse"],types:["MRPL"],workers:[1],repetitions:1,duration_seconds:$$duration_seconds}' \
		"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json.tmp"
	mv -f "$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json.tmp" \
		"$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json"
	printf '%s\n' \
		'make kvm-fxmark-rq2-preflight RUN_ID=$(RUN_ID)' \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/command.txt"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_fuse.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_pass.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_select.bpf.c" \
		"$(ROOT_DIR)/docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/inputs.sha256"
	sha256sum "$(FXMARK_BINARY)" "$(FXMARK_CELL)" "$(FXMARK_FUSE)" \
		"$(FXMARK_PASS_POLICY)" "$(FXMARK_SELECT_POLICY)" \
		"$(KERNEL_IMAGE)" "$(STOCK_KERNEL_IMAGE)" \
		"$(KERNEL_BUILD_DIR)/vmlinux" "$(STOCK_KERNEL_BUILD_DIR)/vmlinux" \
		"$(FXMARK_PATCHED_KERNEL_BTF)" "$(FXMARK_STOCK_KERNEL_BTF)" \
		"$(FXMARK_PATCHED_KERNEL_NOTES)" "$(FXMARK_STOCK_KERNEL_NOTES)" \
		"$(KERNEL_BUILD_DIR)/.config" \
		"$(STOCK_KERNEL_BUILD_DIR)/.config" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts.sha256"
	: >"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"
	: >"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"
	conditions=(stock unattached pass select fuse); \
	for condition in "$${conditions[@]}"; do \
		case "$$condition" in \
		stock|fuse) image="$(STOCK_KERNEL_IMAGE)"; config="$(STOCK_KERNEL_BUILD_DIR)/.config"; vmlinux="$(STOCK_KERNEL_BUILD_DIR)/vmlinux"; commit="$(STOCK_KERNEL_COMMIT)"; btf="$(FXMARK_STOCK_KERNEL_BTF)"; notes="$(FXMARK_STOCK_KERNEL_NOTES)"; flavor=stock ;; \
		unattached|pass|select) image="$(KERNEL_IMAGE)"; config="$(KERNEL_BUILD_DIR)/.config"; vmlinux="$(KERNEL_BUILD_DIR)/vmlinux"; commit="$$(cat "$(KERNEL_COMMIT_FILE)")"; btf="$(FXMARK_PATCHED_KERNEL_BTF)"; notes="$(FXMARK_PATCHED_KERNEL_NOTES)"; flavor=patched ;; \
		*) exit 1 ;; \
		esac; \
		btf_sha=$$(sha256sum "$$btf" | awk '{print $$1}'); \
		notes_sha=$$(sha256sum "$$notes" | awk '{print $$1}'); \
		build_id=$$(readelf -n "$$vmlinux" | awk '/Build ID:/ {print $$3; exit}'); \
		test -n "$$build_id"; \
		printf '1|%s|%s|%s|%s|%s\n' "$$condition" "$$commit" "$$build_id" "$$notes_sha" "$$btf_sha" >>"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"; \
		printf '1|%s|MRPL|1\n' "$$condition" >>"$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"; \
		boot_dir="$(FXMARK_PREFLIGHT_RESULT_DIR)/boots/block-01-$$condition"; \
		install -d "$$boot_dir"; \
		$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,__fxmark_rq2_guest,CONDITION=$$condition REPETITION=1 FXMARK_RUN_DURATION=$(FXMARK_PREFLIGHT_DURATION) FXMARK_RUN_TYPES=MRPL FXMARK_RUN_CORES=1 FXMARK_BOOT_RESULT_DIR=$$boot_dir FXMARK_BOOT_KERNEL_CONFIG=$$config FXMARK_BOOT_KERNEL_COMMIT=$$commit FXMARK_BOOT_KERNEL_BUILD_ID=$$build_id FXMARK_BOOT_KERNEL_NOTES_SHA256=$$notes_sha FXMARK_BOOT_KERNEL_BTF_SHA256=$$btf_sha FXMARK_BOOT_KERNEL_FLAVOR=$$flavor,$$boot_dir,$(FXMARK_PREFLIGHT_RESULT_DIR)); \
	done
	LC_ALL=C sort -o "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt"
	LC_ALL=C sort -o "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt"
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl"
	jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl" | LC_ALL=C sort >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-cells.txt"
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)"' | LC_ALL=C sort >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-boots.txt"
	cmp "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-cells.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-cells.txt"
	cmp "$(FXMARK_PREFLIGHT_RESULT_DIR)/expected-boots.txt" "$(FXMARK_PREFLIGHT_RESULT_DIR)/observed-boots.txt"
	test "$$(jq -s 'length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "5"
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "5"
	test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "5"
	test "$$(find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name boot.json -type f | wc -l)" = "5"
	for boot in "$(FXMARK_PREFLIGHT_RESULT_DIR)"/boots/*; do \
		for file in launcher.stdout.log launcher.stderr.log; do \
			test -e "$$boot/$$file"; \
		done; \
		for file in boot.json observations.jsonl kernel.config kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 kernel-btf.sha256 kernel-flavor.txt kernel-release.txt uname.txt proc-version.txt kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt dmesg.log; do \
			test -s "$$boot/$$file"; \
		done; \
		jq -e '.status == "completed"' "$$boot/boot.json" >/dev/null; \
	done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(FXMARK_PREFLIGHT_RESULT_DIR),$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl)
	jq -e '.layout == "boot-matrix" and (.kernel_commits | keys | sort) == ["patched","stock"]' "$(FXMARK_PREFLIGHT_RESULT_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_PREFLIGHT_RESULT_DIR))

kvm-fxmark-rq2: fxmark-kernel-pair fxmark-rq2-build bpf
	command -v readelf >/dev/null
	$(call NAMEI_EXT_RESULT_ROOT_CREATE,$(FXMARK_RESULT_DIR))
	install -d "$(FXMARK_RESULT_DIR)/boots"
	$(call NAMEI_EXT_RUN_START,$(FXMARK_RESULT_DIR),fxmark-rq2,fxmark-atc2016,kvm_fxmark_rq2_matrix,$(FXMARK_RESULT_DIR)/observations.jsonl,fxmark_pass.bpf.c+fxmark_select.bpf.c,fxmark_cell+fxmark_fuse)
	jq --arg stock_kernel_commit "$(STOCK_KERNEL_COMMIT)" \
		--argjson repetitions "$(FXMARK_REPETITIONS)" \
		--arg types "$(FXMARK_TYPES)" \
		--arg cores "$(FXMARK_CORES)" \
		--argjson duration_seconds "$(FXMARK_DURATION)" \
		'.layout = "boot-matrix" | .kernel_commits = {patched:.kernel_commit,stock:$$stock_kernel_commit} | .matrix = {conditions:["stock","unattached","pass","select","fuse"],types:($$types|split(" ")),workers:($$cores|split(" ")|map(tonumber)),repetitions:$$repetitions,duration_seconds:$$duration_seconds}' \
		"$(FXMARK_RESULT_DIR)/run.json" \
		>"$(FXMARK_RESULT_DIR)/run.json.tmp"
	mv -f "$(FXMARK_RESULT_DIR)/run.json.tmp" "$(FXMARK_RESULT_DIR)/run.json"
	printf '%s\n' 'make kvm-fxmark-rq2 RUN_ID=$(RUN_ID)' \
		>"$(FXMARK_RESULT_DIR)/command.txt"
	lscpu >"$(FXMARK_RESULT_DIR)/host-lscpu.txt"
	find /sys/devices/system/cpu -path '*/cpufreq/scaling_governor' \
		-type f -print -exec sed -n '1p' {} \; \
		>"$(FXMARK_RESULT_DIR)/host-governors.txt"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/benchmarks/fxmark.mk" \
		"$(ROOT_DIR)/mk/results.mk" "$(ROOT_DIR)/mk/kvm.mk" \
		"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_cell.c" \
		"$(ROOT_DIR)/bench/fxmark/fxmark_fuse.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_pass.bpf.c" \
		"$(ROOT_DIR)/bpf/policies/fxmark_select.bpf.c" \
		"$(ROOT_DIR)/analysis/fxmark/analyze.py" \
		"$(ROOT_DIR)/docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md" \
		>"$(FXMARK_RESULT_DIR)/inputs.sha256"
	sha256sum "$(FXMARK_BINARY)" "$(FXMARK_CELL)" "$(FXMARK_FUSE)" \
		"$(FXMARK_PASS_POLICY)" "$(FXMARK_SELECT_POLICY)" \
		"$(KERNEL_IMAGE)" "$(STOCK_KERNEL_IMAGE)" \
		"$(KERNEL_BUILD_DIR)/vmlinux" "$(STOCK_KERNEL_BUILD_DIR)/vmlinux" \
		"$(FXMARK_PATCHED_KERNEL_BTF)" "$(FXMARK_STOCK_KERNEL_BTF)" \
		"$(FXMARK_PATCHED_KERNEL_NOTES)" "$(FXMARK_STOCK_KERNEL_NOTES)" \
		"$(KERNEL_BUILD_DIR)/.config" \
		"$(STOCK_KERNEL_BUILD_DIR)/.config" \
		>"$(FXMARK_RESULT_DIR)/artifacts.sha256"
	: >"$(FXMARK_RESULT_DIR)/expected-boots.txt"
	: >"$(FXMARK_RESULT_DIR)/expected-cells.txt"
	base=(stock unattached pass select fuse); \
	for repetition in $$(seq 1 "$(FXMARK_REPETITIONS)"); do \
		offset=$$(((repetition - 1) % 5)); \
		for step in 0 1 2 3 4; do \
			condition="$${base[$$(((offset + step) % 5))]}"; \
			case "$$condition" in \
			stock|fuse) image="$(STOCK_KERNEL_IMAGE)"; config="$(STOCK_KERNEL_BUILD_DIR)/.config"; vmlinux="$(STOCK_KERNEL_BUILD_DIR)/vmlinux"; commit="$(STOCK_KERNEL_COMMIT)"; btf="$(FXMARK_STOCK_KERNEL_BTF)"; notes="$(FXMARK_STOCK_KERNEL_NOTES)"; flavor=stock ;; \
			unattached|pass|select) image="$(KERNEL_IMAGE)"; config="$(KERNEL_BUILD_DIR)/.config"; vmlinux="$(KERNEL_BUILD_DIR)/vmlinux"; commit="$$(cat "$(KERNEL_COMMIT_FILE)")"; btf="$(FXMARK_PATCHED_KERNEL_BTF)"; notes="$(FXMARK_PATCHED_KERNEL_NOTES)"; flavor=patched ;; \
			*) exit 1 ;; \
			esac; \
			btf_sha=$$(sha256sum "$$btf" | awk '{print $$1}'); \
			notes_sha=$$(sha256sum "$$notes" | awk '{print $$1}'); \
			build_id=$$(readelf -n "$$vmlinux" | awk '/Build ID:/ {print $$3; exit}'); \
			test -n "$$build_id"; \
			printf '%s|%s|%s|%s|%s|%s\n' "$$repetition" "$$condition" "$$commit" "$$build_id" "$$notes_sha" "$$btf_sha" >>"$(FXMARK_RESULT_DIR)/expected-boots.txt"; \
			for type in $(FXMARK_TYPES); do for workers in $(FXMARK_CORES); do printf '%s|%s|%s|%s\n' "$$repetition" "$$condition" "$$type" "$$workers" >>"$(FXMARK_RESULT_DIR)/expected-cells.txt"; done; done; \
			boot_dir="$(FXMARK_RESULT_DIR)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
			install -d "$$boot_dir"; \
			$(call NAMEI_EXT_KVM_RUN_CAPTURE,$$image,__fxmark_rq2_guest,CONDITION=$$condition REPETITION=$$repetition FXMARK_RUN_DURATION=$(FXMARK_DURATION) FXMARK_RUN_TYPES='$(FXMARK_TYPES)' FXMARK_RUN_CORES='$(FXMARK_CORES)' FXMARK_BOOT_RESULT_DIR=$$boot_dir FXMARK_BOOT_KERNEL_CONFIG=$$config FXMARK_BOOT_KERNEL_COMMIT=$$commit FXMARK_BOOT_KERNEL_BUILD_ID=$$build_id FXMARK_BOOT_KERNEL_NOTES_SHA256=$$notes_sha FXMARK_BOOT_KERNEL_BTF_SHA256=$$btf_sha FXMARK_BOOT_KERNEL_FLAVOR=$$flavor,$$boot_dir,$(FXMARK_RESULT_DIR)); \
		done; \
	done
	$(MAKE) -C "$(ROOT_DIR)" fxmark-rq2-finalize \
		RUN_ID="$(RUN_ID)" \
		FXMARK_REPETITIONS="$(FXMARK_REPETITIONS)" \
		FXMARK_TYPES="$(FXMARK_TYPES)" \
		FXMARK_CORES="$(FXMARK_CORES)"

fxmark-rq2-finalize:
	jq -e '.status == "running" and (.completed_at | not) and (.failed_at | not)' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	LC_ALL=C sort -o "$(FXMARK_RESULT_DIR)/expected-boots.txt" "$(FXMARK_RESULT_DIR)/expected-boots.txt"
	LC_ALL=C sort -o "$(FXMARK_RESULT_DIR)/expected-cells.txt" "$(FXMARK_RESULT_DIR)/expected-cells.txt"
	find "$(FXMARK_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_RESULT_DIR)/observations.jsonl"
	jq -s -r '.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"' "$(FXMARK_RESULT_DIR)/observations.jsonl" | LC_ALL=C sort >"$(FXMARK_RESULT_DIR)/observed-cells.txt"
	find "$(FXMARK_RESULT_DIR)/boots" -name boot.json -print0 | sort -z | xargs -0 jq -r '"\(.repetition)|\(.condition)|\(.kernel_commit)|\(.kernel_build_id)|\(.kernel_notes_sha256)|\(.kernel_btf_sha256)"' | LC_ALL=C sort >"$(FXMARK_RESULT_DIR)/observed-boots.txt"
	cmp "$(FXMARK_RESULT_DIR)/expected-cells.txt" "$(FXMARK_RESULT_DIR)/observed-cells.txt"
	cmp "$(FXMARK_RESULT_DIR)/expected-boots.txt" "$(FXMARK_RESULT_DIR)/observed-boots.txt"
	expected=$$((5 * $(FXMARK_REPETITIONS) * $$(wc -w <<<"$(FXMARK_TYPES)") * $$(wc -w <<<"$(FXMARK_CORES)"))); \
	test "$$(jq -s 'length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"; \
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"; \
	test "$$(jq -s '[.[] | "\(.repetition)|\(.condition)|\(.type)|\(.workers)"] | unique | length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"
	expected_boots=$$((5 * $(FXMARK_REPETITIONS))); \
	test "$$(find "$(FXMARK_RESULT_DIR)/boots" -name boot.json -type f | wc -l)" = "$$expected_boots"
	for boot in "$(FXMARK_RESULT_DIR)"/boots/*; do \
		for file in launcher.stdout.log launcher.stderr.log; do \
			test -e "$$boot/$$file"; \
		done; \
		for file in boot.json observations.jsonl kernel.config kernel-commit.txt kernel-build-id.txt kernel-notes.sha256 kernel-btf.sha256 kernel-flavor.txt kernel-release.txt uname.txt proc-version.txt kernel-cmdline.txt proc-stat-before.txt proc-stat-after.txt dmesg.log; do \
			test -s "$$boot/$$file"; \
		done; \
		jq -e '.status == "completed"' "$$boot/boot.json" >/dev/null; \
	done
	$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(FXMARK_RESULT_DIR),$(FXMARK_RESULT_DIR)/observations.jsonl)
	jq -e '.layout == "boot-matrix" and (.kernel_commits | keys | sort) == ["patched","stock"]' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	$(call NAMEI_EXT_RUN_COMPLETE,$(FXMARK_RESULT_DIR))

fxmark-rq2-report:
	jq -e '.status == "completed"' "$(FXMARK_RESULT_DIR)/run.json" >/dev/null
	python3 "$(ROOT_DIR)/analysis/fxmark/analyze.py" \
		--input "$(FXMARK_RESULT_DIR)/observations.jsonl" \
		--output "$(FXMARK_RESULT_DIR)/analysis" \
		--repetitions "$(FXMARK_REPETITIONS)" \
		--seed "$(FXMARK_ANALYSIS_SEED)"
	for file in summary.json summary.csv report.md throughput.png throughput.pdf; do \
		test -s "$(FXMARK_RESULT_DIR)/analysis/$$file"; \
	done

experiment-fxmark-rq2: kvm-fxmark-rq2
	$(MAKE) -C "$(ROOT_DIR)" fxmark-rq2-report \
		RUN_ID="$(RUN_ID)" \
		FXMARK_REPETITIONS="$(FXMARK_REPETITIONS)"

__fxmark_rq2_guest:
	test -n "$(CONDITION)"
	test -n "$(REPETITION)"
	test -n "$(FXMARK_RUN_DURATION)"
	test -n "$(FXMARK_RUN_TYPES)"
	test -n "$(FXMARK_RUN_CORES)"
	test -n "$(FXMARK_BOOT_RESULT_DIR)"
	test -n "$(FXMARK_BOOT_KERNEL_CONFIG)"
	test -n "$(FXMARK_BOOT_KERNEL_COMMIT)"
	test -n "$(FXMARK_BOOT_KERNEL_BUILD_ID)"
	test -n "$(FXMARK_BOOT_KERNEL_NOTES_SHA256)"
	test -n "$(FXMARK_BOOT_KERNEL_BTF_SHA256)"
	test -n "$(FXMARK_BOOT_KERNEL_FLAVOR)"
	install -d "$(FXMARK_BOOT_RESULT_DIR)/raw" "$(FXMARK_GUEST_MOUNT)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
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
	uname -r >"$(FXMARK_BOOT_RESULT_DIR)/kernel-release.txt"
	uname -a >"$(FXMARK_BOOT_RESULT_DIR)/uname.txt"
	cat /proc/version >"$(FXMARK_BOOT_RESULT_DIR)/proc-version.txt"
	cat /proc/cmdline >"$(FXMARK_BOOT_RESULT_DIR)/kernel-cmdline.txt"
	cat /proc/stat >"$(FXMARK_BOOT_RESULT_DIR)/proc-stat-before.txt"
	policy="-"; \
	case "$(CONDITION)" in \
	pass) policy="$(FXMARK_PASS_POLICY)" ;; \
	select) policy="$(FXMARK_SELECT_POLICY)" ;; \
	stock|unattached|fuse) ;; \
	*) exit 1 ;; \
	esac; \
	for type in $(FXMARK_RUN_TYPES); do \
		for cores in $(FXMARK_RUN_CORES); do \
			cell="$${type}-$${cores}"; \
			work="$(FXMARK_GUEST_MOUNT)/cell-$${cell}"; \
			raw="$(FXMARK_BOOT_RESULT_DIR)/raw/$${cell}"; \
			"$(FXMARK_CELL)" "$(CONDITION)" "$(FXMARK_BINARY)" \
			"$(FXMARK_FUSE)" "$$policy" \
				"$(FXMARK_BOOT_RESULT_DIR)/observations.jsonl" "$$raw" \
				"$$work" /sys/fs/cgroup "$$type" "$$cores" \
				"$(FXMARK_RUN_DURATION)" "$(FXMARK_CELL_TIMEOUT)" \
				"$(REPETITION)"; \
		done; \
	done
	cat /proc/stat >"$(FXMARK_BOOT_RESULT_DIR)/proc-stat-after.txt"
	dmesg >"$(FXMARK_BOOT_RESULT_DIR)/dmesg.log"
	! grep -E 'BUG:|WARNING:|Oops:|Call Trace:|hung task|general protection|NULL pointer|KASAN|UBSAN' "$(FXMARK_BOOT_RESULT_DIR)/dmesg.log"
	umount "$(FXMARK_GUEST_MOUNT)"
	jq -n \
		--arg condition "$(CONDITION)" \
		--argjson repetition "$(REPETITION)" \
		--arg kernel_commit "$(FXMARK_BOOT_KERNEL_COMMIT)" \
		--arg kernel_build_id "$(FXMARK_BOOT_KERNEL_BUILD_ID)" \
		--arg kernel_notes_sha256 "$(FXMARK_BOOT_KERNEL_NOTES_SHA256)" \
		--arg kernel_btf_sha256 "$(FXMARK_BOOT_KERNEL_BTF_SHA256)" \
		--arg kernel_flavor "$(FXMARK_BOOT_KERNEL_FLAVOR)" \
		--arg kernel_release "$$(cat "$(FXMARK_BOOT_RESULT_DIR)/kernel-release.txt")" \
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,kernel_build_id:$$kernel_build_id,kernel_notes_sha256:$$kernel_notes_sha256,kernel_btf_sha256:$$kernel_btf_sha256,kernel_flavor:$$kernel_flavor,kernel_release:$$kernel_release,status:"completed",completed_at:$$completed_at}' \
		>"$(FXMARK_BOOT_RESULT_DIR)/boot.json"

fxmark-rq2-clean:
	$(MAKE) -C "$(ROOT_DIR)/bench/fxmark" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(FXMARK_OUTPUT)" clean
	rm -rf "$(FXMARK_SOURCE_ROOT)"
