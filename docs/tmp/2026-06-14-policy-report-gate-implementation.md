# Policy gate report integration

Date: 2026-06-14

## Motivation

After adding `kvm-policy-load` and `kvm-policy-semantic`, the top-level
`make phase1` flow executed the new gates, but `mk/report.mk` still only
reported the older smoke, ABI, functional, benchmark, and Docker artifacts.
That created a gap: the Make target could pass policy gates without the report
explicitly checking or listing their raw JSONL files.

## Files changed

- `mk/report.mk`

## Design

The report now treats policy gates as first-class Phase 1 artifacts:

- `policy-load.jsonl` must exist and be non-empty.
- `policy-semantic.jsonl` must exist and be non-empty.
- every `policy-load` row must have `pass:true`;
- every `policy-semantic` row must have `pass:true`;
- exactly one `policy-semantic-summary` row must have `pass:true`;
- the semantic summary `failures` count must be zero.

The generated `summary.md` now includes:

- policy-load failure count;
- policy-semantic failure count;
- policy-semantic summary failure count;
- a policy-load table;
- a policy-semantic table;
- raw artifact links for policy-load, policy-semantic, and their dmesg logs.

## Alternatives Rejected

- Leaving policy gates out of `summary.md` was rejected because Phase 1 report
  consumers should not need to infer that new raw files matter.
- Aggregating only the final semantic summary was rejected because branch-level
  rows are the evidence that each family exercises distinct lookup/readdir
  semantics.

## Validation

Expected checks:

```text
make report RUN_ID=<existing-run-id>
git diff --check
```

The report gate is still smoke-scale evidence. It does not change the rule that
OSDI C1/C8 require real workload rows to become `validated`.

Observed result:

- `make phase1` passed before the report fix with run id
  `20260614T045335Z-a476f6e2`.
- After updating `mk/report.mk`, `make report RUN_ID=20260614T045335Z-a476f6e2`
  passed.
- Updated summary:
  `results/phase1/20260614T045335Z-a476f6e2/summary.md`.
- The summary now reports:
  - `Policy-load failing cases: 0`
  - `Policy-semantic failing cases: 0`
  - `Policy-semantic summary failures: 0`
- A raw JSONL scan found no `"pass":false`, nonzero semantic `failures`, or
  benchmark `"fail"` rows in the run's JSONL files.
