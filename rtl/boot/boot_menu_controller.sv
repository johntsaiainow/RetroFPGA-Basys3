`timescale 1ns/1ps

module boot_menu_controller (
    input  logic clk,
    input  logic rst,

    // One-cycle button events from Tutorial 006.
    input  logic up_pressed,
    input  logic down_pressed,
    input  logic select_pressed,
    input  logic back_pressed,

    // Menu display interface.
    output logic [1:0] selected_index,
    output logic       menu_active,

    // Core launch interface.
    output logic [1:0] boot_core,
    output logic       boot_request,
    output logic       booting
);

    typedef enum logic {
        STATE_MENU    = 1'b0,
        STATE_BOOTING = 1'b1
    } state_t;

    state_t state;

    // State and output registers.
    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= STATE_MENU;
            selected_index <= 2'd0;
            boot_core      <= 2'd0;
            boot_request   <= 1'b0;
        end else begin

            // A boot request lasts exactly one clock cycle.
            boot_request <= 1'b0;

            case (state)

                STATE_MENU: begin

                    // Priority:
                    // SELECT > UP > DOWN
                    // BACK is ignored in MENU.

                    if (select_pressed) begin

                        boot_core    <= selected_index;
                        boot_request <= 1'b1;
                        state        <= STATE_BOOTING;

                    end else if (up_pressed) begin

                        // Wrap from Z80 to Game Boy.
                        selected_index <=
                            selected_index - 2'd1;

                    end else if (down_pressed) begin

                        // Wrap from Game Boy to Z80.
                        selected_index <=
                            selected_index + 2'd1;

                    end

                end

                STATE_BOOTING: begin

                    // Navigation is disabled after selection.
                    // BACK returns to the menu.
                    if (back_pressed)
                        state <= STATE_MENU;

                end

                default: begin
                    state <= STATE_MENU;
                end

            endcase
        end
    end

    // State indicators.
    always_comb begin
        menu_active = (state == STATE_MENU);
        booting     = (state == STATE_BOOTING);
    end

endmodule
