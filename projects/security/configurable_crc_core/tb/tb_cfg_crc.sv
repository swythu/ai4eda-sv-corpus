`timescale 1ns/1ps
`default_nettype none
module tb_cfg_crc;
  logic clk=0, rst=1, rst_syn=0, crc_en=0, dat_i=0, ref_rst=1;
  logic [6:0] dat_o, ref_o;
  always #5 clk=~clk;
  cfg_crc #(.datw(8),.coff(8'b1000_1001)) dut(.clk,.rst,.rst_syn,.crc_en,.dat_i,.dat_o);
  crc_7 ref_model(.clk,.rst(ref_rst),.crc_en,.sda_i(dat_i),.crc_o(ref_o));
  task automatic check_word(input logic [15:0] word); int bit_index; begin
    @(negedge clk); rst_syn=1; ref_rst=1; @(negedge clk); rst_syn=0; ref_rst=0; crc_en=1;
    for(bit_index=15;bit_index>=0;bit_index--) begin dat_i=word[bit_index]; @(posedge clk); #1; if(dat_o!==ref_o) $fatal(1,"CRC mismatch word=%h bit=%0d dut=%h ref=%h",word,bit_index,dat_o,ref_o); @(negedge clk); end
    crc_en=0;
  end endtask
  initial begin repeat(3) @(posedge clk); @(negedge clk); rst=0; ref_rst=0;
    check_word(16'h0000); check_word(16'hffff); check_word(16'ha5c3); check_word(16'h1234); check_word(16'h8001);
    $display("CFG_CRC_SV_PASS vectors=5 per_bit_scoreboard=pass"); $finish; end
  initial begin #5000; $fatal(1,"CRC timeout"); end
endmodule
`default_nettype wire
