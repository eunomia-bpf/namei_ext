# BOOTSTRAP Cycle 0 Step Report

Timestamp: 2026-07-12T22:20:41-07:00
Cycle: 0000
Phase: BOOTSTRAP
Status: complete
Next phase: BUILD_AND_EVALUATE
Next gate: EXPERIMENT_GATE

## Step Objective

This cycle re-entered BOOTSTRAP under the new research orchestrator, restored
the ambitious scientific story, grounded it in closest-work and source-system
evidence, rewrote the paper into a submission-shaped draft, and reviewed
whether the story can freeze for implementation/evaluation.

## Gate Reports

- BOOTSTRAP idea/root disposition:
  `docs/tmp/cycle-0000-20260712T202757-0700/00-bootstrap-idea/500-root-disposition-20260712T205136-0700.md`
- EXPERIMENT_GATE literature/novelty pressure:
  `docs/tmp/cycle-0000-20260712T202757-0700/01-experiment-gate/999-gate-report-20260712T210219-0700.md`
- WRITE_GATE paper-expression pass:
  `docs/tmp/cycle-0000-20260712T202757-0700/02-write-gate/999-gate-report-20260712T221422-0700.md`
- REVIEW_GATE meta-review and routing:
  `docs/tmp/cycle-0000-20260712T202757-0700/03-review-gate/999-gate-report-20260712T222041-0700.md`

## Frozen Scientific Contract

`namei_ext` is a `sched_ext`-style VFS name-resolution extension point. It
places a bounded eBPF policy decision at VFS name resolution while the kernel
and lower filesystem retain ownership of path walking, dentries, inodes,
permissions, file data, writes, page cache, persistence, and ordinary
filesystem semantics.

Design-space placement:

```text
bind/Overlay/materialization < eBPF LSM < namei_ext < FUSE/custom FS
```

The paper no longer centers table-only/static-table impossibility or
materialized namespace shootouts. Those mechanisms remain background,
related-work context, or legacy diagnostics.

## Frozen Research Questions

RQ1 Expressiveness / sufficiency:
Can a narrow VFS name-resolution extension express real state-dependent
path-view policies without taking over filesystem semantics?

RQ2 Cost / overhead versus FUSE:
What is the cost of putting programmable policy on the VFS name-resolution path
compared with a feature-equivalent FUSE policy implementation under the same
oracle?

RQ3 Safety / boundary versus custom FS:
Does `namei_ext` provide a narrower and safer implementation boundary than
building a custom or stackable filesystem when the needed policy is only name
resolution?

## Evidence And Paper State

The current paper lives under `docs/paper/`. It builds successfully:

```sh
make -B -C docs/paper
```

Output: `.build/paper/main.pdf`, 16 pages.

Citation verification passed:

```sh
python3 /home/yunwei37/workspace/my-paper-work/academic-writing-skills/skills/check-paper-citations/scripts/verify_bib.py docs/paper/refs.bib
```

Result: 25 active entries checked, 52 bibliography entries present, 0 errors,
0 warnings.

Keyword scans found no reader-facing table-only/progress placeholders in the
paper source or generated PDF text.

## Meta-Review Findings

Direction: pass with routing. The story is faithful to the latest user
instructions and does not need to shrink. Missing final numbers are acceptable
for BOOTSTRAP.

Efficiency: do not run more idea refinement or full writing loops unless a new
trigger appears. Do not resume table-only/static-table/materialized shootouts.
Do not use source inventory as a result.

Maintenance: `scripts/check_progress.py` is absent; Make/control-plane routing
still exposes older W1-W4/table-style workflows; `research/*.md` must remain
handoff pointer material rather than competing scientific authority.

## Routing Response

BOOTSTRAP cycle 0 freezes the story and routes to BUILD_AND_EVALUATE
EXPERIMENT_GATE.

The first BUILD_AND_EVALUATE task is not to run final experiments immediately.
It is to repair Make-owned control-plane alignment so the default and
experiment entrypoints reflect the integrated Agent workspace and
environment/cache matrices promised by the paper.

Once Make routing is aligned, the first admitted experiment should be the
AgentFS-derived Agent workspace lifecycle matrix with:

- `namei_ext` in KVM through real `cgroup/namei_ext` attach;
- feature-equivalent FUSE under the same oracle;
- lower-FS semantic preservation checks;
- custom/stackable filesystem boundary evidence;
- raw results and result review before paper interpretation.

The environment/cache matrix follows after the Agent workspace matrix is
admitted and executable. Service/config remains conditional on selecting a real
lookup-time source oracle.

## Canonical Memory Updates

Update `docs/idea-story.md` and `research/STATE.md` to record that BOOTSTRAP
cycle 0 has frozen the story and that BUILD_AND_EVALUATE starts with
Make/control-plane alignment.

No project `AGENTS.md` update is required in this step because the relevant
stable rules already exist: Make is the entrypoint, KVM validates Phase 1, and
git mutation requires explicit user authorization.

## Git Publication

No Git commit or push was performed in this step because repository policy
requires explicit current authorization before mutating Git state. The step is
complete in Markdown and source files but uncommitted.

## Next Action

Enter BUILD_AND_EVALUATE EXPERIMENT_GATE.

Immediate task: repair the Make-owned control plane so `make` targets and help
text expose integrated current experiment entrypoints and isolate old W1-W4 /
table diagnostics as archived legacy paths.

