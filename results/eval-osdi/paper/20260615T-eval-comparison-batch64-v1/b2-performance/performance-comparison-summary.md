# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-batch64-v1
- Phase 1 evidence run: 20260615T-kvm-bench-release-batch64-v1
- External baseline run: 20260615T-kvm-external-baselines-batch64-v1
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-batch64-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- internal_latency_batch=true
- external_latency_batch=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=1.7707235948160134
- min_policy_to_fuse_p99_speedup=1.3266464890872356
- max_pass_only_to_native_p99_ratio=1.7116490077691868
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C3 policy/FUSE 2x speedup threshold, C5 pass-only residual overhead threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.289159672363232, policy/fuse_speedup=51.82935247283994, pass_only/native_p99=1.4113661644251188, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- lookup_tool_redirect: policy/native_p99=1.5133756635786406, policy/fuse_speedup=45.63370933351675, pass_only/native_p99=1.4604455084833976, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- access_tool_redirect: policy/native_p99=1.4956020812685829, policy/fuse_speedup=54.38314350797266, pass_only/native_p99=1.6072224975222993, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- open_tool_redirect: policy/native_p99=1.1076594108884725, policy/fuse_speedup=39.81001236362059, pass_only/native_p99=1.0488203353995482, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- exec_tool_redirect: policy/native_p99=1.0824071849810653, policy/fuse_speedup=1.3266464890872356, pass_only/native_p99=1.1184140922622603, kernel_pass=true, fuse_pass=false, pass_only_pass=false
- readdir_alias_view: policy/native_p99=1.2255142605586833, policy/fuse_speedup=19.545277411910696, pass_only/native_p99=1.2247138550198768, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- build_tree_stat_walk: policy/native_p99=1.7707235948160134, policy/fuse_speedup=77.87577735780913, pass_only/native_p99=1.7116490077691868, kernel_pass=false, fuse_pass=true, pass_only_pass=false
