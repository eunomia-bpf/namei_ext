# mdtest Official virtme-ng Launcher Implementation

## Motivation

The reviewed RQ2 mdtest experiment was previously closed after three KVM
preflights failed before any guest workload observation. The last attempt
proved exact vCPU masks with a project-authored QMP controller, but the
virtme-ng/QEMU launcher exited before the guest barrier and did not preserve a
diagnosable execution boundary. The 2026-08-02 reconsideration plan admits a
new preflight only with the official upstream pinning path added by virtme-ng
commit `8f74cceecb163a5d5b08e70c101de85920eb624c`.

## Files Inspected

- `mk/kvm.mk`: common KVM launch/capture path and existing controller/verifier
  ordering.
- `mk/experiments/mdtest_cold_metadata.mk`: source acquisition, five-condition
  matrix, guest affinity barrier, result finalization, and official
  mdtest/libfuse build path.
- `configs/benchmarks/mdtest_cold_metadata.mk`: frozen versions, matrix sizes,
  kernel pair, and plan/review pointers.
- `tools/kvm/verify_vcpu_affinity.py`: read-only QMP verification, initial
  delay, exact singleton-mask check, and result publication.
- Upstream virtme-ng commit `8f74ccee...`: native `--pin` handoff from
  `virtme-ng` to `virtme-run`, five one-second QMP retries, and automatic QMP
  enablement on port 3636.
- The approved 2026-07-29 mdtest scientific plan and the closed 2026-07-30
  preflight review.

## Implementation

### Pinned official launcher

The mdtest source target now clones the official virtme-ng repository, checks
out `8f74ccee...` detached, verifies the source tree and executable, and runs
the source-native `vng --version`. It is stored under the documented benchmark
cache root and invoked directly from source. No host virtme-ng upgrade or
manually activated environment is required.

The source manifest records the official repository and commit beside the
existing IOR/mdtest 4.0.0 and libfuse 3.18.2 revisions. The raw run manifest
records native pinning, the launcher commit, verifier delay, and 60-second
guest barrier bound.

Immediately before result-root creation, the experiment also requires the
configured executable path to equal the pinned checkout's tracked `vng`,
rejects a symlink, checks the source stamp and checkout `HEAD` against
`8f74ccee...`, and requires the Git index and tracked files to be clean. The
captured source-version record reads `HEAD`, not merely the expected commit
object. A stale stamp, modified checkout, or launcher-path override therefore
fails before a result exists.

### Native-pin capture mode

`mk/kvm.mk` has one opt-in mode. Existing callers retain the old behavior and
default flags. The mdtest recursive launch supplies:

```text
VNG=<pinned source>/vng
NAMEI_EXT_VNG_RUN_FLAGS="--verbose --pin 8-15"
NAMEI_EXT_KVM_CAPTURE_NATIVE_PIN=1
NAMEI_EXT_KVM_CAPTURE_QMP_LISTENER_TIMEOUT=30
NAMEI_EXT_KVM_CAPTURE_VERIFY_INITIAL_DELAY=6
```

Native mode suppresses the old injected QMP option because official `--pin`
enables QMP itself. It never runs `pin_vcpu_affinity.py`.

The host waits at most 30 seconds for a listening TCP socket on port 3636 by
calling `ss -ltn`; this observes kernel socket state without opening a QMP
connection. It records the wait start, listener snapshot, listener observation
time, and status. Only after listener observation does it invoke the existing
read-only verifier with a six-second initial delay. The delay exceeds
upstream's complete five-attempt, one-second retry window. Native pinning has
therefore completed or stopped before the verifier first opens QMP.

The verifier must observe vCPU 0--7 mapped in order to singleton host CPU masks
8--15. It publishes the existing `vcpu-affinity.json`; the guest waits for that
passing record for at most 60 seconds before its workload barrier. This covers
the 30-second listener bound, six-second separation, verifier retries, and a
small scheduling margin. Listener timeout or failed
verification terminates the run. The raw boot directory separately records the
listener status, verifier status, combined launcher/QEMU status, verbose
launcher logs, verifier record, and guest barrier/completion records.

### mdtest result checks

The mdtest finalizer no longer accepts the project-authored
`vcpu-affinity-pin.json`. Every completed boot must instead contain:

- a nonempty listener observation and its timestamp;
- zero listener, verifier, and launcher status values;
- no project-authored pin-controller artifact; and
- a verified affinity record with a six-second initial delay and eight exact
  ordered singleton masks.

The official mdtest source, libfuse source, workload phases, cache-drop
protocol, oracle, parser, conditions, ranks, item counts, repetitions, and
analysis are unchanged. The expected patched kernel revision is updated to the
already-built current prototype commit `b07117a3...`; the stock kernel remains
`062871f1...`.

## Alternatives Rejected

- A fourth run with host virtme-ng 1.40 and the project-authored controller
  would repeat the closed protocol.
- A fixed delay from launcher process start is insufficient because launcher
  preparation could consume the delay before QMP exists. The delay starts only
  after a non-connecting listener observation.
- Connecting a verifier immediately and retrying would contend with native
  pinning and recreate the ambiguity identified by independent review.
- A custom cold FxMark workload is weaker than official mdtest and does not add
  standard create/remove phases.

## Validation Performed

- `git diff --check`: passed.
- `make mdtest-cold-metadata-analysis-test`: passed 19 analyzer tests, 6
  pin-controller tests, and 10 read-only-verifier tests.
- `make mdtest-cold-metadata-source`: cloned and verified official virtme-ng
  `8f74ccee...`; source-native version is `virtme-ng 1.41+18.g8f74cce`.
- `make mdtest-cold-metadata-source-feasibility`: unmodified mdtest create,
  stat, and remove passed with warnings-as-errors and the frozen parser/tree
  oracle at one and four MPI ranks; the official passthrough binary exposed the
  required source, cache, and `clone_fd` options.
- `make mdtest-cold-metadata-kernel-pair`: rebuilt and validated patched
  `b07117a3...` and stock `062871f1...`; their configs differ only by
  `CONFIG_NAMEI_EXT`.
- A bounded local listener check confirmed that `ss -H -ltn
  'sport = :3636'` observes a listening socket without establishing a client
  connection; the temporary listener was terminated after the check.

No KVM run has been executed under the new plan. Host-only checks do not count
as Phase 1 validation.

## Remaining Risks And Next Step

- The official native pin path has not yet been exercised on this host/kernel
  pair. The first stock boot of the bounded real preflight is the only valid
  test.
- The host must satisfy the pre-existing no-turbo, performance-governor,
  homogeneous-core, idle-CPU, clean-tree, and exact-kernel gates before result
  root creation.
- Formal execution remains prohibited until one complete five-condition
  preflight receives an independent result review.

The next step is independent implementation review. Only a `GO` authorizes the
first new KVM preflight attempt.
