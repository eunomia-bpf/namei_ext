// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) 1998-2022 Erez Zadok
 * Copyright (c) 2009	   Shrikar Archak
 * Copyright (c) 2003-2022 Stony Brook University
 * Copyright (c) 2003-2022 The Research Foundation of SUNY
 */

#include "wrapfs.h"

static vm_fault_t wrapfs_fault(struct vm_fault *vmf)
{
	vm_fault_t err;
        struct vm_area_struct *vma = vmf->vma;
	struct file *file, *lower_file;
	const struct vm_operations_struct *lower_vm_ops;
	struct vm_area_struct lower_vma;
	struct vm_area_struct **vma_p = (struct vm_area_struct**) &vmf->vma;

	memcpy(&lower_vma, vma, sizeof(struct vm_area_struct));
	file = lower_vma.vm_file;
	lower_vm_ops = WRAPFS_F(file)->lower_vm_ops;
	BUG_ON(!lower_vm_ops);

	lower_file = wrapfs_lower_file(file);
	/*
	 * XXX: vm_ops->fault may be called in parallel.  Because we have to
	 * resort to temporarily changing the vma->vm_file to point to the
	 * lower file, a concurrent invocation of wrapfs_fault could see a
	 * different value.  In this workaround, we keep a different copy of
	 * the vma structure in our stack, so we never expose a different
	 * value of the vma->vm_file called to us, even temporarily.  A
	 * better fix would be to change the calling semantics of ->fault to
	 * take an explicit file pointer.
	 */
	lower_vma.vm_file = lower_file;
	*vma_p = &lower_vma;
	err = lower_vm_ops->fault(vmf);
	*vma_p = vma;
	return err;
}

static vm_fault_t wrapfs_page_mkwrite(struct vm_fault *vmf)
{
	vm_fault_t err = 0;
        struct vm_area_struct *vma = vmf->vma;
	struct file *file, *lower_file;
	const struct vm_operations_struct *lower_vm_ops;
	struct vm_area_struct lower_vma;
	struct vm_area_struct **vma_p = (struct vm_area_struct**) &vmf->vma;

	memcpy(&lower_vma, vma, sizeof(struct vm_area_struct));
	file = lower_vma.vm_file;
	lower_vm_ops = WRAPFS_F(file)->lower_vm_ops;
	BUG_ON(!lower_vm_ops);
	if (!lower_vm_ops->page_mkwrite)
		goto out;

	lower_file = wrapfs_lower_file(file);
	/*
	 * XXX: vm_ops->page_mkwrite may be called in parallel.
	 * Because we have to resort to temporarily changing the
	 * vma->vm_file to point to the lower file, a concurrent
	 * invocation of wrapfs_page_mkwrite could see a different
	 * value.  In this workaround, we keep a different copy of the
	 * vma structure in our stack, so we never expose a different
	 * value of the vma->vm_file called to us, even temporarily.
	 * A better fix would be to change the calling semantics of
	 * ->page_mkwrite to take an explicit file pointer.
	 */
	lower_vma.vm_file = lower_file;
	*vma_p = &lower_vma;	/* override vma temporarily */
	err = lower_vm_ops->page_mkwrite(vmf);
	*vma_p = vma;	/* restore vma */
out:
	return err;
}

static ssize_t wrapfs_direct_IO(struct kiocb *iocb, struct iov_iter *iter)
{
	/*
	 * This function should never be called directly.  We need it
	 * to exist, to get past a check in open_check_o_direct(),
	 * which is called from do_last().
	 */
	return -EINVAL;
}

static sector_t wrapfs_bmap(struct address_space *mapping, sector_t block)
{
	struct inode *lower_inode = wrapfs_lower_inode(mapping->host);
	int err = bmap(lower_inode, &block);

	if (err)
		return 0;
	return block;
}

const struct address_space_operations wrapfs_aops = {
	.direct_IO = wrapfs_direct_IO,
	.bmap = wrapfs_bmap,
};

const struct vm_operations_struct wrapfs_vm_ops = {
	.fault		= wrapfs_fault,
	.page_mkwrite	= wrapfs_page_mkwrite,
};
