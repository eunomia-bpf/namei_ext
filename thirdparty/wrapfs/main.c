// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) 1998-2022 Erez Zadok
 * Copyright (c) 2009	   Shrikar Archak
 * Copyright (c) 2003-2022 Stony Brook University
 * Copyright (c) 2003-2022 The Research Foundation of SUNY
 */

#include "wrapfs.h"
#include <linux/module.h>

static int wrapfs_fill_super(struct super_block *sb, struct fs_context *fc)
{
	int err = 0;
	struct super_block *lower_sb;
	struct path lower_path = {};
	const char *dev_name = fc->source;
	struct inode *inode;

	if (!dev_name) {
		printk(KERN_ERR
		       "wrapfs: read_super: missing dev_name argument\n");
		err = -EINVAL;
		goto out;
	}

	/* parse lower path */
	err = kern_path(dev_name, LOOKUP_FOLLOW | LOOKUP_DIRECTORY,
			&lower_path);
	if (err) {
		printk(KERN_ERR	"wrapfs: error accessing "
		       "lower directory '%s'\n", dev_name);
		goto out;
	}

	/* allocate superblock private data */
	sb->s_fs_info = kzalloc(sizeof(struct wrapfs_sb_info), GFP_KERNEL);
	if (!WRAPFS_SB(sb)) {
		printk(KERN_CRIT "wrapfs: read_super: out of memory\n");
		err = -ENOMEM;
		goto out_pput;
	}

	/* set the lower superblock field of upper superblock */
	lower_sb = lower_path.dentry->d_sb;
	atomic_inc(&lower_sb->s_active);
	wrapfs_set_lower_super(sb, lower_sb);

	/* inherit maxbytes from lower file system */
	sb->s_maxbytes = lower_sb->s_maxbytes;
	sb->s_stack_depth = lower_sb->s_stack_depth + 1;
	if (sb->s_stack_depth > FILESYSTEM_MAX_STACK_DEPTH) {
		pr_err("wrapfs: lower filesystem stack depth %u exceeds limit\n",
		       lower_sb->s_stack_depth);
		err = -EINVAL;
		goto out_pput;
	}

	/*
	 * Our c/m/atime granularity is 1 ns because we may stack on file
	 * systems whose granularity is as good.
	 */
	sb->s_time_gran = 1;
	sb->s_magic = WRAPFS_SUPER_MAGIC;

	sb->s_op = &wrapfs_sops;
	set_default_d_op(sb, &wrapfs_dops);

	/* get a new inode and allocate our root dentry */
	inode = wrapfs_iget(sb, d_inode(lower_path.dentry));
	if (IS_ERR(inode)) {
		err = PTR_ERR(inode);
		goto out_pput;
	}
	sb->s_root = d_make_root(inode);
	if (!sb->s_root) {
		err = -ENOMEM;
		goto out_pput;
	}
	/* set the lower dentries for s_root */
	wrapfs_set_lower_path(sb->s_root, &lower_path);

	/*
	 * No need to call interpose because we already have a positive
	 * dentry, which was instantiated by d_make_root.  Just need to
	 * d_rehash it.
	 */
	d_rehash(sb->s_root);
	printk(KERN_INFO "wrapfs: mounted on top of %s type %s\n",
	       dev_name, lower_sb->s_type->name);
	goto out; /* all is well */

	/*
	 * path_put is the only resource we need to free if an error occurred
	 * because returning an error from this function will cause
	 * generic_shutdown_super to be called, which will call
	 * wrapfs_put_super, and that function will release any other
	 * resources we took.
	 */
out_pput:
	path_put(&lower_path);
out:
	return err;
}

static int wrapfs_get_tree(struct fs_context *fc)
{
	int err;

	pr_info("wrapfs: get_tree source=%s\n",
		fc->source ? fc->source : "(null)");
	err = get_tree_nodev(fc, wrapfs_fill_super);
	if (err)
		pr_err("wrapfs: get_tree failed: %d\n", err);
	return err;
}

static const struct fs_context_operations wrapfs_context_ops = {
	.get_tree = wrapfs_get_tree,
};

static int wrapfs_init_fs_context(struct fs_context *fc)
{
	fc->ops = &wrapfs_context_ops;
	return 0;
}

static struct file_system_type wrapfs_fs_type = {
	.owner		= THIS_MODULE,
	.name		= WRAPFS_NAME,
	.init_fs_context = wrapfs_init_fs_context,
	.kill_sb	= kill_anon_super,
	.fs_flags	= 0,
};
MODULE_ALIAS_FS(WRAPFS_NAME);

static int __init init_wrapfs_fs(void)
{
	int err;

	pr_info("Registering wrapfs " WRAPFS_VERSION "\n");

	err = wrapfs_init_inode_cache();
	if (err)
		goto out;
	err = wrapfs_init_dentry_cache();
	if (err)
		goto out;
	err = register_filesystem(&wrapfs_fs_type);
out:
	if (err) {
		wrapfs_destroy_inode_cache();
		wrapfs_destroy_dentry_cache();
	}
	return err;
}

static void __exit exit_wrapfs_fs(void)
{
	wrapfs_destroy_inode_cache();
	wrapfs_destroy_dentry_cache();
	unregister_filesystem(&wrapfs_fs_type);
	pr_info("Completed wrapfs module unload\n");
}

MODULE_AUTHOR("Erez Zadok, Filesystems and Storage Lab, Stony Brook University"
	      " (https://www.fsl.cs.sunysb.edu/)");
MODULE_DESCRIPTION("Wrapfs " WRAPFS_VERSION
		   " (https://wrapfs.filesystems.org/)");
MODULE_LICENSE("GPL");

module_init(init_wrapfs_fs);
module_exit(exit_wrapfs_fs);
