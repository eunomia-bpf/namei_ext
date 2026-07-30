# Paper Mechanism-Story Revision

## Motivation

The current paper has enough implementation substance but presents it as a new
BPF program type with four actions. The abstract calls lookup/readdir placement,
bounded actions, and baseline comparability the technical challenges.
Comparability is an evaluation requirement, while the actual Linux construction
problems remain absent from the paper. This makes the contribution look like
another eBPF interface.

## Evidence Inspected

The revision is grounded in the current kernel and reviewed implementation
records:

- `kernel/fs/namei.c`: component and final-open integration, redirected-name
  hashing, selected-target installation, and RCU/ref-walk transitions;
- `kernel/fs/namei_ext.c`: target registration and replacement, RCU scope
  index, context validation, lookup actions, and directory iteration;
- `kernel/fs/readdir.c`: the directory-iteration call site;
- `kernel/kernel/bpf/cgroup.c`: cgroup dispatch and verifier-visible context;
- `docs/tmp/2026-07-27-namei-ext-rcu-decision-implementation.md`;
- `docs/tmp/2026-07-27-namei-ext-rcu-target-selection-implementation.md`; and
- `docs/tmp/2026-07-27-namei-ext-global-parent-fast-path-implementation.md`.

The current prototype and KVM evidence establish the mechanisms described
below. No new action, claim, result, or measurement is introduced by this
writing step.

## Target Outline

1. Present the problem as programmable selection of an existing object without
   transferring filesystem ownership, not as adding a BPF hook.
2. Explain why a naive hook fails:
   - name resolution spans intermediate components, final open/create handling,
     and directory iteration;
   - cache-hot path walking uses RCU and cannot take sleeping locks or ordinary
     references;
   - selecting an external object must remain valid across replacement and
     continue through normal VFS permission/open completion; and
   - the system-wide path hot path must bypass policy work when unattached or
     outside a managed parent.
3. Show the mechanisms that answer those challenges:
   - one decision contract across lookup and readdir call sites;
   - action-specific RCU/ref-walk handling;
   - opaque IDs for registered `struct path` objects, RCU lifetime, and existing
     namei sequence validation;
   - directory-entry filtering with lower iterator position preservation; and
   - a static-key and RCU exact-parent prefilter before context construction.
4. Keep unsupported synthetic aliases, creation through selection, arbitrary
   path strings, and broader filesystem semantics outside the boundary.
5. Merge design and implementation into one primary contribution in the
   Introduction; retain the RQ1/RQ2/RQ3 evaluation as the second contribution.

## Files To Revise

- `docs/paper/main.tex`;
- `docs/paper/sections/01-introduction.tex`;
- `docs/paper/sections/03-design.tex`;
- `docs/paper/sections/04-implementation.tex`;
- `docs/paper/sections/05-evaluation.tex`;
- `docs/idea-story.md`;
- `docs/design.md`; and
- `research/STATE.md`.

## Constraints

- Preserve the three RQs and every quantitative result.
- Preserve the existing-object-only ownership boundary.
- Do not claim full Documents portal compatibility or synthetic readdir
  aliases.
- Do not present the debugfs prototype registration control as a finished
  upstream ABI.
- Keep `sched_ext` as an ownership analogy, not the title or the first
  explanation of the contribution.

## Validation Performed

The revision passed:

- `make -C docs/paper check`;
- `make -C docs/paper snapshot`;
- a LaTeX log check with no overfull boxes, undefined citations, or undefined
  references;
- visual inspection of the title/abstract page and the revised mechanism
  figure; and
- a fresh read-only review against both the paper and modified-kernel source.

The first independent review found no P0 contradiction and confirmed that the
title, abstract, Introduction, and merged contribution no longer primarily read
as another eBPF interface. It identified five blocking presentation or accuracy
issues:

1. the principal figure still reduced the system to eBPF plus four actions;
2. the text omitted full-VFS-restart replay semantics;
3. lookup/readdir coherence was written as a kernel guarantee rather than a
   policy obligation;
4. construction evidence remained outside the paper; and
5. ExtFUSE/FUSE-BPF differentiation was too shallow.

The revision then:

- replaced the action-centered figure with a VFS construction flow spanning
  component walk, final open/create, lower directory iteration, RCU/ref-walk
  handling, registered-target lifetime, and ordinary VFS completion;
- specified at-least-once policy execution across a full `-ECHILD` restart and
  required idempotent externally visible side effects;
- stated that the kernel supplies one action vocabulary while policies own
  lookup/readdir coherence and workload oracles test it;
- added a mechanism-validation table using existing KVM evidence for
  `RESOLVE_CACHED`, 128 concurrent target replacements, exact-parent bypass,
  and ordinary selected-object completion;
- expanded the closest-work comparison around filesystem ownership, target
  lifetime, VFS completion, and unmanaged-path cost; and
- removed the unnecessary `ctex` package so the English PDF no longer renders
  Chinese section labels.

A second independent read-only review confirmed the revised figure, restart
semantics, coherence obligation, replacement description, create restriction,
and PDF rendering. It found two remaining accuracy issues, both corrected:

- `RESOLVE_CACHED` evidence now says selection entered from RCU-walk and
  completed after in-place legitimization without a full restart, rather than
  claiming the whole operation completed in RCU-walk; and
- the FUSE-BPF comparison now acknowledges `root_dir`/`no_daemon` passthrough
  and distinguishes the systems by mounted-filesystem, FUSE-inode, and
  filesystem-forwarding ownership rather than daemon presence.

The mechanism-validation table also separates direct functional checks from
object-identity and lower-preservation evidence supplied by the source-workload
oracles.

## Remaining Risks

The paper must distinguish the implemented selected-directory readdir path from
unsupported synthetic alias generation. The RCU discussion must describe
borrowed target lifetime and existing namei validation without claiming a
formal proof. The fast-path mechanism must remain scoped to the measured host
and FxMark conditions when quantitative results are cited.
