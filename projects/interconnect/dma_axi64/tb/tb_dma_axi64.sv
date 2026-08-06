`timescale 1ns/1ps
`default_nettype none
`include "dma_axi64_defines.v"
module tb_dma_axi64;
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
  logic [64-1:0]       RDATA0;
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
  wire [64-1:0]       WDATA0;
  wire [64/8-1:0]      WSTRB0;
  wire WLAST0;
  wire WVALID0;
  wire BREADY0;
  wire [`ID_BITS-1:0]        ARID0;
  wire [32-1:0]       ARADDR0;
  wire [`LEN_BITS-1:0]       ARLEN0;
  wire [`SIZE_BITS-1:0]   ARSIZE0;
  wire ARVALID0;
  wire RREADY0;
  dma_axi64 dut (.*);
  always #5 clk = ~clk;
  initial begin
    clk = 1'b0;
    reset = 1'b1;
    scan_en = '0;
    periph_tx_req = '0;
    periph_rx_req = '0;
    pclken = '0;
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
    @(negedge clk); reset = 1'b0;
    repeat (20) @(posedge clk); #1;
    if ($isunknown(idle) || $isunknown(INT) || $isunknown(periph_tx_clr) || $isunknown(periph_rx_clr) || $isunknown(prdata) || $isunknown(pslverr) || $isunknown(pready) || $isunknown(AWID0) || $isunknown(AWADDR0) || $isunknown(AWLEN0) || $isunknown(AWSIZE0) || $isunknown(AWVALID0) || $isunknown(WID0) || $isunknown(WDATA0) || $isunknown(WSTRB0) || $isunknown(WLAST0) || $isunknown(WVALID0) || $isunknown(BREADY0) || $isunknown(ARID0) || $isunknown(ARADDR0) || $isunknown(ARLEN0) || $isunknown(ARSIZE0) || $isunknown(ARVALID0) || $isunknown(RREADY0)) $fatal(1, "DMA AXI64 outputs contain X after reset");
    if (AWVALID0 || WVALID0 || ARVALID0) $fatal(1, "unexpected AXI request while idle");
    $display("DMA_AXI64_TOP_SV_PASS: mixed SV top + legacy Verilog blocks");
    $finish;
  end
  initial begin #5000; $fatal(1, "DMA AXI64 reset smoke test timed out"); end
endmodule
`default_nettype wire
