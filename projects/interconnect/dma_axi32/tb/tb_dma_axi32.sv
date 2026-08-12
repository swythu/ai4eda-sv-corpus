`timescale 1ns/1ps
`default_nettype none
`include "dma_axi32_defines.v"

module tb_dma_axi32;
  logic clk;
  logic reset;
  logic scan_en;
  logic [31:1]       periph_tx_req;
  logic [31:1]       periph_rx_req;
  logic pclken;
  logic psel;
  logic penable;
  logic [12:0]             paddr;
  logic pwrite;
  logic [31:0]             pwdata;
  logic AWREADY0;
  logic WREADY0;
  logic [`ID_BITS-1:0]        BID0;
  logic [1:0]             BRESP0;
  logic BVALID0;
  logic ARREADY0;
  logic [`ID_BITS-1:0]        RID0;
  logic [32-1:0]       RDATA0;
  logic [1:0]             RRESP0;
  logic RLAST0;
  logic RVALID0;
  wire idle;
  wire [1-1:0]        INT;
  wire [31:1]       periph_tx_clr;
  wire [31:1]       periph_rx_clr;
  wire [31:0]            prdata;
  wire pslverr;
  wire pready;
  wire [`ID_BITS-1:0]        AWID0;
  wire [32-1:0]       AWADDR0;
  wire [`LEN_BITS-1:0]       AWLEN0;
  wire [`SIZE_BITS-1:0]   AWSIZE0;
  wire AWVALID0;
  wire [`ID_BITS-1:0]        WID0;
  wire [32-1:0]       WDATA0;
  wire [32/8-1:0]      WSTRB0;
  wire WLAST0;
  wire WVALID0;
  wire BREADY0;
  wire [`ID_BITS-1:0]        ARID0;
  wire [32-1:0]       ARADDR0;
  wire [`LEN_BITS-1:0]       ARLEN0;
  wire [`SIZE_BITS-1:0]   ARSIZE0;
  wire ARVALID0;
  wire RREADY0;

  dma_axi32 dut (.*);
  always #5 clk = ~clk;

  task automatic apb_write(input logic [12:0] addr, input logic [31:0] data);
    begin
      @(negedge clk); paddr = addr; pwdata = data; pwrite = 1'b1; psel = 1'b1; penable = 1'b0;
      @(posedge clk); #2; if (!pready || pslverr) $fatal(1, "APB write failed at %h", addr);
      @(negedge clk); penable = 1'b1;
      @(negedge clk); psel = 1'b0; penable = 1'b0; pwrite = 1'b0;
    end
  endtask

  task automatic apb_read(input logic [12:0] addr, output logic [31:0] data, output logic error);
    begin
      @(negedge clk); paddr = addr; pwrite = 1'b0; psel = 1'b1; penable = 1'b0;
      @(posedge clk); #2; if (!pready) $fatal(1, "APB read did not become ready at %h", addr);
      data = prdata; error = pslverr;
      @(negedge clk); penable = 1'b1;
      @(negedge clk); psel = 1'b0; penable = 1'b0;
    end
  endtask

  initial begin
    clk = 1'b0;
    reset = 1'b1;
    scan_en = '0;
    periph_tx_req = '0;
    periph_rx_req = '0;
    pclken = 1'b1;
    psel = '0;
    penable = '0;
    paddr = '0;
    pwrite = '0;
    pwdata = '0;
    AWREADY0 = '0;
    WREADY0 = '0;
    BID0 = '0;
    BRESP0 = '0;
    BVALID0 = '0;
    ARREADY0 = '0;
    RID0 = '0;
    RDATA0 = '0;
    RRESP0 = '0;
    RLAST0 = '0;
    RVALID0 = '0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;
    repeat (20) @(posedge clk);
    #1;
    if ($isunknown(idle) || $isunknown(INT) || $isunknown(periph_tx_clr) || $isunknown(periph_rx_clr) || $isunknown(prdata) || $isunknown(pslverr) || $isunknown(pready) || $isunknown(AWID0) || $isunknown(AWADDR0) || $isunknown(AWLEN0) || $isunknown(AWSIZE0) || $isunknown(AWVALID0) || $isunknown(WID0) || $isunknown(WDATA0) || $isunknown(WSTRB0) || $isunknown(WLAST0) || $isunknown(WVALID0) || $isunknown(BREADY0) || $isunknown(ARID0) || $isunknown(ARADDR0) || $isunknown(ARLEN0) || $isunknown(ARSIZE0) || $isunknown(ARVALID0) || $isunknown(RREADY0))
      $fatal(1, "DMA AXI32 outputs contain X after reset");
    if (AWVALID0 || WVALID0 || ARVALID0)
      $fatal(1, "DMA AXI32 issued an unexpected transaction while idle");
    begin : register_functional_checks
      logic [31:0] value;
      logic error;
      apb_write(13'h1030, 32'h0000_0001);
      apb_read(13'h1030, value, error);
      if (error || value[0] !== 1'b1) $fatal(1, "CORE0_JOINT readback");
      apb_write(13'h1040, 32'h0000_000a);
      apb_read(13'h1040, value, error);
      if (error || value[3:0] !== 4'h0) $fatal(1, "disabled CORE0_CLKDIV behavior");
      apb_write(13'h1050, 32'ha5a5_a5a4);
      apb_read(13'h1050, value, error);
      if (error || value !== 32'ha5a5_a5a4) $fatal(1, "PERIPH_RX_CTRL readback");
      apb_write(13'h0000, 32'hdead_beef);
      apb_read(13'h0000, value, error);
      if (error || value !== 32'hdead_beef) $fatal(1, "channel command readback");
      apb_read(13'h1048, value, error);
      if (!error) $fatal(1, "write-only CORE0_START accepted a read");
      apb_read(13'h10c0, value, error);
      if (!error) $fatal(1, "invalid global register did not report decode error");
    end
    if (AWVALID0 || WVALID0 || ARVALID0)
      $fatal(1, "configuration-only APB traffic unexpectedly started AXI");
    $display("DMA_AXI32_FUNCTIONAL_PASS: APB register oracle + idle AXI checks");
    $finish;
  end

  initial begin
    #5000;
    $fatal(1, "DMA AXI32 functional test timed out");
  end
endmodule

`default_nettype wire
