# FxMark exact-empty dispatch diagnostic

## Motivation

The exact-parent implementation reduced attached PASS and SELECT policy
invocations from about ten per FxMark operation to one, but the attached
throughput remained substantially below the optimized FUSE condition. The next
mechanism change depends on whether the remaining cost comes from entering the
namei_ext dispatch path for every pathname component or from the one matching
component that executes the BPF program.

This is an internal component diagnostic for RQ2. It is not a paper baseline,
does not change the formal five-condition RQ2 matrix, and does not establish a
new workload claim.

## Design

The preflight suite adds an `empty` condition on the patched kernel:

1. create the same ordinary `view/bench` tree used by PASS;
2. attach the same `fxmark_pass.bpf.o` program used by PASS;
3. publish an exact policy-parent set containing no paths;
4. run the same one-worker, cache-hot FxMark MRPL cell;
5. require the attached program ID to remain stable and its run-count delta to
   be zero.

The attached `empty` condition therefore exercises cgroup and namei_ext
dispatch for each pathname component but never invokes the BPF policy. It
differs from `unattached`, where no BPF program is attached, and from PASS,
where the exact benchmark parent matches once per operation.

The formal `kvm-fxmark-rq2` matrix remains:

```text
stock, unattached, pass, select, fuse
```

Only `kvm-fxmark-rq2-preflight` gains:

```text
empty
```

## Interpretation

- `empty` near PASS indicates that repeated nonmatching dispatch dominates.
- `empty` near unattached indicates that the single matching BPF invocation or
  its context construction dominates.
- An intermediate result quantifies both components and determines which fast
  path must be changed first.

Throughput from runs with BPF runtime statistics enabled is diagnostic only.
The same six-condition preflight must also run with statistics disabled before
interpreting throughput.

## Implementation

The FxMark cell accepts `empty`, attaches the PASS policy, calls the
policy-parent `clear` operation, and fails if the policy run count changes
during the measured cell. The preflight Make target records and validates six
cells. The full RQ2 target and its analysis contract remain unchanged.

## Validation

Completed:

- `make fxmark-rq2-build`;
- `git diff --check`;
- `make kvm-fxmark-rq2-preflight
  RUN_ID=20260727T-exact-empty-run-count-v2 FXMARK_BPF_STATS=1`; and
- `make kvm-fxmark-rq2-preflight
  RUN_ID=20260727T-exact-empty-preflight-v1 FXMARK_BPF_STATS=0`.

Both KVM runs completed all six expected boots and cells. Every observation
passed its FxMark tree oracle, cgroup placement check, kernel-identity check,
and dmesg gate.

## Results

The statistics-enabled run is stored at:

`results/experiments/fxmark-rq2-preflight/20260727T-exact-empty-run-count-v2`

| Condition | Work/s | Policy runs during measurement | BPF ns/run |
| --- | ---: | ---: | ---: |
| `empty` | 1,264,742 | 0 | n/a |
| `PASS` | 1,178,644 | 2,357,299 | 25.09 |
| `SELECT` | 1,051,696 | 2,103,401 | 25.09 |

The `empty` program ID remained stable and its raw run count remained five
before and after the measured interval. This validates the intended
attached-but-never-invoked condition. PASS and SELECT each executed almost
exactly once per work unit.

The statistics-disabled run is stored at:

`results/experiments/fxmark-rq2-preflight/20260727T-exact-empty-preflight-v1`

| Condition | Work/s | Relative to patched-unattached | Relative to FUSE |
| --- | ---: | ---: | ---: |
| stock | 2,246,550 | 0.927 | 1.123 |
| patched-unattached | 2,424,194 | 1.000 | 1.212 |
| `empty` | 1,251,366 | 0.516 | 0.626 |
| `PASS` | 1,222,040 | 0.504 | 0.611 |
| `SELECT` | 1,109,172 | 0.458 | 0.555 |
| FUSE | 1,999,708 | 0.825 | 1.000 |

FUSE recorded 28 setup requests and one measured request, preserving the
cache-hot stable-view interpretation. This is still one two-second directional
sample, not a paper performance result.

## Decision

`empty` is within 2.4% of PASS while reaching only 51.6% of patched-unattached
throughput. The dominant remaining cost is therefore paid before the BPF
program executes: each pathname component enters the attached namei_ext
dispatch and performs cgroup owner and exact-parent scope work even when no
parent can match.

Do not run the full RQ2 matrix on this kernel. The next implementation should
add a VFS-owned negative-component fast path before cgroup/BPF dispatch. The
first candidate is a global RCU registry of exact policy parents because it can
reject unrelated parents before discovering the current cgroup attachment.
Its design must account for multiple cgroups registering the same path,
rename/unmount lifetime, exact-empty and global modes, inherited attachments,
and detach teardown. Lookup-lifetime caching remains an alternative if the
registry cannot preserve these semantics without broad VFS changes.
