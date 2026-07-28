# Service Configuration Rotation Implementation Review

## Scope

A fresh read-only reviewer inspected only the W4 service/config rotation
runner, BPF policy, Make/KVM lifecycle, analyzer, tests, and approved plan. The
review focused on false-pass paths, bounded execution, cgroup scope, raw
evidence, cleanup, and repository infrastructure rules. The reviewer did not
edit files.

## Round 1

Verdict: `NO-GO`.

Blocking findings:

1. The analyzer labeled a one-boot dependency preflight as
   `hypothesis supported`, even though only the ten-boot run may be paper
   evidence.
2. The state row wrote a hard-coded expected HTTP-body label. The runner had
   checked a real response internally, but the raw row did not preserve that
   observation for independent review.
3. Some child waits and the outer KVM launch had no hard deadline, so a stuck
   command or VM could block the experiment indefinitely.

Additional findings:

- `readdir` termination errors were not checked;
- policy lookup/readdir counters included events outside the service cgroup;
- successful reloads checked only nginx's `[emerg]` severity;
- an already-exited or zombie master could be reaped during cleanup and
  potentially be mistaken for a successful graceful shutdown.

## Repairs

- The analyzer now accepts only one-boot preflight or ten-boot formal layouts.
  Preflight summaries are `not_tested` with role `dependency_preflight`;
  only ten boots are `supported` with role `formal`. Unit tests cover both.
- After each state converges, the runner makes another real HTTP request,
  verifies the expected bytes, strips the terminal newline, rejects unsafe
  JSON characters, and records the observed body.
- `sha256sum` pipe reads and child exit, directory probes, nginx validation,
  and nginx shutdown use five-second deadlines. The shared KVM capture helper
  gained an optional timeout argument; W4 uses `120s` with a ten-second forced
  kill grace.
- Directory iteration checks both `readdir` errno and `closedir`.
- A BPF cgroup-scope map gates all W4 counters. The runner inserts only the
  service cgroup and records a required `scope_policy` oracle.
- Successful reloads reject new `[emerg]`, `[alert]`, `[crit]`, or `[error]`
  records. Invalid reload requires both the unknown directive and an nginx
  failure-level record.
- Cleanup first calls `waitpid(..., WNOHANG)`. A master that exited before
  `SIGQUIT` is a failure even if its exit status is zero.

## Round 2

Verdict: `NO-GO`.

The reviewer confirmed the evidence-role, actual-body, readdir, cgroup-scope,
and early-master-exit repairs. Three findings remained:

1. target registration and clearing still called the shared harness's
   unbounded child wait, and the runner's post-`SIGKILL` reap was unbounded;
2. log-tail I/O failures still returned `false`, allowing a successful reload
   to interpret an unreadable log as containing no failure; and
3. the analyzer did not validate `result_level`.

Further repairs:

- the shared harness now uses a private five-second bounded wait plus a
  bounded one-second `SIGKILL` reap for target registration, target clearing,
  and policy-parent control operations. The exported wait remains unchanged
  for long-running workload children;
- the runner's forced reap is bounded and a monotonic-clock failure terminates
  the runner visibly;
- log-tail helpers use a tri-state result and every caller propagates negative
  I/O errors; and
- every analyzed state, case, counter, and summary row must have
  `result_level == kvm_service_config_rotation`; a negative test covers this
  contract.

## Round 3

Verdict: `GO`.

The reviewer confirmed:

- all target-register, target-clear, policy-parent, runner termination, and
  clock-failure paths relevant to W4 are bounded or fail visibly;
- every log-tail caller propagates I/O failures rather than treating them as
  no match; and
- state, case, counter, and summary rows enforce the expected result level.

No blocker remained. The reviewer independently reran the nine analyzer tests
and `-Wall -Wextra -fanalyzer -fsyntax-only` checks for the runner and shared
harness. The review did not modify files or expand into other experiments.
