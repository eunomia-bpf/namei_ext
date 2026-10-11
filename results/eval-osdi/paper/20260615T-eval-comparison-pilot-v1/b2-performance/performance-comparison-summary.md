# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-pilot-v1
- Phase 1 evidence run: 20260615T-kvm-bench-release-sample-pilot
- External baseline run: 20260615T-kvm-external-baselines-release-pilot
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-pilot-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=8.179414951245938
- min_policy_to_fuse_p99_speedup=1.448044680537433
- max_pass_only_to_native_p99_ratio=4.364632237871675
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C3 policy/FUSE 2x speedup threshold, C5 pass-only residual overhead threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.3848462115528881, policy/fuse_speedup=76.89219934994583, pass_only/native_p99=2.615153788447112, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- lookup_tool_redirect: policy/native_p99=1.5773615635179152, policy/fuse_speedup=44.774909654104285, pass_only/native_p99=2.517915309446254, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- access_tool_redirect: policy/native_p99=7.948356807511737, policy/fuse_speedup=7.810001968891514, pass_only/native_p99=4.364632237871675, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- open_tool_redirect: policy/native_p99=1.496365968362548, policy/fuse_speedup=51.46828571428571, pass_only/native_p99=2.330483112441214, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- exec_tool_redirect: policy/native_p99=1.1546625061068823, policy/fuse_speedup=1.448044680537433, pass_only/native_p99=1.2497218413628985, kernel_pass=true, fuse_pass=false, pass_only_pass=false
- readdir_alias_view: policy/native_p99=8.179414951245938, policy/fuse_speedup=3.556161915863092, pass_only/native_p99=2.0158179848320694, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- build_tree_stat_walk: policy/native_p99=1.734529110999546, policy/fuse_speedup=73.48920055607516, pass_only/native_p99=2.516937081422604, kernel_pass=false, fuse_pass=true, pass_only_pass=false
