PHASE1_IMAGE ?= namei-ext/phase1:dev
PHASE1_IMAGE_TAR ?= $(CACHE_ROOT)/images/namei-ext-phase1-runtime.tar
DOCKER_CONTEXT_FILES := Dockerfile Makefile README.md AGENTS.md $(shell find configs mk bpf bench tests -type f 2>/dev/null)

.PHONY: docker docker-smoke docker-clean

docker: $(PHASE1_IMAGE_TAR)

docker-smoke: $(PHASE1_IMAGE_TAR)
	install -d "$(PHASE1_RESULT_DIR)"
	printf '{"event":"docker-smoke-start","image":"%s"}\n' "$(PHASE1_IMAGE)" >"$(PHASE1_RESULT_DIR)/docker.jsonl"
	docker run --rm "$(PHASE1_IMAGE)" make -C /opt/namei_ext bpf
	printf '{"event":"docker-smoke","pass":true,"image":"%s","tar_sha256":"%s","detail":"runtime image Makefile BPF target passed without host workspace bind mount"}\n' "$(PHASE1_IMAGE)" "$$(sha256sum "$(PHASE1_IMAGE_TAR)" | awk '{print $$1}')" >>"$(PHASE1_RESULT_DIR)/docker.jsonl"

$(PHASE1_IMAGE_TAR): $(DOCKER_CONTEXT_FILES)
	install -d "$(dir $@)"
	docker build -t "$(PHASE1_IMAGE)" -f "$(ROOT_DIR)/Dockerfile" "$(ROOT_DIR)"
	docker save -o "$@.tmp" "$(PHASE1_IMAGE)"
	mv -f "$@.tmp" "$@"

docker-clean:
	rm -f "$(PHASE1_IMAGE_TAR)" "$(PHASE1_IMAGE_TAR).tmp"
