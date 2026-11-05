`timescale 1ns/1ps
module tb_retrofpga_top;
    logic clk=0;
    logic btn_reset=1, btn_up=0, btn_down=0, btn_select=0, btn_back=0;
    wire hsync,vsync;
    wire [3:0] vga_r,vga_g,vga_b;
    wire [1:0] led_selected;
    wire led_booting;
    int tests=0;
    always #5 clk=~clk;
    retrofpga_top #(.DEBOUNCE_CLK_FREQ_HZ(1000),.DEBOUNCE_MS(1)) dut (
        .clk(clk),.btn_reset(btn_reset),.btn_up(btn_up),.btn_down(btn_down),
        .btn_select(btn_select),.btn_back(btn_back),
        .hsync(hsync),.vsync(vsync),.vga_r(vga_r),.vga_g(vga_g),.vga_b(vga_b),
        .led_selected(led_selected),.led_booting(led_booting));
    task automatic check(input logic [1:0] index, input logic booting);
        @(negedge clk);
        if (led_selected !== index || led_booting !== booting)
            $fatal(1,"state mismatch: index=%0d boot=%b",led_selected,led_booting);
        tests++;
    endtask
    task automatic tap(input int button_id);
        @(negedge clk);
        case (button_id)
            0: btn_up=1;
            1: btn_down=1;
            2: btn_select=1;
            3: btn_back=1;
        endcase
        repeat (12) @(negedge clk);
        case (button_id)
            0: btn_up=0;
            1: btn_down=0;
            2: btn_select=0;
            3: btn_back=0;
        endcase
        repeat (12) @(negedge clk);
    endtask
    initial begin
        $dumpfile("retrofpga_top.vcd");
        $dumpvars(0,tb_retrofpga_top);
        repeat (5) @(negedge clk);
        btn_reset=0;
        repeat (6) @(negedge clk);
        check(0,0);
        tap(1); check(1,0);
        tap(1); check(2,0);
        tap(1); check(3,0);
        tap(1); check(0,0);
        tap(0); check(3,0);
        tap(2); check(3,1);
        tap(1); check(3,1);
        tap(3); check(3,0);
        tap(0); check(2,0);
        // VGA timing should advance, and HSYNC must pulse low.
        begin : vga_check
            bit saw_hsync_low;
            saw_hsync_low = 0;
            repeat (3500) begin
                @(negedge clk);
                if (!hsync) saw_hsync_low = 1;
                if (!dut.video_active && {vga_r,vga_g,vga_b} !== 12'h000)
                    $fatal(1,"RGB must be black during blanking");
            end
            if (!saw_hsync_low) $fatal(1,"HSYNC never asserted low");
        end
        tests++;
        $display("PASS: Tutorial 008 top integration (%0d checks)",tests);
        $finish;
    end
    initial begin
        #1000000; $fatal(1,"timeout");
    end
endmodule
