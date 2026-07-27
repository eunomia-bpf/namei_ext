NAMEI_EXT_RUN_SCHEMA ?= namei_ext.run.v1
NAMEI_EXT_CANONICAL_RESULT_FILES := \
	run.json observations.jsonl command.txt inputs.sha256 artifacts.sha256 \
	stdout.log stderr.log launcher.stdout.log launcher.stderr.log \
	kernel.config uname.txt proc-version.txt kernel-cmdline.txt dmesg.log

define NAMEI_EXT_RESULT_ROOT_CREATE
install -d "$(dir $(1))"
mkdir "$(1)"
endef

define NAMEI_EXT_RUN_START
test ! -e "$(1)/run.json"; test -s "$(KERNEL_COMMIT_FILE)"; kernel_commit=$$(cat "$(KERNEL_COMMIT_FILE)"); case "$$kernel_commit" in (*[!0-9a-f]*|'') exit 1;; esac; test "$${#kernel_commit}" -eq 40; jq -n --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" --arg suite "$(2)" --arg source_system "$(3)" --arg result_level "$(4)" --arg observations "$(notdir $(5))" --arg policy "$(6)" --arg runner "$(7)" --arg kernel_commit "$$kernel_commit" --arg started_at "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{schema:$$schema,run_id:$$run_id,suite:$$suite,source_system:$$source_system,result_level:$$result_level,status:"running",started_at:$$started_at,observations:$$observations,kernel_commit:$$kernel_commit,policy:$$policy,runner:$$runner}' >"$(1)/run.json"
endef

define NAMEI_EXT_RUN_COMPLETE
jq -e '.status == "running" and (.completed_at | not)' "$(1)/run.json" >/dev/null; completed_at=$$(date -u +%Y-%m-%dT%H:%M:%SZ); jq --arg completed_at "$$completed_at" '.status = "completed" | .completed_at = $$completed_at' "$(1)/run.json" >"$(1)/run.json.tmp"; jq -e --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" '.schema == $$schema and .run_id == $$run_id and .status == "completed" and (.completed_at | type == "string" and length > 0)' "$(1)/run.json.tmp" >/dev/null; mv -f "$(1)/run.json.tmp" "$(1)/run.json"
endef

define NAMEI_EXT_RUN_VALIDATE_BASE
jq -e --arg schema "$(NAMEI_EXT_RUN_SCHEMA)" --arg run_id "$(RUN_ID)" --arg observations "$(notdir $(2))" '.schema == $$schema and .run_id == $$run_id and .status == "running" and (.completed_at | not) and .observations == $$observations' "$(1)/run.json" >/dev/null
test -s "$(1)/run.json"
test -s "$(2)"
for file in command.txt inputs.sha256 artifacts.sha256; do test -s "$(1)/$$file"; done
endef

define NAMEI_EXT_RUN_VALIDATE_CANONICAL
$(call NAMEI_EXT_RUN_VALIDATE_BASE,$(1),$(2))
for file in $(NAMEI_EXT_CANONICAL_RESULT_FILES); do test -e "$(1)/$$file"; done
for file in kernel.config uname.txt proc-version.txt kernel-cmdline.txt dmesg.log; do test -s "$(1)/$$file"; done
endef
