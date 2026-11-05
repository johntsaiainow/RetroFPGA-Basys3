# RetroFPGA-Basys3

**A multi-system retro computer and game console built around the Digilent Basys 3 FPGA development board.**

> **Project status: Planning / early development.** The architecture and milestones below are proposed targets, not implemented or verified features.

RetroFPGA-Basys3 aims to bring four distinct classic and experimental computing systems to a single Artix-7 FPGA platform. A VGA boot menu will let users select a system, load compatible software from microSD, and interact with real RTL hardware cores rather than software CPU emulators.

## Target Systems

| System | CPU architecture | Planned software support | Main integration work |
| --- | --- | --- | --- |
| Nintendo Entertainment System (NES/Famicom) | Ricoh 2A03/2A07, 6502-derived | Homebrew ROMs; cartridge compatibility developed incrementally | PPU, APU, cartridge mappers, controllers |
| Nintendo Game Boy (DMG) | Sharp SM83 / LR35902 | Homebrew Game Boy ROMs | PPU, APU, cartridge/MBC, input |
| Z80 Computer | Zilog Z80-compatible | Assembly, SDCC/z88dk C programs; eventual CP/M | Memory map, UART, storage, firmware |
| DCPU-16 Computer | DCPU-16 v1.7 | Assembly; experimental C toolchain later | CPU RTL, assembler/runtime, firmware |

**Compatibility note:** The Game Boy CPU is not a standard Z80. Each system requires its own CPU-compatible implementation and system-level timing/peripherals.

## Target Hardware

- **Board:** Digilent Basys 3
- **FPGA:** AMD/Xilinx Artix-7 XC7A35T-1CPG236C
- **On-chip memory:** 1,800 Kbits (~225 KiB) Block RAM
- **Clock source:** 100 MHz onboard oscillator (system clocks generated as needed)
- **Video:** Onboard 12-bit VGA output
- **Input:** Onboard pushbuttons and switches; USB HID keyboard support to be investigated
- **Programming/debug:** USB-JTAG and UART
- **Configuration storage:** Onboard 32-Mbit (4-MiB) Quad-SPI flash

### Planned Pmod Expansion

| Connector (proposed) | Peripheral | Purpose |
| --- | --- | --- |
| JA | SPI microSD module | ROMs, firmware, disk images, configuration |
| JB | 3.3-V-compatible SPI/QSPI PSRAM module | Large ROM/data buffers and external memory |
| JC | I²S audio DAC module | NES/Game Boy audio and future system sound |
| JXADC | Reserved | Future GPIO or controller expansion, subject to electrical constraints |

These are **proposed assignments**, not validated wiring. Verify each module's pinout, voltage, timing, I/O direction, and power budget before connecting hardware. Time-critical CPU/PPU storage should preferentially use Block RAM; external serial PSRAM requires arbitration, buffering, and latency-aware design.

## Proposed Architecture

```text
                    +-------------------------+
                    |  VGA Boot Menu / BIOS   |
                    | Buttons / Keyboard      |
                    +------------+------------+
                                 |
                     System selection / boot
                                 |
             +-------------------+-------------------+
             |                   |                   |
       +-----v-----+       +-----v-----+       +-----v-----+
       | NES Core  |       | Game Boy  |       | Z80 Core  |
       | CPU/PPU/  |       | CPU/PPU/  |       | CP/M goal |
       | APU       |       | APU       |       +-----------+
       +-----------+       +-----------+
                       +------------------+
                       | DCPU-16 Core     |
                       | Custom firmware  |
                       +------------------+
                                 |
               Shared board-level peripheral interfaces
                  VGA | SPI | PSRAM | Audio | UART
```

**Configuration strategy:** The initial preference is **separate FPGA bitstreams per system**, with a boot-menu image and a future configuration manager. This avoids assuming that all four complete systems will fit simultaneously on the XC7A35T. FPGA MultiBoot/ICAP, flash image sizes, and a reliable return-to-menu path require validation. microSD ROM loading is separate from FPGA configuration; a `.bit` file on microSD is not automatically bootable by the board.

## Development Environment

The primary workflow targets **Linux + Visual Studio Code**, with command-line builds and simulation.

