# Spindle HPC Staging KVM Preflight Attempt 2

## Purpose And Result

This record covers the second real modified-kernel KVM preflight of the
Spindle HPC staging case study:

```text
results/experiments/spindle-staging-preflight/
  20260729T143220Z-spindle02/
```

Attempt 2 passed the packaging-manifest check that stopped attempt 1 and
entered the real source Spindle positive control. It then failed that positive
control because the packaged runtime tree omitted an upstream readlink
fixture. The `namei_ext` and withdrawn-target conditions did not execute.
This root is not a workload or mechanism result.

## Frozen Identity

- source commit:
  `e336f4f9a964e6b8f4bfe15d80bb621bb1ef28b5`
- source tree: clean
- kernel commit:
  `621aff8d1bb52fad718f11fd882c956d6a5686ae`
- kernel tree: clean
- kernel release: `7.1.0-rc7-g621aff8d1bb5`
- Spindle commit:
  `8853636d2d774729a5a728f5cf6c296b65a1099c`

The original `boot.json` recorded successful guest preparation, cleanup,
after-inventory, and dmesg capture, with `inner_status=2`. A later
`make -n` invocation against the stored `guest.mk` executed recursive Make
lines and rewrote `boot.json`, `dmesg.log`, and three status files. This result
root is therefore contaminated. It remains useful only for the source stderr
diagnostic written before that command and is not a valid mechanism result.

## Exact Failure

The source command was the frozen upstream serial pull invocation. The
Spindle launcher returned zero, but the unmodified `test_driver` wrote:

```text
readlink(hello_.py) expected error 22. Got error 2
```

The raw condition row records `exit_status=0` and `pass=false`, but that
adapter version did not inspect stderr and did not record the nonzero wrapper
return that controlled `pass`. The earlier claim that an implemented stderr
gate rejected this run was incorrect. The stderr diagnostic nevertheless
proves independently that the upstream positive control was invalid, and the
fail-fast path prevented the BPF condition from running.

The cause is in the experiment packaging contract. The runtime archive omitted
four write-only upstream fixtures because the unprivileged host packager could
not read their bytes. The plan stated that `--nompi` did not use them. Source
inspection and the KVM diagnostic show that statement was too broad:
`--nompi` skips the exec and stat suites, but `run_readlinks()` still requires
the regular file `hello_.py` to exist so `readlink()` returns `EINVAL` rather
than `ENOENT`.

## Correction

The upstream Makefile creates both `hello_.py` and `hello_x.py` by copying the
same checked-in `testsuite/hello.py` and then applying modes `0200` and `0300`.
The artifact builder now packages that source file and reconstructs those two
runtime entries from the exact same bytes. They use readable transport modes
during transport. Inside the guest, immediately
before the workload window, their modes become the upstream `0200` and `0300`;
raw before/after metadata must match. The outer guest target restores readable
transport modes on every exit path before unmount.

The two `retzero` permission fixtures remain absent. Source inspection confirms
that their exec tests are skipped by `--nompi`; unlike `hello_.py`, attempt 2
did not access them. `hello_x.py` is reconstructed for upstream-tree fidelity;
this command checks only the literal target string of `hello_l.py` and does not
dereference `hello_x.py`.

The current adapter explicitly records its runner errno and requires empty
stderr for successful source and `namei_ext` conditions. Source/cache equality
and fixture reconstruction use direct byte comparison. The Spindle path no
longer creates or validates checksum manifests.

## Next Gate

Attempt 2 counts toward the frozen maximum of three preflight roots. Before
the remaining attempt, the corrected upstream host command completed with
empty stderr and the Make-owned host packaging target directly compared both
reconstructed fixtures with `hello.py`. The remaining attempt must use a fresh
result root; this contaminated root must never be repaired or reused.
