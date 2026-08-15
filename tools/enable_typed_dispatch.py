#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
from __future__ import annotations
import pathlib
import sys

FILES = (
    "arch/x86/entry/syscall_64.c",
    "fs/namei.c",
    "fs/readdir.c",
    "mm/vmscan.c",
    "block/blk-mq.c",
    "drivers/base/dd.c",
    "net/core/dev.c",
)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} KERNEL", file=sys.stderr)
        return 2
    root = pathlib.Path(sys.argv[1]).resolve()
    touched = 0
    for relative in FILES:
        path = root / relative
        if not path.exists():
            continue
        text = path.read_text()
        if "EBPFOS generated boundary" not in text:
            continue
        if "#include <linux/ebpfos.h>" in text and "#include <linux/ebpfos_ops.h>" not in text:
            text = text.replace(
                "#include <linux/ebpfos.h>\n",
                "#include <linux/ebpfos.h>\n#include <linux/ebpfos_ops.h>\n",
                1,
            )
        new = text.replace("ebpfos_run_hook(", "ebpfos_component_run_hook(")
        if new != path.read_text():
            path.write_text(new)
            touched += 1
    print(f"typed eBPFOS dispatch enabled in {touched} Linux source files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
