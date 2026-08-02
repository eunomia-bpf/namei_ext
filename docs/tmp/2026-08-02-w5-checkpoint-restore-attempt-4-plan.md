# W5 Checkpoint/Restore Attempt 4 Plan

## User Decision And Lineage

The user requires all seven industrial RQ1 workloads to be completed and has
explicitly rejected convergence to the five workloads that already pass. This
reopens W5 after the three 2026-07-28/29 dependency attempts. The next KVM root
is attempt 4 in the original Checkpoint/Restore lineage, not a renamed new
experiment or a reset attempt budget.

The three prior roots remain immutable. Each stopped before the focused DMTCP,
`namei_ext`, and withdrawn lifecycles began. They contain no result about the
RQ1 hypothesis.

## Research Question And Hypothesis

Paper RQ1 asks whether a narrow VFS name-resolution extension can express real
state-dependent path-view policies without taking over filesystem semantics.

W5 tests one exact hypothesis: after a real DMTCP checkpoint is restarted under
a changed filesystem layout, `namei_ext` can make the application's unchanged
remembered pathname resolve to the restored existing directory. DMTCP retains
process checkpoint/restart and coordination; the lower filesystem retains file
contents, metadata, permissions, and file operations.

This is a required RQ1 case, not a performance experiment and not a test of
whether a table is sufficient.

## Source Workload And Comparison

- Source system: DMTCP commit
  `068559d9b14c5f96a57869753bba7c066cbf9653`.
- Source behavior: DMTCP PathTranslator and its official `pathvirt` test.
- Disclosed source repair: the existing one-line
  `restart-env-scan-count.patch`, which changes the scan bound in
  `dmtcp_get_restart_env()` from pointer size to the number of bytes read. It
  does not implement pathname translation.
- Main comparison: patched DMTCP PathTranslator running the same application
  and A-to-B oracle.
- Causal control: withdraw the `namei_ext` mapping before restart and require
  the restored application's lookup to fail with `ENOENT`.

No FUSE comparison is needed because this experiment answers RQ1. RQ2 already
has matched FUSE evidence on representative workloads.

## Lifecycle And Oracle

Each condition performs a real DMTCP lifecycle:

1. Prepare immutable generation-A and generation-B workspace directories.
2. Start the application through DMTCP using one logical workspace pathname.
3. Before checkpoint, require `fopen`/`fstat` to select generation A and
   `opendir`/`readdir` to expose `stale.txt` but not `new.txt`.
4. Create one real DMTCP checkpoint image and terminate the original process.
5. Change the mapping from A to B, or withdraw it for the control.
6. Restart the checkpoint image with ordinary DMTCP restart.
7. Require the unchanged logical pathname to select generation B, expose
   `new.txt` but not `stale.txt`, and match the expected existing lower object.
8. Require the withdrawn condition to fail at the same post-restart lookup.
9. Compare lower-object bytes and relevant stat metadata directly before and
   after; no checksum is used as evidence.

The `namei_ext` condition must also show the real `cgroup/namei_ext` attach,
target A-to-B replacement, positive `SELECT` counts before and after restart,
the restarted process in the managed cgroup, and cleanup with no residual BPF
attachment. The PathTranslator condition must execute with no BPF program.

## Implementation Repair

The previous attempt's UID/GID defect is repaired by computing both values in
the same Make recipe and running an immediate `id -u`/`id -g` probe under the
exact `setpriv` invocation before DMTCP starts.

The W5 path will not run, create, or validate checksum manifests. DMTCP source
identity is established by a clean Git checkout at the pinned commit. The
patched build tree, patch file, build logs, executable source revision, kernel
revision, raw DMTCP logs, checkpoint image name/size, application observations,
policy counters, cgroup evidence, lower-object observations, and dmesg are
preserved directly.

## Execution

Preflight attempt 4 uses one modified-kernel KVM boot containing all three
conditions. It passes only if the official source control and every declared
condition reach the complete checkpoint/restart oracle. No partial prefix is a
result.

After a passing preflight and result review, the formal W5 run uses three fresh
modified-kernel KVM boots. Each boot repeats the PathTranslator, `namei_ext`,
and withdrawn lifecycles. All three boots must pass; lifecycle durations are
descriptive only.

Raw roots remain under:

```text
results/experiments/checkpoint-restore-preflight/<RUN_ID>/
results/experiments/checkpoint-restore-rq1/<RUN_ID>/
```

The one runnable entrypoint for each stage is a Make target. Result collectors
write direct observations and logs; the analyzer reconstructs the source
oracle from those raw records.

## Interpretation

- Positive: every PathTranslator and `namei_ext` lifecycle passes the same
  A-to-B oracle, every withdrawn lifecycle fails at the declared post-restart
  lookup, and all lower-object and mechanism-engagement checks pass.
- Contradicted: the source PathTranslator passes but `namei_ext` reaches the
  lifecycle and fails the A-to-B oracle.
- Inconclusive: DMTCP, KVM, packaging, identity, or another dependency fails
  before a comparable lifecycle completes.

A positive result completes W5 evidence toward RQ1. A contradiction bounds the
prototype's checkpoint/restore coverage but does not change the RQ or shrink
the seven-workload requirement. An inconclusive attempt remains repository
evidence and triggers root-cause analysis rather than paper promotion.
