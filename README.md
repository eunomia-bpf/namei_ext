# namei_ext

`namei_ext` is a research prototype for a `sched_ext`-style BPF extension point
in the Linux VFS path-resolution layer.

The project is not a standalone filesystem. The intended design keeps VFS,
dcache, inode, permission, and lower-filesystem semantics in the kernel, while
BPF programs provide programmable path-resolution decisions for lookup and
directory enumeration.

See [docs/idea-story.md](docs/idea-story.md) for the research story and
[docs/design.md](docs/design.md) for the mechanism design. The Linux kernel
fork used for prototyping is tracked as the `kernel` submodule.
