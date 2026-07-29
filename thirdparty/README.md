# thirdparty

Third-party dependencies such as libbpf and bpftool should live here as
submodules or pinned source trees when they are split from the kernel subtree.
The initial Phase 1 infrastructure can use the kernel submodule's in-tree BPF
tools while this directory records the intended dependency boundary.

Small fixes required to execute a pinned upstream workload live under
`patches/<project>/`. Workload acquisition must verify and record each patch;
the patched source must never be described as an unmodified upstream baseline.

Generated dependency locks required to make an official source release
reproducible live under `locks/`. A lock does not modify upstream behavior; its
source commit, generated hash, build toolchain, and use of the build tool's
locked mode must still be recorded by the owning Make target.
