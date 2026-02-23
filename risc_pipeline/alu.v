`timescale 1ns/1ps
module alu(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  alu_ctrl,
    output reg  [31:0] y
);
    always @(*) begin
        case (alu_ctrl)
            3'd0: y = a + b; // ADD
            3'd1: y = a - b; // SUB
            default: y = 32'd0;
        endcase
    end
endmodule
