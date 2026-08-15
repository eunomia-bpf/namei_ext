#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL=${1:-"$ROOT/kernel"}; INITRD=${2:-"$ROOT/.build/initramfs.cpio.gz"}; MODE=${3:-tcg}
RESULTS=${RESULTS:-"$ROOT/results"}; RUN_ID=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
KERNEL_OUT="$ROOT/.build/kernel-x86_64"; IMAGE="$KERNEL_OUT/arch/x86/boot/bzImage"
QEMU=${QEMU:-qemu-system-x86_64}; ACCEL="-accel tcg"
[ "$MODE" != kvm ] || ACCEL="-enable-kvm"
COMMAND_TEXT="$QEMU $ACCEL -kernel $IMAGE -initrd $INITRD"
. "$ROOT/scripts/result-lib.sh"; result_begin
if ! command -v "$QEMU" >/dev/null; then result_finish blocked 2 "qemu unavailable"; exit 2; fi
if [ "$MODE" = kvm ] && { [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; }; then result_finish blocked 2 "KVM unavailable"; exit 2; fi
if [ ! -f "$IMAGE" ]; then result_finish blocked 2 "kernel image not built"; exit 2; fi
set +e
timeout 120 "$QEMU" $ACCEL -nographic -no-reboot -m 512M -kernel "$IMAGE" -initrd "$INITRD" -append 'console=ttyS0 panic=-1 init=/init' 2>"$RESULT_DIR/stderr.log" | tee "$RESULT_DIR/stdout.log"
code=$?
set -e
if grep -q EBPFOS_TEST_PASS "$RESULT_DIR/stdout.log"; then result_finish completed "$code"; exit 0; fi
result_finish failed "$code" "pass marker absent"; exit 1
