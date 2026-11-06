`timescale 1ns/1ps

// Four-row menu overlay. Font ROM remains unchanged from Tutorial 005.
module boot_menu_renderer (
    input  logic [9:0] x, y,
    input  logic video_active,
    input  logic [1:0] selected_index,
    input  logic menu_active,
    output logic [11:0] rgb,
    output logic opaque
);
    logic in_menu;
    logic [9:0] lx, ly;
    logic [1:0] line_index;
    logic [4:0] char_index;
    logic [2:0] glyph_row, glyph_col;
    logic [7:0] ascii, rom_bitmap, bitmap;
    logic glyph_pixel;
    logic selected;

    // Menu starts at (64,128); each row is 24 pixels tall.
    assign in_menu = video_active && x >= 10'd64 && x < 10'd224 &&
                     y >= 10'd128 && y < 10'd224;
    assign lx = x - 10'd64;
    assign ly = y - 10'd128;
    // Divide by 24 using four constant-range comparisons.
    always_comb begin
        if      (ly < 10'd24) line_index = 2'd0;
        else if (ly < 10'd48) line_index = 2'd1;
        else if (ly < 10'd72) line_index = 2'd2;
        else                 line_index = 2'd3;
    end
    assign char_index = lx[7:3];
    assign glyph_col = lx[2:0];
    // Text is drawn at the top of each 24-pixel row.
    // Each menu line is 24 pixels tall (a multiple of 8).
    // The low three bits therefore give the glyph row for every line.
    assign glyph_row = ly[2:0];

    always_comb begin
        ascii = " ";
        case (line_index)
            2'd0: case (char_index) // Z80
                0: ascii="Z"; 1: ascii="8"; 2: ascii="0";
                default: ascii=" "; endcase
            2'd1: case (char_index) // DCPU-16
                0: ascii="D"; 1: ascii="C"; 2: ascii="P";
                3: ascii="U"; 4: ascii="-"; 5: ascii="1";
                6: ascii="6"; default: ascii=" "; endcase
            2'd2: case (char_index) // NES
                0: ascii="N"; 1: ascii="E"; 2: ascii="S";
                default: ascii=" "; endcase
            2'd3: case (char_index) // GAME BOY
                0: ascii="G"; 1: ascii="A"; 2: ascii="M";
                3: ascii="E"; 4: ascii=" "; 5: ascii="B";
                6: ascii="O"; 7: ascii="Y";
                default: ascii=" "; endcase
        endcase
    end

    font_rom font (.ascii(ascii), .row(glyph_row), .bitmap(rom_bitmap));

    // Supply only the missing glyphs, without modifying Tutorial 005.
    always_comb begin
        bitmap = rom_bitmap;
        case (ascii)
            "Z": case (glyph_row)
                0: bitmap=8'h7e; 1: bitmap=8'h02; 2: bitmap=8'h04;
                3: bitmap=8'h08; 4: bitmap=8'h10; 5: bitmap=8'h20;
                6: bitmap=8'h7e; default: bitmap=0; endcase
            "C": case (glyph_row)
                0: bitmap=8'h3c; 1: bitmap=8'h42; 2: bitmap=8'h40;
                3: bitmap=8'h40; 4: bitmap=8'h40; 5: bitmap=8'h42;
                6: bitmap=8'h3c; default: bitmap=0; endcase
            "1": case (glyph_row)
                0: bitmap=8'h08; 1: bitmap=8'h18; 2: bitmap=8'h28;
                3: bitmap=8'h08; 4: bitmap=8'h08; 5: bitmap=8'h08;
                6: bitmap=8'h3e; default: bitmap=0; endcase
            "-": case (glyph_row)
                3: bitmap=8'h3c; default: bitmap=0; endcase
            default: ;
        endcase
    end
    assign glyph_pixel = bitmap[3'd7 - glyph_col] && ((ly % 10'd24) < 10'd8);
    assign selected = selected_index == line_index;
    always_comb begin
        opaque = in_menu;
        rgb = 12'h000;
        if (in_menu) begin
            if (selected && menu_active) rgb = 12'h024;
            else rgb = 12'h001;
            if (glyph_pixel) begin
                if (!menu_active) rgb = 12'hFA0;
                else if (selected) rgb = 12'hFF0;
                else rgb = 12'h0F8;
            end
        end
    end
endmodule
