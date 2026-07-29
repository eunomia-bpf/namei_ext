// SPDX-License-Identifier: GPL-2.0

#include <linux/bpf-cgroup.h>
#include <linux/cgroup.h>
#include <linux/dcache.h>
#include <linux/debugfs.h>
#include <linux/file.h>
#include <linux/fs.h>
#include <linux/hashtable.h>
#include <linux/init.h>
#include <linux/limits.h>
#include <linux/list.h>
#include <linux/mutex.h>
#include <linux/namei.h>
#include <linux/namei_ext.h>
#include <linux/path.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/stringhash.h>
#include <linux/uaccess.h>

#define NAMEI_EXT_TARGET_HASH_BITS 8
#define NAMEI_EXT_SCOPE_HASH_BITS 8
#define NAMEI_EXT_MAX_POLICY_PARENTS 8

struct namei_ext_scope {
	struct hlist_node node;
	struct path path;
};

struct namei_ext_scope_set {
	u32 nr;
	struct namei_ext_scope entries[];
};

struct namei_ext_target {
	struct hlist_node node;
	struct list_head retired;
	u64 cg_id;
	u32 target_id;
	struct path path;
};

static DEFINE_HASHTABLE(namei_ext_targets, NAMEI_EXT_TARGET_HASH_BITS);
static DEFINE_HASHTABLE(namei_ext_scope_index, NAMEI_EXT_SCOPE_HASH_BITS);
static DEFINE_MUTEX(namei_ext_targets_lock);
static DEFINE_MUTEX(namei_ext_scopes_lock);
static DEFINE_RAW_SPINLOCK(namei_ext_scope_seq_lock);
static seqcount_raw_spinlock_t namei_ext_scope_seq =
	SEQCNT_RAW_SPINLOCK_ZERO(namei_ext_scope_seq, &namei_ext_scope_seq_lock);
static unsigned int namei_ext_global_scope_users;
static unsigned int namei_ext_exact_scope_users;
static struct namei_ext_scope_set namei_ext_scope_tombstone;
static struct dentry *namei_ext_debugfs_dir;

static unsigned long namei_ext_target_key(u64 cgroup_id, u32 target_id)
{
	return (unsigned long)(cgroup_id ^ ((u64)target_id << 32) ^
			       target_id);
}

static struct cgroup *namei_ext_current_cgroup(void)
{
	struct cgroup *cgrp;

	rcu_read_lock();
	cgrp = task_dfl_cgroup(current);
	if (!percpu_ref_tryget_live_rcu(&cgrp->bpf.refcnt))
		cgrp = NULL;
	else if (!cgroup_tryget(cgrp)) {
		cgroup_bpf_put(cgrp);
		cgrp = NULL;
	}
	rcu_read_unlock();
	return cgrp;
}

static void namei_ext_put_cgroup(struct cgroup *cgrp)
{
	cgroup_bpf_put(cgrp);
	cgroup_put(cgrp);
}

static int namei_ext_register_target(struct cgroup *cgrp, u32 target_id,
				     const struct path *path)
{
	struct namei_ext_target *target;
	struct namei_ext_target *new_target;
	struct namei_ext_target *old_target = NULL;
	u64 cg_id = cgroup_id(cgrp);
	unsigned long key;
	int ret = 0;

	if (!target_id || !path->mnt || !path->dentry)
		return -EINVAL;

	new_target = kzalloc(sizeof(*new_target), GFP_KERNEL);
	if (!new_target)
		return -ENOMEM;
	new_target->cg_id = cg_id;
	new_target->target_id = target_id;
	new_target->path = *path;

	key = namei_ext_target_key(cg_id, target_id);
	mutex_lock(&namei_ext_targets_lock);
	if (cgroup_is_dead(cgrp)) {
		ret = -ENODEV;
		goto out_unlock;
	}
	hash_for_each_possible(namei_ext_targets, target, node, key) {
		if (target->cg_id != cg_id ||
		    target->target_id != target_id)
			continue;
		hlist_replace_rcu(&target->node, &new_target->node);
		old_target = target;
		break;
	}
	if (!old_target)
		hash_add_rcu(namei_ext_targets, &new_target->node, key);
out_unlock:
	mutex_unlock(&namei_ext_targets_lock);
	if (ret) {
		kfree(new_target);
	} else if (old_target) {
		synchronize_rcu();
		path_put(&old_target->path);
		kfree(old_target);
	}
	return ret;
}

