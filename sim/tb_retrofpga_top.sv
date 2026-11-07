`timescale 1ns/1ps
module tb_retrofpga_top;
    logic clk=0;
    logic ps2_clk=1, ps2_data=1;
    logic btn_reset=1, btn_up=0, btn_down=0, btn_select=0, btn_back=0;
    wire hsync,unused_vsync;
    wire [3:0] vga_r,vga_g,vga_b;
    wire [2:0] led_selected;
    wire led_booting;
    wire [7:0] unused_led_scan_code;
    wire unused_led_valid_activity;
    wire unused_led_error_activity;
    wire unused_led_clock_activity;
    wire unused_led_timeout_activity;
    int tests=0;
    always #5 clk <= ~clk;
    retrofpga_top #(.DEBOUNCE_CLK_FREQ_HZ(1000),.DEBOUNCE_MS(1)) dut (
        .clk(clk),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.btn_reset(btn_reset),.btn_up(btn_up),.btn_down(btn_down),
        .btn_select(btn_select),.btn_back(btn_back),
        .hsync(hsync),.vsync(unused_vsync),.vga_r(vga_r),.vga_g(vga_g),.vga_b(vga_b),
        .led_selected(led_selected),.led_booting(led_booting),
        .led_scan_code(unused_led_scan_code),
        .led_valid_activity(unused_led_valid_activity),
        .led_error_activity(unused_led_error_activity),
        .led_clock_activity(unused_led_clock_activity),
        .led_timeout_activity(unused_led_timeout_activity));
    task automatic check(input logic [2:0] index, input logic booting);
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
        // Initial menu state.
        check(0,0);

        // DOWN navigation: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 0.
        for (int i = 1; i <= 6; i++) begin
            tap(1);
            check(3'(i),0);
        end

        tap(1);
        check(0,0);

        // UP navigation wraps from 0 to 6.
        tap(0);
        check(6,0);

        // Diagnostics is a separate menu entry, not CPU core 6.
        // SELECT on index 6 enters diagnostics.
        tap(2);
        @(negedge clk);
        if (!dut.diagnostics_active)
            $fatal(1, "Diagnostics did not activate");
        tests++;

        // BACK returns to the boot menu.
        tap(3);
        @(negedge clk);
        if (dut.diagnostics_active || !dut.menu_active)
            $fatal(1, "Diagnostics BACK failed");
        tests++;

        // Move from Diagnostics (6) to DCPU-16 (5).
        tap(0);
        check(5,0);

        // Unavailable CPU core must not boot.
        tap(2);
        check(5,0);

        // Navigation remains available.
        tap(0);
        check(4,0);

        // BACK in menu state does not change selection.
        tap(3);
        check(4,0);

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
        $display("PASS: Tutorial 009 six-core top integration (%0d checks)",tests);
        $finish;
    end
    initial begin
        #1000000; $fatal(1,"timeout");
    end
endmodule
