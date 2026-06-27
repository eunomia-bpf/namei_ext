# C4 Lookup/Readdir Matrix Ledger

## Motivation

The claim verdict ledger previously marked C4 as partial because lookup/readdir
consistency was described only as scattered Phase 1 oracle evidence. The paper
needed a single Make-owned, raw-artifact-backed matrix that checks all declared
W1--W4 policy-family oracle rows before upgrading C4.

## Inputs Inspected

- `results/phase1/<run>/w1-oracle.jsonl`
- `results/phase1/<run>/w2-oracle.jsonl`
- `results/phase1/<run>/w3-oracle.jsonl`
- `results/phase1/<run>/w4-oracle.jsonl`
- `configs/eval-osdi/claim-verdict.jq`
- `mk/eval_osdi.mk`

The raw oracle files already contain per-entry lookup and readdir rows in the
modified-kernel KVM path, plus per-policy summary rows for the programmable
policy and `table_redirect` baseline.

## Design

The new C4 ledger is a derived paper-level ledger, not a replacement for the KVM
oracle runs. It reads existing KVM oracle JSONL files and emits one row for each
declared policy family:

- W1 build graph: `build_graph`
- W2 sandbox fixture: `sandbox_fixture`
- W3 checkpoint/restore: `checkpoint_restore`
- W4 cache locality: `cache_locality`

For each family, the ledger requires:

- the family summary row passes with zero failures;
- the number of passing lookup rows equals the declared oracle entry count;
- the number of passing readdir rows equals the declared oracle entry count;
- lookup and readdir rows have the same unique entry identity set, keyed by
  `(workload, branch, visible, effective_shadow)`;
- neither lookup nor readdir contains duplicate entry keys;
- there are no failed rows for the programmable policy.

The summary row sets `c4_supported=true` only when all four families pass. The
scope is explicit: this supports the declared W1--W4 Phase 1 lookup/readdir
matrix, not C8 table-only insufficiency and not full real-workload correctness
by itself.

## Implementation

- Added `configs/eval-osdi/c4-lookup-readdir-matrix.jq`.
- Added `eval-osdi-c4-lookup-readdir-ledger` and `eval-osdi-c4-lookup-readdir`
  to `mk/eval_osdi.mk`.
- Added C4 ledger variables, input SHA256 checks, lower oracle manifest checks,
  summary/manifest generation, and a hard gate requiring all four families.
- The C4 JQ emits per-family `lookup_unique_keys`, `readdir_unique_keys`,
  duplicate-key counts, and lookup-only/readdir-only key sets. This prevents a
  duplicate row from masking a missing lookup or readdir entry.
- The C4 result-level workload labels are paper-scope labels. For W3 they use
  checkpoint fixture wording rather than Podman/CRIU wording, because this
  matrix only covers declared Phase 1 oracle entries.
- Updated `configs/eval-osdi/claim-verdict.jq` so C4 becomes supported when the
  C4 matrix ledger passes.
- Extended `eval-osdi-claim-verdict-ledger` to require the C4 ledger and include
  it in the claim-verdict input manifest.

## Alternatives Rejected

- Rerunning KVM just to produce a differently shaped C4 artifact was rejected.
  The authoritative lookup/readdir rows already exist in the KVM oracle raw
  files, and the missing piece was a paper-level hard gate over those rows.
- Treating `table_redirect` pass rows as C8 support was rejected. The table rows
  remain useful boundary evidence, but C8 requires table/update budget or
  stale-window failure that these path-oracle rows do not establish.

## Validation Plan

Run the C4 ledger against an existing Phase 1 KVM root:

```text
make eval-osdi-c4-lookup-readdir-ledger \
  RUN_ID=<new-c4-run> \
  EVAL_OSDI_C4_PHASE1_RUN_ID=<phase1-run-with-w1-w4-oracles>
```

Then run `eval-osdi-claim-verdict-ledger` with `EVAL_OSDI_CLAIM_C4_RUN_ID`
pointing to the generated C4 ledger. The hard gate should require four supported
main claims, zero partial claims, and C4 `slice_gate_pass=true`.

## Remaining Risks

This ledger improves the C4 claim only within the declared Phase 1 oracle
matrix. It does not remove the broader paper limitations around C6 stress,
C7 clean-checkout reproducibility, or C8 table-only insufficiency.
