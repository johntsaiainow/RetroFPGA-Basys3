`timescale 1ns/1ps

module ps2_keyboard_receiver #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned FILTER_US   = 5,
    parameter int unsigned TIMEOUT_US  = 2000
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       ps2_clk,
    input  logic       ps2_data,

    output logic [7:0] scan_code,
    output logic       scan_valid,
    output logic       frame_error,
    output logic       accepted_edge,
    output logic       timeout_error
);

    localparam int unsigned FILTER_CYCLES =
        (CLK_FREQ_HZ / 1_000_000) * FILTER_US;

    localparam int unsigned TIMEOUT_CYCLES =
        (CLK_FREQ_HZ / 1_000_000) * TIMEOUT_US;

    localparam int FILTER_W =
        (FILTER_CYCLES > 1) ? $clog2(FILTER_CYCLES + 1) : 1;

    localparam int TIMEOUT_W =
        (TIMEOUT_CYCLES > 1) ? $clog2(TIMEOUT_CYCLES + 1) : 1;

    (* ASYNC_REG = "TRUE" *)
    logic [1:0] clk_sync;

    (* ASYNC_REG = "TRUE" *)
    logic [1:0] data_sync;

    logic clk_filtered;
    logic clk_filtered_d;

    logic [FILTER_W-1:0] filter_count;
    logic [TIMEOUT_W-1:0] timeout_count;

    logic [9:1] frame;
    logic [3:0] bit_count;

    logic falling_edge_ps2;

    assign accepted_edge = falling_edge_ps2;

    assign falling_edge_ps2 =
        clk_filtered_d && !clk_filtered;

    // Two-stage synchronizers.
    always_ff @(posedge clk) begin
        if (rst) begin
            clk_sync  <= 2'b11;
            data_sync <= 2'b11;
        end else begin
            clk_sync  <= {clk_sync[0], ps2_clk};
            data_sync <= {data_sync[0], ps2_data};
        end
    end

    // PS/2 clock glitch filter.
    always_ff @(posedge clk) begin
        if (rst) begin
            clk_filtered   <= 1'b1;
            clk_filtered_d <= 1'b1;
            filter_count   <= '0;
        end else begin
            clk_filtered_d <= clk_filtered;

            if (clk_sync[1] == clk_filtered) begin
                filter_count <= '0;
            end else if (filter_count == FILTER_W'(FILTER_CYCLES - 1)) begin
                clk_filtered <= clk_sync[1];
                filter_count <= '0;
            end else begin
                filter_count <= filter_count + 1'b1;
            end
        end
    end

    // Frame receiver.
    always_ff @(posedge clk) begin
        if (rst) begin
            frame         <= '0;
            bit_count     <= '0;
            timeout_count <= '0;
            scan_code     <= '0;
            scan_valid    <= 1'b0;
            frame_error   <= 1'b0;
            timeout_error <= 1'b0;
        end else begin
            scan_valid  <= 1'b0;
            frame_error <= 1'b0;
            timeout_error <= 1'b0;

            if (!falling_edge_ps2 && bit_count != 0) begin
                if (timeout_count == TIMEOUT_W'(TIMEOUT_CYCLES - 1)) begin
                    bit_count     <= '0;
                    timeout_count <= '0;
                    frame_error   <= 1'b1;
                    timeout_error <= 1'b1;
                end else begin
                    timeout_count <= timeout_count + 1'b1;
                end
            end else begin
                timeout_count <= '0;
            end

            if (falling_edge_ps2) begin
                timeout_count <= '0;

                if (bit_count == 0) begin
                    if (!data_sync[1]) begin
                                                bit_count <= 4'd1;
                    end
                end else begin
                    if (bit_count < 10)
                        frame[bit_count] <= data_sync[1];

                    if (bit_count == 10) begin
                        bit_count <= '0;

                        if (data_sync[1] &&
                            (^frame[9:1]) == 1'b1) begin
                            scan_code  <= frame[8:1];
                            scan_valid <= 1'b1;
                        end else begin
                            frame_error <= 1'b1;
                        end
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end
            end
        end
    end

endmodule
