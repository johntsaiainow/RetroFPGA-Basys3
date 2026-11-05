`timescale 1ns/1ps


module tb_vga_timing;

logic clk = 0;
logic rst = 1;
logic pixel_ce;

logic hsync;
logic vsync;
logic video_active;

logic [9:0] x;
logic [9:0] y;

int pixel_count = 0;
int active_count = 0;
int hsync_low_count = 0;
int vsync_low_count = 0;

always #5 clk = ~clk;

pixel_enable pixel_gen (
.clk(clk),
.rst(rst),
.pixel_ce(pixel_ce)
);

vga_timing dut (
.clk(clk),
.rst(rst),
.pixel_ce(pixel_ce),
.hsync(hsync),
.vsync(vsync),
.video_active(video_active),
.x(x),
.y(y)
);

initial begin
repeat (2) @(negedge clk);
rst = 0;

// Verify one complete VGA frame.
repeat (800 * 525) begin

// Sample immediately before a pixel update.
do begin
@(negedge clk);
end while (!pixel_ce);

if (int'(x) !== (pixel_count % 800))
$fatal(1, "X mismatch at pixel %0d", pixel_count);

if (int'(y) !== (pixel_count / 800))
$fatal(1, "Y mismatch at pixel %0d", pixel_count);

if (video_active)
active_count++;

if (!hsync)
hsync_low_count++;

if (!vsync)
vsync_low_count++;

pixel_count++;
end

if (active_count != 640 * 480)
$fatal(1, "Active pixel count mismatch: %0d",
active_count);

if (hsync_low_count != 96 * 525)
$fatal(1, "HSYNC width mismatch: %0d",
hsync_low_count);

if (vsync_low_count != 2 * 800)
$fatal(1, "VSYNC width mismatch: %0d",
vsync_low_count);

$display("PASS: VGA 640x480 timing verified");
$display("Pixels: %0d", pixel_count);
$display("Active pixels: %0d", active_count);
$display("HSYNC low pixels: %0d", hsync_low_count);
$display("VSYNC low pixels: %0d", vsync_low_count);

$finish;
end

endmodule
