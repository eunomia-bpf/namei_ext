# Policy load KVM gate implementation

Date: 2026-06-14

## Motivation

Compiling a BPF object is not enough for Phase 1. A policy must be accepted by
the modified kernel verifier and attach through the real `cgroup/namei_ext`
path inside KVM. This step adds a small Makefile-owned gate that loads,
attaches, detaches, and records every built policy object.

## Files changed

- `tests/policy_load/Makefile`
- `tests/policy_load/namei_ext_policy_load.c`
- `mk/kvm.mk`
- `Makefile`

## Design choices

The test program is intentionally narrow. It does not know policy semantics and
does not emulate path resolution. For each object path it:

1. opens the BPF object with libbpf;
2. loads it, causing verifier and map creation to run in the target kernel;
3. attaches the first program to `BPF_CGROUP_NAMEI_EXT`;
4. detaches it;
5. writes raw JSONL rows for load/attach/detach.

The owning entry point is `make kvm-policy-load`. It boots the modified kernel
through the existing KVM path, mounts bpffs/debugfs/cgroup2 when needed, and
writes raw evidence under `results/phase1/<run-id>/policy-load.jsonl` plus
`dmesg-policy-load.log`.

`make phase1` now includes `kvm-policy-load` before the older functional and
benchmark KVM targets. This keeps all policy objects on the real attach path
without weakening the existing redirect functional tests.

## Alternatives rejected

- Host-kernel load tests were rejected because Phase 1 validation must use KVM.
- Reusing `namei_ext_functional` for every policy was rejected because that
  program encodes the `redirect_alias.bpf.c` semantic oracle. A load gate should
  only test verifier/load/attach, not pretend it validated every family oracle.
- Adding shell wrappers was rejected by the Makefile-only project invariant.

## Validation performed

Expected local checks for this step:

```text
make policy-load
make kvm-policy-load
git diff --check
```

`make kvm-policy-load` is the first real gate for these new policy objects. A
passing load gate still does not prove C1/C8 correctness; the family-specific
workload runners and oracles remain separate required work.

Observed result:

- `make bpf policy-load` passed.
- `make kvm-policy-load` passed with run id
  `20260614T044641Z-4b962c22`.
- Raw policy-load evidence:
  `results/phase1/20260614T044641Z-4b962c22/policy-load.jsonl`.
- Dmesg evidence:
  `results/phase1/20260614T044641Z-4b962c22/dmesg-policy-load.log`.
- The JSONL contains successful load/attach and detach rows for:
  - `build_graph_view.bpf.o`
  - `cache_locality_view.bpf.o`
  - `checkpoint_restore_view.bpf.o`
  - `pass_only.bpf.o`
  - `redirect_alias.bpf.o`
  - `sandbox_fixture_view.bpf.o`
  - `table_redirect.bpf.o`
- A dmesg scan found no `namei_ext`, verifier, BUG, WARNING, Oops, panic, or
  call-trace failure associated with the policy-load run.
- `make phase1-smoke` passed with run id
  `20260614T044722Z-c16d7dc9`.
- `make kvm-functional` passed with run id
  `20260614T044732Z-1d2c6a72`; `functional_summary` is `pass:true`.
- `make kvm-bench` passed with run id
  `20260614T044739Z-8e65771d`; `bench_summary` has `fail:0`.

## Remaining risks

- This gate does not populate policy maps, so it cannot validate
  provenance-derived workload behavior.
- It assumes one cgroup attach at a time and detaches immediately after each
  policy. That is sufficient for a verifier/attach gate, not for multi-policy
  composition experiments.
- If a future policy needs more than the first program in an object, this test
  must be extended and documented before that policy can be counted.
