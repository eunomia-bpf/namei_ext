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
FXMARK_CELL_TIMEOUT ?= 900
FXMARK_ANALYSIS_SEED ?= 20260726
FXMARK_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-rq2/$(RUN_ID)
FXMARK_PREFLIGHT_RESULT_DIR ?= $(RESULT_ROOT)/experiments/fxmark-rq2-preflight/$(RUN_ID)
FXMARK_GUEST_MOUNT ?= /tmp/namei-ext-fxmark-rq2

.PHONY: fxmark-source fxmark-rq2-build fxmark-kernel-pair \
	kvm-fxmark-rq2-preflight kvm-fxmark-rq2 \
	fxmark-rq2-report experiment-fxmark-rq2 \
	__fxmark_rq2_guest fxmark-rq2-clean

fxmark-source: $(FXMARK_SOURCE_STAMP)

fxmark-rq2-build: $(FXMARK_SOURCE_STAMP) runner
	$(MAKE) -C "$(ROOT_DIR)/bench/fxmark" \
		ROOT_DIR="$(ROOT_DIR)" \
		BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(FXMARK_OUTPUT)" \
		FXMARK_SOURCE_ROOT="$(FXMARK_SOURCE_ROOT)" all

fxmark-kernel-pair: kernel kernel-stock kernel-provenance kernel-stock-provenance
	git -C "$(KERNEL_DIR)" merge-base --is-ancestor "$(STOCK_KERNEL_COMMIT)" "$$(cat "$(KERNEL_COMMIT_FILE)")"
	test "$$(cat "$(STOCK_KERNEL_COMMIT_FILE)")" = "$(STOCK_KERNEL_COMMIT)"
	grep '^CONFIG_NAMEI_EXT=y' "$(KERNEL_BUILD_DIR)/.config"
	! grep '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config"
	diff -u \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(KERNEL_BUILD_DIR)/.config") \
		<(grep -v '^CONFIG_NAMEI_EXT=' "$(STOCK_KERNEL_BUILD_DIR)/.config")

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
	install -d "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots"
	printf '%s\n' \
		'make kvm-fxmark-rq2-preflight RUN_ID=$(RUN_ID)' \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/command.txt"
	sha256sum "$(FXMARK_BINARY)" "$(FXMARK_CELL)" "$(FXMARK_FUSE)" \
		"$(FXMARK_PASS_POLICY)" \
		"$(FXMARK_SELECT_POLICY)" \
		>"$(FXMARK_PREFLIGHT_RESULT_DIR)/artifacts.sha256"
	conditions=(stock unattached pass select fuse); \
	for condition in "$${conditions[@]}"; do \
		case "$$condition" in \
		stock|fuse) image="$(STOCK_KERNEL_IMAGE)"; config="$(STOCK_KERNEL_BUILD_DIR)/.config"; commit="$(STOCK_KERNEL_COMMIT)" ;; \
		unattached|pass|select) image="$(KERNEL_IMAGE)"; config="$(KERNEL_BUILD_DIR)/.config"; commit="$$(cat "$(KERNEL_COMMIT_FILE)")" ;; \
		*) exit 1 ;; \
		esac; \
		boot_dir="$(FXMARK_PREFLIGHT_RESULT_DIR)/boots/block-01-$$condition"; \
		install -d "$$boot_dir"; \
		"$(VNG)" --run "$$image" $(VNG_MODULE_FLAGS) --user root \
			--cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" \
			--memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp \
			--append "$(KVM_APPEND)" \
			--exec "$(MAKE) -C $(ROOT_DIR) __fxmark_rq2_guest RUN_ID=$(RUN_ID) CONDITION=$$condition REPETITION=1 FXMARK_RUN_DURATION=$(FXMARK_PREFLIGHT_DURATION) FXMARK_RUN_TYPES=MRPL FXMARK_RUN_CORES=1 FXMARK_BOOT_RESULT_DIR=$$boot_dir FXMARK_BOOT_KERNEL_CONFIG=$$config FXMARK_BOOT_KERNEL_COMMIT=$$commit"; \
	done
	find "$(FXMARK_PREFLIGHT_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl"
	test "$$(jq -s 'length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "5"
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_PREFLIGHT_RESULT_DIR)/observations.jsonl")" = "5"

