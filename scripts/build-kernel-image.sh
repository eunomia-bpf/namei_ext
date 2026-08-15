#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL=${1:-"$ROOT/kernel"}
JOBS=${2:-2}
OUT=${KERNEL_OUT:-"$ROOT/.build/kernel-x86_64"}
for tool in make gcc flex bison bc pahole; do
	command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 2; }
done
"$ROOT/scripts/integrate-kernel.sh" "$KERNEL"
mkdir -p "$OUT"
make -C "$KERNEL" O="$OUT" x86_64_defconfig
"$KERNEL/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" "$ROOT/configs/ebpfos.config"
make -C "$KERNEL" O="$OUT" olddefconfig
make -C "$KERNEL" O="$OUT" -j"$JOBS" bzImage vmlinux
printf 'image=%s\nvmlinux=%s\n' "$OUT/arch/x86/boot/bzImage" "$OUT/vmlinux"
