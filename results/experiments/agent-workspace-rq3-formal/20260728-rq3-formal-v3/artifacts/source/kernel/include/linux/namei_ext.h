/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_NAMEI_EXT_H
#define _LINUX_NAMEI_EXT_H

#include <linux/path.h>
#include <linux/types.h>
#include <uapi/linux/bpf.h>

struct dir_context;
struct file;
struct cgroup;
struct inode;
struct path;
struct qstr;

enum namei_ext_event {
	NAMEI_EXT_LOOKUP = BPF_NAMEI_EXT_LOOKUP,
	NAMEI_EXT_READDIR = BPF_NAMEI_EXT_READDIR,
};

enum namei_ext_action {
	NAMEI_EXT_PASS = BPF_NAMEI_EXT_PASS,
	NAMEI_EXT_REDIRECT = BPF_NAMEI_EXT_REDIRECT,
	NAMEI_EXT_HIDE = BPF_NAMEI_EXT_HIDE,
	NAMEI_EXT_SELECT_TARGET = BPF_NAMEI_EXT_SELECT_TARGET,
};

struct namei_ext_redirect {
	bool active;
	bool target_pending;
	bool target_active;
	bool target_borrowed;
	u32 len;
	u32 hash;
	u32 target_id;
	u64 target_cgroup_id;
	char name[BPF_NAMEI_EXT_NAME_MAX];
	struct path target;
};

#ifdef CONFIG_NAMEI_EXT

#include <linux/bpf-cgroup.h>

static __always_inline bool namei_ext_enabled(void)
{
	return cgroup_bpf_enabled(CGROUP_NAMEI_EXT);
}

int namei_ext_lookup(const struct path *parent, const struct inode *parent_inode,
		     const struct qstr *name, u32 event, u32 lookup_flags,
		     struct namei_ext_redirect *redirect);
int namei_ext_resolve_target(struct namei_ext_redirect *redirect,
			     bool rcu_walk);
int namei_ext_get_target(u64 cgroup_id, u32 target_id, struct path *path);
bool namei_ext_policy_parent_matches(const struct cgroup *cgrp,
				     const struct path *parent);
bool namei_ext_parent_maybe_managed(const struct path *parent);
void namei_ext_cgroup_set_scope_active(struct cgroup *cgrp, bool active);
void namei_ext_cgroup_release(struct cgroup *cgrp);
int namei_ext_iterate_dir(struct file *file, struct dir_context *ctx,
			  int (*iter)(struct file *, struct dir_context *));

#else /* CONFIG_NAMEI_EXT */

static inline bool namei_ext_enabled(void)
{
	return false;
}

static inline int namei_ext_lookup(const struct path *parent,
				   const struct inode *parent_inode,
				   const struct qstr *name,
				   u32 event, u32 lookup_flags,
				   struct namei_ext_redirect *redirect)
{
	return 0;
}

static inline int
namei_ext_resolve_target(struct namei_ext_redirect *redirect, bool rcu_walk)
{
	return 0;
}

static inline bool
namei_ext_policy_parent_matches(const struct cgroup *cgrp,
				const struct path *parent)
{
	return true;
}

static inline bool namei_ext_parent_maybe_managed(const struct path *parent)
{
	return false;
}

static inline void namei_ext_cgroup_release(struct cgroup *cgrp)
{
}

static inline void
namei_ext_cgroup_set_scope_active(struct cgroup *cgrp, bool active)
{
}

static inline int namei_ext_iterate_dir(struct file *file,
					struct dir_context *ctx,
					int (*iter)(struct file *,
						    struct dir_context *))
{
	return iter(file, ctx);
}

#endif /* CONFIG_NAMEI_EXT */

#endif /* _LINUX_NAMEI_EXT_H */