static void namei_ext_clear_targets(u64 cgroup_id)
{
	struct namei_ext_target *target;
	struct namei_ext_target *next;
	struct hlist_node *tmp;
	LIST_HEAD(retired);
	unsigned int bkt;

	mutex_lock(&namei_ext_targets_lock);
	hash_for_each_safe(namei_ext_targets, bkt, tmp, target, node) {
		if (target->cg_id != cgroup_id)
			continue;
		hash_del_rcu(&target->node);
		list_add(&target->retired, &retired);
	}
	mutex_unlock(&namei_ext_targets_lock);

	if (list_empty(&retired))
		return;
	synchronize_rcu();
	list_for_each_entry_safe(target, next, &retired, retired) {
		list_del(&target->retired);
		path_put(&target->path);
		kfree(target);
	}
}

static struct namei_ext_target *
namei_ext_find_target_rcu(u64 cgroup_id, u32 target_id)
{
	struct namei_ext_target *target;
	unsigned long key;

	lockdep_assert_in_rcu_read_lock();

	key = namei_ext_target_key(cgroup_id, target_id);
	hash_for_each_possible_rcu(namei_ext_targets, target, node, key) {
		if (target->cg_id != cgroup_id ||
		    target->target_id != target_id)
			continue;
		return target;
	}
	return NULL;
}

int namei_ext_get_target(u64 cgroup_id, u32 target_id, struct path *path)
{
	struct namei_ext_target *target;
	int ret = -ENOENT;

	if (!target_id)
		return -EINVAL;

	rcu_read_lock();
	target = namei_ext_find_target_rcu(cgroup_id, target_id);
	if (target) {
		*path = target->path;
		path_get(path);
		ret = 0;
	}
	rcu_read_unlock();
	return ret;
}

static ssize_t namei_ext_register_target_write(struct file *file,
					       const char __user *buf,
					       size_t count, loff_t *ppos)
{
	char kbuf[64];
	struct cgroup *cgrp;
	struct fd fd;
	struct path path;
	unsigned int target_id;
	unsigned int fd_num;
	int ret;

	if (!count || count >= sizeof(kbuf))
		return -EINVAL;
	if (copy_from_user(kbuf, buf, count))
		return -EFAULT;
	kbuf[count] = '\0';

	cgrp = namei_ext_current_cgroup();
	if (!cgrp)
		return -ENODEV;
	if (sysfs_streq(kbuf, "clear")) {
		namei_ext_clear_targets(cgroup_id(cgrp));
		namei_ext_put_cgroup(cgrp);
		return count;
	}

	if (sscanf(kbuf, "%u %u", &target_id, &fd_num) != 2) {
		ret = -EINVAL;
		goto out_put_cgroup;
	}

	fd = fdget_raw(fd_num);
	if (fd_empty(fd)) {
		ret = -EBADF;
		goto out_put_cgroup;
	}

	path = fd_file(fd)->f_path;
	path_get(&path);

	ret = namei_ext_register_target(cgrp, target_id, &path);
	if (ret)
		path_put(&path);
	fdput(fd);
out_put_cgroup:
	namei_ext_put_cgroup(cgrp);
	return ret ? ret : count;
}

static const struct file_operations namei_ext_register_target_fops = {
	.write = namei_ext_register_target_write,
};

static unsigned long namei_ext_scope_key(const struct path *path)
{
	return (unsigned long)path->dentry ^ (unsigned long)path->mnt;
}

static void
namei_ext_scope_index_add_locked(struct namei_ext_scope_set *scopes)
{
	u32 i;

	for (i = 0; i < scopes->nr; i++)
		hash_add_rcu(namei_ext_scope_index, &scopes->entries[i].node,
			     namei_ext_scope_key(&scopes->entries[i].path));
	if (WARN_ON_ONCE(namei_ext_exact_scope_users >
			 UINT_MAX - scopes->nr))
		namei_ext_exact_scope_users = UINT_MAX;
	else if (namei_ext_exact_scope_users != UINT_MAX)
		namei_ext_exact_scope_users += scopes->nr;
}

static void
namei_ext_scope_index_del_locked(struct namei_ext_scope_set *scopes)
{
	u32 i;

	for (i = 0; i < scopes->nr; i++)
		hash_del_rcu(&scopes->entries[i].node);
	if (namei_ext_exact_scope_users == UINT_MAX)
		return;
	if (WARN_ON_ONCE(namei_ext_exact_scope_users < scopes->nr))
		namei_ext_exact_scope_users = UINT_MAX;
	else
		namei_ext_exact_scope_users -= scopes->nr;
}

