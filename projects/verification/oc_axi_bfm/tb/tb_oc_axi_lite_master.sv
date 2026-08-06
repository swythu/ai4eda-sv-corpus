`timescale 1ns/1ps
module tb_oc_axi_lite_master;
  logic clock_clk=0, reset_reset=1;
  logic axm_m0_awready=0, axm_m0_wready=0, axm_m0_bvalid=0;
  logic axm_m0_arready=0, axm_m0_rvalid=0;
  logic [31:0] axm_m0_rdata='0, addr='0, w_data='0;
  logic transaction_type=0, start=0;
  wire [31:0] axm_m0_awaddr, axm_m0_wdata, axm_m0_araddr, r_data;
  wire [2:0] axm_m0_awprot, axm_m0_arprot;
  wire axm_m0_awvalid, axm_m0_wlast, axm_m0_wvalid, axm_m0_bready;
  wire axm_m0_arvalid, axm_m0_rready, done;
  int checks=0;
  always #5 clock_clk=~clock_clk;
  new_component dut(.*);

  task automatic pulse_start(input logic is_read,input logic [31:0] a,input logic [31:0] d);
    @(negedge clock_clk); transaction_type=is_read; addr=a; w_data=d; start=1;
    @(negedge clock_clk); start=0;
  endtask

  task automatic finish_write;
    @(negedge clock_clk); axm_m0_bvalid=1;
    @(posedge clock_clk); #1;
    if (!done) $fatal(1,"write did not complete");
    @(negedge clock_clk); axm_m0_bvalid=0;
    @(posedge clock_clk); #1;
    if (done) $fatal(1,"done did not pulse");
  endtask

  initial begin
    repeat(3) @(posedge clock_clk);
    @(negedge clock_clk); reset_reset=0;

    axm_m0_awready=1; axm_m0_wready=1;
    pulse_start(0,32'h1000,32'hdeadbeef);
    @(posedge clock_clk); #1;
    if (axm_m0_awaddr!==32'h1000 || axm_m0_wdata!==32'hdeadbeef || !axm_m0_wlast)
      $fatal(1,"write payload mismatch");
    @(posedge clock_clk); #1;
    if (!axm_m0_bready || axm_m0_awvalid || axm_m0_wvalid) $fatal(1,"parallel write handshake failed");
    axm_m0_awready=0; axm_m0_wready=0;
    finish_write(); checks++;

    axm_m0_awready=1; axm_m0_wready=0;
    pulse_start(0,32'h2004,32'h12345678);
    @(posedge clock_clk); #1;
    if (axm_m0_awvalid || !axm_m0_wvalid) $fatal(1,"split AW handshake failed");
    axm_m0_awready=0; axm_m0_wready=1;
    @(posedge clock_clk); #1;
    if (!axm_m0_bready || axm_m0_wvalid) $fatal(1,"split W handshake failed");
    axm_m0_wready=0;
    finish_write(); checks++;

    axm_m0_arready=1;
    pulse_start(1,32'h3008,'0);
    @(posedge clock_clk); #1;
    if (axm_m0_araddr!==32'h3008 || axm_m0_arvalid) $fatal(1,"AR handshake failed");
    axm_m0_arready=0; axm_m0_rdata=32'hcafef00d; axm_m0_rvalid=1;
    @(posedge clock_clk); #1;
    if (axm_m0_rready) $fatal(1,"RREADY did not drop");
    axm_m0_rvalid=0;
    @(posedge clock_clk); #1;
    if (!done || r_data!==32'hcafef00d) $fatal(1,"read response mismatch");
    checks++;

    if (axm_m0_awprot!==3'b000 || axm_m0_arprot!==3'b000) $fatal(1,"PROT outputs unknown");
    $display("OC_AXI_BFM_SV_PASS checks=%0d parallel_write=pass split_write=pass read=pass",checks);
    $finish;
  end
  initial begin #5000; $fatal(1,"timeout"); end
endmodule
