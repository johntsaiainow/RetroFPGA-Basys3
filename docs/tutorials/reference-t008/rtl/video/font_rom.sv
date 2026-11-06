`timescale 1ns/1ps

module font_rom (
    input  logic [7:0] ascii,
    input  logic [2:0] row,
    output logic [7:0] bitmap
);

    // 8x8 bitmap font.
    // Bit 7 is the leftmost pixel.
    // Bit 0 is the rightmost pixel.
    //
    // Supported characters:
    // A-Z, 0-9, space.

    always_comb begin
        bitmap = 8'h00;

        case (ascii)

            // Space
            8'h20: bitmap = 8'h00;

            // A
            8'h41: case (row)
                3'd0: bitmap = 8'h18;
                3'd1: bitmap = 8'h24;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h7E;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h42;
                default: bitmap = 8'h00;
            endcase

            // B
            8'h42: case (row)
                3'd0: bitmap = 8'h7C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h7C;
                default: bitmap = 8'h00;
            endcase

            // D
            8'h44: case (row)
                3'd0: bitmap = 8'h78;
                3'd1: bitmap = 8'h44;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h42;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h44;
                3'd6: bitmap = 8'h78;
                default: bitmap = 8'h00;
            endcase

            // E
            8'h45: case (row)
                3'd0: bitmap = 8'h7E;
                3'd1: bitmap = 8'h40;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h40;
                3'd5: bitmap = 8'h40;
                3'd6: bitmap = 8'h7E;
                default: bitmap = 8'h00;
            endcase

            // F
            8'h46: case (row)
                3'd0: bitmap = 8'h7E;
                3'd1: bitmap = 8'h40;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h40;
                3'd5: bitmap = 8'h40;
                3'd6: bitmap = 8'h40;
                default: bitmap = 8'h00;
            endcase

            // G
            8'h47: case (row)
                3'd0: bitmap = 8'h3C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h4E;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // I
            8'h49: case (row)
                3'd0: bitmap = 8'h3E;
                3'd1: bitmap = 8'h08;
                3'd2: bitmap = 8'h08;
                3'd3: bitmap = 8'h08;
                3'd4: bitmap = 8'h08;
                3'd5: bitmap = 8'h08;
                3'd6: bitmap = 8'h3E;
                default: bitmap = 8'h00;
            endcase

            // L
            8'h4C: case (row)
                3'd0: bitmap = 8'h40;
                3'd1: bitmap = 8'h40;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h40;
                3'd4: bitmap = 8'h40;
                3'd5: bitmap = 8'h40;
                3'd6: bitmap = 8'h7E;
                default: bitmap = 8'h00;
            endcase

            // M
            8'h4D: case (row)
                3'd0: bitmap = 8'h42;
                3'd1: bitmap = 8'h66;
                3'd2: bitmap = 8'h5A;
                3'd3: bitmap = 8'h5A;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h42;
                default: bitmap = 8'h00;
            endcase

            // N
            8'h4E: case (row)
                3'd0: bitmap = 8'h42;
                3'd1: bitmap = 8'h62;
                3'd2: bitmap = 8'h52;
                3'd3: bitmap = 8'h4A;
                3'd4: bitmap = 8'h46;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h42;
                default: bitmap = 8'h00;
            endcase

            // O
            8'h4F: case (row)
                3'd0: bitmap = 8'h3C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h42;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // P
            8'h50: case (row)
                3'd0: bitmap = 8'h7C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h40;
                3'd5: bitmap = 8'h40;
                3'd6: bitmap = 8'h40;
                default: bitmap = 8'h00;
            endcase

            // R
            8'h52: case (row)
                3'd0: bitmap = 8'h7C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h48;
                3'd5: bitmap = 8'h44;
                3'd6: bitmap = 8'h42;
                default: bitmap = 8'h00;
            endcase

            // S
            8'h53: case (row)
                3'd0: bitmap = 8'h3C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h3C;
                3'd4: bitmap = 8'h02;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // T
            8'h54: case (row)
                3'd0: bitmap = 8'h7F;
                3'd1: bitmap = 8'h08;
                3'd2: bitmap = 8'h08;
                3'd3: bitmap = 8'h08;
                3'd4: bitmap = 8'h08;
                3'd5: bitmap = 8'h08;
                3'd6: bitmap = 8'h08;
                default: bitmap = 8'h00;
            endcase

            // U
            8'h55: case (row)
                3'd0: bitmap = 8'h42;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h42;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // Y
            8'h59: case (row)
                3'd0: bitmap = 8'h41;
                3'd1: bitmap = 8'h22;
                3'd2: bitmap = 8'h14;
                3'd3: bitmap = 8'h08;
                3'd4: bitmap = 8'h08;
                3'd5: bitmap = 8'h08;
                3'd6: bitmap = 8'h08;
                default: bitmap = 8'h00;
            endcase

            // X
            8'h58: case (row)
                3'd0: bitmap = 8'h42;
                3'd1: bitmap = 8'h24;
                3'd2: bitmap = 8'h18;
                3'd3: bitmap = 8'h18;
                3'd4: bitmap = 8'h18;
                3'd5: bitmap = 8'h24;
                3'd6: bitmap = 8'h42;
                default: bitmap = 8'h00;
            endcase

            // Digits: 0
            8'h30: case (row)
                3'd0: bitmap = 8'h3C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h46;
                3'd3: bitmap = 8'h4A;
                3'd4: bitmap = 8'h52;
                3'd5: bitmap = 8'h62;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // 4
            8'h34: case (row)
                3'd0: bitmap = 8'h0C;
                3'd1: bitmap = 8'h14;
                3'd2: bitmap = 8'h24;
                3'd3: bitmap = 8'h44;
                3'd4: bitmap = 8'h7E;
                3'd5: bitmap = 8'h04;
                3'd6: bitmap = 8'h04;
                default: bitmap = 8'h00;
            endcase

            // 6
            8'h36: case (row)
                3'd0: bitmap = 8'h1C;
                3'd1: bitmap = 8'h20;
                3'd2: bitmap = 8'h40;
                3'd3: bitmap = 8'h7C;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            // 8
            8'h38: case (row)
                3'd0: bitmap = 8'h3C;
                3'd1: bitmap = 8'h42;
                3'd2: bitmap = 8'h42;
                3'd3: bitmap = 8'h3C;
                3'd4: bitmap = 8'h42;
                3'd5: bitmap = 8'h42;
                3'd6: bitmap = 8'h3C;
                default: bitmap = 8'h00;
            endcase

            default: bitmap = 8'h00;

        endcase
    end

endmodule
