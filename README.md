# namei_ext

`namei_ext` is a research prototype for a `sched_ext`-style BPF extension point
in the Linux VFS path-resolution layer.

The project is not a standalone filesystem. The intended design keeps VFS,
dcache, inode, permission, and lower-filesystem semantics in the kernel, while
BPF programs provide programmable path-resolution decisions for lookup and
directory enumeration.

See [docs/research_plan.md](docs/research_plan.md) for the current research
plan. The Linux kernel fork used for prototyping is tracked as the `kernel`
submodule.
