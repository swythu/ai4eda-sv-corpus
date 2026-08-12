`timescale 1ns/1ps
module tb_fir_filter;logic clk=0,rstn=0,v,vo;logic signed[7:0]x;logic signed[19:0]y;integer i;integer exp[0:5];fir_filter#(.W(8),.CW(8),.OW(20))d(.clk_i(clk),.rst_ni(rstn),.valid_i(v),.sample_i(x),.valid_o(vo),.sample_o(y));always#5 clk=~clk;
initial begin exp[0]=1;exp[1]=2;exp[2]=3;exp[3]=4;exp[4]=0;exp[5]=0;v=0;x=0;repeat(2)@(negedge clk);rstn=1;for(i=0;i<6;i=i+1)begin v=1;x=(i==0)?1:0;@(negedge clk);#1;if(y!==exp[i])$fatal(1,"tap %0d got %0d",i,y);end v=0;@(negedge clk);if(vo)$fatal(1,"valid bubble");$display("FIR_FILTER_PASS");$finish;end endmodule
