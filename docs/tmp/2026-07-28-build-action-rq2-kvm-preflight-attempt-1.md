# Build Action RQ2 KVM Preflight Attempt 1

## Scope

This record covers the first real paired-preflight attempt for the
Bazel/official-sandboxfs RQ2 experiment:

`results/experiments/build-action-rq2-preflight/20260729T021705Z-build-action-rq2-preflight-v1/`

The attempt used clean source commit
`a4081fd4abc4bff5bced3565ede652d93de1f9a6` and clean modified-kernel commit
`bdc9a83e3dfbef8ff2017f9188c7c86025962183`.

## Result

The attempt is terminally failed and immutable. It entered the first
`namei_ext` KVM boot and did not start the sandboxfs boot. The run therefore
contains no paired correctness or timing result and is not paper evidence.

The following gates passed before failure:

- exact kernel release, notes, BTF, and build identity;
- four-vCPU host pinning to CPUs 4--7;
- empty pre-run BPF and FUSE inventory;
- policy load;
- the 4,096-entry capacity fill/read/clear probe, with all 4,096 entries
  inserted and removed and zero entries remaining; and
- external `bpftool prog show`, which observed the live
  `namei_ext_policy` program.

## Failure

The guest failed at the external middle-phase cgroup-attachment inventory.
The captured system bpftool was `/usr/local/sbin/bpftool` v7.7.0. Its program
enumeration observed the live program, but its compiled cgroup attach-type
table did not include the project-specific `BPF_CGROUP_NAMEI_EXT` value.
Consequently:

- `bpf-programs-middle.json` contained the live policy program; while
- `bpf-cgroup-middle.json` was an empty array.

The suite correctly rejected that contradiction before releasing the runner.
The runner was then terminated by the guest failure trap. The sole raw
observation is the passing capacity row.

This is an experiment-infrastructure identity failure, not evidence that the
policy failed to attach or that the Bazel workload failed. The runner's
successful load/attach call and the live program alone are not sufficient
external attachment evidence, so the cgroup inventory gate must not be
removed.

## Repair

The suite now builds bpftool from the same modified kernel source and UAPI,
under a kernel-commit-keyed build root. The build requires
`BPF_CGROUP_NAMEI_EXT` in bpftool's cgroup attach-type table and
`cgroup/namei_ext` in the resulting binary. Artifact capture records the
copied runtime binary's version, SHA-256, and source commit, and validates the
manifest hash against that exact guest artifact.

The preflight target also enforces the clean-source gate explicitly,
matching the formal target and the frozen plan.

No workload, correctness oracle, FUSE configuration, sample count, timing
boundary, or statistical rule changed. The resulting bpftool reports version
7.8.0 with libbpf 1.8.

The full repository result contract, Build Action analyzer tests, kernel
bpftool build, sandboxfs build, Make syntax checks, and diff checks passed.
An independent attempt-specific review found no blocking or high-severity
finding and returned `ATTEMPT 2 GO`. Attempt 2 is authorized after this repair
is committed so the clean-source gate can pass.
