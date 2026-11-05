`timescale 1ns/1ps


module tb_pixel_enable;

logic clk = 0;
logic rst = 1;
logic pixel_ce;

int cycles = 0;
int pulses = 0;

pixel_enable dut (
.clk(clk),
.rst(rst),
.pixel_ce(pixel_ce)
);

always #5 clk = ~clk;

initial begin
repeat (2) @(negedge clk);
rst = 0;

repeat (40) begin
@(negedge clk);
cycles++;

if (pixel_ce)
pulses++;
end

if (pulses != 10)
$fatal(1, "Expected 10 pulses, got %0d", pulses);

$display("PASS: %0d cycles, %0d pixel enables",
cycles, pulses);
$finish;
end

endmodule
