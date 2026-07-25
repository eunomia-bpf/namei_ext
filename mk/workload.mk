include $(ROOT_DIR)/configs/benchmarks/workloads.mk
include $(ROOT_DIR)/configs/benchmarks/workload-sources.mk

WORKLOAD_CACHE_ROOT ?= $(CACHE_ROOT)/workloads
WORKLOAD_BUILD_ROOT ?= $(BUILD_ROOT)/workloads
WORKLOAD_PROVENANCE_ROOT ?= $(RESULT_ROOT)/workloads/provenance
WORKLOAD_RUNS_ROOT ?= $(RESULT_ROOT)/workloads/runs
WORKLOAD_RESULT_ROOT ?= $(WORKLOAD_PROVENANCE_ROOT)
WORKLOAD_RUN_ROOT ?= $(WORKLOAD_RUNS_ROOT)/$(RUN_ID)

REDIS_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(REDIS_ARCHIVE_NAME)
REDIS_SRC := $(WORKLOAD_BUILD_ROOT)/$(REDIS_SOURCE_DIR_NAME)
REDIS_STAMP := $(REDIS_SRC)/.source.ok
REDIS_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/redis-source.json

NGINX_ARCHIVE := $(WORKLOAD_CACHE_ROOT)/$(NGINX_ARCHIVE_NAME)
NGINX_SRC := $(WORKLOAD_BUILD_ROOT)/$(NGINX_SOURCE_DIR_NAME)
NGINX_STAMP := $(NGINX_SRC)/.source.ok
NGINX_PROVENANCE := $(WORKLOAD_RESULT_ROOT)/nginx-source.json

REDIS_BUILD_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-redis-build
REDIS_BUILD_SRC := $(REDIS_BUILD_WORK_ROOT)/src
REDIS_BUILD_STAMP := $(REDIS_BUILD_SRC)/.workload-source.ok
REDIS_BUILD_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w1-redis-build
REDIS_BUILD_LOG := $(REDIS_BUILD_RESULT_DIR)/build.log
REDIS_BUILD_JSON := $(REDIS_BUILD_RESULT_DIR)/build.json

NGINX_BUILD_WORK_ROOT := $(WORKLOAD_BUILD_ROOT)/runs/$(RUN_ID)/w1-nginx-build
NGINX_BUILD_SRC := $(NGINX_BUILD_WORK_ROOT)/src
NGINX_BUILD_PREFIX := $(NGINX_BUILD_WORK_ROOT)/install
NGINX_BUILD_STAMP := $(NGINX_BUILD_SRC)/.workload-source.ok
NGINX_BUILD_RESULT_DIR := $(WORKLOAD_RUN_ROOT)/w1-nginx-build
NGINX_CONFIGURE_LOG := $(NGINX_BUILD_RESULT_DIR)/configure.log
NGINX_BUILD_LOG := $(NGINX_BUILD_RESULT_DIR)/build.log
NGINX_BUILD_JSON := $(NGINX_BUILD_RESULT_DIR)/build.json

.PHONY: workload-redis-build workload-nginx-build

workload-redis-build: $(REDIS_BUILD_JSON)

workload-nginx-build: $(NGINX_BUILD_JSON)

$(WORKLOAD_CACHE_ROOT) $(WORKLOAD_BUILD_ROOT) $(WORKLOAD_RESULT_ROOT):
	install -d "$@"

$(WORKLOAD_RUN_ROOT) $(REDIS_BUILD_RESULT_DIR) $(NGINX_BUILD_RESULT_DIR):
	install -d "$@"

