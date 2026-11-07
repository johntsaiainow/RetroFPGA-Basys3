`timescale 1ns/1ps
// Tutorial 010: educational SAP-1-style processor.
// Instruction format: [7:4] opcode, [3:0] address.
// LDA=0, ADD=1, SUB=2, OUT=E, HLT=F.
module sap1_core (
    input  logic       clk,
    input  logic       rst,
    input  logic       step_en,
    output logic [7:0] out_port,
    output logic       out_valid,
    output logic       halted,
    output logic [3:0] pc_debug,
    output logic [7:0] acc_debug,
    output logic [7:0] ir_debug
);
    typedef enum logic [1:0] {FETCH, EXECUTE, HALTED} state_t;
    state_t state;
    logic [3:0] pc;
    logic [7:0] ir, acc;
    logic [7:0] mem [0:15];

    // Read-only demonstration image; no reset of program memory.
    initial begin
        for (int i = 0; i < 16; i++) mem[i] = 8'hF0;
        mem[0] = 8'h05; // LDA 5
        mem[1] = 8'h16; // ADD 6
        mem[2] = 8'h27; // SUB 7
        mem[3] = 8'hE0; // OUT
        mem[4] = 8'hF0; // HLT
        mem[5] = 8'd9;
        mem[6] = 8'd4;
        mem[7] = 8'd2;
    end

    assign halted    = (state == HALTED);
    assign pc_debug  = pc;
    assign acc_debug = acc;
    assign ir_debug  = ir;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc        <= 4'd0;
            ir        <= 8'd0;
            acc       <= 8'd0;
            out_port  <= 8'd0;
            out_valid <= 1'b0;
            state     <= FETCH;
        end else begin
            out_valid <= 1'b0;
            if (step_en) begin
                case (state)
                    FETCH: begin
                        ir    <= mem[pc];
                        pc    <= pc + 4'd1;
                        state <= EXECUTE;
                    end
                    EXECUTE: begin
                        case (ir[7:4])
                            4'h0: begin acc <= mem[ir[3:0]];       state <= FETCH; end
                            4'h1: begin acc <= acc + mem[ir[3:0]]; state <= FETCH; end
                            4'h2: begin acc <= acc - mem[ir[3:0]]; state <= FETCH; end
                            4'hE: begin
                                out_port  <= acc;
                                out_valid <= 1'b1;
                                state     <= FETCH;
                            end
                            4'hF: state <= HALTED;
                            default: state <= HALTED; // Illegal opcode trap.
                        endcase
                    end
                    HALTED: state <= HALTED;
                    default: state <= HALTED;
                endcase
            end
        end
    end
endmodule
