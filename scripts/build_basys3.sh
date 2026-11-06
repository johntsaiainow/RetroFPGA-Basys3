#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v vivado >/dev/null 2>&1; then
    echo "ERROR: Vivado not found in PATH."
    echo "Source the Vivado settings64.sh script first."
    exit 127
fi

mkdir -p build/basys3

echo "=== RTL Regression ==="
./scripts/test_t009.sh

echo "=== Vivado Version ==="
vivado -version

echo "=== FPGA Build ==="
cd build/basys3

vivado -mode batch \
    -source "$ROOT/scripts/build_basys3.tcl" \
    -log vivado.log \
    -journal vivado.jou

test -s retrofpga_basys3.bit

echo "=== Bitstream ==="
ls -lh retrofpga_basys3.bit

echo "=== Timing Summary ==="
grep -E 'WNS|TNS|Design Timing Summary' \
    timing_summary.rpt | head -20 || true

echo "=== PASS: Bitstream Generated ==="
