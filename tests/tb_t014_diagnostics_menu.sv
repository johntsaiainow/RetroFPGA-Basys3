`timescale 1ns/1ps

module tb_t014_diagnostics_menu;

    logic clk = 0;
    always #5 clk <= ~clk;

    logic rst = 1;

    logic up_pressed = 0;
    logic down_pressed = 0;
    logic select_pressed = 0;
    logic back_pressed = 0;

    logic menu_up, menu_down, menu_select, menu_back;
    logic cpu_run, cpu_pause, cpu_step;

    logic [2:0] selected_index;
    logic [2:0] boot_core;
    logic menu_active;
    logic diagnostics_active;
    logic boot_request;
    logic booting;

    int passed = 0;

    retrofpga_input_router router (
        .menu_active(menu_active),
        .diagnostics_active(diagnostics_active),
        .up_pressed(up_pressed),
        .down_pressed(down_pressed),
        .select_pressed(select_pressed),
        .back_pressed(back_pressed),
        .menu_up(menu_up),
        .menu_down(menu_down),
        .menu_select(menu_select),
        .menu_back(menu_back),
        .cpu_run(cpu_run),
        .cpu_pause(cpu_pause),
        .cpu_step(cpu_step)
    );

    boot_menu_controller #(
        .IMPLEMENTED_CORES(6'b000001)
    ) controller (
        .clk(clk),
        .rst(rst),
        .up_pressed(menu_up),
        .down_pressed(menu_down),
        .select_pressed(menu_select),
        .back_pressed(menu_back),
        .selected_index(selected_index),
        .menu_active(menu_active),
        .boot_core(boot_core),
        .boot_request(boot_request),
        .booting(booting),
        .diagnostics_active(diagnostics_active)
    );

    task automatic check(
        input logic condition,
        input string message
    );
        if (!condition)
            $fatal(1, "FAIL: %s", message);

        passed++;
        $display("PASS %0d: %s", passed, message);
    endtask

    task automatic press_down;
        @(negedge clk);
        down_pressed = 1;
        @(negedge clk);
        down_pressed = 0;
    endtask

    task automatic press_up;
        @(negedge clk);
        up_pressed = 1;
        @(negedge clk);
        up_pressed = 0;
    endtask

    task automatic press_select;
        @(negedge clk);
        select_pressed = 1;
        @(negedge clk);
        select_pressed = 0;
    endtask

    task automatic press_back;
        @(negedge clk);
        back_pressed = 1;
        @(negedge clk);
        back_pressed = 0;
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);

        check(menu_active && selected_index == 3'd0,
              "Reset enters Boot Menu at ID 0");

        // Navigate to Diagnostics ID 6.
        repeat (6) press_down();

        check(selected_index == 3'd6,
              "DOWN selects Diagnostics ID 6");

        check(menu_active && !diagnostics_active,
              "Diagnostics not entered before SELECT");

        press_select();

        check(diagnostics_active && !menu_active,
              "SELECT enters Diagnostics");

        check(!booting,
              "Diagnostics does not boot a CPU");

        check(!boot_request,
              "Diagnostics does not issue a Boot Request");

        // Test CPU input isolation while in Diagnostics.
        @(negedge clk);
        up_pressed = 1;
        down_pressed = 1;
        select_pressed = 1;
        #1;

        check(!cpu_run && !cpu_pause && !cpu_step,
              "CPU controls isolated in Diagnostics");

        @(negedge clk);
        up_pressed = 0;
        down_pressed = 0;
        select_pressed = 0;

        press_back();

        check(menu_active && !diagnostics_active,
              "BACK returns to Boot Menu");

        check(selected_index == 3'd6,
              "Menu selection preserved after BACK");

        // Wrap from ID 6 to ID 0.
        press_down();

        check(selected_index == 3'd0,
              "DOWN wraps ID 6 to ID 0");

        // SAP-1 remains architecture ID 0.
        press_select();

        check(booting && boot_core == 3'd0,
              "SAP-1 still boots from ID 0");

        check(!diagnostics_active,
              "CPU boot does not activate Diagnostics");

        press_back();

        check(menu_active && !booting,
              "BACK exits SAP-1 to Boot Menu");

        // UP wraps ID 0 to ID 6.
        press_up();

        check(selected_index == 3'd6,
              "UP wraps ID 0 to Diagnostics ID 6");

        $display("SUMMARY: %0d checks passed", passed);
        $finish;
    end

endmodule
