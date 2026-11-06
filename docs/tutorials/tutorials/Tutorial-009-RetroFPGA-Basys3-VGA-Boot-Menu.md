# Tutorial 009 — Six-Architecture VGA Boot Menu on Basys 3

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Board:** Digilent Basys 3, Xilinx Artix-7 `xc7a35tcpg236-1`  
**Development environment:** Ubuntu Linux, terminal-first workflow, Vim, Verilator 5.032, Vivado 2026.1  
**Status:** VGA boot menu and Up/Down navigation verified on real hardware; CPU cores are placeholders.

## 1. Objective

Build and deploy a six-architecture boot-selection interface on the Basys 3 FPGA. The design presents a text-based VGA menu, tracks the highlighted selection, and accepts debounced push-button input.

The menu lists:

1. SAP-1
2. Hack
3. MOS 6502
4. Z80
5. Motorola 68000 (`M68000` on screen)
6. DCPU-16

> **Scope:** This tutorial implements the boot menu, not the six CPUs. The build log confirms `IMPLEMENTED_CORES = 6'b000000`.

## 2. Hardware and software

- Digilent Basys 3 FPGA board and USB cable connected to its programming/JTAG port
- VGA monitor and VGA cable
- Linux development host
- Verilator 5.032
- AMD/Xilinx Vivado 2026.1
- Repository at `~/Projects/RetroFPGA-Basys3`

The observed FPGA device is `xc7a35t_0`, part `xc7a35tcpg236-1`.

## 3. RTL architecture

The Vivado build read these SystemVerilog files:

```text
rtl/
├── retrofpga_top.sv
├── boot/
│   ├── boot_menu_controller.sv
│   ├── core_registry.sv
│   └── counter.sv
├── input/
│   └── button_debounce.sv
└── video/
    ├── boot_menu_renderer.sv
    ├── font_rom.sv
    ├── pixel_enable.sv
    ├── pixel_renderer.sv
    ├── text_renderer.sv
    └── vga_timing.sv
```

The top-level design combines a pixel-enable generator, VGA timing, menu controller, button debounce filters, and text rendering. The boot menu produces a highlighted row and a system-status message. The design exposes VGA RGB, HSYNC, VSYNC, selection LEDs, and a boot-status LED.

### Button and output pin mapping

The following mapping was reviewed against the Basys 3 XDC during development:

| Function | Basys 3 FPGA pin |
|---|---|
| 100 MHz clock | W5 |
| Center / reset | U18 |
| Up | T18 |
| Down | U17 |
| Select / right | T17 |
| Back / left | W19 |
| LED0, LED1, LED2 | U16, E19, U19 |
| Boot status LED3 | V19 |
| VGA red `[3:0]` | G19, H19, J19, N19 |
| VGA green `[3:0]` | J17, H17, G17, D17 |
| VGA blue `[3:0]` | N18, L18, K18, J18 |
| VGA HSYNC | P19 |
| VGA VSYNC | R19 |

The XDC includes a 100 MHz timing constraint:

```tcl
create_clock -name sys_clk -period 10.000 [get_ports {clk}]
```

**Important:** The four-digit seven-segment display is **not** a controlled output of this Tutorial 009 top-level design. It must not be used as the primary proof that the menu is running. Use the VGA picture and the selection LEDs instead.

## 4. Run the RTL regression

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
./scripts/build_basys3.sh
```

The build script first runs the Tutorial 009 regression, then launches the FPGA implementation flow.

Observed regression results:

```text
[1/5] Full Top-Level Lint
[2/5] Controller Build & Simulation
PASS: Tutorial 009 controller simulation
[3/5] VGA Renderer Build & Simulation
PASS: 14 VGA pixel checks
[4/5] Top-Level Integration Simulation
PASS: Tutorial 009 six-core top integration (12 checks)
[5/5] Git Integrity
Tutorial 009 Regression Completed
```

The Git integrity stage reports working-tree status; untracked files are not necessarily test failures. Review them before staging or cleaning. Avoid `git add .` while installers, backups, and generated `build/` files are present.

## 5. Configure Vivado 2026.1 on Linux

In the same terminal session:

```bash
source "$HOME/Xilinx/2026.1/Vivado/settings64.sh"

COMPAT_DIR="$XILINX_VIVADO/lib/lnx64.o/Ubuntu/24"
export LD_LIBRARY_PATH="$COMPAT_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

vivado -version
```

The Ubuntu compatibility-library directory above was used successfully in this particular installation; verify it exists on other hosts.

## 6. Build the FPGA bitstream

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
./scripts/build_basys3.sh

ls -lh build/basys3/retrofpga_basys3.bit
sha256sum build/basys3/retrofpga_basys3.bit
```

The observed build completed synthesis, optimization, placement, routing, DRC, and bitstream generation. Vivado reported **zero synthesis errors and warnings** and **zero DRC errors** in the captured log.

Expected output path:

```text
build/basys3/retrofpga_basys3.bit
```

A previously recorded build produced an approximately 2.1 MB bitstream. The hash may change after any rebuild; do not assume an old checksum applies to a new build.

### Note about `No constraint files found`

The log printed this message during synthesis because the project Tcl script reads the XDC **after** `synth_design`. The same log subsequently confirmed:

```text
Parsing XDC File [.../constraints/basys3.xdc]
Finished Parsing XDC File [.../constraints/basys3.xdc]
```

This was not a missing-XDC failure in the observed implementation.

## 7. Program FPGA SRAM using JTAG

