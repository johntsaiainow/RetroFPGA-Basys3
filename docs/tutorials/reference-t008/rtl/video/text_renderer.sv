`timescale 1ns/1ps


module text_renderer (
input  logic [9:0] x,
input  logic [9:0] y,
input  logic       video_active,

output logic [3:0] vga_r,
output logic [3:0] vga_g,
output logic [3:0] vga_b
);

localparam logic [9:0] TEXT_X = 10'd64;
localparam logic [9:0] TEXT_Y = 10'd64;

logic [9:0] local_x;
logic [9:0] local_y;

logic [7:0] ascii;
logic [7:0] bitmap;
logic [2:0] font_row;
logic [2:0] font_col;

logic [5:0] char_col;
logic [1:0] char_row;

logic pixel_on;
logic [11:0] rgb;

// Translate screen coordinates to text coordinates.
always_comb begin
local_x = 10'd0;
local_y = 10'd0;

if ((x >= TEXT_X) && (y >= TEXT_Y)) begin
local_x = x - TEXT_X;
local_y = y - TEXT_Y;
end
end

assign char_col = local_x[8:3];
assign char_row = local_y[4:3];

assign font_col = local_x[2:0];
assign font_row = local_y[2:0];

// Character selection.
always_comb begin
ascii = 8'h20;

if (video_active &&
(x >= TEXT_X) &&
(y >= TEXT_Y) &&
(local_x < 10'd160) &&
(local_y < 10'd32)) begin

            case (char_row)

// "RETRO FPGA BOOT MENU"
                2'd0: begin
                    case (char_col)
                        6'd0:  ascii = "R";
                        6'd1:  ascii = "E";
                        6'd2:  ascii = "T";
                        6'd3:  ascii = "R";
                        6'd4:  ascii = "O";
                        6'd5:  ascii = " ";
                        6'd6:  ascii = "F";
                        6'd7:  ascii = "P";
                        6'd8:  ascii = "G";
                        6'd9:  ascii = "A";
                        6'd10: ascii = " ";
                        6'd11: ascii = "B";
                        6'd12: ascii = "O";
                        6'd13: ascii = "O";
                        6'd14: ascii = "T";
                        6'd15: ascii = " ";
                        6'd16: ascii = "M";
                        6'd17: ascii = "E";
                        6'd18: ascii = "N";
                        6'd19: ascii = "U";
                        default: ascii = " ";
                    endcase
                end

// "SYSTEM READY"
                2'd2: begin
                    case (char_col)
                        6'd0:  ascii = "S";
                        6'd1:  ascii = "Y";
                        6'd2:  ascii = "S";
                        6'd3:  ascii = "T";
                        6'd4:  ascii = "E";
                        6'd5:  ascii = "M";
                        6'd6:  ascii = " ";
                        6'd7:  ascii = "R";
                        6'd8:  ascii = "E";
                        6'd9:  ascii = "A";
                        6'd10: ascii = "D";
                        6'd11: ascii = "Y";
                        default: ascii = " ";
                    endcase
                end

                default: ascii = " ";

endcase
        end
    end

font_rom font (
        .ascii(ascii),
        .row(font_row),
        .bitmap(bitmap)
    );

// Select one pixel from the current bitmap row.
    assign pixel_on = bitmap[3'd7 - font_col];

// RGB444 text colors.
    always_comb begin
        rgb = 12'h000;

if (video_active && pixel_on) begin
            if (char_row == 2'd0)
                rgb = 12'h0F8; // Green title
            else if (char_row == 2'd2)
                rgb = 12'hAAF; // Light blue status
        end
    end

assign vga_r = rgb[11:8];
    assign vga_g = rgb[7:4];
    assign vga_b = rgb[3:0];

endmodule
