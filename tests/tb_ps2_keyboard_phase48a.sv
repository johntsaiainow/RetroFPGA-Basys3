`timescale 1ns/1ps

module tb_ps2_keyboard_phase48a;
    logic unused_timeout_error;

    logic clk = 0;
    logic rst = 1;
    logic ps2_clk = 1;
    logic ps2_data = 1;

    wire [7:0] scan_code;
    wire scan_valid;
    wire frame_error;

    int valid_count = 0;
    int error_count = 0;
    int checks = 0;

    logic [7:0] last_code = 0;

    // 1 MHz simulation clock.
    always #50 clk <= ~clk;

    ps2_keyboard_receiver #(
        .CLK_FREQ_HZ(10_000_000),
        .FILTER_US(1),
        .TIMEOUT_US(2000)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .scan_code(scan_code),
        .scan_valid(scan_valid),
        .frame_error(frame_error),
        .timeout_error(unused_timeout_error)
    );

    always @(posedge clk) begin
        if (!rst) begin
            if (scan_valid) begin
                valid_count <= valid_count + 1;
                last_code <= scan_code;
            end

            if (frame_error)
                error_count <= error_count + 1;

            assert (!(scan_valid && frame_error))
                else $fatal(1, "Valid/error collision");
        end
    end

    task automatic wait_cycles(input int n);
        repeat (n) @(negedge clk);
    endtask

    task automatic send_bit(input logic value);
        ps2_data = value;
        wait_cycles(200);
        ps2_clk = 0;
        wait_cycles(200);
        ps2_clk = 1;
        wait_cycles(200);
    endtask

    task automatic send_frame(
        input logic [7:0] data,
        input logic bad_parity,
        input logic bad_stop
    );
        logic parity_bit;

        parity_bit = ~(^data);

        send_bit(1'b0);

        for (int i = 0; i < 8; i++)
            send_bit(data[i]);

        send_bit(parity_bit ^ bad_parity);
        send_bit(!bad_stop);

        ps2_data = 1;
        wait_cycles(300);
    endtask

    task automatic expect_result(
        input int expected_valid,
        input int expected_error,
        input logic [7:0] expected_code
    );
        checks++;

        assert (valid_count == expected_valid)
            else $fatal(1,
                "Valid count: expected %0d got %0d",
                expected_valid, valid_count);

        assert (error_count == expected_error)
            else $fatal(1,
                "Error count: expected %0d got %0d",
                expected_error, error_count);

        if (expected_valid > 0) begin
            assert (last_code == expected_code)
                else $fatal(1,
                    "Scan code: expected %02h got %02h",
                    expected_code, last_code);
        end
    endtask

    initial begin
        wait_cycles(10);
        rst = 0;
        wait_cycles(200);

        // A key make code.
        send_frame(8'h1C, 0, 0);
        expect_result(1, 0, 8'h1C);
        $display("PASS: A make code");

        // Break prefix and key release.
        send_frame(8'hF0, 0, 0);
        send_frame(8'h1C, 0, 0);
        expect_result(3, 0, 8'h1C);
        $display("PASS: Break sequence");

        // Invalid parity.
        send_frame(8'h32, 1, 0);
        expect_result(3, 1, 8'h1C);
        $display("PASS: Parity error");

        // Invalid stop bit.
        send_frame(8'h21, 0, 1);
        expect_result(3, 2, 8'h1C);
        $display("PASS: Stop bit error");

        // Clock glitch shorter than filter period.
        ps2_data = 0;
        ps2_clk = 0;
        wait_cycles(5);
        ps2_clk = 1;
        ps2_data = 1;
        wait_cycles(300);

        expect_result(3, 2, 8'h1C);
        $display("PASS: Clock glitch rejection");

        // Incomplete frame followed by timeout.
        send_bit(0);
        send_bit(1);
        send_bit(0);

        ps2_clk = 1;
        ps2_data = 1;

        wait_cycles(22000);
        expect_result(3, 3, 8'h1C);
        $display("PASS: Frame timeout");

        // Recovery after timeout.
        send_frame(8'h45, 0, 0);
        expect_result(4, 3, 8'h45);
        $display("PASS: Recovery after timeout");

        // Reset during partial reception.
        send_bit(0);
        send_bit(1);

        rst = 1;
        wait_cycles(10);
        rst = 0;

        ps2_clk = 1;
        ps2_data = 1;
        wait_cycles(300);

        send_frame(8'h16, 0, 0);
        expect_result(5, 3, 8'h16);
        $display("PASS: Reset recovery");

        $display("====================================");
        // Phase 4.8A: A clock pulse above the filter threshold
        // while data is high must not start a frame.
        ps2_data = 1;
        ps2_clk = 0;
        wait_cycles(25);
        ps2_clk = 1;
        wait_cycles(300);
        expect_result(5, 3, 8'h16);
        $display("PASS: Long idle clock pulse");

        // A long clock pulse with data low is accepted as a start.
        // With no further clock edges, a timeout must be reported.
        ps2_data = 0;
        ps2_clk = 0;
        wait_cycles(25);
        ps2_clk = 1;
        ps2_data = 1;
        wait_cycles(22000);
        expect_result(5, 4, 8'h16);
        $display("PASS: Long start glitch timeout");

        // The receiver must recover after the timeout.
        send_frame(8'h1C, 0, 0);
        expect_result(6, 4, 8'h1C);
        $display("PASS: Recovery after long glitch");

        $display("PASS: %0d protocol checkpoints", checks);
        $display("====================================");

        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "Simulation watchdog timeout");
    end

endmodule
