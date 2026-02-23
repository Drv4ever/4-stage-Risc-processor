`timescale 1ns/1ps
module cpu_top(input clk, input reset);

    // -----------------------------
    // IF stage
    // -----------------------------
    wire [31:0] pc;
    wire [31:0] pc_next = pc + 32'd4;
    wire [31:0] instr_f;

    pc pc1(
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc(pc)
    );

    instr_mem imem(
        .addr(pc),
        .instr(instr_f)
    );

    // IF/ID pipeline register
    reg [31:0] if_id_instr;
    always @(posedge clk) begin
        if (reset)
            if_id_instr <= 32'd0;   // NOP
        else
            if_id_instr <= instr_f;
    end

    // -----------------------------
    // ID stage (decode + reg read + control)
    // -----------------------------
    wire [5:0] opcode_d = if_id_instr[31:26];
    wire [4:0] rs_d     = if_id_instr[25:21];
    wire [4:0] rt_d     = if_id_instr[20:16];
    wire [4:0] rd_d     = if_id_instr[15:11];
    wire [15:0] imm16_d = if_id_instr[15:0];
    wire [31:0] imm_d   = {{16{imm16_d[15]}}, imm16_d};

    // WB stage outputs (from EX/WB reg) feed reg_file write port
    reg        ex_wb_reg_write;
    reg [4:0]  ex_wb_waddr;
    reg [31:0] ex_wb_wdata;

    // Register file (read in ID, write in WB)
    wire [31:0] rd1_d, rd2_d;
    reg_file rf(
        .rs(rs_d),
        .rt(rt_d),
        .rd(ex_wb_waddr),
        .wd(ex_wb_wdata),
        .reg_write(ex_wb_reg_write),
        .rd1(rd1_d),
        .rd2(rd2_d),
        .clk(clk)
    );

    // Control signals generated in ID
    reg        reg_write_d;
    reg        mem_write_d;
    reg        mem_to_reg_d;
    reg        alu_src_imm_d;
    reg        rd_is_rt_d;
    reg [2:0]  alu_ctrl_d;

    // Opcodes: ADD=0, SUB=1, LW=2, SW=3, ADDI=4
    always @(*) begin
        reg_write_d   = 1'b0;
        mem_write_d   = 1'b0;
        mem_to_reg_d  = 1'b0;
        alu_src_imm_d = 1'b0;
        rd_is_rt_d    = 1'b0;
        alu_ctrl_d    = 3'd0;

        case (opcode_d)
            6'd0: begin // ADD
                reg_write_d = 1'b1;
                alu_ctrl_d  = 3'd0;
            end
            6'd1: begin // SUB
                reg_write_d = 1'b1;
                alu_ctrl_d  = 3'd1;
            end
            6'd2: begin // LW
                reg_write_d   = 1'b1;
                mem_to_reg_d  = 1'b1;
                alu_src_imm_d = 1'b1;
                rd_is_rt_d    = 1'b1;
                alu_ctrl_d    = 3'd0;
            end
            6'd3: begin // SW
                mem_write_d   = 1'b1;
                alu_src_imm_d = 1'b1;
                alu_ctrl_d    = 3'd0;
            end
            6'd4: begin // ADDI
                reg_write_d   = 1'b1;
                alu_src_imm_d = 1'b1;
                rd_is_rt_d    = 1'b1;
                alu_ctrl_d    = 3'd0;
            end
            default: begin
                // NOP
            end
        endcase
    end

    wire [4:0] dest_d = (rd_is_rt_d) ? rt_d : rd_d;

    // ID/EX pipeline registers
    reg [31:0] id_ex_a;
    reg [31:0] id_ex_b;
    reg [31:0] id_ex_imm;
    reg [31:0] id_ex_store_data;
    reg [4:0]  id_ex_dest;

    reg        id_ex_reg_write;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_alu_src_imm;
    reg [2:0]  id_ex_alu_ctrl;

    always @(posedge clk) begin
        if (reset) begin
            id_ex_a           <= 32'd0;
            id_ex_b           <= 32'd0;
            id_ex_imm         <= 32'd0;
            id_ex_store_data  <= 32'd0;
            id_ex_dest        <= 5'd0;

            id_ex_reg_write   <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_alu_src_imm <= 1'b0;
            id_ex_alu_ctrl    <= 3'd0;
        end else begin
            id_ex_a           <= rd1_d;
            id_ex_b           <= rd2_d;
            id_ex_imm         <= imm_d;
            id_ex_store_data  <= rd2_d;     // for SW
            id_ex_dest        <= dest_d;

            id_ex_reg_write   <= reg_write_d;
            id_ex_mem_write   <= mem_write_d;
            id_ex_mem_to_reg  <= mem_to_reg_d;
            id_ex_alu_src_imm <= alu_src_imm_d;
            id_ex_alu_ctrl    <= alu_ctrl_d;
        end
    end

    // -----------------------------
    // EX/MEM stage (ALU + data memory access)
    // -----------------------------
    wire [31:0] alu_b_ex = (id_ex_alu_src_imm) ? id_ex_imm : id_ex_b;
    wire [31:0] alu_y_ex;

    alu alu1(
        .a(id_ex_a),
        .b(alu_b_ex),
        .alu_ctrl(id_ex_alu_ctrl),
        .y(alu_y_ex)
    );

    wire [31:0] mem_rd_ex;
    data_mem dmem(
        .addr(alu_y_ex),
        .wd(id_ex_store_data),
        .mem_write(id_ex_mem_write),
        .rd(mem_rd_ex),
        .clk(clk)
    );

    wire [31:0] wb_data_ex = (id_ex_mem_to_reg) ? mem_rd_ex : alu_y_ex;

    // EX/WB pipeline registers
    always @(posedge clk) begin
        if (reset) begin
            ex_wb_reg_write <= 1'b0;
            ex_wb_waddr     <= 5'd0;
            ex_wb_wdata     <= 32'd0;
        end else begin
            ex_wb_reg_write <= id_ex_reg_write;
            ex_wb_waddr     <= id_ex_dest;
            ex_wb_wdata     <= wb_data_ex;
        end
    end

endmodule
