`timescale 1ns/1ps

module tb_boot_menu_controller;

    logic clk = 1'b0;
    logic rst = 1'b1;

    logic up_pressed     = 1'b0;
    logic down_pressed   = 1'b0;
    logic select_pressed = 1'b0;
    logic back_pressed   = 1'b0;

    logic [1:0] selected_index;
    logic       menu_active;
    logic [1:0] boot_core;
    logic       boot_request;
    logic       booting;

    int tests = 0;
    int boot_events = 0;

    // 100 MHz simulation clock: 10 ns period.
    always #5 clk = ~clk;

    boot_menu_controller dut (
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
        .booting(booting)
    );

    // Generate VCD when compiled with --trace.
    initial begin
        $dumpfile("boot_menu_controller.vcd");
        $dumpvars(0, tb_boot_menu_controller);
    end

    // Drive inputs on falling edge, sample after rising edge.
    task automatic step(
        input logic up,
        input logic down,
        input logic sel,
        input logic back
    );
        @(negedge clk);

        up_pressed     = up;
        down_pressed   = down;
        select_pressed = sel;
        back_pressed   = back;

        @(posedge clk);
        #1;

        if (boot_request)
            boot_events++;

        if (menu_active === booting)
            $fatal(1, "Invalid FSM state indicators");
    endtask

    task automatic check(
        input logic [1:0] expected_index,
        input logic       expected_menu,
        input logic [1:0] expected_core,
        input logic       expected_request,
        input int         expected_events
    );
        if (selected_index !== expected_index)
            $fatal(1,
                "Index: got=%0d expected=%0d",
                selected_index, expected_index);

        if (menu_active !== expected_menu)
            $fatal(1,
                "Menu: got=%b expected=%b",
                menu_active, expected_menu);

        if (booting !== !expected_menu)
            $fatal(1, "Booting state mismatch");

        if (boot_core !== expected_core)
            $fatal(1,
                "Core: got=%0d expected=%0d",
                boot_core, expected_core);

        if (boot_request !== expected_request)
            $fatal(1,
                "Request: got=%b expected=%b",
                boot_request, expected_request);

        if (boot_events != expected_events)
            $fatal(1,
                "Events: got=%0d expected=%0d",
                boot_events, expected_events);

        tests++;
    endtask

    initial begin
        $display("RetroFPGA Tutorial 007");
        $display("Boot Menu Controller Test");

        // 1: Reset
        step(0, 0, 0, 0);
        check(2'd0, 1'b1, 2'd0, 1'b0, 0);

        // Release reset at a falling edge.
        @(negedge clk);
        rst = 1'b0;

        // 2: Idle
        step(0, 0, 0, 0);
        check(2'd0, 1'b1, 2'd0, 1'b0, 0);

        // 3: DOWN -> DCPU-16
        step(0, 1, 0, 0);
        check(2'd1, 1'b1, 2'd0, 1'b0, 0);

        // 4: DOWN -> NES
        step(0, 1, 0, 0);
        check(2'd2, 1'b1, 2'd0, 1'b0, 0);

        // 5: DOWN -> Game Boy
        step(0, 1, 0, 0);
        check(2'd3, 1'b1, 2'd0, 1'b0, 0);

        // 6: DOWN wraps -> Z80
        step(0, 1, 0, 0);
        check(2'd0, 1'b1, 2'd0, 1'b0, 0);

        // 7: UP wraps -> Game Boy
        step(1, 0, 0, 0);
        check(2'd3, 1'b1, 2'd0, 1'b0, 0);

        // 8: UP -> NES
        step(1, 0, 0, 0);
        check(2'd2, 1'b1, 2'd0, 1'b0, 0);

        // 9: SELECT -> Boot NES
        step(0, 0, 1, 0);
        check(2'd2, 1'b0, 2'd2, 1'b1, 1);

        // 10: Boot request clears
        step(0, 0, 0, 0);
        check(2'd2, 1'b0, 2'd2, 1'b0, 1);

        // 11: DOWN ignored during BOOTING
        step(0, 1, 0, 0);
        check(2'd2, 1'b0, 2'd2, 1'b0, 1);

        // 12: SELECT ignored during BOOTING
        step(0, 0, 1, 0);
        check(2'd2, 1'b0, 2'd2, 1'b0, 1);

        // 13: BACK -> MENU
        step(0, 0, 0, 1);
        check(2'd2, 1'b1, 2'd2, 1'b0, 1);

        // 14: UP -> DCPU-16
        step(1, 0, 0, 0);
        check(2'd1, 1'b1, 2'd2, 1'b0, 1);

        // 15: SELECT -> Boot DCPU-16
        step(0, 0, 1, 0);
        check(2'd1, 1'b0, 2'd1, 1'b1, 2);

        // 16: Request lasts one clock
        step(0, 0, 0, 0);
        check(2'd1, 1'b0, 2'd1, 1'b0, 2);

        // 17: BACK -> MENU
        step(0, 0, 0, 1);
        check(2'd1, 1'b1, 2'd1, 1'b0, 2);

        // 18: UP and DOWN together -> UP wins
        step(1, 1, 0, 0);
        check(2'd0, 1'b1, 2'd1, 1'b0, 2);

        // 19: SELECT and DOWN -> SELECT wins
        step(0, 1, 1, 0);
        check(2'd0, 1'b0, 2'd0, 1'b1, 3);

        // 20: No repeated boot request in BOOTING
        step(0, 0, 1, 0);
        check(2'd0, 1'b0, 2'd0, 1'b0, 3);

        $display("PASS: Boot Menu Controller verified");
        $display("Tests passed: %0d", tests);
        $display("Boot events: %0d", boot_events);

        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

endmodule
