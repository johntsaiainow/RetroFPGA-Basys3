# Tutorial 003 — 640×480 VGA Timing

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Generate 640×480 timing, sync pulses, and pixel coordinates.

## Place in the series

The archived RTL uses 800 horizontal clocks and 525 lines per frame, with active-low HSYNC and VSYNC.

## Source files

Primary module: `rtl/video/vga_timing.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/video/vga_timing.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module vga_timing (
    input  logic       clk,
    input  logic       rst,
    input  logic       pixel_ce,

    output logic       hsync,
    output logic       vsync,
    output logic       video_active,

    output logic [9:0] x,
    output logic [9:0] y
);

    // VGA 640x480 timing
    // Horizontal: 640 + 16 + 96 + 48 = 800
    // Vertical:   480 + 10 +  2 + 33 = 525

    localparam logic [9:0] H_VISIBLE = 10'd640;
    localparam logic [9:0] H_FRONT   = 10'd16;
    localparam logic [9:0] H_SYNC    = 10'd96;
    localparam logic [9:0] H_BACK    = 10'd48;
    localparam logic [9:0] H_TOTAL   = 10'd800;

    localparam logic [9:0] V_VISIBLE = 10'd480;
    localparam logic [9:0] V_FRONT   = 10'd10;
    localparam logic [9:0] V_SYNC    = 10'd2;
    localparam logic [9:0] V_BACK    = 10'd33;
    localparam logic [9:0] V_TOTAL   = 10'd525;

    logic [9:0] h_count;
    logic [9:0] v_count;

    // Pixel counters
    always_ff @(posedge clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else if (pixel_ce) begin
            if (h_count == H_TOTAL - 10'd1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 10'd1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // Pixel coordinates
    assign x = h_count;
    assign y = v_count;

    // Visible display area
    assign video_active =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);

    // Horizontal sync: active low
    assign hsync = ~(
        (h_count >= H_VISIBLE + H_FRONT) &&
        (h_count < H_VISIBLE + H_FRONT + H_SYNC)
    );

    // Vertical sync: active low
    assign vsync = ~(
        (v_count >= V_VISIBLE + V_FRONT) &&
        (v_count < V_VISIBLE + V_FRONT + V_SYNC)
    );

endmodule
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 003. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

Expected timing: horizontal 640 visible + 16 front porch + 96 sync + 48 back porch = 800; vertical 480 visible + 10 front porch + 2 sync + 33 back porch = 525. A 25 MHz pixel enable yields approximately 59.52 Hz.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 004.


---

## Reproducible lab supplement — VGA timing verification

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-003-640-480-VGA-Timing.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### What to inspect

The archived VGA generator uses 800 pixel clocks per line and 525 lines per frame. Its horizontal sync is low at columns 656–751; vertical sync is low at lines 490–491. The test checks each pixel coordinate, blanking, and both sync polarities across one frame. At a 25 MHz pixel enable, nominal refresh is approximately 59.52 Hz.

Expected: `PASS: Tutorial 003 full VGA frame (800x525)`.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
