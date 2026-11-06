`timescale 1ns/1ps

module retrofpga_input_router (
    input  logic menu_active,

    input  logic up_pressed,
    input  logic down_pressed,
    input  logic select_pressed,
    input  logic back_pressed,

    output logic menu_up,
    output logic menu_down,
    output logic menu_select,
    output logic menu_back,

    output logic cpu_run,
    output logic cpu_pause,
    output logic cpu_step
);

    always_comb begin
        menu_up     = 1'b0;
        menu_down   = 1'b0;
        menu_select = 1'b0;
        menu_back   = 1'b0;

        cpu_run     = 1'b0;
        cpu_pause   = 1'b0;
        cpu_step    = 1'b0;

        if (menu_active) begin
            menu_up     = up_pressed;
            menu_down   = down_pressed;
            menu_select = select_pressed;
        end else begin
            cpu_run     = up_pressed;
            cpu_pause   = down_pressed;
            cpu_step    = select_pressed;
            menu_back   = back_pressed;
        end
    end

endmodule