Programming FPGA SRAM does **not** overwrite the onboard SPI configuration flash. Create a temporary programming script:

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1

cat > /tmp/program_retrofpga.tcl <<'TCL'
set bitfile [file normalize "build/basys3/retrofpga_basys3.bit"]
if {![file isfile $bitfile]} {
    error "Bitstream not found: $bitfile"
}

open_hw_manager
connect_hw_server
open_hw_target

set device [lindex [get_hw_devices xc7a35t_0] 0]
if {$device eq ""} {
    error "Basys 3 FPGA not detected"
}

set_property PROGRAM.FILE $bitfile $device
puts "=== Programming Basys 3 ==="
program_hw_devices $device
refresh_hw_device $device
puts "=== FPGA PROGRAMMING COMPLETED ==="

close_hw_manager
exit 0
TCL

vivado -mode batch \
  -source /tmp/program_retrofpga.tcl \
  -log build/basys3/program.log
```

The captured hardware target was similar to:

```text
localhost:3121/xilinx_tcf/Digilent/210183BF7DF1A
xc7a35t_0
```

The observed programming log included:

```text
INFO: [Labtools 27-3164] End of startup status: HIGH
=== FPGA PROGRAMMING COMPLETED ===
```

If a log reports no supported soft-debug cores, that is informational for this design: no ILA/VIO debug core was integrated. Always check for errors in the full programming log rather than relying only on the final printed marker.

## 8. Hardware acceptance test

Connect a VGA monitor, keep the board powered, and program the SRAM using the command above.

### Observed VGA output

The real monitor displayed:

```text
RETRO FPGA BOOT MENU
SYSTEM READY

> SAP-1
  HACK
  MOS 6502
  Z80
  M68000
  DCPU-16
```

The screenshot showed green title/menu text, a pale-blue `SYSTEM READY` line, yellow text for the selected SAP-1 entry, and a blue selection bar. The display was readable and showed no obvious VGA synchronization corruption.

### Navigation

**Confirmed on hardware:** Up and Down move the selected menu row.

The selected index is also represented on LED0–LED2 as a three-bit binary value, according to the design mapping:

| Selection | LED2 LED1 LED0 |
|---|---|
| SAP-1 | `000` |
| Hack | `001` |
| MOS 6502 | `010` |
| Z80 | `011` |
| M68000 | `100` |
| DCPU-16 | `101` |

**Not yet confirmed in the conversation:** Select/Back transitions and the center reset button on hardware. These require separate tests before declaring full interaction acceptance.

### Acceptance summary

| Check | Result |
|---|---|
| Controller simulation | PASS |
| VGA renderer simulation (14 checks) | PASS |
| Top integration simulation (12 checks) | PASS |
| Vivado synthesis and implementation | PASS |
| FPGA JTAG/SRAM programming | PASS |
| VGA title, status, six entries, highlight | PASS |
| Up/Down navigation | PASS |
| Select/Back/Reset behavior | PENDING hardware confirmation |
| Real CPU execution | NOT IMPLEMENTED |
| SPI flash persistent startup | NOT PROGRAMMED |

## 9. Why the old firmware returns after power-off

The Basys 3 FPGA configuration SRAM is volatile. A JTAG-loaded design disappears when power is removed. At the next power-on, the board can load the older configuration from onboard nonvolatile SPI flash, depending on its configuration-mode setting.

This behavior was observed: after removing and restoring power, the previous seven-segment display firmware returned. It is **not evidence that the JTAG programming failed**; the new VGA menu was subsequently photographed running on real hardware.

**Do not overwrite the SPI flash yet** unless you intend to replace the current power-on design. Permanent configuration is a separate task requiring the correct flash-part selection, configuration-memory image generation, and flash programming/verification.

## 10. Troubleshooting

**The seven-segment display still shows the old counter:** Verify the VGA output and whether the new menu is active. The current top-level RTL does not control the seven-segment display. If the old design returns only after power cycling, this is consistent with flash booting the previous image.

**Vivado sees no FPGA:** Confirm the board's USB/JTAG connection, power, cable, permissions, and hardware server. Inspect `get_hw_targets` and `get_hw_devices` from Vivado's hardware manager.

**The VGA monitor reports no signal:** Confirm the monitor is using the VGA input, the VGA cable is seated, and the board has been programmed in the current power session. If necessary, inspect VGA timing and sync polarity in the RTL and XDC.

**The menu displays but buttons do not respond:** Check the mapped button pins, debounce logic, and reset polarity. Compare the behavior with the controller and top-level testbenches.

**The bitstream file is missing:** Review the full `build_basys3.sh` output and Vivado log before attempting to program the FPGA.

## 11. Next steps

1. Finish real-board Select, Back, and Reset verification.
2. Optionally add a dedicated seven-segment status display to the top-level RTL, with corresponding XDC pins and tests.
3. Decide whether to keep JTAG-only development or create a separate, carefully verified SPI flash programming procedure.
4. Start **Tutorial 010 — SAP-1 CPU Core Integration**, with a genuine CPU datapath, control unit, program memory, instruction execution tests, and an interface back to the boot menu.

## Conclusion

Tutorial 009 has crossed the essential hardware milestone: the six-architecture VGA boot menu was synthesized, routed, configured into a real Artix-7 FPGA, displayed on a physical VGA monitor, and navigated using the board's Up/Down buttons. The architecture names are currently menu placeholders; CPU execution and persistent flash boot remain future work.
