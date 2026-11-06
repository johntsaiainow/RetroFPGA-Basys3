# Tutorial 004 — VGA Pixel Renderer

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Generate an RGB test pattern from pixel coordinates and video-active status.

## Place in the series

This is a color-bar demonstration; it is not the final boot-menu renderer.

## Source files

Primary module: `rtl/video/pixel_renderer.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/video/pixel_renderer.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module pixel_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       video_active,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);

    logic [11:0] rgb;

    // RGB444 color bar generator.
    //
    // Each bar occupies 80 horizontal pixels.
    // Eight bars cover the entire 640-pixel width.

    always_comb begin
        rgb = 12'h000;

        if (video_active && (y < 10'd480)) begin

            if (x < 10'd80)
                rgb = 12'hFFF;  // White

            else if (x < 10'd160)
                rgb = 12'hFF0;  // Yellow

            else if (x < 10'd240)
                rgb = 12'h0FF;  // Cyan

            else if (x < 10'd320)
                rgb = 12'h0F0;  // Green

            else if (x < 10'd400)
                rgb = 12'hF0F;  // Magenta

            else if (x < 10'd480)
                rgb = 12'hF00;  // Red

            else if (x < 10'd560)
                rgb = 12'h00F;  // Blue

            else if (x < 10'd640)
                rgb = 12'h000;  // Black
        end
    end

    assign vga_r = rgb[11:8];
    assign vga_g = rgb[7:4];
    assign vga_b = rgb[3:0];

endmodule
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 004. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 005.


---

## Reproducible lab supplement — Eight-bar renderer verification

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-004-VGA-Pixel-Renderer.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### What to inspect

The reference color-bar module renders eight 80-pixel bars: white, yellow, cyan, green, magenta, red, blue, black. The test samples the center of each bar and verifies black during blanking.

Expected: `PASS: Tutorial 004 eight bars and blanking`.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
