# Agent Workspace RQ2 Experiment Plan Review

Date: 2026-07-27

## Scope

This review evaluated
`docs/tmp/2026-07-27-agent-workspace-rq2-experiment-plan.md` before any real
preflight. The experiment asks whether `namei_ext` has lower path-operation and
workspace-lifecycle cost than a feature-equivalent FUSE implementation under
the same AgentFS-derived correctness oracle.

## Verdict

The initial plan was not ready for a real preflight. The research question,
two-condition comparison, independent-boot design, and paper value were sound,
but four defects had to be closed first.

## Blocking Findings

### 1. The FUSE baseline was coherent but not demonstrably strong

The proposed `entry_timeout=3600,attr_timeout=0,negative_timeout=0` setting
preserved correctness, but forced stable metadata and negative lookups through
the daemon. Libfuse exposes cache-invalidation APIs, so the absence of a usable
libfuse 2 high-level path invalidation call did not justify calling that
configuration the strongest FUSE baseline.

The formal experiment must contain exactly one FUSE result row. It must either
use long caches with correct targeted invalidation or demonstrate in preflight
that such a configuration cannot pass the same oracle. Permission handling
must also be feature-equivalent through `default_permissions` or an explicit
`.access` implementation and denial oracle.

### 2. The local trace was not bound tightly enough to AgentFS

The workload shape was legitimately derived from AgentFS, but the trace checker
only verified project-authored tokens. Every phase must identify the fixed
AgentFS commit, upstream test file, and source operation from which it is
derived. The oracle must explicitly check epoch-visible content and metadata,
negative lookup followed by create and logical-path read, rename source and
destination visibility, unlink absence, and lower/base preservation.

### 3. The lifecycle and statistical protocols were underspecified

The old macro timer includes result emission and is not a paper metric. The
replacement must use exactly 20 raw samples per boot. Each sample begins and
ends in a verified empty state. Its timed region contains only cached-negative
lookup, create, rename, and unlink; setup, reset, JSON, flushing, and oracle
output remain outside the timer.

The boot is the independent unit. For each of ten repetition blocks, the
experiment pairs one fresh `namei_ext` boot with one fresh FUSE boot and
alternates condition order. Analysis takes each boot's median, computes ten
paired FUSE/`namei_ext` ratios, and bootstraps whole pairs with 10,000
fixed-seed resamples. The estimate is the median paired ratio. A 95% interval
containing one is inconclusive, not evidence of equivalence.

### 4. The declared Make entry points did not exist

Before real preflight, the repository must implement:

- `make kvm-agent-workspace-rq2-preflight RUN_ID=<fresh-id>`
- `make experiment-agent-workspace-rq2 RUN_ID=<fresh-id>`

Completion gates must verify the fixed FUSE options, successful invalidation
and FUSE request engagement, exact raw-sample counts, exactly two boots in each
formal pair, all correctness oracles, kernel and artifact identity, stable TSC,
and clean dmesg.

## Resolution Chosen

The installed runtime is libfuse 3.14.0. The matching official release exposes
`fuse_invalidate_path()`. The implementation will therefore use one
cache-coherent FUSE baseline with:

- `entry_timeout=3600`
- `attr_timeout=3600`
- `negative_timeout=3600`
- `default_permissions`
- no cross-open file-data cache
- explicit invalidation of every primed logical inode whose selected backing
  object changes at the epoch transition

The invalidation request and acknowledgement are part of control-plane setup,
not the steady-state operation timer. Attempts and failures are recorded and
gated.

The lifecycle is the claim-matched primary effect. `stat`, `open`, `access`,
and `readdir` are mechanism decompositions shown with all ten paired points and
confidence intervals. FUSE daemon CPU and context-switch accounting is limited
to the same measurement window.

## References Checked

- AgentFS fixed source:
  `https://github.com/tursodatabase/agentfs/tree/0a014ebd4918615baff589ed17486e557e7c6a23`
- AgentFS cache-invalidation test:
  `cli/tests/test-fuse-cache-invalidation.sh`
- AgentFS whiteout test: `cli/tests/test-overlay-whiteout.sh`
- AgentFS base-directory delta test:
  `cli/tests/test-overlay-delta-in-base-dir.sh`
- AgentFS bash, git, and symlink tests under `cli/tests/`
- Libfuse 3.14.0 tag:
  `https://github.com/libfuse/libfuse/tree/fuse-3.14.0`
- Libfuse 3.14.0 high-level invalidation implementation:
  `lib/fuse.c:fuse_invalidate_path`

## Remaining Gate

This review authorizes implementation, not measurement. A real preflight may
start only after the source trace, runners, Make entry points, and completion
checks implement the fixed protocol above.

## Implementation Follow-Up

The first implementation review found two P1 defects:

- the new timer used `write_file()`, so it still included FUSE data write and
  release forwarding;
- completion rejected emitted failures but did not prove every required oracle
  was present, and it marked the formal run complete before analysis.

Both were fixed before measurement. The timed sequence is now strictly
negative `stat`, regular-file `mknod`, rename, and unlink. A committed
per-condition required-oracle manifest is copied into the immutable run
artifacts, and the guest requires exactly one passing row for every listed case
or manifest. Formal runs remain `running` until the statistical report and both
figure formats have been generated and validated.

The second independent review returned **ACCEPT** with no remaining P0 or P1
findings. Host builds, source binding checks, analysis tests, result-contract
tests, oracle-manifest consistency checks, and `git diff --check` passed. The
next gate is the real two-boot KVM preflight.
