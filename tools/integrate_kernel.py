#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
from __future__ import annotations
import argparse, pathlib, re, shutil, sys
class IntegrationError(RuntimeError): pass

def replace_once(path:pathlib.Path,old:str,new:str)->None:
    text=path.read_text(); count=text.count(old)
    if count==0 and new in text:return
    if count!=1:raise IntegrationError(f"{path}: expected one anchor, found {count}: {old[:80]!r}")
    path.write_text(text.replace(old,new,1))

def regex_once(path:pathlib.Path,pattern:str,replacement:str)->None:
    text=path.read_text()
    if "EBPFOS generated boundary" in text:return
    regex=re.compile(pattern,re.MULTILINE|re.DOTALL); matches=list(regex.finditer(text))
    if not matches:raise IntegrationError(f"{path}: regex anchor not found: {pattern}")
    if len(matches)!=1:raise IntegrationError(f"{path}: regex anchor is ambiguous ({len(matches)})")
    path.write_text(regex.sub(replacement,text,count=1))

def add_include(path:pathlib.Path,anchor:str)->None:
    text=path.read_text(); include="#include <linux/ebpfos.h>"
    if include in text:return
    if text.count(anchor)!=1:raise IntegrationError(f"{path}: include anchor mismatch")
    path.write_text(text.replace(anchor,anchor+"\n"+include,1))

def install_overlay(root:pathlib.Path,overlay:pathlib.Path)->None:
    for source in overlay.rglob("*"):
        if source.is_dir():continue
        target=root/source.relative_to(overlay); target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(source,target)

