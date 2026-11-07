# T016.21 — Basys 3 Hardware Acceptance

**Project:** RetroFPGA-Basys3
**Date:** 2026-11-07
**Target:** Digilent Basys 3 (XC7A35T)
**Toolchain:** AMD Vivado 2026.1

## Programming Verification

**Status: PASS**

- JTAG target detected.
- FPGA identified as xc7a35t_0.
- Bitstream programmed successfully.
- FPGA startup status HIGH.
- One ILA debug core detected.

## Functional Acceptance

**Status: COMPLETED — User Reported**

Hardware functional acceptance was reported complete
on November 7, 2026.

Individual H01-H09 observations were not archived.

## Software Regression

- Core Selection: 23 checks PASS.
- SAP-1 Execution Integration: PASS.
- Boot-to-SAP1 E2E: 19 checks PASS.

## Bitstream SHA256

- `retrofpga_t01620.bit`: `c03816df07ed9a31deaec166bba3d9bad0a4276c6b3a8a896ad4157e16b1d731`
- `retrofpga_t01620.ltx`: `55ca6df3513755b3679b833e8a007ffcd73da702c52a21b91b49029955f72f83`

## Conclusion

Simulation regression and FPGA programming verified.
Hardware functional acceptance completed per user report.

**Regression Baseline:** `f27bc29`
