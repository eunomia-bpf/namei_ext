# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-ctx-init-split-tail10-v1
- Phase 1 evidence run: 20260615T-kvm-bench-ctx-init-split-tail10-v1
- External baseline run: 20260615T-kvm-external-baselines-ctx-init-split-tail10-v1
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-tail10-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- internal_latency_batch=true
- external_latency_batch=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=4.373989449932007
- min_policy_to_fuse_p99_speedup=2.2578242999873592
- max_pass_only_to_native_p99_ratio=2.624059316157427
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C5 pass-only residual overhead threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.5262519128278191, policy/fuse_speedup=51.07073710413498, pass_only/native_p99=2.1391483299034353, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- lookup_tool_redirect: policy/native_p99=1.0922185922185923, policy/fuse_speedup=46.30146159075459, pass_only/native_p99=1.6525467775467775, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- access_tool_redirect: policy/native_p99=1.0756033031347711, policy/fuse_speedup=50.051692009540844, pass_only/native_p99=1.4623987813677544, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- open_tool_redirect: policy/native_p99=1.3377667181511355, policy/fuse_speedup=39.89743644566077, pass_only/native_p99=1.951404381900349, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- exec_tool_redirect: policy/native_p99=0.8554161855209559, policy/fuse_speedup=2.2578242999873592, pass_only/native_p99=0.9132577066598594, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- readdir_alias_view: policy/native_p99=4.373989449932007, policy/fuse_speedup=7.3504610475464895, pass_only/native_p99=2.0693823876626967, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- build_tree_stat_walk: policy/native_p99=1.7500239476892214, policy/fuse_speedup=98.96715820875524, pass_only/native_p99=2.624059316157427, kernel_pass=false, fuse_pass=true, pass_only_pass=false
