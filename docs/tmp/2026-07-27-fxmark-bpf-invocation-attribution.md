# FxMark BPF Invocation Attribution

## Motivation

The RCU decision phase improved attached throughput but did not explain the
remaining gap. The next diagnostic must distinguish time spent in the BPF
program from repeated policy dispatch across pathname components. Aggregate
FxMark throughput alone cannot make that distinction.

## Implementation

`bench/fxmark/fxmark_cell.c` now reads the attached program's
`bpf_prog_info.run_cnt` and `run_time_ns` before and after the measured
interval. The collector preserves the four raw counters in each observation:

- `policy_run_count_before`;
- `policy_run_count_after`;
- `policy_run_time_ns_before`; and
- `policy_run_time_ns_after`.

It does not compute ratios or paper summaries. `FXMARK_BPF_STATS=1` explicitly
enables `/proc/sys/kernel/bpf_stats_enabled` inside the guest. The committed
default is zero, so the final performance matrix does not pay statistics
collection overhead. Both preflight and full-matrix `run.json` and
`command.txt` files record this setting.

The implementation continues to verify that exactly one expected program is
attached before and after the measured interval. Missing statistics support,
program-query failure, or attachment drift fails the cell.

## Diagnostic Run

The real modified-kernel KVM run is preserved at:

`results/experiments/fxmark-rq2-preflight/20260727T-rcu-run-count-v1`

All five conditions passed their correctness and identity gates. No declared
kernel failure signature appeared in captured dmesg.

For the attached conditions:

| Condition | Work units | Policy runs | Runs/work | BPF ns/run |
| --- | ---: | ---: | ---: | ---: |
| `PASS` | 1,548,321 | 15,483,415 | 10.0001 | 24.10 |
| `SELECT` | 1,446,543 | 14,465,635 | 10.0001 | 23.54 |

These are derived diagnostic calculations from the preserved raw counters.
They show that each measured work unit invokes the policy approximately ten
times, while the BPF program body accounts for only about 24 ns per
invocation. BPF statistics collection changes runtime behavior, so throughput
from this run must not be compared with the normal final matrix.

## Interpretation

The evidence localizes the next mechanism problem: policy dispatch currently
covers every normal component in the measured absolute path, while the policy
controls one managed directory junction. Optimizing BPF instructions cannot
remove the repeated cgroup dispatch, context construction, and hook overhead.

The next candidate is explicit exact-parent registration. It must remain a
dispatch filter rather than a path-policy language. A safe design requires:

- explicit `GLOBAL` and `EXACT` modes, including `EXACT(empty)`;
- scope matching and BPF execution against the same cgroup object;
- path-reference cleanup tied to cgroup lifetime;
- atomic RCU publication of each cgroup's immutable parent set; and
- one scope decision at directory-iteration entry.

Prefix, glob, recursive, and string-based matching are out of scope.

## Validation And Follow-Up

- `make fxmark-rq2-build` passes with the new fields.
- The diagnostic completed 5/5 KVM cells with exact artifact gates.
- A normal-statistics preflight remains required after any dispatch-filter
  implementation.
- The unchanged full 450-cell matrix should run only after that preflight
  shows the active path has materially improved.

