# OSDI B2/B8 Performance Comparison Verdict

- Run ID: 20260615T-eval-comparison-ctx-init-split-batch64-v1
- Phase 1 evidence run: 20260615T-kvm-bench-ctx-init-split-batch64-v1
- External baseline run: 20260615T-kvm-external-baselines-ctx-init-split-batch64-v1
- Comparison JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/performance-comparison.jsonl
- External baseline tail JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/external-baseline-latency-tail.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/performance-comparison-inputs.sha256
- Manifest: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260615T-eval-comparison-ctx-init-split-batch64-v1/b2-performance/performance-comparison-manifest.json

## Verdict
- input_gate_pass=true
- internal_latency_batch=true
- external_latency_batch=true
- c2_supported=false
- c3_supported=false
- c5_supported=false
- release_gate_pass=false
- verdict=unsupported_by_thresholds_or_missing_macrobench
- max_policy_to_native_p99_ratio=1.812401707481465
- min_policy_to_fuse_p99_speedup=1.6385146327254374
- max_pass_only_to_native_p99_ratio=1.0946244650331562
- missing_evidence=C2 setup/storage/update macrobench comparison, C3 policy/native p99 threshold, C3 policy/FUSE 2x speedup threshold

## Per-Bench Rows
- lookup_native_hot: policy/native_p99=1.812401707481465, policy/fuse_speedup=37.295690260733025, pass_only/native_p99=0.9744252227963753, kernel_pass=false, fuse_pass=true, pass_only_pass=true
- lookup_tool_redirect: policy/native_p99=1.1350080250830503, policy/fuse_speedup=36.82514469876348, pass_only/native_p99=0.9806651487439811, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- access_tool_redirect: policy/native_p99=1.142830268541598, policy/fuse_speedup=44.80489711934156, pass_only/native_p99=1.0946244650331562, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- open_tool_redirect: policy/native_p99=0.8754594393911268, policy/fuse_speedup=38.32009499374483, pass_only/native_p99=0.8838314460738815, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- exec_tool_redirect: policy/native_p99=0.900906500781216, policy/fuse_speedup=1.6385146327254374, pass_only/native_p99=0.8874434646324415, kernel_pass=true, fuse_pass=false, pass_only_pass=true
- readdir_alias_view: policy/native_p99=1.0043835036264492, policy/fuse_speedup=19.598604244194014, pass_only/native_p99=1.0123987505955847, kernel_pass=true, fuse_pass=true, pass_only_pass=true
- build_tree_stat_walk: policy/native_p99=1.0233786919298322, policy/fuse_speedup=78.10002084135412, pass_only/native_p99=0.9957253927519782, kernel_pass=true, fuse_pass=true, pass_only_pass=true
