PHASE1_REPORT ?= $(PHASE1_RESULT_DIR)/summary.md
PHASE1_METADATA ?= $(PHASE1_RESULT_DIR)/metadata.json

.PHONY: provenance report

provenance:
	install -d "$(PHASE1_RESULT_DIR)"
	git -C "$(ROOT_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/main-repo-head.txt"
	git -C "$(KERNEL_DIR)" rev-parse HEAD >"$(PHASE1_RESULT_DIR)/kernel-repo-head.txt"
	git -C "$(ROOT_DIR)" status --porcelain --untracked-files=normal -- . ':(exclude).build' ':(exclude).cache' ':(exclude)results' >"$(PHASE1_RESULT_DIR)/main-repo-status.txt"
	git -C "$(KERNEL_DIR)" status --porcelain --untracked-files=normal >"$(PHASE1_RESULT_DIR)/kernel-repo-status.txt"
	sha256sum "$(KERNEL_CONFIG_FRAGMENT)" >"$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256"
	sha256sum "$(KERNEL_BUILD_DIR)/.config" >"$(PHASE1_RESULT_DIR)/kernel-config.sha256"
	sha256sum "$(ROOT_DIR)/configs/benchmarks/phase1.mk" >"$(PHASE1_RESULT_DIR)/benchmark-config.sha256"
	sha256sum "$(ROOT_DIR)/configs/kvm/x86_64.mk" >"$(PHASE1_RESULT_DIR)/kvm-config.sha256"
	sha256sum "$(ROOT_DIR)/Makefile" "$(ROOT_DIR)/Dockerfile" "$(ROOT_DIR)"/mk/*.mk >"$(PHASE1_RESULT_DIR)/project-config.sha256"
	sha256sum "$(KERNEL_IMAGE)" >"$(PHASE1_RESULT_DIR)/kernel-image.sha256"
	sha256sum "$(PHASE1_IMAGE_TAR)" >"$(PHASE1_RESULT_DIR)/docker-image-tar.sha256"
	docker image inspect --format '{{.Id}}' "$(PHASE1_IMAGE)" >"$(PHASE1_RESULT_DIR)/docker-image-id.txt"
	if grep -m1 '^model name' /proc/cpuinfo >"$(PHASE1_RESULT_DIR)/host-cpu.txt"; then :; else printf '%s\n' 'model name	: unavailable' >"$(PHASE1_RESULT_DIR)/host-cpu.txt"; fi
	main_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/main-repo-status.txt" && printf true || printf false); \
	kernel_dirty=$$(test -s "$(PHASE1_RESULT_DIR)/kernel-repo-status.txt" && printf true || printf false); \
	jq -n \
		--arg run_id "$(RUN_ID)" \
		--arg generated_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--arg main_head "$$(cat "$(PHASE1_RESULT_DIR)/main-repo-head.txt")" \
		--arg kernel_head "$$(cat "$(PHASE1_RESULT_DIR)/kernel-repo-head.txt")" \
		--argjson main_dirty "$$main_dirty" \
		--argjson kernel_dirty "$$kernel_dirty" \
		--arg kernel_image_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-image.sha256")" \
		--arg docker_image_id "$$(cat "$(PHASE1_RESULT_DIR)/docker-image-id.txt")" \
		--arg docker_tar_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/docker-image-tar.sha256")" \
		--arg kernel_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config.sha256")" \
		--arg kernel_config_fragment_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256")" \
		--arg benchmark_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/benchmark-config.sha256")" \
		--arg kvm_config_sha256 "$$(awk '{print $$1}' "$(PHASE1_RESULT_DIR)/kvm-config.sha256")" \
		--arg samples "$(SAMPLES)" \
		--arg bench_iters "$(BENCH_ITERS)" \
		--arg kvm_cpus "$(KVM_CPUS)" \
		--arg kvm_mem "$(KVM_MEM)" \
		--arg kvm_append "$(KVM_APPEND)" \
		'{run_id: $$run_id, generated_at: $$generated_at, main_repo: {head: $$main_head, dirty: $$main_dirty, status_file: "main-repo-status.txt"}, kernel_repo: {head: $$kernel_head, dirty: $$kernel_dirty, status_file: "kernel-repo-status.txt"}, artifacts: {kernel_image_sha256: $$kernel_image_sha256, docker_image_id: $$docker_image_id, docker_tar_sha256: $$docker_tar_sha256, kernel_config_sha256: $$kernel_config_sha256, kernel_config_fragment_sha256: $$kernel_config_fragment_sha256, benchmark_config_sha256: $$benchmark_config_sha256, kvm_config_sha256: $$kvm_config_sha256}, config: {samples: $$samples, bench_iters: $$bench_iters, kvm_cpus: $$kvm_cpus, kvm_mem: $$kvm_mem, kvm_append: $$kvm_append}}' \
		>"$(PHASE1_METADATA)"

report: provenance
	install -d "$(PHASE1_RESULT_DIR)"
	test -s "$(PHASE1_RESULT_DIR)/guest-smoke.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/abi.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/functional.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/bench.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/docker.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/kernel-cmdline.txt"
	test -s "$(PHASE1_METADATA)"
	test -s "$(PHASE1_RESULT_DIR)/main-repo-head.txt"
	test -s "$(PHASE1_RESULT_DIR)/kernel-repo-head.txt"
	test -s "$(PHASE1_RESULT_DIR)/kernel-repo-status.txt"
	test -s "$(PHASE1_RESULT_DIR)/kernel-image.sha256"
	test -s "$(PHASE1_RESULT_DIR)/docker-image-tar.sha256"
	test -s "$(PHASE1_RESULT_DIR)/docker-image-id.txt"
	test -s "$(PHASE1_RESULT_DIR)/benchmark-config.sha256"
	test -s "$(PHASE1_RESULT_DIR)/kernel-config.sha256"
	test -s "$(PHASE1_RESULT_DIR)/kernel-config-fragment.sha256"
	test -s "$(PHASE1_RESULT_DIR)/kvm-config.sha256"
	test -s "$(PHASE1_RESULT_DIR)/project-config.sha256"
	test -s "$(PHASE1_RESULT_DIR)/host-cpu.txt"
	printf '%s\n' '# Phase 1 Report' >"$(PHASE1_REPORT)"
	printf '\n%s\n' '- Date: 2026-06-13' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Scope: KVM smoke, functional policy validation, and smoke-scale microbenchmarks' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Kernel image: $(KERNEL_IMAGE)' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Kernel sha256: '"$$(sha256sum "$(KERNEL_IMAGE)" | awk '{print $$1}')" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Main repo HEAD: '"$$(jq -r '.main_repo.head' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Main repo dirty: '"$$(jq -r '.main_repo.dirty' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Kernel repo HEAD: '"$$(jq -r '.kernel_repo.head' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Kernel repo dirty: '"$$(jq -r '.kernel_repo.dirty' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Result directory: $(PHASE1_RESULT_DIR)' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Samples: $(SAMPLES)' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Benchmark iterations: $(BENCH_ITERS)' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Benchmark config sha256: '"$$(jq -r '.artifacts.benchmark_config_sha256' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	if test -f "$(CACHE_ROOT)/images/namei-ext-phase1-runtime.tar"; then printf '%s\n' '- Docker image tar sha256: '"$$(sha256sum "$(CACHE_ROOT)/images/namei-ext-phase1-runtime.tar" | awk '{print $$1}')" >>"$(PHASE1_REPORT)"; fi
	printf '%s\n' '- Docker image ID: '"$$(jq -r '.artifacts.docker_image_id' "$(PHASE1_METADATA)")" >>"$(PHASE1_REPORT)"
	printf '\n%s\n' '## Gates' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Guest smoke events: '"$$(jq -s 'length' "$(PHASE1_RESULT_DIR)/guest-smoke.jsonl")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- ABI failing cases: '"$$(jq -s '[.[] | select(.event == "abi" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/abi.jsonl")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Functional failing cases: '"$$(jq -s '[.[] | select(.event == "case" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/functional.jsonl")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Benchmark failing operations: '"$$(jq -s '[.[] | select(.event == "bench") | .fail] | add // 0' "$(PHASE1_RESULT_DIR)/bench.jsonl")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Docker failing cases: '"$$(jq -s '[.[] | select(.event == "docker-smoke" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/docker.jsonl")" >>"$(PHASE1_REPORT)"
	printf '%s\n' '- Dmesg warning/oops/panic lines: '"$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)"/dmesg-*.log)" >>"$(PHASE1_REPORT)"
	test "$$(jq -s 'length' "$(PHASE1_RESULT_DIR)/guest-smoke.jsonl")" -ge 2
	test "$$(jq -s '[.[] | select(.event == "abi" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/abi.jsonl")" = "0"
	test "$$(jq -s '[.[] | select(.event == "case" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/functional.jsonl")" = "0"
	test "$$(jq -s '[.[] | select(.event == "bench") | .fail] | add // 0' "$(PHASE1_RESULT_DIR)/bench.jsonl")" = "0"
	test "$$(jq -s '[.[] | select(.event == "docker-smoke" and .pass == false)] | length' "$(PHASE1_RESULT_DIR)/docker.jsonl")" = "0"
	test "$$(awk '/] (BUG:|WARNING:|Oops:|Kernel panic|panic:|hung task)|kernel BUG at/ { n++ } END { print n + 0 }' "$(PHASE1_RESULT_DIR)"/dmesg-*.log)" = "0"
	printf '\n%s\n' '## Docker Cases' >>"$(PHASE1_REPORT)"
	printf '%s\n' '| Case | Pass | Detail |' >>"$(PHASE1_REPORT)"
	printf '%s\n' '|---|---:|---|' >>"$(PHASE1_REPORT)"
	jq -r 'select(.event == "docker-smoke") | "| \(.event) | \(.pass) | \(.detail) |"' "$(PHASE1_RESULT_DIR)/docker.jsonl" >>"$(PHASE1_REPORT)"
	printf '\n%s\n' '## ABI Cases' >>"$(PHASE1_REPORT)"
	printf '%s\n' '| Case | Pass | Detail |' >>"$(PHASE1_REPORT)"
	printf '%s\n' '|---|---:|---|' >>"$(PHASE1_REPORT)"
	jq -r 'select(.event == "abi") | "| \(.name) | \(.pass) | \(.detail) |"' "$(PHASE1_RESULT_DIR)/abi.jsonl" >>"$(PHASE1_REPORT)"
	printf '\n%s\n' '## Functional Cases' >>"$(PHASE1_REPORT)"
	printf '%s\n' '| Case | Pass | Errno | Detail |' >>"$(PHASE1_REPORT)"
	printf '%s\n' '|---|---:|---:|---|' >>"$(PHASE1_REPORT)"
	jq -r 'select(.event == "case") | "| \(.name) | \(.pass) | \(.errno) | \(.detail) |"' "$(PHASE1_RESULT_DIR)/functional.jsonl" >>"$(PHASE1_REPORT)"
	printf '\n%s\n' '## Microbenchmarks' >>"$(PHASE1_REPORT)"
	printf '%s\n' '| Benchmark | Variant | Sample | Ops | Elapsed ns | ns/op | Fail |' >>"$(PHASE1_REPORT)"
	printf '%s\n' '|---|---|---:|---:|---:|---:|---:|' >>"$(PHASE1_REPORT)"
	jq -r 'select(.event == "bench") | "| \(.bench) | \(.variant) | \(.sample) | \(.ops) | \(.elapsed_ns) | \((if .ops == 0 then 0 else (.elapsed_ns / .ops) end)) | \(.fail) |"' "$(PHASE1_RESULT_DIR)/bench.jsonl" >>"$(PHASE1_REPORT)"
	printf '\n%s\n' '## Raw Artifacts' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `guest-smoke.jsonl`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `abi.jsonl`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `functional.jsonl`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `bench.jsonl`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `docker.jsonl`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `metadata.json`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `main-repo-head.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `main-repo-status.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-repo-head.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-repo-status.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-image.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `docker-image-tar.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `docker-image-id.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-config.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-config-fragment.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `benchmark-config.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kvm-config.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `project-config.sha256`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `host-cpu.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel.config`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `kernel-cmdline.txt`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `dmesg-smoke.log`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `dmesg-functional.log`' >>"$(PHASE1_REPORT)"
	printf '%s\n' '- `dmesg-bench.log`' >>"$(PHASE1_REPORT)"
