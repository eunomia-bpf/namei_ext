# Build Action RQ2 KVM Preflight Attempt 3

## Scope

This record covers the third and final real paired-preflight attempt under the
frozen Bazel/official-sandboxfs RQ2 protocol:

`results/experiments/build-action-rq2-preflight/20260729T024914Z-build-action-rq2-preflight-v3/`

The attempt used clean source commit
`5a2308d732e3c463ee9cee206650bfaad9c48cad` and clean modified-kernel
commit `bdc9a83e3dfbef8ff2017f9188c7c86025962183`.

## Result

The attempt is terminally failed and immutable. It completed the first
`namei_ext` boot through policy engagement and the real Bazel builds, then
failed the sample oracle before the sandboxfs boot started. It contains no
paired timing result and is not paper evidence.

The frozen protocol's three real-preflight attempts are exhausted. A fourth
run is not authorized under this plan, even though the deterministic harness
bug is now repaired.

## Evidence That Passed

- The run captured clean source and kernel provenance.
- The copied kernel-source bpftool reported version 7.8 with libbpf 1.8.
- The live BPF inventories recorded the policy and
  `cgroup_namei_ext` attachment.
- The 4,096-entry fill/read/clear capacity gate passed.
- Both pinned Bazel 6.5.0 actions analyzed and built `//:result`
  successfully.
- Bazel A and B reported elapsed times of 4.232 and 4.281 seconds and empty
  stdout logs; neither stderr log contains an action failure.

The sandboxfs arm did not run, so none of these observations supports a
relative performance claim.

## Failure

The runner returned `EIO` after both Bazel actions completed. No saved action
output or post-run lower-object manifest was emitted, which bounds the failure
to the synchronization/output-oracle portion before result publication.

The generated genrule wrote the started, ready, and finished marker contents
with:

```text
printf '%s\n' <sample-id>
```

The runner later validated the started and finished files with
`path_text_equals(path, sample_id)`. That helper performs an exact string
comparison and therefore rejects the trailing newline. The mismatch is
deterministic for every successful action. It explains why Bazel completed
normally while the runner emitted a generic `run`-stage `EIO`.

This is a harness-oracle bug. It is not a Bazel failure, policy-capacity
failure, `namei_ext` correctness result, or sandboxfs comparison.

## Repair

The genrule now writes the started, ready, and finished sample IDs without a
trailing newline. The existing exact marker-content oracle therefore checks
the value that the action actually writes. The two-line Bazel result file
retains its newline-delimited format.

The infrastructure contract checks all three marker-write templates. No
workload input, action command, policy, sandboxfs configuration, scale,
sample count, timing boundary, or statistical rule changed.

## Validation And Independent Review

The repaired runner rebuilt cleanly with `-Wall -Wextra`; all nine Build
Action analysis tests and the focused infrastructure contracts passed.
`git diff --check` also passed.

An independent read-only reviewer verified the diagnosis from the clean source
commit, captured binary template, successful Bazel logs, control flow, and
failure timing. The reviewer found no blocker, high-, or medium-severity
defect and returned `FINAL GO` for committing the repair and failure record.
The review did not authorize another preflight.

Two low-severity evidence limitations remain. The failed root does not retain
the temporary marker bytes, and the raw observation reports only a generic
`EIO`; the source and binary nevertheless make the newline mismatch
deterministic. The new contract checks the three source templates rather than
executing a standalone marker-generation test. A future materially new plan
must add stage-specific runtime evidence before consuming another real
preflight.

## Decision

Attempt 3 remains failed and must not be analyzed or promoted. The repair may
be retained for a future protocol, but the current formal matrix stays
blocked. Before another real paired preflight, a separately reviewed
dependency plan must explain why all three prior harness failures are closed
and add stage-specific failure evidence so a generic `EIO` cannot conceal the
next stopping point.
