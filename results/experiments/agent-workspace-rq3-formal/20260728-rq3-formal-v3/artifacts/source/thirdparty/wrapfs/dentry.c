// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) 1998-2022 Erez Zadok
 * Copyright (c) 2009	   Shrikar Archak
 * Copyright (c) 2003-2022 Stony Brook University
 * Copyright (c) 2003-2022 The Research Foundation of SUNY
 */

#include "wrapfs.h"

/*
 * returns: -ERRNO if error (returned to user)
 *          0: tell VFS to invalidate dentry
 *          1: dentry is valid
 */
static int wrapfs_d_init(struct dentry *dentry)
{
	struct wrapfs_dentry_info *info;

	info = kmem_cache_zalloc(wrapfs_dentry_cachep, GFP_KERNEL);
	if (!info)
		return -ENOMEM;
	spin_lock_init(&info->lock);
	dentry->d_fsdata = info;
	return 0;
}

static int wrapfs_d_revalidate(struct inode *dir, const struct qstr *name,
			       struct dentry *dentry, unsigned int flags)
{
	struct path lower_path;
	struct dentry *lower_dentry;
	int err = 1;

	if (flags & LOOKUP_RCU)
		return -ECHILD;

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_dentry = lower_path.dentry;
	if (!lower_dentry ||
	    !(lower_dentry->d_flags & DCACHE_OP_REVALIDATE))
		goto out;
	err = lower_dentry->d_op->d_revalidate(wrapfs_lower_inode(dir), name,
					       lower_dentry, flags);
out:
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static void wrapfs_d_release(struct dentry *dentry)
{
	/*
	 * It is possible that the dentry private data is NULL in case we
	 * ran out of memory while initializing it in
	 * new_dentry_private_data.  So check for NULL before attempting to
	 * release resources.
	 */
	if (WRAPFS_D(dentry)) {
		/* release and reset the lower paths */
		wrapfs_put_reset_lower_path(dentry);
		kmem_cache_free(wrapfs_dentry_cachep, dentry->d_fsdata);
		dentry->d_fsdata = NULL;
	}
	return;
}

const struct dentry_operations wrapfs_dops = {
	.d_init		= wrapfs_d_init,
	.d_revalidate	= wrapfs_d_revalidate,
	.d_release	= wrapfs_d_release,
};
