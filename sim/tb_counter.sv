`timescale 1ns/1ps

module tb_counter;

    logic clk = 0;
    logic rst = 1;
    logic [3:0] count;

    counter dut (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    always #5 clk = ~clk;

    initial begin
        $display("RetroFPGA Phase 1 - Counter Test");

        #20;
        rst = 0;

        repeat (20) begin
            @(posedge clk);
            #1;
            $display("count = %0d", count);
        end

        $finish;
    end

endmodule
