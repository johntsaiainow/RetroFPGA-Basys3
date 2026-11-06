# Tutorial 007 — Boot Menu Finite-State Machine

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Implement selection navigation and a placeholder boot-request state machine.

## Place in the series

Tutorial 007/008 had a four-entry, 2-bit menu. Tutorial 009 later expanded this to six entries and added a core registry.

## Source files

Primary module: `rtl/boot/boot_menu_controller.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/boot/boot_menu_controller.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module boot_menu_controller (
    input  logic clk,
    input  logic rst,

    // One-cycle button events from Tutorial 006.
    input  logic up_pressed,
    input  logic down_pressed,
    input  logic select_pressed,
    input  logic back_pressed,

    // Menu display interface.
    output logic [1:0] selected_index,
    output logic       menu_active,

    // Core launch interface.
    output logic [1:0] boot_core,
    output logic       boot_request,
    output logic       booting
);

    typedef enum logic {
        STATE_MENU    = 1'b0,
        STATE_BOOTING = 1'b1
    } state_t;

    state_t state;

    // State and output registers.
    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= STATE_MENU;
            selected_index <= 2'd0;
            boot_core      <= 2'd0;
            boot_request   <= 1'b0;
        end else begin

            // A boot request lasts exactly one clock cycle.
            boot_request <= 1'b0;

            case (state)

                STATE_MENU: begin

                    // Priority:
                    // SELECT > UP > DOWN
                    // BACK is ignored in MENU.

                    if (select_pressed) begin

                        boot_core    <= selected_index;
                        boot_request <= 1'b1;
                        state        <= STATE_BOOTING;

                    end else if (up_pressed) begin

                        // Wrap from Z80 to Game Boy.
                        selected_index <=
                            selected_index - 2'd1;

                    end else if (down_pressed) begin

                        // Wrap from Game Boy to Z80.
                        selected_index <=
                            selected_index + 2'd1;

                    end

                end

                STATE_BOOTING: begin

                    // Navigation is disabled after selection.
                    // BACK returns to the menu.
                    if (back_pressed)
                        state <= STATE_MENU;

                end

                default: begin
                    state <= STATE_MENU;
                end

            endcase
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 007. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 008.


---

## Reproducible lab supplement — Boot menu state machine verification

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-007-Boot-Menu-Finite-State-Machine.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### State-machine checks

```bash
cd reference-t008
vim rtl/boot/boot_menu_controller.sv
bash scripts/test_top.sh
```

**Version warning:** the archived Tutorial 008 controller has a four-entry, 2-bit index and a `STATE_BOOTING` state. The Tutorial 009 controller has a six-entry menu and `IMPLEMENTED_CORES=6'b000000`. Do not copy the four-entry controller into the current Tutorial 009 tree. Verify reset, wraparound, one-cycle selection events, and Back behavior against the version under test.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
