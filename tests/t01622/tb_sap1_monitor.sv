`timescale 1ns/1ps

module tb_sap1_monitor;

    logic [9:0] x = 0, y = 0;
    logic video_active = 1;
    logic [3:0] pc = 0;
    logic [7:0] acc = 0;
    logic [7:0] out_port = 0;
    logic [7:0] ir = 0;
    logic running = 0;
    logic halted = 0;
    wire [11:0] rgb;

    integer checks = 0;

    sap1_vga_monitor dut (
        .x(x),
        .y(y),
        .video_active(video_active),
        .pc(pc),
        .acc(acc),
        .out_port(out_port),
        .ir(ir),
        .running(running),
        .halted(halted),
        .rgb(rgb)
    );

    task automatic check_char(
        input integer r,
        input integer c,
        input logic [7:0] expected
    );
        begin
            x = 10'(64 + c * 16);
            y = 10'(80 + r * 16);
            #1;

            if (dut.ascii !== expected) begin
                $display(
                    "FAIL: row=%0d col=%0d expected=%c got=%c",
                    r, c, expected, dut.ascii
                );
                $fatal(1);
            end

            checks++;
        end
    endtask

    initial begin

        // IR = 00
        ir = 8'h00;
        check_char(4, 0, "I");
        check_char(4, 1, "R");
        check_char(4, 10, "0");
        check_char(4, 11, "0");

        // IR = 2F
        ir = 8'h2F;
        check_char(4, 10, "2");
        check_char(4, 11, "F");

        // IR = FF
        ir = 8'hFF;
        check_char(4, 10, "F");
        check_char(4, 11, "F");

        // RUN
        running = 1;
        halted = 0;
        check_char(11, 7, "R");
        check_char(11, 8, "U");
        check_char(11, 9, "N");

        // PAUSE
        running = 0;
        halted = 0;
        check_char(11, 7, "P");
        check_char(11, 8, "A");
        check_char(11, 9, "U");
        check_char(11, 10, "S");
        check_char(11, 11, "E");

        // HALT has priority over RUN
        running = 1;
        halted = 1;
        check_char(11, 7, "H");
        check_char(11, 8, "A");
        check_char(11, 9, "L");
        check_char(11, 10, "T");
        check_char(11, 11, " ");

        // Verify I glyph bitmap
        halted = 0;
        running = 0;
        check_char(4, 0, "I");

        x = 10'd64 + 10'd6;
        y = 10'd80 + 10'd64;
        #1;

        if (dut.bitmap === 8'h00)
            $fatal(1, "FAIL: I glyph bitmap empty");

        checks++;

        // VGA blanking
        video_active = 0;
        #1;

        if (rgb !== 12'h000)
            $fatal(1, "FAIL: VGA blanking");

        checks++;

        $display(
            "T016.22 VGA MONITOR: PASS (%0d checks)",
            checks
        );

        $finish;
    end

endmodule
