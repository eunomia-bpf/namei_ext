def ev($xs; $name): ([ $xs[] | select(.event == $name) ] | first // {});
def oracle_rows($xs; $event; $policy; $op):
  [ $xs[]
    | select(.event == $event and .policy == $policy and .op == $op)
    | select((.workload // "") != "" and (.branch // "") != "")
  ];
def entry_key:
  [(.workload // ""), (.branch // ""), (.visible // ""), (.effective_shadow // "")];
def entry_keys($rows): [ $rows[] | entry_key ];
def unique_keys($rows): (entry_keys($rows) | unique | sort);
def duplicate_keys($rows):
  entry_keys($rows)
  | group_by(.)
  | map(select(length > 1) | .[0]);
def keys_minus($left; $right):
  [ $left[] as $key | if any($right[]; . == $key) then empty else $key end ];
def failed_rows($xs; $event; $policy):
  [ $xs[] | select(.event == $event and .policy == $policy and (.pass != true)) ];
def matrix_row($xs; $event; $summary_event; $family; $policy; $workloads):
  ev($xs; $summary_event) as $summary |
  oracle_rows($xs; $event; $policy; "lookup") as $lookups |
  oracle_rows($xs; $event; $policy; "readdir") as $readdirs |
  unique_keys($lookups) as $lookup_keys |
  unique_keys($readdirs) as $readdir_keys |
  duplicate_keys($lookups) as $duplicate_lookup_keys |
  duplicate_keys($readdirs) as $duplicate_readdir_keys |
  keys_minus($lookup_keys; $readdir_keys) as $lookup_only_keys |
  keys_minus($readdir_keys; $lookup_keys) as $readdir_only_keys |
  failed_rows($xs; $event; $policy) as $failures |
  ($summary.entries // 0) as $entries |
  ($summary.pass == true and
   ($summary.failures // 1) == 0 and
   ($lookups | length) == $entries and
   ($readdirs | length) == $entries and
   ($lookup_keys | length) == $entries and
   ($readdir_keys | length) == $entries and
   ($duplicate_lookup_keys | length) == 0 and
   ($duplicate_readdir_keys | length) == 0 and
   ($lookup_only_keys | length) == 0 and
   ($readdir_only_keys | length) == 0 and
   ($failures | length) == 0) as $pass |
  {
    schema: "namei_ext.eval_osdi.c4_lookup_readdir_matrix.v1",
    event: "eval-osdi-c4-lookup-readdir-matrix",
    run_id: $run_id,
    result_level: "paper_c4_lookup_readdir_matrix",
    phase1_run_id: $phase1_run_id,
    family: $family,
    policy: $policy,
    workloads: $workloads,
    oracle_event: $event,
    summary_event: $summary_event,
    entries: $entries,
    lookup_rows: ($lookups | length),
    readdir_rows: ($readdirs | length),
    lookup_unique_keys: ($lookup_keys | length),
    readdir_unique_keys: ($readdir_keys | length),
    duplicate_lookup_keys: ($duplicate_lookup_keys | length),
    duplicate_readdir_keys: ($duplicate_readdir_keys | length),
    lookup_only_keys: $lookup_only_keys,
    readdir_only_keys: $readdir_only_keys,
    failed_rows: ($failures | length),
    summary_pass: ($summary.pass == true),
    summary_failures: ($summary.failures // null),
    lookup_readdir_matrix_pass: $pass,
    release_gate_pass: $pass,
    supporting_paths: [
      (if $family == "build_graph" then $w1_json
       elif $family == "sandbox_fixture" then $w2_json
       elif $family == "checkpoint_restore" then $w3_json
       else $w4_json end)
    ],
    scope_boundary: "declared Phase 1 workload oracle entries only; not a proof of all possible path-resolution behavior"
  };

[
  matrix_row($w1; "w1-oracle"; "w1-oracle-summary"; "build_graph"; "build_graph"; ["w1-redis-build", "w1-nginx-build"]),
  matrix_row($w2; "w2-oracle"; "w2-oracle-summary"; "sandbox_fixture"; "sandbox_fixture"; ["w2-nginx-fixture", "w2-postgres-secret-fixture"]),
  matrix_row($w3; "w3-oracle"; "w3-oracle-summary"; "checkpoint_restore"; "checkpoint_restore"; ["w3-redis-checkpoint-fixture", "w3-nginx-checkpoint-fixture"]),
  matrix_row($w4; "w4-oracle"; "w4-oracle-summary"; "cache_locality"; "cache_locality"; ["w4-ccache-redis-nginx", "w4-buildkit-prometheus-go-cache"])
] as $rows |
($rows | map(.entries) | add) as $entries |
($rows | map(.lookup_rows) | add) as $lookup_rows |
($rows | map(.readdir_rows) | add) as $readdir_rows |
($rows | map(.lookup_unique_keys) | add) as $lookup_unique_keys |
($rows | map(.readdir_unique_keys) | add) as $readdir_unique_keys |
($rows | map(.duplicate_lookup_keys) | add) as $duplicate_lookup_keys |
($rows | map(.duplicate_readdir_keys) | add) as $duplicate_readdir_keys |
($rows | map(.lookup_only_keys | length) | add) as $lookup_only_key_count |
($rows | map(.readdir_only_keys | length) | add) as $readdir_only_key_count |
($rows | map(select(.lookup_readdir_matrix_pass == true)) | length) as $passing_families |
$rows[],
{
  schema: "namei_ext.eval_osdi.c4_lookup_readdir_matrix.v1",
  event: "eval-osdi-c4-lookup-readdir-matrix-summary",
  run_id: $run_id,
  result_level: "paper_c4_lookup_readdir_matrix",
  phase1_run_id: $phase1_run_id,
  families: ($rows | length),
  required_families: 4,
  passing_families: $passing_families,
  entries: $entries,
  lookup_rows: $lookup_rows,
  readdir_rows: $readdir_rows,
  lookup_unique_keys: $lookup_unique_keys,
  readdir_unique_keys: $readdir_unique_keys,
  duplicate_lookup_keys: $duplicate_lookup_keys,
  duplicate_readdir_keys: $duplicate_readdir_keys,
  lookup_only_key_count: $lookup_only_key_count,
  readdir_only_key_count: $readdir_only_key_count,
  c4_supported: ($passing_families == 4 and $entries > 0 and $lookup_rows == $entries and $readdir_rows == $entries and $lookup_unique_keys == $entries and $readdir_unique_keys == $entries and $duplicate_lookup_keys == 0 and $duplicate_readdir_keys == 0 and $lookup_only_key_count == 0 and $readdir_only_key_count == 0),
  release_gate_pass: ($passing_families == 4 and $entries > 0 and $lookup_rows == $entries and $readdir_rows == $entries and $lookup_unique_keys == $entries and $readdir_unique_keys == $entries and $duplicate_lookup_keys == 0 and $duplicate_readdir_keys == 0 and $lookup_only_key_count == 0 and $readdir_only_key_count == 0),
  scope: "declared_w1_w4_phase1_lookup_readdir_matrix",
  missing_evidence: (if ($passing_families == 4 and $entries > 0 and $lookup_rows == $entries and $readdir_rows == $entries and $lookup_unique_keys == $entries and $readdir_unique_keys == $entries and $duplicate_lookup_keys == 0 and $duplicate_readdir_keys == 0 and $lookup_only_key_count == 0 and $readdir_only_key_count == 0)
    then []
    else ["complete identity-matched pass for W1-W4 declared lookup/readdir oracle matrix"]
    end),
  scope_boundaries: [
    "matrix covers declared W1-W4 Phase 1 oracle entries",
    "matrix does not prove C8 table-only insufficiency",
    "matrix does not replace real workload correctness gates"
  ],
  inputs_sha256_file: $inputs_sha256
}