$(REDIS_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(REDIS_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(NGINX_ARCHIVE): | $(WORKLOAD_CACHE_ROOT)
	curl -fL --retry 3 --connect-timeout 30 -o "$@.tmp" "$(NGINX_URL)"
	mv -f "$@.tmp" "$@"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$@" | sha256sum -c -

$(REDIS_STAMP): $(REDIS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(REDIS_SRC)"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$(REDIS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(REDIS_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(REDIS_SRC)/Makefile"
	test -f "$(REDIS_SRC)/src/Makefile"
	test -f "$(REDIS_SRC)/$(REDIS_LICENSE_PATH)"
	touch "$@"

$(NGINX_STAMP): $(NGINX_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(NGINX_SRC)"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$(NGINX_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(NGINX_ARCHIVE)" -C "$(WORKLOAD_BUILD_ROOT)"
	test -f "$(NGINX_SRC)/configure"
	test -f "$(NGINX_SRC)/conf/nginx.conf"
	test -f "$(NGINX_SRC)/$(NGINX_LICENSE_PATH)"
	touch "$@"

$(REDIS_BUILD_STAMP): $(REDIS_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(REDIS_BUILD_WORK_ROOT)"
	install -d "$(REDIS_BUILD_SRC)"
	printf '%s  %s\n' "$(REDIS_ARCHIVE_SHA256)" "$(REDIS_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(REDIS_ARCHIVE)" -C "$(REDIS_BUILD_SRC)" --strip-components=1
	test -f "$(REDIS_BUILD_SRC)/Makefile"
	test -f "$(REDIS_BUILD_SRC)/src/Makefile"
	touch "$@"

$(NGINX_BUILD_STAMP): $(NGINX_ARCHIVE) | $(WORKLOAD_BUILD_ROOT)
	rm -rf "$(NGINX_BUILD_WORK_ROOT)"
	install -d "$(NGINX_BUILD_SRC)" "$(NGINX_BUILD_PREFIX)"
	printf '%s  %s\n' "$(NGINX_ARCHIVE_SHA256)" "$(NGINX_ARCHIVE)" | sha256sum -c -
	tar -xzf "$(NGINX_ARCHIVE)" -C "$(NGINX_BUILD_SRC)" --strip-components=1
	test -f "$(NGINX_BUILD_SRC)/configure"
	test -f "$(NGINX_BUILD_SRC)/conf/nginx.conf"
	touch "$@"

$(REDIS_PROVENANCE): $(REDIS_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w1-redis-build,w3-redis-podman-criu,w4-ccache-redis-nginx" \
		--arg project "redis" \
		--arg version "$(REDIS_VERSION)" \
		--arg commit "$(REDIS_COMMIT)" \
		--arg url "$(REDIS_URL)" \
		--arg archive "$(REDIS_ARCHIVE)" \
		--arg expected_archive_sha256 "$(REDIS_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(REDIS_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(REDIS_SRC)" \
		--arg license "$(REDIS_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(REDIS_SRC)/$(REDIS_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg makefile_sha256 "$$(sha256sum "$(REDIS_SRC)/Makefile" | awk '{print $$1}')" \
		--arg src_makefile_sha256 "$$(sha256sum "$(REDIS_SRC)/src/Makefile" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, commit:$$commit, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{makefile_sha256:$$makefile_sha256, src_makefile_sha256:$$src_makefile_sha256}}' \
		>"$@"

$(NGINX_PROVENANCE): $(NGINX_STAMP) | $(WORKLOAD_RESULT_ROOT)
	jq -n \
		--arg workload_ids "w1-nginx-build,w2-nginx-fixture,w3-nginx-podman-criu,w4-ccache-redis-nginx" \
		--arg project "nginx" \
		--arg version "$(NGINX_VERSION)" \
		--arg url "$(NGINX_URL)" \
		--arg archive "$(NGINX_ARCHIVE)" \
		--arg expected_archive_sha256 "$(NGINX_ARCHIVE_SHA256)" \
		--arg archive_sha256 "$$(sha256sum "$(NGINX_ARCHIVE)" | awk '{print $$1}')" \
		--arg source_dir "$(NGINX_SRC)" \
		--arg license "$(NGINX_LICENSE_PATH)" \
		--arg license_sha256 "$$(sha256sum "$(NGINX_SRC)/$(NGINX_LICENSE_PATH)" | awk '{print $$1}')" \
		--arg configure_sha256 "$$(sha256sum "$(NGINX_SRC)/configure" | awk '{print $$1}')" \
		--arg conf_sha256 "$$(sha256sum "$(NGINX_SRC)/conf/nginx.conf" | awk '{print $$1}')" \
		'{schema:"namei_ext.workload_source.v1", project:$$project, workload_ids:($$workload_ids | split(",")), version:$$version, url:$$url, archive:$$archive, expected_archive_sha256:$$expected_archive_sha256, archive_sha256:$$archive_sha256, source_dir:$$source_dir, license:{path:$$license, sha256:$$license_sha256}, evidence:{configure_sha256:$$configure_sha256, sample_config_sha256:$$conf_sha256}}' \
		>"$@"

$(REDIS_BUILD_JSON): $(REDIS_BUILD_STAMP) $(REDIS_PROVENANCE) | $(REDIS_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	start_ns=$$(date +%s%N); \
	GIT_CEILING_DIRECTORIES="$(REDIS_BUILD_SRC)" \
		$(MAKE) -C "$(REDIS_BUILD_SRC)" -j"$(JOBS)" BUILD_TLS=no MALLOC=libc redis-server >"$(REDIS_BUILD_LOG)" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(REDIS_BUILD_SRC)/src/redis-server"; \
	jq -n \
		--arg schema "namei_ext.real_workload_build.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-redis-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "redis" \
		--arg version "$(REDIS_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg git_ceiling_directories "$(REDIS_BUILD_SRC)" \
		--arg cc_version "$$(cc --version | sed -n '1p')" \
		--arg source_dir "$(REDIS_BUILD_SRC)" \
		--arg log "$(REDIS_BUILD_LOG)" \
		--arg binary "$(REDIS_BUILD_SRC)/src/redis-server" \
		--arg binary_sha256 "$$(sha256sum "$(REDIS_BUILD_SRC)/src/redis-server" | awk '{print $$1}')" \
		--arg stdout_sha256 "$$(sha256sum "$(REDIS_BUILD_LOG)" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["make","redis-server"], make_variables:{BUILD_TLS:"no", MALLOC:"libc", JOBS:$$jobs}, environment:{GIT_CEILING_DIRECTORIES:$$git_ceiling_directories}, toolchain:{cc_version:$$cc_version}, duration_ns:$$duration_ns, artifacts:{log:$$log, log_sha256:$$stdout_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"

$(NGINX_BUILD_JSON): $(NGINX_BUILD_STAMP) $(NGINX_PROVENANCE) | $(NGINX_BUILD_RESULT_DIR)
	command -v cc >/dev/null
	start_ns=$$(date +%s%N); \
	cd "$(NGINX_BUILD_SRC)" && ./configure --prefix="$(NGINX_BUILD_PREFIX)" --with-cc=cc --without-http_rewrite_module --without-http_gzip_module >"$(NGINX_CONFIGURE_LOG)" 2>&1; \
	$(MAKE) -C "$(NGINX_BUILD_SRC)" -j"$(JOBS)" >"$(NGINX_BUILD_LOG)" 2>&1; \
	end_ns=$$(date +%s%N); \
	test -x "$(NGINX_BUILD_SRC)/objs/nginx"; \
	jq -n \
		--arg schema "namei_ext.real_workload_build.v1" \
		--arg run_id "$(RUN_ID)" \
		--arg workload_id "w1-nginx-build" \
		--arg policy_family "build_graph_view.bpf.c" \
		--arg project "nginx" \
		--arg version "$(NGINX_VERSION)" \
		--arg jobs "$(JOBS)" \
		--arg cc_version "$$(cc --version | sed -n '1p')" \
		--arg source_dir "$(NGINX_BUILD_SRC)" \
		--arg configure_log "$(NGINX_CONFIGURE_LOG)" \
		--arg configure_log_sha256 "$$(sha256sum "$(NGINX_CONFIGURE_LOG)" | awk '{print $$1}')" \
		--arg build_log "$(NGINX_BUILD_LOG)" \
		--arg build_log_sha256 "$$(sha256sum "$(NGINX_BUILD_LOG)" | awk '{print $$1}')" \
		--arg binary "$(NGINX_BUILD_SRC)/objs/nginx" \
		--arg binary_sha256 "$$(sha256sum "$(NGINX_BUILD_SRC)/objs/nginx" | awk '{print $$1}')" \
		--argjson duration_ns "$$((end_ns - start_ns))" \
		'{schema:$$schema, run_id:$$run_id, workload_id:$$workload_id, policy_family:$$policy_family, result_level:"host_source_build_trace", run_environment:"host", policy_executed:false, kvm_validated:false, output_hash_oracle:false, project:$$project, version:$$version, source_dir:$$source_dir, command:["./configure","make"], configure_flags:["--without-http_rewrite_module","--without-http_gzip_module"], make_variables:{JOBS:$$jobs}, toolchain:{cc_version:$$cc_version}, duration_ns:$$duration_ns, artifacts:{configure_log:$$configure_log, configure_log_sha256:$$configure_log_sha256, build_log:$$build_log, build_log_sha256:$$build_log_sha256, binary:$$binary, binary_sha256:$$binary_sha256}}' \
		>"$@"