static void namei_ext_global_scope_get_locked(void)
{
	if (WARN_ON_ONCE(namei_ext_global_scope_users == UINT_MAX))
		return;
	namei_ext_global_scope_users++;
}

static void namei_ext_global_scope_put_locked(void)
{
	if (namei_ext_global_scope_users == UINT_MAX)
		return;
	if (WARN_ON_ONCE(!namei_ext_global_scope_users)) {
		namei_ext_global_scope_users = UINT_MAX;
		return;
	}
	namei_ext_global_scope_users--;
}

static void namei_ext_free_scopes(struct namei_ext_scope_set *scopes)
{
	u32 i;

	if (!scopes || scopes == &namei_ext_scope_tombstone)
		return;
	for (i = 0; i < scopes->nr; i++)
		path_put(&scopes->entries[i].path);
	kfree(scopes);
}

static struct namei_ext_scope_set *
namei_ext_alloc_scopes(u32 nr)
{
	struct namei_ext_scope_set *scopes;

	if (nr > NAMEI_EXT_MAX_POLICY_PARENTS)
		return NULL;
	return kzalloc(struct_size(scopes, entries, nr), GFP_KERNEL);
}

static void
namei_ext_finish_scope_replace(struct namei_ext_scope_set *old_scopes)
{
	if (!old_scopes)
		return;
	synchronize_rcu();
	namei_ext_free_scopes(old_scopes);
}

static struct namei_ext_scope_set *
namei_ext_scope_replace_locked(struct cgroup *cgrp,
			       struct namei_ext_scope_set *new_scopes)
{
	struct namei_ext_scope_set *old_scopes;

	lockdep_assert_held(&namei_ext_scopes_lock);
	raw_spin_lock(&namei_ext_scope_seq_lock);
	write_seqcount_begin(&namei_ext_scope_seq);
	old_scopes = rcu_dereference_protected(cgrp->bpf.namei_ext_scopes, 1);

	if (new_scopes)
		namei_ext_scope_index_add_locked(new_scopes);
	else if (cgrp->bpf.namei_ext_scope_active)
		namei_ext_global_scope_get_locked();

	rcu_assign_pointer(cgrp->bpf.namei_ext_scopes, new_scopes);

	if (old_scopes)
		namei_ext_scope_index_del_locked(old_scopes);
	else if (cgrp->bpf.namei_ext_scope_active)
		namei_ext_global_scope_put_locked();
	write_seqcount_end(&namei_ext_scope_seq);
	raw_spin_unlock(&namei_ext_scope_seq_lock);

	return old_scopes;
}

static int namei_ext_scope_exact(struct cgroup *cgrp,
				 const struct path *path)
{
	struct namei_ext_scope_set *new_scopes;
	struct namei_ext_scope_set *old_scopes = NULL;
	int ret = 0;

	new_scopes = namei_ext_alloc_scopes(1);
	if (!new_scopes)
		return -ENOMEM;
	new_scopes->nr = 1;
	new_scopes->entries[0].path = *path;
	path_get(path);

	mutex_lock(&namei_ext_scopes_lock);
	lockdep_assert_held(&namei_ext_scopes_lock);
	if (cgroup_is_dead(cgrp)) {
		ret = -ENODEV;
	} else {
		old_scopes = namei_ext_scope_replace_locked(cgrp, new_scopes);
		new_scopes = NULL;
	}
	mutex_unlock(&namei_ext_scopes_lock);

	namei_ext_free_scopes(new_scopes);
	namei_ext_finish_scope_replace(old_scopes);
	return ret;
}

static bool namei_ext_cgroup_owns_policy(struct cgroup *cgrp)
{
	struct cgroup *owner;

	lockdep_assert_held(&cgroup_mutex);
	owner = rcu_dereference_protected(cgrp->bpf.namei_ext_owner,
					  lockdep_is_held(&cgroup_mutex));
	return owner == cgrp;
}

