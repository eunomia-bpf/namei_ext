def ev($xs; $name): ([ $xs[] | select(.event == $name) ] | first // {});
def arr($x): if ($x // null) == null then [] elif ($x | type) == "array" then $x else [$x] end;
def claim_missing($x; $prefix): arr($x) | map(select(test($prefix)));

ev($w1; "eval-osdi-w1-build-workload-macrobench-summary") as $w1s |
ev($w2; "eval-osdi-w2-nginx-workload-macrobench-summary") as $w2s |
ev($w3; "eval-osdi-w3-redis-workload-macrobench-summary") as $w3s |
ev($w4; "eval-osdi-w4-ccache-workload-macrobench-summary") as $w4s |
ev($perf; "eval-osdi-performance-comparison-summary") as $ps |
ev($perf_scope; "eval-osdi-performance-tool-redirect-scope-summary") as $pts |
ev($paper_release; "eval-osdi-w2-tool-redirect-paper-release-summary") as $prs |
ev($c4; "eval-osdi-c4-lookup-readdir-matrix-summary") as $c4s |
ev($w4_transition; "w4-cache-transition-summary") as $ts |
ev($w4_cache_table; "w4-cache-table-content-summary") as $cts |
ev($c7_audit; "eval-osdi-c7-artifact-reproducibility-audit-summary") as $c7s |
($w2s.w2_c2_slice_supported == true) as $w2_positive |
($w1s.w1_c2_slice_supported == true) as $w1_positive |
($w3s.w3_c2_slice_supported == true) as $w3_positive |
($w4s.w4_c2_slice_supported == true) as $w4_positive |
($w1s.policy_release_input_pass == true and $w2s.policy_release_input_pass == true and $w3s.policy_release_input_pass == true and $w4s.policy_release_input_pass == true) as $phase1_functional_positive |
($ps.c3_supported == true) as $c3_positive |
($pts.scoped_c3_supported == true) as $c3_scoped_positive |
($prs.paper_release_gate_pass == true) as $paper_release_positive |
($c4s.c4_supported == true and $c4s.release_gate_pass == true) as $c4_positive |
($ps.c5_supported == true) as $c5_positive |
($c7s.artifact_package_gate_pass == true and $c7s.artifact_package_replay_pass == true and $c7s.anonymization_checklist_gate_pass == true) as $c7_artifact_positive |
($c7s.c7_supported == true and $c7s.clean_checkout_gate_pass == true) as $c7_positive |
($ts.qualified_for_c8 == true or $cts.qualified_for_c8 == true) as $c8_positive |
[
  {
    claim_id:"C1",
    active_main_claim:true,
    verdict:(if $phase1_functional_positive then "supported" else "partial" end),
    evidence:["W1-W4 policy-family/path-oracle evidence exists through release ledgers"],
    supporting_paths:[$w1_json, $w2_json, $w3_json, $w4_json],
    supported_wording:"The Phase 1 prototype exercises one narrow VFS name-resolution ABI across four policy families in KVM-backed functional slices.",
    missing_evidence:(if $phase1_functional_positive then [] else ["W1-W4 policy release input evidence is incomplete"] end),
    scope_boundaries:["No qualifying end-to-end policy family yet satisfies all release gates", "C1 release-level programmability and C8 are scoped out of the current main claim set"],
    slice_gate_pass:$phase1_functional_positive,
    paper_release_gate_pass:false,
    release_gate_pass:false
  },
  {
    claim_id:"C2",
    active_main_claim:true,
    verdict:(if $w2_positive then "supported" else "unsupported" end),
    evidence:(["W2 nginx thresholded slice is positive", "W1/W3/W4 workload ledgers are release-input but threshold-negative"] + (if $paper_release_positive then ["Scoped W2 nginx plus tool-redirect paper-release gate passed"] else [] end)),
    supporting_paths:[$w1_json, $w2_json, $w3_json, $w4_json, $paper_release_json],
    supported_wording:(if $w2_positive then "The current evidence supports only a W2 nginx fixture C2 slice, not a global setup/materialization-cost claim." else "No current workload slice supports C2." end),
    missing_evidence:(if $w2_positive then [] else ["W2 C2 slice threshold evidence"] end),
    scope_boundaries:(arr($w1s.failed_gates) + arr($w3s.failed_gates) + arr($w4s.failed_gates) + ["global C2 requires threshold-positive W1, W2, W3, and W4 slices"] | unique),
    slice_gate_pass:$w2_positive,
    paper_release_gate_pass:$paper_release_positive,
    release_gate_pass:false
  },
  {
    claim_id:"C3",
    active_main_claim:true,
    verdict:(if ($c3_positive or $c3_scoped_positive) then "supported" else "unsupported" end),
    evidence:(["Release performance comparison computes native and FUSE p99 thresholds"] + (if $c3_scoped_positive then ["Tool-redirect scoped performance ledger satisfies native and FUSE p99 thresholds"] else [] end) + (if $paper_release_positive then ["Scoped W2 nginx plus tool-redirect paper-release gate passed"] else [] end)),
    supporting_paths:[$performance_json, $performance_scope_json, $paper_release_json],
    supported_wording:(if $c3_positive then "The selected metadata operations satisfy the configured native and FUSE p99 thresholds." elif $c3_scoped_positive then "The tool-redirect lookup/access/open/exec slice satisfies the configured native and FUSE p99 thresholds, while the full metadata suite remains unsupported." else "The current metadata tail-latency evidence does not satisfy the configured release thresholds." end),
    missing_evidence:(if ($c3_positive or $c3_scoped_positive) then [] else ["tool-redirect scoped C3 threshold evidence"] end),
    scope_boundaries:(claim_missing($ps.missing_evidence; "^C3") + (if $c3_scoped_positive then ["full-suite C3 policy/native p99 threshold"] else [] end) | unique),
    slice_gate_pass:($c3_positive or $c3_scoped_positive),
    paper_release_gate_pass:$paper_release_positive,
    release_gate_pass:false
  },
  {
    claim_id:"C4",
    active_main_claim:true,
    verdict:(if $c4_positive then "supported" else "partial" end),
    evidence:(["W1-W4 KVM oracles exercise lookup/readdir subsets and workload-specific content/output checks"] + (if $c4_positive then ["C4 lookup/readdir matrix ledger passes for all four declared policy families"] else [] end)),
    supporting_paths:[$w1_json, $w2_json, $w3_json, $w4_json, $c4_json],
    supported_wording:(if $c4_positive then "The declared W1-W4 Phase 1 oracle matrix supports lookup/readdir consistency for all four policy families." else "The Phase 1 rows support lookup/readdir consistency only for the declared oracle subsets." end),
    missing_evidence:(if $c4_positive then [] else ["No release-wide cross-workload lookup/readdir matrix with every policy family marked qualified"] end),
    scope_boundaries:(arr($c4s.scope_boundaries) + ["C4 does not support C8 table-only insufficiency or full real-workload correctness by itself"] | unique),
    slice_gate_pass:$c4_positive,
    paper_release_gate_pass:false,
    release_gate_pass:false
  },
  {
    claim_id:"C5",
    active_main_claim:$c5_positive,
    verdict:(if $c5_positive then "supported" else "scoped_out" end),
    evidence:["Performance comparison includes pass-only/native residual overhead threshold"],
    supporting_paths:[$performance_json],
    supported_wording:(if $c5_positive then "The selected pass-only residual overhead rows satisfy the configured threshold." else "The current paper scopes out VFS-placement attribution because residual-overhead evidence is negative." end),
    missing_evidence:claim_missing($ps.missing_evidence; "^C5"),
    slice_gate_pass:false,
    paper_release_gate_pass:false,
    release_gate_pass:$c5_positive
  },
  {
    claim_id:"C6",
    active_main_claim:false,
    verdict:"scoped_out",
    evidence:["Current KVM hard gates fail on verifier/load errors, syscall/checker failures, sha mismatches, and kernel diagnostics"],
    supporting_paths:[$w1_json, $w2_json, $w3_json, $w4_json],
    supported_wording:"The current paper treats fail-fast Phase 1 diagnostics as artifact evidence, not as a release-level stress or scalability claim.",
    missing_evidence:["No release-level stress, scale, or robustness sweep"],
    slice_gate_pass:false,
    paper_release_gate_pass:false,
    release_gate_pass:false
  },
  {
    claim_id:"C7",
    active_main_claim:false,
    verdict:"scoped_out",
    evidence:(["Make-owned KVM/Docker targets and sha manifests exist for Phase 1 evidence"] + (if $c7_artifact_positive then ["C7 artifact audit package, anonymization, and package-root paper replay gates passed"] else [] end)),
    supporting_paths:[$w1_json, $w2_json, $w3_json, $w4_json, $c7_audit_json],
    supported_wording:"The current paper treats Make-owned KVM/Docker targets and sha manifests as artifact evidence, not as submission-ready reproducibility.",
    missing_evidence:(if $c7_positive then [] elif $c7_artifact_positive then ["clean checkout reproduction"] else ["artifact package/replay/anonymization gate", "clean checkout reproduction"] end),
    slice_gate_pass:false,
    paper_release_gate_pass:false,
    release_gate_pass:false
  },
  {
    claim_id:"C8",
    active_main_claim:$c8_positive,
    verdict:(if $c8_positive then "supported" else "scoped_out" end),
    evidence:["W4 cache table/content comparator and cache transition counterfactual are explicit C8 checks"],
    supporting_paths:[$w4_cache_table_json, $w4_transition_json],
    supported_wording:(if $c8_positive then "The current W4 evidence shows table-only fails under the configured release budget." else "The current paper scopes out table-only insufficiency because W3/W4 table-only comparators still explain the sampled oracles." end),
    missing_evidence:["table-only budget failure", "release-level stale/update window", "operation-weighted policy cache hit rate strong enough to distinguish the policy from exact table updates"],
    slice_gate_pass:false,
    paper_release_gate_pass:false,
    release_gate_pass:$c8_positive
  }
] as $rows |
($rows | map(select(.active_main_claim == true)) | length) as $active |
($rows | map(select(.active_main_claim != true)) | length) as $scoped_out |
($rows | map(select(.active_main_claim == true and .verdict == "supported")) | length) as $supported |
($rows | map(select(.active_main_claim == true and .verdict == "unsupported")) | length) as $unsupported |
($rows | map(select(.active_main_claim == true and .verdict == "partial")) | length) as $partial |
$rows[],
{
  schema:"namei_ext.eval_osdi.claim_verdict.v1",
  event:"eval-osdi-claim-verdict-summary",
  run_id:$run_id,
  result_level:"paper_claim_verdict",
  claims:($rows | length),
  active_main_claims:$active,
  scoped_out_claims:$scoped_out,
  supported_claims:$supported,
  partial_claims:$partial,
  unsupported_claims:$unsupported,
  weak_accept_ready:$paper_release_positive,
  paper_release_gate_pass:$paper_release_positive,
  paper_release_scope:($prs.scope // "none"),
  release_gate_pass:false,
  highest_risk_claims:(if $c4_positive then ["C7","C8"] else ["C4","C7","C8"] end),
  scoped_out_rationale:["C5 residual-overhead evidence is negative", "C6 lacks release-level stress or scalability evidence", (if $c7_artifact_positive then "C7 lacks clean-checkout reproduction" else "C7 lacks clean-checkout reproduction and artifact package/replay/anonymization gates" end), "C8 table-only insufficiency is not proven by current W3/W4 counterfactuals"],
  required_next_actions:((if $c4_positive then [] else ["turn C4 from Phase 1 oracle-subset consistency into a release-wide lookup/readdir matrix"] end) + ["produce clean-checkout reproduction if the paper wants a C7 reproducibility claim", "produce a full-suite C3 performance comparison if the paper wants to expand beyond tool-redirect operations", "produce threshold-positive W1/W3/W4 evidence if the paper wants to expand beyond the W2 setup/materialization slice"]),
  inputs_sha256_file:$inputs_sha256
}
