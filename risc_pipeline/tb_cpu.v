`timescale 1ns/1ps
module tb_cpu;
    reg clk;
    reg reset;

    cpu_top uut(.clk(clk), .reset(reset));

    // 10ns clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb_cpu);

        clk = 0;
        reset = 1;
        #40;       // hold reset for 4 cycles
        reset = 0;

        #300;      // run
        $finish;
    end
endmodule