static int namei_ext_scope_add(struct cgroup *cgrp,
			       const struct path *path)
{
	struct namei_ext_scope_set *new_scopes = NULL;
	struct namei_ext_scope_set *old_scopes = NULL;
	bool replaced = false;
	u32 i;
	int ret = 0;

	mutex_lock(&namei_ext_scopes_lock);
	if (cgroup_is_dead(cgrp)) {
		ret = -ENODEV;
		goto out_unlock;
	}

	old_scopes = rcu_dereference_protected(cgrp->bpf.namei_ext_scopes, 1);
	if (!old_scopes) {
		ret = -EINVAL;
		goto out_unlock;
	}
	for (i = 0; i < old_scopes->nr; i++) {
		if (path_equal(&old_scopes->entries[i].path, path))
			goto out_unlock;
	}
	if (old_scopes->nr == NAMEI_EXT_MAX_POLICY_PARENTS) {
		ret = -E2BIG;
		goto out_unlock;
	}

	new_scopes = namei_ext_alloc_scopes(old_scopes->nr + 1);
	if (!new_scopes) {
		ret = -ENOMEM;
		goto out_unlock;
	}
	new_scopes->nr = old_scopes->nr + 1;
	for (i = 0; i < old_scopes->nr; i++) {
		new_scopes->entries[i].path = old_scopes->entries[i].path;
		path_get(&new_scopes->entries[i].path);
	}
	new_scopes->entries[old_scopes->nr].path = *path;
	path_get(path);
	old_scopes = namei_ext_scope_replace_locked(cgrp, new_scopes);
	new_scopes = NULL;
	replaced = true;

out_unlock:
	mutex_unlock(&namei_ext_scopes_lock);
	namei_ext_free_scopes(new_scopes);
	if (replaced)
		namei_ext_finish_scope_replace(old_scopes);
	return ret;
}

static int namei_ext_scope_empty(struct cgroup *cgrp)
{
	struct namei_ext_scope_set *new_scopes;
	struct namei_ext_scope_set *old_scopes;
	int ret = 0;

	new_scopes = namei_ext_alloc_scopes(0);
	if (!new_scopes)
		return -ENOMEM;

	mutex_lock(&namei_ext_scopes_lock);
	if (cgroup_is_dead(cgrp)) {
		ret = -ENODEV;
		old_scopes = NULL;
	} else {
		old_scopes = namei_ext_scope_replace_locked(cgrp, new_scopes);
		new_scopes = NULL;
	}
	mutex_unlock(&namei_ext_scopes_lock);

	namei_ext_free_scopes(new_scopes);
	namei_ext_finish_scope_replace(old_scopes);
	return ret;
}

static int namei_ext_scope_global(struct cgroup *cgrp)
{
	struct namei_ext_scope_set *old_scopes;
	int ret = 0;

	mutex_lock(&namei_ext_scopes_lock);
	if (cgroup_is_dead(cgrp)) {
		ret = -ENODEV;
		old_scopes = NULL;
	} else {
		old_scopes = namei_ext_scope_replace_locked(cgrp, NULL);
	}
	mutex_unlock(&namei_ext_scopes_lock);

	namei_ext_finish_scope_replace(old_scopes);
	return ret;
}

static ssize_t namei_ext_policy_parent_write(struct file *file,
					     const char __user *buf,
					     size_t count, loff_t *ppos)
{
	char command[16] = {};
	char kbuf[64];
	struct cgroup *cgrp;
	unsigned int fd_num;
	struct fd fd;
	struct path path;
	char extra;
	int fields;
	int ret;

	if (!count || count >= sizeof(kbuf))
		return -EINVAL;
	if (copy_from_user(kbuf, buf, count))
		return -EFAULT;
	kbuf[count] = '\0';

	cgrp = namei_ext_current_cgroup();
	if (!cgrp)
		return -ENODEV;

	fields = sscanf(kbuf, "%15s %u %c", command, &fd_num, &extra);
	if (!strcmp(command, "clear") || !strcmp(command, "global")) {
		if (fields != 1) {
			ret = -EINVAL;
			goto out_put_cgroup;
		}
		cgroup_lock();
		if (!namei_ext_cgroup_owns_policy(cgrp))
			ret = -ENOENT;
		else if (!strcmp(command, "clear"))
			ret = namei_ext_scope_empty(cgrp);
		else
			ret = namei_ext_scope_global(cgrp);
		cgroup_unlock();
		goto out_put_cgroup;
	}
	if ((strcmp(command, "exact") && strcmp(command, "add")) ||
	    fields != 2) {
		ret = -EINVAL;
		goto out_put_cgroup;
	}
	fd = fdget_raw(fd_num);
	if (fd_empty(fd)) {
		ret = -EBADF;
		goto out_put_cgroup;
	}
	path = fd_file(fd)->f_path;
	if (!d_can_lookup(path.dentry)) {
		ret = -ENOTDIR;
	} else {
		cgroup_lock();
		if (!namei_ext_cgroup_owns_policy(cgrp))
			ret = -ENOENT;
		else if (!strcmp(command, "exact"))
			ret = namei_ext_scope_exact(cgrp, &path);
		else
			ret = namei_ext_scope_add(cgrp, &path);
		cgroup_unlock();
	}
	fdput(fd);

out_put_cgroup:
	namei_ext_put_cgroup(cgrp);
	return ret ? ret : count;
}

