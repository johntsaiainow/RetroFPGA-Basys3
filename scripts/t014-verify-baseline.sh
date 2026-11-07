#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

EXPECTED="4f78a2292f0c60f6cc76daebac3304f651c0eef51be22b30274dd8f61bc53f31"

echo "=== PRODUCTION BITSTREAM ==="

echo "$EXPECTED  build/basys3/retrofpga_basys3.bit" \
    | sha256sum -c -

echo
echo "=== ILA ARTIFACTS ==="

for file in \
    build/basys3/ila/rtl_build/retrofpga_t014_ila.bit \
    build/basys3/ila/rtl_build/retrofpga_t014_ila.ltx \
    build/basys3/ila/rtl_build/t014_first_capture.csv
do
    test -s "$file" || {
        echo "ERROR: Missing or empty: $file"
        exit 1
    }

    ls -lh "$file"
done

echo
echo "=== CSV SAMPLE COUNT ==="

python3 - <<'PY'
import csv

path = "build/basys3/ila/rtl_build/t014_first_capture.csv"

with open(path, newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    radix = next(reader)
    rows = list(reader)

assert "TRIGGER" in header
assert len(rows) == 1024, f"Expected 1024 samples, got {len(rows)}"
assert all(len(row) == len(header) for row in rows)

print(f"Samples: {len(rows)}")
print(f"Signals: {len(header) - 3}")
print("CSV STRUCTURE: PASS")
PY

echo
echo "=== T014 BASELINE VERIFIED ==="
