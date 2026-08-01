# RQ3 target-lifetime preflight10 KCSAN negative result

## Purpose

This record closes the target-lifetime KCSAN preflight path after the bounded
weak-memory correction was tested and refuted. It preserves the failed result
and the decision not to start the formal nine-boot matrix.

## Immutable result

The result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T082629Z-target-lifetime-preflight10/`

It used clean project commit
`3c06c34c8e33116c7d7277f65f8cf83298b8f970` and clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`. The root is terminally `failed`
with `failure: kvm-launch-or-guest-command`; it must not be repaired, rerun, or
cited as a complete positive result.

## Mechanism observations

The normal and KASAN boots each produced a positive `analysis.json`. In both
boots, the final-file and directory cells completed eight traced target
updates, two readers completed 64 descriptor-validated opens each, every
reader observed at least three selected states plus absence, all readers
overlapped an actual kernel update interval, and all 160 trace entries per
cell were retained. All four deterministic replacement/clear RCU retirement
litmus rows, the pinned-object lifecycle, lower-object checks, cleanup, and
kernel-diagnostic gates passed.

The KCSAN runner also returned zero. Both bounded histories, both five-second
stress phases, all four retirement litmus rows, the pinned-object lifecycle,
lower-object checks, and cleanup passed. The final-file stress phase completed
86,935 opens and 958 updates; the directory phase completed 82,958 opens and
955 updates, with zero runner-reported semantic or descriptor failures.

These observations do not make the complete preflight positive because its
KCSAN diagnostic gate failed.

## KCSAN failure

The kernel configuration kept `CONFIG_KCSAN_STRICT=y`, disabled
`CONFIG_KCSAN_WEAK_MEMORY`, retained the frozen sampling parameters and
unknown-origin reporting, and used no function or source filter. KCSAN was
enabled only for the experiment windows. Its counters increased by 247,452
setup watchpoints and 99 data races, with zero assertion failures and zero
encoding false positives.

The retained dmesg contains exactly 99 complete KCSAN blocks:

- 97 `data-race in init_file / init_file` reports;
- one `data-race in folio_mark_accessed / workingset_activation` report; and
- one `data-race in link_path_walk / v9fs_stat2inode_dotl` report.

The reports name the experiment reader process in their stacks. The frozen
rule therefore classifies the KCSAN boot as negative, regardless of whether a
headline is inside the extension implementation. The weak-memory correction
did not eliminate the dominant `init_file` reports and is refuted.

## Decision

The experiment will not start its formal nine-boot matrix. It will not add a
KCSAN report filter, weaken the zero-race gate, reduce strictness, or
reinterpret preflight10 as positive. Normal, KASAN, PROVE_RCU, deterministic
RCU retirement, trace, and lifecycle observations remain diagnostic evidence
from an incomplete preflight; they are not a formal paper result.

Further paper work should use a different evidence question rather than
continue tuning this sanitizer run. The design claim must not state that a
clean strict-KCSAN target-lifetime matrix was completed.
