#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p build/verilator/t013_vga

verilator \
  --binary \
  --timing \
  --assert \
  -Wall \
  -Wno-PINCONNECTEMPTY \
  --top-module tb_sap1_vga_decimal \
  --Mdir build/verilator/t013_vga \
  rtl/common/bin_to_bcd.sv \
  rtl/video/sap1_vga_monitor.sv \
  tests/tb_sap1_vga_decimal.sv

./build/verilator/t013_vga/Vtb_sap1_vga_decimal

git diff --check
