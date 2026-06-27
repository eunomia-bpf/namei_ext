def ev($rows; $name):
  ($rows | map(select(.event == $name)) | first // {});

def count_ev_baseline($rows; $name; $baseline):
  ($rows | map(select(.event == $name and .baseline == $baseline)) | length);

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

ev($policy; "w3-redis-policy-macrobench-summary") as $ps |
ev($baseline; "w3-redis-baseline-macrobench-summary") as $bs |
([$baseline[] | select(.event == "w3-redis-baseline-macrobench-setup") | .baseline] | unique) as $baseline_names |
($ps.pass == true and
 $ps.samples >= $required_samples and
 $ps.systems == 1 and
 $ps.setup_rows == $ps.samples and
 $ps.update_rows == $ps.samples and
 $ps.correctness_rows == $ps.samples and
 $ps.policy_executed == true) as $policy_release_input_pass |
($bs.pass == true and
 $bs.samples >= $required_samples and
 $bs.setup_rows == ($bs.samples * $bs.baseline_count) and
 $bs.update_rows == ($bs.samples * $bs.baseline_count) and
 $bs.correctness_rows == ($bs.samples * $bs.baseline_count) and
 $bs.policy_executed == false and
 $bs.feature_equivalent_baseline == true) as $baseline_release_input_pass |
($baseline_names | index("materialized_checkpoint_view") != null) as $materialized_baseline_pass |
($baseline_names | index("fuse_redirect") != null) as $fuse_baseline_pass |
($materialized_baseline_pass and $fuse_baseline_pass) as $implemented_external_baselines_pass |
{
  setup_ns: metric_stats($policy; "w3-redis-policy-macrobench-setup"; .setup_ns),
  update_ns: metric_stats($policy; "w3-redis-policy-macrobench-update"; .update_ns),
  setup_objects: metric_stats($policy; "w3-redis-policy-macrobench-setup"; setup_objects),
  setup_bytes: metric_stats($policy; "w3-redis-policy-macrobench-setup"; setup_bytes),
  update_writes: metric_stats($policy; "w3-redis-policy-macrobench-update"; total_update_writes),
  materialization_update_writes: metric_stats($policy; "w3-redis-policy-macrobench-update"; materialization_update_writes),
  update_bytes: metric_stats($policy; "w3-redis-policy-macrobench-update"; update_bytes)
} as $policy_stats |
($baseline_names | map(. as $b | {
  baseline: $b,
  setup_ns: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-setup"; $b; .setup_ns),
  update_ns: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-update"; $b; .update_ns),
  setup_objects: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-setup"; $b; setup_objects),
  setup_bytes: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-setup"; $b; setup_bytes),
  update_writes: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-update"; $b; total_update_writes),
  materialization_update_writes: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-update"; $b; materialization_update_writes),
  update_bytes: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-update"; $b; update_bytes),
  fuse_mounts: metric_stats_baseline($baseline; "w3-redis-baseline-macrobench-setup"; $b; (.fuse_mounts // 0))
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
 $implemented_external_baselines_pass and
 $storage_footprint_pass and
 $threshold_pass) as $w3_c2_slice_supported |
{
  schema: "namei_ext.eval_osdi.w3_redis_workload_macrobench.v1",
  event: "eval-osdi-w3-redis-workload-macrobench",
  run_id: $run_id,
  workload_id: "w3-redis-podman-criu",
  row_kind: "proposed_system",
  policy_family: "checkpoint_restore_view.bpf.c",
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
    schema: "namei_ext.eval_osdi.w3_redis_workload_macrobench.v1",
    event: "eval-osdi-w3-redis-workload-macrobench",
    run_id: $run_id,
    workload_id: "w3-redis-podman-criu",
    row_kind: "external_baseline",
    baseline: $s.baseline,
    baseline_run_id: $baseline_run_id,
    source_json: $baseline_json,
    samples: ($bs.samples // 0),
    setup_rows: count_ev_baseline($baseline; "w3-redis-baseline-macrobench-setup"; $s.baseline),
    update_rows: count_ev_baseline($baseline; "w3-redis-baseline-macrobench-update"; $s.baseline),
    correctness_rows: count_ev_baseline($baseline; "w3-redis-baseline-macrobench-correctness"; $s.baseline),
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
    fuse_mounts_avg: $s.fuse_mounts.avg,
    pass: ([$baseline[] | select(.event == "w3-redis-baseline-macrobench-correctness" and .baseline == $s.baseline and .pass != true)] | length == 0),
    release_input_pass: ($baseline_release_input_pass and count_ev_baseline($baseline; "w3-redis-baseline-macrobench-correctness"; $s.baseline) == $bs.samples),
    policy_executed: false,
    kvm_validated: true
  }),
{
  schema: "namei_ext.eval_osdi.w3_redis_workload_macrobench.v1",
  event: "eval-osdi-w3-redis-workload-macrobench-summary",
  run_id: $run_id,
  workload_id: "w3-redis-podman-criu",
  result_level: "w3_workload_kvm_macrobench_thresholded_slice",
  required_samples: $required_samples,
  policy_run_id: $policy_run_id,
  baseline_run_id: $baseline_run_id,
  policy_release_input_pass: $policy_release_input_pass,
  baseline_release_input_pass: $baseline_release_input_pass,
  materialized_baseline_pass: $materialized_baseline_pass,
  fuse_baseline_pass: $fuse_baseline_pass,
  implemented_external_baselines_pass: $implemented_external_baselines_pass,
  full_feature_equivalent_baseline_pass: $implemented_external_baselines_pass,
  baseline_count_observed: ($baseline_names | length),
  required_baseline_families: ["materialized_checkpoint_view", "fuse_redirect"],
  storage_footprint_pass: $storage_footprint_pass,
  setup_latency_threshold_pass: $setup_latency_threshold_pass,
  update_latency_threshold_pass: $update_latency_threshold_pass,
  update_materialization_threshold_pass: $update_materialization_threshold_pass,
  threshold_pass: $threshold_pass,
  w3_c2_slice_supported: $w3_c2_slice_supported,
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
    (if $fuse_baseline_pass then empty else "W3 FUSE checkpoint baseline" end),
    (if $storage_footprint_pass then empty else "W3 storage footprint aggregation" end),
    (if $threshold_pass then empty else "W3 C2 setup/update success thresholds" end),
    "real Podman/CRIU restore and second W3 checkpoint workload remain C8/C1 blockers"
  ],
  failed_gates: [
    (if $setup_latency_threshold_pass then empty else "W3 setup latency threshold failed against best external baseline" end),
    (if $update_latency_threshold_pass then empty else "W3 update latency threshold failed against best external baseline" end),
    (if $update_materialization_threshold_pass then empty else "W3 update materialization threshold failed against external baseline" end)
  ],
  inputs_sha256_file: $inputs_sha256,
  detail: (
    if $w3_c2_slice_supported then
      "W3 Redis has KVM proposed-system rows plus materialized and FUSE external baselines; global C2 remains false until all workloads pass."
    else
      "W3 Redis now has KVM proposed-system rows plus materialized and FUSE external baseline rows, but its thresholded C2 slice is not supported."
    end
  )
}
