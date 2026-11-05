`timescale 1ns/1ps


module tb_pixel_renderer;

logic [9:0] x;
logic [9:0] y;
logic       video_active;

logic [3:0] vga_r;
logic [3:0] vga_g;
logic [3:0] vga_b;

int tests = 0;

pixel_renderer dut (
.x(x),
.y(y),
.video_active(video_active),
.vga_r(vga_r),
.vga_g(vga_g),
.vga_b(vga_b)
);

task automatic check_pixel (
input logic [9:0]  test_x,
input logic [9:0]  test_y,
input logic        active,
input logic [11:0] expected_rgb
);

x = test_x;
y = test_y;
video_active = active;

#1;

if ({vga_r,vga_g,vga_b} !== expected_rgb) begin
$fatal(1,
"FAIL: x=%0d y=%0d RGB=%03h expected=%03h",
x, y,
,
expected_rgb
);
end

tests++;
    endtask

    initial begin

$display("RetroFPGA Tutorial 004");
        $display("VGA Pixel Renderer Test");

// Check all eight color bars.
        check_pixel(10'd0,   10'd0, 1'b1, 12'hFFF);
        check_pixel(10'd80,  10'd0, 1'b1, 12'hFF0);
        check_pixel(10'd160, 10'd0, 1'b1, 12'h0FF);
        check_pixel(10'd240, 10'd0, 1'b1, 12'h0F0);
        check_pixel(10'd320, 10'd0, 1'b1, 12'hF0F);
        check_pixel(10'd400, 10'd0, 1'b1, 12'hF00);
        check_pixel(10'd480, 10'd0, 1'b1, 12'h00F);
        check_pixel(10'd560, 10'd0, 1'b1, 12'h000);

// Check color bar boundaries.
        check_pixel(10'd79,  10'd100, 1'b1, 12'hFFF);
        check_pixel(10'd159, 10'd100, 1'b1, 12'hFF0);
        check_pixel(10'd239, 10'd100, 1'b1, 12'h0FF);
        check_pixel(10'd319, 10'd100, 1'b1, 12'h0F0);
        check_pixel(10'd399, 10'd100, 1'b1, 12'hF0F);
        check_pixel(10'd479, 10'd100, 1'b1, 12'hF00);
        check_pixel(10'd559, 10'd100, 1'b1, 12'h00F);
        check_pixel(10'd639, 10'd100, 1'b1, 12'h000);

// Check bottom visible row.
        check_pixel(10'd0, 10'd479, 1'b1, 12'hFFF);

// Blanking must always produce black.
        check_pixel(10'd0,   10'd0,   1'b0, 12'h000);
        check_pixel(10'd100, 10'd100, 1'b0, 12'h000);
        check_pixel(10'd700, 10'd100, 1'b0, 12'h000);
        check_pixel(10'd0,   10'd500, 1'b0, 12'h000);

// Out-of-range coordinates must remain black.
        check_pixel(10'd640, 10'd100, 1'b1, 12'h000);
        check_pixel(10'd0,   10'd480, 1'b1, 12'h000);

$display("PASS: VGA Pixel Renderer verified");
        $display("Tests passed: %0d", tests);

$finish;
    end

endmodule
