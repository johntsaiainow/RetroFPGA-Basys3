`timescale 1ns/1ps
module tb_font_rom;
  logic [7:0] ascii;
  logic [2:0] row;
  logic [7:0] bitmap;
  font_rom dut(.*);
  task automatic check(input logic [7:0] ch, input logic [2:0] r, input logic [7:0] expected);
    ascii=ch; row=r; #1;
    assert(bitmap === expected) else $fatal(1,"font %h row %0d: got %h expected %h",ch,r,bitmap,expected);
  endtask
  initial begin
    for (int r=0;r<8;r++) check(8'h20,3'(r),8'h00);
    check("A",0,8'h18); check("A",3,8'h7e); check("A",6,8'h42);
    check("B",0,8'h7c); check("B",3,8'h7c);
    check("0",0,8'h3c); check("0",3,8'h4a);
    check("4",4,8'h7e);
    for (int r=0;r<8;r++) check(8'h61,3'(r),8'h00);
    check("A",7,8'h00); check("B",7,8'h00);
    $display("PASS: Tutorial 005 font ROM representative glyphs and defaults"); $finish;
  end
endmodule
