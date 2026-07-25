# Historical Follow-Up Plan

Status: historical provenance only.
Last routing update: 2026-07-02.

This file is no longer the active follow-up plan. Current next action belongs
in `research/STATE.md`; current paper direction belongs in
`docs/idea-story.md`; related-work, novelty, source-use, and comparison verdicts
belong in `docs/background-related-work.md`.

Current next actions:

1. Restore and maintain the main paper idea: `namei_ext` is a
   `sched_ext`-style VFS extension point in the sequence
   bind/Overlay/materialization < eBPF LSM < `namei_ext` < FUSE/custom
   filesystems.
2. Implement one Make-owned, KVM-validated AI agent workspace complete
   experiment using the reproduced source pool.
3. Implement one environment/cache complete experiment with a real correctness
   oracle, FUSE policy comparison, and custom/stackable FS boundary evidence.
4. Keep service/config as conditional scope evidence, and upgrade it only with a
   real reload/update or secret/config rotation trace.
5. Treat DeltaFS, IndexFS, and TableFS as related-work or appendix workload
   shapes, not as the main next experiments.
6. Treat narrow diagnostic-comparison rows as archived boundary evidence only.

Do not add new narrow-comparison, interface-exclusivity, or exclusive-necessity
plans here. Do preserve the positive claim that real workloads can exercise
dynamic state-dependent path-view policy.
