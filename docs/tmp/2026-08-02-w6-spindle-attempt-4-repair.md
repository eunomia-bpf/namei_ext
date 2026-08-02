# W6 Spindle Attempt 4 Repair

## Purpose

W6 HPC File Staging is one of the seven mandatory RQ1 case studies. This
record reopens its source-derived Spindle preflight after the user required
all seven cases to reach complete KVM evidence. The source system, 47-object
workload, oracle, `namei_ext` condition, and withdrawn control do not change.

## Prior Result

The third immutable preflight root is:

```text
results/experiments/spindle-staging-preflight/
  20260729T164002Z-spindle03/
```

The official Spindle command returned zero with empty stderr. Its first-party
debug output reported a completed loader workload, 94 library reads, 92
stores, and server shutdown. The experiment runner nevertheless returned
`EBUSY` because `kill(-pgid, 0)` still found a process-group member ten
seconds after the direct child exited. Mapping collection, BPF attachment,
the `namei_ext` application, and the withdrawn control did not run.

The same result's final `/proc/*/exe` scan found no live executable whose name
started with `spindle`. Unix process-group existence can remain true for a
zombie and is not Spindle's source completion oracle. Attempt 3 is therefore
inconclusive, not a W6 result.

## Repair

The process runner now waits for the direct child and preserves its exact
exit status. On timeout it still kills the child's process group. After a
normal source exit, a separate bounded check polls `/proc/*/exe` until no live
Spindle executable remains. It ignores zombie process-group membership but
still rejects a live Spindle frontend, backend, or bootstrap process.

All scientific gates remain unchanged:

- official Spindle serial pull mode must exit zero with empty stderr;
- first-party logs must yield 47 unique shared-to-local mappings;
- every mapped cache object must be the Spindle-created object on the
  dedicated cache tmpfs and byte-equal to its shared source;
- the unchanged upstream loader workload must consume all 47 registered
  objects through real `cgroup/namei_ext` attachment;
- per-target hits and aggregate SELECT attribution must agree;
- the withdrawn target must make the covered source fail with the expected
  diagnostic and no new SELECT;
- all source/cache objects, BPF state, cgroup state, mounts, and live Spindle
  executables must be clean at teardown.

Only a complete fresh-boot preflight can authorize the formal W6 run.
