# Tutorial 008 — Basys 3 Top-Level Integration

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Integrate button inputs, menu control, VGA timing, text rendering, and output LEDs.

## Place in the series

Tutorial 008 integration was simulated, not yet hardware validated; the archive explicitly warns that no XDC was provided.

## Source files

Primary module: `rtl/retrofpga_top.sv`.

Related modules: `rtl/video/boot_menu_renderer.sv`, `rtl/input/button_debounce.sv`, `rtl/video/vga_timing.sv`, and `rtl/boot/boot_menu_controller.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/retrofpga_top.sv
```

### Reference RTL excerpt (from the archived Tutorial 008 integration snapshot)

```systemverilog
`timescale 1ns/1ps

module retrofpga_top #(
    parameter int unsigned DEBOUNCE_CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned DEBOUNCE_MS = 10
) (
    input  logic clk,
    input  logic btn_reset,
    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_select,
    input  logic btn_back,
    output logic hsync,
    output logic vsync,
    output logic [3:0] vga_r, vga_g, vga_b,
    output logic [1:0] led_selected,
    output logic led_booting
);
    // Asynchronous assertion, synchronous release of reset.
    (* ASYNC_REG = "TRUE" *) logic reset_meta = 1'b1;
    (* ASYNC_REG = "TRUE" *) logic reset_sync = 1'b1;
    always_ff @(posedge clk or posedge btn_reset) begin
        if (btn_reset) begin
            reset_meta <= 1'b1;
            reset_sync <= 1'b1;
        end else begin
            reset_meta <= 1'b0;
            reset_sync <= reset_meta;
        end
    end
    logic pixel_ce, video_active;
    logic [9:0] x, y;
    logic up_pressed, down_pressed, select_pressed, back_pressed;
    logic [1:0] selected_index, boot_core;
    logic menu_active, boot_request, booting;
    logic [3:0] title_r, title_g, title_b;
    logic [11:0] menu_rgb, final_rgb;
    logic menu_opaque;

    pixel_enable pixel_clock (.clk(clk), .rst(reset_sync), .pixel_ce(pixel_ce));
    vga_timing timing (.clk(clk), .rst(reset_sync), .pixel_ce(pixel_ce),
        .hsync(hsync), .vsync(vsync), .video_active(video_active), .x(x), .y(y));

    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        up_filter (.clk(clk), .rst(reset_sync), .button_in(btn_up),
                   .level(), .pressed(up_pressed), .released());
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        down_filter (.clk(clk), .rst(reset_sync), .button_in(btn_down),
                     .level(), .pressed(down_pressed), .released());
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        select_filter (.clk(clk), .rst(reset_sync), .button_in(btn_select),
                       .level(), .pressed(select_pressed), .released());
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        back_filter (.clk(clk), .rst(reset_sync), .button_in(btn_back),
                     .level(), .pressed(back_pressed), .released());

    boot_menu_controller controller (
        .clk(clk), .rst(reset_sync), .up_pressed(up_pressed),
        .down_pressed(down_pressed), .select_pressed(select_pressed),
        .back_pressed(back_pressed), .selected_index(selected_index),
        .menu_active(menu_active), .boot_core(boot_core),
        .boot_request(boot_request), .booting(booting));

    text_renderer title (.x(x), .y(y), .video_active(video_active),
        .vga_r(title_r), .vga_g(title_g), .vga_b(title_b));
    boot_menu_renderer menu (.x(x), .y(y), .video_active(video_active),
        .selected_index(selected_index), .menu_active(menu_active),
        .rgb(menu_rgb), .opaque(menu_opaque));

    always_comb begin
        final_rgb = {title_r, title_g, title_b};
        if (menu_opaque) final_rgb = menu_rgb;
        if (!video_active) final_rgb = 12'h000;
    end
    assign {vga_r, vga_g, vga_b} = final_rgb;
    assign led_selected = selected_index;
    assign led_booting = booting;
endmodule
```

> The excerpt is a reference snapshot, not necessarily the exact code originally written in Tutorial 008. Use the current repository for the latest implementation.

## Validation

```bash
cd ~/Projects/RetroFPGA-Basys3
bash scripts/test_top.sh
```

This command is specifically included in the archived Tutorial 008 integration package.

**Hardware safety:** Do not generate/program a board bitstream without a verified Basys 3 XDC pin map and 3.3 V I/O standards. Tutorial 009 subsequently added XDC and confirmed the VGA boot menu on a real board.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Proceed to [Tutorial 009](../Tutorial-009-RetroFPGA-Basys3-VGA-Boot-Menu.md) for six-architecture menu integration, Vivado build, JTAG configuration, and physical VGA verification.


---

## Reproducible lab supplement — Top-level integration and hardware handoff

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-008-Basys-3-Top-Level-Integration.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### Complete archived integration command

```bash
cd reference-t008
bash scripts/test_top.sh
```

Expected result is the PASS message from `sim/tb_retrofpga_top.sv`, if your Verilator version supports the archived testbench. The archived package did not include a board-complete XDC. Use the **current** repository's `constraints/basys3.xdc` for actual FPGA implementation.

### Current Tutorial 009 hardware handoff

```bash
cd ~/Projects/RetroFPGA-Basys3
source "$HOME/Xilinx/2026.1/Vivado/settings64.sh"
COMPAT_DIR="$XILINX_VIVADO/lib/lnx64.o/Ubuntu/24"
export LD_LIBRARY_PATH="$COMPAT_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
./scripts/build_basys3.sh
```

Do not execute JTAG programming until the generated bitstream exists and you have verified the connected target. See Tutorial 009 for the programming Tcl and hardware acceptance.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
