`timescale 1ns/1ps

module pixel_enable (
    input  logic clk,
    input  logic rst,
    output logic pixel_ce
);

    logic [1:0] divider;

    always_ff @(posedge clk) begin
        if (rst)
            divider <= 2'd0;
        else
            divider <= divider + 2'd1;
    end

    assign pixel_ce = (divider == 2'd3);

endmodule
