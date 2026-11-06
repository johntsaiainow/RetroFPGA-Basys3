`timescale 1ns/1ps

module pixel_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       video_active,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b
);

    logic [11:0] rgb;

    // RGB444 color bar generator.
    //
    // Each bar occupies 80 horizontal pixels.
    // Eight bars cover the entire 640-pixel width.

    always_comb begin
        rgb = 12'h000;

        if (video_active && (y < 10'd480)) begin

            if (x < 10'd80)
                rgb = 12'hFFF;  // White

            else if (x < 10'd160)
                rgb = 12'hFF0;  // Yellow

            else if (x < 10'd240)
                rgb = 12'h0FF;  // Cyan

            else if (x < 10'd320)
                rgb = 12'h0F0;  // Green

            else if (x < 10'd400)
                rgb = 12'hF0F;  // Magenta

            else if (x < 10'd480)
                rgb = 12'hF00;  // Red

            else if (x < 10'd560)
                rgb = 12'h00F;  // Blue

            else if (x < 10'd640)
                rgb = 12'h000;  // Black
        end
    end

    assign vga_r = rgb[11:8];
    assign vga_g = rgb[7:4];
    assign vga_b = rgb[3:0];

endmodule
