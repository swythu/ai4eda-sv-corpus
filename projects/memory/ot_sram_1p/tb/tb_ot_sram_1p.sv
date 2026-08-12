`timescale 1ns/1ps
module tb_ot_sram_1p;
  logic clk=0,req,write; logic[3:0] addr; logic[31:0] wdata,rdata; logic[3:0] wmask;
  ot_sram_1p #(.Depth(16)) dut(.clk_i(clk),.req_i(req),.write_i(write),.addr_i(addr),.wdata_i(wdata),.wmask_i(wmask),.rdata_o(rdata));
  always #5 clk=~clk;
  task automatic wr(input logic[3:0] a,input logic[31:0] d,input logic[3:0] m);
    @(negedge clk);req=1;write=1;addr=a;wdata=d;wmask=m;@(negedge clk);req=0;write=0;
  endtask
  task automatic rd(input logic[3:0] a,input logic[31:0] e);
    @(negedge clk);req=1;write=0;addr=a;@(negedge clk);req=0;#1;if(rdata!==e)$fatal(1,"read got=%h expected=%h",rdata,e);
  endtask
  initial begin req=0;write=0;addr=0;wdata=0;wmask=0;
    wr(3,32'h11223344,4'hf);rd(3,32'h11223344);wr(3,32'haa00cc00,4'b1010);rd(3,32'haa22cc44);
    @(negedge clk);req=0;addr=4;repeat(2)@(negedge clk);#1;if(rdata!==32'haa22cc44)$fatal(1,"request gating");
    $display("OT_SRAM_1P_PASS full masked latency gating");$finish;end
endmodule
