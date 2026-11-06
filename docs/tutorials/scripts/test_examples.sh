#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v verilator >/dev/null || { echo 'Install Verilator first' >&2; exit 1; }
mkdir -p build/tutorial-tests
run() {
  local name="$1"; shift
  echo "=== $name ==="
  verilator --binary --timing --assert -Wno-fatal --top-module "tb_$name" \
    --Mdir "build/tutorial-tests/$name" "$@"
  "build/tutorial-tests/$name/Vtb_$name"
}
run counter examples/t001/counter.sv examples/t001/tb_counter.sv
run pixel_enable reference-t008/rtl/video/pixel_enable.sv examples/t002/tb_pixel_enable.sv
run vga_timing reference-t008/rtl/video/vga_timing.sv examples/t003/tb_vga_timing.sv
run pixel_renderer reference-t008/rtl/video/pixel_renderer.sv examples/t004/tb_pixel_renderer.sv
run font_rom reference-t008/rtl/video/font_rom.sv examples/t005/tb_font_rom.sv
run button_debounce reference-t008/rtl/input/button_debounce.sv examples/t006/tb_button_debounce.sv
run boot_menu_controller reference-t008/rtl/boot/boot_menu_controller.sv examples/t007/tb_boot_menu_controller.sv
bash reference-t008/scripts/test_top.sh