def integrate(root:pathlib.Path,overlay:pathlib.Path)->None:
    if not (root/"Makefile").is_file() or not (root/"kernel/Makefile").is_file():raise IntegrationError(f"{root} is not a Linux source tree")
    install_overlay(root,overlay)
    replace_once(root/"init/Kconfig",'# end of the "standard kernel features (expert users)" menu\n','# end of the "standard kernel features (expert users)" menu\n\nsource "kernel/ebpfos/Kconfig"\n')
    replace_once(root/"kernel/Makefile","obj-$(CONFIG_BPF) += bpf/\n","obj-$(CONFIG_BPF) += bpf/\nobj-$(CONFIG_EBPFOS) += ebpfos/\n")
    syscall=root/"arch/x86/entry/syscall_64.c"; add_include(syscall,"#include <linux/entry-common.h>")
    replace_once(syscall,"\tinstrumentation_begin();\n\tadd_random_kstack_offset();\n\n\tif (!do_syscall_x64(regs, nr) && !do_syscall_x32(regs, nr) && nr != -1) {\n","""\tinstrumentation_begin();
\tadd_random_kstack_offset();

\t/* EBPFOS generated boundary: syscall component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_SYSCALL_HOOK) && nr >= 0) {
\t\tu64 ebpfos_args[EBPFOS_MAX_ARGS] = { nr, regs->di, regs->si, regs->dx, regs->r10, regs->r8 };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_SYSCALL_ENTER, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tswitch (EBPFOS_ACTION_VERDICT(ebpfos_action)) {
\t\tcase EBPFOS_VERDICT_DENY: regs->ax = ebpfos_action_error(ebpfos_action); goto ebpfos_syscall_done;
\t\tcase EBPFOS_VERDICT_REDIRECT: nr = EBPFOS_ACTION_PAYLOAD(ebpfos_action); break;
\t\tcase EBPFOS_VERDICT_OVERRIDE: regs->ax = EBPFOS_ACTION_PAYLOAD(ebpfos_action); goto ebpfos_syscall_done;
\t\tdefault: break;
\t\t}
\t}

\tif (!do_syscall_x64(regs, nr) && !do_syscall_x32(regs, nr) && nr != -1) {
""")
    replace_once(syscall,"\tinstrumentation_end();\n\tsyscall_exit_to_user_mode(regs);","""ebpfos_syscall_done:
\tif (IS_ENABLED(CONFIG_EBPFOS_SYSCALL_HOOK) && nr >= 0) {
\t\tu64 ebpfos_exit_args[3] = { nr, regs->ax, regs->orig_ax };
\t\tu32 ebpfos_exit_action = ebpfos_run_hook(EBPFOS_HOOK_SYSCALL_EXIT, ebpfos_exit_args, ARRAY_SIZE(ebpfos_exit_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_exit_action) == EBPFOS_VERDICT_DENY) regs->ax = ebpfos_action_error(ebpfos_exit_action);
\t\telse if (EBPFOS_ACTION_VERDICT(ebpfos_exit_action) == EBPFOS_VERDICT_OVERRIDE) regs->ax = EBPFOS_ACTION_PAYLOAD(ebpfos_exit_action);
\t}
\tinstrumentation_end();
\tsyscall_exit_to_user_mode(regs);""")
    namei=root/"fs/namei.c"; add_include(namei,"#include <linux/uaccess.h>")
    regex_once(namei,r"(static __always_inline const char \*walk_component\(struct nameidata \*nd, int flags\)\s*\{)",r"""\1
\t/* EBPFOS generated boundary: VFS component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_VFS_HOOK)) {
\t\tu64 ebpfos_args[4] = { nd->last.hash, nd->last.len, flags, nd->flags };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_VFS_LOOKUP, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) return ERR_PTR(ebpfos_action_error(ebpfos_action));
\t}
""")
    readdir=root/"fs/readdir.c"; add_include(readdir,"#include <linux/uaccess.h>")
    regex_once(readdir,r"(int iterate_dir\(struct file \*file, struct dir_context \*ctx\)\s*\{\s*struct inode \*inode = file_inode\(file\);\s*int res = -ENOTDIR;)",r"""\1
\n\t/* EBPFOS generated boundary: VFS readdir component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_VFS_HOOK)) {
\t\tu64 ebpfos_args[4] = { (u64)(unsigned long)file, (u64)(unsigned long)inode, ctx->pos, file->f_mode };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_VFS_READDIR, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) { res = ebpfos_action_error(ebpfos_action); goto out; }
\t}
""")
    vmscan=root/"mm/vmscan.c"; add_include(vmscan,"#include <linux/mm.h>")
    regex_once(vmscan,r"(static void shrink_node\(pg_data_t \*pgdat,\s*struct scan_control \*sc\)\s*\{)",r"""\1
\t/* EBPFOS generated boundary: memory reclaim component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_MM_HOOK)) {
\t\tu64 ebpfos_args[4] = { sc->nr_to_reclaim, sc->priority, sc->gfp_mask, pgdat->node_id };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_MM_RECLAIM, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) return;
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_OVERRIDE && EBPFOS_ACTION_PAYLOAD(ebpfos_action)) sc->nr_to_reclaim = EBPFOS_ACTION_PAYLOAD(ebpfos_action);
\t}
""")
    block=root/"block/blk-mq.c"; add_include(block,"#include <linux/bio.h>")
    regex_once(block,r"(void blk_mq_submit_bio\(struct bio \*bio\)\s*\{)",r"""\1
\t/* EBPFOS generated boundary: block component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_BLOCK_HOOK)) {
\t\tu64 ebpfos_args[4] = { bio->bi_iter.bi_sector, bio->bi_iter.bi_size, bio->bi_opf, (u64)(unsigned long)bio->bi_bdev };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_BLOCK_SUBMIT, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) { bio_io_error(bio); return; }
\t}
""")
    driver=root/"drivers/base/dd.c"; add_include(driver,"#include <linux/device.h>")
    regex_once(driver,r"(static int really_probe\(struct device \*dev,\s*const struct device_driver \*drv\)\s*\{)",r"""\1
\t/* EBPFOS generated boundary: driver component. */
\tif (IS_ENABLED(CONFIG_EBPFOS_DRIVER_HOOK)) {
\t\tu64 ebpfos_args[4] = { (u64)(unsigned long)dev, (u64)(unsigned long)drv, (u64)(unsigned long)dev->bus, (u64)(unsigned long)drv->owner };
\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_DRIVER_PROBE, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) return ebpfos_action_error(ebpfos_action);
\t}
""")
    replace_once(driver,"\tdrv = dev->driver;\n\tif (drv) {\n","""\tdrv = dev->driver;
\tif (drv) {
\t\t/* EBPFOS generated boundary: driver lifecycle component. */
\t\tif (IS_ENABLED(CONFIG_EBPFOS_DRIVER_HOOK)) {
\t\t\tu64 ebpfos_args[3] = { 1, (u64)(unsigned long)dev, (u64)(unsigned long)drv };
\t\t\tu32 ebpfos_action = ebpfos_run_hook(EBPFOS_HOOK_DRIVER_LIFECYCLE, ebpfos_args, ARRAY_SIZE(ebpfos_args));
\t\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) return;
\t\t}
""")
    (root/".ebpfos-integrated").write_text("linux=v7.1.8\nebpfos_abi=1\n")

def main(argv:list[str]|None=None)->int:
    p=argparse.ArgumentParser();p.add_argument("kernel",type=pathlib.Path);p.add_argument("--overlay",type=pathlib.Path);a=p.parse_args(argv);overlay=a.overlay or pathlib.Path(__file__).resolve().parents[1]/"kernel-overlay"
    try: integrate(a.kernel.resolve(),overlay.resolve())
    except IntegrationError as exc: print(exc,file=sys.stderr);return 1
    print(f"integrated eBPFOS into {a.kernel}");return 0
if __name__=="__main__":raise SystemExit(main())
