`timescale 1ns/1ps

module tb_t014_vga_mux;

    logic clk = 0;
    always #5 clk <= ~clk;

    logic btn_reset = 1;
    logic btn_up = 0;
    logic btn_down = 0;
    logic btn_select = 0;
    logic btn_back = 0;
    logic ps2_clk = 1;
    logic ps2_data = 1;

    logic [7:0] led_scan_code;
    logic led_valid_activity;
    logic led_error_activity;
    logic led_clock_activity;
    logic led_timeout_activity;
    logic hsync, vsync;
    logic [3:0] vga_r, vga_g, vga_b;
    logic [2:0] led_selected;
    logic led_booting;

    int passed = 0;

    retrofpga_top #(
        .DEBOUNCE_CLK_FREQ_HZ(100_000_000),
        .DEBOUNCE_MS(1)
    ) dut (
        .clk(clk),
        .btn_reset(btn_reset),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_select(btn_select),
        .btn_back(btn_back),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .led_scan_code(led_scan_code),
        .led_valid_activity(led_valid_activity),
        .led_error_activity(led_error_activity),
        .led_clock_activity(led_clock_activity),
        .led_timeout_activity(led_timeout_activity),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .led_selected(led_selected),
        .led_booting(led_booting)
    );

    task automatic check(
        input logic condition,
        input string description
    );
        if (!condition)
            $fatal(1, "FAIL: %s", description);

        passed++;
        $display("PASS %0d: %s", passed, description);
    endtask


    // PS/2: one bit per falling clock edge.
    task automatic send_ps2_bit(input logic data_bit);
        @(negedge clk);
        ps2_data = data_bit;

        repeat (200) @(negedge clk);
        ps2_clk = 0;

        repeat (2000) @(negedge clk);
        ps2_clk = 1;

        repeat (2000) @(negedge clk);
    endtask

    task automatic send_ps2_byte(input logic [7:0] data_byte);
        logic parity_bit;

        parity_bit = ~(^data_byte);

        send_ps2_bit(1'b0);

        for (int i = 0; i < 8; i++)
            send_ps2_bit(data_byte[i]);

        send_ps2_bit(parity_bit);
        send_ps2_bit(1'b1);
    endtask

    initial begin
        repeat (10) @(negedge clk);
        btn_reset = 0;

        repeat (10) @(negedge clk);

        check(dut.menu_active, "Boot Menu active after reset");
        check(!dut.diagnostics_active, "Diagnostics initially inactive");
        check(dut.ps2_raw_edges == 0, "Raw counter reset");
        check(dut.ps2_accepted_edges == 0, "Accepted counter reset");

        // One PS/2 clock falling edge, held low long enough
        // to pass the 1 us receiver filter.
        ps2_clk = 0;
        repeat (250) @(negedge clk);

        ps2_clk = 1;
        repeat (250) @(negedge clk);

        check(dut.ps2_raw_edges == 16'd1,
              "Raw PS/2 edge counted");

        check(dut.ps2_accepted_edges == 16'd1,
              "Filtered PS/2 edge accepted");

        check(dut.ps2_valid_frames == 0,
              "Incomplete frame not accepted as valid");

        check(dut.ps2_frame_errors == 0,
              "No immediate frame error");

        check(dut.ps2_timeouts == 0,
              "No immediate timeout");

        // Top-level output verification.
        check(led_scan_code == 8'h00,
              "Scan code LED remains zero without valid frame");

        check(!led_valid_activity,
              "Valid-frame activity LED remains inactive");

        check(!led_error_activity,
              "Frame-error activity LED remains inactive");

        check(led_clock_activity,
              "PS/2 clock activity LED detects clock transition");

        check(!led_timeout_activity,
              "Timeout activity LED remains inactive");

        check(hsync && vsync,
              "VGA sync outputs idle high at initial scan position");

        check({vga_r, vga_g, vga_b} === dut.final_rgb,
              "VGA RGB outputs match final mux");

        check(led_selected == 3'd0,
              "Selected architecture LED shows SAP-1");

        check(!led_booting,
              "Booting LED remains inactive");


        // Reset to clear the intentionally incomplete frame
        // used by Phase 9A.
        btn_reset = 1;
        repeat (10) @(negedge clk);
        btn_reset = 0;
        repeat (10) @(negedge clk);

        check(dut.ps2_raw_edges == 0,
              "9B counters reset before full frame");

        // Transmit PS/2 Make Code for A.
        send_ps2_byte(8'h1C);

        repeat (300) @(negedge clk);

        check(dut.ps2_raw_edges == 16'd11,
              "Full frame produces 11 raw clock edges");

        check(dut.ps2_accepted_edges == 16'd11,
              "Receiver accepts 11 filtered edges");

        check(dut.ps2_valid_frames == 16'd1,
              "Exactly one valid PS/2 frame");

        check(dut.ps2_frame_errors == 0,
              "No frame error for valid data");

        check(dut.ps2_timeouts == 0,
              "No timeout during complete frame");

        check(led_scan_code == 8'h1C,
              "Top Level latches scan code 0x1C");

        check(dut.diagnostics_renderer.scan_code == 8'h1C,
              "Scan code reaches VGA Diagnostics Renderer");

        check(!dut.diagnostics_active,
              "Keyboard reception does not change menu state");


        // Navigate from ID 0 to ID 6 (Diagnostics).
        // Debounce is 1 ms, so hold each press for > 1 ms.
        for (int i = 0; i < 6; i++) begin
            btn_down = 1;
            repeat (120_000) @(negedge clk);
            btn_down = 0;
            repeat (120_000) @(negedge clk);
        end

        check(led_selected == 3'd6,
              "Boot Menu selects Diagnostics ID 6");

        btn_select = 1;
        repeat (120_000) @(negedge clk);
        btn_select = 0;
        repeat (120_000) @(negedge clk);

        check(dut.diagnostics_active,
              "SELECT enters Diagnostics mode");

        check(!led_booting,
              "Diagnostics does not boot a CPU");

        check({vga_r, vga_g, vga_b} === dut.diagnostics_rgb,
              "VGA MUX selects Diagnostics RGB");

        check(dut.diagnostics_renderer.scan_code == 8'h1C,
              "Diagnostics retains received scan code");

        btn_back = 1;
        repeat (120_000) @(negedge clk);
        btn_back = 0;
        repeat (120_000) @(negedge clk);

        check(dut.menu_active,
              "BACK returns to Boot Menu");

        check(!dut.diagnostics_active,
              "Diagnostics mode exits after BACK");

        check(led_selected == 3'd6,
              "Menu selection preserved after BACK");

        $display("SUMMARY: %0d checks passed", passed);
        $finish;
    end

endmodule
