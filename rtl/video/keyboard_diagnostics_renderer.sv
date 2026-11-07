`timescale 1ns/1ps

// RetroFPGA Tutorial 014 - Phase 4.9D.5
// PS/2 Keyboard Diagnostics VGA Renderer.

module keyboard_diagnostics_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic video_active,

    input  logic [15:0] raw_edges,
    input  logic [15:0] accepted_edges,
    input  logic [15:0] valid_frames,
    input  logic [15:0] frame_errors,
    input  logic [15:0] timeouts,
    input  logic [7:0]  scan_code,

    output logic [11:0] rgb
);

    localparam logic [9:0] TEXT_X = 10'd64;
    localparam logic [9:0] TEXT_Y = 10'd128;

    logic [8:0] lx;
    logic [9:0] ly;
    logic [3:0] line_index;
    logic [5:0] char_index;
    logic [2:0] glyph_row, glyph_col;

    logic [7:0] ascii;
    logic [7:0] bitmap;
    logic [15:0] value;
    logic [3:0] hex_digit;

    logic in_area;
    logic glyph_pixel;

    function automatic logic [7:0] hex_ascii(
        input logic [3:0] nibble
    );
        if (nibble < 4'd10)
            hex_ascii = 8'h30 + {4'b0000, nibble};
        else
            hex_ascii = 8'h41 + {4'b0000, (nibble - 4'd10)};
    endfunction

    assign in_area =
        video_active &&
        x >= TEXT_X && x < 10'd320 &&
        y >= TEXT_Y && y < 10'd320;

    assign lx = 9'(x - TEXT_X);
    assign ly = y - TEXT_Y;

    assign line_index = 4'(ly / 10'd24);
    assign char_index = lx[8:3];

    assign glyph_row = ly[2:0];
    assign glyph_col = lx[2:0];

    always_comb begin
        value = 16'h0000;

        case (line_index)
            4'd1: value = raw_edges;
            4'd2: value = accepted_edges;
            4'd3: value = valid_frames;
            4'd4: value = frame_errors;
            4'd5: value = timeouts;
            4'd6: value = {8'h00, scan_code};
            default: value = 16'h0000;
        endcase
    end

    always_comb begin
        hex_digit = 4'h0;

        case (char_index)
            6'd22: hex_digit = value[15:12];
            6'd23: hex_digit = value[11:8];
            6'd24: hex_digit = value[7:4];
            6'd25: hex_digit = value[3:0];
            default: hex_digit = 4'h0;
        endcase
    end

    always_comb begin
        ascii = " ";

        if (in_area) begin
            if ((line_index >= 4'd1) &&
                (line_index <= 4'd6) &&
                (char_index >= 6'd22) &&
                (char_index <= 6'd25)) begin

                if ((line_index == 4'd6) &&
                    (char_index < 6'd24))
                    ascii = " ";
                else
                    ascii = hex_ascii(hex_digit);

            end else begin
                case (line_index)

                    // PS2 KEYBOARD DIAGNOSTICS
                    4'd0: case (char_index)
                        0: ascii="P"; 1: ascii="S";
                        2: ascii="2"; 3: ascii=" ";
                        4: ascii="K"; 5: ascii="E";
                        6: ascii="Y"; 7: ascii="B";
                        8: ascii="O"; 9: ascii="A";
                        10: ascii="R"; 11: ascii="D";
                        12: ascii=" "; 13: ascii="D";
                        14: ascii="I"; 15: ascii="A";
                        16: ascii="G"; 17: ascii="N";
                        18: ascii="O"; 19: ascii="S";
                        20: ascii="T"; 21: ascii="I";
                        22: ascii="C"; 23: ascii="S";
                        default: ascii=" ";
                    endcase

                    // RAW EDGES
                    4'd1: case (char_index)
                        0: ascii="R"; 1: ascii="A";
                        2: ascii="W"; 3: ascii=" ";
                        4: ascii="E"; 5: ascii="D";
                        6: ascii="G"; 7: ascii="E";
                        8: ascii="S";
                        default: ascii=" ";
                    endcase

                    // ACCEPTED EDGES
                    4'd2: case (char_index)
                        0: ascii="A"; 1: ascii="C";
                        2: ascii="C"; 3: ascii="E";
                        4: ascii="P"; 5: ascii="T";
                        6: ascii="E"; 7: ascii="D";
                        8: ascii=" "; 9: ascii="E";
                        10: ascii="D"; 11: ascii="G";
                        12: ascii="E"; 13: ascii="S";
                        default: ascii=" ";
                    endcase

                    // VALID FRAMES
                    4'd3: case (char_index)
                        0: ascii="V"; 1: ascii="A";
                        2: ascii="L"; 3: ascii="I";
                        4: ascii="D"; 5: ascii=" ";
                        6: ascii="F"; 7: ascii="R";
                        8: ascii="A"; 9: ascii="M";
                        10: ascii="E"; 11: ascii="S";
                        default: ascii=" ";
                    endcase

                    // FRAME ERRORS
                    4'd4: case (char_index)
                        0: ascii="F"; 1: ascii="R";
                        2: ascii="A"; 3: ascii="M";
                        4: ascii="E"; 5: ascii=" ";
                        6: ascii="E"; 7: ascii="R";
                        8: ascii="R"; 9: ascii="O";
                        10: ascii="R"; 11: ascii="S";
                        default: ascii=" ";
                    endcase

                    // TIMEOUTS
                    4'd5: case (char_index)
                        0: ascii="T"; 1: ascii="I";
                        2: ascii="M"; 3: ascii="E";
                        4: ascii="O"; 5: ascii="U";
                        6: ascii="T"; 7: ascii="S";
                        default: ascii=" ";
                    endcase

                    // SCAN CODE
                    4'd6: case (char_index)
                        0: ascii="S"; 1: ascii="C";
                        2: ascii="A"; 3: ascii="N";
                        4: ascii=" "; 5: ascii="C";
                        6: ascii="O"; 7: ascii="D";
                        8: ascii="E";
                        default: ascii=" ";
                    endcase

                    // BACK TO MENU
                    4'd7: case (char_index)
                        0: ascii="B"; 1: ascii="A";
                        2: ascii="C"; 3: ascii="K";
                        4: ascii=" "; 5: ascii="T";
                        6: ascii="O"; 7: ascii=" ";
                        8: ascii="M"; 9: ascii="E";
                        10: ascii="N"; 11: ascii="U";
                        default: ascii=" ";
                    endcase

                    default: ascii=" ";
                endcase
            end
        end
    end

    font_rom font (
        .ascii(ascii),
        .row(glyph_row),
        .bitmap(bitmap)
    );

    assign glyph_pixel = bitmap[3'd7 - glyph_col] &&
                         ((ly % 10'd24) < 10'd8);

    always_comb begin
        rgb = 12'h000;

        if (in_area) begin
            rgb = 12'h001;

            if (glyph_pixel) begin
                if (line_index == 4'd0)
                    rgb = 12'h0FF;
                else if (line_index == 4'd7)
                    rgb = 12'hFF0;
                else if (char_index >= 6'd22)
                    rgb = 12'h0F8;
                else
                    rgb = 12'hAAF;
            end
        end
    end

endmodule
