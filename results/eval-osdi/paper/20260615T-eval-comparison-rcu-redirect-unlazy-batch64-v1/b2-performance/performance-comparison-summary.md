# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1
- Phase 1 evidence run: 20260615T-kvm-bench-rcu-redirect-unlazy-batch64-v1
- External baseline run: 20260615T-kvm-external-baselines-rcu-redirect-unlazy-batch64-v1
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-redirect-unlazy-batch64-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- internal_latency_batch=true
- external_latency_batch=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=2.4300022634676326
- min_policy_to_fuse_p99_speedup=1.6982541279970493
- max_pass_only_to_native_p99_ratio=1.3752722505228923
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C3 policy/FUSE 2x speedup threshold, C5 pass-only residual overhead threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.5603403816400205, policy/fuse_speedup=28.540902330193358, pass_only/native_p99=0.946836857486677, kernel_pass=false, fuse_pass=true, pass_only_pass=true
- lookup_tool_redirect: policy/native_p99=1.3822345672014058, policy/fuse_speedup=46.29441437007874, pass_only/native_p99=1.3492432401791281, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- access_tool_redirect: policy/native_p99=2.4300022634676326, policy/fuse_speedup=23.434506205900846, pass_only/native_p99=1.0550588501584428, kernel_pass=false, fuse_pass=true, pass_only_pass=true
- open_tool_redirect: policy/native_p99=0.7891031708471368, policy/fuse_speedup=33.73386310817902, pass_only/native_p99=0.7845480359678183, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- exec_tool_redirect: policy/native_p99=0.9921376681760432, policy/fuse_speedup=1.6982541279970493, pass_only/native_p99=0.9398402123986057, kernel_pass=true, fuse_pass=false, pass_only_pass=true
- readdir_alias_view: policy/native_p99=1.2366414422756933, policy/fuse_speedup=19.786820798427485, pass_only/native_p99=1.2177593216905647, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- build_tree_stat_walk: policy/native_p99=1.479743705977806, policy/fuse_speedup=87.92912316167451, pass_only/native_p99=1.3752722505228923, kernel_pass=true, fuse_pass=true, pass_only_pass=false