static const struct file_operations namei_ext_policy_parent_fops = {
	.write = namei_ext_policy_parent_write,
};

static int __init namei_ext_debugfs_init(void)
{
	namei_ext_debugfs_dir = debugfs_create_dir("namei_ext", NULL);
	debugfs_create_file("register_target", 0200, namei_ext_debugfs_dir,
			    NULL, &namei_ext_register_target_fops);
	debugfs_create_file("policy_parent", 0200, namei_ext_debugfs_dir,
			    NULL, &namei_ext_policy_parent_fops);
	return 0;
}
late_initcall(namei_ext_debugfs_init);

bool namei_ext_parent_maybe_managed(const struct path *parent)
{
	struct namei_ext_scope *entry;
	unsigned long key;
	unsigned int seq;
	bool found = false;

	seq = read_seqcount_begin(&namei_ext_scope_seq);
	if (!READ_ONCE(namei_ext_global_scope_users) &&
	    !READ_ONCE(namei_ext_exact_scope_users) &&
	    !read_seqcount_retry(&namei_ext_scope_seq, seq))
		return false;

	key = namei_ext_scope_key(parent);
	rcu_read_lock();
	do {
		seq = read_seqcount_begin(&namei_ext_scope_seq);
		found = READ_ONCE(namei_ext_global_scope_users) != 0;
		if (found)
			continue;
		hash_for_each_possible_rcu(namei_ext_scope_index, entry, node,
					   key) {
			if (!path_equal(&entry->path, parent))
				continue;
			found = true;
			break;
		}
	} while (read_seqcount_retry(&namei_ext_scope_seq, seq));
	rcu_read_unlock();
	return found;
}

bool namei_ext_policy_parent_matches(const struct cgroup *cgrp,
				     const struct path *parent)
{
	struct namei_ext_scope_set *scopes;
	u32 i;

	scopes = rcu_dereference(cgrp->bpf.namei_ext_scopes);
	if (!scopes)
		return true;
	for (i = 0; i < scopes->nr; i++) {
		if (path_equal(&scopes->entries[i].path, parent))
			return true;
	}
	return false;
}

void namei_ext_cgroup_set_scope_active(struct cgroup *cgrp, bool active)
{
	struct namei_ext_scope_set *scopes;

	mutex_lock(&namei_ext_scopes_lock);
	if (cgrp->bpf.namei_ext_scope_active == active)
		goto out;

	raw_spin_lock(&namei_ext_scope_seq_lock);
	write_seqcount_begin(&namei_ext_scope_seq);
	scopes = rcu_dereference_protected(cgrp->bpf.namei_ext_scopes, 1);
	if (!scopes) {
		if (active)
			namei_ext_global_scope_get_locked();
		else
			namei_ext_global_scope_put_locked();
	}
	cgrp->bpf.namei_ext_scope_active = active;
	write_seqcount_end(&namei_ext_scope_seq);
	raw_spin_unlock(&namei_ext_scope_seq_lock);
out:
	mutex_unlock(&namei_ext_scopes_lock);
}

void namei_ext_cgroup_release(struct cgroup *cgrp)
{
	struct namei_ext_scope_set *old_scopes;

	mutex_lock(&namei_ext_scopes_lock);
	old_scopes = namei_ext_scope_replace_locked(cgrp,
						    &namei_ext_scope_tombstone);
	cgrp->bpf.namei_ext_scope_active = false;
	mutex_unlock(&namei_ext_scopes_lock);

	namei_ext_finish_scope_replace(old_scopes);
	namei_ext_clear_targets(cgroup_id(cgrp));
}

