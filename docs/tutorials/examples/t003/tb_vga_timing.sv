`timescale 1ns/1ps
module tb_vga_timing;
  logic clk=0,rst=1,pixel_ce=1;
  logic hsync,vsync,video_active;
  logic [9:0] x,y;
  always #5 clk=~clk;
  vga_timing dut(.*);
  initial begin
    repeat(2) @(negedge clk); rst=0;
    for(int line=0;line<525;line++) begin
      for(int col=0;col<800;col++) begin
        assert(x==10'(col) && y==10'(line))
          else $fatal(1,"coordinate mismatch x=%0d y=%0d expected %0d,%0d",x,y,col,line);
        assert(video_active == ((col<640)&&(line<480))) else $fatal(1,"active video mismatch");
        assert(hsync == !((col>=656)&&(col<752))) else $fatal(1,"hsync mismatch");
        assert(vsync == !((line>=490)&&(line<492))) else $fatal(1,"vsync mismatch");
        @(negedge clk);
      end
    end
    $display("PASS: Tutorial 003 full VGA frame (800x525)");
    $finish;
  end
endmodule
