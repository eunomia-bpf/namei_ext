#!/bin/sh
# SPDX-License-Identifier: MIT
result_begin() {
	: "${RESULTS:?}" "${RUN_ID:?}" "${COMMAND_TEXT:?}"
	RESULT_DIR="$RESULTS/$RUN_ID"; mkdir -p "$RESULT_DIR"
	printf '%s\n' "$COMMAND_TEXT" > "$RESULT_DIR/command.txt"
	printf '{"repository":"ebpfos","run_id":"%s"}\n' "$RUN_ID" > "$RESULT_DIR/source.json"
	if [ -d "${KERNEL:-}/.git" ]; then KCOMMIT=$(git -C "$KERNEL" rev-parse HEAD 2>/dev/null || echo unknown); else KCOMMIT=unknown; fi
	printf '{"commit":"%s","release":"7.1.8"}\n' "$KCOMMIT" > "$RESULT_DIR/kernel.json"
	if [ -f "${KERNEL_OUT:-}/.config" ]; then cp "$KERNEL_OUT/.config" "$RESULT_DIR/config"; else : > "$RESULT_DIR/config"; fi
	: > "$RESULT_DIR/stdout.log"; : > "$RESULT_DIR/stderr.log"
}
result_finish() { state=$1; code=$2; reason=${3:-}; printf '{"state":"%s","exit_code":%s,"reason":"%s"}\n' "$state" "$code" "$reason" > "$RESULT_DIR/status.json"; }
