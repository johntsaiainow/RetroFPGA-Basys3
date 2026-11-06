`timescale 1ns/1ps
module tb_counter;
  logic clk = 0, rst = 1;
  logic [3:0] count;
  always #5 clk = ~clk;
  counter dut(.*);
  initial begin
    repeat (2) @(negedge clk);
    rst = 0;
    for (int i=1; i<=17; i++) begin
      @(negedge clk);
      assert(count == 4'(i)) else $fatal(1, "count mismatch at %0d: %0d", i, count);
    end
    $display("PASS: Tutorial 001 counter (including rollover)");
    $finish;
  end
endmodule
