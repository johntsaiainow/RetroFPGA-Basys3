`timescale 1ns/1ps

module ps2_keyboard_diagnostics #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned PULSE_MS = 200
) (
    input  logic clk,
    input  logic rst,

    input  logic ps2_clk,
    input  logic scan_valid,
    input  logic frame_error,
    input  logic timeout_error,

    output logic [7:0] valid_count,
    output logic [7:0] error_count,

    output logic led_clock_activity,
    output logic led_valid_activity,
    output logic led_error_activity,
    output logic led_timeout_activity
);

    localparam int unsigned PULSE_CYCLES =
        (CLK_FREQ_HZ / 1000) * PULSE_MS;

    localparam int unsigned TIMER_WIDTH =
        $clog2(PULSE_CYCLES + 1);

    logic ps2_meta;
    logic ps2_sync;
    logic ps2_prev;

    logic [TIMER_WIDTH-1:0] clock_timer;
    logic [TIMER_WIDTH-1:0] valid_timer;
    logic [TIMER_WIDTH-1:0] error_timer;
    logic [TIMER_WIDTH-1:0] timeout_timer;

    wire clock_falling = ps2_prev && !ps2_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            ps2_meta <= 1'b1;
            ps2_sync <= 1'b1;
            ps2_prev <= 1'b1;

            valid_count <= '0;
            error_count <= '0;

            clock_timer <= '0;
            valid_timer <= '0;
            error_timer <= '0;
            timeout_timer <= '0;
        end else begin
            ps2_meta <= ps2_clk;
            ps2_sync <= ps2_meta;
            ps2_prev <= ps2_sync;

            if (clock_falling)
                clock_timer <= TIMER_WIDTH'(PULSE_CYCLES);
            else if (clock_timer != 0)
                clock_timer <= clock_timer - 1'b1;

            if (scan_valid) begin
                valid_count <= valid_count + 1'b1;
                valid_timer <= TIMER_WIDTH'(PULSE_CYCLES);
            end else if (valid_timer != 0)
                valid_timer <= valid_timer - 1'b1;

            if (frame_error) begin
                error_count <= error_count + 1'b1;
                error_timer <= TIMER_WIDTH'(PULSE_CYCLES);
            end else if (error_timer != 0)
                error_timer <= error_timer - 1'b1;

            if (timeout_error)
                timeout_timer <= TIMER_WIDTH'(PULSE_CYCLES);
            else if (timeout_timer != 0)
                timeout_timer <= timeout_timer - 1'b1;
        end
    end

    assign led_clock_activity = (clock_timer != 0);
    assign led_valid_activity = (valid_timer != 0);
    assign led_error_activity = (error_timer != 0);
    assign led_timeout_activity = (timeout_timer != 0);

endmodule
