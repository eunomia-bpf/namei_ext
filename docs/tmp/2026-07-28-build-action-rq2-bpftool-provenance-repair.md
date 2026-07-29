# Build Action RQ2 bpftool Provenance Repair

## Motivation

The first Bazel/official-sandboxfs paired KVM preflight failed while capturing
the live cgroup attachment. The guest used a system bpftool built before the
project added `BPF_CGROUP_NAMEI_EXT`. That binary could enumerate the loaded
program but did not query the new cgroup attach type, so its empty attachment
tree contradicted the runner's successful attach.

This was an evidence-tool identity failure. Removing the external attachment
gate or accepting the runner's own success report would weaken the frozen
mechanism-engagement oracle.

## Paths Inspected

- `kernel/tools/bpf/bpftool/cgroup.c`
- `kernel/tools/bpf/bpftool/Makefile`
- `mk/kernel.mk`
- `mk/experiments/build_action_rq2.mk`
- `tests/infrastructure/test_kvm_capture_interface.py`
- the immutable failed result root at
  `results/experiments/build-action-rq2-preflight/20260729T021705Z-build-action-rq2-preflight-v1/`

## Design

The repository now builds bpftool from the same modified kernel source used by
the experiment. The output lives under `.build/kernel-bpftool/` and is keyed
by the kernel source commit. A source-commit change removes the generated
bpftool build root before rebuilding.

The build and capture path requires:

- `BPF_CGROUP_NAMEI_EXT` in bpftool's cgroup attach-type table;
- `cgroup/namei_ext` in the built binary;
- an executable copied runtime artifact;
- a source stamp equal to the modified-kernel commit;
- the copied artifact's observed version and SHA-256 in the run manifest; and
- equality between the manifest SHA-256 and the copied guest artifact.

Both preflight and formal targets depend on this kernel-source bpftool. The
preflight now also requires a clean source tree, matching the formal protocol.

## Alternatives Rejected

- Continuing to use `/usr/local/sbin/bpftool` was rejected because its version
  does not encode support for this project-specific attach type.
- Removing the external cgroup inventory was rejected because a loaded
  program is not proof of an attachment to the intended cgroup.
- Trusting only a binary string was rejected; the build also checks the
  source attach-type table and records the exact copied runtime artifact.
- Changing the workload, oracle, sample count, FUSE configuration, or timing
  boundary was rejected because none caused the failure.

## Validation

`make kernel-bpftool` built bpftool 7.8.0 with libbpf 1.8 from the modified
kernel tree. The Build Action analyzer tests, sandboxfs build, infrastructure
result contract, Make syntax checks, Python compilation, and `git diff
--check` passed after the repair.

An independent attempt-specific review checked the failed raw root, diagnosis,
and repair. It found no blocking or high-severity issue and returned
`ATTEMPT 2 GO`.

## Remaining Work

The repair does not turn attempt 1 into evidence. Its result root remains
failed and immutable. A fresh clean-source attempt 2 must run both the
`namei_ext` and official sandboxfs KVM arms and pass every predeclared
correctness, identity, cleanup, and artifact gate before a formal matrix is
authorized.
