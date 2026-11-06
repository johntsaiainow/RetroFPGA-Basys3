#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="rtl/video/sap1_vga_monitor.sv"
BCD="rtl/common/bin_to_bcd.sv"

echo "=== Tutorial 013 Phase 2 ==="

if [[ ! -f "$TARGET" || ! -f "$BCD" ]]; then
    echo "ERROR: Required RTL file missing."
    exit 1
fi

mkdir -p backups

BACKUP="backups/sap1_vga_monitor.t013p2.$(date +%Y%m%d-%H%M%S).sv"
cp "$TARGET" "$BACKUP"

echo "Backup: $BACKUP"

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
import re

path = Path(sys.argv[1])
src = path.read_text()

if "bin_to_bcd acc_converter" in src:
    print("Already patched; no changes needed.")
    sys.exit(0)

# Validate original Tutorial 012 structure.
required = [
    "logic [3:0] nibble;",
    "case (row)",
    "// Complete small uppercase/digit font",
    "row == 4'd8",
]
for marker in required:
    if marker not in src:
        raise SystemExit(f"ERROR: Missing marker: {marker}")

# Add converter instances.
insert = """
    logic [3:0] acc_h, acc_t, acc_o;
    logic [3:0] out_h, out_t, out_o;
    logic [3:0] pc_h, pc_t, pc_o;

    bin_to_bcd acc_converter (
        .binary(acc),
        .hundreds(acc_h),
        .tens(acc_t),
        .ones(acc_o)
    );

    bin_to_bcd out_converter (
        .binary(out_port),
        .hundreds(out_h),
        .tens(out_t),
        .ones(out_o)
    );

    bin_to_bcd pc_converter (
        .binary({4'b0000, pc}),
        .hundreds(pc_h),
        .tens(pc_t),
        .ones(pc_o)
    );

    function automatic logic [7:0] dec_ascii(
        input logic [3:0] digit
    );
        return 8'h30 + {4'b0000, digit};
    endfunction
"""

src = src.replace(
    "logic [3:0] nibble;",
    "logic [3:0] nibble;\n" + insert,
    1
)

# Expand monitor height.
old_height = "y >= 10'd80 && y < 10'd272"
new_height = "y >= 10'd80 && y < 10'd320"

if old_height not in src:
    raise SystemExit("ERROR: Monitor height marker missing.")

src = src.replace(old_height, new_height, 1)

# Replace only text-generation case block.
new_rows = """
        case (row)
            0: case (col)
                0: ascii="S"; 1: ascii="A"; 2: ascii="P";
                3: ascii="-"; 4: ascii="1";
                6: ascii="C"; 7: ascii="P"; 8: ascii="U";
                default: ascii=" ";
            endcase

            2: case (col)
                0: ascii="P"; 1: ascii="C";
                3: ascii="H"; 4: ascii="E"; 5: ascii="X";
                6: ascii=":";
                8: ascii="0"; 9: ascii="X";
                10: ascii=hex_ascii(pc);
                default: ascii=" ";
            endcase

            3: case (col)
                0: ascii="P"; 1: ascii="C";
                3: ascii="D"; 4: ascii="E"; 5: ascii="C";
                6: ascii=":";
                8: ascii=dec_ascii(pc_t);
                9: ascii=dec_ascii(pc_o);
                default: ascii=" ";
            endcase

            5: case (col)
                0: ascii="A"; 1: ascii="C"; 2: ascii="C";
                4: ascii="H"; 5: ascii="E"; 6: ascii="X";
                7: ascii=":";
                9: ascii="0"; 10: ascii="X";
                11: ascii=hex_ascii(acc[7:4]);
                12: ascii=hex_ascii(acc[3:0]);
                default: ascii=" ";
            endcase

            6: case (col)
                0: ascii="A"; 1: ascii="C"; 2: ascii="C";
                4: ascii="D"; 5: ascii="E"; 6: ascii="C";
                7: ascii=":";
                9:  ascii=dec_ascii(acc_h);
                10: ascii=dec_ascii(acc_t);
                11: ascii=dec_ascii(acc_o);
                default: ascii=" ";
            endcase

            8: case (col)
                0: ascii="O"; 1: ascii="U"; 2: ascii="T";
                4: ascii="H"; 5: ascii="E"; 6: ascii="X";
                7: ascii=":";
                9: ascii="0"; 10: ascii="X";
                11: ascii=hex_ascii(out_port[7:4]);
                12: ascii=hex_ascii(out_port[3:0]);
                default: ascii=" ";
            endcase

            9: case (col)
                0: ascii="O"; 1: ascii="U"; 2: ascii="T";
                4: ascii="D"; 5: ascii="E"; 6: ascii="C";
                7: ascii=":";
                9:  ascii=dec_ascii(out_h);
                10: ascii=dec_ascii(out_t);
                11: ascii=dec_ascii(out_o);
                default: ascii=" ";
            endcase

            11: case (col)
                0: ascii="S"; 1: ascii="T"; 2: ascii="A";
                3: ascii="T"; 4: ascii="E"; 5: ascii=":";
                7:  ascii=halted ? "H" : "R";
                8:  ascii=halted ? "A" : "U";
                9:  ascii=halted ? "L" : "N";
                10: ascii=halted ? "T" : " ";
                default: ascii=" ";
            endcase

            13: case (col)
                0: ascii="B"; 1: ascii="A"; 2: ascii="C";
                3: ascii="K";
                5: ascii="T"; 6: ascii="O";
                8: ascii="M"; 9: ascii="E";
                10: ascii="N"; 11: ascii="U";
                default: ascii=" ";
            endcase

            default: ascii=" ";
        endcase
"""

start = src.index("        case (row)")
end_marker = "\n    end\n    // Complete small uppercase/digit font"
end = src.index(end_marker, start)

src = src[:start] + new_rows.rstrip() + src[end:]

# Move yellow STATE highlighting from row 8 to row 11.
src = src.replace(
    "row == 4'd8",
    "row == 4'd11",
    1
)

path.write_text(src)
print("PATCH: OK")
PY

echo
echo "=== VERILATOR LINT ==="

verilator \
    --lint-only \
    --top-module sap1_vga_monitor \
    -Wall \
    -Wno-fatal \
    "$BCD" \
    "$TARGET"

echo
echo "=== GIT CHECK ==="
git diff --check
git diff --stat -- "$TARGET"

echo
echo "======================================"
echo "Tutorial 013 Phase 2: PATCH + LINT PASS"
echo "======================================"
