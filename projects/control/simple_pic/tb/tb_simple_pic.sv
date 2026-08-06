`timescale 1ns/1ps
`default_nettype none
module tb_simple_pic;
  logic clk=0,rst_n=0,cyc=0,stb=0,we=0;logic [2:1] adr=0;logic [7:0] dat_i=0;wire [7:0] dat_o;wire ack,int_o;logic [8:1] irq='0;
  simple_pic #(.is(8)) dut(.clk_i(clk),.rst_i(rst_n),.cyc_i(cyc),.stb_i(stb),.adr_i(adr),.we_i(we),.dat_i(dat_i),.dat_o(dat_o),.ack_o(ack),.int_o(int_o),.irq(irq));
  always #5 clk=~clk;
  task automatic wb_write(input logic [1:0] address,input logic [7:0] data);begin @(negedge clk);adr=address;dat_i=data;we=1;cyc=1;stb=1;wait(ack);@(negedge clk);cyc=0;stb=0;we=0;wait(!ack);end endtask
  task automatic wb_read(input logic [1:0] address,output logic [7:0] data);begin @(negedge clk);adr=address;we=0;cyc=1;stb=1;wait(ack);#1;data=dat_o;@(negedge clk);cyc=0;stb=0;wait(!ack);end endtask
  task automatic wait_int(input logic expected);int count;begin count=0;while(int_o!==expected&&count<20)begin@(posedge clk);count++;end if(int_o!==expected)$fatal(1,"PIC interrupt timeout expected=%b actual=%b",expected,int_o);end endtask
  logic [7:0] rd;
  initial begin repeat(3)@(posedge clk);@(negedge clk);rst_n=1;repeat(3)@(posedge clk);
    wb_write(0,8'h00);wb_write(1,8'h01);wb_write(2,8'hfe);irq[1]=1;wait_int(1);wb_read(3,rd);if(!rd[0])$fatal(1,"PIC level pending missing");irq[1]=0;repeat(3)@(posedge clk);wb_write(3,8'h01);wait_int(0);
    wb_write(0,8'h02);wb_write(1,8'h02);wb_write(2,8'hfd);repeat(3)@(posedge clk);irq[2]=1;wait_int(1);irq[2]=0;repeat(3)@(posedge clk);wb_write(3,8'h02);wait_int(0);
    $display("SIMPLE_PIC_SV_PASS level_irq=pass rising_edge_irq=pass wishbone=pass");$finish;end
  initial begin #10000;$fatal(1,"PIC timeout");end
endmodule
`default_nettype wire
