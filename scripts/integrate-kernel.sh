#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KERNEL=${1:-"$ROOT/kernel"}
exec python3 "$ROOT/tools/integrate_kernel.py" "$KERNEL"
