# Redirect Table Novelty Position

> 2026-06-29 baseline scope update: this historical record preserves prior reasoning and results. Current C8/B12 guidance is claim-driven baseline selection; exact-map diagnostics are optional boundary evidence only when precomputed mapping is the competing claim.

## Motivation

This note records the outcome of the 2026-06-29 discussion about whether
`namei_ext` should keep centering the "redirect table" question.

The short answer is no: a `logical path -> backing path/blob/layer` table is
not the novelty. Existing FUSE filesystems, stackable/custom filesystems,
OverlayFS-style views, build output services, and object-store mounts have
already solved many forms of path-to-backing indirection. If the paper's claim
is only "redirect one path to another", the claim is weak.

The defensible position is narrower:

> `namei_ext` is a lightweight VFS name-resolution extension point. It lets an
> eBPF policy choose lookup and directory-enumeration behavior while the kernel
> and lower filesystems keep ownership of VFS objects, permissions, file
> operations, persistence, and POSIX-ish semantics.

That is different from a BPF filesystem, and it is also different from a plain
manifest. The research question should be whether this narrow point is useful
for path-view policy that is too narrow to justify a full FUSE or custom
filesystem, but still benefits from being enforced at VFS name resolution
rather than in an application-specific control plane.

## Materials inspected

- User-provided redirect-table research note:
  `/home/yunwei37/.codex/attachments/9e45e708-e609-4272-87dc-330de3d18135/pasted-text.txt`
- `docs/tmp/2026-06-29-c8-fuse-custom-fs-table-survey.md`
- `docs/tmp/2026-06-29-deltafs-yolofs-survey.md`
- `docs/tmp/2026-06-18-agent-sandbox-usecase-scope-adjustment.md`
- `docs/tmp/2026-06-17-tool-redirect-performance-scope-ledger.md`
- `bpf/policies/README.md`

The inspected notes already cover FUSE, OverlayFS, Bazel/Buck remote output
materialization, EdenFS redirections, object-store FUSE mounts, DeltaFS,
YoloFS, BranchFS, and the current Phase 1 policy families. This note does not
replace those surveys. It records the positioning decision that follows from
them.

## Decision

Do not make "redirect table" the novelty story.

Do not make `table_redirect.bpf.c` a mandatory baseline for every claim. It is
only a diagnostic counterfactual for workloads where the paper explicitly
claims value over an exact precomputed mapping. If the real claim is
"lighter-weight than FUSE/custom FS for a narrow name-resolution view", then
the relevant comparison may instead be FUSE, materialized trees, bind mounts,
OverlayFS, namespace setup, or the application/runtime mechanism that current
systems actually use.

The paper should say:

- Redirect tables, manifests, and path-to-object maps are known techniques.
- Many existing systems already use FUSE or custom filesystems because they
  need transparent filesystem boundaries, not because they failed to think of
  path redirection.
- `namei_ext` only targets the subset where the system needs programmable
  name-resolution decisions, not ownership of the data path or filesystem
  semantics.
- If a simpler workload-appropriate mechanism satisfies the same oracle within
  the same setup, update, correctness, and performance budget, the stronger
  `namei_ext` claim is unsupported for that workload. That simpler mechanism
  may be a table, but it does not have to be.

The current invariant should remain: `namei_ext` is not a BPF filesystem.
Policy is an eBPF program under `bpf/policies/*.bpf.c`; lookup and directory
enumeration are event types passed to one kernel-facing BPF decision function.

## Why "why not just redirect?" is already answered by related work

A redirect table is a naming structure. It can answer "where should this
logical path point?" It usually does not, by itself, provide a filesystem
boundary.

Existing systems use FUSE or custom filesystems because they often need at
least some of these properties:

- arbitrary unmodified tools must work through `open`, `stat`, `readdir`,
  `rename`, `readlink`, `mmap`, and similar system calls;
- directory enumeration must match lookup results;
- metadata such as mode, mtime, xattrs, symlinks, hardlinks, and negative
  lookups must be authoritative enough for build tools, package managers,
  IDEs, shells, and debuggers;
