# Tutorial 010 — Build a SAP-1 CPU Core in SystemVerilog

## Goal
Implement and simulate a minimal 8-bit SAP-1-style educational CPU on Linux with Verilator, before connecting it to the Basys 3 boot menu.

## Architecture
- 8-bit accumulator and data path
- 4-bit program counter and operand address
- 16 × 8-bit instruction/data memory
- 8-bit instruction register
- Two clock-enabled phases per instruction: FETCH, EXECUTE
- HALTED state and one-clock `out_valid` pulse

## Instruction set
| Opcode | Mnemonic | Operation |
|---|---|---|
| `0x0` | LDA addr | `ACC = RAM[addr]` |
| `0x1` | ADD addr | `ACC = ACC + RAM[addr]` (8-bit wraparound) |
| `0x2` | SUB addr | `ACC = ACC - RAM[addr]` (8-bit wraparound) |
| `0xE` | OUT | `OUT = ACC`, assert `out_valid` for one clock |
| `0xF` | HLT | Stop execution |

Unsupported opcodes halt execution. The instruction's low nibble is ignored for OUT and HLT.

## Demo program
| Address | Byte | Meaning |
|---|---|---|
| 0 | `05` | LDA 5 |
| 1 | `16` | ADD 6 |
| 2 | `27` | SUB 7 |
| 3 | `E0` | OUT |
| 4 | `F0` | HLT |
| 5 | `09` | Data: 9 |
| 6 | `04` | Data: 4 |
| 7 | `02` | Data: 2 |

Expected: `ACC = 11`, `OUT = 11`, `PC = 5`, `halted = 1`.

## Run on Linux
From the repository root:

```bash
bash scripts/test_sap1.sh
```

The script compiles the CPU and self-checking testbench with Verilator. It uses `build/`, which should be ignored by Git.

## Notes and limitations
This is a compact **SAP-1-style** CPU, not a gate-level reproduction of Malvino's original SAP-1 bus and microinstruction timing. The ROM is fixed for this first milestone; program loading, user-selectable clock speed, register display, and integration with the six-architecture boot menu are later steps. No existing VGA/boot RTL is modified.
