#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Tutorial 014 Phase 2 ==="

verilator \
    --binary \
    --timing \
    --assert \
    -Wall \
    --top-module tb_ps2_keyboard_receiver \
    --Mdir build/verilator/t014_ps2 \
    rtl/input/ps2_keyboard_receiver.sv \
    tests/tb_ps2_keyboard_receiver.sv

echo
echo "=== RUN PROTOCOL TESTS ==="

./build/verilator/t014_ps2/Vtb_ps2_keyboard_receiver

echo
echo "=== GIT CHECK ==="

git diff --check
