`timescale 1ns/1ps

// RetroFPGA Tutorial 009
// Seven-row VGA boot menu, 8x8 glyphs, 24-pixel row pitch.

module boot_menu_renderer (
    input  logic [9:0] x, y,
    input  logic video_active,
    input  logic [2:0] selected_index,
    input  logic menu_active,
    output logic [11:0] rgb,
    output logic opaque
);

    logic in_menu;
    logic [7:0] lx;
    logic [9:0] ly;
    logic [2:0] line_index;
    logic [4:0] char_index;
    logic [2:0] glyph_row, glyph_col;
    logic [7:0] ascii, rom_bitmap, bitmap;
    logic glyph_pixel, selected;

    assign in_menu = video_active &&
                     x >= 10'd64 && x < 10'd224 &&
                     y >= 10'd128 && y < 10'd296;

    assign lx = x[7:0] - 8'd64;
    assign ly = y - 10'd128;

    always_comb begin
        if      (ly < 10'd24)  line_index = 3'd0;
        else if (ly < 10'd48)  line_index = 3'd1;
        else if (ly < 10'd72)  line_index = 3'd2;
        else if (ly < 10'd96)  line_index = 3'd3;
        else if (ly < 10'd120) line_index = 3'd4;
        else if (ly < 10'd144) line_index = 3'd5;
        else                   line_index = 3'd6;
    end

    assign char_index = lx[7:3];
    assign glyph_col  = lx[2:0];
    assign glyph_row  = ly[2:0];

    // Each name is padded to 20 characters.
    always_comb begin
        ascii = " ";

        case (line_index)
            3'd0: case (char_index)
                0: ascii="S"; 1: ascii="A";
                2: ascii="P"; 3: ascii="-";
                4: ascii="1";
                default: ascii=" ";
            endcase

            3'd1: case (char_index)
                0: ascii="H"; 1: ascii="A";
                2: ascii="C"; 3: ascii="K";
                default: ascii=" ";
            endcase

            3'd2: case (char_index)
                0: ascii="M"; 1: ascii="O";
                2: ascii="S"; 3: ascii=" ";
                4: ascii="6"; 5: ascii="5";
                6: ascii="0"; 7: ascii="2";
                default: ascii=" ";
            endcase

            3'd3: case (char_index)
                0: ascii="Z"; 1: ascii="8";
                2: ascii="0";
                default: ascii=" ";
            endcase

            3'd4: case (char_index)
                0: ascii="M"; 1: ascii="6";
                2: ascii="8"; 3: ascii="0";
                4: ascii="0"; 5: ascii="0";
                default: ascii=" ";
            endcase

            3'd5: case (char_index)
                0: ascii="D"; 1: ascii="C";
                2: ascii="P"; 3: ascii="U";
                4: ascii="-"; 5: ascii="1";
                6: ascii="6";
                default: ascii=" ";
            endcase


            3'd6: case (char_index)
                0: ascii="K";  1: ascii="E";
                2: ascii="Y";  3: ascii="B";
                4: ascii="O";  5: ascii="A";
                6: ascii="R";  7: ascii="D";
                8: ascii=" ";  9: ascii="D";
                10: ascii="I"; 11: ascii="A";
                12: ascii="G"; 13: ascii="N";
                14: ascii="O"; 15: ascii="S";
                16: ascii="T"; 17: ascii="I";
                18: ascii="C"; 19: ascii="S";
                default: ascii=" ";
            endcase

            default: ascii=" ";
        endcase
    end

    font_rom font (
        .ascii(ascii),
        .row(glyph_row),
        .bitmap(rom_bitmap)
    );

    // Missing glyphs not supplied by Tutorial 005 font ROM.
    always_comb begin
        bitmap = rom_bitmap;

        case (ascii)
            "C": case (glyph_row)
                0: bitmap=8'h3c; 1: bitmap=8'h42;
                2: bitmap=8'h40; 3: bitmap=8'h40;
                4: bitmap=8'h40; 5: bitmap=8'h42;
                6: bitmap=8'h3c; default: bitmap=0;
            endcase

            "H": case (glyph_row)
                0,1,2,4,5,6: bitmap=8'h42;
                3: bitmap=8'h7e;
                default: bitmap=0;
            endcase

            "K": case (glyph_row)
                0: bitmap=8'h44; 1: bitmap=8'h48;
                2: bitmap=8'h50; 3: bitmap=8'h60;
                4: bitmap=8'h50; 5: bitmap=8'h48;
                6: bitmap=8'h44; default: bitmap=0;
            endcase

            "Z": case (glyph_row)
                0: bitmap=8'h7e; 1: bitmap=8'h02;
                2: bitmap=8'h04; 3: bitmap=8'h08;
                4: bitmap=8'h10; 5: bitmap=8'h20;
                6: bitmap=8'h7e; default: bitmap=0;
            endcase

            "1": case (glyph_row)
                0: bitmap=8'h08; 1: bitmap=8'h18;
                2: bitmap=8'h28; 3,4,5: bitmap=8'h08;
                6: bitmap=8'h3e; default: bitmap=0;
            endcase

            "2": case (glyph_row)
                0: bitmap=8'h3c; 1: bitmap=8'h42;
                2: bitmap=8'h02; 3: bitmap=8'h0c;
                4: bitmap=8'h30; 5: bitmap=8'h40;
                6: bitmap=8'h7e; default: bitmap=0;
            endcase

            "5": case (glyph_row)
                0: bitmap=8'h7e; 1: bitmap=8'h40;
                2: bitmap=8'h7c; 3: bitmap=8'h02;
                4: bitmap=8'h02; 5: bitmap=8'h42;
                6: bitmap=8'h3c; default: bitmap=0;
            endcase

            "-": case (glyph_row)
                3: bitmap=8'h3c;
                default: bitmap=0;
            endcase

            default: ;
        endcase
    end

    assign glyph_pixel =
        bitmap[3'd7 - glyph_col] &&
        ((ly % 10'd24) < 10'd8);

    assign selected = (selected_index == line_index);

    always_comb begin
        opaque = in_menu;
        rgb = 12'h000;

        if (in_menu) begin
            if (selected && menu_active)
                rgb = 12'h024;
            else
                rgb = 12'h001;

            if (glyph_pixel) begin
                if (!menu_active)
                    rgb = 12'hFA0;
                else if (selected)
                    rgb = 12'hFF0;
                else
                    rgb = 12'h0F8;
            end
        end
    end

endmodule
