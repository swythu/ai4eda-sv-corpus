`timescale 1ns/1ps
module tb_reset_synchronizer;logic clk=0,arstn=1,srstn;reset_synchronizer#(.Stages(3))dut(.clk_i(clk),.async_rst_ni(arstn),.sync_rst_ni(srstn));always#5 clk=~clk;
initial begin#1;arstn=0;#1;if(srstn!==0)$fatal(1,"assert");#5;arstn=1;repeat(2)begin@(posedge clk);#1;if(srstn)$fatal(1,"early");end @(posedge clk);#1;if(!srstn)$fatal(1,"release");#3;arstn=0;#1;if(srstn)$fatal(1,"async reassert");$display("RESET_SYNCHRONIZER_PASS");$finish;end endmodule
