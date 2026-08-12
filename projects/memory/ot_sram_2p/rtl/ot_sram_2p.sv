// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Modified by the AI4EDA SV Corpus project: dependency-closed interface.
`default_nettype none
module ot_sram_2p #(
  parameter int Width=32, Depth=128, DataBitsPerMask=8,
  localparam int AddrWidth=$clog2(Depth), MaskWidth=Width/DataBitsPerMask
) (
  input logic clk_a_i,a_req_i,a_write_i,input logic[AddrWidth-1:0] a_addr_i,input logic[Width-1:0] a_wdata_i,input logic[MaskWidth-1:0] a_wmask_i,output logic[Width-1:0] a_rdata_o,
  input logic clk_b_i,b_req_i,b_write_i,input logic[AddrWidth-1:0] b_addr_i,input logic[Width-1:0] b_wdata_i,input logic[MaskWidth-1:0] b_wmask_i,output logic[Width-1:0] b_rdata_o
);
  logic[Width-1:0] mem[0:Depth-1],mask_a,mask_b; integer la,lb;
  initial if(Width<=0||Depth<=1||DataBitsPerMask<=0||Width%DataBitsPerMask)$fatal(1,"invalid parameters");
  always_comb begin
    mask_a='0;mask_b='0;
    for(la=0;la<MaskWidth;la=la+1)mask_a[la*DataBitsPerMask+:DataBitsPerMask]={DataBitsPerMask{a_wmask_i[la]}};
    for(lb=0;lb<MaskWidth;lb=lb+1)mask_b[lb*DataBitsPerMask+:DataBitsPerMask]={DataBitsPerMask{b_wmask_i[lb]}};
  end
  always_ff @(posedge clk_a_i) if(a_req_i) begin
    if(a_write_i) mem[a_addr_i]<=(a_wdata_i&mask_a)|(mem[a_addr_i]&~mask_a);
    else a_rdata_o<=mem[a_addr_i];
  end
  always_ff @(posedge clk_b_i) if(b_req_i) begin
    if(b_write_i) mem[b_addr_i]<=(b_wdata_i&mask_b)|(mem[b_addr_i]&~mask_b);
    else b_rdata_o<=mem[b_addr_i];
  end
endmodule
`default_nettype wire
