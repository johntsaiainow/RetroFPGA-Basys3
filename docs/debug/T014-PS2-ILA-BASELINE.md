# Tutorial 014 — PS/2 Hardware ILA Baseline

## Status

Hardware debug infrastructure: VERIFIED

PS/2 intermittent scan-code anomaly: OPEN

## Hardware

- Board: Digilent Basys 3
- FPGA: Xilinx Artix-7 XC7A35T
- Vivado: 2026.1 BASIC
- ILA core: hw_ila_1
- ILA probe ports: 5
- Total probe width: 46 bits
- Capture depth: 1024 samples
- Sample clock: 100 MHz

## Verified Results

- RTL ILA synthesis: PASS
- Implementation: PASS
- Timing setup slack: +3.390 ns
- FPGA SRAM programming: PASS
- Hardware ILA discovery: PASS
- Immediate trigger: PASS
- Hardware waveform CSV export: PASS

## Debug Artifacts

- build/basys3/ila/rtl_build/retrofpga_t014_ila.bit
- build/basys3/ila/rtl_build/retrofpga_t014_ila.ltx
- build/basys3/ila/rtl_build/t014_first_capture.csv

## Open Issue

Intermittent unexpected PS/2 scan code 0xAA.

Raw edge counts may increase when the external
USB keyboard is disconnected.

The Basys 3 USB keyboard interface includes
a USB-to-PS/2 bridge, so disconnecting the
keyboard does not disconnect the FPGA PS/2 pins
from the bridge.

Root cause: NOT YET DETERMINED.

## Engineering Decision

Preserve the working hardware debug infrastructure.

Defer deeper PS/2 investigation unless the anomaly
blocks required keyboard functionality or causes
a regression.

Continue the RetroFPGA-Basys3 CPU tutorial roadmap.

## Production Bitstream

Expected SHA256:

4f78a2292f0c60f6cc76daebac3304f651c0eef51be22b30274dd8f61bc53f31

Production bitstream must not be overwritten by
ILA debug builds.
