`timescale 1ns/1ps
`default_nettype none
module tb_binary_bcd;
  logic clk=0, rst=1, ce=1;
  logic b2d_start=0, d2b_start=0;
  logic [15:0] binary_in;
  logic [19:0] bcd_out, bcd_in;
  logic [15:0] binary_out;
  logic b2d_done, d2b_done;
  always #5 clk=~clk;
  binary_to_bcd b2d(.clk_i(clk),.ce_i(ce),.rst_i(rst),.start_i(b2d_start),.dat_binary_i(binary_in),.dat_bcd_o(bcd_out),.done_o(b2d_done));
  bcd_to_binary d2b(.clk_i(clk),.ce_i(ce),.rst_i(rst),.start_i(d2b_start),.dat_bcd_i(bcd_in),.dat_binary_o(binary_out),.done_o(d2b_done));
  function automatic logic [19:0] to_bcd(input int unsigned value);
    logic [19:0] result; int i; begin result='0; for(i=0;i<5;i++) begin result[i*4 +: 4]=value%10; value=value/10; end return result; end
  endfunction
  task automatic check_value(input logic [15:0] value);
    logic [19:0] expected; begin
      expected=to_bcd(value); @(negedge clk); binary_in=value; b2d_start=1; @(negedge clk); b2d_start=0;
      wait(!b2d_done); wait(b2d_done); #1;
      if(bcd_out!==expected) $fatal(1,"binary_to_bcd value=%0d expected=%h actual=%h",value,expected,bcd_out);
      @(negedge clk); bcd_in=bcd_out; d2b_start=1; @(negedge clk); d2b_start=0;
      wait(!d2b_done); wait(d2b_done); #1;
      if(binary_out!==value) $fatal(1,"bcd_to_binary expected=%0d actual=%0d",value,binary_out);
    end
  endtask
  initial begin binary_in=0; bcd_in=0; repeat(3) @(posedge clk); @(negedge clk); rst=0;
    check_value(0); check_value(1); check_value(9); check_value(10); check_value(99); check_value(1234); check_value(65535);
    $display("BINARY_BCD_SV_PASS vectors=7 round_trip=pass"); $finish; end
  initial begin #20000; $fatal(1,"binary/BCD timeout"); end
endmodule
`default_nettype wire
