`timescale 1ns/1ps
// Newest received scan code occupies bits [7:0].
module ps2_scan_trace (
    input logic clk, rst,
    input logic scan_valid,
    input logic [7:0] scan_code,
    output logic [127:0] history,
    output logic [4:0] entries
);
    always_ff @(posedge clk) begin
        if (rst) begin
            history <= '0;
            entries <= '0;
        end else if (scan_valid) begin
            history <= {history[119:0], scan_code};
            if (entries < 5'd16) entries <= entries + 1'b1;
        end
    end
endmodule
