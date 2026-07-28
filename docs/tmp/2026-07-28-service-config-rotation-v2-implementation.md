# Service Configuration Rotation V2 Implementation

## Motivation

The original Service Configuration Rotation protocol exhausted three
dependency preflight attempts before policy attachment. nginx attempted to
change ownership of temporary directories inside the virtme-ng shared result
tree, whose host-owned UID cannot be changed from the guest. V2 preserves the
experiment hypothesis and moves only service-owned mutable runtime state to
guest-local storage.

## Files Inspected

- `experiments/service_config_rotation/namei_ext_service_config_rotation.c`
- `analysis/service_config_rotation/analyze.py`
- `analysis/service_config_rotation/test_analyze.py`
- `mk/experiments/service_config_rotation.mk`
- `mk/multi_boot.mk`
- `mk/kvm.mk`
- `mk/workload.mk`
- the raw nginx validation logs from preflight attempts 1-3

## Implementation

The runner now creates a unique
`/tmp/namei-ext-service-config-<runner-pid>` tree for the nginx pid file,
error log, prefix, and service temporary directories. Configuration
generations, content roots, raw observations, stdout/stderr, and captured
artifacts remain in the immutable result boot directory.

The generated configurations no longer force `user root;`. nginx retains its
compiled worker identity and can create or change ownership of its temporary
directories on the guest-local filesystem. The runtime root is mode `0711`,
and the lifecycle sends a 64 KiB request through nginx's proxy path with
`client_body_in_file_only on`. The runner requires the resulting body file to
have the expected size and the worker's effective UID.

After the nginx master is stopped and reaped, the runner:

1. copies the error log to `<boot-dir>/nginx.error.log` with exclusive create;
2. verifies that source and destination are non-empty regular files of equal
   size;
3. fsyncs the copied file;
4. recursively removes the unique guest-local runtime tree; and
5. only then detaches the policy, clears targets, and removes the cgroup.

Error-log capture and runtime removal are emitted as required structured
correctness cases. Graceful and forced shutdown use checked kill/wait results;
runtime capture and removal cannot proceed unless the master was reaped. The
analyzer rejects a run missing any runtime, worker-I/O, capture, or removal
case.

The Service Configuration Rotation suite now uses the shared multi-boot
initialization, guest-Makefile sealing, direct-boot observation collection,
tree validation, and per-boot artifact validation from `mk/multi_boot.mk`.
Protocol and summary schemas are V2. Finalization requires a non-empty copied
error log and verifies `outputs.sha256`, which covers both immutable fixture
files and the captured log. A per-boot `evidence.sha256` also seals all raw
nginx validation/daemon logs, observations, launcher logs, boot metadata, and
kernel identity files. The formal report target rechecks all evidence and
recomputes the analysis into `.build/` before comparing it byte-for-byte with
the stored report.

## Alternatives Rejected

- Keeping runtime state in the shared result tree cannot support nginx's
  required ownership changes.
- Forcing a root worker changes service behavior and still failed because the
  guest cannot change ownership of the host-backed tree.
- Disabling nginx temporary paths would make the dependency pass by weakening
  the real service path.
- Treating a missing log or failed cleanup as informational would allow an
  incomplete lifecycle to pass.
- Adding a new shell or Python orchestrator would violate the repository's
  Make-only control boundary and duplicate the shared multi-boot contract.

## Local Validation

The following checks pass:

```text
make service-config-rotation-analysis-test
make service-config-rotation
make bpf
make result-contract
gcc -fanalyzer
clang --analyze
git diff --check
```

The analyzer suite includes explicit rejection of a missing error-log capture,
missing `pass`, an unknown event, dirty or mismatched run identity, an altered
timeout, and the obsolete V1 protocol schema. The shared
result-contract suite covers deterministic direct-boot collection, missing
per-boot artifacts, directories or symlinks substituted for artifacts, and
nested or moved boot evidence.

## Remaining Gate

Local validation does not establish the real path. The next step is to commit a
clean candidate and run exactly one V2 dependency preflight through
`make kvm-service-config-rotation-preflight`. The preflight must reach the real
`cgroup/namei_ext` attachment path, complete all four nginx states, preserve
lower objects, capture the error log, remove guest-local state, and pass
artifact, source, kernel, and dmesg gates. It is not paper evidence.
