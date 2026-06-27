# Scoped weak-accept completion audit

## Motivation

The active research goal requires an OSDI-standard evaluation, a maintained
Chinese LaTeX paper under `docs/paper/`, and repeated independent reviewer-style
subagent review until the paper and evaluation reach weak-accept quality. This
record captures the current completion evidence without upgrading the claim to a
full release gate.

## Current stage

The project is at the stage 9--11 boundary: paper integration and
reproducibility audit. The current paper is not a full-scope release claim, but
the scoped paper claim is now weak-accept ready under the machine-readable claim
ledger and independent subagent review.

## Evidence inspected

- Paper sources: `docs/paper/main.tex` and `docs/paper/sections/*.tex`.
- Paper build artifact: `.build/paper/main.pdf`.
- Claim verdict ledger:
  `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict.jsonl`.
- Claim verdict input manifest:
  `results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict-inputs.sha256`.
- C7 artifact audit ledger:
  `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit.jsonl`.
- C7 artifact audit input manifest:
  `results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit-inputs.sha256`.
- Independent reviewer subagent: Plato, final read-only review of the v17/v11
  delta and W1/W3/W4 ledger-reference fix.

## Validation performed

```text
make -C docs/paper check
make -C docs/paper paper
sha256sum .build/paper/main.pdf
sha256sum -c results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict-inputs.sha256
sha256sum -c results/eval-osdi/paper/20260617T-eval-c7-artifact-audit-v11/artifact-audit/c7-artifact-reproducibility-audit-inputs.sha256
jq -e -s '...' results/eval-osdi/paper/20260617T-eval-claim-verdict-ledger-v17/claim-verdict/claim-verdict.jsonl
rg stale-run-id patterns over docs/paper/sections and current docs/tmp records
```

The paper check and paper target passed. The current PDF hash is:

```text
54bd918546651c43696c0163bf8665dca554a62ffc4f8df04f4557e89ba62122  .build/paper/main.pdf
```

Both input manifests replayed successfully. The claim-verdict predicate checked
that `weak_accept_ready=true`, `paper_release_gate_pass=true`,
`release_gate_pass=false`, and the highest-risk claims include C7 and C8.

## Subagent verdict

Plato reported no blocker and no must-fix issue for the final v17/v11 state.
The review confirmed:

- C7 v11 `sha256sum -c` passed.
- Claim v17 `sha256sum -c` passed.
- C7 remains scoped out with `c7_supported=false`,
  `release_gate_pass=false`, and only `clean checkout reproduction` missing.
- Claim v17 has `weak_accept_ready=true`, `paper_release_gate_pass=true`,
  global `release_gate_pass=false`, and highest risks C7/C8.
- Paper anchors use claim v17, C7 v11, W1 v7, W3 v7, and W4 v15.
- No stale v16/v10 or W1 v4/W3 v4/W4 v12 references were found in the current
  paper anchors.
- FUSE baseline/test evidence is represented in W1, C3, claim evidence, and the
  paper.
- C7 package replay uses a real `latexmk` paper replay and the package contains
  17/17 declared files.

The reviewer verdict was: scoped weak-accept holds. The same review explicitly
kept the full release gate open because C7 clean-checkout reproduction and C8
remain unfinished.

## Completion audit

The requested weak-accept condition is satisfied for the scoped paper:

- The evaluation is claim-first, uses named baselines, records raw result paths,
  and keeps negative W1/W3/W4, C5, C7, and C8 evidence in scope boundaries
  rather than overclaiming.
- The paper is a maintained Chinese LaTeX paper under `docs/paper/`, not a
  placeholder or outline.
- The final machine-readable claim ledger reports four supported active main
  claims, four scoped-out claims, zero partial claims, zero unsupported claims,
  `weak_accept_ready=true`, and `paper_release_gate_pass=true`.
- Independent subagent review accepted the current scoped state with no blocker
  or must-fix issue.

## Remaining risks

This record does not claim submission-ready full release reproducibility:

- C7 still lacks clean-checkout reproduction because the main repository and
  kernel submodule are dirty.
- C8 still lacks release-level table/update budget failure or a stronger
  operation-weighted policy-cache result.
- C5 residual overhead and C6 stress/scale evidence remain outside the active
  main claim.

These risks are preserved as explicit scope boundaries in the paper and claim
ledger.
