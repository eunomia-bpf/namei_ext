# Round 3: Logic Flow

## Skill Step

`iter-refine-writing` round 3: logic flow.

## Reviewer Finding

The review found three blocking consistency problems:

1. The environment/cache matrix was described as a primary workload, but the
   implementation still lacks final-file target selection. This made the
   evaluation look stronger than the prototype can currently support.
2. The Agent workspace workload risked being described as only a selected
   path-view slice, which weakened the agreed claim that the matrix runs a
   complete lifecycle while attributing only name-resolution decisions to
   `namei_ext`.
3. RQ3 used "safer" without an operational definition. The paper needed to
   define safety as policy-output safety and containment, not as full
   filesystem correctness.

## Fixes Applied

- Rephrased the introduction's gap as a narrow boundary between access-control
  hooks and filesystem-service ownership.
- Added representative path-view examples in the motivation:
  Agent workspace lifecycle and environment/cache transition.
- Updated the experiment-shape table so the Agent row runs a complete fixed
  lifecycle but attributes only lookup/readdir decisions to `namei_ext`.
- Marked final-file target selection as a prerequisite for the environment/cache
  row to become final file-object evidence.
- Rewrote RQ1 to say admitted workloads run the complete lifecycle or fixed
  replay required by the source oracle, while `namei_ext` evidence is limited
  to lookup/readdir effects.
- Rewrote RQ2 to require feature-equivalent FUSE rows under identical delegated
  lifecycle behavior.
- Operationalized RQ3 safety as eBPF verifier bounds, kernel validation of
  action outputs, fail-closed malformed decisions, and lower-filesystem
  ownership of permissions, data operations, writes, and persistence.
- Added a related-work boundary ladder that places namespace construction,
  access hooks, `namei_ext`, FUSE/stackable/custom filesystems, and metadata
  services in one ownership ordering.

## Validation

- `make -C docs/paper paper` passed.
- The generated PDF is `/home/yunwei37/workspace/namei_ext/.build/paper/main.pdf`.
- The current draft is 15 pages, so later rounds still need compression before
  it can be treated as an OSDI/SOSP-length paper draft.

## Remaining Risks

- The environment/cache matrix remains a claim target, but final evidence
  requires implementation work for final-file target selection.
- The current draft still has unanswered RQ evidence slots because final KVM and
  feature-equivalent FUSE rows have not been run.
- Later writing rounds must cut page count without shrinking the hypothesis back
  into a weaker workload slice.
