`timescale 1ns/1ps
module instr_mem(
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] memory [0:255];
    integer i;

    // Encoding:
    // R-type: [opcode(6)][rs(5)][rt(5)][rd(5)][unused(11)]
    // I-type: [opcode(6)][rs(5)][rt(5)][imm(16)]
    //
    // Opcodes: ADD=0, SUB=1, LW=2, SW=3, ADDI=4
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'd0; // NOP

        // Program with NOPs (no forwarding/stalls in this pipeline)
        // 0: ADDI r1, r0, 10
        memory[0]  = {6'd4, 5'd0, 5'd1, 16'd10};
        memory[1]  = 32'd0; // NOP

        // 2: ADDI r2, r0, 20
        memory[2]  = {6'd4, 5'd0, 5'd2, 16'd20};
        memory[3]  = 32'd0; // NOP

        // 4: ADD r3, r1, r2  => r3 = 30
        memory[4]  = {6'd0, 5'd1, 5'd2, 5'd3, 11'd0};
        memory[5]  = 32'd0; // NOP

        // 6: SW r3, 0(r0)    => MEM[0] = 30
        memory[6]  = {6'd3, 5'd0, 5'd3, 16'd0};
        memory[7]  = 32'd0; // NOP

        // 8: LW r4, 0(r0)    => r4 = 30
        memory[8]  = {6'd2, 5'd0, 5'd4, 16'd0};
        memory[9]  = 32'd0; // NOP

        // 10: SUB r5, r4, r1 => r5 = 20
        memory[10] = {6'd1, 5'd4, 5'd1, 5'd5, 11'd0};
        memory[11] = 32'd0; // NOP
    end

    assign instr = memory[addr[31:2]]; // PC/4 indexing

endmodule
