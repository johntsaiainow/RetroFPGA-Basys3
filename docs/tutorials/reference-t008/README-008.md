# Tutorial 008 — Basys 3 Top-Level Integration

Overlay `rtl/`, `sim/`, and `scripts/` onto your existing project. The included existing RTL copies are reference snapshots, not modifications. New files: `rtl/retrofpga_top.sv`, `rtl/video/boot_menu_renderer.sv`, `sim/tb_retrofpga_top.sv`, `scripts/test_top.sh`.

Run `bash scripts/test_top.sh` on Linux with Verilator 5.x installed. This tests menu controls and a VGA HSYNC segment; it is **not** exhaustive VGA frame validation or hardware validation.

Top-level ports: `clk`, `btn_reset`, `btn_up`, `btn_down`, `btn_select`, `btn_back`, `hsync`, `vsync`, `vga_r[3:0]`, `vga_g[3:0]`, `vga_b[3:0]`, `led_selected[1:0]`, `led_booting`.

**Constraints**: No XDC is provided. Obtain the official Digilent Basys 3 master XDC and enable exactly these named top-level signals, mapping them to the corresponding board buttons, clock, VGA and LEDs. Do not synthesize or generate a bitstream without verifying pin mapping and IOSTANDARD LVCMOS33. The 100 MHz clock needs a `create_clock -period 10.000` constraint.

**Caveats**: Existing `text_renderer` draws fixed text. This overlay draws menu entries using existing `font_rom`, adding missing glyphs in the new renderer. No Z80/DCPU/NES/GB CPU cores are instantiated; selecting a core only sets a boot ID and enters a placeholder BOOTING state. The `pixel_renderer` color bars are a prior tutorial demo and are intentionally not used in this menu display.
