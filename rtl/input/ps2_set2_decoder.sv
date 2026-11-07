`timescale 1ns/1ps

module ps2_set2_decoder (
    input  logic       clk,
    input  logic       rst,

    input  logic [7:0] scan_code,
    input  logic       scan_valid,

    // Assert on a receiver frame error or timeout.
    input  logic       frame_error,

    output logic [7:0] key_code,
    output logic       key_extended,
    output logic       key_pressed,
    output logic       key_valid,

    output logic       bat_seen
);

    logic break_pending;
    logic extended_pending;

    always_ff @(posedge clk) begin
        if (rst) begin
            break_pending    <= 1'b0;
            extended_pending <= 1'b0;
            key_code         <= 8'h00;
            key_extended     <= 1'b0;
            key_pressed      <= 1'b0;
            key_valid        <= 1'b0;
            bat_seen         <= 1'b0;
        end else begin
            key_valid <= 1'b0;
            bat_seen  <= 1'b0;

            // A damaged PS/2 frame invalidates pending prefixes.
            if (frame_error) begin
                break_pending    <= 1'b0;
                extended_pending <= 1'b0;
            end else if (scan_valid) begin
                case (scan_code)
                    8'hE0: begin
                        extended_pending <= 1'b1;
                    end

                    8'hF0: begin
                        break_pending <= 1'b1;
                    end

                    8'hAA: begin
                        if (!break_pending &&
                            !extended_pending) begin
                            bat_seen <= 1'b1;
                        end else begin
                            key_code     <= scan_code;
                            key_extended <= extended_pending;
                            key_pressed  <= !break_pending;
                            key_valid    <= 1'b1;
                        end

                        break_pending    <= 1'b0;
                        extended_pending <= 1'b0;
                    end

                    default: begin
                        key_code     <= scan_code;
                        key_extended <= extended_pending;
                        key_pressed  <= !break_pending;
                        key_valid    <= 1'b1;

                        break_pending    <= 1'b0;
                        extended_pending <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
