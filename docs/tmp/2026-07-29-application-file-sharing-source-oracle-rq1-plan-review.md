# Plan Review: RQ1 XDG Documents Portal Source Oracle

## Round 1

The independent reviewer admitted the experiment as a non-redundant W1
source-fidelity repair but returned `NO-GO` for execution until the following
points were frozen:

1. map the portal's real
   `$MOUNT/by-app/$APP/$DOC_ID/$BASENAME` hierarchy to the existing
   `namei_ext` logical hierarchy;
2. probe immediately after grant/revoke returns, with no sleep, polling, or
   retry and a fresh directory stream in every state;
3. specify a Make-owned pinned-source build path and preserve its build/test
   evidence;
4. require all five upstream tests to execute with zero skip, while stating
   that upstream 1.18.4 tests do not cover revoke;
5. describe the shared behavior as per-application view isolation because the
   source controller addresses official `by-app` paths while only the
   `namei_ext` arm uses cgroups;
6. freeze `Add` flags, application IDs, basename, bytes, permission arrays,
   arm order, midpoint cleanup, and exact `ENOENT` checks.

The experiment plan now includes each item. The upstream source arm runs first,
must tear down completely, and is separated from the `namei_ext` arm by an
empty external inventory. The common oracle compares exact per-operation
success or `ENOENT`, enumeration membership, and visible bytes. It does not
compare the portal's virtual inode with the host inode.

Round 1 verdict: `NO-GO` pending the recorded repairs and one follow-up review.

## Round 2

The reviewer rechecked the repaired plan and the concrete builder path. A
non-root container run produced five FUSE skips, which the frozen zero-skip
gate correctly rejects. Running the pinned source build/test image as root with
`--privileged --device /dev/fuse` executed all five upstream subtests, with
zero skip, failure, and timeout; returning the build-tree ownership to the host
UID/GID closes the artifact-permission issue.

No blocking or major finding remains before implementation and one real KVM
preflight.

Round 2 verdict: `GO`.
