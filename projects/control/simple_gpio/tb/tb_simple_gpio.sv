`timescale 1ns/1ps
`default_nettype none
module tb_simple_gpio;
  logic clk=0, rst_n=0, cyc=0, stb=0, adr=0, we=0; logic [7:0] dat_i=0; wire [7:0] dat_o; wire ack;
  tri [8:1] gpio; logic [8:1] ext_value, ext_oe;
  genvar i; generate for(i=1;i<=8;i++) assign gpio[i]=ext_oe[i]?ext_value[i]:1'bz; endgenerate
  simple_gpio #(.io(8)) dut(.clk_i(clk),.rst_i(rst_n),.cyc_i(cyc),.stb_i(stb),.adr_i(adr),.we_i(we),.dat_i(dat_i),.dat_o(dat_o),.ack_o(ack),.gpio(gpio));
  always #5 clk=~clk;
  task automatic wb_write(input logic address,input logic [7:0] data); begin @(negedge clk); adr=address;dat_i=data;we=1;cyc=1;stb=1; wait(ack); @(negedge clk);cyc=0;stb=0;we=0; wait(!ack); end endtask
  task automatic wb_read(input logic address,output logic [7:0] data); begin @(negedge clk);adr=address;we=0;cyc=1;stb=1;wait(ack);#1;data=dat_o;@(negedge clk);cyc=0;stb=0;wait(!ack); end endtask
  logic [7:0] rd;
  initial begin ext_value=8'ha0;ext_oe=8'hf0;repeat(3)@(posedge clk);@(negedge clk);rst_n=1;
    wb_write(0,8'h0f); wb_write(1,8'h05); repeat(3)@(posedge clk);#1;
    if(gpio!==8'ha5)$fatal(1,"GPIO drive/input expected=a5 actual=%h",gpio);
    wb_read(0,rd);if(rd!==8'h0f)$fatal(1,"GPIO ctrl read expected=0f actual=%h",rd);
    wb_read(1,rd);if(rd!==8'ha5)$fatal(1,"GPIO line read expected=a5 actual=%h",rd);
    ext_value=8'h50;repeat(3)@(posedge clk);wb_read(1,rd);if(rd!==8'h55)$fatal(1,"GPIO resample expected=55 actual=%h",rd);
    $display("SIMPLE_GPIO_SV_PASS wishbone=pass bidirectional_gpio=pass synchronizer=pass");$finish;end
  initial begin #5000;$fatal(1,"GPIO timeout");end
endmodule
`default_nettype wire
