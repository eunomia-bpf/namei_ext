NAMEI_EXT_RUN_SCHEMA ?= namei_ext.run.v2
NAMEI_EXT_SOURCE_DIR ?= $(ROOT_DIR)
NAMEI_EXT_KERNEL_SOURCE_DIR ?= $(ROOT_DIR)/kernel
NAMEI_EXT_REQUIRE_CLEAN ?= 0
NAMEI_EXT_SOURCE_RESULT_FILES := \
	source-commit.txt source-status.txt kernel-commit.txt kernel-status.txt
NAMEI_EXT_CANONICAL_RESULT_FILES := \
	run.json observations.jsonl command.txt inputs.sha256 artifacts.sha256 \
	stdout.log stderr.log launcher.stdout.log launcher.stderr.log \
	kernel.config uname.txt proc-version.txt kernel-cmdline.txt dmesg.log \
	$(NAMEI_EXT_SOURCE_RESULT_FILES)

.PHONY: experiment-source-clean

experiment-source-clean:
	source_status=$$(git -C "$(NAMEI_EXT_SOURCE_DIR)" status --porcelain=v1 --untracked-files=all); \
	if test -n "$$source_status"; then \
		printf '%s\n%s\n' 'experiment requires a clean source tree:' "$$source_status" >&2; \
		exit 1; \
	fi
	kernel_status=$$(git -C "$(NAMEI_EXT_KERNEL_SOURCE_DIR)" status --porcelain=v1 --untracked-files=all); \
	if test -n "$$kernel_status"; then \
		printf '%s\n%s\n' 'experiment requires a clean kernel tree:' "$$kernel_status" >&2; \
		exit 1; \
	fi

define NAMEI_EXT_RESULT_ROOT_CREATE
install -d "$(dir $(1))"
mkdir "$(1)"
endef

define NAMEI_EXT_RUN_START
test ! -e "$(1)/run.json"; \
case "$(NAMEI_EXT_REQUIRE_CLEAN)" in (0|1) ;; (*) exit 1;; esac; \
source_commit=$$(git -C "$(NAMEI_EXT_SOURCE_DIR)" rev-parse HEAD); \
kernel_commit=$$(git -C "$(NAMEI_EXT_KERNEL_SOURCE_DIR)" rev-parse HEAD); \
case "$$source_commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
case "$$kernel_commit" in (*[!0-9a-f]*|'') exit 1;; esac; \
test "$${#source_commit}" -eq 40; \
test "$${#kernel_commit}" -eq 40; \
printf '%s\n' "$$source_commit" >"$(1)/source-commit.txt"; \
printf '%s\n' "$$kernel_commit" >"$(1)/kernel-commit.txt"; \
git -C "$(NAMEI_EXT_SOURCE_DIR)" status --porcelain=v1 --untracked-files=all >"$(1)/source-status.txt"; \
git -C "$(NAMEI_EXT_KERNEL_SOURCE_DIR)" status --porcelain=v1 --untracked-files=all >"$(1)/kernel-status.txt"; \
source_dirty=false; \
kernel_dirty=false; \
if test -s "$(1)/source-status.txt"; then source_dirty=true; fi; \
if test -s "$(1)/kernel-status.txt"; then kernel_dirty=true; fi; \
if test "$(NAMEI_EXT_REQUIRE_CLEAN)" -eq 1; then \
	test "$$source_dirty" = false; \
	test "$$kernel_dirty" = false; \
fi; \
jq -n --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" --arg suite "$(2)" --arg source_system "$(3)" --arg result_level "$(4)" --arg observations "$(notdir $(5))" --arg policy "$(6)" --arg runner "$(7)" --arg source_commit "$$source_commit" --arg kernel_commit "$$kernel_commit" --argjson source_dirty "$$source_dirty" --argjson kernel_dirty "$$kernel_dirty" --arg started_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{schema:$$schema,run_id:$$run_id,suite:$$suite,source_system:$$source_system,result_level:$$result_level,status:"running",started_at:$$started_at,observations:$$observations,source:{commit:$$source_commit,dirty:$$source_dirty},kernel:{commit:$$kernel_commit,dirty:$$kernel_dirty},kernel_commit:$$kernel_commit,policy:$$policy,runner:$$runner}' >"$(1)/run.json"
endef

