`timescale 1ns/1ps

module tb_core_selection;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst = 1;
    logic up_pressed = 0;
    logic down_pressed = 0;
    logic select_pressed = 0;
    logic back_pressed = 0;

    wire [2:0] selected_index;
    wire menu_active;
    wire [2:0] boot_core;
    wire boot_request;
    wire booting;
    wire diagnostics_active;

    integer checks = 0;

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

    task automatic check(input logic condition, input string message);
        begin
            if (condition !== 1'b1) begin
                $display("FAIL: %s", message);
                $fatal(1);
            end
            checks = checks + 1;
        end
    endtask

    task automatic press_up;
        @(negedge clk);
        up_pressed = 1;
        @(negedge clk);
        up_pressed = 0;
        #1;
    endtask

    task automatic press_down;
        @(negedge clk);
        down_pressed = 1;
        @(negedge clk);
        down_pressed = 0;
        #1;
    endtask

    task automatic press_select;
        @(negedge clk);
        select_pressed = 1;
        @(negedge clk);
        select_pressed = 0;
        #1;
    endtask

    task automatic press_back;
        @(negedge clk);
        back_pressed = 1;
        @(negedge clk);
        back_pressed = 0;
        #1;
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        #1;

        check(selected_index == 0, "Reset selection");
        check(menu_active, "Menu active after reset");

        // Test seven-entry navigation.
        for (integer i = 1; i <= 6; i++) begin
            press_down();
            check(selected_index == i, "Down navigation");
        end

        press_down();
        check(selected_index == 0, "Down wraps 6 to 0");

        press_up();
        check(selected_index == 6, "Up wraps 0 to 6");

        // Diagnostics selection.
        press_select();
        check(diagnostics_active, "Diagnostics entered");
        check(!boot_request, "Diagnostics does not boot CPU");

        press_back();
        check(menu_active, "ESC returns from diagnostics");
        check(selected_index == 6, "Selection preserved");

        // Unavailable CPU must not boot.
        press_up();
        check(selected_index == 5, "Select DCPU-16");

        press_select();
        check(menu_active, "Unavailable CPU stays in menu");
        check(!boot_request, "Unavailable CPU rejected");

        // Return to SAP-1.
        press_down();
        press_down();
        check(selected_index == 0, "Return to SAP-1");

        press_select();
        check(booting, "SAP-1 enters boot state");
        check(boot_core == 0, "SAP-1 boot ID");
        check(boot_request, "Boot request asserted");

        @(negedge clk);
        #1;
        check(!boot_request, "Boot request one-cycle pulse");

        press_back();
        check(menu_active, "ESC returns from booting");

        $display("T016.21 CORE SELECTION: PASS (%0d checks)", checks);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "T016.21 simulation timeout");
    end

endmodule
