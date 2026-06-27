def ev($xs; $name): ([ $xs[] | select(.event == $name) ] | first // {});

ev($trace; "w2-nginx-real-trace-summary") as $ts |
ev($w2; "eval-osdi-w2-nginx-workload-macrobench-summary") as $w2s |
ev($scope; "eval-osdi-performance-tool-redirect-scope-summary") as $ss |
($ts.w2_real_trace_gate_pass == true) as $trace_pass |
($ts.no_real_production_open_pass == true) as $no_prod |
($ts.endpoint_health_pass == true) as $endpoint |
($ts.upstream_seen == true) as $upstream |
($w2s.w2_c2_slice_supported == true) as $w2_c2 |
($ss.scoped_c3_supported == true) as $c3 |
($w2_c2 and $c3 and $trace_pass and $no_prod and $endpoint and $upstream) as $paper_release |
{
  schema: "namei_ext.eval_osdi.w2_tool_redirect_paper_release.v1",
  event: "eval-osdi-w2-tool-redirect-paper-release-input",
  run_id: $run_id,
  trace_run_id: $trace_run_id,
  w2_run_id: $w2_run_id,
  scope_run_id: $scope_run_id,
  trace_json: $trace_json,
  w2_json: $w2_json,
  scope_json: $scope_json,
  inputs_sha256_file: $inputs_sha256,
  scope: "w2_nginx_fixture_plus_tool_redirect_metadata"
},
{
  schema: "namei_ext.eval_osdi.w2_tool_redirect_paper_release.v1",
  event: "eval-osdi-w2-tool-redirect-paper-release-summary",
  run_id: $run_id,
  result_level: "scoped_paper_release_gate",
  scope: "w2_nginx_fixture_plus_tool_redirect_metadata",
  paper_release_gate_pass: $paper_release,
  release_gate_pass: $paper_release,
  weak_accept_evidence_candidate: $paper_release,
  w2_real_trace_gate_pass: $trace_pass,
  w2_c2_slice_supported: $w2_c2,
  tool_redirect_c3_supported: $c3,
  no_real_production_open_pass: $no_prod,
  endpoint_health_pass: $endpoint,
  upstream_seen: $upstream,
  pre_attach_rejected: ($ts.pre_attach_rejected == true),
  post_detach_rejected: ($ts.post_detach_rejected == true),
  policy_executed: ($ts.policy_executed == true),
  kvm_validated: ($ts.kvm_validated == true),
  dmesg_clean: ($ts.dmesg_clean == true),
  setup_latency_threshold_pass: ($w2s.setup_latency_threshold_pass == true),
  update_latency_threshold_pass: ($w2s.update_latency_threshold_pass == true),
  storage_footprint_pass: ($w2s.storage_footprint_pass == true),
  update_materialization_threshold_pass: ($w2s.update_materialization_threshold_pass == true),
  scoped_kernel_p99_threshold_pass: ($ss.scoped_kernel_p99_threshold_pass == true),
  scoped_fuse_speedup_threshold_pass: ($ss.scoped_fuse_speedup_threshold_pass == true),
  max_scoped_policy_to_native_p99_ratio: ($ss.max_scoped_policy_to_native_p99_ratio // null),
  min_scoped_policy_to_fuse_p99_speedup: ($ss.min_scoped_policy_to_fuse_p99_speedup // null),
  release_scope_boundaries: [
    "not global C2 across W1/W3/W4",
    "not full-suite C3 metadata performance",
    "not release-wide C4 lookup/readdir matrix",
    "not C8 table-only insufficiency"
  ],
  supported_wording: "Within the scoped nginx fixture and tool-redirect metadata release gate, namei_ext passes the real nginx no-production-open trace oracle, reduces W2 setup/materialization cost against five feature-equivalent baselines, and keeps lookup/access/open/exec p99 within configured native/FUSE thresholds.",
  missing_evidence: [
    (if $trace_pass then empty else "W2 real nginx no-production-open trace gate" end),
    (if $w2_c2 then empty else "W2 C2 setup/materialization slice" end),
    (if $c3 then empty else "tool-redirect scoped C3 p99 thresholds" end),
    "global C2 W1/W3/W4 threshold-positive evidence",
    "full-suite C3 metadata threshold evidence",
    "release-wide C4 lookup/readdir matrix",
    "C8 table-only budget failure"
  ],
  inputs_sha256_file: $inputs_sha256
}