static void namei_ext_init_ctx(struct bpf_namei_ext_ctx *ctx,
			       const struct path *parent,
			       const struct inode *parent_inode, u32 event,
			       u32 flags, const struct qstr *name)
{
	const struct inode *inode = parent_inode;
	u32 copied;

	ctx->event = event;
	ctx->flags = flags;
	ctx->name_len = name->len;
	ctx->name_hash = name->hash;
	ctx->cgroup_id = 0;
	ctx->redirect_name_len = 0;
	ctx->target_id = 0;
	ctx->parent_dev = 0;
	ctx->parent_ino = 0;
	ctx->parent_generation = 0;
	ctx->parent_flags = 0;

	copied = min_t(u32, name->len, BPF_NAMEI_EXT_NAME_MAX);
	memcpy(ctx->name, name->name, copied);
	if (copied < BPF_NAMEI_EXT_NAME_MAX)
		memset(ctx->name + copied, 0,
		       BPF_NAMEI_EXT_NAME_MAX - copied);
	memset(ctx->redirect_name, 0, BPF_NAMEI_EXT_NAME_MAX);

	if (!inode && parent && parent->dentry)
		inode = d_backing_inode(parent->dentry);
	if (inode) {
		ctx->parent_dev = inode->i_sb ? inode->i_sb->s_dev : 0;
		ctx->parent_ino = inode->i_ino;
		ctx->parent_generation = inode->i_generation;
	}
}

static bool namei_ext_redirect_valid(const struct bpf_namei_ext_ctx *ctx)
{
	u32 len = ctx->redirect_name_len;
	u32 i;

	if (!len || len > BPF_NAMEI_EXT_NAME_MAX)
		return false;
	if (len == 1 && ctx->redirect_name[0] == '.')
		return false;
	if (len == 2 && ctx->redirect_name[0] == '.' &&
	    ctx->redirect_name[1] == '.')
		return false;
	for (i = 0; i < len; i++) {
		if (ctx->redirect_name[i] == '/' ||
		    ctx->redirect_name[i] == '\0')
			return false;
	}
	return true;
}

static void namei_ext_fill_redirect(const struct path *parent,
				    const struct bpf_namei_ext_ctx *ctx,
				    struct namei_ext_redirect *redirect)
{
	redirect->active = true;
	redirect->len = ctx->redirect_name_len;
	memcpy(redirect->name, ctx->redirect_name, redirect->len);
	redirect->hash = full_name_hash(parent->dentry, redirect->name,
					redirect->len);
}

int namei_ext_lookup(const struct path *parent, const struct inode *parent_inode,
		     const struct qstr *name, u32 event, u32 lookup_flags,
		     struct namei_ext_redirect *redirect)
{
	struct bpf_namei_ext_ctx ctx;
	int action;

	redirect->active = false;
	redirect->target_pending = false;
	redirect->target_active = false;
	redirect->target_borrowed = false;
	namei_ext_init_ctx(&ctx, parent, parent_inode, event, lookup_flags, name);
	action = __cgroup_bpf_run_namei_ext(&ctx, parent);
	if (action < 0)
		return action;

	switch (action) {
	case BPF_NAMEI_EXT_PASS:
		return 0;
	case BPF_NAMEI_EXT_REDIRECT:
		if (lookup_flags & LOOKUP_CREATE)
			return -EOPNOTSUPP;
		if (!namei_ext_redirect_valid(&ctx))
			return -EINVAL;
		namei_ext_fill_redirect(parent, &ctx, redirect);
		return 0;
	case BPF_NAMEI_EXT_HIDE:
		return -ENOENT;
	case BPF_NAMEI_EXT_SELECT_TARGET:
		if (lookup_flags & LOOKUP_CREATE)
			return -EOPNOTSUPP;
		if ((lookup_flags & LOOKUP_OPEN) &&
		    !(lookup_flags & LOOKUP_DIRECTORY))
			return -EOPNOTSUPP;
		redirect->target_cgroup_id = ctx.cgroup_id;
		redirect->target_id = ctx.target_id;
		redirect->target_pending = true;
		return 0;
	default:
		return -EINVAL;
	}
}

