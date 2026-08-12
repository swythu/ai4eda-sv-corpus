// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Modified by the AI4EDA SV Corpus project: dependency-closed interface.
`default_nettype none
module ot_sram_1p #(
  parameter int Width=32, Depth=128, DataBitsPerMask=8,
  localparam int AddrWidth=$clog2(Depth), MaskWidth=Width/DataBitsPerMask
) (
  input logic clk_i, req_i, write_i,
  input logic [AddrWidth-1:0] addr_i,
  input logic [Width-1:0] wdata_i,
  input logic [MaskWidth-1:0] wmask_i,
  output logic [Width-1:0] rdata_o
);
  logic [Width-1:0] mem [0:Depth-1];
  logic [Width-1:0] expanded_mask;
  integer lane;
  initial if (Width<=0 || Depth<=1 || DataBitsPerMask<=0 || Width%DataBitsPerMask)
    $fatal(1,"ot_sram_1p has invalid parameters");
  always_comb begin
    expanded_mask='0;
    for(lane=0;lane<MaskWidth;lane=lane+1)
      expanded_mask[lane*DataBitsPerMask +: DataBitsPerMask]={DataBitsPerMask{wmask_i[lane]}};
  end
  always_ff @(posedge clk_i) if (req_i) begin
    if (write_i) mem[addr_i] <= (wdata_i&expanded_mask)|(mem[addr_i]&~expanded_mask);
    else rdata_o <= mem[addr_i];
  end
endmodule
`default_nettype wire