- open file descriptors must remain meaningful after rename or unlink;
- remote CAS, object-store, git, or blob data must be lazily materialized;
- writes need copy-on-write, staging, tombstones, journaling, commit/abort,
  rollback, fork, garbage collection, or audit state;
- cache validity, stale objects, corrupt objects, and generation changes must
  be handled at runtime.

Those are not just "redirect path A to path B" problems. FUSE and custom
filesystems are used because they expose a normal OS filesystem interface while
implementing metadata, caching, materialization, and lifecycle semantics
behind that interface.

Therefore, the paper should not imply that prior systems chose FUSE only
because they lacked a redirect table. They chose FUSE/custom FS because their
problem was broader than a table.

## What redirect remains good for

Redirect is still useful, but its role should be scoped:

- It can be an internal representation inside a larger filesystem or runtime.
- It can be a hot-path bypass for generated output, temporary files, package
  caches, logs, and large sequential writes.
- It can be a sanity check for simple path-view workloads.
- It can be a counterfactual when the paper makes a claim specifically about
  dynamic policy adding value over exact mapping.

This matches the EdenFS-style lesson from the prior notes: virtualize the
source tree and remote/read-mostly artifacts, but redirect or bind-mount
write-heavy generated directories when they do not need the virtual
filesystem's semantics.

## What `namei_ext` can still claim

The plausible claim is not "we replace FUSE" or "we invented redirect." The
plausible claim is:

> Some path-view workloads need dynamic policy during lookup and directory
> enumeration, but do not need a new filesystem implementation. `namei_ext`
> exposes that smaller decision point to eBPF while preserving lower-filesystem
> ownership of VFS objects and file operations.

This can be valuable when:

- the view depends on bounded runtime state such as branch, epoch, cache
  validity, or workload family;
- `readdir` and lookup must stay consistent without materializing a whole tree;
- FUSE is too broad or too expensive for metadata-heavy name-resolution slices;
- a workload-specific setup mechanism would need expensive materialization,
  repeated namespace updates, or unsafe stale windows;
- the desired semantics stop at name resolution and do not require owning
  create, unlink, rename, writeback, fsync, mmap, file locking, or storage
  layout.

That last boundary is important. If the workload needs agent-style staging,
rollback, snapshot travel, progressive permission, content storage, or process
checkpoint state, then `namei_ext` can at most provide a lower-level
name-resolution component. It is not YoloFS, BranchFS, DeltaFS, CRIU, or a VM
snapshot system.

## Paper positioning consequences

Avoid these claims:

- "Redirect tables are the new idea."
- "FUSE/custom filesystems are unnecessary because a redirect table can do the
  same thing."
- "`namei_ext` is a general programmable filesystem."
- "`namei_ext` replaces FUSE, OverlayFS, object-store mounts, or agent-native
  filesystems."
- "A static table failing one configuration proves policy novelty in general."
- "Every use case needs a redirect-table baseline."

Prefer these claims:

- "`namei_ext` is a narrow programmable path-resolution extension."
- "The kernel and lower filesystem retain object ownership and file-operation
  semantics."
- "FUSE/custom filesystems remain the right abstraction when a system must own
  metadata, data, writeback, lifecycle, or compatibility semantics."
- "Table-only redirect is an optional diagnostic counterfactual when the claim
  is specifically about exact mapping versus dynamic policy."
- "The contribution is only supported where `namei_ext` beats the
  workload-appropriate simpler mechanism under the declared correctness,
  setup, update, stale-window, and performance budgets."

This also means related work should acknowledge prior systems generously.
They solved broader problems. Our question is whether a smaller kernel hook is
useful in the narrower region between static materialization and a full
filesystem boundary.

## Experiment consequences

C8 should be claim-driven, not redirect-table-driven. It should not ask only
whether a table can encode the final aliases. A table can encode many final
views after the state has already been computed, and many workloads should be
compared against more natural mechanisms than a table.

The sharper question is:

