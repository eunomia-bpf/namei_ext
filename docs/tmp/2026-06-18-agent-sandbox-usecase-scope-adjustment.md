# Agent Sandbox Use-Case Scope Adjustment

## Motivation

The paper discussion briefly expanded the prospective agent sandbox use case to include eval isolation. That is not needed for the current paper story and would create an extra correctness and security-adjacent claim. This note records the narrower organization so later experiment planning does not drift.

## Decision

The paper should use three top-level use cases:

1. Agent sandbox lifecycle.
2. Service fixture sandbox.
3. Content-verified cache view.

Fork, fanout, checkpoint rollback, restore, and deterministic trace replay are sub-experiments inside agent sandbox lifecycle. They are not separate use cases. Eval isolation is explicitly out of scope for this use case.

## Agent sandbox lifecycle scope

The agent sandbox lifecycle use case should measure path-view operations needed by coding-agent sandboxes:

- workspace fork or fanout from a pinned repository state;
- checkpoint rollback or restore after a failed edit/test path;
- deterministic file-operation trace replay from pinned tasks, preferably SWE-bench-style repository tasks rather than live LLM runs;
- workspace materialization/update cost under repeated edits.

The core oracle is not "agent solved the task". The oracle is deterministic sandbox state behavior:

- expected workspace files and hashes are visible after fork or rollback;
- stale files from a later generation are not visible after rollback;
- post-rollback lookup/readdir/open/stat traces resolve to one declared generation;
- if checkpoint generations are part of the experiment, the mixed-epoch count is zero;
- raw trace replay preserves expected errno/content/hash outcomes.

## Non-goals

Eval isolation is out of scope. It would require benchmark harness, secret/future-state, or adversarial isolation claims that are not necessary to show the VFS path-resolution mechanism. It also overlaps with the separate service fixture sandbox line, where config/secret/cert/endpoint fixture substitution is already the relevant correctness story.

The paper should also avoid claiming that current W3 Redis RDB replay is a real restore benchmark. It can remain as negative or preliminary evidence unless replaced by a real sandbox checkpoint/rollback or Podman/CRIU restore workload with fresh post-restore VFS operations.

## Baselines

The agent sandbox lifecycle baseline family should be feature-equivalent for workspace state management:

- copy-tree workspace clone;
- git worktree or checkout/reset where it matches the operation;
- bind/symlink/projection only for operations they can faithfully express;
- FUSE redirect for programmable user-space path remapping;
- native filesystem snapshot only if the experiment environment can provide it reproducibly.

Native direct execution is a lower-bound reference, not a feature-equivalent baseline for fork or rollback.

## Consequence for current workload names

W1 build graph should not remain a standalone main use case unless it is redesigned around agent sandbox traces. It can be folded into the agent sandbox lifecycle as a trace replay source.

W2 nginx fixture remains the service fixture sandbox use case and should keep its own app health, endpoint, and no-production-open oracles.

W4 ccache or a stronger BuildKit/cache workload remains the content-verified cache view use case. It still needs a stronger positive result or should be reported as mixed/negative evidence.
