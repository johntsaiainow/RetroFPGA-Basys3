`timescale 1ns/1ps

module tb_sap1_execution_integration;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst = 1;
    logic run_pressed = 0;
    logic pause_pressed = 0;
    logic step_pressed = 0;

    logic step_en;
    logic running;
    logic halted;
    logic [3:0] pc;
    logic [7:0] acc;
    logic [7:0] out_port;
    logic out_valid;

    sap1_execution_controller controller (
        .clk(clk),
        .rst(rst),
        .run_pressed(run_pressed),
        .pause_pressed(pause_pressed),
        .step_pressed(step_pressed),
        .cpu_halted(halted),
        .step_en(step_en),
        .running(running)
    );

    sap1_core cpu (
        .clk(clk),
        .rst(rst),
        .step_en(step_en),
        .out_port(out_port),
        .out_valid(out_valid),
        .halted(halted),
        .pc_debug(pc),
        .acc_debug(acc)
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    task automatic check_cpu(
        input logic [3:0] expected_pc,
        input logic [7:0] expected_acc,
        input logic expected_halt
    );
        if (pc !== expected_pc ||
            acc !== expected_acc ||
            halted !== expected_halt) begin
            $fatal(1,
                "CPU FAIL PC=%h ACC=%h HALT=%b expected=%h/%h/%b",
                pc, acc, halted,
                expected_pc, expected_acc, expected_halt);
        end
    endtask

    task automatic step_instruction;
        @(negedge clk);
        step_pressed = 1;
        tick();

        @(negedge clk);
        step_pressed = 0;

        // Controller supplies exactly two CPU clock enables.
        repeat (3) tick();

        if (step_en !== 0 || running !== 0)
            $fatal(1, "CPU did not return to paused state");
    endtask

    initial begin
        tick();

        @(negedge clk);
        rst = 0;

        check_cpu(4'h0, 8'd0, 0);

        // Instruction 0: LDA 5 => ACC = 9
        step_instruction();
        check_cpu(4'h1, 8'd9, 0);
        $display("PASS: STEP 1 LDA => ACC=9");

        // Instruction 1: ADD 6 => ACC = 13
        step_instruction();
        check_cpu(4'h2, 8'd13, 0);
        $display("PASS: STEP 2 ADD => ACC=13");

        // Instruction 2: SUB 7 => ACC = 11
        step_instruction();
        check_cpu(4'h3, 8'd11, 0);
        $display("PASS: STEP 3 SUB => ACC=11");

        // Instruction 3: OUT => OUT = 11
        step_instruction();
        check_cpu(4'h4, 8'd11, 0);

        if (out_port !== 8'd11)
            $fatal(1, "OUT FAIL: %0d", out_port);

        $display("PASS: STEP 4 OUT => OUT=11");

        // Instruction 4: HLT
        step_instruction();
        check_cpu(4'h5, 8'd11, 1);
        $display("PASS: STEP 5 HLT");

        // RUN must not restart a halted CPU.
        @(negedge clk);
        run_pressed = 1;
        tick();

        @(negedge clk);
        run_pressed = 0;
        repeat (4) tick();

        check_cpu(4'h5, 8'd11, 1);
        $display("PASS: HALT prevents further execution");

        // Reset both controller and CPU.
        @(negedge clk);
        rst = 1;
        tick();

        check_cpu(4'h0, 8'd0, 0);

        if (running !== 0 || step_en !== 0)
            $fatal(1, "RESET controller failed");

        $display("PASS: CPU and controller RESET");

        $display("=== TUTORIAL 012 INTEGRATION PASS ===");
        $finish;
    end

endmodule
