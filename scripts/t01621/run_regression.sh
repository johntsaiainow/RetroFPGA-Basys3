#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

OUT="build/tests/t01621"
mkdir -p "$OUT"

echo "=== T016.21 CORE SELECTION ==="

iverilog -g2012 \
  -s tb_core_selection \
  -o "$OUT/tb_core_selection.vvp" \
  rtl/boot/core_registry.sv \
  rtl/boot/boot_menu_controller.sv \
  tests/t01621/tb_core_selection.sv

vvp "$OUT/tb_core_selection.vvp"

echo "=== SAP-1 EXECUTION INTEGRATION ==="

iverilog -g2012 \
  -s tb_sap1_execution_integration \
  -o "$OUT/tb_sap1_execution_integration.vvp" \
  rtl/common/sap1_execution_controller.sv \
  cores/sap1/sap1_core.sv \
  tests/tb_sap1_execution_integration.sv

vvp "$OUT/tb_sap1_execution_integration.vvp"

echo "=== T016.21 BOOT-TO-SAP1 E2E ==="

iverilog -g2012 \
  -s tb_boot_to_sap1_e2e \
  -o "$OUT/tb_boot_to_sap1_e2e.vvp" \
  rtl/boot/core_registry.sv \
  rtl/boot/boot_menu_controller.sv \
  rtl/common/retrofpga_input_router.sv \
  rtl/common/sap1_execution_controller.sv \
  cores/sap1/sap1_core.sv \
  tests/t01621/tb_boot_to_sap1_e2e.sv

vvp "$OUT/tb_boot_to_sap1_e2e.vvp"

echo "=== T016.21 REGRESSION: ALL PASS ==="
