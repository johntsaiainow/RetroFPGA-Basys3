`timescale 1ns/1ps

module tb_ps2_keyboard_menu_adapter;

    logic key_valid = 0;
    logic [7:0] key_code = 0;
    logic key_extended = 0;
    logic key_pressed = 0;

    wire key_up, key_down, key_select, key_back;

    integer checks = 0;

    ps2_keyboard_menu_adapter dut (
        .key_valid(key_valid),
        .key_code(key_code),
        .key_extended(key_extended),
        .key_pressed(key_pressed),
        .key_up(key_up),
        .key_down(key_down),
        .key_select(key_select),
        .key_back(key_back)
    );

    task automatic check(
        input logic valid,
        input logic [7:0] code,
        input logic ext,
        input logic pressed,
        input logic [3:0] expected
    );
        begin
            key_valid    = valid;
            key_code     = code;
            key_extended = ext;
            key_pressed  = pressed;
            #1;

            if ({key_up, key_down, key_select, key_back}
                !== expected) begin
                $display("FAIL: code=%02h actual=%b expected=%b",
                    code,
                    {key_up, key_down, key_select, key_back},
                    expected);
                $fatal(1);
            end

            checks = checks + 1;
        end
    endtask

    initial begin
        check(1, 8'h75, 1, 1, 4'b1000);
        check(1, 8'h72, 1, 1, 4'b0100);
        check(1, 8'h5A, 0, 1, 4'b0010);
        check(1, 8'h76, 0, 1, 4'b0001);

        // Break events must not trigger menu actions.
        check(1, 8'h75, 1, 0, 4'b0000);
        check(1, 8'h72, 1, 0, 4'b0000);
        check(1, 8'h5A, 0, 0, 4'b0000);
        check(1, 8'h76, 0, 0, 4'b0000);

        // No valid event.
        check(0, 8'h75, 1, 1, 4'b0000);

        // Basys 3 compatibility: non-extended 75 is Up.
        check(1, 8'h75, 0, 1, 4'b1000);

        // Extended Enter is not ordinary Enter.
        check(1, 8'h5A, 1, 1, 4'b0000);

        // BAT does not produce menu actions.
        check(1, 8'hAA, 0, 1, 4'b0000);

        $display("=== T016 MENU ADAPTER PASS ===");
        $display("Checks: %0d", checks);
        $finish;
    end

endmodule
