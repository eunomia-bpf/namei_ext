#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
from __future__ import annotations
import pathlib
import sys


def replace_once(path: pathlib.Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one network anchor, found {count}: {old!r}")
    path.write_text(text.replace(old, new, 1))


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} KERNEL", file=sys.stderr)
        return 2
    root = pathlib.Path(sys.argv[1]).resolve()
    path = root / "net/core/dev.c"
    if not path.is_file():
        raise RuntimeError(f"missing {path}")

    replace_once(
        path,
        "#include <linux/netdevice.h>\n",
        "#include <linux/netdevice.h>\n#include <linux/ebpfos.h>\n#include <linux/ebpfos_ops.h>\n",
    )
    replace_once(
        path,
        "\tstruct Qdisc *q;\n\n\tskb_reset_mac_header(skb);\n",
        """\tstruct Qdisc *q;

\t/* EBPFOS generated boundary: network component TX. */
\tif (IS_ENABLED(CONFIG_EBPFOS_NET_HOOK)) {
\t\tu64 ebpfos_args[4] = {
\t\t\t(u64)(unsigned long)skb, skb->len, skb->protocol, dev->ifindex
\t\t};
\t\tu32 ebpfos_action = ebpfos_component_run_hook(
\t\t\tEBPFOS_HOOK_NET_TX, ebpfos_args, ARRAY_SIZE(ebpfos_args));

\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY) {
\t\t\tkfree_skb(skb);
\t\t\treturn NET_XMIT_DROP;
\t\t}
\t}

\tskb_reset_mac_header(skb);
""",
    )
    replace_once(
        path,
        "\t__be16 type;\n\n\tnet_timestamp_check(!READ_ONCE(net_hotdata.tstamp_prequeue), skb);\n",
        """\t__be16 type;

\t/* EBPFOS generated boundary: network component RX. */
\tif (IS_ENABLED(CONFIG_EBPFOS_NET_HOOK)) {
\t\tu64 ebpfos_args[4] = {
\t\t\t(u64)(unsigned long)skb, skb->len, skb->protocol,
\t\t\tskb->dev ? skb->dev->ifindex : 0
\t\t};
\t\tu32 ebpfos_action = ebpfos_component_run_hook(
\t\t\tEBPFOS_HOOK_NET_RX, ebpfos_args, ARRAY_SIZE(ebpfos_args));

\t\tif (EBPFOS_ACTION_VERDICT(ebpfos_action) == EBPFOS_VERDICT_DENY)
\t\t\tgoto drop;
\t}

\tnet_timestamp_check(!READ_ONCE(net_hotdata.tstamp_prequeue), skb);
""",
    )
    print(f"integrated eBPFOS network boundaries into {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
