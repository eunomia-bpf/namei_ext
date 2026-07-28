# Agent Workspace RQ2 Formal v2 Analysis Failure

## Purpose

This record preserves the failure of the first full run after the
publication-control preflight. The failure is an artifact serialization
defect. It is not a workload correctness failure or a negative performance
result.

The result root is:

```text
results/experiments/agent-workspace-rq2/20260727T-agent-workspace-rq2-formal-v2
```

## Completed Work

The clean-source run at commit
`bedc5a46a0912da4ffd27ce0ad34da7602778767` completed all ten paired blocks and
twenty independent KVM boots. Before analysis:

- all twenty guest boot records completed;
- all vCPU-affinity proofs and guest start barriers passed;
- all required source-derived oracles passed;
- all 20,000 lifecycle samples and the other declared sample-count gates
  passed;
- all input and runtime artifact hashes passed;
- all guest.mk identity checks passed; and
- every dmesg and clocksource gate passed.

The finalizer reached the report target.

## Failure

The host matrix appended launch-order objects with plain `jq -n`. Each object
therefore occupied multiple lines even though the artifact was named
`launch-order.jsonl`. The finalizer used `jq -s`, which accepts a whitespace
separated stream of pretty-printed JSON objects and therefore did not enforce
the one-object-per-line contract.

The strict analyzer correctly read the artifact one line at a time and failed
on line 1:

```text
invalid JSON: Expecting property name enclosed in double quotes: line 2 column 1
```

No analysis directory or performance verdict was accepted. The run is marked
failed with reason `launch-order-jsonl-contract`.

## Repair

- The launch-order writer now uses `jq -c -n`.
- The finalizer requires exactly two launch-order lines per paired block in
  addition to validating the ordered JSON stream and its schema.
- A Make-owned failure target records terminal failed state and a reason.
- The analysis target invokes that failure target if the analyzer or artifact
  contract fails.

## Decision

The raw formal-v2 root is preserved and will not be rewritten or compacted.
The hypothesis, workload, FUSE baseline, CPU placement, correctness oracle,
sample counts, paired-boot protocol, and analysis remain unchanged. A fresh
formal-v3 result root will rerun all twenty boots from the repaired clean
commit.
