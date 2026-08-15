#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL=${1:-"$ROOT/kernel"}
OUT=${2:-"$ROOT/.build/bpf-native"}
CLANG=${CLANG:-clang}
BPFTOOL=${BPFTOOL:-bpftool}
VMLINUX=${VMLINUX:-"$ROOT/.build/kernel-x86_64/vmlinux"}
command -v "$CLANG" >/dev/null || { echo "missing $CLANG" >&2; exit 2; }
if [ "${BPFTOOL#/}" != "$BPFTOOL" ]; then
	test -x "$BPFTOOL" || { echo "missing executable $BPFTOOL" >&2; exit 2; }
else
	command -v "$BPFTOOL" >/dev/null || { echo "missing $BPFTOOL" >&2; exit 2; }
fi
printf 'int x;' | "$CLANG" -target bpf -x c -c -o /dev/null - 2>/dev/null || { echo "$CLANG does not include the BPF backend" >&2; exit 2; }
mkdir -p "$OUT"
for source in components/syscall/syscall.bpf.c components/syscall/test_override.bpf.c components/filesystem/filesystem.bpf.c components/filesystem/test_deny_len6.bpf.c components/memory/memory.bpf.c components/block/block.bpf.c components/driver/driver.bpf.c components/driver/lifecycle.bpf.c components/network/network.bpf.c components/scheduler/scheduler.bpf.c components/security/security.bpf.c; do
	name=$(basename "$source" .bpf.c)
	"$CLANG" -target bpf -O2 -g -D__TARGET_ARCH_x86 -I"$ROOT/components/include" -Wall -Wextra -Werror -c "$ROOT/$source" -o "$OUT/$name.bpf.o"
done
test -d "$KERNEL/tools/sched_ext/include" || { echo "$KERNEL is not a Linux tree with sched_ext tools" >&2; exit 2; }
if [ -f "$VMLINUX" ]; then
	"$BPFTOOL" btf dump file "$VMLINUX" format c > "$OUT/vmlinux.h"
elif [ -r /sys/kernel/btf/vmlinux ]; then
	"$BPFTOOL" btf dump file /sys/kernel/btf/vmlinux format c > "$OUT/vmlinux.h"
else
	echo "no vmlinux BTF available" >&2
	exit 2
fi
ARCH=$(uname -m)
case "$ARCH" in
	x86_64) TARGET_ARCH=x86 ;;
	aarch64) TARGET_ARCH=arm64 ;;
	*) echo "unsupported host architecture: $ARCH" >&2; exit 2 ;;
esac
COMMON="-target bpf -O2 -g -D__TARGET_ARCH_${TARGET_ARCH} -I$OUT -I$KERNEL/tools/lib -I$KERNEL/tools/sched_ext/include -I$KERNEL/tools/testing/selftests/bpf/tools/include -I$KERNEL/tools/testing/selftests/bpf"
# shellcheck disable=SC2086
"$CLANG" $COMMON -c "$ROOT/components/scheduler/sched_ext.bpf.c" -o "$OUT/sched_ext.bpf.o"
# shellcheck disable=SC2086
"$CLANG" $COMMON -c "$ROOT/components/security/lsm.bpf.c" -o "$OUT/lsm.bpf.o"
for object in "$OUT"/*.bpf.o; do
	test -s "$object"
	printf '%s\n' "$object"
done
