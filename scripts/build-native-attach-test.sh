#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL=${1:-"$ROOT/kernel"}
OUT=${2:-"$ROOT/.build/libbpf"}
JOBS=${JOBS:-2}
mkdir -p "$OUT"
make -C "$KERNEL/tools/lib/bpf" OUTPUT="$OUT/" -j"$JOBS"
test -s "$OUT/libbpf.a"
${CC:-cc} -O2 -g -static \
	-I"$KERNEL/tools/lib" \
	-I"$KERNEL/tools/include" \
	-I"$KERNEL/tools/include/uapi" \
	"$ROOT/cmd/ebpfos-native-test.c" "$OUT/libbpf.a" \
	-lelf -lz -lpthread -ldl \
	-o "$OUT/ebpfos-native-test"
test -x "$OUT/ebpfos-native-test"
printf '%s\n' "$OUT/ebpfos-native-test"
