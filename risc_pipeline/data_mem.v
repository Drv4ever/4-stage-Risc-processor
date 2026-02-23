`timescale 1ns/1ps
module data_mem(
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    input  wire        mem_write,
    output wire [31:0] rd,
    input  wire        clk
);
    reg [31:0] memory [0:255];

    integer i;
    initial begin
        for (i=0; i<256; i=i+1) memory[i] = 32'd0;
    end

    // word addressed
    assign rd = memory[addr[31:2]];

    always @(posedge clk) begin
        if (mem_write)
            memory[addr[31:2]] <= wd;
    end
endmodule
