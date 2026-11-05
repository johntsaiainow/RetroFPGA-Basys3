#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=========================================="
echo " RetroFPGA Tutorial 009 Full Regression"
echo "=========================================="

command -v verilator >/dev/null || {
    echo "ERROR: Verilator not installed"
    exit 1
}

RTL=(
    rtl/boot/core_registry.sv
    rtl/boot/boot_menu_controller.sv
    rtl/input/button_debounce.sv
    rtl/video/font_rom.sv
    rtl/video/pixel_enable.sv
    rtl/video/vga_timing.sv
    rtl/video/text_renderer.sv
    rtl/video/boot_menu_renderer.sv
    rtl/retrofpga_top.sv
)

echo
echo "[1/5] Full Top-Level Lint"

verilator \
    --lint-only \
    -Wall \
    --top-module retrofpga_top \
    "${RTL[@]}"

echo
echo "[2/5] Controller Build & Simulation"

verilator \
    --binary --timing --assert -Wall \
    --top-module tb_boot_menu_six \
    --Mdir obj_dir/t009 \
    rtl/boot/core_registry.sv \
    rtl/boot/boot_menu_controller.sv \
    sim/tb_boot_menu_six.sv

./obj_dir/t009/Vtb_boot_menu_six

echo
echo "[3/5] VGA Renderer Build & Simulation"

verilator \
    --binary --timing --assert -Wall \
    --top-module tb_boot_menu_renderer_six \
    --Mdir obj_dir/t009_vga \
    rtl/video/font_rom.sv \
    rtl/video/boot_menu_renderer.sv \
    sim/tb_boot_menu_renderer_six.sv

./obj_dir/t009_vga/Vtb_boot_menu_renderer_six

echo
echo "[4/5] Top-Level Integration Simulation"

if [[ -f sim/tb_retrofpga_top.sv ]]; then
    echo "Found Top-Level Testbench"

    verilator \
        --binary --timing --assert -Wall \
        --top-module tb_retrofpga_top \
        --Mdir obj_dir/t009_top \
        "${RTL[@]}" \
        sim/tb_retrofpga_top.sv

    ./obj_dir/t009_top/Vtb_retrofpga_top
else
    echo "SKIP: sim/tb_retrofpga_top.sv not found"
    echo "Top-Level dynamic simulation is not yet verified."
fi

echo
echo "[5/5] Git Integrity"

git diff --check
git status --short

echo
echo "=========================================="
echo " Tutorial 009 Regression Completed"
echo "=========================================="
