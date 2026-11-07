`timescale 1ns/1ps

module tb_boot_menu_six;
    wire diagnostics_active;

    logic clk = 0;
    always #5 clk <= ~clk;

    logic rst = 1;
    logic up_pressed = 0;
    logic down_pressed = 0;
    logic select_pressed = 0;
    logic back_pressed = 0;

    logic [2:0] selected_index;
    logic menu_active;
    logic [2:0] boot_core;
    logic boot_request;
    logic booting;

    // Only SAP-1 is enabled for this test.
    boot_menu_controller #(
        .IMPLEMENTED_CORES(6'b000001)
    ) dut (
        .clk(clk),
        .rst(rst),
        .up_pressed(up_pressed),
        .down_pressed(down_pressed),
        .select_pressed(select_pressed),
        .back_pressed(back_pressed),
        .selected_index(selected_index),
        .menu_active(menu_active),
        .boot_core(boot_core),
        .boot_request(boot_request),
        .booting(booting),
        .diagnostics_active(diagnostics_active)
    );

    task automatic tick;
        @(posedge clk);
        #1;
        if (diagnostics_active && booting)
            $fatal(1, "Diagnostics and booting cannot both be active");
    endtask

    task automatic press_down;
        @(negedge clk);
        down_pressed = 1;
        tick();
        @(negedge clk);
        down_pressed = 0;
    endtask

    task automatic press_up;
        @(negedge clk);
        up_pressed = 1;
        tick();
        @(negedge clk);
        up_pressed = 0;
    endtask

    task automatic press_select;
        @(negedge clk);
        select_pressed = 1;
        tick();
        @(negedge clk);
        select_pressed = 0;
    endtask

    task automatic press_back;
        @(negedge clk);
        back_pressed = 1;
        tick();
        @(negedge clk);
        back_pressed = 0;
    endtask

    initial begin
        $display("RetroFPGA Tutorial 009 Controller Test");

        tick();
        @(negedge clk);
        rst = 0;
        tick();

        assert(selected_index == 0);
        assert(menu_active);

        // Six CPU architectures plus one Diagnostics entry.
        for (int i = 1; i <= 6; i++) begin
            press_down();
            assert(selected_index == 3'(i))
                else $fatal(1, "Navigation failed at %0d", i);
        end

        // Wrap 6 -> 0.
        press_down();
        assert(selected_index == 0)
            else $fatal(1, "Down wrap failed");

        // Wrap 0 -> 6.
        press_up();
        assert(selected_index == 6)
            else $fatal(1, "Up wrap failed");

        // Diagnostics is not a CPU core.
        press_select();
        assert(diagnostics_active && !menu_active &&
               !booting && !boot_request)
            else $fatal(1, "Diagnostics entry failed");

        // BACK returns from Diagnostics to the menu.
        press_back();
        assert(menu_active && !diagnostics_active && !booting)
            else $fatal(1, "Diagnostics BACK failed");

        // Move from Diagnostics (6) to DCPU-16 (5).
        press_up();
        assert(selected_index == 5)
            else $fatal(1, "DCPU-16 selection failed");

        // DCPU-16 is not implemented.
        press_select();
        assert(menu_active && !booting && !boot_request &&
               !diagnostics_active)
            else $fatal(1, "Unavailable core booted");

        // Return to SAP-1 through Diagnostics menu entry.
        press_down();
        assert(selected_index == 6);
        press_down();
        assert(selected_index == 0);

        // SAP-1 is enabled in this test configuration.
        press_select();
        assert(booting && boot_request && boot_core == 0)
            else $fatal(1, "SAP-1 boot failed");

        tick();
        assert(!boot_request)
            else $fatal(1, "Boot request was not one cycle");

        // BACK returns to menu.
        press_back();
        assert(menu_active && !booting)
            else $fatal(1, "BACK failed");

        $display("PASS: Tutorial 009 controller simulation");
        $finish;
    end

endmodule
