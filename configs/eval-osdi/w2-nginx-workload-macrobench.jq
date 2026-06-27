def ev($rows; $name):
  ($rows | map(select(.event == $name)) | first // {});

def count_ev_baseline($rows; $name; $baseline):
  ($rows | map(select(.event == $name and .baseline == $baseline)) | length);

def values_baseline($rows; $name; $baseline; $field):
  [$rows[] | select(.event == $name and .baseline == $baseline) | .[$field]];

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

ev($policy; "w2-nginx-macrobench-summary") as $ps |
ev($baseline; "w2-nginx-baseline-summary") as $bs |
([$baseline[] | select(.event == "w2-nginx-baseline-setup") | .baseline] | unique) as $baseline_names |
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
($baseline_names | index("copy_tree") != null and index("symlink_forest") != null) as $copy_symlink_baselines_pass |
($baseline_names | index("bind_mount") != null) as $bind_baseline_pass |
($baseline_names | index("projected_volume") != null) as $projected_volume_baseline_pass |
($baseline_names | index("fuse_redirect") != null) as $fuse_baseline_pass |
($copy_symlink_baselines_pass and $bind_baseline_pass) as $copy_symlink_bind_baselines_pass |
($copy_symlink_bind_baselines_pass and $projected_volume_baseline_pass) as $copy_symlink_bind_projected_baselines_pass |
($copy_symlink_bind_projected_baselines_pass and $fuse_baseline_pass) as $all_feature_baselines_pass |
{
  setup_ns: metric_stats($policy; "w2-nginx-macrobench-setup"; .setup_ns),
  update_ns: metric_stats($policy; "w2-nginx-macrobench-update"; .update_ns),
  setup_objects: metric_stats($policy; "w2-nginx-macrobench-setup"; setup_objects),
  setup_bytes: metric_stats($policy; "w2-nginx-macrobench-setup"; setup_bytes),
  update_writes: metric_stats($policy; "w2-nginx-macrobench-update"; total_update_writes),
  materialization_update_writes: metric_stats($policy; "w2-nginx-macrobench-update"; materialization_update_writes),
  update_bytes: metric_stats($policy; "w2-nginx-macrobench-update"; update_bytes)
} as $policy_stats |
($baseline_names | map(. as $b | {
  baseline: $b,
  setup_ns: metric_stats_baseline($baseline; "w2-nginx-baseline-setup"; $b; .setup_ns),
  update_ns: metric_stats_baseline($baseline; "w2-nginx-baseline-update"; $b; .update_ns),
  setup_objects: metric_stats_baseline($baseline; "w2-nginx-baseline-setup"; $b; setup_objects),
  setup_bytes: metric_stats_baseline($baseline; "w2-nginx-baseline-setup"; $b; setup_bytes),
  update_writes: metric_stats_baseline($baseline; "w2-nginx-baseline-update"; $b; total_update_writes),
  materialization_update_writes: metric_stats_baseline($baseline; "w2-nginx-baseline-update"; $b; materialization_update_writes),
  update_bytes: metric_stats_baseline($baseline; "w2-nginx-baseline-update"; $b; update_bytes)
})) as $baseline_stats |
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
 $all_feature_baselines_pass and
 $storage_footprint_pass and
 $threshold_pass) as $w2_c2_slice_supported |
{
  schema: "namei_ext.eval_osdi.w2_nginx_workload_macrobench.v1",
  event: "eval-osdi-w2-nginx-workload-macrobench",
  run_id: $run_id,
  workload_id: "w2-nginx-fixture",
  row_kind: "proposed_system",
  policy_family: "sandbox_fixture_view.bpf.c",
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
    schema: "namei_ext.eval_osdi.w2_nginx_workload_macrobench.v1",
    event: "eval-osdi-w2-nginx-workload-macrobench",
    run_id: $run_id,
    workload_id: "w2-nginx-fixture",
    row_kind: "feature_baseline",
    baseline: $s.baseline,
    baseline_run_id: $baseline_run_id,
    source_json: $baseline_json,
    samples: ($bs.samples // 0),
    setup_rows: count_ev_baseline($baseline; "w2-nginx-baseline-setup"; $s.baseline),
    update_rows: count_ev_baseline($baseline; "w2-nginx-baseline-update"; $s.baseline),
    correctness_rows: count_ev_baseline($baseline; "w2-nginx-baseline-correctness"; $s.baseline),
    setup_ns_min: $s.setup_ns.min,
    setup_ns_max: $s.setup_ns.max,
    setup_ns_avg: $s.setup_ns.avg,
    update_ns_min: $s.update_ns.min,
    update_ns_max: $s.update_ns.max,
    update_ns_avg: $s.update_ns.avg,
    setup_objects_avg: $s.setup_objects.avg,
    setup_bytes_avg: $s.setup_bytes.avg,
    update_writes_avg: $s.update_writes.avg,
    materialization_update_writes_avg: $s.materialization_update_writes.avg,
    update_bytes_avg: $s.update_bytes.avg,
    pass: ([$baseline[] | select(.event == "w2-nginx-baseline-correctness" and .baseline == $s.baseline and .pass != true)] | length == 0),
    release_input_pass: ($baseline_release_input_pass and count_ev_baseline($baseline; "w2-nginx-baseline-correctness"; $s.baseline) == $bs.samples),
    policy_executed: false,
    kvm_validated: true
  }),
{
  schema: "namei_ext.eval_osdi.w2_nginx_workload_macrobench.v1",
  event: "eval-osdi-w2-nginx-workload-macrobench-summary",
  run_id: $run_id,
  workload_id: "w2-nginx-fixture",
  result_level: "w2_workload_kvm_macrobench_thresholded_slice",
  required_samples: $required_samples,
  policy_run_id: $policy_run_id,
  baseline_run_id: $baseline_run_id,
  policy_release_input_pass: $policy_release_input_pass,
  baseline_release_input_pass: $baseline_release_input_pass,
  copy_symlink_baselines_pass: $copy_symlink_baselines_pass,
  bind_baseline_pass: $bind_baseline_pass,
  projected_volume_baseline_pass: $projected_volume_baseline_pass,
  fuse_baseline_pass: $fuse_baseline_pass,
  copy_symlink_bind_baselines_pass: $copy_symlink_bind_baselines_pass,
  copy_symlink_bind_projected_baselines_pass: $copy_symlink_bind_projected_baselines_pass,
  all_feature_baselines_pass: $all_feature_baselines_pass,
  baseline_count_observed: ($baseline_names | length),
  required_baseline_families: ["copy_tree", "symlink_forest", "bind_mount", "projected_volume", "fuse_redirect"],
  full_feature_equivalent_baseline_pass: $all_feature_baselines_pass,
  storage_footprint_pass: $storage_footprint_pass,
  setup_latency_threshold_pass: $setup_latency_threshold_pass,
  update_latency_threshold_pass: $update_latency_threshold_pass,
  update_materialization_threshold_pass: $update_materialization_threshold_pass,
  threshold_pass: $threshold_pass,
  w2_c2_slice_supported: $w2_c2_slice_supported,
  c2_supported: false,
  release_gate_pass: false,
  policy_setup_ns_avg: $policy_stats.setup_ns.avg,
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
  baseline_stats: $baseline_stats,
  missing_evidence: [
    (if $fuse_baseline_pass then empty else "FUSE W2 baseline" end),
    (if $storage_footprint_pass then empty else "W2 storage footprint aggregation" end),
    (if $threshold_pass then empty else "W2 C2 setup/storage/update success thresholds" end),
    "W1/W3/W4 workload setup/storage/update macrobench"
  ],
  inputs_sha256_file: $inputs_sha256,
  detail: (
    if $w2_c2_slice_supported then
      "W2 has thresholded KVM proposed-system rows and five feature baseline rows; global C2 remains false until W1/W3/W4 macrobench rows exist."
    else
      "W2 has KVM proposed-system rows plus feature baseline rows, but the W2 storage/threshold slice is not yet supported."
    end
  )
}
