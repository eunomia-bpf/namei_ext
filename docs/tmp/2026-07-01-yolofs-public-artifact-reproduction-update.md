# YoloFS Public Artifact Reproduction Update

Date: 2026-07-01

## Motivation

Earlier notes said the original YoloFS implementation was not found. That is
now stale. A public YoloFS organization and filesystem repository are
available, so the source-role decision must be corrected without rewriting the
historical 2026-06-30 audit.

This record belongs in `docs/tmp/` as dated reproduction evidence. The durable
novelty and baseline conclusion belongs in `docs/background-related-work.md`;
the source catalog entry belongs in `docs/reference/CODE_SOURCES.md`; raw logs
remain under `results/reproduction/`.

## Sources Inspected

Public sources:

- `https://github.com/YoloFS/YoloFS`
- `https://github.com/YoloFS/filesystem`
- `https://yolofs.github.io`

Local checkouts:

- `.cache/source-inspection/yolofs-filesystem`
- `.cache/source-inspection/yolofs-filesystem-compat`
- `.cache/source-inspection/yolofs-site`

Raw logs and summaries:

- `results/reproduction/2026-07-01-official-workloads/yolofs/`

## Artifact Status

The public `YoloFS/YoloFS` umbrella repository points to a public
`YoloFS/filesystem` submodule, plus several submodules for agent evaluation,
performance evaluation, paper materials, and results.

The filesystem code is public and partially reproduced. Several supporting
submodules are not publicly accessible from this environment. Recursive clone
registered the submodules, but `agent-eval`, `agent-results`, `paper`,
`paper-plan`, `paper-study`, `perf-eval`, and `perf-results` failed with
"Repository not found." The raw evidence is:

- `results/reproduction/2026-07-01-official-workloads/yolofs/yolofs-umbrella-recursive-clone.log`

Therefore:

- it is no longer correct to repeat the earlier no-public-code conclusion;
- it is correct to say "the public YoloFS filesystem code was found and partly
  reproduced";
- it is not correct to say the original YoloFS agent benchmark or performance
  benchmark has been reproduced, because the relevant submodules are not
  accessible.

## What Ran

Main branch filesystem repository:

- Repo: `https://github.com/YoloFS/filesystem`
- Head: `684829ec5e8193e8560b52573b2575a347906d0e`
- Unit tests: passed, `288 passed; 0 failed`.
- Raw summary:
  `results/reproduction/2026-07-01-official-workloads/yolofs/yolofs-filesystem-test-unit-summary.json`

Main branch build and VM attempts:

- `make build` failed before producing a usable module due a kmod build target
  issue: `No rule to make target 'dentry.o', needed by 'yolofs.o'`.
- Direct kmod build with source path reached host-kernel compilation and then
  failed on Linux 6.15 headers because `no_llseek` is not declared.
- `make test-e2e-vm` first failed with the `/usr/local/bin/qemu-system-x86_64`
  binary because that binary lacks the user network backend.
- Retrying with `/usr/bin/qemu-system-x86_64` started the VM, but the guest
  lacked `make`.
- A follow-up dependency-install attempt was blocked by guest SSH/cloud-init
  instability: repeated SSH probes closed or reset the connection.

Compat branch filesystem repository:

- Repo: `https://github.com/YoloFS/filesystem`
- Branch: `compat`
- Head: `f37d17583464e72793c63a31de17ca86e19262fe`
- Unit tests: passed, `288 passed; 0 failed`.
- Direct kmod build with `KBUILD_KMOD_SRC` passed and produced `yolofs.ko`.
- Raw summaries:
  - `results/reproduction/2026-07-01-official-workloads/yolofs/yolofs-filesystem-compat-test-unit-summary.json`
  - `results/reproduction/2026-07-01-official-workloads/yolofs/yolofs-filesystem-compat-kmod-direct-src-build-summary.json`

No host module load or mounted YoloFS e2e test was performed.

## Workload Information Extracted

The public YoloFS site describes two agent-facing workload families:

1. Hidden-side-effect self-correction tasks. A routine command such as a build,
   linter, or deploy step has a hidden destructive filesystem side effect.
   Correctness is checked by final working-tree state and expected outputs.
2. Routine filesystem tasks. These record prompts, permission dialogs, tool
   calls, snapshots, terminal screen/session logs, and file state.

The public performance pages describe:

- bare ext4, OverlayFS, BranchFS, and YoloFS comparisons;
- single-file 1GB I/O with 4KB requests;
- metadata operations across base, snapshot, and staging layers;
- snapshot scalability;
- a kernel-development workflow that creates a git worktree, builds a kernel,
  searches/edits/rebuilds, and commits changes across a large source tree.

These workload descriptions are useful for `namei_ext`, but the public
filesystem tests reproduced here are not the same as reproducing the private
agent-eval or perf-eval benchmark harnesses.

## Reuse Decision

YoloFS should move from an older methodology-only status to "public
code-backed methodology and partial filesystem artifact source."

Use it for:

- hidden-side-effect final-tree oracles;
- staging/snapshot/permission methodology;
- agent-visible workspace state transitions;
- related-work comparison against a stackable kernel filesystem that owns
  broader write/staging/snapshot semantics.

Do not claim:

- original YoloFS agent benchmark reproduction;
- original YoloFS performance benchmark reproduction;
- mounted filesystem e2e reproduction;
- full YoloFS semantic conformance.

For the `namei_ext` paper, YoloFS remains a strong workload and related-work
source, but the first Make-owned KVM workload should still reuse only the
path-view subset that belongs at VFS name resolution. YoloFS itself is broader:
it owns staging, write/create/delete behavior, snapshots, permissions, and
commit/abort semantics.

## Canonical Documentation Updates Needed

The current canonical state should be:

- `docs/background-related-work.md`: YoloFS public filesystem code found;
  main/compat unit tests pass; compat kmod builds; agent/perf submodules are
  inaccessible; original agent/perf benchmark not reproduced.
- `docs/reference/CODE_SOURCES.md`: YoloFS belongs in direct/methodology
  workload sources with public filesystem code and website links.
- `research/STATE.md`: replace stale methodology-only wording with the partial
  reproduction status above.
- Historical 2026-06-30 notes: add correction pointers instead of rewriting
  the earlier survey.

## Follow-Up

`docs/tmp/2026-07-01-yolofs-e2e-vm-retry.md` records a later retry of the
public `make test-e2e-vm` mounted-filesystem integration target. The retry
confirmed that the public e2e entry point exists and was attempted, but it still
did not reach YoloFS kmod install or Rust e2e test execution on this host:
default PATH QEMU lacks user networking, and system QEMU boots the guest but
times out before SSH/9p readiness.

Additional follow-up: `docs/tmp/2026-07-02-yolofs-compat-e2e-vm-reproduction.md`
reproduces the public `compat` branch mounted VM e2e target after guest build
dependency installation and local generated-artifact cleanup. That run passed
`593/593` mounted e2e tests. The unavailable umbrella `agent-eval` and
`perf-eval` submodule boundary remains unchanged.
