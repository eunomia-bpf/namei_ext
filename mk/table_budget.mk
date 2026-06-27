TABLE_BUDGET_JSON ?= $(PHASE1_RESULT_DIR)/table-budget.jsonl
TABLE_BUDGET_INPUTS_SHA256 ?= $(PHASE1_RESULT_DIR)/table-budget-inputs.sha256

.PHONY: table-budget

table-budget:
	install -d "$(PHASE1_RESULT_DIR)"
	test -s "$(PHASE1_RESULT_DIR)/w1-oracle.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/w2-oracle.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/w3-oracle.jsonl"
	test -s "$(PHASE1_RESULT_DIR)/w4-oracle.jsonl"
	test -s "$(W1_ORACLE_ENTRIES_TSV)"
	test -s "$(W2_ORACLE_ENTRIES_TSV)"
	test -s "$(W3_ORACLE_ENTRIES_TSV)"
	test -s "$(W4_ORACLE_ENTRIES_TSV)"
	sha256sum "$(PHASE1_RESULT_DIR)/w1-oracle.jsonl" "$(PHASE1_RESULT_DIR)/w2-oracle.jsonl" "$(PHASE1_RESULT_DIR)/w3-oracle.jsonl" "$(PHASE1_RESULT_DIR)/w4-oracle.jsonl" "$(W1_ORACLE_ENTRIES_TSV)" "$(W2_ORACLE_ENTRIES_TSV)" "$(W3_ORACLE_ENTRIES_TSV)" "$(W4_ORACLE_ENTRIES_TSV)" "$(ROOT_DIR)/configs/eval-osdi/policy-budgets.mk" "$(ROOT_DIR)/mk/table_budget.mk" >"$(TABLE_BUDGET_INPUTS_SHA256)"
	w1_entries=$$(wc -l <"$(W1_ORACLE_ENTRIES_TSV)"); \
	w2_entries=$$(wc -l <"$(W2_ORACLE_ENTRIES_TSV)"); \
	w3_entries=$$(wc -l <"$(W3_ORACLE_ENTRIES_TSV)"); \
	w4_entries=$$(wc -l <"$(W4_ORACLE_ENTRIES_TSV)"); \
	w1_table_pass=$$(jq -s '[.[] | select(.event == "w1-oracle-summary" and .policy == "table_redirect" and .pass == true and .failures == 0)] | length == 1' "$(PHASE1_RESULT_DIR)/w1-oracle.jsonl"); \
	w2_table_pass=$$(jq -s '[.[] | select(.event == "w2-oracle-summary" and .policy == "table_redirect" and .pass == true and .failures == 0)] | length == 1' "$(PHASE1_RESULT_DIR)/w2-oracle.jsonl"); \
	w3_table_pass=$$(jq -s '[.[] | select(.event == "w3-oracle-summary" and .policy == "table_redirect" and .pass == true and .failures == 0)] | length == 1' "$(PHASE1_RESULT_DIR)/w3-oracle.jsonl"); \
	w4_table_pass=$$(jq -s '[.[] | select(.event == "w4-oracle-summary" and .policy == "table_redirect" and .pass == true and .failures == 0)] | length == 1' "$(PHASE1_RESULT_DIR)/w4-oracle.jsonl"); \
	: >"$(TABLE_BUDGET_JSON)"; \
	jq -cn \
		--arg family "build_graph" \
		--arg policy "build_graph_view.bpf.c" \
		--arg oracle "w1-oracle.jsonl" \
		--arg basis "phase1_path_oracle_table_baseline" \
		--argjson entries "$$w1_entries" \
		--argjson table_pass "$$w1_table_pass" \
		--argjson max_entries "$(OSDI_MAX_POLICY_MAP_ENTRIES)" \
		--argjson max_memory_bytes "$(OSDI_MAX_POLICY_MAP_MEMORY_BYTES)" \
		--argjson max_ratio "$(OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO)" \
		--argjson update_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" \
		--argjson max_stale_ms "$(OSDI_TABLE_MAX_STALE_WINDOW_MS)" \
		--argjson max_update_ms "$(OSDI_TABLE_MAX_UPDATE_LATENCY_MS)" \
		'{event:"table-budget", result_level:"table_budget_accounting", family:$$family, programmable_policy:$$policy, table_policy:"table_redirect.bpf.c", oracle_jsonl:$$oracle, budget_basis:$$basis, pass:$$table_pass, table_baseline_current_oracle_pass:$$table_pass, entries:$$entries, table_entries_required:$$entries, programmable_entries_observed:$$entries, over_materialization_ratio:1, max_over_materialization_ratio:$$max_ratio, update_writes_accounted:$$entries, update_writes_basis:"entry_count_from_phase1_table_load", max_update_writes:($$entries * $$update_ratio), max_entries:$$max_entries, max_memory_bytes:$$max_memory_bytes, max_stale_window_ms:$$max_stale_ms, max_update_latency_ms:$$max_update_ms, qualified_for_c8:false, detail:"table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied"}' \
		>>"$(TABLE_BUDGET_JSON)"; \
	jq -cn \
		--arg family "sandbox_fixture" \
		--arg policy "sandbox_fixture_view.bpf.c" \
		--arg oracle "w2-oracle.jsonl" \
		--arg basis "phase1_path_oracle_table_baseline" \
		--argjson entries "$$w2_entries" \
		--argjson table_pass "$$w2_table_pass" \
		--argjson max_entries "$(OSDI_MAX_POLICY_MAP_ENTRIES)" \
		--argjson max_memory_bytes "$(OSDI_MAX_POLICY_MAP_MEMORY_BYTES)" \
		--argjson max_ratio "$(OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO)" \
		--argjson update_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" \
		--argjson max_stale_ms "$(OSDI_TABLE_MAX_STALE_WINDOW_MS)" \
		--argjson max_update_ms "$(OSDI_TABLE_MAX_UPDATE_LATENCY_MS)" \
		'{event:"table-budget", result_level:"table_budget_accounting", family:$$family, programmable_policy:$$policy, table_policy:"table_redirect.bpf.c", oracle_jsonl:$$oracle, budget_basis:$$basis, pass:$$table_pass, table_baseline_current_oracle_pass:$$table_pass, entries:$$entries, table_entries_required:$$entries, programmable_entries_observed:$$entries, over_materialization_ratio:1, max_over_materialization_ratio:$$max_ratio, update_writes_accounted:$$entries, update_writes_basis:"entry_count_from_phase1_table_load", max_update_writes:($$entries * $$update_ratio), max_entries:$$max_entries, max_memory_bytes:$$max_memory_bytes, max_stale_window_ms:$$max_stale_ms, max_update_latency_ms:$$max_update_ms, qualified_for_c8:false, detail:"table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied"}' \
		>>"$(TABLE_BUDGET_JSON)"; \
	jq -cn \
		--arg family "checkpoint_restore" \
		--arg policy "checkpoint_restore_view.bpf.c" \
		--arg oracle "w3-oracle.jsonl" \
		--arg basis "phase1_path_oracle_table_baseline" \
		--argjson entries "$$w3_entries" \
		--argjson table_pass "$$w3_table_pass" \
		--argjson max_entries "$(OSDI_MAX_POLICY_MAP_ENTRIES)" \
		--argjson max_memory_bytes "$(OSDI_MAX_POLICY_MAP_MEMORY_BYTES)" \
		--argjson max_ratio "$(OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO)" \
		--argjson update_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" \
		--argjson max_stale_ms "$(OSDI_TABLE_MAX_STALE_WINDOW_MS)" \
		--argjson max_update_ms "$(OSDI_TABLE_MAX_UPDATE_LATENCY_MS)" \
		'{event:"table-budget", result_level:"table_budget_accounting", family:$$family, programmable_policy:$$policy, table_policy:"table_redirect.bpf.c", oracle_jsonl:$$oracle, budget_basis:$$basis, pass:$$table_pass, table_baseline_current_oracle_pass:$$table_pass, entries:$$entries, table_entries_required:$$entries, programmable_entries_observed:$$entries, over_materialization_ratio:1, max_over_materialization_ratio:$$max_ratio, update_writes_accounted:$$entries, update_writes_basis:"entry_count_from_phase1_table_load", max_update_writes:($$entries * $$update_ratio), max_entries:$$max_entries, max_memory_bytes:$$max_memory_bytes, max_stale_window_ms:$$max_stale_ms, max_update_latency_ms:$$max_update_ms, qualified_for_c8:false, detail:"table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied"}' \
		>>"$(TABLE_BUDGET_JSON)"; \
	jq -cn \
		--arg family "cache_locality" \
		--arg policy "cache_locality_view.bpf.c" \
		--arg oracle "w4-oracle.jsonl" \
		--arg basis "phase1_path_oracle_table_baseline" \
		--argjson entries "$$w4_entries" \
		--argjson table_pass "$$w4_table_pass" \
		--argjson max_entries "$(OSDI_MAX_POLICY_MAP_ENTRIES)" \
		--argjson max_memory_bytes "$(OSDI_MAX_POLICY_MAP_MEMORY_BYTES)" \
		--argjson max_ratio "$(OSDI_TABLE_MAX_OVER_MATERIALIZATION_RATIO)" \
		--argjson update_ratio "$(OSDI_TABLE_MAX_UPDATE_WRITES_RATIO)" \
		--argjson max_stale_ms "$(OSDI_TABLE_MAX_STALE_WINDOW_MS)" \
		--argjson max_update_ms "$(OSDI_TABLE_MAX_UPDATE_LATENCY_MS)" \
		'{event:"table-budget", result_level:"table_budget_accounting", family:$$family, programmable_policy:$$policy, table_policy:"table_redirect.bpf.c", oracle_jsonl:$$oracle, budget_basis:$$basis, pass:$$table_pass, table_baseline_current_oracle_pass:$$table_pass, entries:$$entries, table_entries_required:$$entries, programmable_entries_observed:$$entries, over_materialization_ratio:1, max_over_materialization_ratio:$$max_ratio, update_writes_accounted:$$entries, update_writes_basis:"entry_count_from_phase1_table_load", max_update_writes:($$entries * $$update_ratio), max_entries:$$max_entries, max_memory_bytes:$$max_memory_bytes, max_stale_window_ms:$$max_stale_ms, max_update_latency_ms:$$max_update_ms, qualified_for_c8:false, detail:"table baseline path-oracle accounting recorded; release-level table/update counterfactual not satisfied"}' \
		>>"$(TABLE_BUDGET_JSON)"; \
	jq -cs \
		'{event:"table-budget-summary", result_level:"table_budget_accounting", pass:([.[] | select(.event == "table-budget" and .pass == true)] | length == 4), families:([.[] | select(.event == "table-budget")] | length), table_current_oracle_passes:([.[] | select(.event == "table-budget" and .table_baseline_current_oracle_pass == true)] | length), qualified_for_c8:false, detail:"current accounting records table-only path-oracle behavior; C8 remains unsupported until release-level table/update budget counterfactual fails"}' \
		"$(TABLE_BUDGET_JSON)" >>"$(TABLE_BUDGET_JSON)"; \
	test "$$w1_table_pass" = "true"; \
	test "$$w2_table_pass" = "true"; \
	test "$$w3_table_pass" = "true"; \
	test "$$w4_table_pass" = "true"
