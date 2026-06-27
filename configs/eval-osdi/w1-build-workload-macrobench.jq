def ev($rows; $name):
  ($rows | map(select(.event == $name)) | first // {});

def count_ev_baseline($rows; $name; $baseline):
  ($rows | map(select(.event == $name and .baseline == $baseline)) | length);

def count_w1_fuse_correctness_test_rows($rows):
  ($rows | map(select(.event == "w1-build-baseline-correctness" and
                      .baseline == "fuse_redirect" and
                      .pass == true and
                      (.visible_aliases // 0) > 0 and
                      (.alias_parent_dirs // 0) > 0 and
                      (.fuse_mounts // 0) == (.alias_parent_dirs // -1) and
                      (.materialized_output_hash_match // false) == true and
                      (.post_update_output_hash_match // false) == true)) | length);

def avg($xs):
  if ($xs | length) > 0 then (($xs | add) / ($xs | length)) else 0 end;

def stat($xs):
  {
    min: ($xs | min // 0),
    max: ($xs | max // 0),
    avg: avg($xs)
  };

def setup_objects:
  ((.created_dirs // 0) + (.created_files // 0) + (.created_symlinks // 0) +
   (.bind_mounts // 0) + (.fuse_mounts // 0));

def setup_bytes:
  ((.bytes_written // 0) + (.bytes_copied // 0));

def total_update_writes:
  ((.source_update_writes // 0) + (.baseline_update_writes // 0) +
   (.policy_update_writes // 0));

def materialization_update_writes:
  ((.baseline_update_writes // 0) + (.policy_update_writes // 0));

def update_bytes:
  ((.update_bytes_written // 0) + (.update_bytes_copied // 0));

def metric_stats($rows; $event; metric):
  stat([$rows[] | select(.event == $event) | metric]);

def metric_stats_baseline($rows; $event; $baseline; metric):
  stat([$rows[] | select(.event == $event and .baseline == $baseline) | metric]);

ev($policy; "w1-build-macrobench-summary") as $ps |
ev($baseline; "w1-build-baseline-summary") as $bs |
ev($fuse_test; "w1-build-baseline-summary") as $fs |
([$baseline[] | select(.event == "w1-build-baseline-setup") | .baseline] | unique) as $baseline_names |
($ps.pass == true and
 $ps.samples >= $required_samples and
 $ps.setup_rows == $ps.samples and
 $ps.update_rows == $ps.samples and
 $ps.correctness_rows == $ps.samples) as $policy_release_input_pass |
($bs.pass == true and
 $bs.samples >= $required_samples and
 $bs.setup_rows == ($bs.samples * $bs.baseline_count) and
 $bs.update_rows == ($bs.samples * $bs.baseline_count) and
 $bs.correctness_rows == ($bs.samples * $bs.baseline_count)) as $baseline_release_input_pass |
($baseline_names | index("copy_tree") != null) as $copy_tree_baseline_pass |
($baseline_names | index("symlink_forest") != null) as $symlink_forest_baseline_pass |
($baseline_names | index("bind_mount") != null) as $bind_mount_baseline_pass |
($baseline_names | index("projected_volume") != null) as $projected_volume_baseline_pass |
($baseline_names | index("fuse_redirect") != null) as $fuse_baseline_observed |
($fs.pass == true and
 $fs.samples >= $required_samples and
 (($fs.selected_baselines // "") | contains("fuse_redirect")) and
 $fs.setup_rows == $fs.samples and
 $fs.update_rows == $fs.samples and
 $fs.correctness_rows == $fs.samples) as $fuse_test_release_input_pass |
(count_w1_fuse_correctness_test_rows($fuse_test)) as $fuse_correctness_test_rows |
($fuse_test_release_input_pass and
 $fuse_correctness_test_rows == ($fs.samples // 0)) as $fuse_correctness_test_pass |
($fuse_baseline_observed and $fuse_correctness_test_pass) as $fuse_baseline_pass |
($copy_tree_baseline_pass and $symlink_forest_baseline_pass and
 $bind_mount_baseline_pass) as $implemented_feature_baselines_pass |
($implemented_feature_baselines_pass and $projected_volume_baseline_pass and
 $fuse_baseline_pass) as $full_feature_equivalent_baseline_pass |
{
  setup_ns: metric_stats($policy; "w1-build-macrobench-setup"; .setup_ns),
  source_copy_ns: metric_stats($policy; "w1-build-macrobench-setup"; .source_copy_ns),
  update_ns: metric_stats($policy; "w1-build-macrobench-update"; .update_ns),
  setup_objects: metric_stats($policy; "w1-build-macrobench-setup"; setup_objects),
  setup_bytes: metric_stats($policy; "w1-build-macrobench-setup"; setup_bytes),
  update_writes: metric_stats($policy; "w1-build-macrobench-update"; total_update_writes),
  materialization_update_writes: metric_stats($policy; "w1-build-macrobench-update"; materialization_update_writes),
  update_bytes: metric_stats($policy; "w1-build-macrobench-update"; update_bytes)
} as $policy_stats |
($baseline_names | map(. as $b | {
  baseline: $b,
  setup_ns: metric_stats_baseline($baseline; "w1-build-baseline-setup"; $b; .setup_ns),
  source_copy_ns: metric_stats_baseline($baseline; "w1-build-baseline-setup"; $b; .source_copy_ns),
  update_ns: metric_stats_baseline($baseline; "w1-build-baseline-update"; $b; .update_ns),
  setup_objects: metric_stats_baseline($baseline; "w1-build-baseline-setup"; $b; setup_objects),
  setup_bytes: metric_stats_baseline($baseline; "w1-build-baseline-setup"; $b; setup_bytes),
  update_writes: metric_stats_baseline($baseline; "w1-build-baseline-update"; $b; total_update_writes),
  materialization_update_writes: metric_stats_baseline($baseline; "w1-build-baseline-update"; $b; materialization_update_writes),
  update_bytes: metric_stats_baseline($baseline; "w1-build-baseline-update"; $b; update_bytes),
  visible_aliases: metric_stats_baseline($baseline; "w1-build-baseline-correctness"; $b; (.visible_aliases // 0)),
  alias_parent_dirs: metric_stats_baseline($baseline; "w1-build-baseline-correctness"; $b; (.alias_parent_dirs // 0)),
  correctness_fuse_mounts: metric_stats_baseline($baseline; "w1-build-baseline-correctness"; $b; (.fuse_mounts // 0))
})) as $baseline_stats |
{
  visible_aliases: metric_stats_baseline($fuse_test; "w1-build-baseline-correctness"; "fuse_redirect"; (.visible_aliases // 0)),
  alias_parent_dirs: metric_stats_baseline($fuse_test; "w1-build-baseline-correctness"; "fuse_redirect"; (.alias_parent_dirs // 0)),
  correctness_fuse_mounts: metric_stats_baseline($fuse_test; "w1-build-baseline-correctness"; "fuse_redirect"; (.fuse_mounts // 0))
} as $fuse_test_stats |
([$baseline_stats[].setup_ns.avg] | min // 0) as $best_baseline_setup_ns_avg |
([$baseline_stats[].update_ns.avg] | min // 0) as $best_baseline_update_ns_avg |
([$baseline_stats[].setup_objects.avg] | min // 0) as $min_baseline_setup_objects_avg |
([$baseline_stats[].setup_bytes.avg] | min // 0) as $min_baseline_setup_bytes_avg |
([$baseline_stats[].update_writes.avg] | min // 0) as $min_baseline_update_writes_avg |
([$baseline_stats[].materialization_update_writes.avg] | min // 0) as $min_baseline_materialization_update_writes_avg |
([$baseline_stats[].update_bytes.avg] | min // 0) as $min_baseline_update_bytes_avg |
($policy_stats.setup_objects.avg <= $min_baseline_setup_objects_avg and
 $policy_stats.setup_bytes.avg <= $min_baseline_setup_bytes_avg) as $storage_footprint_pass |
($policy_stats.setup_ns.avg <= $best_baseline_setup_ns_avg) as $setup_latency_threshold_pass |
($policy_stats.update_ns.avg <= $best_baseline_update_ns_avg) as $update_latency_threshold_pass |
($policy_stats.update_writes.avg <= $min_baseline_update_writes_avg and
 $policy_stats.materialization_update_writes.avg <= $min_baseline_materialization_update_writes_avg and
 $policy_stats.update_bytes.avg <= $min_baseline_update_bytes_avg) as $update_materialization_threshold_pass |
($setup_latency_threshold_pass and
 $update_latency_threshold_pass and
 $update_materialization_threshold_pass) as $threshold_pass |
($policy_release_input_pass and
 $baseline_release_input_pass and
 $full_feature_equivalent_baseline_pass and
 $storage_footprint_pass and
 $threshold_pass) as $w1_c2_slice_supported |
[
  (if $policy_release_input_pass then empty else "W1 proposed-system release input" end),
  (if $baseline_release_input_pass then empty else "W1 feature baseline release input" end),
  (if $projected_volume_baseline_pass then empty else "W1 projected-volume baseline" end),
  (if $fuse_baseline_pass then empty else "W1 FUSE baseline correctness test" end),
  "W3/W4 workload setup/storage/update macrobench"
] as $missing_inputs |
[
  (if $storage_footprint_pass then empty else "W1 storage footprint gate failed" end),
  (if $setup_latency_threshold_pass then empty else "W1 setup latency threshold failed" end),
  (if $update_latency_threshold_pass then empty else "W1 update latency threshold failed" end),
  (if $update_materialization_threshold_pass then empty else "W1 update materialization threshold failed" end)
] as $failed_gates |
{
  schema: "namei_ext.eval_osdi.w1_build_workload_macrobench.v1",
  event: "eval-osdi-w1-build-workload-macrobench",
  run_id: $run_id,
  workload_id: "w1-build-graph",
  row_kind: "proposed_system",
  policy_family: "build_graph_view.bpf.c",
  policy_run_id: $policy_run_id,
  source_json: $policy_json,
  samples: ($ps.samples // 0),
  setup_rows: ($ps.setup_rows // 0),
  update_rows: ($ps.update_rows // 0),
  correctness_rows: ($ps.correctness_rows // 0),
  pass: ($ps.pass // false),
  failures: ($ps.failures // 1),
  release_input_pass: $policy_release_input_pass,
  setup_ns_avg: $policy_stats.setup_ns.avg,
  source_copy_ns_avg: $policy_stats.source_copy_ns.avg,
  update_ns_avg: $policy_stats.update_ns.avg,
  setup_objects_avg: $policy_stats.setup_objects.avg,
  setup_bytes_avg: $policy_stats.setup_bytes.avg,
  update_writes_avg: $policy_stats.update_writes.avg,
  materialization_update_writes_avg: $policy_stats.materialization_update_writes.avg,
  update_bytes_avg: $policy_stats.update_bytes.avg,
  policy_executed: true,
  kvm_validated: true
},
($baseline_stats[] as $s |
  {
    schema: "namei_ext.eval_osdi.w1_build_workload_macrobench.v1",
    event: "eval-osdi-w1-build-workload-macrobench",
    run_id: $run_id,
    workload_id: "w1-build-graph",
    row_kind: "feature_baseline",
    baseline: $s.baseline,
    baseline_run_id: $baseline_run_id,
    source_json: $baseline_json,
    samples: ($bs.samples // 0),
    setup_rows: count_ev_baseline($baseline; "w1-build-baseline-setup"; $s.baseline),
    update_rows: count_ev_baseline($baseline; "w1-build-baseline-update"; $s.baseline),
    correctness_rows: count_ev_baseline($baseline; "w1-build-baseline-correctness"; $s.baseline),
    setup_ns_min: $s.setup_ns.min,
    setup_ns_max: $s.setup_ns.max,
    setup_ns_avg: $s.setup_ns.avg,
    source_copy_ns_avg: $s.source_copy_ns.avg,
    update_ns_min: $s.update_ns.min,
    update_ns_max: $s.update_ns.max,
    update_ns_avg: $s.update_ns.avg,
    setup_objects_avg: $s.setup_objects.avg,
    setup_bytes_avg: $s.setup_bytes.avg,
    update_writes_avg: $s.update_writes.avg,
    materialization_update_writes_avg: $s.materialization_update_writes.avg,
    update_bytes_avg: $s.update_bytes.avg,
    visible_aliases_avg: (if $s.baseline == "fuse_redirect" then $fuse_test_stats.visible_aliases.avg else $s.visible_aliases.avg end),
    alias_parent_dirs_avg: (if $s.baseline == "fuse_redirect" then $fuse_test_stats.alias_parent_dirs.avg else $s.alias_parent_dirs.avg end),
    correctness_fuse_mounts_avg: (if $s.baseline == "fuse_redirect" then $fuse_test_stats.correctness_fuse_mounts.avg else $s.correctness_fuse_mounts.avg end),
    fuse_correctness_test_run_id: (if $s.baseline == "fuse_redirect" then $fuse_test_run_id else null end),
    fuse_correctness_test_pass: (if $s.baseline == "fuse_redirect" then $fuse_correctness_test_pass else null end),
    pass: ([$baseline[] | select(.event == "w1-build-baseline-correctness" and .baseline == $s.baseline and .pass != true)] | length == 0),
    release_input_pass: ($baseline_release_input_pass and count_ev_baseline($baseline; "w1-build-baseline-correctness"; $s.baseline) == $bs.samples),
    policy_executed: false,
    kvm_validated: true
  }),
{
  schema: "namei_ext.eval_osdi.w1_build_workload_macrobench.v1",
  event: "eval-osdi-w1-build-workload-macrobench-summary",
  run_id: $run_id,
  workload_id: "w1-build-graph",
  result_level: "w1_workload_kvm_macrobench_thresholded_slice",
  required_samples: $required_samples,
  policy_run_id: $policy_run_id,
  baseline_run_id: $baseline_run_id,
  fuse_test_run_id: $fuse_test_run_id,
  policy_release_input_pass: $policy_release_input_pass,
  baseline_release_input_pass: $baseline_release_input_pass,
  copy_tree_baseline_pass: $copy_tree_baseline_pass,
  symlink_forest_baseline_pass: $symlink_forest_baseline_pass,
  bind_mount_baseline_pass: $bind_mount_baseline_pass,
  projected_volume_baseline_pass: $projected_volume_baseline_pass,
  fuse_test_release_input_pass: $fuse_test_release_input_pass,
  fuse_correctness_test_rows: $fuse_correctness_test_rows,
  fuse_correctness_test_pass: $fuse_correctness_test_pass,
  fuse_baseline_pass: $fuse_baseline_pass,
  implemented_feature_baselines_pass: $implemented_feature_baselines_pass,
  required_baseline_families: ["copy_tree", "symlink_forest", "bind_mount", "projected_volume", "fuse_redirect"],
  full_feature_equivalent_baseline_pass: $full_feature_equivalent_baseline_pass,
  baseline_count_observed: ($baseline_names | length),
  storage_footprint_pass: $storage_footprint_pass,
  setup_latency_threshold_pass: $setup_latency_threshold_pass,
  update_latency_threshold_pass: $update_latency_threshold_pass,
  update_materialization_threshold_pass: $update_materialization_threshold_pass,
  threshold_pass: $threshold_pass,
  w1_c2_slice_supported: $w1_c2_slice_supported,
  c2_supported: false,
  release_gate_pass: false,
  policy_setup_ns_avg: $policy_stats.setup_ns.avg,
  policy_source_copy_ns_avg: $policy_stats.source_copy_ns.avg,
  policy_update_ns_avg: $policy_stats.update_ns.avg,
  policy_setup_objects_avg: $policy_stats.setup_objects.avg,
  policy_setup_bytes_avg: $policy_stats.setup_bytes.avg,
  policy_update_writes_avg: $policy_stats.update_writes.avg,
  policy_materialization_update_writes_avg: $policy_stats.materialization_update_writes.avg,
  policy_update_bytes_avg: $policy_stats.update_bytes.avg,
  best_baseline_setup_ns_avg: $best_baseline_setup_ns_avg,
  best_baseline_update_ns_avg: $best_baseline_update_ns_avg,
  min_baseline_setup_objects_avg: $min_baseline_setup_objects_avg,
  min_baseline_setup_bytes_avg: $min_baseline_setup_bytes_avg,
  min_baseline_update_writes_avg: $min_baseline_update_writes_avg,
  min_baseline_materialization_update_writes_avg: $min_baseline_materialization_update_writes_avg,
  min_baseline_update_bytes_avg: $min_baseline_update_bytes_avg,
  fuse_visible_aliases_avg: $fuse_test_stats.visible_aliases.avg,
  fuse_alias_parent_dirs_avg: $fuse_test_stats.alias_parent_dirs.avg,
  fuse_correctness_mounts_avg: $fuse_test_stats.correctness_fuse_mounts.avg,
  baseline_stats: $baseline_stats,
  missing_inputs: $missing_inputs,
  failed_gates: $failed_gates,
  missing_evidence: $missing_inputs,
  inputs_sha256_file: $inputs_sha256,
  detail: (
    if $w1_c2_slice_supported then
      "W1 has thresholded KVM proposed-system and full feature baseline rows; global C2 remains false until W3/W4 macrobench rows exist."
    else
      "W1 ledger preserves proposed-system and baseline rows, but W1 C2 slice is not yet supported."
    end
  )
}
