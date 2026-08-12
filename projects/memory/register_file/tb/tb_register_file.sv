`timescale 1ns/1ps
module tb_register_file;
  logic clk=0,we;logic[4:0]wa,ra,rb;logic[31:0]wd,qa,qb;
  register_file dut(.clk_i(clk),.we_i(we),.waddr_i(wa),.wdata_i(wd),.raddr_a_i(ra),.raddr_b_i(rb),.rdata_a_o(qa),.rdata_b_o(qb));
  always #5 clk=~clk;
  initial begin we=0;wa=0;wd=0;ra=0;rb=0;#1;if(qa!==0||qb!==0)$fatal(1,"zero register");
    @(negedge clk);we=1;wa=3;wd=32'h12345678;ra=3;rb=0;#1;if(qa!==wd)$fatal(1,"bypass");
    @(negedge clk);we=0;ra=0;rb=3;#1;if(qa!==0||qb!==32'h12345678)$fatal(1,"dual read");
    @(negedge clk);we=1;wa=0;wd=32'hffffffff;@(negedge clk);we=0;ra=0;#1;if(qa!==0)$fatal(1,"zero write");
    $display("REGISTER_FILE_PASS dual-read write bypass zero");$finish;end
endmodule
