# Agent Workspace RQ3 Formal Report

- Formal run: `20260728-rq3-formal-v3`
- Complete independent KVM boots: 3/3
- Lower filesystem: ext4
- Pairwise AgentFS-derived oracles: 37/37 for both mechanisms in every boot
- `namei_ext` fd-only counter unchanged: 3/3 boots

## Responsibility Matrix

| Responsibility | `namei_ext` | Wrapfs-derived | FUSE comparator |
| --- | --- | --- | --- |
| policy execution | verified BPF decision function | privileged kernel module policy | userspace filesystem daemon callbacks |
| lookup and readdir | BPF decision; VFS performs resolution | Wrapfs lookup and iterate methods | FUSE requests and daemon callbacks |
| inode, dentry, super, and file methods | VFS and lower filesystem | Wrapfs interposes and forwards | FUSE client and daemon filesystem |
| ordinary open-fd data and metadata operations | selected lower file operations | Wrapfs file and inode methods forward to lower | daemon-mediated FUSE requests |
| target and scope state | cgroup policy link, target registry, policy maps | mount source, stacked dentries, module policy | mount plus daemon path and epoch state |
| daemon and mount lifetime | no policy mount or userspace daemon | stacked mount and kernel module | mount and live daemon connection |
| cache and coherency | existing VFS and lower-filesystem caches | stacked dentry/inode state plus lower caches | FUSE client caches plus daemon invalidation protocol |
| invalid policy behavior | verifier and bounded kernel errno checks | kernel module validation and failure paths | daemon validation, disconnect, and request failure paths |
| persistence | lower filesystem | forwarded to lower filesystem | daemon implementation and lower backing store |

## Runtime Attribution

| Wrapfs method | Count range across boots | Engaged boots |
| --- | ---: | ---: |
| `fill_super` | 2-2 | 3/3 |
| `put_super` | 2-2 | 3/3 |
| `lookup` | 28-28 | 3/3 |
| `readdir` | 10-10 | 3/3 |
| `open` | 22-22 | 3/3 |
| `read_iter` | 15-15 | 3/3 |
| `write_iter` | 2-2 | 3/3 |
| `fsync` | 1-1 | 3/3 |
| `getattr` | 10-10 | 3/3 |
| `setattr` | 1-1 | 3/3 |
| `create` | 2-2 | 3/3 |
| `rename` | 2-2 | 3/3 |
| `unlink` | 1-1 | 3/3 |

Every trace row is attributed to the expected `wrapfs_* [wrapfs]` module symbol. Counts describe this fixed oracle and are not a performance or safety score.

## Fail-Closed Matrix

| Fault | Errno | Lower-object evidence | Boots |
| --- | ---: | --- | ---: |
| `verifier_reject_ctx_write` | 13 | verifier log | 3/3 |
| `verifier_reject_action_4` | 22 | verifier log | 3/3 |
| `redirect_len_zero` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_len_zero_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_len_65` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_len_65_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_dot` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_dot_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_dot_dot` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_dot_dot_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_slash` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_slash_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_embedded_nul` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_embedded_nul_readdir` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `target_zero` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `target_zero_warm` | 22 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `target_unregistered` | 2 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `select_readdir` | 95 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `select_create` | 95 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `redirect_create` | 95 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |
| `select_final_open` | 95 | statx + SHA-256 for 8 objects; 2 directory manifests | 3/3 |

Each runtime cell independently loads and attaches the policy, registers its target, executes one fault, detaches, clears targets, and preserves the lower-object manifest. The child cgroups are removed before completion.

## Source Accounting

- `namei_ext` workload entry points: cgroup/namei_ext
- `namei_ext` deployed kernel integration files: 9
- Wrapfs deployed compiled sources: 6
- Wrapfs deployed VFS slots: alloc_inode, compat_ioctl, create, d_init, d_release, d_revalidate, evict_inode, fasync, flush, free_inode, fsync, get_link, get_tree, getattr, init_fs_context, iterate_shared, kill_sb, listxattr, llseek, lookup, mmap, open, permission, put_super, read_iter, release, rename, setattr, statfs, symlink, umount_begin, unlink, unlocked_ioctl, write_iter
- FUSE comparator callbacks: create, getattr, mknod, open, read, readdir, readlink, release, rename, truncate, unlink, write
- FUSE kernel client compiled sources: 15

## Supported Claim

For this existing-object Agent workspace view, `namei_ext` confines workload policy execution to pathname lookup and directory iteration, after which ordinary file operations use the selected lower object. The matched stackable implementation registers and executes superblock, lookup, directory, inode, and file methods for the same pairwise oracle. Invalid programs and unsupported decisions are contained at the verifier or declared errno boundary in this matrix. This is a boundary claim, not a complete-system security or generality claim.
