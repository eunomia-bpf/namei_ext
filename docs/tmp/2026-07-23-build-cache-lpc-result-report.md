# Build/Cache LPC Result Report

Date: 2026-07-23
Run ID: `20260723T-build-cache-release-v1`
Raw root: `results/experiments/build-cache/20260723T-build-cache-release-v1/`
Plan: `docs/tmp/2026-07-23-build-cache-experiment-b-plan.md`

## Motivation

The immediate goal was to turn Experiment B from a planned traditional
build/cache workload into a complete, reviewable result package that can serve
both the paper story and an LPC/upstream discussion. The upstream-facing
question is practical: can a VFS name-resolution extension point express a real
cache-object path policy without asking userspace to own a filesystem daemon or
asking the policy to own lower-filesystem data/write semantics?

This run uses Redis/nginx source compiles through ccache. It compares:

- proposed system: `cache_locality_view.bpf.c` attached through the real
  `cgroup/namei_ext` KVM path;
- main RQ2 baseline: feature-equivalent FUSE compile-through cache view;
- control: native hot ccache.

The release run covers verified hot-cache object selection. It does not claim
the full miss/stale/corrupt/epoch-switch cache-state matrix.

## Implementation Changes

- `Makefile` now routes `make experiment-env-cache` to a real KVM build/cache
  matrix instead of a failing placeholder.
- `mk/kvm.mk` adds `kvm-build-cache-matrix` and
  `__experiment_build_cache_matrix`. The target boots the modified kernel in
  KVM, runs the trace, policy-bridge, attached-policy compile, native compile,
  and FUSE compile rows, copies raw JSONL/SHA/dmesg artifacts into a single
  experiment root, writes provenance, emits boundary rows, and gates correctness
  with `jq`.
- `tests/w1_oracle/namei_ext_w1_oracle.c` now records compile time for
  attached ccache policy compile rows as `compile_ns` and `compile_ns_avg`.
- `docs/tmp/2026-07-23-build-cache-experiment-b-plan.md` records the admitted
  Experiment B plan for this scoped release run.

## Command

Smoke run:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=1 RUN_ID=20260723T-build-cache-smoke-v1
```

Release run:

```sh
make experiment-env-cache BUILD_CACHE_SAMPLES=20 RUN_ID=20260723T-build-cache-release-v1
```

The release run completed in KVM. The raw command/provenance file is
`results/experiments/build-cache/20260723T-build-cache-release-v1/build-cache-matrix-command.txt`.

## Raw Artifacts

The experiment root contains:

| Artifact | Purpose |
| --- | --- |
| `build-cache-matrix.jsonl` | Paper-facing summary, boundary, and completion rows. |
| `build-cache-matrix-inputs.sha256` | Hashes for kernel, policy, runner, plan, Makefiles, and copied raw JSONLs. |
| `w4-ccache-bulk-trace.jsonl` | Real ccache cache-path trace witness. |
| `w4-ccache-bulk-policy-bridge.jsonl` | Trace-derived policy content bridge. |
| `w4-ccache-bulk-policy-compile.jsonl` | Attached `namei_ext` compile rows and operation trace evidence. |
| `w4-ccache-bulk-native-compile.jsonl` | Native hot-ccache control rows. |
| `w4-ccache-bulk-fuse-compile.jsonl` | Feature-equivalent FUSE compile-through rows. |
| `*-inputs.sha256`, `*-outputs.sha256` | Input/output hash evidence for raw rows. |
| `dmesg-*.log`, `kernel.config`, `uname.txt`, `proc-version.txt`, `kernel-cmdline.txt` | KVM/kernel provenance and failure-signature evidence. |
| `stdout-build-cache-matrix.log`, `stderr-build-cache-matrix.log` | Captured run output. |

`stderr-build-cache-matrix.log` is empty in the release run.

## Result Summary

The terminal summary row is:

```json
{
  "event": "build-cache-matrix-summary",
  "samples": 20,
  "workload": "redis-nginx-ccache",
  "pass": true,
  "policy_executed": true,
  "feature_equivalent_fuse": true,
  "output_hash_match": true,
  "kvm_validated": true
}
```

Key measured fields:

| Metric | `namei_ext` | Native hot ccache | Feature-equivalent FUSE |
| --- | ---: | ---: | ---: |
| Compile jobs | 400 | 400 | 400 |
| Output hash matches | 400 | 400 | 400 |
| Total compile ns | 152,263,433,153 | 157,443,184,178 | 267,748,534,960 |
| Average ns/job | 380,658,582.9 | 393,607,960.4 | 669,371,337.4 |
| Average ns/sample | 7,613,171,657.7 | 7,872,159,208.9 | 13,387,426,748.0 |
| Cache path file ops | 8,000 | 8,000 | 6,000 |
| Cache object ops | 3,200 | 3,200 | 3,200 |
| Redirected/direct cache hits | 800 redirected objects | 400 direct hits | 400 direct hits |

Derived release-run ratios:

- FUSE/namei_ext total compile time: `1.758x`.
- Native/namei_ext total compile time: `1.034x`.

These timing ratios are release-run observations, not yet a statistical
performance model. Correctness is the main result: all rows pass the same
output-object oracle, and the proposed row engages the real KVM
`cgroup/namei_ext` attach path.

## Boundary Evidence

The `namei_ext` boundary row records:

- owned methods: `lookup_policy,readdir_policy`;
- daemon state: none;
- data path owner: lower filesystem;
- write path owner: lower filesystem and ccache;
- policy surface: verified eBPF policy plus kernel validation.

The matched FUSE row records:

- owned methods: `getattr,readdir,open,read,release`;
- daemon state: FUSE cache-view daemon and mount lifecycle;
- data path owner: FUSE request path over backing cache objects;
- write path owner: ccache read-only mode with tempdir outside the FUSE mount;
- policy surface: userspace filesystem daemon plus kernel FUSE interface.

This supports the upstream argument that the same cache-object selection can be
placed at VFS name resolution while preserving lower-filesystem data/write
semantics, instead of moving the workload through a filesystem-service boundary.

## Result Review

- Run status: valid for the scoped verified-hot-cache release row.
- Tested hypothesis: supported for real Redis/nginx ccache hot-cache object
  selection through `namei_ext` versus feature-equivalent FUSE.
- Research value: decisive non-agent workload evidence for the scoped
  hot-cache row; supporting evidence toward the broader Experiment B
  state-machine claim.
- Paper impact: additional RQ1 and RQ2 evidence, plus concrete RQ3 boundary
  evidence for LPC/upstream framing.
- Next paper decision: use this as the first completed traditional build/cache
  result; do not claim full miss/stale/corrupt/epoch coverage until those cells
  run under the same oracle.

## Remaining Limits

- The release run covers verified hot-cache object selection only. The broader
  build/cache state machine still needs real same-oracle miss, stale, corrupt,
  and epoch-switch compile cells.
- The FUSE implementation is the repository's feature-equivalent cache-view
  baseline. It is correct for the tested oracle, but future work should account
  for optimized FUSE configurations and passthrough work when making broad
  performance claims.
- The run uses 20 repeated samples but does not compute confidence intervals.
- Upstream acceptance still requires kernel selftests, API documentation,
  security/verifier discussion, and a small reproducible demo suitable for
  review outside the paper artifact.

## Next Best Work

For the next time-box, the highest-value follow-up is an upstream packet:

1. a minimal KVM selftest/demo target that runs in minutes;
2. a short API and safety-boundary document for the proposed hook;
3. the real build/cache release result distilled into a cover-letter style
   motivation;
4. then real stale/corrupt/epoch compile cells if the paper needs the broader
   cache-state claim.