> What is the simplest mechanism that already satisfies this workload's
> correctness contract, and does `namei_ext` improve on it without taking over
> filesystem semantics?

For cache-locality workloads, the natural baselines may be native ccache,
BuildKit/Bazel-style cache behavior, materialized cache directories, FUSE, or
an exact table if the claim says table materialization is insufficient. If the
table is included, charge it for updates needed to track hit, miss, stale,
corrupt, and epoch changes. But do not make the table comparison the center of
the claim unless reviewers would otherwise reasonably reduce the mechanism to
exact mapping.

For agent-sandbox or build-trace workloads, the natural baselines are likely
copy tree, git worktree/checkout, OverlayFS, bind/symlink projection, FUSE
branching filesystems, YoloFS/BranchFS-style systems where applicable, and
runtime checkpoint mechanisms. A table comparison is useful only if the
claimed contribution is specifically that dynamic lookup policy avoids
precomputing exact per-action or per-branch views.

For service fixture substitution, the current W2-style workload is mainly
setup/materialization evidence. It should not be expected to prove a
redirect-table argument. Its better role is to show that a narrow VFS
name-resolution hook can express fixture substitution without implementing a
filesystem or rewriting the service.

For performance claims, the `tool_redirect` scoped ledger remains useful but
must stay scoped. It supports a narrow metadata-operation slice, not a
full-suite FUSE/native performance claim.

## Alternatives rejected

### Treat redirect table as the contribution

Rejected. This is too weak because many systems already use manifests,
path-to-object mappings, redirection, bind mounts, overlay mechanisms, or FUSE
views. A reviewer can fairly reduce this to "just a table" unless experiments
show dynamic policy value beyond exact mapping.

### Claim FUSE/custom FS are obsolete

Rejected. FUSE and custom filesystems solve broader compatibility,
metadata, data-path, lifecycle, and storage problems. `namei_ext` intentionally
does not own those semantics.

### Make the table baseline mandatory

Rejected. This would keep the paper centered on redirect tables even when the
real comparison should be FUSE, materialized namespace setup, OverlayFS,
bind/symlink projection, or an application-specific runtime. Use the table
baseline only when the claim being tested is exact mapping versus dynamic
policy.

### Drop table artifacts entirely

Rejected. `table_redirect.bpf.c` is still useful as a diagnostic and as a
guardrail against accidentally reducing a policy family to an exact
`component -> target` lookup. It should not dictate the whole evaluation.

### Avoid the word redirect entirely

Rejected. Redirect is still the concrete VFS action and remains useful for
lookup/readdir behavior, hot-path bypass, and counterfactual tests. The fix is
to stop treating redirect as novelty, not to hide it.

## Validation performed

This was a documentation and positioning step. No build, KVM boot, or Phase 1
runtime validation was run. That is intentional: this note does not claim a
new implementation result.

Consistency checks performed:

- confirmed existing survey notes already distinguish FUSE/custom FS from
  table-only counterfactuals;
- confirmed `bpf/policies/README.md` keeps `table_redirect.bpf.c` scoped to
  exact map lookup behavior;
- confirmed the current policy family documentation warns that collapsing all
  policies to `component -> target` table lookups would no longer support the
  OSDI C8 programmability claim.

## Remaining risks and follow-up

- The paper still needs a concise related-work paragraph that says this
  explicitly: prior FUSE/custom FS systems already solve broad redirection and
  filesystem-boundary problems; `namei_ext` explores a narrower point.
- C8 remains workload-dependent. If the workload-appropriate simpler baseline
  passes under declared budgets, the corresponding `namei_ext` claim should be
  weakened or dropped.
- Agent-sandbox framing is risky unless the paper clearly states that
  `namei_ext` does not provide write staging, rollback, process checkpointing,
  or safety policy by itself.
- The evaluation should keep exact table, updated table, FUSE, materialized,
  bind/OverlayFS, and native references separated when they are used. Mixing
  them into one "redirect baseline" would blur the argument this note is
  trying to fix.
