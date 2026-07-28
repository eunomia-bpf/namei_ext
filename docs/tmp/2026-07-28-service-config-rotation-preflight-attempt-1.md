# Service Configuration Rotation Preflight Attempt 1

## Command

```text
make kvm-service-config-rotation-preflight \
  RUN_ID=20260728T-service-config-rotation-preflight-v1
```

## Outcome

The real modified-kernel KVM path started and reached the W4 runner, but the
first physical `nginx -t` control failed before policy attachment. The run
correctly terminated and retained:

```text
results/experiments/service-config-rotation-preflight/
  20260728T-service-config-rotation-preflight-v1/
```

`run.json` is `failed` with `kvm-launch-or-guest-command`. The raw runner
contains a failed `current` physical-validation row and no state-transition
row. This attempt is dependency failure evidence, not an RQ result.

## Root Cause

The guest Makefile passed repository-relative artifact and result paths. The
runner used the relative result directory to construct each physical
configuration pathname, then invoked nginx with both `-p <prefix>` and
`-c <relative-config>`. nginx interpreted the relative configuration path
under the prefix and attempted:

```text
<prefix>/<relative-config>
```

instead of the fixture's real configuration file. The validation stderr also
showed that the default `<prefix>/logs/` directory did not exist.

This is a runner path-construction defect. It does not test or contradict the
approved name-resolution hypothesis.

## Forward Repair

The runner now resolves the policy object, result JSONL, nginx binary, and
result directory with `realpath()` before constructing the fixture. All nginx
configuration, pid, error-log, and static-root paths are therefore absolute.
Fixture setup also creates `<prefix>/logs/` before any nginx command.

The approved state machine, oracle, timeout, target IDs, repetitions, and
analysis remain unchanged. Attempt 2 must use a fresh `RUN_ID`; attempt 1 is
not overwritten or promoted.
