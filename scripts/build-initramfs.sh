#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/.build/initramfs.cpio.gz"}
STAGE="$ROOT/.build/initramfs-root"
BPF_DIR=${EBPFOS_BPF_DIR:-"$ROOT/.build/bpf-native"}
rm -rf "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/dev" "$STAGE/proc" "$STAGE/sys" "$STAGE/tmp" "$STAGE/opt/ebpfos" "$(dirname "$OUT")"
${CC:-cc} -static -Os -s "$ROOT/initramfs/init.c" -o "$STAGE/init"
${CC:-cc} -static -Os -s -D_GNU_SOURCE -D_POSIX_C_SOURCE=200809L -I"$ROOT/kernel-module" "$ROOT/cmd/ebpfosctl.c" -o "$STAGE/bin/ebpfosctl"
${CC:-cc} -static -Os -s -D_GNU_SOURCE -D_POSIX_C_SOURCE=200809L -I"$ROOT/kernel-module" "$ROOT/cmd/ebpfos-load.c" -o "$STAGE/bin/ebpfos-load"
for name in syscall test_override filesystem test_deny_len6 scheduler memory block network security driver lifecycle; do test -f "$BPF_DIR/$name.bpf.o" || { echo "missing native BPF object: $BPF_DIR/$name.bpf.o" >&2; exit 2; }; cp "$BPF_DIR/$name.bpf.o" "$STAGE/opt/ebpfos/"; done
( cd "$STAGE"; find . -print0 | sort -z | cpio --null -o --format=newc 2>/dev/null | gzip -9n ) > "$OUT"
printf '%s\n' "$OUT"
