`timescale 1ns/1ps

// RetroFPGA Tutorial 009
// Six-architecture boot menu controller.

module boot_menu_controller #(
    parameter logic [5:0] IMPLEMENTED_CORES = 6'b000000
) (
    input  logic clk,
    input  logic rst,

    input  logic up_pressed,
    input  logic down_pressed,
    input  logic select_pressed,
    input  logic back_pressed,

    output logic [2:0] selected_index,
    output logic       menu_active,

    output logic [2:0] boot_core,
    output logic       boot_request,
    output logic       booting,
    output logic       diagnostics_active
);

    typedef enum logic [1:0] {
        STATE_MENU        = 2'd0,
        STATE_BOOTING     = 2'd1,
        STATE_DIAGNOSTICS = 2'd2
    } state_t;

    state_t state;

    logic core_valid;
    logic core_available;

    core_registry #(
        .IMPLEMENTED_CORES(IMPLEMENTED_CORES)
    ) registry (
        .core_id(selected_index),
        .core_valid(core_valid),
        .core_available(core_available)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= STATE_MENU;
            selected_index <= 3'd0;
            boot_core      <= 3'd0;
            boot_request   <= 1'b0;
        end else begin
            boot_request <= 1'b0;

            case (state)

                STATE_MENU: begin
                    // Priority: SELECT > UP > DOWN.

                    if (select_pressed) begin
                        if (selected_index == 3'd6) begin
                            state <= STATE_DIAGNOSTICS;
                        end else if (core_valid && core_available) begin
                            boot_core    <= selected_index;
                            boot_request <= 1'b1;
                            state        <= STATE_BOOTING;
                        end
                    end else if (up_pressed) begin
                        if (selected_index == 3'd0)
                            selected_index <= 3'd6;
                        else
                            selected_index <= selected_index - 3'd1;
                    end else if (down_pressed) begin
                        if (selected_index == 3'd6)
                            selected_index <= 3'd0;
                        else
                            selected_index <= selected_index + 3'd1;
                    end
                end

                STATE_BOOTING: begin
                    if (back_pressed)
                        state <= STATE_MENU;
                end

                STATE_DIAGNOSTICS: begin
                    if (back_pressed)
                        state <= STATE_MENU;
                end

                default: begin
                    state <= STATE_MENU;
                end

            endcase
        end
    end

    always_comb begin
        menu_active = (state == STATE_MENU);
        booting            = (state == STATE_BOOTING);
        diagnostics_active = (state == STATE_DIAGNOSTICS);
    end

endmodule
