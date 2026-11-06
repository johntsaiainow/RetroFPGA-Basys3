# Tutorial 002 — 25 MHz Pixel Enable

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Derive a pixel clock-enable pulse from the Basys 3 100 MHz input clock.

## Place in the series

The four-cycle divider creates a 25 MHz pixel enable while all logic stays in the 100 MHz clock domain.

## Source files

Primary module: `rtl/video/pixel_enable.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/video/pixel_enable.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module pixel_enable (
    input  logic clk,
    input  logic rst,
    output logic pixel_ce
);

    logic [1:0] divider;

    always_ff @(posedge clk) begin
        if (rst)
            divider <= 2'd0;
        else
            divider <= divider + 2'd1;
    end

    assign pixel_ce = (divider == 2'd3);

endmodule
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 002. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 003.


---

## Reproducible lab supplement — 25 MHz pixel-enable verification

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-002-25-MHz-Pixel-Enable.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### What to inspect

At a 100 MHz input clock, the archived 2-bit divider generates one `pixel_ce` pulse every four input clocks. This is a **clock enable**, not a separately routed 25 MHz clock. The test checks 10 pulses in 40 cycles.

Expected: `PASS: Tutorial 002 pixel enable 1/4 rate`.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
