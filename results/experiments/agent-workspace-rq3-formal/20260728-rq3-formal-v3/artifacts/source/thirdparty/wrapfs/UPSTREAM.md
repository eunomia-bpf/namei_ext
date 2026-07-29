# Wrapfs Source

This directory starts from the `fs/wrapfs` subtree in the latest official
Wrapfs branch:

- repository: `git://git.fsl.cs.sunysb.edu/wrapfs-latest.git`
- commit: `464802c8fd1a25413b295161c9bb9a4ce7bfa33b`
- upstream kernel base: Linux 5.18
- upstream page: <https://wrapfs.filesystems.org/>

The upstream source is GPL-2.0-only and retains its original SPDX and copyright
headers.

Project changes are limited to:

1. porting the module to the Linux 7.1 VFS API used by the `namei_ext`
   prototype; and
2. adding the matched Agent workspace view rule required by the RQ3 experiment.

This is a source-derived experimental baseline, not an unmodified upstream
Wrapfs result. The owning Make target records this source, the upstream commit,
the built module, and the current kernel identity.
