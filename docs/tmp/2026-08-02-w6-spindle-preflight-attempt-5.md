# W6 Spindle Preflight Attempt 5

## Result

`results/experiments/spindle-staging-preflight/20260802T113300Z-spindle05/`
is a valid modified-kernel KVM preflight attempt and not an RQ1 result. It
reached the direct `namei_ext` application, then stopped at an incorrect
harness stderr oracle before selection counters, identity probes, permission,
withdrawal, and preservation gates.

## Evidence Reached

- Project commit `4563b2f`, kernel commit `b07117a`, and Spindle commit
  `8853636` were clean and recorded.
- The official serial-pull Spindle condition exited zero with empty stderr in
  2.237 s, and no live Spindle executable remained.
- First-party Spindle logs yielded exactly 47 unique source-to-cache mappings.
- Every cache object was on the dedicated cache tmpfs, had a distinct
  device/inode from its shared source, and was byte-equal with matching size.
- The canary covered the source `libtest10.so`; the real BPF program attached;
  47 targets and 48 exact source/cache-origin rules were installed.
- The unchanged direct upstream loader exited zero in the policy cgroup in
  0.182 s.
- Cleanup removed the policy, targets, cgroup, canary mount, temporary roots,
  and live Spindle processes. External BPF/FUSE inventories and the declared
  dmesg scan passed.

## First Failed Gate

The direct loader's stderr contained exactly 44 ordered lines from
`dlstart libtest10.so` through `dlstart libtls20.so`. Pinned upstream
`testsuite/test_driver.c` emits these with `test_printf`; without the Spindle
audit client, `libtestoutput.so` routes them to stderr. They are progress
records, not `err_printf` failures. The runner nevertheless called
`file_is_empty(namei_stderr)`, so it recorded `diagnostic_ok=false` despite
application exit status zero.

This differs from the source Spindle condition, where the audit client captures
the same progress stream in Spindle's first-party log and the launcher stderr
is correctly required to be empty.

## Repair And Next Gate

The direct condition now requires the exact 44-line transcript derived from
the pinned upstream source. Any missing, extra, reordered, or error line fails.
The source Spindle empty-stderr gate and withdrawn nonzero-exit plus
`libtest10.so` diagnostic gate remain unchanged.

After compilation and contract tests, the next attempt must use a fresh result
root and non-PTY Make invocation. It must complete the remaining selection,
identity, permission, withdrawn, preservation, and cleanup gates before a
formal three-boot run is authorized.

The earlier root
`results/experiments/spindle-staging-preflight/20260802T114500Z-spindle04/`
is a separate invalid host-launch attempt: a PTY stopped `vng/QEMU` before the
guest wrote any observation, and Make marked it failed after timeout. It does
not inform W6 behavior and must not be reused.
