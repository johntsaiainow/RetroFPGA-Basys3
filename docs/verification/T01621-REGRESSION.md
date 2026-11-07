# T016.21 — Boot Selection & SAP-1 Execution Verification

## Status

RTL Regression: PASS

Hardware Acceptance: PENDING

## Verification Environment

- Project: RetroFPGA-Basys3
- Target: Digilent Basys 3 (XC7A35T)
- Simulator: Icarus Verilog
- Language: SystemVerilog

## Regression Results

| Test | Result |
|---|---|
| Core Selection | PASS — 23 checks |
| SAP-1 Execution Integration | PASS |
| Boot-to-SAP1 E2E | PASS — 19 checks |

## CPU Execution Results

| Instruction | Result |
|---|---|
| LDA 5 | ACC = 9 |
| ADD 6 | ACC = 13 |
| SUB 7 | ACC = 11 |
| OUT | OUT = 11 |
| HLT | HALT = 1 |

Final CPU state:

- PC = 5
- ACC = 11
- OUT = 11
- HALT = 1

## Boot Interface

The boot menu selects SAP-1 using core ID 0.

SAP-1 activation:

    sap_active = booting && (boot_core == 0)

CPU reset:

    sap_reset = reset_sync || !sap_active

The execution controller generates step_en for the SAP-1 CPU.

The boot_request output is not connected in the current Top-Level.
Boot activation uses the persistent booting state.

## Verified Behaviors

- Reset enters the boot menu.
- SAP-1 is held in reset before boot.
- Selecting SAP-1 releases CPU reset.
- Step executes the demonstration program.
- HALT prevents further execution.
- ESC returns to the boot menu.
- Returning to the menu resets SAP-1.
- Reboot starts from PC = 0.
- Unavailable CPU selection is rejected.

## Scope and Limitations

This report records RTL simulation results.

The T016.20 PS/2 hardware acceptance was completed separately.

T016.21-specific FPGA hardware acceptance has not yet been performed.

## Reproduction

    scripts/t01621/run_regression.sh
