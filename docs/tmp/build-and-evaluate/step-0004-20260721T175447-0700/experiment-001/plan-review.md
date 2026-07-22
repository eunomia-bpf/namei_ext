# Plan Review: RQ1 Agent Workspace Expressiveness

## Inputs

- `AGENTS.md`
- `experiment-001/plan.md`
- Agent-workspace definitions and recipes in `mk/kvm.mk`
- `tests/agent_workspace/Makefile`
- The argument parsing, source-trace gate, lifecycle, correctness checks, and cleanup/control flow in both Agent workspace C runners
- Read-only expansion probe: `make -n experiment-agent-workspace RUN_ID=plan-review-probe`

## Findings

- **RQ fit and admission value:** sound. The integrated AgentFS-derived lifecycle directly tests whether the narrow `cgroup/namei_ext` boundary can express state-dependent lookup/readdir views while lower-FS operations remain authoritative. It adds headline evidence beyond isolated policy tests, and positive versus contradictory outcomes lead to different RQ1 decisions.
- **Direct correctness:** sound in design. The runner checks reads, stats, symlinks, readdir visibility, cached-negative create, rename, unlink, executable access, final state, lower-tree placement/non-materialization, policy attachment/counters, and unregistered-target containment. These are direct observations rather than a derived aggregate score.
- **Controls and fairness:** the no-hook checks are useful lower-FS controls and the FUSE lifecycle broadly mirrors the same hard-coded state and operations. However, only the `namei_ext` runner can receive and validate the fixed source-trace artifact; the FUSE runner merely emits a hard-coded `fuse_agentfs_source_trace_declared` pass. Therefore the claimed independent same-source-oracle control is not actually bound to the same artifact. This must be repaired if that control is used to rule out a method-tailored oracle.
- **Repetitions:** the plan explicitly requires three fresh terminal KVM runs and all three passing. The Make matrix recipe produces one run directory per `RUN_ID`; three distinct invocations can satisfy the plan, but the target does not itself aggregate or verify three-run completion. Execution/reporting must retain all three run IDs and verify the conjunctive rule.
- **Entrypoint executability:** `make experiment-agent-workspace` resolves to the real build/KVM workflow, but its current matrix recipe cannot complete successfully.

## Blockers

1. **Known:** `mk/kvm.mk` invokes the matrix `namei_ext` runner without its required `SOURCE_TRACE` argument. Matrix mode emits a failed `agentfs_source_trace_artifact` case and exits before the lifecycle.
2. **Additional executable blocker:** after that argument is supplied, the Make completion loop requires a passing case named `agentfs_source_trace_declared`, but the `namei_ext` runner emits `agentfs_source_trace_artifact` and `agentfs_source_trace_replayed`; it never emits `agentfs_source_trace_declared`. Thus the authoritative target still fails even for a valid trace and completed lifecycle.
3. **Scientific control blocker:** the FUSE control does not accept or validate the fixed source trace. Its unconditional declaration cannot support the plan's claim that both realizations use the same fixed source artifact/oracle. Either bind both runners to the same trace and gate both results, or narrow the control claim so it is not used as source-provenance evidence.

## Verdict

**BLOCKED pending repair, then rereview.** The hypothesis, admission rationale, workload, and direct correctness metrics are worthy of execution, but the authoritative command is not currently completable and the source/control provenance claim is not yet fair. Preserve the three-run requirement as three fresh terminal run directories after the repaired preflight; no broader workload or extra baseline is required.

## Follow-Up Review Round 2

### Inputs

- Current experiment plan.
- Repair diff for `mk/kvm.mk`.
- Repair diff for `tests/agent_workspace/namei_ext_agent_workspace_fuse.c`.

### Findings

- **Blocker 1 resolved:** Make now defines the fixed source trace, records and hashes it, and passes it as the required fourth matrix argument to the `namei_ext` runner.
- **Blocker 2 resolved:** the completion loop now requires the event names actually emitted by that runner: `agentfs_source_trace_artifact` and `agentfs_source_trace_replayed`.
- **Blocker 3 resolved:** matrix-mode FUSE now requires the same source-trace path, validates it with the same trace check, emits gated artifact/replay cases, and Make requires both cases. The independent realization is therefore bound to the same fixed source artifact.
- **Three-run completion remains sufficient:** the plan requires three fresh terminal invocations with distinct `RUN_ID` values and a conjunctive three-of-three interpretation. One run directory per invocation is compatible with that rule; aggregation inside a single Make process is not necessary.
- **Stronger FUSE symmetry is valid:** the control now creates/chmods the same executable tool, measures open/access/exec, times the same create/rename/unlink lifecycle, and exposes those metrics to Make's fail-fast completion checks. These additions close operation-coverage asymmetry and do not change the RQ1 oracle or promote timing to an RQ1 claim. No new result-invalidating defect is visible in the repairs.
- **Nonblocking polish:** the separate dependency preflight recipe still does not pass the trace, although the paper-facing matrix requires and validates it for both realizations. This does not invalidate a completed matrix result, but passing the trace in preflight would align that recipe more literally with the plan's source-trace preflight wording.

### Verdict

**APPROVED for real preflight and the three-run full execution.** All three prior blockers are resolved, the authoritative matrix path is internally executable from the reviewed repairs, and the strengthened FUSE symmetry introduces no scientific or executable blocker.