define NAMEI_EXT_RUN_COMPLETE
jq -e '.status == "running" and (.completed_at | not)' "$(1)/run.json" >/dev/null; completed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); jq --arg completed_at "$$completed_at" '.status = "completed" | .completed_at = $$completed_at' "$(1)/run.json" >"$(1)/run.json.tmp"; jq -e --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" '.schema == $$schema and .run_id == $$run_id and .status == "completed" and (.completed_at | type == "string" and length > 0)' "$(1)/run.json.tmp" >/dev/null; mv -f "$(1)/run.json.tmp" "$(1)/run.json"
endef

define NAMEI_EXT_RUN_VALIDATE_COMPLETE
jq -e --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" '.schema == $$schema and .status == "completed" and (.completed_at | type == "string" and length > 0) and (.run_id | type == "string" and length > 0) and (.observations | type == "string" and length > 0) and (.source.commit | type == "string" and length == 40) and (.source.dirty | type == "boolean") and (.kernel.commit | type == "string" and length == 40) and (.kernel.dirty | type == "boolean") and .kernel_commit == .kernel.commit' "$(1)/run.json" >/dev/null
endef

define NAMEI_EXT_ANALYSIS_PREPARE
if test ! -e "$(1)" && test -e "$(1).old"; then \
	mv "$(1).old" "$(1)"; \
fi; \
if test -e "$(1)" && test -e "$(1).old"; then \
	rm -rf "$(1).old"; \
fi; \
rm -rf "$(1).tmp"
endef

define NAMEI_EXT_ANALYSIS_PUBLISH
if test -e "$(1)"; then mv "$(1)" "$(1).old"; fi; \
if ! mv "$(1).tmp" "$(1)"; then \
	if test -e "$(1).old"; then mv "$(1).old" "$(1)"; fi; \
	exit 1; \
fi; \
rm -rf "$(1).old"
endef

define NAMEI_EXT_RUN_VALIDATE_BASE
jq -e --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" --arg observations "$(notdir $(2))" '.schema == $$schema and .run_id == $$run_id and .status == "running" and (.completed_at | not) and .observations == $$observations and (.source.commit | type == "string" and length == 40) and (.source.dirty | type == "boolean") and (.kernel.commit | type == "string" and length == 40) and (.kernel.dirty | type == "boolean") and .kernel_commit == .kernel.commit' "$(1)/run.json" >/dev/null
test -s "$(1)/run.json"
test -s "$(2)"
for file in command.txt inputs.sha256 artifacts.sha256 source-commit.txt kernel-commit.txt; do test -s "$(1)/$$file"; done
for file in source-status.txt kernel-status.txt; do test -e "$(1)/$$file"; done
test "$$(cat "$(1)/source-commit.txt")" = "$$(jq -r '.source.commit' "$(1)/run.json")"
test "$$(cat "$(1)/kernel-commit.txt")" = "$$(jq -r '.kernel.commit' "$(1)/run.json")"
test "$$(test -s "$(1)/source-status.txt" && printf true || printf false)" = "$$(jq -r '.source.dirty' "$(1)/run.json")"
test "$$(test -s "$(1)/kernel-status.txt" && printf true || printf false)" = "$$(jq -r '.kernel.dirty' "$(1)/run.json")"
endef

define NAMEI_EXT_RUN_VALIDATE_CANONICAL
$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(1),$(2))
for file in $(NAMEI_EXT_CANONICAL_RESULT_FILES); do test -e "$(1)/$$file"; done
for file in kernel.config uname.txt proc-version.txt kernel-cmdline.txt dmesg.log; do test -s "$(1)/$$file"; done
endef
