`timescale 1ns/1ps

module tb_t014_diagnostics_vga;

    logic [9:0] x = 0;
    logic [9:0] y = 0;
    logic video_active = 1;

    logic [15:0] raw_edges = 16'hA123;
    logic [15:0] accepted_edges = 16'hF234;
    logic [15:0] valid_frames = 16'h5678;
    logic [15:0] frame_errors = 16'h9ABC;
    logic [15:0] timeouts = 16'hDEF0;
    logic [7:0] scan_code = 8'hFA;

    logic [11:0] rgb;
    int passed = 0;

    keyboard_diagnostics_renderer dut (
        .x(x),
        .y(y),
        .video_active(video_active),
        .raw_edges(raw_edges),
        .accepted_edges(accepted_edges),
        .valid_frames(valid_frames),
        .frame_errors(frame_errors),
        .timeouts(timeouts),
        .scan_code(scan_code),
        .rgb(rgb)
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

    task automatic sample_char(
        input int line_no,
        input int column_no,
        input byte expected_ascii
    );
        x = 10'(64 + column_no * 8);
        y = 10'(128 + line_no * 24);
        #1;

        if (dut.ascii !== expected_ascii)
            $fatal(
                1,
                "Character mismatch line=%0d col=%0d got=%h expected=%h",
                line_no, column_no, dut.ascii, expected_ascii
            );

        passed++;
        $display(
            "PASS %0d: line=%0d col=%0d ASCII=%c",
            passed, line_no, column_no, expected_ascii
        );
    endtask

    initial begin
        // Title
        sample_char(0, 0, "P");
        sample_char(0, 1, "S");
        sample_char(0, 2, "2");
        sample_char(0, 23, "S");

        // Counter labels
        sample_char(1, 0, "R");
        sample_char(2, 0, "A");
        sample_char(3, 0, "V");
        sample_char(4, 0, "F");
        sample_char(5, 0, "T");
        sample_char(6, 0, "S");
        sample_char(7, 0, "B");

        // HEX values
        sample_char(1, 22, "A");
        sample_char(1, 23, "1");
        sample_char(1, 24, "2");
        sample_char(1, 25, "3");

        sample_char(2, 22, "F");
        sample_char(3, 22, "5");
        sample_char(4, 22, "9");
        sample_char(5, 22, "D");

        // 8-bit scan code: FA
        sample_char(6, 22, " ");
        sample_char(6, 23, " ");
        sample_char(6, 24, "F");
        sample_char(6, 25, "A");

        // Verify actual title glyph pixel: P, row 0, bit 6.
        x = 10'd65;
        y = 10'd128;
        #1;
        check(rgb == 12'h0FF, "Title pixel cyan");

        // Verify actual HEX glyph pixel: A row 0, bit 4.
        x = 10'(64 + 22 * 8 + 3);
        y = 10'd152;
        #1;
        check(rgb == 12'h0F8, "HEX value pixel green");

        // Verify ordinary label glyph: R row 0, bit 6.
        x = 10'd65;
        y = 10'd152;
        #1;
        check(rgb == 12'hAAF, "Label pixel light blue");

        // Verify BACK glyph: B row 0, bit 6.
        x = 10'd65;
        y = 10'd296;
        #1;
        check(rgb == 12'hFF0, "BACK pixel yellow");

        // Text line spacing.
        x = 10'd65;
        y = 10'd140;
        #1;
        check(rgb == 12'h001, "Line spacing background");

        // Outside diagnostics area.
        x = 10'd10;
        y = 10'd10;
        #1;
        check(rgb == 12'h000, "Outside area black");

        // Video blanking.
        x = 10'd65;
        y = 10'd128;
        video_active = 0;
        #1;
        check(rgb == 12'h000, "Inactive video black");

        // Dynamic update.
        video_active = 1;
        raw_edges = 16'hBEEF;
        sample_char(1, 22, "B");
        sample_char(1, 23, "E");
        sample_char(1, 24, "E");
        sample_char(1, 25, "F");

        $display("SUMMARY: %0d checks passed", passed);
        $finish;
    end

endmodule
