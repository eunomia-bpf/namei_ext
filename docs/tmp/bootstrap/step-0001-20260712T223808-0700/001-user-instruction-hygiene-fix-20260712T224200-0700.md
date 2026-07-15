# User-Instruction Hygiene Fix After Independent Review

Timestamp: 2026-07-12T22:42:00-07:00
Phase: BOOTSTRAP
Step: 0001
Status: complete
Parent:
`docs/tmp/bootstrap/step-0001-20260712T223808-0700/000-recovery-bootstrap-reentry-20260712T223808-0700.md`

## Question And Entry

An independent subagent review checked whether the BOOTSTRAP re-entry complied
with the current `auto-research-orchestrator` skill. It accepted the phase
routing and story direction, but found one hygiene issue:
`docs/user-instruction.md` still contained pasted assistant summaries and a
candidate RQ block that the user had quoted only to criticize.

The skill requires `docs/user-instruction.md` to contain user-authored prompt
text only. When a user prompt quotes an assistant answer or reference, only the
user's own request or critique should be logged as user authority.

## Inputs And Method

Read:

- subagent review verdict from agent `019f5a01-ecb8-7bf3-b5bc-31fe4b457ed9`
- `docs/user-instruction.md`

Edited only `docs/user-instruction.md`.

## Results

Removed the pasted non-user content from the instruction log:

- the quoted YoloFS/DockSmith/DeltaFS assessment;
- the quoted source-status summary for YoloFS/AgentFS/Redis AFS/Mirage;
- two copies of the RQ1/RQ2/RQ3/RQ4 candidate framing that the user was
  challenging.

Preserved the user's actual critiques and instructions, including:

- `我觉得这些得再看看，你提出来的基本上无意义`;
- `DeltaFS YoloFS 你确定没法实现一个？也搜索不到？再去仔细看看？AgentFS也需要看看？DeltaFS / IndexFS / TableFS 这些用了啥 workload？`;
- `都去研究并且复现，然后写一个复现报告，看看怎么用起来？`;
- the user's question that the previous RQ/contribution framing was
  `乱七八糟`;
- the later user-authored RQ corrections and mechanism ladder.

Validation scan:

```sh
rg -n "follow-up|instruction:|recovered prior prompt|Status:|Current default|assistant|superseded|root disposition|YoloFS：|DockSmith：|RQ1: Workload characterization|RQ4: Scope limits" docs/user-instruction.md
```

Result: no matches.

## Scientific Impact And Decision

This fix does not change the candidate story. It prevents assistant-authored
phrasing from becoming user authority during BOOTSTRAP. The active story remains
the strong `sched_ext`-style VFS name-resolution extension-point candidate, and
the active phase remains BOOTSTRAP.

## Completion And Next Action

The instruction-log hygiene issue is resolved. Continue the BOOTSTRAP
EXPERIMENT_GATE with current literature/novelty pressure before any renewed
freeze.
