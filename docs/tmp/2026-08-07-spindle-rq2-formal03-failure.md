# Spindle RQ2 Formal03 Failure

## Status

The result root
`results/experiments/spindle-staging-rq2/20260808T074422Z-w6-rq2-formal03/`
is a failed run and remains unchanged. It is not paper evidence. The matrix
completed its first `namei_ext` boot and stopped in its first FUSE boot.

The source tree was clean at commit `06c1a36176ec91259574b858bd48d72e516839be`
and the modified kernel was clean at commit
`b07117a3cb41826a34af5ca61e3e2c81dade793f`. The FUSE boot's prepare, cleanup,
inventory, and dmesg checks returned zero; its workload command returned 2
because the notification gate failed.

## Result

Changing notification order did not change the failure. For both permission
transitions, entry invalidation ran first and returned `-ENOENT`; the following
inode invalidation returned zero. The runner rejected the transition before
executing the independent permission probe. This falsifies the formal02
ordering hypothesis.

Both conditions again recorded `tmpfs` as the compiled-runtime lower
filesystem. The completed `namei_ext` arm passed its source and mechanism
oracles, but the pair is incomplete and has no comparative performance result.

## Primary-Source Correction

The exact-zero entry-notification rule is stricter than libfuse's public
contract for path invalidation. In pinned libfuse 3.18.2,
`include/fuse.h:fuse_invalidate_path()` explicitly documents `-ENOENT` as
meaning that there was no kernel entry to invalidate because it was unseen or
forgotten, and says this is not an error. The official
`example/notify_inval_entry.c` likewise treats `-ENOENT` from entry expiry as
"entry does not exist anymore in the kernel." The kernel implementation in
`fs/fuse/dir.c:fuse_reverse_inval_entry()` returns `-ENOENT` when the parent or
positive parent/name entry is absent.

Therefore, requiring every entry notification to return exactly zero does not
test feature-equivalent behavior. It turns an idempotent "nothing cached"
outcome into a baseline failure. Correctness should instead require:

- the inode notification used for backing-mode changes succeeds;
- an entry notification returns either zero or `-ENOENT`;
- after every state change, the application-level permission or withdrawal
  oracle observes the new state;
- any other notification error fails the run.

The application oracle is decisive: if `-ENOENT` masks a stale positive entry,
the next unprivileged open or withdrawn loader launch will observe the old
state and fail the condition.

## Plan Amendment Required

Revise the existing comparison plan and analyzer to follow the documented
libfuse contract, while preserving raw component statuses. This is a baseline
correctness correction, not a new hypothesis or a weaker workload. The paired
matrix, common tmpfs lower filesystem, cache settings, passthrough mode,
correctness probes, samples, repetitions, and primary metric remain unchanged.

The amended plan must receive an independent review before another full run.
Formal03 must not be reused or modified.
