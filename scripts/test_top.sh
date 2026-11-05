#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
verilator --lint-only --timing --trace --top-module tb_retrofpga_top \
  rtl/video/pixel_enable.sv rtl/video/vga_timing.sv rtl/video/font_rom.sv \
  rtl/video/text_renderer.sv rtl/video/boot_menu_renderer.sv \
  rtl/input/button_debounce.sv rtl/boot/boot_menu_controller.sv \
  rtl/retrofpga_top.sv sim/tb_retrofpga_top.sv
verilator --binary --timing --trace --top-module tb_retrofpga_top \
  rtl/video/pixel_enable.sv rtl/video/vga_timing.sv rtl/video/font_rom.sv \
  rtl/video/text_renderer.sv rtl/video/boot_menu_renderer.sv \
  rtl/input/button_debounce.sv rtl/boot/boot_menu_controller.sv \
  rtl/retrofpga_top.sv sim/tb_retrofpga_top.sv
./obj_dir/Vtb_retrofpga_top
