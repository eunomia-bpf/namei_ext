# Experiment Plan: RQ1 Build Action Sandboxing

## Research Question

- RQ exactly as written in the paper: Can a narrow VFS name-resolution
  extension express real state-dependent path-view policies without taking
  over filesystem semantics?
- Specific uncertainty tested here: Can the current declared-input allowlist
  policy give two concurrent real Bazel actions different existing-object
  views at the same logical pathname while hiding undeclared children from
  lookup and directory enumeration?
- Why the answer matters: The only passing W3 KVM result predates the current
  allowlist policy. A formal run is needed before the paper can use W3 as
  evidence for the implemented mechanism.

## Paper-Value Admission

- Planned role: supporting RQ1 breadth.
- Largest credible paper story this experiment could unlock: One bounded
  `namei_ext` decision function can construct concurrent action-specific
  existing-object views for an unmodified build system while Bazel and the
  lower filesystem retain build, file-operation, and object ownership.
- Strongest reviewer reject argument addressed: The current W3 claim rests on
  an obsolete fixed-name denylist and one old boot, rather than the present
  arbitrary declared-input allowlist.
- Independent evidence added: Three fresh boots exercise the current
  `build_action_roots` and `build_action_declared_inputs` maps, both allow and
  hide branches, two simultaneous cgroup views, direct output bytes, lower
  object identity, and cleanup.
- Why the result is not tautological: Two unmodified Bazel 6.5.0 builds must
  reach a common barrier, read different bytes through the same logical path,
  fail both lookup and readdir discovery of physically existing undeclared
  inputs, and preserve the selected lower objects.
- Paper decision if positive: Admit W3 as a reviewed traditional RQ1 row using
  the current policy.
- Paper decision if contradictory, mixed, or inconclusive: Retain the old run
  as historical evidence only and remove W3 from current-mechanism RQ1 claims.
- Best alternative experiment: Repeating W1 would strengthen another
  supporting case but would not repair the current-policy evidence gap. W4,
  W5, and W6 have closed dependency protocols. W3 therefore has the highest
  immediate RQ1 decision value.

## Expected And Alternative Outcomes

- Current expected answer: Each action cgroup selects its registered lower
  root, declared `input.txt` passes normal lookup/readdir, and absent allowlist
  entries return `HIDE`.
- Strongest competing explanation: The allowlist may hide a Bazel-required
  component, directory enumeration may diverge from lookup, cgroup identity
  may not reach the genrule, or concurrent actions may cross views.
- Result that would contradict the expectation: Either Bazel action fails,
  reads the other action's bytes, observes `private.txt`, misses an allow/hide
  policy branch, changes a lower object, or leaves policy/target state behind.

## Published Precedent And Real Assets

- Closest published protocol: Bazel's official sandboxing contract says actions
  should see only known inputs:
  <https://bazel.build/docs/sandboxing>.
- Official system and version: Bazel 6.5.0 Linux x86-64 from the official
  release:
  <https://github.com/bazelbuild/bazel/releases/tag/6.5.0>.
- Source-system precedent: sandboxfs constructs arbitrary action views without
  a symlink forest:
  <https://github.com/bazelbuild/sandboxfs> and
  <https://blog.bazel.build/2017/08/25/introducing-sandboxfs.html>.
- What is reused: The official Bazel binary, native `genrule`, standalone spawn
  strategy, and source-derived declared/undeclared-input oracle.
- Necessary custom glue: One BPF policy and one C controller create the two
  cgroups, register existing roots, install allowlist entries, and preserve raw
  observations. They do not implement a build system or process sandbox.

## Comparison

- Proposed method: Current `cgroup/namei_ext` build-action allowlist policy.
- Main baseline: None. This is RQ1 sufficiency; the separately frozen RQ2
  experiment owns the matched official-sandboxfs comparison.
- Controls: Direct lower-object metadata and byte observations before and
  after both actions; physically existing undeclared inputs; distinct expected
  output bytes; external BPF/FUSE inventory before and after the run.
- Information fairness: Both action cgroups receive one registered existing
  root and one declared `input.txt` allowlist entry. No table, materialization,
  symlink-forest, or FUSE row is added to this RQ1 experiment.

## Workloads And Metrics

- Real workload: Two Bazel 6.5.0 `genrule` builds execute concurrently in
  separate cgroups.
- Primary metrics: Successful Bazel exits; exact action A/B output bytes;
  undeclared-input lookup and readdir invisibility; positive lookup, readdir,
  `SELECT`, allow-lookup, allow-readdir, hide-lookup, and hide-readdir counters.
- Correctness: Both actions reach the barrier before release; saved lower input
  and undeclared files retain expected bytes; before/after device, inode, mode,
  and size match; output and lower files are ordinary lower-FS objects; policy,
  target, cgroup, and external BPF/FUSE state clean up; dmesg passes the
  declared kernel-failure scan.
- Repetitions: One real modified-kernel KVM preflight, followed by three fresh
  KVM boots with the unchanged workload and oracle.
- Cost: Approximately two minutes per boot.

## Planned Runs

| Run group | Role | Workload | System/method | Repetitions | Decision consequence |
|---|---|---|---|---:|---|
| preflight | dependency | Two concurrent Bazel genrules | current `namei_ext` allowlist | 1 boot | admits the unchanged formal matrix |
| formal | proposed | Same two-action lifecycle | current `namei_ext` allowlist | 3 fresh boots | supports W3 only if every boot passes |
| lower objects | control | Four selected/hidden lower files | direct lower-FS observation | once per boot | invalidates a boot if identity or bytes change |
| withdrawn/cleanup | control | policy and target teardown | kernel/external inventory | once per boot | invalidates a boot if state remains |

## Execution

- Authoritative preflight:
  `make kvm-build-action-sandboxing-preflight RUN_ID=<fresh-id>`.
- Formal command:
  `make experiment-build-action-sandboxing-rq1 RUN_ID=<fresh-id>`.
- Real preflight: One boot executes the complete two-action lifecycle and all
  controls, not a mock or object-file inspection.
- Full completion: Three terminal clean-source boots; all required case and
  counter records occur exactly once per boot; direct output/lower-file
  comparisons pass; cleanup and dmesg checks pass.
- Raw results:
  `results/experiments/build-action-sandboxing-rq1[-preflight]/<RUN_ID>/`.
- Recovery: A failed root remains unchanged and is excluded from formal
  evidence. No in-place retry is permitted.

## Interpretation

- Positive result: The current mechanism expresses this existing-object
  action-view subset for real Bazel actions without owning Bazel execution,
  output construction, lower file operations, or persistence.
- Negative or contradictory result: Remove W3 from current-policy RQ1 evidence
  and report the failed branch or semantic mismatch internally.
- Mixed or inconclusive result: Any failed action, branch, lower-object check,
  cleanup, or boot makes the formal result inconclusive.
- Target paper artifact: One compact W3 row in the RQ1 workload table, not a
  standalone performance figure.

## Reproducibility Notes

- Software: Bazel 6.5.0, modified kernel commit recorded by each result root.
- Configuration: `--batch`, standalone spawn strategy, one job per Bazel
  process, no Bzlmod, no network fetches.
- No random seed is used.
- The workflow records versions, commands, raw outputs, and object observations
  directly. It does not create checksum manifests.
