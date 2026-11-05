`timescale 1ns/1ps

// RetroFPGA Tutorial 009
// Six-architecture core availability registry.
//
// Core IDs:
//   0 = SAP-1
//   1 = Hack
//   2 = MOS 6502
//   3 = Z80
//   4 = Motorola 68000
//   5 = DCPU-16
//
// Availability bits are enabled only after a CPU core
// has been implemented and verified.

module core_registry #(
    parameter logic [5:0] IMPLEMENTED_CORES = 6'b000000
) (
    input  logic [2:0] core_id,
    output logic       core_valid,
    output logic       core_available
);

    always_comb begin
        core_valid     = (core_id <= 3'd5);
        core_available = 1'b0;

        if (core_valid)
            core_available = IMPLEMENTED_CORES[core_id];
    end

endmodule
