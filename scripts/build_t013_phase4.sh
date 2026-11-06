#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Tutorial 013 Phase 4 ==="

echo
echo "=== CHECK BUILD SOURCES ==="
sed -n '1,45p' scripts/build_basys3.tcl

echo
echo "=== VERIFY REQUIRED FILES ==="
for file in \
    rtl/common/bin_to_bcd.sv \
    rtl/video/sap1_vga_monitor.sv \
    scripts/build_basys3.tcl
do
    test -f "$file" || {
        echo "ERROR: Missing $file"
        exit 1
    }
    echo "OK: $file"
done

echo
echo "=== VERIFY SOURCE DISCOVERY ==="

python3 - <<'PY'
from pathlib import Path

script = Path("scripts/build_basys3.tcl").read_text()

if "rtl/common" not in script:
    raise SystemExit(
        "ERROR: Cannot confirm rtl/common is included "
        "in Vivado source discovery."
    )

if "rtl/video" not in script:
    raise SystemExit(
        "ERROR: Cannot confirm rtl/video is included "
        "in Vivado source discovery."
    )

print("PASS: Source directories referenced")
PY

echo
echo "=== RE-RUN VERILATOR ==="
./scripts/test_t013_phase3.sh

echo
echo "=== GIT DIFF CHECK ==="
git diff --check

echo
echo "=== VIVADO BUILD ==="

mkdir -p build/logs

LOG="build/logs/tutorial013_phase4_$(date +%Y%m%d_%H%M%S).log"

set -o pipefail
vivado -mode batch \
    -source scripts/build_basys3.tcl \
    2>&1 | tee "$LOG"

echo
echo "=== BITSTREAM ==="

BIT="build/basys3/retrofpga_basys3.bit"

test -s "$BIT" || {
    echo "ERROR: Bitstream missing or empty"
    exit 1
}

ls -lh "$BIT"

echo
echo "Build completed. Review timing and DRC in:"
echo "$LOG"
