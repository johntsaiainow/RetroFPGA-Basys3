`timescale 1ns/1ps

module ps2_edge_counters (
    input  logic clk,
    input  logic rst,

    input  logic ps2_clk,
    input  logic accepted_edge,
    input  logic scan_valid,
    input  logic frame_error,
    input  logic timeout_error,

    output logic [15:0] raw_edge_count,
    output logic [15:0] accepted_edge_count,
    output logic [15:0] valid_frame_count,
    output logic [15:0] frame_error_count,
    output logic [15:0] timeout_count
);

    (* ASYNC_REG = "TRUE" *) logic [1:0] ps2_clk_sync;
    logic ps2_clk_prev;

    wire raw_falling_edge =
        ps2_clk_prev && !ps2_clk_sync[1];

    always_ff @(posedge clk) begin
        if (rst) begin
            ps2_clk_sync       <= 2'b11;
            ps2_clk_prev       <= 1'b1;

            raw_edge_count      <= '0;
            accepted_edge_count <= '0;
            valid_frame_count   <= '0;
            frame_error_count   <= '0;
            timeout_count       <= '0;
        end else begin
            ps2_clk_sync <= {ps2_clk_sync[0], ps2_clk};
            ps2_clk_prev <= ps2_clk_sync[1];

            if (raw_falling_edge)
                raw_edge_count <= raw_edge_count + 1'b1;

            if (accepted_edge)
                accepted_edge_count <= accepted_edge_count + 1'b1;

            if (scan_valid)
                valid_frame_count <= valid_frame_count + 1'b1;

            if (frame_error)
                frame_error_count <= frame_error_count + 1'b1;

            if (timeout_error)
                timeout_count <= timeout_count + 1'b1;
        end
    end

endmodule
