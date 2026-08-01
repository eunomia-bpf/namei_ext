# RQ3 target-lifetime preflight07 bounded-history repair

## Purpose

This record explains why preflight07 is not target-lifetime evidence and how
the experiment protocol was corrected before another KVM attempt.

## Immutable failed result

The result root is:

`results/experiments/namei-ext-target-lifetime-preflight/20260801T061550Z-target-lifetime-preflight07/`

The run used clean project commit
`f18926ed7a4e3f383ccacca4ee11287016cb37be` and clean kernel commit
`621aff8d1bb52fad718f11fd882c956d6a5686ae`. The normal-kernel guest mounted
the tmpfs and loop-backed ext4 filesystem, attached the real policy, and
entered the runner. It failed before the directory, KASAN, and KCSAN boots.

## Raw observations

- `boots/normal-01/observations.jsonl` contains 2,241,443 lines and occupies
  457 MiB after one five-second publication cell.
- `boots/normal-01/final-file-concurrent-rcu-trace.txt` reports 94,519 entries
  retained from 137,000 written. The missing 42,481 entries invalidate marker
  and update-window matching.
- The final-file replacement and clear deterministic RCU litmus rows passed.
  The pinned-object lifecycle rows that happened to execute also passed, but
  the required four litmus rows across final-file and directory cells are not
  present.
- JSONL line 2,241,219 contains a partial history record followed by a cleanup
  record. The run summary reports 426 failures. Once evidence writes failed,
  the old runner continued issuing operations, so the remaining stream is not
  a complete operation history.
- `run.json` is terminally `failed` with
  `failure: kvm-launch-or-guest-command`. No KASAN or KCSAN boot exists.

These facts make the run infrastructure-invalid and incomplete. They do not
show a `namei_ext` lifetime violation.

## Root cause

The original protocol combined a CPU-speed-dependent fixed-duration loop with
full per-operation JSON and ftrace capture. Moving the live work from 9p to
local ext4 exposed the resulting unbounded evidence volume. Enlarging the disk
or trace ring would move the same failure to longer or faster runs and would
not make a partially written history valid.

## Protocol correction

The next runner uses a bounded complete history plus a separate sanitizer
stress phase:

- history updates are an exact configured quota;
- each history reader has a configured target and a fixed upper bound while it
  obtains both selected and absent results;
- the configured duration is a hard success deadline for the history phase;
- all history invoke, syscall-return, response, identity, and descriptor rows
  remain raw evidence;
- ftrace runs only during that bounded history and must retain every entry;
- any history or trace write failure stops the cell;
- the fixed-duration stress phase validates every opened object and descriptor
  but records aggregate classes and any individual failure, not every success;
- KASAN and KCSAN execute both phases through the same real attachment, and the
  existing per-cell sanitizer and dmesg gates remain unchanged.

The runner rejects a history whose joined operations complete at or after that
deadline, even if every quota was eventually met. The offline analyzer repeats
that elapsed-time check and requires the raw ftrace update windows to cover the
exact bounded update history. It also checks history quotas, upper bounds,
history-to-summary equality, full ftrace retention, stress duration and
engagement, zero unexpected stress operations, and the existing lower-object,
cleanup, KASAN, KCSAN, lockdep, and RCU requirements.

## Host validation before rerun

The runner must pass a clean warnings-as-errors static build and GCC
`-fanalyzer`; the analyzer unit suite must pass; `git diff --check` must pass;
and an independent reviewer must find no P0/P1 evidence gap. Only then may a
fresh result root run the normal, KASAN, and KCSAN preflight matrix.

## Host validation result

The corrected runner passed its warnings-as-errors static build and a separate
GCC `-fanalyzer` build. All 52 analyzer tests passed, including rejection tests
for incomplete ftrace coverage and history completion after the deadline;
Python byte compilation and `git diff --check` also passed.

Independent read-only review found and closed six P1 protocol gaps before the
rerun: an unmarked final clear, subset-only trace coverage, late history
completion, execution of later cells after a failed cell, lower-object
verification after a failed cell, and execution of the formal regression
control after a failed runner. The final review returned `GO` with no remaining
P0/P1 blocking commit or a fresh KVM preflight.
