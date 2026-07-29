// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) 1998-2022 Erez Zadok
 * Copyright (c) 2009	   Shrikar Archak
 * Copyright (c) 2003-2022 Stony Brook University
 * Copyright (c) 2003-2022 The Research Foundation of SUNY
 */

#include "wrapfs.h"

static int wrapfs_create(struct mnt_idmap *idmap, struct inode *dir,
			 struct dentry *dentry, umode_t mode, bool want_excl)
{
	struct path lower_path;
	struct dentry *lower_parent;
	struct dentry *lower_dentry;
	int err;

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_parent = dget_parent(lower_path.dentry);
	lower_dentry = start_creating_dentry(lower_parent, lower_path.dentry);
	if (IS_ERR(lower_dentry)) {
		err = PTR_ERR(lower_dentry);
		goto out_parent;
	}

	err = vfs_create(mnt_idmap(lower_path.mnt), lower_dentry, mode, NULL);
	if (!err)
		err = wrapfs_interpose(dentry, dir->i_sb, &lower_path);
	if (!err) {
		fsstack_copy_attr_times(dir, d_inode(lower_parent));
		fsstack_copy_inode_size(dir, d_inode(lower_parent));
	}
	end_creating(lower_dentry);
out_parent:
	dput(lower_parent);
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static int wrapfs_unlink(struct inode *dir, struct dentry *dentry)
{
	struct path lower_path;
	struct dentry *lower_parent;
	struct dentry *lower_dentry;
	struct inode *lower_inode;
	int err;

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_parent = dget_parent(lower_path.dentry);
	lower_dentry = start_removing_dentry(lower_parent, lower_path.dentry);
	if (IS_ERR(lower_dentry)) {
		err = PTR_ERR(lower_dentry);
		goto out_parent;
	}

	lower_inode = d_inode(lower_dentry);
	err = vfs_unlink(mnt_idmap(lower_path.mnt), d_inode(lower_parent),
			 lower_dentry, NULL);
	if (!err) {
		fsstack_copy_attr_times(dir, d_inode(lower_parent));
		fsstack_copy_inode_size(dir, d_inode(lower_parent));
		set_nlink(d_inode(dentry), lower_inode->i_nlink);
		inode_set_ctime_to_ts(d_inode(dentry), inode_get_ctime(dir));
	}
	end_removing(lower_dentry);
	if (!err)
		d_drop(dentry);
out_parent:
	dput(lower_parent);
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static int wrapfs_symlink(struct mnt_idmap *idmap, struct inode *dir,
			  struct dentry *dentry, const char *symname)
{
	struct path lower_path;
	struct dentry *lower_parent;
	struct dentry *lower_dentry;
	int err;

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_parent = dget_parent(lower_path.dentry);
	lower_dentry = start_creating_dentry(lower_parent, lower_path.dentry);
	if (IS_ERR(lower_dentry)) {
		err = PTR_ERR(lower_dentry);
		goto out_parent;
	}

	err = vfs_symlink(mnt_idmap(lower_path.mnt), d_inode(lower_parent),
			  lower_dentry, symname, NULL);
	if (!err)
		err = wrapfs_interpose(dentry, dir->i_sb, &lower_path);
	if (!err) {
		fsstack_copy_attr_times(dir, d_inode(lower_parent));
		fsstack_copy_inode_size(dir, d_inode(lower_parent));
	}
	end_creating(lower_dentry);
out_parent:
	dput(lower_parent);
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static int wrapfs_rename(struct mnt_idmap *idmap, struct inode *old_dir,
			 struct dentry *old_dentry, struct inode *new_dir,
			 struct dentry *new_dentry, unsigned int flags)
{
	struct path lower_old_path;
	struct path lower_new_path;
	struct dentry *lower_old_parent;
	struct dentry *lower_new_parent;
	struct renamedata rd = {};
	int err;

	if (flags)
		return -EINVAL;

	wrapfs_get_lower_path(old_dentry, &lower_old_path);
	wrapfs_get_lower_path(new_dentry, &lower_new_path);
	lower_old_parent = dget_parent(lower_old_path.dentry);
	lower_new_parent = dget_parent(lower_new_path.dentry);

	rd.mnt_idmap = mnt_idmap(lower_old_path.mnt);
	rd.old_parent = lower_old_parent;
	rd.new_parent = lower_new_parent;
	err = start_renaming_two_dentries(&rd, lower_old_path.dentry,
					  lower_new_path.dentry);
	if (err)
		goto out_parents;

	err = vfs_rename(&rd);
	if (!err) {
		fsstack_copy_attr_all(new_dir, d_inode(lower_new_parent));
		fsstack_copy_inode_size(new_dir, d_inode(lower_new_parent));
		if (new_dir != old_dir) {
			fsstack_copy_attr_all(old_dir, d_inode(lower_old_parent));
			fsstack_copy_inode_size(old_dir,
					       d_inode(lower_old_parent));
		}
	}
	end_renaming(&rd);
out_parents:
	dput(lower_old_parent);
	dput(lower_new_parent);
	wrapfs_put_lower_path(old_dentry, &lower_old_path);
	wrapfs_put_lower_path(new_dentry, &lower_new_path);
	return err;
}

static const char *wrapfs_get_link(struct dentry *dentry, struct inode *inode,
				   struct delayed_call *done)
{
	struct path lower_path;
	const char *lower_link;
	char *copy;
	DEFINE_DELAYED_CALL(lower_done);

	if (!dentry)
		return ERR_PTR(-ECHILD);

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_link = vfs_get_link(lower_path.dentry, &lower_done);
	if (IS_ERR(lower_link)) {
		copy = ERR_CAST(lower_link);
		goto out;
	}
	copy = kstrdup(lower_link, GFP_KERNEL);
	do_delayed_call(&lower_done);
	if (!copy) {
		copy = ERR_PTR(-ENOMEM);
		goto out;
	}
	fsstack_copy_attr_atime(d_inode(dentry), d_inode(lower_path.dentry));
	set_delayed_call(done, kfree_link, copy);
out:
	wrapfs_put_lower_path(dentry, &lower_path);
	return copy;
}

static int wrapfs_permission(struct mnt_idmap *idmap, struct inode *inode,
			     int mask)
{
	return inode_permission(&nop_mnt_idmap, wrapfs_lower_inode(inode), mask);
}

static int wrapfs_setattr(struct mnt_idmap *idmap, struct dentry *dentry,
			  struct iattr *ia)
{
	struct path lower_path;
	struct inode *inode = d_inode(dentry);
	struct inode *lower_inode;
	struct iattr lower_ia;
	int err;

	err = setattr_prepare(idmap, dentry, ia);
	if (err)
		return err;

	wrapfs_get_lower_path(dentry, &lower_path);
	lower_inode = d_inode(lower_path.dentry);
	lower_ia = *ia;
	if (ia->ia_valid & ATTR_FILE)
		lower_ia.ia_file = wrapfs_lower_file(ia->ia_file);

	if (ia->ia_valid & ATTR_SIZE) {
		err = inode_newsize_ok(inode, ia->ia_size);
		if (err)
			goto out;
		truncate_setsize(inode, ia->ia_size);
	}

	if (lower_ia.ia_valid & (ATTR_KILL_SUID | ATTR_KILL_SGID))
		lower_ia.ia_valid &= ~ATTR_MODE;

	inode_lock(lower_inode);
	err = notify_change(mnt_idmap(lower_path.mnt), lower_path.dentry,
			    &lower_ia, NULL);
	inode_unlock(lower_inode);
	if (!err) {
		fsstack_copy_attr_all(inode, lower_inode);
		fsstack_copy_inode_size(inode, lower_inode);
	}
out:
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static int wrapfs_getattr(struct mnt_idmap *idmap, const struct path *path,
			  struct kstat *stat, u32 request_mask,
			  unsigned int flags)
{
	struct dentry *dentry = path->dentry;
	struct path lower_path;
	int err;

	wrapfs_get_lower_path(dentry, &lower_path);
	err = vfs_getattr_nosec(&lower_path, stat, request_mask, flags);
	if (!err) {
		fsstack_copy_attr_all(d_inode(dentry),
				      d_inode(lower_path.dentry));
		stat->dev = dentry->d_sb->s_dev;
	}
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

static ssize_t wrapfs_listxattr(struct dentry *dentry, char *buffer,
				size_t buffer_size)
{
	struct path lower_path;
	ssize_t err;

	wrapfs_get_lower_path(dentry, &lower_path);
	err = vfs_listxattr(lower_path.dentry, buffer, buffer_size);
	wrapfs_put_lower_path(dentry, &lower_path);
	return err;
}

const struct inode_operations wrapfs_symlink_iops = {
	.permission	= wrapfs_permission,
	.setattr	= wrapfs_setattr,
	.getattr	= wrapfs_getattr,
	.get_link	= wrapfs_get_link,
	.listxattr	= wrapfs_listxattr,
};

const struct inode_operations wrapfs_dir_iops = {
	.create		= wrapfs_create,
	.lookup		= wrapfs_lookup,
	.unlink		= wrapfs_unlink,
	.symlink	= wrapfs_symlink,
	.rename		= wrapfs_rename,
	.permission	= wrapfs_permission,
	.setattr	= wrapfs_setattr,
	.getattr	= wrapfs_getattr,
	.listxattr	= wrapfs_listxattr,
};

const struct inode_operations wrapfs_main_iops = {
	.permission	= wrapfs_permission,
	.setattr	= wrapfs_setattr,
	.getattr	= wrapfs_getattr,
	.listxattr	= wrapfs_listxattr,
};
