`timescale 1ns/1ps

module sap1_execution_controller #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned RUN_IPS = 2
) (
    input  logic clk,
    input  logic rst,
    input  logic run_pressed,
    input  logic pause_pressed,
    input  logic step_pressed,
    input  logic cpu_halted,
    output logic step_en,
    output logic running
);

    localparam int unsigned PERIOD =
        (CLK_FREQ_HZ / RUN_IPS) < 1 ?
        1 : (CLK_FREQ_HZ / RUN_IPS);

    localparam int unsigned CW =
        (PERIOD <= 1) ? 1 : $clog2(PERIOD);

    logic [CW-1:0] counter;
    logic [1:0] cycles_remaining;
    logic run_mode;

    initial begin
        assert (CLK_FREQ_HZ > 0 && RUN_IPS > 0)
            else $fatal(1, "Invalid clock parameters");
    end

    assign running = run_mode;

    assign step_en =
        !rst && !cpu_halted &&
        (cycles_remaining != 0);

    always_ff @(posedge clk) begin
        if (rst || cpu_halted) begin
            counter          <= '0;
            cycles_remaining <= 2'd0;
            run_mode         <= 1'b0;
        end else begin

            // Complete any already scheduled instruction.
            if (cycles_remaining != 0)
                cycles_remaining <= cycles_remaining - 2'd1;

            if (pause_pressed) begin
                run_mode <= 1'b0;
                counter  <= '0;
            end else if (run_pressed) begin
                run_mode <= 1'b1;
                counter  <= '0;
            end else if (run_mode) begin
                if (counter == CW'(PERIOD - 1)) begin
                    counter <= '0;

                    if (cycles_remaining == 0)
                        cycles_remaining <= 2'd2;
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                counter <= '0;

                if (step_pressed && cycles_remaining == 0)
                    cycles_remaining <= 2'd2;
            end
        end
    end

endmodule
