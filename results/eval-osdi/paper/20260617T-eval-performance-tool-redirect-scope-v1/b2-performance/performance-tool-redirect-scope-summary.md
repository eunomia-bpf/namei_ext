# OSDI Tool-Redirect Performance Scope Ledger

- Run ID: 20260617T-eval-performance-tool-redirect-scope-v1
- Source performance comparison run: 20260615T-eval-comparison-ctx-init-split-tail10-hardgate-v1
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-performance-tool-redirect-scope-v1/b2-performance/performance-tool-redirect-scope-inputs.sha256

## Verdict
- scoped_c3_supported=true
- full_suite_c3_supported=false
- release_gate_pass=false
- max_scoped_policy_to_native_p99_ratio=1.3377667181511355
- min_scoped_policy_to_fuse_p99_speedup=2.2578242999873592
- failed_full_suite_benches=lookup_native_hot, readdir_alias_view, build_tree_stat_walk

## Scoped Rows
- lookup_tool_redirect: policy/native_p99=1.0922185922185923, policy/fuse_speedup=46.30146159075459, kernel_pass=true, fuse_pass=true
- access_tool_redirect: policy/native_p99=1.0756033031347711, policy/fuse_speedup=50.051692009540844, kernel_pass=true, fuse_pass=true
- open_tool_redirect: policy/native_p99=1.3377667181511355, policy/fuse_speedup=39.89743644566077, kernel_pass=true, fuse_pass=true
- exec_tool_redirect: policy/native_p99=0.8554161855209559, policy/fuse_speedup=2.2578242999873592, kernel_pass=true, fuse_pass=true
