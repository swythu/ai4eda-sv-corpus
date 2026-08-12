`timescale 1ns/1ps
module tb_cdc_handshake;logic sc=0,dc=0,sr=0,dr=0,sv,sready,dv,dready;logic[7:0]sd,dd;integer sent=0,got=0;
cdc_handshake#(.Width(8))dut(.src_clk_i(sc),.src_rst_ni(sr),.src_data_i(sd),.src_valid_i(sv),.src_ready_o(sready),.dst_clk_i(dc),.dst_rst_ni(dr),.dst_data_o(dd),.dst_valid_o(dv),.dst_ready_i(dready));always#5 sc=~sc;always#7 dc=~dc;
always@(posedge dc)if(dv&&dready)begin if(dd!==got+8'h40)$fatal(1,"order got=%h index=%0d",dd,got);got=got+1;end
initial begin sv=0;sd=0;dready=0;repeat(3)@(negedge sc);sr=1;dr=1;fork begin for(sent=0;sent<12;sent=sent+1)begin while(!sready)@(negedge sc);sd=sent+8'h40;sv=1;@(negedge sc);sv=0;end end begin repeat(5)@(negedge dc);dready=1;repeat(10)@(negedge dc);dready=0;repeat(5)@(negedge dc);dready=1;end join_none wait(got==12);$display("CDC_HANDSHAKE_PASS ordered backpressure");$finish;end initial begin#10000;$fatal(1,"timeout");end endmodule
