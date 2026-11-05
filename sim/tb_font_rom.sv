`timescale 1ns/1ps

module tb_font_rom;

    logic [7:0] ascii;
    logic [2:0] row;
    logic [7:0] bitmap;

    int tests = 0;

    font_rom dut (
        .ascii(ascii),
        .row(row),
        .bitmap(bitmap)
    );

    task automatic check_row (
        input logic [7:0] test_ascii,
        input logic [2:0] test_row,
        input logic [7:0] expected
    );
        ascii = test_ascii;
        row = test_row;

        #1;

        if (bitmap !== expected) begin
            $fatal(1,
                "FAIL: ASCII=%02h row=%0d got=%02h expected=%02h",
                ascii, row, bitmap, expected
            );
        end

        tests++;
    endtask

    initial begin
        $display("RetroFPGA Tutorial 005");
        $display("Font ROM Test");

        // Letter A
        check_row("A", 3'd0, 8'h18);
        check_row("A", 3'd1, 8'h24);
        check_row("A", 3'd2, 8'h42);
        check_row("A", 3'd3, 8'h7E);
        check_row("A", 3'd4, 8'h42);
        check_row("A", 3'd5, 8'h42);
        check_row("A", 3'd6, 8'h42);
        check_row("A", 3'd7, 8'h00);

        // Letter R
        check_row("R", 3'd0, 8'h7C);
        check_row("R", 3'd3, 8'h7C);
        check_row("R", 3'd6, 8'h42);

        // Letter M
        check_row("M", 3'd0, 8'h42);
        check_row("M", 3'd2, 8'h5A);

        // Space and unsupported character
        check_row(" ", 3'd0, 8'h00);
        check_row(" ", 3'd7, 8'h00);
        check_row("?", 3'd0, 8'h00);

        $display("PASS: Font ROM verified");
        $display("Tests passed: %0d", tests);

        $finish;
    end

endmodule
