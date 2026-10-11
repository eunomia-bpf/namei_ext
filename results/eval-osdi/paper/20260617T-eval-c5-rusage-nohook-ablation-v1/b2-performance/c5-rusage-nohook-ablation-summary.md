# OSDI C5 Rusage/No-Hook Ablation Ledger

- Run ID: 20260617T-eval-c5-rusage-nohook-ablation-v1
- Rusage tail run: 20260615T-eval-rusage-tail10-v1
- No-hook baseline run: 20260615T-eval-nohook-baseline-tail10-v1
- Matched baseline/pass-only run: 20260615T-eval-baseline-passonly-tail10-v1
- Raw JSONL: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation.jsonl
- Input sha256: /home/yunwei37/workspace/namei_ext/results/eval-osdi/paper/20260617T-eval-c5-rusage-nohook-ablation-v1/b2-performance/c5-rusage-nohook-ablation-inputs.sha256

## Verdict
- c5_supported=false
- release_gate_pass=false
- max_matched_pass_only_to_native_p99_ratio=1.3228769017980637
- max_full_pass_only_to_native_p99_ratio=1.7728191397011408
- max_full_pass_only_to_nohook_p99_ratio=1.3064224548049477
- failed_matched_benches=access_tool_redirect, lookup_native_hot, open_tool_redirect
- failed_full_run_benches=access_tool_redirect, build_tree_stat_walk, lookup_native_hot, lookup_tool_redirect, open_tool_redirect, readdir_alias_view
- max_pass_only_ctxt_switches_mean_per_op=1.003671875

## Per-Bench Rows
- access_tool_redirect: matched_pass/native_p99=1.283616173375722, full_pass/native_p99=1.562859256729839, full_pass/nohook_p99=1.3064224548049477, pass_cpu_mean_ns=361.953125, pass_ctxt_switch_mean_per_op=0
- build_tree_stat_walk: matched_pass/native_p99=1.034983499711855, full_pass/native_p99=1.7728191397011408, full_pass/nohook_p99=1.0143791273802725, pass_cpu_mean_ns=569.71923828125, pass_ctxt_switch_mean_per_op=1.708984375e-05
- exec_tool_redirect: matched_pass/native_p99=0.9063755553881351, full_pass/native_p99=1.0074580317474129, full_pass/nohook_p99=0.9878328782360033, pass_cpu_mean_ns=22627.1875, pass_ctxt_switch_mean_per_op=1.003671875
- lookup_native_hot: matched_pass/native_p99=1.1553165173719127, full_pass/native_p99=1.472163784699061, full_pass/nohook_p99=1.0893799597524396, pass_cpu_mean_ns=405.859375, pass_ctxt_switch_mean_per_op=0
- lookup_tool_redirect: matched_pass/native_p99=0.31406628090478694, full_pass/native_p99=1.5113225105986972, full_pass/nohook_p99=1.100022578460149, pass_cpu_mean_ns=410.546875, pass_ctxt_switch_mean_per_op=7.8125e-05
- open_tool_redirect: matched_pass/native_p99=1.3228769017980637, full_pass/native_p99=1.373776617830239, full_pass/nohook_p99=0.8978155951388754, pass_cpu_mean_ns=674.609375, pass_ctxt_switch_mean_per_op=0
- readdir_alias_view: matched_pass/native_p99=1.0378869126625963, full_pass/native_p99=1.4099411050933737, full_pass/nohook_p99=0.9989934680268827, pass_cpu_mean_ns=274.109375, pass_ctxt_switch_mean_per_op=0
