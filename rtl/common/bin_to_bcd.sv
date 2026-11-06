`timescale 1ns/1ps

// Tutorial 013 - Phase 1
// Unsigned 8-bit binary to 3-digit BCD.
// Pure combinational Double Dabble (shift-and-add-3).
module bin_to_bcd (
    input  logic [7:0] binary,
    output logic [3:0] hundreds,
    output logic [3:0] tens,
    output logic [3:0] ones
);

    logic [19:0] shift_reg;

    always_comb begin
        shift_reg = {12'b0, binary};

        for (int i = 0; i < 8; i++) begin
            if (shift_reg[19:16] >= 4'd5)
                shift_reg[19:16] =
                    shift_reg[19:16] + 4'd3;

            if (shift_reg[15:12] >= 4'd5)
                shift_reg[15:12] =
                    shift_reg[15:12] + 4'd3;

            if (shift_reg[11:8] >= 4'd5)
                shift_reg[11:8] =
                    shift_reg[11:8] + 4'd3;

            shift_reg = shift_reg << 1;
        end

        hundreds = shift_reg[19:16];
        tens     = shift_reg[15:12];
        ones     = shift_reg[11:8];
    end

endmodule
