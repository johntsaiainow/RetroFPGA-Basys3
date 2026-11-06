`timescale 1ns/1ps

module retrofpga_top #(
    parameter int unsigned DEBOUNCE_CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned DEBOUNCE_MS = 10,
    parameter logic [5:0] IMPLEMENTED_CORES = 6'b000001
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
    output logic [2:0] led_selected,
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
    logic [2:0] selected_index, boot_core;
    logic menu_active, boot_request, booting;
    logic [3:0] title_r, title_g, title_b;
    logic [11:0] menu_rgb, final_rgb;
    logic menu_opaque;
    logic [7:0] sap_out, sap_acc;
    logic [3:0] sap_pc;
    logic sap_halted, sap_out_valid;
    logic sap_active;
    logic sap_running;
    logic [11:0] sap_rgb;
    logic cpu_step;
    logic sap_reset;

    logic menu_up, menu_down, menu_select, menu_back;
    logic cpu_run, cpu_pause, cpu_step_pressed;

    pixel_enable pixel_clock (.clk(clk), .rst(reset_sync), .pixel_ce(pixel_ce));
    vga_timing timing (.clk(clk), .rst(reset_sync), .pixel_ce(pixel_ce),
        .hsync(hsync), .vsync(vsync), .video_active(video_active), .x(x), .y(y));

    /* verilator lint_off PINCONNECTEMPTY */
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        up_filter (.clk(clk), .rst(reset_sync), .button_in(btn_up),
                   .level(), .pressed(up_pressed), .released());
    /* verilator lint_off PINCONNECTEMPTY */
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        down_filter (.clk(clk), .rst(reset_sync), .button_in(btn_down),
                     .level(), .pressed(down_pressed), .released());
    /* verilator lint_off PINCONNECTEMPTY */
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        select_filter (.clk(clk), .rst(reset_sync), .button_in(btn_select),
                       .level(), .pressed(select_pressed), .released());
    /* verilator lint_off PINCONNECTEMPTY */
    button_debounce #(.CLK_FREQ_HZ(DEBOUNCE_CLK_FREQ_HZ), .DEBOUNCE_MS(DEBOUNCE_MS))
        back_filter (.clk(clk), .rst(reset_sync), .button_in(btn_back),
                     .level(), .pressed(back_pressed), .released());

    /* verilator lint_on PINCONNECTEMPTY */
    boot_menu_controller #(
    .IMPLEMENTED_CORES(IMPLEMENTED_CORES)
) controller (
        .clk(clk), .rst(reset_sync), .up_pressed(menu_up),
        .down_pressed(menu_down), .select_pressed(menu_select),
        .back_pressed(menu_back), .selected_index(selected_index),
        .menu_active(menu_active), .boot_core(boot_core),
        .boot_request(boot_request), .booting(booting));

    text_renderer title (.x(x), .y(y), .video_active(video_active),
        .vga_r(title_r), .vga_g(title_g), .vga_b(title_b));
    boot_menu_renderer menu (.x(x), .y(y), .video_active(video_active),
        .selected_index(selected_index), .menu_active(menu_active),
        .rgb(menu_rgb), .opaque(menu_opaque));

    // Tutorial 012: board-independent input routing.
    retrofpga_input_router input_router (
        .menu_active(menu_active),
        .up_pressed(up_pressed),
        .down_pressed(down_pressed),
        .select_pressed(select_pressed),
        .back_pressed(back_pressed),
        .menu_up(menu_up),
        .menu_down(menu_down),
        .menu_select(menu_select),
        .menu_back(menu_back),
        .cpu_run(cpu_run),
        .cpu_pause(cpu_pause),
        .cpu_step(cpu_step_pressed)
    );

    // SAP-1 is architecture ID 0.
    assign sap_active = booting && (boot_core == 3'd0);
    assign sap_reset = reset_sync || !sap_active;

    sap1_execution_controller #(
        .CLK_FREQ_HZ(100_000_000),
        .RUN_IPS(2)
    ) execution_controller (
        .clk(clk),
        .rst(sap_reset),
        .run_pressed(cpu_run),
        .pause_pressed(cpu_pause),
        .step_pressed(cpu_step_pressed),
        .cpu_halted(sap_halted),
        .step_en(cpu_step),
        .running(sap_running)
    );

    sap1_core cpu (
        .clk(clk), .rst(sap_reset), .step_en(cpu_step),
        .out_port(sap_out), .out_valid(sap_out_valid),
        .halted(sap_halted), .pc_debug(sap_pc), .acc_debug(sap_acc)
    );
    sap1_vga_monitor monitor (
        .x(x), .y(y), .video_active(video_active),
        .pc(sap_pc), .acc(sap_acc), .out_port(sap_out),
        .halted(sap_halted), .rgb(sap_rgb)
    );

    always_comb begin
        final_rgb = {title_r, title_g, title_b};
        if (menu_opaque) final_rgb = menu_rgb;
        if (sap_active) final_rgb = sap_rgb;
        if (!video_active) final_rgb = 12'h000;
    end
    assign {vga_r, vga_g, vga_b} = final_rgb;
    assign led_selected = selected_index;
    assign led_booting = booting;
endmodule
