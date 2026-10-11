# OSDI C3 Full-Suite Residual Diagnostic

- Run ID: 20260617T-eval-c3-full-suite-residual-diagnostic-v1
- Source performance comparison run: 20260617T-eval-comparison-ctx-init-split-tail10-hardgate-v4
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-c3-full-suite-residual-diagnostic-v1/b2-performance/c3-full-suite-residual-diagnostic-inputs.sha256

## Verdict
- source_input_gate_pass=true
- fuse_baseline_threshold_pass=true
- full_suite_c3_supported=false
- full_suite_c5_supported=false
- release_gate_pass=false
- failed_kernel_benches=lookup_native_hot, readdir_alias_view, build_tree_stat_walk
- failed_pass_only_benches=lookup_native_hot, lookup_tool_redirect, access_tool_redirect, open_tool_redirect, readdir_alias_view, build_tree_stat_walk
- diagnostic_classes=common_hook_residual_dominates, near_native_p99_threshold, passes_full_suite_c3, policy_p99_tail_outlier

## Per-Bench Rows
- lookup_native_hot: class=near_native_p99_threshold, policy/native_p99=1.5262519128278191, policy/fuse_speedup=51.07073710413498, pass_only/native_p99=2.1391483299034353, policy_p99/p95=1.0446780077292592
- lookup_tool_redirect: class=passes_full_suite_c3, policy/native_p99=1.0922185922185923, policy/fuse_speedup=46.30146159075459, pass_only/native_p99=1.6525467775467775, policy_p99/p95=1.0390986472645074
- access_tool_redirect: class=passes_full_suite_c3, policy/native_p99=1.0756033031347711, policy/fuse_speedup=50.051692009540844, pass_only/native_p99=1.4623987813677544, policy_p99/p95=1.0484116750674013
- open_tool_redirect: class=passes_full_suite_c3, policy/native_p99=1.3377667181511355, policy/fuse_speedup=39.89743644566077, pass_only/native_p99=1.951404381900349, policy_p99/p95=1.0118993531078946
- exec_tool_redirect: class=passes_full_suite_c3, policy/native_p99=0.8554161855209559, policy/fuse_speedup=2.2578242999873592, pass_only/native_p99=0.9132577066598594, policy_p99/p95=1.0214684063244004
- readdir_alias_view: class=policy_p99_tail_outlier, policy/native_p99=4.373989449932007, policy/fuse_speedup=7.3504610475464895, pass_only/native_p99=2.0693823876626967, policy_p99/p95=3.1160495667170567
- build_tree_stat_walk: class=common_hook_residual_dominates, policy/native_p99=1.7500239476892214, policy/fuse_speedup=98.96715820875524, pass_only/native_p99=2.624059316157427, policy_p99/p95=1.0111166270876009
