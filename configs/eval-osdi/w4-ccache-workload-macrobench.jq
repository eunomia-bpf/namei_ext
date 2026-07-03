def ev($rows; $name):
  ($rows | map(select(.event == $name)) | first // {});

def ev2($rows; $primary; $fallback):
  (($rows | map(select(.event == $primary)) | first) // ev($rows; $fallback));

def avg($xs):
  if ($xs | length) > 0 then (($xs | add) / ($xs | length)) else 0 end;

def stat($xs):
  {
    min: ($xs | min // 0),
    max: ($xs | max // 0),
    avg: avg($xs)
  };

def metric_stats($rows; $event; $system; metric):
  stat([$rows[] | select(.event == $event and .system == $system) | metric]);

($w4 // []) as $rows |
($w4_materialized // []) as $mrows |
($w4_bulk_policy // []) as $bprows |
($w4_bulk_policy_macro // []) as $bpmrows |
($w4_bulk_materialized // []) as $bmrows |
($w4_bulk_fuse // []) as $bfrows |
($w4_bulk_fuse_compile // []) as $bfcrows |
($w4_bulk_native // []) as $bncrows |
ev($rows; "w4-ccache-rule-macrobench-summary") as $summary |
ev($mrows; "w4-ccache-materialized-baseline-summary") as $msummary |
ev2($bprows; "w4-ccache-bulk-policy-compile-release-summary"; "w4-ccache-bulk-policy-compile-summary") as $bpsummary |
ev($bpmrows; "w4-ccache-bulk-policy-macrobench-summary") as $bpmsummary |
ev($bmrows; "w4-ccache-materialized-baseline-summary") as $bmsummary |
ev($bfrows; "w4-ccache-fuse-baseline-summary") as $bfsummary |
ev($bfcrows; "w4-ccache-bulk-fuse-compile-summary") as $bfcsummary |
ev($bncrows; "w4-ccache-bulk-native-compile-summary") as $bncsummary |
($summary.pass == true and
 $summary.samples >= $required_samples and
 $summary.systems == 2 and
 $summary.setup_rows == ($summary.samples * 2) and
 $summary.update_rows == ($summary.samples * 2) and
 $summary.correctness_rows == ($summary.samples * 2)) as $release_input_pass |
($msummary.pass == true and
 $msummary.samples >= $required_samples and
 $msummary.systems == 1 and
 $msummary.setup_rows == $msummary.samples and
 $msummary.update_rows == $msummary.samples and
 $msummary.correctness_rows == $msummary.samples and
 $msummary.policy_executed == false and
 $msummary.feature_equivalent_baseline == true) as $materialized_release_input_pass |
($bpsummary.pass == true and
 $bpsummary.bulk_policy_compile == true and
 $bpsummary.policy_executed == true and
 $bpsummary.ccache_compile_policy_executed == true and
 $bpsummary.output_hash_match == true and
 (($bpsummary.attached_compile_jobs == (($bpsummary.samples // 1) * $bpsummary.source_manifest_count)) or
  ($bpsummary.attached_compile_jobs == $bpsummary.source_manifest_count)) and
 $bpsummary.policy_redirected_cache_objects > 0) as $bulk_policy_compile_input_pass |
($bulk_policy_compile_input_pass) as $bulk_policy_compile_smoke_pass |
($bulk_policy_compile_input_pass and
 ($bpsummary.samples // 0) >= $required_samples and
 ($bpsummary.compile_rows // 0) == ($bpsummary.samples // 0) and
 $bpsummary.attached_compile_jobs == (($bpsummary.samples // 0) * $bpsummary.source_manifest_count) and
 $bpsummary.attached_compile_output_matches == $bpsummary.attached_compile_jobs and
 ($bpsummary.attached_cache_path_file_ops // 0) > 0 and
 ($bpsummary.attached_policy_cache_object_ops // 0) > 0 and
 $bpsummary.operation_weighted_policy_hit_rate_is_release == true) as $bulk_policy_compile_release_input_pass |
($bmsummary.pass == true and
 $bmsummary.workload == "w4-ccache-bulk-redis-nginx" and
 $bmsummary.samples >= $required_samples and
 $bmsummary.systems == 1 and
 $bmsummary.setup_rows == $bmsummary.samples and
 $bmsummary.update_rows == $bmsummary.samples and
 $bmsummary.correctness_rows == $bmsummary.samples and
 $bmsummary.policy_executed == false and
 $bmsummary.feature_equivalent_baseline == true) as $bulk_materialized_release_input_pass |
($bfsummary.pass == true and
 $bfsummary.workload == "w4-ccache-bulk-redis-nginx" and
 $bfsummary.samples >= $required_samples and
 $bfsummary.systems == 1 and
 $bfsummary.setup_rows == $bfsummary.samples and
 $bfsummary.update_rows == $bfsummary.samples and
 $bfsummary.correctness_rows == $bfsummary.samples and
 $bfsummary.policy_executed == false and
 $bfsummary.feature_equivalent_baseline == true) as $bulk_fuse_release_input_pass |
($bfcsummary.pass == true and
 $bfcsummary.workload == "w4-ccache-bulk-redis-nginx" and
 $bfcsummary.samples >= $required_samples and
 $bfcsummary.compile_rows == $bfcsummary.samples and
 $bfcsummary.policy_executed == false and
 $bfcsummary.feature_equivalent_baseline == true and
 $bfcsummary.complete_ccache_compile_through_fuse == true and
 $bfcsummary.read_oriented_cache_view_only == false and
 $bfcsummary.total_compile_jobs == ($bfcsummary.samples * $bfcsummary.source_manifest_count) and
 $bfcsummary.total_compile_output_matches == $bfcsummary.total_compile_jobs and
 $bfcsummary.direct_cache_hit >= $bfcsummary.total_compile_jobs and
 $bfcsummary.fuse_mounts == $bfcsummary.samples and
 $bfcsummary.operation_weighted_fuse_hit_rate_is_release == true) as $bulk_fuse_compile_release_input_pass |
($bncsummary.pass == true and
 $bncsummary.workload == "w4-ccache-bulk-redis-nginx" and
 $bncsummary.samples >= $required_samples and
 $bncsummary.compile_rows == $bncsummary.samples and
 $bncsummary.policy_executed == false and
 $bncsummary.feature_equivalent_baseline == true and
 $bncsummary.total_compile_jobs == ($bncsummary.samples * $bncsummary.source_manifest_count) and
 $bncsummary.total_compile_output_matches == $bncsummary.total_compile_jobs and
 $bncsummary.direct_cache_hit >= $bncsummary.total_compile_jobs and
 $bncsummary.operation_weighted_native_hit_rate_is_release == true) as $bulk_native_compile_release_input_pass |
([ $rows[] | select(.event == "w4-ccache-rule-macrobench-setup") | .system ] | unique) as $systems |
($systems | index("parent_rule_policy") != null) as $parent_policy_pass |
($systems | index("table_redirect") != null) as $table_baseline_pass |
($release_input_pass and $parent_policy_pass) as $policy_release_input_pass |
($release_input_pass and $table_baseline_pass) as $table_release_input_pass |
{
  setup_ns: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "parent_rule_policy"; .setup_ns),
  update_ns: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "parent_rule_policy"; .update_ns),
  setup_objects: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "parent_rule_policy"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
  setup_bytes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "parent_rule_policy"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  setup_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "parent_rule_policy"; (.total_rule_writes // 0)),
  setup_lookup_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "parent_rule_policy"; (.lookup_rule_writes // 0)),
  update_writes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "parent_rule_policy"; ((.source_update_writes // 0) + (.policy_update_writes // 0))),
  update_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "parent_rule_policy"; (.update_total_rule_writes // 0)),
  update_bytes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "parent_rule_policy"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0)))
} as $policy_stats |
{
  setup_ns: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "table_redirect"; .setup_ns),
  update_ns: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "table_redirect"; .update_ns),
  setup_objects: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "table_redirect"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
  setup_bytes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "table_redirect"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  setup_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "table_redirect"; (.total_rule_writes // 0)),
  setup_lookup_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-setup"; "table_redirect"; (.lookup_rule_writes // 0)),
  update_writes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "table_redirect"; ((.source_update_writes // 0) + (.baseline_update_writes // 0))),
  update_rule_writes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "table_redirect"; (.update_total_rule_writes // 0)),
  update_bytes: metric_stats($rows; "w4-ccache-rule-macrobench-update"; "table_redirect"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0)))
} as $table_stats |
{
  setup_ns: metric_stats($mrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; .setup_ns),
  update_ns: metric_stats($mrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; .update_ns),
  setup_objects: metric_stats($mrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
  setup_bytes: metric_stats($mrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  setup_rule_writes: metric_stats($mrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; (.total_rule_writes // 0)),
  setup_lookup_rule_writes: metric_stats($mrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; (.lookup_rule_writes // 0)),
  update_writes: metric_stats($mrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; ((.source_update_writes // 0) + (.baseline_update_writes // 0))),
  update_rule_writes: metric_stats($mrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; (.update_total_rule_writes // 0)),
  update_bytes: metric_stats($mrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0)))
} as $materialized_stats |
{
  setup_ns: metric_stats($bmrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; .setup_ns),
  update_ns: metric_stats($bmrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; .update_ns),
  setup_objects: metric_stats($bmrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
  setup_bytes: metric_stats($bmrows; "w4-ccache-materialized-baseline-setup"; "materialized_cache_view"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  update_writes: metric_stats($bmrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; ((.source_update_writes // 0) + (.baseline_update_writes // 0))),
  update_bytes: metric_stats($bmrows; "w4-ccache-materialized-baseline-update"; "materialized_cache_view"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0)))
} as $bulk_materialized_stats |
{
  setup_ns: metric_stats($bfrows; "w4-ccache-fuse-baseline-setup"; "fuse_redirect"; .setup_ns),
  update_ns: metric_stats($bfrows; "w4-ccache-fuse-baseline-update"; "fuse_redirect"; .update_ns),
  setup_objects: metric_stats($bfrows; "w4-ccache-fuse-baseline-setup"; "fuse_redirect"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
 setup_bytes: metric_stats($bfrows; "w4-ccache-fuse-baseline-setup"; "fuse_redirect"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  update_writes: metric_stats($bfrows; "w4-ccache-fuse-baseline-update"; "fuse_redirect"; ((.source_update_writes // 0) + (.baseline_update_writes // 0))),
  update_bytes: metric_stats($bfrows; "w4-ccache-fuse-baseline-update"; "fuse_redirect"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0))),
  fuse_mounts: metric_stats($bfrows; "w4-ccache-fuse-baseline-setup"; "fuse_redirect"; (.fuse_mounts // 0))
} as $bulk_fuse_stats |
{
  setup_ns: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-setup"; "cache_locality_exact_policy"; .setup_ns),
  update_ns: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-update"; "cache_locality_exact_policy"; .update_ns),
  setup_objects: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-setup"; "cache_locality_exact_policy"; ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) + (.bind_mounts // 0) + (.fuse_mounts // 0))),
  setup_bytes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-setup"; "cache_locality_exact_policy"; ((.bytes_written // 0) + (.bytes_copied // 0))),
  setup_rule_writes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-setup"; "cache_locality_exact_policy"; (.total_rule_writes // 0)),
  setup_lookup_rule_writes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-setup"; "cache_locality_exact_policy"; (.lookup_rule_writes // 0)),
  update_writes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-update"; "cache_locality_exact_policy"; ((.source_update_writes // 0) + (.policy_update_writes // 0))),
  update_rule_writes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-update"; "cache_locality_exact_policy"; (.update_total_rule_writes // 0)),
  update_bytes: metric_stats($bpmrows; "w4-ccache-bulk-policy-macrobench-update"; "cache_locality_exact_policy"; ((.update_bytes_written // 0) + (.update_bytes_copied // 0)))
} as $bulk_policy_stats |
([$bulk_materialized_stats.setup_ns.avg, $bulk_fuse_stats.setup_ns.avg] | min) as $bulk_best_setup_ns_avg |
([$bulk_materialized_stats.update_ns.avg, $bulk_fuse_stats.update_ns.avg] | min) as $bulk_best_update_ns_avg |
([$bulk_materialized_stats.setup_objects.avg, $bulk_fuse_stats.setup_objects.avg] | min) as $bulk_min_setup_objects_avg |
([$bulk_materialized_stats.setup_bytes.avg, $bulk_fuse_stats.setup_bytes.avg] | min) as $bulk_min_setup_bytes_avg |
($policy_stats.setup_objects.avg <= $materialized_stats.setup_objects.avg and
 $policy_stats.setup_bytes.avg <= $materialized_stats.setup_bytes.avg) as $storage_footprint_pass |
($policy_stats.setup_ns.avg <= $materialized_stats.setup_ns.avg) as $setup_latency_threshold_pass |
($policy_stats.update_ns.avg <= $materialized_stats.update_ns.avg) as $update_latency_threshold_pass |
($policy_stats.setup_rule_writes.avg <= $materialized_stats.setup_objects.avg and
 $policy_stats.update_rule_writes.avg <= $materialized_stats.update_writes.avg) as $rule_materialization_threshold_pass |
($setup_latency_threshold_pass and
 $update_latency_threshold_pass and
 $rule_materialization_threshold_pass) as $threshold_pass |
($policy_release_input_pass and
 $materialized_release_input_pass and
 $storage_footprint_pass and
 $threshold_pass) as $w4_c2_slice_supported |
($bulk_materialized_release_input_pass and
 $bulk_fuse_release_input_pass and
 $bulk_fuse_compile_release_input_pass and
 $bulk_native_compile_release_input_pass) as $bulk_external_baseline_release_input_pass |
($bpmsummary.pass == true and
 $bpmsummary.workload == "w4-ccache-bulk-redis-nginx" and
 $bpmsummary.samples >= $required_samples and
 $bpmsummary.systems == 1 and
 $bpmsummary.setup_rows == $bpmsummary.samples and
 $bpmsummary.update_rows == $bpmsummary.samples and
 $bpmsummary.correctness_rows == $bpmsummary.samples and
 $bpmsummary.policy_executed == true and
 $bpmsummary.compile_smoke_required == true) as $bulk_policy_release_input_pass |
($bulk_policy_release_input_pass and
 $bulk_policy_stats.setup_objects.avg <= $bulk_min_setup_objects_avg and
 $bulk_policy_stats.setup_bytes.avg <= $bulk_min_setup_bytes_avg) as $bulk_storage_footprint_pass |
($bulk_policy_release_input_pass and
 $bulk_policy_stats.setup_ns.avg <= $bulk_best_setup_ns_avg) as $bulk_setup_latency_threshold_pass |
($bulk_policy_release_input_pass and
 $bulk_policy_stats.update_ns.avg <= $bulk_best_update_ns_avg) as $bulk_update_latency_threshold_pass |
($bulk_setup_latency_threshold_pass and
 $bulk_update_latency_threshold_pass) as $bulk_threshold_pass |
($bulk_policy_release_input_pass and
 $bulk_policy_compile_release_input_pass and
 $bulk_external_baseline_release_input_pass and
 $bulk_storage_footprint_pass and
 $bulk_threshold_pass) as $bulk_release_comparison_pass |
[
  (if $policy_release_input_pass then empty else "W4 parent-rule policy release input" end),
  (if $table_release_input_pass then empty else "W4 table_redirect internal baseline release input" end),
  (if $materialized_release_input_pass then empty else "W4 materialized external baseline release input" end),
  (if $bulk_policy_compile_release_input_pass then empty else "W4 bulk policy-attached compile release input" end),
  (if $bulk_policy_release_input_pass then empty else "W4 bulk proposed-system release repetition setup/update ledger" end),
  (if $bulk_materialized_release_input_pass then empty else "W4 bulk materialized baseline release input" end),
  (if $bulk_fuse_release_input_pass then empty else "W4 bulk FUSE cache-view baseline release input" end),
  (if $bulk_fuse_compile_release_input_pass then empty else "W4 complete compile-through-FUSE baseline" end),
  (if $bulk_native_compile_release_input_pass then empty else "W4 native ccache compile baseline" end)
] as $missing_inputs |
[
  (if $setup_latency_threshold_pass then empty else "W4 setup latency threshold failed against materialized external baseline" end),
  (if $update_latency_threshold_pass then empty else "W4 update latency threshold failed against materialized external baseline" end),
  (if $rule_materialization_threshold_pass then empty else "W4 rule materialization threshold failed against materialized external baseline" end),
  (if $bulk_release_comparison_pass then empty else "W4 bulk comparison gate failed against materialized/FUSE/native external baselines or missing compile release input" end)
] as $failed_gates |
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-redis-nginx",
  row_kind: "proposed_system",
  policy_family: "cache_locality_view.bpf.c",
  source_json: $w4_json,
  samples: ($summary.samples // 0),
  setup_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-setup" and .system == "parent_rule_policy") ] | length),
  update_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-update" and .system == "parent_rule_policy") ] | length),
  correctness_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-correctness" and .system == "parent_rule_policy" and .pass == true) ] | length),
  pass: $policy_release_input_pass,
  release_input_pass: $policy_release_input_pass,
  setup_ns_avg: $policy_stats.setup_ns.avg,
  update_ns_avg: $policy_stats.update_ns.avg,
  setup_objects_avg: $policy_stats.setup_objects.avg,
  setup_bytes_avg: $policy_stats.setup_bytes.avg,
  setup_rule_writes_avg: $policy_stats.setup_rule_writes.avg,
  setup_lookup_rule_writes_avg: $policy_stats.setup_lookup_rule_writes.avg,
  update_writes_avg: $policy_stats.update_writes.avg,
  update_rule_writes_avg: $policy_stats.update_rule_writes.avg,
  update_bytes_avg: $policy_stats.update_bytes.avg,
  policy_executed: true,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-redis-nginx",
  row_kind: "feature_baseline",
  baseline: "table_redirect",
  policy_family: "table_redirect.bpf.c",
  source_json: $w4_json,
  samples: ($summary.samples // 0),
  setup_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-setup" and .system == "table_redirect") ] | length),
  update_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-update" and .system == "table_redirect") ] | length),
  correctness_rows: ([ $rows[] | select(.event == "w4-ccache-rule-macrobench-correctness" and .system == "table_redirect" and .pass == true) ] | length),
  pass: $table_release_input_pass,
  release_input_pass: $table_release_input_pass,
  internal_ablation_only: true,
  setup_ns_avg: $table_stats.setup_ns.avg,
  update_ns_avg: $table_stats.update_ns.avg,
  setup_objects_avg: $table_stats.setup_objects.avg,
  setup_bytes_avg: $table_stats.setup_bytes.avg,
  setup_rule_writes_avg: $table_stats.setup_rule_writes.avg,
  setup_lookup_rule_writes_avg: $table_stats.setup_lookup_rule_writes.avg,
  update_writes_avg: $table_stats.update_writes.avg,
  update_rule_writes_avg: $table_stats.update_rule_writes.avg,
  update_bytes_avg: $table_stats.update_bytes.avg,
  policy_executed: true,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-redis-nginx",
  row_kind: "external_baseline",
  baseline: "materialized_cache_view",
  source_json: $w4_materialized_json,
  samples: ($msummary.samples // 0),
  setup_rows: ([ $mrows[] | select(.event == "w4-ccache-materialized-baseline-setup" and .system == "materialized_cache_view") ] | length),
  update_rows: ([ $mrows[] | select(.event == "w4-ccache-materialized-baseline-update" and .system == "materialized_cache_view") ] | length),
  correctness_rows: ([ $mrows[] | select(.event == "w4-ccache-materialized-baseline-correctness" and .system == "materialized_cache_view" and .pass == true) ] | length),
  pass: $materialized_release_input_pass,
  release_input_pass: $materialized_release_input_pass,
  setup_ns_avg: $materialized_stats.setup_ns.avg,
  update_ns_avg: $materialized_stats.update_ns.avg,
  setup_objects_avg: $materialized_stats.setup_objects.avg,
  setup_bytes_avg: $materialized_stats.setup_bytes.avg,
  setup_rule_writes_avg: $materialized_stats.setup_rule_writes.avg,
  setup_lookup_rule_writes_avg: $materialized_stats.setup_lookup_rule_writes.avg,
  update_writes_avg: $materialized_stats.update_writes.avg,
  update_rule_writes_avg: $materialized_stats.update_rule_writes.avg,
  update_bytes_avg: $materialized_stats.update_bytes.avg,
  policy_executed: false,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-bulk-redis-nginx",
  row_kind: "proposed_system",
  policy_family: "cache_locality_view.bpf.c",
  result_level: "bulk_policy_setup_update_release_input",
  source_json: $w4_bulk_policy_macro_json,
  compile_source_json: $w4_bulk_policy_json,
  samples: ($bpmsummary.samples // 0),
  source_manifest_count: (($bpmsummary.source_manifest_count // $bpsummary.source_manifest_count) // 0),
  attached_compile_jobs: ($bpsummary.attached_compile_jobs // 0),
  attached_compile_output_matches: ($bpsummary.attached_compile_output_matches // 0),
  setup_rows: ([ $bpmrows[] | select(.event == "w4-ccache-bulk-policy-macrobench-setup" and .system == "cache_locality_exact_policy") ] | length),
  update_rows: ([ $bpmrows[] | select(.event == "w4-ccache-bulk-policy-macrobench-update" and .system == "cache_locality_exact_policy") ] | length),
  correctness_rows: ([ $bpmrows[] | select(.event == "w4-ccache-bulk-policy-macrobench-correctness" and .system == "cache_locality_exact_policy" and .pass == true) ] | length),
  pass: ($bulk_policy_release_input_pass and $bulk_policy_compile_release_input_pass),
  smoke_input_pass: $bulk_policy_compile_smoke_pass,
  release_input_pass: ($bulk_policy_release_input_pass and $bulk_policy_compile_release_input_pass),
  setup_update_release_input_pass: $bulk_policy_release_input_pass,
  compile_release_input_pass: $bulk_policy_compile_release_input_pass,
  bulk_release_comparison_pass: $bulk_release_comparison_pass,
  setup_ns_avg: $bulk_policy_stats.setup_ns.avg,
  update_ns_avg: $bulk_policy_stats.update_ns.avg,
  setup_objects_avg: $bulk_policy_stats.setup_objects.avg,
  setup_bytes_avg: $bulk_policy_stats.setup_bytes.avg,
  setup_rule_writes_avg: $bulk_policy_stats.setup_rule_writes.avg,
  setup_lookup_rule_writes_avg: $bulk_policy_stats.setup_lookup_rule_writes.avg,
  update_writes_avg: $bulk_policy_stats.update_writes.avg,
  update_rule_writes_avg: $bulk_policy_stats.update_rule_writes.avg,
  update_bytes_avg: $bulk_policy_stats.update_bytes.avg,
  policy_executed: ($bpsummary.policy_executed // false),
  setup_update_policy_executed: ($bpmsummary.policy_executed // false),
  ccache_compile_policy_executed: ($bpsummary.ccache_compile_policy_executed // false),
  output_hash_match: ($bpsummary.output_hash_match // false),
  policy_redirected_cache_objects: ($bpsummary.policy_redirected_cache_objects // 0),
  attached_cache_path_file_ops: ($bpsummary.attached_cache_path_file_ops // 0),
  attached_policy_cache_object_ops: ($bpsummary.attached_policy_cache_object_ops // 0),
  attached_sampled_operation_hit_rate: ($bpsummary.attached_sampled_operation_hit_rate // 0),
  operation_weighted_policy_cache_hit_rate: ($bpsummary.operation_weighted_policy_cache_hit_rate // false),
  operation_weighted_policy_hit_rate_is_release: ($bpsummary.operation_weighted_policy_hit_rate_is_release // false),
  kvm_validated: ($bpsummary.kvm_validated // false)
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-bulk-redis-nginx",
  row_kind: "external_baseline",
  baseline: "materialized_cache_view",
  result_level: "bulk_external_baseline",
  source_json: $w4_bulk_materialized_json,
  samples: ($bmsummary.samples // 0),
  setup_rows: ([ $bmrows[] | select(.event == "w4-ccache-materialized-baseline-setup" and .system == "materialized_cache_view") ] | length),
  update_rows: ([ $bmrows[] | select(.event == "w4-ccache-materialized-baseline-update" and .system == "materialized_cache_view") ] | length),
  correctness_rows: ([ $bmrows[] | select(.event == "w4-ccache-materialized-baseline-correctness" and .system == "materialized_cache_view" and .pass == true) ] | length),
  pass: $bulk_materialized_release_input_pass,
  release_input_pass: $bulk_materialized_release_input_pass,
  setup_ns_avg: $bulk_materialized_stats.setup_ns.avg,
  update_ns_avg: $bulk_materialized_stats.update_ns.avg,
  setup_objects_avg: $bulk_materialized_stats.setup_objects.avg,
  setup_bytes_avg: $bulk_materialized_stats.setup_bytes.avg,
  update_writes_avg: $bulk_materialized_stats.update_writes.avg,
  update_bytes_avg: $bulk_materialized_stats.update_bytes.avg,
  policy_executed: false,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-bulk-redis-nginx",
  row_kind: "external_baseline",
  baseline: "fuse_redirect",
  result_level: "bulk_external_baseline",
  source_json: $w4_bulk_fuse_json,
  samples: ($bfsummary.samples // 0),
  setup_rows: ([ $bfrows[] | select(.event == "w4-ccache-fuse-baseline-setup" and .system == "fuse_redirect") ] | length),
  update_rows: ([ $bfrows[] | select(.event == "w4-ccache-fuse-baseline-update" and .system == "fuse_redirect") ] | length),
  correctness_rows: ([ $bfrows[] | select(.event == "w4-ccache-fuse-baseline-correctness" and .system == "fuse_redirect" and .pass == true) ] | length),
  pass: $bulk_fuse_release_input_pass,
  release_input_pass: $bulk_fuse_release_input_pass,
  setup_ns_avg: $bulk_fuse_stats.setup_ns.avg,
  update_ns_avg: $bulk_fuse_stats.update_ns.avg,
  setup_objects_avg: $bulk_fuse_stats.setup_objects.avg,
  setup_bytes_avg: $bulk_fuse_stats.setup_bytes.avg,
  update_writes_avg: $bulk_fuse_stats.update_writes.avg,
  update_bytes_avg: $bulk_fuse_stats.update_bytes.avg,
  fuse_mounts_avg: $bulk_fuse_stats.fuse_mounts.avg,
  read_oriented_cache_view_only: true,
  complete_ccache_compile_through_fuse: false,
  policy_executed: false,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-bulk-redis-nginx",
  row_kind: "external_baseline",
  baseline: "fuse_redirect_compile",
  result_level: "bulk_external_compile_baseline",
  source_json: $w4_bulk_fuse_compile_json,
  samples: ($bfcsummary.samples // 0),
  compile_rows: ([ $bfcrows[] | select(.event == "w4-ccache-bulk-fuse-compile-sample" and .system == "fuse_redirect_compile") ] | length),
  source_manifest_count: ($bfcsummary.source_manifest_count // 0),
  total_compile_jobs: ($bfcsummary.total_compile_jobs // 0),
  total_compile_output_matches: ($bfcsummary.total_compile_output_matches // 0),
  compile_ns_avg: ($bfcsummary.compile_ns_avg // 0),
  direct_cache_hit: ($bfcsummary.direct_cache_hit // 0),
  ccache_log_direct_cache_hit: ($bfcsummary.ccache_log_direct_cache_hit // 0),
  cache_path_file_ops: ($bfcsummary.cache_path_file_ops // 0),
  cache_object_ops: ($bfcsummary.cache_object_ops // 0),
  sampled_operation_hit_rate: ($bfcsummary.sampled_operation_hit_rate // 0),
  fuse_mounts: ($bfcsummary.fuse_mounts // 0),
  pass: $bulk_fuse_compile_release_input_pass,
  release_input_pass: $bulk_fuse_compile_release_input_pass,
  read_oriented_cache_view_only: false,
  complete_ccache_compile_through_fuse: ($bfcsummary.complete_ccache_compile_through_fuse // false),
  operation_weighted_fuse_hit_rate_is_release: ($bfcsummary.operation_weighted_fuse_hit_rate_is_release // false),
  policy_executed: false,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench",
  run_id: $run_id,
  workload_id: "w4-ccache-bulk-redis-nginx",
  row_kind: "external_baseline",
  baseline: "native_ccache_hot_compile",
  result_level: "bulk_external_compile_baseline",
  source_json: $w4_bulk_native_json,
  samples: ($bncsummary.samples // 0),
  compile_rows: ([ $bncrows[] | select(.event == "w4-ccache-bulk-native-compile-sample" and .system == "native_ccache_hot_compile") ] | length),
  source_manifest_count: ($bncsummary.source_manifest_count // 0),
  total_compile_jobs: ($bncsummary.total_compile_jobs // 0),
  total_compile_output_matches: ($bncsummary.total_compile_output_matches // 0),
  compile_ns_avg: ($bncsummary.compile_ns_avg // 0),
  cache_miss: ($bncsummary.cache_miss // 0),
  direct_cache_hit: ($bncsummary.direct_cache_hit // 0),
  local_storage_hit: ($bncsummary.local_storage_hit // 0),
  local_storage_write: ($bncsummary.local_storage_write // 0),
  cache_path_file_ops: ($bncsummary.cache_path_file_ops // 0),
  cache_object_ops: ($bncsummary.cache_object_ops // 0),
  sampled_operation_hit_rate: ($bncsummary.sampled_operation_hit_rate // 0),
  pass: $bulk_native_compile_release_input_pass,
  release_input_pass: $bulk_native_compile_release_input_pass,
  read_oriented_cache_view_only: false,
  real_ccache_run: true,
  operation_weighted_native_hit_rate_is_release: ($bncsummary.operation_weighted_native_hit_rate_is_release // false),
  policy_executed: false,
  kvm_validated: true
},
{
  schema: "namei_ext.eval_osdi.w4_ccache_workload_macrobench.v1",
  event: "eval-osdi-w4-ccache-workload-macrobench-summary",
  run_id: $run_id,
  workload_id: "w4-ccache-redis-nginx",
  result_level: "w4_workload_kvm_rule_macrobench_external_baseline_thresholded_slice",
  required_samples: $required_samples,
  source_json: $w4_json,
  materialized_source_json: $w4_materialized_json,
  bulk_policy_source_json: $w4_bulk_policy_json,
  bulk_policy_macrobench_source_json: $w4_bulk_policy_macro_json,
  bulk_materialized_source_json: $w4_bulk_materialized_json,
  bulk_fuse_source_json: $w4_bulk_fuse_json,
  bulk_fuse_compile_source_json: $w4_bulk_fuse_compile_json,
  bulk_native_source_json: $w4_bulk_native_json,
  policy_release_input_pass: $policy_release_input_pass,
  table_release_input_pass: $table_release_input_pass,
  baseline_release_input_pass: $materialized_release_input_pass,
  table_baseline_pass: $table_baseline_pass,
  materialized_baseline_pass: $materialized_release_input_pass,
  full_feature_equivalent_baseline_pass: $materialized_release_input_pass,
  bulk_policy_compile_smoke_pass: $bulk_policy_compile_smoke_pass,
  bulk_policy_compile_release_input_pass: $bulk_policy_compile_release_input_pass,
  bulk_policy_release_input_pass: $bulk_policy_release_input_pass,
  bulk_materialized_baseline_pass: $bulk_materialized_release_input_pass,
  bulk_fuse_baseline_pass: $bulk_fuse_release_input_pass,
  bulk_fuse_compile_baseline_pass: $bulk_fuse_compile_release_input_pass,
  bulk_native_compile_baseline_pass: $bulk_native_compile_release_input_pass,
  bulk_external_baseline_release_input_pass: $bulk_external_baseline_release_input_pass,
  bulk_full_feature_equivalent_baseline_pass: $bulk_external_baseline_release_input_pass,
  bulk_release_comparison_pass: $bulk_release_comparison_pass,
  bulk_storage_footprint_pass: $bulk_storage_footprint_pass,
  bulk_setup_latency_threshold_pass: $bulk_setup_latency_threshold_pass,
  bulk_update_latency_threshold_pass: $bulk_update_latency_threshold_pass,
  bulk_threshold_pass: $bulk_threshold_pass,
  storage_footprint_pass: $storage_footprint_pass,
  setup_latency_threshold_pass: $setup_latency_threshold_pass,
  update_latency_threshold_pass: $update_latency_threshold_pass,
  rule_materialization_threshold_pass: $rule_materialization_threshold_pass,
  threshold_pass: $threshold_pass,
  w4_c2_slice_supported: $w4_c2_slice_supported,
  c2_supported: false,
  release_gate_pass: false,
  policy_setup_ns_avg: $policy_stats.setup_ns.avg,
  table_setup_ns_avg: $table_stats.setup_ns.avg,
  baseline_setup_ns_avg: $materialized_stats.setup_ns.avg,
  materialized_setup_ns_avg: $materialized_stats.setup_ns.avg,
  policy_update_ns_avg: $policy_stats.update_ns.avg,
  table_update_ns_avg: $table_stats.update_ns.avg,
  baseline_update_ns_avg: $materialized_stats.update_ns.avg,
  materialized_update_ns_avg: $materialized_stats.update_ns.avg,
  bulk_policy_setup_ns_avg: $bulk_policy_stats.setup_ns.avg,
  bulk_policy_update_ns_avg: $bulk_policy_stats.update_ns.avg,
  bulk_policy_setup_objects_avg: $bulk_policy_stats.setup_objects.avg,
  bulk_policy_setup_bytes_avg: $bulk_policy_stats.setup_bytes.avg,
  bulk_policy_setup_rule_writes_avg: $bulk_policy_stats.setup_rule_writes.avg,
  bulk_policy_update_rule_writes_avg: $bulk_policy_stats.update_rule_writes.avg,
  bulk_policy_update_bytes_avg: $bulk_policy_stats.update_bytes.avg,
  bulk_policy_attached_compile_jobs: ($bpsummary.attached_compile_jobs // 0),
  bulk_policy_redirected_cache_objects: ($bpsummary.policy_redirected_cache_objects // 0),
  bulk_policy_attached_cache_path_file_ops: ($bpsummary.attached_cache_path_file_ops // 0),
  bulk_policy_attached_policy_cache_object_ops: ($bpsummary.attached_policy_cache_object_ops // 0),
  bulk_policy_attached_sampled_operation_hit_rate: ($bpsummary.attached_sampled_operation_hit_rate // 0),
  bulk_materialized_setup_ns_avg: $bulk_materialized_stats.setup_ns.avg,
  bulk_materialized_update_ns_avg: $bulk_materialized_stats.update_ns.avg,
  bulk_fuse_setup_ns_avg: $bulk_fuse_stats.setup_ns.avg,
  bulk_fuse_update_ns_avg: $bulk_fuse_stats.update_ns.avg,
  bulk_fuse_mounts_avg: $bulk_fuse_stats.fuse_mounts.avg,
  bulk_fuse_compile_ns_avg: ($bfcsummary.compile_ns_avg // 0),
  bulk_fuse_compile_samples: ($bfcsummary.samples // 0),
  bulk_fuse_compile_source_manifest_count: ($bfcsummary.source_manifest_count // 0),
  bulk_fuse_compile_total_compile_jobs: ($bfcsummary.total_compile_jobs // 0),
  bulk_fuse_compile_total_output_matches: ($bfcsummary.total_compile_output_matches // 0),
  bulk_fuse_compile_direct_cache_hit: ($bfcsummary.direct_cache_hit // 0),
  bulk_fuse_compile_cache_path_file_ops: ($bfcsummary.cache_path_file_ops // 0),
  bulk_fuse_compile_cache_object_ops: ($bfcsummary.cache_object_ops // 0),
  bulk_fuse_compile_sampled_operation_hit_rate: ($bfcsummary.sampled_operation_hit_rate // 0),
  bulk_native_compile_ns_avg: ($bncsummary.compile_ns_avg // 0),
  bulk_native_compile_samples: ($bncsummary.samples // 0),
  bulk_native_compile_source_manifest_count: ($bncsummary.source_manifest_count // 0),
  bulk_native_compile_total_compile_jobs: ($bncsummary.total_compile_jobs // 0),
  bulk_native_compile_total_output_matches: ($bncsummary.total_compile_output_matches // 0),
  bulk_native_compile_cache_miss: ($bncsummary.cache_miss // 0),
  bulk_native_compile_direct_cache_hit: ($bncsummary.direct_cache_hit // 0),
  bulk_native_compile_local_storage_hit: ($bncsummary.local_storage_hit // 0),
  bulk_native_compile_local_storage_write: ($bncsummary.local_storage_write // 0),
  bulk_native_compile_cache_path_file_ops: ($bncsummary.cache_path_file_ops // 0),
  bulk_native_compile_cache_object_ops: ($bncsummary.cache_object_ops // 0),
  bulk_native_compile_sampled_operation_hit_rate: ($bncsummary.sampled_operation_hit_rate // 0),
  bulk_best_external_setup_ns_avg: $bulk_best_setup_ns_avg,
  bulk_best_external_update_ns_avg: $bulk_best_update_ns_avg,
  policy_setup_objects_avg: $policy_stats.setup_objects.avg,
  baseline_setup_objects_avg: $materialized_stats.setup_objects.avg,
  policy_setup_bytes_avg: $policy_stats.setup_bytes.avg,
  baseline_setup_bytes_avg: $materialized_stats.setup_bytes.avg,
  policy_setup_rule_writes_avg: $policy_stats.setup_rule_writes.avg,
  baseline_setup_rule_writes_avg: $materialized_stats.setup_rule_writes.avg,
  policy_setup_lookup_rule_writes_avg: $policy_stats.setup_lookup_rule_writes.avg,
  baseline_setup_lookup_rule_writes_avg: $materialized_stats.setup_lookup_rule_writes.avg,
  policy_update_rule_writes_avg: $policy_stats.update_rule_writes.avg,
  baseline_update_rule_writes_avg: $materialized_stats.update_rule_writes.avg,
  policy_update_bytes_avg: $policy_stats.update_bytes.avg,
  baseline_update_bytes_avg: $materialized_stats.update_bytes.avg,
  missing_inputs: $missing_inputs,
  failed_gates: $failed_gates,
  inputs_sha256_file: $inputs_sha256,
  detail: (
    if $w4_c2_slice_supported then
      "W4 ccache release rows pass against materialized external baseline, but global C2 remains false until every workload ledger passes."
    elif $bulk_release_comparison_pass then
      "W4 bulk ccache release rows pass against materialized/FUSE/native external baselines and the attached compile smoke witness passes; nonbulk W4 still blocks global C2."
    else
      "W4 ccache release rows pass functionally, but materialized_cache_view is a stronger external baseline on this trace shape; bulk policy rows, compile smoke, and external baselines still do not pass every release comparison gate."
    end
  )
}
