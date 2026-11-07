# T016.20 — Basys 3 Keyboard Compatibility

## Status

HARDWARE ACCEPTANCE: PASS (5/5)

## Hardware

- Board: Digilent Basys 3
- FPGA: XC7A35T
- Toolchain: Vivado 2026.1
- Interface: USB HID to PS/2 bridge

## Fix

Accept both extended and non-extended PS/2 Set 2
scan codes for Up (75) and Down (72).

## Verification

| Test | Result |
|---|---|
| Up Arrow | PASS |
| Down Arrow | PASS |
| Enter | PASS |
| ESC | PASS |
| Key Release | PASS |
| Icarus Regression | PASS |
| Verilator Lint | PASS |
| Vivado Implementation | PASS |

Worst Setup Slack: +2.174 ns

## Compatibility Note

Non-extended 75 and 72 are accepted as navigation
events. Numeric keypad keys using these scan codes
may also trigger navigation.

## Scope

Keyboard navigation and the T016.20 FPGA build
are verified. This does not certify all six CPU
architectures as implemented.
