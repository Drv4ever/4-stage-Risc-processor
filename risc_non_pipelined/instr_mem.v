`timescale 1ns/1ps
module instr_mem(
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] memory [0:255];
    integer i;

    // Small demo program
    // Encoding used here:
    // R-type: [opcode(6)][rs(5)][rt(5)][rd(5)][unused(11)]
    // I-type: [opcode(6)][rs(5)][rt(5)][imm(16)]
    //
    // Opcodes:
    // ADD=0, SUB=1, LW=2, SW=3, ADDI=4
    initial begin
        // Initialize entire memory to NOP (0)
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'd0;

        // Program:
        // 0: ADDI r1, r0, 10
        memory[0] = {6'd4, 5'd0, 5'd1, 16'd10};

        // 1: ADDI r2, r0, 20
        memory[1] = {6'd4, 5'd0, 5'd2, 16'd20};

        // 2: ADD  r3, r1, r2  => r3 = 30
        memory[2] = {6'd0, 5'd1, 5'd2, 5'd3, 11'd0};

        // 3: SW r3, 0(r0)  => MEM[0] = 30
        memory[3] = {6'd3, 5'd0, 5'd3, 16'd0};

        // 4: LW r4, 0(r0)  => r4 = 30
        memory[4] = {6'd2, 5'd0, 5'd4, 16'd0};

        // 5: SUB r5, r4, r1 => r5 = 20
        memory[5] = {6'd1, 5'd4, 5'd1, 5'd5, 11'd0};
    end

    // PC is byte-addressed, so divide by 4 for word index
    assign instr = memory[addr[31:2]];

endmodule
