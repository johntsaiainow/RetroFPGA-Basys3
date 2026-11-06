# Tutorial 005 — Font ROM and Text Rendering

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Render text on the VGA display using a glyph ROM and character layout.

## Place in the series

The archived implementation includes font_rom.sv and text_renderer.sv. The older renderer draws fixed text.

## Source files

Primary module: `rtl/video/text_renderer.sv`.

Related module: `rtl/video/font_rom.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/video/text_renderer.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps


module text_renderer (
input  logic [9:0] x,
input  logic [9:0] y,
input  logic       video_active,

output logic [3:0] vga_r,
output logic [3:0] vga_g,
output logic [3:0] vga_b
);

localparam logic [9:0] TEXT_X = 10'd64;
localparam logic [9:0] TEXT_Y = 10'd64;

logic [9:0] local_x;
logic [9:0] local_y;

logic [7:0] ascii;
logic [7:0] bitmap;
logic [2:0] font_row;
logic [2:0] font_col;

logic [5:0] char_col;
logic [1:0] char_row;

logic pixel_on;
logic [11:0] rgb;

// Translate screen coordinates to text coordinates.
always_comb begin
local_x = 10'd0;
local_y = 10'd0;

if ((x >= TEXT_X) && (y >= TEXT_Y)) begin
local_x = x - TEXT_X;
local_y = y - TEXT_Y;
end
end

assign char_col = local_x[8:3];
assign char_row = local_y[4:3];

assign font_col = local_x[2:0];
assign font_row = local_y[2:0];

// Character selection.
always_comb begin
ascii = 8'h20;

if (video_active &&
(x >= TEXT_X) &&
(y >= TEXT_Y) &&
(local_x < 10'd160) &&
(local_y < 10'd32)) begin

            case (char_row)

// "RETRO FPGA BOOT MENU"
                2'd0: begin
                    case (char_col)
                        6'd0:  ascii = "R";
                        6'd1:  ascii = "E";
                        6'd2:  ascii = "T";
                        6'd3:  ascii = "R";
                        6'd4:  ascii = "O";
                        6'd5:  ascii = " ";
                        6'd6:  ascii = "F";
                        6'd7:  ascii = "P";
                        6'd8:  ascii = "G";
                        6'd9:  ascii = "A";
                        6'd10: ascii = " ";
                        6'd11: ascii = "B";
                        6'd12: ascii = "O";
                        6'd13: ascii = "O";
                        6'd14: ascii = "T";
                        6'd15: ascii = " ";
                        6'd16: ascii = "M";
                        6'd17: ascii = "E";
                        6'd18: ascii = "N";
                        6'd19: ascii = "U";
                        default: ascii = " ";
                    endcase
                end
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 005. Use the current repository for the latest implementation.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 006.


---

## Reproducible lab supplement — Font ROM and text renderer integration

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-005-Font-ROM-and-Text-Rendering.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### Integration test and inspection

```bash
cd reference-t008
vim rtl/video/font_rom.sv
vim rtl/video/text_renderer.sv
bash scripts/test_top.sh
```

The archived integration test validates the top-level behavior but **does not constitute a glyph-by-glyph font-ROM test**. To extend coverage, create a dedicated testbench sampling the expected glyph pixels at known `(x,y)` coordinates and assert both glyph and background colors. Do not claim a dedicated font test passed until it is run.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
