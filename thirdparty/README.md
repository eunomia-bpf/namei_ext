# thirdparty

Third-party dependencies such as libbpf and bpftool should live here as
submodules or pinned source trees when they are split from the kernel subtree.
The initial Phase 1 infrastructure can use the kernel submodule's in-tree BPF
tools while this directory records the intended dependency boundary.
