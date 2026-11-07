`timescale 1ns/1ps

module ps2_event_counters (
    input  logic clk,
    input  logic rst,

    input  logic scan_valid,
    input  logic key_valid,
    input  logic key_pressed,

    input  logic key_up,
    input  logic key_down,
    input  logic key_select,
    input  logic key_back,

    output logic [15:0] scan_count,
    output logic [15:0] key_count,
    output logic [15:0] press_count,
    output logic [15:0] release_count,
    output logic [15:0] action_count
);

    always_ff @(posedge clk) begin
        if (rst) begin
            scan_count    <= '0;
            key_count     <= '0;
            press_count   <= '0;
            release_count <= '0;
            action_count  <= '0;
        end else begin
            if (scan_valid)
                scan_count <= scan_count + 1'b1;

            if (key_valid) begin
                key_count <= key_count + 1'b1;

                if (key_pressed)
                    press_count <= press_count + 1'b1;
                else
                    release_count <= release_count + 1'b1;
            end

            if (key_up || key_down ||
                key_select || key_back)
                action_count <= action_count + 1'b1;
        end
    end

endmodule
