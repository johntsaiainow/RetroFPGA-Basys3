`timescale 1ns/1ps
module sap1_vga_monitor (
    input logic [9:0] x, y,
    input logic video_active,
    input logic [3:0] pc,
    input logic [7:0] acc, out_port,
    input logic halted,
    output logic [11:0] rgb
);
    logic [7:0] ascii, bitmap;
    logic [5:0] col;
    logic [3:0] row;
    logic [2:0] glyph_x, glyph_y;
    logic inside_monitor;

    logic [3:0] acc_h, acc_t, acc_o;
    logic [3:0] out_h, out_t, out_o;
    logic [3:0] pc_t, pc_o;

    bin_to_bcd acc_converter (
        .binary(acc),
        .hundreds(acc_h),
        .tens(acc_t),
        .ones(acc_o)
    );

    bin_to_bcd out_converter (
        .binary(out_port),
        .hundreds(out_h),
        .tens(out_t),
        .ones(out_o)
    );

    bin_to_bcd pc_converter (
        .binary({4'b0000, pc}),
        .hundreds(),
        .tens(pc_t),
        .ones(pc_o)
    );

    function automatic logic [7:0] dec_ascii(
        input logic [3:0] digit
    );
        return 8'h30 + {4'b0000, digit};
    endfunction

    function automatic logic [7:0] hex_ascii(input logic [3:0] n);
        if (n < 10) return 8'h30 + {4'b0,n};
        return 8'h41 + {4'b0,(n - 4'd10)};
    endfunction
    // Text grid: 2x pixels, 16x16 cells, at (64,80).
    always_comb begin
        inside_monitor = video_active && x >= 10'd64 && x < 10'd448 &&
                 y >= 10'd80 && y < 10'd320;
        col = 6'((x - 10'd64) >> 4);
        row = 4'((y - 10'd80) >> 4);
        glyph_x = 3'((x - 10'd64) >> 1);
        glyph_y = 3'((y - 10'd80) >> 1);
        ascii = " ";

        case (row)
            0: case (col)
                0: ascii="S"; 1: ascii="A"; 2: ascii="P";
                3: ascii="-"; 4: ascii="1";
                6: ascii="C"; 7: ascii="P"; 8: ascii="U";
                default: ascii=" ";
            endcase

            2: case (col)
                0: ascii="P"; 1: ascii="C";
                3: ascii="H"; 4: ascii="E"; 5: ascii="X";
                6: ascii=":";
                8: ascii="0"; 9: ascii="X";
                10: ascii=hex_ascii(pc);
                default: ascii=" ";
            endcase

            3: case (col)
                0: ascii="P"; 1: ascii="C";
                3: ascii="D"; 4: ascii="E"; 5: ascii="C";
                6: ascii=":";
                8: ascii=dec_ascii(pc_t);
                9: ascii=dec_ascii(pc_o);
                default: ascii=" ";
            endcase

            5: case (col)
                0: ascii="A"; 1: ascii="C"; 2: ascii="C";
                4: ascii="H"; 5: ascii="E"; 6: ascii="X";
                7: ascii=":";
                9: ascii="0"; 10: ascii="X";
                11: ascii=hex_ascii(acc[7:4]);
                12: ascii=hex_ascii(acc[3:0]);
                default: ascii=" ";
            endcase

            6: case (col)
                0: ascii="A"; 1: ascii="C"; 2: ascii="C";
                4: ascii="D"; 5: ascii="E"; 6: ascii="C";
                7: ascii=":";
                9:  ascii=dec_ascii(acc_h);
                10: ascii=dec_ascii(acc_t);
                11: ascii=dec_ascii(acc_o);
                default: ascii=" ";
            endcase

            8: case (col)
                0: ascii="O"; 1: ascii="U"; 2: ascii="T";
                4: ascii="H"; 5: ascii="E"; 6: ascii="X";
                7: ascii=":";
                9: ascii="0"; 10: ascii="X";
                11: ascii=hex_ascii(out_port[7:4]);
                12: ascii=hex_ascii(out_port[3:0]);
                default: ascii=" ";
            endcase

            9: case (col)
                0: ascii="O"; 1: ascii="U"; 2: ascii="T";
                4: ascii="D"; 5: ascii="E"; 6: ascii="C";
                7: ascii=":";
                9:  ascii=dec_ascii(out_h);
                10: ascii=dec_ascii(out_t);
                11: ascii=dec_ascii(out_o);
                default: ascii=" ";
            endcase

            11: case (col)
                0: ascii="S"; 1: ascii="T"; 2: ascii="A";
                3: ascii="T"; 4: ascii="E"; 5: ascii=":";
                7:  ascii=halted ? "H" : "R";
                8:  ascii=halted ? "A" : "U";
                9:  ascii=halted ? "L" : "N";
                10: ascii=halted ? "T" : " ";
                default: ascii=" ";
            endcase

            13: case (col)
                0: ascii="B"; 1: ascii="A"; 2: ascii="C";
                3: ascii="K";
                5: ascii="T"; 6: ascii="O";
                8: ascii="M"; 9: ascii="E";
                10: ascii="N"; 11: ascii="U";
                default: ascii=" ";
            endcase

            default: ascii=" ";
        endcase
    end
    // Complete small uppercase/digit font for monitor, avoiding dependency on
    // the Tutorial 005 ROM's incomplete glyph set.
    always_comb begin
        bitmap = 8'h00;
        case (ascii)
            "A": case(glyph_y) 0:bitmap=8'h18;1:bitmap=8'h24;2:bitmap=8'h42;3:bitmap=8'h7e;4,5,6:bitmap=8'h42;default:;endcase
            "B": case(glyph_y) 0,3,6:bitmap=8'h7c;1,2,4,5:bitmap=8'h42;default:;endcase
            "C": case(glyph_y) 0,6:bitmap=8'h3c;1,5:bitmap=8'h42;2,3,4:bitmap=8'h40;default:;endcase
            "E": case(glyph_y) 0,3,6:bitmap=8'h7e;1,2,4,5:bitmap=8'h40;default:;endcase
            "H": case(glyph_y) 3:bitmap=8'h7e;0,1,2,4,5,6:bitmap=8'h42;default:;endcase
            "K": case(glyph_y) 0:bitmap=8'h44;1:bitmap=8'h48;2:bitmap=8'h50;3:bitmap=8'h60;4:bitmap=8'h50;5:bitmap=8'h48;6:bitmap=8'h44;default:;endcase
            "L": case(glyph_y) 6:bitmap=8'h7e;0,1,2,3,4,5:bitmap=8'h40;default:;endcase
            "M": case(glyph_y) 0,4,5,6:bitmap=8'h42;1:bitmap=8'h66;2,3:bitmap=8'h5a;default:;endcase
            "N": case(glyph_y) 0,6:bitmap=8'h42;1:bitmap=8'h62;2:bitmap=8'h52;3:bitmap=8'h4a;4:bitmap=8'h46;5:bitmap=8'h42;default:;endcase
            "O": case(glyph_y) 0,6:bitmap=8'h3c;1,2,3,4,5:bitmap=8'h42;default:;endcase
            "P": case(glyph_y) 0,3:bitmap=8'h7c;1,2:bitmap=8'h42;4,5,6:bitmap=8'h40;default:;endcase
            "R": case(glyph_y) 0,3:bitmap=8'h7c;1,2,6:bitmap=8'h42;4:bitmap=8'h48;5:bitmap=8'h44;default:;endcase
            "S": case(glyph_y) 0,3,6:bitmap=8'h3c;1:bitmap=8'h42;2:bitmap=8'h40;4:bitmap=8'h02;5:bitmap=8'h42;default:;endcase
            "T": case(glyph_y) 0:bitmap=8'h7f;1,2,3,4,5,6:bitmap=8'h08;default:;endcase
            "U": case(glyph_y) 0,1,2,3,4,5:bitmap=8'h42;6:bitmap=8'h3c;default:;endcase
            "X": case(glyph_y) 0,6:bitmap=8'h42;1,5:bitmap=8'h24;2,3,4:bitmap=8'h18;default:;endcase
            "0": case(glyph_y) 0,6:bitmap=8'h3c;1,2,3,4,5:bitmap=8'h42;default:;endcase
            "1": case(glyph_y) 0:bitmap=8'h08;1:bitmap=8'h18;2:bitmap=8'h28;3,4,5:bitmap=8'h08;6:bitmap=8'h3e;default:;endcase
            "2": case(glyph_y) 0:bitmap=8'h3c;1:bitmap=8'h42;2:bitmap=8'h02;3:bitmap=8'h0c;4:bitmap=8'h30;5:bitmap=8'h40;6:bitmap=8'h7e;default:;endcase
            "3": case(glyph_y) 0,6:bitmap=8'h3c;1,4:bitmap=8'h42;2,5:bitmap=8'h02;3:bitmap=8'h1c;default:;endcase
            "4": case(glyph_y) 0:bitmap=8'h0c;1:bitmap=8'h14;2:bitmap=8'h24;3:bitmap=8'h44;4:bitmap=8'h7e;5,6:bitmap=8'h04;default:;endcase
            "5": case(glyph_y) 0:bitmap=8'h7e;1:bitmap=8'h40;2:bitmap=8'h7c;3,4:bitmap=8'h02;5:bitmap=8'h42;6:bitmap=8'h3c;default:;endcase
            "6": case(glyph_y) 0:bitmap=8'h1c;1:bitmap=8'h20;2:bitmap=8'h40;3:bitmap=8'h7c;4,5:bitmap=8'h42;6:bitmap=8'h3c;default:;endcase
            "7": case(glyph_y) 0:bitmap=8'h7e;1:bitmap=8'h02;2:bitmap=8'h04;3,4:bitmap=8'h08;5,6:bitmap=8'h10;default:;endcase
            "8": case(glyph_y) 0,3,6:bitmap=8'h3c;1,2,4,5:bitmap=8'h42;default:;endcase
            "9": case(glyph_y) 0:bitmap=8'h3c;1,2:bitmap=8'h42;3:bitmap=8'h3e;4:bitmap=8'h02;5:bitmap=8'h04;6:bitmap=8'h38;default:;endcase
            "D": case(glyph_y) 0,6:bitmap=8'h78;1,5:bitmap=8'h44;2,3,4:bitmap=8'h42;default:;endcase
            "F": case(glyph_y) 0:bitmap=8'h7e;1,2,4,5,6:bitmap=8'h40;3:bitmap=8'h7c;default:;endcase
            ":": case(glyph_y) 2,5:bitmap=8'h18;default:;endcase
            "-": case(glyph_y) 3:bitmap=8'h3c;default:;endcase
            default: bitmap=8'h00;
        endcase
    end
    always_comb begin
        rgb = 12'h001;
        if (inside_monitor && bitmap[3'd7-glyph_x]) rgb = (row == 4'd11) ? 12'hFF0 : 12'h0F8;
        if (!video_active) rgb = 12'h000;
    end
endmodule
