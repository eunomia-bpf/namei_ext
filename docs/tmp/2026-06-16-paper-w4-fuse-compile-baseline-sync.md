# Paper Sync For W4 FUSE Compile Baseline

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## Motivation

After the W4 bulk FUSE compile-through baseline passed and entered the W4
workload ledger, the paper still described W4 as missing a complete
compile-through-FUSE comparator. That was stale and could mislead the claim
scope.

## Files Updated

- `docs/paper/main.tex`
- `docs/paper/sections/01-introduction.tex`
- `docs/paper/sections/05-evaluation.tex`
- `docs/paper/sections/07-limitations.tex`

## Edit Scope

The edits update W4 evidence status only:

- W4 bulk now lists the complete compile-through-FUSE baseline alongside the
  materialized/FUSE cache-view baselines and policy setup/update release input.
- The C2 claim row points to the v9 W4 workload ledger.
- The text preserves the negative W4 verdict because setup/update/materialization
  gates and C8 remain unsupported.
- Native/cache-remap/BuildKit are no longer described as required evidence for
  the already-closed compile-through-FUSE gap.

## Validation

Validation ran through the paper Makefile:

```text
make -C docs/paper check
make -C docs/paper paper
```

Both commands passed. The PDF build still reports existing overfull box and
large-float warnings, but there were no LaTeX build failures.

## Remaining Risks

The paper is still a claim ledger and evaluation contract rather than a
submission-ready OSDI paper. W4 remains a negative result, and C8 remains
unsupported because the current sampled table-only comparators still pass.