kvm-fxmark-rq2: fxmark-kernel-pair fxmark-rq2-build bpf
	install -d "$(FXMARK_RESULT_DIR)/boots"
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg started_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--argjson repetitions "$(FXMARK_REPETITIONS)" \
		--arg types "$(FXMARK_TYPES)" \
		--arg cores "$(FXMARK_CORES)" \
		'{run_id:$$run_id,status:"running",started_at:$$started_at,repetitions:$$repetitions,types:($$types|split(" ")),workers:($$cores|split(" ")|map(tonumber))}' \
		>"$(FXMARK_RESULT_DIR)/run.json"
	printf '%s\n' 'make kvm-fxmark-rq2 RUN_ID=$(RUN_ID)' \
		>"$(FXMARK_RESULT_DIR)/command.txt"
	lscpu >"$(FXMARK_RESULT_DIR)/host-lscpu.txt"
	find /sys/devices/system/cpu -path '*/cpufreq/scaling_governor' \
		-type f -print -exec sed -n '1p' {} \; \
		>"$(FXMARK_RESULT_DIR)/host-governors.txt"
	sha256sum "$(FXMARK_BINARY)" "$(FXMARK_CELL)" "$(FXMARK_FUSE)" \
		"$(FXMARK_PASS_POLICY)" \
		"$(FXMARK_SELECT_POLICY)" "$(KERNEL_IMAGE)" \
		"$(STOCK_KERNEL_IMAGE)" \
		"$(ROOT_DIR)/bench/fxmark/fxmark-correctness.patch" \
		"$(ROOT_DIR)/docs/tmp/2026-07-26-rq2-fxmark-experiment-plan.md" \
		>"$(FXMARK_RESULT_DIR)/artifacts.sha256"
	base=(stock unattached pass select fuse); \
	for repetition in $$(seq 1 "$(FXMARK_REPETITIONS)"); do \
		offset=$$(((repetition - 1) % 5)); \
		for step in 0 1 2 3 4; do \
			condition="$${base[$$(((offset + step) % 5))]}"; \
			case "$$condition" in \
			stock|fuse) image="$(STOCK_KERNEL_IMAGE)"; config="$(STOCK_KERNEL_BUILD_DIR)/.config"; commit="$(STOCK_KERNEL_COMMIT)" ;; \
			unattached|pass|select) image="$(KERNEL_IMAGE)"; config="$(KERNEL_BUILD_DIR)/.config"; commit="$$(cat "$(KERNEL_COMMIT_FILE)")" ;; \
			*) exit 1 ;; \
			esac; \
			boot_dir="$(FXMARK_RESULT_DIR)/boots/block-$$(printf '%02d' "$$repetition")-$$condition"; \
			install -d "$$boot_dir"; \
			"$(VNG)" --run "$$image" $(VNG_MODULE_FLAGS) --user root \
				--cwd "$(ROOT_DIR)" --disable-monitor --cpus "$(KVM_CPUS)" \
				--memory "$(KVM_MEM)" --rwdir "$(ROOT_DIR)" --overlay-rwdir /tmp \
				--append "$(KVM_APPEND)" \
				--exec "$(MAKE) -C $(ROOT_DIR) __fxmark_rq2_guest RUN_ID=$(RUN_ID) CONDITION=$$condition REPETITION=$$repetition FXMARK_RUN_DURATION=$(FXMARK_DURATION) FXMARK_RUN_TYPES='$(FXMARK_TYPES)' FXMARK_RUN_CORES='$(FXMARK_CORES)' FXMARK_BOOT_RESULT_DIR=$$boot_dir FXMARK_BOOT_KERNEL_CONFIG=$$config FXMARK_BOOT_KERNEL_COMMIT=$$commit"; \
		done; \
	done
	find "$(FXMARK_RESULT_DIR)/boots" -name observations.jsonl -print0 \
		| sort -z | xargs -0 cat >"$(FXMARK_RESULT_DIR)/observations.jsonl"
	expected=$$((5 * $(FXMARK_REPETITIONS) * $$(wc -w <<<"$(FXMARK_TYPES)") * $$(wc -w <<<"$(FXMARK_CORES)"))); \
	test "$$(jq -s 'length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"
	test "$$(jq -s '[.[] | select(.pass == true)] | length' "$(FXMARK_RESULT_DIR)/observations.jsonl")" = "$$expected"
	completed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
	jq --arg completed_at "$$completed_at" \
		'.status="completed" | .completed_at=$$completed_at' \
		"$(FXMARK_RESULT_DIR)/run.json" >"$(FXMARK_RESULT_DIR)/run.json.tmp"; \
	mv -f "$(FXMARK_RESULT_DIR)/run.json.tmp" "$(FXMARK_RESULT_DIR)/run.json"

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
	install -d "$(FXMARK_BOOT_RESULT_DIR)/raw" "$(FXMARK_GUEST_MOUNT)"
	if ! mountpoint -q /sys/fs/bpf; then mount -t bpf bpf /sys/fs/bpf; fi
	if ! mountpoint -q /sys/kernel/debug; then mount -t debugfs debugfs /sys/kernel/debug; fi
	if ! mountpoint -q /sys/fs/cgroup; then mount -t cgroup2 cgroup2 /sys/fs/cgroup; fi
	mount -t tmpfs -o "size=$(FXMARK_TMPFS_SIZE),noatime" tmpfs "$(FXMARK_GUEST_MOUNT)"
	: >"$(FXMARK_BOOT_RESULT_DIR)/observations.jsonl"
	cp "$(FXMARK_BOOT_KERNEL_CONFIG)" "$(FXMARK_BOOT_RESULT_DIR)/kernel.config"
	printf '%s\n' "$(FXMARK_BOOT_KERNEL_COMMIT)" >"$(FXMARK_BOOT_RESULT_DIR)/kernel-commit.txt"
	uname -a >"$(FXMARK_BOOT_RESULT_DIR)/uname.txt"
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
		--arg completed_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{condition:$$condition,repetition:$$repetition,kernel_commit:$$kernel_commit,status:"completed",completed_at:$$completed_at}' \
		>"$(FXMARK_BOOT_RESULT_DIR)/boot.json"

fxmark-rq2-clean:
	$(MAKE) -C "$(ROOT_DIR)/bench/fxmark" \
		ROOT_DIR="$(ROOT_DIR)" BUILD_ROOT="$(BUILD_ROOT)" \
		OUTPUT="$(FXMARK_OUTPUT)" clean
	rm -rf "$(FXMARK_SOURCE_ROOT)"
