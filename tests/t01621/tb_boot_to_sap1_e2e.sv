`timescale 1ns/1ps

module tb_boot_to_sap1_e2e;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst = 1;
    logic up_pressed = 0;
    logic down_pressed = 0;
    logic select_pressed = 0;
    logic back_pressed = 0;

    wire menu_up, menu_down, menu_select, menu_back;
    wire cpu_run, cpu_pause, cpu_step_pressed;
    wire [2:0] selected_index, boot_core;
    wire menu_active, boot_request, booting, diagnostics_active;
    wire sap_active, sap_reset, step_en, running;
    wire halted, out_valid;
    wire [3:0] pc;
    wire [7:0] acc, out_port;

    integer checks = 0;

    boot_menu_controller #(
        .IMPLEMENTED_CORES(6'b000001)
    ) menu (
        .clk(clk), .rst(rst),
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
        .cpu_step(cpu_step_pressed)
    );

    assign sap_active = booting && (boot_core == 3'd0);
    assign sap_reset = rst || !sap_active;

    sap1_execution_controller #(
        .CLK_FREQ_HZ(100),
        .RUN_IPS(10)
    ) execution_controller (
        .clk(clk), .rst(sap_reset),
        .run_pressed(cpu_run),
        .pause_pressed(cpu_pause),
        .step_pressed(cpu_step_pressed),
        .cpu_halted(halted),
        .step_en(step_en),
        .running(running)
    );

    sap1_core cpu (
        .clk(clk), .rst(sap_reset),
        .step_en(step_en),
        .out_port(out_port),
        .out_valid(out_valid),
        .halted(halted),
        .pc_debug(pc),
        .acc_debug(acc)
    );

    task automatic check(input logic condition, input string message);
        begin
            if (condition !== 1'b1) begin
                $display("FAIL: %s", message);
                $fatal(1);
            end
            checks++;
        end
    endtask

    task automatic press_select;
        begin
            @(negedge clk);
            select_pressed = 1;
            @(negedge clk);
            select_pressed = 0;
            #1;
        end
    endtask

    task automatic press_back;
        begin
            @(negedge clk);
            back_pressed = 1;
            @(negedge clk);
            back_pressed = 0;
            #1;
        end
    endtask

    task automatic press_down;
        begin
            @(negedge clk);
            down_pressed = 1;
            @(negedge clk);
            down_pressed = 0;
            #1;
        end
    endtask

    task automatic step_instruction;
        begin
            press_select();
            repeat (4) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        #1;

        check(menu_active, "Reset enters menu");
        check(sap_reset, "SAP-1 held in reset");

        press_select();
        check(booting, "SAP-1 selected");
        check(boot_core == 0, "SAP-1 core ID");
        check(!sap_reset, "SAP-1 reset released");

        @(posedge clk);
        #1;
        check(pc == 0, "PC starts at zero");

        step_instruction();
        check(pc == 1 && acc == 9, "LDA result");

        step_instruction();
        check(pc == 2 && acc == 13, "ADD result");

        step_instruction();
        check(pc == 3 && acc == 11, "SUB result");

        step_instruction();
        check(pc == 4 && out_port == 11, "OUT result");

        step_instruction();
        check(pc == 5 && halted, "HLT reached");

        press_back();
        check(menu_active, "ESC returns to menu");
        check(sap_reset, "SAP-1 reset reasserted");

        @(posedge clk);
        #1;
        check(pc == 0 && acc == 0, "CPU reset completed");

        press_select();
        check(booting, "SAP-1 rebooted");
        check(pc == 0, "Reboot starts at PC zero");

        press_back();
        @(posedge clk);
        #1;

        press_down();
        check(selected_index == 1, "Hack selected");

        press_select();
        check(menu_active, "Unavailable Hack rejected");
        check(sap_reset, "Unavailable core cannot start SAP-1");

        $display(
            "T016.21 BOOT-TO-SAP1 E2E: PASS (%0d checks)",
            checks
        );
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "T016.21 E2E simulation timeout");
    end

endmodule
