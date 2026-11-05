`timescale 1ns/1ps

module tb_text_renderer;

    logic [9:0] x;
    logic [9:0] y;
    logic video_active;

    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;

    int tests = 0;

    text_renderer dut (
        .x(x),
        .y(y),
        .video_active(video_active),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    task automatic check_pixel (
        input logic [9:0] test_x,
        input logic [9:0] test_y,
        input logic active,
        input logic [11:0] expected
    );
        x = test_x;
        y = test_y;
        video_active = active;

        #1;

        if ({vga_r, vga_g, vga_b} !== expected) begin
            $fatal(1,
                "FAIL: x=%0d y=%0d RGB=%03h expected=%03h",
                x, y,
                {vga_r, vga_g, vga_b},
                expected
            );
        end

        tests++;
    endtask

    initial begin
        $display("RetroFPGA Tutorial 005");
        $display("Text Renderer Test");

        // First character is R at (64,64).
        // R row 0 = 8'h7C = 01111100.

        check_pixel(10'd64, 10'd64, 1'b1, 12'h000);
        check_pixel(10'd65, 10'd64, 1'b1, 12'h0F8);
        check_pixel(10'd66, 10'd64, 1'b1, 12'h0F8);
        check_pixel(10'd67, 10'd64, 1'b1, 12'h0F8);
        check_pixel(10'd68, 10'd64, 1'b1, 12'h0F8);
        check_pixel(10'd69, 10'd64, 1'b1, 12'h0F8);
        check_pixel(10'd70, 10'd64, 1'b1, 12'h000);
        check_pixel(10'd71, 10'd64, 1'b1, 12'h000);

        // Second character E begins at x=72.
        check_pixel(10'd73, 10'd64, 1'b1, 12'h0F8);

        // Empty row between title and status.
        check_pixel(10'd65, 10'd72, 1'b1, 12'h000);

        // Status begins at y=80.
        // First character S row 0 = 00111100.
        check_pixel(10'd66, 10'd80, 1'b1, 12'hAAF);

        // Outside text region.
        check_pixel(10'd0, 10'd0, 1'b1, 12'h000);
        check_pixel(10'd300, 10'd100, 1'b1, 12'h000);

        // Blanking overrides text.
        check_pixel(10'd65, 10'd64, 1'b0, 12'h000);

        $display("PASS: Text Renderer verified");
        $display("Tests passed: %0d", tests);

        $finish;
    end

endmodule
