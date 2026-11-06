`timescale 1ns/1ps
module tb_pixel_enable;
  logic clk = 0, rst = 1, pixel_ce;
  int pulses = 0;
  always #5 clk = ~clk;
  pixel_enable dut(.*);
  initial begin
    repeat(2) @(negedge clk);
    rst = 0;
    repeat(40) begin
      @(negedge clk);
      if (pixel_ce) pulses++;
    end
    assert(pulses == 10) else $fatal(1,"expected 10 pulses, got %0d",pulses);
    $display("PASS: Tutorial 002 pixel enable 1/4 rate");
    $finish;
  end
endmodule
