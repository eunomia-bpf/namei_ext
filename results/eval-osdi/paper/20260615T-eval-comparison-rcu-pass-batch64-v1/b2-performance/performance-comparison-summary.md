# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-rcu-pass-batch64-v1
- Phase 1 evidence run: 20260615T-kvm-bench-rcu-pass-batch64-v1
- External baseline run: 20260615T-kvm-external-baselines-rcu-pass-batch64-v1
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-rcu-pass-batch64-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- internal_latency_batch=true
- external_latency_batch=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=2.488702622442055
- min_policy_to_fuse_p99_speedup=1.6227850507964676
- max_pass_only_to_native_p99_ratio=1.483472492279538
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C3 policy/FUSE 2x speedup threshold, C5 pass-only residual overhead threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.3702390483815623, policy/fuse_speedup=46.3830550918197, pass_only/native_p99=1.483472492279538, kernel_pass=true, fuse_pass=true, pass_only_pass=false
- lookup_tool_redirect: policy/native_p99=2.124484142687546, policy/fuse_speedup=26.97815327301756, pass_only/native_p99=1.353553055571259, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- access_tool_redirect: policy/native_p99=2.0590468156895825, policy/fuse_speedup=77.80514426171943, pass_only/native_p99=1.2904139302283546, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- open_tool_redirect: policy/native_p99=1.8863290459279596, policy/fuse_speedup=22.242655318071794, pass_only/native_p99=1.2617505744725297, kernel_pass=false, fuse_pass=true, pass_only_pass=false
- exec_tool_redirect: policy/native_p99=0.9477992215598783, policy/fuse_speedup=1.6227850507964676, pass_only/native_p99=0.9783738872782132, kernel_pass=true, fuse_pass=false, pass_only_pass=true
- readdir_alias_view: policy/native_p99=1.0679700479137073, policy/fuse_speedup=18.736991613310487, pass_only/native_p99=1.0220065971637011, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- build_tree_stat_walk: policy/native_p99=2.488702622442055, policy/fuse_speedup=50.075435694660285, pass_only/native_p99=1.3617926901663744, kernel_pass=false, fuse_pass=true, pass_only_pass=false
