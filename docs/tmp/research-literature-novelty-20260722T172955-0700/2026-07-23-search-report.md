# 2026-07-23 Recent Literature Refresh

## Objective

Refresh the related-work frontier after the BOOTSTRAP reset and add recent
OSDI/FAST/NSDI/EuroSys papers without shrinking the current story:
`namei_ext` is a narrow, sched_ext-style VFS name-resolution extension point
between access-control hooks and FUSE/custom filesystems.

## Coverage Boundary

This pass checked three threat categories:

- Same-claim risk: programmable VFS name-resolution object selection with
  eBPF while preserving lower-filesystem object/data semantics.
- RQ2 fairness pressure: recent FUSE or userspace-filesystem optimizations
  that make a naive FUSE comparison unacceptable.
- RQ3 boundary pressure: recent full, custom, distributed, generated, or
  multi-component filesystems that show when broader filesystem ownership is
  the right boundary.

It also checked recent agentic-system context because prior user instructions
asked to include AI-agent-related source systems, but agentic orchestration
papers are treated as workload context, not filesystem baselines.

## Queries And Primary Sources

Representative searches:

- `OSDI 2026 technical sessions eBPF vBPF PeeR USEC Oxbow DeLFS`
- `FAST 2026 technical sessions CoFS SpecFS FUSE file system`
- `EuroSys 2026 SwitchFS MesaFS file system metadata service`
- `NSDI 2026 FalconFS KRAKENGUARD eBPF filesystem`
- `"name resolution" eBPF VFS filesystem paper`
- `"path resolution" eBPF Linux VFS filesystem paper`
- `OSDI 2026 Murakkab Resource-Efficient Agentic Workflow Orchestration`
- `SREGym AI SRE agents benchmark 2026 arXiv GitHub`

Primary pages checked:

- OSDI'26: Oxbow, DeLFS, vBPF, PeeR, USEC, Xkernel, Murakkab, Spice, and the
  LLM data-pipeline operational paper.
- FAST'26/FAST'24: CoFS, SYSSPEC/SpecFS, RFUSE.
- NSDI'26: FalconFS and KRAKENGUARD.
- EuroSys'26: official program entries for MesaFS and SwitchFS; SwitchFS
  arXiv page.
- OSDI'22/OSDI'25: XRP and bpftime/EIM.
- Public repositories: RFUSE, Oxbow, FalconFS, SpecFS, XRP, KRAKENGUARD,
  Xkernel, SREGym.

## Downloaded References

New local PDFs added under `docs/reference/`:

- `osdi26-kim-oxbow.pdf`
- `osdi26-ahn-delfs.pdf`
- `osdi26-zhang-vbpf.pdf`
- `osdi26-carin-peer.pdf`
- `osdi26-jiang-usec.pdf`
- `osdi26-chen-xkernel.pdf`
- `osdi26-chaudhry-murakkab.pdf`
- `osdi26-holmes-spice.pdf`
- `osdi26-chen-llm-data-pipeline.pdf`
- `nsdi26-xu-falconfs.pdf`
- `nsdi26-patel-krakenguard.pdf`
- `fast24-cho-rfuse.pdf`
- `fast26-wang-cofs.pdf`
- `fast26-liu-specfs.pdf`
- `osdi22-zhong-xrp.pdf`
- `osdi25-zheng-bpftime-eim.pdf`
- `arxiv2410.08618-switchfs.pdf`
- `arxiv2503.18191-distfuse.pdf`
- `arxiv2605.07161-sregym.pdf`

MesaFS was verified through ACM DOI `10.1145/3767295.3803573` and the
EuroSys'26 program, but the ACM PDF endpoint returned HTTP 403 during direct
download. It is therefore cited as primary metadata only, with no local PDF
claim.

## Novelty Impact

No same-claim paper was found in this pass. The closest surrounding systems
strengthen the story rather than requiring a smaller claim:

- RFUSE, CoFS, and DFUSE show that FUSE can be optimized and specialized. This
  strengthens the requirement that RQ2 compare against feature-equivalent FUSE
  under the same oracle, not against a generic weak FUSE strawman.
- Oxbow, DeLFS, FalconFS, SwitchFS, MesaFS, and SpecFS/SYSSPEC show strong
  recent reasons to build full or distributed filesystems. They strengthen RQ3:
  `namei_ext` is valuable only when lookup/readdir path-view selection is
  sufficient and broader filesystem ownership is unnecessary.
- XRP, vBPF, PeeR, KRAKENGUARD, Xkernel, bpftime/EIM, and USEC are neighboring
  extension and access-control systems. They help explain safety, attach-point,
  and tail-latency assumptions, but none places a bounded policy decision at
  VFS name resolution for lower-object selection.
- Murakkab and SREGym support the broader claim that real agentic systems use
  live, multi-step, tool-backed environments with oracles. They are workload
  context, not filesystem mechanisms.

## Canonical Updates

Updated durable files:

- `docs/background-related-work.md`
- `docs/reference/INDEX.md`
- `docs/reference/CODE_SOURCES.md`
- `docs/paper/refs.bib`
- `docs/paper/sections/06-related-work.tex`

The current RQ/contribution story remains:

- RQ1: expressiveness/sufficiency of a narrow VFS name-resolution extension for
  real path-view policies.
- RQ2: cost and overhead versus feature-equivalent FUSE.
- RQ3: safety/boundary value versus custom, stackable, or full filesystems.

## Remaining Uncertainty

- MesaFS PDF/code could not be downloaded in this pass; it should remain DOI
  metadata unless an official artifact becomes available.
- RFUSE, Oxbow, FalconFS, SpecFS, XRP, KRAKENGUARD, Xkernel, and SREGym have
  visible source/artifact repositories. They are useful for source facts and
  boundary context, but not automatically admitted as main runnable baselines.
- No eBPF'26 accepted-paper list was available on 2026-07-23; the CFP exists,
  but paper decisions should not be cited as accepted work yet.

## Next Action

Do not reopen the table-only/materialized-view shootout as the novelty center.
Proceed with the fixed experiment plan: implement complete Agent workspace and
traditional build/cache matrices through the real KVM `cgroup/namei_ext` path,
with correctness gated before overhead, feature-equivalent FUSE for RQ2, and
workload-specific ownership accounting for RQ3.
