`timescale 1ns/1ps
module reg_file(
    input  wire [4:0]  rs,
    input  wire [4:0]  rt,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    input  wire        reg_write,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    input  wire        clk
);
    reg [31:0] regs [0:31];

    // Optional: init all to 0
    integer i;
    initial begin
        for (i=0; i<32; i=i+1) regs[i] = 32'd0;
    end

    // Read (combinational)
    assign rd1 = (rs == 0) ? 32'd0 : regs[rs];
    assign rd2 = (rt == 0) ? 32'd0 : regs[rt];

    // Write (sequential)
    always @(posedge clk) begin
        if (reg_write && (rd != 0))
            regs[rd] <= wd;
    end
endmodule
