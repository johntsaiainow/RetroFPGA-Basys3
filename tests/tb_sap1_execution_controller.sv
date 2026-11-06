`timescale 1ns/1ps

module tb_sap1_execution_controller;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst = 1;
    logic run_pressed = 0;
    logic pause_pressed = 0;
    logic step_pressed = 0;
    logic cpu_halted = 0;
    logic step_en;
    logic running;

    sap1_execution_controller dut (
        .clk(clk),
        .rst(rst),
        .run_pressed(run_pressed),
        .pause_pressed(pause_pressed),
        .step_pressed(step_pressed),
        .cpu_halted(cpu_halted),
        .step_en(step_en),
        .running(running)
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    task automatic check(
        input logic expected_step,
        input logic expected_running
    );
        if (step_en !== expected_step ||
            running !== expected_running) begin
            $fatal(1,
                "FAIL step=%b running=%b expected=%b/%b",
                step_en, running,
                expected_step, expected_running);
        end
    endtask

    initial begin
        tick();
        check(0, 0);

        @(negedge clk);
        rst = 0;
        step_pressed = 1;
        tick();
        check(1, 0);

        @(negedge clk);
        step_pressed = 0;

        tick();
        check(1, 0);

        tick();
        check(0, 0);

        $display("PASS: STEP advances exactly two cycles");

        @(negedge clk);
        run_pressed = 1;
        tick();
        check(1, 1);

        @(negedge clk);
        run_pressed = 0;
        repeat (3) begin
            tick();
            check(1, 1);
        end

        $display("PASS: RUN continuous execution");

        @(negedge clk);
        pause_pressed = 1;
        tick();
        check(0, 0);

        @(negedge clk);
        pause_pressed = 0;
        tick();
        check(0, 0);

        $display("PASS: PAUSE stops execution");

        @(negedge clk);
        cpu_halted = 1;
        tick();
        check(0, 0);

        @(negedge clk);
        run_pressed = 1;
        tick();
        check(0, 0);

        $display("PASS: HALT blocks execution");

        @(negedge clk);
        cpu_halted = 0;
        run_pressed = 0;
        rst = 1;
        tick();
        check(0, 0);

        $display("PASS: RESET");
        $display("=== TUTORIAL 012 CONTROLLER PASS ===");
        $finish;
    end

endmodule
