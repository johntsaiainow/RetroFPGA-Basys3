`timescale 1ns/1ps

module vga_timing (
    input  logic       clk,
    input  logic       rst,
    input  logic       pixel_ce,

    output logic       hsync,
    output logic       vsync,
    output logic       video_active,

    output logic [9:0] x,
    output logic [9:0] y
);

    // VGA 640x480 timing
    // Horizontal: 640 + 16 + 96 + 48 = 800
    // Vertical:   480 + 10 +  2 + 33 = 525

    localparam logic [9:0] H_VISIBLE = 10'd640;
    localparam logic [9:0] H_FRONT   = 10'd16;
    localparam logic [9:0] H_SYNC    = 10'd96;
    localparam logic [9:0] H_BACK    = 10'd48;
    localparam logic [9:0] H_TOTAL   = 10'd800;

    localparam logic [9:0] V_VISIBLE = 10'd480;
    localparam logic [9:0] V_FRONT   = 10'd10;
    localparam logic [9:0] V_SYNC    = 10'd2;
    localparam logic [9:0] V_BACK    = 10'd33;
    localparam logic [9:0] V_TOTAL   = 10'd525;

    logic [9:0] h_count;
    logic [9:0] v_count;

    // Pixel counters
    always_ff @(posedge clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else if (pixel_ce) begin
            if (h_count == H_TOTAL - 10'd1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 10'd1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // Pixel coordinates
    assign x = h_count;
    assign y = v_count;

    // Visible display area
    assign video_active =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);

    // Horizontal sync: active low
    assign hsync = ~(
        (h_count >= H_VISIBLE + H_FRONT) &&
        (h_count < H_VISIBLE + H_FRONT + H_SYNC)
    );

    // Vertical sync: active low
    assign vsync = ~(
        (v_count >= V_VISIBLE + V_FRONT) &&
        (v_count < V_VISIBLE + V_FRONT + V_SYNC)
    );

endmodule
