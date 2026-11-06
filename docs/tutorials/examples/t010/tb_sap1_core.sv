`timescale 1ns/1ps
module tb_sap1_core;
    logic clk = 0;
    logic rst = 1;
    logic step_en = 1;
    logic [7:0] out_port, acc_debug;
    logic out_valid, halted;
    logic [3:0] pc_debug;
    int output_events = 0;
    always #5 clk = ~clk;

    sap1_core dut (.*);

    initial begin
        repeat (2) @(negedge clk);
        rst = 0;
        // Freeze and confirm PC stays at reset value.
        step_en = 0;
        repeat (3) @(negedge clk);
        assert (pc_debug == 0 && !halted) else $fatal(1,"step_en freeze failed");
        step_en = 1;
        for (int i = 0; i < 20; i++) begin
            @(negedge clk);
            if (out_valid) begin
                output_events++;
                assert (out_port == 8'd11) else $fatal(1,"OUT=%0d expected 11",out_port);
            end
            if (halted) break;
        end
        assert (halted) else $fatal(1,"CPU did not halt");
        assert (output_events == 1) else $fatal(1,"OUT event count=%0d",output_events);
        assert (acc_debug == 8'd11) else $fatal(1,"ACC=%0d",acc_debug);
        assert (pc_debug == 4'd5) else $fatal(1,"PC=%0d",pc_debug);
        repeat (4) @(negedge clk);
        assert (halted && !out_valid && out_port == 8'd11)
            else $fatal(1,"HALT not stable");
        $display("PASS: Tutorial 010 SAP-1 executed 9 + 4 - 2 = 11, OUT once, HLT");
        $finish;
    end
    initial begin
        #10000;
        $fatal(1,"Simulation timeout");
    end
endmodule
