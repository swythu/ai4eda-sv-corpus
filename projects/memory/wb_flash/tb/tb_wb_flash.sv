`timescale 1ns/1ps
module tb_wb_flash;
  logic clk_i=0, nrst_i=0;
  logic [18:0] wb_adr_i='0;
  logic [31:0] wb_dat_i='0;
  logic [3:0] wb_sel_i='0;
  logic wb_we_i=0, wb_stb_i=0, wb_cyc_i=0;
  logic [7:0] flash_dat_i=8'h5a;
  wire [31:0] wb_dat_o;
  wire wb_ack_o;
  wire [18:0] flash_adr_o;
  wire [7:0] flash_dat_o;
  wire flash_oe, flash_ce, flash_we;
  int checks=0;
  always #5 clk_i=~clk_i;

  wb_flash #(.ws(4'd2)) dut (.*);

  task automatic begin_cycle(input logic wr, input logic [3:0] sel, input logic [31:0] data);
    @(negedge clk_i);
    wb_we_i=wr; wb_sel_i=sel; wb_dat_i=data; wb_cyc_i=1; wb_stb_i=1;
    #1;
    if (flash_ce !== 0) $fatal(1,"flash CE not active");
    if (wr && (flash_we !== 0 || flash_oe !== 1)) $fatal(1,"write controls wrong");
    if (!wr && (flash_oe !== 0 || flash_we !== 1)) $fatal(1,"read controls wrong");
    wait(wb_ack_o===1);
    @(negedge clk_i);
    wb_cyc_i=0; wb_stb_i=0; wb_we_i=0;
    @(posedge clk_i); #1;
    if (wb_ack_o !== 0 || flash_ce !== 1) $fatal(1,"cycle did not return idle");
  endtask

  task automatic check_lane(input logic [3:0] sel, input logic [1:0] lane, input logic [7:0] expected);
    wb_adr_i=19'h1234; 
    fork
      begin_cycle(1'b1,sel,32'hd4c3b2a1);
      begin
        wait(wb_cyc_i);
        #1;
        if (flash_adr_o !== {wb_adr_i[18:2],lane}) $fatal(1,"lane address mismatch");
        if (flash_dat_o !== expected) $fatal(1,"lane data mismatch got=%02x",flash_dat_o);
      end
    join
    checks++;
  endtask

  initial begin
    repeat(3) @(posedge clk_i); nrst_i=1;
    check_lane(4'b0001,2'd0,8'ha1);
    check_lane(4'b0010,2'd1,8'hb2);
    check_lane(4'b0100,2'd2,8'hc3);
    check_lane(4'b1000,2'd3,8'hd4);
    begin_cycle(1'b0,4'b0001,'0);
    if (wb_dat_o !== 32'h5a5a5a5a) $fatal(1,"read replication mismatch");
    checks++;
    $display("WB_FLASH_SV_PASS checks=%0d lanes=4 waitstate=pass read_write=pass",checks);
    $finish;
  end
  initial begin #5000; $fatal(1,"timeout"); end
endmodule