int namei_ext_resolve_target(struct namei_ext_redirect *redirect,
			     bool rcu_walk)
{
	struct namei_ext_target *target;
	int ret;

	if (!redirect->target_pending)
		return 0;
	if (!redirect->target_id)
		return -EINVAL;

	if (rcu_walk) {
		lockdep_assert_in_rcu_read_lock();
		target = namei_ext_find_target_rcu(redirect->target_cgroup_id,
						   redirect->target_id);
		if (!target)
			return -ENOENT;
		redirect->target = target->path;
		redirect->target_borrowed = true;
	} else {
		ret = namei_ext_get_target(redirect->target_cgroup_id,
					   redirect->target_id,
					   &redirect->target);
		if (ret)
			return ret;
	}

	redirect->target_pending = false;
	redirect->target_active = true;
	return 0;
}

struct namei_ext_dir_context {
	struct dir_context ctx;
	struct dir_context *orig;
	struct file *file;
	struct cgroup *cgrp;
	int error;
};

static bool namei_ext_filldir(struct dir_context *ctx, const char *name,
			      int namlen, loff_t offset, u64 ino,
			      unsigned int d_type)
{
	struct namei_ext_dir_context *namei_ctx =
		container_of(ctx, struct namei_ext_dir_context, ctx);
	struct qstr qname = QSTR_INIT(name, namlen);
	struct bpf_namei_ext_ctx bpf_ctx;
	int action;

	qname.hash = full_name_hash(namei_ctx->file->f_path.dentry, name,
				    namlen);
	namei_ext_init_ctx(&bpf_ctx, &namei_ctx->file->f_path,
			   file_inode(namei_ctx->file),
			   BPF_NAMEI_EXT_READDIR, 0, &qname);
	action = __cgroup_bpf_run_namei_ext_cgroup(namei_ctx->cgrp, &bpf_ctx);

	switch (action) {
	case BPF_NAMEI_EXT_PASS:
		namei_ctx->orig->pos = ctx->pos;
		namei_ctx->orig->count = ctx->count;
		namei_ctx->orig->dt_flags_mask = ctx->dt_flags_mask;
		if (!namei_ctx->orig->actor(namei_ctx->orig, name, namlen,
					    offset, ino, d_type))
			return false;
		ctx->pos = namei_ctx->orig->pos;
		ctx->count = namei_ctx->orig->count;
		ctx->dt_flags_mask = namei_ctx->orig->dt_flags_mask;
		return true;
	case BPF_NAMEI_EXT_REDIRECT:
		if (!namei_ext_redirect_valid(&bpf_ctx)) {
			namei_ctx->error = -EINVAL;
			return false;
		}
		namei_ctx->orig->pos = ctx->pos;
		namei_ctx->orig->count = ctx->count;
		namei_ctx->orig->dt_flags_mask = ctx->dt_flags_mask;
		if (!namei_ctx->orig->actor(
			    namei_ctx->orig,
			    (const char *)bpf_ctx.redirect_name,
			    bpf_ctx.redirect_name_len, offset, ino, d_type))
			return false;
		ctx->pos = namei_ctx->orig->pos;
		ctx->count = namei_ctx->orig->count;
		ctx->dt_flags_mask = namei_ctx->orig->dt_flags_mask;
		return true;
	case BPF_NAMEI_EXT_HIDE:
		return true;
	case BPF_NAMEI_EXT_SELECT_TARGET:
		namei_ctx->error = -EOPNOTSUPP;
		return false;
	default:
		namei_ctx->error = action < 0 ? action : -EINVAL;
		return false;
	}
}

int namei_ext_iterate_dir(struct file *file, struct dir_context *ctx,
			  int (*iter)(struct file *, struct dir_context *))
{
	struct cgroup *cgrp;
	struct namei_ext_dir_context namei_ctx = {
		.ctx = {
			.actor = namei_ext_filldir,
			.pos = ctx->pos,
			.count = ctx->count,
			.dt_flags_mask = ctx->dt_flags_mask,
		},
		.orig = ctx,
		.file = file,
	};
	int ret;

	cgrp = cgroup_bpf_get_namei_ext_cgroup(&file->f_path);
	if (!cgrp)
		return iter(file, ctx);
	namei_ctx.cgrp = cgrp;

	ret = iter(file, &namei_ctx.ctx);
	ctx->pos = namei_ctx.ctx.pos;
	ctx->count = namei_ctx.ctx.count;
	ctx->dt_flags_mask = namei_ctx.ctx.dt_flags_mask;
	if (!ret && namei_ctx.error)
		ret = namei_ctx.error;
	cgroup_bpf_put(cgrp);
	cgroup_put(cgrp);
	return ret;
}
