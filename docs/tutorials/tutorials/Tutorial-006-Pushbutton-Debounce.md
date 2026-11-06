# Tutorial 006 — Pushbutton Debounce

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Convert noisy mechanical button inputs into clean one-cycle press events.

## Place in the series

The archived RTL provides the button filter used by the menu controller.

## Source files

Primary module: `rtl/input/button_debounce.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/input/button_debounce.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module button_debounce #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned DEBOUNCE_MS = 10
) (
    input  logic clk,
    input  logic rst,
    input  logic button_in,

    output logic level,
    output logic pressed,
    output logic released
);

    // Number of clock cycles required for debounce.
    // Integer ceiling avoids truncating fractional cycles.
    localparam longint unsigned DEBOUNCE_CYCLES =
        (longint'(CLK_FREQ_HZ) * DEBOUNCE_MS
         + 999) / 1000;

    localparam int unsigned COUNTER_WIDTH =
        (DEBOUNCE_CYCLES > 1)
            ? $clog2(DEBOUNCE_CYCLES)
            : 1;

    localparam logic [COUNTER_WIDTH-1:0] COUNT_LAST =
        COUNTER_WIDTH'(DEBOUNCE_CYCLES - 1);

    // Two-stage synchronizer.
    (* ASYNC_REG = "TRUE" *) logic sync_stage1;
    (* ASYNC_REG = "TRUE" *) logic sync_stage2;

    logic [COUNTER_WIDTH-1:0] stable_count;

    // Parameter checks for simulation.
    initial begin
        assert (CLK_FREQ_HZ > 0)
            else $fatal(1, "CLK_FREQ_HZ must be > 0");

        assert (DEBOUNCE_MS > 0)
            else $fatal(1, "DEBOUNCE_MS must be > 0");

        assert (DEBOUNCE_CYCLES >= 1)
            else $fatal(1, "Invalid debounce interval");
    end

    // Synchronize the asynchronous push button.
    always_ff @(posedge clk) begin
        if (rst) begin
            sync_stage1 <= 1'b0;
            sync_stage2 <= 1'b0;
        end else begin
            sync_stage1 <= button_in;
            sync_stage2 <= sync_stage1;
        end
    end

    // Debounce filter and one-cycle event pulses.
    always_ff @(posedge clk) begin
        if (rst) begin
            level        <= 1'b0;
            pressed      <= 1'b0;
            released     <= 1'b0;
            stable_count <= '0;
        end else begin

            // Pulses default to zero every clock.
            pressed  <= 1'b0;
            released <= 1'b0;

            if (sync_stage2 == level) begin

                // Input agrees with the accepted level.
                stable_count <= '0;

            end else if (stable_count == COUNT_LAST) begin

                // Input has remained different long enough.
                level        <= sync_stage2;
                stable_count <= '0;

                if (sync_stage2)
                    pressed <= 1'b1;
                else
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 006. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 007.


---

## Reproducible lab supplement — Button synchronizer and debounce verification

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-006-Pushbutton-Debounce.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### Debounce-specific checks

```bash
cd reference-t008
vim rtl/input/button_debounce.sv
bash scripts/test_top.sh
```

Inspect the two-stage synchronizer, stable counter, and one-clock `pressed`/`released` pulses. The archived top test uses reduced debounce parameters for simulation. **Real 10 ms debounce at 100 MHz requires approximately one million stable cycles**; a short simulation with reduced parameters is not a full physical switch-bounce characterization.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
