`timescale 1ns/1ps

module tb_boot_menu_renderer_six;

    logic [9:0] x = 0;
    logic [9:0] y = 0;
    logic video_active = 1;
    logic [2:0] selected_index = 0;
    logic menu_active = 1;

    logic [11:0] rgb;
    logic opaque;

    int tests = 0;

    boot_menu_renderer dut (
        .x(x),
        .y(y),
        .video_active(video_active),
        .selected_index(selected_index),
        .menu_active(menu_active),
        .rgb(rgb),
        .opaque(opaque)
    );

    task automatic sample_pixel(
        input int px,
        input int py,
        input logic [11:0] expected_rgb,
        input logic expected_opaque
    );
        x = 10'(px);
        y = 10'(py);
        #1;

        assert(rgb == expected_rgb &&
               opaque == expected_opaque)
            else $fatal(1,
                "Pixel (%0d,%0d): RGB=%03h expected=%03h, opaque=%b expected=%b",
                px, py, rgb, expected_rgb,
                opaque, expected_opaque);

        tests++;
    endtask

    initial begin
        $display("RetroFPGA Tutorial 009 VGA Renderer Test");

        // Outside menu.
        sample_pixel(63, 128, 12'h000, 1'b0);
        sample_pixel(224, 128, 12'h000, 1'b0);
        sample_pixel(64, 296, 12'h000, 1'b0);

        // Diagnostics row 6: unselected background.
        sample_pixel(200, 284, 12'h001, 1'b1);

        // Selected row 0, background.
        sample_pixel(200, 140, 12'h024, 1'b1);

        // Unselected row 1, background.
        sample_pixel(200, 164, 12'h001, 1'b1);

        // Verify all seven selectable rows.
        for (int i = 0; i < 7; i++) begin
            selected_index = 3'(i);
            sample_pixel(200, 140 + i * 24,
                         12'h024, 1'b1);
        end

        // Verify a glyph pixel: S in SAP-1.
        selected_index = 0;
        sample_pixel(66, 128, 12'hFF0, 1'b1);

        // Booting changes glyph color.
        menu_active = 0;
        sample_pixel(66, 128, 12'hFA0, 1'b1);

        // Inactive video must not draw the menu.
        video_active = 0;
        sample_pixel(66, 128, 12'h000, 1'b0);

        $display("PASS: %0d VGA pixel checks", tests);
        $finish;
    end

endmodule
