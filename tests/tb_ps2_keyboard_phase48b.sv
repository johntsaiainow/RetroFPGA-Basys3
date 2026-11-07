`timescale 1ns/1ps

module tb_ps2_keyboard_phase48b;

    // 10 MHz: one cycle = 100 ns.
    localparam int unsigned CLK_HZ = 10_000_000;
    localparam int HALF_PERIOD_NS = 50;

    logic clk = 0;
    logic rst = 1;
    logic ps2_clk = 1;
    logic ps2_data = 1;

    wire [7:0] scan_code;
    wire scan_valid;
    wire frame_error;
    wire timeout_error;

    int valid_count = 0;
    int error_count = 0;
    int timeout_count = 0;
    logic [7:0] last_code = 0;

    int cases_run = 0;
    int cases_valid = 0;
    int cases_failed = 0;

    always #(HALF_PERIOD_NS) clk <= ~clk;

    ps2_keyboard_receiver #(
        .CLK_FREQ_HZ(CLK_HZ),
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
        .timeout_error(timeout_error)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_count <= 0;
            error_count <= 0;
            timeout_count <= 0;
            last_code <= 0;
        end else begin
            if (scan_valid) begin
                valid_count <= valid_count + 1;
                last_code <= scan_code;
            end

            if (frame_error)
                error_count <= error_count + 1;

            if (timeout_error)
                timeout_count <= timeout_count + 1;

            assert (!(scan_valid && frame_error))
                else $fatal(1, "Valid/error collision");
        end
    end

    task automatic wait_cycles(input int n);
        repeat (n) @(negedge clk);
    endtask

    task automatic reset_receiver;
        rst = 1;
        ps2_clk = 1;
        ps2_data = 1;
        wait_cycles(20);
        rst = 0;
        wait_cycles(300);
    endtask

    // One PS/2 bit lasts 60 us:
    // Clock falls at t=20 us, rises at t=40 us.
    //
    // phase_cycles:
    //   negative = data changes before falling edge
    //   zero     = data changes at falling edge
    //   positive = data changes after falling edge
    //
    // 10 cycles = 1 us.
    task automatic send_bit_phase(
        input logic value,
        input int phase_cycles
    );
        int before_edge;
        int after_edge;

        before_edge = 200 + phase_cycles;

        if (before_edge < 0 || before_edge > 400)
            $fatal(1, "Phase outside supported range");

        if (phase_cycles <= 0) begin
            wait_cycles(before_edge);
            ps2_data = value;
            wait_cycles(-phase_cycles);
            ps2_clk = 0;
            wait_cycles(200);
        end else begin
            wait_cycles(200);
            ps2_clk = 0;
            wait_cycles(phase_cycles);
            ps2_data = value;
            after_edge = 200 - phase_cycles;
            wait_cycles(after_edge);
        end

        ps2_clk = 1;
        wait_cycles(200);
    endtask

    task automatic send_frame_phase(
        input logic [7:0] data,
        input int phase_cycles
    );
        logic parity_bit;

        parity_bit = ~(^data);

        send_bit_phase(1'b0, phase_cycles);

        for (int i = 0; i < 8; i++)
            send_bit_phase(data[i], phase_cycles);

        send_bit_phase(parity_bit, phase_cycles);
        send_bit_phase(1'b1, phase_cycles);

        ps2_data = 1;
        wait_cycles(300);
    endtask

    task automatic run_case(input int phase_cycles);
        logic passed;

        reset_receiver();
        send_frame_phase(8'h1C, phase_cycles);

        // Allow incomplete frames to time out.
        wait_cycles(23000);

        passed = (valid_count == 1) &&
                 (error_count == 0) &&
                 (timeout_count == 0) &&
                 (last_code == 8'h1C);

        cases_run++;

        if (passed) begin
            cases_valid++;
            $display(
                "PASS phase=%0d ns valid=%0d error=%0d timeout=%0d code=%02h",
                phase_cycles * 100,
                valid_count,
                error_count,
                timeout_count,
                last_code
            );
        end else begin
            cases_failed++;
            $display(
                "FAIL phase=%0d ns valid=%0d error=%0d timeout=%0d code=%02h",
                phase_cycles * 100,
                valid_count,
                error_count,
                timeout_count,
                last_code
            );
        end

        // The -20 us case is our required baseline.
        if (phase_cycles == -200)
            assert (passed)
                else $fatal(1, "Baseline phase failed");
    endtask

    initial begin
        $display("====================================");
        $display("Tutorial 014 Phase 4.8B");
        $display("Clock/Data Phase Margin Sweep");
        $display("====================================");

        run_case(-200); // -20 us
        run_case(-50);  //  -5 us
        run_case(-20);  //  -2 us
        run_case(-10);  //  -1 us
        run_case(-5);   //  -0.5 us
        run_case(0);    //   0 us
        run_case(5);    //  +0.5 us
        run_case(10);   //  +1 us
        run_case(20);   //  +2 us
        run_case(50);   //  +5 us

        $display("====================================");
        $display(
            "SUMMARY cases=%0d valid=%0d failed=%0d",
            cases_run, cases_valid, cases_failed
        );
        $display("====================================");

        assert (cases_run == 10)
            else $fatal(1, "Incomplete phase sweep");

        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "Simulation watchdog timeout");
    end

endmodule
