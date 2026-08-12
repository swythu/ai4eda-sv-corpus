`timescale 1ns/1ps
module tb_ecc_ram;
  logic clk=0,req,wr,inj;logic[3:0]addr;logic[31:0]wd,rd;logic[5:0]bitn;logic cor,unc;integer i;
  ecc_ram dut(.clk_i(clk),.req_i(req),.write_i(wr),.addr_i(addr),.wdata_i(wd),.inject_i(inj),.inject_bit_i(bitn),.rdata_o(rd),.corrected_o(cor),.uncorrectable_o(unc));always #5 clk=~clk;
  initial begin req=0;wr=0;inj=0;addr=2;wd=32'hcafe1234;bitn=0;@(negedge clk);req=1;wr=1;@(negedge clk);req=0;wr=0;#1;if(rd!==wd||cor||unc)$fatal(1,"clean");
    for(i=0;i<32;i=i+1)begin inj=1;bitn=i;#1;if(rd!==wd||!cor||unc)$fatal(1,"single bit %0d",i);end
    bitn=38;#1;if(rd!==wd||!cor||unc)$fatal(1,"overall parity");
    force dut.codeword=dut.mem[addr]^(39'b11);#1;if(!unc)$fatal(1,"double bit");release dut.codeword;
    $display("ECC_RAM_PASS clean single-correct double-detect");$finish;end
endmodule
