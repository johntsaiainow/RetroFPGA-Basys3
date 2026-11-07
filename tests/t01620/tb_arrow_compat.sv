`timescale 1ns/1ps

module tb_arrow_compat;

    logic       key_valid;
    logic [7:0] key_code;
    logic       key_extended;
    logic       key_pressed;

    logic key_up;
    logic key_down;
    logic key_select;
    logic key_back;

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
        input logic [7:0] code,
        input logic ext,
        input logic pressed,
        input logic valid,
        input logic [3:0] expected
    );
        begin
            key_code     = code;
            key_extended = ext;
            key_pressed  = pressed;
            key_valid    = valid;

            #10;

            if ({key_up, key_down, key_select, key_back}
                !== expected) begin
                $display(
                    "FAIL code=%02h ext=%b pressed=%b valid=%b",
                    code, ext, pressed, valid
                );
                $fatal(1);
            end
        end
    endtask

    initial begin
        key_valid    = 0;
        key_code     = 0;
        key_extended = 0;
        key_pressed  = 0;

        // Up Arrow
        check(8'h75, 0, 1, 1, 4'b1000);
        check(8'h75, 1, 1, 1, 4'b1000);

        // Down Arrow
        check(8'h72, 0, 1, 1, 4'b0100);
        check(8'h72, 1, 1, 1, 4'b0100);

        // Enter / ESC
        check(8'h5A, 0, 1, 1, 4'b0010);
        check(8'h76, 0, 1, 1, 4'b0001);

        // Break events must not trigger menu actions
        check(8'h75, 0, 0, 1, 4'b0000);
        check(8'h75, 1, 0, 1, 4'b0000);
        check(8'h72, 0, 0, 1, 4'b0000);
        check(8'h72, 1, 0, 1, 4'b0000);

        // Invalid events
        check(8'h75, 0, 1, 0, 4'b0000);
        check(8'h72, 1, 1, 0, 4'b0000);

        // Unrecognized scan code
        check(8'h1C, 0, 1, 1, 4'b0000);

        $display("T016.20 ARROW COMPATIBILITY: PASS");
        $finish;
    end

endmodule
