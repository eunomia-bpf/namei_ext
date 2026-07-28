NAMEI_EXT_PINNED_HOST_RESULT_FILES := \
	host-lscpu.txt host-lscpu-extended.txt host-cpu-pin.txt \
	host-cpu-pin.json host-cpu-frequency-policy.txt vng-version.txt \
	vng-executable.sha256 vng-run-module.sha256 \
	host-proc-stat-before.txt host-proc-stat-after.txt \
	host-proc-interrupts-before.txt host-proc-interrupts-after.txt

define NAMEI_EXT_MULTI_BOOT_INIT
install -d "$(1)/boots"
: >"$(1)/expected-boots.txt"
endef

define NAMEI_EXT_MULTI_BOOT_CAPTURE_PINNED_HOST
lscpu >"$(1)/host-lscpu.txt"
lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE,MAXMHZ,MINMHZ \
	>"$(1)/host-lscpu-extended.txt"
cat /proc/stat >"$(1)/host-proc-stat-before.txt"
cat /proc/interrupts >"$(1)/host-proc-interrupts-before.txt"
printf '%s\n' "$(2)" >"$(1)/host-cpu-pin.txt"
pin_start=$$(printf '%s\n' "$(2)" | cut -d- -f1); \
pin_end=$$(printf '%s\n' "$(2)" | cut -d- -f2); \
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
endef

define NAMEI_EXT_MULTI_BOOT_CAPTURE_PINNED_HOST_AFTER
cat /proc/stat >"$(1)/host-proc-stat-after.txt"
cat /proc/interrupts >"$(1)/host-proc-interrupts-after.txt"
endef

define NAMEI_EXT_MULTI_BOOT_SEAL_GUEST_MAKEFILE
test "$$(wc -l <"$(1)")" = "$(2)"; \
! grep -F "$(ROOT_DIR)/" "$(1)" >/dev/null; \
(cd "$$(dirname "$(1)")" && sha256sum "$$(basename "$(1)")" \
	>"$$(basename "$(1)").sha256")
endef

define NAMEI_EXT_MULTI_BOOT_VALIDATE_TREE
test "$$(find "$(1)/boots" -mindepth 1 -maxdepth 1 -type d | wc -l)" = \
	"$(2)"
test "$$(find "$(1)/boots" -mindepth 1 -maxdepth 1 ! -type d | wc -l)" = \
	"0"
test "$$(find "$(1)/boots" -mindepth 3 \
	\( -name boot.json -o -name observations.jsonl \) | wc -l)" = "0"
endef

define NAMEI_EXT_MULTI_BOOT_COLLECT_OBSERVATIONS
$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_TREE,$(1),$(2))
while IFS= read -r -d '' boot; do \
	test -f "$$boot/observations.jsonl"; \
	cat "$$boot/observations.jsonl"; \
done < <(find "$(1)/boots" -mindepth 1 -maxdepth 1 -type d -print0 | \
	LC_ALL=C sort -z) >"$(1)/observations.jsonl"
endef

define NAMEI_EXT_MULTI_BOOT_VALIDATE_BOOT_FILES
$(call NAMEI_EXT_MULTI_BOOT_VALIDATE_TREE,$(1),$(2))
while IFS= read -r -d '' boot; do \
	for file in $(3); do \
		test -f "$$boot/$$file"; \
		test ! -L "$$boot/$$file"; \
	done; \
done < <(find "$(1)/boots" -mindepth 1 -maxdepth 1 -type d -print0 | \
	LC_ALL=C sort -z)
endef

define NAMEI_EXT_MULTI_BOOT_VALIDATE_PINNED_HOST_FILES
for file in $(NAMEI_EXT_PINNED_HOST_RESULT_FILES); do \
	test -s "$(1)/$$file"; \
done
endef
