# Shared External Inventory Capture

## Motivation

Formal suites need raw evidence of external BPF programs, cgroup attachments,
FUSE mounts, and processes holding `/dev/fuse`. FxMark and
Checkpoint/Restore carried equivalent capture commands, and the planned Build
Action FUSE comparison needs the same observations.

## Implementation

`mk/multi_boot.mk` now owns
`NAMEI_EXT_GUEST_CAPTURE_EXTERNAL_INVENTORY`. The caller supplies:

1. an existing boot result directory;
2. the packaged `bpftool` binary; and
3. a phase label such as `before` or `after`.

The helper writes five raw files for that phase:

- `bpf-programs-<phase>.json`;
- `bpf-cgroup-<phase>.json`;
- `fuse-mounts-<phase>.txt`;
- `fuse-open-fds-<phase>.txt`;
- `fuse-open-fds-<phase>.status`.

It records and accepts the two documented `lsof` outcomes: zero when an owner
is found and one when no owner is found. Any other status fails the suite. The
helper does not interpret the captured state.

FxMark and Checkpoint/Restore retain their existing assertions that the
inventories are empty and unchanged around the measured work. A future Build
Action suite can require sandboxfs to appear during its measured interval
without changing the shared capture path.

## Alternatives Rejected

A generic experiment template was rejected because workload matrices,
correctness oracles, daemon lifecycles, and statistical decisions are
suite-specific. Moving directories was also rejected because the existing
ownership boundaries already match the project contract.

## Validation

The infrastructure source contract requires both existing suites to call the
shared helper before and after execution and rejects private copies of the
`findmnt` and `lsof` capture commands.

An independent review found that indentation in a multiline Make `call` became
leading whitespace in the directory and executable arguments. The helper now
normalizes all three arguments with Make's `strip` function. A regression test
expands an indented multiline call with `make -n` and checks the exact rendered
directory and `bpftool` command.

Validation completed:

- seven focused KVM-interface tests passed;
- the rendered FxMark guest recipe passed `bash -n`;
- `git diff --check` and full Make parsing passed;
- `make result-contract` passed 21 infrastructure tests, 19 FxMark analyzer
  tests, eight Agent workspace analyzer tests, and publication replay; and
- independent final review returned `GO` with no blocker.

## Remaining Work

The Build Action RQ2 suite will become the third caller. It must interpret the
middle inventory differently: the sandboxfs condition requires one expected
FUSE mount and daemon owner, while the `namei_ext` condition requires no FUSE
state.
