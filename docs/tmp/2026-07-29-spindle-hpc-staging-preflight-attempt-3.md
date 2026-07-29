# Spindle HPC Staging KVM Preflight Attempt 3

## Result

The third modified-kernel preflight used:

```text
results/experiments/spindle-staging-preflight/
  20260729T164002Z-spindle03/
```

The guest booted kernel `621aff8d1bb52fad718f11fd882c956d6a5686ae`
from clean source commit `233688d1009c31b36d39e63d7d5f04ef17e68882`.
Guest preparation, cleanup, after-inventory, and dmesg capture completed. The
source Spindle command returned zero and wrote no stderr, but the experiment
stopped before mapping collection or BPF attachment. This root is not an RQ1
workload result.

## Failure

The adapter launched Spindle as a process-group leader. After that leader
returned, `kill(-pgid, 0)` continued to report at least one process in the
group for ten seconds. The wrapper returned `EBUSY`:

```json
{"condition":"source_spindle","exit_status":0,"runner_errno":16,
 "diagnostic_ok":true,"pass":false}
```

The source log confirms that Spindle executed the complete loader workload:
the application exited zero, Spindle began shutdown, and its server reported
94 library reads and 92 stores. Spindle's serial launcher forks a daemon and
application and reaps them through a `SIGCHLD` path. Process-group
nonexistence is therefore not the source system's completion oracle and can
also remain true for a zombie process. The adapter's later executable-name
scan found no live `spindle*` executable.

## Interpretation

This is a wrapper completion defect. It does not support or contradict the
claim that `namei_ext` can select Spindle-populated files because the adapter
did not parse the 47 focal mappings, register targets, attach the policy, or
run the `namei_ext` and withdrawn conditions.

The three-attempt Spindle preflight is closed. The failed root remains
unchanged, and no fourth Spindle run is started. RQ1 work proceeds
breadth-first to Toolchain and Dependency Environments.
