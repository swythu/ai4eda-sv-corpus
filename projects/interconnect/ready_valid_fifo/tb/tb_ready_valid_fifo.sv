`timescale 1ns/1ps
module tb_ready_valid_fifo;logic clk=0,rstn=0,vi,ro,vo,ri;logic[7:0]di,do_;logic[2:0]u;integer i;
ready_valid_fifo#(.Width(8),.Depth(4))dut(.clk_i(clk),.rst_ni(rstn),.data_i(di),.valid_i(vi),.ready_o(ro),.data_o(do_),.valid_o(vo),.ready_i(ri),.usage_o(u));always#5 clk=~clk;
initial begin vi=0;ri=0;di=0;repeat(2)@(negedge clk);rstn=1;for(i=0;i<4;i=i+1)begin vi=1;di=i+10;@(negedge clk);end vi=0;if(ro||u!=4)$fatal(1,"full");repeat(2)begin#1;if(do_!==10)$fatal(1,"stable");@(negedge clk);end
ri=1;for(i=0;i<4;i=i+1)begin#1;if(!vo||do_!==i+10)$fatal(1,"order");@(negedge clk);end ri=0;#1;if(vo||u!=0)$fatal(1,"empty");
vi=1;ri=1;di=8'h55;@(negedge clk);#1;if(!vo||do_!==8'h55)$fatal(1,"stream first");di=8'h66;@(negedge clk);#1;if(!vo||do_!==8'h66)$fatal(1,"stream second");vi=0;@(negedge clk);#1;if(vo)$fatal(1,"stream drain");$display("READY_VALID_FIFO_PASS");$finish;end endmodule
