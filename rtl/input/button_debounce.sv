`timescale 1ns/1ps

module button_debounce #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned DEBOUNCE_MS = 10
) (
    input  logic clk,
    input  logic rst,
    input  logic button_in,

    output logic level,
    output logic pressed,
    output logic released
);

    // Number of clock cycles required for debounce.
    // Integer ceiling avoids truncating fractional cycles.
    localparam longint unsigned DEBOUNCE_CYCLES =
        (longint'(CLK_FREQ_HZ) * DEBOUNCE_MS
         + 999) / 1000;

    localparam int unsigned COUNTER_WIDTH =
        (DEBOUNCE_CYCLES > 1)
            ? $clog2(DEBOUNCE_CYCLES)
            : 1;

    localparam logic [COUNTER_WIDTH-1:0] COUNT_LAST =
        COUNTER_WIDTH'(DEBOUNCE_CYCLES - 1);

    // Two-stage synchronizer.
    (* ASYNC_REG = "TRUE" *) logic sync_stage1;
    (* ASYNC_REG = "TRUE" *) logic sync_stage2;

    logic [COUNTER_WIDTH-1:0] stable_count;

    // Parameter checks for simulation.
    initial begin
        assert (CLK_FREQ_HZ > 0)
            else $fatal(1, "CLK_FREQ_HZ must be > 0");

        assert (DEBOUNCE_MS > 0)
            else $fatal(1, "DEBOUNCE_MS must be > 0");

        assert (DEBOUNCE_CYCLES >= 1)
            else $fatal(1, "Invalid debounce interval");
    end

    // Synchronize the asynchronous push button.
    always_ff @(posedge clk) begin
        if (rst) begin
            sync_stage1 <= 1'b0;
            sync_stage2 <= 1'b0;
        end else begin
            sync_stage1 <= button_in;
            sync_stage2 <= sync_stage1;
        end
    end

    // Debounce filter and one-cycle event pulses.
    always_ff @(posedge clk) begin
        if (rst) begin
            level        <= 1'b0;
            pressed      <= 1'b0;
            released     <= 1'b0;
            stable_count <= '0;
        end else begin

            // Pulses default to zero every clock.
            pressed  <= 1'b0;
            released <= 1'b0;

            if (sync_stage2 == level) begin

                // Input agrees with the accepted level.
                stable_count <= '0;

            end else if (stable_count == COUNT_LAST) begin

                // Input has remained different long enough.
                level        <= sync_stage2;
                stable_count <= '0;

                if (sync_stage2)
                    pressed <= 1'b1;
                else
                    released <= 1'b1;

            end else begin

                // Count consecutive different samples.
                stable_count <= stable_count + 1'b1;

            end
        end
    end

endmodule
