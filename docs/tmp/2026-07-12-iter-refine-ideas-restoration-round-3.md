# Iter-Refine-Ideas Restoration Round 3

Date: 2026-07-12
Skill: `iter-refine-ideas`
Round: 3, Novelty, Experiments, And Results

## Objective

Check what prior work and experimental results would make researchers believe,
limit, or change the restored direction.

## Discussant Finding

The discussant accepted the restored idea and identified the novelty axis as
ownership boundary: eBPF owns bounded lookup/readdir policy while the kernel and
lower filesystem retain VFS and data semantics. The required repair was not to
shrink the paper, but to make the evidence matrix, closest-work comparison, and
failure interpretation explicit.

## Main-Agent Response

Accepted and applied:

- Added a falsifiable evaluation matrix with AgentFS workspace,
  environment/cache, and service/config rows.
- Added an ownership matrix distinguishing materialized namespaces, FUSE/source
  filesystems, custom filesystems/Bento, and `namei_ext`.
- Added explicit result standards and claim-changing outcomes.
- Strengthened Related Work around direct ownership comparisons with
  FUSE/ExtFUSE/Bento/Wrapfs, namespace construction, agent filesystems, and
  metadata services.
- Connected policy state to concrete workload state in Design.
- Added negative-result interpretation to Limitations.
- Promoted service/config to required characterization and expected third KVM
  deep dive for OSDI/SOSP scope.

Deferred:

- A polished figure is left to the `paper-figures` skill.
- Additional namespace/name-resolution related work remains for a later
  literature pass.

## Anti-Shrinkage Check

The accepted fixes require stronger evidence for the restored idea. They do
not reduce the paper to two workloads, table-only failure, or eBPF necessity.

## Validation

Validation is run after the corresponding paper edits in this turn.
