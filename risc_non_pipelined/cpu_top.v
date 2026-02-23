`timescale 1ns/1ps
module cpu_top(input clk, input reset);

    // Fetch
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] instr;

    assign pc_next = pc + 32'd4;

    pc pc1(
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc(pc)
    );

    instr_mem imem(
        .addr(pc),
        .instr(instr)
    );

    // Decode fields
    wire [5:0] opcode = instr[31:26];
    wire [4:0] rs     = instr[25:21];
    wire [4:0] rt     = instr[20:16];
    wire [4:0] rd     = instr[15:11];
    wire [15:0] imm16  = instr[15:0];
    wire [31:0] imm    = {{16{imm16[15]}}, imm16}; // sign-extend

    // Control signals
    reg        reg_write;
    reg        mem_write;
    reg        mem_to_reg;
    reg        alu_src_imm;
    reg        rd_is_rt;       // for I-type destination
    reg [2:0]  alu_ctrl;

    // Simple control decode
    // Opcodes: ADD=0, SUB=1, LW=2, SW=3, ADDI=4
    always @(*) begin
        // defaults
        reg_write  = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src_imm= 1'b0;
        rd_is_rt   = 1'b0;
        alu_ctrl   = 3'd0;

        case (opcode)
            6'd0: begin // ADD (R-type)
                reg_write = 1'b1;
                alu_ctrl  = 3'd0;
            end
            6'd1: begin // SUB (R-type)
                reg_write = 1'b1;
                alu_ctrl  = 3'd1;
            end
            6'd2: begin // LW
                reg_write  = 1'b1;
                mem_to_reg = 1'b1;
                alu_src_imm= 1'b1;
                rd_is_rt   = 1'b1; // dest = rt
                alu_ctrl   = 3'd0; // addr = rs + imm
            end
            6'd3: begin // SW
                mem_write  = 1'b1;
                alu_src_imm= 1'b1;
                alu_ctrl   = 3'd0; // addr = rs + imm
            end
            6'd4: begin // ADDI
                reg_write  = 1'b1;
                alu_src_imm= 1'b1;
                rd_is_rt   = 1'b1; // dest = rt
                alu_ctrl   = 3'd0;
            end
            default: begin
                // NOP
            end
        endcase
    end

    // Register file
    wire [31:0] reg_data1, reg_data2;
    wire [4:0]  waddr = (rd_is_rt) ? rt : rd;
    wire [31:0] wdata;

    reg_file rf(
        .rs(rs),
        .rt(rt),
        .rd(waddr),
        .wd(wdata),
        .reg_write(reg_write),
        .rd1(reg_data1),
        .rd2(reg_data2),
        .clk(clk)
    );

    // ALU
    wire [31:0] alu_b = (alu_src_imm) ? imm : reg_data2;
    wire [31:0] alu_out;

    alu alu1(
        .a(reg_data1),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .y(alu_out)
    );

    // Data memory
    wire [31:0] mem_out;

    data_mem dmem(
        .addr(alu_out),
        .wd(reg_data2),
        .mem_write(mem_write),
        .rd(mem_out),
        .clk(clk)
    );

    // Writeback mux
    assign wdata = (mem_to_reg) ? mem_out : alu_out;

endmodule
