`timescale 1ns/1ps
module tb_boot_menu_controller;
  logic clk=0,rst=1,up_pressed=0,down_pressed=0,select_pressed=0,back_pressed=0;
  logic [1:0] selected_index,boot_core;
  logic menu_active,boot_request,booting;
  always #5 clk=~clk;
  boot_menu_controller dut(.*);
  task automatic tick;
    @(negedge clk); #1;
  endtask
  task automatic check(input int idx,input bit menu,input bit req,input int core);
    assert(selected_index===2'(idx) && menu_active===menu && booting===!menu && boot_request===req && boot_core===2'(core))
      else $fatal(1,"FSM got idx=%0d menu=%b boot=%b req=%b core=%0d; expected idx=%0d menu=%b req=%b core=%0d",selected_index,menu_active,booting,boot_request,boot_core,idx,menu,req,core);
  endtask
  task automatic pulse_down;
    down_pressed=1; tick(); down_pressed=0; tick();
  endtask
  task automatic pulse_up;
    up_pressed=1; tick(); up_pressed=0; tick();
  endtask
  initial begin
    repeat(2) tick(); rst=0; tick(); check(0,1,0,0);
    pulse_up(); check(3,1,0,0); // 2-bit wrap
    pulse_down(); check(0,1,0,0);
    pulse_down(); check(1,1,0,0);
    pulse_down(); check(2,1,0,0);
    pulse_down(); check(3,1,0,0);
    pulse_down(); check(0,1,0,0);
    // SELECT has priority over UP/DOWN.
    select_pressed=1; up_pressed=1; down_pressed=1;
    tick(); check(0,0,1,0);
    select_pressed=0; up_pressed=0; down_pressed=0;
    tick(); check(0,0,0,0);
    pulse_down(); check(0,0,0,0); // navigation disabled while booting
    back_pressed=1; tick(); check(0,1,0,0);
    back_pressed=0; tick(); check(0,1,0,0);
    pulse_down(); check(1,1,0,0);
    select_pressed=1; tick(); check(1,0,1,1);
    select_pressed=0; tick(); check(1,0,0,1);
    rst=1; tick(); check(0,1,0,0);
    $display("PASS: Tutorial 007 four-entry boot menu FSM"); $finish;
  end
endmodule
