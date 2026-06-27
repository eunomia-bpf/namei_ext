# W3 Redis Policy And FUSE Macrobench Implementation

## Motivation

The W3 checkpoint workload already had a KVM Redis replay witness for
`dump.rdb -> dump.ckpt` and a table_redirect counterfactual. That evidence was
functional, but it did not provide C2-style setup/update rows or an external
FUSE baseline. This step adds those raw rows for the Redis checkpoint replay
case without treating the project as a filesystem or adding a non-Make control
plane.

## Code Paths Inspected

- `tests/w1_oracle/namei_ext_w1_oracle.c`
  - Existing Redis helpers: `run_redis_daemon`, `redis_set`, `redis_save`,
    `redis_get`, and `run_w3_redis_replay`.
  - Existing W1/W2/W4 macrobench emitters and row schemas.
  - Existing W1 FUSE alias helper used to expose a visible name while hiding a
    backing file in directory enumeration.
- `bpf/policies/checkpoint_restore_view.bpf.c`
  - Literal lookup redirect from `dump.rdb` to `dump.ckpt`.
  - Literal readdir redirect from `dump.ckpt` to `dump.rdb`.
- `mk/kvm.mk`
  - W3 replay targets and W2/W4 macrobench validation patterns.

## Design

The proposed-system W3 macrobench keeps the same real Redis RDB replay path as
the existing witness:

- Generate a real Redis `dump.ckpt` by starting Redis, setting
  `namei_ext_w3_key`, and running `SAVE`.
- Confirm `dump.rdb` is absent before policy attach.
- Attach `checkpoint_restore_view.bpf.o` to the current cgroup in the modified
  KVM kernel.
- Start Redis with `--dbfilename dump.rdb` and require that it loads the value
  through the policy redirect.
- Check directory enumeration sees `dump.rdb` and hides `dump.ckpt`.
- Update the backing checkpoint with a new Redis value while the policy remains
  attached.
- Restart Redis through `dump.rdb` and require the updated value.
- Detach the policy and require `dump.rdb` to be absent again.

The external baselines use the same Redis checkpoint behavior:

- `materialized_checkpoint_view` copies an out-of-view source `dump.ckpt` into a
  visible `dump.rdb` and updates by regenerating the source RDB then copying it
  again.
- `fuse_redirect` mounts a FUSE directory view over the checkpoint directory,
  maps `dump.rdb` to the backing `dump.ckpt`, hides `dump.ckpt` from readdir,
  and updates by regenerating the backing Redis RDB.

## Implementation

Added C runner modes:

- `--checkpoint-redis-policy-macrobench`
- `--checkpoint-redis-baseline-macrobench`

Added KVM Make targets:

- `kvm-w3-redis-policy-macrobench`
- `kvm-w3-redis-baseline-macrobench`

The guest targets hash the runner, policy objects, Redis binary, W3 workload
manifest, this implementation note, and `mk/kvm.mk`. They fail if setup,
update, or correctness rows are missing. The FUSE target also requires one
FUSE mount per sample and positive correctness rows for initial read, readdir
aliasing, hidden backing, and post-update Redis read.

## Alternatives Rejected

- Directly inspecting `.bpf.o` or Redis RDB files was rejected because Phase 1
  validation must run the modified kernel in KVM and exercise the real attach
  path.
- A checked-in shell helper was rejected because project-owned orchestration is
  Makefile-only.
- A synthetic text-file checkpoint was rejected because the existing W3 claim is
  about Redis checkpoint replay, so the macrobench should keep Redis in the
  path.

## Validation Plan

Run in order:

```text
make w1-oracle
make kvm-w3-redis-policy-macrobench RUN_ID=<run> W3_REDIS_POLICY_MACROBENCH_SAMPLES=1
make kvm-w3-redis-baseline-macrobench RUN_ID=<run> W3_REDIS_BASELINE_MACROBENCH_SAMPLES=1
```

Release rows should then use the same targets with the paper sample budget.

## Validation Results

The runner and Make targets were validated in the modified-kernel KVM guest.

- `make w1-oracle` passed after the runner changes.
- Smoke policy run
  `20260616T-w3-redis-policy-macrobench-smoke-v1` passed with one setup row,
  one update row, one correctness row, policy execution, and a clean dmesg
  issue scan.
- Smoke baseline run
  `20260616T-w3-redis-baseline-macrobench-smoke-v1` passed with one
  `materialized_checkpoint_view` sample and one `fuse_redirect` sample. The
  FUSE setup row recorded `fuse_mounts=1`, and the dmesg issue scan was clean.
- Release policy run
  `20260616T-w3-redis-macrobench-release-v1` passed with 20 setup rows, 20
  update rows, 20 correctness rows, `policy_executed=true`, and
  `kvm_validated=true`.
- Release baseline run under the same run id passed with
  `materialized_checkpoint_view` and `fuse_redirect`, each with 20 setup rows,
  20 update rows, and 20 correctness rows. FUSE setup rows recorded
  `fuse_mounts=1` for every sample.
- Claim ledger
  `20260616T-eval-w3-redis-workload-macrobench-ledger-v1` verified the policy
  and baseline input hashes and wrote
  `w3-redis-workload-macrobench.jsonl`. The ledger records
  `policy_release_input_pass=true`, `baseline_release_input_pass=true`,
  `materialized_baseline_pass=true`, `fuse_baseline_pass=true`, and
  `storage_footprint_pass=true`.

The W3 C2 slice remains unsupported. The stable blocker across release reruns
is setup latency against the best external baseline, so the claim-level ledger
records `threshold_pass=false`, `w3_c2_slice_supported=false`, and
`release_gate_pass=false`. Average policy setup latency is around 22 ms, while
the materialized setup baseline is around 7 ms. Redis update latency is close
to the best external baseline, and the exact threshold booleans and averages
are recorded in the generated W3 ledger summary.

## Remaining Risks

- This is still a post-restore VFS replay, not a real Podman/CRIU restore.
- The checkpoint policy path uses literal redirects for `dump.rdb` and
  `dump.ckpt`, so it remains C8-negative until a release counterfactual makes a
  table-only implementation fail or exceed a declared budget.
- Only Redis is covered in this step; the planned W3 nginx/Podman checkpoint
  workload remains absent.
