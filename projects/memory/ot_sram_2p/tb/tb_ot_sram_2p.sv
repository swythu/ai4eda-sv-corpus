`timescale 1ns/1ps
module tb_ot_sram_2p;
  logic ca=0,cb=0,ar,aw,br,bw;logic[3:0]aa,ba;logic[31:0]ad,bd,aq,bq;logic[3:0]am,bm;
  ot_sram_2p #(.Depth(16)) dut(.clk_a_i(ca),.a_req_i(ar),.a_write_i(aw),.a_addr_i(aa),.a_wdata_i(ad),.a_wmask_i(am),.a_rdata_o(aq),.clk_b_i(cb),.b_req_i(br),.b_write_i(bw),.b_addr_i(ba),.b_wdata_i(bd),.b_wmask_i(bm),.b_rdata_o(bq));
  always #5 ca=~ca;always #7 cb=~cb;
  initial begin ar=0;aw=0;br=0;bw=0;aa=0;ba=0;ad=0;bd=0;am=0;bm=0;
    @(negedge ca);ar=1;aw=1;aa=1;ad=32'h11112222;am=4'hf;
    @(negedge cb);br=1;bw=1;ba=2;bd=32'h33334444;bm=4'hf;
    @(negedge ca);ar=0;aw=0;@(negedge cb);br=0;bw=0;
    @(negedge ca);ar=1;aa=2;@(negedge ca);ar=0;#1;if(aq!==32'h33334444)$fatal(1,"read A");
    @(negedge cb);br=1;ba=1;@(negedge cb);br=0;#1;if(bq!==32'h11112222)$fatal(1,"read B");
    @(negedge ca);ar=1;aw=1;aa=3;ad=32'haaaa5555;am=4'hf;
    @(negedge cb);br=1;bw=1;ba=4;bd=32'hdeadbeef;bm=4'hf;
    @(negedge ca);ar=0;aw=0;@(negedge cb);br=0;bw=0;
    @(negedge ca);ar=1;aa=3;@(negedge ca);ar=0;#1;if(aq!==32'haaaa5555)$fatal(1,"write A");
    @(negedge cb);br=1;ba=4;@(negedge cb);br=0;#1;if(bq!==32'hdeadbeef)$fatal(1,"write B");
    $display("OT_SRAM_2P_PASS independent clocks ports");$finish;end
  initial begin #3000;$fatal(1,"timeout");end
endmodule
