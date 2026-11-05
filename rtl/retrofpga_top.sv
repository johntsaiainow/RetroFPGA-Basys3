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
