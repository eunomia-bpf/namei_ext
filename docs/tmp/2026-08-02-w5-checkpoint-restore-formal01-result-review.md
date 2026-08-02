# W5 Checkpoint/Restore Formal Result Review

## Decision

`results/experiments/checkpoint-restore-rq1/20260802T111000Z-w5-formal01/`
is valid formal RQ1 evidence for W5 Checkpoint/Restore and Migration. The tested
hypothesis is supported in three fresh modified-kernel KVM boots. W5 is
complete; the seven-workload RQ1 portfolio is now 6/7, with W6 HPC File
Staging still required.

## Provenance And Execution

- Project source: clean commit `dcc525c`.
- Kernel source: clean commit `b07117a`, release
  `7.1.0-rc7-gb07117a3cb41`, with `CONFIG_NAMEI_EXT=y`.
- DMTCP source: commit `068559d` with the disclosed one-line correction to the
  restart-environment scan bound.
- Three independent KVM boots each executed DMTCP PathTranslator,
  `namei_ext`, and withdrawn-map conditions.
- Every condition produced a real DMTCP checkpoint image of approximately
  24.39 MB. Independent inspection found the
  `DMTCP_CHECKPOINT_IMAGE_v4.0` header in all nine images.

## Correctness And Attribution

All six positive conditions restarted the same application and reopened the
same logical pathname on generation B after observing generation A before
checkpoint. The logical inode matched the selected lower object in every
observation.

| Boot | PathTranslator inode A -> B | `namei_ext` inode A -> B | Installed `SELECT` | Withdrawn result | Withdrawn `SELECT` |
| --- | --- | --- | --- | --- | --- |
| 1 | 36497319 -> 36497325 | 36497357 -> 36497363 | 12 -> 24 | expected `ENOENT` | 12 -> 12 |
| 2 | 36497549 -> 36497555 | 36497629 -> 36497635 | 12 -> 24 | expected `ENOENT` | 12 -> 12 |
| 3 | 36497831 -> 36497837 | 36497911 -> 36497917 | 12 -> 24 | expected `ENOENT` | 12 -> 12 |

The withdrawn condition is the causal control: the policy selected generation
A before checkpoint, the rule was removed, restart-time selection did not
occur, and the application observed the declared missing-path result rather
than generation A or B.

## Preserved Responsibilities

- 165 controller observations and 18 application observations passed.
- All 54 before and 54 after lower-object records agreed on device, inode,
  mode, size, mtime, and contents.
- BPF program and cgroup inventories were empty before and after every boot and
  after every condition.
- Application, controller, DMTCP command, launch, restart, quit, and KVM
  launcher error logs were empty where the protocol requires empty stderr.
- DMTCP retained process checkpointing, restart, descriptor restoration,
  coordination, and checkpoint-image ownership. `namei_ext` supplied only the
  post-restart existing-directory selection.

The kernel logs contained no project-declared BUG, WARNING, Oops, or Call Trace
signature. Each successful DMTCP restart emitted one
`__vm_enough_memory` refusal for an attempted very-large virtual-address
reservation. All nine restart and application oracles still passed, so this is
recorded as a DMTCP runtime caveat rather than hidden or interpreted as a
`namei_ext` success condition.

## Supported Claim

In this source-derived DMTCP checkpoint/restart workload, `namei_ext` rebinds
the same pathname from an existing generation-A directory to generation B
after a real restart. Withdrawing the rule yields `ENOENT` without a
restart-time `SELECT`. The result repeats in three modified-kernel KVM boots
while preserving the tested lower objects.

## Claim Limits

The result does not support a performance claim, open-file-descriptor
redirection, multiprocess or cross-host migration, arbitrary DMTCP or CRIU
workloads, all lower filesystems, or replacement of DMTCP's checkpoint and
restart machinery. It contributes one of the seven required industrial RQ1
cases and does not reduce the requirement to complete W6.
