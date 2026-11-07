`timescale 1ns/1ps
module ps2_trace_renderer (
    input logic [9:0] x, y,
    input logic video_active,
    input logic [127:0] history,
    input logic [4:0] entries,
    output logic overlay_active,
    output logic [11:0] rgb
);
    // 8 bytes per row; each byte takes 3 glyph columns.
    localparam logic [9:0] X0 = 10'd64;
    localparam logic [9:0] Y0 = 10'd344;
    logic [9:0] dx, dy;
    logic [4:0] char_col;
    logic [1:0] char_part;
    logic [2:0] glyph_col, glyph_row;
    logic [4:0] byte_index;
    logic [7:0] current_byte, ascii, bitmap;
    logic [3:0] nibble;
    logic glyph_pixel;
    function automatic logic [7:0] hex_ascii(input logic [3:0] n);
        if (n < 10) hex_ascii = 8'h30 + {4'b0,n};
        else hex_ascii = 8'h41 + {4'b0,(n-4'd10)};
    endfunction
    always_comb begin
        overlay_active = video_active && x >= X0 && x < X0 + 10'd192 &&
                         y >= Y0 && y < Y0 + 10'd48;
        dx = x - X0;
        dy = y - Y0;
        char_col = dx[7:3];
        glyph_col = dx[2:0];
        glyph_row = dy[2:0];
        char_part = 2'(char_col % 3);
        byte_index = 5'((dy >= 10'd24 ? 8 : 0) + (int'(char_col) / 3));
        current_byte = 8'h00;
        if (byte_index < 16)
            current_byte = history[8*byte_index +: 8];
        nibble = (char_part == 0) ? current_byte[7:4] : current_byte[3:0];
        ascii = 8'h20;
        if (byte_index < 16 && char_part < 2)
            ascii = (byte_index < entries) ? hex_ascii(nibble) : 8'h2D;
    end

    assign glyph_pixel = bitmap[3'd7 - glyph_col];

    always_comb begin
        rgb = 12'h000;
        if (overlay_active &&
            ((dy % 10'd24) < 10'd8) &&
            glyph_pixel)
            rgb = 12'h0F8;
    end

    font_rom font (
        .ascii(ascii),
        .row(glyph_row),
        .bitmap(bitmap)
    );
endmodule
