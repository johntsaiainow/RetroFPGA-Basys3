`timescale 1ns/1ps

module tb_ps2_edge_counters;

    logic clk = 0;
    logic rst = 1;
    logic ps2_clk = 1;
    logic accepted_edge = 0;
    logic scan_valid = 0;
    logic frame_error = 0;
    logic timeout_error = 0;

    wire [15:0] raw_edge_count;
    wire [15:0] accepted_edge_count;
    wire [15:0] valid_frame_count;
    wire [15:0] frame_error_count;
    wire [15:0] timeout_count;

    int tests_passed = 0;

    always #5 clk <= ~clk;

    ps2_edge_counters dut (
        .clk(clk),
        .rst(rst),
        .ps2_clk(ps2_clk),
        .accepted_edge(accepted_edge),
        .scan_valid(scan_valid),
        .frame_error(frame_error),
        .timeout_error(timeout_error),
        .raw_edge_count(raw_edge_count),
        .accepted_edge_count(accepted_edge_count),
        .valid_frame_count(valid_frame_count),
        .frame_error_count(frame_error_count),
        .timeout_count(timeout_count)
    );

    task automatic tick(input int cycles);
        repeat (cycles) @(negedge clk);
    endtask

    task automatic check_counts(
        input int raw_expected,
        input int accepted_expected,
        input int valid_expected,
        input int error_expected,
        input int timeout_expected
    );
        assert (int'(raw_edge_count) == raw_expected &&
                int'(accepted_edge_count) == accepted_expected &&
                int'(valid_frame_count) == valid_expected &&
                int'(frame_error_count) == error_expected &&
                int'(timeout_count) == timeout_expected)
        else $fatal(1,
            "COUNTER MISMATCH raw=%0d accepted=%0d valid=%0d error=%0d timeout=%0d",
            raw_edge_count, accepted_edge_count,
            valid_frame_count, frame_error_count,
            timeout_count);
    endtask

    task automatic send_raw_edge;
        ps2_clk = 0;
        tick(5);
        ps2_clk = 1;
        tick(5);
    endtask

    task automatic pulse_accepted;
        accepted_edge = 1;
        tick(1);
        accepted_edge = 0;
        tick(1);
    endtask

    task automatic pulse_valid;
        scan_valid = 1;
        tick(1);
        scan_valid = 0;
        tick(1);
    endtask

    task automatic pulse_error;
        frame_error = 1;
        tick(1);
        frame_error = 0;
        tick(1);
    endtask

    task automatic pulse_timeout;
        timeout_error = 1;
        tick(1);
        timeout_error = 0;
        tick(1);
    endtask

    initial begin
        $display("==================================");
        $display("Tutorial 014 Phase 4.9B");
        $display("PS/2 Edge Counter Regression");
        $display("==================================");

        tick(10);
        rst = 0;
        tick(5);

        // TEST 1: reset state
        check_counts(0, 0, 0, 0, 0);
        tests_passed++;
        $display("PASS 1: Reset");

        // TEST 2: raw edges
        repeat (11) send_raw_edge();
        check_counts(11, 0, 0, 0, 0);
        tests_passed++;
        $display("PASS 2: Raw edges = 11");

        // TEST 3: accepted edges
        repeat (11) pulse_accepted();
        check_counts(11, 11, 0, 0, 0);
        tests_passed++;
        $display("PASS 3: Accepted edges = 11");

        // TEST 4: valid frame
        pulse_valid();
        check_counts(11, 11, 1, 0, 0);
        tests_passed++;
        $display("PASS 4: Valid frame");

        // TEST 5: frame error and timeout
        pulse_error();
        pulse_timeout();
        check_counts(11, 11, 1, 1, 1);
        tests_passed++;
        $display("PASS 5: Error counters");

        // TEST 6: extra raw edge, no accepted edge
        send_raw_edge();
        check_counts(12, 11, 1, 1, 1);
        tests_passed++;
        $display("PASS 6: Raw/accepted divergence");

        // TEST 7: reset all counters
        rst = 1;
        tick(5);
        rst = 0;
        tick(5);
        check_counts(0, 0, 0, 0, 0);
        tests_passed++;
        $display("PASS 7: Reset recovery");

        $display("==================================");
        $display("SUMMARY: %0d/7 PASS", tests_passed);
        $display("==================================");

        assert (tests_passed == 7)
            else $fatal(1, "Incomplete regression");

        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Simulation watchdog timeout");
    end

endmodule
