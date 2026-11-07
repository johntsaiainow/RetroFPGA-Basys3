`timescale 1ns/1ps

module tb_sap1_vga_decimal;

    logic [9:0] x, y;
    logic video_active;
    logic [3:0] pc;
    logic [7:0] acc, out_port;
    logic halted;
    logic [11:0] rgb;

    int checks = 0;

    sap1_vga_monitor dut (
        .x(x),
        .y(y),
        .video_active(video_active),
        .pc(pc),
        .acc(acc),
        .out_port(out_port),
        .halted(halted),
        .ir(8'h00),
        .running(1'b1),
        .rgb(rgb)
    );

    task automatic check_char(
        input int row_idx,
        input int col_idx,
        input byte expected
    );
        x = 10'(64 + col_idx * 16 + 2);
        y = 10'(80 + row_idx * 16 + 2);
        #1;

        if (dut.ascii !== expected) begin
            $fatal(1,
                "CHAR FAIL row=%0d col=%0d expected=%c got=%c",
                row_idx, col_idx, expected, dut.ascii
            );
        end

        checks++;
    endtask

    task automatic check_digits(
        input int row_idx,
        input int col_start,
        input int value,
        input int digits
    );
        int digit;
        int divisor;

        for (int i = 0; i < digits; i++) begin
            divisor = 1;

            for (int j = 0; j < digits - i - 1; j++)
                divisor *= 10;

            digit = (value / divisor) % 10;

            check_char(
                row_idx,
                col_start + i,
                byte'(32'h30 + digit)
            );
        end
    endtask

    initial begin
        x = 0;
        y = 0;
        video_active = 1;
        pc = 5;
        acc = 11;
        out_port = 11;
        halted = 0;

        #1;

        $display("=== Tutorial 013 Phase 3 ===");

        // Check decimal labels and initial values.
        check_char(3, 3, "D");
        check_char(3, 4, "E");
        check_char(3, 5, "C");

        check_digits(3, 8, 5, 2);
        check_digits(6, 9, 11, 3);
        check_digits(9, 9, 11, 3);

        $display("PASS: Initial decimal values");

        // Exhaustive ACC / OUT decimal display.
        for (int value = 0; value < 256; value++) begin
            acc = 8'(value);
            out_port = 8'(255 - value);

            check_digits(6, 9, value, 3);
            check_digits(9, 9, 255 - value, 3);
        end

        $display("PASS: ACC/OUT 256-value sweep");

        // All PC values.
        for (int value = 0; value < 16; value++) begin
            pc = 4'(value);
            check_digits(3, 8, value, 2);
        end

        $display("PASS: PC 0..15");

        // Verify selected HEX characters.
        acc = 8'hAB;
        out_port = 8'hFF;
        pc = 4'hF;

        check_char(5, 11, "A");
        check_char(5, 12, "B");
        check_char(8, 11, "F");
        check_char(8, 12, "F");
        check_char(2, 10, "F");

        $display("PASS: HEX display");

        // Verify HALT / RUN ASCII.
        halted = 1;
        check_char(11, 7, "H");
        check_char(11, 8, "A");
        check_char(11, 9, "L");
        check_char(11, 10, "T");

        halted = 0;
        check_char(11, 7, "R");
        check_char(11, 8, "U");
        check_char(11, 9, "N");

        $display("PASS: RUN/HALT labels");

        // Verify blanking.
        video_active = 0;
        x = 100;
        y = 100;
        #1;

        if (rgb !== 12'h000)
            $fatal(1, "VIDEO BLANKING FAIL rgb=%h", rgb);

        checks++;

        $display("PASS: Video blanking");

        // Verify background.
        video_active = 1;
        x = 10;
        y = 10;
        #1;

        if (rgb !== 12'h001)
            $fatal(1, "BACKGROUND FAIL rgb=%h", rgb);

        checks++;

        $display("PASS: Background");

        $display("====================================");
        $display("PASS: %0d VGA checks", checks);
        $display("====================================");

        $finish;
    end

endmodule
