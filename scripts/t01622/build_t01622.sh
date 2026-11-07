#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

VIVADO="$HOME/Xilinx/2026.1/Vivado/bin/vivado"

if [[ ! -x "$VIVADO" ]]; then
    echo "ERROR: Vivado 2026.1 not found"
    exit 127
fi

export LD_LIBRARY_PATH="$HOME/Xilinx/2026.1/Vivado/lib/lnx64.o/Ubuntu/24:${LD_LIBRARY_PATH:-}"

OUT="$ROOT/build/basys3/t01622"
mkdir -p "$OUT"

echo "=== T016.22 PRE-BUILD REGRESSION ==="
bash scripts/t01621/run_regression.sh

echo "=== T016.22 VIVADO BUILD ==="

cd "$OUT"

"$VIVADO" -mode batch \
    -source "$ROOT/scripts/t01622/build_t01622.tcl" \
    -log vivado.log \
    -journal vivado.jou \
    -notrace

test -s retrofpga_t01622.bit

echo "=== BITSTREAM SHA256 ==="
sha256sum retrofpga_t01622.bit

echo "=== TIMING ==="
grep -E 'WNS|TNS|Design Timing Summary' timing_summary.rpt \
    | head -20 || true

echo "=== T016.22 FPGA BUILD COMPLETE ==="
