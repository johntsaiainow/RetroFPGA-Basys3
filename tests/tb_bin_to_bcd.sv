`timescale 1ns/1ps

module tb_bin_to_bcd;

    logic [7:0] binary;
    logic [3:0] hundreds, tens, ones;

    int expected_h;
    int expected_t;
    int expected_o;
    int errors = 0;

    bin_to_bcd dut (
        .binary(binary),
        .hundreds(hundreds),
        .tens(tens),
        .ones(ones)
    );

    initial begin
        $display("====================================");
        $display("Tutorial 013 - Phase 1");
        $display("Binary-to-BCD Exhaustive Verification");
        $display("====================================");

        for (int value = 0; value < 256; value++) begin
            binary = 8'(value);

            expected_h = value / 100;
            expected_t = (value / 10) % 10;
            expected_o = value % 10;

            #1;

            if (int'(hundreds) != expected_h ||
                int'(tens)     != expected_t ||
                int'(ones)     != expected_o) begin

                $display(
                    "FAIL binary=%0d expected=%0d%0d%0d got=%0d%0d%0d",
                    value,
                    expected_h, expected_t, expected_o,
                    hundreds, tens, ones
                );

                errors++;
            end

            if (value == 0   ||
                value == 9   ||
                value == 10  ||
                value == 11  ||
                value == 99  ||
                value == 100 ||
                value == 255) begin

                $display(
                    "CHECK binary=%3d BCD=%0d%0d%0d",
                    value, hundreds, tens, ones
                );
            end
        end

        if (errors == 0) begin
            $display("====================================");
            $display("PASS: All 256 binary values verified");
            $display("====================================");
        end else begin
            $fatal(1, "FAIL: %0d conversion errors", errors);
        end

        $finish;
    end

endmodule
