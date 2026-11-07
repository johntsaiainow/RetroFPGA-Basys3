`timescale 1ns/1ps

module ps2_keyboard_menu_adapter (
    input  logic       key_valid,
    input  logic [7:0] key_code,
    input  logic       key_extended,
    input  logic       key_pressed,

    output logic       key_up,
    output logic       key_down,
    output logic       key_select,
    output logic       key_back
);

    always_comb begin
        key_up     = 1'b0;
        key_down   = 1'b0;
        key_select = 1'b0;
        key_back   = 1'b0;

        if (key_valid && key_pressed) begin
            if (key_extended) begin
                case (key_code)
                    8'h75: key_up   = 1'b1;
                    8'h72: key_down = 1'b1;
                    default: ;
                endcase
            end else begin
                case (key_code)
                    8'h75: key_up   = 1'b1;
                    8'h72: key_down = 1'b1;
                    8'h5A: key_select = 1'b1;
                    8'h76: key_back   = 1'b1;
                    default: ;
                endcase
            end
        end
    end

endmodule
