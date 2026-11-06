`timescale 1ns/1ps

module tb_sap1_t012_phase4;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst = 1;
    logic run_pressed = 0;
    logic pause_pressed = 0;
    logic step_pressed = 0;

    logic step_en, running, halted;
    logic [3:0] pc;
    logic [7:0] acc, out_port;
    logic out_valid;

    sap1_execution_controller #(
        .CLK_FREQ_HZ(100),
        .RUN_IPS(10)
    ) controller (
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

    task automatic press_step;
        @(negedge clk);
        step_pressed = 1;
        tick();

        @(negedge clk);
        step_pressed = 0;
        repeat (3) tick();
    endtask

    initial begin
        tick();

        @(negedge clk);
        rst = 0;

        // STEP: LDA 5
        press_step();

        if (pc != 1 || acc != 9)
            $fatal(1, "STEP failed PC=%0d ACC=%0d", pc, acc);

        $display("PASS: STEP executes LDA");

        // RUN: execute remaining instructions.
        @(negedge clk);
        run_pressed = 1;
        tick();

        @(negedge clk);
        run_pressed = 0;

        begin : wait_halt
            bit reached_halt;
            reached_halt = 0;

            for (int i = 0; i < 100; i++) begin
                tick();
                if (halted) begin
                    reached_halt = 1;
                    break;
                end
            end

            if (!reached_halt)
                $fatal(1, "RUN timeout");
        end

        if (pc != 5 || acc != 11 || out_port != 11)
            $fatal(1,
                "RUN failed PC=%0d ACC=%0d OUT=%0d",
                pc, acc, out_port);

        $display("PASS: RUN reaches HALT");
        $display("PASS: ACC=11 OUT=11");

        // RESET
        @(negedge clk);
        rst = 1;
        tick();

        if (pc != 0 || acc != 0 || halted)
            $fatal(1, "RESET failed");

        $display("PASS: RESET");
        $display("=== TUTORIAL 012 PHASE 4 PASS ===");
        $finish;
    end

endmodule