| Task | Tool |
| --- | --- |
| RTL design | SystemVerilog (Verilog/VHDL cores may be integrated where appropriate) |
| Editor | Visual Studio Code; Vim-compatible terminal workflow |
| RTL simulation and lint | Verilator; optionally Icarus Verilog |
| Waveform inspection | GTKWave |
| FPGA synthesis, place-and-route, bitstream | AMD Vivado using Tcl scripts |
| Build orchestration | GNU Make |
| Testbenches and utilities | C++, Python |
| Z80 C development | SDCC / z88dk |
| NES homebrew C development | cc65 |
| Game Boy homebrew C development | GBDK-2020 |
| DCPU-16 | DCPU assembler; experimental C compiler to be evaluated |

> Vivado installation and OS compatibility must be checked against AMD's supported platforms. The repository will aim for reproducible command-line builds, but build targets are not yet implemented.

### Linux Prerequisites (simulation and editing)

```bash
sudo apt update
sudo apt install git make gcc g++ python3 verilator iverilog gtkwave
```

Install VS Code and AMD Vivado separately. The following commands describe the **planned** developer interface; they will work only after their corresponding Makefile rules and scripts are added:

```bash
make sim
make synth
make bitstream
make program
```

## Proposed Repository Layout

```text
RetroFPGA-Basys3/
├── .vscode/              # Editor settings and build tasks
├── boards/basys3/        # Board-specific top level and constraints
├── boot/                 # VGA menu and configuration manager
├── cores/
│   ├── nes/
│   ├── gameboy/
│   ├── z80/
│   └── dcpu16/
├── peripherals/          # VGA, UART, SPI, PSRAM, audio, input
├── firmware/             # Monitor, boot code, homebrew examples
├── sim/                  # RTL tests and verification
├── scripts/              # Vivado Tcl and support utilities
├── docs/                 # Architecture, memory maps, pinouts
└── Makefile              # Planned build entry point
```

This tree is a **design proposal** and does not imply that these directories or modules already exist.

## Development Roadmap

- [ ] **Phase 1 — Board bring-up:** Clock/reset, VGA 640×480 output, button-controlled four-system boot-menu prototype.
- [ ] **Phase 2 — Peripheral validation:** microSD SPI sector reads, PSRAM read/write and latency tests, I²S audio test tone.
- [ ] **Phase 3 — Z80 computer:** CPU RTL integration, memory map, UART monitor, C-generated program; investigate CP/M support.
- [ ] **Phase 4 — DCPU-16 computer:** ISA conformance tests, RAM/ROM integration, assembler programs, experimental C runtime.
- [ ] **Phase 5 — Game Boy:** SM83 core, video/audio, cartridge support, first homebrew ROM.
- [ ] **Phase 6 — NES:** CPU, PPU/APU, input, initial mapper support, first homebrew ROM.
- [ ] **Phase 7 — Unified boot:** Configuration image layout, ICAP/MultiBoot feasibility, ROM browser, return-to-menu behavior.
- [ ] **Phase 8 — Integration:** Compatibility testing, documentation, timing closure, hardware release images.

## Verification Goals

Each CPU core should have instruction-level tests before hardware integration. Each peripheral should have standalone simulation and physical bring-up tests. Full-system milestones require successful Vivado timing reports, tested FPGA images, and documented board wiring. ROM compatibility will be reported per system and mapper rather than claimed universally.

## References

- [Digilent Basys 3 reference](https://digilent.com/reference/programmable-logic/basys-3/start)
- [Digilent FPGA constraints repository](https://github.com/Digilent/digilent-xdc)
- [NESdev Wiki](https://www.nesdev.org/wiki/Nesdev_Wiki)
- [Game Boy Pan Docs](https://gbdev.io/pandocs/)
- [SDCC](https://sdcc.sourceforge.net/)
- [z88dk](https://github.com/z88dk/z88dk)
- [cc65](https://cc65.github.io/)
- [GBDK-2020](https://github.com/gbdk-2020/gbdk-2020)

## Legal and Licensing Notes

This project is intended for hardware education, preservation research, and original/homebrew software. Nintendo, NES, Famicom, and Game Boy are trademarks of their respective owners; this project is not affiliated with or endorsed by Nintendo. Do not distribute copyrighted commercial ROMs or proprietary firmware without permission. Third-party FPGA cores and libraries must be reviewed for their individual licenses before incorporation. A repository-wide source license has **not yet been selected**.

---

**Goal:** One Basys 3 board, four distinct hardware computing worlds, and an open, reproducible FPGA development workflow.
