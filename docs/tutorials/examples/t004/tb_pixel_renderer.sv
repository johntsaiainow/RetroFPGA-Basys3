`timescale 1ns/1ps
module tb_pixel_renderer;
  logic [9:0] x, y;
  logic video_active;
  logic [3:0] vga_r, vga_g, vga_b;
  pixel_renderer dut(.*);
  logic [11:0] expected [8] = '{12'hfff,12'hff0,12'h0ff,12'h0f0,12'hf0f,12'hf00,12'h00f,12'h000};
  initial begin
    video_active=1; y=100;
    for (int i=0; i<8; i++) begin
      x=10'(i*80+40); #1;
      assert({vga_r,vga_g,vga_b} == expected[i])
        else $fatal(1,"bar %0d mismatch",i);
    end
    video_active=0; #1;
    assert({vga_r,vga_g,vga_b} == 12'h000) else $fatal(1,"blanking failed");
    $display("PASS: Tutorial 004 eight bars and blanking");
    $finish;
  end
endmodule
